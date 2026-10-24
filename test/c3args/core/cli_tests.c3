module c3args::tests::core;

import c3args::core;

bool test_handler_was_called = false;

fn void test_cli_rejects_invalid_unselected_subcommand() @test
{
    Arg[1] invalid_args = {
        {
            .name = "",
            .kind = ArgKind.OPTION
        }
    };

    Command[1] subcommands = {
        {
            .name = "hidden",
            .args = invalid_args[0..]
        }
    };

    Command root = {
        .name = "app",
        .subcommands = subcommands[0..]
    };

    Cli cli = {
        .name = "app",
        .root_command = root
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--help" };

    bool success = cli.parse(argv, &matches, &error);

    assert(!success, "CLI should reject invalid command definitions");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}


fn void test_cli_test_handler(Matches* matches)
{
    test_handler_was_called = true;
}

fn void test_cli_does_not_execute_handler_when_help_requested() @test
{
    test_handler_was_called = false;

    Command root = {
        .name = "app",
        .handler = &test_cli_test_handler
    };

    Cli cli = {
        .name = "app",
        .root_command = root
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    matches.help_requested = true;

    bool success = cli.execute(&matches);

    assert(success, "Execution should succeed when help is requested");
    assert(
        !test_handler_was_called,
        "Command handler must not run when help is requested"
    );
}


fn void test_cli_root_long_help_is_recognized() @test
{
    Cli cli = {
        .name = "app",
        .root_command = {
            .name = "app"
        }
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--help" };

    bool success = cli.parse(argv, &matches, &error);

    assert(success, "Root --help should succeed");
    assert(matches.help_requested, "Root --help should set help_requested");
}

fn void test_cli_root_short_help_is_recognized() @test
{
    Cli cli = {
        .name = "app",
        .root_command = {
            .name = "app"
        }
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "-h" };

    bool success = cli.parse(argv, &matches, &error);

    assert(success, "Root -h should succeed");
    assert(matches.help_requested, "Root -h should set help_requested");
}

fn void test_cli_subcommand_long_help_is_recognized() @test
{
    Command[1] subcommands = {
        {
            .name = "config"
        }
    };

    Cli cli = {
        .name = "app",
        .root_command = {
            .name = "app",
            .subcommands = subcommands[0..]
        }
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "config", "--help" };

    bool success = cli.parse(argv, &matches, &error);

    assert(success, "Subcommand --help should succeed");
    assert(matches.help_requested, "Subcommand --help should set help_requested");
    assert(
        cli.selected_command.name == "config",
        "The selected command should be config"
    );
}

fn void test_cli_subcommand_short_help_is_recognized() @test
{
    Command[1] subcommands = {
        {
            .name = "config"
        }
    };

    Cli cli = {
        .name = "app",
        .root_command = {
            .name = "app",
            .subcommands = subcommands[0..]
        }
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "config", "-h" };

    bool success = cli.parse(argv, &matches, &error);

    assert(success, "Subcommand -h should succeed");
    assert(matches.help_requested, "Subcommand -h should set help_requested");
    assert(
        cli.selected_command.name == "config",
        "The selected command should be config"
    );
}


fn void test_cli_nested_subcommand_help_is_recognized() @test
{
    Command[1] nested_commands = {
        {
            .name = "set"
        }
    };

    Command[1] subcommands = {
        {
            .name = "config",
            .subcommands = nested_commands[0..]
        }
    };

    Cli cli = {
        .name = "app",
        .root_command = {
            .name = "app",
            .subcommands = subcommands[0..]
        }
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "config", "set", "--help" };

    bool success = cli.parse(argv, &matches, &error);

    assert(success, "Nested --help should succeed");
    assert(matches.help_requested, "Nested --help should set help_requested");
    assert(
        cli.selected_command.name == "set",
        "The deepest subcommand should be selected"
    );
}

fn void test_cli_help_after_option_is_recognized() @test
{
    Arg[1] args = {
        {
            .name = "verbose",
            .kind = ArgKind.FLAG
        }
    };

    Cli cli = {
        .name = "app",
        .root_command = {
            .name = "app",
            .args = args[0..]
        }
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--verbose", "--help" };

    bool success = cli.parse(argv, &matches, &error);

    assert(success, "Help after an option should succeed");
    assert(matches.help_requested, "Help after an option should be recognized");
}

fn void test_cli_help_token_can_be_an_option_value() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .kind = ArgKind.OPTION
        }
    };

    Cli cli = {
        .name = "app",
        .root_command = {
            .name = "app",
            .args = args[0..]
        }
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--name", "--help" };

    bool success = cli.parse(argv, &matches, &error);

    assert(success, "The help token should be accepted as an option value");
    assert(
        !matches.help_requested,
        "Help should not be requested when the token is consumed as a value"
    );
}

