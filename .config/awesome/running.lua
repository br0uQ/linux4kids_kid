-- Libraries
local naughty   = require("naughty")
local awful     = require("awful")
local gears     = require("gears")
local wibox     = require("wibox")

-- {{{ Print ToDo using nauthy.notify
local function notify_todo(s)
    naughty.notify({ preset = naughty.config.presets.normal,
        title = "ToDo",
        text = s })
end

local running = {}

local tasklist_buttons = awful.util.table.join(
  awful.button({ }, 1, function (c)
    -- This will also un-minimize the client, if needed
    c:raise()
    c:swap(awful.client.getmaster())
    c.focus = c
  end)
)

local tasklist_widget = awful.widget.tasklist {
    screen  = screen[1],
    filter  = awful.widget.tasklist.filter.allscreen,
    buttons = tasklist_buttons,
    placement = awful.placement.centered,
    style   = {
        shape = gears.shape.rounded_rect,
    },
    layout  = {
        spacing = 5,
        forced_num_rows = 2,
        layout = wibox.layout.grid.horizontal
    },
    widget_template = {
        {
            {
                {
                    id      = 'clienticon',
                    widget  = awful.widget.clienticon,
                },
                {
                    id      = 'clientcontent',
                    widget  = wibox.widget.imagebox,
                    forced_height = 256,
                    forced_width = 256,
                },
                {
                    id      = 'text_role',
                    widget  = wibox.widget.textbox,
                },
                layout = wibox.layout.fixed.vertical,
            },
            margins = 4,
            widget  = wibox.container.margin,
        },
        id              = 'background_role',
        forced_width    = 256,
        forced_height   = 1024,
        widget          = wibox.container.background,
        create_callback = function(self, c, index, objects)
            self:get_children_by_id('clienticon')[1].client = c
        end,
    },
}

local tasklist_layout_widget = wibox.container.place(tasklist_widget, "center", "center")

local popup = awful.popup {
    widget              = tasklist_layout_widget,
    border_color        = '#777777',
    border_width        = 2,
    ontop               = true,
    placement           = awful.placement.maximize,
    shape               = gears.shape.rounded_rect,
    visible             = false,
    hide_on_right_click = true,
    bg                  = '#000000A0'
}

running.show = function()
    -- show running clients
    if popup.visible then
        popup.visible = false
    else
        popup.visible = true
    end
end

return running

--[[
--Backup
local function get_clients()
    local client_names = {}
    for c in awful.client.iterate(function() return true end) do
        table.insert(client_names, c.name)
    end
    return client_names
end
--]]
