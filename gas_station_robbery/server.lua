RegisterNetEvent('gasStationRobbery:notifyRobbery')
AddEventHandler('gasStationRobbery:notifyRobbery', function(location)
    local message = '^1[ALERT] ^1Robbery in progress at gas station! ^5(Blue & Red Alert)'
    
    -- Notify all players
    TriggerClientEvent('chat:addMessage', -1, { args = { message } })
    
    -- Additional logic for police response can be implemented here
end)
