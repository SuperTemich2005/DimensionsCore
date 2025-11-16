AddCSLuaFile()

DEFAULT_DIMENSION = "overworld"
DimensionTables = {} -- Key: dimension name. Value: table of entities residing in that dimension.

-- Modify Entity Physics and define dimension management-related functions
local ENT = FindMetaTable("Entity")
local PLY = FindMetaTable("Player")

function ENT:GetDimension()
    return self:GetNWString("Dimension")
end

function PLY:GetDimension()
    return self:GetNWString("Dimension")
end

if SERVER then
    -- Function to Set Dimension. It will try writing dimension value to given entity and propagate the dimension to connected entities.
    function PLY:SetDimension(dimension)
        timer.Simple(0,function()
            if not IsValid(self) then return end
            if DimensionTables[self:GetDimension()] then
                DimensionTables[self:GetDimension()][self] = nil
            end
            self:SetNWString("Dimension",dimension)

            -- Update collisions
            if IsValid(self:GetPhysicsObject()) and self:GetPhysicsObject():IsValid() then
                self:SetCustomCollisionCheck(dimension ~= DEFAULT_DIMENSION)
                self:CollisionRulesChanged()
            end

            -- Handle player's entities (weapons and viewmodels and viewentities)
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
            
            -- Update visibility of this entity to ALL players
            for _, ply in pairs(player.GetAll()) do
                self:SetPreventTransmit(ply,ply:GetDimension() ~= self:GetDimension())
            end
            
            if not DimensionTables[dimension] then
                DimensionTables[dimension] = {}
            end
            DimensionTables[dimension][self] = true
        end)
    end

    function ENT:SetDimension(dimension)
        timer.Simple(0,function()
            if not IsValid(self) then return end

            -- Set dimension value
            if DimensionTables[self:GetDimension()] then
                DimensionTables[self:GetDimension()][self] = nil
            end
            self:SetNWString("Dimension",dimension)

            -- Update collisions
            if IsValid(self:GetPhysicsObject()) and self:GetPhysicsObject():IsValid() then
                self:SetCustomCollisionCheck(dimension ~= DEFAULT_DIMENSION)
                self:CollisionRulesChanged()
            end

            -- Make vehicles also pull players along
            if self:IsVehicle() then
                if self:GetDriver() then
                    self:GetDriver():SetDimension(dimension)
                end
            end
            
            if not DimensionTables[dimension] then
                DimensionTables[dimension] = {}
            end
            -- Make dimension shift propagate on all constrained entities, but only if this is not a child
            if not IsValid(self:GetParent()) then
                for k, v in pairs(constraint.GetAllConstrainedEntities(self)) do
                    -- Set dimension value
                    if DimensionTables[v:GetDimension()] then
                        DimensionTables[v:GetDimension()][v] = nil
                    end
                    v:SetNWString("Dimension",dimension)
                    
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

                    DimensionTables[dimension][v] = true
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

            DimensionTables[dimension][self] = true
        end) 
    end
    
    -- Hooks for setting dimension to newly created entities
    hook.Add("OnEntityCreated","Assign Dimension Values To Entities",function(ent)
        timer.Simple(0,function()
            if not IsValid(ent) then return end
            print(ent,"is created!")
            if (ent:GetDimension() ~= "") then
                print("Dimension is already set for ",ent,": ",ent:GetDimension()) 
                return 
            end

            if IsValid(ent:GetOwner()) or IsValid(ent:CPPIGetOwner()) or IsValid(ent:GetCreator()) then
                print("Propaganding dimension from")
                if IsValid(ent:CPPIGetOwner()) then
                    print("CPPI Owner ",ent:CPPIGetOwner(),ent:CPPIGetOwner():GetDimension())
                    ent:SetDimension(ent:CPPIGetOwner():GetDimension())
                elseif IsValid(ent:GetOwner()) then
                    print("Vanilla Owner ",ent:GetOwner(),ent:GetOwner():GetDimension())
                    ent:SetDimension(ent:GetOwner():GetDimension())
                elseif IsValid(ent:GetCreator()) then
                    print("Vanilla Creator ",ent:GetCreator(),ent:GetCreator():GetDimension())
                    ent:SetDimension(ent:GetCreator():GetDimension())
                end
            end
            timer.Simple(0,function()
                print("Dimension: ",ent:GetDimension())
                if ent:GetDimension() == "" then
                    print("Dimension is an empty string. Falling back to DEFAULT_DIMENSION (",DEFAULT_DIMENSION,")")
                    ent:SetDimension(DEFAULT_DIMENSION)
                end
                timer.Simple(0,function()
                    print("Assigned dimension: ",ent:GetDimension())
                end)
            end)
        end)
    end)

    -- Hooks for putting players in dimensions
    local playerRespawnHooks = {"PlayerSpawn","PlayerInitialSpawn"}
    for _, hookName in pairs(playerRespawnHooks) do
        hook.Add(hookName,"Assign Dimension Values to Players",function(ply)
            print("Putting ",ply," in dimension ",DEFAULT_DIMENSION)
            ply:SetDimension(DEFAULT_DIMENSION)
        end)
    end

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
    local interactionHook = {"PlayerUse","PhysgunPickup","AllowPlayerPickup","GravGunPickupAllowed","PlayerCanPickupItem","PlayerCanHearPlayersVoice","CanPlayerUnfreeze","CanPlayerEnterVehicle","GravGunPunt"}
    for k,hookName in ipairs(interactionHook) do
        hook.Add(hookName,"Prevent Player Interactions with Extradimensional Entities",function(ply,ent)
            if(ply:GetDimension() != ent:GetDimension()) then
                return false
            end
        end)
    end

    --set the creator of an entity (for ent:GetCreator()) to the player that spawned it
    local playerSpawnedStuff = {"PlayerSpawnedNPC","PlayerSpawnedSENT","PlayerSpawnedSWEP","PlayerSpawnedVehicle"}
    for k,hookName in ipairs(playerSpawnedStuff) do
        hook.Add(hookName,"DimensionCore-SetSpawnedCreator",function(ply,ent)
            ent:SetCreator(ply)
        end)
    end

    --Extra because these ones have a model argument
    local playerSpawnedStuffExt = {"PlayerSpawnedEffect","PlayerSpawnedProp","PlayerSpawnedRagdoll"}
    for k,hookName in ipairs(playerSpawnedStuffExt) do
        hook.Add(hookName,"DimensionCore-SetSpawnedCreator",function(ply,model,ent)
            ent:SetCreator(ply)
        end)
    end

    -- Edge case, if a player is somehow in a vehicle that isnt in the same dimension
    hook.Add("PlayerLeaveVehicle","DimensionCore-LeaveVehicle",function(ply,veh)
        if(ply:GetDimension() ~= veh:GetDimension()) then
            ply:SetDimension(veh:GetDimension())
        end
    end)

    -- Return all players to the default dimension if an admin ran map cleanup
    --make sure this can check if a player is stuck in something and just respawn them later
    hook.Add("PostCleanupMap","DimensionCore-MapCleanup",function()
        for k,v in ipairs(player.GetAll()) do
            v:SetDimension(DEFAULT_DIMENSION)
        end
    end)
end

if CLIENT then
    --potentially add DrawPhysgunBeam, EntityFireBullets, GravGunPunt, and PlayerFootstep hooks if they still render from players/entities in other dimensions
    
    --may need PlayerStartVoice if you can see the hud icon of players in other dimensions using VC

    --make players very lonely by preventing them from seeing chat messages from players in other dimensions
    --make sure this doesnt break things like ulx message admins using @<message>
    hook.Add("OnPlayerChat", "DimensionCore-DimensionalChat", function(ply, text, teamChat, isDead)
        if(ply:GetDimension() ~= LocalPlayer():GetDimension()) then
            if(string.sub(text,1,1) ~= ">") then --make players talk cross-dimensionally if the message starts with a >
                return true
            end
        end
    end)

    hook.Add("EntityEmitSound", "DimensionCore-ClientSounds", function(tbl)
        local ent = tbl.Entity

        if(ent:GetDimension() ~= LocalPlayer():GetDimension()) then
            return false
        end
    end)

    /* -- unfinished currently as attacker / victim is the string name of it, not the entity, and it can be an npc or a player
    hook.Add("AddDeathNotice","DimensionCore-DeathNotice",function(attacker,attackerTeam,inflictor,victim,victimTeam)
        ent = findByName(victim) --this wont work as findByName does nothing on the client
        if(victim:GetDimension() ~= LocalPlayer():GetDimension()) then
            return false
        end
    end)
    */
end