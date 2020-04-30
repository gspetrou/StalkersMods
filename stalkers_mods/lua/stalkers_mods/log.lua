StalkersMods = StalkersMods or {}
StalkersMods.Logging = StalkersMods.Logging or {}

-- Micro-optimizations
local file_Exists = file.Exists
local file_Append = file.Append
local os_date = os.date

StalkersMods.Logging = {
	LogFolder = StalkersMods.DataFolder.."/logs"
}
StalkersMods.Logging.Levels = {
	GENERAL = {
		text = "GENERAL",
		value = 1
	},
	WARNING = {
		text = "WARNING",
		value = 2,
		color = Color(255, 255, 0)
	},
	SECURITY = {
		text = "SECURITY",
		value = 3,
		color = Color(0, 255, 255)
	},
	ERROR = {
		text = "ERROR",
		value = 4,
		color = Color(255, 0, 0)
	}
}

-----------------------------------------
-- StalkersMods.Logging.GetLogPrintLevel
-----------------------------------------
-- Desc:		Gets the current log print level.
-- Returns:		Number.
local loggingLevel = CreateConVar("stalker_log_printlevel", "1", FCVAR_ARCHIVE, "Sets the level of the logs worth printing to console.")
function StalkersMods.Logging.GetLogPrintLevel()
	return loggingLevel:GetInt()
end

---------------------------------------------
-- StalkersMods.Logging.GetTodaysLogFileName
---------------------------------------------
-- Desc:		Gets what the name of today's logfile should be.
-- Returns:		String
function StalkersMods.Logging.GetTodaysLogFileName()
	return os_date("%Y-%m-%d.txt")
end

-------------------------------------------------
-- StalkersMods.Logging.GetTodaysLogFileFullPath
-------------------------------------------------
-- Desc:		Gets the full path to today's log file.
-- Returns:		String
function StalkersMods.Logging.GetTodaysLogFileFullPath()
	return StalkersMods.Logging.LogFolder.."/"..StalkersMods.Logging.GetTodaysLogFileName()
end

----------------------------------
-- StalkersMods.Logging.MakeFiles
----------------------------------
-- Desc:		Makes the logging files on the server.
-- Arg One:		Boolean=false, should we force the deletion/recreation of all log files?
function StalkersMods.Logging.MakeFiles(force)
	if force == true then
		StalkersMods.Utility.DeleteFolder(StalkersMods.Logging.LogFolder)
	end

	local created = StalkersMods.Utility.CreateFileIfNotExists(StalkersMods.Logging.GetTodaysLogFileFullPath())
	if created then
		StalkersMods.Logging.LogGeneral("Created todays log file")
	end
end

----------------------------
-- StalkersMods.Logging.Log
----------------------------
-- Desc:		Writes to today's log file at the given level.
-- Arg One:		String, text to log.
-- Arg Two:		StalkersMods.Logging.Levels enum, log level.
function StalkersMods.Logging.Log(text, level)
	local logFilePath = StalkersMods.Logging.GetTodaysLogFileFullPath()
	if not file_Exists(logFilePath, "DATA") then
		StalkersMods.Logging.MakeFiles()
	end

	local logText = os_date("%X").." [".. level.text.."] "..text
	if level.value >= StalkersMods.Logging.GetLogPrintLevel() then
		if level.color then
			MsgC(level.color, "[LOG] "..logText.."\n")
		else
			print("[LOG] "..logText)
		end
	end
	file_Append(logFilePath, logText.."\n")
end

-- Helper log functions.
function StalkersMods.Logging.LogGeneral(text)
	StalkersMods.Logging.Log(text, StalkersMods.Logging.Levels.GENERAL)
end
function StalkersMods.Logging.LogWarning(text)
	StalkersMods.Logging.Log(text, StalkersMods.Logging.Levels.WARNING)
end
function StalkersMods.Logging.LogSecurity(text)
	StalkersMods.Logging.Log(text, StalkersMods.Logging.Levels.SECURITY)
end
function StalkersMods.Logging.LogError(text, shouldHalt)
	StalkersMods.Logging.Log(text, StalkersMods.Logging.Levels.ERROR)

	-- Time stamp errors for easier searching in lua_errors_server.txt
	if shouldHalt then
		error(os_date("%X").." "..text)
	else
		ErrorNoHalt(os_date("%X").." (No Halt) "..text.."\n")
	end
end

hook.Add("Initialize", "StalkersMods.Logging.Initialize", function()
	StalkersMods.Logging.MakeFiles()
end)