-- Reload the current URL when playback stalls due to network loss.
-- If paused-for-cache stays true for >15s, reloads the file.
-- For YouTube, this re-resolves via yt-dlp getting fresh stream URLs.

local stall_start = nil
local STALL_TIMEOUT = 3

mp.observe_property("paused-for-cache", "bool", function(_, paused)
    if paused then
        if not stall_start then
            stall_start = mp.get_time()
        end
    else
        stall_start = nil
    end
end)

mp.add_periodic_timer(1, function()
    if stall_start and (mp.get_time() - stall_start) >= STALL_TIMEOUT then
        local path = mp.get_property("path")
        if path then
            mp.msg.warn("stalled for " .. STALL_TIMEOUT .. "s, reloading")
            mp.commandv("loadfile", path, "replace")
        end
        stall_start = nil
    end
end)
