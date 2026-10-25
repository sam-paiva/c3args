module c3args::core;

import std::io;

struct Cli
{
	String name;
	String description;
	Command root_command;
	Command* selected_command;
}

fn bool Cli.parse(
    Cli* cli,
    String[] argv,
    Matches* matches,
    ParseError* error
)
{
    matches.reset();

    cli.selected_command = &cli.root_command;

    if (!cli.root_command.validate(error))
    {
        return false;
    }

    return parse_command(
        cli,
        &cli.root_command,
        argv,
        matches,
        error
    );
}

fn bool parse_command(
	Cli* cli, 
	Command* command, 
	String[] argv, 
	Matches* matches, 
	ParseError* error) @private
{
	cli.selected_command = command;

	if (argv.len > 0)
	{
		int subcommand_index = command.find_subcommand(argv[0]);

		if (subcommand_index != -1)
		{
			Command* subcommand = &command.subcommands[subcommand_index];

			return parse_command(cli, subcommand, argv[1..], matches, error);
		}
	}

	return command.parse(argv, matches, error);
}

fn bool Cli.execute(Cli* cli, Matches* matches)
{
	if (matches.help_requested)
	{
		return true;
	}

	if (cli.selected_command == null)
	{
		return false;
	}

	Command* command = cli.selected_command;

	if (command.handler == null)
	{
		return false;
	}

	command.handler(matches);

	return true;
}

// Returns whether target is contained in this command's tree.
fn bool Cli.contains_command(Cli* cli, Command* command, Command* target)
{
	if (command == target)
	{
		return true;
	}

	for (int i = 0; i < command.subcommands.len; i++)
	{
		if (cli.contains_command(&command.subcommands[i], target))
		{
			return true;
		}
	}

	return false;
}

// Prints the path in root-to-leaf order.
fn void Cli.print_command_path(Cli* cli, Command* command, Command* target)
{
	io::print(command.name);

	if (command == target)
	{
		return;
	}

	for (int i = 0; i < command.subcommands.len; i++)
	{
		Command* child = &command.subcommands[i];

		if (cli.contains_command(child, target))
		{
			io::print(" ");
			cli.print_command_path(child, target);
			return;
		}
	}
}

fn void Cli.print_help(Cli* cli)
{
	String help = c3args::core::format(cli);
	io::print(help);
}
