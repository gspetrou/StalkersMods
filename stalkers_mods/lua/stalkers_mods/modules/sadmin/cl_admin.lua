hook.Add("InitPostEntity", "StalkersMods.Admin.SignifyReady", function()
	RunConsoleCommand("stalkermods_admin_clientready")
end)

net.Receive("StalkersMods.Admin.SyncUserGroups", function()
	local userGroups = {}
	local numGroups = net.ReadUInt(StalkersMods.Admin.Config.NWUserGroupBits)
	for i = 1, numGroups do
		local group = StalkersMods.Admin.UserGroups.NetReadUserGroup()
		StalkersMods.Admin.UserGroups.RegisterUserGroup(group)
	end

	if not StalkersMods.Admin.Initialized then
		StalkersMods.Admin.Initialized = true
	end
end)

net.Receive("StalkersMods.Admin.SyncUserGroup", function()
	local group = StalkersMods.Admin.NetReadUserGroup()
	StalkersMods.Admin.UserGroups.RegisterUserGroup(group)
end)

net.Receive("StalkersMods.Admin.RemoveUserGroup", function()
	StalkersMods.Admin.UserGroups.RemoveUserGroup(net.ReadString())
end)

net.Receive("StalkersMods.Admin.PlayerUserGroupChanged", function()
	local ply = StalkersMods.Utility.WritePlayer(ply)
	if IsValid(ply) then
		CAMI.SignalUserGroupChanged(ply, net.ReadString(), net.ReadString(), StalkersMods.Admin.CAMI.AdminModName)
	end
end)