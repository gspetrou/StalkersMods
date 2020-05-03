StalkersMods.Admin = StalkersMods.Admin or {}

-- CAMI Relevant Data
StalkersMods.Admin.CAMI = StalkersMods.Admin.CAMI or {}
StalkersMods.Admin.CAMI.AdminModName = "sadmin"

StalkersMods.Admin.ChatPrefix = "[SAdmin]"
StalkersMods.Admin.PrefixColor = Color(30, 144, 255)

StalkersMods.Admin.ColEnums = {
	WHITE = 0,
	TARGET = 1,
	ARGS = 2,
	CMD = 3
}
StalkersMods.Admin.Colors = {
	Color(255, 255, 255),	-- White
	Color(39, 174, 96),		-- Target
	Color(230, 126, 34),	-- Arguments
	Color(155, 89, 182)		-- Commands
}

------------------------------------
-- StalkersMods.Admin.TargetsToText
------------------------------------
-- Desc:		Takes a single player or table of players and returns a comma seperated string of their names.
-- Arg One:		Player or table of players.
-- Returns:		String, comma seperated names.
function StalkersMods.Admin.TargetsToText(targets)
	if not targets or (istable(targets) and #targets == 0) then
		return ""
	end

	if isentity(targets) then
		return targets:Nick()
	end

	if #targets == 1 then
		return targets[1]:Nick()
	end

	if #targets == 2 then
		return targets[1]:Nick().." and "..targets[2]:Nick()
	end

	local out = ""
	for i = 1, #targets do
		out = out..targets[i]:Nick()
		if i == #targets - 1 then
			out = out..", and "
		elseif i ~= #targets then
			out = out..", "
		end
	end

	return out
end

-----------------------------
-- StalkersMods.Admin.Notify
-----------------------------
-- Desc:		Notifies the target with the given args. If target is NULL uses MsgC (server), if not then chat.AddText.
-- 				This is not networked!
-- Arg One:		Player, or NULL, who to notify. If NULL then prints to server.
-- Arg Two:		Table, data for notification. Each array cell can either be a string (white text), or a table in form {textColor, text}.
if SERVER then util.AddNetworkString("StalkersMods.Admin.Notify") end
function StalkersMods.Admin.Notify(target, notifData)
	-- Must be called from server to work!
	if CLIENT then
		return
	end

	if IsValid(target) then
		timer.Simple(0, function()
			if not IsValid(target) then
				return
			end
			
			net.Start("StalkersMods.Admin.Notify")
				if isstring(notifData) then
					net.WriteUInt(1, StalkersMods.Admin.Config.NWNotifArgs)
					net.WriteUInt(StalkersMods.Admin.ColEnums.WHITE, 2)
					net.WriteString(notifData)
				else
					net.WriteUInt(#notifData, StalkersMods.Admin.Config.NWNotifArgs)
					for i = 1, #notifData do
						if isstring(notifData[i]) then
							net.WriteUInt(StalkersMods.Admin.ColEnums.WHITE, 2)
							net.WriteString(notifData[i])
						else
							net.WriteUInt(notifData[i][1], 2)
							net.WriteString(notifData[i][2])
						end
					end
				end
			net.Send(target)
		end)
	else
		local printMsg = {}
		if isstring(notifData) then
			table.insert(printMsg, color_white)
			table.insert(printMsg, notifData)
		else
			for i, v in ipairs(notifData) do
				if isstring(v) then
					table.insert(printMsg, color_white)
					table.insert(printMsg, v)
				else
					table.insert(printMsg, StalkersMods.Admin.Colors[v[1]])
					table.insert(printMsg, v[2])
				end
			end
		end
		table.insert(printMsg, "\n")
		MsgC(StalkersMods.Admin.PrefixColor, StalkersMods.Admin.ChatPrefix, " ", unpack(printMsg))
	end
end

function StalkersMods.Admin.PrintHelp()
	local cmdData = {}
	local cmdText = ""
	for cmdName, cmdObj in SortedPairs(StalkersMods.Admin.GetAllCommands()) do
		table.insert(cmdData, Color(255, 140, 140))
		table.insert(cmdData, "\t"..cmdObj:GetName())
		table.insert(cmdData, color_white)

		local cmdDesc = ""
		if cmdObj:GetPrettyName() ~= "" then
			cmdDesc = cmdDesc.."\n\t\t- "..cmdObj:GetPrettyName()
		end
		if cmdObj:GetDescription() ~= "" then
			cmdDesc = cmdDesc.."\n\t\t- "..cmdObj:GetDescription()
		end

		if cmdDesc ~= "" then
			table.insert(cmdData, cmdDesc)
		end

		table.insert(cmdData, "\n")
	end

	MsgC(color_white,
		"\n--------------------------\n",
		"---", Color(255, 140, 140), "Stalker's Admin Mod", color_white, "----\n",
		"--------------------------\n",
		"Run commands like so:\t\tsadmin cmdName <target> <arg(s)>\n",
		"Run a chat command like so:\t!cmdName <target> <arg(s)>\n",
		"Target selectors:\n",
		"\tPlayerName\t- Select a player by their name or partial name\n",
		"\t*\t\t- Select all players\n",
		"\t^\t\t- Select yourself\n",
		"\t!\t\t- Select everyone but yourself\n",
		"\tt\t\t- Select the player you're looking at (eye trace)\n",
		"\tSTEAM_X:Y:Z\t- Select the player by their SteamID32\n",
		"\tSTEAM64\t\t- Select the player by their SteamID64\n",
		"\th\t\t- Select all humans\n",
		"\tb\t\t- Select all bots\n",
		"Commands:\n", unpack(cmdData)
	)
end

hook.Add("Initialize", "StalkersMods.Admin.Initialize", function()
	if SERVER then
		-- Remove gmod's built in rank system.
		hook.Remove("PlayerInitialSpawn", "PlayerAuthSpawn")
		StalkersMods.Admin.LoadDataFiles()
	end

	StalkersMods.Admin.LoadCommands()

	if SERVER then
		StalkersMods.Admin.Initialized = true
	end
end)

--------------------
-- CAMI Conformance
--------------------
hook.Add("CAMI.OnUsergroupRegistered", "StalkersMods.Admin.CAMIOnRegisterGroup", function(camiGroup, src)
	if not StalkersMods.Admin.Initialized or StalkersMods.Admin.CAMI.AdminModName == src then
		return
	end

	if not StalkersMods.Admin.UserGroups.UserGroupExists(camiGroup.Name) then
		local newGroup = StalkersMods.Admin.UserGroup:New()
		newGroup:SetName(camiGroup.Name)
		newGroup:SetInherits(camiGroup.Inherits)
		StalkersMods.Admin.UserGroups.Groups[camiGroup.Name] = newGroup

		if SERVER then
			StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		end
	end
end)

hook.Add("CAMI.OnUsergroupUnregistered", "StalkersMods.Admin.CAMIOnUnRegisterGroup", function(camiGroup, src)
	if not StalkersMods.Admin.Initialized or StalkersMods.Admin.CAMI.AdminModName == src then
		return
	end

	if StalkersMods.Admin.UserGroups.UserGroupExists(camiGroup.Name) then
		StalkersMods.Admin.UserGroups.RemoveUserGroup(camiGroup.Name)

		if SERVER then
			StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		end
	end
end)

hook.Add("CAMI.PlayerUsergroupChanged", "StalkersMods.Admin.CAMIPlayerGroupChanged", function(ply, from, to, src)
	if src == StalkersMods.Admin.CAMI.AdminModName then
		return
	end

	-- Their user group is already changed so just set their offline group.
	if SERVER then
		StalkersMods.Admin.UserGroups.SetOfflinePlayerUserGroupBySteamID(ply:SteamID(), to)
	end
end)

hook.Add("CAMI.OnPrivilegeRegistered", "StalkersMods.Admin.CAMIOnPrivilegeRegistered", function(camiPriv)
	if not StalkersMods.Admin.Initialized then
		return
	end

	StalkersMods.Admin.UserGroups.Groups[camiPriv.MinAccess]:GivePrivilege(camiPriv.Name)
	if SERVER then
		StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
	end
end)

hook.Add("CAMI.OnPrivilegeUnregistered", "StalkersMods.Admin.CAMIOnPrivilegeUnRegistered", function(camiPriv)
	if not StalkersMods.Admin.Initialized then
		return
	end

	local minAccessGroup = StalkersMods.Admin.UserGroups[camiPriv.MinAccess]
	if minAccessGroup then
		minAccessGroup:RevokePrivilege(camiPriv.Name)
		if SERVER then
			StalkersMods.Admin.UserGroups.WriteUserGroupsFile()
		end
	end
end)

hook.Add("CAMI.PlayerHasAccess", "StalkersMods.Admin.CAMIPlayerHasAccess", function(caller, privilege, cb)
	cb(StalkersMods.Admin.UserGroups.UserHasPrivilege(caller, privilege))
	return true
end)