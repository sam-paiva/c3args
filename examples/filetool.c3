
module examples;

import std::io;
import std::collections::list;
import c3args::core;

fn void run_filetool(Matches* matches)
{
    String output = matches.get("output");

    bool verbose = false;
    matches.get_bool("verbose", &verbose);

    io::printfn("Output directory: %s", output);

    List{String} files;
    files.init(mem);
    defer files.free();

    matches.get_all("files", &files);

    foreach (file : files)
    {
        if (verbose)
        {
            io::printf("Processing: ");
        }

        io::printfn("%s", file);
    }
}

fn void get_config(Matches* matches)
{
    String key = matches.get("key");
    io::printfn("Get config: %s", key);
}

fn void set_config(Matches* matches)
{
    String key = matches.get("key");
    String value = matches.get("value");

    io::printfn("Set config: %s = %s", key, value);
}

fn int main(String[] args)
{
    Arg[] root_args = {
        {
            .name = "verbose",
            .short_name = "v",
            .kind = ArgKind.FLAG,
            .description = "Enable verbose output"
        },
        {
            .name = "output",
            .short_name = "o",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Output directory"
        }
    };

    PositionalArg[] root_positionals = {
        {
            .name = "files",
            .required = true,
            .allow_multiple = true,
            .description = "Files to process"
        }
    };

    Arg[] get_args = {
        {
            .name = "key",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Configuration key"
        }
    };

    Command get_command = {
        .name = "get",
        .description = "Get a configuration value",
        .args = get_args,
        .handler = &get_config
    };

    Arg[] set_args = {
        {
            .name = "key",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Configuration key"
        },
        {
            .name = "value",
            .kind = ArgKind.OPTION,
            .required = true,
            .description = "Configuration value"
        }
    };

    Command set_command = {
        .name = "set",
        .description = "Set a configuration value",
        .args = set_args,
        .handler = &set_config
    };

    Command[] config_subcommands = {
        get_command,
        set_command
    };

    Command config_command = {
        .name = "config",
        .description = "Manage configuration",
        .subcommands = config_subcommands
    };

    Command[] root_subcommands = {
        config_command
    };

    Command root_command = {
        .name = "filetool",
        .description = "File processing example",
        .args = root_args,
        .positionals = root_positionals,
        .subcommands = root_subcommands,
        .handler = &run_filetool
    };

    Cli cli = {
        .name = "filetool",
        .description = "File processing and configuration",
        .root_command = root_command
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;

    if (!cli.parse(args, &matches, &error))
    {
        cli.print_help();
        return 1;
    }

    if (matches.help_requested)
    {
        cli.print_help();
        return 0;
    }

    cli.execute(&matches);
    return 0;
}
