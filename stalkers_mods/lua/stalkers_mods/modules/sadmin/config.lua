StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.Config = StalkersMods.Admin.Config or {}

-- Stores general settings
StalkersMods.Admin.Config.SettingsFile = "stalkers_mods/admin/settings.dat"
-- Stores each user group and its privileges
StalkersMods.Admin.Config.UserGroupsFile = "stalkers_mods/admin/usergroups.dat"
-- Stores player's ranks
StalkersMods.Admin.Config.OfflinePlayerRanksFile = "stalkers_mods/admin/playerranks.dat"

-- 2 to the power of this many bits = number of groups supported by the admin mod.
StalkersMods.Admin.Config.NWUserGroupBits = 6
-- 2 to the power of this many bits = number of privileges supported by the admin mod.
StalkersMods.Admin.Config.NWPrivilegeBits = 10

StalkersMods.Admin.Config.DefaultSettings = {
	-- Make sure this fucking exists please.
	-- Also the actual default usergroup can be something custom, this is only for the
	-- case of a data wipe and we need a default usergroup.
	["stock_default_usergroup"] = "user"
}

StalkersMods.Admin.Config.DefaultPlayerRanks = {
	["STEAM_0:1:18093014"] = "stalker"	-- This is the rank called stalker
}

-- superadmin, admin, and user need to exist.
StalkersMods.Admin.Config.DefaultUserGroups = {
	["stalker"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("stalker")
		userGroup:SetPrettyName("Stalker")
		userGroup:SetInherits("superadmin")
		return userGroup
	end,
	["superadmin"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("superadmin")
		userGroup:SetPrettyName("Stalker")
		userGroup:SetInherits("Super-Administrator")
		return userGroup
	end,
	["admin"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("admin")
		userGroup:SetPrettyName("Stalker")
		userGroup:SetInherits("Administrator")
		return userGroup
	end,
	["user"] = function()
		local userGroup = StalkersMods.Admin.UserGroup:New()
		userGroup:SetName("user")
		userGroup:SetPrettyName("User")
		return userGroup
	end
}