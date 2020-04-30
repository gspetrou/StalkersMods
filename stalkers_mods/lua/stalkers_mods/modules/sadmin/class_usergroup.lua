StalkersMods.Admin = StalkersMods.Admin or {}

---------------------------------------
-- Object StalkersMods.Admin.UserGroup
---------------------------------------
-- Desc:		An object representing a user group.
StalkersMods.Admin.UserGroup = {
	Name = "",			-- Console/chat name of command
	PrettyName = "",	-- Name used for displaying in menus
	Inherits = "",		-- Other user group it inherits
	Privileges = {},	-- List of privileges (could be a command name or a CAMI.Privilege)

	__tostring = function(self)
		return "SAdmin UserGroup ("..(self.Name == "" and "Unset group" or self.Name)..")"
	end
}

-- Generate simple getters and setters:
local preSettersGettersAdded = table.Copy(StalkersMods.Admin.UserGroup)
for k, v in pairs(preSettersGettersAdded) do
	StalkersMods.Admin.UserGroup["Get"..k] = function(self)
		return self[k]
	end
	StalkersMods.Admin.UserGroup["Set"..k] = function(self, newVal)
		self[k] = newVal
	end
end

---------------------------------------------
-- StalkersMods.Admin.UserGroup:HasPrivilege
---------------------------------------------
-- Desc:		Sees if the user group has a given privilege.
-- Arg One:		String, privilege.
-- Returns:		Boolean.
function StalkersMods.Admin.UserGroup:HasPrivilege(privName)
	return StalkersMods.Admin.UserGroups.UserGroupHasPrivilege(self:GetName(), privName)
end

----------------------------------------------
-- StalkersMods.Admin.UserGroup:GivePrivilege
----------------------------------------------
-- Desc:		Gives the usergroup the given privilege.
-- Arg One:		String, privilege.
function StalkersMods.Admin.UserGroup:GivePrivilege(privName)
	table.insert(self.Privileges, privName)
end

------------------------------------------------
-- StalkersMods.Admin.UserGroup:RevokePrivilege
------------------------------------------------
-- Desc:		Takes the privilege from given the user group.
-- Arg One:		String, privilege.
function StalkersMods.Admin.UserGroup:RevokePrivilege(privName)
	for i, priv in ipairs(self:GetPrivileges()) do
		if priv == privName then
			table.remove(self.Privileges, i)
		end
	end
end

------------------------------------
-- StalkersMods.Admin.UserGroup:New
------------------------------------
-- Desc:		Creates a new StalkersMods.Admin.UserGroup object
-- Arg One:		StalkersMods.Admin.UserGroup object, data to set on the object at init, can be used as a copy constructor.
-- Returns:		StalkersMods.Admin.UserGroup object.
function StalkersMods.Admin.UserGroup:New(grp)
	grp = grp or {}		
	setmetatable(grp, self)
	self.__index = self
	return grp
end