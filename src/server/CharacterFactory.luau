-- CharacterFactory: builds one brainrot character Model out of plain parts.
-- One job: turn a CharacterData row into a creature with a body, a head, eyes,
-- one or two absurd accessories and a floating name label. Every part is
-- anchored and non-colliding, so GameManager moves the whole model with
-- PivotTo and no physics ever gets a vote.

local CharacterFactory = {}

local function makePart(parent, name, size, cframe, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Shape = shape or Enum.PartType.Block
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Parent = parent
	return part
end

local function makeWedge(parent, name, size, cframe, color)
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = Enum.Material.SmoothPlastic
	wedge.Anchored = true
	wedge.CanCollide = false
	wedge.CanQuery = false
	wedge.CanTouch = false
	wedge.Parent = parent
	return wedge
end

-- A name plate that floats over the head: the creature's name in its rarity
-- colour, and under it the rarity and what it earns each second.
local function addNameLabel(head, data, rarity)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameLabel"
	gui.Size = UDim2.fromOffset(230, 84)
	gui.StudsOffset = Vector3.new(0, 1.9, 0)
	gui.MaxDistance = 75
	gui.AlwaysOnTop = false
	gui.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.fromScale(1, 0.55)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = data.Name
	nameLabel.TextColor3 = rarity.LabelColor
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.Cartoon
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = gui

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "Info"
	infoLabel.Position = UDim2.fromScale(0, 0.55)
	infoLabel.Size = UDim2.fromScale(1, 0.45)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = data.Rarity .. "  -  $" .. data.CashPerSecond .. "/s"
	infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.Cartoon
	infoLabel.TextStrokeTransparency = 0.4
	infoLabel.Parent = gui
end

local function addAccessory(model, kind, data, s, bodyTop, headY, head)
	local body = data.BodyColor
	local accent = data.AccentColor
	-- Note: a cylinder Part's length runs along its local X, so a standing
	-- cylinder is that size turned 90 degrees about Z.
	if kind == "ChefHat" then
		makePart(model, "ChefHatBand", Vector3.new(0.7, 1.5, 1.5) * s,
			CFrame.new(0, headY + 0.95 * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(255, 255, 255), Enum.PartType.Cylinder)
		makePart(model, "ChefHatTop", Vector3.new(1.15, 0.75, 1.15) * s,
			CFrame.new(0, headY + 1.55 * s, 0), Color3.fromRGB(255, 255, 255), Enum.PartType.Ball)
	elseif kind == "EyeStalks" then
		for _, side in ipairs({ -1, 1 }) do
			makePart(model, "EyeStalk", Vector3.new(0.75, 0.18, 0.18) * s,
				CFrame.new(side * 0.42 * s, headY + 0.95 * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
				body, Enum.PartType.Cylinder)
			makePart(model, "StalkEye", Vector3.new(0.44, 0.44, 0.44) * s,
				CFrame.new(side * 0.42 * s, headY + 1.4 * s, 0), Color3.fromRGB(20, 20, 20), Enum.PartType.Ball)
		end
	elseif kind == "Belly" then
		makePart(model, "Belly", Vector3.new(1.5, 1.65, 0.7) * s,
			CFrame.new(0, bodyTop - 0.65 * s, 0.72 * s), accent, Enum.PartType.Ball)
	elseif kind == "Horns" then
		for _, side in ipairs({ -1, 1 }) do
			makePart(model, "Horn", Vector3.new(0.95, 0.22, 0.22) * s,
				CFrame.new(side * 0.85 * s, headY + 0.75 * s, 0) * CFrame.Angles(0, 0, math.rad(90 - side * 25)),
				Color3.fromRGB(232, 220, 190), Enum.PartType.Cylinder)
		end
	elseif kind == "Fin" then
		makeWedge(model, "DorsalFin", Vector3.new(0.35, 1.2, 1.4) * s,
			CFrame.new(0, bodyTop + 0.35 * s, -0.1 * s) * CFrame.Angles(math.rad(-15), 0, 0), accent)
		makeWedge(model, "TailFin", Vector3.new(0.3, 1.1, 1.2) * s,
			CFrame.new(0, bodyTop - 0.9 * s, -1.45 * s) * CFrame.Angles(0, math.pi, 0), accent)
	elseif kind == "Wings" then
		for _, side in ipairs({ -1, 1 }) do
			makePart(model, "Wing", Vector3.new(0.25, 1.7, 2.3) * s,
				CFrame.new(side * 1.2 * s, bodyTop - 0.2 * s, -0.75 * s)
					* CFrame.Angles(math.rad(-20), 0, side * math.rad(30)), accent)
		end
	elseif kind == "Mane" then
		makePart(model, "Mane", Vector3.new(2.2, 2.15, 2.2) * s,
			CFrame.new(0, headY, -0.55 * s), accent, Enum.PartType.Ball)
	elseif kind == "Crown" then
		makePart(model, "Crown", Vector3.new(0.55, 1.15, 1.15) * s,
			CFrame.new(0, headY + 1.0 * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color3.fromRGB(255, 215, 60), Enum.PartType.Cylinder)
	elseif kind == "Horn" then
		makeWedge(model, "UnicornHorn", Vector3.new(0.42, 1.25, 0.42) * s,
			CFrame.new(0, headY + 1.05 * s, 0.3 * s) * CFrame.Angles(math.rad(-15), 0, 0),
			Color3.fromRGB(255, 215, 60))
	elseif kind == "Tentacles" then
		for i = 1, 6 do
			local angle = (i / 6) * math.pi * 2
			local x = math.cos(angle) * 0.95 * s
			local z = math.sin(angle) * 0.95 * s
			makePart(model, "Tentacle", Vector3.new(1.05, 0.42, 0.42) * s,
				CFrame.new(x, 0.45 * s, z) * CFrame.Angles(0, 0, math.rad(90)),
				body, Enum.PartType.Cylinder)
		end
	end
end

-- Build the creature standing at the origin, feet on y=0, face toward +Z.
-- The model's pivot is its body, and the RootHeight attribute says how far
-- above the ground that pivot sits, so callers can place the feet exactly.
function CharacterFactory.Build(data, rarity)
	local s = data.Scale
	local model = Instance.new("Model")
	model.Name = data.Name

	local bodyShape = data.BodyShape == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
	local bodySize = (data.BodyShape == "Ball" and Vector3.new(2.3, 2.1, 2.0) or Vector3.new(2.2, 2.1, 1.7)) * s
	local bodyCenterY = 1.55 * s
	local bodyTop = bodyCenterY + bodySize.Y / 2

	local hasTentacles = data.Accessory == "Tentacles" or data.Accessory2 == "Tentacles"
	if not hasTentacles then
		for _, side in ipairs({ -1, 1 }) do
			makePart(model, "Foot", Vector3.new(0.62, 0.5, 0.72) * s,
				CFrame.new(side * 0.5 * s, 0.25 * s, 0.05 * s), data.AccentColor)
		end
	end

	local body = makePart(model, "Body", bodySize, CFrame.new(0, bodyCenterY, 0), data.BodyColor, bodyShape)

	local headY = bodyTop + 0.72 * s
	if data.Accessory == "LongNeck" then
		makePart(model, "Neck", Vector3.new(1.7, 0.62, 0.62) * s,
			CFrame.new(0, bodyTop + 0.8 * s, 0) * CFrame.Angles(0, 0, math.rad(90)),
			data.BodyColor, Enum.PartType.Cylinder)
		headY = bodyTop + 1.6 * s + 0.72 * s
	end
	local head = makePart(model, "Head", Vector3.new(1.7, 1.55, 1.7) * s,
		CFrame.new(0, headY, 0), data.BodyColor, Enum.PartType.Ball)

	-- Eyes on the face (+Z side), unless the creature wears them on stalks.
	if data.Accessory ~= "EyeStalks" then
		for _, side in ipairs({ -1, 1 }) do
			makePart(model, "Eye", Vector3.new(0.3, 0.3, 0.3) * s,
				CFrame.new(side * 0.34 * s, headY + 0.14 * s, 0.8 * s),
				Color3.fromRGB(18, 18, 22), Enum.PartType.Ball)
		end
	end

	addAccessory(model, data.Accessory, data, s, bodyTop, headY, head)
	if data.Accessory2 then
		addAccessory(model, data.Accessory2, data, s, bodyTop, headY, head)
	end

	addNameLabel(head, data, rarity)

	model.PrimaryPart = body
	model:SetAttribute("RootHeight", bodyCenterY)
	return model
end

return CharacterFactory
