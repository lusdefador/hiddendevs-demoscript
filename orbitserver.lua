--demo meant to showcase understanding of frame math for time-based paths, metatables for platform config + path lookup, RunService.Heartbeat drive, according to the app rules

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PLATFORM_FOLDER_NAME = "MovingPlatforms"
local BASE_SIZE = Vector3.new(12, 1.5, 8)

local function getCircleCFrame(t: number, center: Vector3, radius: number, speed: number, phase: number)
	local angle = speed * t + phase
	local x = center.X + radius * math.cos(angle)
	local z = center.Z + radius * math.sin(angle)
	local y = center.Y
	local pos = Vector3.new(x, y, z)
	local lookDir = Vector3.new(-math.sin(angle), 0, math.cos(angle))
	return CFrame.lookAt(pos, pos + lookDir)
end

local function getBobCFrame(t: number, center: Vector3, amplitude: number, speed: number, phase: number)
	local y = center.Y + amplitude * math.sin(speed * t + phase)
	local pos = Vector3.new(center.X, y, center.Z)
	return CFrame.new(pos)
end

local function getFigure8CFrame(t: number, center: Vector3, radius: number, speed: number, phase: number)
	local angle = speed * t + phase
	local x = center.X + radius * math.cos(angle)
	local z = center.Z + radius * 0.5 * math.sin(2 * angle)
	local y = center.Y
	local pos = Vector3.new(x, y, z)
	local dx = -radius * math.sin(angle)
	local dz = radius * math.cos(2 * angle)
	local lookDir = Vector3.new(dx, 0, dz).Unit
	if lookDir.Magnitude < 0.01 then
		lookDir = Vector3.new(1, 0, 0)
	end
	return CFrame.lookAt(pos, pos + lookDir)
end

local function getTiltedCircleCFrame(t: number, center: Vector3, radius: number, speed: number, phase: number, tiltDeg: number?)
	local angle = speed * t + phase
	local x = center.X + radius * math.cos(angle)
	local z = center.Z + radius * math.sin(angle)
	local y = center.Y
	local pos = Vector3.new(x, y, z)
	local lookDir = Vector3.new(-math.sin(angle), 0, math.cos(angle))
	local baseCFrame = CFrame.lookAt(pos, pos + lookDir)
	local tiltRad = math.rad(tiltDeg or 12)
	local tiltCFrame = CFrame.Angles(tiltRad, 0, 0)
	return baseCFrame * tiltCFrame
end

local PATH_FUNCTIONS = {
	circle = getCircleCFrame,
	bob = getBobCFrame,
	figure8 = getFigure8CFrame,
	tiltedCircle = getTiltedCircleCFrame,
}

local OrbitingPlatformMeta = {}
OrbitingPlatformMeta.__index = OrbitingPlatformMeta

function OrbitingPlatformMeta:GetCFrameAtTime(t: number): CFrame
	local fn = PATH_FUNCTIONS[self.pathType]
	if not fn then
		return CFrame.new(self.center)
	end
	if self.pathType == "bob" then
		return fn(t, self.center, self.amplitude or 4, self.speed, self.phase)
	end
	if self.pathType == "tiltedCircle" then
		return fn(t, self.center, self.radius, self.speed, self.phase, self.tiltDeg)
	end
	return fn(t, self.center, self.radius, self.speed, self.phase)
end

local function createOrbitingPlatform(part: BasePart, config: { [string]: any })
	local obj = {
		part = part,
		center = config.center :: Vector3,
		radius = config.radius or 16,
		speed = config.speed or 0.8,
		phase = config.phase or 0,
		pathType = config.pathType or "circle",
		amplitude = config.amplitude,
		tiltDeg = config.tiltDeg,
	}
	setmetatable(obj, OrbitingPlatformMeta)
	return obj
end

local function createPlatformPart(parent: Instance, size: Vector3?, color: Color3?): BasePart
	local part = Instance.new("Part")
	part.Name = "MovingPlatform"
	part.Size = size or BASE_SIZE
	part.Anchored = true
	part.CanCollide = true
	part.CastShadow = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color or Color3.fromRGB(80, 130, 180)
	part.Parent = parent
	return part
end

local function ensureFolder(): Folder
	local folder = Workspace:FindFirstChild(PLATFORM_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = PLATFORM_FOLDER_NAME
		folder.Parent = Workspace
	end
	return folder :: Folder
end

local platforms: { any } = {}

local function buildPlatforms()
	local folder = ensureFolder()
	platforms = {}

	local centerA = Vector3.new(0, 18, 0)
	local partA = createPlatformPart(folder, BASE_SIZE, Color3.fromRGB(80, 130, 180))
	table.insert(platforms, createOrbitingPlatform(partA, {
		center = centerA,
		radius = 20,
		speed = 0.6,
		phase = 0,
		pathType = "circle",
	}))

	local centerB = Vector3.new(30, 22, 0)
	local partB = createPlatformPart(folder, Vector3.new(10, 1.2, 10), Color3.fromRGB(120, 80, 160))
	table.insert(platforms, createOrbitingPlatform(partB, {
		center = centerB,
		radius = 14,
		speed = 1.0,
		phase = math.pi * 0.5,
		pathType = "figure8",
	}))

	local centerC = Vector3.new(-25, 14, 20)
	local partC = createPlatformPart(folder, Vector3.new(14, 1.5, 6), Color3.fromRGB(90, 160, 100))
	table.insert(platforms, createOrbitingPlatform(partC, {
		center = centerC,
		amplitude = 5,
		speed = 0.5,
		phase = 0,
		pathType = "bob",
	}))

	local centerD = Vector3.new(0, 26, 25)
	local partD = createPlatformPart(folder, BASE_SIZE, Color3.fromRGB(180, 100, 80))
	table.insert(platforms, createOrbitingPlatform(partD, {
		center = centerD,
		radius = 12,
		speed = 0.4,
		phase = math.pi,
		pathType = "circle",
	}))

	local centerE = Vector3.new(20, 20, -15)
	local partE = createPlatformPart(folder, Vector3.new(8, 1.2, 8), Color3.fromRGB(160, 140, 80))
	table.insert(platforms, createOrbitingPlatform(partE, {
		center = centerE,
		radius = 10,
		speed = 1.2,
		phase = math.pi * 0.25,
		pathType = "figure8",
	}))

	local centerF = Vector3.new(-15, 24, -10)
	local partF = createPlatformPart(folder, Vector3.new(10, 1.2, 6), Color3.fromRGB(100, 120, 180))
	table.insert(platforms, createOrbitingPlatform(partF, {
		center = centerF,
		radius = 14,
		speed = 0.7,
		phase = math.pi * 0.75,
		pathType = "tiltedCircle",
		tiltDeg = 15,
	}))

	local centerG = Vector3.new(10, 20, 30)
	local partG = createPlatformPart(folder, Vector3.new(8, 1.2, 8), Color3.fromRGB(140, 100, 120))
	table.insert(platforms, createOrbitingPlatform(partG, {
		center = centerG,
		radius = 11,
		speed = 0.55,
		phase = math.pi * 0.5,
		pathType = "circle",
	}))
end

local function updatePlatforms()
	local t = tick()
	for i = 1, #platforms do
		local p = platforms[i]
		local cframe = p:GetCFrameAtTime(t)
		p.part.CFrame = cframe
	end
end

local function ensureGround()
	local name = "OrbitingPlatforms_Floor"
	local existing = Workspace:FindFirstChild(name)
	if existing then
		return existing :: BasePart
	end
	local ground = Instance.new("Part")
	ground.Name = name
	ground.Size = Vector3.new(128, 2, 128)
	ground.Position = Vector3.new(0, 1, 0)
	ground.Anchored = true
	ground.CanCollide = true
	ground.Material = Enum.Material.Ground
	ground.Color = Color3.fromRGB(90, 70, 50)
	ground.Parent = Workspace
	return ground
end

buildPlatforms()
ensureGround()

RunService.Heartbeat:Connect(function()
	updatePlatforms()
end)
