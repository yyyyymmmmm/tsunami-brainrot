-- A square that moves with the arrow keys inside a grey box.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local ARENA_WIDTH = 640
local ARENA_HEIGHT = 480
local SQUARE_SIZE = 48
local SPEED = 320 -- pixels per second

local gui = Instance.new("ScreenGui")
gui.Name = "GameGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
background.BorderSizePixel = 0
background.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Hint"
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0.5, -ARENA_HEIGHT / 2 - 56)
title.Size = UDim2.fromOffset(ARENA_WIDTH, 40)
title.BackgroundTransparency = 1
title.Text = "Use the arrow keys to move the square"
title.TextColor3 = Color3.fromRGB(230, 230, 230)
title.TextSize = 24
title.Font = Enum.Font.SourceSans
title.Parent = background

local arena = Instance.new("Frame")
arena.Name = "Arena"
arena.AnchorPoint = Vector2.new(0.5, 0.5)
arena.Position = UDim2.fromScale(0.5, 0.5)
arena.Size = UDim2.fromOffset(ARENA_WIDTH, ARENA_HEIGHT)
arena.BackgroundColor3 = Color3.fromRGB(110, 110, 110)
arena.BorderColor3 = Color3.fromRGB(30, 30, 30)
arena.BorderSizePixel = 2
arena.Parent = background

local square = Instance.new("Frame")
square.Name = "Square"
square.Size = UDim2.fromOffset(SQUARE_SIZE, SQUARE_SIZE)
square.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
square.BorderColor3 = Color3.fromRGB(30, 30, 30)
square.BorderSizePixel = 2
square.Parent = arena

-- The square's top-left corner inside the arena, starting in the middle.
local x = (ARENA_WIDTH - SQUARE_SIZE) / 2
local y = (ARENA_HEIGHT - SQUARE_SIZE) / 2

local function place()
	square.Position = UDim2.fromOffset(math.floor(x + 0.5), math.floor(y + 0.5))
end

place()
gui.Parent = player:WaitForChild("PlayerGui")

RunService.RenderStepped:Connect(function(dt)
	local dx = 0
	local dy = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		dx -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		dx += 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		dy -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		dy += 1
	end
	if dx == 0 and dy == 0 then
		return
	end
	x = math.clamp(x + dx * SPEED * dt, 0, ARENA_WIDTH - SQUARE_SIZE)
	y = math.clamp(y + dy * SPEED * dt, 0, ARENA_HEIGHT - SQUARE_SIZE)
	place()
end)
