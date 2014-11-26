local itemEntry = 70010          --物品id,需要那些可以点击使用的物品，比如炉石之类的
local qtos = 4                --每完成多少个任务获得一点分配点数
local resetItem = 70002       --重置加点所需要的物品材料
local resetItemAmount = 10       --重置所需要材料数量

local STAT_STRENGTH				= 1
local STAT_AGILITY				= 2
local STAT_STAMINA				= 3
local STAT_INTELLECT			= 4
local STAT_SPIRIT				= 5

local statName = {
	[STAT_STRENGTH]             = "力量",
	[STAT_AGILITY]              = "敏捷",
	[STAT_STAMINA]              = "耐力",
	[STAT_INTELLECT]            = "智力",
	[STAT_SPIRIT]               = "精神"	
}

local spells = {
	[STAT_STRENGTH] = {
		[1] = 99901,
		[250] = 99902
	},
	[STAT_AGILITY] = {
		[1] = 99903,
		[250] = 99904
	},
	[STAT_STAMINA] = {
		[1] = 99905,
		[250] = 99906
	},
	[STAT_INTELLECT] = {
		[1] = 99907,
		[250] = 99908
	},
	[STAT_SPIRIT] = {
		[1] = 99909,
		[250] = 999010
	}
}

CharDBExecute([[	
CREATE TABLE IF NOT EXISTS `character_quest_to_point` (	
  `guid` int(11) NOT NULL,
  `zongshu` int(11) NOT NULL DEFAULT '0',
  `liliang` int(11) NOT NULL DEFAULT '0',
  `minjie` int(11) NOT NULL DEFAULT '0',
  `naili` int(11) NOT NULL DEFAULT '0',
  `zhili` int(11) NOT NULL DEFAULT '0',
  `jingshen` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
]])

local playerStats = {}

local function LoadPlayerStats(player)
	local pGUID = player:GetGUIDLow()
    local query = CharDBQuery("SELECT guid,liliang,minjie,naili,zhili,jingshen FROM character_quest_to_point WHERE guid="..pGUID)
    if(query) then
        repeat
            playerStats[query:GetUInt32(0)] = {
                [STAT_STRENGTH] 			= query:GetUInt32(1),
                [STAT_AGILITY] 		        = query:GetUInt32(2),
                [STAT_STAMINA] 		        = query:GetUInt32(3),
                [STAT_INTELLECT] 		    = query:GetUInt32(4),
                [STAT_SPIRIT] 		        = query:GetUInt32(5)
            }
        until not query:NextRow()
    else --如果在数据库中无记录，则这位玩家的属性均为零
        playerStats[pGUID] = {
	            [STAT_STRENGTH] 			= 0,
	            [STAT_AGILITY] 		        = 0,
	            [STAT_STAMINA] 		        = 0,
	            [STAT_INTELLECT] 		    = 0,
	            [STAT_SPIRIT] 		        = 0
        }
    end
end

function Image(name, prefix, afterfix, width, height, x, y)
  if(width == nil) then width = 24 end
  if(height == nil) then height = 24 end
  if(x == nil) then x = 0 end
  if(y == nil) then y = 0 end
  if(prefix == nil) then prefix = "" end
  if(afterfix == nil) then afterfix = "" end
  local str = prefix.."|TInterface/"..name..":"..height..":"..width..":"..x..":"..y.."|t"..afterfix
  return str
end

local goldIcon 				= Image("MONEYFRAME/UI-GoldIcon"," ","",12,12)
local FFButton 				= Image("TIMEMANAGER/FFButton")
local ResetButton 			= Image("TIMEMANAGER/ResetButton")
local nextButton 			= Image("BUTTONS/UI-SpellbookIcon-NextPage-Up")
local prevButton 			= Image("BUTTONS/UI-SpellbookIcon-PrevPage-Up")
local ui_raidframe_arrow 	= Image("RAIDFRAME/UI-RAIDFRAME-ARROW")
local addButton 			= Image("GuildBankFrame/UI-GuildBankFrame-NewTab")

function Player:SetStat(type,value)
	if value < 0 then value = 0 end
	local pGUID = self:GetGUIDLow()
	playerStats[pGUID][type] = value

	local spellBonusID = spells[type][250]
	local spellID = spells[type][1]

	local spellBonusCount = math.floor(value / 250)
	local spellCount = value % 250

	if(spellBonusCount > 0) then
		if self:GetAura(spellBonusID) == nil then
			self:AddAura(spellBonusID,self)
		end
		self:GetAura(spellBonusID):SetStackAmount(spellBonusCount)
	else
		self:RemoveAura(spellBonusID)
	end

	if(spellCount > 0) then
		if self:GetAura(spellID) == nil then
			self:AddAura(spellID,self)
		end
		self:GetAura(spellID):SetStackAmount(spellCount)
	else
		self:RemoveAura(spellID)
	end
end

function Player:GetStat(type)
	local pGUID = self:GetGUIDLow()
	return playerStats[pGUID][type]
end

function Player:AddStat(type,value)
	if value == nil then value = 1 end
	self:SetStat(type,self:GetStat(type) + value)
end

function Player:ResetStat()
	for i=STAT_STRENGTH,STAT_SPIRIT do
		self:SetStat(i,0)
	end
end

function Player:GetQuestCount()
	self:SaveToDB()
	local pGUID = self:GetGUIDLow()
	local query = CharDBQuery("SELECT counter FROM character_achievement_progress WHERE criteria=3631 and guid="..pGUID.." LIMIT 1")
	if query then
		return query:GetUInt32(0)
	end 
	return 0
end

function Player:GetTotalPoints()
	return math.floor(self:GetQuestCount() / qtos)
end

function Player:GetRestPoints()
	local usedPoints = 0
	for i = STAT_STRENGTH,STAT_SPIRIT do
		usedPoints = usedPoints + self:GetStat(i)
	end
	return self:GetTotalPoints() - usedPoints
end

local function StatGossipHello(event, player, item)	
	player:GossipClearMenu()	
	player:GossipMenuAddItem(30,"每完成1个任务将获取"..(1 / qtos).."点潜力点数。\n当前共完成任务|cFFA50000"..player:GetQuestCount().."|r个。\n\n剩余潜能点数 (|cFFA50000"..player:GetRestPoints().."/"..player:GetTotalPoints().."|r)\n\n",0,0)
	for i = STAT_STRENGTH,STAT_SPIRIT do
		player:GossipMenuAddItem(30,FFButton..">>  "..statName[i].." + |cFF006699"..player:GetStat(i).."|r　　　<点击加点>",0,i)
	end
	player:GossipMenuAddItem(30,"\n　　　"..ResetButton.."重置加点分配"..ResetButton,0,999,false,"确定重置吗？\n\n需要消耗："..GetItemLink(resetItem).." x "..resetItemAmount)
	player:GossipSendMenu(100, item)--(npc_text, unit[, menu_id])
	return false
end

local function StatGossipSelect(event, player, item, sender, intid, code, menu_id)
	if intid == 0 then
		StatGossipHello(event, player, item)
		return
	end

	if intid == 999 then
		if (player:GetStat(1) + player:GetStat(2) + player:GetStat(3) + player:GetStat(4) + player:GetStat(5)) <= 0 then
			player:SendBroadcastMessage("你当前并未加点，无需重置。")
		elseif player:HasItem(resetItem,resetItemAmount) then	
			player:RemoveItem(resetItem,resetItemAmount)
			player:ResetStat()
			player:SendBroadcastMessage("重置完毕~~~~")
		else 			
			player:SendBroadcastMessage("重置失败，缺少"..GetItemLink(resetItem).." x "..resetItemAmount)
		end
		StatGossipHello(event, player, item)
		return
	end
	
	if (intid >= STAT_STRENGTH and intid <= STAT_SPIRIT) then
		if player:GetRestPoints() <= 0 then
			player:SendBroadcastMessage("剩余潜能点数不足，请继续完成任务吧~")
			StatGossipHello(event, player, item)
			return
		end
		player:AddStat(intid)
		StatGossipHello(event, player, item)
	end
end


local players = GetPlayersInWorld()
if(players) then --当reload eluna时，遍历所有在线玩家的属性数据，保存到内存中
    for _, player in ipairs(players) do
        LoadPlayerStats(player)
    end
end

local function SavePlayerStatsData()
    for pGUID, data in pairs(playerStats) do
        CharDBExecute("REPLACE INTO character_quest_to_point(guid,liliang,minjie,naili,zhili,jingshen) values ("..pGUID..","..data[STAT_STRENGTH]..","..data[STAT_AGILITY]..","..data[STAT_STAMINA]..","..data[STAT_INTELLECT]..","..data[STAT_SPIRIT]..")")
    end
    print(">> All player stats saved.")
end

local function SavePlayerStatsCommand(event, player, msg, _, lang) --玩家在聊天频道输入#savestats，就会保存他的属性加点数据，供gm测试用。
	if(msg == "#savestats") then 
		SavePlayerStatsData()
		return false
	end
end

local function Onlogin(event, player)
	LoadPlayerStats(player)
end

local function Onlogout(event, player)
	SavePlayerStatsData() --保存玩家数据
    local pGUID = player:GetGUIDLow()
    playerStats[pGUID] = nil --清理内存中的属性数据，释放内存
end

print (">> Quest Stats System Loaded.")

CreateLuaEvent(SavePlayerStatsData, 1000 * 60 * 5, 0) --每五分钟保存一次玩家数据至数据库
RegisterPlayerEvent(3, Onlogin)
RegisterPlayerEvent(4, Onlogout)
RegisterPlayerEvent(18,SavePlayerStatsCommand)
RegisterItemGossipEvent(itemEntry, 1, StatGossipHello)
RegisterItemGossipEvent(itemEntry, 2, StatGossipSelect)