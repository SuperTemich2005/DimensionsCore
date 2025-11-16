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

hook.Add("PlayerSwitchWeapon","Pull Weapons in Owner's Dimension",function(owner,_,weapon)
    weapon:SetDimension(owner:GetDimension())
end)
hook.Add("WeaponEquip","Pull Weapons in Owner's Dimension",function(weapon,owner)
    weapon:SetDimension(owner:GetDimension())
end)


local baseTraceLine = util.TraceLine
util.TraceLine = function(traceData)
    local baseFilter = traceData.filter
    local originator = nil
    local traceDimension = DEFAULT_DIMENSION
    
    -- Figure out what dimension we're in
    if baseFilter then
        if type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
            originator = baseFilter -- Assume that the filtered entity is the originator, because why would a filter be just one entity if it's not the caller?
            traceDimension = originator:GetDimension()
        else
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