-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
local dpi       = require("beautiful.xresources").apply_dpi
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
require("quitmenu")
require("app_drawer")
local running = require("running")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors,
                     font = "Sans 8" })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err),
                         font = "Sans 8" })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
local awesome_config = string.format("%s/.config/awesome/", os.getenv("HOME"))
local icons = awesome_config .. "icons/"

-- Themes define colours, icons, font and wallpapers.
local themes = {
    "default",		-- 1
}

local chosen_theme = themes[1]

local themes_folder = awesome_config .. "themes/"
beautiful.init(themes_folder .. chosen_theme .. "/theme.lua")


-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.max,
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max.fullscreen,
}
-- }}}

terminal = "xterm"

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Print ToDo using nauthy.notify
local function notify_todo(s)
    naughty.notify({ preset = naughty.config.presets.normal,
        title = "ToDo",
        text = s,
        font = "Sans 16" })
end

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock()

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- app_drawer
local app_drawer_icon = wibox.widget.imagebox(icons .. "launch.png")
app_drawer_icon:connect_signal("button::press", function ()
    -- open app_drawer
    app_drawer_show()
end)

-- running_apps
local running_apps_icon = wibox.widget.imagebox(icons .. "running.png")
running_apps_icon:connect_signal("button::press", function ()
    -- show running apps
    running.show()
end)

-- close app button
local close_app_button = awful.widget.tasklist {
    screen   = screen[1],
    filter   = awful.widget.tasklist.filter.focused,
    buttons  = awful.util.table.join(
        awful.button({ }, 1, function (c)
            -- close client
            c:kill()
        end)),
    style    = {
        shape_border_width = 1,
        shape_border_color = '#777777',
        shape  = gears.shape.rounded_bar,
    },
    layout   = {
        spacing = 10,
        spacing_widget = {
            {
                forced_width = 5,
                shape        = gears.shape.circle,
                widget       = wibox.widget.separator
            },
            valign = 'center',
            halign = 'center',
            widget = wibox.container.place,
        },
        layout  = wibox.layout.flex.horizontal
    },
    -- Notice that there is *NO* wibox.wibox prefix, it is a template,
    -- not a widget instance.
    widget_template = {
        widget = wibox.widget.imagebox,
        image   = icons .. "close_app.png",
    },
}

local audio_slider_widget = wibox.widget {
    bar_shape           = gears.shape.rounded_rect,
    bar_height          = dpi(3),
    bar_color           = '#A0A0A0',
    handle_color        = '#A0A0A0',
    handle_shape        = gears.shape.circle,
    handle_border_color = beautiful.border_color,
    handle_border_width = dpi(1),
    widget              = wibox.widget.slider,
    forced_width        = dpi(350),
    forced_height       = dpi(20),
}

-- ToDo get current volume
-- audio_slider_widget.value = --curent volume
local get_volume_command = "amixer get 'Master'"
awful.spawn.easy_async(get_volume_command, function(stdout, stderr, reason, exit_code)
    local volume = stdout:match("%[(%d+)%%%]")
    audio_slider_widget.value = tonumber(volume)
end)

local volume_down_button = wibox.widget.imagebox(icons .. "minus.png")
volume_down_button:connect_signal("button::press", function()
    audio_slider_widget.value = audio_slider_widget.value - 10
end)
local volume_up_button = wibox.widget.imagebox(icons .. "plus.png")
volume_up_button:connect_signal("button::press", function()
    audio_slider_widget.value = audio_slider_widget.value + 10
end)

local minus_container = wibox.container.margin()
minus_container.widget = volume_down_button
minus_container.margins = dpi(20)


local plus_container = wibox.container.margin()
plus_container.widget = volume_up_button
plus_container.margins = dpi(20)

local audio_control_widget = wibox.widget {
    layout = wibox.layout.fixed.horizontal,
    minus_container,
    audio_slider_widget,
    plus_container,
}

local audio_popup = awful.popup {
    widget          = audio_control_widget,
    border_color    = '#303030',
    border_width    = dpi(7),
    preferred_positions = 'top',
--    preferred_anchors   = 'middle',
    shape           = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, dpi(45))
    end,
    visible         = false,
    maximum_height  = dpi(120),
    bg              = '#DFDFDF',
    ontop           = true,
}

audio_slider_widget:connect_signal("widget::redraw_needed", function()
    -- called when slider value changes
    local set_volume_cmd = "amixer set 'Master' " .. tostring(audio_slider_widget.value) .. "%"
    awful.spawn.with_shell(set_volume_cmd)
end)

-- audio_control
local audio_control_icon = wibox.widget.imagebox(icons .. "audio.png")
audio_control_icon:connect_signal("button::press", function()
    -- open audio control
    if audio_popup.visible then
        audio_popup.visible = false
    else
        audio_popup:move_next_to(mouse.current_widget_geometry)
        audio_popup.visible = true
    end
end)

-- power_menu
local power_menu_icon = wibox.widget.imagebox(icons .. "poweroff.png")
power_menu_icon:connect_signal("button::press", function()
    -- open power menu
    exit_screen_show()
end)

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local sep = wibox.widget {
    widget      = wibox.widget.separator,
    opacity     = 1,
    orientation = "vertical",
    border_width    = 0,
    border_color    = '#FFFFFF',
    forced_width    = dpi(24),
}

local space = wibox.widget.textbox(" ")

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "bottom", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        expand = "none",
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            space,
	        app_drawer_icon,
            sep,
            running_apps_icon,
        },
    	{ -- Middle widget
            -- Add buttons for HOME/BACK/APPs, etc
            mytextclock,
            layout = wibox.layout.fixed.horizontal,
        },
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            close_app_button,
            sep,
            wibox.widget.systray(),
            sep,
            audio_control_icon,
            sep,
	        power_menu_icon,
        },
    }
end)
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),

    -- Standard program
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",
        function (c)
            c.fullscreen = not c.fullscreen
            c:raise()
        end,
        {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
              {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
              {description = "toggle floating", group = "client"})
)

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- }}}
