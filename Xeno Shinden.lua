--[[
	Shinden - Xeno Shinden Menu
	Created from How to Use.lua template
]]

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Shinden",
	Footer = "version: 1.0",
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
	ToggleKeybind = Enum.KeyCode.RightShift,
})

local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Settings = Window:AddTab("Settings", "settings"),
	Key = Window:AddKeyTab("Key System"),
}

-- ============================================================
-- MAIN TAB - ESP
-- ============================================================

local MainGroupBox = Tabs.Main:AddLeftGroupbox("ESP", "eye")

MainGroupBox:AddToggle("ESPEnabled", {
	Text = "Enable ESP",
	Tooltip = "Toggle ESP on/off",
	Default = false,
	Callback = function(Value)
		print("[ESP] Enabled:", Value)
	end,
})

MainGroupBox:AddToggle("ESPPlayerInfo", {
	Text = "Show Player Info",
	Tooltip = "Display: Name | Rank | Title",
	Default = true,
	Callback = function(Value)
		print("[ESP] Player Info:", Value)
	end,
})

MainGroupBox:AddToggle("ESPStats", {
	Text = "Show Stats",
	Tooltip = "Display: Health/MaxHealth | Chakra/MaxChakra",
	Default = true,
	Callback = function(Value)
		print("[ESP] Stats:", Value)
	end,
})

MainGroupBox:AddToggle("ESPDistance", {
	Text = "Show Distance",
	Tooltip = "Display distance to players",
	Default = true,
	Callback = function(Value)
		print("[ESP] Distance:", Value)
	end,
})

MainGroupBox:AddToggle("ESPTool", {
	Text = "Show Tool",
	Tooltip = "Display tool held below avatar",
	Default = true,
	Callback = function(Value)
		print("[ESP] Tool:", Value)
	end,
})

MainGroupBox:AddSlider("ESPMaxDistance", {
	Text = "Max Distance",
	Default = 100,
	Min = 10,
	Max = 5000,
	Rounding = 1,
	Compact = false,
	Callback = function(Value)
		print("[ESP] Max Distance:", Value)
	end,
})

-- ============================================================
-- SETTINGS TAB
-- ============================================================

local SettingsGroupBox = Tabs.Settings:AddLeftGroupbox("UI Settings", "settings")

SettingsGroupBox:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Tooltip = "Enable/disable custom cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})

SettingsGroupBox:AddButton({
	Text = "Save Settings",
	Func = function()
		print("Settings saved!")
		Library:Notification("Success", "Settings have been saved!", 3)
	end,
	Tooltip = "Save your current settings",
})

SettingsGroupBox:AddButton({
	Text = "Reset Settings",
	Func = function()
		print("Settings reset!")
		Library:Notification("Info", "Settings have been reset to default!", 3)
	end,
	Tooltip = "Reset all settings to default",
	Risky = true,
})

SettingsGroupBox:AddButton({
	Text = "Unload",
	Func = function()
		showAllDisplayNames()
		for k, v in pairs(espBillboards)     do v:Destroy() end
		for k, v in pairs(espToolBillboards) do v:Destroy() end
		espBillboards     = {}
		espToolBillboards = {}
		if espScreenGui then espScreenGui:Destroy() end
		Library:Unload()
	end,
	Tooltip = "Completely unload the UI",
	Risky = true,
})

-- ============================================================
-- ESP RENDERING LOGIC
-- ============================================================

local espBillboards     = {}
local espToolBillboards = {}
local hiddenNametags    = {}
local players           = game:GetService("Players")
local localPlayer       = players.LocalPlayer

local espScreenGui = Instance.new("ScreenGui")
espScreenGui.Name = "ESPGui"
espScreenGui.ResetOnSpawn = false
espScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- ── Display name hide / restore ──────────────────────────────

local function hideDisplayName(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		hiddenNametags[character.Name] = {
			displayType = humanoid.DisplayDistanceType,
		}
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

local function showDisplayName(characterName)
	local livingThings = workspace:FindFirstChild("LivingThings")
	if not livingThings then hiddenNametags[characterName] = nil return end
	local character = livingThings:FindFirstChild(characterName)
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and hiddenNametags[characterName] then
			humanoid.DisplayDistanceType = hiddenNametags[characterName].displayType
		end
	end
	hiddenNametags[characterName] = nil
end

local function showAllDisplayNames()
	local livingThings = workspace:FindFirstChild("LivingThings")
	if livingThings then
		for characterName, data in pairs(hiddenNametags) do
			local character = livingThings:FindFirstChild(characterName)
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.DisplayDistanceType = data.displayType
				end
			end
		end
	end
	hiddenNametags = {}
end

-- ── Player info getter ────────────────────────────────────────

local function getPlayerInfo(character)
	local info = {}

	-- Name
	if character:FindFirstChild("FakeHead") and character.FakeHead:FindFirstChild("PlrName") then
		info.name = tostring(character.FakeHead.PlrName.Value)
	else
		info.name = character.Name
	end

	-- Rank, Rating, team color
	local player = players:FindFirstChild(character.Name)
	if player then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local rankVal  = leaderstats:FindFirstChild("Rank")
			local titleVal = leaderstats:FindFirstChild("Rating")
			if rankVal  then info.rank  = tostring(rankVal.Value)  end
			if titleVal then info.title = tostring(titleVal.Value) end
		end

		-- Team color (BrickColor → Color3)
		if player.Team then
			info.teamColor = player.TeamColor.Color
		end
	end

	-- Health
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		info.health    = math.floor(humanoid.Health)
		info.maxHealth = math.floor(humanoid.MaxHealth)
	end

	-- Chakra
	local chakra = character:FindFirstChild("Chakra")
	if chakra then
		info.chakra    = math.floor(chakra.Value    or 0)
		info.maxChakra = math.floor(chakra.MaxValue or 0)
	end

	-- CombatTag (check character first, then player)
	local combatTag = character:FindFirstChild("CombatTag")
		or (player and player:FindFirstChild("CombatTag"))
	if combatTag and tonumber(combatTag.Value) and tonumber(combatTag.Value) > 0 then
		info.inCombat = true
	else
		info.inCombat = false
	end

	-- Distance
	local localChar = localPlayer.Character
	if character:FindFirstChild("HumanoidRootPart") and localChar and localChar:FindFirstChild("HumanoidRootPart") then
		info.distance = math.floor((character.HumanoidRootPart.Position - localChar.HumanoidRootPart.Position).Magnitude)
	end

	-- Tool
	local tool = character:FindFirstChildOfClass("Tool")
	if tool then info.tool = tool.Name end

	return info
end

-- ── Billboard builders ────────────────────────────────────────

local function makeLabel(parent, name, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, textSize + 2)
	label.BackgroundTransparency = 1
	label.RichText = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize or 13
	label.TextStrokeTransparency = 0.4
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextScaled = false
	label.Parent = parent
	return label
end

-- Main billboard (above head)
local function createBillboard(character, headPart)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(10, 0, 0, 80) -- taller to fit combat tag
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.MaxDistance = Options.ESPMaxDistance.Value or 100
	billboard.AlwaysOnTop = true
	billboard.Adornee = headPart
	billboard.Parent = espScreenGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = billboard

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 2)
	layout.Parent = frame

	-- Order: IN COMBAT → Name/Rank/Title → HP/Chakra → Distance
	makeLabel(frame, "LabelCombat", 10) -- small red combat tag
	makeLabel(frame, "LabelInfo",   13)
	makeLabel(frame, "LabelStats",  13)
	makeLabel(frame, "LabelDist",   13)

	return billboard
end

-- Tool billboard (below avatar)
local function createToolBillboard(rootPart)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(6, 0, 0, 20)
	billboard.StudsOffset = Vector3.new(0, -3.5, 0)
	billboard.MaxDistance = Options.ESPMaxDistance.Value or 100
	billboard.AlwaysOnTop = true
	billboard.Adornee = rootPart
	billboard.Parent = espScreenGui

	local label = Instance.new("TextLabel")
	label.Name = "LabelTool"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.RichText = true
	label.TextColor3 = Color3.fromRGB(255, 220, 80)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 12
	label.TextStrokeTransparency = 0.4
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextScaled = false
	label.Parent = billboard

	return billboard
end

-- ── Billboard updaters ────────────────────────────────────────

local function updateBillboard(billboard, info)
	local frame = billboard:FindFirstChildOfClass("Frame")
	if not frame then return end

	local labelCombat = frame:FindFirstChild("LabelCombat")
	local labelInfo   = frame:FindFirstChild("LabelInfo")
	local labelStats  = frame:FindFirstChild("LabelStats")
	local labelDist   = frame:FindFirstChild("LabelDist")

	-- IN COMBAT tag (small red, always shown if active regardless of other toggles)
	if labelCombat then
		if info.inCombat then
			labelCombat.Text    = "IN COMBAT"
			labelCombat.TextColor3 = Color3.fromRGB(255, 50, 50)
			labelCombat.Visible = true
		else
			labelCombat.Visible = false
		end
	end

	-- Name | Rank | Title — colored by team color
	if labelInfo then
		if Toggles.ESPPlayerInfo.Value then
			local line1 = info.name or "Unknown"
			if info.rank  and info.rank  ~= "" then line1 = line1 .. " | " .. info.rank  end
			if info.title and info.title ~= "" then line1 = line1 .. " | " .. info.title end
			labelInfo.Text = line1
			-- Use team color if available, otherwise white
			if info.teamColor then
				labelInfo.TextColor3 = info.teamColor
			else
				labelInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
			labelInfo.Visible = true
		else
			labelInfo.Visible = false
		end
	end

	-- Health (green) | Chakra (blue)
	if labelStats then
		if Toggles.ESPStats.Value then
			local line2 = ""
			if info.health then
				line2 = '<font color="rgb(80,255,80)">' .. info.health .. "/" .. info.maxHealth .. "</font>"
			end
			if info.chakra then
				if line2 ~= "" then line2 = line2 .. "  |  " end
				line2 = line2 .. '<font color="rgb(80,180,255)">' .. info.chakra .. "/" .. info.maxChakra .. "</font>"
			end
			labelStats.Text    = line2
			labelStats.Visible = true
		else
			labelStats.Visible = false
		end
	end

	-- Distance
	if labelDist then
		if Toggles.ESPDistance.Value and info.distance then
			labelDist.Text    = info.distance .. "m"
			labelDist.Visible = true
		else
			labelDist.Visible = false
		end
	end
end

local function updateToolBillboard(billboard, info)
	local label = billboard:FindFirstChild("LabelTool")
	if not label then return end
	if Toggles.ESPTool.Value and info.tool then
		label.Text    = "[" .. info.tool .. "]"
		label.Visible = true
	else
		label.Visible = false
	end
end

-- ── Main loop ─────────────────────────────────────────────────

game:GetService("RunService").RenderStepped:Connect(function()
	if not Toggles.ESPEnabled.Value then
		showAllDisplayNames()
		for k, v in pairs(espBillboards)     do v:Destroy() end
		for k, v in pairs(espToolBillboards) do v:Destroy() end
		espBillboards     = {}
		espToolBillboards = {}
		return
	end

	local localChar = localPlayer.Character
	if not localChar or not localChar:FindFirstChild("HumanoidRootPart") then return end

	local livingThings = workspace:FindFirstChild("LivingThings")
	if not livingThings then return end

	local activePlayers = {}

	for _, character in pairs(livingThings:GetChildren()) do
		if character == localChar then continue end
		if not character:FindFirstChild("HumanoidRootPart") then continue end

		local key      = character.Name
		local headPart = character:FindFirstChild("FakeHead") or character:FindFirstChild("Head")
		local rootPart = character:FindFirstChild("HumanoidRootPart")

		activePlayers[key] = true

		if not espBillboards[key] and headPart then
			hideDisplayName(character)
			espBillboards[key] = createBillboard(character, headPart)
		end

		if not espToolBillboards[key] and rootPart then
			espToolBillboards[key] = createToolBillboard(rootPart)
		end

		local maxDist = Options.ESPMaxDistance.Value or 100
		local info    = getPlayerInfo(character)

		if espBillboards[key] then
			espBillboards[key].MaxDistance = maxDist
			updateBillboard(espBillboards[key], info)
		end

		if espToolBillboards[key] then
			espToolBillboards[key].MaxDistance = maxDist
			updateToolBillboard(espToolBillboards[key], info)
		end
	end

	for key, billboard in pairs(espBillboards) do
		if not activePlayers[key] then
			showDisplayName(key)
			billboard:Destroy()
			espBillboards[key] = nil
		end
	end

	for key, billboard in pairs(espToolBillboards) do
		if not activePlayers[key] then
			billboard:Destroy()
			espToolBillboards[key] = nil
		end
	end
end)

-- ============================================================
-- SAVE / THEME MANAGER
-- ============================================================

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("Shinden/Settings")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

print("Shinden loaded successfully!")
