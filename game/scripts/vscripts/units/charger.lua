
LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

function Spawn (entityKeyValues)
  thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  thisEntity:SetContextThink( "ChargerThink", partial(ChargerThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())

  ABILITY_charge = thisEntity:FindAbilityByName("boss_charger_charge")
  ABILITY_summon_pillar = thisEntity:FindAbilityByName("boss_charger_summon_pillar")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_charge, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    "boss_charger_charge"
  })

end

function GetAllPillars ()
  local towers = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    GLOBAL_origin,
    nil,
    1200,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  function isTower (tower)
    return tower:GetUnitName() == "npc_dota_boss_charger_pillar"
  end

  return filter(isTower, iter(towers))
end

function CheckPillars ()
  local towers = GetAllPillars()

  -- print('Found ' .. towers:length() .. ' towers!')

  if towers:length() > 7 then
    return false
  end

  local towerLocation = Vector(0,0,0)
  while towerLocation:Length() < 700 do
    -- sometimes rng fails us
    towerLocation = Vector(math.random(-1,1), math.random(-1,1), 0):Normalized() * 800
  end

  towerLocation = towerLocation + GLOBAL_origin

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    AbilityIndex = ABILITY_summon_pillar:entindex(), --Optional.  Only used when casting abilities
    Position = towerLocation, --Optional.  Only used when targeting the ground
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  return true
end

function ChargerThink (state, target)
  if not thisEntity:IsAlive() then
    GetAllPillars():each(function (pillar)
      pillar:Kill(thisEntity, ABILITY_charge)
    end)
    return 0
  end
  if not GLOBAL_origin then
    GLOBAL_origin = thisEntity:GetAbsOrigin()
  else
    local distance = (GLOBAL_origin - thisEntity:GetAbsOrigin()):Length()
    if distance > 1000 then
      ExecuteOrderFromTable({
        UnitIndex = thisEntity:entindex(),
        OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        Position = GLOBAL_origin, --Optional.  Only used when targeting the ground
        Queue = 0 --Optional.  Used for queueing up abilities
      })
      return 5
    end
  end

  if not thisEntity:IsIdle() then
    return 0.1
  end
  if CheckPillars() then
    return 0.5
  end
  if ChargeHero() then
    return 1
  end

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = GLOBAL_origin, --Optional.  Only used when targeting the ground
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  return 0.1

end

function ChargeHero ()
  if not ABILITY_charge:IsCooldownReady() then
    return false
  end
  local units = FindUnitsInRadius(
    thisEntity:GetTeamNumber(),
    thisEntity:GetAbsOrigin(),
    nil,
    1000,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
    FIND_CLOSEST,
    false
  )

  if #units == 0 then
    return false
  end
  local hero = units[1]

  ExecuteOrderFromTable({
    UnitIndex = thisEntity:entindex(),
    OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
    TargetIndex = hero:entindex(), --Optional.  Only used when targeting units
    AbilityIndex = ABILITY_charge:entindex(), --Optional.  Only used when casting abilities
    Position = hero:GetAbsOrigin(), --Optional.  Only used when targeting the ground
    Queue = 0 --Optional.  Used for queueing up abilities
  })

  return true
end
