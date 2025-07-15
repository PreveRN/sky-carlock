local ESX = exports['es_extended']:getSharedObject()

lib.callback.register('sky-carlock:checkOwner', function(source, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    plate = plate and plate:match("^%s*(.-)%s*$")

    local result = MySQL.query.await('SELECT owner FROM owned_vehicles WHERE plate = ?', {
        plate
    })

    return result[1] and result[1].owner == xPlayer.identifier
end)

lib.callback.register('sky-carlock:hasItem', function(source, item)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local count = exports.ox_inventory:Search(source, 'count', item)
    return count and count > 0
end)

RegisterNetEvent('sky-carlock:consumeItem', function(item)
    local src = source
    if not src or not item then return end

    exports.ox_inventory:RemoveItem(src, item, 1)
end)

RegisterNetEvent('sky-carlock:addItem', function(item, count)
    local src = source
    if not src or not item or not count then return end

    exports.ox_inventory:AddItem(src, item, count)
end)
