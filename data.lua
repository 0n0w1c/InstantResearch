data:extend({
    {
        type = "sprite",
        name = "instant-research-icon",
        filename = "__InstantResearch__/graphics/icons/instant-research-64.png",
        size = 64,
        mipmap_count = 2,
        flags = { "gui-icon" }
    },
    {
        type = "shortcut",
        name = "instant-research-toggle",
        localised_name = { "shortcut-name.instant-research-toggle" },
        action = "lua",
        toggleable = true,
        style = "default",
        icon = "__InstantResearch__/graphics/icons/instant-research-32.png",
        icon_size = 32,
        small_icon = "__InstantResearch__/graphics/icons/instant-research-24.png",
        small_icon_size = 24,
    }
})
