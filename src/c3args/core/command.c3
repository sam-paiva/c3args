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

fn int Command.find_long_arg(Command* command, String name)
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

fn bool Command.validate(Command* command, ParseError* error)
{
    // Validate arguments belonging to this command.
    for (int i = 0; i < command.args.len; i++)
    {
        Arg current = command.args[i];

        if (current.name.len == 0)
        {
            error.kind = ParseErrorKind.INVALID_DEFINITION;
            error.argument = current.name;
            return false;
        }

        for (int j = i + 1; j < command.args.len; j++)
        {
            Arg other = command.args[j];

            if (current.name == other.name)
            {
                error.kind = ParseErrorKind.INVALID_DEFINITION;
                error.argument = current.name;
                return false;
            }

            if (
                current.short_name.len > 0 &&
                current.short_name == other.short_name
            )
            {
                error.kind = ParseErrorKind.INVALID_DEFINITION;
                error.argument = current.short_name;
                return false;
            }
        }
    }

    // Validate subcommand names and detect duplicate siblings.
    for (int i = 0; i < command.subcommands.len; i++)
    {
        Command* current = &command.subcommands[i];

        if (current.name.len == 0)
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

        // Recursively validate this subcommand's own definition.
        if (!current.validate(error))
        {
            return false;
        }
    }

    return true;
}

fn bool Command.parse(
    Command* command,
    String[] argv,
    Matches* matches,
    ParseError* error
)
{
    if (!command.validate(error))
    {
        return false;
    }

    int positional_index = 0;
    bool options_terminated = false;

    for (int i = 0; i < argv.len; i++)
    {
        String token = argv[i];

        // "--" ends option parsing.
        if (!options_terminated && token == "--")
        {
            options_terminated = true;
            continue;
        }

        // After "--", every token is positional.
        if (options_terminated || token.len == 0 || token[0] != '-')
        {
            if (positional_index >= command.positionals.len)
            {
                error.kind = ParseErrorKind.UNEXPECTED_ARGUMENT;
                error.argument = token;
                return false;
            }

            PositionalArg positional = command.positionals[positional_index];

            matches.add_option(positional.name, token);

            if (!positional.allow_multiple)
            {
                positional_index++;
            }

            continue;
        }

        // A lone '-' is not a valid option.
        if (token.len < 2)
        {
            error.kind = ParseErrorKind.UNEXPECTED_ARGUMENT;
            error.argument = token;
            return false;
        }

        bool is_long_option = token[1] == '-';

        String name;
        String value;
        bool has_inline_value = false;
        int arg_index;

        // Resolve the argument name and optional inline value.
        if (is_long_option)
        {
            String option_token = token[2..];

            for (int j = 0; j < option_token.len; j++)
            {
                if (option_token[j] == '=')
                {
                    name = option_token[0..(j - 1)];
                    value = option_token[(j + 1)..];
                    has_inline_value = true;
                    break;
                }
            }

            if (!has_inline_value)
            {
                name = option_token;
            }

            arg_index = command.find_long_arg(name);
        }
        else
        {
            String option_token = token[1..];

            for (int j = 0; j < option_token.len; j++)
            {
                if (option_token[j] == '=')
                {
                    name = option_token[0..(j - 1)];
                    value = option_token[(j + 1)..];
                    has_inline_value = true;
                    break;
                }
            }

            if (!has_inline_value)
            {
                name = option_token;
            }

            arg_index = command.find_short_arg(name);
        }

        // Reject unknown arguments.
        if (arg_index == -1)
        {
            error.kind = ParseErrorKind.UNKNOWN_OPTION;
            error.argument = token;
            return false;
        }

        Arg arg = command.args[arg_index];

        // Flags do not consume values and are idempotent.
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

            continue;
        }

        // Reject duplicate options unless repetition is enabled.
        if (matches.has(arg.name) && !arg.allow_multiple)
        {
            error.kind = ParseErrorKind.DUPLICATE_ARGUMENT;
            error.argument = arg.name;
            return false;
        }

        // Read an inline value or consume the next token.
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
            if ((long)i + 1 >= argv.len)
            {
                error.kind = ParseErrorKind.MISSING_VALUE;
                error.argument = token;
                return false;
            }

            String next_token = argv[i + 1];

            // Don't mistake another option for this option's value.
            // Negative numeric values are valid option values.
            if (next_token.len >= 2 && next_token[0] == '-')
            {
                bool is_negative_number =
                next_token.len >= 2 &&
                next_token[0] == '-' &&
                next_token[1] >= '0' &&
                next_token[1] <= '9';

                if (!is_negative_number)
                {
                    error.kind = ParseErrorKind.MISSING_VALUE;
                    error.argument = token;
                    return false;
                }
            }

            i++;
            value = argv[i];
        }

        matches.add_option(arg.name, value);
    }

    // Validate required arguments after parsing.
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

fn int Command.find_short_arg(Command* command, String name)
{
    for (int i = 0; i < command.args.len; i++)
    {
        if (command.args[i].short_name == name)
        {
            return i;
        }
    }

    return -1;
}
