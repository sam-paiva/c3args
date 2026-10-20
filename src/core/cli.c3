module core;

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

    if (argv.len > 0)
    {
        if (argv[0] == "--help" || argv[0] == "-h")
        {
            matches.help_requested = true;
            return true;
        }
    }

    return cli.parse_command(
        &cli.root_command,
        argv,
        matches,
        error
    );
}

fn bool Cli.parse_command(
    Cli* cli,
    Command* command,
    String[] argv,
    Matches* matches,
    ParseError* error
)
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

            return cli.parse_command(
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

fn void Cli.print_help(Cli* cli)
{
    Command* command = &cli.root_command;

    if (cli.selected_command != null)
    {
        command = cli.selected_command;
    }

    io::printfn("%s", command.name);

    if (command.description.len > 0)
    {
        io::printfn("%s", command.description);
    }

    io::printfn("");
    io::printfn("Usage: %s [OPTIONS]", command.name);

    if (command.subcommands.len > 0)
    {
        io::printfn("       %s <COMMAND>", command.name);
    }

    if (command.args.len > 0)
    {
        io::printfn("");
        io::printfn("Options:");

        foreach (arg : command.args)
        {
            if (arg.kind == ArgKind.OPTION)
            {
                if (arg.short_name.len > 0)
                {
                    io::printfn(
                        "  -%s, --%s <VALUE>  %s%s",
                        arg.short_name,
                        arg.name,
                        arg.description,
                        arg.required ? " (required)" : ""
                    );
                }
                else
                {
                    io::printfn(
                        "      --%s <VALUE>  %s%s",
                        arg.name,
                        arg.description,
                        arg.required ? " (required)" : ""
                    );
                }
            }
            else
            {
                io::printfn(
                    "  -%s, --%s  %s",
                    arg.short_name,
                    arg.name,
                    arg.description
                );
            }
        }
    }

    if (command.subcommands.len > 0)
    {
        io::printfn("");
        io::printfn("Commands:");

        foreach (subcommand : command.subcommands)
        {
            io::printfn(
                "  %s  %s",
                subcommand.name,
                subcommand.description
            );
        }
    }

    io::printfn("");
    io::printfn("  -h, --help  Show this help message");
}
