RegisterCommand("s_bbox", function(source, args)
    local zoneID = tonumber(args[1])
    for i = 1, #zones[zoneID].zones do
        CalculateBoundingBox(zones[zoneID].zones[i])
    end
end, false)

zone = {maxGrass = 5, boundingCoords = vector4(0, 0, 0, 0), coords = {}}

RegisterNetEvent("addCoord")
AddEventHandler("addCoord", function()
    local player = tonumber(source)
    local ped = GetPlayerPed(player)
    local playerCoords = GetEntityCoords(ped)

    table.insert(zone.coords, playerCoords)
    print(playerCoords)
end)

RegisterCommand("stopZone", function()
    zone.boundingCoords = CalculateBoundingBox(zone)

    print(zone)

    zone = {maxGrass = 5, boundingCoords = vector4(0, 0, 0, 0), coords = {}}
end, false)

function CalculateBoundingBox(region)
    -- Calculate the bounding box for each zone, gettting the min and max x and y coords of the whole zone

    local zone = region
    local minX = 9999999
    local minY = 9999999
    local maxX = -999999
    local maxY = -999999

    for i = 1, #zone.coords do
        if zone.coords[i].x < minX then minX = zone.coords[i].x end
        if zone.coords[i].y < minY then minY = zone.coords[i].y end
        if zone.coords[i].x > maxX then maxX = zone.coords[i].x end
        if zone.coords[i].y > maxY then maxY = zone.coords[i].y end
    end

    return vector4(minX, minY, maxX, maxY)

end
