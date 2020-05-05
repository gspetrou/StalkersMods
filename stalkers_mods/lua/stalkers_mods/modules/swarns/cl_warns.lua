StalkersMods.Warnings = StalkersMods.Warnings or {}

hook.Add("StalkersMods.Admin.AddCustomOptions", "StalkersMods.Warnings.AddToAdminMenu", function(sadminMenu)
	sadminMenu:AddOption("Open Warnings", function()
		RunConsoleCommand("swarn_menu")
	end):SetIcon("icon16/exclamation.png")
end)

concommand.Add("swarn_menu", function()
	StalkersMods.Warnings.ToggleMenu()
end)

------------------------------------
-- StalkersMods.Warnings.ToggleMenu
------------------------------------
-- Desc:		Toggles the warnings menu open or close.
function StalkersMods.Warnings.ToggleMenu()
	if StalkersMods.Warnings.IsMenuOpen() then
		StalkersMods.Warnings.CloseMenu()
	else
		StalkersMods.Warnings.OpenMenu()
	end
end

----------------------------------
-- StalkersMods.Warnings.OpenMenu
----------------------------------
-- Desc:		Opens the warnings menu.
function StalkersMods.Warnings.OpenMenu()
	StalkersMods.Warnings.RequestLatestWarningsOfOnlinePlayers()
	StalkersMods.Warnings.CloseMenu()
	StalkersMods.Warnings.MenuPanel = vgui.Create("StalkersMods.Warnings.Menu")
	gui.EnableScreenClicker(true)
end

-----------------------------------
-- StalkersMods.Warnings.CloseMenu
-----------------------------------
-- Desc:		Closes the warning menu.
function StalkersMods.Warnings.CloseMenu()
	if IsValid(StalkersMods.Warnings.MenuPanel) then
		StalkersMods.Warnings.MenuPanel:Remove()
		StalkersMods.Warnings.MenuPanel = nil
	end
	gui.EnableScreenClicker(false)
end

------------------------------------
-- StalkersMods.Warnings.IsMenuOpen
------------------------------------
-- Desc:		Is the warnings menu open.
-- Returns:		Boolean.
function StalkersMods.Warnings.IsMenuOpen()
	return IsValid(StalkersMods.Warnings.MenuPanel)
end

--------------------------------------
-- StalkersMods.Warnings.GetMenuPanel
--------------------------------------
-- Desc:		Gets the warning menu panel if its valid.
-- Returns:		StalkersMods.Warnings.Menu panel, or false if we failed.
function StalkersMods.Warnings.GetMenuPanel()
	return IsValid(StalkersMods.Warnings.MenuPanel) and StalkersMods.Warnings.MenuPanel or false
end

function StalkersMods.Warnings.SendNewWarning(plySteamID, reason)
	net.Start("StalkersMods.Warnings.RequestAddWarn")
		net.WriteString(plySteamID)
		net.WriteString(reason)
	net.SendToServer()
end

function StalkersMods.Warnings.RequestLatestWarningsOfOnlinePlayers()
	StalkersMods.Warnings.WaitingOnOnlineWarnData = true
	net.Start("StalkersMods.Warnings.RequestOnlineWarns")
	net.SendToServer()
end

net.Receive("StalkersMods.Warings.SyncOnlinePlys", function()
	StalkersMods.Warnings.OnlinePlayerWarnings = {}

	local numWarns = net.ReadUInt(12)
	for i = 1, numWarns do
		local warn = StalkersMods.Warnings.ReadWarning()
		if not StalkersMods.Warnings.OnlinePlayerWarnings[warn:GetOwnerSteamID()] then
			StalkersMods.Warnings.OnlinePlayerWarnings[warn:GetOwnerSteamID()] = {warn}
		else
			table.insert(StalkersMods.Warnings.OnlinePlayerWarnings[warn:GetOwnerSteamID()], warn)
		end
	end

	if StalkersMods.Warnings.WaitingOnOnlineWarnData then
		StalkersMods.Warnings.WaitingOnOnlineWarnData = false

		local warnMenu = StalkersMods.Warnings.GetMenuPanel()
		if warnMenu then
			warnMenu:UpdateOnlinePlayerPanel()
		end
	end
end)

surface.CreateFont("StalkersMods.Warnings.LoadingFont", {
	font = "DermaDefaultBold",
	extended = false,
	size = 50,
	weight = 700,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

surface.CreateFont("StalkersMods.Warnings.PlayerName", {
	font = "Roboto",
	extended = false,
	size = 40,
	weight = 700,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
})

------------------------------
-- StalkersMods.Warnings.Menu
------------------------------
-- Desc:		A vgui for the SWarn warnings system.
do
	local PANEL = {
		WIDTH = 700,
		HEIGHT = 500
	}

	function PANEL:Init()
		self:SetName("StalkersMods.Warnings.Menu")
		self:SetTitle("SWarn - Warnings Mod")
		self:SetSize(self.WIDTH, self.HEIGHT)
		self:Center()

		-- Containning property sheet.
		self.PropertySheet = vgui.Create("DPropertySheet", self)
		self.PropertySheet:Dock(FILL)

		-- Online player data.
		self.OnlinePlayersSheet = vgui.Create("StalkersMods.Warnings.WarnsDisplayPanel", self.PropertySheet)
		function self.OnlinePlayersSheet:Paint(w, h)
			if StalkersMods.Warnings.WaitingOnOnlineWarnData then
				surface.SetFont("StalkersMods.Warnings.LoadingFont")
				local text = "Loading..."
				local textW, textH = surface.GetTextSize(text)
				surface.SetTextPos(w/2 - textW/2, h/2 - textH/2)
				surface.SetTextColor(0, 0, 0, 255)
				surface.DrawText(text)
			else
				self.BaseClass.Paint(self, w, h)
			end
		end
		self.PropertySheet:AddSheet("Online Players", self.OnlinePlayersSheet, "icon16/user.png")

		-- Online player data.
		self.OfflinePlayersSheet = vgui.Create("DPanel", self.PropertySheet)
		self.PropertySheet:AddSheet("Offline Players", self.OfflinePlayersSheet, "icon16/table_edit.png")
	end

	function PANEL:UpdateOnlinePlayerPanel()
		self.OnlinePlayersSheet:SetWarnData(StalkersMods.Warnings.OnlinePlayerWarnings)
	end

	function PANEL:OnClose()
		gui.EnableScreenClicker(false)
	end

	vgui.Register("StalkersMods.Warnings.Menu", PANEL, "DFrame")
end

-------------------------------------------
-- StalkersMods.Warnings.WarnsDisplayPanel
-------------------------------------------
-- Desc:		A DPanel derived vgui element that displays the warnings of its given warn objects.
do
	local PANEL = {
		PlayerWarnControlsHeight = 40,
		AddWarnButtonWidth = 80
	}

	function PANEL:Init()
		self.WarnData = {}

		-- List of players to view warns of.
		self.PlayerListScroll = vgui.Create("DScrollPanel", self)
		--function self.PlayerListScroll:Paint(w,h) draw.RoundedBox(0, 0, 0, w, h, Color(255,0,0)) end
		
		-- Controls for the given player's warns.
		self.PlayerWarnControls = vgui.Create("DPanel", self)
		self.PlayerWarnControls.NameLabel = vgui.Create("DLabel", self.PlayerWarnControls)
		self.PlayerWarnControls.NameLabel:SetText("")
		self.PlayerWarnControls.NameLabel:SetFont("StalkersMods.Warnings.PlayerName")
		self.PlayerWarnControls.NameLabel:SetTextColor(Color(0, 0, 0, 255))
		self.PlayerWarnControls.AddWarnButton = vgui.Create("DButton", self.PlayerWarnControls)
		self.PlayerWarnControls.AddWarnButton:SetText("Add Warning")
		self.PlayerWarnControls.AddWarnButton:SetVisible(false)
		--function self.PlayerWarnControls:Paint(w,h) draw.RoundedBox(0, 0, 0, w, h, Color(255,0,0)) end

		-- List of warns of that player.
		self.PlayerWarnScroll = vgui.Create("DScrollPanel", self)
		--function self.PlayerWarnScroll:Paint(w,h) draw.RoundedBox(0, 0, 0, w, h, Color(0,255,0)) end
	end

	function PANEL:PerformLayout(w, h)
		local plyScrollListWidth = w/3
		local plyWarnScrollListWidth = w - plyScrollListWidth

		self.PlayerListScroll:SetPos(0, 0)
		self.PlayerListScroll:SetSize(plyScrollListWidth, h)

		self.PlayerWarnControls:SetPos(plyScrollListWidth, 0)
		self.PlayerWarnControls:SetSize(plyWarnScrollListWidth, self.PlayerWarnControlsHeight)
		self.PlayerWarnControls.NameLabel:SetSize(plyWarnScrollListWidth - self.AddWarnButtonWidth, self.PlayerWarnControlsHeight)
		self.PlayerWarnControls.NameLabel:SetPos(0, 0)
		self.PlayerWarnControls.AddWarnButton:SetSize(self.AddWarnButtonWidth, self.PlayerWarnControlsHeight)
		self.PlayerWarnControls.AddWarnButton:SetPos(plyWarnScrollListWidth - self.AddWarnButtonWidth, 0)

		self.PlayerWarnScroll:SetPos(plyScrollListWidth, self.PlayerWarnControlsHeight)
		self.PlayerWarnScroll:SetSize(plyWarnScrollListWidth, h - self.PlayerWarnControlsHeight)
	end

	function PANEL:SetWarnData(data)
		self.WarnData = data
		self:BuildFromWarnData()
	end

	function PANEL:BuildFromWarnData()
		local sortedPlys = player.GetAll()
		table.sort(sortedPlys, function(plyA, plyB)
			return plyA:Nick() < plyB:Nick()
		end)

		for i, ply in ipairs(sortedPlys) do
			local plyButton = self.PlayerListScroll:Add("DButton")
			plyButton:SetText(ply:Nick())
			plyButton:Dock(TOP)
			plyButton:DockMargin(2, 2, 2, 2)
			local plySteamID = ply:SteamID()
			plyButton.DoClick = function(pnl)
				self:PopuplateWarnScrollForSteamID(plySteamID)
			end
		end
	end

	function PANEL:PopuplateWarnScrollForSteamID(steamID)
		self.PlayerWarnScroll:Clear()
		local warnsForPlayer = self.WarnData[steamID]
		local ply = player.GetBySteamID(steamID)

		self.PlayerWarnControls.NameLabel:SetText(ply:Nick())
		self.PlayerWarnControls.NameLabel:SizeToContents()
		self.PlayerWarnControls.AddWarnButton.DoClick = function(slfButton)
			Derma_StringRequest(
				"Warn player: "..ply:Nick().." ("..steamID..")",
				"Please give a reason for your warning:",
				"",
				function(text)
					StalkersMods.Warnings.SendNewWarning(steamID, text or "")
					StalkersMods.Warnings.CloseMenu()
				end,
				nil, "Confirm", "Cancel"
			)
		end
		self.PlayerWarnControls.AddWarnButton:SetVisible(true)
		self.PlayerWarnControls.AddWarnButton:InvalidateLayout()

		if warnsForPlayer and #warnsForPlayer > 0 then
			for i, warn in ipairs(warnsForPlayer) do
				local warningBar = self.PlayerWarnScroll:Add("StalkersMods.Warnings.WarningBar")
				warningBar:SetWarnData(warn)
				-- TODO: Format how this is displayed
			end
		else
			self:InvalidateLayout()	-- Size self.PlayerWarnScroll right.

			local plyButton = self.PlayerWarnScroll:Add("DLabel")
			plyButton:SetTextColor(Color(0, 0, 0, 255))
			plyButton:SetText("This player has no warnings")
			plyButton:SizeToContents()
			local parentW, parentH = self.PlayerWarnScroll:GetSize()
			local selfW, selfH = plyButton:GetSize()
			plyButton:SetPos(parentW/2 - selfW/2, parentH/2 - selfH/2)
		end
	end

	vgui.Register("StalkersMods.Warnings.WarnsDisplayPanel", PANEL, "DPanel")
end

do
	local PANEL = {}

	function PANEL:Init()
		self.Warn = nil
	end

	function PANEL:SetWarnData(data)
		self.Warn = data
	end

	function PANEL:Paint(w, h)
		draw.RoundedBox(0,0,0,w,h, Color(255, 255, 0, 255))
	end

	vgui.Register("StalkersMods.Warnings.WarningBar", PANEL, "DPanel")
end