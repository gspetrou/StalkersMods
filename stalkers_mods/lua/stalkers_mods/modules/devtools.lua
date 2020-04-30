-- Gets me!
StalkerID = "STEAM_0:1:18093014"
function Stalker()
	return player.GetBySteamID(StalkerID)
end

if SERVER then
	-- Refreshes the map
	concommand.Add("rmap", function(ply)
		if not IsValid(ply) or StalkersMods.IsStalker(ply) then
			RunConsoleCommand("changelevel", game.GetMap())
		end
	end)

	-- Clears the server console
	concommand.Add("cls", function(ply)
		if not IsValid(ply) or StalkersMods.IsStalker(ply) then
			print(string.rep("\n", 30))
		end
	end)

	-- Runs server lua
	concommand.Add("lr", function(ply, _, _, argstr)
		if not IsValid(ply) or StalkersMods.IsStalker(ply) then
			RunString(argstr)	-- Im lazy
		end
	end)

	-- Adds bots
	concommand.Add("addbots", function(ply, _, args)
		if not IsValid(ply) or StalkersMods.IsStalker(ply) then
			for i = 1, args[1] do
				RunConsoleCommand("bot")
			end
		end
	end)

	-- Kicks all bots
	concommand.Add("kickbots", function(ply)
		if not IsValid(ply) or StalkersMods.IsStalker(ply) then
			for i, v in ipairs(player.GetBots()) do
				v:Kick("You're a bot")
			end
		end
	end)
else
	-- Runs clientside lua
	concommand.Add("lrc", function(ply, _, _, argstr)
		if not IsValid(ply) or StalkersMods.IsStalker(ply) then
			RunString(argstr)
		end
	end)
end

-- It that player me?
function StalkersMods.IsStalker(ply)
	return ply == Stalker()
end

-- Gets a bot by the number in its name
function StalkersMods.GetBot(num)
	for i, bot in ipairs(player.GetBots()) do
		local endNum = tonumber(string.sub(bot:Nick(), 4))
		if endNum == num then
			return bot
		end
	end
end

-- Gets the Entity that Stalker is looking at
function StalkersMods.EyeEnt()
	return Stalker():GetEyeTrace().Entity
end