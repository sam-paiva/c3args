module c3args;

import std::io;
import core;

fn void handle_get(Matches* matches)
{
    foreach (entry : matches.entries)
    {
        io::printfn("%s = %s", entry.name, entry.value);
    }
}

fn void handle_set(Matches* matches)
{
    foreach (entry : matches.entries)
    {
        if (entry.name == "name")
        {
            io::printfn("Setting configuration: %s", entry.value);
        }
    }
}

fn void main(String[] argv)
{

    Arg[1] get_definitions = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Name to retrieve"
        }
    };

    Arg[1] set_definitions = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Name to set"
        }
    };

    Command get_command = {
        .name = "get",
        .description = "Get configuration",
        .args = get_definitions[0..],
        .handler = &handle_get
    };

    Command set_command = {
        .name = "set",
        .description = "Set configuration",
        .args = set_definitions[0..],
        .handler = &handle_set
    };

    Command[2] config_subcommands = {
        get_command,
        set_command
    };

    Command config_command = {
        .name = "config",
        .description = "Manage configuration",
        .subcommands = config_subcommands[0..]
    };

    Command root_command = {
        .name = "c3args",
        .description = "A command-line argument parsing library",
        .subcommands = (Command[]){ config_command }
    };

    Cli cli = {
        .name = "c3args",
        .description = "A command-line argument parsing library",
        .root_command = root_command
    };

    Matches matches;
    matches.entries.init(mem);
    defer matches.entries.free();

    ParseError error;

    if (!cli.parse(argv[1..], &matches, &error))
    {
        switch (error.kind)
        {
            case ParseErrorKind.UNKNOWN_OPTION:
                io::printfn("Unknown option '%s'.", error.argument);
            case ParseErrorKind.MISSING_VALUE:
                io::printfn("Option '%s' requires a value.", error.argument);
            case ParseErrorKind.MISSING_REQUIRED_ARGUMENT:
                io::printfn("Missing required argument: --%s", error.argument);
            case ParseErrorKind.UNEXPECTED_ARGUMENT:
                io::printfn("Unexpected argument '%s'.", error.argument);
        }

        return;
    }

    if (matches.help_requested)
    {
        cli.print_help();
        return;
    }

    if (!cli.execute(&matches))
    {
        io::printfn("No handler registered for this command.");
        return;
    }
}
