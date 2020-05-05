local CATEGORY = "User Management"
--[[
Contains:
	- Add user
	- Add userid
	- Remove user
	- Remove userid
	- Add privilege
	- Remove privilege
	- Add group
	- Remove group
]]--

------------
-- Add User
------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "adduser",
	PrettyName = "Add User",
	Category = CATEGORY,
	Description = "Add user to the given group.",
	ArgDescription = "<user group>",
	NeedsTargets = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or not isstring(args[1]) then
		StalkersMods.Admin.Notify(caller, 
			{StalkersMods.Admin.ColEnums.CMD, self:GetName()},
			" takes one arg: user group.")
		return false
	end

	if not StalkersMods.Admin.UserGroups.UserGroupExists(args[1]) then
		StalkersMods.Admin.Notify(caller, {
			"Tried to set player(s) to non-existant user group '",
			{StalkersMods.Admin.ColEnums.ARGS, args[1]},
			"'."
		})
		return false
	end

	if SERVER then
		for i, ply in ipairs(targets) do
			StalkersMods.Admin.UserGroups.SetPlayerUserGroupAndSave(ply, args[1])
		end
	end

	local targetStr = StalkersMods.Admin.TargetsToText(targets)
	StalkersMods.Admin.Notify(caller, {
		"Set rank(s) of '",
		{StalkersMods.Admin.ColEnums.TARGET, targetStr},
		"' to '",
		{StalkersMods.Admin.ColEnums.ARGS, args[1]},
		"'."
	})
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

--------------
-- Add UserID
--------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "adduserid",
	PrettyName = "Add UserID",
	Category = CATEGORY,
	Description = "Add user (by SteamID) to the given group.",
	ArgDescription = "<steamid32> <usergroup>",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args ~= 2 then
		StalkersMods.Admin.Notify(caller, 
			{StalkersMods.Admin.ColEnums.CMD, self:GetName()},
			" takes two args: steamid32 and usergroup")
		return false
	end

	if not StalkersMods.Utility.IsSteamID32(args[1]) then
		StalkersMods.Admin.Notify(caller, {
			"Invalid SteamID, expecting a SteamID in the form STEAM_X:Y:Z"
		})
		return false
	elseif not StalkersMods.Admin.UserGroups.UserGroupExists(args[2]) then
		StalkersMods.Admin.Notify(caller, {
			"Tried to set player to non-existant user group '",
			{StalkersMods.Admin.ColEnums.ARGS, args[2]},
			"'."
		})
		return false
	end

	if SERVER then
		StalkersMods.Admin.UserGroups.SetOfflinePlayerUserGroupBySteamID(args[1], args[2])
	end

	local targetStr = StalkersMods.Admin.TargetsToText(targets)
	StalkersMods.Admin.Notify(caller, {
		"Set SteamID '",
		{StalkersMods.Admin.ColEnums.TARGET, args[1]},
		"' to rank '",
		{StalkersMods.Admin.ColEnums.ARGS, args[2]},
		"'."
	})
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


---------------
-- Remove User
---------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "removeuser",
	PrettyName = "Remove User",
	Category = CATEGORY,
	Description = "Remove user from their given group.",
	NeedsTargets = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if SERVER then
		for i, ply in ipairs(targets) do
			StalkersMods.Admin.UserGroups.RemovePlayerUserGroup(ply)
		end

		local targetStr = StalkersMods.Admin.TargetsToText(targets)
		StalkersMods.Admin.Notify(caller, {
			"Removed rank(s) of '",
			{StalkersMods.Admin.ColEnums.TARGET, targetStr},
			"'."
		})
	end
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

-----------------
-- Remove UserID
-----------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "removeuserid",
	PrettyName = "Remove UserID",
	Category = CATEGORY,
	Description = "Remove user (by SteamID) from their group.",
	ArgDescription = "<steamid32>",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args ~= 1 then
		StalkersMods.Admin.Notify(caller,
			{StalkersMods.Admin.ColEnums.CMD, self:GetName()},
			" takes one arg: steamid32")
		return false
	end

	if not StalkersMods.Utility.IsSteamID32(args[1]) then
		StalkersMods.Admin.Notify(caller, {
			"Invalid SteamID, expecting a SteamID in the form STEAM_X:Y:Z"
		})
		return false
	end

	if SERVER then
		StalkersMods.Admin.UserGroups.SetOfflinePlayerUserGroupBySteamID(args[1], StalkersMods.Admin.UserGroups.GetDefaultUserGroup())
	end

	local targetStr = StalkersMods.Admin.TargetsToText(targets)
	StalkersMods.Admin.Notify(caller, {
		"Removed the rank of player with SteamID of '",
		{StalkersMods.Admin.ColEnums.TARGET, args[1]},
		"'.",
	})
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

------------------
-- Give Privilege
------------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "giveprivilege",
	PrettyName = "Give Privilege",
	Category = CATEGORY,
	Description = "Gives a usergroup privilege to run a command/privilege.",
	ArgDescription = "<usergroup> <command/privilege to give>",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args < 2 then
		StalkersMods.Admin.Notify(caller, {
			{StalkersMods.Admin.ColEnums.CMD, self:GetName()},
			" needs two args: user group name and privilege name."
		})
		return false
	end

	if not StalkersMods.Admin.UserGroups.UserGroupExists(args[1]) then
		StalkersMods.Admin.Notify(caller, {
			"Invalid group name '",
			{StalkersMods.Admin.ColEnums.ARGS, args[1]},
			"'."
		})
		return false
	end

	if SERVER then
		StalkersMods.Admin.UserGroups.UserGroupAddPrivilege(args[1], args[2])
		StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		StalkersMods.Admin.Notify(caller, {
			"Gave privilege '",
			{StalkersMods.Admin.ColEnums.ARGS, args[2]},
			"' to '",
			{StalkersMods.Admin.ColEnums.TARGET, args[1]},
			"'."
		})
	end
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

--------------------
-- Remove Privilege
--------------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "removeprivilege",
	PrettyName = "Remove Privilege",
	Category = CATEGORY,
	Description = "Takes a privilege from a given user group.",
	ArgDescription = "<usergroup> <command/privilege to take>",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args < 2 then
		StalkersMods.Admin.Notify(caller, {
			{StalkersMods.Admin.ColEnums.CMD, self:GetName()},
			" needs two args: user group name and privilege name."
		})
		return false
	end

	if not StalkersMods.Admin.UserGroups.UserGroupExists(args[1]) then
		StalkersMods.Admin.Notify(caller, {
			"Invalid group name '",
			{StalkersMods.Admin.ColEnums.ARGS, args[1]},
			"'."
		})
		return false
	end

	if SERVER then
		StalkersMods.Admin.UserGroups.UserGroupTakePrivilege(args[1], args[2])
		StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		StalkersMods.Admin.Notify(caller, {
			"Removed privilege '",
			{StalkersMods.Admin.ColEnums.ARGS, args[2]},
			" from '",
			{StalkersMods.Admin.ColEnums.TARGET, args[1]},
			"'."
		})
	end
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

-------------
-- Add Group
-------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "addgroup",
	PrettyName = "Add Group",
	Category = CATEGORY,
	Description = "Adds a user group.",
	ArgDescription = "<user group> <user group to inherit from=\"user\">",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args == 0 or #args > 2 then
		StalkersMods.Admin.Notify(caller, {
			{StalkersMods.Admin.ColEnums.CMD, self:GetName()},
			" needs at least one arg: UserGroup Name and (optionally) user group it inherits from."
		})
		return false
	end

	local newGroupName = args[1]
	local inheritsFromGroup = args[2]

	if not isstring(newGroupName) or #newGroupName == 0 then
		StalkersMods.Admin.Notify(caller, {
			"New user group name invalid!"
		})
		return false
	end
	if StalkersMods.Admin.UserGroups.UserGroupExists(newGroupName) then
		StalkersMods.Admin.Notify(caller, {
			"A group with the name '",
			{StalkersMods.Admin.ColEnums.ARGS, newGroupName},
			"' already exists!"
		})
		return false
	end
	if isstring(inheritsFromGroup) and not StalkersMods.Admin.UserGroups.UserGroupExists(inheritsFromGroup) then
		StalkersMods.Admin.Notify(caller, {
			"Tried to inherit from non-existant group '",
			{StalkersMods.Admin.ColEnums.ARGS, inheritsFromGroup},
			"'!"
		})
		return false
	end

	if SERVER then
		local newGroup = StalkersMods.Admin.Command:New()
		newGroup:SetName(newGroupName)
		if isstring(inheritsFromGroup) then
			newGroup:SetInherits(inheritsFromGroup)
		end
		StalkersMods.Admin.UserGroups.RegisterUserGroup(newGroup)
		StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		StalkersMods.Admin.UserGroups.SyncUserGroup(newGroup)

		StalkersMods.Admin.Notify(caller, {
			"Added usergroup '",
			{StalkersMods.Admin.ColEnums.ARGS, newGroupName},
			"'."
		})
	end
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

----------------
-- Remove Group
----------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "removegroup",
	PrettyName = "Remove Group",
	Category = CATEGORY,
	Description = "Removes a user group.",
	ArgDescription = "<usergroup>",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args ~= 2 then
		StalkersMods.Admin.Notify(caller, {
			{StalkersMods.Admin.ColEnums.CMD, self:GetName()},
			" needs at only one arg: UserGroup Name."
		})
		return false
	end

	if not isstring(args[1]) or #args[1] == 0 or not StalkersMods.Admin.UserGroups.UserGroupExists(args[1]) then
		StalkersMods.Admin.Notify(caller, {
			"User group '",
			{StalkersMods.Admin.ColEnums.ARGS, args[1]},
			"' does not exist!"
		})
		return false
	elseif args[1] == "user" or args[1] == "admin" or args[1] == "superadmin" then
		StalkersMods.Admin.Notify(caller, {
			"Default user groups user, admin, and superadmin cannot be removed!"
		})
		return false
	end

	if SERVER then
		StalkersMods.Admin.UserGroups.RemoveUserGroup(args[1])
		StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		StalkersMods.Admin.UserGroups.WriteOfflinePlayerRanksFile()	-- Connected players with this rank will switch to server default so save.
		StalkersMods.Admin.UserGroups.SyncUserGroupRemoval(args[1])

		StalkersMods.Admin.Notify(caller, {
			"Removed usergroup '",
			{StalkersMods.Admin.ColEnums.ARGS, args[1]},
			"'."
		})
	end
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)