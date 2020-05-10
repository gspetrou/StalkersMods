StalkersMods.Warnings = StalkersMods.Warnings or {}
StalkersMods.Warnings.SaveFileLocation = "stalkers_mods/warnings.dat"

--------------------------------------------
-- StalkersMods.Warnings.SaveWarningsToFile
--------------------------------------------
-- Desc:		Saves current warnings to storage.
function StalkersMods.Warnings.SaveWarningsToFile()
	StalkersMods.Utility.SaveTableToFile(StalkersMods.Warnings.Warnings, StalkersMods.Warnings.SaveFileLocation)
end

---------------------------------------
-- StalkersMods.Warnings.LoadDataFiles
---------------------------------------
-- Desc:		Loads warnings from their storage file. Data goes into StalkersMods.Warnings.Warnings.
-- Arg One:		Boolean, delete old files and start fresh.
function StalkersMods.Warnings.LoadDataFiles(forceClean)
	if forceClean or StalkersMods.Utility.CreateFileIfNotExists(StalkersMods.Warnings.SaveFileLocation) then
		StalkersMods.Warnings.Warnings = {}
		StalkersMods.Warnings.SaveWarningsToFile()
	else
		warnTbl = StalkersMods.Utility.LoadTableFromFile(StalkersMods.Warnings.SaveFileLocation)

		-- Ensure the warning objects are made back into objects, not just tables.
		for plySteamID, warnTableOfPly in pairs(warnTbl) do
			for i, warnForPly in ipairs(warnTableOfPly) do
				warnTbl[plySteamID][i] = StalkersMods.Warnings.WarningClass:New(warnForPly)
			end
		end

		StalkersMods.Warnings.Warnings = warnTbl
	end
end

------------------------------------------
-- StalkersMods.Warnings.GetWarningsTable
------------------------------------------
-- Desc:		Gets the warning data table.
-- Returns:		Table, of warnings.
function StalkersMods.Warnings.GetWarningsTable()
	return StalkersMods.Warnings.Warnings or {}
end

---------------------------------------------
-- StalkersMods.Warnings.GetWarningsOfPlayer
---------------------------------------------
-- Desc:		Gets the warnings of a player.
-- Arg One:		Player entity
-- Returns:		Table, or nil if none.
function StalkersMods.Warnings.GetWarningsOfPlayer(ply)
	return StalkersMods.Warnings.GetWarningsOfSteamID(ply:SteamID())
end

----------------------------------------------
-- StalkersMods.Warnings.GetWarningsOfSteamID
----------------------------------------------
-- Desc:		Gets warnings of SteamID.
-- Arg One:		String, steamid32
-- Returns:		Table, warnings belonging to that steamid, or nil.
function StalkersMods.Warnings.GetWarningsOfSteamID(steamID)
	return StalkersMods.Warnings.GetWarningsTable()[steamID]
end

---------------------------------------------
-- StalkersMods.Warnings.GiveWarningToPlayer
---------------------------------------------
-- Desc:		Gives a warning to a player.
-- Arg One:		Player entity.
-- Arg Two:		StalkersMods.Warnings.WarningClass
function StalkersMods.Warnings.GiveWarningToPlayer(ply, warningObj)
	StalkersMods.Warnings.GiveWarningToSteamID(ply:SteamID(), warningObj)
end

----------------------------------------------
-- StalkersMods.Warnings.GiveWarningToSteamID
----------------------------------------------
-- Desc:		Gives a warning to a SteamID
-- Arg One:		String, steamid to warn.
-- Arg Two:		StalkersMods.Warnings.WarningClass
function StalkersMods.Warnings.GiveWarningToSteamID(steamID, warningObj)
	if StalkersMods.Warnings.Warnings[steamID] then
		table.insert(StalkersMods.Warnings.Warnings[steamID], warningObj)
	else
		StalkersMods.Warnings.Warnings[steamID] = {warningObj}
	end
	StalkersMods.Warnings.SaveWarningsToFile()
end

-------------------------------------------------
-- StalkersMods.Warnings.RemoveWarningFromPlayer
-------------------------------------------------
-- Desc:		Removes a warning from a player
-- Arg One:		Player
-- Arg Two:		String, warning unique ID
function StalkersMods.Warnings.RemoveWarningFromPlayer(ply, warnID)
	StalkersMods.Warnings.RemoveWarningFromSteamID(ply:SteamID(), warnID)
end

--------------------------------------------------
-- StalkersMods.Warnings.RemoveWarningFromSteamID
--------------------------------------------------
-- Desc:		Removes a warning from a steamid.
-- Arg One:		String, steamid32.
-- Arg Two:		String, warning unique id.
function StalkersMods.Warnings.RemoveWarningFromSteamID(steamID, warnID)
	if StalkersMods.Warnings.Warnings[steamID] then
		for i, warn in ipairs(StalkersMods.Warnings.Warnings[steamID]) do
			if warn:GetUniqueID() == warnID then
				table.remove(StalkersMods.Warnings.Warnings[steamID], i)
				break
			end
		end
		if #StalkersMods.Warnings.Warnings[steamID] == 0 then
			StalkersMods.Warnings.Warnings[steamID] = nil
		end
		StalkersMods.Warnings.SaveWarningsToFile()
	end
end

----------------------------------------------
-- StalkersMods.Warnings.GetWarningByUniqueID
----------------------------------------------
-- Desc:		Gets a warninging objects from its unique id.
-- Arg One:		String, warning unique id.
-- Returns:		StalkersMods.Warnings.WarningClass.
function StalkersMods.Warnings.GetWarningByUniqueID(uniqueID)
	local objSplitID = string.Split(uniqueID, "-")
	local plysWarnings = StalkersMods.Warnings.GetWarningsOfSteamID(objSplitID[1])
	local timeStampNum = tonumber(objSplitID[2])

	for i, warning in ipairs(plysWarnings) do
		if warning:GetTimeStamp() == timeStampNum then
			return warning
		end
	end

	return nil
end

-------------------------------------------------
-- StalkersMods.Warnings.GiveOnlinePlayerWarning
-------------------------------------------------
-- Desc:		Gives an online player a warning.
-- Arg One:		Player, to be warned.
-- Arg Two:		Player or NULL. Player warning the person, null/nil if server.
-- Arg Three:	String, reason for warn.
function StalkersMods.Warnings.GiveOnlinePlayerWarning(plyGetWarn, plyGiveWarn, reason)
	local warnObj = StalkersMods.Warnings.WarningClass:New()
	warnObj:SetOwnerSteamID(plyGetWarn:SteamID())
	warnObj:SetOwnerNick(plyGetWarn:Nick())
	if IsValid(plyGiveWarn) then
		warnObj:SetGivenBySteamID(plyGiveWarn:SteamID())
		warnObj:SetGivenByNick(plyGiveWarn:Nick())
	else
		warnObj:SetGivenBySteamID("SERVER")
		warnObj:SetGivenByNick("SERVER")
	end
	warnObj:SetDescription(reason)
	warnObj:SetTimeStamp(os.time())
	StalkersMods.Warnings.GiveWarningToPlayer(plyGetWarn, warnObj)
end

--------------------------------------------------
-- StalkersMods.Warnings.GiveOfflinePlayerWarning
--------------------------------------------------
-- Desc:		Warns a given steamid.
-- Arg One:		String, steamid to warn.
-- Arg Two:		Player, giving the warning, or null/nill for server.
-- Arg Three:	String, reason.
function StalkersMods.Warnings.GiveOfflinePlayerWarning(steamIDGetWarn, plyGiveWarn, reason)
	local warnObj = StalkersMods.Warnings.WarningClass:New()
	warnObj:SetOwnerSteamID(steamIDGetWarn)

	if isstring(plyGiveWarn) then
		if StalkersMods.Utility.IsSteamID32(plyGiveWarn) then
			local plyGiveWarnEntity = player.GetBySteamID(plyGiveWarn)
			if IsValid(plyGiveWarnEntity) then
				warnObj:SetGivenByNick(plyGiveWarnEntity:Nick())
			end
		end
		warnObj:SetGivenBySteamID(plyGiveWarn)
	else
		warnObj:SetGivenBySteamID("SERVER")
		warnObj:SetGivenByNick("SERVER")
	end
	warnObj:SetDescription(reason)
	warnObj:SetTimeStamp(os.time())
	StalkersMods.Warnings.GiveWarningToSteamID(steamIDGetWarn, warnObj)
end

--------------------------------------------------
-- StalkersMods.Warnings.SyncOnlinePlayerWarnings
--------------------------------------------------
-- Desc:		Sends the warnings of all online players to the given recipients.
-- Arg One:		Player/Table/true. Player/table of player recipients, or true for everyone.
util.AddNetworkString("StalkersMods.Warnings.SyncOnlinePlys")
function StalkersMods.Warnings.SyncOnlinePlayerWarnings(recipients)
	local warnsToSend = {}

	for i, ply in ipairs(player.GetAll()) do
		local plyWarnData = StalkersMods.Warnings.GetWarningsOfPlayer(ply)
		if plyWarnData then
			for i, warnObj in ipairs(plyWarnData) do
				table.insert(warnsToSend, warnObj)
			end
		end
	end

	net.Start("StalkersMods.Warnings.SyncOnlinePlys")
		net.WriteUInt(#warnsToSend, 12)
		for i, warn in ipairs(warnsToSend) do
			StalkersMods.Warnings.WriteWarning(warnsToSend[i])
		end
	if not recipients then
		net.Broadcast()
	else
		net.Send(recipients)
	end
end

------------------------------------------
-- StalkersMods.Warnings.SyncSelfWarnings
------------------------------------------
-- Desc:		Sends the given player their own warnings.
-- Arg One:		Player.
function StalkersMods.Warnings.SyncSelfWarnings(ply)
	local warnsToSend = StalkersMods.Warnings.GetWarningsOfPlayer(ply) or {}
	net.Start("StalkersMods.Warnings.SyncOnlinePlys")
		net.WriteUInt(#warnsToSend, 12)
		for i, warn in ipairs(warnsToSend) do
			StalkersMods.Warnings.WriteWarning(warn)
		end
	net.Send(ply)
end

-- Received from client when they ask to view warnings.
util.AddNetworkString("StalkersMods.Warnings.RequestOnlineWarns")
net.Receive("StalkersMods.Warnings.RequestOnlineWarns", function(_, ply)
	if not IsValid(ply) then
		return
	end

	CAMI.PlayerHasAccess(ply, StalkersMods.Warnings.Privileges.SYNC_ANY.Name, function(allowed)
		-- If not allowed then try to send their own warning data.
		if not allowed then
			CAMI.PlayerHasAccess(ply, StalkersMods.Warnings.Privileges.SYNC_SELF.Name, function(allowed)
				if allowed then
					StalkersMods.Warnings.SyncSelfWarnings(ply)
				else
					-- Send them shit
					net.Start("StalkersMods.Warnings.SyncOnlinePlys")
						net.WriteUInt(0, 12)
					net.Send(ply)
					StalkersMods.Logging.LogWarning("[SWarn] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried viewing warnings when they aren't allowed.")
				end
			end)
		else
			StalkersMods.Warnings.SyncOnlinePlayerWarnings(ply)
		end
	end)
end)

-- Received from client when they want to add a warning.
util.AddNetworkString("StalkersMods.Warnings.RequestAddWarn")
net.Receive("StalkersMods.Warnings.RequestAddWarn", function(_, ply)
	if not IsValid(ply) then
		return
	end

	local targetSteamID = net.ReadString()
	local reason = net.ReadString()
	if not StalkersMods.Utility.IsSteamID32(targetSteamID) then
		return
	end

	CAMI.PlayerHasAccess(ply, StalkersMods.Warnings.Privileges.ADD.Name, function(allowed)
		if allowed then
			StalkersMods.Warnings.GiveOfflinePlayerWarning(targetSteamID, ply:SteamID(), reason)
		else
			StalkersMods.Logging.LogSecurity("[SWarn] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried adding a warning to ("..targetSteamID..") when they aren't allowed!")
		end
	end)
end)

-- Received from client when they want to delete a warning.
util.AddNetworkString("StalkersMods.Warnings.RequestDeleteWarn")
net.Receive("StalkersMods.Warnings.RequestDeleteWarn", function(_, ply)
	if not IsValid(ply) then
		return
	end

	local warnID = net.ReadString()
	local warnObj = StalkersMods.Warnings.GetWarningByUniqueID(warnID)
	if warnObj then
		CAMI.PlayerHasAccess(ply, StalkersMods.Warnings.Privileges.DELETE.Name, function(allowed)
			if allowed then
				StalkersMods.Warnings.RemoveWarningFromSteamID(warnObj:GetOwnerSteamID(), warnID)
			else
				StalkersMods.Logging.LogSecurity("[SWarn] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried deleting warning ("..warnID..") when they aren't allowed!")
			end
		end)
	end
end)

-- Received from client when they wany to see the warnings of a player given their SteamID.
util.AddNetworkString("StalkersMods.Warnings.RequestBySteamID")
net.Receive("StalkersMods.Warnings.RequestBySteamID", function(_, ply)
	if not IsValid(ply) then
		return
	end
	
	local steamID = net.ReadString()

	local function sendDataOfSteamID(steamID, recip)
		local warningsOfSteamID = StalkersMods.Warnings.GetWarningsOfSteamID(steamID)

		net.Start("StalkersMods.Warnings.RequestBySteamID")
			if warningsOfSteamID then
				net.WriteUInt(#warningsOfSteamID, 12)
			else
				net.WriteUInt(0, 12)
			end

			for i, warn in ipairs(warningsOfSteamID) do
				StalkersMods.Warnings.WriteWarning(warn)
			end
		net.Send(ply)
	end

	if steamID == ply:SteamID() then
		CAMI.PlayerHasAccess(ply, StalkersMods.Warnings.Privileges.SYNC_SELF.Name, function(allowed)
			if allowed then
				sendDataOfSteamID(steamID, ply)
			else
				-- Send them shit
				net.Start("StalkersMods.Warnings.RequestBySteamID")
					net.WriteUInt(0, 12)
				net.Send(ply)
				StalkersMods.Logging.LogWarning("[SWarn] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried viewing their own warnings when they aren't allowed.")
			end
		end)
	else
		CAMI.PlayerHasAccess(ply, StalkersMods.Warnings.Privileges.SYNC_ANY.Name, function(allowed)
			if allowed then
				sendDataOfSteamID(steamID, ply)
			else
				-- Send them shit
				net.Start("StalkersMods.Warnings.RequestBySteamID")
					net.WriteUInt(0, 12)
				net.Send(ply)
				StalkersMods.Logging.LogWarning("[SWarn] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried viewing someone else's warnings when they aren't allowed.")
			end
		end)
	end	
end)

hook.Add("Initialize", "StalkersMods.Warnings.Initialize", function()
	StalkersMods.Warnings.LoadDataFiles()
end)