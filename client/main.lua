local QBCore = exports["qb-core"]:GetCoreObject()
local PlayerData = {}




local hudInfo = {
  isCar = false,
  isTalking = false,
  radioTalking = false,
  bars = {
    health = 0,
    armor = 0,
    hunger = 0,
    thrist = 0,
    stress = 0,
    stamina = 0,
    oxygen = 100,
    voice = 0,
    radio = 0
  }
}

local carInfo = {
  belt = false,
  cruiser = false,
  moto = false,
  emer = false,
  street = "",
  speed = 0,
  gear = 0,
  bars = {
    fuel = 0,
    engine = 0,
    rpm = 0,
  }
}
local actualCar = 0
CreateThread(function()
  Wait(200)
  if IsPedInAnyVehicle(PlayerPedId(), false) then
    hudInfo.isCar = true
    actualCar = GetVehiclePedIsIn(PlayerPedId(), false)
  end
end)


CreateThread(function()
  Wait(500)
  PlayerData = QBCore.Functions.GetPlayerData()
  hudInfo.bars.thrist = PlayerData.metadata["thirst"]
  hudInfo.bars.hunger = PlayerData.metadata["hunger"]
  hudInfo.bars.armor = PlayerData.metadata["armor"]
  hudInfo.bars.stress = PlayerData.metadata["stress"]
  SendNUIMessage({ hudInfo = hudInfo })
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
  PlayerData = QBCore.Functions.GetPlayerData()
  hudInfo.bars.thrist = PlayerData.metadata["thirst"]
  hudInfo.bars.hunger = PlayerData.metadata["hunger"]
  hudInfo.bars.armor = PlayerData.metadata["armor"]
  hudInfo.bars.stress = PlayerData.metadata["stress"]
  SendNUIMessage({ hudInfo = hudInfo })
end)

RegisterNetEvent('QBCore:Client:SetPlayerData', function(val)
  PlayerData = val
  hudInfo.bars.thrist = PlayerData.metadata["thirst"]
  hudInfo.bars.hunger = PlayerData.metadata["hunger"]
  hudInfo.bars.armor = PlayerData.metadata["armor"]
  hudInfo.bars.stress = PlayerData.metadata["stress"]
  SendNUIMessage({ hudInfo = hudInfo })
end)


CreateThread(function()
  TriggerEvent('pma-voice:setTalkingMode', 2)
  while true do
    Wait(400)
    hudInfo.isTalking = NetworkIsPlayerTalking(cache.ped)
    if not Config.radio then
      hudInfo.bars.radio = 0
    elseif Config.radio and hudInfo.radioTalking then -- Si tiene el export y esta hablando lo seteamos al 100%
      hudInfo.bars.radio = 100
    else
      hudInfo.bars.radio = 0
    end
    SendNUIMessage({ hudInfo = hudInfo })
  end
end)

AddEventHandler('pma-voice:setTalkingMode', function(voiceMode)
  if voiceMode == 2 then
    hudInfo.bars.voice = 45
  elseif voiceMode == 1 then
    hudInfo.bars.voice = 20
  else
    hudInfo.bars.voice = 100
  end
end)

AddEventHandler('pma-voice:radioActive', function(broadCasting)
  hudInfo.radioTalking = broadCasting
end)

lib.onCache("vehicle", function(value)
  actualCar = value
  hudInfo.isCar = type(actualCar) == 'number' and true or value
end)

RegisterNetEvent("hud:client:UpdateNeeds", function(newHunger, newThirst)
  hudInfo.bars.thrist = newThirst
  hudInfo.bars.hunger = newHunger
end)

CreateThread(function()
  while true do
    Wait(2000)
    hudInfo.bars.health = (GetEntityHealth(PlayerPedId()) - 100)
    hudInfo.bars.stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    hudInfo.bars.oxygen = math.ceil(GetPlayerUnderwaterTimeRemaining(PlayerId())) * 10
    if hudInfo.isCar then
      hudInfo.left = GetMinimapAnchor().width + GetMinimapAnchor().left_x + 10
    end
    SendNUIMessage({ hudInfo = hudInfo })
  end
end)

-- CAR HUD --

CreateThread(function()
  while true do
    Wait(2000)
    if hudInfo.isCar then
      carInfo.belt = false
    end
    if hudInfo.isCar then
      Wait(100)
      DisplayRadar(true)
      carInfo.emer = IsVehicleSirenOn(actualCar)

      carInfo.speed = math.floor(GetEntitySpeed(actualCar) * 3.6)

      carInfo.gear = GetVehicleCurrentGear(actualCar)

      carInfo.bars.fuel = GetVehicleFuelLevel(actualCar) * 60 / 100

      carInfo.bars.engine = GetVehicleEngineHealth(actualCar)

      carInfo.bars.rpm = GetVehicleCurrentRpm(actualCar)

      if GetVehicleClass(actualCar) == 8 or GetVehicleClass(actualCar) == 13 then
        carInfo.belt = false
        carInfo.moto = true
      else
        carInfo.moto = false
      end

      SendNUIMessage({ carInfo = carInfo })
    end

    if not hudInfo.isCar then
      DisplayRadar(false)
    end
  end
end)

CreateThread(function()
  while true do
    Wait(3000)
    if hudInfo.isCar then
      Wait(5000)
      if not carInfo.belt and not carInfo.moto then
        PlaySound("alerta", 0.5)
      end
      local coords = GetEntityCoords(PlayerPedId());
      local streetname = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
      local zone = GetNameOfZone(coords.x, coords.y, coords.z);
      local zoneLabel = GetLabelText(zone);
      _street = GetStreetNameFromHashKey(streetname);
      carInfo.street = zoneLabel .. " / " .. _street .. "  "
    end
  end
end)

-- CINTURON --

RegisterKeyMapping("cinturon", "Poner / Quitar el cinturón", "KEYBOARD", "X")

RegisterCommand("cinturon", function()
  if hudInfo.isCar and not carInfo.moto then
    carInfo.belt = not carInfo.belt
    if carInfo.belt then
      PlaySound('buckle', 0.2)
      QBCore.Functions.Notify("Te has puesto el cinturon", "primary", 3000)
      --LOGICA DEL CINTURON
      local s, e = pcall(function()
        return SetFlyThroughWindscreenParams(1000.0, 1000.0, 17.0, 500.0)
      end)

      if not s then
        print(e) -- error al setear el valor
      end
      SetPedConfigFlag(cache.playerId, 32, true)
    else
      PlaySound('unbuckle', 0.2)
      QBCore.Functions.Notify("Te has quitado el cinturon", "primary", 3000)
      ResetFlyThroughWindscreenParams()
      SetPedConfigFlag(cache.playerId, 32, false)
    end
  elseif not carInfo.moto then
    carInfo.belt = false
  elseif carInfo.moto then
    QBCore.Functions.Notify("Este vehiculo no tiene cinturon", "error", 3000)
    ResetFlyThroughWindscreenParams()
    SetPedConfigFlag(cache.playerId, 32, false)
  end
end, false)

-- LOGICA DEL CINTURON --
-- CreateThread(function()
--   while true do
--     Wait(2500)
--     while carInfo.belt do
--       Wait(1)
--       DisableControlAction(0, 75, true)
--       DisableControlAction(27, 75, true)
--     end
--   end
-- end)

-- CreateThread(function()
--   while true do
--     Wait(3000)
--     while not carInfo.belt and hudInfo.isCar and not carInfo.moto do
--       local velBuffer = GetEntityVelocity(actualCar)
--       local prevSpeed = GetEntitySpeed(actualCar) * 3.6
--       Wait(1000)
--       local currentSpeed = GetEntitySpeed(actualCar) * 3.6

--       if (prevSpeed - currentSpeed) >= 120 then
--         local co = GetEntityCoords(PlayerPedId())
--         local fw = Fwv(PlayerPedId())
--         SetEntityCoords(PlayerPedId(), co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
--         SetEntityVelocity(PlayerPedId(), velBuffer.x, velBuffer.y, velBuffer.z)
--         Wait(1)
--         SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
--       end
--     end
--   end
-- end)

function Fwv(entity)
  local hr = GetEntityHeading(entity) + 90.0
  if hr < 0.0 then hr = 360.0 + hr end
  hr = hr * 0.0174533
  return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

RegisterKeyMapping('limitador', 'Poner/Quitar el limitador de velocidad', 'keyboard', '')

RegisterCommand('limitador', function()
  if hudInfo.isCar then
    if carInfo.cruiser == false then
      local player = PlayerPedId()
      local vehicle = GetVehiclePedIsIn(player, false)
      local speed = GetEntitySpeed(vehicle)
      carInfo.cruiser = true
      SetEntityMaxSpeed(vehicle, speed)
    else
      carInfo.cruiser = false
      local player = PlayerPedId()
      local vehicle = GetVehiclePedIsIn(player, false)
      local maxSpeed = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
      SetEntityMaxSpeed(vehicle, maxSpeed)
    end
  end
end, false)

function PlaySound(soundFile, soundVolume)
  SendNUIMessage({
    transactionType = 'playSound',
    transactionFile = soundFile,
    transactionVolume = soundVolume
  })
end

--[[ANCLA]]
local EstadoAncla = false

CreateThread(function()
  while true do
    Wait(2000)
    local playerPed = PlayerPedId()
    while EstadoAncla and IsPedInAnyBoat(playerPed) do
      Wait(0)
      SetVehicleEngineOn(GetVehiclePedIsIn(playerPed, false), false, false, true)
      FreezeEntityPosition(GetVehiclePedIsIn(playerPed, false), true)
    end
    if IsPedInAnyBoat(playerPed) and not EstadoAncla then
      SetVehicleEngineOn(GetVehiclePedIsIn(playerPed, false), true, false, true)
      FreezeEntityPosition(GetVehiclePedIsIn(playerPed, false), false)
    end
    if not IsPedInAnyBoat(playerPed) then EstadoAncla = false end
  end
end)

RegisterCommand('ancla', function()
  local myVehicleSpeed = GetEntitySpeed(GetVehiclePedIsIn(PlayerPedId(), false))
  if (myVehicleSpeed * 3.6) > 20 then
    QBCore.Functions.Notify("Vas muy rápido, no puedes anclar el barco")
  elseif not EstadoAncla then
    QBCore.Functions.Notify("Has echado el ancla")
    EstadoAncla = true
  elseif EstadoAncla then
    QBCore.Functions.Notify("Has retirado el ancla")
    EstadoAncla = false
  end
end, false)

local showHud = true

RegisterCommand("hud", function()
  showHud = not showHud
  SendNUIMessage({
    showHud = showHud
  })
end, false)
