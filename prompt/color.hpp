/**
 * @file color.hpp
 * @brief Output-related coloring with ANSI escape sequences.
 */

#ifndef COLOR_HPP_INCLUDED
#define COLOR_HPP_INCLUDED

#include <stdexcept>

namespace Color
{
    enum ID
    {
        BLACK,
        RED,
        GREEN,
        YELLOW,
        BLUE,
        MAGENTA,
        CYAN,
        WHITE,
        DIM,
        END,
    };

    constexpr char const *ansi(ID id)
    {
        switch (id)
        {
        case BLACK:
            return "\x1b[30m";
        case RED:
            return "\x1b[31m";
        case GREEN:
            return "\x1b[32m";
        case YELLOW:
            return "\x1b[33m";
        case BLUE:
            return "\x1b[34m";
        case MAGENTA:
            return "\x1b[35m";
        case CYAN:
            return "\x1b[36m";
        case WHITE:
            return "\x1b[37m";
        case DIM:
            return "\x1b[2m";
        case END:
            return "\x1b[0m";
        default:
            throw std::invalid_argument("Invalid color");
        }
    }
}

#endif // COLOR_HPP_INCLUDED
