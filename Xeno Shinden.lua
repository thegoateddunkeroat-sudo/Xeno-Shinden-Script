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

-- Create Tabs
local Tabs = {
	Main = Window:AddTab("Main", "user"),
	Settings = Window:AddTab("Settings", "settings"),
	Key = Window:AddKeyTab("Key System"),
}

-- ============================================================
-- MAIN TAB - ESP
-- ============================================================

--[[
	ESP Data Format:
	
	Line 1: workspace.LivingThings.[PlayerName].FakeHead.PlrName | Rank (from leaderstats.Rank) | Title (from leaderstats.Jonin)
	Line 2: Health/MaxHealth | Chakra/MaxChakra (where Chakra has .Value and .MaxValue)
	Line 3: Distance
]]

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

-- ============================================================
-- ESP RENDERING LOGIC
-- ============================================================

local espBillboards = {}
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

-- Create a ScreenGui for billboards
local espScreenGui = nil
pcall(function()
	espScreenGui = Instance.new("ScreenGui")
	espScreenGui.Name = "ESPGui"
	espScreenGui.ResetOnSpawn = false
	if localPlayer:FindFirstChild("PlayerGui") then
		espScreenGui.Parent = localPlayer.PlayerGui
	else
		espScreenGui.Parent = localPlayer:WaitForChild("PlayerGui", 10)
	end
	print("[ESP] ScreenGui created successfully")
end)

-- Function to get player info
local function getPlayerInfo(character)
	local info = {}
	
	-- Get name
	if character:FindFirstChild("FakeHead") and character.FakeHead:FindFirstChild("PlrName") then
		info.name = character.FakeHead.PlrName.Value or "Unknown"
	else
		info.name = character.Name
	end
	
	-- Get rank and title from leaderstats
	local leaderstats = character.Parent:FindFirstChild("leaderstats")
	if leaderstats then
		if leaderstats:FindFirstChild("Rank") then
			info.rank = tostring(leaderstats.Rank.Value)
		end
		if leaderstats:FindFirstChild("Jonin") then
			info.title = tostring(leaderstats.Jonin.Value)
		end
	end
	
	-- Get health
	if character:FindFirstChild("Humanoid") then
		info.health = math.floor(character.Humanoid.Health)
		info.maxHealth = math.floor(character.Humanoid.MaxHealth)
	end
	
	-- Get chakra
	if character:FindFirstChild("Chakra") then
		info.chakra = math.floor(character.Chakra.Value or 0)
		info.maxChakra = math.floor(character.Chakra.MaxValue or 0)
	end
	
	-- Get position for distance
	if character:FindFirstChild("HumanoidRootPart") then
		local dist = (character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
		info.distance = math.floor(dist)
	end
	
	return info
end

-- Function to create or update billboard
local function createOrUpdateBillboard(character, headPart)
	local playerName = character.Name
	local key = playerName
	
	-- Remove old billboard if it exists
	if espBillboards[key] then
		espBillboards[key]:Destroy()
		espBillboards[key] = nil
	end
	
	-- Create new billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(4, 0, 2.5, 0)
	billboard.MaxDistance = Toggles.ESPMaxDistance.Value or 100
	billboard.Adornee = headPart
	billboard.Parent = espScreenGui
	
	-- Create text label
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextStrokeTransparency = 0.5
	textLabel.Parent = billboard
	
	espBillboards[key] = billboard
	
	-- Update text
	local function updateText()
		if not Toggles.ESPEnabled.Value then return end
		
		local info = getPlayerInfo(character)
		local lines = {}
		
		if Toggles.ESPPlayerInfo.Value then
			local line1 = info.name
			if info.rank then line1 = line1 .. " | " .. info.rank end
			if info.title then line1 = line1 .. " | " .. info.title end
			table.insert(lines, line1)
		end
		
		if Toggles.ESPStats.Value then
			local line2 = ""
			if info.health then
				line2 = info.health .. "/" .. info.maxHealth
			end
			if info.chakra then
				if line2 ~= "" then line2 = line2 .. " | " end
				line2 = line2 .. info.chakra .. "/" .. info.maxChakra
			end
			if line2 ~= "" then table.insert(lines, line2) end
		end
		
		if Toggles.ESPDistance.Value and info.distance then
			table.insert(lines, info.distance .. "m")
		end
		
		textLabel.Text = table.concat(lines, "\n")
	end
	
	updateText()
	return updateText
end

-- Main ESP loop
game:GetService("RunService").RenderStepped:Connect(function()
	if not Toggles.ESPEnabled.Value then
		-- Clear all billboards if ESP is disabled
		for k, v in pairs(espBillboards) do
			if v and v.Parent then
				v:Destroy()
			end
		end
		espBillboards = {}
		return
	end
	
	if not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
	if not espScreenGui or not espScreenGui.Parent then return end
	
	-- Find LivingThings folder
	local livingThings = workspace:FindFirstChild("LivingThings")
	if not livingThings then 
		print("[ESP] LivingThings not found")
		return 
	end
	
	-- Track which players we've seen
	local activePlayers = {}
	local playerCount = 0
	
	-- Check each player in LivingThings
	for _, playerFolder in pairs(livingThings:GetChildren()) do
		playerCount = playerCount + 1
		local character = playerFolder:FindFirstChild("Char")
		
		if character and character ~= localPlayer.Character then
			activePlayers[playerFolder.Name] = true
			
			local headPart = character:FindFirstChild("FakeHead") or character:FindFirstChild("Head")
			if headPart then
				if not espBillboards[playerFolder.Name] then
					createOrUpdateBillboard(character, headPart)
					print("[ESP] Created billboard for:", playerFolder.Name)
				end
				
				-- Update max distance
				if espBillboards[playerFolder.Name] and espBillboards[playerFolder.Name].Parent then
					espBillboards[playerFolder.Name].MaxDistance = Toggles.ESPMaxDistance.Value or 100
					
					-- Update text
					local info = getPlayerInfo(character)
					local textLabel = espBillboards[playerFolder.Name]:FindFirstChildOfClass("TextLabel")
					if textLabel then
						local lines = {}
						
						if Toggles.ESPPlayerInfo.Value then
							local line1 = info.name
							if info.rank then line1 = line1 .. " | " .. info.rank end
							if info.title then line1 = line1 .. " | " .. info.title end
							table.insert(lines, line1)
						end
						
						if Toggles.ESPStats.Value then
							local line2 = ""
							if info.health then
								line2 = info.health .. "/" .. info.maxHealth
							end
							if info.chakra then
								if line2 ~= "" then line2 = line2 .. " | " end
								line2 = line2 .. info.chakra .. "/" .. info.maxChakra
							end
							if line2 ~= "" then table.insert(lines, line2) end
						end
						
						if Toggles.ESPDistance.Value and info.distance then
							table.insert(lines, info.distance .. "m")
						end
						
						textLabel.Text = table.concat(lines, "\n")
					end
				elseif espBillboards[playerFolder.Name] then
					-- Billboard was destroyed, remove it
					espBillboards[playerFolder.Name] = nil
				end
			end
		end
	end
	
	if playerCount == 0 then
		print("[ESP] LivingThings is empty")
	end
	
	-- Remove billboards for players no longer in LivingThings
	for key in pairs(espBillboards) do
		if not activePlayers[key] then
			if espBillboards[key] and espBillboards[key].Parent then
				espBillboards[key]:Destroy()
			end
			espBillboards[key] = nil
		end
	end
end)

-- Automatically update SaveManager theme
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("Shinden/Settings")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

print("Shinden loaded successfully!")
