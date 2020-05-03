local CATEGORY = "Utility"
--[[
Contains:
	- Ban
	- BanID
	- Unban
	- Kick
	- Map
	- Help
]]--

------------
-- Ban User
------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "ban",
	PrettyName = "Ban",
	Category = CATEGORY,
	Description = "Bans the given user.",
	NeedsTargets = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(targets) or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "Invalid target(s) to ban.")
		return false
	end

	local bannedBy
	local length = 0
	local reason

	if #args > 0 then
		if tonumber(args[1]) then
			length = tonumber(args[1])
			if args[2] then
				reason = ""
				for i = 2, #args do
					reason = reason..args[i].." "
				end
				reason = reason:sub(1, -1)
			end
		else
			reason = ""
			for i = 1, #args do
				reason = reason..args[i].." "
			end
			reason = reason:sub(1, -1)
		end
	end

	if IsValid(caller) then
		bannedBy = caller
	end

	if SERVER then
		for i, ply in ipairs(targets) do
			StalkersMods.Admin.BanPlayer(ply, length, reason, bannedBy)
		end
	end

	local targetStr = StalkersMods.Admin.TargetsToText(targets)
	StalkersMods.Admin.Notify(caller, {
		"Banned '",
		{StalkersMods.Admin.ColEnums.TARGET, targetStr},
		"' for time ",
		{StalkersMods.Admin.ColEnums.ARGS, length == 0 and "Permament" or StalkersMods.Utility.SecondsToTimeLeft(length)},
		" with reason '",
		{StalkersMods.Admin.ColEnums.ARGS, reason or "No reason given."},
		"'."
	})
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


----------
-- Ban ID
----------
local cmd = StalkersMods.Admin.Command:New{
	Name = "banid",
	PrettyName = "Bans UserID",
	Category = CATEGORY,
	Description = "Bans the given user's SteamID.",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args == 0 or not StalkersMods.Utility.IsSteamID32(args[1]) then
		StalkersMods.Admin.Notify(caller, "Invalid input, expected SteamID32.")
		return false
	end

	local target = args[1]
	local bannedBy
	local length = 0
	local reason

	if #args > 1 then
		if tonumber(args[2]) then
			length = tonumber(args[2])
			if args[3] then
				reason = ""
				for i = 3, #args do
					reason = reason..args[i].." "
				end
				reason = reason:sub(1, -1)
			end
		else
			reason = ""
			for i = 2, #args do
				reason = reason..args[i].." "
			end
			reason = reason:sub(1, -1)
		end
	end

	if IsValid(caller) then
		bannedBy = caller:SteamID()
	end

	if SERVER then
		for i, ply in ipairs(targets) do
			StalkersMods.Admin.BanSteamID(target, length, reason, bannedBy)
		end
	end

	local targetStr = StalkersMods.Admin.TargetsToText(targets)
	StalkersMods.Admin.Notify(caller, {
		"Banned '",
		{StalkersMods.Admin.ColEnums.TARGET, target},
		"' for time: ",
		{StalkersMods.Admin.ColEnums.ARGS, length == 0 and "Permament" or StalkersMods.Utility.SecondsToTimeLeft(length)},
		"."
	})
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


--------
-- Kick
--------
local cmd = StalkersMods.Admin.Command:New{
	Name = "kick",
	PrettyName = "Kick",
	Category = CATEGORY,
	Description = "Kicks the given user.",
	NeedsTargets = true
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(targets) or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "Invalid target.")
		return false
	end

	local reason = "No reason given."
	if #args > 0 then
		reason = ""
		for i, word in ipairs(args) do
			reason = reason..word.." "
		end
		reason = reason:sub(1, -1)
	end

	for i, ply in ipairs(targets) do
		ply:Kick(reason)
	end

	local targetStr = StalkersMods.Admin.TargetsToText(targets)
	StalkersMods.Admin.Notify(caller, {
		"Kicked '",
		{StalkersMods.Admin.ColEnums.TARGET, targetStr},
		"' with reason '",
		{StalkersMods.Admin.ColEnums.ARGS, reason},
		"'."
	})
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


-------
-- Map
-------
local cmd = StalkersMods.Admin.Command:New{
	Name = "map",
	PrettyName = "Set Map",
	Category = CATEGORY,
	Description = "Changes the server to the given map.",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not istable(args) or #args == 0 or not file.Exists("maps/"..args[1]..".bsp", "GAME") then
		StalkersMods.Admin.Notify(caller, {
			"Invalid map '",
			{StalkersMods.Admin.ColEnums.ARGS, args[1]},
			"'."
		})
		return false
	end

	StalkersMods.Admin.Notify(caller, {
		"Changing map to '",
		{StalkersMods.Admin.ColEnums.ARGS, args[1]},
		"' in 5 seconds."
	})

	timer.Simple(5, function()
		RunConsoleCommand("changelevel", args[1])
	end)

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

--------
-- Help
--------
local cmd = StalkersMods.Admin.Command:New{
	Name = "help",
	PrettyName = "Help",
	Category = CATEGORY,
	Description = "Displays helpful info about the admin mod.",
	NeedsTargets = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "Check your console for helpful info.")
		if SERVER then
			net.Start("StalkersMods.Admin.PrintHelp")
			net.Send(caller)
		end
	else
		StalkersMods.Admin.PrintHelp()
	end

	return true
end
if SERVER then
	util.AddNetworkString("StalkersMods.Admin.PrintHelp")
else
	net.Receive("StalkersMods.Admin.PrintHelp", function()
		timer.Simple(0.1, StalkersMods.Admin.PrintHelp)
	end)
end
StalkersMods.Admin.RegisterCommand(cmd)