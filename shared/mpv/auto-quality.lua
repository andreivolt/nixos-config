-- Auto-quality: Adjusts stream quality based on window size
-- Reloads with position preservation when window is resized

local mp = require 'mp'

local state = {
    current_tier = nil,
    manual_override = false,
    debounce_timer = nil,
    current_url = nil,
    pre_resolve_proc = nil,
    seek_on_load = nil,
    checking_initial = false, -- flag to prevent reload loop
}

-- Quality tiers: window height threshold -> max video height
local tiers = {
    {max_height = 400, quality = 360},
    {max_height = 600, quality = 480},
    {max_height = 900, quality = 720},
    {max_height = 1200, quality = 1080},
    {max_height = 1800, quality = 1440},
    {max_height = math.huge, quality = nil}, -- nil = best available
}

-- Check if path is a stream URL (not local file)
local function is_stream(path)
    if not path then return false end
    return path:match("^https?://") or path:match("^ytdl://")
end

-- Get quality tier index for window height
local function get_tier(height)
    for i, tier in ipairs(tiers) do
        if height < tier.max_height then return i end
    end
    return #tiers
end

-- Get quality label for OSD
local function get_quality_label(tier_idx)
    local quality = tiers[tier_idx] and tiers[tier_idx].quality
    return quality and (quality .. "p") or "best"
end

-- Build ytdl-format string for quality (preserves H.264 codec preference)
local function build_format(quality)
    if quality then
        return string.format("bestvideo[height<=?%d][vcodec^=avc]+bestaudio/best", quality)
    else
        return "bestvideo[vcodec^=avc]+bestaudio/best"
    end
end

-- Check if current video height matches or is below tier limit
local function video_matches_tier(tier_idx)
    local video_height = mp.get_property_number("height")
    if not video_height then return true end -- can't check, assume ok

    local tier_quality = tiers[tier_idx].quality
    if not tier_quality then return true end -- "best" tier, any height is fine

    -- Video should be at or below the tier limit
    return video_height <= tier_quality
end

-- Pre-resolve URL with yt-dlp in background to warm cache
local function pre_resolve(url, format, callback)
    local args = {"yt-dlp", "-g", "-f", format, "--", url}
    state.pre_resolve_proc = mp.command_native_async({
        name = "subprocess",
        args = args,
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, result)
        state.pre_resolve_proc = nil
        if callback then callback(success) end
    end)
end

-- Reload stream with new quality, preserving position
local function reload_with_quality(tier_idx, silent)
    if not state.current_url then return end

    local quality = tiers[tier_idx].quality
    local format = build_format(quality)
    local pos = mp.get_property_number("time-pos") or 0
    local url = state.current_url
    local old_label = state.current_tier and get_quality_label(state.current_tier) or "?"
    local new_label = get_quality_label(tier_idx)

    local reloaded = false
    local function do_reload()
        if reloaded then return end
        reloaded = true

        state.seek_on_load = pos
        state.checking_initial = true -- prevent re-check after this reload

        mp.set_property("ytdl-format", format)
        mp.commandv("loadfile", url, "replace")
        if not silent then
            mp.osd_message("Auto quality: " .. old_label .. " -> " .. new_label, 2)
        end
    end

    -- Try pre-resolve first for faster reload
    pre_resolve(url, format, function(success)
        do_reload()
    end)

    -- Timeout: reload anyway after 2s if pre-resolve hangs
    mp.add_timeout(2, function()
        if state.pre_resolve_proc then
            mp.abort_async_command(state.pre_resolve_proc)
        end
        do_reload()
    end)
end

-- Debounced resize handler
local function on_resize(_, height)
    if not height or height <= 0 then return end
    if not state.current_url then return end
    if not is_stream(state.current_url) then return end
    if state.manual_override then return end

    local new_tier = get_tier(height)
    if new_tier == state.current_tier then return end

    -- Cancel pending timer
    if state.debounce_timer then
        state.debounce_timer:kill()
        state.debounce_timer = nil
    end

    -- Debounce: wait 800ms after resize stops
    state.debounce_timer = mp.add_timeout(0.8, function()
        state.debounce_timer = nil
        state.current_tier = new_tier
        reload_with_quality(new_tier)
    end)
end

-- Handle file loaded event
local function on_file_loaded()
    local path = mp.get_property("path")
    state.current_url = path
    state.manual_override = false

    -- Seek to saved position if this is a quality reload
    if state.seek_on_load then
        mp.set_property_number("time-pos", state.seek_on_load)
        state.seek_on_load = nil
    end

    -- Skip quality check if this load was triggered by us
    if state.checking_initial then
        state.checking_initial = false
        mp.msg.info("Auto quality: skipping check (reload in progress)")
        return
    end

    -- Check if stream quality matches window size
    if is_stream(path) then
        local osd_height = mp.get_property_number("osd-height")
        local video_height = mp.get_property_number("height")
        mp.msg.info("Auto quality: osd-height=" .. tostring(osd_height) .. " video-height=" .. tostring(video_height))

        if osd_height and osd_height > 0 then
            local desired_tier = get_tier(osd_height)
            local desired_quality = tiers[desired_tier].quality
            state.current_tier = desired_tier

            mp.msg.info("Auto quality: desired tier=" .. desired_tier .. " (" .. get_quality_label(desired_tier) .. "), video=" .. tostring(video_height))

            -- If video is higher quality than needed, reload with correct quality
            if not video_matches_tier(desired_tier) then
                mp.msg.info("Auto quality: video too high, reloading for " .. get_quality_label(desired_tier))
                reload_with_quality(desired_tier, true)
            else
                mp.msg.info("Auto quality: video matches tier, no reload needed")
            end
        else
            mp.msg.info("Auto quality: no osd-height available")
        end
    else
        mp.msg.info("Auto quality: not a stream, skipping")
    end
end

-- Monitor window height for resize
mp.observe_property("osd-height", "number", on_resize)

-- Track file changes
mp.register_event("file-loaded", on_file_loaded)

-- Detect manual quality selection from quality-menu
mp.register_script_message("video-format-set", function()
    state.manual_override = true
    mp.osd_message("Auto quality: disabled (manual)", 2)
end)
