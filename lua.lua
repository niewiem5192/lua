if LPH_OBFUSCATED == nil then
	LPH_NO_VIRTUALIZE = function(...)
		return ...
	end
end

--// Cache
local game, workspace = game, workspace
local getrawmetatable, pcall, next, tick, getgenv = getrawmetatable, pcall, next, tick, getgenv
local Vector2new, Vector3zero, CFramenew, Color3fromRGB, Color3fromHSV, Drawingnew, TweenInfonew = Vector2.new, Vector3.zero, CFrame.new, Color3.fromRGB, Color3.fromHSV, Drawing and Drawing.new, TweenInfo.new
local mousemoverel, mousemoveabs, tablefind, tableremove, stringlower, stringsub, mathclamp = mousemoverel or (Input and Input.MouseMove), mousemoveabs, table.find, table.remove, string.lower, string.sub, math.clamp
local mouse1press, mouse1release, mouse1click, taskwait = mouse1press, mouse1release, mouse1click, task.wait
local clonefunction, cloneref = clonefunction or LPH_NO_VIRTUALIZE(function(...)
	return ...
end), cloneref or LPH_NO_VIRTUALIZE(function(...)
	return ...
end)

local GameMetatable = getrawmetatable and getrawmetatable(game) or {
	__index = LPH_NO_VIRTUALIZE(function(self, Index)
		return self[Index]
	end),
	__newindex = LPH_NO_VIRTUALIZE(function(self, Index, Value)
		self[Index] = Value
	end)
}

local __index = GameMetatable.__index
local __newindex = GameMetatable.__newindex

local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

local _GetService = __index(game, "GetService")
local GetService = function(Service)
	return cloneref(_GetService(game, Service))
end

--// Services
local RunService = GetService("RunService")
local UserInputService = GetService("UserInputService")
local TweenService = GetService("TweenService")
local Players = GetService("Players")

--// Service Methods
local LocalPlayer = __index(Players, "LocalPlayer")
local Camera = __index(workspace, "CurrentCamera")

local FindFirstChild, FindFirstChildOfClass = __index(game, "FindFirstChild"), __index(game, "FindFirstChildOfClass")
local GetDescendants = __index(game, "GetDescendants")
local WorldToViewportPoint = __index(Camera, "WorldToViewportPoint")
local GetPartsObscuringTarget = __index(Camera, "GetPartsObscuringTarget")
local GetMouseLocation = __index(UserInputService, "GetMouseLocation")
local GetPlayers = __index(Players, "GetPlayers")
local GetPlayerFromCharacter = __index(Players, "GetPlayerFromCharacter")
local Mouse = __index(LocalPlayer, "GetMouse")(LocalPlayer)
local CameraViewportSize = __index(Camera, "ViewportSize")

--// Variables
local RequiredDistance, Typing, Running, ServiceConnections, Animation, OriginalSensitivity = 2000, false, false, {}
local Connect, Disconnect = __index(game, "DescendantAdded").Connect

do
	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
	Disconnect = TemporaryConnection.Disconnect
	Disconnect(TemporaryConnection)
end

--// Environment & Configuration
getgenv().ExunysDeveloperAimbot = {
	DeveloperSettings = {
		UpdateMode = "RenderStepped",
		TeamCheckOption = "TeamColor",
		RainbowSpeed = 1,
		DisableWarnings = false
	},

	Settings = {
		Enabled = true,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		OffsetToMoveDirection = false,
		OffsetIncrement = 15,
		Sensitivity = 0,
		Sensitivity2 = 6,
		LockMode = 2,
		LockPart = "Head",
		TriggerKey = Enum.KeyCode.Q,
		Toggle = false
	},

	Triggerbot = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		AimLockedCheck = false,
		Delay = 0
	},

	ESP = {
		Enabled = false,
		Boxes = true,
		Names = true,
		Tracers = false,
		TeamCheck = false,
		Color = Color3fromRGB(255, 255, 255)
	},

	CustomCrosshair = {
		Enabled = false,
		Spin = true,
		Speed = 2,
		Size = 14
	},

	ClosestPlayerTracer = {
		Enabled = false,
		Position = 3,
		Transparency = 0.5,
		Thickness = 1,
		RainbowColor = false,
		Color = Color3fromRGB(150, 150, 255)
	},

	FOVSettings = {
		Enabled = true,
		Visible = true,
		Radius = 150,
		NumSides = 60,
		Thickness = 1,
		Transparency = 1,
		Filled = false,
		RainbowColor = false,
		RainbowOutlineColor = false,
		Color = Color3fromRGB(255, 255, 255),
		OutlineColor = Color3fromRGB(0, 0, 0),
		LockedColor = Color3fromRGB(255, 150, 150)
	},

	Blacklisted = {},
	FOVCircleOutline = Drawingnew("Circle"),
	FOVCircle = Drawingnew("Circle"),
	Tracer = Drawingnew("Line"),
	ESPObjects = {}
}

local Environment, _warn = getgenv().ExunysDeveloperAimbot, clonefunction(warn); warn = function(...)
	return not Environment.DeveloperSettings.DisableWarnings and _warn(...)
end

repeat
	taskwait(0)
until Environment and Environment.FOVCircle and Environment.FOVCircleOutline

setrenderproperty(Environment.FOVCircle, "Visible", false)
setrenderproperty(Environment.FOVCircleOutline, "Visible", false)

--// Tworzenie linii dla gwiazdy Dawida (6 linii)
local StarLines = {}
for i = 1, 6 do
	local line = Drawingnew("Line")
	line.Visible = false
	line.Thickness = 1.5
	table.insert(StarLines, line)
end

--// Funkcja czyszcząca ESP
local function CleanESP(player)
	if Environment.ESPObjects[player] then
		pcall(function()
			Environment.ESPObjects[player].Box:Remove()
			Environment.ESPObjects[player].Name:Remove()
			Environment.ESPObjects[player].TracerLine:Remove()
		end)
		Environment.ESPObjects[player] = nil
	end
end

--// Core Functions
local FixUsername = LPH_NO_VIRTUALIZE(function(String)
	for _, Value in next, GetPlayers(Players) do
		local Name = __index(Value, "Name")
		if stringsub(stringlower(Name), 1, #String) == stringlower(String) then
			return Name
		end
	end
end)

local GetRainbowColor = LPH_NO_VIRTUALIZE(function(speedMultiplier)
	local RainbowSpeed = (Environment.DeveloperSettings.RainbowSpeed or 1) * (speedMultiplier or 1)
	return Color3fromHSV(tick() % RainbowSpeed / RainbowSpeed, 1, 1)
end)

local ConvertVector = LPH_NO_VIRTUALIZE(function(Vector)
	return Vector2new(Vector.X, Vector.Y)
end)

local CancelLock = LPH_NO_VIRTUALIZE(function()
	Environment.Locked = nil
	setrenderproperty(Environment.FOVCircle, "Color", Environment.FOVSettings.Color)
	__newindex(UserInputService, "MouseDeltaSensitivity", OriginalSensitivity)

	if Animation then
		Animation:Cancel()
	end

	setrenderproperty(Environment.Tracer, "Visible", Environment.ClosestPlayerTracer.Enabled)
end)

local GetClosestPlayer = LPH_NO_VIRTUALIZE(function(Aux)
	local Settings = Environment.Settings
	local LockPart = Settings.LockPart

	if not Environment.Locked or Aux then
		RequiredDistance = Environment.FOVSettings.Enabled and Environment.FOVSettings.Radius or 2000
		Required3DDistance = 10000

		for _, Value in next, GetPlayers(Players) do
			local Character = __index(Value, "Character")
			local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

			if Value ~= LocalPlayer and not tablefind(Environment.Blacklisted, __index(Value, "Name")) and Character and FindFirstChild(Character, LockPart) and Humanoid then
				local PartPosition, TeamCheckOption = __index(Character[LockPart], "Position"), Environment.DeveloperSettings.TeamCheckOption

				if Settings.TeamCheck and __index(Value, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
					continue
				end

				if Settings.AliveCheck and __index(Humanoid, "Health") <= 0 then
					continue
				end

				if Settings.WallCheck then
					local BlacklistTable = GetDescendants(__index(LocalPlayer, "Character"))
					for _, _Value in next, GetDescendants(Character) do
						BlacklistTable[#BlacklistTable + 1] = _Value
					end

					if #GetPartsObscuringTarget(Camera, {PartPosition}, BlacklistTable) > 0 then
						continue
					end
				end

				local Vector, OnScreen, Distance = WorldToViewportPoint(Camera, PartPosition)
				Vector = ConvertVector(Vector)
				Distance = (GetMouseLocation(UserInputService) - Vector).Magnitude
				local _3DDistance = (__index(Camera, "CFrame").Position - PartPosition).Magnitude

				if Distance < RequiredDistance and _3DDistance < Required3DDistance and OnScreen then
					RequiredDistance, Required3DDistance = Distance, _3DDistance

					if not Aux then
						Environment.Locked = Value
					elseif not Running and not Environment.Locked then
						return Value
					end
				end
			end
		end
	elseif (GetMouseLocation(UserInputService) - ConvertVector(WorldToViewportPoint(Camera, __index(__index(__index(Environment.Locked, "Character"), LockPart], "Position")))).Magnitude > RequiredDistance then
		CancelLock()
	end
end)

local Load = function()
	OriginalSensitivity = __index(UserInputService, "MouseDeltaSensitivity")
	local Settings, Triggerbot, Tracer, FOVCircle, FOVCircleOutline, TracerSettings, FOVSettings, ESPSettings = Environment.Settings, Environment.Triggerbot, Environment.Tracer, Environment.FOVCircle, Environment.FOVCircleOutline, Environment.ClosestPlayerTracer, Environment.FOVSettings, Environment.ESP
	local OffsetToMoveDirection, LockPart = Settings.OffsetToMoveDirection, Settings.LockPart
	local DeveloperSettings = Environment.DeveloperSettings
	local UpdateMode = DeveloperSettings.UpdateMode
	local TeamCheckOption = DeveloperSettings.TeamCheckOption

	if mouse1press and mouse1release then
		ServiceConnections.Triggerbot = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
			if Triggerbot.Enabled and Mouse.Target then
				local TargetPart = Mouse.Target
				local Character = TargetPart.Parent
				local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
				local Player = GetPlayerFromCharacter(Players, Character)

				if Character and Humanoid and Player and TargetPart.Name == "Head" then
					if Triggerbot.TeamCheck and __index(Player, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
						return
					end
					if Triggerbot.AliveCheck and __index(Humanoid, "Health") <= 0 then
						return
					end
					if Triggerbot.AimLockedCheck and not Environment.Locked then
						return
					end
					if Triggerbot.Delay ~= 0 then
						taskwait(Triggerbot.Delay)
					end
					mouse1press()
					__index(RunService, UpdateMode):Wait()
					mouse1release()
					mouse1click()
				end
			end
		end))
	end

	ServiceConnections.ESPConnection = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		local ESPTable = Environment.ESPObjects

		local ccConfig = Environment.CustomCrosshair
		if ccConfig.Enabled then
			local center = Camera.ViewportSize / 2
			local radius = ccConfig.Size or 14
			local baseAngle = ccConfig.Spin and (tick() * (ccConfig.Speed * 2)) or 0
			local sharedRainbowColor = GetRainbowColor(1)
			
			local pts = {}
			for i = 1, 6 do
				local angle = baseAngle + ((i - 1) * (math.pi / 3))
				pts[i] = Vector2new(center.X + math.cos(angle) * radius, center.Y + math.sin(angle) * radius)
			end
			
			StarLines[1].From = pts[1] StarLines[1].To = pts[3]
			StarLines[2].From = pts[3] StarLines[2].To = pts[5]
			StarLines[3].From = pts[5] StarLines[3].To = pts[1]
			StarLines[4].From = pts[2] StarLines[4].To = pts[4]
			StarLines[5].From = pts[4] StarLines[5].To = pts[6]
			StarLines[6].From = pts[6] StarLines[6].To = pts[2]

			for i = 1, 6 do
				StarLines[i].Visible = true
				StarLines[i].Color = sharedRainbowColor
			end
		else
			for _, line in ipairs(StarLines) do
				line.Visible = false
			end
		end

		for _, Player in next, GetPlayers(Players) do
			if Player ~= LocalPlayer then
				local Character = __index(Player, "Character")
				local HumanoidRootPart = Character and FindFirstChild(Character, "HumanoidRootPart")
				local Humanoid = Character and FindFirstChildOfClass(Character, "Humanoid")

				if not ESPSettings.Enabled or not Character or not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
					CleanESP(Player)
					continue
				end

				if ESPSettings.TeamCheck and __index(Player, TeamCheckOption) == __index(LocalPlayer, TeamCheckOption) then
					CleanESP(Player)
					continue
				end

				if not ESPTable[Player] then
					ESPTable[Player] = {
						Box = Drawingnew("Square"),
						Name = Drawingnew("Text"),
						TracerLine = Drawingnew("Line")
					}
					setrenderproperty(ESPTable[Player].Box, "Filled", false)
					setrenderproperty(ESPTable[Player].Box, "Thickness", 1.5)
					
					setrenderproperty(ESPTable[Player].Name, "Size", 13)
					setrenderproperty(ESPTable[Player].Name, "Center", true)
					setrenderproperty(ESPTable[Player].Name, "Outline", true)
					
					setrenderproperty(ESPTable[Player].TracerLine, "Thickness", 1)
				end

				local ESPData = ESPTable[Player]
				local Box, NameText, TracerLine = ESPData.Box, ESPData.Name, ESPData.TracerLine

				local RootPos, OnScreen = WorldToViewportPoint(Camera, HumanoidRootPart.Position)
				if OnScreen then
					local Head = FindFirstChild(Character, "Head")
					local Leg = HumanoidRootPart.Position - Vector3.new(0, 3, 0)
					local HeadPos = Head and WorldToViewportPoint(Camera, Head.Position + Vector3.new(0, 0.5, 0)) or RootPos
					local LegPos = WorldToViewportPoint(Camera, Leg)

					local Height = math.abs(HeadPos.Y - LegPos.Y)
					local Width = Height / 2

					if ESPSettings.Boxes then
						setrenderproperty(Box, "Visible", true)
						setrenderproperty(Box, "Size", Vector2new(Width, Height))
						setrenderproperty(Box, "Position", Vector2new(RootPos.X - Width / 2, RootPos.Y - Height / 2))
						setrenderproperty(Box, "Color", ESPSettings.Color)
					else
						setrenderproperty(Box, "Visible", false)
					end

					if ESPSettings.Names then
						setrenderproperty(NameText, "Visible", true)
						local dist = math.floor((HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude)
						setrenderproperty(NameText, "Text", __index(Player, "Name") .. " [" .. dist .. "m]")
						setrenderproperty(NameText, "Position", Vector2new(RootPos.X, (RootPos.Y - Height / 2) - 18))
						setrenderproperty(NameText, "Color", ESPSettings.Color)
					else
						setrenderproperty(NameText, "Visible", false)
					end

					if ESPSettings.Tracers then
						setrenderproperty(TracerLine, "Visible", true)
						setrenderproperty(TracerLine, "From", Vector2new(CameraViewportSize.X / 2, CameraViewportSize.Y))
						setrenderproperty(TracerLine, "To", Vector2new(RootPos.X, RootPos.Y + Height / 2))
						setrenderproperty(TracerLine, "Color", ESPSettings.Color)
					else
						setrenderproperty(TracerLine, "Visible", false)
					end
				else
					setrenderproperty(Box, "Visible", false)
					setrenderproperty(NameText, "Visible", false)
					setrenderproperty(TracerLine, "Visible", false)
				end
			end
		end
	end))

	ServiceConnections.UpdateTracer = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		local ClosestPlayer = TracerSettings.Enabled and Settings.Enabled and GetClosestPlayer(true)

		if ClosestPlayer then
			setrenderproperty(Tracer, "Visible", true)
			for Index, Value in next, TracerSettings do
				if Index == "Color" then continue end
				if pcall(getrenderproperty, Tracer, Index) then
					setrenderproperty(Tracer, Index, Value)
				end
			end
			setrenderproperty(Tracer, "Color", TracerSettings.RainbowColor and GetRainbowColor(1) or TracerSettings.Color)

			if TracerSettings.Position == 1 then
				setrenderproperty(Tracer, "From", Vector2new(CameraViewportSize.X / 2, CameraViewportSize.Y))
			elseif TracerSettings.Position == 2 then
				setrenderproperty(Tracer, "From", CameraViewportSize / 2)
			elseif TracerSettings.Position == 3 then
				setrenderproperty(Tracer, "From", GetMouseLocation(UserInputService))
			else
				TracerSettings.Position = 3
			end

			setrenderproperty(Tracer, "To", ConvertVector(WorldToViewportPoint(Camera, __index(__index(ClosestPlayer, "Character")[Settings.LockPart], "Position"))))
		else
			setrenderproperty(Tracer, "Visible", false)
		end
	end))

	ServiceConnections.RenderSteppedConnection = Connect(__index(RunService, UpdateMode), LPH_NO_VIRTUALIZE(function()
		if FOVSettings.Enabled and Settings.Enabled then
			for Index, Value in next, FOVSettings do
				if Index == "Color" then continue end
				if pcall(getrenderproperty, FOVCircle, Index) then
					setrenderproperty(FOVCircle, Index, Value)
					setrenderproperty(FOVCircleOutline, Index, Value)
				end
			end

			setrenderproperty(FOVCircle, "Color", (Environment.Locked and FOVSettings.LockedColor) or FOVSettings.RainbowColor and GetRainbowColor(1) or FOVSettings.Color)
			setrenderproperty(FOVCircleOutline, "Color", FOVSettings.RainbowOutlineColor and GetRainbowColor(1) or FOVSettings.OutlineColor)
			setrenderproperty(FOVCircleOutline, "Thickness", FOVSettings.Thickness + 1)
			setrenderproperty(FOVCircle, "Position", GetMouseLocation(UserInputService))
			setrenderproperty(FOVCircleOutline, "Position", GetMouseLocation(UserInputService))
		else
			setrenderproperty(FOVCircle, "Visible", false)
			setrenderproperty(FOVCircleOutline, "Visible", false)
		end

		if Running and Settings.Enabled then
			GetClosestPlayer()
			local Offset = OffsetToMoveDirection and __index(FindFirstChildOfClass(__index(Environment.Locked, "Character"), "Humanoid"), "MoveDirection") * (mathclamp(Settings.OffsetIncrement, 1, 30) / 10) or Vector3zero

			if Environment.Locked then
				local LockedPosition_Vector3 = __index(__index(Environment.Locked, "Character")[LockPart], "Position")
				local LockedPosition = WorldToViewportPoint(Camera, LockedPosition_Vector3 + Offset)

				if Settings.LockMode == 2 then
					local MousePos = GetMouseLocation(UserInputService)
					local DeltaX = (LockedPosition.X - MousePos.X)
					local DeltaY = (LockedPosition.Y - MousePos.Y)
					
					local SmoothFactor = mathclamp(Settings.Sensitivity2, 1, 30)
					mousemoverel(DeltaX / SmoothFactor, DeltaY / SmoothFactor)
				elseif Settings.LockMode == 3 and mousemoveabs then
					mousemoveabs(LockedPosition.X, LockedPosition.Y)
				else
					if Settings.Sensitivity > 0 then
						Animation = TweenService:Create(Camera, TweenInfonew(Settings.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset)})
						Animation:Play()
					else
						__newindex(Camera, "CFrame", CFramenew(Camera.CFrame.Position, LockedPosition_Vector3 + Offset))
					end
					__newindex(UserInputService, "MouseDeltaSensitivity", 0)
				end

				setrenderproperty(FOVCircle, "Color", FOVSettings.LockedColor)
				setrenderproperty(Tracer, "Visible", false)
			end
		end
	end))

	ServiceConnections.InputBeganConnection = Connect(__index(UserInputService, "InputBegan"), LPH_NO_VIRTUALIZE(function(Input, GameProcessed)
		if Typing then return end
		local TriggerKey = Settings.TriggerKey

		if Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			Running = true
		end
	end))

	ServiceConnections.InputEndedConnection = Connect(__index(UserInputService, "InputEnded"), LPH_NO_VIRTUALIZE(function(Input, GameProcessed)
		if Typing then return end
		local TriggerKey = Settings.TriggerKey

		if Input.KeyCode == TriggerKey or Input.UserInputType == TriggerKey then
			Running = false
			CancelLock()
		end
	end))
end

--// Typing Check
ServiceConnections.TypingStartedConnection = Connect(__index(UserInputService, "TextBoxFocused"), function()
	Typing = true
end)
ServiceConnections.TypingEndedConnection = Connect(__index(UserInputService, "TextBoxFocusReleased"), function()
	Typing = false
end)

--// Rayfield UI
local function BuildGUI()
	local Success, Rayfield = pcall(function()
		return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
	end)

	if not Success or not Rayfield then return end

	local Window = Rayfield:CreateWindow({
		Name = "Exunys Aimbot V3 - Ultimate Hub",
		LoadingTitle = "Ładowanie...",
		LoadingSubtitle = "by Exunys",
		ConfigurationSaving = { Enabled = false },
		KeySystem = false,
	})

	local MainTab = Window:CreateTab("Aimbot", 4483362458)
	
	pcall(function()
		MainTab:CreateToggle({
			Name = "Aktywny",
			CurrentValue = Environment.Settings.Enabled,
			Callback = function(Value)
				Environment.Settings.Enabled = Value
			end,
		})
	end)

	pcall(function()
		MainTab:CreateKeybind({
			Name = "Klawisz Celowania",
			CurrentKeybind = Enum.KeyCode.Q,
			HoldToInteract = false,
			Flag = "AimKeybind",
			Callback = function(Keybind)
				Environment.Settings.TriggerKey = Keybind
			end,
		})
	end)

	pcall(function()
		MainTab:CreateToggle({
			Name = "Team Check",
			CurrentValue = Environment.Settings.TeamCheck,
			Callback = function(Value)
				Environment.Settings.TeamCheck = Value
			end,
		})
	end)

	pcall(function()
		MainTab:CreateToggle({
			Name = "Wall Check (Przez ściany)",
			CurrentValue = Environment.Settings.WallCheck,
			Callback = function(Value)
				Environment.Settings.WallCheck = Value
			end,
		})
	end)

	pcall(function()
		MainTab:CreateSlider({
			Name = "Smooth (Płynność celowania)",
			Range = {1, 25},
			Increment = 0.5,
			CurrentValue = Environment.Settings.Sensitivity2,
			Callback = function(Value)
				Environment.Settings.Sensitivity2 = Value
			end,
		})
	end)

	pcall(function()
		MainTab:CreateDropdown({
			Name = "Część ciała",
			Options = {"Head", "HumanoidRootPart", "UpperTorso"},
			CurrentOption = Environment.Settings.LockPart,
			Callback = function(Option)
				Environment.Settings.LockPart = Option[1]
			end,
		})
	end)

	local ESPTab = Window:CreateTab("ESP", 4483362458)

	pcall(function()
		ESPTab:CreateToggle({
			Name = "Włącz ESP",
			CurrentValue = Environment.ESP.Enabled,
			Callback = function(Value)
				Environment.ESP.Enabled = Value
			end,
		})
	end)

	pcall(function()
		ESPTab:CreateToggle({
			Name = "Boxy (Ładne ramki)",
			CurrentValue = Environment.ESP.Boxes,
			Callback = function(Value)
				Environment.ESP.Boxes = Value
			end,
		})
	end)

	pcall(function()
		ESPTab:CreateToggle({
			Name = "Nazwy i Dystans",
			CurrentValue = Environment.ESP.Names,
			Callback = function(Value)
				Environment.ESP.Names = Value
			end,
		})
	end)

	pcall(function()
		ESPTab:CreateToggle({
			Name = "Tracersy do graczy",
			CurrentValue = Environment.ESP.Tracers,
			Callback = function(Value)
				Environment.ESP.Tracers = Value
			end,
		})
	end)

	pcall(function()
		ESPTab:CreateToggle({
			Name = "Team Check (ESP)",
			CurrentValue = Environment.ESP.TeamCheck,
			Callback = function(Value)
				Environment.ESP.TeamCheck = Value
			end,
		})
	end)

	local VisualsTab = Window:CreateTab("Celownik", 4483362458)

	pcall(function()
		VisualsTab:CreateToggle({
			Name = "Włącz Celownik (Gwiazda Rainbow)",
			CurrentValue = Environment.CustomCrosshair.Enabled,
			Callback = function(Value)
				Environment.CustomCrosshair.Enabled = Value
			end,
		})
	end)

	pcall(function()
		VisualsTab:CreateToggle({
			Name = "Obrót celownika (Kręcenie się)",
			CurrentValue = Environment.CustomCrosshair.Spin,
			Callback = function(Value)
				Environment.CustomCrosshair.Spin = Value
			end,
		})
	end)

	pcall(function()
		VisualsTab:CreateSlider({
			Name = "Rozmiar celownika (Skala)",
			Range = {4, 30},
			Increment = 1,
			CurrentValue = Environment.CustomCrosshair.Size,
			Callback = function(Value)
				Environment.CustomCrosshair.Size = Value
			end,
		})
	end)

	pcall(function()
		VisualsTab:CreateSlider({
			Name = "Prędkość obrotu",
			Range = {0.5, 10},
			Increment = 0.5,
			CurrentValue = Environment.CustomCrosshair.Speed,
			Callback = function(Value)
				Environment.CustomCrosshair.Speed = Value
			end,
		})
	end)

	local TriggerTab = Window:CreateTab("Triggerbot", 4483362458)

	pcall(function()
		TriggerTab:CreateToggle({
			Name = "Włącz Triggerbota (Głowa)",
			CurrentValue = Environment.Triggerbot.Enabled,
			Callback = function(Value)
				Environment.Triggerbot.Enabled = Value
			end,
		})
	end)

	pcall(function()
		TriggerTab:CreateSlider({
			Name = "Opóźnienie strzału (ms)",
			Range = {0, 500},
			Increment = 10,
			CurrentValue = Environment.Triggerbot.Delay * 1000,
			Callback = function(Value)
				Environment.Triggerbot.Delay = Value / 1000
			end,
		})
	end)

	pcall(function()
		TriggerTab:CreateToggle({
			Name = "Team Check (Triggerbot)",
			CurrentValue = Environment.Triggerbot.TeamCheck,
			Callback = function(Value)
				Environment.Triggerbot.TeamCheck = Value
			end,
		})
	end)

	local FOVTab = Window:CreateTab("FOV & Widok", 4483362458)

	pcall(function()
		FOVTab:CreateToggle({
			Name = "Pokaż okrąg FOV",
			CurrentValue = Environment.FOVSettings.Visible,
			Callback = function(Value)
				Environment.FOVSettings.Visible = Value
				Environment.FOVSettings.Enabled = Value
			end,
		})
	end)

	pcall(function()
		FOVTab:CreateSlider({
			Name = "Promień FOV (Rozmiar)",
			Range = {20, 400},
			Increment = 5,
			CurrentValue = Environment.FOVSettings.Radius,
			Callback = function(Value)
				Environment.FOVSettings.Radius = Value
			end,
		})
	end)

	pcall(function()
		FOVTab:CreateToggle({
			Name = "Tęcza FOV (Rainbow Color)",
			CurrentValue = Environment.FOVSettings.RainbowColor,
			Callback = function(Value)
				Environment.FOVSettings.RainbowColor = Value
			end,
		})
	end)
end

--// Interactive User Methods
Environment.Exit = LPH_NO_VIRTUALIZE(function(self)
	assert(self, "EXUNYS_AIMBOT-V3.Exit: Missing parameter #1 \"self\" <table>.")
	for Index, _ in next, ServiceConnections do
		pcall(Disconnect, ServiceConnections[Index])
	end
	Load = nil; ConvertVector = nil; CancelLock = nil; GetClosestPlayer = nil; GetRainbowColor = nil; FixUsername = nil
	pcall(function() self.FOVCircle:Remove() end)
	pcall(function() self.FOVCircleOutline:Remove() end)
	pcall(function() self.Tracer:Remove() end)
	for _, line in ipairs(StarLines) do
		pcall(function() line:Remove() end)
	end
	if self.ESPObjects then
		for player, _ in next, self.ESPObjects do
			CleanESP(player)
		end
	end
	getgenv().ExunysDeveloperAimbot = nil; pcall(collectgarbage, "step", 200)
end)

Environment.Restart = LPH_NO_VIRTUALIZE(function()
	for Index, _ in next, ServiceConnections do
		pcall(Disconnect, ServiceConnections[Index])
	end
	Load()
end)

Environment.Load = Load
setmetatable(Environment, {__call = Load})

Load()
pcall(BuildGUI)

return Environment