module core;

import std::collections::list;

struct Command
{
    String name;
    Arg[] args;
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

fn bool Command.parse(
    Command* command,
    String[] argv,
    Matches* matches,
    ParseError* error
)
{
    for (int i = 0; i < argv.len; i++)
    {
        String token = argv[i];

        if (token.len < 2 || token[0] != '-')
        {
            error.kind = ParseErrorKind.UNEXPECTED_ARGUMENT;
            error.argument = token;
            return false;
        }

        bool is_long_option = token.len >= 2
        && token[1] == '-';

        String name;
        int arg_index;

        if (is_long_option)
        {
            name = token[2..];
            arg_index = command.find_long_arg(name);
        }
        else
        {
            name = token[1..];
            arg_index = command.find_short_arg(name);
        }

        if (arg_index == -1)
        {
            error.kind = ParseErrorKind.UNKNOWN_OPTION;
            error.argument = token;
            return false;
        }

        Arg arg = command.args[arg_index];

        if (arg.kind == ArgKind.FLAG)
        {
            matches.add_flag(arg.name);
            continue;
        }

        if ((long)i + 1 >= argv.len)
        {
            error.kind = ParseErrorKind.MISSING_VALUE;
            error.argument = token;
            return false;
        }

        i++;
        matches.add_option(arg.name, argv[i]);
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
