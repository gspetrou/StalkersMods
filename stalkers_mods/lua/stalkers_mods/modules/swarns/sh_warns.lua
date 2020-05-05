StalkersMods.Warnings = StalkersMods.Warnings or {}

function StalkersMods.Warnings.WriteWarning(warningObj)
	net.WriteString(warningObj:GetOwnerSteamID())
	net.WriteString(warningObj:GetOwnerNick())
	net.WriteString(warningObj:GetGivenBySteamID())
	net.WriteString(warningObj:GetGivenByNick())
	net.WriteString(warningObj:GetDescription())
	net.WriteString(tostring(warningObj:GetTimeStamp()))
end

function StalkersMods.Warnings.ReadWarning()
	return StalkersMods.Warnings.WarningClass:New({
		OwnerSteamID = net.ReadString(),
		OwnerNick = net.ReadString(),
		GivenBySteamID = net.ReadString(),
		GivenByNick = net.ReadString(),
		Description = net.ReadString(),
		TimeStamp = tonumber(net.ReadString())
	})
end