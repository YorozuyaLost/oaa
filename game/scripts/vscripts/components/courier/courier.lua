-- Courier Spawner and maybe future handler


-- Taken from bb template
if Courier == nil then
  Debug.EnabledModules['courier:*'] = true
  DebugPrint ( 'creating new Courier object' )
  Courier = class({})
end

function Courier:Init ()
  Courier.hasCourier = {}
  Courier.hasCourier[DOTA_TEAM_BADGUYS] = false
  Courier.hasCourier[DOTA_TEAM_GOODGUYS] = false
end

function Courier:SpawnCourier (hero)
  Timers:CreateTimer(1, function ()
    DebugPrint("Creating Courier for Team " .. hero:GetTeamNumber())

    -- Check if there is an item blocking slot 1, if so sell it
    slot1Item = hero:GetItemInSlot(0)
    if slot1Item then
      hero:SellItem(slot1Item)
    end

    -- Create couriers and then cast them straight away
    local courier = hero:AddItemByName('item_courier')
    if courier then
        hero:CastAbilityImmediately(courier, hero:GetPlayerID())
    end
    local flying = hero:AddItemByName('item_flying_courier')
    if flying then
        hero:CastAbilityImmediately(flying, hero:GetPlayerID())
    end

    Courier.hasCourier[hero:GetTeamNumber()] = true
  end)
end
