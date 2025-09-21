require("constants")

local function list_append(dst, src)
    for _, v in ipairs(src) do
        table.insert(dst, v)
    end
    return dst
end

local quality_active = mods["quality"] ~= nil and mods["no-more-quality"] == nil
local order_counter = 0

SCIENCE_PACKS = {
    "automation-science-pack",
    "logistic-science-pack",
    "military-science-pack",
    "chemical-science-pack",
    "production-science-pack",
    "utility-science-pack",
    "space-science-pack"
}

if mods["space-age"] then
    local packs = {
        "metallurgic-science-pack",
        "electromagnetic-science-pack",
        "agricultural-science-pack",
        "cryogenic-science-pack",
        "promethium-science-pack"
    }

    list_append(SCIENCE_PACKS, packs)
end

---
--    1. Add if-blocks here, for new science packs (see space-age if-block above)
--    2. Update locale.cfg
--    3. Add an optional dependency in info.json
---

local function get_next_order()
    order_counter = order_counter + 1
    return string.format("a-%03d", order_counter)
end

local function make_science_setting(name)
    return {
        type = "bool-setting",
        name = "instant-research-include-" .. name,
        setting_type = "startup",
        default_value = false,
        order = get_next_order(),
    }
end

for _, pack in ipairs(SCIENCE_PACKS) do
    data:extend({
        make_science_setting(pack)
    })
end

data:extend({
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
        hidden = not quality_active
    },
})
