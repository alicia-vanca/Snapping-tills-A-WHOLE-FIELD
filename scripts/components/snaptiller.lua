-- 250617 VanCa: Add QueueManager to handle farm tiles queue
local QueueManager = require("components/queuemanager")

local DebugPrint = _G.SnappingTills.DebugPrint

local TILESNAPS = {
    MAP_2x2 = {{-1, -1}, {1, -1}, {-1, 1}, {1, 1}},
    MAP_3x3 = {
        {-1.333, -1.333},
        {0, -1.333},
        {1.333, -1.333},
        {-1.333, 0},
        {0, 0},
        {1.333, 0},
        {-1.333, 1.333},
        {0, 1.333},
        {1.333, 1.333}
    },
    MAP_4x4 = {
        {-1.99950, -1.99950},
        {-0.66649, -1.99950},
        {0.66651, -1.99950},
        {1.99952, -1.99950},
        {-1.99950, -0.66649},
        {-0.66649, -0.66649},
        {0.66651, -0.66649},
        {1.99952, -0.66649},
        {-1.99950, 0.66651},
        {-0.66649, 0.66651},
        {0.66651, 0.66651},
        {1.99952, 0.66651},
        {-1.99950, 1.99952},
        {-0.66649, 1.99952},
        {0.66651, 1.99952},
        {1.99952, 1.99952}
    },
    MAP_QUAGMIRE = {
        {-1.5, -1.5},
        {-0.5, -1.5},
        {0.5, -1.5},
        {1.5, -1.5},
        {-1.5, -0.5},
        {-0.5, -0.5},
        {0.5, -0.5},
        {1.5, -0.5},
        {-1.5, 0.5},
        {-0.5, 0.5},
        {0.5, 0.5},
        {1.5, 0.5},
        {-1.5, 1.5},
        {-0.5, 1.5},
        {0.5, 1.5},
        {1.5, 1.5}
    },
    MAP_HEXAGON = {
        {-1.5, -1.6},
        {0.5, -1.6},
        {-0.5, -0.8},
        {1.5, -0.8},
        {-1.5, 0},
        {0.5, 0},
        {-0.5, 0.8},
        {1.5, 0.8},
        {-1.5, 1.6},
        {0.5, 1.6}
    },
    MAP_HEXAGON2 = {
        {-0.5, -1.6},
        {1.5, -1.6},
        {-1.5, -0.8},
        {0.5, -0.8},
        {-0.5, 0},
        {1.5, 0},
        {-1.5, 0.8},
        {0.5, 0.8},
        {-0.5, 1.6},
        {1.5, 1.6}
    }
}

-- Decide the tilling order in a tile
-- heading 360 = 0
local HEADSNAPS = {
    IDS_2x2 = {
        [0] = {1, 3, 2, 4},
        [45] = {1, 2, 3, 4},
        [90] = {2, 1, 4, 3},
        [135] = {2, 4, 1, 3},
        [180] = {4, 2, 3, 1},
        [225] = {4, 3, 2, 1},
        [270] = {3, 4, 1, 2},
        [315] = {3, 1, 4, 2}
    },
    -- The snap layout in a tile:
    -- 1 4 7
    -- 2 5 8
    -- 3 6 9
    IDS_3x3 = {
        [0] = {1, 4, 7, 2, 5, 8, 3, 6, 9},
        [45] = {1, 2, 4, 3, 5, 7, 6, 8, 9},
        [90] = {3, 2, 1, 6, 5, 4, 9, 8, 7},
        [135] = {3, 6, 2, 9, 5, 1, 8, 4, 7},
        [180] = {9, 6, 3, 8, 5, 2, 7, 4, 1},
        [225] = {9, 8, 6, 7, 5, 3, 4, 2, 1},
        [270] = {7, 8, 9, 4, 5, 6, 1, 2, 3},
        [315] = {7, 4, 8, 1, 5, 9, 2, 6, 3}
    },
    -- 250321 VanCa: Plant the middle slot last for more beauty in 2&4 types intercropping
    IDS_3x3_EVEN_INTERCROPPING = {
        [0] = {1, 4, 7, 8, 9, 6, 3, 2, 5},
        [45] = {1, 4, 7, 8, 9, 6, 3, 2, 5},
        [90] = {3, 2, 1, 4, 7, 8, 9, 6, 5},
        [135] = {3, 2, 1, 4, 7, 8, 9, 6, 5},
        [180] = {9, 6, 3, 2, 1, 4, 7, 8, 5},
        [225] = {9, 6, 3, 2, 1, 4, 7, 8, 5},
        [270] = {7, 8, 9, 6, 3, 2, 1, 4, 5},
        [315] = {7, 8, 9, 6, 3, 2, 1, 4, 5}
    },
    IDS_4x4 = {
        [0] = {1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16},
        [45] = {1, 2, 5, 3, 6, 9, 4, 7, 10, 13, 8, 11, 14, 12, 15, 16},
        [90] = {4, 3, 2, 1, 8, 7, 6, 5, 12, 11, 10, 9, 16, 15, 14, 13},
        [135] = {4, 8, 3, 12, 7, 2, 16, 11, 6, 1, 15, 10, 5, 14, 9, 13},
        [180] = {16, 12, 8, 4, 15, 11, 7, 3, 14, 10, 6, 2, 13, 9, 5, 1},
        [225] = {16, 15, 12, 14, 11, 8, 13, 10, 7, 4, 9, 6, 3, 5, 2, 1},
        [270] = {13, 14, 15, 16, 9, 10, 11, 12, 5, 6, 7, 8, 1, 2, 3, 4},
        [315] = {13, 9, 14, 5, 10, 15, 1, 6, 11, 16, 2, 7, 12, 3, 8, 4}
    },
    IDS_HEXAGON = {
        [0] = {1, 5, 9, 3, 7, 2, 6, 10, 4, 8},
        [45] = {1, 2, 3, 5, 4, 6, 7, 9, 8, 10},
        [90] = {2, 1, 4, 3, 6, 5, 8, 7, 10, 9},
        [135] = {4, 2, 8, 6, 3, 1, 10, 7, 5, 9},
        [180] = {8, 4, 10, 6, 2, 7, 3, 9, 5, 1},
        [225] = {10, 8, 9, 7, 6, 4, 5, 3, 2, 1},
        [270] = {9, 10, 7, 8, 5, 6, 3, 4, 1, 2},
        [315] = {9, 5, 7, 10, 1, 3, 6, 8, 2, 4}
    },
    IDS_HEXAGON2 = {
        [0] = {3, 7, 1, 5, 9, 4, 8, 2, 6, 10},
        [45] = {1, 3, 2, 4, 5, 7, 6, 8, 9, 10},
        [90] = {2, 1, 4, 3, 6, 5, 8, 7, 10, 9},
        [135] = {2, 6, 4, 1, 10, 8, 5, 3, 9, 7},
        [180] = {10, 6, 2, 8, 4, 9, 5, 1, 7, 3},
        [225] = {10, 9, 8, 6, 7, 5, 4, 2, 3, 1},
        [270] = {9, 10, 7, 8, 5, 6, 3, 4, 1, 2},
        [315] = {7, 9, 3, 5, 8, 10, 1, 4, 6, 2}
    }
}

-- 250319 VanCa: Get the number of planted xxx seeds on the tile
local function CountPlantedSeedOnTile(self, pos, seed_prefab)
    DebugPrint("-------------------------------------")
    DebugPrint("CountPlantedSeedOnTile")

    -- Get planted prefab from seed prefab: xxxx_seeds -> farm_plant_xxxx
    seed_prefab = seed_prefab:match("^(.-)_seeds$")
    if not seed_prefab then
        -- Probally it's a general "seeds"
        DebugPrint("seed_count: exclude random seeds")
        return 0
    end
    local plant_prefab = "farm_plant_" .. seed_prefab

    -- Get the tile center
    local x, y, z = _G.TheWorld.Map:GetTileCenterPoint(pos.x, 0, pos.z)

    -- Search for entities within a radius of TILE_SCALE*1.5 from tile center
    -- A little more than enough ( TILE_SCALE*sqrt(2) ) but that's ok
    local planted_seeds = TheSim:FindEntities(x, 0, z, TILE_SCALE * 1.5, {"farm_plant"})

    -- Count entities that has the same prefab within pos_center's x +- 2, z +- 2
    -- add 0.005 to avoid fractional offsets (ex: ent_pos.z = "202.00050354004")
    local seed_count = 0
    for _, ent in pairs(planted_seeds) do
        if ent.prefab == plant_prefab then
            local ent_pos = ent:GetPosition()
            if
                ent_pos.x >= (x - 2.005) and ent_pos.x <= (x + 2.005) and ent_pos.z >= (z - 2.005) and
                    ent_pos.z <= (z + 2.005)
             then
                seed_count = seed_count + 1
            end
        end
    end
    DebugPrint("seed_count: ", seed_count)
    return seed_count
end

local function DoActionTill(self, coord)
    DebugPrint("-------------------------------------")
    DebugPrint("DoActionTill coord:", coord)
    local pos = Point(coord[1], 0, coord[2])
    local cantill = true
    local x, y, z = pos:Get()
    local item = self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    if not item then
        DebugPrint("not item")
        return false
    end

    -- 250330 VanCa: Repeatedly send the action until the location is tilled (useful when the network is unstable)
    repeat
        if self.isquagmire then
            cantill = TheWorld.Map:CanTillSoilAtPoint(pos)
        else
            cantill = TheWorld.Map:CanTillSoilAtPoint(x, y, z)
        end
        if cantill then
            local playercontroller = self.inst.components.playercontroller
            local act = BufferedAction(self.inst, nil, ACTIONS.TILL, item, pos)

            if playercontroller.ismastersim then
                self.inst.components.combat:SetTarget(nil)
                playercontroller:DoAction(act)
            else
                if playercontroller.locomotor then
                    act.preview_cb = function()
                        SendRPCToServer(RPC.RightClick, ACTIONS.TILL.code, pos.x, pos.z, nil, nil, true)
                    end
                    playercontroller:DoAction(act)
                else
                    SendRPCToServer(RPC.RightClick, ACTIONS.TILL.code, pos.x, pos.z, nil, nil, true)
                end
            end

            Sleep(FRAMES * 6)
            repeat
                Sleep(FRAMES * 3)
            until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving") and
                self.inst:HasTag("idle") and
                not self.inst.components.playercontroller:IsDoingOrWorking()
        end
    until not cantill or not self:isValidSnap(coord)
    DebugPrint("end")

    return true
end

local function DoActionDeploy(self, pos)
    DebugPrint("-------------------------------------")
    DebugPrint("DoActionDeploy pos: ", pos)
    local x, y, z = pos:Get()
    local item = self.inst.replica.inventory and self.inst.replica.inventory:GetActiveItem()

    if not item then
        return false
    end

    -- 250330 VanCa: Repeatedly send the action until the location is planted (useful when the network is unstable)
    local can_plant
    repeat
        can_plant = TheWorld.Map:CanTillSoilAtPoint(x, y, z, true)
        if can_plant then
            DebugPrint("CanTillSoilAtPoint")
            local playercontroller = self.inst.components.playercontroller
            local act = BufferedAction(self.inst, nil, ACTIONS.DEPLOY, item, pos)

            if playercontroller.ismastersim then
                DebugPrint("playercontroller.ismastersim")
                self.inst.components.combat:SetTarget(nil)
                playercontroller:DoAction(act)
            else
                if playercontroller.locomotor then
                    act.preview_cb = function()
                        DebugPrint("locomotor SendRPCToServer")
                        SendRPCToServer(RPC.RightClick, ACTIONS.DEPLOY.code, pos.x, pos.z, nil, nil, true)
                    end
                    playercontroller:DoAction(act)
                else
                    DebugPrint("SendRPCToServer")
                    SendRPCToServer(RPC.RightClick, ACTIONS.DEPLOY.code, pos.x, pos.z, nil, nil, true)
                end
            end

            Sleep(FRAMES * 6)
            repeat
                Sleep(FRAMES * 3)
            until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving") and
                self.inst:HasTag("idle") and
                not self.inst.components.playercontroller:IsDoingOrWorking()
        end
    until not can_plant

    return true
end

local SnapTiller =
    Class(
    function(self, inst)
        self.inst = inst
        self.snap_mode = 0
        self.intercropping_mode = 1
        self.isquagmire = false
        self.actionthread = nil
        self.snaplistaction = nil
        self.queue_manager = QueueManager(self.inst)
    end
)

function SnapTiller:HasAdjacentSoilTile(pos)
    local deltadir = {{0, -4}, {4, -4}, {4, 0}, {4, 4}, {0, 4}, {-4, 4}, {-4, 0}, {-4, -4}}

    for _, v in ipairs(deltadir) do
        local px, pz = pos.x + v[1], pos.z + v[2]
        local tile = TheWorld.Map:GetTileAtPoint(px, 0, pz)

        if tile == WORLD_TILES.FARMING_SOIL or tile == WORLD_TILES.QUAGMIRE_SOIL then
            return true
        end

        for _, ent in ipairs(TheWorld.Map:GetEntitiesOnTileAtPoint(px, 0, pz)) do
            if ent.prefab == "farm_plow" then
                return true
            end
        end
    end

    return false
end

function SnapTiller:GetSnapListOnTile(tilex, tiley, heading, active_item)
    local result = {}
    local map = {}
    local tilecenter = Point(TheWorld.Map:GetTileCenterPoint(tilex, tiley))

    if heading ~= nil then
        if heading == 360 then
            heading = 0
        end

        if heading >= 0 and heading < 45 then
            heading = 0
        elseif heading >= 45 and heading < 90 then
            heading = 45
        elseif heading >= 90 and heading < 135 then
            heading = 90
        elseif heading >= 135 and heading < 180 then
            heading = 135
        elseif heading >= 180 and heading < 225 then
            heading = 180
        elseif heading >= 225 and heading < 270 then
            heading = 225
        elseif heading >= 270 and heading < 315 then
            heading = 270
        else
            heading = 315
        end
    end

    if self.isquagmire then
        if heading ~= nil and HEADSNAPS.IDS_4x4[heading] ~= nil then
            for _, i in ipairs(HEADSNAPS.IDS_4x4[heading]) do
                table.insert(map, TILESNAPS.MAP_QUAGMIRE[i])
            end
        else
            map = TILESNAPS.MAP_QUAGMIRE
        end
    else
        -- 250321 VanCa: Add handling for even-types intercropping
        if self.snap_mode == 1 or self.snap_mode == 3 then
            if self:HasAdjacentSoilTile(tilecenter) or self.snap_mode == 3 then
                -- (snap_mode == optimal & HasAdjacentSoilTile) or (snap_mode == 3x3)
                if heading ~= nil then
                    local maxIdenticalPlantsPerTile = self:GetMaxIdenticalPlantsPerTile(#TILESNAPS.MAP_3x3, active_item)
                    if
                        (maxIdenticalPlantsPerTile == 2 or maxIdenticalPlantsPerTile == 4) and
                            HEADSNAPS.IDS_3x3_EVEN_INTERCROPPING[heading] ~= nil
                     then
                        -- Intercropping 2 or 4 types. Plant order:
                        -- 1 2 3
                        -- 8 9 4
                        -- 7 6 5
                        for _, i in ipairs(HEADSNAPS.IDS_3x3_EVEN_INTERCROPPING[heading]) do
                            table.insert(map, TILESNAPS.MAP_3x3[i])
                        end
                    elseif HEADSNAPS.IDS_3x3[heading] ~= nil then
                        -- Intercropping Off or intercropping 3 types. Plant order:
                        -- 1 2 3
                        -- 4 5 6
                        -- 7 8 9
                        for _, i in ipairs(HEADSNAPS.IDS_3x3[heading]) do
                            table.insert(map, TILESNAPS.MAP_3x3[i])
                        end
                    end
                else
                    map = TILESNAPS.MAP_3x3
                end
            else
                -- (snap_mode==optimal & don't HasAdjacentSoilTile)
                if heading ~= nil and HEADSNAPS.IDS_4x4[heading] ~= nil then
                    for _, i in ipairs(HEADSNAPS.IDS_4x4[heading]) do
                        table.insert(map, TILESNAPS.MAP_4x4[i])
                    end
                else
                    map = TILESNAPS.MAP_4x4
                end
            end
        elseif self.snap_mode == 2 then
            if heading ~= nil and HEADSNAPS.IDS_4x4[heading] ~= nil then
                for _, i in ipairs(HEADSNAPS.IDS_4x4[heading]) do
                    table.insert(map, TILESNAPS.MAP_4x4[i])
                end
            else
                map = TILESNAPS.MAP_4x4
            end
        elseif self.snap_mode == 4 then
            if heading ~= nil and HEADSNAPS.IDS_2x2[heading] ~= nil then
                for _, i in ipairs(HEADSNAPS.IDS_2x2[heading]) do
                    table.insert(map, TILESNAPS.MAP_2x2[i])
                end
            else
                map = TILESNAPS.MAP_2x2
            end
        elseif self.snap_mode == 5 then
            if tiley % 2 == 0 then
                if heading ~= nil and HEADSNAPS.IDS_HEXAGON[heading] ~= nil then
                    for _, i in ipairs(HEADSNAPS.IDS_HEXAGON[heading]) do
                        table.insert(map, TILESNAPS.MAP_HEXAGON[i])
                    end
                else
                    map = TILESNAPS.MAP_HEXAGON
                end
            else
                if heading ~= nil and HEADSNAPS.IDS_HEXAGON2[heading] ~= nil then
                    for _, i in ipairs(HEADSNAPS.IDS_HEXAGON2[heading]) do
                        table.insert(map, TILESNAPS.MAP_HEXAGON2[i])
                    end
                else
                    map = TILESNAPS.MAP_HEXAGON2
                end
            end
        end
    end

    for _, v in ipairs(map) do
        local x, z = tilecenter.x + v[1], tilecenter.z + v[2]

        if self.isquagmire then
            x = x + (x / 10000)
            z = z + (z / 10000)
        end

        table.insert(result, {x, z})
    end

    return result
end

function SnapTiller:GetSnap(pos)
    local tilex, tiley = TheWorld.Map:GetTileCoordsAtPoint(pos.x, pos.y, pos.z)
    local snaplist = self:GetSnapListOnTile(tilex, tiley)
    local mindist = 16
    local minpos = nil

    for _, v in ipairs(snaplist) do
        local dist = distsq(pos.x, pos.z, v[1], v[2])
        if dist < mindist then
            mindist = dist
            minpos = Point(v[1], 0, v[2])
        end
    end

    if minpos ~= nil then
        pos = minpos
    end

    return pos
end

function SnapTiller:isValidSnap(snap)
    local ents = TheSim:FindEntities(snap[1], 0, snap[2], 0.005, {"soil"})
    for _, v in pairs(ents) do
        if not v:HasTag("NOCLICK") then
            return false
        end
    end
    return true
end

function SnapTiller:StartAutoTillTile(tile)
    DebugPrint("-------------------------------------")
    DebugPrint("StartAutoTillTile(tile) tile: ", tile)

    local target_pos = tile:GetPosition()
    DebugPrint("tile:GetPosition(): ", target_pos)

    local tilex, tiley = TheWorld.Map:GetTileCoordsAtPoint(target_pos.x, target_pos.y, target_pos.z)
    DebugPrint("tilex: ", tilex, "tiley: ", tiley)
    local index = 1

    self.snaplistaction = self:GetSnapListOnTile(tilex, tiley, TheCamera.heading)

    -- Filter invalid snaps
    for i = #self.snaplistaction, 1, -1 do
        local snap = self.snaplistaction[i]
        if not self:isValidSnap(snap) then
            table.remove(self.snaplistaction, i)
        end
    end

    -- Process all snaps for this tile
    while self.inst:IsValid() do
        local coord = self.snaplistaction[index]

        if coord == nil then
            break
        end

        if not DoActionTill(self, coord) then
            break
        end

        -- Process to the next snap
        index = index + 1
    end
    return true
end

function SnapTiller:StartAutoTillAtPoint()
    DebugPrint("-------------------------------------")
    DebugPrint("StartAutoTillAtPoint")
    local manager = self.queue_manager
    local is_controller = TheInput:ControllerAttached()
    local input_pos = self.inst:GetPosition()
    if not is_controller then
        input_pos = TheInput:GetWorldPosition()
    end

    local current_time = GetTime()
    if
        (manager.last_click.time and (current_time - manager.last_click.time) <= manager.double_click_speed) or
            is_controller
     then
        -- If use controller, excute on double click by default
        DebugPrint("Double click")
        manager:TryAddToQueue(input_pos, true)
    else
        DebugPrint("Single click / First click of a Double click")
        manager:TryAddToQueue(input_pos, false)
    end

    if not manager.action_thread then
        DebugPrint("First call")
        -- First call: Initialize and start processing
        manager.last_click.time = current_time
        return manager:StartProcessThread(
            function(tile)
                -- Existing code that till a single tile
                DebugPrint("Handle single tile")
                self:StartAutoTillTile(tile) -- Synchronous processing
            end
        )
    end
end

-- Get entity's container
function SnapTiller:GetContainer(ent)
    -- DebugPrint("ent:", ent)
    if ent and ent.replica then
        return ent.replica.container or ent.replica.inventory
    end
end

local order_all = {"container", "equip", "body", "backpack", "mouse"}

-- Get the location of the item and its container. Actually, tags are legacy code [Items under the mouse will only be included if order == ‘mouse’]
-- reference: 呼吸
function SnapTiller:GetSlotsFromAll(allowed_prefabs, tags_required, validate_func, order)
    DebugPrint("-------------------------------------")
    DebugPrint("GetSlotsFromAll: allowed_prefabs:", allowed_prefabs, "tags_required:", tags_required)
    local result = {}
    local invent = self.inst.replica.inventory

    if order == "mouse" then
        order = order_all
    elseif type(order) == "string" and table.contains(order_all, order) then
        order = {order}
    elseif type(order) == "table" then
        for _, storage_name in pairs(order) do
            local temp_order = {}
            if type(storage_name) == "string" and table.contains(order_all, storage_name) then
                table.insert(temp_order, storage_name)
            end
        end
        order = temp_order
    else
        order = {"container", "equip", "body", "backpack"}
    end

    -- Make sure tags_required and allowed_prefabs are table, or nil
    tags_required =
        (type(tags_required) == "string" and {tags_required}) or (type(tags_required) == "table" and tags_required) or
        nil
    allowed_prefabs =
        (type(allowed_prefabs) == "string" and {allowed_prefabs}) or
        (type(allowed_prefabs) == "table" and allowed_prefabs) or
        nil

    local backpack_list, container_list = {}, {}
    DebugPrint("invent:GetOpenContainers():", invent:GetOpenContainers())
    for container_inst, _ in pairs(invent:GetOpenContainers() or {}) do
        if container_inst:HasTag("INLIMBO") then
            table.insert(backpack_list, container_inst)
        else
            table.insert(container_list, container_inst)
        end
    end

    local function check_and_add_result(cont, slot, item)
        if
            item and (not allowed_prefabs or table.contains(allowed_prefabs, item.prefab)) and
                (not tags_required or item:HasTags(tags_required)) and
                (not validate_func or validate_func(item, cont, slot))
         then
            table.insert(
                result,
                {
                    cont = cont,
                    slot = slot,
                    item = item
                }
            )
        end
    end

    local function check_containers(conts)
        for _, cont in pairs(conts) do
            local container = self:GetContainer(cont)
            -- 241010 VanCa: Stop taking item from "cooker" type container
            if container and container.type ~= "cooker" then
                DebugPrint("[ " .. tostring(cont) .. " ]")
                for slot, item in pairs(container:GetItems()) do
                    DebugPrint("slot:", slot, "item:", tostring(item))
                    check_and_add_result(cont, slot, item)
                end
            end
        end
    end

    for _, storage_name in pairs(order) do
        if storage_name == "body" then
            DebugPrint("--- inventory ---")
            for slot, item in pairs(invent:GetItems()) do
                DebugPrint("slot:", slot, "item:", tostring(item))
                check_and_add_result(self.inst, slot, item)
            end
        elseif storage_name == "equip" then
            DebugPrint("--- equip ---")
            for slot, item in pairs(invent:GetEquips()) do
                DebugPrint("slot:", slot, "item:", tostring(item))
                check_and_add_result(self.inst, slot, item)
            end
        elseif storage_name == "mouse" then
            DebugPrint("--- mouse ---")
            check_and_add_result(self.inst, "mouse", self.inst.replica.inventory:GetActiveItem())
        elseif storage_name == "backpack" then
            DebugPrint("--- backpack ---")
            check_containers(backpack_list)
        elseif storage_name == "container" then
            DebugPrint("--- containers ---")
            check_containers(container_list)
        end
    end

    DebugPrint("Result:", result)
    return result
end

-- return.item: item object
-- return.slot: item position
-- return.container: cont_instst
function SnapTiller:GetSlotFromAll(allowed_prefabs, tags_required, validate_func, order)
    return self:GetSlotsFromAll(allowed_prefabs, tags_required, validate_func, order)[1]
end

-- 2500321 VanCa: Add functions to Auto get new stack of seeds when planting with Wormwood
function SnapTiller:GetNewActiveItem(allowed_prefabs, tags_required, validate_func, order)
    DebugPrint("-------------------------------------")
    DebugPrint("GetNewActiveItem: prefabs:", allowed_prefabs, "tags_required:", tags_required)

    local invent = self.inst.replica.inventory

    -- Make sure allowed_prefabs is a table (or nil)
    allowed_prefabs =
        (type(allowed_prefabs) == "string" and allowed_prefabs ~= "" and {allowed_prefabs}) or
        (type(allowed_prefabs) == "table" and allowed_prefabs) or
        nil

    local item_data = self:GetSlotFromAll(allowed_prefabs, tags_required, validate_func, order)
    if item_data then
        DebugPrint("item_data:", item_data)
        local container = self:GetContainer(item_data.cont)
        repeat
            container:TakeActiveItemFromAllOfSlot(item_data.slot)
            Sleep(FRAMES * 3)
        until invent:GetActiveItem() == item_data.item
        DebugPrint("GetNewActiveItem - Done")
        return item_data.item
    end

    -- If we didn't find the required item
    if allowed_prefabs and table.contains(allowed_prefabs, "goldcoin") and goldenpiggy_data then
        -- in case the required item was "goldcoin", try to find a goldenpiggy and withdraw from it
        local goldenpiggy_data = self:GetSlotFromAll("goldenpiggy")
        if goldenpiggy_data then
            invent:UseItemFromInvTile(goldenpiggy_data.item)
        end

        -- long wait
        Sleep(self.work_delay)
        repeat
            Sleep(self.action_delay)
        until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving") and
            self.inst:HasTag("idle") and
            not self.inst.components.playercontroller:IsDoingOrWorking()
    end
end

-- 250330 VanCa: removed intercropping_mode 1 (off): max (snap_count) plants per tile
-- intercropping_mode 1 (auto): max plants based on inventory first slots (max 4)
-- intercropping_mode 2 (intercropping 2 types): max (snap_count / 2) plants per tile
-- intercropping_mode 3 (intercropping 3 types): max (snap_count / 3) plants per tile
-- and so on...
function SnapTiller:GetMaxIdenticalPlantsPerTile(snap_count, active_item)
    DebugPrint("-------------------------------------")
    DebugPrint("GetMaxIdenticalPlantsPerTile")

    if self.intercropping_mode > 1 or not active_item then
        return math.floor(snap_count / self.intercropping_mode)
    end

    local active_prefab = active_item.prefab

    local empty_count = 0
    local same_prefab_count = 0
    local denominator = 0

    local invent = self.inst.replica.inventory
    local body_items = invent:GetItems() or {}

    DebugPrint("body_items ", body_items)
    for i = 1, 4 do
        local item = body_items[i]
        if not item or item:HasTag("deployedfarmplant") then
            if not item then
                denominator = denominator + 1
                empty_count = empty_count + 1
            else
                denominator = denominator + 1
                if item.prefab == active_prefab then
                    same_prefab_count = same_prefab_count + 1
                end
            end
        else
            -- Stop processing at first non-empty, non-seed slot
            break
        end
    end

    if (denominator == 0) or (empty_count + same_prefab_count == 0) then
        return snap_count
    end

    local ratio = (empty_count + same_prefab_count) / denominator
    return math.floor(snap_count * ratio)
end

-- 250321 VanCa: Add intercropping handle
function SnapTiller:StartAutoDeployTile(tile)
    DebugPrint("-------------------------------------")
    DebugPrint("StartAutoDeployTile")
    local target_pos = tile:GetPosition()
    DebugPrint("tile:GetPosition(): ", target_pos)

    local tilex, tiley = TheWorld.Map:GetTileCoordsAtPoint(target_pos.x, target_pos.y, target_pos.z)
    local index = 1

    local active_item = self.inst.replica.inventory and self.inst.replica.inventory:GetActiveItem()

    self.snaplistaction = self:GetSnapListOnTile(tilex, tiley, TheCamera.heading, active_item)
	
    local maxIdenticalPlantsPerTile = self:GetMaxIdenticalPlantsPerTile(#self.snaplistaction, active_item)

    -- 250318 VanCa: Removed this part to plant in narrowed spaces with Wormwood
    -- for i = #self.snaplistaction, 1, -1 do
    -- local snap = self.snaplistaction[i]
    -- local ents = TheSim:FindEntities(snap[1], 0, snap[2], 0.005, {"soil"})
    -- local flagremove = false

    -- for _, v in pairs(ents) do
    -- if not v:HasTag("NOCLICK") then
    -- flagremove = true
    -- break
    -- end
    -- end

    -- if flagremove then table.remove(self.snaplistaction, i) end
    -- end


    while self.inst:IsValid() and active_item and
        CountPlantedSeedOnTile(self, target_pos, active_item.prefab) < maxIdenticalPlantsPerTile do
        local coord = self.snaplistaction[index]

        if coord == nil then
            break
        end
        if not DoActionDeploy(self, Point(coord[1], 0, coord[2])) then
            break
        end
        index = index + 1

        -- 250321 VanCa: Auto "reload" seeds
        if not self.inst.replica.inventory:GetActiveItem() then
            active_item = self:GetNewActiveItem(active_item.prefab)
        end
    end
    return true
end

function SnapTiller:StartAutoDeployAtPoint()
    DebugPrint("-------------------------------------")
    DebugPrint("StartAutoDeployAtPoint")
    local manager = self.queue_manager
    local is_controller = TheInput:ControllerAttached()
    local input_pos = self.inst:GetPosition()
    if not is_controller then
        input_pos = TheInput:GetWorldPosition()
    end

    local current_time = GetTime()
    if
        (manager.last_click.time and (current_time - manager.last_click.time) <= manager.double_click_speed) or
            is_controller
     then
        -- If use controller, excute on double click by default
        DebugPrint("Double click")
        manager:TryAddToQueue(input_pos, true)
    else
        DebugPrint("Single click / First click of a Double click")
        manager:TryAddToQueue(input_pos, false)
    end

    if not manager.action_thread then
        DebugPrint("First call")
        -- First call: Initialize and start processing
        manager.last_click.time = current_time
        return manager:StartProcessThread(
            function(tile)
                -- Existing code that till a single tile
                DebugPrint("Handle single tile")
                self:StartAutoDeployTile(tile) -- Synchronous processing
            end
        )
    end
end

function SnapTiller:ClearActionThread()
    DebugPrint("-------------------------------------")
    DebugPrint("SnapTiller:ClearActionThread")
    if self.actionthread then
        KillThreadsWithID("snaptillertactionhread")
        self.actionthread:SetList(nil)
        self.actionthread = nil
        self.snaplistaction = nil
    end
    if self.queue_manager then
        self.queue_manager:ClearThread()
    end
end

SnapTiller.OnRemoveEntity = SnapTiller.ClearActionThread
SnapTiller.OnRemoveFromEntity = SnapTiller.ClearActionThread

return SnapTiller
