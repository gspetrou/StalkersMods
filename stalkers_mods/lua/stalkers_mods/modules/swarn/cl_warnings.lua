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
	StalkersMods.Warnings.OnlinePlayerWarnings = nil
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

----------------------------------------
-- StalkersMods.Warnings.SendNewWarning
----------------------------------------
-- Desc:		Asks the server to register a new warning.
-- Arg One:		String, steamid to warn.
-- Arg Two:		String, reason for warning.
function StalkersMods.Warnings.SendNewWarning(plySteamID, reason)
	if #reason >= 65533 then
		chat.AddText(Color(30, 144, 255), "[SWarn]", color_white, " Warning reason must be less than 65533 characters!")
	end

	net.Start("StalkersMods.Warnings.RequestAddWarn")
		net.WriteString(plySteamID)
		net.WriteString(reason)
	net.SendToServer()
end

--------------------------------------------------------------
-- StalkersMods.Warnings.RequestLatestWarningsOfOnlinePlayers
--------------------------------------------------------------
-- Desc:		Requests the server for the warning data of online players.
-- 				If they aren't allowed, then retrieves their own warnings.
function StalkersMods.Warnings.RequestLatestWarningsOfOnlinePlayers()
	StalkersMods.Warnings.WaitingOnOnlineWarnData = true
	net.Start("StalkersMods.Warnings.RequestOnlineWarns")
	net.SendToServer()
end

--------------------------------------------------
-- StalkersMods.Warnings.RequestWarningsOfSteamID
--------------------------------------------------
-- Desc:		Requests the warnings of a given steamid.
function StalkersMods.Warnings.RequestWarningsOfSteamID(steamID)
	net.Start("StalkersMods.Warnings.RequestBySteamID")
		net.WriteString(steamID)
	net.SendToServer()
end

-- Received from server, tells the client of the given player's warnings.
net.Receive("StalkersMods.Warnings.SyncOnlinePlys", function()
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

-- Received from the server to tell the client about the given steamid's warnings.
net.Receive("StalkersMods.Warnings.RequestBySteamID", function()
	local numWarnings = net.ReadUInt(12)
	local warnings = {}
	for i = 1, numWarnings do
		warnings[i] = StalkersMods.Warnings.ReadWarning()
	end

	local warnMenu = StalkersMods.Warnings.GetMenuPanel()
	if warnMenu then
		warnMenu:UpdateOfflinePlayerPanel(warnings)
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
		WIDTH = 800,
		HEIGHT = 500,
		OfflineSearchBarTall = 40
	}

	function PANEL:Init()
		self:SetName("StalkersMods.Warnings.Menu")
		self:SetTitle("SWarn - Warnings Mod")
		self:SetSize(self.WIDTH, self.HEIGHT)
		self:Center()
		self:MakePopup()

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

		-- Offline player data.
		self.OfflineSearchState = "blank"
		self.OfflineWarningsList = nil
		self.OfflinePlayersSheet = vgui.Create("DPanel", self.PropertySheet)
		self.OfflinePlayersSheet.SearchPanel = vgui.Create("DPanel", self.OfflinePlayersSheet)
		self.OfflinePlayersSheet.SearchPanel:SetPos(0, 0)
		self.OfflinePlayersSheet.SearchPanel:SetTall(self.OfflineSearchBarTall)
		self.OfflinePlayersSheet.SearchPanel:Dock(TOP)
		function self.OfflinePlayersSheet.SearchPanel:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
		end
		self.OfflinePlayersSheet.SearchPanel.SearchLabel = vgui.Create("DLabel", self.OfflinePlayersSheet.SearchPanel)
		self.OfflinePlayersSheet.SearchPanel.SearchLabel:SetText("Search SteamID:")
		self.OfflinePlayersSheet.SearchPanel.SearchLabel:SizeToContents()
		self.OfflinePlayersSheet.SearchPanel.SearchLabel:SetPos(10, self.OfflineSearchBarTall/2 - self.OfflinePlayersSheet.SearchPanel.SearchLabel:GetTall()/2)
		self.OfflinePlayersSheet.SearchPanel.SearchLabel:SetTextColor(Color(255, 255, 255, 255))

		self.OfflinePlayersSheet.SearchPanel.SearchBar = vgui.Create("DTextEntry", self.OfflinePlayersSheet.SearchPanel)
		self.OfflinePlayersSheet.SearchPanel.SearchBar:SetPos(100, 5)
		self.OfflinePlayersSheet.SearchPanel.SearchBar:SetSize(200, 30)
		self.OfflinePlayersSheet.SearchPanel.SearchBar:SetValue("")
		self.OfflinePlayersSheet.SearchPanel.SearchBar:SetPlaceholderText("STEAM_0:1:123456789")

		self.OfflinePlayersSheet.SearchPanel.SearchButton = vgui.Create("DButton", self.OfflinePlayersSheet.SearchPanel)
		self.OfflinePlayersSheet.SearchPanel.SearchButton:SetText("Search")
		self.OfflinePlayersSheet.SearchPanel.SearchButton:SetPos(305, 5)
		self.OfflinePlayersSheet.SearchPanel.SearchButton:SetSize(80, 30)
		self.OfflinePlayersSheet.SearchPanel.SearchButton.DoClick = function()
			local searchSteamID = self.OfflinePlayersSheet.SearchPanel.SearchBar:GetText()
			if not StalkersMods.Utility.IsSteamID32(searchSteamID) then
				self.OfflineSearchState = "invalid"
			else
				self.OfflineSearchState = "searching"
				StalkersMods.Warnings.RequestWarningsOfSteamID(searchSteamID)
			end
		end

		self.OfflinePlayersSheet.PlayerWarnList = vgui.Create("DScrollPanel", self.OfflinePlayersSheet)
		self.OfflinePlayersSheet.PlayerWarnList:SetPos(0, self.OfflineSearchBarTall)
		self.OfflinePlayersSheet.PlayerWarnList:Dock(FILL)
		self.OfflinePlayersSheet.PlayerWarnList.Paint = function(panelList, w, h)
			if not self.OfflineSearchState or self.OfflineSearchState == "blank" then
				return
			end

			surface.SetFont("StalkersMods.Warnings.LoadingFont")
			local noticeText = ""
			
			if self.OfflineSearchState == "searching" then
				noticeText = "Searching..."
			elseif self.OfflineSearchState == "noresult" then
				noticeText = "No result found"
			else
				noticeText = "Invalid input"
			end

			local textW, textH = surface.GetTextSize(noticeText)
			surface.SetTextPos(w/2 - textW/2, h/2 - textH/2)
			surface.SetTextColor(0, 0, 0, 255)
			surface.DrawText(noticeText)
		end

		self.OfflinePlayersSheet.SearchPanel.AddOfflineWarnButton = vgui.Create("DButton", self.OfflinePlayersSheet.SearchPanel)
		CAMI.PlayerHasAccess(LocalPlayer(), StalkersMods.Warnings.Privileges.ADD.Name, function(allowed)
			if not allowed then
				self.OfflinePlayersSheet.SearchPanel.AddOfflineWarnButton:SetVisible(false)
				return
			end
			
			self.OfflinePlayersSheet.SearchPanel.AddOfflineWarnButton:SetText("Add Warning by SteamID")
			self.OfflinePlayersSheet.SearchPanel.AddOfflineWarnButton:SetSize(140, 30)
			self.OfflinePlayersSheet.SearchPanel.AddOfflineWarnButton:SetPos(self.WIDTH - 170, 5)
			self.OfflinePlayersSheet.SearchPanel.AddOfflineWarnButton.DoClick = function()
				local frame = vgui.Create("DFrame")
				frame:SetTitle("Give warning to SteamID")
				frame:SetDraggable(false)
				frame:ShowCloseButton(true)
				frame:SetBackgroundBlur(true)
				frame:SetDrawOnTop(true)

				local containningPanel = vgui.Create("DPanel", frame)
				containningPanel:SetPaintBackground(false)
				containningPanel:Dock(FILL)

				local steamidToWarnLabel = vgui.Create("DLabel", containningPanel)
				steamidToWarnLabel:SetText("Enter SteamID of player to warn:")
				steamidToWarnLabel:SizeToContents()
				steamidToWarnLabel:SetContentAlignment(5)
				steamidToWarnLabel:SetTextColor(color_white)
				local steamidTextEntry = vgui.Create("DTextEntry", containningPanel)
				steamidTextEntry:SetText("")
				steamidTextEntry:SetPlaceholderText("STEAM_0:1:23456789")
				steamidTextEntry:SetSize(225, 25)
				
				local reasonLabel = vgui.Create("DLabel", containningPanel)
				reasonLabel:SetText("Enter reason for the warning:")
				reasonLabel:SizeToContents()
				reasonLabel:SetContentAlignment(5)
				reasonLabel:SetTextColor(color_white)
				local reasonTextEntry = vgui.Create("DTextEntry", containningPanel)
				reasonTextEntry:SetText("")
				reasonTextEntry:SetSize(225, 25)
				
				local submitButton = vgui.Create("DButton", containningPanel)
				submitButton:SetText("Submit")
				submitButton.DoClick = function()
					local steamID = steamidTextEntry:GetText()
					local reason = reasonTextEntry:GetText()

					if not steamID or not StalkersMods.Utility.IsSteamID32(steamID) then
						chat.AddText(Color(30, 144, 255), "[SWarn]", color_white, " Entered invalid SteamID.")
					elseif not reason or reason == "" then
						chat.AddText(Color(30, 144, 255), "[SWarn]", color_white, " You must enter a reason.")
					else
						StalkersMods.Warnings.SendNewWarning(steamID, reason)
						chat.AddText(Color(30, 144, 255), "[SWarn]", color_white, " Submitted new warning for SteamID '"..steamID.."'.")
					end

					StalkersMods.Warnings.CloseMenu()
					frame:Close()
				end
				local closeButton = vgui.Create("DButton", containningPanel)
				closeButton:SetText("Cancel")
				closeButton.DoClick = function() frame:Close() end

				local frameW, frameH = 300, 160
				frame:SetSize(frameW, frameH)
				frame:Center()

				steamidToWarnLabel:SetPos(frameW/2 - steamidToWarnLabel:GetWide()/2, 0)
				steamidTextEntry:SetPos(frameW/2 - steamidTextEntry:GetWide()/2, 20)
				reasonLabel:SetPos(frameW/2 - reasonLabel:GetWide()/2, 50)
				reasonTextEntry:SetPos(frameW/2 - reasonTextEntry:GetWide()/2, 70)
				submitButton:SetPos(frameW/2 - submitButton:GetWide() - 1, 100)
				closeButton:SetPos(frameW/2 + 1, 100)

				frame:MakePopup()
				frame:DoModal()
			end
		end)
		
		self.PropertySheet:AddSheet("Offline Players", self.OfflinePlayersSheet, "icon16/table_edit.png")
	end

	function PANEL:UpdateOnlinePlayerPanel()
		self.OnlinePlayersSheet:SetWarnData(StalkersMods.Warnings.OnlinePlayerWarnings)
	end

	function PANEL:UpdateOfflinePlayerPanel(warns)
		self.OfflineWarningsList = warns
		if #self.OfflineWarningsList == 0 then
			self.OfflineSearchState = "noresult"
		else
			table.sort(self.OfflineWarningsList, function(warnA, warnB)
				return warnA:GetTimeStamp() > warnB:GetTimeStamp()
			end)

			for i, warnObj in ipairs(self.OfflineWarningsList) do
				local warningBar = self.OfflinePlayersSheet.PlayerWarnList:Add("StalkersMods.Warnings.WarningBar")
				warningBar:SetWarnData(warnObj)
				warningBar:SetTall(100)
				warningBar:Dock(TOP)
				warningBar:SetDarker(i % 2 == 0 and true or false)
			end
			self.OfflineSearchState = "blank"
		end
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
		
		-- Controls for the given player's warns.
		self.PlayerWarnControls = vgui.Create("DPanel", self)
		self.PlayerWarnControls:SetVisible(false)
		self.PlayerWarnControls.NameLabel = vgui.Create("DLabel", self.PlayerWarnControls)
		self.PlayerWarnControls.NameLabel:SetText("")
		self.PlayerWarnControls.NameLabel:SetFont("StalkersMods.Warnings.PlayerName")
		self.PlayerWarnControls.NameLabel:SetTextColor(Color(0, 0, 0, 255))
		self.PlayerWarnControls.CopySteamID = vgui.Create("DButton", self.PlayerWarnControls)
		self.PlayerWarnControls.CopySteamID:SetText("Copy SteamID")
		self.PlayerWarnControls.CopySteamID:SetVisible(false)
		self.PlayerWarnControls.AddWarnButton = vgui.Create("DButton", self.PlayerWarnControls)
		self.PlayerWarnControls.AddWarnButton:SetText("Add Warning")
		self.PlayerWarnControls.AddWarnButton:SetVisible(false)

		-- List of warns of that player.
		self.PlayerWarnScroll = vgui.Create("DScrollPanel", self)
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

		CAMI.PlayerHasAccess(LocalPlayer(), StalkersMods.Warnings.Privileges.ADD.Name, function(allowed)
			if allowed then
				self.PlayerWarnControls.CopySteamID:SetSize(self.AddWarnButtonWidth, self.PlayerWarnControlsHeight/2)
				self.PlayerWarnControls.CopySteamID:SetPos(plyWarnScrollListWidth - self.AddWarnButtonWidth, 0)
			else
				self.PlayerWarnControls.CopySteamID:SetSize(self.AddWarnButtonWidth, self.PlayerWarnControlsHeight)
				self.PlayerWarnControls.CopySteamID:SetPos(plyWarnScrollListWidth - self.AddWarnButtonWidth, 0)
			end			
		end)

		self.PlayerWarnControls.AddWarnButton:SetSize(self.AddWarnButtonWidth, self.PlayerWarnControlsHeight/2)
		self.PlayerWarnControls.AddWarnButton:SetPos(plyWarnScrollListWidth - self.AddWarnButtonWidth, self.PlayerWarnControlsHeight/2)

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
		self.PlayerWarnControls.CopySteamID.DoClick = function(slfButton)
			SetClipboardText(steamID)
			chat.AddText(Color(30, 144, 255), "[SWarn]", color_white, " Player's SteamID copied to clipboard ("..steamID..").")
		end
		self.PlayerWarnControls:SetVisible(true)
		self.PlayerWarnControls:InvalidateLayout()
		self.PlayerWarnControls.CopySteamID:SetVisible(true)
		self.PlayerWarnControls.CopySteamID:InvalidateLayout()

		CAMI.PlayerHasAccess(LocalPlayer(), StalkersMods.Warnings.Privileges.ADD.Name, function(allowed)
			if not allowed then
				return
			end

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
		end)

		if warnsForPlayer and #warnsForPlayer > 0 then
			table.sort(warnsForPlayer, function(warnA, warnB)
				return warnA:GetTimeStamp() > warnB:GetTimeStamp()
			end)
			
			for i, warn in ipairs(warnsForPlayer) do
				local warningBar = self.PlayerWarnScroll:Add("StalkersMods.Warnings.WarningBar")
				warningBar:SetWarnData(warn)
				warningBar:SetTall(100)
				warningBar:Dock(TOP)
				warningBar:SetDarker(i % 2 == 0 and true or false)
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

------------------------------------
-- StalkersMods.Warnings.WarningBar
------------------------------------
-- Desc:		A vgui element for describing the details of a StalkersMods.Warnings.WarningClass object.
do
	local PANEL = {
		darkerColor = Color(40, 40, 40, 255),
		lighterColor = Color(70, 70, 70, 255)
	}

	function PANEL:Init()
		self.Warn = nil
		self.BGColor = self.lighterColor

		-- Warned By Info
		self.WarnedByHeader = vgui.Create("DLabel", self)
		self.WarnedByHeader:SetText("Warned by:")
		self.WarnedByHeader:SizeToContents()
		self.WarnedByHeader:SetPos(5, 5)

		self.WarnedBySteamID = vgui.Create("DLabel", self)
		self.WarnedBySteamID:SetText(" ")
		self.WarnedBySteamID:SizeToContents()
		self.WarnedBySteamID:SetPos(5, 20)
		self.WarnedBySteamID:SetMouseInputEnabled(true)
		self.WarnedBySteamID:SetCursor("hand")
		function self.WarnedBySteamID:DoClick()
			SetClipboardText(self:GetText())
			chat.AddText(Color(30, 144, 255), "[SWarn]", color_white, " Copied SteamID of player giving the warning to clipboard.")
		end

		self.WarnedByNick = vgui.Create("DLabel", self)
		self.WarnedByNick:SetText(" ")
		self.WarnedByNick:SizeToContents()
		self.WarnedByNick:SetPos(5, 35)
		self.WarnedByNick:SetMouseInputEnabled(true)
		self.WarnedByNick:SetCursor("hand")
		function self.WarnedByNick:DoClick()
			SetClipboardText(self:GetText())
			chat.AddText(Color(30, 144, 255), "[SWarn]", color_white, " Copied nickname of player giving the warning to clipboard.")
		end

		-- Delete button
		self.DeleteButton = vgui.Create("DImageButton", self)
		CAMI.PlayerHasAccess(LocalPlayer(), StalkersMods.Warnings.Privileges.DELETE.Name, function(allowed)
			if not allowed then
				self.DeleteButton:SetVisible(false)
				return
			end
			
			self.DeleteButton:SetImage("icon16/delete.png")
			self.DeleteButton:SetTooltip("Delete Warning")
			self.DeleteButton.DoClick = function()
				Derma_Query("Are you sure you would like to delete this warning?", "Delete Warning", "Yes", function()
					StalkersMods.Warnings.CloseMenu()

					if self.Warn and self.Warn:GetUniqueID() then
						net.Start("StalkersMods.Warnings.RequestDeleteWarn")
							net.WriteString(self.Warn:GetUniqueID())
						net.SendToServer()
					end
				end, "Cancel")
			end
		end)

		-- Reason
		self.ReasonHeader = vgui.Create("DLabel", self)
		self.ReasonHeader:SetText("Reason:")
		self.ReasonHeader:SizeToContents()
		self.ReasonHeader:SetPos(175, 5)

		self.ReasonText = vgui.Create("RichText", self)
		self.ReasonText:InsertColorChange(255, 255, 255, 255)
		self.ReasonText:SetText("")
		self.ReasonText:SetMouseInputEnabled(true)
		self.ReasonText:SetCursor("beam")
		function self.ReasonText:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(20, 20, 20))
		end
	end

	function PANEL:SetWarnData(data)
		self.Warn = data
		self.WarnedBySteamID:SetText(self.Warn:GetOwnerSteamID())
		self.WarnedByNick:SetText(self.Warn:GetGivenByNick())

		self.ReasonText:AppendText(self.Warn:GetDescription())

		self.WarnedBySteamID:SizeToContents()
		self.WarnedByNick:SizeToContents()
	end

	function PANEL:Paint(w, h)
		draw.RoundedBox(0, 0, 0, w, h, self.BGColor)
	end

	function PANEL:SetDarker(b)
		self.BGColor = b and self.darkerColor or self.lighterColor
	end

	function PANEL:PerformLayout(w, h)
		self.ReasonText:SetPos(175, 20)
		self.ReasonText:SetSize(w - 175 - 5, h - 25)

		self.DeleteButton:SetSize(16, 16)
		self.DeleteButton:SetPos(5, h - 21)
	end
	vgui.Register("StalkersMods.Warnings.WarningBar", PANEL, "DPanel")
end