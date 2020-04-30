StalkersMods = StalkersMods or {}
StalkersMods.AddonFolder = "stalkers_mods"	-- Folder containning StalkersMods.
StalkersMods.DataFolder = "stalkers_mods"	-- Folder to store data files.

-- Load von
AddCSLuaFile(StalkersMods.AddonFolder.."/von.lua")
include(StalkersMods.AddonFolder.."/von.lua")

-- Load CAMI
AddCSLuaFile(StalkersMods.AddonFolder.."/cami.lua")
include(StalkersMods.AddonFolder.."/cami.lua")

-- Load utility
AddCSLuaFile(StalkersMods.AddonFolder.."/utility.lua")
include(StalkersMods.AddonFolder.."/utility.lua")

-- Load logs
AddCSLuaFile(StalkersMods.AddonFolder.."/log.lua")
include(StalkersMods.AddonFolder.."/log.lua")

---------------------------
-- StalkersMods.Initialize
---------------------------
-- Desc:		Loads the addon's subfiles, can be called manually when a new file is added to avoid a map change.
function StalkersMods.Initialize()
	StalkersMods.Utility.IncludeFolder(StalkersMods.AddonFolder.."/modules", true, 1)
end

-- Load rest of the addon.
StalkersMods.Initialized = StalkersMods.Initialized or false	-- Has initialized at least once before.
if not StalkersMods.Initialized then
	StalkersMods.Initialize()
	StalkersMods.Initialized = true
end