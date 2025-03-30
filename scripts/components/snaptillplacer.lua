local function MakeSnapTillPlacer(self, x, z, index)
    if self.linked == nil then
        self.linked = {}
    end

    local inst = SpawnPrefab("snaptillplacer")
    if inst then
        inst.Transform:SetPosition(x, 0, z)
        --inst:SetDebugNumber(index)
        table.insert(self.linked, inst)
    end
end

local function ApplayVisible(self)
    if self.linked ~= nil then
        for _, v in ipairs(self.linked) do
            if self.visible then
                v:Show()
            else
                v:Hide()
            end
        end
    end
end

local SnapTillPlacer =
    Class(
    function(self, inst)
        self.inst = inst
        self.linked = nil
        self.deployed_farm_plant = false
        self.cache_tile_pos = nil
        self.cache_snap_mode = nil
        self.cache_adjacent_soil = nil
        self.visible = true
        self.inst:StartUpdatingComponent(self)
    end
)

function SnapTillPlacer:ClearLinked()
    if self.linked ~= nil then
        for _, v in ipairs(self.linked) do
            v:Remove()
        end
        self.linked = nil
    end
end

function SnapTillPlacer:Hide()
    self.visible = false
    ApplayVisible(self)
end

function SnapTillPlacer:Show()
    self.visible = true
    ApplayVisible(self)
end

function SnapTillPlacer:OnUpdate(dt)
    if self.inst == nil then
        self:ClearLinked()
        return
    end

    if self.inst.components.snaptiller.snap_mode == 0 then
        self:ClearLinked()
        return
    end

    if
        self.inst.components.snaptiller == nil or self.inst.replica.inventory == nil or
            (self.inst.replica.rider and self.inst.replica.rider:IsRiding())
     then
        self:ClearLinked()
        return
    end

    local activeitem = self.inst.replica.inventory:GetActiveItem()

    -- 250322 VanCa: Change "deployed_farm_plant" from a local variable to a component variable
    -- so that the "placer" events can utilize it.
    -- "deployed_farm_plant" flag is decided in "placer" event (modmain.lua)

    -- Reset flag
    if self.deployed_farm_plant and not (activeitem and activeitem:HasTag("deployedfarmplant")) then
        self.deployed_farm_plant = false
    end

    if not self.deployed_farm_plant then
        local equippeditem = self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if
            not equippeditem or
                (equippeditem and equippeditem.prefab ~= "farm_hoe" and equippeditem.prefab ~= "golden_farm_hoe" and
                    equippeditem.prefab ~= "shovel_lunarplant" and
                    equippeditem.prefab ~= "quagmire_hoe")
         then
            self:ClearLinked()
            return
        end
    end

    local pos = nil

    if TheInput:ControllerAttached() then
        pos = Point(self.inst.entity:LocalToWorldSpace(0, 0, 0))
    else
        if not self.deployed_farm_plant and activeitem ~= nil then
            self:ClearLinked()
            return
        end

        pos = TheInput:GetWorldPosition()
    end

    if not pos then
        self:ClearLinked()
        return
    end

    local tilex, tiley = TheWorld.Map:GetTileCoordsAtPoint(pos.x, pos.y, pos.z)
    local tile = TheWorld.Map:GetTile(tilex, tiley)

    if self.cache_tile_pos == nil then
        self.cache_tile_pos = {tilex, tiley}
    end

    if self.cache_snap_mode == nil then
        self.cache_snap_mode = self.inst.components.snaptiller.snap_mode
    end

    if self.cache_snap_mode == 1 then
        local res =
            self.inst.components.snaptiller:HasAdjacentSoilTile(Point(TheWorld.Map:GetTileCenterPoint(tilex, tiley)))
        if self.cache_adjacent_soil ~= res then
            self.cache_adjacent_soil = res
            self:ClearLinked()
        end
    end

    if (tile == WORLD_TILES.FARMING_SOIL or tile == WORLD_TILES.QUAGMIRE_SOIL) or self.deployed_farm_plant then
        if
            self.cache_tile_pos[1] ~= tilex or self.cache_tile_pos[2] ~= tiley or
                self.cache_snap_mode ~= self.inst.components.snaptiller.snap_mode or
                self.linked == nil
         then
            self:ClearLinked()
            local snaplist = self.inst.components.snaptiller:GetSnapListOnTile(tilex, tiley)
            for i, v in ipairs(snaplist) do
                MakeSnapTillPlacer(self, v[1], v[2], i)
            end
            self.cache_tile_pos = {tilex, tiley}
            self.cache_snap_mode = self.inst.components.snaptiller.snap_mode
            ApplayVisible(self)
        end
    else
        self:ClearLinked()
    end

    if self.linked ~= nil then
        local can = true
        for _, v in ipairs(self.linked) do
            if self.deployed_farm_plant then
                local x, y, z = v.Transform:GetWorldPosition()
                can = TheWorld.Map:CanTillSoilAtPoint(x, y, z, true)
            else
                if self.inst.components.snaptiller.isquagmire then
                    can = TheWorld.Map:CanTillSoilAtPoint(Point(v.Transform:GetWorldPosition()))
                else
                    can = TheWorld.Map:CanTillSoilAtPoint(v.Transform:GetWorldPosition())
                end
            end

            if can then
                v.AnimState:PlayAnimation("on", false)
            else
                v.AnimState:PlayAnimation("off", false)
            end
        end
    end
end

SnapTillPlacer.OnRemoveEntity = SnapTillPlacer.ClearLinked
SnapTillPlacer.OnRemoveFromEntity = SnapTillPlacer.ClearLinked

return SnapTillPlacer
