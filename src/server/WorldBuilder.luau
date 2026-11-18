-- WorldBuilder: constructs the whole bay out of parts at runtime.
-- One job: geometry. The island, the water, the palms, the row of player
-- bases, the egg machine and the rebirth shrine are all built here, so the
-- place file itself stays a thin shell and every script lives under src/.
-- Returns the landmarks GameManager plays on: the field, the bases, the
-- spawn, and the two ProximityPrompts.

local WorldBuilder = {}

local GRASS_TOP = 1.2
local PLOT_TOP = 2.8
local PAD_TOP = 3.2

local PLOT_COLORS = {
	Color3.fromRGB(255, 170, 170), Color3.fromRGB(255, 205, 140),
	Color3.fromRGB(255, 240, 150), Color3.fromRGB(170, 235, 170),
	Color3.fromRGB(150, 220, 255), Color3.fromRGB(180, 190, 255),
	Color3.fromRGB(220, 180, 255), Color3.fromRGB(255, 180, 220),
}

local function makePart(parent, name, size, cframe, color, options)
	options = options or {}
	local part = Instance.new(options.ClassName or "Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	if options.Shape then
		part.Shape = options.Shape
	end
	part.Material = options.Material or Enum.Material.SmoothPlastic
	part.Transparency = options.Transparency or 0
	part.Anchored = true
	part.CanCollide = options.CanCollide ~= false
	part.CanQuery = options.CanQuery ~= false
	part.Parent = parent
	return part
end

-- A flat disc: a cylinder Part's length runs along X, so turn it about Z.
local function makeDisc(parent, name, diameter, thickness, position, color, options)
	options = options or {}
	options.Shape = Enum.PartType.Cylinder
	return makePart(parent, name, Vector3.new(thickness, diameter, diameter),
		CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, options)
end

-- A floating text board. Returns the TextLabel so callers can rewrite it
-- (a base sign shows its owner's name, or EMPTY BASE while unclaimed).
local function makeBillboard(anchor, title, subtitle, width)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromOffset(width or 280, subtitle and 110 or 70)
	gui.StudsOffset = Vector3.new(0, 1, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = false
	gui.Parent = anchor

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.fromScale(1, subtitle and 0.55 or 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.Cartoon
	titleLabel.TextStrokeTransparency = 0.35
	titleLabel.Parent = gui

	if subtitle then
		local subLabel = Instance.new("TextLabel")
		subLabel.Name = "Subtitle"
		subLabel.Position = UDim2.fromScale(0, 0.55)
		subLabel.Size = UDim2.fromScale(1, 0.45)
		subLabel.BackgroundTransparency = 1
		subLabel.Text = subtitle
		subLabel.TextColor3 = Color3.fromRGB(230, 245, 255)
		subLabel.TextScaled = true
		subLabel.Font = Enum.Font.Cartoon
		subLabel.TextStrokeTransparency = 0.35
		subLabel.Parent = gui
	end
	return titleLabel
end

local function buildPalm(parent, x, z, groundY, height)
	local palm = Instance.new("Model")
	palm.Name = "PalmTree"
	palm.Parent = parent
	makePart(palm, "Trunk", Vector3.new(height, 1.25, 1.25),
		CFrame.new(x, groundY + height / 2 - 0.4, z) * CFrame.Angles(0, 0, math.rad(96)),
		Color3.fromRGB(133, 94, 55), { Shape = Enum.PartType.Cylinder })
	local topY = groundY + height - 0.6
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		makePart(palm, "Frond", Vector3.new(6.5, 0.25, 1.7),
			CFrame.new(x + dir.X * 2.4, topY + 0.5, z + dir.Z * 2.4)
				* CFrame.Angles(0, -angle, 0) * CFrame.Angles(0, 0, math.rad(-25)),
			Color3.fromRGB(64, 166, 72))
	end
	for _, offset in ipairs({ Vector3.new(0.7, -0.5, 0.3), Vector3.new(-0.6, -0.6, -0.4) }) do
		makePart(palm, "Coconut", Vector3.new(0.85, 0.85, 0.85),
			CFrame.new(x + offset.X, topY + offset.Y, z + offset.Z),
			Color3.fromRGB(101, 74, 40), { Shape = Enum.PartType.Ball })
	end
end

local function buildUmbrella(parent, x, z, groundY, color)
	makePart(parent, "UmbrellaPole", Vector3.new(5, 0.28, 0.28),
		CFrame.new(x, groundY + 2.5, z) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(240, 240, 240), { Shape = Enum.PartType.Cylinder })
	makeDisc(parent, "UmbrellaTop", 9, 0.35, Vector3.new(x, groundY + 5.1, z), color)
end

local function buildCloud(parent, x, y, z)
	local cloud = Instance.new("Model")
	cloud.Name = "Cloud"
	cloud.Parent = parent
	local puffs = {
		{ Vector3.new(11, 4, 7.5), Vector3.new(0, 0, 0) },
		{ Vector3.new(8, 3.4, 6), Vector3.new(5.5, -0.4, 1) },
		{ Vector3.new(7, 3, 5.4), Vector3.new(-5.5, -0.5, -1) },
	}
	for _, puff in ipairs(puffs) do
		makePart(cloud, "Puff", puff[1], CFrame.new(x + puff[2].X, y + puff[2].Y, z + puff[2].Z),
			Color3.fromRGB(255, 255, 255), { Shape = Enum.PartType.Ball, Transparency = 0.15, CanCollide = false })
	end
end

-- One player base: a coloured plot on the boardwalk, six display pads, a
-- glowing bank pad at its front edge and a name sign at its back.
local function buildBase(parent, index, centerX)
	local color = PLOT_COLORS[((index - 1) % #PLOT_COLORS) + 1]
	local base = Instance.new("Model")
	base.Name = "Base" .. index
	base.Parent = parent

	makePart(base, "Plot", Vector3.new(23, 0.8, 27), CFrame.new(centerX, 2.4, -74), color)

	local pads = {}
	for row, dz in ipairs({ -79, -69 }) do
		for col, dx in ipairs({ -6.5, 0, 6.5 }) do
			local pad = makeDisc(base, "DisplayPad", 4.6, 0.4,
				Vector3.new(centerX + dx, 3.0, dz), Color3.fromRGB(250, 250, 250), { CanCollide = false })
			table.insert(pads, { Part = pad, Occupant = nil, Row = row, Col = col })
		end
	end

	local bankPad = makeDisc(base, "BankPad", 7, 0.5, Vector3.new(centerX, 3.05, -62), color,
		{ Material = Enum.Material.Neon, CanCollide = false })

	local signBoard = makePart(base, "SignBoard", Vector3.new(18, 5, 0.6),
		CFrame.new(centerX, 6.2, -86.8), Color3.fromRGB(94, 66, 40), { Material = Enum.Material.Wood })
	local signLabel = makeBillboard(signBoard, "EMPTY BASE", nil, 300)

	return {
		Index = index,
		CenterX = centerX,
		BankPad = bankPad,
		Pads = pads,
		SignLabel = signLabel,
		Owner = nil,
	}
end

function WorldBuilder.Build()
	local folder = Instance.new("Folder")
	folder.Name = "World"
	folder.Parent = workspace

	-- Water and land. The ocean is walkable shallows; invisible walls at the
	-- island's edge keep players from wandering off across it.
	makePart(folder, "Ocean", Vector3.new(1200, 2, 1200), CFrame.new(0, -3, 0),
		Color3.fromRGB(35, 120, 205), { Transparency = 0.35, Material = Enum.Material.Glass })
	makePart(folder, "IslandSand", Vector3.new(270, 4, 215), CFrame.new(0, -2, 0),
		Color3.fromRGB(237, 214, 160), { Material = Enum.Material.Sand })
	makePart(folder, "FieldGrass", Vector3.new(195, 1.2, 125), CFrame.new(0, 0.6, 6),
		Color3.fromRGB(104, 188, 74), { Material = Enum.Material.Grass })
	makePart(folder, "Boardwalk", Vector3.new(235, 2, 36), CFrame.new(0, 1, -74),
		Color3.fromRGB(146, 102, 62), { Material = Enum.Material.WoodPlanks })

	for _, wall in ipairs({
		{ Vector3.new(280, 14, 2), Vector3.new(0, 5, -107) },
		{ Vector3.new(280, 14, 2), Vector3.new(0, 5, 107) },
		{ Vector3.new(2, 14, 216), Vector3.new(-136, 5, 0) },
		{ Vector3.new(2, 14, 216), Vector3.new(136, 5, 0) },
	}) do
		makePart(folder, "BoundaryWall", wall[1], CFrame.new(wall[2]),
			Color3.fromRGB(255, 255, 255), { Transparency = 1, CanQuery = false })
	end

	-- The row of bases along the north boardwalk.
	local bases = {}
	for i = 1, 8 do
		bases[i] = buildBase(folder, i, -88.2 + (i - 1) * 25.2)
	end

	-- Spawn, on the south sand, with the welcome sign behind it.
	local spawn = makePart(folder, "SpawnPad", Vector3.new(14, 1, 14), CFrame.new(0, 0.5, 88),
		Color3.fromRGB(64, 200, 190), { ClassName = "SpawnLocation" })
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	local welcomeBoard = makePart(folder, "WelcomeSign", Vector3.new(34, 9, 1),
		CFrame.new(0, 6.5, 99), Color3.fromRGB(94, 66, 40), { Material = Enum.Material.Wood })
	makeBillboard(welcomeBoard, "TSUNAMI BRAINROT BAY", "Grab a brainrot - bank it at your base - dodge the wave!", 560)

	-- The egg machine: a giant spotted egg on a pedestal, south field.
	local eggPedestal = makeDisc(folder, "EggPedestal", 10, 1.2, Vector3.new(18, 1.8, 56),
		Color3.fromRGB(120, 90, 160))
	local egg = makePart(folder, "GiantEgg", Vector3.new(7, 9, 7), CFrame.new(18, 6.6, 56),
		Color3.fromRGB(250, 245, 230), { Shape = Enum.PartType.Ball, CanCollide = false })
	for i, spot in ipairs({
		Vector3.new(2.8, 1.5, 1.6), Vector3.new(-2.6, 2.6, 1.9), Vector3.new(0.4, -1.8, 3.1),
		Vector3.new(-1.8, 0.4, -2.9), Vector3.new(2.4, 3.4, -1.4),
	}) do
		makePart(folder, "EggSpot", Vector3.new(1.5, 1.5, 1.5),
			CFrame.new(18 + spot.X, 6.6 + spot.Y, 56 + spot.Z),
			i % 2 == 0 and Color3.fromRGB(246, 121, 172) or Color3.fromRGB(110, 200, 240),
			{ Shape = Enum.PartType.Ball, CanCollide = false })
	end
	makeBillboard(egg, "EGG MACHINE", "$100 a hatch - Mythic is 2%!", 340)
	local eggPrompt = Instance.new("ProximityPrompt")
	eggPrompt.Name = "HatchPrompt"
	eggPrompt.ActionText = "Hatch Egg"
	eggPrompt.ObjectText = "$100 - Random Brainrot!"
	eggPrompt.HoldDuration = 0.4
	eggPrompt.MaxActivationDistance = 14
	eggPrompt.RequiresLineOfSight = false
	eggPrompt.Parent = eggPedestal

	-- The rebirth shrine: a glowing crystal on a matching pedestal.
	makeDisc(folder, "RebirthPedestal", 8, 1.2, Vector3.new(-18, 1.8, 56), Color3.fromRGB(70, 60, 110))
	local crystal = makePart(folder, "RebirthCrystal", Vector3.new(3, 5.2, 3),
		CFrame.new(-18, 5, 56) * CFrame.Angles(math.rad(18), math.rad(45), 0),
		Color3.fromRGB(178, 102, 255), { Material = Enum.Material.Neon, CanCollide = false })
	local crystalLight = Instance.new("PointLight")
	crystalLight.Color = Color3.fromRGB(178, 102, 255)
	crystalLight.Range = 20
	crystalLight.Brightness = 2
	crystalLight.Parent = crystal
	makeBillboard(crystal, "REBIRTH SHRINE", "Reset for +100% income, forever", 340)
	local rebirthPrompt = Instance.new("ProximityPrompt")
	rebirthPrompt.Name = "RebirthPrompt"
	rebirthPrompt.ActionText = "Rebirth"
	rebirthPrompt.ObjectText = "Reset cash and base for +100% income"
	rebirthPrompt.HoldDuration = 1
	rebirthPrompt.MaxActivationDistance = 14
	rebirthPrompt.RequiresLineOfSight = false
	rebirthPrompt.Parent = crystal

	-- Dressing: palms on the sand and behind the bases, rocks, umbrellas, clouds.
	for _, palmSpot in ipairs({
		{ -112, -38, 0 }, { 114, -34, 0 }, { -118, 44, 0 }, { 120, 58, 0 },
		{ -64, 80, 0 }, { 66, 84, 0 }, { -104, 88, 0 }, { 108, 92, 0 },
		{ -34, -99, 0 }, { 38, -99, 0 }, { -97, 10, 1.2 }, { 99, -52, 1.2 },
	}) do
		buildPalm(folder, palmSpot[1], palmSpot[2], palmSpot[3], 11 + (palmSpot[1] % 3))
	end
	for _, rockSpot in ipairs({
		{ -90, 20, 1.2 }, { 95, -10, 1.2 }, { -50, -58, 0 }, { 80, 72, 0 }, { -14, 100, 0 },
	}) do
		makePart(folder, "Rock", Vector3.new(3.2, 1.9, 2.7),
			CFrame.new(rockSpot[1], rockSpot[3] + 0.6, rockSpot[2]),
			Color3.fromRGB(140, 140, 145), { Shape = Enum.PartType.Ball })
	end
	buildUmbrella(folder, -40, 92, 0, Color3.fromRGB(235, 80, 80))
	buildUmbrella(folder, 44, 96, 0, Color3.fromRGB(60, 190, 200))
	buildUmbrella(folder, 92, 32, 1.2, Color3.fromRGB(250, 200, 60))
	buildCloud(folder, -70, 58, -40)
	buildCloud(folder, 60, 64, 20)
	buildCloud(folder, 0, 60, 92)
	buildCloud(folder, -42, 66, 62)
	buildCloud(folder, 92, 57, -72)

	return {
		Folder = folder,
		Field = { MinX = -82, MaxX = 82, MinZ = -42, MaxZ = 56, Y = GRASS_TOP },
		Bases = bases,
		SpawnCFrame = CFrame.new(0, 4, 88),
		EggPrompt = eggPrompt,
		EggPosition = Vector3.new(18, GRASS_TOP, 46),
		RebirthPrompt = rebirthPrompt,
		SafeZoneMaxZ = -50,
		PlotTop = PLOT_TOP,
		PadTop = PAD_TOP,
	}
end

return WorldBuilder
