function DrawBoundingBox(region)
    local z = 100.0

    local x1, y1 = region.x, region.w
    local x2, y2 = region.z, region.w
    local x3, y3 = region.x, region.y
    local x4, y4 = region.z, region.y

    local _, z1 = GetGroundZFor_3dCoord(x1, y1, z, false)
    local _, z2 = GetGroundZFor_3dCoord(x2, y2, z, false)
    local _, z3 = GetGroundZFor_3dCoord(x3, y3, z, false)
    local _, z4 = GetGroundZFor_3dCoord(x4, y4, z, false)

    local c1 = vector3(x1, y1, z1 + 0.1)
    local c2 = vector3(x2, y2, z2 + 0.1)
    local c3 = vector3(x3, y3, z3 + 0.1)
    local c4 = vector3(x4, y4, z4 + 0.1)

    -- Draw 4 lines
    DrawLine(c1, c2, 255, 0, 0, 255)
    DrawLine(c1, c3, 0, 255, 0, 255)

    DrawLine(c4, c2, 0, 0, 255, 255)
    DrawLine(c4, c3, 255, 255, 0, 255)
end

function DrawRegionLines(region)
    for i = 1, #region.coords do
        local nextIndex = i + 1
        if nextIndex > #region.coords then nextIndex = 1 end

        local _, z = GetGroundZFor_3dCoord(region.coords[i].x,
                                           region.coords[i].y,
                                           region.coords[i].z)
        local _, z2 = GetGroundZFor_3dCoord(region.coords[nextIndex].x,
                                            region.coords[nextIndex].y,
                                            region.coords[nextIndex].z)

        local c1 = vector3(region.coords[i].x, region.coords[i].y, z + 0.1)
        local c2 = vector3(region.coords[nextIndex].x,
                           region.coords[nextIndex].y, z2 + 0.1)

        DrawLine(c1, c2, 255, 0, 0, 255)
    end
end

function DrawLineToPlayer(point)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local _, z = GetGroundZFor_3dCoord(playerCoords.x, playerCoords.y,
                                       playerCoords.z)

    local c1 = vector3(playerCoords.x, playerCoords.y, z + 0.1)
    local c2 = vector3(point.x, point.y, z + 0.1)

    DrawLine(c1, c2, 255, 0, 0, 255)
end

function DrawRegionPolygon(region)
    -- Using three coords, draw a poly
    local coords = region.coords

    for i = 1, #coords do
        local nextIndex = i + 1
        if nextIndex > #coords then nextIndex = 1 end

        local nextNextIndex = nextIndex + 1
        if nextNextIndex > #coords then nextNextIndex = 1 end

        local _, z =
            GetGroundZFor_3dCoord(coords[i].x, coords[i].y, coords[i].z)
        local _, z2 = GetGroundZFor_3dCoord(coords[nextIndex].x,
                                            coords[nextIndex].y,
                                            coords[nextIndex].z)
        local _, z3 = GetGroundZFor_3dCoord(coords[nextNextIndex].x,
                                            coords[nextNextIndex].y,
                                            coords[nextNextIndex].z)

        local c1 = vector3(coords[i].x, coords[i].y, z + 0.1)
        local c2 = vector3(coords[nextIndex].x, coords[nextIndex].y, z2 + 0.1)
        local c3 = vector3(coords[nextNextIndex].x, coords[nextNextIndex].y,
                           z3 + 0.1)

        DrawPoly(c1, c2, c3, 155, 150, 0, 175)
    end
end

RegisterCommand("pos", function()
    local coords = GetEntityCoords(PlayerPedId())
    TriggerEvent("chatMessage",
                 "X: " .. coords.x .. " Y: " .. coords.y .. " Z: " .. coords.z)
end, false)

RegisterCommand("bbox", function(source, args)
    local zoneID = tonumber(args[1])

    -- Calculate the bounding box for each zone, gettting the min and max x and y coords of the whole zone
    for i = 1, #zones[zoneID].zones do
        local zone = zones[zoneID].zones[i]
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

        print(vector4(minX, minY, maxX, maxY))

    end
end, false)

SetWeatherTypeNow("EXTRASUNNY")
SetWeatherTypePersist("EXTRASUNNY")
SetWeatherTypeNowPersist("EXTRASUNNY")
NetworkOverrideClockTime(12, 0, 0)

local addingZone = false
local zone = {maxGrass = 5, boundingCoords = vector4(0, 0, 0, 0), coords = {}}

RegisterCommand("addCoord", function()
    TriggerServerEvent("addCoord")
    addingZone = true
    local coords = GetEntityCoords(PlayerPedId())
    table.insert(zone.coords, coords)
end, false)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if addingZone then
            zone.boundingCoords = CalculateBoundingBox(zone)
            DrawBoundingBox(zone.boundingCoords)
            DrawRegionPolygon(zone)
            DrawRegionLines(zone)
            DrawLineToPlayer(zone.coords[#zone.coords])
        end
    end
end)

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
