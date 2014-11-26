
print(">>  loadind  Wolrd Chating.lua")

local SAY=" "--普通聊天
local WSAY="sj"

local ItemEntry=70008 --用于使用后查看积分并兑换的物品entry。 ps 其实可以整合到什么超级炉石那里的，所选用的物品必须带技能的能使用的。
local jf_entry=70002 --代表积分的物品可以叫某某货币之类的,本来想直接加在数据库值然后读取的 不过兑换东西的时候太麻烦，所以还是做成了物品容易用于兑换。
local jf_mins=10 --设置每多少分钟得到1点积分。
local QuestCount=nil
local questPCH=2.5

local KillCount=nil
local killPCH=0.008

local mins=nil
local jf=nil	
local jf_count=nil
local inGameTime=nil
local playergid=nil
local jf_Data=nil
local jf_ingametime=nil

local TEAM_ALLIANCE	= 0	--联盟阵营
local TEAM_HORDE	= 1	--部落阵营


local CLASS={--职业号
	WARRIOR 		= 1,		--战士
	PALADIN			= 2,		--圣骑士
	HUNTER			= 3,		--猎人
	ROGUE			= 4,		--盗贼
	PRIEST			= 5,		--牧师
	DEATH_KNIGHT	= 6,		--死亡骑士
	SHAMAN			= 7,		--萨满
	MAGE			= 8,		--法师
	WARLOCK			= 9,		--术士
	DRUID			= 11,		--德鲁伊
}	

local ClassName={--职业表
	[CLASS.WARRIOR]		="|cffC79C6E",				--战士
	[CLASS.PALADIN]		="|cffF58CBA",				--圣骑士
	[CLASS.HUNTER]		="|cffABD473",				--猎人
	[CLASS.ROGUE]		="|cffFFF569",				--盗贼
	[CLASS.PRIEST]		="|cffFFFFFF",				--牧师
	[CLASS.DEATH_KNIGHT]="|cffC41F3B",				--死亡骑士
	[CLASS.SHAMAN]		="|cff2459FF",				--萨满
	[CLASS.MAGE]		="|cff69CCF0",				--法师
	[CLASS.WARLOCK]		="|cff9482C9",				--术士
	[CLASS.DRUID]		="|cffFF7D0A",				--德鲁伊
}
	

local ts=os.date("*t",time)
local t=string.format("%2d:%2d:%2d",ts.hour,ts.min,ts.sec)
	
	
local function GetPlayerInfo(player)--得到玩家信息
	local Pclass	= ClassName[player:GetClass()] or "???" --得到职业
	local Pname		= player:GetName()
	local Pteam		= ""
	local team=player:GetTeam()
	if(team==TEAM_ALLIANCE)then
		Pteam="|cFF0070d0联盟|r"
	elseif(team==TEAM_HORDE)then 
		Pteam="|cFFF000A0部落|r"
	end
	return string.format("%s[%s|Hplayer:%s|h%s|h|r]",Pteam,Pclass,Pname,Pname)
end


local function online_jf(event, player, item, target,intid)	
	player:GossipClearMenu()	
	playergid=player:GetGUIDLow()
	jf_Data=CharDBQuery("SELECT jf_time,jf,QuestToJF,KillToJF FROM characters_jf WHERE guid="..playergid..";")
	QuestCount=CharDBQuery("SELECT counter FROM character_achievement_progress WHERE criteria=3631 and guid="..playergid.." LIMIT 1")
	KillCount=CharDBQuery("SELECT counter FROM character_achievement_progress WHERE criteria=5529 and guid="..playergid.." LIMIT 1")
	local caidan_kaiguan = nil
	if (jf_Data) then	
		if (player:GetLevel() >= 78) then
			inGameTime=player:GetTotalPlayedTime()
			jf_ingametime=math.modf(inGameTime-jf_Data:GetInt32(0))
			jf=math.modf(jf_ingametime/60/jf_mins)
			mins=math.modf(jf_ingametime/60)	
			if (jf>0) then
				player:GossipMenuAddItem(0,"在线时间累计可以兑换"..GetItemLink(jf_entry).." x "..jf.." ",1,0)
				caidan_kaiguan = true
			end
		end
		if (QuestCount) then
			local QusetToJFCount = math.modf(QuestCount:GetInt32(0)*questPCH-jf_Data:GetInt32(2))
			if QusetToJFCount > 0 then
				player:GossipMenuAddItem(0,"累计任务数可兑换："..GetItemLink(jf_entry).." x "..QusetToJFCount.."。",1,1)
				caidan_kaiguan = true
			end
		end
		if (KillCount) then
			local KillToJFCount =math.modf(KillCount:GetInt32(0)*killPCH-jf_Data:GetInt32(3))
			if KillToJFCount > 0 then
				player:GossipMenuAddItem(0,"累计击杀生物数可兑换："..GetItemLink(jf_entry).." x "..KillToJFCount.."。",1,2)
				caidan_kaiguan = true
			end
		end
		if (caidan_kaiguan == true) then
			player:GossipSendMenu(1, player,50001)	
		else
			player:SendBroadcastMessage("未达到兑换条件。")
		end
	else
		CharDBExecute("insert into characters_jf (guid,jf_time,jf) VALUES ("..playergid..",0,0);")	
		online_jf(event, player, item, target,intid)
		--player:SendBroadcastMessage("首次使用，初始化数据。")
	end
end
	
	
local function timetojf(event, player, item, target,intid)
	if(intid==0) then
		jf=math.modf(jf_ingametime/60/jf_mins)
		if (jf > 0) then
			player:AddItem(jf_entry, jf)
			playergid=player:GetGUIDLow()
			CharDBExecute("update characters_jf set level="..player:GetLevel()..",nplayer='"..player:GetName().."',jf_time=jf_time+"..jf_ingametime..",jf=jf+"..jf.." where guid="..playergid..";")
			player:SendBroadcastMessage("成功兑换"..GetItemLink(jf_entry).." x " ..jf)
			player:GossipComplete()
			player:GossipClearMenu()
		else
			player:SendBroadcastMessage("兑换失败，累计在线时间少于"..jf_mins.."分钟。")
			player:GossipComplete()
			player:GossipClearMenu()
		end
	elseif(intid==1) then
		local QusetToJFCount = math.modf(QuestCount:GetInt32(0)*questPCH-jf_Data:GetInt32(2))
		if QusetToJFCount > 0 then
			player:AddItem(jf_entry, QusetToJFCount)
			CharDBExecute("update characters_jf set QuestToJF=QuestToJF+"..QusetToJFCount.." where guid="..playergid..";")
			player:SendBroadcastMessage("成功兑换"..GetItemLink(jf_entry).." x " ..QusetToJFCount)
			player:GossipComplete()
			player:GossipClearMenu()
		else
			player:SendBroadcastMessage("兑换失败。")
			player:GossipComplete()
			player:GossipClearMenu()
		end	
	elseif(intid==2) then
		local KillToJFCount = math.modf(KillCount:GetInt32(0)*killPCH-jf_Data:GetInt32(3))
		if KillToJFCount > 0 then
			player:AddItem(jf_entry, KillToJFCount)
			CharDBExecute("update characters_jf set KillToJF=KillToJF+"..KillToJFCount.." where guid="..playergid..";")
			player:SendBroadcastMessage("成功兑换"..GetItemLink(jf_entry).." x " ..KillToJFCount)
			player:GossipComplete()
			player:GossipClearMenu()
		else
			player:SendBroadcastMessage("兑换失败.")
			player:GossipComplete()
			player:GossipClearMenu()
		end	
	end
end



local function PlayerOnChat(event, player, msg, Type, lang)--世界聊天

	local head=string.format("[世]|cFFF08000%s|r说:",GetPlayerInfo(player))
	if(msg=="#buff")then
	    player:AddAura(48074, player)
        player:AddAura(48170, player)
        player:AddAura(43223, player)
        player:AddAura(36880, player)
        player:AddAura(467, player)
        player:AddAura(48469, player)
        player:AddAura(48162, player)
		player:AddAura(58054, player)
		SendWorldMessage("|cffFF0000玩家【"..player:GetName().."】脑门不幸被门挤了，觉得自己很强大。|r")
		return false
	elseif(msg=="泡点") then
		 online_jf(event, player, item, target,intid)	
		 return false
	elseif(string.find(msg,WSAY)) then 
		local sSAY = string.gsub(msg, WSAY, "")
		SendWorldMessage(string.format("%s|cFFFFFFFF%s|r",head,sSAY))
		return false

	end	
end

	CharDBExecute([[	
CREATE TABLE IF NOT EXISTS `characters_jf` (
  `guid` int(10) NOT NULL,
  `nplayer` text NOT NULL,
  `level` tinyint(3) NOT NULL DEFAULT '0',
  `jf_time` int(10) NOT NULL DEFAULT '0',
  `jf` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])


	RegisterPlayerEvent(18, PlayerOnChat) --世界聊天
	RegisterPlayerGossipEvent(50001,2,timetojf)
	
	
	