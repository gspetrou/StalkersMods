StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.Commands = StalkersMods.Admin.Commands or {}

--------------------------------------
-- StalkersMods.Admin.RegisterCommand
--------------------------------------
-- Desc:		Registers a new command with the admin mod.
-- Arg One:		StalkersMods.Admin.Command object, to register with admin mod.
function StalkersMods.Admin.RegisterCommand(cmdObj)
	StalkersMods.Admin.Commands[cmdObj:GetName()] = cmdObj
end

function StalkersMods.Admin.LoadCommands()
	StalkersMods.IncludeFolder("stalkers_mods/admin_mod/commands", true, 1)
	hook.Call("StalkersMods.Admin.LoadCommands")
end