local texts = {}

RegisterNetEvent('server:add3dtext')
AddEventHandler('server:add3dtext', function(textData)
    table.insert(texts, textData)
    TriggerClientEvent('client:sync3dtexts', -1, texts)
end)

RegisterNetEvent('server:remove3dtext')
AddEventHandler('server:remove3dtext', function(closestIndex)
    if closestIndex and texts[closestIndex] then
        table.remove(texts, closestIndex)
        TriggerClientEvent('client:sync3dtexts', -1, texts)
    end
end)

AddEventHandler('playerJoining', function(playerId)
    local src = playerId
    TriggerClientEvent('client:sync3dtexts', src, texts)
end)

if Config.Debug then
    RegisterCommand('debug3dtexts', function(source, args)
        print('Aktuelle 3D-Texte auf dem Server:')
        for i, textData in ipairs(texts) do
            print(i, textData.text, "~s~"..textData.coords)
        end
    end, false)
end