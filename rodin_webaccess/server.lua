local VorpCore
TriggerEvent("getCore", function(core)
    VorpCore = core
end)

local function canAccessLocation(src, cfg)
    if not VorpCore then return false end
    
    local Character = VorpCore.getUser(src).getUsedCharacter
    if not Character then return false end
    
    local job = Character.job or "none"
    local grade = tonumber(Character.jobgrade or Character.jobGrade or 0)

    if cfg.requiredJobs == false or cfg.requiredJobs == nil then
        return true
    end

    for requiredJob, requiredGrade in pairs(cfg.requiredJobs) do
        if job == requiredJob and grade >= (tonumber(requiredGrade) or 0) then
            return true
        end
    end

    return false
end

-- UI ACCESS
RegisterNetEvent("rodin_webaccess:canUse")
AddEventHandler("rodin_webaccess:canUse", function(locationName)
    local src = source
    for _, v in pairs(Config.Locations) do
        if v.name == locationName then
            TriggerClientEvent("rodin_webaccess:useResult", src, canAccessLocation(src, v))
            return
        end
    end
    TriggerClientEvent("rodin_webaccess:useResult", src, false)
end)

-- BLIP VISIBILITY
RegisterNetEvent("rodin_webaccess:canSeeBlip")
AddEventHandler("rodin_webaccess:canSeeBlip", function()
    local src = source
    local result = {}

    for _, cfg in pairs(Config.Locations) do
        if cfg.blip and cfg.blip.enable and canAccessLocation(src, cfg) then
            table.insert(result, cfg)
        end
    end

    TriggerClientEvent("rodin_webaccess:receiveBlipList", src, result)
end)
