-- Legacy master server thing
-- Created by William "JetBoom" Moodhe
-- williammoodhe@gmail.com
-- Some code scraped from the glsock2 thread on facepunch

require 'glsock2'

module( "legacyquery", package.seeall )

local HL2_MASTER_ADDRESS = "hl2master.steampowered.com"
local HL2_MASTER_PORT = 27011
local FILTER = "\\gamedir\\garrysmod'"
local REGION = string.char(0xFF) -- World
local A2S_INFO = string.char(0xFF)..string.char(0xFF)..string.char(0xFF)..string.char(0xFF)..string.char(0x54).."Source Engine Query"..string.char(0x00)
local SERVER_INFO_TIMEOUT = 2.0 -- I think 2000ms ping isn't playable anyway.
local REFRESH_RATE = 0.05

local GLSockErrorCodes = 
{
	[GLSOCK_ERROR_SUCCESS] = "GLSOCK_ERROR_SUCCESS",
	[GLSOCK_ERROR_ACCESSDENIED] = "GLSOCK_ERROR_ACCESSDENIED",
	[GLSOCK_ERROR_ADDRESSFAMILYNOTSUPPORTED] = "GLSOCK_ERROR_ADDRESSFAMILYNOTSUPPORTED",
	[GLSOCK_ERROR_ADDRESSINUSE] = "GLSOCK_ERROR_ADDRESSINUSE",
	[GLSOCK_ERROR_ALREADYCONNECTED] = "GLSOCK_ERROR_ALREADYCONNECTED",
	[GLSOCK_ERROR_ALREADYSTARTED] = "GLSOCK_ERROR_ALREADYSTARTED",
	[GLSOCK_ERROR_BROKENPIPE] = "GLSOCK_ERROR_BROKENPIPE",
	[GLSOCK_ERROR_CONNECTIONABORTED] = "GLSOCK_ERROR_CONNECTIONABORTED",
	[GLSOCK_ERROR_CONNECTIONREFUSED] = "GLSOCK_ERROR_CONNECTIONREFUSED",
	[GLSOCK_ERROR_CONNECTIONRESET] = "GLSOCK_ERROR_CONNECTIONRESET",
	[GLSOCK_ERROR_BADDESCRIPTOR] = "GLSOCK_ERROR_BADDESCRIPTOR",
	[GLSOCK_ERROR_BADADDRESS] = "GLSOCK_ERROR_BADADDRESS",
	[GLSOCK_ERROR_HOSTUNREACHABLE] = "GLSOCK_ERROR_HOSTUNREACHABLE",
	[GLSOCK_ERROR_INPROGRESS] = "GLSOCK_ERROR_INPROGRESS",
	[GLSOCK_ERROR_INTERRUPTED] = "GLSOCK_ERROR_INTERRUPTED",
	[GLSOCK_ERROR_INVALIDARGUMENT] = "GLSOCK_ERROR_INVALIDARGUMENT",
	[GLSOCK_ERROR_MESSAGESIZE] = "GLSOCK_ERROR_MESSAGESIZE",
	[GLSOCK_ERROR_NAMETOOLONG] = "GLSOCK_ERROR_NAMETOOLONG",
	[GLSOCK_ERROR_NETWORKDOWN] = "GLSOCK_ERROR_NETWORKDOWN",
	[GLSOCK_ERROR_NETWORKRESET] = "GLSOCK_ERROR_NETWORKRESET",
	[GLSOCK_ERROR_NETWORKUNREACHABLE] = "GLSOCK_ERROR_NETWORKUNREACHABLE",
	[GLSOCK_ERROR_NODESCRIPTORS] = "GLSOCK_ERROR_NODESCRIPTORS",
	[GLSOCK_ERROR_NOBUFFERSPACE] = "GLSOCK_ERROR_NOBUFFERSPACE",
	[GLSOCK_ERROR_NOMEMORY] = "GLSOCK_ERROR_NOMEMORY",
	[GLSOCK_ERROR_NOPERMISSION] = "GLSOCK_ERROR_NOPERMISSION",
	[GLSOCK_ERROR_NOPROTOCOLOPTION] = "GLSOCK_ERROR_NOPROTOCOLOPTION",
	[GLSOCK_ERROR_NOTCONNECTED] = "GLSOCK_ERROR_NOTCONNECTED",
	[GLSOCK_ERROR_NOTSOCKET] = "GLSOCK_ERROR_NOTSOCKET",
	[GLSOCK_ERROR_OPERATIONABORTED] = "GLSOCK_ERROR_OPERATIONABORTED",
	[GLSOCK_ERROR_OPERATIONNOTSUPPORTED] = "GLSOCK_ERROR_OPERATIONNOTSUPPORTED",
	[GLSOCK_ERROR_SHUTDOWN] = "GLSOCK_ERROR_SHUTDOWN",
	[GLSOCK_ERROR_TIMEDOUT] = "GLSOCK_ERROR_TIMEDOUT",
	[GLSOCK_ERROR_TRYAGAIN] = "GLSOCK_ERROR_TRYAGAIN",
	[GLSOCK_ERROR_WOULDBLOCK] = "GLSOCK_ERROR_WOULDBLOCK"
}

local function GetError(err)
	local erstr = GLSockErrorCodes[err or -1]
	if erstr then return erstr end

	return tostring(err)
end

local RefreshID = 0
local ServerType

local function Message(text)
	print("[legacyquery] "..text)
end

local function ProcessInfo(buffer, ip, port, sock)
	print("ProcessInfo for ", ip, port)

	local _, hostname, map, gamedirectory, gamedescription, shortappid, numplayers, maxplayers, numofbots,
	dedicated, os, password, secure, gameversion, extra, gameport, steamid, spectport, spectname, gametag, gameid

	_, version = buffer:ReadByte()
	_, hostname = buffer:ReadString()
	_, map = buffer:ReadString()
	_, gamedirectory = buffer:ReadString()
	_, gamedescription = buffer:ReadString()
	_, shortappid = buffer:ReadShort()
	_, numplayers = buffer:ReadByte()
	_, maxplayers = buffer:ReadByte()
	_, numofbots = buffer:ReadByte()
	_, dedicated = buffer:ReadByte()
	_, os = buffer:ReadByte()
	_, password = buffer:ReadByte()
	_, secure = buffer:ReadByte()
	_, gameversion = buffer:ReadString()
	_, extra = buffer:ReadByte()
	
	if bit.band(extra, 0x80) == 0x80 then
		_, gameport = buffer:ReadShort()
	end
	
	if bit.band(extra, 0x10) == 0x10 then
		steamid = {
			select(2, buffer:ReadLong()),
			select(2, buffer:ReadLong())
		}
	end
	
	if bit.band(extra, 0x40) == 0x40 then
		_, spectport = buffer:ReadShort()
	end
	
	if bit.band(extra, 0x40) == 0x40 then
		_, spectname = buffer:ReadString()
	end
	
	if bit.band(extra, 0x20) == 0x20 then
		_, gametag = buffer:ReadString()
	end
	
	if bit.band(extra, 0x01) == 0x01 then
		gameid = {
			select(2, buffer:ReadLong()),
			select(2, buffer:ReadLong())
		}
	end
	
	local data = {
		["version"] = version,
		["hostname"] = hostname,
		["map"] = map,
		["gamedirectory"] = gamedirectory,
		["gamedescription"] = gamedescription,
		["shortappid"] = shortappid,
		["numplayers"] = numplayers,
		["maxplayers"] = maxplayers,
		["numofbots"] = numofbots,
		["dedicated"] = string.char(dedicated),
		["os"] = string.char(os),
		["password"] = password,
		["secure"] = secure,
		["gameversion"] = gameversion,
		
		["extra"] = extra,		
			["gameport"] = gameport,
			["steamid"] = steamid,
			["spectport"] = spectport,
			["spectname"] = spectname,
			["gametag"] = gametag,
			["gameid"] = gameid,
	}

	local gamemode, workshopid
	if gametag then
		gamemode = string.match(gametag, "gm:([%d%w_-]+)")
		workshopid = string.match(gametag, "gmws:(%d+)")
	end

	local ping = 5 --math.ceil((CurTime() - sock.StartTime) * 1000)

	ServerCallback( ping , hostname, gamedescription, map, numplayers, maxplayers, numofbots, password == 1, 5, ip..":"..port, tostring(gamemode or ""), tostring(workshopid or "") )

	--PrintTable(data)
end

local OnReadInfoRequest

local function CreateInfoSocket()
	Message("Creating new server query socket")

	return GLSock(GLSOCK_TYPE_UDP)
end

local function CloseInfoSocket(sock)
	if sock then
		Message("Serer query socket died or finished its job")

		if sock.Cancel then
			sock:Cancel()
		end
		if sock.Close then
			sock:Close()
		end
		--[[if sock.Destroy then
			sock:Destroy()
		end]]
	end
end

local function ContinueReadInfo(sock)
	sock:ReadFrom(1500, OnReadInfoRequest)
end

OnReadInfoRequest = function(sock, address, port, buffer, err)
	if err ~= GLSOCK_ERROR_SUCCESS then
		Message("Error in OnReadInfoRequest! "..GetError(err))

		CloseInfoSocket(sock)
		return
	end

	Message("Received " .. buffer:Size() .. " bytes")

	--[[local count, data = buffer:Read(buffer:Size())
	if count > 0 then
		Message(data)
	end]]

	if buffer:Size() < 1 then 
		Message("Received weird buffer of size "..buffer:Size().." from "..address..":"..port)

		CloseInfoSocket(sock)
		return
	end

	local _, b1 = buffer:ReadByte()
	local _, b2 = buffer:ReadByte()
	local _, b3 = buffer:ReadByte()
	local _, b4 = buffer:ReadByte()

	if buffer:EOB() then
		Message("Invalid Buffer size ("..buffer:Size()..") for this packet type from "..address..":"..port.." Bytes: "..b1.." ".." "..b2.." "..b3.." "..b4)

		CloseInfoSocket(sock)
		return
	end

	if b1 ~= 0xFF or b2 ~= 0xFF or b3 ~= 0xFF or b4 ~= 0xFF then
		Message("Invalid A2S_INFO response from "..address..":"..port)

		CloseInfoSocket(sock)
		return
	end

	local _, b5 = buffer:ReadByte()

	if b5 == 0x49 then
		ProcessInfo(buffer, address, port, sock)
	else
		Message("Invalid A2S_INFO response from "..address..":"..port.." (Byte: "..b5..")")
	end

	CloseInfoSocket(sock)
end

local function OnSend(sock, bytes, err)
	if err ~= GLSOCK_ERROR_SUCCESS then
		Message("SendTo error ("..GetError(err)..")")
	end
end

local function SocketTimeOut(sock)
	if sock ~= nil then
		if sock.Cancel then
			sock:Cancel()
		end
		if sock.Close then
			sock:Close()
		end
		--[[if sock.Destroy then
			sock:Destroy()
		end]]

		--Message("Request timed out")
	end
end

function RequestServerInfo(host, port)
	local sock = CreateInfoSocket()
	if sock then
		local buffer = GLSockBuffer()
		if #A2S_INFO ~= buffer:Write(A2S_INFO) then
			Message("Buffer length isn't the same as what was written???")
		end

		--sock.StartTime = CurTime() -- This crashes??? Put it in a table?
		sock:SendTo(buffer, host, port, OnSend)

		sock:ReadFrom(1500, OnReadInfoRequest)

		timer.Simple(SERVER_INFO_TIMEOUT, function() SocketTimeOut(sock) end)
	end
end

--[[local Seed = "0.0.0.0:0"

local function More()
	local buffer = GLSockBuffer()
	buffer:Write()
end]]

local ServerListID
local Servers

local function ServerRefreshTimer()
	-- User stopped the refresh
	if ShouldStop[ServerType] then
		timer.Destroy("ServerListQuery")
		return
	end

	ServerListID = ServerListID + 1
	local address = Servers[ServerListID]
	if address then
		local ip, port = string.match(address, "(.+):(%d+)")
		if ip then
			RequestServerInfo(ip, tonumber(port))
		end
	else
		-- We're done!
		timer.Destroy("ServerListQuery")
	end
end

local function FetchedServerList(body, len, headers, code)
	if len > 0 and tonumber(code) == 200 then
		Servers = string.Explode("\n", body)
		ServerListID = 0

		timer.Create("ServerListQuery", REFRESH_RATE, 0, ServerRefreshTimer)
	end
end

function GetMasterServerList(server_type, refresh_id)
	timer.Destroy("ServerListQuery")

	ServerType = server_type
	RefreshID = refresh_id
	--[[CreateSocket()

	GetMoreServers()

	InitializeSocket()]]

	-- Hardcoded for now...
	http.Fetch("http://www.noxiousnet.com/output.txt", FetchedServerList, function() end)
end
