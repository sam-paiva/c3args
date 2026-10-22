module c3args::core;

import std::collections::list;

excuse UNKNOWN_OPTION, MISSING_VALUE, UNEXPECTED_ARGUMENT;

struct MatchEntry
{
    String name;
    String value;
    bool is_flag;
}

alias MatchEntryList = List{MatchEntry};

struct Matches
{
    MatchEntryList entries;
    bool help_requested;
}

fn bool Matches.has(Matches* matches, String name)
{
    foreach (entry : matches.entries)
    {
        if (entry.name == name)
        {
            return true;
        }
    }

    return false;
}

fn bool Matches.get(Matches* matches, String name, String* out_value)
{
    foreach (entry : matches.entries)
    {
        if (entry.name == name && !entry.is_flag)
        {
            *out_value = entry.value;
            return true;
        }
    }

    return false;
}

fn void Matches.add_flag(Matches* matches, String name)
{

    matches.entries.push(
        {
            .name = name,
            .value = "true",
            .is_flag = true
        }
    );
}

fn void Matches.add_option(Matches* matches, String name, String value)
{
    matches.entries.push(
        {
            .name = name,
            .value = value,
            .is_flag = false,
        }
    );
}

fn bool Matches.get_bool(Matches* matches, String name, bool* value)
{
    foreach (entry : matches.entries)
    {
        if (entry.name == name && entry.is_flag)
        {
            *value = true;
            return true;
        }
    }

    * value = false;
    return false;
}

fn void Matches.get_all(Matches* matches, String name, List{String} * values)
{
    foreach (entry : matches.entries)
    {
        if (entry.name == name && !entry.is_flag)
        {
            values.push(entry.value);
        }
    }
}
