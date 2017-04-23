LinkLuaModifier("modifier_item_lucience_aura_handler", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_regen_aura", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_movespeed_aura", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_regen_effect", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_lucience_movespeed_effect", "items/lucience.lua", LUA_MODIFIER_MOTION_NONE)

-- Name constants
local regenAuraName = "modifier_item_lucience_regen_aura"
local movespeedAuraName = "modifier_item_lucience_movespeed_aura"
local regenIconName = "custom/lucience"
local movespeedIconName = "custom/lucience_movespeed"
local auraTypeRegen = 1
local auraTypeMovespeed = 2

item_lucience = class({})

function item_lucience:GetIntrinsicModifierName()
  return "modifier_item_lucience_aura_handler"
end

function item_lucience:OnToggle()
  self:StartCooldown(self:GetCooldown(self:GetLevel()))

  local caster = self:GetCaster()
  -- Switch auras
  if self.auraHandler then
    self.auraHandler:OnRefresh()
  end
end

function item_lucience:GetAbilityTextureName()
  if self.auraHandler:IsNull() then
    return self.BaseClass.GetAbilityTextureName(self)
  elseif self.auraHandler:GetStackCount() == auraTypeRegen then
    return regenIconName
  elseif self.auraHandler:GetStackCount() == auraTypeMovespeed then
    return movespeedIconName
  else
    return self.BaseClass.GetAbilityTextureName(self)
  end
end

function item_lucience.RemoveLucienceAuras(unit)
  unit:RemoveModifierByName(regenAuraName)
  unit:RemoveModifierByName(movespeedAuraName)
end

function item_lucience.RemoveLucienceEffects(ability, effectModifierName, unit)
  local effectModifier = unit:FindModifierByName(effectModifierName)
  if effectModifier and ability:GetLevel() > effectModifier:GetAbility():GetLevel() then
    unit:RemoveModifierByName(effectModifierName)
  end
end

item_lucience_2 = class(item_lucience)
item_lucience_3 = class(item_lucience)

------------------------------------------------------------------------

modifier_item_lucience_aura_handler = class({})

function modifier_item_lucience_aura_handler:IsHidden()
  return true
end

function modifier_item_lucience_aura_handler:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_lucience_aura_handler:OnCreated()
  local ability = self:GetAbility()
  ability.auraHandler = self
  self.bonusDamage = ability:GetSpecialValueFor("bonus_damage")

  if IsServer() then
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local currentRegenAura = parent:FindModifierByName(regenAuraName)
    local currentMovespeedAura = parent:FindModifierByName(movespeedAuraName)

    -- Set stack count to update item icon
    if ability:GetToggleState() then
      self:SetStackCount(auraTypeMovespeed)
    else
      self:SetStackCount(auraTypeRegen)
    end

    -- If the owner has a higher level Lucience Aura then don't do anything
    if currentRegenAura and ability:GetLevel() < currentRegenAura:GetAbility():GetLevel() then
      return
    elseif currentMovespeedAura and ability:GetLevel() < currentMovespeedAura:GetAbility():GetLevel() then
      return
    end

    item_lucience.RemoveLucienceAuras(parent)
    -- Delay adding the aura modifiers by a frame so that illusions won't always spawn with the regen aura
    Timers:CreateTimer({
      callback = function()
        if ability:GetToggleState() then
          parent:AddNewModifier(caster, ability, movespeedAuraName, {})
        else
          parent:AddNewModifier(caster, ability, regenAuraName, {})
        end
      end
    })
  end
end

modifier_item_lucience_aura_handler.OnRefresh = modifier_item_lucience_aura_handler.OnCreated

function modifier_item_lucience_aura_handler:OnDestroy()
  if IsServer() then
    local parent = self:GetParent()

    local ability = self:GetAbility()
    local currentRegenAura = parent:FindModifierByName(regenAuraName)
    local currentMovespeedAura = parent:FindModifierByName(movespeedAuraName)

    -- If the owner has a higher level Lucience Aura then don't do anything
    if currentRegenAura and ability:GetLevel() < currentRegenAura:GetAbility():GetLevel() then
      return
    elseif currentMovespeedAura and ability:GetLevel() < currentMovespeedAura:GetAbility():GetLevel() then
      return
    end
    function RefreshHandler(modifier)
      modifier:OnRefresh()
    end

    item_lucience.RemoveLucienceAuras(parent)

    -- Refresh any other handlers on the parent so that lower level Lucience will take effect when dropping a higher level
    if parent:HasModifier(self:GetName()) then
      local auraHandlers = parent:FindAllModifiersByName(self:GetName())
      foreach(RefreshHandler, auraHandlers)
    end
  end
end

function modifier_item_lucience_aura_handler:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
  }
end

function modifier_item_lucience_aura_handler:GetModifierPreAttack_BonusDamage()
  return self.bonusDamage
end

------------------------------------------------------------------------

modifier_item_lucience_regen_aura = class({})

function modifier_item_lucience_regen_aura:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local units = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetOrigin(), nil, self:GetAbility():GetSpecialValueFor("aura_radius"), self:GetAuraSearchTeam(), self:GetAuraSearchType(), self:GetAuraSearchFlags(), FIND_ANY_ORDER, false)
    local ability = self:GetAbility()
    local effectModifierName = "modifier_item_lucience_regen_effect"

    -- Force reapplication of effect modifiers so that effects update immediately when Lucience is upgraded
    foreach(partial(ability.RemoveLucienceEffects, ability, effectModifierName), units)
  end
end

function modifier_item_lucience_regen_aura:IsHidden()
  return true
end

function modifier_item_lucience_regen_aura:IsDebuff()
  return false
end

function modifier_item_lucience_regen_aura:IsPurgable()
  return false
end

function modifier_item_lucience_regen_aura:IsAura()
  return true
end

function modifier_item_lucience_regen_aura:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_lucience_regen_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_lucience_regen_aura:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_lucience_regen_aura:GetModifierAura()
  return "modifier_item_lucience_regen_effect"
end

------------------------------------------------------------------------

modifier_item_lucience_movespeed_aura = class(modifier_item_lucience_regen_aura)

function modifier_item_lucience_movespeed_aura:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local units = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetOrigin(), nil, self:GetAbility():GetSpecialValueFor("aura_radius"), self:GetAuraSearchTeam(), self:GetAuraSearchType(), self:GetAuraSearchFlags(), FIND_ANY_ORDER, false)
    local ability = self:GetAbility()
    local effectModifierName = "modifier_item_lucience_movespeed_effect"

    -- Force reapplication of effect modifiers so that effects update immediately when Lucience is upgraded
    foreach(partial(ability.RemoveLucienceEffects, ability, effectModifierName), units)
  end
end

function modifier_item_lucience_movespeed_aura:GetModifierAura()
  return "modifier_item_lucience_movespeed_effect"
end

------------------------------------------------------------------------

modifier_item_lucience_regen_effect = class({})

function modifier_item_lucience_regen_effect:OnCreated()
  self.regenBonus = self:GetAbility():GetSpecialValueFor("regen_bonus")
end

modifier_item_lucience_regen_effect.OnRefresh = modifier_item_lucience_regen_effect.OnCreated

function modifier_item_lucience_regen_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_item_lucience_regen_effect:GetModifierConstantHealthRegen()
  return self.regenBonus
end

function modifier_item_lucience_regen_effect:GetEffectName()
  return "particles/units/heroes/hero_necrolyte/necrolyte_ambient_glow.vpcf"
end

function modifier_item_lucience_regen_effect:GetTexture()
  return regenIconName
end

------------------------------------------------------------------------

modifier_item_lucience_movespeed_effect = class({})

function modifier_item_lucience_movespeed_effect:OnCreated()
  self.movespeedBonus = self:GetAbility():GetSpecialValueFor("speed_bonus")
end

modifier_item_lucience_movespeed_effect.OnRefresh = modifier_item_lucience_movespeed_effect.OnCreated

function modifier_item_lucience_movespeed_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
end

function modifier_item_lucience_movespeed_effect:GetModifierMoveSpeedBonus_Percentage()
  return self.movespeedBonus
end

function modifier_item_lucience_movespeed_effect:GetEffectName()
  return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ambient_glow.vpcf"
end

function modifier_item_lucience_movespeed_effect:GetTexture()
  return movespeedIconName
end
