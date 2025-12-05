-- This file is dedicated to patching entities and functions in other addons.

local function isOneOf(value, values_str, case_sensitive) -- Function used by gmod_wire_target_finder
    if not isstring(value) or not isstring(values_str) then return false end
    if values_str == "" then return true end -- why :/

    if not case_sensitive then
        value = value:lower()
        values_str = values_str:lower()
    end

    for possible in values_str:gmatch("[^, ]+") do
        if possible == value then return true end
    end
    return false
end
local function CheckPlayers(self, contact) -- Function used by gmod_wire_target_finder
	if self.NoTargetOwner and self:GetPlayer() == contact then return false end
	if not isOneOf(contact:GetName(), self.PlayerName, self.CaseSen) then return false end

	-- Check if the player's steamid/steamid64 matches the SteamIDs
	if self.SteamName:Trim() ~= "" then
		local contact_steamid, contact_steamid64 = contact:SteamID(), contact:SteamID64() or "multirun"
		if not ( isOneOf(contact_steamid, self.SteamName, self.CaseSen) or isOneOf(contact_steamid64, self.SteamName, self.CaseSen) ) then
			return false
		end
	end

	return self:FindColor(contact) and self:CheckTheBuddyList(contact)
end


hook.Add("PlayerSwitchWeapon","Pull Weapons in Owner's Dimension",function(owner,_,weapon)
    weapon:SetDimension(owner:GetDimension())
end)

hook.Add("WeaponEquip","Pull Weapons in Owner's Dimension",function(weapon,owner)
    weapon:SetDimension(owner:GetDimension())
end)


hook.Add("OnEntityCreated","Patch Entities to Account for Dimensions",function(ENT)
    if ENT:GetClass() == "gmod_wire_target_finder" then
        function ENT:Think()
            self.BaseClass.Think(self)

            if not (self.Inputs.Hold and self.Inputs.Hold.Value > 0) then
                -- Find targets that meet requirements
                local mypos = self:GetPos()
                local bogeys, dists, ndists = {}, {}, 0
                for _, contact in ipairs(ents.FindInSphere(mypos, self.MaxRange or 10)) do
                    if contact:GetDimension() ~= self:GetDimension() then continue end
                    local class = contact:GetClass()
                    if
                        -- Ignore array of entities if provided
                        (not self.Ignored or not table.HasValue(self.Ignored, contact) ) and
                        -- Ignore owned stuff if checked
                        ((not self.NoTargetOwnersStuff or (class == "player") or (WireLib.GetOwner(contact) ~= self:GetPlayer())) and
                        -- NPCs
                        ((self.TargetNPC and (contact:IsNPC()) and (isOneOf(class, self.NPCName))) or
                        --Players
                        (self.TargetPlayer and (class == "player") and CheckPlayers(self, contact) or
                        --Locators
                        (self.TargetBeacon and (class == "gmod_wire_locator")) or
                        --RPGs
                        (self.TargetRPGs and (class == "rpg_missile")) or
                        -- Hoverballs
                        (self.TargetHoverballs and (class == "gmod_hoverball" or class == "gmod_wire_hoverball")) or
                        -- Thruster
                        (self.TargetThrusters	and (class == "gmod_thruster" or class == "gmod_wire_thruster" or class == "gmod_wire_vectorthruster")) or
                        -- Props
                        (self.TargetProps and (class == "prop_physics") and (isOneOf(contact:GetModel(), self.PropModel))) or
                        -- Vehicles
                        (self.TargetVehicles and contact:IsVehicle()) or
                        -- Entity classnames
                        (self.EntFil ~= "" and isOneOf(class, self.EntFil)))))
                    then
                        local dist = (contact:GetPos() - mypos):Length()
                        if (dist >= self.MinRange) then
                            -- put targets in a table index by the distance from the finder
                            bogeys[dist] = contact

                            ndists = ndists + 1
                            dists[ndists] = dist
                        end
                    end
                end

                -- sort the list of bogeys by key (distance)
                self.Bogeys = {}
                self.InRange = {}
                table.sort(dists)
                local k = 1
                for i, d in ipairs(dists) do
                    if not self:IsTargeted(bogeys[d], i) then
                        self.Bogeys[k] = bogeys[d]
                        k = k + 1
                        if k > self.MaxBogeys then break end
                    end
                end


                -- check that the selected targets are valid
                for i = 1, self.MaxTargets do
                    if (self:IsOnHold(i)) then
                        self.InRange[i] = true
                    end

                    if not self.InRange[i] or not self.SelectedTargets[i] or self.SelectedTargets[i] == nil or not self.SelectedTargets[i]:IsValid() then
                        if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], false) end
                        if (#self.Bogeys > 0) then
                            self.SelectedTargets[i] = table.remove(self.Bogeys, 1)
                            if (self.PaintTarget) then self:TargetPainter(self.SelectedTargets[i], true) end
                            Wire_TriggerOutput(self, tostring(i), 1)
                            Wire_TriggerOutput(self, tostring(i) .. "_Ent", self.SelectedTargets[i])
                        else
                            self.SelectedTargets[i] = nil
                            Wire_TriggerOutput(self, tostring(i), 0)
                            Wire_TriggerOutput(self, tostring(i) .. "_Ent", NULL)
                        end
                    end
                end

            end

            -- temp hack
            if self.SelectedTargets[1] then
                self:ShowOutput(true)
            else
                self:ShowOutput(false)
            end
            self:NextThink(CurTime() + 1)
            return true
        end
    elseif ENT:GetClass() == "gmod_wire_trigger" then
        ENT:AddCallback("Setup",function()
            timer.Simple(FrameTime(),function()
                ENT:GetTriggerEntity():SetDimension(ENT:GetDimension())
            end)
        end)
    elseif ENT:GetClass() == "gmod_wire_trigger_entity" then
        function ENT:StartTouch( ent )

            local owner = self:GetTriggerEntity()
            if not IsValid( owner ) then return end
            if ent == owner then return end -- this never happens but just in case...
            if owner:GetFilter() == 1 and not ent:IsPlayer() or owner:GetFilter() == 2 and ent:IsPlayer() then return end
            local ply = ent:IsPlayer() and ent
            if owner:GetOwnerOnly() and ( WireLib.GetOwner( ent ) or ply ) ~= WireLib.GetOwner( owner ) then return end
            if ent:GetDimension() ~= self:GetDimension() then return end
        
            self.EntsInside[ #self.EntsInside+1 ] = ent
        
            WireLib.TriggerOutput( owner, "EntCount", #self.EntsInside )
            WireLib.TriggerOutput( owner, "Entities", self.EntsInside )
        
        end
    end
    --[[ elseif ENT:GetClass() == "glide_missile" then
        local ray = {}
        local traceData = {
            output = ray,
            filter = { NULL, NULL },
            mask = MASK_PLAYERSOLID,
            maxs = Vector(),
            mins = Vector()
        }
        function ENT:Think()
            local t = CurTime()
        
            if t > self.lifeTime then
                self:Explode()
                return
            end
        
            self:NextThink( t )
        
            local phys = self:GetPhysicsObject()
        
            if not self.applyThrust or not IsValid( phys ) then
                return true
            end
        
            if self:WaterLevel() > 0 then
                self.applyThrust = false
                phys:EnableGravity( true )
                return true
            end
        
            local dt = FrameTime()
        
            self:SetEffectiveness( math.Approach( self:GetEffectiveness(), 1, dt * 4 ) )
        
            -- Point towards the target
            local target = self.target
            local myPos = self:GetPos()
            local fw = self:GetForward()
        
            -- Or towards a nearby flare
            local flare, flareDistSqr = Glide.GetClosestFlare( myPos, fw, 1500 )
        
            if IsValid( flare ) and flare:GetDimension() == self:GetDimension() then
                target = flare
        
                if flareDistSqr < self.flareExplodeRadius then
                    self:Explode()
                    return
                end
            end
        
            if IsValid( target ) and target:GetDimension() == self:GetDimension() then
                self:SetHasTarget( target.IsCountermeasure ~= true )
        
                local targetPos = target:WorldSpaceCenter()
                local dir = targetPos - myPos
                dir:Normalize()
        
                -- If the target is outside our FOV, stop tracking it
                if math.abs( dir:Dot( fw ) ) < self.missThreshold then
                    self.target = nil
                    self.aimDir = nil
                else
                    -- Let PhysicsSimulate handle this
                    self.aimDir = dir
                end
            else
                self:SetHasTarget( false )
            end
        
            traceData.start = myPos
            traceData.endpos = myPos + self:GetVelocity() * dt * 2
            traceData.filter = function(ent)
                if ent == self then return false end
                if ent == self:GetOwner() then return false end

                if ent:GetDimension() ~= self:GetDimension() then return false end

                return true
            end
        
            -- Trace result is stored on `ray`
            util.TraceHull( traceData )
        
            if not ray.HitSky and ray.Hit then
                self:Explode()
            end
        
            return true
        end        
    elseif ENT:GetClass() == "glide_projectile" then
        local ray = {}
        local traceData = {
            output = ray,
            filter = { NULL, NULL },
            mask = MASK_PLAYERSOLID,
            maxs = Vector(),
            mins = Vector()
        }
        function ENT:Think()
            local t = CurTime()
        
            if t > self.lifeTime then
                self:Explode()
                return false
            end
        
            if self.submerged then return false end
        
            if self:WaterLevel() > 2 then
                self.submerged = true
        
                local phys = self:GetPhysicsObject()
        
                if IsValid( phys ) then
                    phys:Wake()
                    phys:EnableGravity( true )
                    phys:SetVelocityInstantaneous( self.velocity * 0.5 )
                end
        
                return false
            end
        
            local dt = FrameTime()
            local vel = self.velocity
        
            vel = vel + ( dt * self.gravity )
        
            self.velocity = vel
        
            local lastPos = self:GetPos()
            local nextPos = lastPos + vel * dt
        
            -- Check if we've hit anything along the way
            traceData.start = lastPos
            traceData.endpos = nextPos
            traceData.filter = function(ent)
                if ent == self then return false end
                if ent == self:GetOwner() then return false end

                if ent:GetDimension() ~= self:GetDimension() then return false end

                return true
            end
        
            if Glide.GetDevMode() then
                debugoverlay.Line( traceData.start, traceData.endpos, 0.75, Color( 255, 0, 0 ), true )
            end
        
            -- Trace result is stored on `ray`
            util.TraceHull( traceData )
        
            if ray.HitSky then
                self:Remove()
                return
            end
        
            if ray.Hit then
                self:SetPos( ray.HitPos )
                self:Explode()
                return
            end
        
            self:SetPos( nextPos )
            self:SetAngles( self.velocity:Angle() )
            self:NextThink( t )
        
            return true
        end
    end ]]
end)

-- Patch Glide Turrets
--[[ local glideFireBulletBase = Glide.FireBullet
function Glide.FireBullet(params,traceFilter)
    local baseFilter = traceFilter.filter
    local modifiedFilter = function(ent)
        if IsValid(baseFilter) then
            print("Base filter is a ",type(baseFilter))
            if type(baseFilter) == "table" then
                print("Base filter is a table")
                return not table.HasValue(baseFilter,ent)
            end
            if type(baseFilter) == "Entity" then
                print("Base filter is an entity")
                return baseFilter ~= ent
            end
        end

        if IsValid(params.inflictor) then
            if ent ~= params.inflictor then
                return ent:GetDimension() == params.inflictor:GetDimension()
            end
        elseif IsValid(params.attacker) then
            if ent ~= params.attacker then
                return ent:GetDimension() == params.attacker:GetDimension()
            end
        end
    end
    glideFireBulletBase(params,modifiedFilter)
end ]]

--[[ local baseEyeTrace = FindMetaTable("Player").GetEyeTrace
FindMetaTable("Player").GetEyeTrace = function(self)
    local trace = util.TraceLine({
        start = self:EyePos(),
        endpos = self:EyePos()+self:GetAimVector()*32767,
        filter = function(ent)
            if ent == self then return false end
            if ent:GetDimension() ~= self:GetDimension() then return false end
            return true
        end
    })
    return trace
end ]]

local baseCreate = ents.Create
function ents.Create(class)
    return baseCreate(class)
end