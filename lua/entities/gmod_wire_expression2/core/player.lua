e2function entity entity:aimEntity()
	if not IsValid(this) then return self:throw("Invalid entity!", NULL) end
	if not this:IsPlayer() then return self:throw("Expected a Player, got Entity", NULL) end
    
    local trace = util.TraceLine({
        start = this:EyePos(),
        endpos = this:EyePos()+this:GetAimVector()*32767,
        filter = function(ent)
            if ent == this or ent:GetDimension() ~= this:GetDimension() then
                return false
            end
            return true
        end
    })
	return trace.Entity
end

e2function vector entity:aimPos()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	if not this:IsPlayer() then return self:throw("Expected a Player, got Entity", Vector(0, 0, 0)) end

    local trace = util.TraceLine({
        start = this:EyePos(),
        endpos = this:EyePos()+this:GetAimVector()*32767,
        filter = function(ent)
            if ent == this or ent:GetDimension() ~= this:GetDimension() then
                return false
            end
            return true
        end
    })
	return trace.HitPos
end

e2function vector entity:aimNormal()
	if not IsValid(this) then return self:throw("Invalid entity!", Vector(0, 0, 0)) end
	if not this:IsPlayer() then return self:throw("Expected a Player, got Entity", Vector(0, 0, 0)) end

	local trace = util.TraceLine({
        start = this:EyePos(),
        endpos = this:EyePos()+this:GetAimVector()*32767,
        filter = function(ent)
            if ent == this or ent:GetDimension() ~= this:GetDimension() then
                return false
            end
            return true
        end
    })
	return trace.HitNormal
end