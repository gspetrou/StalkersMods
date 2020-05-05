local CATEGORY = "RCON"
--[[
Contains:
	- Rcon
	- Run Lua
	- Run Client Lua
	- Entity
]]--


--------
-- RCON
--------
local cmd = StalkersMods.Admin.Command:New{
	Name = "rcon",
	PrettyName = "Remote Console",
	Category = CATEGORY,
	Description = "Send commands to the server console.",
	ArgDescription = "<console command>",
	NeedsTargets = false,
	HasNoArgs = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	local firstSpace
	for i = 1, #cmdStr do
		if cmdStr[i] == " " then
			firstSpace = i
			break
		end
	end

	if not firstSpace then
		StalkersMods.Admin.Notify(caller, "Invalid command.")
		return false
	end

	local cmdText = string.sub(cmdStr, firstSpace + 1)
	if not cmdText or cmdText == 0 then
		StalkersMods.Admin.Notify(caller, "Invalid command.")
		return false
	end

	game.ConsoleCommand(cmdText.."\n")
	StalkersMods.Admin.Notify(caller, "Ran RCON command.")
	StalkersMods.Logging.LogSecurity(
		(IsValid(caller) and (caller:Nick().." ("..caller:SteamID()..")") or "SERVER").." ran command on server:\n"..cmdText)
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


-----------
-- Run Lua
-----------
local cmd = StalkersMods.Admin.Command:New{
	Name = "runlua",
	PrettyName = "Run Lua",
	Category = CATEGORY,
	Description = "Run lua on the server.",
	ArgDescription = "<serverside lua code>",
	NeedsTargets = false,
	HasNoArgs = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	local firstSpace
	for i = 1, #cmdStr do
		if cmdStr[i] == " " then
			firstSpace = i
			break
		end
	end

	if not firstSpace then
		StalkersMods.Admin.Notify(caller, "Invalid lua.")
		return false
	end

	local lua = string.sub(cmdStr, firstSpace + 1)
	if not lua or lua == 0 then
		StalkersMods.Admin.Notify(caller, "Invalid lua.")
		return false
	end

	RunString(lua)
	StalkersMods.Admin.Notify(caller, "Ran Lua on server.")
	StalkersMods.Logging.LogSecurity(
		(IsValid(caller) and (caller:Nick().." ("..caller:SteamID()..")") or "SERVER").." ran lua on server:\n"..lua)
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)

------------------
-- Run Client Lua
------------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "runluacl",
	PrettyName = "Run Client Lua",
	Category = CATEGORY,
	Description = "Run lua a client.",
	ArgDescription = "<clientside lua code>",
	NeedsTargets = true,
	HasNoArgs = false
}
function cmd:OnExecute(caller, args, targets, cmdStr)
	if not targets or #targets == 0 then
		StalkersMods.Admin.Notify(caller, "Invalid target(s).")
		return false
	elseif not args or #args == 0 then
		StalkersMods.Admin.Notify(caller, "Invalid lua.")
		return false
	end

	local lua = ""
	for i, word in ipairs(args) do
		lua = lua..args[i].." "
	end
	lua = lua:sub(1, -1)

	if not lua or lua == 0 then
		StalkersMods.Admin.Notify(caller, "Invalid lua.")
		return false
	end

	StalkersMods.Admin.Notify(caller, "Ran Lua on clients.")
	StalkersMods.Logging.LogSecurity(
		(IsValid(caller) and (caller:Nick().." ("..caller:SteamID()..")") or "SERVER").." ran lua on clients:\n"..lua)

	net.Start("StalkersMods.Admin.CMDRunClLua")
		net.WriteString(lua)
	net.Send(targets)

	return true
end
if SERVER then util.AddNetworkString("StalkersMods.Admin.CMDRunClLua") else
	net.Receive("StalkersMods.Admin.CMDRunClLua", function()
		local lua = net.ReadString()
		timer.Simple(0.005, function()
			RunString(lua)
		end)
	end)
end
StalkersMods.Admin.RegisterCommand(cmd)



----------
-- Entity
----------
local cmd = StalkersMods.Admin.Command:New{
	Name = "ent",
	PrettyName = "Make Entity",
	Category = CATEGORY,
	Description = "Makes an entity where the caller is looking.",
	ArgDescription = "<entity classname (e.g. \"weapon_physgun\")>",
	NeedsTargets = false,
	HasNoArgs = false
}
function cmd:OnExecute(caller, args, targets)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "Server cannot make an entity.")
		return false
	elseif not args or #args == 0 then
		StalkersMods.Admin.Notify(caller, "Tried to make invalid entity.")
		return false
	elseif #args > 1 then
		StalkersMods.Admin.Notify(caller, "This function only takes one arg, the class name.")
		return false
	end

	local className = string.lower(args[1])
	local newEnt = ents.Create(className)
	if not newEnt or not IsValid(newEnt) then
		StalkersMods.Admin.Notify(caller, {
			"Failed creating entity '",
			{StalkersMods.Admin.ColEnums.ARGS, className},
			"'."
		})
		return false
	end

	local hitVector = caller:GetEyeTrace().HitPos
	hitVector.z = hitVector.z + 20
	newEnt:SetPos(hitVector)
	newEnt:Spawn()
	newEnt:Activate()

	StalkersMods.Admin.Notify(caller, {
		"Created an entity of type '",
		{StalkersMods.Admin.ColEnums.ARGS, className},
		"'."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)