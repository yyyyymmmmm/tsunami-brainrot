-- GameManager: the rules of Tsunami Brainrot Bay, and all of its state.
-- One job: run the loop. Characters wander the field, players grab them by
-- walking into them, carry them home to a glowing bank pad, and banked
-- characters pay cash every second. The egg machine sells random hatches,
-- the shrine sells rebirths, and every so often a tsunami sweeps the field
-- and takes whatever a player is still carrying out in the open.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameManager = {}

function GameManager.Start(deps)
	local Data = deps.Data
	local Factory = deps.Factory
	local Config = Data.CONFIG
	local world = deps.World.Build()
	local rng = Random.new()

	-- The client HUD talks to the server through these three events.
	local remotes = Instance.new("Folder")
	remotes.Name = "BrainrotRemotes"
	remotes.Parent = ReplicatedStorage
	local function makeRemote(name)
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = remotes
		return event
	end
	local toastEvent = makeRemote("Toast")
	local countdownEvent = makeRemote("TsunamiCountdown")
	local waveStateEvent = makeRemote("TsunamiState")

	local brainrots = Instance.new("Folder")
	brainrots.Name = "Brainrots"
	brainrots.Parent = workspace

	-- State. A record is { Model, Data, Pos, Target, Speed, Phase, Facing }.
	local wanderers = {}
	local carriedBy = {} -- [player] = record
	local bankedBy = {} -- [player] = { record, ... }
	local baseByPlayer = {} -- [player] = base
	local lastBankWarn = {} -- [player] = clock time of the last "base full" toast

	local function placeModel(model, groundPosition, facingAngle)
		local rootHeight = model:GetAttribute("RootHeight") or 1.5
		model:PivotTo(CFrame.new(
			groundPosition.X,
			groundPosition.Y + rootHeight,
			groundPosition.Z
		) * CFrame.Angles(0, facingAngle, 0))
	end

	local function randomFieldPosition()
		local field = world.Field
		return Vector3.new(
			rng:NextNumber(field.MinX, field.MaxX),
			field.Y,
			rng:NextNumber(field.MinZ, field.MaxZ)
		)
	end

	local function rollRarity(weightKey)
		local total = 0
		for _, rarity in pairs(Data.RARITIES) do
			total += rarity[weightKey]
		end
		local roll = rng:NextNumber(0, total)
		for rarityName, rarity in pairs(Data.RARITIES) do
			roll -= rarity[weightKey]
			if roll <= 0 then
				return rarityName
			end
		end
		return "Common"
	end

	local function pickCharacter(weightKey)
		local bucket = Data.BY_RARITY[rollRarity(weightKey)]
		return bucket[rng:NextInteger(1, #bucket)]
	end

	local function spawnWanderer(data, position)
		local model = Factory.Build(data, Data.RARITIES[data.Rarity])
		model.Parent = brainrots
		local record = {
			Model = model,
			Data = data,
			Pos = position,
			Target = position,
			Speed = rng:NextNumber(3.5, 5.5),
			Phase = rng:NextNumber(0, math.pi * 2),
			Facing = 0,
		}
		placeModel(model, position, 0)
		table.insert(wanderers, record)
		return record
	end

	local function rootOf(player)
		local character = player.Character
		if not character then
			return nil
		end
		return character:FindFirstChild("HumanoidRootPart")
	end

	local function refreshIncome(player)
		local total = 0
		for _, record in ipairs(bankedBy[player] or {}) do
			total += record.Data.CashPerSecond
		end
		player:SetAttribute("Income", total * (player:GetAttribute("Multiplier") or 1))
	end

	local function bankCarried(player, record)
		local base = baseByPlayer[player]
		if not base then
			return false
		end
		for _, pad in ipairs(base.Pads) do
			if pad.Occupant == nil then
				pad.Occupant = record
				local padPos = pad.Part.Position
				placeModel(record.Model, Vector3.new(padPos.X, world.PadTop, padPos.Z), 0)
				table.insert(bankedBy[player], record)
				carriedBy[player] = nil
				player:SetAttribute("Carrying", "")
				player:SetAttribute("CarryRate", 0)
				refreshIncome(player)
				toastEvent:FireClient(player, "Banked " .. record.Data.Name
					.. "! It now earns $" .. record.Data.CashPerSecond .. "/s at your base.")
				return true
			end
		end
		return false
	end

	local function setupPlayer(player)
		local stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		local cash = Instance.new("IntValue")
		cash.Name = "Cash"
		cash.Value = Config.StartCash
		cash.Parent = stats
		local rebirths = Instance.new("IntValue")
		rebirths.Name = "Rebirths"
		rebirths.Value = 0
		rebirths.Parent = stats
		stats.Parent = player

		player:SetAttribute("Carrying", "")
		player:SetAttribute("CarryRate", 0)
		player:SetAttribute("Income", 0)
		player:SetAttribute("Multiplier", 1)
		bankedBy[player] = {}

		for _, base in ipairs(world.Bases) do
			if base.Owner == nil then
				base.Owner = player
				base.SignLabel.Text = player.DisplayName .. "'s Base"
				baseByPlayer[player] = base
				break
			end
		end

		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				local root = character:WaitForChild("HumanoidRootPart", 5)
				if root then
					root.CFrame = world.SpawnCFrame
				end
			end)
		end)
	end

	local function cleanupPlayer(player)
		local carried = carriedBy[player]
		if carried then
			carried.Model:Destroy()
			carriedBy[player] = nil
		end
		for _, record in ipairs(bankedBy[player] or {}) do
			record.Model:Destroy()
		end
		bankedBy[player] = nil
		local base = baseByPlayer[player]
		if base then
			base.Owner = nil
			base.SignLabel.Text = "EMPTY BASE"
			for _, pad in ipairs(base.Pads) do
				pad.Occupant = nil
			end
			baseByPlayer[player] = nil
		end
		lastBankWarn[player] = nil
	end

	-- The wave itself: a translucent wall crossing the bay west to east.
	-- Anything wild it passes is washed away; any player it catches outside
	-- the base boardwalk loses their carried character and lands back at spawn.
	local function runWave()
		local wave = Instance.new("Part")
		wave.Name = "TsunamiWave"
		wave.Size = Vector3.new(10, 70, 165)
		wave.Color = Color3.fromRGB(40, 140, 255)
		wave.Transparency = 0.4
		wave.Material = Enum.Material.Glass
		wave.Anchored = true
		wave.CanCollide = false
		wave.CanQuery = false
		wave.CanTouch = false
		wave.CFrame = CFrame.new(-215, 30, 32)
		wave.Parent = world.Folder

		local hit = {}
		local startTime = os.clock()
		while true do
			local alpha = math.clamp((os.clock() - startTime) / Config.WaveTravelTime, 0, 1)
			local waveX = -215 + alpha * 430
			wave.CFrame = CFrame.new(waveX, 30, 32)

			for i = #wanderers, 1, -1 do
				if wanderers[i].Pos.X <= waveX + 3 then
					wanderers[i].Model:Destroy()
					table.remove(wanderers, i)
				end
			end

			for _, player in ipairs(Players:GetPlayers()) do
				if not hit[player] then
					local root = rootOf(player)
					if root and root.Position.Z > world.SafeZoneMaxZ and root.Position.X <= waveX + 5 then
						hit[player] = true
						local carried = carriedBy[player]
						if carried then
							carried.Model:Destroy()
							carriedBy[player] = nil
							player:SetAttribute("Carrying", "")
							player:SetAttribute("CarryRate", 0)
							toastEvent:FireClient(player,
								"The tsunami washed away your " .. carried.Data.Name .. "!")
						else
							toastEvent:FireClient(player, "The tsunami got you! Back to the beach.")
						end
						root.CFrame = world.SpawnCFrame
						root.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
					end
				end
			end

			if alpha >= 1 then
				break
			end
			task.wait(0.05)
		end
		wave:Destroy()
	end

	-- Wandering, grabbing, carrying and banking, ten times a second.
	task.spawn(function()
		while true do
			local dt = task.wait(0.1)
			local now = os.clock()

			for _, record in ipairs(wanderers) do
				local dx = record.Target.X - record.Pos.X
				local dz = record.Target.Z - record.Pos.Z
				local dist = math.sqrt(dx * dx + dz * dz)
				if dist < 2 then
					record.Target = randomFieldPosition()
				else
					local step = math.min(record.Speed * dt, dist)
					record.Pos = Vector3.new(
						record.Pos.X + dx / dist * step,
						world.Field.Y,
						record.Pos.Z + dz / dist * step
					)
					record.Facing = math.atan2(dx, dz)
				end
				local bob = math.abs(math.sin(now * 4 + record.Phase)) * 0.25
				placeModel(record.Model,
					Vector3.new(record.Pos.X, world.Field.Y + bob, record.Pos.Z), record.Facing)
			end

			for _, player in ipairs(Players:GetPlayers()) do
				local root = rootOf(player)
				if root then
					if not carriedBy[player] then
						for i, record in ipairs(wanderers) do
							local dx = record.Pos.X - root.Position.X
							local dz = record.Pos.Z - root.Position.Z
							if dx * dx + dz * dz <= 20.25 then -- within 4.5 studs: grabbed
								table.remove(wanderers, i)
								carriedBy[player] = record
								player:SetAttribute("Carrying", record.Data.Name)
								player:SetAttribute("CarryRate", record.Data.CashPerSecond)
								break
							end
						end
					end

					local carried = carriedBy[player]
					if carried then
						local look = root.CFrame.LookVector
						local bob = math.sin(now * 5) * 0.15
						placeModel(carried.Model,
							root.Position + Vector3.new(0, 3.1 + bob, 0),
							math.atan2(look.X, look.Z))

						local base = baseByPlayer[player]
						if base then
							local padPos = base.BankPad.Position
							local dx = padPos.X - root.Position.X
							local dz = padPos.Z - root.Position.Z
							if dx * dx + dz * dz <= 56.25 then -- within 7.5 studs of the pad
								if not bankCarried(player, carried) then
									if now - (lastBankWarn[player] or 0) > 5 then
										lastBankWarn[player] = now
										toastEvent:FireClient(player,
											"Your base is full! All 6 pads are taken.")
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	-- Keep the field stocked.
	task.spawn(function()
		while true do
			task.wait(3.5)
			local carriedCount = 0
			for _ in pairs(carriedBy) do
				carriedCount += 1
			end
			if #wanderers < Config.WanderCap and #wanderers + carriedCount < Config.ActiveCap then
				spawnWanderer(pickCharacter("SpawnWeight"), randomFieldPosition())
			end
		end
	end)

	-- Banked characters pay their owners every second.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local income = player:GetAttribute("Income") or 0
				if income > 0 then
					local stats = player:FindFirstChild("leaderstats")
					if stats then
						stats.Cash.Value += income
					end
				end
			end
		end
	end)

	-- The tsunami clock: calm, a ten-second warning, then the wave.
	task.spawn(function()
		task.wait(20)
		while true do
			task.wait(Config.TsunamiInterval)
			for seconds = Config.TsunamiWarning, 1, -1 do
				countdownEvent:FireAllClients(seconds)
				task.wait(1)
			end
			waveStateEvent:FireAllClients("wave")
			runWave()
			waveStateEvent:FireAllClients("over")
		end
	end)

	world.EggPrompt.Triggered:Connect(function(player)
		local stats = player:FindFirstChild("leaderstats")
		if not stats then
			return
		end
		if stats.Cash.Value < Config.EggCost then
			toastEvent:FireClient(player, "You need $" .. Config.EggCost .. " to hatch an egg!")
			return
		end
		stats.Cash.Value -= Config.EggCost
		local data = pickCharacter("EggWeight")
		spawnWanderer(data, world.EggPosition + Vector3.new(
			rng:NextNumber(-3, 3), 0, rng:NextNumber(-2, 2)))
		toastEvent:FireClient(player, "You hatched " .. data.Name .. " (" .. data.Rarity
			.. ")! Grab it before someone else does!")
	end)

	world.RebirthPrompt.Triggered:Connect(function(player)
		local stats = player:FindFirstChild("leaderstats")
		if not stats then
			return
		end
		local cost = Config.RebirthBaseCost * (Config.RebirthCostGrowth ^ stats.Rebirths.Value)
		if stats.Cash.Value < cost then
			toastEvent:FireClient(player, "Rebirth costs $" .. cost .. ". Keep banking!")
			return
		end
		for _, record in ipairs(bankedBy[player] or {}) do
			record.Model:Destroy()
		end
		bankedBy[player] = {}
		local base = baseByPlayer[player]
		if base then
			for _, pad in ipairs(base.Pads) do
				pad.Occupant = nil
			end
		end
		stats.Cash.Value = 0
		stats.Rebirths.Value += 1
		player:SetAttribute("Multiplier", 1 + stats.Rebirths.Value)
		refreshIncome(player)
		toastEvent:FireClient(player, "REBIRTH! Your income is now x"
			.. (1 + stats.Rebirths.Value) .. " forever.")
	end)

	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(cleanupPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	-- Opening stock, so the first player in finds a living field.
	for _ = 1, 8 do
		spawnWanderer(pickCharacter("SpawnWeight"), randomFieldPosition())
	end
end

return GameManager
