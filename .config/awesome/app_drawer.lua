local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require ("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local lfs = require("lfs")
local menubar = require("menubar")

local icons_dir = os.getenv("HOME") .. "/.config/awesome/icons/"
local app_dir = os.getenv("HOME") .. "/.local/share/applications/"

-- Appearance
local icon_size = beautiful.app_drawer_icon_size or dpi(100)
local text_font = beautiful.app_drawer_font or "sans 14"
local apps_title_font = beautiful.app_drawer_apps_title_font or "sans 70"
local cols = 5
local rows = 4

-- Commands
local start_app = function(s)
    awful.spawn.with_shell(s)
end

-- Title
local apps_title_widget = wibox.widget.textbox("Apps")
apps_title_widget.font = apps_title_font

-- {{{ Buttons
local app_list_widget = wibox.widget {
    homogenous      = true,
    spacing         = 30,
    layout          = wibox.layout.grid,
    expand          = "none",
    forced_num_cols = cols,
    forced_num_rows = rows,
}

app_list_widget:set_orientation("vertical")

-- Get file extension
local function get_extension(filename)
    local rev = string.reverse(filename)
    local len = rev:find("%.")
    local rev_ext = rev:sub(1,len)
    return string.reverse(rev_ext)
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function get_app_values(file)
    values = {}
    for line in io.lines(file) do 
        local words = {}
        line = line .. "="
        for w in line:gmatch("(.-)=") do
            table.insert(words, w)
        end
        -- only save value if new and valid
        if #words == 2 and values[words[1]] == nil then
            values[words[1]] = words[2]
        end
    end
    return values
end

local function add_app(file)
    local values = get_app_values(file)
    local icon_path = menubar.utils.lookup_icon(values["Icon"])
    local app_icon = wibox.widget.imagebox(icon_path)
    app_icon.resize = true
    app_icon.forced_width = icon_size
    app_icon.forced_height = icon_size
    local name = wibox.widget.textbox(values["Name"])
    name.font = text_font
    local app = wibox.widget{
        {
            nil,
            app_icon,
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        {
            nil,
            name,
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        layout = wibox.layout.fixed.vertical
    }
    app_list_widget:add(app)
end

-- Get all local desktop files
for file in lfs.dir(app_dir) do
    if file ~= "." and file ~= ".." and get_extension(file) == ".desktop" then
        add_app(app_dir .. file)
    end
end

-- Create Widget
app_drawer = wibox({visible = false, ontop = true, type = "normal"})
awful.placement.maximize(app_drawer)

app_drawer.bg = beautiful.exit_screen_bg or beautiful.wibar_bg or "#222222"
app_drawer.fg = beautiful.exit_screen_fg or beautiful.wibar_fg or "#FEFEFE"

local app_drawer_grabber
function app_drawer_hide()
    awful.keygrabber.stop(app_drawer_grabber)
    app_drawer.visible = false
end

function app_drawer_show()
    app_drawer_grabber = awful.keygrabber.run(function(_, key, event)
        if event == "release" then return end

	if key == 'Escape' then
            app_drawer_hide()
        end
    end)
    app_drawer.visible = true
end

app_drawer:buttons(gears.table.join(
    -- Middle click - Hide app_drawer
    awful.button({ }, 2, function()
        app_drawer_hide()
    end),
    -- Right click - Hide app_drawer
    awful.button({ }, 3, function()
        app_drawer_hide()
    end)
))

app_drawer:setup {
    nil,
    {
        {
            nil,
            app_list_widget,
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
--[[
-- Old app_drawer design
-- 
-- Item placement
app_drawer:setup {
    nil,
    {
        {
            nil,
            apps_title_widget,
            nil,
            expand = "none",
            layout = wibox.layout.align.horizontal
        },
        {
            nil,
            apps_widget,
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
--]]
