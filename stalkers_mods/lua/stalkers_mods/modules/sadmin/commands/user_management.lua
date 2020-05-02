local CATEGORY = "User Management"

------------
-- Add User
------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "adduser",
	PrettyName = "Add User",
	Category = CATEGORY,
	Description = "Add user to the given group.",
	NeedsTargets = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or not isstring(args[1]) then
		StalkersMods.Admin.Notify(caller, "Missing user group argument.")
		return false
	end

	if not StalkersMods.Admin.UserGroups.UserGroupExists(args[1]) then
		StalkersMods.Admin.Notify(caller, {
			"Tried to set player(s) to non-existant user group '",
			{StalkersMods.Admin.ColEnums.ARGS, groupName},
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


---------------
-- Remove User
---------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "removeuser",
	PrettyName = "Remove User",
	Category = CATEGORY,
	Description = "Remove user from the given group.",
	NeedsTargets = true
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


------------------
-- Give Privilege
------------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "giveprivilege",
	PrettyName = "Give Privilege",
	Category = CATEGORY,
	Description = "Gives a usergroup privilege to run a command/privilege.",
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
			" to '",
			{StalkersMods.Admin.ColEnums.TARGET, args[1]},
			"'."
		})
	end
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)