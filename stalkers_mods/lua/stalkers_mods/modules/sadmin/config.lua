StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.Config = StalkersMods.Admin.Config or {}

-- Stores general settings
StalkersMods.Admin.Config.SettingsFile = "stalkers_mods/admin/settings.dat"
-- Stores each user group and its privileges
StalkersMods.Admin.Config.UserGroupsFile = "stalkers_mods/admin/usergroups.dat"
-- Stores player's ranks
StalkersMods.Admin.Config.OfflinePlayerRanksFile = "stalkers_mods/admin/playerranks.dat"
-- Stores player's bans
StalkersMods.Admin.Config.PlayerBansFile = "stalkers_mods/admin/bans.dat"

-- 2 to the power of this many bits = number of groups supported by the admin mod.
StalkersMods.Admin.Config.NWUserGroupBits = 6
-- 2 to the power of this many bits = number of privileges supported by the admin mod.
StalkersMods.Admin.Config.NWPrivilegeBits = 10
-- 2 to the power of this many bits = number of notification args we can send.
StalkersMods.Admin.Config.NWNotifArgs = 5

StalkersMods.Admin.Config.DefaultSettings = {
	-- Make sure this fucking exists please.
	-- Also the actual default usergroup can be something custom, this is only for the
	-- case of a data wipe and we need a default usergroup.
	["stock_default_usergroup"] = "user"
}

StalkersMods.Admin.Config.DefaultPlayerRanks = {
	["STEAM_0:1:18093014"] = "stalker"	-- This is the rank called stalker
}

StalkersMods.Admin.Config.CategoryIcons = {
	["Utility"] = "icon16/wrench.png",
	["User Management"] = "icon16/user.png",
	["Teleportation"] = "icon16/map_edit.png",
}

-- superadmin, admin, and user need to exist.
StalkersMods.Admin.Config.DefaultUserGroups = {
	["stalker"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("stalker")
		userGroup:SetPrettyName("Stalker")
		userGroup:SetInherits("superadmin")
		userGroup:SetPrivileges({
			"adduser",
			"adduserid",
			"removeuser",
			"removeuserid",
			"giveprivilege",
			"removeprivilege",
			"addgroup",
			"removegroup",
			"ban",
			"banid",
			"kick",
			"map",
			"help"
		})
		return userGroup
	end,
	["superadmin"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("superadmin")
		userGroup:SetPrettyName("Super-Administrator")
		userGroup:SetInherits("admin")
		return userGroup
	end,
	["admin"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("admin")
		userGroup:SetPrettyName("Administrator")
		userGroup:SetInherits("user")
		return userGroup
	end,
	["user"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("user")
		userGroup:SetPrettyName("User")
		userGroup:GivePrivilege("help")
		return userGroup
	end
}