local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --inst.entity:AddLabel()

    inst.AnimState:SetBank("snaptillplacer")
    inst.AnimState:SetBuild("snaptillplacer")
    inst.AnimState:PlayAnimation("on", false)
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(4)
    --[[
    inst.Label:SetFontSize(35)
    inst.Label:SetFont(DEFAULTFONT)
    inst.Label:SetText("")
    inst.Label:SetWorldOffset(0, 0.3, 0)
    
    inst.SetDebugNumber = function(inst, number)
        inst.Label:SetText(tostring(number))
    end
    ]]
    return inst
end

return Prefab("snaptillplacer", fn)
