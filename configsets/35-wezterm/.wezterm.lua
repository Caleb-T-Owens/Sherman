-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'Github'

config.font_size = 22

config.font = wezterm.font('CommitMonoDotted', { weight = 400 })

-- Disable ligatures
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

config.native_macos_fullscreen_mode = true

-- and finally, return the configuration to wezterm
return config
