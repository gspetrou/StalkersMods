StalkersMods.Warnings = StalkersMods.Warnings or {}

---------------------------------------------
-- Object StalkersMods.Warnings.WarningClass
---------------------------------------------
-- Desc:		An object representing a warning.
StalkersMods.Warnings.WarningClass = {
	OwnerSteamID = "",		-- SteamID of person getting warned.
	OwnerNick = "",			-- Nick of person getting warned AT THE TIME THEY GOT WARNED.
	GivenBySteamID = "",	-- SteamID of player that warned them.
	GivenByNick = "",		-- Nick of player that warned them AT THE TIME THEY GOT WARNED.
	Description = "",		-- Description of the warning.
	TimeStamp = 0			-- Time (unix epoch) that the warning took place.
}

-- Generate simple getters and setters:
local preSettersGettersAdded = table.Copy(StalkersMods.Warnings.WarningClass)
for k, v in pairs(preSettersGettersAdded) do
	StalkersMods.Warnings.WarningClass["Get"..k] = function(self)
		return self[k]
	end
	StalkersMods.Warnings.WarningClass["Set"..k] = function(self, newVal)
		self[k] = newVal
	end
end

-- Returns a formated string representing the command.
function StalkersMods.Warnings.WarningClass:__tostring()
	return "SWarn Warning (for "..(self.OwnerSteamID == "" and "Unset Player" or self.OwnerSteamID)..")"
end

-------------------------------------------------------
-- StalkersMods.Warnings.WarningClass:GetFormattedTime
-------------------------------------------------------
-- Desc:		Gets a formatted string of when the warning took place.
-- Returns:		String
function StalkersMods.Warnings.WarningClass:GetFormattedTime()
	return os.date("%c", self:GetTimeStamp())
end

--------------------------------------------------
-- StalkersMods.Warnings.WarningClass:GetUniqueID
--------------------------------------------------
-- Desc:		Returns a unique identifying string for this warning object.
-- Returns:		String
function StalkersMods.Warnings.WarningClass:GetUniqueID()
	return self:GetOwnerSteamID().."-"..tostring(self:GetTimeStamp())
end

------------------------------------------
-- StalkersMods.Warnings.WarningClass:New
------------------------------------------
-- Desc:		Creates a new warning object.
-- Arg One:		Table, can be used as copy constructor or data to base new object off of.
-- Returns:		StalkersMods.Warnings.WarningClass object.
function StalkersMods.Warnings.WarningClass:New(warn)
	warn = warn or {}		
	setmetatable(warn, self)
	self.__index = self
	return warn
end