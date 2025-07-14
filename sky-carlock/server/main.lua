local ESX = exports['es_extended']:getSharedObject()

lib.callback.register('sky-carlock:checkOwner', function(source, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    local result = MySQL.query.await('SELECT owner FROM owned_vehicles WHERE plate = ?', {
        plate
    })

    if result[1] and result[1].owner == xPlayer.identifier then
        return true
    else
        return false
    end
end)
