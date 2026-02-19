-- enforce minimum pixel size for subtitles and OSD in small windows
-- mpv scales both proportionally to window height (ref 720px), which
-- makes them unreadable in small windows. this clamps them at a floor.

local base_sub_size = mp.get_property_number("sub-font-size", 45)
local base_osd_size = mp.get_property_number("osd-font-size", 55)
local min_px = 30
local ref_height = 720

local function update(_, h)
    if not h or h <= 0 then return end
    local sub_px = base_sub_size * h / ref_height
    local osd_px = base_osd_size * h / ref_height

    if sub_px < min_px then
        mp.set_property_number("sub-font-size", base_sub_size * min_px / sub_px)
    else
        mp.set_property_number("sub-font-size", base_sub_size)
    end

    if osd_px < min_px then
        mp.set_property_number("osd-font-size", base_osd_size * min_px / osd_px)
    else
        mp.set_property_number("osd-font-size", base_osd_size)
    end
end

mp.observe_property("osd-height", "number", update)
