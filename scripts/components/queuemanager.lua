-- 250317 VanCa: Add this file to manage tilling / planting on multi tiles
-- Reference: Action Queue RB3, Bird Painting Scroll

function table_print(tt, indent, done)
    done = done or {}
    indent = indent or 0
    if type(tt) == "table" then
        local sb = {}
        for key, value in pairs(tt) do
            table.insert(sb, string.rep(" ", indent)) -- indent it
            if "number" == type(key) then
                table.insert(sb, string.format('%d: "%s" (%s)\n', key, tostring(value), type(value)))
            else
                table.insert(sb, string.format('%s = "%s" (%s)\n', tostring(key), tostring(value), type(value)))
            end
        end
        return table.concat(sb)
    else
        return tt .. "(type: " .. type(tt) .. ")\n"
    end
end

function to_string(tbl)
    if "nil" == type(tbl) then
        return tostring(nil)
    elseif "table" == type(tbl) then
        return "\n" .. table_print(tbl) .. "\n"
    elseif "string" == type(tbl) then
        return tbl
    else
        return tostring(tbl) .. "(" .. type(tbl) .. ")"
    end
end
DebugPrint = false and function(...)
    local msg = "[Snap tillss]"
    for i = 1, arg.n do
        msg = msg .. " " .. to_string(arg[i])
    end
    print(msg .. "\n")
end or function()
        --[[disabled]]
    end

local QueueManager =
    Class(
    function(self, inst)
        self.inst = inst
        self.selected_farm_tiles = {}
        self.action_thread = nil
        self.action_delay = FRAMES * 3
        self.work_delay = FRAMES * 6
        self.last_click = {time = nil}
        self.double_click_speed = 0.5
        DebugPrint("QueueManager initialize")
    end
)

function QueueManager:IsSelectedFarmTile(tile)
    --DebugPrint("IsSelectedEntity: ent:", ent)
    return self.selected_farm_tiles[tile] ~= nil
end

function QueueManager:SelectFarmTile(tile, rightclick)
    DebugPrint("-------------------------------------")
    DebugPrint("SelectFarmTile: tile:", tostring(tile))
    if self:IsSelectedFarmTile(tile) then
        DebugPrint("Farm tile has been selected before")
        return
    end
    self.selected_farm_tiles[tile] = true
    DebugPrint("...done! Farm tile has been selected")
end

function QueueManager:DeselectFarmTile(tile)
    DebugPrint("-------------------------------------")
    DebugPrint("DeselectFarmTile: tile:", tostring(tile))

    if self:IsSelectedFarmTile(tile) then
        self.selected_farm_tiles[tile] = nil
    end
end

-- reference: 呼吸
function QueueManager:AddAdjacentFarmTiles(init_tile, target_pos)
    DebugPrint("-------------------------------------")
    DebugPrint("AddAdjacentFarmTiles: init_tile:", tostring(init_tile), "target_pos:", target_pos)
    if target_pos then
        if not TheWorld.Map:IsFarmableSoilAtPoint(target_pos.x, 0, target_pos.z) then
            --DebugPrint("Not a farm tile")
            return
        end

        -- Select farm tile
        for _, ent in pairs(TheWorld.Map:GetEntitiesOnTileAtPoint(target_pos.x, target_pos.y, target_pos.z)) do
            if ent.prefab == "nutrients_overlay" then
                if self:IsSelectedFarmTile(ent) then
                    -- Farm tile is already selected
                    -- "return" to prevent overlap recursion
                    return
                else
                    self:SelectFarmTile(ent)
                    break
                end
            end
        end
    else
        target_pos = init_tile:GetPosition()
    end

    -- Trigger a recursion to select adjacent (4 directions) farm tiles
    --DebugPrint("North-West")
    self:AddAdjacentFarmTiles(
        init_tile,
        {
            x = target_pos.x + 4,
            y = target_pos.y,
            z = target_pos.z
        }
    )
    --DebugPrint("East-South")
    self:AddAdjacentFarmTiles(
        init_tile,
        {
            x = target_pos.x - 4,
            y = target_pos.y,
            z = target_pos.z
        }
    )
    --DebugPrint("South-West")
    self:AddAdjacentFarmTiles(
        init_tile,
        {
            x = target_pos.x,
            y = target_pos.y,
            z = target_pos.z - 4
        }
    )
    --DebugPrint("North-East")
    self:AddAdjacentFarmTiles(
        init_tile,
        {
            x = target_pos.x,
            y = target_pos.y,
            z = target_pos.z + 4
        }
    )
end

-- Creage Dummy entity to hold the position of non-farm tile
function QueueManager:CreateDummyEntity(x, y, z)
    for tile, _ in pairs(self.selected_farm_tiles) do
        if tile.x == x and tile.y == y and tile.z == z then
            return tile -- Reuse the existing tile table
        end
    end

    -- Create a new table if no existing one matches
    local ent = {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        -- Get position
        GetPosition = function(self)
            return {x = self.x, y = self.y, z = self.z}
        end,
        -- Set position
        SetPosition = function(self, new_x, new_y, new_z)
            self.x = new_x
            self.y = new_y
            self.z = new_z
        end
    }
    return ent
end

local function _distsq(targ_a, targ_b)
    local x, y, z = targ_a.x, targ_a.y, targ_a.z
    local x1, y1, z1 = targ_b.x, targ_b.y, targ_b.z
    local dx = x1 - x
    local dy = y1 - y
    local dz = z1 - z
    return dx * dx + dy * dy + dz * dz
end

-- Select nearby non-farm tiles that in the SEARCH_RANGE of the "center_tile"
function QueueManager:AddAdjacentNonFarmTiles(center_tile, init_tile, target_pos)
    DebugPrint("-------------------------------------")
    DebugPrint("AddAdjacentNonFarmTiles: init_tile:", tostring(init_tile), "target_pos:", target_pos)
    if target_pos then
        local SEARCH_RANGE = 10

        local distance = math.sqrt(_distsq(center_tile:GetPosition(), target_pos))
        DebugPrint("distance:", distance)

        if not TheWorld.Map:IsFarmableSoilAtPoint(target_pos.x, 0, target_pos.z) and distance < SEARCH_RANGE then
            local tile_ent = self:CreateDummyEntity(target_pos.x, target_pos.y, target_pos.z)
            if self:IsSelectedFarmTile(tile_ent) then
                -- Non-farm tile is already selected
                -- "return" to prevent overlap recursion
                return
            else
                --DebugPrint("Select non-farm tile")
                self:SelectFarmTile(tile_ent)
            end
        else
            --DebugPrint("Not a non-farm tile or out of range")
            return
        end
    else
        target_pos = init_tile:GetPosition()
    end

    -- Trigger a recursion to select adjacent (4 directions) non-farm tiles
    --DebugPrint("North-West")
    self:AddAdjacentNonFarmTiles(
        center_tile,
        init_tile,
        {
            x = target_pos.x + 4,
            y = target_pos.y,
            z = target_pos.z
        }
    )
    --DebugPrint("East-South")
    self:AddAdjacentNonFarmTiles(
        center_tile,
        init_tile,
        {
            x = target_pos.x - 4,
            y = target_pos.y,
            z = target_pos.z
        }
    )
    --DebugPrint("South-West")
    self:AddAdjacentNonFarmTiles(
        center_tile,
        init_tile,
        {
            x = target_pos.x,
            y = target_pos.y,
            z = target_pos.z - 4
        }
    )
    --DebugPrint("North-East")
    self:AddAdjacentNonFarmTiles(
        center_tile,
        init_tile,
        {
            x = target_pos.x,
            y = target_pos.y,
            z = target_pos.z + 4
        }
    )
end

function QueueManager:GetClosestTile()
    DebugPrint("-------------------------------------")
    DebugPrint("GetClosestTile")
    local mindistsq, closest_tile
    local player_pos = self.inst:GetPosition()
    local player_pos_x, player_pos_z = player_pos.x, player_pos.z
    for tile in pairs(self.selected_farm_tiles) do
        local curdistsq = player_pos:DistSq(tile:GetPosition())
        if not mindistsq or curdistsq < mindistsq then
            mindistsq = curdistsq
            closest_tile = tile
        end
    end
    DebugPrint("Closest tile:", tostring(closest_tile))
    return closest_tile
end

-- Add entity to queue if valid
function QueueManager:TryAddToQueue(pos, is_double_click)
    DebugPrint("-------------------------------------")
    DebugPrint("TryAddToQueue")
    local clicked_farm_tile = nil
    local current_time = GetTime()
    self.last_click.time = current_time

    for _, ent in pairs(TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x, pos.y, pos.z)) do
        -- Look for tile's nutrients_overlay entity, that's a farm tile
        if ent.prefab == "nutrients_overlay" then
            clicked_farm_tile = ent
            break
        end
    end

    if clicked_farm_tile then
        -- Planting/tilling on farm tile
        if is_double_click then
            -- Add adjacent farm tiles to the list
            self:AddAdjacentFarmTiles(clicked_farm_tile)
        else
            -- Add the clicked farm tile to the list
            self:SelectFarmTile(clicked_farm_tile)
        end
    else
        -- Planting on non-farm tile (Wormwood)
        local dummy_entity = self:CreateDummyEntity(_G.TheWorld.Map:GetTileCenterPoint(pos.x, 0, pos.z))
        if is_double_click then
            -- Add adjacent non-farm tiles to the list
            self:AddAdjacentNonFarmTiles(dummy_entity, dummy_entity)
        else
            -- Add the clicked non-farm tile to the list
            self:SelectFarmTile(dummy_entity)
        end
    end
end

-- Start processing the queue (called from the tiller class)
function QueueManager:StartProcessThread(on_process_farm_tile)
    DebugPrint("-------------------------------------")
    DebugPrint("StartProcessThread")

    if self.action_thread then
        return false
    end

    self.action_thread =
        StartThread(
        function()
            DebugPrint("Start action_thread")
            self.inst:ClearBufferedAction()
            while self.inst:IsValid() do
                local closest_farm_tile = self:GetClosestTile()
                if not closest_farm_tile then
                    break
                end

                on_process_farm_tile(closest_farm_tile) -- Callback to the tiller class's action

                self:DeselectFarmTile(closest_farm_tile)
            end

            self:ClearThread()
        end,
        "snap_tills_queue_thread"
    )

    return true
end

-- Clear the thread reference
function QueueManager:ClearThread()
    DebugPrint("-------------------------------------")
    DebugPrint("QueueManager:ClearThread")
    if self.action_thread then
        KillThreadsWithID("snap_tills_queue_thread")
        self.action_thread = nil
    end
    for tile in pairs(self.selected_farm_tiles) do
        self:DeselectFarmTile(tile)
    end
end

return QueueManager
