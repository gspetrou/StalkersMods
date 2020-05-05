local CATEGORY = "Teleportation"
--[[
Contains:
	- Teleport
	- Bring
	- Goto
	- Send
	- Return
]]--

-- Thanks ULX
local function spiralGrid(rings)
	local grid = {}
	local col, row

	for ring = 1, rings do -- For each ring...
		row = ring
		for col = 1 - ring, ring do -- Walk right across top row
			table.insert(grid, {col, row})
		end

		col = ring
		for row = ring - 1, -ring, -1 do -- Walk down right-most column
			table.insert(grid, {col, row})
		end

		row = -ring
		for col = ring - 1, -ring, -1 do -- Walk left across bottom row
			table.insert(grid, {col, row})
		end

		col = -ring
		for row= 1 - ring, ring do -- Walk up left-most column
			table.insert(grid, {col, row})
		end
	end

	return grid
end
local tpGrid = spiralGrid(24)

-- Thanks again ULX
local function playerSend(from, to, force)
	if not to:IsInWorld() and not force then return false end -- No way we can do this one

	local yawForward = to:EyeAngles().yaw
	local directions = { -- Directions to try
		math.NormalizeAngle(yawForward - 180), -- Behind first
		math.NormalizeAngle(yawForward + 90), -- Right
		math.NormalizeAngle(yawForward - 90), -- Left
		yawForward,
	}

	local t = {}
	t.start = to:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
	t.filter = {to, from}

	local i = 1
	t.endpos = to:GetPos() + Angle(0, directions[i], 0):Forward() * 47 -- (33 is player width, this is sqrt( 33^2 * 2 ))
	local tr = util.TraceEntity(t, from)
	while tr.Hit do -- While it's hitting something, check other angles
		i = i + 1
		if i > #directions then	 -- No place found
			if force then
				return to:GetPos() + Angle(0, directions[1], 0):Forward() * 47
			else
				return false
			end
		end

		t.endpos = to:GetPos() + Angle(0, directions[i], 0):Forward() * 47

		tr = util.TraceEntity(t, from)
	end

	return tr.HitPos
end

------------
-- Teleport
------------
local cmd = StalkersMods.Admin.Command:New{
	Name = "tp",
	PrettyName = "Teleport",
	Category = CATEGORY,
	Description = "Teleports yourself or target to a location.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't teleport somewhere!")
		return false
	elseif not caller:Alive() then
		StalkersMods.Admin.Notify(caller, "You're not alive to be teleported!")
		return false
	elseif #targets > 1 then
		StalkersMods.Admin.Notify(caller, "You can only teleport one player at a time.")
		return false
	end
	
	-- Thanks ULX for this code.
	local target = targets[1]
	local tr = util.TraceEntity({
		start = caller:GetPos() + Vector(0, 0, 32),
		endpos = caller:GetPos() + caller:EyeAngles():Forward() * 16384,
		filter = target == caller and target or {target, caller}
	}, target)

	local pos = tr.HitPos
	if target == caller and pos:Distance(target:GetPos()) < 64 then
		return false
	end

	if target:InVehicle() then
		target:ExitVehicle()
	end

	target.stalkermods_admin_returnAng = target:EyeAngles()
	target.stalkermods_admin_returnPos = target:GetPos()
	target:SetPos(pos)
	target:SetLocalVelocity(Vector(0, 0, 0))

	if target == caller then
		StalkersMods.Admin.Notify(caller, {
			"Teleported ",
			{StalkersMods.Admin.ColEnums.TARGET, "yourself"},
			"."
		})
	else
		StalkersMods.Admin.Notify(caller, {
			"Teleported ",
			{StalkersMods.Admin.ColEnums.TARGET, target:Nick()},
			"."
		})
	end

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


---------
-- Bring
---------
local cmd = StalkersMods.Admin.Command:New{
	Name = "bring",
	PrettyName = "Bring",
	Category = CATEGORY,
	Description = "Bring the target to yourself.",
	NeedsTargets = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't bring someone!")
		return false
	elseif not caller:Alive() then
		StalkersMods.Admin.Notify(caller, "You're not alive!")
		return false
	elseif caller:InVehicle() then
		StalkersMods.Admin.Notify(caller, "Leave your vehicle first.")
		return false
	end
	
	-- Thanks ULX.
	local t = {
		start = caller:GetPos(),
		filter = {caller},
		endpos = caller:GetPos(),
	}
	local tr = util.TraceEntity(t, caller)
	if tr.Hit then
		StalkersMods.Admin.Notify(caller, "Can't teleport when you're inside the world!")
		return false
	end

	local tpPlayers = {}
	for i = 1, #targets do
		local ply = targets[i]
		if not ply:Alive() then
			StalkersMods.Admin.Notify(caller, "Player "..ply:Nick().." is dead.")
		elseif ply ~= caller then
			table.insert(tpPlayers, ply)
		end
	end

	local playersInvolved = table.Copy(tpPlayers)
	table.insert(playersInvolved, caller)
	local affectedPlayers = {}
	local cell_size = 50
	for i = 1, #tpGrid do
		local c = tpGrid[i][1]
		local r = tpGrid[i][2]
		local target = table.remove(tpPlayers)
		if not target then
			break
		end

		local yawForward = caller:EyeAngles().yaw
		local offset = Vector(r * cell_size, c * cell_size, 0)
		offset:Rotate(Angle(0, yawForward, 0))

		local t = {}
		t.start = caller:GetPos() + Vector(0, 0, 32) -- Move them up a bit so they can travel across the ground
		t.filter = playersInvolved
		t.endpos = t.start + offset
		local tr = util.TraceEntity(t, target)

		if tr.Hit then
			table.insert(tpPlayers, target)
		else
			if target:InVehicle() then
				target:ExitVehicle()
			end
			target.stalkermods_admin_returnAng = target:EyeAngles()
			target.stalkermods_admin_returnPos = target:GetPos()
			target:SetPos(t.endpos)
			target:SetEyeAngles((caller:GetPos() - t.endpos):Angle())
			target:SetLocalVelocity(Vector(0, 0, 0))
			table.insert(affectedPlayers, target)
		end
	end

	if #tpPlayers > 0 then
		StalkersMods.Admin.Notify(caller, "Not enough room to bring everyone!")
	end
	if #affectedPlayers > 0 then
		StalkersMods.Admin.Notify(caller, {
			"Brought ",
			{StalkersMods.Admin.ColEnums.TARGET, StalkersMods.Admin.TargetsToText(affectedPlayers)},
			" to you."
		})
	end

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


--------
-- Goto
--------
local cmd = StalkersMods.Admin.Command:New{
	Name = "goto",
	PrettyName = "Goto",
	Category = CATEGORY,
	Description = "Go to someone.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't go to someone!")
		return false
	elseif not caller:Alive() then
		StalkersMods.Admin.Notify(caller, "You're not alive!")
		return false
	elseif caller:InVehicle() then
		StalkersMods.Admin.Notify(caller, "Leave your vehicle first.")
		return false
	elseif #targets ~= 1 then
		StalkersMods.Admin.Notify(caller, "You can only go to one person.")
		return false
	elseif not targets[1]:Alive() then
		StalkersMods.Admin.Notify(caller, {
			{StalkersMods.Admin.ColEnums.TARGET, targets[1]:Nick()},
			" is not alive!"
			})
		return false
	elseif targets[1]:InVehicle() and caller:GetMoveType() ~= MOVETYPE_NOCLIP then
		StalkersMods.Admin.Notify(caller, "Target is in a vehicle, try this command again while no-clipping.")
		return false
	end

	-- Thanks ULX	
	local newpos = playerSend(caller, targets[1], caller:GetMoveType() == MOVETYPE_NOCLIP)
	if not newpos then
		StalkersMods.Admin.Notify(caller, "Can't find a place to put you! No-clip and use this command to force a goto.")
		return
	end

	if caller:InVehicle() then
		caller:ExitVehicle()
	end

	local newang = (targets[1]:GetPos() - newpos):Angle()
	caller.stalkermods_admin_returnAng = caller:EyeAngles()
	caller.stalkermods_admin_returnPos = caller:GetPos()
	caller:SetPos(newpos)
	caller:SetEyeAngles(newang)
	caller:SetLocalVelocity(Vector(0, 0, 0))

	StalkersMods.Admin.Notify(caller, {
		"Teleported yourself to ",
		{StalkersMods.Admin.ColEnums.TARGET, targets[1]:Nick()},
		"."
	})

	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


--------
-- Send
--------
local cmd = StalkersMods.Admin.Command:New{
	Name = "send",
	PrettyName = "Send",
	Category = CATEGORY,
	Description = "Send a player to someone else.",
	ArgDescription = "<player to send target to>",
	NeedsTargets = true,
	HasNoArgs = false
}
function cmd:OnExecute(caller, args, targets)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't go to someone!")
		return false
	elseif #targets ~= 1 then
		StalkersMods.Admin.Notify(caller, "You can only send one person at a time.")
		return false
	elseif not args or #args == 0 then
		StalkersMods.Admin.Notify(caller, "No destination target found.")
		return false
	end
	
	local from = targets[1]
	local to = StalkersMods.Admin.GetPlayersByTargetQuery(ply, args[1])
	if not to or #to ~= 1 then
		StalkersMods.Admin.Notify(caller, "You can only send a player to a single other player.")
		return false
	else
		to = to[1]
	end

	if from == to then
		StalkersMods.Admin.Notify(caller, "You cannot send a target to themselves!")
		return false
	elseif not from:Alive() or not to:Alive() then
		local notif = {}
		if not from:Alive() and not to:Alive() then
			table.insert(notif, {
				{StalkersMods.Admin.ColEnums.TARGET, from:Alive()},
				" and ",
				{StalkersMods.Admin.ColEnums.TARGET, to:Alive()},
				" are both dead."
			})
		elseif not from:Alive() then
			table.insert(notif, {
				{StalkersMods.Admin.ColEnums.TARGET, from:Alive()},
				" is dead."
			})
		else
			table.insert(notif, {
				{StalkersMods.Admin.ColEnums.TARGET, to:Alive()},
				" is dead."
			})
		end
		StalkersMods.Admin.Notify(caller, notif)
		return false
	end

	if to:InVehicle() and from:GetMoveType() ~= MOVETYPE_NOCLIP then
		StalkersMods.Admin.Notify(caller, "Target is in a vehicle.")
		return false
	end

	local newpos = playerSend(from, to, from:GetMoveType() == MOVETYPE_NOCLIP)
	if not newpos then
		StalkersMods.Admin.Notify(caller, "Can't find a place to put them!")
		return false
	end

	if from:InVehicle() then
		from:ExitVehicle()
	end

	local newang = (from:GetPos() - newpos):Angle()
	from.stalkermods_admin_returnAng = from:EyeAngles()
	from.stalkermods_admin_returnPos = from:GetPos()
	from:SetPos(newpos)
	from:SetEyeAngles(newang)
	from:SetLocalVelocity(Vector(0, 0, 0))
	StalkersMods.Admin.Notify(caller, {
		"Sent ",
		{StalkersMods.Admin.ColEnums.TARGET, from:Nick()},
		" to ",
		{StalkersMods.Admin.ColEnums.ARGS, to:Nick()},
		"."
	})
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)


----------
-- Return
----------
local cmd = StalkersMods.Admin.Command:New{
	Name = "return",
	PrettyName = "Return",
	Category = CATEGORY,
	Description = "Return a player after they've been teleported somewhere.",
	NeedsTargets = true,
	NoTargetIsSelf = true,
	HasNoArgs = true
}
function cmd:OnExecute(caller, args, targets)
	if not IsValid(caller) then
		StalkersMods.Admin.Notify(caller, "The server can't return somewhere!")
		return false
	end
	
	local returnedPlayers = {}
	local failedPlayers = {}
	for i, ply in ipairs(targets) do
		if ply:Alive() and ply.stalkermods_admin_returnPos then
			if ply:InVehicle() then
				ply:ExitVehicle()
			end
			ply:SetPos(ply.stalkermods_admin_returnPos)
			ply:SetEyeAngles(ply.stalkermods_admin_returnAng)
			ply:SetLocalVelocity(Vector(0, 0, 0))
			ply.stalkermods_admin_returnPos = nil
			ply.stalkermods_admin_returnAng = nil
			table.insert(returnedPlayers, ply)
		else
			table.insert(failedPlayers, ply)
		end
	end

	local successPlys = StalkersMods.Admin.TargetsToText(returnedPlayers)
	local failedPlys = StalkersMods.Admin.TargetsToText(failedPlayers)
	if #successPlys == 0 then
		StalkersMods.Admin.Notify(caller, "Failed to return player(s). They were either not alive or had no return location.")
	elseif #failedPlys == 0 then
		StalkersMods.Admin.Notify(caller, {
			"Successfully returned ",
			{StalkersMods.Admin.ColEnums.TARGET, successPlys},
			"."
		})
	else
		StalkersMods.Admin.Notify(caller, {
			"Successfully returned ",
			{StalkersMods.Admin.ColEnums.TARGET, successPlys},
			", failed to return ",
			{StalkersMods.Admin.ColEnums.ARGS, failedPlys},
			"."
		})
	end
	return true
end
StalkersMods.Admin.RegisterCommand(cmd)