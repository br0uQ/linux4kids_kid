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

local function get_clients()
    local client_names = {}
    for c in awful.client.iterate(function() return true end) do
        table.insert(client_names, c.name)
    end
    return client_names
end

local tasklist_widget = awful.widget.tasklist {
    screen  = screen[1],
    filter  = awful.widget.tasklist.filter.allscreen,
    buttons = tasklist_buttons,
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
                id      = 'clienticon',
                widget  = awful.widget.clienticon,
            },
            margins = 4,
            widget  = wibox.container.margin,
        },
        id              = 'background_role',
        forced_width    = 48,
        forced_height   = 48,
        widget          = wibox.container.background,
        create_callback = function(self, c, index, objects)
            self:get_children_by_id('clienticon')[1].client = c
        end,
    },
}

local popup = awful.popup {
    widget = tasklist_widget,
    border_color    = '#777777',
    border_width    = 2,
    ontop           = true,
    placement       = awful.placement.maximize,
    shape           = gears.shape.rounded_rect,
    visible         = false,
    hide_on_right_click = true,
    bg              = '#000000A0'
}

local popup2 = wibox({
    visible = false,
    ontop = true,
    type = "normal",
})
awful.placement.maximize(popup2)
popup2.widget = tasklist_widget
popup2.bg = '#000000A0'

running.show = function()
    -- show running clients
    notify_todo("show running clients")
    for key,value in ipairs(get_clients()) do
        notify_todo(value)
    end
    if popup.visible then
        popup.visible = false
    else
        popup.visible = true
    end
end

return running
