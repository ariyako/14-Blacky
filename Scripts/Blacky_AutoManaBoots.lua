--[[  
  ____  _            _          ____ ______ ___  
 |  _ \| |          | |        |___ \____  |__ \ 
 | |_) | | __ _  ___| | ___   _  __) |  / /   ) |
 |  _ <| |/ _` |/ __| |/ / | | ||__ <  / /   / / 
 | |_) | | (_| | (__|   <| |_| |___) |/ /   / /_ 
 |____/|_|\__,_|\___|_|\_\\__, |____//_/   |____|
                           __/ |                 
                          |___/                  
		Auto Mana Boots v0.3
	
	Features:
	- Automatically activate Arcane Boots when its on cooldown and you need the mana
	- Wait for allies that need mana

	Planned Features:
	- Adjust the outer distance based on how bad the allies need mana
	- Drop int and mana items before using Arcanes and pick them up after (if there are no enemies near)
	
	Version History:
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

require("libs.Utils")
require("libs.ScriptConfig")  


ScriptConfig = ScriptConfig.new()

local me = entityList:GetMyHero()


--ScriptConfig:SetName("Blacky's Auto Mana Boots")
ScriptConfig:SetParameter("Enabled", true)
ScriptConfig:SetParameter("ManaRequired", 100)
ScriptConfig:SetParameter("WaitForAllies",true)
ScriptConfig:SetParameter("ManaAllies", 50)
ScriptConfig:Load()

local F10 = drawMgr:CreateFont("F10","Arial",10,500) --TODO: Decide which font is best and remove others!
local F11 = drawMgr:CreateFont("F11","Arial",11,500)
local F12 = drawMgr:CreateFont("F12","Arial",12,500)
local F13 = drawMgr:CreateFont("F13","Arial",13,500)
local F14 = drawMgr:CreateFont("F14","Arial",14,500)

local iconx        = 320
local icony        = 5

local inDistance   = 580 -- Range of Mana replenish is 600, but I added a 20 range buffer because of possible delay
local inDistance_shown = inDistance-40 -- this is what the range_display effect on the player will be to avoid misleading and accidentally not getting some heroes in the Mana AOE
local outDistance  = 1800 -- Maybe reduce to 1200 range, maybe scale range with how bad they need mana (If they are really low on mana the script will wait even if they are further away)

local text         = drawMgr:CreateText(iconx + 55, icony, 0xFFFFFFFF, "", F14)
local icon         = drawMgr:CreateRect(iconx, icony, 40, 25, 0xCCCCCC, drawMgr:GetTextureId("NyanUI/items/arcane_boots"))
text.visible = true
icon.visible = true

local effect_arcaneBootsRange = Effect(me, "range_display")
effect_arcaneBootsRange:SetVector(1,Vector(inDistance_shown,0,0))



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

function HasManaBoots()
	for i = 1,6,1 do
		if me:HasItem(i) then
			if me:GetItem(i).name == "item_arcane_boots"  then
				if me:GetItem(i).cd == 0 then
					return i
				end
			end
		end
	end
	return false

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

function Tick(tick)
	if PlayingGame() and me.alive and HasManaBoots() and NeedsMana() and (not me:IsChanneling()) and (not me.invisible) and (not NearFountain()) and SleepCheck("Blacky's Mana Boots") then
		
		if NearbyPlayersNeedingMana() == 0 or (not ScriptConfig:GetParameter("WaitForAllies")) then
			me:SafeCastItem("item_arcane_boots")
			Sleep(500,"Blacky's Mana Boots")
		end

	end

end

function Frame()  --TODO: Add a range_display with the range of the mana boots replenish buff, when there are still allies who need to get in the radius
	if PlayingGame() and me.alive and HasManaBoots() and NeedsMana() and (NearbyPlayersNeedingMana() > 0 or (not ScriptConfig:GetParameter("WaitForAllies"))) then

		icon.visible = true
		text.visible = true
		text.text = (tostring(NearbyPlayersNeedingMana()))
		effect_arcaneBootsRange:SetVector(1,Vector(inDistance_shown,0,0))
	else

			icon.visible = false
			text.visible = false
			effect_arcaneBootsRange:SetVector(0,Vector(inDistance_shown,0,0))
			
	end
end


print("Blacky's Auto Mana Boots Loaded")

script:RegisterEvent(EVENT_TICK, Tick)
script:RegisterEvent(EVENT_FRAME, Frame)