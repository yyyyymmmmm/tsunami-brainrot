-- Tsunami Brainrot Bay: the client HUD.
-- Cash and income sit top-right, clear of Roblox's own top-left menu
-- buttons; the carried-character indicator sits bottom-centre; toasts land
-- mid-screen; the tsunami banner owns the top-centre. Everything shown comes
-- from the server: cash through leaderstats, the rest through player
-- attributes and the BrainrotRemotes events. This script decides nothing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stats = player:WaitForChild("leaderstats")
local cashValue = stats:WaitForChild("Cash")
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local function formatMoney(amount)
	local grouped = tostring(math.floor(amount)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

local function makePanel(name, size, position, anchor, color, transparency)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position
	panel.AnchorPoint = anchor
	panel.BackgroundColor3 = color or Color3.fromRGB(22, 26, 36)
	panel.BackgroundTransparency = transparency or 0.25
	panel.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	return panel
end

local function makeLabel(parent, name, size, position, text, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = playerGui

local title = makeLabel(gui, "Title", UDim2.fromOffset(460, 34), UDim2.new(0.5, 0, 0, 10),
	"🌴 TSUNAMI BRAINROT BAY 🌴", 24, Color3.fromRGB(255, 255, 255))
title.AnchorPoint = Vector2.new(0.5, 0)
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextStrokeTransparency = 0.5

local cashPanel = makePanel("CashPanel", UDim2.fromOffset(252, 68),
	UDim2.new(1, -16, 0, 16), Vector2.new(1, 0))
cashPanel.Parent = gui
local cashLabel = makeLabel(cashPanel, "Cash", UDim2.new(1, -24, 0, 30),
	UDim2.fromOffset(12, 6), "💰 $0", 24, Color3.fromRGB(255, 225, 120))
local incomeLabel = makeLabel(cashPanel, "Income", UDim2.new(1, -24, 0, 24),
	UDim2.fromOffset(12, 38), "📈 $0/s", 16, Color3.fromRGB(170, 230, 170))

local banner = makePanel("TsunamiBanner", UDim2.fromOffset(720, 58),
	UDim2.new(0.5, 0, 0, 56), Vector2.new(0.5, 0), Color3.fromRGB(200, 60, 40), 0.15)
banner.Visible = false
banner.Parent = gui
local bannerLabel = makeLabel(banner, "BannerText", UDim2.fromScale(1, 1),
	UDim2.fromOffset(0, 0), "", 30, Color3.fromRGB(255, 255, 255))
bannerLabel.TextXAlignment = Enum.TextXAlignment.Center

local carryPanel = makePanel("CarryPanel", UDim2.fromOffset(600, 48),
	UDim2.new(0.5, 0, 1, -24), Vector2.new(0.5, 1))
carryPanel.Visible = false
carryPanel.Parent = gui
local carryLabel = makeLabel(carryPanel, "CarryText", UDim2.fromScale(1, 1),
	UDim2.fromOffset(0, 0), "", 20, Color3.fromRGB(255, 240, 190))
carryLabel.TextXAlignment = Enum.TextXAlignment.Center

local toastLabel = makeLabel(gui, "Toast", UDim2.fromOffset(700, 50),
	UDim2.new(0.5, 0, 0.36, 0), "", 22, Color3.fromRGB(255, 255, 255))
toastLabel.AnchorPoint = Vector2.new(0.5, 0)
toastLabel.TextXAlignment = Enum.TextXAlignment.Center
toastLabel.BackgroundTransparency = 0.35
toastLabel.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
toastLabel.TextStrokeTransparency = 0.6
toastLabel.Visible = false
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toastLabel

local helpLabel = makeLabel(gui, "Help", UDim2.fromOffset(560, 22),
	UDim2.new(0, 12, 1, -14), "Walk into a brainrot to grab it - bank it at your glowing pad - outrun the wave!",
	14, Color3.fromRGB(235, 245, 255))
helpLabel.AnchorPoint = Vector2.new(0, 1)
helpLabel.TextStrokeTransparency = 0.6

local function refreshCash()
	cashLabel.Text = "💰 $" .. formatMoney(cashValue.Value)
end

local function refreshIncome()
	local income = player:GetAttribute("Income") or 0
	local multiplier = player:GetAttribute("Multiplier") or 1
	local text = "📈 $" .. formatMoney(income) .. "/s"
	if multiplier > 1 then
		text ..= "  (x" .. multiplier .. ")"
	end
	incomeLabel.Text = text
end

local function refreshCarry()
	local carrying = player:GetAttribute("Carrying") or ""
	if carrying ~= "" then
		carryLabel.Text = "🎒 Carrying " .. carrying .. " ($"
			.. (player:GetAttribute("CarryRate") or 0) .. "/s) - bank it at your base!"
		carryPanel.Visible = true
	else
		carryPanel.Visible = false
	end
end

cashValue.Changed:Connect(refreshCash)
player:GetAttributeChangedSignal("Income"):Connect(refreshIncome)
player:GetAttributeChangedSignal("Multiplier"):Connect(refreshIncome)
player:GetAttributeChangedSignal("Carrying"):Connect(refreshCarry)
player:GetAttributeChangedSignal("CarryRate"):Connect(refreshCarry)
refreshCash()
refreshIncome()
refreshCarry()

remotes:WaitForChild("TsunamiCountdown").OnClientEvent:Connect(function(seconds)
	bannerLabel.Text = "🌊 TSUNAMI IN " .. seconds .. "! RUN TO YOUR BASE! 🌊"
	banner.BackgroundColor3 = Color3.fromRGB(200, 60, 40)
	banner.Visible = true
end)

remotes:WaitForChild("TsunamiState").OnClientEvent:Connect(function(state)
	if state == "wave" then
		bannerLabel.Text = "🌊 TSUNAMI!!! 🌊"
		banner.BackgroundColor3 = Color3.fromRGB(30, 110, 220)
		banner.Visible = true
	else
		banner.Visible = false
	end
end)

local toastToken = 0
remotes:WaitForChild("Toast").OnClientEvent:Connect(function(text)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(3, function()
		if toastToken == token then
			toastLabel.Visible = false
		end
	end)
end)
