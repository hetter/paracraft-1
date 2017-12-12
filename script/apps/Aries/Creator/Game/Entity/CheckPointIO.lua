--[[
Title: Checkpoint block Entity
Author(s): Dummy
Date: 2017/12/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/apps/Aries/Creator/Game/Entity/CheckPointIO.lua");
local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO")
-------------------------------------------------------
]]

local WorldCommon = commonlib.gettable("MyCompany.Aries.Creator.WorldCommon");
			
local CheckPointIO = commonlib.gettable("MyCompany.Aries.Game.EntityManager.CheckPointIO");

CheckPointIO.world_points = {};
CheckPointIO.user_points = {};
CheckPointIO.check_points = {};

local function writeXml(xmlTable, xmlFile)
	ParaIO.CreateDirectory(xmlFile);
	local xml_data = commonlib.Lua2XmlString(xmlTable, true, true);
	if (xml_data) then
		local file = ParaIO.open(xmlFile, "w");
		if(file:IsValid()) then
			file:WriteString(xml_data);
			file:close();
		end
	end	
end

local function writeXmlElement(xmlTable, name, element)
	local isFind = false;
	for k, v in pairs(xmlTable) do
		if v.name == name then
			v.attr = element;
			isFind = true;
			break;
		end
	end
	
	if not isFind then
		local newInx = #xmlTable + 1;
		xmlTable[newInx] = {};
		xmlTable[newInx].name = name;
		xmlTable[newInx].attr = element;
	end
end

function CheckPointIO.getUserFileName(worldName)
	local keepWorkUserName;
	local loginMain = commonlib.gettable("Mod.WorldShare.login.loginMain");
	if loginMain then
		keepWorkUserName = loginMain.username;
	end	
	if not keepWorkUserName or keepWorkUserName == "" then
		keepWorkUserName = "tempUser";
	end

	local world_name = worldName or WorldCommon.GetWorldTag("name");
	local filename = "temp/saves/" .. keepWorkUserName .. "/" .. world_name .. "/checkpoint.xml";

	return filename;
end

function CheckPointIO.getWorldFileName(worldName)
	local filename;
	if worldName then
		filename = string.format("worlds/DesignHouse/%S/checkpoint.xml", worldName);
	else
		filename = GameLogic.current_worlddir .. "mod/checkpoint.xml";
	end
	return filename;
end

function CheckPointIO.readAll(worldName)
	local worldFile = CheckPointIO.getWorldFileName(worldName);
	local world_points = ParaXML.LuaXML_ParseFile(worldFile);
	CheckPointIO.world_points = world_points or {};
	
	local userFile = CheckPointIO.getUserFileName(worldName);
	local user_points = ParaXML.LuaXML_ParseFile(userFile);
	CheckPointIO.user_points = user_points or {};	

	for _, v in pairs(CheckPointIO.world_points) do
		CheckPointIO.check_points[v.name] = commonlib.deepcopy(v);
	end
	
	for _, v in pairs(CheckPointIO.user_points) do
		local existWorldAttr;
		if not CheckPointIO.check_points[v.name] then
			CheckPointIO.check_points[v.name] = {};
			CheckPointIO.check_points[v.name].name = v.name;
			CheckPointIO.check_points[v.name].attr = {};
		else
			existWorldAttr = CheckPointIO.check_points[v.name].attr;
		end
		
		if(existWorldAttr) then
			local checkRet = CheckPointIO.checkUser(v.attr, existWorldAttr);
			CheckPointIO.check_points[v.name].isOpen = checkRet;
		end
		
		for kv, vv in pairs(v.attr or {}) do
			if not CheckPointIO.check_points[v.name].attr[kv] then
				CheckPointIO.check_points[v.name].attr[kv] = vv;
			end
		end
		

	end	
end

function CheckPointIO._writeUser()
	local localFile = CheckPointIO.getUserFileName();	
	writeXml(CheckPointIO.user_points, localFile);		
end	

function CheckPointIO._writeWorld()
	local localFile = CheckPointIO.getWorldFileName();
	writeXml(CheckPointIO.world_points, localFile);			
end	

function CheckPointIO.write(name, params, isUser)
	local existWorldAttr;
	if not CheckPointIO.check_points[name] then
		CheckPointIO.check_points[name] = {};
		CheckPointIO.check_points[name].name = name;
		CheckPointIO.check_points[name].attr = {};
	else
		
		for _, v in pairs(CheckPointIO.world_points) do
			if name == v.name then
				existWorldAttr = v.attr;
				break;
			end
		end	
	end
	
	for k, v in pairs(params) do
		if isUser then
			if not CheckPointIO.check_points[name].attr[k] then
				CheckPointIO.check_points[name].attr[k] = v;
			end
		else
			CheckPointIO.check_points[name].attr[k] = v;
		end
	end
	
	if(existWorldAttr) then
		local checkRet = CheckPointIO.checkUser(CheckPointIO.check_points[name].attr, existWorldAttr);
		if checkRet then
			CheckPointIO.check_points[v.name].isOpen = checkRet;
		end
	end
	
	if (isUser) then		
		writeXmlElement(CheckPointIO.user_points, name, params);
		CheckPointIO._writeUser();
	else
		writeXmlElement(CheckPointIO.world_points, name, params);
		CheckPointIO._writeWorld();
	end
end

function CheckPointIO.read(name)
	return CheckPointIO.check_points[name];
end

function CheckPointIO.readUser(inx)
	return CheckPointIO.user_points[inx];
end

function CheckPointIO.checkUser(userAttr, worldAttr)
	if userAttr.name == worldAttr.name then
		return true;
	else
		return false;
	end
end