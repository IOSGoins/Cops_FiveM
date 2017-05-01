local isCop = false
local isInService = false
local rank = "inconnu"
local checkpoints = {}
local existingVeh = nil
local handCuffed = false

-- Location to enable an officer service
local takingService = {
  --{x=850.156677246094, y=-1283.92004394531, z=28.0047378540039},
  {x=457.956909179688, y=-992.72314453125, z=30.6895866394043}
  --{x=1856.91320800781, y=3689.50073242188, z=34.2670783996582},
  --{x=-450.063201904297, y=6016.5751953125, z=31.7163734436035}
}

local stationGarage = {
	{x=452.115966796875, y=-1018.10681152344, z=28.4786586761475}
}

AddEventHandler("playerSpawned", function()
	TriggerServerEvent("police:checkIsCop")
end)

RegisterNetEvent('police:receiveIsCop')
AddEventHandler('police:receiveIsCop', function(result)
	if(result == "inconnu") then
		isCop = false
	else
		isCop = true
		rank = result
	end
end)

RegisterNetEvent('police:nowCop')
AddEventHandler('police:nowCop', function()
	isCop = true
end)

RegisterNetEvent('police:noLongerCop')
AddEventHandler('police:noLongerCop', function()
	isCop = false
	isInService = false
	local model = GetHashKey("a_m_y_mexthug_01")

	RequestModel(model)
	while not HasModelLoaded(model) do
		RequestModel(model)
		Citizen.Wait(0)
	end

	SetPlayerModel(PlayerId(), model)
	SetModelAsNoLongerNeeded(model)
	RemoveAllPedWeapons(GetPlayerPed(-1), true)
	GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_KNIFE"), true, true)
	
	if(existingVeh ~= nil) then
		SetEntityAsMissionEntity(existingVeh, true, true)
		Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(existingVeh))
		existingVeh = nil
	end
end)

RegisterNetEvent('police:fouille')
AddEventHandler('police:fouille', function()
	if(isInService) then
		t, distance = GetClosestPlayer()
		if(distance ~= -1 and distance < 1) then
			TriggerServerEvent("police:targetFouille", GetPlayerServerId(t))
		else
			TriggerServerEvent("police:targetFouilleEmpty")
		end
	else
		TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Vous n'êtes pas en service !")
	end
end)

RegisterNetEvent('police:amende')
AddEventHandler('police:amende', function(t, amount)
	if(isInService) then
		TriggerServerEvent("police:amendeGranted", t, amount)
	else
		TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Vous n'êtes pas en service !")
	end
end)

RegisterNetEvent('police:cuff')
AddEventHandler('police:cuff', function(t)
	if(isInService) then
		t, distance = GetClosestPlayer()
		if(distance ~= -1 and distance < 1) then
			TriggerServerEvent("police:cuffGranted", GetPlayerServerId(t))
		else
			TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Aucun joueur à portée !")
		end
	else
		TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Vous n'êtes pas en service !")
	end
end)

RegisterNetEvent('police:getArrested')
AddEventHandler('police:getArrested', function()
	if(isCop == false) then
		handCuffed = not handCuffed
		if(handCuffed) then
			TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Vous avez été menotté.")
		else
			TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Liberté ! Adieu merveilleuses menottes ...")
		end
	end
end)

RegisterNetEvent('police:payAmende')
AddEventHandler('police:payAmende', function(amount)
	TriggerServerEvent('bank:withdrawAmende', amount)
	TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Vous avez payé une amende de $"..amount..".")
end)

RegisterNetEvent('police:dropIllegalItem')
AddEventHandler('police:dropIllegalItem', function(id)
	TriggerEvent("player:looseItem", tonumber(id), exports.vdk_inventory:getQuantity(id))
end)

RegisterNetEvent('police:forceEnter')
AddEventHandler('police:forceEnter', function(id)
	if(isInService) then
		t, distance = GetClosestPlayer()
		if(distance ~= -1 and distance < 1) then
			TriggerServerEvent("police:forceEnterAsk", GetPlayerServerId(t))
		else
			TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Aucun joueur menotté à portée !")
		end
	else
		TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "Vous n'êtes pas en service !")
	end
end)

RegisterNetEvent('police:forcedEnteringVeh')
AddEventHandler('police:forcedEnteringVeh', function()
	if(handCuffed) then
		TriggerEvent('chatMessage', 'SYSTEM', {255, 0, 0}, "yo tt le monde, c'est Squeezie.")
		local coords = GetEntityCoords(GetPlayerPed(-1), 0)
		TaskWarpPedIntoVehicle(GetPlayerPed(-1), GetClosestVehicle(coords["x"], coords["y"], coords["z"], 3, 0, 0), -2)
	end
end)

function GetPlayers()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end

function GetClosestPlayer()
	local players = GetPlayers()
	local closestDistance = -1
	local closestPlayer = -1
	local ply = GetPlayerPed(-1)
	local plyCoords = GetEntityCoords(ply, 0)
	
	for index,value in ipairs(players) do
		local target = GetPlayerPed(value)
		if(target ~= ply) then
			local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
			local distance = GetDistanceBetweenCoords(targetCoords["x"], targetCoords["y"], targetCoords["z"], plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
			if(closestDistance == -1 or closestDistance > distance) then
				closestPlayer = value
				closestDistance = distance
			end
		end
	end
	
	return closestPlayer, closestDistance
end

function drawTxt(text,font,centre,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextProportional(0)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextDropShadow(0, 0, 0, 0,255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(centre)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x , y)
end

function getIsInService()
	return isInService
end

function isNearTakeService()
	for i = 1, #takingService do
		local ply = GetPlayerPed(-1)
		local plyCoords = GetEntityCoords(ply, 0)
		local distance = GetDistanceBetweenCoords(takingService[i].x, takingService[i].y, takingService[i].z, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
		if(distance < 30) then
			DrawMarker(1, takingService[i].x, takingService[i].y, takingService[i].z-1, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.5, 0, 0, 255, 155, 0, 0, 2, 0, 0, 0, 0)
		end
		if(distance < 2) then
			return true
		end
	end
end

function isNearStationGarage()
	for i = 1, #stationGarage do
		local ply = GetPlayerPed(-1)
		local plyCoords = GetEntityCoords(ply, 0)
		local distance = GetDistanceBetweenCoords(stationGarage[i].x, stationGarage[i].y, stationGarage[i].z, plyCoords["x"], plyCoords["y"], plyCoords["z"], true)
		if(distance < 30) then
			DrawMarker(1, stationGarage[i].x, stationGarage[i].y, stationGarage[i].z-1, 0, 0, 0, 0, 0, 0, 2.0, 2.0, 1.5, 0, 0, 255, 155, 0, 0, 2, 0, 0, 0, 0)
		end
		if(distance < 2) then
			return true
		end
	end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if(isCop) then
			if(isNearTakeService()) then
				if(isInService) then
					drawTxt("Appuyez sur ~g~E~s~ pour prendre congé de votre service",0,1,0.5,0.8,0.6,255,255,255,255)
				else
					drawTxt("Appuyez sur ~g~E~s~ pour vous mettre en service",0,1,0.5,0.8,0.6,255,255,255,255)
				end
				if IsControlJustPressed(1, 38)  then
					isInService = not isInService
					
					if(isInService) then
						local model = GetHashKey("s_m_y_cop_01")

						RequestModel(model)
						while not HasModelLoaded(model) do
							RequestModel(model)
							Citizen.Wait(0)
						end

						SetPlayerModel(PlayerId(), model)
						SetModelAsNoLongerNeeded(model)
						
						GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_NIGHTSTICK"), true, true)
						GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PISTOL50"), true, true)
						GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_STUNGUN"), true, true)
						GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_PUMPSHOTGUN"), true, true)
					else
						local model = GetHashKey("a_m_y_mexthug_01")

						RequestModel(model)
						while not HasModelLoaded(model) do
							RequestModel(model)
							Citizen.Wait(0)
						end

						SetPlayerModel(PlayerId(), model)
						SetModelAsNoLongerNeeded(model)
						RemoveAllPedWeapons(GetPlayerPed(-1), true)
						GiveWeaponToPed(GetPlayerPed(-1), GetHashKey("WEAPON_KNIFE"), true, true)
					end
				end
			end
			
			if(isInService) then
				if(isNearStationGarage()) then
					if(existingVeh ~= nil) then
						drawTxt("Appuyez sur ~g~E~s~ pour ranger votre véhicule de fonction",0,1,0.5,0.8,0.6,255,255,255,255)
					else
						drawTxt("Appuyez sur ~g~E~s~ pour prendre votre véhicule de fonction",0,1,0.5,0.8,0.6,255,255,255,255)
					end
					
					if IsControlJustPressed(1, 38)  then
						if(existingVeh ~= nil) then
							SetEntityAsMissionEntity(existingVeh, true, true)
							Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(existingVeh))
							existingVeh = nil
						else
							local car = GetHashKey("police3")
							local ply = GetPlayerPed(-1)
							local plyCoords = GetEntityCoords(ply, 0)
							
							RequestModel(car)
							while not HasModelLoaded(car) do
									Citizen.Wait(0)
							end
							
							existingVeh = CreateVehicle(car, plyCoords["x"], plyCoords["y"], plyCoords["z"], 90.0, true, false)
							TaskWarpPedIntoVehicle(ply, existingVeh, -1)
						end
					end
				end
				
				
			end
		else
			if (handCuffed == true) then
			  RequestAnimDict('mp_arresting')

			  while not HasAnimDictLoaded('mp_arresting') do
				Citizen.Wait(0)
			  end

			  local myPed = PlayerPedId()
			  local animation = 'idle'
			  local flags = 16

			  TaskPlayAnim(myPed, 'mp_arresting', animation, 8.0, -8, -1, flags, 0, 0, 0, 0)
			end
		end
    end
end)