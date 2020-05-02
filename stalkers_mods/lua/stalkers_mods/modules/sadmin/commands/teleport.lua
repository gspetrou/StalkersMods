local cmd = StalkersMods.Admin.Command:New{
	Name = "tp",
	PrettyName = "Teleport",
	Category = "Teleportation",
	Description = "Teleports either target1 to target2 or target1 to where caller is looking at.",
	NeedsTargets = true
}
function cmd:OnExecute(caller, args, targets)
	print("Ran")
end
StalkersMods.Admin.RegisterCommand(cmd)