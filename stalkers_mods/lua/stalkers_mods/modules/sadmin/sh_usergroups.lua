StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.UserGroups = StalkersMods.Admin.UserGroups or {}
StalkersMods.Admin.UserGroups.Groups = StalkersMods.Admin.UserGroups.Groups or {}

-- CAMI Relevant Data
StalkersMods.Admin.CAMI = {}
StalkersMods.Admin.CAMI.AdminModName = "sadmin"
StalkersMods.Admin.CAMI.DefaultGroups = {"superadmin", "admin", "user"}

---------------------------------------------------
-- StalkersMods.Admin.UserGroups.NetWriteUserGroup
---------------------------------------------------
-- Desc:		To be called while networking, write a user group.
-- Arg One:		String, name of user group.
function StalkersMods.Admin.UserGroups.NetWriteUserGroup(userGroupName)
	local userGroup = StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName)
	net.WriteString(userGroup.Name)
	net.WriteString(userGroup.PrettyName)
	net.WriteString(userGroup.Inherits)
	StalkersMods.Utility.NetWriteNumericArray(userGroup.Privileges, StalkersMods.Admin.Config.NWPrivilegeBits, net.WriteString)
end

--------------------------------------------------
-- StalkersMods.Admin.UserGroups.NetReadUserGroup
--------------------------------------------------
-- Desc:		To be called while networking, reads a user group.
-- Returns:		StalkersMods.Admin.UserGroup object, of user group data.
function StalkersMods.Admin.UserGroups.NetReadUserGroup()
	local userGroup = StalkersMods.Admin.UserGroup:New()
	userGroup:SetName(net.ReadString())
	userGroup:SetPrettyName(net.ReadString())
	userGroup:SetInherits(net.ReadString())
	userGroup:SetPrivileges(StalkersMods.Utility.NetReadNumericArray(StalkersMods.Admin.Config.NWPrivilegeBits, net.ReadString))

	return userGroup
end

-------------------------------------------------------
-- StalkersMods.Admin.UserGroups.UserGroupHasPrivilege
-------------------------------------------------------
-- Desc:		Can the given user group execute the given command. Returns false if user group doesn't exist btw.
-- Arg One:		String, user group name.
-- Arg Two:		String, privilege name.
-- Returns:		Boolean, can they execute.
local function userGroupHasPrivilege(userGroupName, privName, checked)
	if checked[userGroupName] then
		StalkersMods.Logging.LogError("There is cyclical user group inheritance involving group '"..userGroupName.."'!" , true)
	end

	local userGroup = StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName)
	if not userGroup then
		return false
	end

	-- First check our immediate rank's privileges.
	for i, curPriv in ipairs(userGroup:GetPrivileges()) do
		if privName == curPriv then
			return true
		end
	end

	checked[userGroupName] = true

	-- Then check the privileges of rank we inherit from.
	if userGroup:GetInherits() ~= "" then
		return userGroupHasPrivilege(userGroup:GetInherits(), privName, checked)
	end

	return false
end
function StalkersMods.Admin.UserGroups.UserGroupHasPrivilege(userGroupName, privName)
	local checked = {}
	return userGroupHasPrivilege(userGroupName, privName, checked)
end

--------------------------------------------------
-- StalkersMods.Admin.UserGroups.UserHasPrivilege
--------------------------------------------------
-- Desc:		Can the given player execute the given privilege.
-- Arg One:		Player
-- Returns:		Boolean
function StalkersMods.Admin.UserGroups.UserHasPrivilege(ply, privName)
	return IsValid(ply) and ply:IsPlayer()
		and StalkersMods.Admin.UserGroups.UserGroupHasPrivilege(ply:GetUserGroup(), privName)
end

---------------------------------------------------------
-- StalkersMods.Admin.UserGroups.GetPlayersWithPrivilege
---------------------------------------------------------
-- Desc:		Returns all players with a given privilege.
-- Arg One:		String, privilege name.
-- Returns:		Table of players.
function StalkersMods.Admin.UserGroups.GetPlayersWithPrivilege(privName)
	local out = {}
	for i, ply in ipairs(player.GetAll()) do
		if StalkersMods.Admin.UserGroups.UserHasPrivilege(ply, privName) then
			table.insert(out, ply)
		end
	end
	return out
end

-----------------------------------------------
-- StalkersMods.Admin.UserGroups.GetUserGroups
-----------------------------------------------
-- Desc:		Gets the user group table.
-- Returns:		Table, of StalkersMods.Admin.UserGroup objects.
function StalkersMods.Admin.UserGroups.GetUserGroups()
	return StalkersMods.Admin.UserGroups.Groups
end

----------------------------------------------
-- StalkersMods.Admin.UserGroups.GetUserGroup
----------------------------------------------
-- Desc:		Gets a user group given its name.
-- Returns:		StalkersMods.Admin.UserGroup object
function StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName)
	return StalkersMods.Admin.UserGroups.GetUserGroups()[userGroupName]
end

-------------------------------------------------
-- StalkersMods.Admin.UserGroups.UserGroupExists
-------------------------------------------------
-- Desc:		Sees if the given user group exists.
-- Arg One:		String, id of group to see if it exists.
-- Returns:		Boolean.
function StalkersMods.Admin.UserGroups.UserGroupExists(userGroupName)
	return istable(StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName))
end

---------------------------------------------------
-- StalkersMods.Admin.UserGroups.RegisterUserGroup
---------------------------------------------------
-- Desc:		Registers the given group with the admin mod.
-- Arg One:		StalkersMods.Admin.UserGroup object
function StalkersMods.Admin.UserGroups.RegisterUserGroup(userGroup)
	local name = userGroup:GetName()
	StalkersMods.Admin.UserGroups.Groups[userGroup:GetName()] = userGroup

	-- CAMI
	local inherits = userGroup:GetInherits()
	if inherits == "" then inherits = "user" end
	CAMI.RegisterUsergroup({Name = name, Inherits = inherits}, StalkersMods.Admin.CAMI.AdminModName)
end

-------------------------------------------------
-- StalkersMods.Admin.UserGroups.RemoveUserGroup
-------------------------------------------------
-- Desc:		Removes the given user group from the admin mod. You cannot remove user, admin, or superadmin!
-- Arg One:		String, user group name.
function StalkersMods.Admin.UserGroups.RemoveUserGroup(userGroupName)
	for i, defaultGroup in ipairs(StalkersMods.Admin.CAMI.DefaultGroups) do
		if userGroupName == defaultGroup then
			StalkersMods.Logging.LogError("Tried to remove default usergroup '"..userGroupName.."'!" , true)
		end
	end

	StalkersMods.Admin.UserGroups.Groups[userGroupName] = nil

	-- CAMI
	CAMI.UnregisterUsergroup(userGroupName, StalkersMods.Admin.CAMI.AdminModName)

	if SERVER then
		for i, ply in ipairs(StalkersMods.Admin.UserGroups.GetPlayersByUserGroup(userGroupName)) do
			StalkersMods.Admin.UserGroups.RemovePlayerUserGroup(ply)
		end
	end
end

-------------------------------------------------------
-- StalkersMods.Admin.UserGroups.GetPlayersByUserGroup
-------------------------------------------------------
-- Desc:		Gets all online players with the given user group name
function StalkersMods.Admin.UserGroups.GetPlayersByUserGroup(groupName)
	local out = {}
	for i, ply in ipairs(player.GetAll()) do
		if ply:GetUserGroup() == groupName then
			table.insert(out, ply)
		end
	end
	return out
end