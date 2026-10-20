module core;

import std::io;

struct Cli
{
    String name;
    String description;
    Command root_command;
}

fn bool Cli.parse(
    Cli* cli,
    String[] argv,
    Matches* matches,
    ParseError* error
)
{
    // Handle built-in help before required-argument validation.
    foreach (token : argv)
    {
        if (token == "--help" || token == "-h")
        {
            matches.help_requested = true;
            return true;
        }
    }

    return cli.root_command.parse(argv, matches, error);
}

fn void Cli.print_help(Cli* cli)
{
    io::printfn("%s - %s", cli.name, cli.description);
    io::printfn("");
    io::printfn("Usage: %s [OPTIONS]", cli.name);
    io::printfn("");
    io::printfn("Options:");

    foreach (arg : cli.root_command.args)
    {
        String ali = "";

        if (arg.short_name.len > 0)
        {
            ali = arg.short_name;
        }

        if (arg.kind == ArgKind.OPTION)
        {
            if (ali.len > 0)
            {
                io::printfn(
                    "  -%s, --%s <VALUE>  %s%s",
                    ali,
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
            if (ali.len > 0)
            {
                io::printfn(
                    "  -%s, --%s          %s",
                    ali,
                    arg.name,
                    arg.description
                );
            }
            else
            {
                io::printfn(
                    "      --%s          %s",
                    arg.name,
                    arg.description
                );
            }
        }
    }

    io::printfn("  -h, --help          Show this help message");
}
