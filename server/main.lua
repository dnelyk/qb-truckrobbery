local QBCore = exports['qb-core']:GetCoreObject()
local ResetTimer = Config.Cooldown * 1000
local ActiveMission = 0

RegisterServerEvent('qb-truckrobbery:starthack:server', function()
	local _source = source
	local xPlayer = QBCore.Functions.GetPlayer(_source)
	if ActiveMission == 0 then
		for _, v in pairs(QBCore.Functions.GetPlayers()) do
			local Player = QBCore.Functions.GetPlayer(v)
			if Player ~= nil then
				if Player.PlayerData.job.name == "police" then
					TriggerClientEvent('QBCore:Notify', _source, "You can't figure out what to do.")
				else
					TriggerClientEvent("qb-truckrobbery:starthack", _source)
					
				end
			end
		end
	else
		TriggerClientEvent('QBCore:Notify', _source, 'There are no trucks available right now.')
	end
end)

RegisterServerEvent('qb-truckrobbery:setcooldown', function()
	Cooldown()	
end)

RegisterServerEvent('qb-truckrobbery:server:callCops', function(streetLabel, coords)
    TriggerClientEvent("qb-truckrobbery:client:robberyCall", -1, streetLabel, coords)
end)

function Cooldown()
	ActiveMission = 1
	Wait(ResetTimer)
	ActiveMission = 0
	TriggerClientEvent('qb-truckrobbery:cleanup', -1)
end

RegisterServerEvent('qb-truckrobbery:alertpolice', function(x ,y, z)
    TriggerClientEvent('qb-truckrobbery:callpolice', -1, x, y, z)
end)

RegisterServerEvent('qb-truckrobbery:reward', function()
	local _source = source
	local xPlayer = QBCore.Functions.GetPlayer(_source)
	local bags = Config.BagAmount
	local info = {
		worth = Config.BagWorth
	}
	xPlayer.Functions.AddItem('markedbills', bags, false, info)
	TriggerClientEvent('inventory:client:ItemBox', _source, QBCore.Shared.Items['markedbills'], "add")

	local chance = math.random(1, 100)
	TriggerClientEvent('QBCore:Notify', _source, "You took "..bags.." bags of cash from the van.")

	if chance >= 90 then
		xPlayer.Functions.AddItem(Config.RareItem, 1)
		TriggerClientEvent('inventory:client:ItemBox', _source, QBCore.Shared.Items[Config.RareItem], "add")
	end
	Wait(2500)
end)
