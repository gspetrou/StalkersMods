StalkersMods = StalkersMods or {}
StalkersMods.Utility = StalkersMods.Utility or {}

--------------------------------------------------
-- StalkersMods.Utility.CreateDirectoryIfNotExist
--------------------------------------------------
-- Desc:		Creates a directory (and its non-existant parent directories) if it doesnt exist.
-- Arg One:		String, path, dont end with a "/"
function StalkersMods.Utility.CreateDirectoryIfNotExist(path)
	local folders = string.Explode("/", path)
	local folderPath = ""
	for i, folder in ipairs(folders) do
		folderPath = folderPath .. folder .. "/"
		if not file.Exists(folderPath, "DATA") then
			file.CreateDir(folderPath)
		end
	end
end

----------------------------------------------
-- StalkersMods.Utility.CreateFileIfNotExists
----------------------------------------------
-- Desc:		Creates a file and its parent directories if they do not exist.
-- Arg One:		String, file path.
-- Arg Two:		Boolean=false, even if the file exists, clear it.
-- Returns:		Boolean, was the file created or did it already exist.
function StalkersMods.Utility.CreateFileIfNotExists(path, overwrite)
	local containningFolderPath = ""
	for i = #path, 1, -1 do
		if path[i] == "/" then
			containningFolderPath = string.sub(path, 1, i)
			break
		end
	end

	StalkersMods.Utility.CreateDirectoryIfNotExist(containningFolderPath)

	if overwrite or not file.Exists(path, "DATA") then
		file.Write(path, "")
		return true
	end
	return false
end

-------------------------------------
-- StalkersMods.Utility.DeleteFolder
-------------------------------------
-- Desc:		Deletes a folder and everything in it recursively.
-- Arg One:		String, path to folder to delete, dont end with a "/"
function StalkersMods.Utility.DeleteFolder(path)
	local files, folders = file.Find(path.."/*", "DATA")

	for i, fileName in ipairs(files) do
		file.Delete(path.."/"..fileName)
	end

	for i, folderName in ipairs(folders) do
		StalkersMods.Utility.DeleteFolder(path.."/"..folderName)
		file.Delete(path.."/"..folderName)
	end

	file.Delete(path)
end

--------------------------------------
-- StalkersMods.Utility.IncludeFolder
--------------------------------------
-- Desc:		Includes and AddCSLuaFiles all files in a given directory according to their name prefix (sv_, cl_, sh_).
--				No prefix will be shared.
-- Arg One:		String, path to scan.
-- Arg Two:		Boolean=false, should recurse into subdirectories.
-- Arg Three:	Number=nil, how many folders deep to go down. Nil will go till it cannot anymore. 0 will only include lua files in that folder, not subfolders.
function StalkersMods.Utility.IncludeFolder(path, recurse, count)
	if isnumber(count) and count < 0 then
		return
	end

	local files, folders = file.Find(path.."/*", "LUA")
	for i, fileName in ipairs(files) do
		if string.sub(fileName, -4) == ".lua" then
			local prefix = string.sub(fileName, 1, 3)
			local fullFilePath = path.."/"..fileName

			if prefix == "sv_" then
				if SERVER then
					include(fullFilePath)
				end
			elseif prefix == "cl_" then
				if SERVER then
					AddCSLuaFile(fullFilePath)
				else
					include(fullFilePath)
				end
			else
				if SERVER then
					AddCSLuaFile(fullFilePath)
				end
				include(fullFilePath)
			end
		end
	end

	if recurse then
		for i, folderName in ipairs(folders) do
			StalkersMods.Utility.IncludeFolder(path.."/"..folderName, true, isnumber(count) and count - 1 or nil)
		end
	end		
end

----------------------------------------
-- StalkersMods.Utility.SaveTableToFile
----------------------------------------
-- Desc:		Saves a lua table to a file using vON.
-- Arg One:		Table, to serialize.
-- Arg Two:		String, file to save to.
local von_serialize = StalkersMods.von.serialize
local file_Write = file.Write
function StalkersMods.Utility.SaveTableToFile(tbl, fileName)
	StalkersMods.Utility.CreateFileIfNotExists(fileName)
	file_Write(fileName, von_serialize(tbl))
end

------------------------------------------
-- StalkersMods.Utility.LoadTableFromFile
------------------------------------------
-- Desc:		Loads a serialized table from a file and deserializes it using vON.
-- Arg One:		String, path to folder
-- Returns:		Table, read from file.
local von_deserialize = StalkersMods.von.deserialize
local file_Read = file.Read
function StalkersMods.Utility.LoadTableFromFile(fileName)
	if not file.Exists(fileName, "DATA") then
		StalkersMods.Logging.LogError("Tried to read table from non-existant file '"..tostring(fileName).."'", true)
	end

	return von_deserialize(file_Read(fileName, "DATA"))
end

if SERVER then
	----------------------------------------------------
	-- StalkersMods.Utility.IsPlayerValidAndFullyAuthed
	----------------------------------------------------
	-- Desc:		Is the given player fully authenticated by the server.
	-- Arg One:		Player
	-- Returns:		Boolean
	function StalkersMods.Utility.IsPlayerValidAndFullyAuthed(ply)
		return IsValid(ply) and ply:IsPlayer() and ply:IsFullyAuthenticated()
	end
end

---------------------------------------------
-- StalkersMods.Utility.NetWriteNumericArray
---------------------------------------------
-- Desc:		Sends a numeric array in an efficient manner (write length, then read), instead of net.WriteTable.
-- 				Be sure the writeFunc matches the corresponding readFunc!
-- Arg One:		Table, to be written.
-- Arg Two:		Number, max size of array in bits. Say your array wont have more than 255 items, make this 8 (2^8).
-- Arg Three:	Function, a net.Write* function.
-- Arg Four:	Vararg=nil, extra arg passed into writeFunc, used in cases like where writeFunc=net.WriteUInt(stuff, extraArg).
function StalkersMods.Utility.NetWriteNumericArray(arr, bitMax, writeFunc, ...)
	net.WriteUInt(#arr, bitMax)
	for i = 1, #arr do
		writeFunc(arr[i], ...)
	end
end

--------------------------------------------
-- StalkersMods.Utility.NetReadNumericArray
--------------------------------------------
-- Desc:		Reads a numeric array in an efficient manner (read length, then read individual cells), instead of net.WriteTable.
-- 				Be sure the readFunc matches the corresponding writeFunc!
-- Arg One:		Number, max size of array in bits. Say your array wont have more than 255 items, make this 8 (2^8).
-- Arg Three:	Function, a net.Read* function.
-- Arg Four:	Vararg=nil, extra arg passed into readFunc, used in cases like where readFunc=net.ReadUInt(extraArg).
function StalkersMods.Utility.NetReadNumericArray(bitMax, readFunc, ...)
	local arrMaxize = net.ReadUInt(bitMax)
	local arr = {}
	for i = 1, arrMaxize do
		arr[i] = readFunc(...)
	end
	return arr
end

--------------------------------------------
-- StalkersMods.Utility.CopySequentialTable
--------------------------------------------
-- Desc:		Takes the given array and returns a copy.
-- 				Be careful, the values copied may still be shallow copies that could affect the original input!
-- Arg One:		Table, with sequential numeric indices and non-nil values until the end.
-- Returns:		Table, copy of arg one.
function StalkersMods.Utility.CopySequentialTable(arr)
	local out = {}
	for i, v in ipairs(arr) do
		out[i] = v
	end
	return out
end

------------------------------------
-- StalkersMods.Utility.WritePlayer
------------------------------------
-- Desc:		Writes a player in a more optimized way over the net library.
-- Arg One:		Player, to write.
function StalkersMods.Utility.WritePlayer(ply)
	if IsValid(ply) then
		net.WriteUInt(ply:EntIndex(), 7)
	else
		net.WriteUInt(0, 7)
	end
end

-----------------------------------
-- StalkersMods.Utility.ReadPlayer
-----------------------------------
-- Desc:		More optmized way to read player via net message.
-- Returns:		Player, read over net library.
function StalkersMods.Utility.ReadPlayer()
	local i = net.ReadUInt(7)
	local ply = Entity(i)
	if not i or not ply:IsPlayer() then
		return
	end
	return ply
end

----------------------------------------------
-- StalkersMods.Utility.StringsHaveAnyOverlap
----------------------------------------------
-- Desc:		Checks if two strings have any overlap.
-- Arg One:		String
-- Arg Two:		String
-- Returns:		Boolean
function StalkersMods.Utility.StringsHaveAnyOverlap(a, b)
	return (string.lower(a) == string.lower(b)) or string.find(string.lower(a), string.lower(b), nil, true)
end

function StalkersMods.Utility.SecondsToTimeLeft(rawSec)
	local days = math.floor(rawSec/86400)
	rawSec = math.floor(rawSec%86400)
	local hours = math.floor(rawSec/3600)
	rawSec = math.floor(rawSec%3600)
	local mins = math.floor(rawSec/60)
	rawSec = math.floor(rawSec%60)

	local daysText = tostring(days)
	if #daysText < 2 then
		daysText = "0"..daysText
	end
	local hoursText = tostring(hours)
	if #hoursText < 2 then
		hoursText = "0"..hoursText
	end
	local minText = tostring(mins)
	if #minText < 2 then
		minText = "0"..minText
	end
	local secText = tostring(rawSec)
	if #secText < 2 then
		secText = "0"..secText
	end
	return daysText..":"..hoursText..":"..minText..":"..secText
end