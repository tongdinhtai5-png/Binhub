--==================================================
-- BIN HUB 1.1 + CLONE TP
--==================================================

if game.CoreGui:FindFirstChild("BinHub11") then
    game.CoreGui.BinHub11:Destroy()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local TPWalkLoop = nil
local TPScale = 0
local ESPActive = false
local FloatingActive = false
local AimbotActive = false
local FloatPart = nil

-- CLONE TP
local CloneTPActive = false
local CharacterClone = nil
local ClonePosition = nil

--==================================================
-- TP WALK
--==================================================

local function StartTPWalk(scaleValue)
    TPScale = scaleValue

    if TPWalkLoop then
        TPWalkLoop:Disconnect()
        TPWalkLoop = nil
    end

    TPWalkLoop = RunService.Heartbeat:Connect(function()
        pcall(function()
            local Character = LocalPlayer.Character
            if not Character then return end

            local Root = Character:FindFirstChild("HumanoidRootPart")
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")

            if Root and Humanoid and Humanoid.MoveDirection.Magnitude > 0 then
                local Direction = Humanoid.MoveDirection
                local Velocity = Direction * (TPScale * 10)

                Root.Velocity = Vector3.new(
                    Velocity.X,
                    Root.Velocity.Y,
                    Velocity.Z
                )
            end
        end)
    end)
end

local function StopTPWalk()
    if TPWalkLoop then
        TPWalkLoop:Disconnect()
        TPWalkLoop = nil
    end

    TPScale = 0
end

--==================================================
-- ESP
--==================================================

local function CreateESP(Player)
    if Player == LocalPlayer then return end

    local function SetupCharacter(Character)
        local Root = Character:WaitForChild("HumanoidRootPart", 5)
        if not Root then return end

        if Root:FindFirstChild("HitboxESP") then
            Root.HitboxESP:Destroy()
        end

        local Box = Instance.new("BoxHandleAdornment")
        Box.Name = "HitboxESP"
        Box.Size = Character:GetExtentsSize() + Vector3.new(0.5, 0.5, 0.5)
        Box.AlwaysOnTop = true
        Box.ZIndex = 5
        Box.Color3 = Color3.fromRGB(255, 30, 30)
        Box.Transparency = 0.55
        Box.Adornee = Root
        Box.Parent = Root
    end

    if Player.Character then
        SetupCharacter(Player.Character)
    end

    Player.CharacterAdded:Connect(SetupCharacter)
end

--==================================================
-- FLOATING
--==================================================

local function ToggleFloating()
    local Character = LocalPlayer.Character
    if not Character then return end

    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    if FloatingActive then
        if not FloatPart or not FloatPart.Parent then
            FloatPart = Instance.new("Part")
            FloatPart.Name = "BinHubFloatPart"
            FloatPart.Size = Vector3.new(6, 0.5, 6)
            FloatPart.Transparency = 1
            FloatPart.Anchored = true
            FloatPart.CanCollide = true
            FloatPart.Parent = workspace
        end

        FloatPart.CFrame = Root.CFrame * CFrame.new(0, -3.5, 0)
    else
        if FloatPart then
            FloatPart:Destroy()
            FloatPart = nil
        end
    end
end

--==================================================
-- AIMBOT V2
--==================================================

local AimbotFOV = 250
local AimbotMaxDistance = 150
local AimbotSmoothness = 0.18

local function GetClosestPlayerV2()
    local ClosestPlayer = nil
    local BestScore = math.huge
    local Character = LocalPlayer.Character

    if not Character then return nil end

    local MyRoot = Character:FindFirstChild("HumanoidRootPart")
    if not MyRoot then return nil end

    local Viewport = Camera.ViewportSize
    local ScreenCenter = Vector2.new(Viewport.X / 2, Viewport.Y / 2)

    for _, Player in ipairs(Players:GetPlayers()) do
        if Player ~= LocalPlayer and Player.Character then
            local Humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
            local Root = Player.Character:FindFirstChild("HumanoidRootPart")
            local Head = Player.Character:FindFirstChild("Head")

            if Humanoid and Humanoid.Health > 0 and Root and Head then
                local WorldDistance = (MyRoot.Position - Root.Position).Magnitude

                if WorldDistance <= AimbotMaxDistance then
                    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Head.Position)

                    if OnScreen and ScreenPos.Z > 0 then
                        local ScreenDistance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - ScreenCenter).Magnitude

                        if ScreenDistance <= AimbotFOV and ScreenDistance < BestScore then
                            BestScore = ScreenDistance
                            ClosestPlayer = Player
                        end
                    end
                end
            end
        end
    end

    return ClosestPlayer
end

local function UpdateAimbotV2()
    if not AimbotActive then return end

    local Target = GetClosestPlayerV2()
    if not Target or not Target.Character then return end

    local Head = Target.Character:FindFirstChild("Head")
        or Target.Character:FindFirstChild("HumanoidRootPart")

    if not Head then return end

    local Desired = CFrame.new(Camera.CFrame.Position, Head.Position)
    Camera.CFrame = Camera.CFrame:Lerp(Desired, AimbotSmoothness)
end

--==================================================
-- CLONE TP
--==================================================

local function RemoveCharacterClone()
    if CharacterClone then
        CharacterClone:Destroy()
        CharacterClone = nil
    end

    ClonePosition = nil
end

local function CreateCharacterClone()
    RemoveCharacterClone()

    local Character = LocalPlayer.Character
    if not Character then return end

    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    ClonePosition = Root.CFrame
    Character.Archivable = true

    local Clone = Character:Clone()
    Clone.Name = "BinHub_CloneTP"

    for _, Obj in ipairs(Clone:GetDescendants()) do
        if Obj:IsA("Script")
            or Obj:IsA("LocalScript")
            or Obj:IsA("ModuleScript") then

            Obj:Destroy()

        elseif Obj:IsA("BasePart") then
            Obj.Anchored = true
            Obj.CanCollide = false
            Obj.CanTouch = false
            Obj.CanQuery = false
            Obj.Transparency =
                math.clamp(Obj.Transparency + 0.15, 0, 1)

        elseif Obj:IsA("Humanoid") then
            Obj.DisplayDistanceType =
                Enum.HumanoidDisplayDistanceType.None
        end
    end

    Clone.Parent = workspace

    local CloneRoot = Clone:FindFirstChild("HumanoidRootPart")
    if CloneRoot then
        CloneRoot.CFrame = ClonePosition
    end

    CharacterClone = Clone
end

local function TeleportToClone()
    local Character = LocalPlayer.Character
    if not Character or not ClonePosition then return end

    local Root = Character:FindFirstChild("HumanoidRootPart")
    if Root then
        Root.CFrame = ClonePosition
    end
end

local function ToggleCloneTP(Value)
    CloneTPActive = Value

    if Value then
        CreateCharacterClone()
    else
        RemoveCharacterClone()
    end
end

--==================================================
-- RENDER LOOP
--==================================================

RunService.RenderStepped:Connect(function()

    if ESPActive then
        for _, Player in pairs(Players:GetPlayers()) do
            pcall(function()
                if Player ~= LocalPlayer
                    and Player.Character
                    and Player.Character:FindFirstChild("HumanoidRootPart") then

                    if not Player.Character.HumanoidRootPart:FindFirstChild("HitboxESP") then
                        CreateESP(Player)
                    end
                end
            end)
        end
    else
        for _, Player in pairs(Players:GetPlayers()) do
            pcall(function()
                if Player.Character
                    and Player.Character:FindFirstChild("HumanoidRootPart")
                    and Player.Character.HumanoidRootPart:FindFirstChild("HitboxESP") then

                    Player.Character.HumanoidRootPart.HitboxESP:Destroy()
                end
            end)
        end
    end

    if FloatingActive and FloatPart then
        pcall(function()
            local Character = LocalPlayer.Character

            if Character and Character:FindFirstChild("HumanoidRootPart") then
                local Root = Character.HumanoidRootPart

                FloatPart.CFrame = CFrame.new(
                    Root.Position.X,
                    FloatPart.Position.Y,
                    Root.Position.Z
                )
            end
        end)
    end

    pcall(UpdateAimbotV2)
end)

--==================================================
-- UI
--==================================================

local BinHub = {}

function BinHub:CreateWindow(TitleText)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BinHub11"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Name = "OpenBtn"
    OpenBtn.Parent = ScreenGui
    OpenBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    OpenBtn.Position = UDim2.new(0.18, 0, 0.03, 0)
    OpenBtn.Size = UDim2.new(0, 70, 0, 36)
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.Text = "GUI"
    OpenBtn.TextColor3 = Color3.fromRGB(255, 190, 0)
    OpenBtn.TextSize = 14

    Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 8)

    local OpenStroke = Instance.new("UIStroke")
    OpenStroke.Color = Color3.fromRGB(255, 190, 0)
    OpenStroke.Thickness = 1.2
    OpenStroke.Parent = OpenBtn

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    MainFrame.Position = UDim2.new(0.5, -105, 0.5, -190)
    MainFrame.Size = UDim2.new(0, 210, 0, 500)
    MainFrame.Visible = false

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(40, 40, 48)
    MainStroke.Thickness = 1.5
    MainStroke.Parent = MainFrame

    local Header = Instance.new("Frame")
    Header.Parent = MainFrame
    Header.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    Header.Size = UDim2.new(1, 0, 0, 42)

    Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

    local HeaderHide = Instance.new("Frame")
    HeaderHide.Parent = Header
    HeaderHide.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
    HeaderHide.BorderSizePixel = 0
    HeaderHide.Position = UDim2.new(0, 0, 1, -10)
    HeaderHide.Size = UDim2.new(1, 0, 0, 10)

    local Title = Instance.new("TextLabel")
    Title.Parent = Header
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = TitleText
    Title.TextColor3 = Color3.fromRGB(255, 205, 50)
    Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent = Header
    CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
    CloseBtn.Position = UDim2.new(1, -32, 0.5, -11)
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 75, 75)
    CloseBtn.TextSize = 18

    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

    local Container = Instance.new("ScrollingFrame")
    Container.Parent = MainFrame
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Position = UDim2.new(0, 0, 0, 52)
    Container.Size = UDim2.new(1, 0, 1, -52)
    Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Container.ScrollBarThickness = 3

    local Layout = Instance.new("UIListLayout")
    Layout.Parent = Container
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 9)

    OpenBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = true
        OpenBtn.Visible = false
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Visible = false
        OpenBtn.Visible = true
    end)

    local Dragging = false
    local DragInput
    local DragStart
    local StartPos

    local function Update(input)
        local Delta = input.Position - DragStart

        MainFrame.Position = UDim2.new(
            StartPos.X.Scale,
            StartPos.X.Offset + Delta.X,
            StartPos.Y.Scale,
            StartPos.Y.Offset + Delta.Y
        )
    end

    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)

    return {
        Container = Container
    }
end

function BinHub:CreateButton(Window, Options)

    local Button = Instance.new("TextButton")
    Button.Parent = Window.Container
    Button.BackgroundColor3 =
        Options.BoxColor or Color3.fromRGB(28, 28, 36)
    Button.Size = UDim2.new(0.88, 0, 0, 36)
    Button.Font = Enum.Font.GothamBold
    Button.Text = "  " .. Options.Name
    Button.TextColor3 =
        Options.TextColor or Color3.fromRGB(240, 240, 240)
    Button.TextSize = 13
    Button.TextXAlignment = Enum.TextXAlignment.Left
    Button.AutoButtonColor = false

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(45, 45, 55)
    Stroke.Thickness = 1
    Stroke.Parent = Button

    local Arrow = Instance.new("TextLabel")
    Arrow.BackgroundTransparency = 1
    Arrow.Position = UDim2.new(1, -25, 0, 0)
    Arrow.Size = UDim2.new(0, 20, 1, 0)
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Text = "→"
    Arrow.TextColor3 =
        Options.TextColor or Color3.fromRGB(150, 150, 160)
    Arrow.TextSize = 14
    Arrow.Parent = Button

    Button.MouseButton1Click:Connect(function()
        if Options.Callback then
            Options.Callback()
        end
    end)

    return Button
end

function BinHub:CreateToggle(Window, Options)

    local State = false

    local Frame = Instance.new("Frame")
    Frame.Parent = Window.Container
    Frame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
    Frame.Size = UDim2.new(0.88, 0, 0, 38)

    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel")
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.Size = UDim2.new(0.65, 0, 1, 0)
    Label.Font = Enum.Font.GothamBold
    Label.Text = Options.Name
    Label.TextColor3 = Color3.fromRGB(220, 220, 225)
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local Toggle = Instance.new("TextButton")
    Toggle.Parent = Frame
    Toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
    Toggle.Position = UDim2.new(1, -48, 0.5, -9)
    Toggle.Size = UDim2.new(0, 36, 0, 18)
    Toggle.Text = ""

    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    Knob.Position = UDim2.new(0, 2, 0.5, -7)
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Parent = Toggle

    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    Toggle.MouseButton1Click:Connect(function()
        State = not State

        if State then
            Toggle.BackgroundColor3 = Color3.fromRGB(30, 140, 70)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

            Knob:TweenPosition(
                UDim2.new(1, -16, 0.5, -7),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.15,
                true
            )

            Label.TextColor3 =
                Options.ActiveColor or Color3.fromRGB(255, 255, 255)
        else
            Toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
            Knob.BackgroundColor3 = Color3.fromRGB(160, 160, 160)

            Knob:TweenPosition(
                UDim2.new(0, 2, 0.5, -7),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.15,
                true
            )

            Label.TextColor3 = Color3.fromRGB(220, 220, 225)
        end

        if Options.Callback then
            Options.Callback(State)
        end
    end)

    return Frame
end

--==================================================
-- CREATE BIN HUB
--==================================================

local Window = BinHub:CreateWindow("Bin Hub 1.1")

BinHub:CreateButton(Window, {
    Name = "TP Walk 4",
    BoxColor = Color3.fromRGB(25, 32, 35),
    TextColor = Color3.fromRGB(80, 220, 255),
    Callback = function()
        StartTPWalk(4)
    end
})

BinHub:CreateButton(Window, {
    Name = "TP Walk 5",
    BoxColor = Color3.fromRGB(32, 28, 40),
    TextColor = Color3.fromRGB(180, 120, 255),
    Callback = function()
        StartTPWalk(5)
    end
})

BinHub:CreateButton(Window, {
    Name = "TP Walk 10",
    BoxColor = Color3.fromRGB(25, 35, 25),
    TextColor = Color3.fromRGB(80, 255, 120),
    Callback = function()
        StartTPWalk(10)
    end
})

BinHub:CreateButton(Window, {
    Name = "Disable TP Walk",
    BoxColor = Color3.fromRGB(35, 25, 25),
    TextColor = Color3.fromRGB(255, 100, 100),
    Callback = function()
        StopTPWalk()
    end
})

BinHub:CreateToggle(Window, {
    Name = "ESP Hitbox Targets",
    ActiveColor = Color3.fromRGB(255, 220, 60),
    Callback = function(Value)
        ESPActive = Value
    end
})

BinHub:CreateToggle(Window, {
    Name = "Platform Floating",
    ActiveColor = Color3.fromRGB(60, 240, 255),
    Callback = function(Value)
        FloatingActive = Value
        ToggleFloating()
    end
})

BinHub:CreateToggle(Window, {
    Name = "Aimbot V2",
    ActiveColor = Color3.fromRGB(255, 120, 200),
    Callback = function(Value)
        AimbotActive = Value
    end
})

--==================================================
-- CLONE TP TOGGLE
--==================================================

BinHub:CreateToggle(Window, {
    Name = "Clone TP",
    ActiveColor = Color3.fromRGB(255, 190, 60),
    Callback = function(Value)
        ToggleCloneTP(Value)
    end
})

-- TP VỀ VỊ TRÍ CLONE
BinHub:CreateButton(Window, {
    
    Name = ""TP Back To Clone",
    BoxColor = Color3.fromRGB(35, 30, 20),
    TextColor = Color3.fromRGB(255, 210, 70),
    Callback = function()
        TeleportToClone()
    end
})

--==================================================
-- NOTIFICATION
--==================================================

pcall(function()
    game:GetService("StarterGui"):SetCore(
        "SendNotification",
        {
            Title = "Bin Hub 1.1",
            Text = "Bin Hub + Clone TP loaded!",
            Duration = 3
        }
    )
end)
