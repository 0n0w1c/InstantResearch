local quality_techs = {
    ["quality-module"] = true,
    ["quality-module-2"] = true,
    ["quality-module-3"] = true,
    ["epic-quality"] = true,
    ["legendary-quality"] = true
}

local cached_science_packs

local function is_infinite_tech(tech)
    local infinite = 4294967295
    local prototype = tech and tech.prototype
    if not prototype then return false end

    return prototype.max_level == infinite
end

local function current_tech_level(tech)
    return (tech.level) or (tech.prototype and tech.prototype.level) or 1
end

local function complete_infinite_to_level(force, tech, cur, target_level)
    if not (cur and target_level) or target_level < cur then return end

    local count = target_level - cur
    for i = 1, count do
        force.add_research(tech)
        force.research_progress = 1
    end
    force.research_progress = 1
end

local function tech_requires_included_packs(tech, included_set, include_free)
    local required_packs = tech.research_unit_ingredients
    if not required_packs or #required_packs == 0 then
        return include_free
    end
    for _, ingredient in ipairs(required_packs) do
        if not included_set[ingredient.name] then
            return false
        end
    end
    return true
end

local function tech_and_prereqs_included(tech, included_set, include_free, skip_quality, visited)
    if is_infinite_tech(tech) then return false end
    if quality_techs[tech.name] and skip_quality then return false end
    if visited[tech.name] then return true end
    visited[tech.name] = true

    if not tech_requires_included_packs(tech, included_set, include_free) then
        return false
    end

    for _, prereq in pairs(tech.prerequisites or {}) do
        if not tech_and_prereqs_included(prereq, included_set, include_free, skip_quality, visited) then
            return false
        end
    end
    return true
end

local function get_all_includable_science_packs()
    if cached_science_packs then return cached_science_packs end

    cached_science_packs = {
        "automation-science-pack",
        "logistic-science-pack",
        "military-science-pack",
        "chemical-science-pack",
        "production-science-pack",
        "utility-science-pack",
        "space-science-pack"
    }

    if script.active_mods["space-age"] then
        table.insert(cached_science_packs, "metallurgic-science-pack")
        table.insert(cached_science_packs, "electromagnetic-science-pack")
        table.insert(cached_science_packs, "agricultural-science-pack")
        table.insert(cached_science_packs, "cryogenic-science-pack")
        table.insert(cached_science_packs, "promethium-science-pack")
    end

    return cached_science_packs
end

local function get_included_science_packs()
    local included = {}
    for _, science_pack in ipairs(get_all_includable_science_packs()) do
        local setting = settings.startup["instant-research-include-" .. science_pack]
        if setting and setting.value then
            table.insert(included, science_pack)
        end
    end
    return included
end

local function instant_research()
    local included_packs = get_included_science_packs()
    if #included_packs == 0 then return end

    local included_set = {}
    for _, pack in ipairs(included_packs) do
        included_set[pack] = true
    end

    local skip_quality = settings.startup["instant-research-skip-quality-module"]
        and settings.startup["instant-research-skip-quality-module"].value

    local include_free = settings.startup["instant-research-include-free-techs"]
        and settings.startup["instant-research-include-free-techs"].value

    for _, force in pairs(game.forces) do
        for _, tech in pairs(force.technologies) do
            if tech.enabled and not tech.researched and not is_infinite_tech(tech) then
                local visited = {}
                if tech_and_prereqs_included(tech, included_set, include_free, skip_quality, visited) then
                    tech.research_recursive()
                end
            end
        end
    end
end

local function enable_default_shortcut(player)
    if player and player.valid and player.is_shortcut_available("instant-research-toggle") then
        player.set_shortcut_toggled("instant-research-toggle", true)
    end
end

local function destroy_instant_research_gui(player)
    if player.opened and player.opened.name == "instant_research_frame" then
        player.opened.destroy()
        player.opened = nil
    elseif player.gui.screen.instant_research_frame then
        player.gui.screen.instant_research_frame.destroy()
    end
end

local function show_instant_research_gui(player, tech)
    destroy_instant_research_gui(player)

    local frame = player.gui.screen.add {
        type = "frame",
        name = "instant_research_frame",
        direction = "vertical"
    }
    frame.auto_center = true

    local titlebar = frame.add { type = "flow", direction = "horizontal", drag_target = frame }
    titlebar.add {
        type = "label",
        caption = { "", "[img=instant-research-icon]", { "gui-caption.instant-research-label" } },
        style = "frame_title",
        ignored_by_interaction = true
    }
    local spacer = titlebar.add { type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true }
    spacer.style.horizontally_stretchable = true
    spacer.style.height = 24

    local content = frame.add { type = "flow", name = "instant_research_content", direction = "vertical" }

    local infinite = tech and is_infinite_tech(tech)
    if infinite then
        local row = content.add {
            type = "flow",
            name = "instant_research_level_row",
            direction = "horizontal"
        }
        row.style.horizontally_stretchable = true
        row.style.horizontal_align = "center"

        row.add { type = "label", caption = { "gui-label.level" } }

        local textfield = row.add {
            type = "textfield",
            name = "instant_research_level_textfield",
            numeric = true,
            allow_decimal = false,
            allow_negative = false,
            text = tostring(current_tech_level(tech))
        }
        textfield.style.width = 80
    end

    local buttons = content.add { type = "flow", name = "instant_research_buttons", direction = "horizontal" }
    buttons.add { type = "button", name = "instant_research_yes", caption = { "gui-button.instant-research-yes" } }
    buttons.add { type = "button", name = "instant_research_no", caption = { "gui-button.instant-research-no" } }

    frame.tags = { tech_name = tech and tech.name or nil, is_infinite = infinite and true or false }
    player.opened = frame
end

script.on_event(defines.events.on_gui_click, function(event)
    local player = game.get_player(event.player_index)
    local element = event.element
    if not (player and element and element.valid) then return end

    local name = element.name
    if name ~= "instant_research_yes" and name ~= "instant_research_no" then
        return
    end

    local frame = player.gui.screen.instant_research_frame
    if not (frame and frame.valid) then return end

    local force = player.force
    local current_research = force.current_research

    if name == "instant_research_yes" then
        local tags = frame.tags or {}
        if tags.is_infinite and tags.tech_name then
            local tech = force.technologies[tags.tech_name]
            if tech then
                local content   = frame.instant_research_content
                local row       = content and content.instant_research_level_row
                local textfield = row and row.instant_research_level_textfield
                local target    = textfield and tonumber((textfield.text or ""):match("%d+"))
                local current   = current_tech_level(tech)
                if target and target >= current then
                    complete_infinite_to_level(force, tech, current, target)
                end
            end
        else
            if current_research then
                force.research_progress = 1
            end
        end
    end

    destroy_instant_research_gui(player)
end)

local function remove_from_research_queue(force, tech_name)
    local current_queue = force.research_queue
    if not current_queue or #current_queue == 0 then return end

    local updated_queue = {}
    for _, queued_item in ipairs(current_queue) do
        local queued_name = queued_item.name
        if queued_name and queued_name ~= tech_name then
            table.insert(updated_queue, queued_item)
        end
    end

    force.research_queue = (#updated_queue > 0) and updated_queue or nil
end

script.on_event(defines.events.on_research_queued, function(event)
    local tech = event.research
    if not tech then return end

    local skip_quality = settings.startup["instant-research-skip-quality-module"]
        and settings.startup["instant-research-skip-quality-module"].value

    if skip_quality and quality_techs[tech.name] then
        tech.force.cancel_current_research()
        remove_from_research_queue(tech.force, tech.name)
        return
    end

    local player_index = event.player_index
    if not player_index then return end
    local player = game.get_player(player_index)
    if not player then return end
    if not player.is_shortcut_toggled("instant-research-toggle") then return end

    show_instant_research_gui(player, tech)
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
    if event.prototype_name == "instant-research-toggle" then
        local player = game.get_player(event.player_index)
        if player then
            local new_state = not player.is_shortcut_toggled("instant-research-toggle")
            player.set_shortcut_toggled("instant-research-toggle", new_state)
        end
    end
end)

script.on_event(defines.events.on_player_created, function(event)
    local player = game.get_player(event.player_index)
    enable_default_shortcut(player)
end)

script.on_init(function()
    instant_research()
end)

script.on_configuration_changed(function()
    cached_science_packs = nil
    instant_research()
end)
