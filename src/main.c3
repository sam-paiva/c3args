module c3args;

import std::io;
import core;

fn void main(String[] argv)
{
    Arg[2] definitions = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Your name"
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

    Command command = {
        .name = "c3args",
        .args = definitions[0..]
    };

    Cli cli = {
        .name = "c3args",
        .description = "A command-line argument parsing library",
        .root_command = command
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

    foreach (entry : matches.entries)
    {
        io::printfn("%s = %s", entry.name, entry.value);
    }
}
