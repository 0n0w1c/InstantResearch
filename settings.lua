local space_age_active = mods["space-age"] ~= nil
local order_counter = 0

local function get_next_order()
    order_counter = order_counter + 1
    return string.format("a-%03d", order_counter)
end

local function make_science_setting(name, hidden)
    return {
        type = "bool-setting",
        name = "instant-research-include-" .. name,
        setting_type = "startup",
        default_value = false,
        order = get_next_order(),
        hidden = hidden
    }
end

data:extend({
    make_science_setting("automation-science-pack", false),
    make_science_setting("logistic-science-pack", false),
    make_science_setting("military-science-pack", false),
    make_science_setting("chemical-science-pack", false),
    make_science_setting("production-science-pack", false),
    make_science_setting("utility-science-pack", false),
    make_science_setting("space-science-pack", false),

    make_science_setting("metallurgic-science-pack", not space_age_active),
    make_science_setting("electromagnetic-science-pack", not space_age_active),
    make_science_setting("agricultural-science-pack", not space_age_active),
    make_science_setting("cryogenic-science-pack", not space_age_active),
    make_science_setting("promethium-science-pack", not space_age_active),

    {
        type = "bool-setting",
        name = "instant-research-include-free-techs",
        setting_type = "startup",
        default_value = false,
        order = get_next_order()
    },
    {
        type = "bool-setting",
        name = "instant-research-skip-quality-module",
        setting_type = "startup",
        default_value = false,
        order = get_next_order(),
        hidden = not space_age_active
    },
})
