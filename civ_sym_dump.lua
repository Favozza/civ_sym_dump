-- civ_sym_dump: dump all civilization symbols of the loaded world to a civ_symbols_nameworld.txt file in the DF folder
-- Usage: Embark -> Smooth stone wall/floor -> Dettail -> Specify image -> Existing image -> Click on DFHack -> civ_sym_dump

local function safe(f, ...)
    local ok, r = pcall(f, ...)
    if ok then return r end
end

if not dfhack.isWorldLoaded() then
    qerror('No world data loaded yet. Try again after loading the save.')
end

local function find_image(id, subid)
    for _, c in ipairs(df.global.world.art_image_chunks.all) do
        if c.id == id then
            for _, m in ipairs(c.images) do
                local a = m.art_image
                if a and a.subid == subid then return a end
            end
        end
    end
end

local function plant_name(pid)
    local p = safe(function() return df.global.world.raws.plants.all[pid] end)
    return p and p.name or ('plant#' .. pid)
end

local function shape_name(e)
    local sh = safe(function() return df.global.world.raws.descriptors.shapes[e.shape_id] end)
    local nm = sh and safe(function() return sh.name end)
    return nm and ('shape: ' .. nm) or ('shape#' .. e.shape_id)
end

local function describe(e)
    local t = tostring(e._type)
    local cnt = e.count and e.count > 1 and (' x' .. e.count) or ''
    if t:find('creaturest') then
        local cr = df.creature_raw.find(e.race)
        return (cr and cr.name[0] or ('race#' .. e.race)) .. cnt
    elseif t:find('treest') then
        return 'tree: ' .. plant_name(e.plant_id) .. cnt
    elseif t:find('plantst') then
        return 'plant: ' .. plant_name(e.plant_id) .. cnt
    elseif t:find('itemst') then
        local name = df.item_type[e.item_type] or ('item#' .. e.item_type)
        if e.item_subtype >= 0 then
            local d = safe(dfhack.items.getSubtypeDef, e.item_type, e.item_subtype)
            if d then name = d.name end
        end
        return 'item: ' .. name .. cnt
    elseif t:find('shapest') then
        return shape_name(e) .. cnt
    end
    return t
end

-- name of the civilization's own race, e.g. "Dwarf"
local function civ_race_name(ent)
    local cr = ent.race >= 0 and safe(df.creature_raw.find, ent.race)
    local nm = cr and cr.name[0]
    if not nm or nm == '' then return 'Unknown race' end
    return (nm:gsub('^%l', string.upper))
end

local function loaded_signature()
    local ids = {}
    for _, c in ipairs(df.global.world.art_image_chunks.all) do
        ids[#ids + 1] = c.id
    end
    table.sort(ids)
    return table.concat(ids, ',')
end

-- writes the file, returns number of civs that could not be decoded
local function dump(filter)
    local by_race, decoded, missing, missing_chunks = {}, 0, 0, {}

    for _, ent in ipairs(df.global.world.entities.all) do
        if ent.type == df.historical_entity_type.Civilization
           and #ent.resources.art_image_ids > 0 and ent.name.has_name then
            local cname = dfhack.translation.translateName(ent.name, true)
            local race = civ_race_name(ent)
            local id = ent.resources.art_image_ids[0]
            local sub = ent.resources.art_image_subids[0]
            local img = find_image(id, sub)
            local line
            if img then
                decoded = decoded + 1
                local parts = {}
                for _, e in ipairs(img.elements) do parts[#parts + 1] = describe(e) end
                line = cname .. ' -> ' .. table.concat(parts, ' + ')
            else
                missing = missing + 1
                missing_chunks[id] = true
                line = ('%s -> (symbol chunk %d not loaded)'):format(cname, id)
            end
            by_race[race] = by_race[race] or {}
            table.insert(by_race[race], line)
        end
    end

    -- sort races alphabetically and the civs inside each race
    local races = {}
    for race, list in pairs(by_race) do
        table.sort(list)
        races[#races + 1] = race
    end
    table.sort(races)

    local out = {}
    for i, race in ipairs(races) do
        local list = by_race[race]
        if i > 1 then out[#out + 1] = '' end
        out[#out + 1] = ('=== %s (%d civ%s) ==='):format(race, #list, #list == 1 and '' or 's')
        for _, l in ipairs(list) do out[#out + 1] = l end
    end

    -- one file per world so results never mix
    local world = safe(dfhack.world.ReadWorldFolder)
        or safe(function() return dfhack.translation.translateName(df.global.world.world_data.name, true) end)
        or 'world'
    world = tostring(world):gsub('[^%w_%-]', '_')
    local path = ('%s/civ_symbols_%s.txt'):format(dfhack.getDFPath(), world)

    local f = assert(io.open(path, 'w'))
    f:write(table.concat(out, '\n'), '\n')
    f:close()

    if filter and filter ~= '' then
        for _, race in ipairs(races) do
            for _, l in ipairs(by_race[race]) do
                if (race .. ' ' .. l):lower():find(filter, 1, true) then
                    print(('[%s] %s'):format(race, l))
                end
            end
        end
    end

    print(('civ_sym_dump: %d civs decoded, %d not decodable, %d races. Saved to %s')
        :format(decoded, missing, #races, path))
    if missing > 0 then
        local ids = {}
        for id in pairs(missing_chunks) do ids[#ids + 1] = tostring(id) end
        table.sort(ids)
        print('Missing symbol chunk(s): ' .. table.concat(ids, ', '))
    end
    return missing
end

-- poll about once a second (in frames, so it also runs in menus)
local function watch(last_sig)
    dfhack.timeout(60, 'frames', function()
        if not dfhack.isWorldLoaded() then return end
        local sig = loaded_signature()
        if sig ~= last_sig then
            print('civ_sym_dump: new symbol data loaded, updating file...')
            if dump('') == 0 then
                print('civ_sym_dump: all symbols decoded, done watching.')
                return
            end
        end
        watch(sig)
    end)
end

local missing = dump((({...})[1] or ''):lower())
if missing > 0 then
    print('civ_sym_dump: watching for symbol chunks to load; the file updates automatically.')
    watch(loaded_signature())
end

-- END OF civ_sym_dump.lua
