local QBCore = exports['qb-core']:GetCoreObject()
local MissionMarker = vector3(960.71197509766, -215.51979064941, 76.2552947998) -- <<place where is the marker with the mission
local dealerCoords = vector3(960.78, -216.25, 76.25) 							-- << place where the NPC dealer stands
local VehicleSpawn1 = vector3(-1327.479736328, -86.045326232910, 49.31) 		-- << below the coordinates for random vehicle responses
local VehicleSpawn2 = vector3(-2075.888183593, -233.73908996580, 21.10)
local VehicleSpawn3 = vector3(-972.1781616210, -1530.9045410150, 4.890)
local VehicleSpawn4 = vector3(798.18426513672, -1799.8173828125, 29.33)
local VehicleSpawn5 = vector3(1247.0718994141, -344.65634155273, 69.08)
local DriverWep = "WEAPON_SMG" 											-- << the weapon the driver is to be equipped with
local NavWep = "WEAPON_SMG" 												-- << the weapon the guard should be equipped with
local TimeToBlow = 30 * 1000 													-- << bomb detonation time after planting, default 20 seconds
local PickupMoney = 0
local BlowBackdoor = 0
local SilenceAlarm = 0
local PoliceAlert = 0
local PoliceBlip = 0
local LootTime = 1
local GuardsDead = 0
local prop
local lootable = 0
local BlownUp = 0
local TruckBlip
local transport
local MissionStart = 0
local warning = 0
local VehicleCoords = nil
local dealer
local PlayerJob = {}
local pilot = nil
local navigator = nil

local cooldown = false
local bombed = false

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
    end)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

function hintToDisplay(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, 20000)
end

---

function CheckGuards()
    if IsPedDeadOrDying(pilot) == 1 or IsPedDeadOrDying(navigator) == 1 then
        GuardsDead = 1
    end
    Citizen.Wait(500)
end

function AlertPolice()
    local a, b, c = table.unpack(GetEntityCoords(transport))
    local AlertCoordA = tonumber(string.format("%.2f", a))
    local AlertCoordB = tonumber(string.format("%.2f", b))
    local AlertCoordC = tonumber(string.format("%.2f", c))
    TriggerServerEvent('qb-truckrobbery:alertpolice', AlertCoordA, AlertCoordB, AlertCoordC)
    Citizen.Wait(500)
end

RegisterNetEvent('qb-truckrobbery:callpolice', function(x, y, z)
    if PlayerJob ~= nil and PlayerJob.name == 'police' then

        if PoliceBlip == 0 then
            PoliceBlip = 1
            local blip = AddBlipForCoord(x, y, z)
            SetBlipSprite(blip, 67)
            SetBlipScale(blip, 1.0)
            SetBlipColour(blip, 2)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString('Assault on the transport of cash')
            EndTextCommandSetBlipName(blip)
            SetNewWaypoint(x, y)
            Citizen.Wait(10000)
            RemoveBlip(blip)
            PoliceBlip = 0
        end

        local PoliceCoords = GetEntityCoords(PlayerPedId(), false)
        local PoliceDist = #(PoliceCoords - vector3(x, y, z))
        if PoliceDist <= 4.5 then
            local dict = "anim@mp_player_intmenu@key_fob@"

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do
                Citizen.Wait(100)
            end
            if SilenceAlarm == 0 then
                hintToDisplay('Press ~INPUT_DETONATE~ to silence the alarm')
                SilenceAlarm = 1
            end
            if IsControlPressed(0, 47) and GuardsDead == 1 then

                TaskPlayAnim(PlayerPedId(), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
                TriggerEvent('qb-truckrobbery:cleanup')
                RemoveBlip(TruckBlip)
                Citizen.Wait(500)
            end
        end

    end
end)

RegisterNetEvent('qb-truckrobbery:client:911alert', function()
    if PoliceAlert == 0 then
        local transCoords = GetEntityCoords(transport)

        local s1, s2 = GetStreetNameAtCoord(transCoords.x, transCoords.y, transCoords.z)
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
        local streetLabel = street1
        if street2 ~= nil then
            streetLabel = streetLabel .. " " .. street2
        end

        TriggerServerEvent("qb-truckrobbery:server:callCops", streetLabel, transCoords)

        PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
        PoliceAlert = 1
    end
end)

RegisterNetEvent('qb-truckrobbery:client:robberyCall', function(streetLabel, coords)
    if PlayerJob.name == "police" then
        local store = "Armored Truck"

        PlaySound(-1, "Lose_1st", "GTAO_FM_Events_Soundset", 0, 0, 1)
        TriggerEvent('qb-policealerts:client:AddPoliceAlert', {
            timeOut = 10000,
            alertTitle = Config.PoliceAlertMessage,
            coords = {
                x = coords.x,
                y = coords.y,
                z = coords.z
            },
            details = {
                [1] = {
                    icon = '<i class="fas fa-university"></i>',
                    detail = store
                },
                [2] = {
                    icon = '<i class="fas fa-globe-europe"></i>',
                    detail = streetLabel
                }
            },
            callSign = QBCore.Functions.GetPlayerData().metadata["callsign"]
        })

        local transG = 250
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 487)
        SetBlipColour(blip, 4)
        SetBlipDisplay(blip, 4)
        SetBlipAlpha(blip, transG)
        SetBlipScale(blip, 1.2)
        SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.PoliceAlertMessage)
        EndTextCommandSetBlipName(blip)
        while transG ~= 0 do
            Wait(180 * 4)
            transG = transG - 1
            SetBlipAlpha(blip, transG)
            if transG == 0 then
                SetBlipSprite(blip, 2)
                RemoveBlip(blip)
                return
            end
        end
    end
end)

function MissionNotification()
    Citizen.Wait(2000)
    TriggerServerEvent('qb-phone:server:sendNewMail', {
        sender = Config.Sender,
        subject = Config.EmailSubject,
        message = Config.EmailMessage 
    })
    Citizen.Wait(3000)
end
---
--
RegisterNetEvent('qb-truckrobbery:starthack', function()
    local itemname = Config.HackItem
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not cooldown then
        QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
            if hasItem then
                QBCore.Functions.Progressbar("open_locker_drill", Config.ProgressMessage, Config.ProgressTime, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function() -- Done
                    if Config.HackType == "laptop" then
                        exports["hacking"]:hacking(
                        function() -- success
                            cooldown = true
                            TriggerServerEvent('qb-truckrobbery:setcooldown')
                            QBCore.Functions.Notify(Config.HackSuccessNotification, 'success', 4500)
                            MissionNotification()
                            local DrawCoord = math.random(1, 5)
                            if DrawCoord == 1 then
                                VehicleCoords = VehicleSpawn1
                            elseif DrawCoord == 2 then
                                VehicleCoords = VehicleSpawn2
                            elseif DrawCoord == 3 then
                                VehicleCoords = VehicleSpawn3
                            elseif DrawCoord == 4 then
                                VehicleCoords = VehicleSpawn4
                            elseif DrawCoord == 5 then
                                VehicleCoords = VehicleSpawn5
                            end
                        
                            RequestModel(GetHashKey('stockade'))
                            while not HasModelLoaded(GetHashKey('stockade')) do
                                Citizen.Wait(0)
                            end
                        
                            SetNewWaypoint(VehicleCoords.x, VehicleCoords.y)
                            ClearAreaOfVehicles(VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 15.0, false, false, false, false, false)
                            transport = CreateVehicle(GetHashKey('stockade'), VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 52.0, true,
                                true)
                            SetEntityAsMissionEntity(transport)
                            TruckBlip = AddBlipForEntity(transport)
                            SetBlipSprite(TruckBlip, 67)
                            SetBlipColour(TruckBlip, 46)
                            SetBlipFlashes(TruckBlip, false)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentString('Gruppe Sechs Security Truck')
                            EndTextCommandSetBlipName(TruckBlip)
                            --
                            RequestModel("s_m_m_security_01")
                            while not HasModelLoaded("s_m_m_security_01") do
                                Wait(10)
                            end
                            pilot = CreatePed(26, "s_m_m_security_01", VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 268.9422, true, false)
                            navigator = CreatePed(26, "s_m_m_security_01", VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 268.9422, true,
                                false)
                            SetPedIntoVehicle(pilot, transport, -1)
                            SetPedIntoVehicle(navigator, transport, 0)
                            SetPedFleeAttributes(pilot, 0, 0)
                            SetPedCombatAttributes(pilot, 46, 1)
                            SetPedCombatAbility(pilot, 100)
                            SetPedCombatMovement(pilot, 2)
                            SetPedCombatRange(pilot, 2)
                            SetPedKeepTask(pilot, true)
                            GiveWeaponToPed(pilot, GetHashKey(DriverWep), 250, false, true)
                            SetPedAsCop(pilot, true)
                            --
                            SetPedFleeAttributes(navigator, 0, 0)
                            SetPedCombatAttributes(navigator, 46, 1)
                            SetPedCombatAbility(navigator, 100)
                            SetPedCombatMovement(navigator, 2)
                            SetPedCombatRange(navigator, 2)
                            SetPedKeepTask(navigator, true)
                            TaskEnterVehicle(navigator, transport, -1, 0, 1.0, 1)
                            GiveWeaponToPed(navigator, GetHashKey(NavWep), 250, false, true)
                            SetPedAsCop(navigator, true)
                            --
                            TaskVehicleDriveWander(pilot, transport, 80.0, 443)
                            MissionStart = 1
                            local PlayerData = QBCore.Functions.GetPlayerData()
                            local PlayerID = PlayerData.citizenid
                            print('Citizen ID: '..PlayerID..' Has Successfully Trigger the Armored Truck Robbery!')
                            TriggerServerEvent("QBCore:Server:RemoveItem", itemname, 1)
                            TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[itemname], "remove")
                            Citizen.Wait(60000)
                            cooldown = false

                        end,

                        function() -- failure
                            QBCore.Functions.Notify(Config.FailureNotification, 'error', 3200)
                            TriggerServerEvent("QBCore:Server:RemoveItem", itemname, 1)
                            TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[itemname], "remove")
                        end)
                    elseif Config.HackType == "memory" then
                        exports["qb-truckrobbery"]:thermiteminigame(10, 3, 3, 6,

                        function() -- success
                            cooldown = true
                            TriggerServerEvent('qb-truckrobbery:setcooldown')
                            QBCore.Functions.Notify(Config.HackSuccessNotification, 'success', 4500)
                            MissionNotification()
                            local DrawCoord = math.random(1, 5)
                            if DrawCoord == 1 then
                                VehicleCoords = VehicleSpawn1
                            elseif DrawCoord == 2 then
                                VehicleCoords = VehicleSpawn2
                            elseif DrawCoord == 3 then
                                VehicleCoords = VehicleSpawn3
                            elseif DrawCoord == 4 then
                                VehicleCoords = VehicleSpawn4
                            elseif DrawCoord == 5 then
                                VehicleCoords = VehicleSpawn5
                            end
                        
                            RequestModel(GetHashKey('stockade'))
                            while not HasModelLoaded(GetHashKey('stockade')) do
                                Citizen.Wait(0)
                            end
                        
                            SetNewWaypoint(VehicleCoords.x, VehicleCoords.y)
                            ClearAreaOfVehicles(VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 15.0, false, false, false, false, false)
                            transport = CreateVehicle(GetHashKey('stockade'), VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 52.0, true,
                                true)
                            SetEntityAsMissionEntity(transport)
                            TruckBlip = AddBlipForEntity(transport)
                            SetBlipSprite(TruckBlip, 67)
                            SetBlipColour(TruckBlip, 46)
                            SetBlipFlashes(TruckBlip, false)
                            BeginTextCommandSetBlipName("STRING")
                            AddTextComponentString('Gruppe Sechs Security Truck')
                            EndTextCommandSetBlipName(TruckBlip)
                            --
                            RequestModel("s_m_m_security_01")
                            while not HasModelLoaded("s_m_m_security_01") do
                                Wait(10)
                            end
                            pilot = CreatePed(26, "s_m_m_security_01", VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 268.9422, true, false)
                            navigator = CreatePed(26, "s_m_m_security_01", VehicleCoords.x, VehicleCoords.y, VehicleCoords.z, 268.9422, true,
                                false)
                            SetPedIntoVehicle(pilot, transport, -1)
                            SetPedIntoVehicle(navigator, transport, 0)
                            SetPedFleeAttributes(pilot, 0, 0)
                            SetPedCombatAttributes(pilot, 46, 1)
                            SetPedCombatAbility(pilot, 100)
                            SetPedCombatMovement(pilot, 2)
                            SetPedCombatRange(pilot, 2)
                            SetPedKeepTask(pilot, true)
                            GiveWeaponToPed(pilot, GetHashKey(DriverWep), 250, false, true)
                            SetPedAsCop(pilot, true)
                            --
                            SetPedFleeAttributes(navigator, 0, 0)
                            SetPedCombatAttributes(navigator, 46, 1)
                            SetPedCombatAbility(navigator, 100)
                            SetPedCombatMovement(navigator, 2)
                            SetPedCombatRange(navigator, 2)
                            SetPedKeepTask(navigator, true)
                            TaskEnterVehicle(navigator, transport, -1, 0, 1.0, 1)
                            GiveWeaponToPed(navigator, GetHashKey(NavWep), 250, false, true)
                            SetPedAsCop(navigator, true)
                            --
                            TaskVehicleDriveWander(pilot, transport, 80.0, 443)
                            MissionStart = 1
                            local PlayerData = QBCore.Functions.GetPlayerData()
                            local PlayerID = PlayerData.citizenid
                            print('Citizen ID: '..PlayerID..' Has Successfully Trigger the Armored Truck Robbery!')
                            TriggerServerEvent("QBCore:Server:RemoveItem", itemname, 1)
                            TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[itemname], "remove")
                            Citizen.Wait(60000)
                            cooldown = false
                        end,
                    
                        function() -- failure
                            QBCore.Functions.Notify(Config.FailureNotification, 'error', 3200)
                            TriggerServerEvent("QBCore:Server:RemoveItem", itemname, 1)
                            TriggerEvent('inventory:client:ItemBox', QBCore.Shared.Items[itemname], "remove")
                        end)
                    else
                        QBCore.Functions.Notify('Error.', 'error', 3200)
                    end
                end, function() -- Cancel
                    QBCore.Functions.Notify('Cancelled.', 'error', 3200)
                end)
            else
                QBCore.Functions.Notify(Config.NoItemMessage, "error")
            end
        end, Config.HackItem)
    else
        QBCore.Functions.Notify(Config.UnavailableNotification, 'error', 7500)
    end

end)

---- C4 AND MONEY COLLECTION ----  
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)

        if MissionStart == 1 then
            local plyCoords = GetEntityCoords(PlayerPedId(), false)
            local transCoords = GetEntityCoords(transport)
            local dist = #(plyCoords - transCoords)

            if dist <= 55.0 then

                DrawMarker(0, transCoords.x, transCoords.y, transCoords.z + 4.5, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, 135, 31, 35, 100, 1, 0, 0, 0)
                if warning == 0 then
                    warning = 1
                    QBCore.Functions.Notify(Config.KillGuardsNotification, "error")
                end

                if GuardsDead == 0 then
                    CheckGuards()
                elseif GuardsDead == 1 and BlownUp == 0 then
                    AlertPolice()
                    
                end

            else
                Citizen.Wait(500)
            end

            if dist <= 7 and BlownUp == 0 and PlayerJob.name ~= 'police' then
                if BlowBackdoor == 0 then
                    BlowBackdoor = 1
                end
 
                exports['qb-target']:AddTargetEntity(transport, {
                    options = {
                        { 
                        type = "client", 
                        event = "qb-truckrobbery:vehiclebomb",
                        label = Config.BombPrompt, 
                        icon = Config.BombIcon,
                        },
                    },
                    distance = 2.5
                })

            end

        else
            Citizen.Wait(1500)
        end
    end
end)



function CheckVehicleInformation()
    if IsVehicleStopped(transport) then
        if IsVehicleSeatFree(transport, -1) and IsVehicleSeatFree(transport, 0) and IsVehicleSeatFree(transport, 1) and
            GuardsDead == 1 then
            if not IsEntityInWater(PlayerPedId()) then
                if not bombed then 
                    bombed = true
                    RequestAnimDict('anim@heists@ornate_bank@thermal_charge_heels')
                    while not HasAnimDictLoaded('anim@heists@ornate_bank@thermal_charge_heels') do
                        Citizen.Wait(50)
                    end
                    local x, y, z = table.unpack(GetEntityCoords(PlayerPedId()))
                    prop = CreateObject(GetHashKey('prop_c4_final_green'), x, y, z + 0.2, true, true, true)
                    AttachEntityToEntity(prop, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 60309), 0.06, 0.0, 0.06, 90.0,
                        0.0, 0.0, true, true, false, true, 1, true)
                    SetCurrentPedWeapon(PlayerPedId(), GetHashKey("WEAPON_UNARMED"), true)
                    FreezeEntityPosition(PlayerPedId(), true)
                    TaskPlayAnim(PlayerPedId(), 'anim@heists@ornate_bank@thermal_charge_heels', "thermal_charge", 3.0, -8,
                        -1, 63, 0, 0, 0, 0)
                    Citizen.Wait(5500)
                    ClearPedTasks(PlayerPedId())
                    DetachEntity(prop)
                    AttachEntityToEntity(prop, transport, GetEntityBoneIndexByName(transport, 'door_pside_r'), -0.7, 0.0,
                        0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
                    QBCore.Functions.Notify("The load will be detonated in " .. TimeToBlow / 1000 .. " seconds.", "error")
                    FreezeEntityPosition(PlayerPedId(), false)
                    Citizen.Wait(TimeToBlow)
                    local transCoords = GetEntityCoords(transport)
                    SetVehicleDoorBroken(transport, 2, false)
                    SetVehicleDoorBroken(transport, 3, false)
                    AddExplosion(transCoords.x, transCoords.y, transCoords.z, 'EXPLOSION_TANKER', 2.0, true, false, 2.0)
                    ApplyForceToEntity(transport, 0, transCoords.x, transCoords.y, transCoords.z, 0.0, 0.0, 0.0, 1, false,
                        true, true, true, true)
                    BlownUp = 1
                    lootable = 1
                    QBCore.Functions.Notify(Config.BombedSuccessNotification, "success")
                    RemoveBlip(TruckBlip)
                    Citizen.Wait(120000)
                    bombed = false
                else

                end
            else
                QBCore.Functions.Notify(Config.PositionErrorNotification, "error")
            end
        else
            QBCore.Functions.Notify(Config.VehicleNotEmptyNotification, "error")
        end
    else
        QBCore.Functions.Notify(Config.VehicleMovingNotification, "error")
    end
end

-- Crim Client
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5)

        if lootable == 1 then
            local plyCoords = GetEntityCoords(PlayerPedId(), false)
            local transCoords = GetEntityCoords(transport)
            local dist = #(plyCoords - transCoords)

            if dist > 45.0 then
                Citizen.Wait(500)
            end

            if dist <= 4.5 then
                if PickupMoney == 0 then
                    exports['qb-target']:AddTargetEntity(transport, {
                    options = {
                        { 
                        type = "client", 
                        event = "qb-truckrobbery:vehiclegrabcash",
                        label = Config.CashPrompt, 
                        icon = Config.CashIcon,
                        },
                    },
                    distance = 2.5
                })
                    PickupMoney = 1
                end
                -- if IsControlJustPressed(0, 38) then
                --     lootable = 0
                --     TakingMoney()
                --     Citizen.Wait(500)
                -- end
            end
        else
            Citizen.Wait(1500)
        end
    end
end)

RegisterNetEvent("qb-truckrobbery:vehiclebomb", function()
    if not bombed then
        Wait(15)
        CheckVehicleInformation()
        TriggerEvent("qb-truckrobbery:client:911alert")
        Citizen.Wait(500)

    else
        QBCore.Functions.Notify(Config.BombCooldownNotification, 'error')
    end

end)

RegisterNetEvent("qb-truckrobbery:vehiclegrabcash", function()
    if not cashgrabbed then

        TakingMoney()
        Citizen.Wait(500)

    end

end)



RegisterNetEvent('qb-truckrobbery:cleanup', function()
    PickupMoney = 0
    BlowBackdoor = 0
    SilenceAlarm = 0
    PoliceAlert = 0
    PoliceBlip = 0
    LootTime = 1
    GuardsDead = 0
    lootable = 0
    BlownUp = 0
    MissionStart = 0
    warning = 0
end)

-- Crim Client
function TakingMoney()
    if not cashgrabbed then
        cashgrabbed = true
        RequestAnimDict('anim@heists@ornate_bank@grab_cash_heels')
        while not HasAnimDictLoaded('anim@heists@ornate_bank@grab_cash_heels') do
        Citizen.Wait(50)
        end
        local PedCoords = GetEntityCoords(PlayerPedId())
        local bag = CreateObject(GetHashKey('prop_cs_heist_bag_02'), PedCoords.x, PedCoords.y, PedCoords.z, true, true, true)
        AttachEntityToEntity(bag, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.0, 0.0, -0.16, 250.0, -30.0, 0.0,
            false, false, false, false, 2, true)
        TaskPlayAnim(PlayerPedId(), "anim@heists@ornate_bank@grab_cash_heels", "grab", 8.0, -8.0, -1, 1, 0, false, false,
            false)
        FreezeEntityPosition(PlayerPedId(), true)
        QBCore.Functions.Notify(Config.CashGrabNotification, "success")
        local _time = GetGameTimer()
        while GetGameTimer() - _time < 20000 do
            Citizen.Wait(1)
        end
        LootTime = GetGameTimer() - _time
        DeleteEntity(bag)
        ClearPedTasks(PlayerPedId())
        FreezeEntityPosition(PlayerPedId(), false)
        SetPedComponentVariation(PlayerPedId(), 5, 45, 0, 2)
        TriggerServerEvent("qb-truckrobbery:reward", LootTime)
        TriggerEvent('qb-truckrobbery:cleanup')
        Citizen.Wait(2500)
        Citizen.Wait(120000)
        DeleteEntity(transport)
        cashgrabbed = false
    else
        QBCore.Functions.Notify(Config.CashCooldownNotification, 'error')
    end
    
end


--- Laptop Target ---

exports['qb-target']:AddBoxZone("qb-truckrobbery:starthack", vector3(563.59, -3124.2, 18.26), 1.5, 1.6, { -- The name has to be unique, the coords a vector3 as shown, the 1.5 is the length of the boxzone and the 1.6 is the width of the boxzone, the length and width have to be float values
name = "qb-truckrobbery:starthack", -- This is the name of the zone recognized by PolyZone, this has to be unique so it doesn't mess up with other zones
heading = 90.0, -- The heading of the boxzone, this has to be a float value
debugPoly = false, -- This is for enabling/disabling the drawing of the box, it accepts only a boolean value (true or false), when true it will draw the polyzone in green
minZ = 17.7, -- This is the bottom of the boxzone, this can be different from the Z value in the coords, this has to be a float value
maxZ = 18.9, -- This is the top of the boxzone, this can be different from the Z value in the coords, this has to be a float value
}, {
options = { -- This is your options table, in this table all the options will be specified for the target to accept
{ -- This is the first table with options, you can make as many options inside the options table as you want
    type = "server", -- This specifies the type of event the target has to trigger on click, this can be "client", "server", "command" or "qbcommand", this is OPTIONAL and will only work if the event is also specified
    event = "qb-truckrobbery:starthack:server", -- This is the event it will trigger on click, this can be a client event, server event, command or qbcore registered command, NOTICE: Normal command can't have arguments passed through, QBCore registered ones can have arguments passed through
    icon = 'fas fa-laptop', -- This is the icon that will display next to this trigger option
    label = 'Access the Gruppe Sechs Database', -- This is the label of this option which you would be able to click on to trigger everything, this has to be a string
    -- item = 'trojan_usb', -- This is the item it has to check for, this option will only show up if the player has this item, this is OPTIONAL
}
},
distance = 2.5, -- This is the distance for you to be at for the target to turn blue, this is in GTA units and has to be a float value
})