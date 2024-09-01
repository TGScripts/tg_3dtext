local markerActive = false
local currentMarkerCoords = nil
local texts = {}

RegisterCommand('position3dtext', function()
    Citizen.CreateThread(function()
        if markerActive then
            markerActive = false
            currentMarkerCoords = nil
            if Config.Debug then
                tg_shownotification("Der 3D-Text Positionierungsmodus wurde beendet.")
            end
            return
        end

        markerActive = true

        while markerActive do
            Citizen.Wait(0)

            local playerPed = PlayerPedId()
            local camCoords = GetGameplayCamCoord()
            local camRot = GetGameplayCamRot(0)
            local camDirection = RotAnglesToVec(camRot)

            local rayEndCoords = camCoords + camDirection * Config.ViewDistance
            
            local rayHandle = StartShapeTestRay(camCoords.x, camCoords.y, camCoords.z, rayEndCoords.x, rayEndCoords.y, rayEndCoords.z, -1, playerPed, 0)
            local _, hit, endCoords, _, _ = GetShapeTestResult(rayHandle)

            if hit then
                currentMarkerCoords = endCoords
                DrawMarker(Config.MarkerType, endCoords.x, endCoords.y, endCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, 0.1, 0, 0, 255, 255, false, true, 2, false, false, false, false)
            end
        end
    end)
end, false)

RegisterCommand('add3dtext', function(source, args)
    if markerActive and currentMarkerCoords then
        if #args < 2 then
            tg_shownotification("Bitte sowohl den ~y~Text~s~ als auch die ~y~Distanz~s~ angeben (zB: '~b~/add3dtext Hallo 10~s~').")
            return
        end

        local distance = tonumber(args[#args])
        if not distance or distance < Config.MinDistance or distance > Config.MaxDistance then
            tg_shownotification("Die Distanz muss zwischen ~b~"..Config.MinDistance.."~s~ und ~b~"..Config.MaxDistance.."~s~ liegen.")
            return
        end

        local text = table.concat(args, " ", 1, #args - 1)
        
        local textData = {coords = currentMarkerCoords, text = text, distance = distance}

        TriggerServerEvent('server:add3dtext', textData)
        if Config.Debug then
            tg_shownotification("Erfolgreich einen neuen 3D Text erstellt.")
        end
        
        markerActive = false
        currentMarkerCoords = nil
    else
        tg_shownotification("Bitte zuerst den '~b~/position3dtext~s~' Command verwenden.")
    end
end, false)

RegisterCommand('remove3dtext', function()
    if #texts == 0 then
        tg_shownotification("Es gibt keine 3D-Texte zum Entfernen.")
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestIndex = nil
    local closestDistance = Config.MaxDistance + 1

    for i, textData in ipairs(texts) do
        local dist = #(playerCoords - textData.coords)
        if dist < closestDistance then
            closestDistance = dist
            closestIndex = i
        end
    end

    if closestIndex then
        TriggerServerEvent('server:remove3dtext', closestIndex)
        tg_shownotification("Der nächste 3D-Text wurde entfernt.")
    else
        tg_shownotification("Kein 3D-Text in der Nähe zum Entfernen.")
    end
end, false)

RegisterNetEvent('client:sync3dtexts')
AddEventHandler('client:sync3dtexts', function(serverTexts)
    texts = serverTexts
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for _, textData in ipairs(texts) do
            local coords = textData.coords
            local text = textData.text
            local maxDistance = textData.distance

            Draw3DText(coords.x, coords.y, coords.z, text, maxDistance)
        end
    end
end)

function RotAnglesToVec(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

function Draw3DText(x, y, z, text, maxDistance)
    local camCoords = GetGameplayCamCoord()
    local dist = #(camCoords - vector3(x, y, z))

    if dist > maxDistance then
        return
    end

    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(1)

        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(text)
        EndTextCommandDisplayText(_x, _y)
    end
end

function tg_shownotification(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostMessagetext("CHAR_DEFAULT", "CHAR_DEFAULT", false, 0, "TG 3D-Text Script", "")
end

TriggerEvent('chat:addSuggestion', '/position3dtext', 'Starte den Platzierungsmodus für den 3D-Text.', {})

TriggerEvent('chat:addSuggestion', '/add3dtext', 'Platziere einen 3D-Text an der ausgewählten Position.', {
    { name="Text", help="Was soll drauf stehen?" },
    { name="Distanz", help="Wie weit soll der Text gesehen werden?" }
})

TriggerEvent('chat:addSuggestion', '/remove3dtext', 'Entferne einen nahe gelegenen 3D-Text.', {})

if Config.Debug then
    TriggerEvent('chat:addSuggestion', '/debug3dtexts', 'Liste aller aktiven 3D-Texte.', {})
end