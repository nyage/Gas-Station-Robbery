
-- Configuration
Config = {}

Config.GasStationLocations = {
    {x = 1959.3, y = 3748.1, z = 31.3}, -- Example coordinates for a gas station
    {x = 200.0, y = -1500.0, z = 29.0}  -- Add more coordinates as needed
}

Config.RobberyTimer = 60 -- Time in seconds for the robbery
Config.RobberyCooldown = 60000 -- Cooldown in milliseconds before the next robbery can be started

local isRobbing = false
local robberyCooldown = false
local robberyTimer = Config.RobberyTimer

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local inCircle = false

        -- Draw the 3D circle and check if the player is within range
        for _, loc in pairs(Config.GasStationLocations) do
            local distance = Vdist(playerCoords.x, playerCoords.y, playerCoords.z, loc.x, loc.y, loc.z)
            if distance < 5.0 then
                inCircle = true
                DrawMarker(1, loc.x, loc.y, loc.z + 1.0, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 0.5, 255, 0, 0, 100, false, true, 2, false, nil, nil, false, false, false, false, false)

                -- Display popup prompt to rob
                if not isRobbing then
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to rob the gas station.")
                end
            end
        end

        -- Check for robbery start
        if inCircle and IsControlJustPressed(1, 51) then -- 'E' key
            if not isRobbing then -- Ensure the robbery can only be started if it's not already in progress
                TriggerEvent('startRobbery')
            end
        end

        -- Hide prompt if not in any gas station
        if not inCircle and not isRobbing then
            ClearPrints()
        end
    end
end)

function DisplayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

RegisterNetEvent('startRobbery') -- Ensure this event is registered
AddEventHandler('startRobbery', function()
    if isRobbing then
        TriggerEvent('chat:addMessage', { args = { '^1Robbery', 'A robbery is already in progress!' } })
        return
    end

    if robberyCooldown then
        TriggerEvent('chat:addMessage', { args = { '^1Robbery', 'You must wait before robbing again!' } })
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, loc in pairs(Config.GasStationLocations) do
        if Vdist(playerCoords.x, playerCoords.y, playerCoords.z, loc.x, loc.y, loc.z) < 5.0 then
            isRobbing = true
            robberyCooldown = true

            -- Notify all players of the robbery
            TriggerServerEvent('gasStationRobbery:notifyRobbery', loc)

            Citizen.CreateThread(function()
                while robberyTimer > 0 do
                    Citizen.Wait(1000)
                    robberyTimer = robberyTimer - 1
                    -- Display timer to the player
                    TriggerEvent('chat:addMessage', { args = { '^2Timer:', 'Time left: ' .. robberyTimer .. ' seconds' } })
                end
                completeRobbery()
            end)

            Citizen.SetTimeout(Config.RobberyCooldown, function()
                robberyCooldown = false
            end)

            break
        end
    end
end)

function completeRobbery()
    isRobbing = false
    robberyTimer = Config.RobberyTimer -- Reset timer
    TriggerEvent('chat:addMessage', { args = { '^2Robbery', 'Robbery completed! Get out of there!' } })
    -- Reward the player (e.g., give money)
end

-- Create a blip for the gas stations
Citizen.CreateThread(function()
    for _, loc in pairs(Config.GasStationLocations) do
        local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(blip, 361) -- Gas station blip sprite
        SetBlipColour(blip, 1) -- Red color for robbery location
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Gas Station")
        EndTextCommandSetBlipName(blip)
        SetBlipAsShortRange(blip, true)
    end
end)

