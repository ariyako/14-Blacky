--<< Instantly Tethers you to the farthest or closest friendly unit from you. >>
--<< Blacky372 >>
--[[  
  ____  _            _          ____ ______ ___  
 |  _ \| |          | |        |___ \____  |__ \ 
 | |_) | | __ _  ___| | ___   _  __) |  / /   ) |
 |  _ <| |/ _` |/ __| |/ / | | ||__ <  / /   / / 
 | |_) | | (_| | (__|   <| |_| |___) |/ /   / /_ 
 |____/|_|\__,_|\___|_|\_\__, |____//_/   |____|
                           __/ |                 
                          |___/                  
		Instant Tether v0.1
	
	Features:
	- On the press of a hotkey instantly tethers you to the farthest (or closest) friendly unit from you
	
	Version History:
	v0.1
	- Initial Release
					  
]]

local __VERSION = "0.1"

require("libs.Utils")
require("libs.ScriptConfig")  


ScriptConfig = ScriptConfig.new()

ScriptConfig:SetParameter("Enabled", true)
ScriptConfig:SetParameter("Hotkey", "K", ScriptConfig.TYPE_HOTKEY) 
-- The Hotkey used to insta-tether

ScriptConfig:SetParameter("UseClosest", false) 
-- Uses the closest friendly unit instead of the farthest.

ScriptConfig:Load()


local F14 = drawMgr:CreateFont("F14","Arial",14,500)
local useKey = ScriptConfig:GetParameter("Hotkey")
local me = nil
if PlayingGame() then -- Initialize Constants, Images and Effects
	me = entityList:GetMyHero()
end

local function _log(message)
	print("Blacky's Instant Tether v" .. __VERSION .. " -> " .. message)
end


function Key(msg, code)
	if client.chat or client.console or client.loading or msg ~= KEY_DOWN or not SleepCheck("Blacky's Instant Tether") then return end

	if IsKeyDown(useKey) and me.name == "npc_dota_hero_wisp"  and me:CanCast() then --TODO: Maybe replace "IsKeyDown(useKey)" with "code == "useKey" | Needs testing

		if me:FindSpell("wisp_tether"):CanBeCasted() then

			local buddies = entityList:FindEntities({classId=CDOTA_BaseNPC_Creep_Lane, team=me.team, alive = true})

			local buddiesInRange = {}
			local buddiesInRangeCounter = 0
			for i,v in ipairs(buddies) do
				if me:GetDistance2D(v) < 1800   then
					buddiesInRange[buddiesInRangeCounter] = v
					buddiesInRangeCounter = buddiesInRangeCounter + 1
				end
			end

			local bestBuddy = buddiesInRange[1]

			if not ScriptConfig:GetParameter("UseClosest") then				
				for i,v in ipairs(buddiesInRange) do
					if me:GetDistance2D(v) > me:GetDistance2D(bestBuddy) then

						bestBuddy = v
					end
				end
			else
				for i,v in ipairs(buddiesInRange) do
					if GetDistance2D(v,me) < GetDistance2D(bestBuddy) then
						bestBuddy = v
					end
				end
			end
			

			me:SafeCastSpell("wisp_tether",bestBuddy)
			Sleep(1000, "Blacky's Instant Tether")

		end
	end
end




function GameClose() -- Unload and destroy all objects, images and effects

	collectgarbage("collect")
	script:Unload()
end

_log("Loaded!")

script:RegisterEvent(EVENT_KEY,Key)
script:RegisterEvent(EVENT_CLOSE, GameClose)
