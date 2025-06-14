-- 250321 VanCa: Add intercropping handling

-- 250324 VanCa: Integrate KeyBind UI by 李皓奇
-- https://github.com/liolok/DST-KeyBind-UI
modimport("keybind")

Assets = {
    Asset("ANIM", "anim/snaptillplacer.zip")
}

PrefabFiles = {
    "snaptillplacer"
}

local _G = GLOBAL

function table_print(tt, indent, done)
    done = done or {}
    indent = indent or 0
    local spacer = string.rep("  ", indent)

    if type(tt) == "table" then
        if done[tt] then
            return "table (circular reference)"
        end
        done[tt] = true

        local sb = {"{\n"}
        for key, value in pairs(tt) do
            table.insert(sb, spacer .. "  ")
            if type(key) == "number" then
                table.insert(sb, string.format("[%d] = ", key))
            else
                table.insert(sb, string.format("%s = ", tostring(key)))
            end

            -- Expand 1 level deep, show type for deeper tables
            if type(value) == "table" then
                if indent < 1 then -- Only expand up to 1 level deep
                    table.insert(sb, table_print(value, indent + 1, done))
                else
                    table.insert(sb, tostring(value) .. " (table)")
                end
            else
                table.insert(sb, tostring(value) .. " (" .. type(value) .. ")")
            end
            table.insert(sb, ",\n")
        end
        table.insert(sb, spacer .. "}")
        done[tt] = nil -- Allow reuse of this table in other branches
        return table.concat(sb)
    else
        return tostring(tt) .. " (" .. type(tt) .. ")"
    end
end

function to_string(tbl)
    if tbl == nil then
        return "nil"
    end
    if type(tbl) == "table" then
        return table_print(tbl, 0, {})
    elseif "string" == type(tbl) then
        return tbl
    end
    return tostring(tbl) .. " (" .. type(tbl) .. ")"
end

local DebugPrint = false and function(...)
        local msg = "[SnappingTills]"
        for i = 1, arg.n do
            msg = msg .. " " .. to_string(arg[i])
        end
        if arg.n > 1 then
            msg = msg .. "\n"
        end
        print(msg)
    end or function()
    end
_G.SnappingTills = {}
_G.SnappingTills.DebugPrint = DebugPrint

mods = _G.rawget(_G, "mods") or (function()
        local m = {}
        _G.rawset(_G, "mods", m)
        return m
    end)()

local configlanguage = GetModConfigData("language")

_G.TUNING.SNAPPINGTILLS = {}
_G.TUNING.SNAPPINGTILLS.LANGUAGE = "en"
_G.STRINGS.SNAPPINGTILLS = {
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
    ACTION_CHANGE_INTERCROPPING_MODE = "Toggle intercropping mode",
    INTERCROPPING = {
        [1] = "Intercropping: Inventory based",
        -- [1] = "Intercropping: Off",
        [2] = "Intercropping: 2 types",
        [3] = "Intercropping: 3 types",
        [4] = "Intercropping: 4 types"
    }
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
    _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE = "自动犁地"
    _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE = "自动种地"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE = "切换犁地模式"
    _G.STRINGS.SNAPPINGTILLS.OFF = "犁地模式: 关闭"
    _G.STRINGS.SNAPPINGTILLS.CONTROLLER_AUTO_TILLING = " [自动耕作]"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED = "犁地模式: 最佳(3x3)"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4 = "犁地模式: 4x4"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3 = "犁地模式: 3x3"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2 = "犁地模式: 2x2"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON = "犁地模式: 六边形(1田10坑)"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_INTERCROPPING_MODE = "切换间作模式"
    _G.STRINGS.SNAPPINGTILLS.INTERCROPPING = {
        [1] = "间作模式：基于物品栏",
        -- [1] = "间作模式：关闭",
        [2] = "间作模式：2 种",
        [3] = "间作模式：3 种",
        [4] = "间作模式：4 种"
    }
elseif _G.TUNING.SNAPPINGTILLS.LANGUAGE == "ru" then
    -- Russian
    _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE = "Вспахать автоматически тайл"
    _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE = "Засадить автоматически тайл"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE = "Сменить режим привязки"
    _G.STRINGS.SNAPPINGTILLS.OFF = "Snapping tills: отключён"
    _G.STRINGS.SNAPPINGTILLS.CONTROLLER_AUTO_TILLING = " [Автоматическая вспашка]"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED = "Snapping tills: оптимизированный режим"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4 = "Snapping tills: режим 4x4"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3 = "Snapping tills: режим 3x3"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2 = "Snapping tills: режим 2x2"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON = "Snapping tills: режим шестиугольный"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_INTERCROPPING_MODE = "Переключить совмещение"
    _G.STRINGS.SNAPPINGTILLS.INTERCROPPING = {
        [1] = "Совмещение: По слотам инвентаря",
        -- [1] = "Совмещение: Выкл",
        [2] = "Совмещение: 2 вида",
        [3] = "Совмещение: 3 вида",
        [4] = "Совмещение: 4 вида"
    }
elseif _G.TUNING.SNAPPINGTILLS.LANGUAGE == "esp" then
    -- Español
    _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE = "Arrar Tierra Automaticamente"
    _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE = "Plantar automaticamente"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE = "Cambiar A Snap Mod"
    _G.STRINGS.SNAPPINGTILLS.OFF = "Snapping tills: Desactivado"
    _G.STRINGS.SNAPPINGTILLS.CONTROLLER_AUTO_TILLING = " [Arrar Automaticamente]"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED = "Snapping tills: Modo Optimizado"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4 = "Snapping tills: zona de 4x4"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3 = "Snapping tills: zona de 3x3"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2 = "Snapping tills: zona de 2x2"
    _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON = "Snapping tills: Hexagono"
    _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_INTERCROPPING_MODE = "Alternar cultivo intercalado"
    _G.STRINGS.SNAPPINGTILLS.INTERCROPPING = {
        [1] = "Cultivo intercalado: Basado en inventario",
        -- [1] = "Cultivo intercalado: Desactivado",
        [2] = "Cultivo intercalado: 2 tipos",
        [3] = "Cultivo intercalado: 3 tipos",
        [4] = "Cultivo intercalado: 4 tipos"
    }
end

local persistentdata = require("persistentdata")
local datacontainer = persistentdata("snappingtills")

datacontainer:Load()

local keychagemode = GetModConfigData("keychagemode")
local visiblesnaps = GetModConfigData("visiblesnaps")
local isquagmire = _G.TheNet:GetServerGameMode() == "quagmire"
local is_on_geometricplacement = false
local controller_autotilling = false
local controller_autoplanting = false

-- 250318 Vanca: Change the conditions which stop the queue
local interrupt_controls = {}
for control = _G.CONTROL_ATTACK, _G.CONTROL_MOVE_RIGHT do
    interrupt_controls[control] = true
end
local mouse_controls = {[_G.CONTROL_PRIMARY] = false, [_G.CONTROL_SECONDARY] = true}

_G.ACTIONS.TILL.stroverridefn = function(act)
    if _G.TheInput:ControllerAttached() and controller_autotilling then
        return _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE
    elseif
        _G.TheInput:IsKeyDown(_G.KEY_LSHIFT) and (not _G.ACTIONS.TILL.tile_placer or not is_on_geometricplacement) and
            _G.ThePlayer.components.snaptiller.snap_mode ~= 0
     then
        return _G.STRINGS.SNAPPINGTILLS.ACTION_TILL_TILE
    end

    return nil
end

_G.ACTIONS.DEPLOY.stroverridefn = function(act)
    if
        _G.TheInput:IsKeyDown(_G.KEY_LSHIFT) and not is_on_geometricplacement and
            _G.ThePlayer.components.snaptiller.snap_mode ~= 0 and
            act.invobject:HasTag("deployedfarmplant")
     then
        return _G.STRINGS.SNAPPINGTILLS.ACTION_DEPLOY_TILE
    end

    return nil
end

local function GetSnapModeString(snap_mode)
    local postfix = ""
    if _G.TheInput:ControllerAttached() and controller_autotilling then
        postfix = " [auto tilling]"
    end

    if snap_mode == 0 then
        return _G.STRINGS.SNAPPINGTILLS.OFF
    elseif snap_mode == 1 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_OPTIMIZED .. postfix
    elseif snap_mode == 2 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_4x4 .. postfix
    elseif snap_mode == 3 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_3x3 .. postfix
    elseif snap_mode == 4 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_2x2 .. postfix
    elseif snap_mode == 5 then
        return _G.STRINGS.SNAPPINGTILLS.SNAP_MODE_HEXAGON .. postfix
    end

    return ""
end

--250321 VanCa: Get the text that will show up when changing intercropping mode
-- or when picking up seeds with Wormwood
local function GetIntercroppingModeString(intercropping_mode)
    local postfix = ""
    if _G.TheInput:ControllerAttached() and controller_autoplanting then
        postfix = " [auto planting]"
    end

    return _G.STRINGS.SNAPPINGTILLS.INTERCROPPING[intercropping_mode] .. postfix
end

local function IsDefaultScreen()
    local activescreen = _G.TheFrontEnd:GetActiveScreen()
    local screen = activescreen and activescreen.name or ""
    return screen:find("HUD") ~= nil and not isquagmire and _G.ThePlayer ~= nil and _G.ThePlayer.components ~= nil and
        _G.ThePlayer.components.snaptiller ~= nil and
        not _G.ThePlayer.HUD:IsChatInputScreenOpen() and
        not _G.ThePlayer.HUD.writeablescreen
end

-- Get enabled snap modes from config
local enabled_snap_modes = {}

for mode = 0, 5 do
    if mode == 0 and GetModConfigData("enable_off_mode") then
        table.insert(enabled_snap_modes, mode)
    elseif mode == 1 and GetModConfigData("enable_optimized_mode") then
        table.insert(enabled_snap_modes, mode)
    elseif mode == 2 and GetModConfigData("enable_4x4_mode") then
        table.insert(enabled_snap_modes, mode)
    elseif mode == 3 and GetModConfigData("enable_3x3_mode") then
        table.insert(enabled_snap_modes, mode)
    elseif mode == 4 and GetModConfigData("enable_2x2_mode") then
        table.insert(enabled_snap_modes, mode)
    elseif mode == 5 and GetModConfigData("enable_hexagon_mode") then
        table.insert(enabled_snap_modes, mode)
    end
end

local function ToggleSnapMode()
    if IsDefaultScreen() then
        local current_mode = _G.ThePlayer.components.snaptiller.snap_mode

        -- Find next valid mode
        local next_index = 3
        for i, mode in ipairs(enabled_snap_modes) do
            if mode == current_mode then
                next_index = i % #enabled_snap_modes + 1
                break
            end
        end

        local new_mode = enabled_snap_modes[next_index]

        -- Controller handling
        -- off > mode A > excute auto tilling mode A > mode B > excute auto tilling mode B > ...
        if _G.TheInput:ControllerAttached() then
            if controller_autotilling then
                controller_autotilling = false
            elseif enabled_snap_modes[next_index] > 0 then
                new_mode = current_mode
                controller_autotilling = true
            end
        end

        _G.ThePlayer.components.snaptiller.snap_mode = new_mode

        datacontainer:SetValue("version", "1.1.9")
        datacontainer:SetValue("snap_mode", new_mode)
        datacontainer:SetValue("controller_autotilling", controller_autotilling)
        datacontainer:Save()

        _G.ThePlayer.components.talker:Say(GetSnapModeString(new_mode))
    end
end

-- Get enabled intercropping modes from config
local enabled_intercropping_modes = {}

for mode = 1, 4 do
    if mode == 1 and GetModConfigData("enable_auto_mode") then
        table.insert(enabled_intercropping_modes, mode)
    elseif mode == 2 and GetModConfigData("enable_2_types_mode") then
        table.insert(enabled_intercropping_modes, mode)
    elseif mode == 3 and GetModConfigData("enable_3_types_mode") then
        table.insert(enabled_intercropping_modes, mode)
    elseif mode == 4 and GetModConfigData("enable_4_types_mode") then
        table.insert(enabled_intercropping_modes, mode)
    end
end

local function ToggleIntercroppingMode()
    if IsDefaultScreen() then
        local current_mode = _G.ThePlayer.components.snaptiller.intercropping_mode

        -- Find next valid mode
        local next_index = 1
        for i, mode in ipairs(enabled_intercropping_modes) do
            if mode == current_mode then
                next_index = i % #enabled_intercropping_modes + 1
                break
            end
        end

        local new_mode = enabled_intercropping_modes[next_index]

        -- Controller handling
        -- mode A > excute auto planting mode A > mode B > excute auto planting mode B > ...
        if _G.TheInput:ControllerAttached() then
            if controller_autoplanting then
                controller_autoplanting = false
            else
                new_mode = current_mode
                controller_autoplanting = true
            end
        end

        _G.ThePlayer.components.snaptiller.intercropping_mode = new_mode

        datacontainer:SetValue("version", "1.1.9")
        datacontainer:SetValue("intercropping_mode", new_mode)
        datacontainer:SetValue("controller_autoplanting", controller_autoplanting)
        datacontainer:Save()

        _G.ThePlayer.components.talker:Say(GetIntercroppingModeString(new_mode))
    end
end

if _G.KnownModIndex:IsModEnabled("workshop-351325790") then
    local original_print = _G.print

    AddComponentPostInit(
        "placer",
        function(self, inst)
            -- so crazy, but no other way
            _G.print = function()
            end -- KnownModIndex functions kinda spam the logs
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

                self.inst:ListenForEvent(
                    "onremove",
                    function()
                        if
                            _G.ThePlayer.components.snaptillplacer and
                                _G.ACTIONS.TILL.tile_placer == "till_actiongridplacer"
                         then
                            _G.ThePlayer.components.snaptillplacer:Show()
                        elseif _G.ThePlayer.components.snaptillplacer then
                            _G.ThePlayer.components.snaptillplacer:Show()
                        end
                    end
                )
            end
        end
    )
end

AddComponentPostInit(
    "placer",
    function(self, inst)
        local original_OnUpdate = self.OnUpdate
        self.OnUpdate = function(self, dt)
            original_OnUpdate(self, dt)
            -- 250322 VanCa: Show green/red circle grid when planting seeds with bare hands
            -- Only show when snapping mode is enabled
            local snap_mode = _G.ThePlayer.components.snaptiller.snap_mode
            if
                self.inst.prefab == "seeds_placer" and snap_mode > 0 and not is_on_geometricplacement and
                    not _G.TheInput:ControllerAttached() and self.invobject and self.invobject:HasTag("deployedfarmplant")
             then
                local is_deploying_seeds = _G.ThePlayer.components.snaptillplacer.deployed_farm_plant
                if not is_deploying_seeds then
                    _G.ThePlayer.components.snaptillplacer.deployed_farm_plant = true
                    -- Say about current Intercropping mode when Wormwood pick up seeds with mouse
                    local intercropping_mode = _G.ThePlayer.components.snaptiller.intercropping_mode
                    _G.ThePlayer.components.talker:Say(GetIntercroppingModeString(intercropping_mode))
                end
                local pos = _G.ThePlayer.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
                self.inst.Transform:SetPosition(pos:Get())
                self.selected_pos = pos
            end
        end
    end
)

-- 250330 VanCa: Make snap tilling easier. Trigger tilling by clicking on a farm tile instead of its snap point
function isTillingAtPoint(self, act)
    if act and act.action == _G.ACTIONS.TILL and not (_G.ACTIONS.TILL.tile_placer and is_on_geometricplacement) then
        return true
    elseif act == nil then
        local equipped_item = self.inst.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
        if
            equipped_item and
                (equipped_item.prefab == "farm_hoe" or equipped_item.prefab == "golden_farm_hoe" or
                    equipped_item.prefab == "shovel_lunarplant" or
                    equipped_item.prefab == "quagmire_hoe")
         then
            local pos = self.inst.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
            local is_farm_tile = false
            for _, ent in pairs(_G.TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x, pos.y, pos.z)) do
                -- Look for tile's nutrients_overlay entity, that's a farm tile
                if ent.prefab == "nutrients_overlay" then
                    is_farm_tile = true
                    break
                end
            end
            return is_farm_tile
        end
    end
    return false
end

-- 250330 VanCa: Make snap planting easier. Trigger planting by clicking on land tile instead of its snap point
function isPlantingAtPoint(self, act)
    if
        act and act.action == _G.ACTIONS.DEPLOY and act.invobject:HasTag("deployedfarmplant") and
            not is_on_geometricplacement
     then
        return true
    elseif act == nil then
        local pos = self.inst.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
        local is_land = _G.TheWorld.Map:IsLandTileAtPoint(pos.x, pos.y, pos.z)
        return is_land and _G.ThePlayer.components.snaptillplacer.deployed_farm_plant
    end
    return false
end

AddComponentPostInit(
    "playercontroller",
    function(self, inst)
        if inst ~= _G.ThePlayer then
            return
        end

        self.inst:AddComponent("snaptiller")

        self.inst:AddComponent("snaptillplacer")

        local version = datacontainer:GetValue("version")
        local snap_mode = datacontainer:GetValue("snap_mode")
        local intercropping_mode = datacontainer:GetValue("intercropping_mode")
        local _controller_autotilling = datacontainer:GetValue("controller_autotilling")
        local _controller_autoplanting = datacontainer:GetValue("controller_autoplanting")

        if #enabled_snap_modes == 0 then
            -- Fallback if all snap modes disabled
            table.insert(enabled_snap_modes, 0)
            snap_mode = 0
        elseif version == nil or snap_mode == nil then
            snap_mode = 3
        end
        if #enabled_intercropping_modes == 0 then
            -- Fallback if all intercropping modes disabled
            table.insert(enabled_intercropping_modes, 1)
            intercropping_mode = 1
        elseif version == nil or intercropping_mode == nil then
            intercropping_mode = 1
        end

        if type(_controller_autotilling) == "boolean" then
            controller_autotilling = _controller_autotilling
        end
        if type(_controller_autoplanting) == "boolean" then
            controller_autoplanting = _controller_autoplanting
        end

        self.inst.components.snaptiller.snap_mode = snap_mode
        self.inst.components.snaptiller.intercropping_mode = intercropping_mode
        self.inst.components.snaptiller.isquagmire = isquagmire
	
        self.inst.components.snaptillplacer.visible_setting = visiblesnaps

        local original_OnControl = self.OnControl
        local original_OnRightClick = self.OnRightClick
        local original_DoControllerAltActionButton = self.DoControllerAltActionButton

        self.OnControl = function(self, control, down)
            original_OnControl(self, control, down)
            -- 250318 Vanca: Change the conditions which stop the queue:
            -- Attack or move
            -- Click when not holding L-shift (except click on HUD)
            if
                down and
                    (interrupt_controls[control] or
                        (not _G.TheInput:IsKeyDown(_G.KEY_LSHIFT) and mouse_controls[control] ~= nil and
                            not _G.TheInput:GetHUDEntityUnderMouse())) and
                    self.inst and
                    self.inst.HUD and
                    not self.inst.HUD:HasInputFocus() and
                    self.inst.components.snaptiller.queue_manager.action_thread
             then
                self.inst.components.snaptiller:ClearActionThread()
            end
        end

        self.OnRightClick = function(self, down)
            local autotilldown = false

            if _G.TheInput:IsKeyDown(_G.KEY_LSHIFT) then
                autotilldown = true
            end

            local act = self:GetRightMouseAction()

            if _G.ThePlayer.components.snaptiller.snap_mode ~= 0 then
                -- Wormwood planting
                if isPlantingAtPoint(self, act) then
                    -- 250318 VanCa: only process mouse-up event to prevent double process per click
                    -- and compatible with ActionQueuer RB3
                    if not down then
                        if autotilldown then
                            -- LShift + Single right click
                            self.inst.components.snaptiller:StartAutoDeployAtPoint()
                        else
                            -- Single right click
                            local playercontroller = self.inst.components.playercontroller
                            local pos = self.inst.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
                            -- Skip if can't plant at this snap
                            if _G.TheWorld.Map:CanTillSoilAtPoint(pos.x, pos.y, pos.z, true) then
                                local item = self.inst.replica.inventory and self.inst.replica.inventory:GetActiveItem()
                                local act = _G.BufferedAction(self.inst, nil, _G.ACTIONS.DEPLOY, item, pos)

                                if playercontroller.ismastersim then
                                    self.inst.components.combat:SetTarget(nil)
                                    playercontroller:DoAction(act)
                                else
                                    if playercontroller.locomotor then
                                        act.preview_cb = function()
                                            _G.SendRPCToServer(
                                                _G.RPC.RightClick,
                                                _G.ACTIONS.DEPLOY.code,
                                                pos.x,
                                                pos.z,
                                                nil,
                                                nil,
                                                true
                                            )
                                        end
                                        playercontroller:DoAction(act)
                                    else
                                        _G.SendRPCToServer(
                                            _G.RPC.RightClick,
                                            _G.ACTIONS.DEPLOY.code,
                                            pos.x,
                                            pos.z,
                                            nil,
                                            nil,
                                            true
                                        )
                                    end
                                end
                            end
                        end
                    end
                    return
                end

                -- Tilling
                if isTillingAtPoint(self, act) then
                    -- 250318 VanCa: only process mouse-up event to prevent double process per click
                    -- and compatible with ActionQueuer RB3
                    if not down then
                        if autotilldown then
                            -- LShift + Single right click
                            self.inst.components.snaptiller:StartAutoTillAtPoint()
                        else
                            -- Single right click
                            local playercontroller = self.inst.components.playercontroller
                            local pos = self.inst.components.snaptiller:GetSnap(_G.TheInput:GetWorldPosition())
                            -- Skip if this snap is already tilled
                            if self.inst.components.snaptiller:isValidSnap({pos.x, pos.z}) then
                                local item =
                                    self.inst.replica.inventory and
                                    self.inst.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
                                local act = _G.BufferedAction(self.inst, nil, _G.ACTIONS.TILL, item, pos)

                                if playercontroller.ismastersim then
                                    self.inst.components.combat:SetTarget(nil)
                                    playercontroller:DoAction(act)
                                else
                                    if playercontroller.locomotor then
                                        act.preview_cb = function()
                                            _G.SendRPCToServer(
                                                _G.RPC.RightClick,
                                                _G.ACTIONS.TILL.code,
                                                pos.x,
                                                pos.z,
                                                nil,
                                                nil,
                                                true
                                            )
                                        end
                                        playercontroller:DoAction(act)
                                    else
                                        _G.SendRPCToServer(
                                            _G.RPC.RightClick,
                                            _G.ACTIONS.TILL.code,
                                            pos.x,
                                            pos.z,
                                            nil,
                                            nil,
                                            true
                                        )
                                    end
                                end
                            end
                        end
                    end
                    return
                end
            end

            -- Snap mode == 0 : Off
            -- Original right click
            original_OnRightClick(self, down)
        end

        self.DoControllerAltActionButton = function(self)
            local _, act = self:GetGroundUseAction()

            if _G.ThePlayer.components.snaptiller.snap_mode ~= 0 and act then
                if
                    act.action == _G.ACTIONS.TILL and act.pos and
                        (not _G.ACTIONS.TILL.tile_placer or not is_on_geometricplacement)
                 then
                    if controller_autotilling then
                        self.inst.components.snaptiller:StartAutoTillAtPoint()
                    else
                        local pos =
                            self.inst.components.snaptiller:GetSnap(
                            Point(act.pos.local_pt.x, act.pos.local_pt.y, act.pos.local_pt.z)
                        )
                        act.pos = _G.DynamicPosition(pos)

                        if self.ismastersim then
                            self.inst.components.combat:SetTarget(nil)
                        elseif self.locomotor == nil then
                            self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                            _G.SendRPCToServer(
                                _G.RPC.ControllerAltActionButtonPoint,
                                act.action.code,
                                act.pos.local_pt.x,
                                act.pos.local_pt.z,
                                nil,
                                act.action.canforce,
                                isspecial,
                                act.action.mod_name,
                                act.pos.walkable_platform,
                                act.pos.walkable_platform ~= nil
                            )
                        elseif self:CanLocomote() then
                            act.preview_cb = function()
                                self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                                local isreleased = not _G.TheInput:IsControlPressed(_G.CONTROL_CONTROLLER_ALTACTION)
                                _G.SendRPCToServer(
                                    _G.RPC.ControllerAltActionButtonPoint,
                                    act.action.code,
                                    act.pos.local_pt.x,
                                    act.pos.local_pt.z,
                                    isreleased,
                                    nil,
                                    isspecial,
                                    act.action.mod_name,
                                    act.pos.walkable_platform,
                                    act.pos.walkable_platform ~= nil
                                )
                            end
                        end

                        self:DoAction(act)
                    end
                    return
                elseif
                    act.action == _G.ACTIONS.DEPLOY and act.invobject:HasTag("deployedfarmplant") and
                        not is_on_geometricplacement
                 then
                    -- 250321 VanCa: Support autoplanting on controller
                    if controller_autoplanting then
                        self.inst.components.snaptiller:StartAutoDeployAtPoint()
                    else
                        local pos =
                            self.inst.components.snaptiller:GetSnap(
                            Point(act.pos.local_pt.x, act.pos.local_pt.y, act.pos.local_pt.z)
                        )
                        act.pos = _G.DynamicPosition(pos)

                        if self.ismastersim then
                            self.inst.components.combat:SetTarget(nil)
                        elseif self.locomotor == nil then
                            self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                            _G.SendRPCToServer(
                                _G.RPC.ControllerAltActionButtonPoint,
                                act.action.code,
                                act.pos.local_pt.x,
                                act.pos.local_pt.z,
                                nil,
                                act.action.canforce,
                                isspecial,
                                act.action.mod_name,
                                act.pos.walkable_platform,
                                act.pos.walkable_platform ~= nil
                            )
                        elseif self:CanLocomote() then
                            act.preview_cb = function()
                                self.remote_controls[_G.CONTROL_CONTROLLER_ALTACTION] = 0
                                local isreleased = not _G.TheInput:IsControlPressed(_G.CONTROL_CONTROLLER_ALTACTION)
                                _G.SendRPCToServer(
                                    _G.RPC.ControllerAltActionButtonPoint,
                                    act.action.code,
                                    act.pos.local_pt.x,
                                    act.pos.local_pt.z,
                                    isreleased,
                                    nil,
                                    isspecial,
                                    act.action.mod_name,
                                    act.pos.walkable_platform,
                                    act.pos.walkable_platform ~= nil
                                )
                            end
                        end

                        self:DoAction(act)
                    end
                    return
                end
            end

            original_DoControllerAltActionButton(self)
        end
    end
)

AddClassPostConstruct(
    "components/inventoryitem_replica",
    function(self, inst)
        local original_CanDeploy = self.CanDeploy
        self.CanDeploy = function(self, pt, ...)
            -- ACTIONS.DEPLOY.stroverridefn does not use intensive checks, so do the same here
            if
                self.inst:HasTag("deployedfarmplant") and _G.ThePlayer.components.snaptiller.snap_mode ~= 0 and
                    not is_on_geometricplacement
             then
                pt = _G.ThePlayer.components.snaptiller:GetSnap(pt)
            end
            return original_CanDeploy(self, pt, ...)
        end
    end
)

local function IsHandSlotItemHoe(slot)
    return slot ~= nil and slot.equipslot == _G.EQUIPSLOTS.HANDS and slot.tile ~= nil and slot.tile.item ~= nil and
        (slot.tile.item.prefab == "farm_hoe" or slot.tile.item.prefab == "golden_farm_hoe" or
            slot.tile.item.prefab == "shovel_lunarplant" or
            slot.tile.item.prefab == "quagmire_hoe")
end

local function IsSlotItemSeeds(slot)
    return slot ~= nil and slot.tile ~= nil and slot.tile.item ~= nil and slot.tile.item:HasTag("deployedfarmplant")
end

-- for support controller
AddClassPostConstruct(
    "widgets/inventorybar",
    function(self)
        local original_OnControl = self.OnControl
        local original_UpdateCursorText = self.UpdateCursorText

        self.OnControl = function(self, control, down)
            local res = original_OnControl(self, control, down)

            -- 250321 Vanca: Allow changing snap_mode and intercropping_mode on both Seeds & Hoe
            if
                self.open and not down and not isquagmire and
                    (IsSlotItemSeeds(self.active_slot) or IsHandSlotItemHoe(self.active_slot))
             then
                if control == _G.CONTROL_MENU_MISC_2 then
                    ToggleSnapMode()
                    return true
                elseif control == _G.CONTROL_MENU_MISC_1 then
                    ToggleIntercroppingMode()
                    return true
                end
            end

            return res
        end

        self.UpdateCursorText = function(self)
            original_UpdateCursorText(self)

            if
                self.open and not isquagmire and
                    (IsSlotItemSeeds(self.active_slot) or IsHandSlotItemHoe(self.active_slot))
             then
                local str =
                    self.actionstringbody:GetString() ..
                    "\n" ..
                        _G.TheInput:GetLocalizedControl(_G.TheInput:GetControllerID(), _G.CONTROL_MENU_MISC_2) ..
                            " " ..
                                _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_SNAP_MODE ..
                                    "\n" ..
                                        _G.TheInput:GetLocalizedControl(
                                            _G.TheInput:GetControllerID(),
                                            _G.CONTROL_MENU_MISC_1
                                        ) ..
                                            " " .. _G.STRINGS.SNAPPINGTILLS.ACTION_CHANGE_INTERCROPPING_MODE
                self.actionstringbody:SetString(str)

                local _, h0 = self.actionstringtitle:GetRegionSize()
                local _, h1 = self.actionstringbody:GetRegionSize()

                self.actionstringtitle:SetPosition(0, h0 / 2 + h1)
                self.actionstringbody:SetPosition(0, h1 / 2)
            end
        end
    end
)

local callback = {} -- config name to function called when the key event triggered

-- Shift key is fixed after update 1.8
-- 250320 VanCa: Hotkey to toggle intercropping mode
callback = {
    key_change_snap_mode = ToggleSnapMode,
    key_change_intercropping_mode = ToggleIntercroppingMode
}

local handler = {} -- config name to key event handlers
function KeyBind(name, key)
    if handler[name] then
        handler[name]:Remove()
    end -- disable old binding
    if key ~= nil then -- new binding
        if key >= 1000 then -- it's a mouse button
            handler[name] =
                GLOBAL.TheInput:AddMouseButtonHandler(
                function(button, down, x, y)
                    if button == key and down then
                        callback[name]()
                    end
                end
            )
        else -- it's a keyboard key
            handler[name] = GLOBAL.TheInput:AddKeyDownHandler(key, callback[name])
        end
    else -- no binding
        handler[name] = nil
    end
end
