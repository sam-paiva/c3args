module c3args::tests::core;

import std::collections::list;
import c3args::core;

fn void test_long_option_inline_value() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--name=Samuel" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Long option with inline value should parse");

    String value;
    assert(matches.get("name", &value), "Name should be present");
    assert(value == "Samuel", "Name should equal Samuel");
}

fn void test_short_option_inline_value() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "-n=Samuel" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Short option with inline value should parse");

    String value;
    assert(matches.get("name", &value), "Name should be present");
    assert(value == "Samuel", "Name should equal Samuel");
}

fn void test_variadic_positional_arguments() @test
{
    PositionalArg[1] positionals = {
        {
            .name = "name",
            .required = true,
            .allow_multiple = true
        }
    };

    Command command = {
        .name = "test",
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "Samuel", "Alex", "Jordan" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Multiple positional values should parse");

    List{String} names;
    names.init(mem);
    defer names.free();

    matches.get_all("name", &names);

    assert(names.len() == 3, "All three positional values should be stored");

    String first;
    assert(matches.get("name", &first), "First positional should exist");
    assert(first == "Samuel", "First positional should equal Samuel");
}

fn void test_unknown_option_is_rejected() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--unknown" };

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Unknown options should be rejected");
    assert(
        error.kind == ParseErrorKind.UNKNOWN_OPTION,
        "Error should identify an unknown option"
    );
}

fn void test_missing_required_option_is_rejected() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Missing required options should be rejected");
    assert(
        error.kind == ParseErrorKind.MISSING_REQUIRED_ARGUMENT,
        "Error should identify the missing required argument"
    );
}

fn void test_duplicate_option_is_rejected() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--name", "Samuel", "--name", "Alex" };

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Duplicate options should be rejected");
    assert(
        error.kind == ParseErrorKind.DUPLICATE_ARGUMENT,
        "Expected duplicate argument error"
    );
}

fn void test_repeated_flag_is_idempotent() @test
{
    Arg[1] args = {
        {
            .name = "verbose",
            .short_name = "v",
            .kind = ArgKind.FLAG
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--verbose", "--verbose" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Repeated flags should be accepted");
    assert(matches.entries.len() == 1, "Flag should be stored only once");
    assert(matches.has("verbose"), "Verbose flag should be present");
}

fn void test_missing_option_value_is_rejected() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION,
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    {
        Matches matches;
        matches.init();
        defer matches.deinit();

        ParseError error;
        String[] argv = (String[]){ "--name" };

        bool success = command.parse(argv, &matches, &error);

        assert(!success, "Missing option value should be rejected");
        assert(
            error.kind == ParseErrorKind.MISSING_VALUE,
            "Expected missing value error"
        );
    }

    {
        Matches matches;
        matches.init();
        defer matches.deinit();

        ParseError error;
        String[] argv = (String[]){ "--name=" };

        bool success = command.parse(argv, &matches, &error);

        assert(!success, "Empty inline value should be rejected");
        assert(
            error.kind == ParseErrorKind.MISSING_VALUE,
            "Expected missing value error for empty inline value"
        );
    }
}

fn void test_extra_positional_is_rejected() @test
{
    PositionalArg[1] positionals = {
        {
            .name = "name",
            .required = true,
            .allow_multiple = false
        }
    };

    Command command = {
        .name = "test",
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "Samuel", "Alex" };

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Extra positional arguments should be rejected");
    assert(
        error.kind == ParseErrorKind.UNEXPECTED_ARGUMENT,
        "Expected unexpected argument error"
    );
}

fn void test_mixed_positionals_and_flags() @test
{
    Arg[1] args = {
        {
            .name = "verbose",
            .short_name = "v",
            .kind = ArgKind.FLAG
        }
    };

    PositionalArg[1] positionals = {
        {
            .name = "person",
            .required = true,
            .allow_multiple = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..],
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "Samuel", "--verbose", "Alex" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Mixed positionals and flags should parse");
    assert(matches.has("verbose"), "Verbose flag should be present");

    List{String} people;
    people.init(mem);
    defer people.free();

    matches.get_all("person", &people);

    assert(people.len() == 2, "Both positional values should be stored");
    assert(people[0] == "Samuel", "First positional should be Samuel");
    assert(people[1] == "Alex", "Second positional should be Alex");
}

fn void test_double_dash_allows_dash_prefixed_value() @test
{
    PositionalArg[1] positionals = {
        {
            .name = "file",
            .required = true,
            .allow_multiple = false
        }
    };

    Command command = {
        .name = "test",
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--", "-important-file.txt" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Dash-prefixed positional should be accepted after --");

    String file;
    assert(matches.get("file", &file), "File should be present");
    assert(file == "-important-file.txt", "File value should be preserved");
}

fn void test_double_dash_ends_option_parsing() @test
{
    Arg[1] args = {
        {
            .name = "verbose",
            .short_name = "v",
            .kind = ArgKind.FLAG
        }
    };

    PositionalArg[1] positionals = {
        {
            .name = "value",
            .required = true,
            .allow_multiple = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..],
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--", "--verbose", "-x" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Tokens after -- should be positional values");
    assert(!matches.has("verbose"), "Flag after -- should not be enabled");

    List{String} values;
    values.init(mem);
    defer values.free();

    matches.get_all("value", &values);

    assert(values.len() == 2, "Both values should be stored");
    assert(values[0] == "--verbose", "First value should be preserved");
    assert(values[1] == "-x", "Second value should be preserved");
}

fn void test_double_dash_without_required_value_fails() @test
{
    PositionalArg[1] positionals = {
        {
            .name = "file",
            .required = true,
            .allow_multiple = false
        }
    };

    Command command = {
        .name = "test",
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--" };

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Missing required positional should fail");
    assert(
        error.kind == ParseErrorKind.MISSING_REQUIRED_ARGUMENT,
        "Expected missing required argument error"
    );
}

fn void test_negative_value_is_accepted() @test
{
    Arg[1] args = {
        {
            .name = "count",
            .kind = ArgKind.OPTION
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--count", "-5" };

    bool success = command.parse(argv, &matches, &error);

    assert(success, "Negative values should be accepted");

    String value;
    assert(matches.get("count", &value), "Count should be present");
    assert(value == "-5", "Count should equal -5");
}

fn void test_empty_inline_value_is_rejected() @test
{
    Arg[1] args = {
        {
            .name = "name",
            .kind = ArgKind.OPTION
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){ "--name=" };

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Empty inline values should be rejected");
    assert(
        error.kind == ParseErrorKind.MISSING_VALUE,
        "Empty inline values should report a missing value"
    );
}

fn void test_duplicate_long_argument_name_is_rejected() @test
{
    Arg[2] args = {
        {
            .name = "name",
            .short_name = "n",
            .kind = ArgKind.OPTION
        }
        ,
        {
            .name = "name",
            .short_name = "N",
            .kind = ArgKind.FLAG
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Duplicate long names should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}

fn void test_duplicate_short_argument_name_is_rejected() @test
{
    Arg[2] args = {
        {
            .name = "name",
            .short_name = "x",
            .kind = ArgKind.OPTION
        }
        ,
        {
            .name = "verbose",
            .short_name = "x",
            .kind = ArgKind.FLAG
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Duplicate short names should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}

fn void test_empty_argument_name_is_rejected() @test
{
    Arg[1] args = {
        {
            .name = "",
            .kind = ArgKind.OPTION
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Empty argument names should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}

fn void test_duplicate_sibling_subcommands_are_rejected() @test
{
    Command[2] subcommands = {
        {
            .name = "get"
        }
        ,
        {
            .name = "get"
        }
    };

    Command root = {
        .name = "config",
        .subcommands = subcommands[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = root.parse(argv, &matches, &error);

    assert(!success, "Duplicate sibling subcommands should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error for duplicate subcommands"
    );
}

fn void test_invalid_definition_in_nested_subcommand_is_rejected() @test
{
    Arg[1] invalid_args = {
        {
            .name = "",
            .kind = ArgKind.OPTION
        }
    };

    Command[1] subcommands = {
        {
            .name = "get",
            .args = invalid_args[0..]
        }
    };

    Command root = {
        .name = "config",
        .subcommands = subcommands[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = root.parse(argv, &matches, &error);

    assert(!success, "Invalid nested definitions should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error from nested command"
    );
}

fn void test_empty_positional_name_is_rejected() @test
{
    PositionalArg[1] positionals = {
        {
            .name = "",
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Empty positional names should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}

fn void test_duplicate_positional_names_are_rejected() @test
{
    PositionalArg[2] positionals = {
        {
            .name = "file",
            .required = true
        }
        ,
        {
            .name = "file",
            .required = false
        }
    };

    Command command = {
        .name = "test",
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Duplicate positional names should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}

fn void test_positional_option_name_conflict_is_rejected() @test
{
    Arg[1] args = {
        {
            .name = "file",
            .kind = ArgKind.OPTION
        }
    };

    PositionalArg[1] positionals = {
        {
            .name = "file",
            .required = true
        }
    };

    Command command = {
        .name = "test",
        .args = args[0..],
        .positionals = positionals[0..]
    };

    Matches matches;
    matches.init();
    defer matches.deinit();

    ParseError error;
    String[] argv = (String[]){};

    bool success = command.parse(argv, &matches, &error);

    assert(!success, "Positional/option name conflicts should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Expected invalid definition error"
    );
}


fn void test_get_all_appends_to_existing_values() @test
{
    Matches matches;
    matches.init();
    defer matches.deinit();

    matches.add_option("name", "Samuel");
    matches.add_option("name", "Alex");

    List{String} names;
    names.init(mem);
    defer names.free();

    names.push("Existing");

    matches.get_all("name", &names);

    assert(names.len() == 3, "Existing value and both matches should remain");
    assert(names[0] == "Existing", "Existing value should be preserved");
    assert(names[1] == "Samuel", "First matching value should be appended");
    assert(names[2] == "Alex", "Second matching value should be appended");
}

fn void test_get_all_for_missing_name_adds_nothing() @test
{
    Matches matches;
    matches.init();
    defer matches.deinit();

    List{String} values;
    values.init(mem);
    defer values.free();

    values.push("Existing");

    matches.get_all("missing", &values);

    assert(values.len() == 1, "Missing name should add no values");
    assert(values[0] == "Existing", "Existing value should remain unchanged");
}

fn void test_get_flag_for_missing_name_sets_false() @test
{
    Matches matches;
    matches.init();
    defer matches.deinit();

    bool value = true;

    bool found = matches.get_flag("missing", &value);

    assert(!found, "Missing flag should return false");
    assert(!value, "Missing flag should set output to false");
}

fn void test_duplicate_short_names_are_rejected() @test
{
    Command command = {
        .name = "test",
        .args = {
            {
                .name = "name",
                .short_name = "n",
                .kind = ArgKind.OPTION,
            },
            {
                .name = "number",
                .short_name = "n",
                .kind = ArgKind.OPTION,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Duplicate short names should be rejected");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Duplicate short names should produce an invalid-definition error"
    );
}

fn void test_long_only_arguments_can_share_empty_short_names() @test
{
    Command command = {
        .name = "test",
        .args = {
            {
                .name = "name",
                .kind = ArgKind.OPTION,
            },
            {
                .name = "number",
                .kind = ArgKind.OPTION,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(valid, "Long-only arguments should allow empty short names");
}

fn void test_positional_name_conflicting_with_short_name_is_rejected() @test
{
    Command command = {
        .name = "test",
        .args = {
            {
                .name = "output",
                .short_name = "o",
                .kind = ArgKind.OPTION,
            },
        },
        .positionals = {
            {
                .name = "o",
                .required = true,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Positional name must not conflict with a short option name");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Conflict should produce an invalid-definition error"
    );
}

fn void test_multiple_long_only_arguments_are_valid() @test
{
    Command command = {
        .name = "test",
        .args = {
            {
                .name = "output",
                .kind = ArgKind.OPTION,
            },
            {
                .name = "verbose",
                .kind = ArgKind.FLAG,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(valid, "Multiple long-only arguments should be valid");
}


fn void test_long_argument_name_starting_with_dash_is_rejected() @test
{
    Command command = {
        .name = "test",
        .args = {
            {
                .name = "-output",
                .kind = ArgKind.OPTION,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Long argument names must not start with a dash");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Invalid names should produce an invalid-definition error"
    );
}

fn void test_long_argument_name_containing_equals_is_rejected() @test
{
    Command command = {
        .name = "test",
        .args = {
            {
                .name = "out=put",
                .kind = ArgKind.OPTION,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Long argument names must not contain equals");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Invalid names should produce an invalid-definition error"
    );
}

fn void test_short_name_longer_than_one_character_is_rejected() @test
{
    Command command = {
        .name = "test",
        .args = {
            {
                .name = "output",
                .short_name = "out",
                .kind = ArgKind.OPTION,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Short names must contain exactly one character");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Invalid short names should produce an invalid-definition error"
    );
}

fn void test_positional_name_starting_with_dash_is_rejected() @test
{
    Command command = {
        .name = "test",
        .positionals = {
            {
                .name = "--file",
                .required = true,
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Positional names must not start with a dash");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Invalid names should produce an invalid-definition error"
    );
}


fn void test_subcommand_name_starting_with_dash_is_rejected() @test
{
    Command command = {
        .name = "test",
        .subcommands = {
            {
                .name = "-invalid",
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Subcommand names must not start with a dash");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Invalid subcommand names should produce an invalid-definition error"
    );
}

fn void test_subcommand_name_containing_equals_is_rejected() @test
{
    Command command = {
        .name = "test",
        .subcommands = {
            {
                .name = "invalid=name",
            },
        },
    };

    ParseError error;
    bool valid = command.validate(&error);

    assert(!valid, "Subcommand names must not contain equals signs");
    assert(
        error.kind == ParseErrorKind.INVALID_DEFINITION,
        "Invalid subcommand names should produce an invalid-definition error"
    );
}

