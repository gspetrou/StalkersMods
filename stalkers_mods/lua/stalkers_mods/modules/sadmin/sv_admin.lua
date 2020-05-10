StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.Settings = StalkersMods.Admin.Settings or {}
StalkersMods.Admin.Bans = StalkersMods.Admin.Bans or {}

concommand.Add("stalkermods_admin_clientready", function(ply)
	if not ply.stalkermods_admin_clientready then
		StalkersMods.Admin.UserGroups.SyncUserGroups(ply)
		ply.stalkermods_admin_clientready = true
	end
end)

--------------------------------
-- StalkersMods.Admin.BanPlayer
--------------------------------
-- Desc:		Bans the given player.
-- Arg One:		Player, to ban.
-- Arg Two:		Number, length of ban in seconds.
-- Arg Three:	String, reason.
-- Arg Four:	Player or Steamid, who banned them. Nil for server.
function StalkersMods.Admin.BanPlayer(ply, length, reason, bannedBy)
	if not ply:IsBot() then
		local bannedBySteamID
		if isentity(bannedBy) then
			bannedBySteamID = bannedBy:SteamID()
		end
		StalkersMods.Admin.BanSteamID(ply:SteamID(), length, reason, bannedBySteamID)
	end
end

---------------------------------
-- StalkersMods.Admin.BanSteamID
---------------------------------
-- Desc:		Bans the given SteamID.
-- Arg One:		String, steamid to ban.
-- Arg Two:		Number, length of ban in sec.
-- Arg Three:	String, reason for ban.
-- Arg Four:	String, steamid of player that gave the ban.
function StalkersMods.Admin.BanSteamID(steamid, length, reason, bannedBySteamID)
	if steamid ~= "BOT" then
		local bannedByPlyName
		if bannedBySteamID then
			bannedByPlyName = player.GetBySteamID(bannedBySteamID)
			if IsValid(bannedByPlyName) then
				bannedByPlyName = bannedByPlyName:Nick()
			end
		end

		local ply = player.GetBySteamID(steamid)
		if IsValid(ply) then
			local banLengthText
			if length == 0 then
				banLengthText = "Forever"
			else
				banLengthText = StalkersMods.Utility.SecondsToTimeLeft(length)
			end
			local kickedByText = isstring(bannedBySteamID) and bannedBySteamID or "SERVER"

			if bannedBySteamID then
				local bannedBy = player.GetBySteamID(bannedBySteamID)
				if isentity(bannedBy) then
					kickedByText = bannedBy:Nick().." ("..bannedBySteamID..")"
				end
			end

			ply:Kick("Banned\nReason: "..(reason or "No reason").."\nLength: "..banLengthText.."\nKicked by: "..kickedByText)
		end

		local banData = {
			TimeOfBan = os.time(),
			Length = length,
			Reason = reason or "No reason",
			BannedBy = bannedBySteamID,
			BannedByNick = bannedByPlyName
		}

		if StalkersMods.Admin.Bans[steamid] then
			StalkersMods.Admin.Bans[steamid].CurrentlyBanned = true
			table.insert(StalkersMods.Admin.Bans[steamid].Bans, 1, banData)
		else
			StalkersMods.Admin.Bans[steamid] = {
				CurrentlyBanned = true,
				Bans = {banData}
			}
		end
		StalkersMods.Admin.WriteBansFile()
	end
end
-----------------------------------
-- StalkersMods.Admin.UnBanSteamID
-----------------------------------
-- Desc:		Unbans the given steamid.
-- Arg One:		String, steamid to unban.
function StalkersMods.Admin.UnBanSteamID(steamid)
	if StalkersMods.Admin.Bans[steamid] then
		StalkersMods.Admin.Bans[steamid].CurrentlyBanned = false
		StalkersMods.Admin.WriteBansFile()
	end
end

-------------------------------
-- StalkersMods.Admin.IsBanned
-------------------------------
-- Desc:		Sees if the given steamid is banned.
-- Arg One:		String, steamid.
-- Returns:		Boolean.
function StalkersMods.Admin.IsBanned(steamid)
	local banData = StalkersMods.Admin.Bans[steamid]
	if banData and banData.CurrentlyBanned then
		if not banData.Bans or #banData.Bans == 0 then
			return true, 0
		end

		local banEndData = banData.Bans[1]
		if banEndData.Length == 0 then
			return true, 0, banEndData
		end

		local banEndTime = banEndData.TimeOfBan + banEndData.Length
		local curTime = os.time()
		if banEndTime > curTime then
			return true, banEndTime - curTime, banEndData
		else
			StalkersMods.Admin.Bans[steamid].CurrentlyBanned = false
			StalkersMods.Admin.WriteBansFile()
			return false, -1
		end
	end
	return false, -1
end

------------------------------------
-- StalkersMods.Admin.WriteBansFile
------------------------------------
-- Desc:		Updates the currents bans with the ban file.
function StalkersMods.Admin.WriteBansFile()
	StalkersMods.Utility.SaveTableToFile(StalkersMods.Admin.Bans, StalkersMods.Admin.Config.PlayerBansFile)
end

------------------------------------
-- StalkersMods.Admin.WriteSettings
------------------------------------
-- Desc:		Writes the current state of StalkersMods.Admin.Settings to StalkersMods.Admin.Config.SettingsFile
function StalkersMods.Admin.WriteSettings()
	StalkersMods.Utility.SaveTableToFile(StalkersMods.Admin.Settings, StalkersMods.Admin.Config.SettingsFile)
end

----------------------------------------------
-- StalkersMods.Admin.GenerateDefaultSettings
----------------------------------------------
-- Desc:		Generates a table of settings in case none exist.
-- Returns:		Table, of user groups.
function StalkersMods.Admin.GenerateDefaultSettings()
	local defaultSettings = StalkersMods.Admin.Config.DefaultSettings
	defaultSettings.DefaultRank = defaultSettings["stock_default_usergroup"]
	return defaultSettings
end

------------------------------------
-- StalkersMods.Admin.LoadDataFiles
------------------------------------
-- Desc:		Loads data from the cold storage files of the admin mod.
-- Arg One:		Boolean=false, should we delete all old data and start fresh.
function StalkersMods.Admin.LoadDataFiles(forceClean)
	-- Load bans
	if forceClean or StalkersMods.Utility.CreateFileIfNotExists(StalkersMods.Admin.Config.PlayerBansFile) then
		StalkersMods.Admin.Bans = {}
		StalkersMods.Admin.WriteBansFile()
	else
		StalkersMods.Admin.Bans = StalkersMods.Utility.LoadTableFromFile(StalkersMods.Admin.Config.PlayerBansFile)
	end

	-- Load our user groups either from file or generated defaults, then register them.
	local grps
	if forceClean or StalkersMods.Utility.CreateFileIfNotExists(StalkersMods.Admin.Config.UserGroupsFile) then
		grps = StalkersMods.Admin.UserGroups.GenerateDefaultUserGroups()
		
	else
		grps = StalkersMods.Utility.LoadTableFromFile(StalkersMods.Admin.Config.UserGroupsFile)

		-- Lua "objects" get saved as a table when serialized so undo this by recreating their object.
		for groupName, groupAsTable in pairs(grps) do
			grps[groupName] = StalkersMods.Admin.UserGroup:New(groupAsTable)
		end
	end
	for userGroupName, userGroup in pairs(grps) do
		StalkersMods.Admin.UserGroups.RegisterUserGroup(userGroup)
	end
	StalkersMods.Admin.UserGroups.Groups = grps

	-- Merge CAMI shit
	-- If a CAMI group isn't registered in our mod then add it.
	local camiGroups = CAMI.GetUsergroups()
	for camiGroupName, camiGroup in pairs(camiGroups) do
		if not StalkersMods.Admin.UserGroups.UserGroupExists(camiGroupName) then
			local userGroup = StalkersMods.Admin.UserGroup:New()
			userGroup:SetName(camiGroup.Name)
			if camiGroup.Inherits ~= "user" then
				userGroup:SetInherits(camiGroup.Inherits)
			end
			StalkersMods.Admin.UserGroups.Groups[userGroup:GetName()] = userGroup
		end
	end
	-- If a CAMI privilege isn't assigned to its MinAccess group then assign it.
	local camiPrivs = CAMI.GetPrivileges()
	for camiPrivName, camiPriv in pairs(camiPrivs) do
		local minAccessGroupName = camiPriv.MinAccess
		if StalkersMods.Admin.UserGroups.UserGroupExists(minAccessGroupName) and not StalkersMods.Admin.UserGroups.UserGroupHasPrivilege(minAccessGroupName, camiPriv.Name) then
			StalkersMods.Admin.UserGroups.UserGroupAddPrivilege(minAccessGroupName, camiPriv.Name)
		end
	end

	StalkersMods.Admin.UserGroups.WriteUserGroupsFile()

	-- Load the offline playerranks file, or generate a default one if one doesn't exist and save it.
	if forceClean or StalkersMods.Utility.CreateFileIfNotExists(StalkersMods.Admin.Config.OfflinePlayerRanksFile) then
		StalkersMods.Admin.UserGroups.OfflineRanks = StalkersMods.Admin.UserGroupsGenerateDefaultPlayerRanks()
		StalkersMods.Admin.UserGroups.WriteOfflinePlayerRanksFile()
	else
		StalkersMods.Admin.UserGroups.OfflineRanks = StalkersMods.Utility.LoadTableFromFile(StalkersMods.Admin.Config.OfflinePlayerRanksFile)
	end

	-- Load the settings file, or generate a default one if one doesn't exist and save it.
	if forceClean or StalkersMods.Utility.CreateFileIfNotExists(StalkersMods.Admin.Config.SettingsFile) then
		StalkersMods.Admin.Settings = StalkersMods.Admin.GenerateDefaultSettings()
		StalkersMods.Admin.WriteSettings()
	else
		StalkersMods.Admin.Settings = StalkersMods.Utility.LoadTableFromFile(StalkersMods.Admin.Config.SettingsFile)
	end
end

hook.Add("PlayerAuthed", "StalkersMods.Admin.SetRankOnAuth", function(ply, steamID)
	local userGroupName = StalkersMods.Admin.UserGroups.GetOfflinePlayerUserGroupBySteamID(steamID)

	-- If their group got deleted or they dont have a group then assign them the default.
	if not userGroupName or not StalkersMods.Admin.UserGroups.UserGroupExists(userGroupName) then
		StalkersMods.Admin.UserGroups.SetPlayerUserGroupAndSave(ply, StalkersMods.Admin.UserGroups.GetDefaultUserGroup())
	else
		ply:SetUserGroup(userGroupName)
	end
end)

hook.Add("PlayerSay", "StalkersMods.Admin.CheckChatForCommand", function(ply, text, teamChat)
	if #text < 2 then
		return
	end

	if text == "!adminmenu" or text == "/adminmenu" then
		ply:ConCommand("sadmin_menu")
		if text == "/adminmenu" then
			return ""
		end
	end

	if text[1] == "!" or text[1] == "/" then
		local succeeded = StalkersMods.Admin.ValidateAndRunCommand(ply, text, true)

		if text[1] == "/" and StalkersMods.Admin.UserGroups.UserHasPrivilege(ply, StalkersMods.Admin.Config.SilentCommandOnSlash) then
			return ""
		end
	end
end)

hook.Add("CheckPassword", "StalkersMods.Admin.KickBannedPlayers", function(steamID64, _, _, _, name)
	local steamID = util.SteamIDFrom64(steamID64)
	local isBanned, banLeft, banData = StalkersMods.Admin.IsBanned(steamID)
	if isBanned then
		local banLengthText
		if banLeft == 0 then
			banLengthText = "Forever"
		else
			banLengthText = StalkersMods.Utility.SecondsToTimeLeft(banLeft)
		end

		local bannedByText = "SERVER"
		if banData.BannedBy then
			if banData.BannedByNick then
				bannedByText = banData.BannedByNick.." ("..banData.BannedBy..")"
			else
				bannedByText = banData.BannedBy
			end
		end

		local banMsg = string.format("Banned\nReason: %s\nTime Left: %s\nBanned by: %s", tostring(banData.Reason), tostring(banLengthText), tostring(bannedByText))
		return false, banMsg
	end
end)

util.AddNetworkString("StalkersMods.Admin.TryCmd")
net.Receive("StalkersMods.Admin.TryCmd", function(_, ply)
	StalkersMods.Admin.ValidateAndRunCommand(ply, net.ReadString())
end)
