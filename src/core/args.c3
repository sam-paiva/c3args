module core;

enum ArgKind
{
    FLAG,
    OPTION
}

struct Arg
{
    String name;
    String short_name;
    ArgKind kind;
    bool required;
    bool allow_multiple;
    String description;
}

struct PositionalArg
{
    String name;
    bool required;
    String description;
    bool allow_multiple;
}
