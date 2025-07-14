local ESX = exports['es_extended']:getSharedObject()

local function playLockAnim()
    local ped = cache.ped

    RequestAnimDict("anim@mp_player_intmenu@key_fob@")
    while not HasAnimDictLoaded("anim@mp_player_intmenu@key_fob@") do
        Wait(0)
    end

    TaskPlayAnim(ped, "anim@mp_player_intmenu@key_fob@", "fob_click", 8.0, -8.0, 1000, 49, 0, false, false, false)
    RemoveAnimDict("anim@mp_player_intmenu@key_fob@")
end

local function honk(vehicle, times)
    for i = 1, times do
        StartVehicleHorn(vehicle, 100, "HELDDOWN", false)
        Wait(150)
    end
end

local function playCloseDoorSound(vehicle)
    PlayVehicleDoorCloseSound(vehicle, 1)
end

local function playOpenDoorSound()
    PlaySoundFrontend(-1, "DOOR_UNLOCK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

RegisterCommand('lockcar', function()
    local playerPed = cache.ped
    local coords = GetEntityCoords(playerPed)
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        vehicle = GetClosestVehicle(coords, Config.MaxDistance, 0, 71)
    end

    if vehicle == 0 then
        lib.notify({ title = 'Car Lock', description = 'No vehicle nearby!', type = 'error' })
        return
    end

    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(coords - vehicleCoords)

    if distance > Config.MaxDistance then
        lib.notify({ title = 'Car Lock', description = 'Too far from vehicle!', type = 'error' })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)

    lib.callback('sky-carlock:checkOwner', false, function(isOwner)
        if isOwner then
            local locked = GetVehicleDoorLockStatus(vehicle)

            playLockAnim()
            Wait(300)

            if locked == 1 then
                SetVehicleDoorsLocked(vehicle, 2)
                playCloseDoorSound(vehicle)
                honk(vehicle, 2)
                lib.notify({ title = 'Car Lock', description = 'Vehicle locked', type = 'success' })
            else
                SetVehicleDoorsLocked(vehicle, 1)
                playOpenDoorSound()
                honk(vehicle, 1)
                lib.notify({ title = 'Car Lock', description = 'Vehicle unlocked', type = 'info' })
            end

            SetVehicleLights(vehicle, 2)
            Wait(150)
            SetVehicleLights(vehicle, 0)
        else
            lib.notify({ title = 'Car Lock', description = 'You do not own this vehicle!', type = 'error' })
        end
    end, plate)
end, false)

RegisterKeyMapping('lockcar', 'Lock or Unlock Vehicle', 'keyboard', Config.LockKey)
