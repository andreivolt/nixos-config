local wezterm = require 'wezterm'

local config = {
  font = wezterm.font_with_fallback({
    {
      family = "PragmataSevka",
      weight = "Light",
    },
    "Noto Color Emoji",
  }),
  font_rules = {
    {
      italic = true,
      font = wezterm.font_with_fallback({
        {
          family = "PragmataSevka",
          weight = "Light",
          style = "Italic",
        },
      }),
    },
    {
      intensity = "Bold",
      font = wezterm.font_with_fallback({
        {
          family = "PragmataSevka",
          weight = "Regular",
        },
      }),
    },
    {
      italic = true,
      intensity = "Bold",
      font = wezterm.font_with_fallback({
        {
          family = "PragmataSevka",
          weight = "Regular",
          style = "Italic",
        },
      }),
    },
  },
  enable_tab_bar = false,
  cell_width = 0.83,
  line_height = 0.9,
  window_decorations = "NONE",
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  -- disable_default_key_bindings = true,
  window_background_opacity = 0.85,
  font_size = 18,
}

return config
