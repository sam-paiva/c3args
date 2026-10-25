module c3args::core;

import std::collections::list;

alias CommandHandler = fn void(Matches* matches);

struct Command
{
	String name;
	String description;
	Arg[] args;
	PositionalArg[] positionals;
	Command[] subcommands;
	CommandHandler handler;
}

fn int Command.find_subcommand(Command* command, String name)
{
	for (int i = 0; i < command.subcommands.len; i++)
	{
		if (command.subcommands[i].name == name)
		{
			return i;
		}
	}

	return -1;
}

fn int find_long_arg(Command* command, String name) @private
{
	for (int i = 0; i < command.args.len; i++)
	{
		if (command.args[i].name == name)
		{
			return i;
		}
	}

	return -1;
}

fn int find_short_arg(Command* command, String name) @private
{
	for (int i = 0; i < command.args.len; i++)
	{
		if (command.args[i].short_name.len > 0 && command.args[i].short_name == name)
		{
			return i;
		}
	}

	return -1;
}

fn bool is_negative_number(String token)
{
	return token.len >= 2 && token[0] == '-' && token[1] >= '0' && token[1] <= '9';
}

fn bool Command.validate(Command* command, ParseError* error)
{
	// Validate option and flag definitions.
	for (int i = 0; i < command.args.len; i++)
	{
		Arg current = command.args[i];

		// Long names must be non-empty and cannot start with '-' or contain '='.
		if (current.name.len == 0 || current.name[0] == '-' || current.name.contains("="))
		{
			error.kind = ParseErrorKind.INVALID_DEFINITION;
			error.argument = current.name;
			return false;
		}

		// Short names are optional, but must be a single valid character.
		if (current.short_name.len > 1
			|| (current.short_name.len > 0 && (current.short_name[0] == '-' || current.short_name.contains(
			"="
		))))
		{
			error.kind = ParseErrorKind.INVALID_DEFINITION;
			error.argument = current.short_name;
			return false;
		}

		// Argument names and short aliases must be unique,
		// including collisions between the two categories.
		for (int j = i + 1; j < command.args.len; j++)
		{
			Arg other = command.args[j];

			// Duplicate long names.
			if (current.name == other.name)
			{
				error.kind = ParseErrorKind.INVALID_DEFINITION;
				error.argument = current.name;
				return false;
			}

			// Duplicate short aliases.
			if (current.short_name.len > 0 && other.short_name.len > 0 && current.short_name == other.short_name)
			{
				error.kind = ParseErrorKind.INVALID_DEFINITION;
				error.argument = current.short_name;
				return false;
			}

			// Current long name conflicts with the other short alias.
			if (other.short_name.len > 0 && current.name == other.short_name)
			{
				error.kind = ParseErrorKind.INVALID_DEFINITION;
				error.argument = current.name;
				return false;
			}

			// Current short alias conflicts with the other long name.
			if (current.short_name.len > 0 && current.short_name == other.name)
			{
				error.kind = ParseErrorKind.INVALID_DEFINITION;
				error.argument = current.short_name;
				return false;
			}
		}
	}

	// Validate positional definitions.
	bool optional_positional_seen = false;

	for (int i = 0; i < command.positionals.len; i++)
	{
		PositionalArg current = command.positionals[i];

		if (current.name.len == 0 || current.name[0] == '-' || current.name.contains("="))
		{
			error.kind = ParseErrorKind.INVALID_DEFINITION;
			error.argument = current.name;
			return false;
		}

		// A variadic positional must be the final positional.
		if (current.allow_multiple && i != command.positionals.len - 1)
		{
			error.kind = ParseErrorKind.INVALID_DEFINITION;
			error.argument = current.name;
			return false;
		}

		// Required positionals cannot follow optional positionals.
		if (current.required && optional_positional_seen)
		{
			error.kind = ParseErrorKind.INVALID_DEFINITION;
			error.argument = current.name;
			return false;
		}

		if (!current.required)
		{
			optional_positional_seen = true;
		}

		// Positional names must not conflict with option names or aliases.
		for (int j = 0; j < command.args.len; j++)
		{
			Arg arg = command.args[j];

			if (current.name == arg.name || (arg.short_name.len > 0 && current.name == arg.short_name))
			{
				error.kind = ParseErrorKind.INVALID_DEFINITION;
				error.argument = current.name;
				return false;
			}
		}

		// Positional names must be unique.
		for (int j = i + 1; j < command.positionals.len; j++)
		{
			if (current.name == command.positionals[j].name)
			{
				error.kind = ParseErrorKind.INVALID_DEFINITION;
				error.argument = current.name;
				return false;
			}
		}
	}

	// Validate subcommand names and sibling uniqueness.
	for (int i = 0; i < command.subcommands.len; i++)
	{
		Command* current = &command.subcommands[i];

		if (current.name.len == 0 || current.name[0] == '-' || current.name.contains("="))
		{
			error.kind = ParseErrorKind.INVALID_DEFINITION;
			error.argument = current.name;
			return false;
		}

		for (int j = i + 1; j < command.subcommands.len; j++)
		{
			if (current.name == command.subcommands[j].name)
			{
				error.kind = ParseErrorKind.INVALID_DEFINITION;
				error.argument = current.name;
				return false;
			}
		}

		// Validate nested command definitions recursively.
		if (!current.validate(error))
		{
			return false;
		}
	}

	return true;
}

fn bool Command.parse_positional(
	Command* command,
	String token,
	int* positional_index,
	Matches* matches,
	ParseError* error
)
{
	if (*positional_index >= command.positionals.len)
	{
		error.kind = ParseErrorKind.UNEXPECTED_ARGUMENT;
		error.argument = token;
		return false;
	}

	PositionalArg positional = command.positionals[*positional_index];

	matches.add_option(positional.name, token);

	if (!positional.allow_multiple)
	{
		(*positional_index)++;
	}

	return true;
}

fn void Command.resolve_option_token(
	Command* command,
	String token,
	String* name,
	String* value,
	bool* has_inline_value,
	int* arg_index
)
{
	bool is_long_option = token[1] == '-';
	String option_token;

	if (is_long_option)
	{
		option_token = token[2..];
	}
	else
	{
		option_token = token[1..];
	}

	*has_inline_value = false;
	*name = option_token;
	*value = "";

	for (int j = 0; j < option_token.len; j++)
	{
		if (option_token[j] == '=')
		{
			if (j == 0)
			{
				*name = "";
			}
			else
			{
				*name = option_token[0..(j - 1)];
			}

			*value = option_token[(j + 1)..];
			*has_inline_value = true;
			break;
		}
	}

	if (is_long_option)
	{
		*arg_index = find_long_arg(command, *name);
	}
	else
	{
		*arg_index = find_short_arg(command, *name);
	}
}

fn bool Command.parse_option(
	Command* command,
	String[] argv,
	int* index,
	String token,
	Matches* matches,
	ParseError* error
)
{
	if (token.len < 2)
	{
		error.kind = ParseErrorKind.UNEXPECTED_ARGUMENT;
		error.argument = token;
		return false;
	}

	String name;
	String value;
	bool has_inline_value =  false;
	int arg_index         = -1;

	command.resolve_option_token(token, &name, &value, &has_inline_value, &arg_index);

	if (arg_index == -1)
	{
		error.kind = ParseErrorKind.UNKNOWN_OPTION;
		error.argument = token;
		return false;
	}

	Arg arg = command.args[arg_index];

	// Flags are idempotent and don't consume values.
	if (arg.kind == ArgKind.FLAG)
	{
		if (has_inline_value)
		{
			error.kind = ParseErrorKind.UNEXPECTED_ARGUMENT;
			error.argument = token;
			return false;
		}

		if (!matches.has(arg.name))
		{
			matches.add_flag(arg.name);
		}

		return true;
	}

	// Reject duplicate options unless repetition is enabled.
	if (matches.has(arg.name) && !arg.allow_multiple)
	{
		error.kind = ParseErrorKind.DUPLICATE_ARGUMENT;
		error.argument = arg.name;
		return false;
	}

	// Obtain the option value.
	if (has_inline_value)
	{
		if (value.len == 0)
		{
			error.kind = ParseErrorKind.MISSING_VALUE;
			error.argument = token;
			return false;
		}
	}
	else
	{
		if ((long)*index + 1 >= argv.len)
		{
			error.kind = ParseErrorKind.MISSING_VALUE;
			error.argument = token;
			return false;
		}

		String next_token = argv[*index + 1];

		// Allow help tokens as values when an option expects a value.
		// Other option-like tokens remain invalid, except negative numbers.
		if (next_token.len >= 2 && next_token[0] == '-' && !is_negative_number(
			next_token
		) && next_token != "--help" && next_token != "-h")
		{
			error.kind = ParseErrorKind.MISSING_VALUE;
			error.argument = token;
			return false;
		}

		(*index)++;
		value = argv[*index];
	}

	matches.add_option(arg.name, value);
	return true;
}

fn bool Command.validate_required_arguments(Command* command, Matches* matches, ParseError* error)
{
	foreach (arg : command.args)
	{
		if (arg.required && !matches.has(arg.name))
		{
			error.kind = ParseErrorKind.MISSING_REQUIRED_ARGUMENT;
			error.argument = arg.name;
			return false;
		}
	}

	foreach (positional : command.positionals)
	{
		if (positional.required && !matches.has(positional.name))
		{
			error.kind = ParseErrorKind.MISSING_REQUIRED_ARGUMENT;
			error.argument = positional.name;
			return false;
		}
	}

	return true;
}


fn bool Command.parse(Command* command, String[] argv, Matches* matches, ParseError* error)
{
	if (!command.validate(error))
	{
		return false;
	}

	int positional_index    = 0;
	bool options_terminated = false;

	for (int i = 0; i < argv.len; i++)
	{
		String token = argv[i];

		// "--" terminates option parsing.
		if (!options_terminated && token == "--")
		{
			options_terminated = true;
			continue;
		}

		// Recognize help only when it is parsed as an argument,
		// not when it has already been consumed as an option value.
		if (!options_terminated && (token == "--help" || token == "-h"))
		{
			matches.help_requested = true;
			return true;
		}

		// Parse positional arguments.
		if (options_terminated || token.len == 0 || token[0] != '-')
		{
			if (!command.parse_positional(token, &positional_index, matches, error))
			{
				return false;
			}

			continue;
		}

		if (!command.parse_option(argv, &i, token, matches, error))
		{
			return false;
		}
	}

	return command.validate_required_arguments(matches, error);
}
