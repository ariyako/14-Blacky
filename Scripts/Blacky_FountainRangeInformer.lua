--<< Displays the attack and true sight range for the fountains. >>
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
		Fountain Range Informer v0.1
	
	Features:
	- Shows the Attack and True Sight range of the enemy fountain
	
	Version History:
	v0.1
	- Initial Release
					  
]]

__VERSION = "0.1"

require("libs.Utils")
require("libs.ScriptConfig")  


ScriptConfig = ScriptConfig.new()

ScriptConfig:SetParameter("Enabled", true)

ScriptConfig:SetParameter("AttackRange", true)
-- Display the attack range

ScriptConfig:SetParameter("TrueSight", true)
-- Display the true sight range

ScriptConfig:SetParameter("OwnFountain", false)
-- Display for own fountain

ScriptConfig:SetParameter("EnemyFountain", true)
-- Display for enemy fountain
ScriptConfig:Load()

local me = nil
local effects = {}
effects.mine = {}
effects.enemy = {}
local fountains = {}
	

if PlayingGame() then -- Initialize Constants, Images and Effects
	me = entityList:GetMyHero()
	local eList = entityList:FindEntities({classId=CDOTA_Unit_Fountain})
	for i,v in ipairs(eList) do
		if v.team == me.team then
			fountains.mine = v
		else
			fountains.enemy = v
		end
	end

	if ScriptConfig:GetParameter("OwnFountain") then
		if ScriptConfig:GetParameter("AttackRange") then
			effects.mine.attackRange = Effect(fountains.mine, "range_display")
			effects.mine.attackRange:SetVector(1, Vector(1370, 0, 0))
		end
		if ScriptConfig:GetParameter("TrueSight") then
			effects.mine.trueSight = Effect(fountains.mine, "range_display")
			effects.mine.trueSight:SetVector(1, Vector(1220, 0, 0))
		end
	end

	if ScriptConfig:GetParameter("EnemyFountain") then
		if ScriptConfig:GetParameter("AttackRange") then
			effects.enemy.attackRange = Effect(fountains.enemy, "range_display")
			effects.enemy.attackRange:SetVector(1, Vector(1370, 0, 0))
		end
		if ScriptConfig:GetParameter("TrueSight") then
			effects.enemy.trueSight = Effect(fountains.enemy, "range_display")
			effects.enemy.trueSight:SetVector(1, Vector(1220, 0, 0))
		end
	end
end

local function _log(message)
	print("Blacky's Fountain Range Informer v" .. __VERSION .. " -> " .. message)
end


function GameClose() -- Unload and destroy all objects, images and effects
	effects = nil
	collectgarbage("collect")
	script:Unload()
end

_log("Loaded!")

script:RegisterEvent(EVENT_CLOSE, GameClose)