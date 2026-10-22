module c3args::core;

enum ParseErrorKind
{
    UNKNOWN_OPTION,
    MISSING_VALUE,
    UNEXPECTED_ARGUMENT,
    MISSING_REQUIRED_ARGUMENT,
    DUPLICATE_ARGUMENT,
    INVALID_DEFINITION
}

struct ParseError
{
    ParseErrorKind kind;
    String argument;
}
