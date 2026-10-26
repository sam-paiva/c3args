# c3args

A lightweight, reusable command-line argument parser for [C3](https://c3-lang.org/), inspired by Rust's [`clap`](https://docs.rs/clap/latest/clap/).

`c3args` provides a structured way to define command-line interfaces, parse arguments, validate command definitions, and handle nested subcommands.

> **Status:** Early development — API and distribution setup may change.

## Features

- **Flags and options** — support long names (`--verbose`) and short aliases (`-v`).
- **Inline values** — accept `--name=Maria` and `-n=Maria`.
- **Positional arguments** — define required, optional, and variadic positional arguments.
- **Required argument validation** — report missing required options and positionals.
- **Repeated arguments** — explicitly configure whether options or positionals can accept multiple values.
- **Nested subcommands** — build command hierarchies such as `config get` and `config set`.
- **Help handling** — support `--help` and `-h`.
- **End-of-options marker** — use `--` to treat subsequent tokens as positional values, including tokens beginning with `-`.
- **Negative numeric values** — allow negative numbers as option values.
- **Duplicate detection** — reject duplicate option definitions and repeated option occurrences when repetition isn't enabled; repeated flags are idempotent.
- **Definition validation** — detect invalid names, duplicate aliases, conflicting positional definitions, and invalid command hierarchies.
- **Test coverage** — automated tests for parsing, validation, repeated arguments, and nested command behavior.

## Core API

The main API is in the `c3args::core` module.

| Type | Responsibility |
|---|---|
| `Arg` | Defines a flag or option, including its names, required status, and repetition behavior. |
| `PositionalArg` | Defines a positional argument and whether it is required or variadic. |
| `Command` | Defines arguments, positionals, nested subcommands, and a command handler. |
| `Cli` | Represents the CLI, parses arguments, tracks the selected command, and dispatches execution. |
| `Matches` | Stores parsed argument values and provides accessors for retrieving them. |
| `ParseError` | Represents parsing and command-definition errors. |

## Supported argument syntax

| Syntax | Meaning |
|---|---|
| `--verbose` | Long flag |
| `-v` | Short flag |
| `--name Samuel` | Long option with a separate value |
| `-n Samuel` | Short option with a separate value |
| `--name=Samuel` | Long option with an inline value |
| `-n=Samuel` | Short option with an inline value |
| `tool input.txt` | Positional argument |
| `tool file1.txt file2.txt` | Variadic positional arguments, when configured |
| `tool -- -filename.txt` | Treat subsequent tokens as positional values |
| `tool config get` | Nested subcommand |

## Development

### Requirements

- [C3 compiler](https://c3-lang.org/) — developed with C3 compiler `0.8.5_1`.

### Build

From the project root:

```bash
c3c build
```

### Run tests

```bash
c3c test
```

The test suite covers argument parsing, required values, positional arguments, repeated values, option termination, help handling, and command-definition validation.

## Project structure

```text
c3args/
├── project.json
├── src/
│   └── c3args/
│       └── core/
├── test/
├── lib/
└── README.md
```

The source tree contains the implementation, `test/` contains automated tests, and `lib/` is configured as a dependency search directory.

## Contributing

Contributions, bug reports, and suggestions are welcome. Please include tests for changes to parser behavior or command-definition validation.

## License

A license has not yet been specified. Licensing information will be added before the first public release.
