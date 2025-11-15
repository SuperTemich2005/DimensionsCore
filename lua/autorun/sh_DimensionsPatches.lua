hook.Add("PlayerSwitchWeapon","Modify Toolgun to Not Trace Extradimensional Entities",function(ply,oldWeapon,newWeapon)
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
    local baseFilter = traceData.filter
    print("Modified TraceLine call!")
    local candidates = ents.FindInBox(traceData.start-Vector(1,1,1),traceData.start+Vector(1,1,1))
    print("Trying to figure out entity that sent the trace. Candidates: ")
    PrintTable(candidates)
    local originator = candidates[1]
    for _, candidate in pairs(candidates) do
        print("Dotting ",candidate,", dot product: ",candidate:GetForward():GetNormalized()," dot ",(traceData.end-traceData.start):GetNormalized()," = ",candidate:GetForward():GetNormalized():Dot((traceData.end-traceData.start):GetNormalized()))
        if candidate:GetForward():GetNormalized():Dot((traceData.end-traceData.start):GetNormalized()) > originator:GetForward():GetNormalized():Dot((traceData.end-traceData.start):GetNormalized()) then
            originator = candidate
            print("New originator: ",originator)
        end
    end
    traceData.filter = function(ent)
        local returnValue = false
        if IsValid(baseFilter) then
            if type(baseFilter) == "table" then
                returnValue = not table.HasValue(baseFilter,ent) -- Set returnValue to be true if ent is not in baseFilter (table)
            elseif type(baseFilter) == "Entity" then
                returnValue = baseFilter ~= ent -- Set returnValue to be true if ent is not baseFilter (entity)
            end
        end
        if returnValue then -- If we detect that a trace might hit, we then check for dimensions
            if originator:GetDimension() ~= ent:GetDimension() then
                returnValue = false
            end
        end
        return returnValue
    end
    baseTraceLine(traceData)
end