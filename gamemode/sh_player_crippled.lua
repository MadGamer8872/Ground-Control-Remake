+AddCSLuaFile()
 +
 +GM.MinMorphine = 1
 +GM.MaxMorphine = 2 -- maximum Morphine a player can carry
 +GM.DefaultMorphine = 1 -- how many morphine we should start out with when we first join the server
 +GM.MorphineWeight = 0.2 -- how much each individual morphine weighs
 +GM.MorphineDistance = 50 -- distance between us and another player to bandage them
 +
 +if CLIENT then
 +	CreateClientConVar("gc_Morphine", GM.DefaultMorphine, true, true)
 +end
 +
 +local PLAYER = FindMetaTable("Player")
 +
 +local traceData = {}
 +
 +function PLAYER:getMorphineTarget()
 +	if self.crippled then -- first and foremost we must take care of our own broken bones
 +		return self
 +	end
 +	
 +	local target = nil
 +	
 +	traceData.start = self:GetShootPos()
 +	traceData.endpos = traceData.start + self:GetAimVector() * GAMEMODE.MorphineDistance
 +	traceData.filter = self
 +	
 +	local trace = util.TraceLine(traceData)
 +	local ent = trace.Entity
 +	
 +	
 +	if IsValid(ent) and ent:IsPlayer() then
 +		if self:canMorphine(ent) then
 +			target = ent
 +		end
 +	end
 +	
 +	return target
 +end
 +
 +function PLAYER:canMorphine(target)
 +	if not IsValid(target) or not self:Alive() then
 +		return false
 +	end
 +	
 +	local wep = self:GetActiveWeapon()
 +	
 +	if IsValid(wep) and CurTime() < wep.GlobalDelay then
 +		return false
 +	end
 +	
 +	if SERVER then
 +		if not target.Crippled then
 +			return false
 +		end
 +	end
 +	
 +	if CLIENT then
 +		if not target:hasStatusEffect("bleeding") then
 +			return false
 +		end
 +	end
 +	
 +	return self.bandages > 0 and target:Team() == self:Team()
 +end
 +
 +function PLAYER:setCripple(bleeding)
 +	self.bleeding = bleeding
 +	
 +	if SERVER then
 +		self:sendBleedState()
 +		
 +		if not bleeding and (self.regenPool and self.regenPool > 0) then
 +			self:sendStatusEffect("healing", true)
 +		end
 +	end
 +end
 +
 +function PLAYER:setBandages(bandages)
 +	bandages = bandages or GAMEMODE.DefaultBandages
 +	
 +	self.bandages = bandages
 +	
 +	if SERVER then
 +		self:sendBandages()
 +	end
 +end
 +
 +function PLAYER:resetBleedData()
 +	self:setBleeding(false)
 +	self.bleedInflictor = nil
 +	self.bleedHealthDrainTime = 0
 +	self.healAmount = 0
 +end
 +
 +function PLAYER:getDesiredBandageCount()
 +	if GAMEMODE.curGametype.getDesiredBandageCount then
 +		local count = GAMEMODE.curGametype:getDesiredBandageCount(self)
 +		
 +		if count then
 +			return count
 +		end
 +	end
 +	
 +	return math.Clamp(self:GetInfoNum("gc_bandages", GAMEMODE.DefaultBandages), GAMEMODE.MinBandages, GAMEMODE.MaxBandages)
 +end
 +
 +function GM:getBandageWeight(bandageCount)
 +	return bandageCount * self.BandageWeight
 +end