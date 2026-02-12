local ov = mp.create_osd_overlay("ass-events")
local timer = nil
local frame = 1
local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

local function show()
    ov.data = string.format(
        "{\\an5\\fs120\\bord0\\1c&HFFFFFF&\\alpha&H40}%s",
        spinner[frame]
    )
    ov:update()
    frame = frame % #spinner + 1
end

local function start()
    if not timer then
        frame = 1
        show()
        timer = mp.add_periodic_timer(0.08, show)
    end
end

local function stop()
    if timer then
        timer:kill()
        timer = nil
        ov:remove()
    end
end

local function update()
    local idle = mp.get_property_bool("core-idle", false)
    local paused = mp.get_property_bool("pause", false)
    local eof = mp.get_property_bool("eof-reached", false)
    local vid = mp.get_property("vid")
    if idle and not paused and not eof and vid ~= "no" then
        start()
    else
        stop()
    end
end

mp.observe_property("core-idle", "bool", update)
mp.observe_property("pause", "bool", update)
mp.observe_property("eof-reached", "bool", update)
mp.observe_property("vid", "string", update)
