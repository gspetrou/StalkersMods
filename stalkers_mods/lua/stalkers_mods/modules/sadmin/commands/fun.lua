local CATEGORY = "Fun"
--[[
Contains:
	- Slay
	- HP
	- Strip
	- God
	- Ungod
	- Freeze
	- Unfreeze
	- Cloak
	- Uncloak
]]--

--------
-- Slay
--------
local cmd = StalkersMods.Admin.Command:New{
	Name = "slay",
	PrettyName = "Slay",
	Category = CATEGORY,
	Description = "Slay the given player.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "Server, you are our god, you are immortal!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	for i, ply in ipairs(targets) do
		ply:Kill()
	end

	StalkersMods.Admin.Notify(caller, {
		"Slayed ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


--------
-- HP
--------
local cmd = StalkersMods.Admin.Command:New{
	Name = "hp",
	PrettyName = "Set Health",
	Category = CATEGORY,
	Description = "Set health of given player(s).",
	ArgDescription = "<number, health amount>",
	NeedsTargets = true,
	NoTargetIsSelf = false,	-- Make them use ^ to target themselves
	HasNoArgs = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "Server, you are our god, you are immortal!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	elseif not args or #args == 0 or not tonumber(args[1]) then
		StalkersMods.Admin.Notify(caller, "Tried setting to an invalid health amount.")
		return false
	elseif #args > 1 then
		StalkersMods.Admin.Notify(caller, "Too many arguments.")
		return false
	end

	local hp = tonumber(args[1])
	for i, ply in ipairs(targets) do
		ply:SetHealth(hp)
	end

	StalkersMods.Admin.Notify(caller, {
		"Set HP of ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		" to ",
		{StalkersMods.Admin.ColEnums.ARGS, args[1]},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


---------
-- Strip
---------
local cmd = StalkersMods.Admin.Command:New{
	Name = "strip",
	PrettyName = "Strip",
	Category = CATEGORY,
	Description = "Strips the given player.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "Server can't be stripped!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	for i, ply in ipairs(targets) do
		if ply:Alive() then
			ply:StripWeapons()
			ply:StripAmmo()
		end
	end

	StalkersMods.Admin.Notify(caller, {
		"Stripped ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


-------
-- God
-------
local cmd = StalkersMods.Admin.Command:New{
	Name = "god",
	PrettyName = "God",
	Category = CATEGORY,
	Description = "Makes given player invincible.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "Server can't be godded!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	local whoToNofify = {}
	for i, ply in ipairs(targets) do
		ply:GodEnable()

		if caller ~= ply then
			table.insert(whoToNofify, ply)
		end
	end
	if #whoToNofify > 0 then
		StalkersMods.Admin.Notify(whoToNofify, "You have been godded.")
	end

	StalkersMods.Admin.Notify(caller, {
		"Godded ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


---------
-- Ungod
---------
local cmd = StalkersMods.Admin.Command:New{
	Name = "ungod",
	PrettyName = "Ungod",
	Category = CATEGORY,
	Description = "Removes the given players invincibility.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't be ungodded, it is god!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	local whoToNofify = {}
	for i, ply in ipairs(targets) do
		ply:GodDisable()

		if caller ~= ply then
			table.insert(whoToNofify, ply)
		end
	end
	if #whoToNofify > 0 then
		StalkersMods.Admin.Notify(whoToNofify, "You have been ungodded.")
	end

	StalkersMods.Admin.Notify(caller, {
		"Ungodded ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


----------
-- Freeze
----------
local cmd = StalkersMods.Admin.Command:New{
	Name = "freeze",
	PrettyName = "Freeze",
	Category = CATEGORY,
	Description = "Freezes the given player.",
	NeedsTargets = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't freeze!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	local whoToNofify = {}
	for i, ply in ipairs(targets) do
		if ply:InVehicle() then
			ply:ExitVehicle()
		end
		ply:Lock()
		ply.stalkersmods_admin_isfrozen = true

		if caller ~= ply then
			table.insert(whoToNofify, ply)
		end
	end
	if #whoToNofify > 0 then
		StalkersMods.Admin.Notify(whoToNofify, "You have been frozen.")
	end

	StalkersMods.Admin.Notify(caller, {
		"Froze ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
if SERVER then
	hook.Add("CanPlayerSuicide", "StalkersMods.Admin.CanSuicideOnFreeze", function(ply)
		if ply.stalkersmods_admin_isfrozen then
			StalkersMods.Admin.Notify(ply, "You cannot suicide while frozen.")
			return false
		end
	end)
end
StalkersMods.Admin.RegisterCommand(cmd)


------------
-- Unfreeze
------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "unfreeze",
	PrettyName = "Unfreeze",
	Category = CATEGORY,
	Description = "Unfreezes the given player.",
	NeedsTargets = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't freeze or unfreeze!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	local whoToNofify = {}
	for i, ply in ipairs(targets) do
		ply:UnLock()
		ply.stalkersmods_admin_isfrozen = false

		if caller ~= ply then
			table.insert(whoToNofify, ply)
		end
	end
	if #whoToNofify > 0 then
		StalkersMods.Admin.Notify(whoToNofify, "You have been unfrozen.")
	end

	StalkersMods.Admin.Notify(caller, {
		"Unfroze ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


---------
-- Cloak
---------
local cmd = StalkersMods.Admin.Command:New{
	Name = "cloak",
	PrettyName = "Cloak",
	Category = CATEGORY,
	Description = "Makes the given player invisible.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server is omnipotent and thus cannot be cloaked!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	local whoToNofify = {}
	for i, ply in ipairs(targets) do
		ply.stalkersmods_admin_iscloaked = true
		ply:SetNoDraw(true)
		if ply ~= caller then
			table.insert(whoToNofify, ply)
		end
	end
	if #whoToNofify > 0 then
		StalkersMods.Admin.Notify(whoToNofify, "You are now invisible.")
	end

	StalkersMods.Admin.Notify(caller, {
		"Cloaked ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


-----------
-- Uncloak
-----------
local cmd = StalkersMods.Admin.Command:New{
	Name = "uncloak",
	PrettyName = "Uncloak",
	Category = CATEGORY,
	Description = "Uncloaks the given player.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server is omnipotent and thus cannot be uncloaked!")
		return false
	elseif not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "No target(s) found.")
		return false
	end

	local whoToNofify = {}
	for i, ply in ipairs(targets) do
		ply:SetNoDraw(false)
		ply.stalkersmods_admin_iscloaked = false
		if ply ~= caller then
			table.insert(whoToNofify, ply)
		end
	end
	if #whoToNofify > 0 then
		StalkersMods.Admin.Notify(whoToNofify, "You are no longer invisible.")
	end

	StalkersMods.Admin.Notify(caller, {
		"Uncloaked ",
		{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)
if SERVER then
	hook.Add("PostPlayerDeath", "StalkersMods.Admin.UncloakOnDeath", function(ply)
		if ply.stalkersmods_admin_iscloaked then
			ply:ConCommand("sadmin uncloak ^")
			ply.stalkersmods_admin_iscloaked = false
		end
	end)
end