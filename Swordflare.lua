local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Swordflare Farm",
    LoadingTitle = "Swordflare Pro Farm",
    LoadingSubtitle = "By Haeser",
    ConfigurationSaving = { Enabled = true, FolderName = "SwordflareConfig", FileName = "Settings" },
    KeySystem = false
})

local FarmTab = Window:CreateTab("Farm", 4483362458)
local MovementTab = Window:CreateTab("Movement", 6031094678)
local ServerTab = Window:CreateTab("Server", 6031094678)

FarmTab:CreateSection("Auto Farm Controls")

FarmTab:CreateToggle({
    Name = "Auto Farm Enabled",
    CurrentValue = false,
    Callback = function(v) getgenv().FarmEnabled = v end
})

local mobOptions = {
    "Grass Warrior", "Forest Keeper", "Forest Spirit", "Stone Guard",
    "Obsidian Guard", "Fire Spirit", "Crystal Spirit", "Prism Spirit",
    "Elemental Caster", "Elite Forest Keeper", "Obsidian Guardian",
    "Flame Battlemage", "Forest Shade", "Crystal Shade",
    "Veiled Singularity"
}

local SelectedLabel = FarmTab:CreateParagraph({
    Title = "Currently Selected Mobs",
    Content = "None selected yet"
})

local MobDropdown = FarmTab:CreateDropdown({
    Name = "Select Mobs to Farm",
    Options = mobOptions,
    MultiSelect = true,
    CurrentOption = {},
    Flag = "SelectedMobs",
    Callback = function(Option)
        local selected = {}
        if typeof(Option) == "string" then
            table.insert(selected, Option)
        elseif typeof(Option) == "table" then
            selected = Option
        else
            selected = {}
        end

        getgenv().SelectedMobs = {}
        local lines = {}

        for _, mobName in ipairs(selected) do
            if mobName and mobName ~= "" then
                getgenv().SelectedMobs[mobName] = true
                table.insert(lines, mobName)
            end
        end

        if #lines == 0 then
            SelectedLabel:Set("None selected yet")
        else
            SelectedLabel:Set(table.concat(lines, "\n"))
        end
    end
})

FarmTab:CreateButton({Name = "Select All Mobs", Callback = function() MobDropdown:Set(mobOptions) end})
FarmTab:CreateButton({Name = "Clear Selection", Callback = function() MobDropdown:Set({}) end})

FarmTab:CreateSection("Position Settings")

getgenv().PositionMode = "Behind"
FarmTab:CreateDropdown({
    Name = "Teleport Position",
    Options = {"Behind", "Above", "Below"},
    CurrentOption = {"Behind"},
    Callback = function(o) getgenv().PositionMode = o[1] end
})

FarmTab:CreateSlider({
    Name = "Position Offset (Studs)",
    Range = {1, 15},
    Increment = 0.5,
    CurrentValue = 5,
    Callback = function(v) getgenv().OffsetDistance = v end
})

MovementTab:CreateSection("Movement Hacks")

local SpeedEnabled, SpeedValue = false, 16
MovementTab:CreateToggle({Name="Speed Hack", CurrentValue=false, Callback=function(v) SpeedEnabled = v end})
MovementTab:CreateSlider({Name="WalkSpeed", Range={1,100}, CurrentValue=16, Callback=function(v) SpeedValue = v end})

local FlyEnabled, FlySpeed = false, 50
MovementTab:CreateToggle({Name="Fly", CurrentValue=false, Callback=function(v) FlyEnabled = v end})
MovementTab:CreateSlider({Name="Fly Speed", Range={10,100}, CurrentValue=50, Callback=function(v) FlySpeed = v end})

local InfJumpEnabled = false
MovementTab:CreateToggle({Name="Infinite Jump", CurrentValue=false, Callback=function(v) InfJumpEnabled = v end})

MovementTab:CreateSection("GUI Controls")
MovementTab:CreateButton({
    Name = "Destroy GUI (Permanent - re-execute script to restore)",
    Callback = function() Rayfield:Destroy() print("GUI destroyed permanently.") end
})

ServerTab:CreateSection("Server Hopping")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local placeId = game.PlaceId

ServerTab:CreateButton({Name = "Rejoin Current Server", Callback = function() TS:TeleportToPlaceInstance(placeId, game.JobId) end})
ServerTab:CreateButton({Name = "Hop to Random Server", Callback = function() TS:Teleport(placeId) print("Hopping...") end})

ServerTab:CreateButton({
    Name = "Hop to Low Player Server (<10 players)",
    Callback = function()
        local servers = {}
        local s, r = pcall(function()
            return HS:GetAsync("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100")
        end)
        if s then
            local data = HS:JSONDecode(r)
            for _, v in ipairs(data.data or {}) do
                if v.id ~= game.JobId and v.playing and v.playing < 10 and v.playing > 0 then
                    table.insert(servers, v)
                end
            end
        end
        if #servers > 0 then
            table.sort(servers, function(a,b) return a.playing < b.playing end)
            TS:TeleportToPlaceInstance(placeId, servers[1].id)
            print("Hopping to server with "..servers[1].playing.." players")
        else
            print("No low-player servers → random hop")
            TS:Teleport(placeId)
        end
    end
})

Rayfield:LoadConfiguration()

getgenv().FarmEnabled = false
getgenv().SelectedMobs = {}
getgenv().OffsetDistance = 5

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local enemies = workspace:WaitForChild("Enemies")

spawn(function()
    while task.wait(0.1) do
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = SpeedEnabled and SpeedValue or 16 end
    end
end)

UIS.JumpRequest:Connect(function()
    if InfJumpEnabled then
        local hum = player.Character and player.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local bv, bg
spawn(function()
    while true do task.wait()
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        if FlyEnabled then
            bv = bv or Instance.new("BodyVelocity", root) bv.MaxForce = Vector3.new(1e9,1e9,1e9)
            bg = bg or Instance.new("BodyGyro", root) bg.MaxTorque = Vector3.new(1e9,1e9,1e9) bg.P = 20000
            local cam = workspace.CurrentCamera
            local move = Vector3.new()
            if UIS:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            bv.Velocity = move.Magnitude > 0 and (move.Unit * FlySpeed * 10) or Vector3.new()
            bg.CFrame = cam.CFrame
        else
            if bv then bv:Destroy() bv = nil end
            if bg then bg:Destroy() bg = nil end
        end
    end
end)

local function nameMatches(a, b)
    local ca = a:gsub("%s+", ""):lower()
    local cb = b:gsub("%s+", ""):lower()
    return cb:find(ca) or ca:find(cb)
end

spawn(function()
    while true do
        task.wait()
        if not getgenv().FarmEnabled or not next(getgenv().SelectedMobs) then continue end
        local char = player.Character if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart") if not root then continue end
        local tool = char:FindFirstChildOfClass("Tool")
        local click = tool and tool:FindFirstChild("Remotes") and tool.Remotes:FindFirstChild("Click")
        if not click then
            for _, t in player.Backpack:GetChildren() do
                if t:IsA("Tool") then t.Parent = char task.wait(0.1) break end
            end
            continue
        end
        for _, enemy in pairs(enemies:GetChildren()) do
            if not getgenv().FarmEnabled then break end
            local selected = getgenv().SelectedMobs[enemy.Name]
            if not selected then
                for sel in pairs(getgenv().SelectedMobs) do
                    if nameMatches(sel, enemy.Name) then selected = true break end
                end
            end
            if not selected then continue end
            local hitbox = enemy:FindFirstChild("Hitbox") or enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if not hitbox or not hum or hum.Health <= 0 then continue end
            local mode = getgenv().PositionMode
            local offset = getgenv().OffsetDistance
            local cf = hitbox.CFrame * (mode == "Behind" and CFrame.new(0,4,-offset) or mode == "Above" and CFrame.new(0,offset+3,0) or CFrame.new(0,-offset,0))
            root.CFrame = cf
            if mode == "Behind" then root.CFrame = CFrame.lookAt(root.Position, hitbox.Position) end
            click:FireServer() click:FireServer() click:FireServer()
            task.wait(0.1)
        end
    end
end)

print("Swordflare Farm loaded | Fixed dropdown | Press K to toggle GUI")
