-- 250617 VanCa: Add QueueManager to handle farm tiles queue
local QueueManager = require("components/queuemanager")

local TILESNAPS =
{
    MAP_2x2 = {{-1, -1}, {1, -1}, {-1, 1}, {1, 1}},
    MAP_3x3 = {{-1.333, -1.333}, {0, -1.333}, {1.333, -1.333}, {-1.333, 0}, {0, 0}, {1.333, 0}, {-1.333, 1.333}, {0, 1.333}, {1.333, 1.333}},
    MAP_4x4 = {{-1.99950, -1.99950}, {-0.66649, -1.99950}, {0.66651, -1.99950}, {1.99952, -1.99950}, {-1.99950, -0.66649}, {-0.66649, -0.66649}, {0.66651, -0.66649}, {1.99952, -0.66649}, {-1.99950, 0.66651}, {-0.66649, 0.66651}, {0.66651, 0.66651}, {1.99952, 0.66651}, {-1.99950, 1.99952}, {-0.66649, 1.99952}, {0.66651, 1.99952}, {1.99952, 1.99952}},
    MAP_QUAGMIRE = {{-1.5, -1.5}, {-0.5, -1.5}, {0.5, -1.5}, {1.5, -1.5}, {-1.5, -0.5}, {-0.5, -0.5}, {0.5, -0.5}, {1.5, -0.5}, {-1.5, 0.5}, {-0.5, 0.5}, {0.5, 0.5}, {1.5, 0.5}, {-1.5, 1.5}, {-0.5, 1.5}, {0.5, 1.5}, {1.5, 1.5}},
    MAP_HEXAGON = {{-1.5, -1.6}, {0.5, -1.6}, {-0.5, -0.8}, {1.5, -0.8}, {-1.5, 0}, {0.5, 0}, {-0.5, 0.8}, {1.5, 0.8}, {-1.5, 1.6}, {0.5, 1.6}},
    MAP_HEXAGON2 = {{-0.5, -1.6}, {1.5, -1.6},{-1.5, -0.8}, {0.5, -0.8}, {-0.5, 0}, {1.5, 0}, {-1.5, 0.8}, {0.5, 0.8}, {-0.5, 1.6}, {1.5, 1.6}},
}

-- heading 360 = 0
local HEADSNAPS =
{
    IDS_2x2 = {
        [0] = {1, 3, 2, 4},
        [45] = {1, 2, 3, 4},
        [90] = {2, 1, 4, 3},
        [135] = {2, 4, 1, 3},
        [180] = {4, 2, 3, 1},
        [225] = {4, 3, 2, 1},
        [270] = {3, 4, 1, 2},
        [315] = {3, 1, 4, 2}},

    IDS_3x3 = {
        [0] = {1, 4, 7, 2, 5, 8, 3, 6, 9},
        [45] = {1, 2, 4, 3, 5, 7, 6, 8, 9},
        [90] = {3, 2, 1, 6, 5, 4, 9, 8, 7},
        [135] = {3, 6, 2, 9, 5, 1, 8, 4, 7},
        [180] = {9, 6, 3, 8, 5, 2, 7, 4, 1},
        [225] = {9, 8, 6, 7, 5, 3, 4, 2, 1},
        [270] = {7, 8, 9, 4, 5, 6, 1, 2, 3},
        [315] = {7, 4, 8, 1, 5, 9, 2, 6, 3}},

    IDS_4x4 = {
        [0] = {1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15, 4, 8, 12, 16},
        [45] = {1, 2, 5, 3, 6, 9, 4, 7, 10, 13, 8, 11, 14, 12, 15, 16},
        [90] = {4, 3, 2, 1, 8, 7, 6, 5, 12, 11, 10, 9, 16, 15, 14, 13},
        [135] = {4, 8, 3, 12, 7, 2, 16, 11, 6, 1, 15, 10, 5, 14, 9, 13},
        [180] = {16, 12, 8, 4, 15, 11, 7, 3, 14, 10, 6, 2, 13, 9, 5, 1},
        [225] = {16, 15, 12, 14, 11, 8, 13, 10, 7, 4, 9, 6, 3, 5, 2, 1},
        [270] = {13, 14, 15, 16, 9, 10, 11, 12, 5, 6, 7, 8, 1, 2, 3, 4},
        [315] = {13, 9, 14, 5, 10, 15, 1, 6, 11, 16, 2, 7, 12, 3, 8, 4}},

    IDS_HEXAGON = { 
        [0] = {1, 5, 9, 3, 7, 2, 6, 10, 4, 8},
        [45] = {1, 2, 3, 5, 4, 6, 7, 9, 8, 10},
        [90] = {2, 1, 4, 3, 6, 5, 8, 7, 10, 9},
        [135] = {4, 2, 8, 6, 3, 1, 10, 7, 5, 9},
        [180] = {8, 4, 10, 6, 2, 7, 3, 9, 5, 1},
        [225] = {10, 8, 9, 7, 6, 4, 5, 3, 2, 1},
        [270] = {9, 10, 7, 8, 5, 6, 3, 4, 1, 2},
        [315] = {9, 5, 7, 10, 1, 3, 6, 8, 2, 4}},

    IDS_HEXAGON2 = {
        [0] = {3, 7, 1, 5, 9, 4, 8, 2, 6, 10},
        [45] = {1, 3, 2, 4, 5, 7, 6, 8, 9, 10},
        [90] = {2, 1, 4, 3, 6, 5, 8, 7, 10, 9},
        [135] = {2, 6, 4, 1, 10, 8, 5, 3, 9, 7},
        [180] = {10, 6, 2, 8, 4, 9, 5, 1, 7, 3},
        [225] = {10, 9, 8, 6, 7, 5, 4, 2, 3, 1},
        [270] = {9, 10, 7, 8, 5, 6, 3, 4, 1, 2},
        [315] = {7, 9, 3, 5, 8, 10, 1, 4, 6, 2}}
}

local function DoActionTill(self, pos)
    DebugPrint("-------------------------------------")
    DebugPrint("DoActionTill pos:", pos)
    local cantill = true
    local x, y, z = pos:Get()
    local item = self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)

    if not item then 
		DebugPrint("not item")
		return false 
	end

    if self.isquagmire then
        cantill = TheWorld.Map:CanTillSoilAtPoint(pos)
    else
        cantill = TheWorld.Map:CanTillSoilAtPoint(x, y, z)
    end

    if cantill then
		DebugPrint("cantill")
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
        until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving")
              and self.inst:HasTag("idle") and not self.inst.components.playercontroller:IsDoingOrWorking()
    end
	DebugPrint("end")

    return true
end

local function DoActionDeploy(self, pos)
    DebugPrint("-------------------------------------")
    DebugPrint("DoActionDeploy pos: ", pos)
    local x, y, z = pos:Get()
    local item = self.inst.replica.inventory and self.inst.replica.inventory:GetActiveItem()

    if not item then return false end

    if TheWorld.Map:CanTillSoilAtPoint(x, y, z, true) then
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
        until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving")
              and self.inst:HasTag("idle") and not self.inst.components.playercontroller:IsDoingOrWorking()
    end

    return true
end

local SnapTiller = Class(function(self, inst)
    self.inst = inst
    self.snapmode = 0
    self.isquagmire = false
    self.actionthread = nil
    self.snaplistaction = nil
	self.queue_manager = QueueManager(self.inst)
end)

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

function SnapTiller:GetSnapListOnTile(tilex, tiley, heading)
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
        if self.snapmode == 1 then
            if self:HasAdjacentSoilTile(tilecenter) then
                if heading ~= nil and HEADSNAPS.IDS_3x3[heading] ~= nil then
                    for _, i in ipairs(HEADSNAPS.IDS_3x3[heading]) do
                        table.insert(map, TILESNAPS.MAP_3x3[i])
                    end
                else
                    map = TILESNAPS.MAP_3x3
                end
            else
                if heading ~= nil and HEADSNAPS.IDS_4x4[heading] ~= nil then
                    for _, i in ipairs(HEADSNAPS.IDS_4x4[heading]) do
                        table.insert(map, TILESNAPS.MAP_4x4[i])
                    end
                else
                    map = TILESNAPS.MAP_4x4
                end
            end
        elseif self.snapmode == 2 then
            if heading ~= nil and HEADSNAPS.IDS_4x4[heading] ~= nil then
                for _, i in ipairs(HEADSNAPS.IDS_4x4[heading]) do
                    table.insert(map, TILESNAPS.MAP_4x4[i])
                end
            else
                map = TILESNAPS.MAP_4x4
            end
        elseif self.snapmode == 3 then
            if heading ~= nil and HEADSNAPS.IDS_3x3[heading] ~= nil then
                for _, i in ipairs(HEADSNAPS.IDS_3x3[heading]) do
                    table.insert(map, TILESNAPS.MAP_3x3[i])
                end
            else
                map = TILESNAPS.MAP_3x3
            end
        elseif self.snapmode == 4 then
            if heading ~= nil and HEADSNAPS.IDS_2x2[heading] ~= nil then
                for _, i in ipairs(HEADSNAPS.IDS_2x2[heading]) do
                    table.insert(map, TILESNAPS.MAP_2x2[i])
                end
            else
                map = TILESNAPS.MAP_2x2
            end
        elseif self.snapmode == 5 then
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

function SnapTiller:StartAutoTillTile(tile)
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
		local ents = TheSim:FindEntities(snap[1], 0, snap[2], 0.005, {"soil"})
		local flagremove = false

		for _, v in pairs(ents) do
			if not v:HasTag("NOCLICK") then
				flagremove = true
				break
			end
		end 

		if flagremove then table.remove(self.snaplistaction, i) end
	end

	-- Process all snaps for this tile
	while self.inst:IsValid() do
		local coord = self.snaplistaction[index]

		if coord == nil then break end
		if not DoActionTill(self, Point(coord[1], 0, coord[2])) then break end

		index = index + 1
	end
    return true
end

function SnapTiller:StartAutoTillAtPoint()
    DebugPrint("-------------------------------------")
    DebugPrint("StartAutoTillAtPoint")
    local manager = self.queue_manager	
	local input_pos = self.inst:GetPosition()
	if not TheInput:ControllerAttached() then
		input_pos = TheInput:GetWorldPosition()
	end
	
	local current_time = GetTime()
	if manager.last_click.time and (current_time - manager.last_click.time) <= manager.double_click_speed then
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
		return manager:StartProcessThread(function(tile)
				-- Existing code that till a single tile
				DebugPrint("Handle single tile")
				self:StartAutoTillTile(tile)  -- Synchronous processing
			end)
    end
end

function SnapTiller:StartAutoDeployTile(tile)
    DebugPrint("-------------------------------------")
    DebugPrint("StartAutoDeployTile")
	local target_pos = tile:GetPosition()
	DebugPrint("tile:GetPosition(): ", target_pos)

	local tilex, tiley = TheWorld.Map:GetTileCoordsAtPoint(target_pos.x, target_pos.y, target_pos.z)
	local index = 1

	self.snaplistaction = self:GetSnapListOnTile(tilex, tiley, TheCamera.heading)

	-- 250318 VanCa: Remove this part to plant in narrowed spaces with Wormwood
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

	while self.inst:IsValid() do
		local coord = self.snaplistaction[index]

		if coord == nil then break end
		if not DoActionDeploy(self, Point(coord[1], 0, coord[2])) then break end

		index = index + 1
	end
    return true
end

function SnapTiller:StartAutoDeployAtPoint()
    DebugPrint("-------------------------------------")
    DebugPrint("StartAutoDeployAtPoint")
    local manager = self.queue_manager	
	local input_pos = self.inst:GetPosition()
	if not TheInput:ControllerAttached() then
		input_pos = TheInput:GetWorldPosition()
	end
	
	local current_time = GetTime()
	if manager.last_click.time and (current_time - manager.last_click.time) <= manager.double_click_speed then
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
		return manager:StartProcessThread(function(tile)
				-- Existing code that till a single tile
				DebugPrint("Handle single tile")
				self:StartAutoDeployTile(tile)  -- Synchronous processing
			end)
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
