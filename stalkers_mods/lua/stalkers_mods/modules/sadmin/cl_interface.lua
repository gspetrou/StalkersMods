StalkersMods.Admin = StalkersMods.Admin or {}
StalkersMods.Admin.Menu = StalkersMods.Admin.Menu or {}

concommand.Add("sadmin_menu", function()
	if StalkersMods.Admin.Menu.IsOpen() then
		StalkersMods.Admin.Menu.Close()
	else
		StalkersMods.Admin.Menu.Open()
	end
end)

function StalkersMods.Admin.Menu.IsOpen()
	return IsValid(StalkersMods.Admin.Menu.Panel)
end

function StalkersMods.Admin.Menu.Open()
	if StalkersMods.Admin.Menu.IsOpen() then
		StalkersMods.Admin.Menu.Close()
	end

	StalkersMods.Admin.Menu.Panel = vgui.Create("StalkersMods.Admin.Menu")
	StalkersMods.Admin.Menu.Panel:SetPos(100, 100)
	gui.EnableScreenClicker(true)
end

function StalkersMods.Admin.Menu.Close()
	if StalkersMods.Admin.Menu.IsOpen() then
		StalkersMods.Admin.Menu.Panel:Remove()
		StalkersMods.Admin.Menu.Panel = nil
	end
	gui.EnableScreenClicker(false)
end


---------------------------
-- StalkersMods.Admin.Menu
---------------------------
-- Desc:		A vgui for the SAdmin admin mod.
do
	local PANEL = {}

	function PANEL:RunDermaStringCmdWithPlayerTarget(prettyName, details, cmdName, target)
		Derma_StringRequest("SAdmin - "..prettyName, details, "", function(text)
			LocalPlayer():ConCommand(StalkersMods.Admin.CommandPrefix.." "..cmdName.." "..target.." "..text)
		end, nil, "Enter", "Cancel")
	end

	function PANEL:Init()
		self:SetName("StalkersMods.Admin.Menu")

		-- Add our DraggableDMenuOption
		local draggableHeader = vgui.Create("DraggableDMenuOption", self)
		draggableHeader:SetMenu(self)
		draggableHeader:SetText("                      ")
		draggableHeader:SetCenteredText("Stalker's Admin Mod")
		draggableHeader:SetRootPanel(self)
		draggableHeader:SetDisabled(true)
		self:AddPanel(draggableHeader)

		-- Add commands.
		local allCommands = StalkersMods.Admin.GetAllCommands()
		local categories = {}
		local selfUserGroup = LocalPlayer():GetUserGroup()

		-- Collect command categories.
		for cmdName, cmdObj in pairs(allCommands) do
			if StalkersMods.Admin.UserGroups.UserGroupHasPrivilege(selfUserGroup, cmdName) then
				if not categories[cmdObj:GetCategory()] then
					categories[cmdObj:GetCategory()] = {cmdObj}
				else
					table.insert(categories[cmdObj:GetCategory()], cmdObj)
				end
			end
		end
		
		-- Add all categories.
		self.CommandSubMenus = {}
		for categoryName, categoryCommands in SortedPairs(categories) do
			local child, parent = self:AddSubMenu(categoryName)
			if StalkersMods.Admin.Config.CategoryIcons[categoryName] then
				parent:SetIcon(StalkersMods.Admin.Config.CategoryIcons[categoryName])
			end

			function parent:OnMousePressed() end -- Disable clicking a submenu from closing the menu

			self.CommandSubMenus[categoryName] = child
		end

		-- Add commands to each category.
		for categoryName, categoryCommands in SortedPairs(categories) do
			local menuPanel = self.CommandSubMenus[categoryName]
			table.sort(categoryCommands, function(cmdA, cmdB)
				local nameA = cmdA:GetPrettyName() ~= "" and cmdA:GetPrettyName() or cmdA:GetName()
				local nameB = cmdB:GetPrettyName() ~= "" and cmdB:GetPrettyName() or cmdB:GetName()
				return nameA < nameB
			end)

			for i, cmdObj in ipairs(categoryCommands) do
				local name = cmdObj:GetPrettyName()
				if name == "" then
					name = cmdObj:GetName()
				end

				local details = "Command:     "..name
				if cmdObj:GetDescription() ~= "" then
					details = details.."\nDescription:   "..cmdObj:GetDescription()
				end
				if cmdObj:GetArgDescription() ~= "" then
					details = details.."\nArguments:   "..cmdObj:GetArgDescription()
				end
				details = details.."\nEnter additional arguments or just press <enter>."

				if cmdObj:GetNeedsTargets() then
					local child, parent = menuPanel:AddSubMenu(name)
					function parent:OnMousePressed() end -- Disable clicking a submenu from closing the menu
					child:AddOption("Yourself", function() self:RunDermaStringCmdWithPlayerTarget(name, details, cmdObj:GetName(), "^") end)
					child:AddOption("Everyone but yourself", function()	self:RunDermaStringCmdWithPlayerTarget(name, details, cmdObj:GetName(), "!") end)
					child:AddOption("Everyone", function() self:RunDermaStringCmdWithPlayerTarget(name, details, cmdObj:GetName(), "*") end)
					child:AddOption("Humans", function() self:RunDermaStringCmdWithPlayerTarget(name, details, cmdObj:GetName(), "h") end)
					child:AddOption("Bots", function() self:RunDermaStringCmdWithPlayerTarget(name, details, cmdObj:GetName(), "b") end)
					child:AddSpacer()

					local plys = player.GetAll()
					table.sort(plys, function(plyA, plyB)
						return plyA:Nick() < plyB:Nick()
					end)

					for i, ply in ipairs(plys) do
						local plyName = ply:Nick()
						local rpname = ply.getDarkRPVar and ply:getDarkRPVar("rpname") or ""
						if rpname ~= "" and plyName ~= rpname then
							plyName = plyName.." ("..rpname..")"
						end
						child:AddOption(plyName, function()
							local plyID = ply:IsBot() and ply:Nick() or ply:SteamID()
							if cmdObj:GetHasNoArgs() then
								LocalPlayer():ConCommand(StalkersMods.Admin.CommandPrefix.." "..cmdObj:GetName().." "..plyID)
							else
								self:RunDermaStringCmdWithPlayerTarget(name, details, cmdObj:GetName(), plyID)
							end
						end)
					end
				else
					menuPanel:AddOption(name, function()
						if cmdObj:GetHasNoArgs() then
							LocalPlayer():ConCommand(StalkersMods.Admin.CommandPrefix.." "..cmdObj:GetName())
						else
							Derma_StringRequest("SAdmin - "..name, details, "", function(text)
								LocalPlayer():ConCommand(StalkersMods.Admin.CommandPrefix.." "..cmdObj:GetName().." "..text)
							end, nil, "Enter", "Cancel")
						end
					end)
				end
			end
		end

		-- Add external options.
		if hook.GetTable()["StalkersMods.Admin.AddCustomOptions"] then
			self:AddSpacer()
		end
		hook.Run("StalkersMods.Admin.AddCustomOptions", self)
	end

	function PANEL:OnRemove()
		self:MouseCapture(false)
		gui.EnableScreenClicker(false)
	end

	vgui.Register("StalkersMods.Admin.Menu", PANEL, "DMenu")
end

------------------------
-- DraggableDMenuOption
------------------------
-- Desc:		A DMenuOption that can be added to a DMenu that lets you drag around the whole DMenu.
-- 				Make sure you pass the DMenu to this panel via pnl:SetRootPanel()
do
	local PANEL = {}

	function PANEL:Init()
		self.IsDragging = false
		self.RootPanel = nil
		self.CenteredText = ""
		self.DragOffsetX = 0
		self.DragOffsetY = 0
	end

	function PANEL:SetCenteredText(txt)
		self.CenteredText = txt
	end
	
	function PANEL:GetCenteredText()
		return self.CenteredText
	end

	function PANEL:SetRootPanel(pnl)
		self.RootPanel = pnl
	end
	
	function PANEL:GetRootPanel()
		return self.RootPanel
	end

	function PANEL:OnMousePressed(mousecode)
		if mousecode ~= MOUSE_LEFT then
			return
		end

		if self:GetRootPanel() then
			if not self.IsDragging then
				local pnlPosX, pnlPosY = self:GetRootPanel():GetPos()
				self.DragOffsetX = gui.MouseX() - pnlPosX
				self.DragOffsetY = gui.MouseY() - pnlPosY
			end
		end

		self.IsDragging = true
	end

	function PANEL:OnMouseReleased(mousecode)
		if mousecode ~= MOUSE_LEFT then
			return
		end

		self.IsDragging = false
	end

	function PANEL:Think()
		local rootPanel = self:GetRootPanel()
		if self.IsDragging and IsValid(rootPanel) then
			local x = math.Clamp(gui.MouseX() - self.DragOffsetX, 1, ScrW() - rootPanel:GetWide() - 1)
			local y = math.Clamp(gui.MouseY() - self.DragOffsetY, 1, ScrH() - rootPanel:GetTall() - 1)
			rootPanel:SetPos(x, y)
		end
	end

	function PANEL:Paint(w, h)
		surface.SetDrawColor(90, 90, 90)
		surface.DrawRect(0, 0, w, h)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawRect(1, 1, w - 2, h - 2)

		surface.SetFont("DermaDefault")
		surface.SetTextColor(0, 0, 0, 255)
		local text = self:GetCenteredText()
		local txtW, txtH = surface.GetTextSize(text)
		surface.SetTextPos(w/2 - txtW/2, h/2 - txtH/2)
		surface.DrawText(text)
		return false
	end

	vgui.Register("DraggableDMenuOption", PANEL, "DMenuOption")
end