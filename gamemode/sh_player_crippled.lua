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
 +	return self.morphine > 0 and target:Team() == self:Team()
 +end
 +
 +function PLAYER:setCripple(cripple)
 +	self.cripple = cripple
 +	
 +	if SERVER then
 +		self:sendCrippleState()
 +		
 +		if not cripple and (self.regenPool and self.regenPool > 0) then
 +			self:sendStatusEffect("healing", true)
 +		end
 +	end
 +end
 +
 +function PLAYER:setCripple(cripple)
 +	Morphine = morphine or GAMEMODE.MedicMorphine
 +	
 +	self.morphine = morphine
 +	
 +	if SERVER then
 +		self:sendMorphine()
 +	end
 +end
 +
 +function PLAYER:resetCrippleData()
 +	self:setCripple(false)
 +	self.crippleInflictor = nil
 + self.healamount = 0
 +end
 +
 +function PLAYER:getDesiredCount()
 +	if GAMEMODE.curGametype.getDesiredMorphineCount then
 +		local count = GAMEMODE.curGametype:getDesiredMorphineCount(self)
 +		
 +		if count then
 +			return count
 +		end
 +	end
 +	
 +	return math.Clamp(self:GetInfoNum("gc_morphine", GAMEMODE.DefaultMorphine), GAMEMODE.MinMorphine, GAMEMODE.MaxMorphine)
 +end
 +
 +function GM:getMorphineWeight(bandageCount)
 +	return morphineCount * self.MorphineWeight
 +end
