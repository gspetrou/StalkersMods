StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.UserGroups = StalkersMods.Admin.UserGroups or {}
StalkersMods.Admin.UserGroups.OfflineRanks = StalkersMods.Admin.UserGroups.OfflineRanks or {}

-----------------------------------------------------
-- StalkersMods.Admin.UserGroups.GetDefaultUserGroup
-----------------------------------------------------
-- Desc:		Gets the server default rank/usergroup.
-- Returns:		String
function StalkersMods.Admin.UserGroups.GetDefaultUserGroup()
	return StalkersMods.Admin.Settings.DefaultUserGroup or StalkersMods.Admin.Config.DefaultSettings["stock_default_usergroup"]
end

-------------------------------------------------------------
-- StalkersMods.Admin.UserGroups.WriteOfflinePlayerRanksFile
-------------------------------------------------------------
-- Desc:		Writes the current state of StalkersMods.Admin.UserGroups.OfflineRanks to StalkersMods.Admin.Config.OfflinePlayerRanksFile
function StalkersMods.Admin.UserGroups.WriteOfflinePlayerRanksFile()
	StalkersMods.Utility.SaveTableToFile(StalkersMods.Admin.UserGroups.OfflineRanks, StalkersMods.Admin.Config.OfflinePlayerRanksFile)
end

-----------------------------------------------------
-- StalkersMods.Admin.UserGroups.WriteUserGroupsFile
-----------------------------------------------------
-- Desc:		Writes the current state of StalkersMods.Admin.UserGroups.Groups to StalkersMods.Admin.UserGroupsFile
function StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
	StalkersMods.Utility.SaveTableToFile(StalkersMods.Admin.UserGroups.GetUserGroups(), StalkersMods.Admin.Config.UserGroupsFile)
end

-----------------------------------------------------------
-- StalkersMods.Admin.UserGroups.GenerateDefaultUserGroups
-----------------------------------------------------------
-- Desc:		Generates a table of default user groups in case none exist.
-- Returns:		Table, of default StalkersMods.Admin.UserGroup objects.
function StalkersMods.Admin.UserGroups.GenerateDefaultUserGroups()
	local defaultUserGroups = {}
	for groupName, genFunc in pairs(StalkersMods.Admin.Config.DefaultUserGroups) do
		defaultUserGroups[groupName] = genFunc()
	end

	return defaultUserGroups
end

-----------------------------------------------------------
-- StalkersMods.Admin.UserGroupsGenerateDefaultPlayerRanks
-----------------------------------------------------------
-- Desc:		Generates a table of default player ranks in case none exist.
-- Returns:		Table, of user groups.
function StalkersMods.Admin.UserGroupsGenerateDefaultPlayerRanks()
	return StalkersMods.Admin.Config.DefaultPlayerRanks
end

-----------------------------------------------------------------
-- StalkersMods.Admin.UserGroups.GetPlayerUserGroupNameBySteamID
-----------------------------------------------------------------
-- Desc:		Gets a user's usergroup by their SteamID, can return nil if unset!
-- Arg One:		String, steamID.
-- Returns:		String or nil, string if user group is found for player, nil if not.
function StalkersMods.Admin.UserGroups.GetPlayerUserGroupBySteamID(steamID)
	-- If they're in game get their player entity's steamid
	local ply = player.GetBySteamID(steamID)
	if StalkersMods.Utility.IsPlayerValidAndFullyAuthed(ply) then
		return ply:GetUserGroup()
	end

	-- Else check file
	return StalkersMods.Admin.GetOfflinePlayerUserGroupBySteamID(steamID)
end

--------------------------------------------------------------------
-- StalkersMods.Admin.UserGroups.SetOfflinePlayerUserGroupBySteamID
--------------------------------------------------------------------
-- Desc:		Sets the user group of a player in the offline ranks file and saves.
-- Arg One:		String, SteamID of player.
-- Arg Two:		String, user group name.
function StalkersMods.Admin.UserGroups.SetOfflinePlayerUserGroupBySteamID(steamID, userGroupName)
	StalkersMods.Admin.UserGroups.OfflineRanks[steamID] = userGroupName
	StalkersMods.Admin.UserGroups.WriteOfflinePlayerRanksFile()
end

--------------------------------------------------------------------
-- StalkersMods.Admin.UserGroups.GetOfflinePlayerUserGroupBySteamID
--------------------------------------------------------------------
-- Desc:		Gets the user group of a player in the offline ranks file.
-- Arg One:		String, SteamID of player.
-- Arg Two:		String, user group name.
function StalkersMods.Admin.UserGroups.GetOfflinePlayerUserGroupBySteamID(steamID)
	return StalkersMods.Admin.UserGroups.OfflineRanks[steamID]
end

-----------------------------------------------------------
-- StalkersMods.Admin.UserGroups.SetPlayerUserGroupAndSave
-----------------------------------------------------------
-- Desc:		Sets a user's usergroup by their 
-- Arg One:		Player, target.
-- Arg Two:		String, desired user group.
util.AddNetworkString("StalkersMods.Admin.PlayerUserGroupChanged")
function StalkersMods.Admin.UserGroups.SetPlayerUserGroupAndSave(ply, newGroup)
	local oldGroup = ply:GetUserGroup()
	ply:SetUserGroup(newGroup)
	StalkersMods.Admin.UserGroups.SetOfflinePlayerUserGroupBySteamID(ply:SteamID(), newGroup)
	
	net.Start("StalkersMods.Admin.PlayerUserGroupChanged")
		StalkersMods.Utility.WritePlayer(ply)
		net.WriteString(oldGroup)
		net.WriteString(newGroup)
	net.Broadcast()

	-- CAMI
	CAMI.SignalUserGroupChanged(ply, oldGroup, newGroup, StalkersMods.Admin.CAMI.AdminModName)
end

-------------------------------------------------------
-- StalkersMods.Admin.UserGroups.RemovePlayerUserGroup
-------------------------------------------------------
-- Desc:		Sets a user's user group back to the server default.
-- Arg One:		Player.
function StalkersMods.Admin.UserGroups.RemovePlayerUserGroup(ply)
	local defaultUserGroup = StalkersMods.Admin.UserGroups.GetDefaultUserGroup()
	StalkersMods.Admin.UserGroups.SetPlayerUserGroupAndSave(ply, defaultUserGroup)
end

------------------------------------------------
-- StalkersMods.Admin.UserGroups.SyncUserGroups
------------------------------------------------
-- Desc:		Networks all user groups to every client.
-- Arg One:		Player, table, or nil, player to send to one player, table for table of players, nil for broadcast.
util.AddNetworkString("StalkersMods.Admin.SyncUserGroups")
function StalkersMods.Admin.UserGroups.SyncUserGroups(recipients)
	local userGroupArray = {}
	for userGroupName, userGroup in pairs(StalkersMods.Admin.UserGroups.GetUserGroups()) do
		table.insert(userGroupArray, userGroupName)
	end

	net.Start("StalkersMods.Admin.SyncUserGroups")
		net.WriteUInt(#userGroupArray, StalkersMods.Admin.Config.NWUserGroupBits)
		for i = 1, #userGroupArray do
			StalkersMods.Admin.UserGroups.NetWriteUserGroup(userGroupArray[i])
		end
	if recipients == nil then
		net.Broadcast()
	else
		net.Send(recipients)
	end
end

------------------------------------------------
-- StalkersMods.Admin.UserGroups.SyncUserGroups
------------------------------------------------
-- Desc:		Networks the given user group to every client.
-- Arg One:		String, user group name.
-- Arg Two:		Player, table, or nil, player to send to one player, table for table of players, nil for broadcast.
util.AddNetworkString("StalkersMods.Admin.SyncUserGroup")
function StalkersMods.Admin.UserGroups.SyncUserGroup(userGroupName, recipients)
	net.Start("StalkersMods.Admin.SyncUserGroup")
		StalkersMods.Admin.UserGroups.NetWriteUserGroup(userGroupName)
	if recipients == nil then
		net.Broadcast()
	else
		net.Send(recipients)
	end
end

-------------------------------------------------------
-- StalkersMods.Admin.UserGroups.UserGroupAddPrivilege
-------------------------------------------------------
-- Desc:		Adds a privilege to the given user group.
-- Arg One:		String, name of user group.
-- Arg Two:		String, privilege name.
util.AddNetworkString("StalkersMods.Admin.AddPrivilege")
function StalkersMods.Admin.UserGroups.UserGroupAddPrivilege(userGroupName, privName)
	local userGroup = StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName)
	userGroup:GivePrivilege(privName)

	net.Start("StalkersMods.Admin.AddPrivilege")
		net.WriteString(userGroupName)
		net.WriteString(privName)
	net.Broadcast()
end

--------------------------------------------------------
-- StalkersMods.Admin.UserGroups.UserGroupTakePrivilege
--------------------------------------------------------
-- Desc:		Takes a privilege from the given user group.
-- Arg One:		String, name of user group.
-- Arg Two:		String, privilege name.
util.AddNetworkString("StalkersMods.Admin.RemovePrivilege")
function StalkersMods.Admin.UserGroups.UserGroupTakePrivilege(userGroupName, privName)
	local userGroup = StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName)
	userGroup:RevokePrivilege(privName)

	net.Start("StalkersMods.Admin.RemovePrivilege")
		net.WriteString(userGroupName)
		net.WriteString(privName)
	net.Broadcast()
end