StalkersMods.F4Menu = StalkersMods.F4Menu or {}

-- Toggles the f4 menu.
concommand.Add("sf4menu", function()
	StalkersMods.F4Menu.ToggleMenu()
end)

----------------------------------
-- StalkersMods.F4Menu.ToggleMenu
----------------------------------
-- Desc:		Toggles the f4 menu open or closed.
function StalkersMods.F4Menu.ToggleMenu()
	if StalkersMods.F4Menu.IsMenuValid() and StalkersMods.F4Menu.GetMenuPanel():IsVisible() then
		StalkersMods.F4Menu.CloseMenu()
	else
		StalkersMods.F4Menu.OpenMenu()
	end
end

--------------------------------
-- StalkersMods.F4Menu.OpenMenu
--------------------------------
-- Desc:		Opens the f4 menu.
function StalkersMods.F4Menu.OpenMenu()
	if StalkersMods.F4Menu.IsMenuValid() then
		StalkersMods.F4Menu.MenuPanel:Show()
	else
		StalkersMods.F4Menu.MenuPanel = vgui.Create("StalkersMods.F4Menu")
	end
end

---------------------------------
-- StalkersMods.F4Menu.CloseMenu
---------------------------------
-- Desc:		Closes the f4 menu if its open.
function StalkersMods.F4Menu.CloseMenu()
	if StalkersMods.F4Menu.IsMenuValid() then
		StalkersMods.F4Menu.MenuPanel:Hide()
	end
end

-----------------------------------
-- StalkersMods.F4Menu.IsMenuValid
-----------------------------------
-- Desc:		Is the f4 menu valid.
-- Returns:		Boolean.
function StalkersMods.F4Menu.IsMenuValid()
	return IsValid(StalkersMods.F4Menu.MenuPanel)
end

------------------------------------
-- StalkersMods.F4Menu.GetMenuPanel
------------------------------------
-- Desc:		Gets the f4 menu panel.
-- Returns:		StalkersMods.F4Menu element.
function StalkersMods.F4Menu.GetMenuPanel()
	return StalkersMods.F4Menu.IsMenuValid() and StalkersMods.F4Menu.MenuPanel or false
end

-----------------------------------
-- StalkersMods.F4Menu.DeletePanel
-----------------------------------
-- Desc:		Deletes the f4 menu panel to make a new one later.
function StalkersMods.F4Menu.DeletePanel()
	if IsValid(StalkersMods.F4Menu.MenuPanel) then
		StalkersMods.F4Menu.MenuPanel:Remove()
	end
	StalkersMods.F4Menu.MenuPanel = nil
end

-- TODO: Remove this autorefresh tool
if StalkersMods.F4Menu.IsMenuValid() and StalkersMods.F4Menu.GetMenuPanel():IsVisible() then
	StalkersMods.F4Menu.DeletePanel()
	timer.Simple(0, function() StalkersMods.F4Menu.OpenMenu() end)
end

-----------------------
-- StalkersMods.F4Menu
-----------------------
-- Desc:		The f4 menu panel.
do
	local PANEL = {
		Name = "StalkersMods.F4Menu",
		Description = "Stalker's Custom F4 Menu",
		Title = "Stalker's DarkRP Server",
		WidthPercent = 0.85,
		HeightPercent = 0.85
	}

	function PANEL:Init()
		self:SetName(self.Name)
		self:SetTitle(self.Title)
		StalkersMods.Utility.SetupPanelBlur(self)
		self:Refresh()
	end

	function PANEL:Show()
		self:Refresh()
		self:SetVisible(true)
		gui.EnableScreenClicker(true)
	end

	function PANEL:Hide()
		self:SetVisible(false)
		gui.EnableScreenClicker(false)
	end

	function PANEL:Close()
		self:Hide()
	end

	function PANEL:OnRemove()
		gui.EnableScreenClicker(false)
	end

	function PANEL:Refresh()
		self:SetSize(ScrW() * self.WidthPercent, ScrH() * self.HeightPercent)
		self:InvalidateLayout()
		self:Center()
		self:MakePopup()
	end

	function PANEL:Paint(w, h)
		-- Blur the panel.
		self:BlurPanel()

		-- Add a darkness to the blur (spooky).
		surface.SetDrawColor(10, 10, 10, 200)
		surface.DrawRect(0, 0, w, h)

		-- Add an outline.
		surface.SetDrawColor(30, 30, 30, 200)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	derma.DefineControl(PANEL.Name, PANEL.Description, PANEL, "DFrame")
end