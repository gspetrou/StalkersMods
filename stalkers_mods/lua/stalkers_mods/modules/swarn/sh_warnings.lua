StalkersMods.Warnings = StalkersMods.Warnings or {}

StalkersMods.Warnings.Privileges = {
	SYNC_ANY = {
		Name = "swarn_sync_any",
		MinAccess = "admin",
		Description = "User can view any user's warnings."
	},
	SYNC_SELF = {
		Name = "swarn_sync_self",
		MinAccess = "user",
		Description = "User can view thier own warnings."
	},
	ADD = {
		Name = "swarn_add",
		MinAccess = "admin",
		Description = "User can add a warning to any player."
	},
	DELETE = {
		Name = "swarn_delete",
		MinAccess = "admin",
		Description = "User can delete anyone's warning."
	}
}

for privID, camiPriv in pairs(StalkersMods.Warnings.Privileges) do
	CAMI.RegisterPrivilege(camiPriv)
end

function StalkersMods.Warnings.WriteWarning(warningObj)
	net.WriteString(warningObj:GetOwnerSteamID())
	net.WriteString(warningObj:GetOwnerNick())
	net.WriteString(warningObj:GetGivenBySteamID())
	net.WriteString(warningObj:GetGivenByNick())
	net.WriteString(warningObj:GetDescription())
	net.WriteString(tostring(warningObj:GetTimeStamp()))
end

function StalkersMods.Warnings.ReadWarning()
	return StalkersMods.Warnings.WarningClass:New({
		OwnerSteamID = net.ReadString(),
		OwnerNick = net.ReadString(),
		GivenBySteamID = net.ReadString(),
		GivenByNick = net.ReadString(),
		Description = net.ReadString(),
		TimeStamp = tonumber(net.ReadString())
	})
end

-- SAdmin Integration
hook.Add("StalkersMods.Admin.LoadCommands", "StalkersMods.SWarn.SAdminCommands", function()
	-- Warn
	local cmd = StalkersMods.Admin.Command:New{
		Name = "warn",
		PrettyName = "Warn",
		Category = "Utility",
		Description = "Warn the given player.",
		NeedsTargets = true,
		NoTargetIsSelf = false,
		HasNoArgs = false
	}
	function cmd:OnExecute(caller, args, targets, cmdStr)
		if not targets or #targets == 0 then
			StalkersMods.Admin.Notify(caller, "No target(s) found.")
			return false
		elseif #targets > 1 then
			StalkersMods.Admin.Notify(caller, "You can only warn one target at a time.")
			return false
		elseif not args or #args == 0 then
			StalkersMods.Admin.Notify(caller, "You must give a valid warning.")
			return false
		end

		local reason = ""
		for i, word in ipairs(args) do
			reason = reason.." "..word
		end
		reason = reason:sub(1, -1)

		if #reason == 0 then
			StalkersMods.Admin.Notify(caller, "You must give a valid warning.")
			return false
		end

		if SERVER then
			StalkersMods.Warnings.GiveOfflinePlayerWarning(targets[1]:SteamID(), IsValid(caller) and caller:SteamID() or "SERVER", reason)
		end

		StalkersMods.Admin.Notify(caller, {
			{StalkersMods.Admin.ColEnums.ARGS, "You"},
			" warned ",
			{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(targets)},
			"."
		})

		return true
	end
	StalkersMods.Admin.RegisterCommand(cmd)


	-- Warnid
	local cmd = StalkersMods.Admin.Command:New{
		Name = "warnid",
		PrettyName = "Warn ID",
		Category = "Utility",
		Description = "Warn the given steamid.",
		NeedsTargets = false,
		NoTargetIsSelf = false,
		HasNoArgs = false
	}
	function cmd:OnExecute(caller, args, targets, cmdStr)
		if not args or #args < 2 then
			StalkersMods.Admin.Notify(caller, "You must give a valid steamid and warning reason.")
			return false
		end

		local steamID = args[1]
		if not StalkersMods.Utility.IsSteamID32(steamID) then
			StalkersMods.Admin.Notify(caller, "Invalid SteamID.")
			return false
		end

		local reason = ""
		for i = 2, #args do
			reason = reason.." "..args[i]
		end
		reason = reason:sub(1, -1)

		if #reason == 0 then
			StalkersMods.Admin.Notify(caller, "You must give a valid reason.")
			return false
		end

		if SERVER then
			StalkersMods.Warnings.GiveOfflinePlayerWarning(steamID, IsValid(caller) and caller:SteamID() or "SERVER", reason)
		end

		StalkersMods.Admin.Notify(caller, {
			{StalkersMods.Admin.ColEnums.ARGS, "You"},
			" warned ",
			{StalkersMods.Admin.ColEnums.TARGET, steamID},
			"."
		})

		return true
	end
	StalkersMods.Admin.RegisterCommand(cmd)
end)