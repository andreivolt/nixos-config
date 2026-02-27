local utils = require "mp.utils"
local casting = false

local function remote_cmd(json)
    utils.subprocess({
        args = {"ssh", "watts", "socat", "-", "/tmp/mpv-cast-receiver"},
        stdin_data = json .. "\n",
        capture_stdout = true,
        capture_stderr = true,
    })
end

local function enter_cast_mode()
    casting = true
    mp.commandv("set", "pause", "yes")
    mp.osd_message("casting to watts", 3)

    mp.add_forced_key_binding("space", "cast-pause", function()
        remote_cmd('{"command":["cycle","pause"]}')
    end)
    mp.add_forced_key_binding("LEFT", "cast-seek-back", function()
        remote_cmd('{"command":["seek",-5]}')
    end)
    mp.add_forced_key_binding("RIGHT", "cast-seek-fwd", function()
        remote_cmd('{"command":["seek",5]}')
    end)
    mp.add_forced_key_binding("UP", "cast-seek-fwd-big", function()
        remote_cmd('{"command":["seek",60]}')
    end)
    mp.add_forced_key_binding("DOWN", "cast-seek-back-big", function()
        remote_cmd('{"command":["seek",-60]}')
    end)
    mp.add_forced_key_binding("Shift+LEFT", "cast-seek-back-30", function()
        remote_cmd('{"command":["seek",-30]}')
    end)
    mp.add_forced_key_binding("Shift+RIGHT", "cast-seek-fwd-30", function()
        remote_cmd('{"command":["seek",30]}')
    end)
    mp.add_forced_key_binding("m", "cast-mute", function()
        remote_cmd('{"command":["cycle","mute"]}')
    end)
    mp.add_forced_key_binding("9", "cast-vol-down", function()
        remote_cmd('{"command":["add","volume",-2]}')
    end)
    mp.add_forced_key_binding("0", "cast-vol-up", function()
        remote_cmd('{"command":["add","volume",2]}')
    end)
    mp.add_forced_key_binding("f", "cast-fullscreen", function()
        remote_cmd('{"command":["cycle","fullscreen"]}')
    end)
    mp.add_forced_key_binding("[", "cast-speed-down", function()
        remote_cmd('{"command":["multiply","speed",0.9]}')
    end)
    mp.add_forced_key_binding("]", "cast-speed-up", function()
        remote_cmd('{"command":["multiply","speed",1.1]}')
    end)
    mp.add_forced_key_binding("BS", "cast-speed-reset", function()
        remote_cmd('{"command":["set_property","speed",1]}')
    end)
    mp.add_forced_key_binding("q", "cast-quit", function()
        remote_cmd('{"command":["stop"]}')
        mp.command("quit")
    end)
end

-- triggered by uosc button or mpv-cast CLI via script-message
mp.register_script_message("cast-to-watts", function()
    local url = mp.get_property("path")
    local pos = mp.get_property_number("time-pos", 0)
    if not url then
        mp.osd_message("no video to cast", 2)
        return
    end

    mp.osd_message("casting to watts...", 1)

    local json = '{"command":["loadfile","' .. url .. '","replace","-1","start=' .. math.floor(pos) .. '"]}'
    remote_cmd(json)

    enter_cast_mode()
end)

-- also triggered by IPC from mpv-cast CLI
mp.register_script_message("enter-cast-mode", enter_cast_mode)
