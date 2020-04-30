local cmd = StalkersMods.Admin.Command:New{
	consoleCommandName = "tp",
	Category = "Teleportation",
	fancyName = "Teleport",
	description = "Teleports either target1 to target2 or target1 to where caller is looking at.",
	defaultAccess = StalkersMods.Admin.DefaultAccess.ADMIN
}
function cmd:OnExecute(caller, args, targets)
	print"asd"
	print(caller:Nick().." ran "..self.consoleCommandName.. " with args:")
	PrintTable(args)
	print("And targets:")
	PrintTable(targets)
end
StalkersMods.Admin.RegisterCommand(cmd)