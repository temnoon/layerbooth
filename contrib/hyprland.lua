-- Layerbooth for Omarchy's Hyprland Lua config.
-- Chromium derives the app id from the URL path; Hyprland regexes must match the whole class.
-- Put in ~/.config/hypr/hyprland.lua:
o.window("^chrome-127\\.0\\.0\\.1__layerbooth.*$", { float = true, size = { 1280, 780 }, center = true, tag = "-default-opacity", opacity = "1 1" })

-- Put in ~/.config/hypr/autostart.lua to re-apply the preset starred for login:
-- o.launch_on_start("layerbooth --apply")
