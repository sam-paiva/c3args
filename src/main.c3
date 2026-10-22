module c3args;

import std::io;
import c3args::core;
import std::collections::list;

fn void handle_get(Matches* matches)
{
    String name;

    if (matches.get("name", &name))
    {
        io::printfn("Name: %s", name);
    }

    bool verbose;
    matches.get_bool("verbose", &verbose);

    if (verbose)
    {
        io::printn("Verbose mode enabled.");
    }

    List{String} names;
    names.init(mem);
    defer names.free();

    matches.get_all("name", &names);

    foreach (name_entry : names)
    {
        io::printfn("Found name: %s", name_entry);
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

    //Register a Positional Argument
    PositionalArg[1] get_positionals = {
        {
            .name = "name",
            .required = true,
            .allow_multiple = true,
            .description = "Names to retrieve"
        }
    };

    Arg[2] get_definitions = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Name to retrieve"
        }
        ,
        {
            .name = "verbose",
            .short_name = "v",
            .kind = ArgKind.FLAG,
            .required = false,
            .description = "Enable verbose output"
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
        .handler = &handle_get,
        .positionals = get_positionals[0..]
    };

    Command set_command = {
        .name = "set",
        .description = "Set configuration",
        .args = set_definitions[0..],
        .handler = &handle_set
    };

    Command[2] config_subcommands = {
        get_command,
        set_command,
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
            case ParseErrorKind.DUPLICATE_ARGUMENT:
                io::printfn("Option '%s' cannot be specified more than once.", error.argument);
            case INVALID_DEFINITION:
                io::printfn(
                    "Error: Invalid command definition: %s",
                    error.argument
                );
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
