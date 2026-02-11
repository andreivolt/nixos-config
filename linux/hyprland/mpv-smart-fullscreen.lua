-- Workaround: Hyprland doesn't allow pinned windows to go fullscreen.
-- When mpv tries to fullscreen, its WM request is silently rejected.
-- This script unpins before fullscreening; the auto-pin service re-pins on exit.

local utils = require("mp.utils")
local initialized = false

mp.observe_property("fullscreen", "bool", function(_, fs)
    if not initialized then
        initialized = true
        return
    end
    if not fs then return end

    local result = mp.command_native({
        name = "subprocess",
        args = {"hyprctl", "activewindow", "-j"},
        capture_stdout = true,
    })
    local info = result and utils.parse_json(result.stdout or "")
    if not info or not info.pinned then return end

    mp.command_native({
        name = "subprocess",
        args = {"hyprctl", "dispatch", "pin", "address:" .. info.address},
    })
    mp.command_native({
        name = "subprocess",
        args = {"hyprctl", "dispatch", "fullscreen", "0"},
    })
end)
