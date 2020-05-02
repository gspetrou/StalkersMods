StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.Commands = StalkersMods.Admin.Commands or {}
StalkersMods.Admin.CommandPrefix = "sadmin"

--------------------------------------
-- StalkersMods.Admin.RegisterCommand
--------------------------------------
-- Desc:		Registers a new command with the admin mod.
-- Arg One:		StalkersMods.Admin.Command object, to register with admin mod.
function StalkersMods.Admin.RegisterCommand(cmdObj)
	StalkersMods.Admin.Commands[cmdObj:GetName()] = cmdObj
end

-------------------------------------
-- StalkersMods.Admin.GetAllCommands
-------------------------------------
-- Desc:		Returns a table of all registered StalkersMods.Admin.Command objects.
-- Returns:		Table, of StalkersMods.Admin.Command objects
function StalkersMods.Admin.GetAllCommands()
	return StalkersMods.Admin.Commands
end

---------------------------------------
-- StalkersMods.Admin.GetCommandByName
---------------------------------------
-- Desc:		Gets a StalkersMods.Admin.Command object given its name.
-- Returns:		StalkersMods.Admin.Command object
function StalkersMods.Admin.GetCommandByName(name)
	return StalkersMods.Admin.GetAllCommands()[name]
end

------------------------------------
-- StalkersMods.Admin.CommandExists
------------------------------------
-- Desc:		Sees if a command exists given its name.
-- Arg One:		String, name of command.
-- Returns:		Boolean, does the given command exist.
function StalkersMods.Admin.CommandExists(name)
	return tobool(StalkersMods.Admin.Commands[name])
end

-----------------------------------
-- StalkersMods.Admin.LoadCommands
-----------------------------------
-- Desc:		Loads the commands folder.
function StalkersMods.Admin.LoadCommands()
	StalkersMods.Utility.IncludeFolder(StalkersMods.AddonFolder.."/modules/sadmin/commands", true, 1)
	hook.Call("StalkersMods.Admin.LoadCommands")

	-- Register concommand
	concommand.Add(StalkersMods.Admin.CommandPrefix, function(ply, cmd, args, argStr)
		if SERVER then
			StalkersMods.Admin.ValidateAndRunCommand(ply, argStr)
		else
			print(argStr)
			net.Start("StalkersMods.Admin.TryCmd")
				net.WriteString(argStr)
			net.SendToServer()
		end		
	end)
end

function StalkersMods.Admin.ValidateAndRunCommand(ply, cmdStr)
	if cmdStr[1] == "!" or cmdStr[1] == "/" then
		cmdStr = string.sub(cmdStr, 1)
	end

	local cmdObj, targets, args = StalkersMods.Admin.GetCommandAndArgsFromString(ply, cmdStr)
	if not cmdObj then
		return
	end

	local success = false
	if not IsValid(ply) or StalkersMods.Admin.UserGroups.UserHasPrivilege(ply, cmdObj:GetName()) then
		success = cmdObj:OnExecute(ply, args, targets, cmdStr)

		local nameSteamID = IsValid(ply) and "'"..ply:Nick().."' ("..ply:SteamID()..")" or "SERVER"
		StalkersMods.Logging.LogGeneral("[SAdmin] Player "..nameSteamID.." ran command '"..tostring(cmdObj:GetName()).."'.")
	else
		StalkersMods.Logging.LogSecurity("[SAdmin] Player '"..ply:Nick().."' ("..ply:SteamID()..") tried running '"..tostring(cmdObj:GetName()).."' which they dont have access to as rank '"..ply:GetUserGroup().."'.")
		
		StalkersMods.Admin.Notify(ply,{
			"Your rank '",
			{StalkersMods.Admin.ColEnums.ARGS, ply:GetUserGroup()},
			"' does not have access to the command '",
			{StalkersMods.Admin.ColEnums.CMD, tostring(cmdObj:GetName())},
			"'!"
		})
	end
	
	return success
end

----------------------------------------------
-- StalkersMods.Admin.GetPlayersByTargetQuery
----------------------------------------------
-- Desc:		Tries to get a player or group of players given a search query.
-- 				Reminder, names cant be 1 letter long so we reserve some here for selectors.
-- Arg One:		Player, calling. Can be nil, or NULL for server.
-- Arg Two:		String, query.
-- Arg Three:	Boolean=false, should silence error messages.
-- Returns:		Table of players, or nil.
function StalkersMods.Admin.GetPlayersByTargetQuery(ply, query, silence)
	if not query or query == "" then
		StalkersMods.Admin.Notify(ply, "Invalid player input!")
		return
	end

	-- All
	if query == "*" then
		return player.GetAll()
	-- Self
	elseif query == "^" then
		return {ply}
	-- Everyone but self
	elseif query == "!" then
		if not ply then
			return player.GetAll()
		end
		local out = player.GetAll()
		for i, v in ipairs(out) do
			if v == out then
				table.remove(out, i)
				return out
			end
		end
	-- Bots
	elseif query == "b" then
		return player.GetBots()
	-- Humans
	elseif query == "b" then
		return player.GetHumans()
	-- Eye target
	elseif query == "t" then
		if IsValid(ply) then
			local tr = ply:GetEyeTraceNoCursor()
			if tr.Entity and IsValid(tr.Entity) and tr.Entity:IsPlayer() then
				return {target}
			end
		end
		return
	end

	-- SteamID32
	local plyBySteamID32 = player.GetBySteamID(query)
	if plyBySteamID32 then return {plyBySteamID32} end

	-- SteamID64
	local plyBySteamID64 = player.GetBySteamID64(query)
	if plyBySteamID64 then return {plyBySteamID64} end

	-- Check names (only from start of name)
	-- Example: User "Stalker", "alker" will fail but "Sta" will find
	local strongestTargets = {}
	local strongestTargetLen = 0
	for i, v in ipairs(player.GetAll()) do
		local q = string.lower(query)
		local targName = string.lower(v:Nick())
		local startPos, endPos = string.find(targName, q, 1, true)
		local addedSelf = false
		if isnumber(startPos) and isnumber(endPos) and startPos == 1 then
			if endPos - startPos > strongestTargetLen then
				strongestTargets = {v}
				strongestTargetLen = endPos - startPos
			elseif endPos - startPos == strongestTargetLen then
				table.insert(strongestTargets, v)
				addedSelf = true
			end
		end

		local rpName = v.getDarkRPVar and v:getDarkRPVar("rpname") or false
		if rpName then
			startPos, endPos = string.find(rpName, q, 1, true)
			if isnumber(startPos) and isnumber(endPos) and startPos == 1 then
				if endPos - startPos > strongestTargetLen then
					strongestTargets = {v}
					strongestTargetLen = endPos - startPos
				elseif endPos - startPos == strongestTargetLen and not addedSelf then
					table.insert(strongestTargets, v)
				end
			end
		end
	end
	if #strongestTargets == 1 then
		return {strongestTargets[1]}
	elseif #strongestTargets > 1 then
		if not silence then
			StalkersMods.Admin.Notify(ply, "Multiple targets found!")
			return
		end
	end

	if not silence then
		StalkersMods.Admin.Notify(ply, "No targets found!")
		return
	end
end

--------------------------------------------------
-- StalkersMods.Admin.GetCommandAndArgsFromString
--------------------------------------------------
-- Desc:		Given a string of text tries to determine if its a command and its args/targets.
-- Arg One:		Player, calling player, NULL for server.
-- Arg Two:		String, text to examine.
-- Return 1:	StalkersMods.Admin.Command object or nil, if failed.
-- Return 2:	Table, of players.
-- Return 3:	Table, table of string args.
function StalkersMods.Admin.GetCommandAndArgsFromString(ply, text)
	if not text then
		return
	end

	text = string.Trim(text)
	if #text == 0 then
		return
	end

	if text[1] == "!" or text[1] == "/" then
		text = string.sub(text, 2)
		if #text == 0 then
			return
		end
	end

	local explodedText = string.Explode(" ", text)
	local cmdObj = StalkersMods.Admin.GetCommandByName(explodedText[1])
	if not cmdObj then
		StalkersMods.Admin.Notify(ply, "Invalid command.")
		return
	end

	-- Remove cmdObj from explodedText now that we found it
	table.remove(explodedText, 1)

	-- Found command and has no target, so the remainder must just be args.
	if not cmdObj:GetNeedsTargets() then
		return cmdObj, nil, explodedText
	end

	-- Next text is target.
	local rawTargetQuery = table.remove(explodedText, 1)
	local targets = StalkersMods.Admin.GetPlayersByTargetQuery(ply, rawTargetQuery)
	if not istable(targets) or #targets == 0 then
		return
	end

	-- Remaining text is args.
	local args = explodedText
	if not args or #args == 0 then
		return cmdObj, targets, nil
	end

	return cmdObj, targets, args
end