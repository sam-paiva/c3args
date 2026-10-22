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
    cli.selected_command = &cli.root_command;

    return parse_command(cli,
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
    ParseError* error
) @private
{
    cli.selected_command = command;

    if (argv.len > 0)
    {
        if (argv[0] == "--help" || argv[0] == "-h")
        {
            matches.help_requested = true;
            return true;
        }

        int subcommand_index = command.find_subcommand(argv[0]);

        if (subcommand_index != -1)
        {
            Command* subcommand = &command.subcommands[subcommand_index];

            return parse_command(
                cli,
                subcommand,
                argv[1..],
                matches,
                error
            );
        }
    }

    return command.parse(argv, matches, error);
}

fn bool Cli.execute(Cli* cli, Matches* matches)
{
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
fn bool Cli.contains_command(
    Cli* cli,
    Command* command,
    Command* target
)
{
    if (command == target)
    {
        return true;
    }

    for (int i = 0; i < command.subcommands.len; i++)
    {
        if (cli.contains_command(
                &command.subcommands[i],
                target
            ))
        {
            return true;
        }
    }

    return false;
}

// Prints the path in root-to-leaf order.
fn void Cli.print_command_path(
    Cli* cli,
    Command* command,
    Command* target
)
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
    Command* command = &cli.root_command;

    if (cli.selected_command != null)
    {
        command = cli.selected_command;
    }

    // Title and description.
    io::printfn("%s", command.name);

    if (command.description.len > 0)
    {
        io::printfn("%s", command.description);
    }

    // Usage line with the full command path.
    io::print("\nUsage:\n  ");
    cli.print_command_path(&cli.root_command, command);

    for (int i = 0; i < command.positionals.len; i++)
    {
        PositionalArg positional = command.positionals[i];

        if (positional.required)
        {
            io::printf(" <%s>", positional.name);
        }
        else
        {
            io::printf(" [%s]", positional.name);
        }

        if (positional.allow_multiple)
        {
            io::print("...");
        }
    }

    if (command.args.len > 0)
    {
        io::print(" [OPTIONS]");
    }

    if (command.subcommands.len > 0)
    {
        io::print(" <COMMAND>");
    }

    io::print("\n");

    // Positional arguments.
    if (command.positionals.len > 0)
    {
        io::printfn("\nArguments:");

        foreach (positional : command.positionals)
        {
            io::printf(
                "  <%s>  %s",
                positional.name,
                positional.description
            );

            if (positional.required)
            {
                io::print(" (required)");
            }

            io::print("\n");
        }
    }

    // Options and flags.
    if (command.args.len > 0)
    {
        io::printfn("\nOptions:");

        foreach (arg : command.args)
        {
            if (arg.short_name.len > 0)
            {
                io::printf("  -%s, --%s", arg.short_name, arg.name);
            }
            else
            {
                io::printf("      --%s", arg.name);
            }

            if (arg.kind == ArgKind.OPTION)
            {
                io::print(" <VALUE>");
            }

            io::printf("  %s", arg.description);

            if (arg.required)
            {
                io::print(" (required)");
            }

            io::print("\n");
        }
    }

    // Nested commands.
    if (command.subcommands.len > 0)
    {
        io::printfn("\nCommands:");

        foreach (subcommand : command.subcommands)
        {
            io::printf(
                "  %s  %s\n",
                subcommand.name,
                subcommand.description
            );
        }
    }

    io::printfn("  -h, --help  Show this help message");
}
