-- Debug log helper
local function DebugLog(message)
    if Config and Config.Debug then
        print('^3[WebAccess Debug]^7 ' .. message)
    end
end

DebugLog('Client script loading...')

local spawnedObjects = {}
local loadingModels = {}
local createdBlips = {}

local OpenPrompt = nil
local PromptGroup = GetRandomIntInRange(0, 0xffffff)
local IsUiOpen = false
local MenuIsOpen = false
local PendingOpen = nil
local ActiveLocation = nil

DebugLog('Variables initialized')

-----------------------------------------------------------
-- Load menu data
-----------------------------------------------------------
MenuData = {}
TriggerEvent("redemrp_menu_base:getData", function(call)
    MenuData = call
    DebugLog('MenuData initialized')
end)

-----------------------------------------------------------
-- R KEY prompt setup
-----------------------------------------------------------
function SetupPrompt()
    local label = CreateVarString(10, 'LITERAL_STRING', (Lang and Lang.PromptOpen) or "Open")
    OpenPrompt = PromptRegisterBegin()
    PromptSetControlAction(OpenPrompt, 0xE30CD707)  -- R key
    PromptSetText(OpenPrompt, label)
    PromptSetEnabled(OpenPrompt, true)
    PromptSetVisible(OpenPrompt, true)
    PromptSetStandardMode(OpenPrompt, true)
    PromptSetGroup(OpenPrompt, PromptGroup)
    PromptRegisterEnd(OpenPrompt)
    DebugLog('Prompt setup complete')
end
Citizen.CreateThread(SetupPrompt)

-----------------------------------------------------------
-- BLIP SYSTEM (RemoveAll → full rebuild for multiple coords)
-----------------------------------------------------------
function CreateBlip(v, pos)
    local key = GenerateObjectKey(v, pos)
    if createdBlips[key] then return end
    local blip = BlipAddForCoords(1664425300, pos.x, pos.y, pos.z)
    SetBlipSprite(blip, v.blip.sprite or 587827268, true)
    SetBlipScale(blip, 0.20)
    local label = CreateVarString(10, "LITERAL_STRING", v.name)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, label)
    createdBlips[key] = blip
    DebugLog('Created blip for: ' .. v.name)
end

function RemoveAllBlips()
    local count = 0
    for _, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then 
            RemoveBlip(blip)
            count = count + 1
        end
    end
    createdBlips = {}
    DebugLog('Removed ' .. count .. ' blips')
end

RegisterNetEvent("rodin_webaccess:receiveBlipList")
AddEventHandler("rodin_webaccess:receiveBlipList", function(list)
    -- Collect keys for accessible locations
    local validKeys = {}
    for _, v in ipairs(list) do
        local coordsList = v.coords
        if type(coordsList) ~= "table" then coordsList = { coordsList } end

        for _, pos in ipairs(coordsList) do
            local key = GenerateObjectKey(v, pos)
            validKeys[key] = true
            CreateBlip(v, pos)  -- Skips if it already exists
        end
    end
    
    -- Remove only blips that are no longer accessible
    for key, blip in pairs(createdBlips) do
        if not validKeys[key] then
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
                DebugLog('Removed blip (no access): ' .. key)
            end
            createdBlips[key] = nil
        end
    end
end)

AddEventHandler("playerSpawned", function()
    TriggerServerEvent("rodin_webaccess:canSeeBlip")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        TriggerServerEvent("rodin_webaccess:canSeeBlip")
    end
end)

-----------------------------------------------------------
-- Interaction object spawn
-----------------------------------------------------------
function GenerateObjectKey(v, pos)
    -- Generate a more unique key (x/y/z precision improved by x1000)
    return v.name .. "_" .. math.floor(pos.x * 1000) .. "_" .. math.floor(pos.y * 1000) .. "_" .. math.floor(pos.z * 1000)
end

function SpawnInteractionObject(v, pos)
    local key = GenerateObjectKey(v, pos)

    if not v.model then return end
    if loadingModels[key] then return end
    if spawnedObjects[key] and DoesEntityExist(spawnedObjects[key]) then return end
    
    loadingModels[key] = true
    local model = GetHashKey(v.model)
    
    if not IsModelValid(model) then
        loadingModels[key] = nil
        return
    end

    RequestModel(model)
    local modelTimeout = 0
    while not HasModelLoaded(model) do 
        Wait(10)
        modelTimeout = modelTimeout + 1
        if modelTimeout > 100 then
            print('^1[WebAccess] ERROR: Failed to load model ' .. v.model .. '^7')
            loadingModels[key] = nil
            return
        end
    end
    
    if HasModelLoaded(model) then
        local obj = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
        local heading = pos.w or 0.0
        SetEntityHeading(obj, heading)
        FreezeEntityPosition(obj, true)
        
        spawnedObjects[key] = obj
        loadingModels[key] = nil
        DebugLog('Spawned object: ' .. v.name .. ' at ' .. pos.x .. ', ' .. pos.y .. ', ' .. pos.z .. ' (heading: ' .. heading .. ')')
        DebugLog('Object handle: ' .. obj)
    end
end

function DeleteInteractionObject(v, pos)
    local key = GenerateObjectKey(v, pos)
    local obj = spawnedObjects[key]
    if obj and DoesEntityExist(obj) then
        DeleteObject(obj)
        DebugLog('Deleted object: ' .. v.name)
    end
    spawnedObjects[key] = nil
    loadingModels[key] = nil
end

-----------------------------------------------------------
-- Permission Result
-----------------------------------------------------------
RegisterNetEvent("rodin_webaccess:useResult")
AddEventHandler("rodin_webaccess:useResult", function(allowed)

    if not PendingOpen then return end

    if not allowed then
        TriggerEvent("vorp:Tip", (Lang and Lang.NoPermission) or "You don't have permission.", 4000)
        PendingOpen = nil
        return
    end

    ActiveLocation = PendingOpen

    local links = (PendingOpen.links and type(PendingOpen.links) == "table") and PendingOpen.links or nil
    local linkCount = links and #links or 0

    if linkCount > 1 then
        
        local elements = {}
        for _, link in ipairs(links) do
            elements[#elements + 1] = { label = link.label, value = link.url }
        end

        MenuData.Open(
            'default',
            GetCurrentResourceName(),
            "webaccess_" .. PendingOpen.name,
            {
                title = PendingOpen.name,
                align = 'top-left',
                subtext = (Lang and Lang.MenuSelectSubtext) or "Please select an option.",
                elements = elements
            },
            function(data, menu)
                SetNuiFocus(true, true)
                SendNUIMessage({ action = "open", url = data.current.value })
                IsUiOpen = true
                MenuIsOpen = false
                menu.close()
            end,
            function(data, menu)
                menu.close()
                IsUiOpen = false
                MenuIsOpen = false
                ActiveLocation = nil
            end
        )

        MenuIsOpen = true
        IsUiOpen = true

    else
        local url = links and links[1].url or PendingOpen.url
        SetNuiFocus(true, true)
        SendNUIMessage({ action = "open", url = url })
        IsUiOpen = true
    end

    PendingOpen = nil
end)

-----------------------------------------------------------
-- Prompt Thread & Open UI
-----------------------------------------------------------
Citizen.CreateThread(function()
    DebugLog('Main thread started')
    
    -- Clean up any existing objects/blips from a previous session
    DebugLog('Cleaning up any existing objects from previous session...')
    for key, obj in pairs(spawnedObjects) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
            DebugLog('Cleaned up old object: ' .. key)
        end
    end
    for key, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
            DebugLog('Cleaned up old blip: ' .. key)
        end
    end
    spawnedObjects = {}
    createdBlips = {}
    
    DebugLog('Found ' .. #Config.Locations .. ' locations')
    DebugLog('Initialization complete!')
    
    while true do
        Citizen.Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())

        for _, v in ipairs(Config.Locations) do

            local coordsList = v.coords
            if type(coordsList) ~= "table" then coordsList = { coordsList } end

            for _, pos in ipairs(coordsList) do
                local key = GenerateObjectKey(v, pos)
                local obj = spawnedObjects[key]
                
                -- Object existence check (prevents duplicate spawns)
                if obj and not DoesEntityExist(obj) then
                    spawnedObjects[key] = nil
                end

                local dist = #(playerCoords - vector3(pos.x, pos.y, pos.z))

                if dist < 30 then
                    SpawnInteractionObject(v, pos)
                else
                    DeleteInteractionObject(v, pos)
                end

                if dist < 1.5 and not (IsUiOpen or MenuIsOpen) then
                    PromptSetActiveGroupThisFrame(PromptGroup, CreateVarString(10, 'LITERAL_STRING', v.name))

                    if IsControlJustPressed(0, 0xE30CD707) then
                        local dataCopy = table.clone(v)
                        dataCopy.coords = pos
                        PendingOpen = dataCopy
                        TriggerServerEvent("rodin_webaccess:canUse", v.name)
                    end
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- Auto Close UI if player walks +4m away
-----------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300)

        if (IsUiOpen or MenuIsOpen) and ActiveLocation then
            local dist = #(GetEntityCoords(PlayerPedId()) - vector3(ActiveLocation.coords.x, ActiveLocation.coords.y, ActiveLocation.coords.z))
            if dist > 4.0 then
                SendNUIMessage({ action = "close" })
                SetNuiFocus(false, false)
                IsUiOpen = false
                MenuIsOpen = false
                ActiveLocation = nil
                if MenuData and MenuData.CloseAll then
                    pcall(function() MenuData.CloseAll() end)
                end
            end
        end
    end
end)

-----------------------------------------------------------
-- NUI CLOSE
-----------------------------------------------------------
RegisterNUICallback("close", function(_, cb)
    SendNUIMessage({ action = "close" })
    SetNuiFocus(false, false)
    IsUiOpen = false
    MenuIsOpen = false
    ActiveLocation = nil
    cb("ok")
end)

-----------------------------------------------------------
-- ESC / BACKSPACE CLOSE
-----------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if (IsUiOpen or MenuIsOpen) and
           (IsControlJustPressed(0, 0x156F7119) or IsControlJustPressed(0, 0x8CC9CD42)) then
           
            SendNUIMessage({ action = "close" })
            SetNuiFocus(false, false)
            IsUiOpen = false
            MenuIsOpen = false
            ActiveLocation = nil
            if MenuData and MenuData.CloseAll then
                pcall(function() MenuData.CloseAll() end)
            end
        end
    end
end)

-----------------------------------------------------------
-- Cleanup Function
-----------------------------------------------------------
local function CleanupResources()
    DebugLog('=== Starting cleanup process ===')
    
    -- Close UI
    SendNUIMessage({ action = "close" })
    SetNuiFocus(false, false)

    if MenuData then
        pcall(function() MenuData.CloseAll() end)
    end

    -- Delete spawned objects
    local objectCount = 0
    for key, obj in pairs(spawnedObjects) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
            objectCount = objectCount + 1
            DebugLog('Deleted object: ' .. key .. ' (handle: ' .. obj .. ')')
        end
    end
    DebugLog('Deleted ' .. objectCount .. ' objects')
    
    -- Delete blips
    local blipCount = 0
    for key, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
            blipCount = blipCount + 1
            DebugLog('Deleted blip: ' .. key .. ' (ID: ' .. blip .. ')')
        end
    end
    DebugLog('Deleted ' .. blipCount .. ' blips')
    
    -- Delete prompt
    if OpenPrompt then
        PromptDelete(OpenPrompt)
        DebugLog('Deleted prompt')
    end
    
    -- Clear tables and flags
    spawnedObjects = {}
    createdBlips = {}
    loadingModels = {}
    IsUiOpen = false
    MenuIsOpen = false
    PendingOpen = nil
    ActiveLocation = nil
    
    DebugLog('=== Cleanup completed! ===')
end

-----------------------------------------------------------
-- Resource Stop Handlers
-----------------------------------------------------------
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        DebugLog('onResourceStop event triggered for: ' .. resource)
        CleanupResources()
    end
end)

AddEventHandler("onClientResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        DebugLog('onClientResourceStop event triggered for: ' .. resource)
        CleanupResources()
    end
end)

-- Cleanup when player drops
AddEventHandler("playerDropped", function()
    CleanupResources()
end)

-- Resource state monitor thread (more reliable cleanup)
Citizen.CreateThread(function()
    local resourceName = GetCurrentResourceName()
    local wasRunning = true
    
    while true do
        Wait(1000) -- Check every 1 second
        
        local state = GetResourceState(resourceName)
        
        -- If resource is stopping/stopped/missing
        if state == 'stopped' or state == 'stopping' or state == 'missing' or state == 'unknown' then
            if wasRunning then
                CleanupResources()
                wasRunning = false
                break -- End this thread
            end
        else
            wasRunning = true
        end
    end
end)