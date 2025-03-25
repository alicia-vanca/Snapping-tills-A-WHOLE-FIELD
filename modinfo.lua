-- 250324 VanCa: Integrate KeyBind UI by 李皓奇
-- https://github.com/liolok/DST-KeyBind-UI

version = "1.1.9_04"
name = "Snapping tills A WHOLE FIELD v" .. version
description =
    [[Aligns plowing to the grid.

LeftShift + RightClick: Launch auto tilling on a tile.
LeftShift + DoubleRightClick: Launch auto tilling on multi tiles.
Key "L": Toggle snap modes: off / optimized / 4x4 / 3x3 / 2x2 / hexagon.
Key ";": Toggle Intercropping mode: off / intercropping 2-3-4 types of plants per tile.
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

local keyboard = { -- from STRINGS.UI.CONTROLSSCREEN.INPUTS[1] of strings.lua, need to match constants.lua too.
    { 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'Print', 'ScrolLock', 'Pause' },
    { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' },
    { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' },
    { 'Escape', 'Tab', 'CapsLock', 'LShift', 'LCtrl', 'LSuper', 'LAlt' },
    { 'Space', 'RAlt', 'RSuper', 'RCtrl', 'RShift', 'Enter', 'Backspace' },
    { 'BackQuote', 'Tilde', 'Minus', 'Equals', 'LeftBracket', 'RightBracket' },
    { 'Backslash', 'Semicolon', 'Quote', 'Period', 'Slash' }, -- punctuation
    { 'Up', 'Down', 'Left', 'Right', 'Insert', 'Delete', 'Home', 'End', 'PageUp', 'PageDown' }, -- navigation
}
local numpad = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'Period', 'Divide', 'Multiply', 'Minus', 'Plus' }
local mouse = { '\238\132\130', '\238\132\131', '\238\132\132' } -- Middle Mouse Button, Mouse Button 4 and 5
local key_disabled = {description = "Disabled", data = "KEY_DISABLED"}
keys = {key_disabled}
for i = 1, #mouse do
    keys[#keys + 1] = {description = mouse[i], data = mouse[i]}
end
for i = 1, #keyboard do
    for j = 1, #keyboard[i] do
        local key = keyboard[i][j]
        keys[#keys + 1] = {description = key, data = "KEY_" .. key:upper()}
    end
    keys[#keys + 1] = key_disabled
end
for i = 1, #numpad do
    local key = numpad[i]
    keys[#keys + 1] = {description = "Numpad " .. key, data = "KEY_KP_" .. key:upper()}
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
            {description = "On", data = true},
            {description = "Off", data = false}
        },
        default = true
    },
    {
        name = "key_change_snap_mode",
        label = "Toggle snap mode",
        hover = "Key to toggle snap mode",
        options = keys,
        default = "KEY_L"
    },
    {
        -- 250320 VanCa: Add key to change intercropping mode (1/2/3/4 types of plants on 1 tile)
        name = "key_change_intercropping_mode",
        label = "Toggle intercropping mode",
        hover = "Key to toggle intercropping mode",
        options = keys,
        default = "KEY_SEMICOLON"
    }
}
