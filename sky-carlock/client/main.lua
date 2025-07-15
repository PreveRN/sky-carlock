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

local function playErrorSound()
    PlaySoundFrontend(-1, "ERROR", "HUD_AMMO_SHOP_SOUNDSET", true)
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

exports('useLockpick', function(item)
    TriggerEvent('sky-carlock:useLockpick', item)
end)

RegisterNetEvent('sky-carlock:useLockpick', function(item)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords, Config.MaxDistance or 15.0, 0, 71)

    if vehicle == 0 then
        lib.notify({ title = 'Lockpick', description = 'No vehicle nearby!', type = 'error' })
        return
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    local hasItem = lib.callback.await('sky-carlock:hasItem', false, Config.LockpickItem or 'lockpick')
    if not hasItem then
        lib.notify({ title = 'Lockpick', description = 'You don’t have a lockpick!', type = 'error' })
        return
    end

    lib.callback('sky-carlock:checkOwner', false, function(isOwner)
        if isOwner then
            lib.notify({ title = 'Lockpick', description = 'You already own this vehicle.', type = 'info' })
            return
        end

        TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WELDING', 0, true)

        local success = lib.progressBar({
            duration = Config.LockpickDuration or 6000,
            label = 'Lockpicking vehicle...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })

        ClearPedTasks(ped)
        if not success then
            lib.notify({ title = 'Lockpick', description = 'Canceled.', type = 'error' })
            return
        end

        local roll = math.random(1, 100)
        if roll <= (Config.LockpickSuccessChance or 70) then
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
            playOpenDoorSound()
            SetVehicleLights(vehicle, 2)
            Wait(150)
            SetVehicleLights(vehicle, 0)
            lib.notify({ title = 'Lockpick', description = 'Lockpick success! Vehicle unlocked.', type = 'success' })
        else
            playErrorSound()
            lib.notify({ title = 'Lockpick', description = 'Lockpick failed.', type = 'error' })
        end

        TriggerServerEvent('sky-carlock:consumeItem', Config.LockpickItem or 'lockpick')
    end, plate)
end)

CreateThread(function()
    DecorRegister("originalPlate", 3) 
end)

exports('useFakePlate', function(item)
    TriggerEvent('sky-carlock:useFakePlate', item)
end)

exports('useOriginalPlate', function(item)
    TriggerEvent('sky-carlock:useOriginalPlate', item)
end)

local function generateFakePlate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local plate = ""
    for i = 1, 8 do
        local rand = math.random(1, #chars)
        plate = plate .. chars:sub(rand, rand)
    end
    return plate
end

RegisterNetEvent('sky-carlock:useFakePlate', function(item)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords, 3.5, 0, 71)
    if vehicle == 0 then
        lib.notify({ title = 'Fake Plate', description = 'No vehicle nearby.', type = 'error' })
        return
    end

    local state = Entity(vehicle).state
    local hasFakePlateItem = lib.callback.await('sky-carlock:hasItem', false, Config.FakePlateItem)
    if state.originalPlate then
        lib.notify({ title = 'Fake Plate', description = 'Vehicle already has a fake plate.', type = 'error' })
        return
    end
    if not hasFakePlateItem then
        lib.notify({ title = 'Fake Plate', description = 'You don’t have a fake plate item.', type = 'error' })
        return
    end

    NetworkRequestControlOfEntity(vehicle)
    while not NetworkHasControlOfEntity(vehicle) do Wait(10) end
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)

    RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
    while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do Wait(0) end
    TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

    local success = lib.progressBar({
        duration = 5000,
        label = 'Installing Fake Plate...',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true }
    })

    ClearPedTasks(ped)
    if not success then return end

    local originalPlate = GetVehicleNumberPlateText(vehicle)
    local fake = generateFakePlate()

    state:set('originalPlate', originalPlate, true)
    SetVehicleNumberPlateText(vehicle, fake)

    TriggerServerEvent('sky-carlock:consumeItem', Config.FakePlateItem)
    TriggerServerEvent('sky-carlock:addItem', 'original_plate', 1)

    lib.notify({ title = 'Fake Plate', description = 'Fake plate applied: ' .. fake, type = 'success' })
end)

RegisterNetEvent('sky-carlock:useOriginalPlate', function(item)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords, 3.5, 0, 71)
    if vehicle == 0 then
        lib.notify({ title = 'Original Plate', description = 'No vehicle nearby.', type = 'error' })
        return
    end

    local state = Entity(vehicle).state
    if not state.originalPlate then
        lib.notify({ title = 'Original Plate', description = 'This vehicle has no fake plate.', type = 'error' })
        return
    end

    NetworkRequestControlOfEntity(vehicle)
    while not NetworkHasControlOfEntity(vehicle) do Wait(10) end

    RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
    while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do Wait(0) end
    TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)

    local success = lib.progressBar({
        duration = 5000,
        label = 'Reinstalling Original Plate...',
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true }
    })

    ClearPedTasks(ped)
    if not success then return end

    SetVehicleNumberPlateText(vehicle, state.originalPlate)
    state:set('originalPlate', nil, true)

    TriggerServerEvent('sky-carlock:consumeItem', 'original_plate')

    lib.notify({ title = 'Original Plate', description = 'Original plate restored.', type = 'success' })
end)

RegisterKeyMapping('lockcar', 'Lock or Unlock Vehicle', 'keyboard', Config.LockKey)
