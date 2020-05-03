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

net.Receive("StalkersMods.Admin.Notify", function()
	local out = {StalkersMods.Admin.PrefixColor, StalkersMods.Admin.ChatPrefix.. " ", color_white}
	local numMsg = net.ReadUInt(StalkersMods.Admin.Config.NWNotifArgs)
	for i = 1, numMsg do
		table.insert(out, StalkersMods.Admin.Colors[net.ReadUInt(2) + 1])
		table.insert(out, net.ReadString())
	end
	chat.AddText(unpack(out))
end)

net.Receive("StalkersMods.Admin.AddPrivilege", function()
	local userGroupName = net.ReadString()
	local privName = net.ReadString()
	local userGroup = StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName)
	userGroup:GivePrivilege(privName)
end)

net.Receive("StalkersMods.Admin.RemovePrivilege", function()
	local userGroupName = net.ReadString()
	local privName = net.ReadString()
	local userGroup = StalkersMods.Admin.UserGroups.GetUserGroup(userGroupName)
	userGroup:RevokePrivilege(privName)
end)

net.Receive("StalkersMods.Admin.SyncUserGroupRemoval", function()
	local removedGroup = net.ReadString()
	StalkersMods.Admin.UserGroups.RemoveUserGroup(removedGroup)
end)