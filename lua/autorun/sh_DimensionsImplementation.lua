AddCSLuaFile()

DEFAULT_DIMENSION = 0

-- Modify Entity Physics and define dimension management-related functions
local ENT = FindMetaTable("Entity")

function ENT:GetDimension()
    return self:GetNWInt("Dimension")
end

if SERVER then
    -- Function to Set Dimension. It will try writing dimension value to given entity and propagate the dimension to connected entities.
    function ENT:SetDimension(dimension)
        timer.Simple(0,function()
            if not IsValid(self) then return end

            -- Set dimension value
            self:SetNWInt("Dimension",dimension)

            -- Update collisions
            if IsValid(self:GetPhysicsObject()) and self:GetPhysicsObject():IsValid() then
                self:SetCustomCollisionCheck(dimension ~= DEFAULT_DIMENSION)
                self:CollisionRulesChanged()
            end
    
            -- Handle player's entities (weapons and viewmodels and viewentities)
            if self:IsPlayer() then
                for _, wep in ipairs(self:GetWeapons()) do
                    wep:SetDimension(dimension)
                end

                -- Also update visibility on ALL entities for this player
                for _, ent in pairs(ents.GetAll()) do
                    if IsValid(ent:GetOwner()) and ent:IsWeapon() and ent:GetOwner() == self then continue end
                    if (ent == self:GetViewModel(0)) or (ent == self:GetViewModel(1)) or (ent == self:GetViewModel(2)) then continue end
                    if ent == self:GetViewEntity() then continue end
                    if ent == self:GetHands() then continue end
                    ent:SetPreventTransmit(self,self:GetDimension() ~= ent:GetDimension())
                end
            end

            -- Make vehicles also pull players along
            if self:IsVehicle() then
                if self:GetDriver() then
                    self:GetDriver():SetDimension(dimension)
                end
            end

            -- Make dimension shift propagate on all constrained entities, but only if this is not a child
            if not IsValid(self:GetParent()) then
                for k, v in pairs(constraint.GetAllConstrainedEntities(self)) do
                    -- Set dimension value
                    v:SetNWInt("Dimension",dimension)
                    
                    -- Update collisions
                    if IsValid(v:GetPhysicsObject()) and v:GetPhysicsObject():IsValid() then
                        v:SetCustomCollisionCheck(dimension ~= DEFAULT_DIMENSION)
                        v:CollisionRulesChanged()
                    end
                    
                    -- Pull drivers in
                    if v:IsVehicle() then
                        if v:GetDriver() then
                            v:GetDriver():SetDimension(dimension)
                        end
                    end
                    
                    -- Propagate shift on children
                    for k2, v2 in pairs(v:GetChildren()) do
                        v2:SetDimension(dimension)
                    end

                    -- Update visibility
                    for _, ply in pairs(player.GetAll()) do
                        v:SetPreventTransmit(ply,ply:GetDimension() ~= v:GetDimension())
                    end
                end
            end

            -- Propagate shift on children
            for k, v in pairs(self:GetChildren()) do
                v:SetDimension(dimension)
            end

            -- Update visibility of this entity to ALL players
            for _, ply in pairs(player.GetAll()) do
                self:SetPreventTransmit(ply,ply:GetDimension() ~= self:GetDimension())
            end
        end) 
    end
    
    -- Hooks for setting dimension to newly created entities
    hook.Add("OnEntityCreated","Assign Dimension Values To Entities",function(ent)
        timer.Simple(0,function()
            if not IsValid(ent) then return end
            if ent:GetDimension() ~= nil then return end

            if IsValid(ent:GetOwner()) or IsValid(ent:CPPIGetOwner()) then
                if IsValid(ent:CPPIGetOwner()) then
                    ent:SetDimension(ent:CPPIGetOwner():GetDimension())
                elseif IsValid(ent:GetOwner()) then
                    ent:SetDimension(ent:GetOwner():GetDimension())
                end
            else
                ent:SetDimension(DEFAULT_DIMENSION)
            end
        end)
    end)

    hook.Add("CreateEntityRagdoll","Assign Dimension Values to Ragdolls",function(owner,doll)
        timer.Simple(0,function()
            if not IsValid(owner) then return end
            if not IsValid(doll) then return end

            doll:SetDimension(owner:GetDimension())
        end)
    end)

    -- Hook for handling physical colisions between entities
    hook.Add("ShouldCollide","Prevent Entities from Colliding Across Dimensions",function(ent1,ent2)
        return (ent1:GetDimension() == ent2:GetDimension()) or (ent1:IsWorld() or ent2:IsWorld())
    end)

    -- Hook for making bullets pass through extradimensional entities
    hook.Add("EntityFireBullets","Prevent Bullets from Getting Blocked by Extradimensional Entities",function(ent,data)
        local baseCallback = nil
        if data.Callback then
            baseCallback = data.Callback
        end
        data.Callback = function(attacker,baseTraceResult,dmgInfo)
            if IsValid(baseTraceResult.Entity) and baseTraceResult.Entity:GetDimension() ~= ent:GetDimension() then
                baseTraceResult.Hit = false
            end
            if baseCallback then
                return baseCallback(attacker,baseTraceResult,dmgInfo)
            end
        end
    end)

    -- Hook for preventing miscellaneous interactions between player and entities (credit Nova Astral)
    local interactionHook = {"PlayerUse","PhysgunPickup","AllowPlayerPickup","GravGunPickupAllowed","PlayerCanPickupWeapon","PlayerCanPickupItem","PlayerCanHearPlayersVoice","CanPlayerUnfreeze"}
    for k,hook in ipairs(interactionHook) do
        hook.Add(hook,"Prevent Player Interactions with Extradimensional Entities",function(ply,ent)
            if(ply:GetDimension() != ent:GetDimension()) then
                return false
            end
        end)
    end
end