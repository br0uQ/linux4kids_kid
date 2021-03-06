local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require ("beautiful")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi
local lfs = require("lfs")
local menubar = require("menubar")
local naughty = require("naughty")

local icons_dir = os.getenv("HOME") .. "/.config/awesome/icons/"
local app_dir = os.getenv("HOME") .. "/.local/share/applications/"

-- Appearance
local icon_size = beautiful.app_drawer_icon_size or dpi(100)
local text_font = beautiful.app_drawer_font or "sans 14"
local apps_title_font = beautiful.app_drawer_apps_title_font or "sans 70"
local cols = 5
local rows = 4
local page_selector_size = beautiful.page_selector_size or dpi(16)
local page_selectors_height = beautiful.page_selectors_height or dpi(36)
local app_drawer_bg = beautiful.app_drawer_bg or '#000000A0'

-- Title
local apps_title_widget = wibox.widget.textbox("Apps")
apps_title_widget.font = apps_title_font

-- {{{ Buttons
local function create_app_list_page()
    local app_list_widget = wibox.widget {
        homogenous      = true,
        spacing         = 30,
        layout          = wibox.layout.grid,
        expand          = "none",
        forced_num_cols = cols,
        forced_num_rows = rows,
    }

    app_list_widget:set_orientation("vertical")
    
    return app_list_widget
end

local app_list_pages = {}
local app_list_page = create_app_list_page()
table.insert(app_list_pages, app_list_page)
local page_selectors = wibox.widget {
    homogenous      = true,
    spacing         = 8,
    layout          = wibox.layout.fixed.horizontal,
    forced_height   = page_selectors_height,
    expand          = "none",
}
local app_list_widget = wibox.container.background(app_list_pages[1])
local page = 1
local active_page_selector
local active_page = 1
local page_selector_list = {}
local function add_page_selector(index, check)
    local page_selector = wibox.widget {
        checked     = check,
        color       = beautiful.bg_normal,
        paddings    = 2,
        shape       = gears.shape.circle,
        widget      = wibox.widget.checkbox,
        forced_width = page_selector_size,
        forced_height = page_selector_size,
    }
    page_selector:buttons(gears.table.join(
        awful.button({ }, 1, function()
            -- cycle through pages
            app_list_widget.widget = app_list_pages[index]
            active_page_selector.checked = false
            page_selector.checked = true
            active_page_selector = page_selector
            active_page = index
        end)
    ))

    page_selectors:add(page_selector)
    if check then
        active_page_selector = page_selector
    end
    table.insert(page_selector_list, page_selector)
end
add_page_selector(1, true)

local function switch_page()
    page_selector_list[active_page].checked = true
    active_page_selector = page_selector_list[active_page]
    app_list_widget.widget = app_list_pages[active_page]
end

local function select_previous_page()
    page_selector_list[active_page].checked = false
    active_page = active_page - 1
    if active_page <= 0 then
        active_page = #page_selector_list
    end
    switch_page()
end

local function select_next_page()
    page_selector_list[active_page].checked = false
    active_page = active_page + 1
    if active_page > #page_selector_list then
        active_page = 1
    end
    switch_page()
end

-- Get file extension
local function get_extension(filename)
    local rev = string.reverse(filename)
    local len = rev:find("%.")
    local rev_ext = rev:sub(1,len)
    return string.reverse(rev_ext)
end

local app_count = 0


local function add_app(file)
    local program = menubar.utils.parse_desktop_file(file)
    local app_icon = wibox.widget.imagebox(program.icon_path)
    app_icon.resize = true
    app_icon.forced_width = icon_size
    app_icon.forced_height = icon_size
    local name = wibox.widget.textbox(program.Name)
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
    app:buttons(gears.table.join(
        awful.button({ }, 1, function()
            app_drawer_hide()
            awful.spawn.with_shell(program.cmdline)
        end)
    ))
    app_count = app_count + 1
    if app_count > 20 then
        app_list_page = create_app_list_page()
        table.insert(app_list_pages, app_list_page)
        page = page + 1
        add_page_selector(page, false)
        app_count = 1
    end
    app_list_page:add(app)
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

app_drawer.bg = app_drawer_bg
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
    -- Left click - Hide app_drawer
    awful.button({ }, 1, function()
        app_drawer_hide()
    end),
    -- Middle click - Hide app_drawer
    awful.button({ }, 2, function()
        app_drawer_hide()
    end),
    -- Right click - Hide app_drawer
    awful.button({ }, 3, function()
        app_drawer_hide()
    end),
    -- Scroll up - Show previous app drawer page
    awful.button({ }, 4, function()
        select_previous_page()
    end),
    -- Scroll down - Show next app drawer page
    awful.button({ }, 5, function()
        select_next_page()
    end)
))

app_drawer:setup {
    nil,
    {
        nil,
        app_list_widget,
        nil,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    {
        nil,
        page_selectors,
        nil,
        expand = "none",
        layout = wibox.layout.align.horizontal
    },
    expand  = "none",
    layout  = wibox.layout.align.vertical,
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
