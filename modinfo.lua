version = "1.1.9_02"
name = "Snapping tills A WHOLE FIELD v" .. version
description =
    [[Aligns plowing to the grid.

LeftShift + RightClick: Launch auto tilling on a tile.
LeftShift + DoubleRightClick: Launch auto tilling on multi tiles.
Key "L": Toggle snap modes: off / optimized / 4x4 / 3x3 / 2x2 / hexagon.
Optimized mode checks for an adjacent soil tile, if not found adjacent soil tile then uses 4x4 else uses 3x3. You can bind key in configure mod.

Important:
    "Geometric Placement" has priority, so that to use this mod,
    "Geometric Placement" must be OFF in game (key B -> "off")
    or disabled "snap till" in options (key B -> disable "snap till")

Сontroller support (auto swich tiles hasn't been tested)
Compatible with Geometric Placement
Compatible with ActionQueue Reborn (ActionQueue RB2/RB3)
]]
author = "surg | modified by VanCa"
api_version_dst = 10
priority = -101 -- -101 for compatible with "No Release Deployables v2" mod
icon_atlas = "modicon.xml"
icon = "modicon.tex"
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true

local key_list = {
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "0",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "F1",
    "F2",
    "F3",
    "F4",
    "F5",
    "F6",
    "F7",
    "F8",
    "F9",
    "F10",
    "F11",
    "F12",
    "TAB",
    "CAPSLOCK",
    "LSHIFT",
    "RSHIFT",
    "LCTRL",
    "RCTRL",
    "LALT",
    "RALT",
    "ALT",
    "CTRL",
    "SHIFT",
    "SPACE",
    "ENTER",
    "ESCAPE",
    "MINUS",
    "EQUALS",
    "BACKSPACE",
    "PERIOD",
    "SLASH",
    "SEMICOLON",
    "LEFTBRACKET",
    "BACKSLASH",
    "RIGHTBRACKET",
    "TILDE",
    "PRINT",
    "SCROLLOCK",
    "PAUSE",
    "INSERT",
    "HOME",
    "DELETE",
    "END",
    "PAGEUP",
    "PAGEDOWN",
    "UP",
    "DOWN",
    "LEFT",
    "RIGHT",
    "KP_DIVIDE",
    "KP_MULTIPLY",
    "KP_PLUS",
    "KP_MINUS",
    "KP_ENTER",
    "KP_PERIOD",
    "KP_EQUALS"
}
local key_options = {}

for i = 1, #key_list do
    key_options[i] = {description = key_list[i], data = "KEY_" .. key_list[i]}
end

configuration_options = {
    {
        name = "language",
        label = "Language",
        hover = "Default language.",
        options = {
            {description = "Auto detect", data = "auto", hover = "Auto detect"},
            {description = "English", data = "en", hover = "English"},
            {description = "Español", data = "esp", hover = "Español"},
            {description = "简体中文", data = "sch", hover = "Simplified Chinese"},
            {description = "Русский", data = "ru", hover = "Russian"}
        },
        default = "auto"
    },
    {
        name = "visiblesnaps",
        label = "Visible snaps",
        hover = "Visible snaps",
        options = {
            {description = "on", data = true},
            {description = "off", data = false}
        },
        default = true
    },
    {
        name = "keychagemode",
        label = "Toggle snap mode",
        hover = "Key to toggle snap mode",
        options = key_options,
        default = "KEY_L"
    },
    {
        -- 250320 VanCa: Add key to change intercropping mode (1/2/3/4 types of plants on 1 tile)
        name = "key_chage_intercropping_mode",
        label = "Toggle intercropping mode",
        hover = "Key to toggle intercropping mode",
        options = key_options,
        default = "KEY_SEMICOLON"
    }
}
