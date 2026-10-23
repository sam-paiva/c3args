module c3args::tests::core;

import c3args::core;

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
    matches.entries.init(mem);
    defer matches.entries.free();

    ParseError error;
    String[] argv = (String[]){ "--help" };

    bool success = cli.parse(argv, &matches, &error);

    assert(!success, "CLI should reject invalid command definitions");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}
