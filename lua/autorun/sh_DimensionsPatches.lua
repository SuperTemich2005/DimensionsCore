hook.Add("DISABLED PlayerSwitchWeapon","Modify Toolgun to Not Trace Extradimensional Entities",function(ply,oldWeapon,newWeapon)
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
end)


local baseTraceLine = util.TraceLine
--[[ util.TraceLine = function(traceData)
    local candidates = ents.FindInBox(traceData.start-Vector(1,1,1)*100,traceData.start+Vector(1,1,1)*100)
    local originator = candidates[1]
    if #candidates > 0 then
        for _, candidate in pairs(candidates) do
            if candidate:GetForward():GetNormalized():Dot((traceData.endpos-traceData.start):GetNormalized()) > originator:GetForward():GetNormalized():Dot((traceData.endpos-traceData.start):GetNormalized()) then
                originator = candidate
            end
        end
    end
    local traceDimension = originator:GetDimension()
    if traceDimension == "" then traceDimension = DEFAULT_DIMENSION end
    
    local baseFilter = traceData.filter
    if baseFilter then
        if type(baseFilter) == "table" then
            for k, v in pairs(ents.GetAll()) do
                if v:GetDimension() ~= traceDimension then
                    baseFilter[#baseFilter+1] = v
                end
            end
        elseif type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
        elseif type(baseFilter) == "function" then
            baseFilter = function(ent)
                local returnValue = false
                if baseFilter then
                    if type(baseFilter) == "table" then
                        returnValue = not table.HasValue(baseFilter,ent) -- Set returnValue to be true if ent is not in baseFilter (table)
                    elseif type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
                        returnValue = baseFilter ~= ent -- Set returnValue to be true if ent is not baseFilter (entity)
                    elseif type(baseFilter) == "function" then
                        returnValue = baseFilter(ent)
                    end
                else
                    returnValue = true
                end
        
                if returnValue then -- If we detect that a trace might hit, we then check for dimensions
                    if IsValid(originator) then
                        if originator:GetDimension() ~= ent:GetDimension() then
                            returnValue = false
                        else
                            returnValue = true
                        end
                    end
                end
                return returnValue
            end
        end
    else
        baseFilter = {}
        for k, v in pairs(ents.GetAll()) do
            if v:GetDimension() ~= traceDimension then
                baseFilter[k] = v
            end
        end
    end
    traceData.filter = baseFilter
    return baseTraceLine(traceData)
end ]]
util.TraceLine = function(traceData)
    local baseFilter = traceData.filter
    local originator = nil
    local traceDimension = DEFAULT_DIMENSION
    
    --print("Base Filter: ",baseFilter,type(baseFilter))
    -- Figure out what dimension we're in
    if baseFilter then
        if type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
            originator = baseFilter -- Assume that the filtered entity is the originator, because why would a filter be just one entity if it's not the caller?
            traceDimension = originator:GetDimension()
        else
            --PrintTable(baseFilter)
            -- Now we need to use the expensive calculation
            local startpos = traceData.start
            local traceDir = (traceData.endpos-traceData.start):GetNormalized()
            
            local candidates = ents.FindInSphere(startpos,64)
            if #candidates > 0 then
                originator = candidates[1]
                local originatorBestScore = originator:GetForward():Dot(traceDir)
                for _, candidate in pairs(candidates) do
                    local thisScore = candidate:GetForward():Dot(traceDir)
                    if thisScore > originatorBestScore then
                        originator = candidate
                        originatorBestScore = thisScore
                    end
                    if originatorBestScore > 0.9999 then break end
                end
                traceDimension = originator:GetDimension()
            end
        end
    end

    if SERVER then print("Trace dimension: ",traceDimension) end
    
    -- Build new filter
    local newFilter = nil
    if baseFilter then
        if type(baseFilter) == "table" then
            if SERVER then print("New filter will be a table (from table)") end
            newFilter = table.Copy(baseFilter)
            --[[ for k, v in pairs(DimensionTables[traceDimension]) do
                newFilter[#newFilter+1] = v
            end ]]
            for dimensionName, dimensionTable in pairs(DimensionTables) do
                if dimensionName ~= traceDimension then
                    for v, _ in pairs(dimensionTable) do
                        if not IsValid(v) then continue end
                        newFilter[#newFilter+1] = v
                        if SERVER then print("Adding entity ",v," from dimension ",dimensionName) end
                    end
                end
            end
            --print("New Filter is a table")
            --PrintTable(newFilter)
        elseif type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
            if SERVER then print("New filter will be a table (from entity ",baseFilter,")") end
            newFilter = {baseFilter}
            for dimensionName, dimensionTable in pairs(DimensionTables) do
                if dimensionName ~= traceDimension then
                    for v, _ in pairs(dimensionTable) do
                        if not IsValid(v) then continue end
                        newFilter[#newFilter+1] = v
                        if SERVER then print("Adding entity ",v," from dimension ",dimensionName) end
                    end
                end
            end
            --print("New Filter is a table but was made out of an entity ",baseFilter)
            --PrintTable(newFilter)
        elseif type(baseFilter) == "function" then
            if SERVER then print("New filter will be a function") end
            newFilter = function(ent)
                if ent:GetDimension() ~= traceDimension then return false end
                return baseFilter(ent)
            end
            --print("New Filter is a function")
        end
    else
        newFilter = function(ent) 
            return ent:GetDimension() == traceDimension
        end
    end
    traceData.filter = newFilter
    return baseTraceLine(traceData)
end