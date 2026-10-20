module core;

faultdef ERROR_INVALID_INPUT;

struct ParsedArgs
{
    bool verbose;
    String name;
}

fn ParsedArgs? parse(String[] args)
{
    if (args.len == 0)
    {
        return ERROR_INVALID_INPUT~;
    }

    ParsedArgs parsedArgs = {
        .name = "",
        .verbose = false
    };

    foreach (index, arg : args)
    {
        if (arg == "--verbose" || arg == "-v")
        {
            parsedArgs.verbose = true;
        }
        else if (arg == "--name" || arg == "-n")
        {
            if (index + 1 < args.len)
            {
                parsedArgs.name = args[index + 1];
            }
        }
    }

    return parsedArgs;
}
