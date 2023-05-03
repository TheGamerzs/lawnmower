local mowingJob = false
local cuttingGrass = false
local maxGrass = 0
local totalGrass = 0
local cutGrass = 0
local lawnmowerObject = nil
local grassHandler = {}

-- Cleanup
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if DoesEntityExist(lawnmowerObject) then
            DetachEntity(lawnmowerObject, true, true)
            DeleteEntity(lawnmowerObject)
        end

        for i = 1, #grassHandler do
            if DoesEntityExist(grassHandler[i]) then
                DeleteEntity(grassHandler[i])
            end
        end

        ClearPedTasks(PlayerPedId())
    end
end)

AddEventHandler("onResourceStart", function(resource)
    if resource == GetCurrentResourceName() then
        local attachedObjects = GetGamePool("CObject")

        for i = 1, #attachedObjects do DeleteEntity(attachedObjects[i]) end
    end
end)

-- TODO: Clean up this code

-- Logic
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(wait)

        if mowingJob then
            if cuttingGrass then

                local coords = GetEntityCoords(lawnmowerObject)

                for i = 1, #grassHandler do
                    local grassCoords = GetEntityCoords(grassHandler[i])

                    DrawMarker(1, grassCoords.x, grassCoords.y,
                               grassCoords.z + 0.1, 0, 0, 0, 0, 0, 0, 0.5, 0.5,
                               0.05, 0, 255, 0, 200, 0, 0, 0, 0)

                end

                for i = 1, #grassHandler do
                    local grassCoords = GetEntityCoords(grassHandler[i])
                    local distance = GetDistanceBetweenCoords(coords,
                                                              grassCoords, true)

                    if distance < 0.75 then
                        if DoesEntityExist(grassHandler[i]) then
                            DeleteEntity(grassHandler[i])
                            RemoveBlip(GetBlipFromEntity(grassHandler[i]))
                            table.remove(grassHandler, i)
                            cutGrass = cutGrass + 1
                        end
                    end
                end

                if cutGrass == totalGrass then
                    mowingJob = false
                    cuttingGrass = false
                    totalGrass = 0
                    cutGrass = 0
                    ClearPedTasks(PlayerPedId())
                    DeleteEntity(lawnmowerObject)
                    TriggerEvent('chat:addMessage', {
                        color = {255, 0, 0},
                        multiline = true,
                        args = {
                            "Lawnmower", "You have finished mowing the lawn!"
                        }
                    })
                end
            end
        end
    end
end)

function startAnimation()
    -- Animation
    local dict = "timetable@gardener@lawnmow@"
    local anim = "idle_a"
    local dict2 = "anim@heists@box_carry@"
    local anim2 = "idle"

    RequestAnimDict(dict)
    RequestAnimDict(dict2)
    while not HasAnimDictLoaded(dict) or not HasAnimDictLoaded(dict2) do
        Citizen.Wait(0)
    end

    local len = GetAnimDuration(dict, anim)
    local len2 = GetAnimDuration(dict2, anim2)

    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, len, 0, 0, false, false,
                 false)

    Citizen.Wait(len * 1000)

    TaskPlayAnim(PlayerPedId(), dict2, anim2, 1.0, -1.0, len2, 49, 1, false,
                 true, false)

    cuttingGrass = true

    AttachEntityToEntity(lawnmowerObject, PlayerPedId(),
                         GetPedBoneIndex(PlayerPedId(), 28422), 0.0, -0.6, -1.2,
                         0.0, 0.0, 0.0, false, false, false, false, 2, true)

end

function isLeft(p1, p2, p3)
    return (p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)
end

function isPointInsideRegion(region, point)
    local wn = 0

    for i = 1, #region do
        local j = i % #region + 1

        if region[i].y <= point.y then
            if region[j].y > point.y and isLeft(region[i], region[j], point) > 0 then
                wn = wn + 1
            end
        else
            if region[j].y <= point.y and isLeft(region[i], region[j], point) <
                0 then wn = wn - 1 end
        end
    end

    return wn % 2 == 1
end

function generateGrass()
    local zones = zones[1].zones

    local failedPositions = 0

    local grassModel = GetHashKey(grass[math.random(1, #grass)])

    RequestModel(grassModel)
    while not HasModelLoaded(grassModel) do Wait(1) end

    for zone = 1, #zones do
        maxGrass = math.random(0, zones[zone].maxGrass)
        totalGrass = totalGrass + maxGrass

        for i = 1, maxGrass do

            local boundingCoords = zones[zone].boundingCoords
            local x = math.random() * (boundingCoords.x - boundingCoords.z) +
                          boundingCoords.x
            local y = math.random() * (boundingCoords.w - boundingCoords.y) +
                          boundingCoords.w

            while not isPointInsideRegion(zones[zone].coords, vector3(x, y, 0)) do
                Wait(0)

                failedPositions = failedPositions + 1

                x = math.random() * (boundingCoords.z - boundingCoords.x) +
                        boundingCoords[1].x
                y = math.random() * (boundingCoords.y - boundingCoords.w) +
                        boundingCoords.w
            end

            local _, z = GetGroundZFor_3dCoord(x, y, 100.0, 0)

            local grassObject = CreateObject(grassModel, x, y, z - 0.2, false,
                                             1, false)

            if grassObject == nil then
                i = i - 1
            else

                table.insert(grassHandler, grassObject)
                AddBlipForEntity(grassObject)
                SetEntityAsMissionEntity(grassObject, true, true)

                SetEntityHeading(grassObject, math.random(0, 360))
                PlaceObjectOnGroundProperly_2(grassObject)
                FreezeEntityPosition(grassObject, true)
            end
        end

    end

    print("Failed to generate " .. failedPositions .. " grass objects")

    print("Generated " .. #grassHandler .. " grass objects in " .. #zones ..
              " zones")
end

function startJob()
    RequestModel(lawnmowerModel)

    local spawnCoords = GetEntityCoords(PlayerPedId())
    local spawnHeading = GetEntityHeading(PlayerPedId())

    spawnCoords =
        GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.76, 0.0)

    local _, Z = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y,
                                       spawnCoords.z, 0)
    spawnCoords = vector3(spawnCoords.x, spawnCoords.y, Z)

    while not HasModelLoaded(lawnmowerModel) do Wait(0) end

    lawnmowerObject = CreateObject(lawnmowerModel, spawnCoords, true, false)
    SetEntityRotation(lawnmowerObject, vector3(0.0, 0.0, spawnHeading), 1, true)
    SetEntityAsMissionEntity(lawnmowerObject, true, true)
    SetModelAsNoLongerNeeded(lawnmowerModel)

    generateGrass()

    startAnimation()

    TriggerEvent("chatMessage", "Mowing job started!")
end

RegisterCommand("startmowingjob", function()
    if mowingJob then
        return TriggerEvent("chatMessage", "You're already on a mowing job!")
    end

    mowingJob = true
    cutGrass = 0

    startJob()
end, false)
