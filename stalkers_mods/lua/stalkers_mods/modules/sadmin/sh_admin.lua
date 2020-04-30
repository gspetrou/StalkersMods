StalkersMods.Admin = StalkersMods.Admin or {}

-- CAMI Relevant Data
StalkersMods.Admin.CAMI = StalkersMods.Admin.CAMI or {}
StalkersMods.Admin.CAMI.AdminModName = "sadmin"

hook.Add("Initialize", "StalkersMods.Admin.Initialize", function()
	if SERVER then
		-- Remove gmod's built in rank system.
		hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn")
		StalkersMods.Admin.LoadDataFiles()
	end

	if SERVER then
		StalkersMods.Admin.Initialized = true
	end
end)

--------------------
-- CAMI Conformance
--------------------
hook.Add("CAMI.OnUsergroupRegistered", "StalkersMods.Admin.CAMIOnRegisterGroup", function(camiGroup, src)
	if not StalkersMods.Admin.Initialized or StalkersMods.Admin.CAMI.AdminModName == src then
		return
	end

	if not StalkersMods.Admin.UserGroup.UserGroupExists(camiGroup.Name) then
		local newGroup = StalkersMods.Admin.UserGroup:New()
		newGroup:SetName(camiGroup.Name)
		newGroup:SetInherits(camiGroup.Inherits)
		StalkersMods.Admin.UserGroups.Groups[camiGroup.Name] = newGroup

		if SERVER then
			StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		end
	end
end)

hook.Add("CAMI.OnUsergroupUnregistered", "StalkersMods.Admin.CAMIOnUnRegisterGroup", function(camiGroup, src)
	if not StalkersMods.Admin.Initialized or StalkersMods.Admin.CAMI.AdminModName == src then
		return
	end

	if StalkersMods.Admin.UserGroup.UserGroupExists(camiGroup.Name) then
		StalkersMods.Admin.UserGroups.RemoveUserGroup(camiGroup.Name)

		if SERVER then
			StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		end
	end
end)

hook.Add("CAMI.PlayerUsergroupChanged", "StalkersMods.Admin.CAMIPlayerGroupChanged", function(ply, from, to, src)
	if src == StalkersMods.Admin.CAMI.AdminModName then
		return
	end

	-- Their user group is already changed so just set their offline group.
	if SERVER then
		StalkersMods.Admin.UserGroups.SetOfflinePlayerUserGroupBySteamID(ply:SteamID(), to)
	end
end)

hook.Add("CAMI.OnPrivilegeRegistered", "StalkersMods.Admin.CAMIOnPrivilegeRegistered", function(camiPriv)
	if not StalkersMods.Admin.Initialized then
		return
	end

	StalkersMods.Admin.UserGroups.Groups[camiPriv.MinAccess]:GivePrivilege(camiPriv.Name)
	if SERVER then
		StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
	end
end)

hook.Add("CAMI.OnPrivilegeUnregistered", "StalkersMods.Admin.CAMIOnPrivilegeUnRegistered", function(camiPriv)
	if not StalkersMods.Admin.Initialized then
		return
	end

	local minAccessGroup = StalkersMods.Admin.UserGroups[camiPriv.MinAccess]
	if minAccessGroup then
		minAccessGroup:RevokePrivilege(camiPriv.Name)
		if SERVER then
			StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		end
	end
end)

hook.Add("CAMI.PlayerHasAccess", "StalkersMods.Admin.CAMIPlayerHasAccess", function(caller, privilege, cb)
	cb(StalkersMods.Admin.UserGroups.UserHasPrivilege(caller, privilege))
	return true
end)