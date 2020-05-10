if CLIENT then
	-- Dsaible drawing of the physgun beam/glow if a player is nodrawn.
	hook.Add("DrawPhysgunBeam", "StalkersMods.DisablePhysgunBeamOnNoDraw", function(ply)
		if ply:GetNoDraw() then
			return false
		end
	end)
end