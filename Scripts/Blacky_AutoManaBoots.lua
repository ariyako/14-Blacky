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
	
	
	Version History:
	v0.3
	- Upgraded to the new Ensage version
	- 
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
require("libs.HotkeyConfig")


ScriptConfig = ConfigGUI:New(script.name)


ScriptConfig:SetName("Blacky's Auto Mana Boots")
ScriptConfig:AddParam("AutoManaBoots", "AutoManaBoots", SGC_TYPE_TOGGLE, false, true, nil)
ScriptConfig:AddParam("AutoManaBootsManaRequired", "Required Mana", SGC_TYPE_NUMCYCLE, false, 100, nil, 25, 400, 25)
ScriptConfig:AddParam("AutoManaBootsWaitForAllies", "Wait for Allies", SGC_TYPE_TOGGLE, false, true, nil)
ScriptConfig:AddParam("AutoManaBootsManaAllies", "Required Mana (Allies)", SGC_TYPE_NUMCYCLE, false, 50, nil, 50, 1000, 50)

iconx        = 10
icony        = 200

text         = drawManager:CreateText(iconx + 55, icony, 0xFFFFFFFF, "")
icon         = drawManager:CreateRectM(iconx, icony, 40, 25, "NyanUI/items/arcane_boots")

text.visible = false
icon.visible = false

inDistance   = 550
outDistance  = 1800




function NearbyPlayersNeedingMana()
	local numberOfPlayersSwag = 0
	local nearbyPlayers = entityList:FindEntities({type=TYPE_HERO, team=me.team, alive = true})
	for i,v in ipairs(nearbyPlayers) do
		if GetDistance2D(v,me) > inDistance and GetDistance2D(v,me) < outDistance and v.mana<v.maxMana-ScriptConfig.AutoManaBootsManaAllies then
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
	return me.mana < me.maxMana-ScriptConfig.AutoManaBootsManaRequired
end

function NearFountain()

	if me.x <= 6800 and me.y <= 6300 and me.team == TEAM_RADIANT then 
		return true
	elseif me.x >= 5600 and me.y >= 5000 and me.team == TEAM_DIRE then
		return true
	else 
		return false
	end

end

function Tick(tick)
	if PlayingGame() and me.alive and HasManaBoots() and NeedsMana() and (not me:IsChanneling()) and (not me.invisible) and (not NearFountain()) and SleepCheck("Blacky's Mana Boots") then
		
		if NearbyPlayersNeedingMana() == 0 or (not ScriptConfig.AutoManaBootsWaitForAllies) then
			me:SafeCastItem("item_arcane_boots")
			Sleep(500,"Blacky's Mana Boots")
		end

	end

end

function Frame()  --TODO: Add a range_display with the range of the mana boots replenish buff, when there are still allies who need to get in the radius
	if PlayingGame() and me.alive and HasManaBoots() and NeedsMana() and (NearbyPlayersNeedingMana() > 0 or (not ScriptConfig.AutoManaBootsWaitForAllies)) then

		icon.visible = true
		text.visible = true
		text:SetText(tostring(NearbyPlayersNeedingMana()))
	else

			icon.visible = false


			text.visible = false

	end
end


print("Blacky's Auto Mana Boots Loaded")

script:RegisterEvent(EVENT_TICK, Tick)
script:RegisterEvent(EVENT_FRAME, Frame)