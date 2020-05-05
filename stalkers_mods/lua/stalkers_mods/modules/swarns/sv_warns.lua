StalkersMods.Warnings = StalkersMods.Warnings or {}
StalkersMods.Warnings.SaveFileLocation = "stalkers_mods/warnings.dat"

function StalkersMods.Warnings.SaveWarningsToFile()
	StalkersMods.Utility.SaveTableToFile(StalkersMods.Warnings.Warnings, StalkersMods.Warnings.SaveFileLocation)
end

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

function StalkersMods.Warnings.GetWarningsTable()
	return StalkersMods.Warnings.Warnings or {}
end

function StalkersMods.Warnings.GetWarningsOfPlayer(ply)
	return StalkersMods.Warnings.GetWarningsOfSteamID(ply:SteamID())
end

function StalkersMods.Warnings.GetWarningsOfSteamID(steamID)
	return StalkersMods.Warnings.GetWarningsTable()[steamID]
end

function StalkersMods.Warnings.GiveWarningToPlayer(ply, warningObj)
	StalkersMods.Warnings.GiveWarningToSteamID(ply:SteamID(), warningObj)
end

function StalkersMods.Warnings.GiveWarningToSteamID(steamID, warningObj)
	if StalkersMods.Warnings.Warnings[steamID] then
		table.insert(StalkersMods.Warnings.Warnings[steamID], warningObj)
	else
		StalkersMods.Warnings.Warnings[steamID] = {warningObj}
	end
	StalkersMods.Warnings.SaveWarningsToFile()
end

function StalkersMods.Warnings.RemoveWarningFromPlayer(ply, warnID)
	StalkersMods.Warnings.RemoveWarningFromSteamID(ply:SteamID(), warnID)
end

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

util.AddNetworkString("StalkersMods.Warings.SyncOnlinePlys")
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

	net.Start("StalkersMods.Warings.SyncOnlinePlys")
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

util.AddNetworkString("StalkersMods.Warnings.RequestOnlineWarns")
net.Receive("StalkersMods.Warnings.RequestOnlineWarns", function(_, ply)
	StalkersMods.Warnings.SyncOnlinePlayerWarnings(ply)
end)

util.AddNetworkString("StalkersMods.Warnings.RequestAddWarn")
net.Receive("StalkersMods.Warnings.RequestAddWarn", function(_, ply)
	local targetSteamID = net.ReadString()
	local reason = net.ReadString()
	if not StalkersMods.Utility.IsSteamID32(targetSteamID) then
		return
	end
	StalkersMods.Warnings.GiveOfflinePlayerWarning(targetSteamID, ply:SteamID(), reason)
end)

hook.Add("Initialize", "StalkersMods.Warnings.Initialize", function()
	StalkersMods.Warnings.LoadDataFiles()
end)