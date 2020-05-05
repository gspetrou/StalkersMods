StalkersMods.Admin = StalkersMods.Admin or {}

-------------------------------------
-- Object StalkersMods.Admin.Command
-------------------------------------
-- Desc:		An object representing a command.
StalkersMods.Admin.Command = {
	Name = "",			-- Console/chat name of command
	PrettyName = "",	-- Name used for displaying in menus
	Category = "Uncategorized",
	Description = "",
	NeedsTargets = true,
	NoTargetIsSelf = false, -- Only has effect if NeedsTargets is true. If no target is passed then the caller is the target.
	ArgDescription = "",
	HasNoArgs = false	-- Used for commands like "help" so we know not to bother prompting for args in the menu.
}

-- Generate simple getters and setters:
local preSettersGettersAdded = table.Copy(StalkersMods.Admin.Command)
for k, v in pairs(preSettersGettersAdded) do
	StalkersMods.Admin.Command["Get"..k] = function(self)
		return self[k]
	end
	StalkersMods.Admin.Command["Set"..k] = function(self, newVal)
		self[k] = newVal
	end
end

----------------------------------------
-- StalkersMods.Admin.Command:OnExecute
----------------------------------------
-- Desc:		Called when a command gets ran by someone.
-- Arg One:		Player/NULL, player if called by player, NULL if by server.
-- Arg Two:		Table or nil, table of args passed, nil if none passed.
-- Arg Three:	Entity, Table, or nil, entity target, table of target entities, nil target.
function StalkersMods.Admin.Command:OnExecute(caller, args, targets)
	local name = IsValid(caller) and caller:Nick() or "NULL"
	local text ="[SAdmin] Caller '%s' tried to call command '%s' which has an unset OnExecute function."
	StalkersMods.Logging.LogWarning(string.format(text, name, self.ConsoleCommand))
end

-- Returns a formated string representing the command.
function StalkersMods.Admin.Command:__tostring()
	return "SAdmin Command ("..(self.Name == "" and "Unset name" or self.Name)..")"
end

----------------------------------
-- StalkersMods.Admin.Command:New
----------------------------------
-- Desc:		Creates a new StalkersMods.Admin.Command object
-- Arg One:		StalkersMods.Admin.Command object, data to set on the object at init, can be used as a copy constructor.
-- Returns:		StalkersMods.Admin.Command object.
function StalkersMods.Admin.Command:New(cmd)
	cmd = cmd or {}		
	setmetatable(cmd, self)
	self.__index = self
	return cmd
end