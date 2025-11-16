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
util.TraceLine = function(traceData)
    --print("Modified TraceLine call!")
    local candidates = ents.FindInBox(traceData.start-Vector(1,1,1)*100,traceData.start+Vector(1,1,1)*100)
    --print("Trying to figure out entity that sent the trace. Candidates: ")
    --PrintTable(candidates)
    local originator = candidates[1]
    for _, candidate in pairs(candidates) do
        --print("Dotting ",candidate,", dot product: ",candidate:GetForward():GetNormalized()," dot ",(traceData.endpos-traceData.start):GetNormalized()," = ",candidate:GetForward():GetNormalized():Dot((traceData.endpos-traceData.start):GetNormalized()))
        if candidate:GetForward():GetNormalized():Dot((traceData.endpos-traceData.start):GetNormalized()) > originator:GetForward():GetNormalized():Dot((traceData.endpos-traceData.start):GetNormalized()) then
            originator = candidate
            --print("New originator: ",originator)
        end
    end
    --print("Settled on originator: ",originator)
    
    local baseFilter = traceData.filter
    traceData.filter = function(ent)
        local returnValue = false
        --print("Starting trace filtering")
        if baseFilter then
            --print("There's a base filter of type ",type(baseFilter))
            if type(baseFilter) == "table" then
                returnValue = not table.HasValue(baseFilter,ent) -- Set returnValue to be true if ent is not in baseFilter (table)
                --print("It's a table. returnValue set to ",returnValue)
            elseif type(baseFilter) == "Entity" or type(baseFilter) == "Player" then
                returnValue = baseFilter ~= ent -- Set returnValue to be true if ent is not baseFilter (entity)
                --print("It's an entity. returnValue set to ",returnValue)
            elseif type(baseFilter) == "function" then
                returnValue = baseFilter(ent)
                --print("It's a function. returnValue set to ",returnValue)
            end
        else
            --print("There's no base filter. returnValue set to true")
            returnValue = true
        end

        if returnValue then -- If we detect that a trace might hit, we then check for dimensions
            --print("Checking dimensions")
            if IsValid(originator) then
                if originator:GetDimension() ~= ent:GetDimension() then
                    returnValue = false
                else
                    returnValue = true
                end
                --print("returnValue set to ",returnValue)
            end
        end
        return returnValue
    end
    return baseTraceLine(traceData)
end
