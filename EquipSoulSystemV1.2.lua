print(">>  EquipSoul System Code By Ayase")

local EquipSoulTar = {}
local PlayerEquipSoul = {}
local EquipSoul = {}
local DBQuery = nil
local ItemClassSubClassName = {}

EquipSoul = {
		{["slot"]=1,		["DBName"]="EQUIP_HEAD",		["Name"]="|cFFCC0000 头部 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Head:40:40|t"},
		{["slot"]=3,		["DBName"]="EQUIP_SHOULDERS",	["Name"]="|cFFCC0000 肩膀 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Shoulder:40:40|t"},
		{["slot"]=5,		["DBName"]="EQUIP_CHEST",		["Name"]="|cFFCC0000 胸部 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Chest:40:40|t"},
		{["slot"]=6,		["DBName"]="EQUIP_WAIST",		["Name"]="|cFFCC0000 腰带 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Waist:40:40|t"},
		{["slot"]=7,		["DBName"]="EQUIP_LEGS",		["Name"]="|cFFCC0000 裤子 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Legs:40:40|t"},
		{["slot"]=8,		["DBName"]="EQUIP_FEET",		["Name"]="|cFFCC0000 鞋子 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Feet:40:40|t"},
		{["slot"]=9,		["DBName"]="EQUIP_WRISTS",		["Name"]="|cFFCC0000 护腕 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Wrists:40:40|t"},
		{["slot"]=10,		["DBName"]="EQUIP_HANDS",		["Name"]="|cFFCC0000 手套 |r",	["IconNil"] = "|TInterface/PaperDoll/UI-PaperDoll-Slot-Hands:40:40|t"},
		}

ItemClassSubClassName = {[1] = "布甲",[2] = "皮甲",[3] = "锁甲",[4] = "板甲",}

function EquipSoul_Player_Onlogin (event,player)
	EquipSoul_Player_Onlogin_Event(event, player)
end

function EquipSoul_Player_Onlogin_Event(event, player, item, target)
	local pGuid = player:GetGUIDLow()
	local DBNameTemp = "pGuid,"
	for k,v in pairs(EquipSoul) do
		DBNameTemp = DBNameTemp..EquipSoul[k]["DBName"]..","
	end
	DBQuery = CharDBQuery("SELECT "..string.sub(DBNameTemp,1,#DBNameTemp-1).." FROM character_equipsoulsystem WHERE pGuid="..pGuid)
	PlayerEquipSoul[pGuid] = {}
	if (DBQuery) then
		for k,v in pairs(EquipSoul) do
			PlayerEquipSoul[pGuid][k] = {["Equip"] = DBQuery:GetInt32(k)}
			player:SetState(1000,PlayerEquipSoul[pGuid][k]["Equip"],0)
		end
	else
		for k,v in pairs(EquipSoul) do
			PlayerEquipSoul[pGuid][k] = {["Equip"] = 0}
		end
		CharDBExecute("INSERT INTO `character_equipsoulsystem` (`pGuid`) VALUES ("..pGuid..")")
	end
	--pEquipSoulTar(event, player, item, target)
end

function pEquipSoulTar(event, player, item, target)
	local pGuid = player:GetGUIDLow()
	EquipSoulTar[pGuid] = {
			["Name"]			= target:GetName(),
			["Entry"] 			= target:GetEntry(),
			["SubClass"] 		= target:GetSubClass(),
			["InventoryType"] 	= target:GetInventoryType(),
			["Display"]			= target:GetDisplayId(),
			["ItemLevel"]		= target:GetItemLevel(),
			["RequiredLevel"]	= target:GetRequiredLevel()
	}
	--print (EquipSoulTar[pGuid]["Entry"])
	return EquipSoulSelectGossip(event, player, item, target,intid)
end

function EquipSoulSelectGossip(event, player, item, target,intid)
	if (PlayerEquipSoul[pGuid] == nil) then 
		local pGuid = player:GetGUIDLow()
		local DBNameTemp = "pGuid,"
		for k,v in pairs(EquipSoul) do
			DBNameTemp = DBNameTemp..EquipSoul[k]["DBName"]..","
		end
		DBQuery = CharDBQuery("SELECT "..string.sub(DBNameTemp,1,#DBNameTemp-1).." FROM character_equipsoulsystem WHERE pGuid="..pGuid)
		PlayerEquipSoul[pGuid] = {}
		for k,v in pairs(EquipSoul) do
			PlayerEquipSoul[pGuid][k] = {["Equip"] = DBQuery:GetInt32(k)}
		end
	end
	local pGuid = player:GetGUIDLow()
	player:GossipClearMenu()
	player:GossipMenuAddItem(4,"你所选择的装备：\n|TInterface/ICONS/"..ItemDisplay[EquipSoulTar[pGuid]["Display"]]..":40:40|t"..GetItemLink(EquipSoulTar[pGuid]["Entry"]),1,999)	
	local TextTemp = ""
	local CanEquipClass = false
	for k=1,4 do
		if pClass[player:GetClass()]["CanEquip"][k] == EquipSoulTar[pGuid]["SubClass"] then
			CanEquipClass = true
		end
		if pClass[player:GetClass()]["CanEquip"][k] then
			TextTemp = TextTemp.."[|cFFFF9900"..ItemClassSubClassName[pClass[player:GetClass()]["CanEquip"][k]].."|r]"
		end
	end
	local EquipSoulCan = false
	for k,v in pairs(EquipSoul) do
		if EquipSoulTar[pGuid]["InventoryType"]==20 then EquipSoulTar[pGuid]["InventoryType"]=5 end --匹配袍子跟胸甲
		if (EquipSoul[k]["slot"]==EquipSoulTar[pGuid]["InventoryType"]) then
			EquipSoulCan = true
		end
	end
	if EquipSoulCan then
		if CanEquipClass then 
			for k,v in pairs(EquipSoul) do
				if (EquipSoul[k]["slot"]==EquipSoulTar[pGuid]["InventoryType"]) then
					if (PlayerEquipSoul[pGuid][k]["Equip"] == 0) then
						player:GossipMenuAddItem(4,"灵甲部件("..EquipSoul[k]["Name"]..")：\n"..EquipSoul[k]["IconNil"].." 无物品 ",1,k)
					else
						player:GossipMenuAddItem(4,"灵甲部件("..EquipSoul[k]["Name"]..")： \n|TInterface/ICONS/"..ItemDisplay[pItemDisplay[PlayerEquipSoul[pGuid][k]["Equip"]]]..":40:40|t"..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"]),1,k,false,"点击确认将卸下灵甲"..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"]).."至背包中。")
						player:SendBroadcastMessage("查看当前灵甲部件("..EquipSoul[k]["Name"]..")的具体属性："..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"])) 
					end
					player:GossipMenuAddItem(4,"附加部件",1,998,false,"确认把"..GetItemLink(EquipSoulTar[pGuid]["Entry"]).."附加到你的灵甲部件("..EquipSoul[k]["Name"]..")当中吗？\n需要消耗"..GetItemLink(EquipSoulItemcl).." x "..math.modf(EquipSoulTar[pGuid]["ItemLevel"]*EquipSoulItembeilv))
					player:GossipSendMenu(2,player,50007)	
				end
			end
		else
			player:SendBroadcastMessage("|cFF00FFFF  >>> 你的职业 |r["..pClass[player:GetClass()]["Name"].."]|cFF00FFFF只能允许附加灵甲的类型为|r"..TextTemp.."|cFF00FFFF。|r")
			player:GossipComplete()	
		end
	else
		player:SendBroadcastMessage("|cFF00FFFF  >>> ["..EquipSoulTar[pGuid]["Name"].."]不在灵甲系统的适用范围内。|r") 
		player:GossipComplete()	
	end
end

function EquipSoulSelectSave(event, player, item, target,intid)
	local pGuid = player:GetGUIDLow()
	for k,v in pairs(EquipSoul) do
		if (EquipSoul[k]["slot"]==EquipSoulTar[pGuid]["InventoryType"]) then
			if (player:GetLevel() >= EquipSoulTar[pGuid]["RequiredLevel"] - EquipSoulPlayerLevel) then 
				if player:HasItem(EquipSoulItemcl,math.modf(EquipSoulTar[pGuid]["ItemLevel"]*EquipSoulItembeilv)) and player:HasItem(EquipSoulTar[pGuid]["Entry"],1) then
					if (PlayerEquipSoul[pGuid][k]["Equip"] > 0) then
						player:SetState(1000,PlayerEquipSoul[pGuid][k]["Equip"],1)
						player:AddItem(PlayerEquipSoul[pGuid][k]["Equip"], 1)
					end
					player:SetState(1000,EquipSoulTar[pGuid]["Entry"],0)
					PlayerEquipSoul[pGuid][k]["Equip"] = EquipSoulTar[pGuid]["Entry"]
					player:RemoveItem(EquipSoulTar[pGuid]["Entry"],1)
					player:RemoveItem(EquipSoulItemcl,math.modf(EquipSoulTar[pGuid]["ItemLevel"]*EquipSoulItembeilv))
					CharDBExecute("update character_EquipSoulSystem set "..EquipSoul[k]["DBName"].."="..EquipSoulTar[pGuid]["Entry"].." where pGuid="..pGuid)
					player:SaveToDB()
				else
					player:SendBroadcastMessage("|cFF00FFFF  >>> 材料不足，需要：物品等级("..EquipSoulTar[pGuid]["ItemLevel"]..") x "..EquipSoulItembeilv.." = "..math.modf(EquipSoulTar[pGuid]["ItemLevel"] * EquipSoulItembeilv)..GetItemLink(EquipSoulItemcl)) 
				end
			else
				player:SendBroadcastMessage("|cFF00FFFF  >>> 等级不足，需要等级达到"..EquipSoulTar[pGuid]["RequiredLevel"] - EquipSoulPlayerLevel .."级才可以附加至灵甲。") 
			end
		end
	end
	player:GossipComplete()	
end

function EquipSoulSelectGossipEvent(event, player, item, target,intid)
	local pGuid = player:GetGUIDLow()
	if intid == 999 then
		player:GossipComplete()	
	elseif intid == 998 then
		EquipSoulSelectSave(event, player, item, target,intid)
	else
		for k,v in pairs(EquipSoul) do
			if intid == k then
				if PlayerEquipSoul[pGuid][k]["Equip"] >0 then
					player:SetState(1000,PlayerEquipSoul[pGuid][k]["Equip"],1)
					player:AddItem(PlayerEquipSoul[pGuid][k]["Equip"], 1)
					PlayerEquipSoul[pGuid][k]["Equip"] = 0
					CharDBExecute("update character_EquipSoulSystem set "..EquipSoul[k]["DBName"].."=0 where pGuid="..pGuid)
					player:SaveToDB()
				end
				return EquipSoulSelectGossip(event, player, item, target,intid)
			end
		end
	end
end
	
function EquipSoul_Player_GuanLi_Event(event, player, msg, Type, lang, item)
	if(msg=="#ES") then
		if (PlayerEquipSoul[pGuid] == nil) then 
			local pGuid = player:GetGUIDLow()
			local DBNameTemp = "pGuid,"
			for k,v in pairs(EquipSoul) do
				DBNameTemp = DBNameTemp..EquipSoul[k]["DBName"]..","
			end
			DBQuery = CharDBQuery("SELECT "..string.sub(DBNameTemp,1,#DBNameTemp-1).." FROM character_equipsoulsystem WHERE pGuid="..pGuid)
			PlayerEquipSoul[pGuid] = {}
			for k,v in pairs(EquipSoul) do
				PlayerEquipSoul[pGuid][k] = {["Equip"] = DBQuery:GetInt32(k)}
			end
		end
		return EquipSoul_Player_GuanLi(event, player, msg, Type, lang, item)
	elseif (string.find(msg,"#ESP ")) then
		if(player:GetGMRank()>=3)then
			--player:SendBroadcastMessage("GM灵甲管理。") 
			EquipSoul_GM_GuanLi_pGuid = string.gsub(msg, "#ESP ", "")
			return EquipSoul_GM_GuanLi(event, player, msg, Type, lang, item)
		else
			player:SendBroadcastMessage("仅在GM模式下可用。") 
		end
	end
end

function EquipSoul_GM_GuanLi(event, player, msg, Type, lang, item)
	local pGuid = EquipSoul_GM_GuanLi_pGuid
	local DBNameTemp = "pGuid,"
	for k,v in pairs(EquipSoul) do
		DBNameTemp = DBNameTemp..EquipSoul[k]["DBName"]..","
	end
	DBQuery = CharDBQuery("SELECT "..string.sub(DBNameTemp,1,#DBNameTemp-1).." FROM character_equipsoulsystem WHERE pGuid="..pGuid)
	local pDBName = CharDBQuery("SELECT name FROM characters WHERE guid="..pGuid)
	PlayerEquipSoul[pGuid] = {}
	if DBQuery then 
		for k,v in pairs(EquipSoul) do
			PlayerEquipSoul[pGuid][k] = {["Equip"] = DBQuery:GetInt32(k)}
		end
		player:GossipClearMenu()
		player:SendBroadcastMessage("GM灵甲管理模式\n当前为玩家(|cFF0066FF"..pDBName:GetString(0).."|R)所装备的灵甲：") 
		player:GossipMenuAddItem(4,"玩家(|cFF0066FF"..pDBName:GetString(0).."|r)所装备的灵甲",1,999)
		for k,v in pairs(EquipSoul) do
			if (PlayerEquipSoul[pGuid][k]["Equip"] == 0) then
				player:GossipMenuAddItem(4,"灵甲部件("..EquipSoul[k]["Name"]..")：\n"..EquipSoul[k]["IconNil"].." 无物品 ",1,999)
			else
				player:GossipMenuAddItem(4,"灵甲部件("..EquipSoul[k]["Name"]..")： \n|TInterface/ICONS/"..ItemDisplay[pItemDisplay[PlayerEquipSoul[pGuid][k]["Equip"]]]..":40:40|t"..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"]),1,k,false,"点击确认将卸下灵甲"..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"]).."至背包中。")
				player:SendBroadcastMessage("灵甲部件("..EquipSoul[k]["Name"]..")："..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"])) 
			end
		end
		player:GossipSendMenu(3,player,50011)	--GM管理灵甲
	else
		player:SendBroadcastMessage("无数据。") 
	end
end
	
function EquipSoul_Player_GuanLi(event, player, msg, Type, lang, item)
	local pGuid = player:GetGUIDLow()
	player:GossipClearMenu()
	player:SendBroadcastMessage("灵甲管理菜单：") 
	for k,v in pairs(EquipSoul) do
		if (PlayerEquipSoul[pGuid][k]["Equip"] == 0) then
			player:GossipMenuAddItem(4,"灵甲部件("..EquipSoul[k]["Name"]..")：\n"..EquipSoul[k]["IconNil"].." 无物品 ",1,999)
		else
			player:GossipMenuAddItem(4,"灵甲部件("..EquipSoul[k]["Name"]..")： \n|TInterface/ICONS/"..ItemDisplay[pItemDisplay[PlayerEquipSoul[pGuid][k]["Equip"]]]..":40:40|t"..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"]),1,k,false,"点击确认将卸下灵甲"..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"]).."至背包中。")
			player:SendBroadcastMessage("灵甲部件("..EquipSoul[k]["Name"]..")："..GetItemLink(PlayerEquipSoul[pGuid][k]["Equip"])) 
		end
	end
	player:GossipSendMenu(3,player,50008)	
end

function EquipSoul_GM_GuanLi_Select(event, player, item, target,intid)
	local pGuid = EquipSoul_GM_GuanLi_pGuid
	for k,v in pairs(EquipSoul) do
		if intid == k then
			if PlayerEquipSoul[pGuid][k]["Equip"] >0 then
				player:AddItem(PlayerEquipSoul[pGuid][k]["Equip"], 1)
				PlayerEquipSoul[pGuid][k]["Equip"] = 0
				CharDBExecute("update character_EquipSoulSystem set "..EquipSoul[k]["DBName"].."=0 where pGuid="..pGuid)
			end
			return EquipSoul_GM_GuanLi(event, player, item, target,intid)
		else
			player:GossipComplete()	
		end
	end
end
	
function EquipSoul_Player_GuanLi_Select(event, player, item, target,intid)
	local pGuid = player:GetGUIDLow()
	for k,v in pairs(EquipSoul) do
		if intid == k then
			if PlayerEquipSoul[pGuid][k]["Equip"] >0 then
				player:SetState(1000,PlayerEquipSoul[pGuid][k]["Equip"],1)
				player:AddItem(PlayerEquipSoul[pGuid][k]["Equip"], 1)
				PlayerEquipSoul[pGuid][k]["Equip"] = 0
				CharDBExecute("update character_EquipSoulSystem set "..EquipSoul[k]["DBName"].."=0 where pGuid="..pGuid)
				player:SaveToDB()
			end
			return EquipSoul_Player_GuanLi(event, player, item, target,intid)
		else
			player:GossipComplete()	
		end
	end
end

CharDBExecute([[
CREATE TABLE IF NOT EXISTS `character_EquipSoulSystem` (
`pGuid`  int(10) NOT NULL ,
`EQUIP_HEAD`  int(10) NOT NULL DEFAULT 0 COMMENT '头部' ,
`EQUIP_SHOULDERS`  int(10) NOT NULL DEFAULT 0 COMMENT '肩膀' ,
`EQUIP_CHEST`   int(10) NOT NULL DEFAULT 0 COMMENT '胸部' ,
`EQUIP_WAIST`   int(10) NOT NULL DEFAULT 0 COMMENT '腰带' ,
`EQUIP_LEGS`   int(10) NOT NULL DEFAULT 0 COMMENT '裤子' ,
`EQUIP_FEET`   int(10) NOT NULL DEFAULT 0 COMMENT '鞋子' ,
`EQUIP_WRISTS`   int(10) NOT NULL DEFAULT 0 COMMENT '护腕' ,
`EQUIP_HANDS`   int(10) NOT NULL DEFAULT 0 COMMENT '手套' ,
`EQUIP_BACK`   int(10) NOT NULL DEFAULT 0 COMMENT '背部' ,
  PRIMARY KEY (`pGuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
	]])

RegisterPlayerEvent(3,EquipSoul_Player_Onlogin)
RegisterItemEvent(EquipSoulItemEntry, 2, pEquipSoulTar)
--RegisterItemEvent(EquipSoulItemEntry, 2, EquipSoul_Player_Onlogin_Event)  
RegisterPlayerGossipEvent(50007,2,EquipSoulSelectGossipEvent)
RegisterPlayerEvent(18, EquipSoul_Player_GuanLi_Event) 
RegisterPlayerGossipEvent(50008,2,EquipSoul_Player_GuanLi_Select)
RegisterPlayerGossipEvent(50011,2,EquipSoul_GM_GuanLi_Select)