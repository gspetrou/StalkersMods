if CLIENT then
	-- Otherwise the physgun will still be visible for invisible players and that seems dumb.
	hook.Add("DrawPhysgunBeam", "StalkersMods.DisablePhysgunBeamOnNoDraw", function(ply)
		if ply:GetNoDraw() then
			return false
		end
	end)
end