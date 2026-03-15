-- Swordflare Selective Auto-Farm + Speed/Fly/Inf Jump + Position Control (Rayfield UI)
-- Behind/Above/Below + Offset Slider | Speed 1-100 | Fly + Inf Jump

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Swordflare Farm",
    LoadingTitle = "Swordflare Pro Farm",
    LoadingSubtitle = "By Haeser",
    ConfigurationSaving = { Enabled = true, FolderName = "SwordflareConfig", FileName = "Settings" },
    Discord = { Enabled = false },
    KeySystem = false
})

local FarmTab = Window:CreateTab("Farm", 4483362458)
local MovementTab = Window:CreateTab("Movement", 6031094678)

-- ==================== FARM SETTINGS ====================
local FarmSection = FarmTab:CreateSection("Auto Farm Controls")

local EnabledToggle = FarmTab:CreateToggle({
    Name = "Auto Farm Enabled",
    CurrentValue = false,
    Flag = "FarmEnabled",
    Callback = function(Value) getgenv().FarmEnabled = Value end
})

local mobOptions = {
    "Grass Warrior", "Forest Keeper", "Forest Spirit", "Stone Guard",
    "Obsidian Guard", "Fire Spirit", "Crystal Spirit", "Prism Spirit",
    "Elemental Caster", "Elite Forest Keeper(Boss)", "Obsidian Guardian",
    "Flame Battlemage (Boss)", "Forest Shade (Boss)", "Crystal Shade (Boss)",
    "Veiled Singularity (Boss)"
}

local MobDropdown = FarmTab:CreateDropdown({
    Name = "Select Mobs to Farm",
    Options = mobOptions,
    CurrentOption = {},
    MultiSelect = true,
    Flag = "SelectedMobs",
    Callback = function(Options)
        getgenv().SelectedMobs = {}
        for _, v in ipairs(Options) do getgenv().SelectedMobs[v] = true end
    end
})

-- Quick buttons
FarmTab:CreateButton({ Name = "Select All", Callback = function() MobDropdown:Set(mobOptions) end })
FarmTab:CreateButton({ Name = "Clear Selection", Callback = function() MobDropdown:Refresh({}, true) getgenv().SelectedMobs = {} end })

-- ==================== POSITION CONTROL ====================
local PositionSection = FarmTab:CreateSection("Position Settings")

local PositionMode = "Behind"
local PositionDropdown = FarmTab:CreateDropdown({
    Name = "Teleport Position",
    Options = {"Behind", "Above", "Below"},
    CurrentOption = {"Behind"},
    MultiSelect = false,
    Callback = function(Option) PositionMode = Option[1] end
})

local OffsetSlider = FarmTab:CreateSlider({
    Name = "Position Offset (Studs)",
    Range = {1, 15},
    Increment = 0.5,
    CurrentValue = 5,
    Flag = "Offset",
    Callback = function(Value) getgenv().OffsetDistance = Value end
})

-- ==================== MOVEMENT HACKS ====================
local MoveSection = MovementTab:CreateSection("Movement Hacks")

-- Speed Hack
local SpeedEnabled = false
local SpeedValue = 16

local SpeedToggle = MovementTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Callback = function(Value) SpeedEnabled = Value end
})

local SpeedSlider = MovementTab:CreateSlider({
    Name = "WalkSpeed (1-100)",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value) SpeedValue = Value end
})

-- Fly
local FlyEnabled = false
local FlySpeed = 50

local FlyToggle = MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value) FlyEnabled = Value end
})

local FlySlider = MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 100},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(Value) FlySpeed = Value end
})

-- Infinite Jump
local InfJumpEnabled = false

local InfJumpToggle = MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value) InfJumpEnabled = Value end
})

Rayfield:LoadConfiguration()

-- ==================== CORE VARIABLES ====================
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local enemies = workspace:WaitForChild("Enemies")

getgenv().FarmEnabled = false
getgenv().SelectedMobs = {}
getgenv().OffsetDistance = 5

-- ==================== MOVEMENT HANDLERS ====================

-- Speed Handler
spawn(function()
    while task.wait(0.1) do
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            if SpeedEnabled then
                hum.WalkSpeed = SpeedValue
            else
                hum.WalkSpeed = 16
            end
        end
    end
end)

-- Infinite Jump
UIS.JumpRequest:Connect(function()
    if InfJumpEnabled then
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Fly Handler
local bv, bg = nil, nil
spawn(function()
    while true do
        task.wait()
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        if FlyEnabled then
            if not bv then
                bv = Instance.new("BodyVelocity")
                bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                bv.Parent = root

                bg = Instance.new("BodyGyro")
                bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                bg.P = 20000
                bg.Parent = root
            end

            local cam = workspace.CurrentCamera
            local move = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end

            bv.Velocity = move.Unit * FlySpeed * 10
            bg.CFrame = cam.CFrame
        else
            if bv then bv:Destroy() bv = nil end
            if bg then bg:Destroy() bg = nil end
        end
    end
end)

-- ==================== MAIN FARM LOOP ====================
spawn(function()
    while true do
        if not getgenv().FarmEnabled or next(getgenv().SelectedMobs) == nil then
            task.wait(0.2) continue
        end

        local char = player.Character
        if not char then task.wait() continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then task.wait() continue end

        local tool = char:FindFirstChildOfClass("Tool")
        local click = tool and tool:FindFirstChild("Remotes") and tool.Remotes:FindFirstChild("Click")

        if not click then
            for _, t in player.Backpack:GetChildren() do
                if t:IsA("Tool") then t.Parent = char task.wait(0.1) break end
            end
            task.wait() continue
        end

        for _, enemy in pairs(enemies:GetChildren()) do
            if not getgenv().FarmEnabled then break end
            if not getgenv().SelectedMobs[enemy.Name] then continue end

            local hitbox = enemy:FindFirstChild("Hitbox")
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if not hitbox or not hum or hum.Health <= 0 then continue end

            -- Dynamic Position (Behind / Above / Below)
            local offset = getgenv().OffsetDistance
            local targetCFrame

            if PositionMode == "Behind" then
                targetCFrame = hitbox.CFrame * CFrame.new(0, 4, -offset)
            elseif PositionMode == "Above" then
                targetCFrame = hitbox.CFrame * CFrame.new(0, offset + 3, 0)
            elseif PositionMode == "Below" then
                targetCFrame = hitbox.CFrame * CFrame.new(0, -offset, 0)
            end

            root.CFrame = targetCFrame

            -- Face enemy when behind
            if PositionMode == "Behind" then
                local look = CFrame.lookAt(root.Position, hitbox.Position)
                root.CFrame = CFrame.new(root.Position) * look.Rotation
            end

            -- Fast M1 (same delay as your original sample)
            click:FireServer()
            click:FireServer()
            click:FireServer()

            task.wait(0.1)
        end

        task.wait()
    end
end)

print("✅ Full Rayfield Farm Loaded! Use the tabs to configure everything.")