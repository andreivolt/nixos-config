local mp = require("mp")

local function open_in_browser()
    local path = mp.get_property("path")
    if not path then
        mp.osd_message("No video loaded")
        return
    end

    local video_id = path:match("youtube%.com/watch%?v=([%w_%-]+)")
        or path:match("youtu%.be/([%w_%-]+)")
        or path:match("youtube%.com/embed/([%w_%-]+)")

    if not video_id then
        mp.osd_message("Not a YouTube video")
        return
    end

    local pos = mp.get_property_number("time-pos")
    local timestamp = math.floor(pos or 0)

    local url = "https://www.youtube.com/watch?v=" .. video_id .. "&t=" .. timestamp .. "s"
    mp.commandv("run", "xdg-open", url)
    mp.command("quit")
end

mp.add_key_binding(nil, "open-in-browser", open_in_browser)
