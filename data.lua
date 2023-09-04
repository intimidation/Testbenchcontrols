local ICONPATH = "__button__/"
local custom_sprites = {
    {
        type = "sprite",
        name = "auto_button_sprite",
        filename = ICONPATH .. "auto.png",
        width = 28,
        height = 27,
    },
    {
        type = "sprite",
        name = "manual_button_sprite",
        filename = ICONPATH .. "manual.png",
        width = 27,
        height = 26,
    },
    {
        type = "sprite",
        name = "reset_button_sprite",
        filename = ICONPATH .. "reset.png",
        width = 28,
        height = 27,
    },
    {
        type = "sprite",
        name = "sets_button_sprite",
        filename = ICONPATH .. "sets.png",
        width = 28,
        height = 27,
    },
    {
        type = "sprite",
        name = "settings_button_sprite",
        filename = ICONPATH .. "settings.png",
        width = 27,
        height = 27,
    },
    {
        type = "sprite",
        name = "start_button_sprite",
        filename = ICONPATH .. "start.png",
        width = 27,
        height = 26,
    },
    {
        type = "sprite",
        name = "stop_button_sprite",
        filename = ICONPATH .. "stop.png",
        width = 27,
        height = 26,
    },
	{
	    type = "sprite",
        name = "speed_up_button_sprite",
        filename = ICONPATH .. "speedup.png",
        width = 280,
        height = 292,
    }	
}
data:extend(custom_sprites)
