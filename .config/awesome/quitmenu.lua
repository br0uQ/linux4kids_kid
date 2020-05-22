local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require ("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local icons_dir = os.getenv("HOME") .. "/.config/awesome/icons/"

-- Appearance
local icon_size = beautiful.exit_screen_icon_size or dpi(120)
local text_font = beautiful.exit_screen_font or "sans 14"
local goodbye_font = beautiful.exit_screen_goodbye_font or "sans 70"

-- Commands
local poweroff_command = function()
    awful.spawn.with_shell("systemctl poweroff")
end
local reboot_command = function()
    awful.spawn.with_shell("systemctl reboot")
end
local suspend_command = function()
    awful.spawn.with_shell("systemctl suspend")
end
local cancel_command = function()
    exit_screen_hide()
end

local username = os.getenv("USER")
-- Capitalize username
local goodbye_widget = wibox.widget.textbox("Goodbye " .. username:sub(1,1):upper()..username:sub(2))
goodbye_widget.font = goodbye_font

-- {{{ Buttons
-- Poweroff
local poweroff_icon = wibox.widget.imagebox(beautiful.exit_screen_poweroff_icon or icons_dir .. "poweroff_white.png")
poweroff_icon.resize = true
poweroff_icon.forced_width = icon_size
poweroff_icon.forced_height = icon_size
local poweroff_text = wibox.widget.textbox("Poweroff")
poweroff_text.font = text_font
local poweroff = wibox.widget{
    {
        nil,
        poweroff_icon,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    {
        nil,
        poweroff_text,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    layout = wibox.layout.fixed.vertical
}
poweroff:buttons(gears.table.join(
    awful.button({ }, 1, function()
        poweroff_command()
    end)
))
-- Reboot
local reboot_icon = wibox.widget.imagebox(beautiful.exit_screen_reboot_icon or icons_dir .. "reboot_white.png")
reboot_icon.resize = true
reboot_icon.forced_width = icon_size
reboot_icon.forced_height = icon_size
local reboot_text = wibox.widget.textbox("Reboot")
reboot_text.font = text_font
local reboot = wibox.widget{
    {
        nil,
        reboot_icon,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    {
        nil,
        reboot_text,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    layout = wibox.layout.fixed.vertical
}
reboot:buttons(gears.table.join(
    awful.button({ }, 1, function()
        reboot_command()
    end)
))
-- Suspend
local suspend_icon = wibox.widget.imagebox(beautiful.exit_screen_suspend_icon or icons_dir .. "suspend_white.svg")
suspend_icon.resize = true
suspend_icon.forced_width = icon_size
suspend_icon.forced_height = icon_size
local suspend_text = wibox.widget.textbox("Suspend")
suspend_text.font = text_font
local suspend = wibox.widget{
    {
        nil,
        suspend_icon,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    {
        nil,
        suspend_text,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    layout = wibox.layout.fixed.vertical
}
suspend:buttons(gears.table.join(
    awful.button({ }, 1, function()
        suspend_command()
    end)
))
-- Cancel
local cancel_icon = wibox.widget.imagebox(beautiful.exit_screen_cancel_icon or icons_dir .. "cancel_white.png")
cancel_icon.resize = true
cancel_icon.forced_width = icon_size
cancel_icon.forced_height = icon_size
local cancel_text = wibox.widget.textbox("Cancel")
cancel_text.font = text_font
local cancel = wibox.widget{
    {
        nil,
        cancel_icon,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    {
        nil,
        cancel_text,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    layout = wibox.layout.fixed.vertical
}
cancel:buttons(gears.table.join(
    awful.button({ }, 1, function()
        cancel_command()
    end)
))

-- Create Widget
exit_screen = wibox({visible = false, ontop = true, type = "dock"})
awful.placement.maximize(exit_screen)

exit_screen.bg = beautiful.exit_screen_bg or beautiful.wibar_bg or "#444444"
exit_screen.fg = beautiful.exit_screen_fg or beautiful.wibar_fg or "#FEFEFE"

local exit_screen_grabber
function exit_screen_hide()
    awful.keygrabber.stop(exit_screen_grabber)
    exit_screen.visible = false
end

function exit_screen_show()
    exit_screen_grabber = awful.keygrabber.run(function(_, key, event)
        if event == "release" then return end

	if key == 'Escape' then
            exit_screen_hide()
        end
    end)
    exit_screen.visible = true
end

exit_screen:buttons(gears.table.join(
    -- Middle click - Hide exit_screen
    awful.button({ }, 2, function()
        exit_screen_hide()
    end),
    -- Right click - Hide exit_screen
    awful.button({ }, 3, function()
        exit_screen_hide()
    end)
))

-- Item placement
exit_screen:setup {
    nil,
    {
        {
            nil,
            goodbye_widget,
            nil,
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        {
            nil,
            {
                poweroff,
                reboot,
                suspend,
                cancel,
                spacing = dpi(20),
                layout = wibox.layout.fixed.horizontal
            },
            nil,
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        layout = wibox.layout.fixed.vertical
    },
    nil,
    expand = "none",
    layout = wibox.layout.align.vertical
}
