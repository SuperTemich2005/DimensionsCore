--[[ hook.Add("DISABLED PlayerSwitchWeapon","Modify Toolgun to Not Trace Extradimensional Entities",function(ply,oldWeapon,newWeapon)
    timer.Simple(0,function()
        if newWeapon:GetClass() == "gmod_tool" then
            local weapon = ply:GetTool()

            local baseLeft = weapon.LeftClick
            local baseRight = weapon.RightClick
            local baseReload = weapon.Reload

            function weapon:LeftClick(trace)
                local newTrace = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = ply:EyePos()+ply:GetAimVector()*32767,
                    filter = function(ent)
                        if ent == ply or ent:GetDimension() ~= ply:GetDimension() then
                            return false
                        end
                        return true
                    end
                })
                return baseLeft(self,newTrace)
            end
            function weapon:RightClick(trace)
                local newTrace = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = ply:EyePos()+ply:GetAimVector()*32767,
                    filter = function(ent)
                        if ent == ply or ent:GetDimension() ~= ply:GetDimension() then
                            return false
                        end
                        return true
                    end
                })
                return baseRight(self,newTrace)
            end
            function weapon:Reload(trace)
                local newTrace = util.TraceLine({
                    start = ply:EyePos(),
                    endpos = ply:EyePos()+ply:GetAimVector()*32767,
                    filter = function(ent)
                        if ent == ply or ent:GetDimension() ~= ply:GetDimension() then
                            return false
                        end
                        return true
                    end
                })
                return baseReload(self,newTrace)
            end
        end
    end)
end) ]]

function dim_GetFunctionCaller()
    --if SERVER then print("Call to dim_GetFunctionCaller") end
    local level = 0
    while debug.getinfo(level) and (debug.getinfo(level) ~= {}) do
        local key, originator = debug.getlocal(level,1)
        --if SERVER then print("Level: ",level,", Key: ",key,", Originator: ",originator) end
        if key == "self" and type(originator) == "Entity" or type(originator) == "Player" or type(originator) == "Weapon" then
            --if SERVER then print("Originator type seems to check out, returning ",originator) end
            if originator then return originator end
        --elseif key == "self" and type(originator) == "table" then
            --if SERVER then print("The originator is a table somehow? Trying to return originator.entity") end
            --if originator.entity then return originator.entity end
        else
            --if SERVER then print("Going up a level.") end
            level = level + 1
        end
    end
    --if SERVER then print("Nothing found...") end
    return
end

local baseTraceLine = util.TraceLine
util.TraceLine = function(traceData)
    local baseFilter = traceData.filter
    local traceDimension = DEFAULT_DIMENSION

    local originator = dim_GetFunctionCaller()
    if originator and IsValid(originator) then
        traceDimension = originator:GetDimension()
    end

    -- Build new filter
    local newFilter = nil
    if baseFilter then
        if type(baseFilter) == "table" then
            newFilter = table.Copy(baseFilter)
            for dimensionName, dimensionTable in pairs(DimensionTables) do
                if dimensionName ~= traceDimension then
                    for v, _ in pairs(dimensionTable) do
                        if not IsValid(v) then continue end
                        newFilter[#newFilter+1] = v
                    end
                end
            end
        elseif type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
            newFilter = {baseFilter}
            for dimensionName, dimensionTable in pairs(DimensionTables) do
                if dimensionName ~= traceDimension then
                    for v, _ in pairs(dimensionTable) do
                        if not IsValid(v) then continue end
                        newFilter[#newFilter+1] = v
                    end
                end
            end
        elseif type(baseFilter) == "function" then
            newFilter = function(ent)
                if ent:GetDimension() ~= traceDimension then return false end
                return baseFilter(ent)
            end
        end
    else
        newFilter = function(ent) 
            return ent:GetDimension() == traceDimension
        end
    end
    traceData.filter = newFilter
    return baseTraceLine(traceData)
end

local baseTraceHull = util.TraceHull
util.TraceHull = function(traceData)
    local baseFilter = traceData.filter
    local traceDimension = DEFAULT_DIMENSION

    local originator = dim_GetFunctionCaller()
    if originator and IsValid(originator) then
        traceDimension = originator:GetDimension()
    end

    -- Build new filter
    local newFilter = nil
    if baseFilter then
        if type(baseFilter) == "table" then
            newFilter = table.Copy(baseFilter)
            for dimensionName, dimensionTable in pairs(DimensionTables) do
                if dimensionName ~= traceDimension then
                    for v, _ in pairs(dimensionTable) do
                        if not IsValid(v) then continue end
                        newFilter[#newFilter+1] = v
                    end
                end
            end
        elseif type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
            newFilter = {baseFilter}
            for dimensionName, dimensionTable in pairs(DimensionTables) do
                if dimensionName ~= traceDimension then
                    for v, _ in pairs(dimensionTable) do
                        if not IsValid(v) then continue end
                        newFilter[#newFilter+1] = v
                    end
                end
            end
        elseif type(baseFilter) == "function" then
            newFilter = function(ent)
                if ent:GetDimension() ~= traceDimension then return false end
                return baseFilter(ent)
            end
        end
    else
        newFilter = function(ent) 
            return ent:GetDimension() == traceDimension
        end
    end
    traceData.filter = newFilter

    return baseTraceHull(traceData)
end


