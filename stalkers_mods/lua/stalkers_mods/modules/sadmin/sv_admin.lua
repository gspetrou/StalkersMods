StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.Settings = StalkersMods.Admin.Settings or {}

concommand.Add("stalkermods_admin_clientready", function(ply)
	if not ply.stalkermods_admin_clientready then
		StalkersMods.Admin.UserGroups.SyncUserGroups(ply)
		ply.stalkermods_admin_clientready = true
	end
end)

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
	-- Load our user groups either from file or generated defaults, then register them.
	local grps
	if forceClean or StalkersMods.Utility.CreateFileIfNotExists(StalkersMods.Admin.Config.UserGroupsFile) then
		grps = StalkersMods.Admin.UserGroups.GenerateDefaultUserGroups()
		
	else
		grps = StalkersMods.Utility.LoadTableFromFile(StalkersMods.Admin.Config.UserGroupsFile)
	end
	for userGroupName, userGroup in pairs(grps) do
		StalkersMods.Admin.UserGroups.RegisterUserGroup(userGroup)
	end
	StalkersMods.Admin.UserGroups.Groups = grps

	-- Merge CAMI shit
	-- If a CAMI group isn't registered in our mod then add it.
	local camiGroups = CAMI.GetUsergroups()
	for camiGroupName, camiGroup in pairs(camiGroups) do
		if not StalkersMods.Admin.UserGroup.UserGroupExists(camiGroupName) then
			local userGroup = StalkersMods.Admin.UserGroup:New()
			userGroup:SetName(camiGroup.Name)
			userGroup:SetInherits(camiGroup.Inherits)
			StalkersMods.Admin.UserGroups.Groups[userGroup:GetName()] = userGroup
		end
	end
	-- If a CAMI privilege isn't assigned to its MinAccess group then assign it.
	local camiPrivs = CAMI.GetPrivileges()
	for camiPrivName, camiPriv in pairs(camiPrivs) do
		local minAccessGroupName = camiPrive.MinAccess
		if StalkersMods.Admin.UserGroup.UserGroupExists(minAccessGroupName) and not StalkersMods.Admin.UserGroups.UserGroupHasPrivilege(minAccessGroupName, camiPrive.Name) then
			StalkersMods.Admin.UserGroups.UserGroupAddPrivilege(minAccessGroupName, camiPriv.Name)
		end
	end

	StalkersMods.Admin.UserGroups.WriteOfflinePlayerRanksFile()

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

	-- If their group got delete or they dont have a group then assign them the default.
	if not userGroupName or not StalkersMods.Admin.UserGroup.UserGroupExists(userGroupName) then
		StalkersMods.Admin.UserGroups.SetPlayerUserGroupAndSave(ply, StalkersMods.Admin.GetDefaultUserGroup())
	else
		ply:SetUserGroup(userGroupName)
	end
end)