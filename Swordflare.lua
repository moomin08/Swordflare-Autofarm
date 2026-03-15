-- Swordflare Farm - Updated (no selected mobs label + refresh + experimental spawn trigger)

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

-- ==================== FARM SETTINGS ====================
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

getgenv().SelectedMobs = {}

local MobDropdown = FarmTab:CreateDropdown({
    Name = "Select Mobs to Farm",
    Options = mobOptions,
    MultiSelect = true,
    CurrentOption = {},
    Flag = "SelectedMobsToFarm",
    Callback = function(Options)
        getgenv().SelectedMobs = {}
        for _, mobName in ipairs(Options or {}) do
            if typeof(mobName) == "string" and mobName ~= "" then
                getgenv().SelectedMobs[mobName] = true
            end
        end
    end
})

FarmTab:CreateButton({
    Name = "Select All Mobs",
    Callback = function()
        MobDropdown:Set(mobOptions)
    end
})

FarmTab:CreateButton({
    Name = "Clear Selection",
    Callback = function()
        MobDropdown:Set({})
    end
})

FarmTab:CreateButton({
    Name = "Refresh Mobs (Re-check enemies)",
    Callback = function()
        print("Refreshing enemies list...")
        -- Just a placeholder; sometimes calling GetChildren again helps sync
        -- You can add workspace.Enemies.ChildAdded:Wait() or something if needed
    end
})

FarmTab:CreateToggle({
    Name = "Force Mob Spawn Area (Experimental - may help bosses)",
    CurrentValue = false,
    Callback = function(v)
        getgenv().ForceSpawnCheck = v
        if v then
            print("Force spawn mode ON - will try to visit areas if no mobs found")
        else
            print("Force spawn mode OFF")
        end
    end
})

-- ==================== POSITION CONTROL ====================
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

-- ==================== MOVEMENT HACKS ====================
-- (keeping your existing movement section unchanged for brevity)

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
    Name = "Destroy GUI (Permanent - re-execute to restore)",
    Callback = function()
        Rayfield:Destroy()
        print("GUI destroyed permanently.")
    end
})

-- ==================== SERVER HOPPING ====================
-- (keeping your existing server section)

ServerTab:CreateSection("Server Hopping")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local placeId = game.PlaceId

ServerTab:CreateButton({Name = "Rejoin Current Server", Callback = function() TeleportService:TeleportToPlaceInstance(placeId, game.JobId) end})
ServerTab:CreateButton({Name = "Hop to Random Server", Callback = function() TeleportService:Teleport(placeId) print("Hopping...") end})

ServerTab:CreateButton({
    Name = "Hop to Low Player Server (<10 players)",
    Callback = function()
        local servers = {}
        local s, r = pcall(function()
            return HttpService:GetAsync("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100")
        end)
        if s then
            local data = HttpService:JSONDecode(r)
            for _, v in ipairs(data.data or {}) do
                if v.id ~= game.JobId and v.playing and v.playing < 10 and v.playing > 0 then
                    table.insert(servers, v)
                end
            end
        end
        if #servers > 0 then
            table.sort(servers, function(a,b) return a.playing < b.playing end)
            TeleportService:TeleportToPlaceInstance(placeId, servers[1].id)
        else
            TeleportService:Teleport(placeId)
        end
    end
})

Rayfield:LoadConfiguration()

-- ==================== CORE VARIABLES & LOOPS ====================
getgenv().FarmEnabled = false
getgenv().SelectedMobs = {}
getgenv().OffsetDistance = 5
getgenv().ForceSpawnCheck = false

local player = game.Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local enemiesFolder = workspace:WaitForChild("Enemies")

-- Speed, Fly, Inf Jump loops (unchanged, assuming you have them)

-- Main Farm Loop with experimental spawn trigger
spawn(function()
    while true do
        task.wait(0.2)  -- slightly slower to reduce lag

        if not getgenv().FarmEnabled or not next(getgenv().SelectedMobs) then continue end

        local char = player.Character
        if not char then continue end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local originalPos = root.CFrame  -- remember where we were

        local tool = char:FindFirstChildOfClass("Tool")
        local clickRemote = tool and tool:FindFirstChild("Remotes") and tool.Remotes:FindFirstChild("Click")

        if not clickRemote then
            -- equip tool logic (unchanged)
            for _, t in player.Backpack:GetChildren() do
                if t:IsA("Tool") then t.Parent = char task.wait(0.1) break end
            end
            continue
        end

        local foundAny = false

        for _, enemy in pairs(enemiesFolder:GetChildren()) do
            if not getgenv().FarmEnabled then break end

            local isTarget = getgenv().SelectedMobs[enemy.Name]
            if not isTarget then
                for sel in pairs(getgenv().SelectedMobs) do
                    if enemy.Name:lower():find(sel:lower()) or sel:lower():find(enemy.Name:lower()) then
                        isTarget = true
                        break
                    end
                end
            end

            if not isTarget then continue end

            local hitbox = enemy:FindFirstChild("Hitbox") or enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
            local hum = enemy:FindFirstChildOfClass("Humanoid")

            if not hitbox or not hum or hum.Health <= 0 then continue end

            foundAny = true

            local mode = getgenv().PositionMode
            local offset = getgenv().OffsetDistance
            local targetCF = hitbox.CFrame * (
                mode == "Behind" and CFrame.new(0,4,-offset) or
                mode == "Above"  and CFrame.new(0,offset+3,0) or
                CFrame.new(0,-offset,0)
            )

            root.CFrame = targetCF

            if mode == "Behind" then
                root.CFrame = CFrame.lookAt(root.Position, hitbox.Position)
            end

            for _ = 1, 3 do
                clickRemote:FireServer()
            end

            task.wait(0.12)
        end

        -- Experimental: if no targets found and force mode on → try to "visit" areas
        if getgenv().ForceSpawnCheck and not foundAny then
            print("No matching mobs → trying to force spawn areas...")

            -- Example positions - REPLACE THESE WITH ACTUAL COORDINATES FROM THE GAME
            -- You need to find safe-ish spots near boss spawn areas (use F3X or explorer to get coords)
            local possibleSpawnSpots = {
                CFrame.new(150, 50, -200),   -- example: near Crystal Shade area (CHANGE THESE!)
                CFrame.new(-300, 80, 400),   -- another possible boss zone
                CFrame.new(0, 100, 0)        -- add more if you know them
            }

            for _, spot in ipairs(possibleSpawnSpots) do
                if not getgenv().FarmEnabled then break end
                root.CFrame = spot
                task.wait(1.5)  -- give server time to spawn mobs
            end

            -- Return to original spot
            root.CFrame = originalPos
            task.wait(0.5)
        end
    end
end)

print("Swordflare Farm loaded - no selected label, refresh button added, experimental spawn force ON")
