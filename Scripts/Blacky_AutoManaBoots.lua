--<< Automatically activates your Arcane Boots under configurable conditions. >>
--<< Blacky372 >>
--[[  
  ____  _            _          ____ ______ ___  
 |  _ \| |          | |        |___ \____  |__ \ 
 | |_) | | __ _  ___| | ___   _  __) |  / /   ) |
 |  _ <| |/ _` |/ __| |/ / | | ||__ <  / /   / / 
 | |_) | | (_| | (__|   <| |_| |___) |/ /   / /_ 
 |____/|_|\__,_|\___|_|\_\\__, |____//_/   |____|
                           __/ |                 
                          |___/                  
		Auto Mana Boots v0.4c
	
	Features:
	- Automatically activate Arcane Boots when its on cooldown and you need the mana
	- Wait for allies that need mana
	- Show AOE of mana boots when allies need to come closer
	
	Version History:
	v0.4c
	- Adjusted minor things to fit the Blacky Script Standard
	v0.4b
	- Minor bugfix
	v0.4a
	- The script will now not try to create an effect even out of game
	v0.4
	- Range display can now be deactivated when a teamfight is happening to avoid confusion
	- Optimized outer range to 2000
	- Status text will now show much more information
	v0.3
	- Upgraded to the new Ensage version
	- Migrated from HotkeyConfig to ScriptConfig
	- Optimized inner range
	- Added a range_display around the hero when there are allies that need to get in range
	v0.2b
	- Fixed a problem resulting in an error
	v0.2a
	- The number displaying the playes, who still need to get close to you, is now displayed in white instead of black	
	v0.2
	- The script now will not activate when you are near your fountain ( Would be a waste ) 
	- Now using SafeCastItem() instead of CastItem()
	v0.1c
	- Fixed trying to cast mana boots while being dead
	v0.1b
	- Fixed Problems with HotkeyConfig
	- Cleaned some code
	- Added channeling and invisibility protection
	v0.1a
	- Removed unused lib requires
	- Added numcycles for the required mana numbers
	- Simplified some code
	v0.1
	- Initial Release
					  
]]

__VERSION = "0.4c"

require("libs.Utils")
require("libs.ScriptConfig")  


ScriptConfig = ScriptConfig.new()

ScriptConfig:SetParameter("Enabled", true)
ScriptConfig:SetParameter("ManaRequired", 100) 
--The amount of mana your hero needs to be missing to activate

ScriptConfig:SetParameter("WaitForAllies",true) 
-- Will the script wait until all allies that need mana are in arcanes AOE?

ScriptConfig:SetParameter("ManaAllies", 50) 
-- The amount of mana the allies need to miss to be waited for.

ScriptConfig:SetParameter("RangeDisplayTeamfightDetection", true) 
-- If the script thinks there is a teamfight happening dont show the range_display to avoid confusion

ScriptConfig:SetParameter("DropItems", true) 
-- Drop int and mana items before activating arcanes to get more mana out of it 

ScriptConfig:SetParameter("DropItemsSafeMode", true) 
-- Dont drop items if there is an enemy nearby

ScriptConfig:SetParameter("DropItemsSafeModeSearchRange", 800) 
-- The radius the script will search for enemies in safe item drop mode

ScriptConfig:Load()

local F14 = drawMgr:CreateFont("F14","Arial",14,500)
local me = nil
if PlayingGame() then
	me = entityList:GetMyHero()

	local iconx        = 320
	local icony        = 5

	local inDistance   = 580 -- Range of Mana replenish is 600, but I added a 20 range buffer because of possible delay
	local inDistance_shown = inDistance-40 -- this is what the range_display effect on the player will be to avoid misleading and accidentally not getting some heroes in the Mana AOE
	local outDistance  = 2000 -- TODO: Scale range with how bad allies need mana (If they are really low on mana the script will wait even if they are further away)

	local text         = drawMgr:CreateText(iconx + 50, icony, 0xFFFFFFFF, "", F14)
	local icon         = drawMgr:CreateRect(iconx, icony, 40, 25, 0xCCCCCC, drawMgr:GetTextureId("NyanUI/items/arcane_boots"))
	text.visible = true
	icon.visible = true

	local effect_arcaneBootsRange = Effect(me, "range_display")
	effect_arcaneBootsRange:SetVector(1,Vector(inDistance_shown,0,0))
end

local function _log(message)
	print("Blacky's Auto Mana Boots v" .. __VERSION .. " -> " .. message)
end

function NearbyPlayersNeedingMana()
	local numberOfPlayersSwag = 0
	local nearbyPlayers = entityList:FindEntities({type=LuaEntityNPC.TYPE_HERO, team=me.team, alive = true})
	for i,v in ipairs(nearbyPlayers) do
		if GetDistance2D(v,me) > inDistance and GetDistance2D(v,me) < outDistance and v.mana<v.maxMana-ScriptConfig:GetParameter("ManaAllies") then
			numberOfPlayersSwag = numberOfPlayersSwag + 1
		end
	end
	return numberOfPlayersSwag
end

function GetManaBootsCooldown()
	for i = 1,6,1 do
		if me:HasItem(i) then
			if me:GetItem(i).name == "item_arcane_boots"  then
				return me:GetItem(i).cd
			end
		end
	end
	return -1

end

function NeedsMana()
	return me.mana < me.maxMana-ScriptConfig:GetParameter("ManaRequired")
end

function NearFountain()

	if me.position.x <= 6800 and me.position.y <= 6300 and me.team == TEAM_RADIANT then 
		return true
	elseif me.position.x >= 5600 and me.position.y >= 5000 and me.team == TEAM_DIRE then
		return true
	else 
		return false
	end

end

function TeamfightDetection()
	local nearbyPlayers = entityList:FindEntities({type=LuaEntityNPC.TYPE_HERO, alive = true})
	local enemiesInRange = 0
	local alliesInRange = 0
	for i,v in ipairs(nearbyPlayers) do
		if GetDistance2D(v,me) <= 1000 then
			if v.team == me.team and v ~= me then
				alliesInRange = alliesInRange + 1
			else
				enemiesInRange = alliesInRange + 1
			end
		end
	end
	if alliesInRange >= 2 and enemiesInRange >= 3 then
		return Vector(alliesInRange,enemiesInRange,0)
	else
		return false
	end
end

function Tick(tick)
	if PlayingGame() and me.alive and GetManaBootsCooldown() == 0 and NeedsMana() and (not me:IsChanneling()) and (not me.invisible) and (not NearFountain()) and SleepCheck("Blacky's Mana Boots") then
		
		if NearbyPlayersNeedingMana() == 0 or (not ScriptConfig:GetParameter("WaitForAllies")) then
			me:SafeCastItem("item_arcane_boots")
			Sleep(500,"Blacky's Mana Boots")
		end

	end

end

function Frame()
	if PlayingGame() then
		local ArcanesCooldown = GetManaBootsCooldown()
		if not me.alive then
			icon.visible = false
			text.visible = false
			if  effect_arcaneBootsRange then
				effect_arcaneBootsRange = false
				collectgarbage("collect")
			end
		elseif ArcanesCooldown == -1 then
			icon.visible = false
			text.visible = false
			if  effect_arcaneBootsRange then
				effect_arcaneBootsRange = false
				collectgarbage("collect")
			end
		elseif ArcanesCooldown > 0 then
			icon.visible = true
			text.visible = true
			text.text = "Arcane Boots on cooldown: "..tostring(math.floor(ArcanesCooldown))
			if  effect_arcaneBootsRange then
				effect_arcaneBootsRange = false
				collectgarbage("collect")
			end
		elseif not NeedsMana() then
			icon.visible = true
			text.visible = true
			text.text = "Enough Mana"
			if  effect_arcaneBootsRange then
				effect_arcaneBootsRange = false
				collectgarbage("collect")
			end
		elseif TeamfightDetection() and ScriptConfig:GetParameter("RangeDisplayTeamfightDetection") then
			icon.visible = true
			text.visible = true
			text.text = "Teamfight! Waiting for allies: "..(tostring(NearbyPlayersNeedingMana())) -- .." "..tostring(TeamfightDetection().x).." "..tostring(TeamfightDetection().y)
			if  effect_arcaneBootsRange then
				effect_arcaneBootsRange = false
				collectgarbage("collect")
			end
		elseif NearbyPlayersNeedingMana() > 0 and ScriptConfig:GetParameter("WaitForAllies") then
			icon.visible = true
			text.visible = true
			text.text = "Waiting for allies: "..(tostring(NearbyPlayersNeedingMana()))
			if not effect_arcaneBootsRange then
				effect_arcaneBootsRange = Effect(me, "range_display")
				effect_arcaneBootsRange:SetVector(1,Vector(inDistance_shown,0,0))
			end
		else  -- THIS SHOULD NEVER HAPPEN!
			icon.visible = true
			text.visible = true
			text.text = "Unexpected Error: ERR001"
			if  effect_arcaneBootsRange then
				effect_arcaneBootsRange = false
				collectgarbage("collect")
			end
				
		end
	end
end

function GameClose()
	effect_arcaneBootsRange:SetVector(0,Vector(inDistance_shown,0,0))
	icon.visible = false
	text.visible = false
	effect_arcaneBootsRang = false
	icon = false
	text = false
	collectgarbage("collect")
	script:Unload()
end

_log("Loaded!")

script:RegisterEvent(EVENT_TICK, Tick)
script:RegisterEvent(EVENT_FRAME, Frame)
script:RegisterEvent(EVENT_CLOSE, GameClose)
