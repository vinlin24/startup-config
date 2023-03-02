/**
 * @file strings.hpp
 * @brief TODO.
 */

#ifndef STRINGS_HPP_INCLUDED
#define STRINGS_HPP_INCLUDED

#include <optional>
#include <string>

inline bool
startsWith(std::string const &string, std::string const &prefix)
{
    std::size_t pos = string.rfind(prefix, 0);
    return pos == 0;
}

inline std::optional<std::string>
substringAfter(std::string const &string, std::string const &prefix)
{
    std::size_t pos = string.find(prefix);
    if (pos != std::string::npos)
        return string.substr(pos + prefix.size());
    return std::nullopt;
}

#endif // STRINGS_HPP_INCLUDED
