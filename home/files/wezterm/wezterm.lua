local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 13.0

-- Theme
config.color_scheme = "rose-pine-moon"

-- Frameless / transparent window
config.window_decorations = "NONE"
config.window_background_opacity = 0.92
config.text_background_opacity = 1.0

-- Hide tab bar when only one tab is open
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

config.scrollback_lines = 10000

-- Padding
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

return config
