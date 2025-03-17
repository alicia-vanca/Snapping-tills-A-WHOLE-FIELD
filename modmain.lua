Assets =
{
    Asset("ANIM", "anim/snaptillplacer.zip"),
}

PrefabFiles =
{
    "snaptillplacer",
}

local _G = GLOBAL
mods = _G.rawget(_G, "mods") or (function() local m = {} _G.rawset(_G, "mods", m) return m end)()

local configlanguage = GetModConfigData("language")

_G.TUNING.SNAPPINGTILLS = {}
_G.TUNING.SNAPPINGTILLS.LANGUAGE = "en"
_G.STRINGS.SNAPPINGTILLS =
{
    ACTION_TILL_TILE = "Auto till tile",
    ACTION_DEPLOY_TILE = "Auto planting tile",
    ACTION_CHANGE_SNAP_MODE = "Toggle snap mode",
    OFF = "Snapping tills: Off",
    CONTROLLER_AUTO_TILLING = " [auto tilling]",
    SNAP_MODE_OPTIMIZED = "Snapping tills: optimized mode",
    SNAP_MODE_4x4 = "Snapping tills: mode 4x4",
    SNAP_MODE_3x3 = "Snapping tills: mode 3x3",
    SNAP_MODE_2x2 = "Snapping tills: mode 2x2",
    SNAP_MODE_HEXAGON = "Snapping tills: mode hexagon",
}

if configlanguage == "auto" then
    local currloc = _G.GetCurrentLocale()
    if currloc ~= nil and currloc.code == "zh" then
        _G.TUNING.SNAPPINGTILLS.LANGUAGE = "sch"
    end

    if mods.RussianLanguagePack or mods.UniversalTranslator then
        _G.TUNING.SNAPPINGTILLS.LANGUAGE = "ru"
    end

    if mods.EspanolLanguagePack or mods.UniversalTranslator then
        _G.TUNING.SNAPPINGTILLS.LANGUAGE = "esp"
    end
else
    _G.TUNING.SNAPPINGTILLS.LANGUAGE = configlanguage
end

if _G.TUNING.SNAPPINGTILLS.LANGUAGE == "sch" then
    --Simplified Chinese
    _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE= "自动犁地"
    _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE= "自动种地"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE = "切换犁地模式"
    _G.STRINGS.SNAPPINGTILLS.OFF = "犁地模式: 关闭"
    _G.STRINGS.SNAPPINGTILLS.CONTROLLER_AUTO_TILLING = " [自动耕作]"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED = "犁地模式: 最佳(3x3)"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4 = "犁地模式: 4x4"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3 = "犁地模式: 3x3"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2 = "犁地模式: 2x2"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON = "犁地模式: 六边形(1田10坑)"
elseif _G.TUNING.SNAPPINGTILLS.LANGUAGE == "ru" then
    -- Russian
    _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE= "Вспахать автоматически тайл"
    _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE= "Засадить автоматически тайл"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE = "Сменить режим привязки"
    _G.STRINGS.SNAPPINGTILLS.OFF = "Snapping tills: отключён"
    _G.STRINGS.SNAPPINGTILLS.CONTROLLER_AUTO_TILLING = " [Автоматическая вспашка]"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED = "Snapping tills: оптимизированный режим"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4 = "Snapping tills: режим 4x4"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3 = "Snapping tills: режим 3x3"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2 = "Snapping tills: режим 2x2"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON = "Snapping tills: режим шестиугольный"
elseif _G.TUNING.SNAPPINGTILLS.LANGUAGE == "esp" then
    -- Español
    _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE= "Arrar Tierra Automaticamente"
    _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE= "Plantar automaticamente"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE = "Cambiar A Snap Mod"
    _G.STRINGS.SNAPPINGTILLS.OFF = "Snapping tills: Desactivado"
    _G.STRINGS.SNAPPINGTILLS.CONTROLLER_AUTO_TILLING = " [Arrar Automaticamente]"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED = "Snapping tills: Modo Optimizado"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4 = "Snapping tills: zona de 4x4"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3 = "Snapping tills: zona de 3x3"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2 = "Snapping tills: zona de 2x2"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON = "Snapping tills: Hexagono"
end

local persistentdata = require("persistentdata")
local datacontainer = persistentdata("snappingtills")

datacontainer:Load()

local keychagemode = GetModConfigData("keychagemode")
local visiblesnaps = GetModConfigData("visiblesnaps")
local isquagmire = _G.TheNet:GetServerGameMode() == "quagmire"
local is_on_geometricplacement = false
local controller_autotilling = false

local continuecontrols = {[_G.CONTROL_ROTATE_LEFT] = true, [_G.CONTROL_ROTATE_RIGHT] = true, [_G.CONTROL_MAP] = true, [_G.CONTROL_ZOOM_IN] = true, [_G.CONTROL_ZOOM_OUT] = true, [_G.CONTROL_MAP_ZOOM_IN] = true, [_G.CONTROL_MAP_ZOOM_OUT] = true, [_G.CONTROL_SCROLLBACK] = true, [_G.CONTROL_SCROLLFWD] = true}

_G.ACTIONS.TILL.stroverridefn = function(act)
    if _G.TheInput:ControllerAttached() and controller_autotilling then
        return _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE
    elseif _G.TheInput:IsKeyDown(_G.KEY_LSHIFT) and (not _G.ACTIONS.TILL.tile_placer or not is_on_geometricplacement) and
       _G.ThePlayer.components.snaptiller.snapmode ~= 0 then
        return _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE
    end

    return nil
end

_G.ACTIONS.DEPLOY.stroverridefn = function(act)
    if _G.TheInput:IsKeyDown(_G.KEY_LSHIFT) and not is_on_geometricplacement and
      _G.ThePlayer.components.snaptiller.snapmode ~= 0 and act.invobject:HasTag("deployedfarmplant") then
        return _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE
    end

    return nil
end

local function GetSnapModeString(mode)
    local postfix = ""

    if _G.TheInput:ControllerAttached() and controller_autotilling then
        postfix = " [auto tilling]"
    end

    if mode == 0 then
        return _G.STRINGS.SNAPPINGTILLS.OFF
    elseif mode == 1 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED..postfix
    elseif mode == 2 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4..postfix
    elseif mode == 3 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3..postfix
    elseif mode == 4 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2..postfix
    elseif mode == 5 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON..postfix
    end

    return ""
end

local function IsDefaultScreen()
    local activescreen = _G.TheFrontEnd:GetActiveScreen()
    local screen = activescreen and activescreen.name or ""
    return screen:find("HUD") ~= nil and not isquagmire and
           _G.ThePlayer ~= nil and _G.ThePlayer.components ~= nil and _G.ThePlayer.components.snaptiller ~= nil and
           not _G.ThePlayer.HUD:IsChatInputScreenOpen() and not _G.ThePlayer.HUD.writeablescreen
end

local function IsHandSlotItemHoe(slot)
    return slot ~= nil and slot.equipslot == _G.EQUIPSLOTS.HANDS and slot.tile ~= nil and slot.tile.item ~= nil and
           (slot.tile.item.prefab == "farm_hoe" or
            slot.tile.item.prefab == "golden_farm_hoe" or
            slot.tile.item.prefab == "shovel_lunarplant" or
            slot.tile.item.prefab == "quagmire_hoe")
end

local function ToggleSnapMode()
    if IsDefaultScreen() then
        local snapmode = _G.ThePlayer.components.snaptiller.snapmode

        if _G.TheInput:ControllerAttached() and snapmode > 0 then
            if controller_autotilling then
                snapmode = snapmode + 1
                controller_autotilling = false
            else
                controller_autotilling = true
            end
        else
            snapmode = snapmode + 1
        end

        if snapmode > 5 then
            snapmode = 0
        end

        _G.ThePlayer.components.snaptiller.snapmode = snapmode

        datacontainer:SetValue("version", "1.1.0")
        datacontainer:SetValue("snapmode", snapmode)
        datacontainer:SetValue("controller_autotilling", controller_autotilling)
        datacontainer:Save()

        _G.ThePlayer.components.talker:Say(GetSnapModeString(snapmode))
    end
end

if _G.KnownModIndex:IsModEnabled("workshop-351325790") then
    local original_print = _G.print

    AddComponentPostInit("placer", function(self, inst)
        -- so crazy, but no other way
        _G.print = function() end -- KnownModIndex functions kinda spam the logs
        local config = _G.KnownModIndex:LoadModConfigurationOptions("workshop-351325790", true)
        for _, v in ipairs(config) do
            if v.name == "CTRL" then
                is_on_geometricplacement = not v.saved
                break
            end
        end
        _G.print = original_print --restore print functionality!

        if is_on_geometricplacement then
            if _G.ThePlayer.components.snaptillplacer and _G.ACTIONS.TILL.tile_placer == "till_actiongridplacer" then
                _G.ThePlayer.components.snaptillplacer:Hide()
            elseif _G.ThePlayer.components.snaptillplacer then
                _G.ThePlayer.components.snaptillplacer:Hide()
            end

            self.inst:ListenForEvent("onremove", function()
                if _G.ThePlayer.components.snaptillplacer and _G.ACTIONS.TILL.tile_placer == "till_actiongridplacer" then
                    _G.ThePlayer.components.snaptillplacer:Show()
                elseif _G.ThePlayer.components.snaptillplacer then
                _G.ThePlayer.components.snaptillplacer:Show()
                end
            end)
        end
    end)
end

AddComponentPostInit("placer", function(self, inst)
    local original_OnUpdate = self.OnUpdate
    self.OnUpdate = function(self, dt)
        original_OnUpdate(self, dt)
        if not is_on_geometricplacement then
            if self.inst.prefab == "seeds_placer" and _G.ThePlayer ~= nil and _G.ThePlayer:HasTag("plantkin") then
                if not _G.TheInput:ControllerAttached() then
                    local pos = _G.ThePlayer.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
                    self.inst.Transform:SetPosition(pos:Get())
                    self.selected_pos = pos
                end
            end
        end
    end
end)

AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= _G.ThePlayer then return end

    self.inst:AddComponent("snaptiller")

    if visiblesnaps then
        self.inst:AddComponent("snaptillplacer")
    end

    local version = datacontainer:GetValue("version")
    local snapmode = datacontainer:GetValue("snapmode")
    local _controller_autotilling = datacontainer:GetValue("controller_autotilling")

    --patch
    if version == nil then
        snapmode = 1
    end

    if snapmode == nil then
        snapmode = 1
    end
    
    if type(_controller_autotilling) == "boolean" then
        controller_autotilling = _controller_autotilling
    end

    self.inst.components.snaptiller.snapmode = snapmode
    self.inst.components.snaptiller.isquagmire = isquagmire

    local original_OnControl = self.OnControl
    local original_OnRightClick = self.OnRightClick
    local original_DoControllerAltActionButton = self.DoControllerAltActionButton

    self.OnControl = function(self, control, down)
        original_OnControl(self, control, down)

        if down and not continuecontrols[control] and self.inst and self.inst.HUD and not self.inst.HUD:HasInputFocus() and
          self.inst.components.snaptiller and self.inst.components.snaptiller.actionthread and self.inst.components.snaptiller.snaplistaction then
           self.inst.components.snaptiller:ClearActionThread()
        end
    end

    self.OnRightClick = function(self, down)
        local autotilldown = false

        if _G.TheInput:IsKeyDown(_G.KEY_LSHIFT) and not down then
            autotilldown = true
        end

        if not down and not autotilldown then
            return original_OnRightClick(self, down)
        end

        local act = self:GetRightMouseAction()

        if _G.ThePlayer.components.snaptiller.snapmode ~= 0 and act then
            if act.action == _G.ACTIONS.DEPLOY and act.invobject:HasTag("deployedfarmplant") and not is_on_geometricplacement then
                if autotilldown then
                    self.inst.components.snaptiller:StartAutoDeployTile()
                    return
                else
                    local playercontroller = self.inst.components.playercontroller
                    local pos = self.inst.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
                    local item = self.inst.replica.inventory and self.inst.replica.inventory:GetActiveItem()
                    local act = _G.BufferedAction(self.inst, nil, _G.ACTIONS.DEPLOY, item, pos)

                    if playercontroller.ismastersim then
                        self.inst.components.combat:SetTarget(nil)
                        playercontroller:DoAction(act)
                    else
                        if playercontroller.locomotor then
                            act.preview_cb = function()
                                _G.SendRPCToServer(_G.RPC.RightClick, _G.ACTIONS.DEPLOY.code, pos.x, pos.z, nil, nil, true)
                            end
                            playercontroller:DoAction(act)
                        else
                            _G.SendRPCToServer(_G.RPC.RightClick, _G.ACTIONS.DEPLOY.code, pos.x, pos.z, nil, nil, true)
                        end
                    end
                    return
                end
            end

            if act.action == _G.ACTIONS.TILL and (not _G.ACTIONS.TILL.tile_placer or not is_on_geometricplacement) then
                if autotilldown then
                    self.inst.components.snaptiller:StartAutoTillTile()
                    return
                else
                    local playercontroller = self.inst.components.playercontroller
                    local pos = self.inst.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
                    local item = self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
                    local act = _G.BufferedAction(self.inst, nil, _G.ACTIONS.TILL, item, pos)

                    if playercontroller.ismastersim then
                        self.inst.components.combat:SetTarget(nil)
                        playercontroller:DoAction(act)
                    else
                        if playercontroller.locomotor then
                            act.preview_cb = function()
                                _G.SendRPCToServer(_G.RPC.RightClick, _G.ACTIONS.TILL.code, pos.x, pos.z, nil, nil, true)
                            end
                            playercontroller:DoAction(act)
                        else
                            _G.SendRPCToServer(_G.RPC.RightClick, _G.ACTIONS.TILL.code, pos.x, pos.z, nil, nil, true)
                        end
                    end
                    return
                end
            end
        end

        original_OnRightClick(self, down)
    end

    self.DoControllerAltActionButton = function(self)
        local _, act = self:GetGroundUseAction()

        if _G.ThePlayer.components.snaptiller.snapmode ~= 0 and act then
            if act.action == _G.ACTIONS.TILL and act.pos and (not _G.ACTIONS.TILL.tile_placer or not is_on_geometricplacement) then
                if controller_autotilling then
                    self.inst.components.snaptiller:StartAutoTillTile()
                else
                    local pos = self.inst.components.snaptiller:GetSnap(Point(act.pos.local_pt.x, act.pos.local_pt.y, act.pos.local_pt.z))
                    act.pos = _G.DynamicPosition(pos)

                    if self.ismastersim then
                        self.inst.components.combat:SetTarget(nil)
                    elseif self.locomotor == nil then
                        self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                        _G.SendRPCToServer(_G.RPC.ControllerAltActionButtonPoint, act.action.code, act.pos.local_pt.x, act.pos.local_pt.z, nil, act.action.canforce, isspecial, act.action.mod_name, act.pos.walkable_platform, act.pos.walkable_platform ~= nil)
                    elseif self:CanLocomote() then
                        act.preview_cb = function()
                            self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                            local isreleased = not _G.TheInput:IsControlPressed(_G.CONTROL_CONTROLLER_ALTACTION)
                            _G.SendRPCToServer(_G.RPC.ControllerAltActionButtonPoint, act.action.code, act.pos.local_pt.x, act.pos.local_pt.z, isreleased, nil, isspecial, act.action.mod_name, act.pos.walkable_platform, act.pos.walkable_platform ~= nil)
                        end
                    end

                    self:DoAction(act)
                end
                return
            end
        end

        original_DoControllerAltActionButton(self)
    end
end)

AddClassPostConstruct("components/inventoryitem_replica", function(self, inst)
    local original_CanDeploy = self.CanDeploy
    self.CanDeploy = function(self, pt, ...)
        -- ACTIONS.DEPLOY.stroverridefn does not use intensive checks, so do the same here
        if self.inst:HasTag("deployedfarmplant") and _G.ThePlayer.components.snaptiller.snapmode ~= 0 and not is_on_geometricplacement then
            pt = _G.ThePlayer.components.snaptiller:GetSnap(pt)
        end
        return original_CanDeploy(self, pt, ...)
    end
end)

-- for support controller 
AddClassPostConstruct("widgets/inventorybar", function(self)
    local original_OnControl = self.OnControl
    local original_UpdateCursorText = self.UpdateCursorText

    self.OnControl = function(self, control, down)
        local res = original_OnControl(self, control, down)

        if self.open and not down and not isquagmire and control == _G.CONTROL_MENU_MISC_2 and IsHandSlotItemHoe(self.active_slot) then
            ToggleSnapMode()
            return true
        end

        return res
    end

    self.UpdateCursorText = function(self)
        original_UpdateCursorText(self)

        if self.open and not isquagmire and IsHandSlotItemHoe(self.active_slot) then
            local str = self.actionstringbody:GetString().."\n".._G.TheInput:GetLocalizedControl(_G.TheInput:GetControllerID(), _G.CONTROL_MENU_MISC_2).." ".._G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE
            self.actionstringbody:SetString(str)
            
            local _, h0 = self.actionstringtitle:GetRegionSize()
            local _, h1 = self.actionstringbody:GetRegionSize()

            self.actionstringtitle:SetPosition(0, h0 / 2 + h1)
            self.actionstringbody:SetPosition(0, h1 / 2)
        end
    end
end)

-- patch key, fixed shit after update 1.8
local togglekey = nil
if keychagemode ~= nil then
    togglekey = _G[keychagemode]
end

if togglekey == nil then
    togglekey = _G.KEY_L
end

_G.TheInput:AddKeyUpHandler(togglekey, function(key)
    ToggleSnapMode()
end)

