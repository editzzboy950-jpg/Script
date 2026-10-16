--[==[
    Xen Hub — Wind UI Re-implementation
    All original functional code, features, state loops, and hooks preserved 1:1.
]==]

-------------------------------------------------------------------------------
-- Services / globals                                                  
-------------------------------------------------------------------------------
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService       = game:GetService("HttpService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")
local GuiService        = game:GetService("GuiService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-------------------------------------------------------------------------------
-- Settings / config file                                       
-------------------------------------------------------------------------------
getgenv().Setting = getgenv().Setting or {}
local Setting = getgenv().Setting
Setting.FileName    = "Xen-Hub-67.json"
Setting.MaxDistance = 350

local function CreateDefaultSettings()                                            
    return {
        CamlockEnabled   = false, WalkOnWater   = false, AutoRaceV3 = false, AutoRaceV4 = false,
        SpeedEnabled     = false, DashEnabled   = false, SpeedValue = 16,    DashValue  = 300,
        FADistance       = 8,     AimbotSkills  = false, FastAttack = false, InfiniteEnergy = false,
        UnbreakableSkills = false, AntiStun     = false, PlayerEsp  = false,
        PlayerTracers    = true,  NPCTracers    = true,  PredictionAmount = 0.163186,
        AimbotSkillsNPC  = false, AimbotSkillsPlayer = false,
    }
end
Setting.Data = CreateDefaultSettings()

local function SaveSettings()                                             
    pcall(function()
        writefile(Setting.FileName, HttpService:JSONEncode(Setting.Data))
    end)
end

local function LoadSettings()                                             
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(Setting.FileName))
    end)
    if ok and typeof(decoded) == "table" then
        for k, v in pairs(decoded) do
            Setting.Data[k] = v
        end
        return true
    end
    return false
end

if LoadSettings() then
    StarterGui:SetCore("SendNotification", {
        Title = "Xen Hub", Text = "Config Loaded Successfully!", Duration = 3,
    })
end

-- mirror persisted toggles into _G (the feature loops read _G)
_G.AutoRaceV3        = Setting.Data.AutoRaceV3
_G.AutoRaceV4        = Setting.Data.AutoRaceV4
_G.WalkOnWater       = Setting.Data.WalkOnWater
_G.FastAttackEnabled = Setting.Data.FastAttack
_G.InfiniteEnergy    = Setting.Data.InfiniteEnergy
_G.UnbreakableSkills = Setting.Data.UnbreakableSkills
_G.AntiStun          = Setting.Data.AntiStun
_G.PlayerEsp         = Setting.Data.PlayerEsp
_G.FADistance        = Setting.Data.FADistance

-------------------------------------------------------------------------------
-- State shared by the recovered closures 
-------------------------------------------------------------------------------
local SpeedEnabled, DashEnabled = Setting.Data.SpeedEnabled, Setting.Data.DashEnabled
local AimbotNPC,  AimbotPlayer  = Setting.Data.AimbotSkillsNPC, Setting.Data.AimbotSkillsPlayer
local NPCTracers, PlayerTracers = Setting.Data.NPCTracers, Setting.Data.PlayerTracers
local CamlockEnabled, CamlockConn, CamlockTarget = false, nil, nil
local NPCTarget, PlayerTarget, NPCAimPoint, PlayerAimPoint = nil, nil, nil, nil
local MouseShadow = { Hit = nil, Target = nil }

local NPCLine    = Drawing.new("Line")                                   
NPCLine.Thickness, NPCLine.Color, NPCLine.Transparency, NPCLine.Visible = 1.5, Color3.fromRGB(255, 0, 0), 1, false
local PlayerLine = Drawing.new("Line")
PlayerLine.Thickness, PlayerLine.Color, PlayerLine.Transparency, PlayerLine.Visible = 1.5, Color3.fromRGB(0, 170, 255), 1, false

-------------------------------------------------------------------------------
-- Recovered helpers  
-------------------------------------------------------------------------------
local function GetPlayerLevel(player)                                          
    local data = player:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then return data.Level.Value end
    return "???"
end

local function IsAllyPlayer(player)                                            
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local list = playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Allies")
                 and playerGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
    return list and list:FindFirstChild(player.Name) ~= nil
end

local function IsPositionInSafeZone(position)                                      
    local origin = workspace:FindFirstChild("_WorldOrigin")
    local zones  = origin and origin:FindFirstChild("SafeZones")
    if not zones then return false end
    for _, part in ipairs(zones:GetChildren()) do
        if part:IsA("BasePart") then
            local mesh   = part:FindFirstChildOfClass("SpecialMesh")
            local radius = mesh and (mesh.Scale.X / 2) or 50
            if (part.Position - position).Magnitude <= radius then return true end
        end
    end
    return false
end

local function FindNearestValidPlayer(myHrp)                                  
    if not myHrp then return nil end
    local best, bestDist = nil, Setting.MaxDistance
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
           and plr.Character:FindFirstChild("Humanoid") then
            if plr.Character.Humanoid.Health > 0 then
                local hrp = plr.Character.HumanoidRootPart
                if IsPositionInSafeZone(hrp.Position) then continue end
                if plr:GetAttribute("PvpDisabled") or false then continue end
                if LocalPlayer.Team and plr.Team then
                    if LocalPlayer.Team.Name == "Marines" and plr.Team.Name == "Marines" then continue end
                end
                if IsAllyPlayer(plr) then continue end
                local dist = (myHrp.Position - hrp.Position).Magnitude
                if dist < bestDist then bestDist, best = dist, plr end
            end
        end
    end
    return best
end

local function FindNearestNPC(myHrp)                                     
    if not myHrp then return nil end
    local best, bestDist = nil, Setting.MaxDistance
    local enemies = workspace:FindFirstChild("Enemies")
    if enemies then
        for _, mob in ipairs(enemies:GetChildren()) do
            local humanoid = mob:FindFirstChildOfClass("Humanoid")
            local part = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("UpperTorso")
            if humanoid and humanoid.Health > 0 and part then
                local dist = (part.Position - myHrp.Position).Magnitude
                if dist <= bestDist then bestDist, best = dist, mob end
            end
        end
    end
    return best
end

local function FindNearbyAttackTargets(character, _, radius)                        
    local origin, hits = character:GetPivot().Position, {}
    local function scan(folder)
        if not folder then return end
        for _, model in ipairs(folder:GetChildren()) do
            if model ~= character and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp and (origin - hrp.Position).Magnitude <= radius then table.insert(hits, { model, hrp }) end
            end
        end
    end
    scan(workspace:FindFirstChild("Enemies"))
    scan(workspace:FindFirstChild("Characters"))
    return hits
end

local function FindPlayerClosestToCrosshair()                                      
    local bestDist = math.huge
    local centre   = Vector2.new(GuiService:GetScreenResolution().X / 2, GuiService:GetScreenResolution().Y / 2)
    local best     = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                if char.Humanoid.Health > 0 then
                    local screen, onScreen = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
                    if onScreen then
                        local d = (centre - Vector2.new(screen.X, screen.Y)).Magnitude
                        if d < bestDist then best, bestDist = char.HumanoidRootPart, d end
                    end
                end
            end
        end
    end
    return best
end

local function PredictTargetPosition(part)
    return part.Position + part.Velocity * Setting.Data.PredictionAmount
end

local function RedirectClickTowardTarget(character, _, toolFolder, extraArg, targetState)   
    if not targetState[1] or not toolFolder:FindFirstChild("LeftClickRemote") then return end
    local targetPart = targetState[1][2]
    local direction  = (targetPart.Position - character:GetPivot().Position).Unit
    toolFolder.LeftClickRemote:FireServer(direction, extraArg)
end

-------------------------------------------------------------------------------
-- M1 / Fast Attack module                                        
-------------------------------------------------------------------------------
local M1Combo = setmetatable({ Debounce = 0, ComboDebounce = 0 }, {})
M1Combo.__index = M1Combo

local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")

function M1Combo:PerformAttack()
    if tick() - self.Debounce < 0.1 then return end
    self.Debounce = tick()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool or not char:FindFirstChild("Humanoid") then return end
    local isMelee = table.find({ "Melee", "Sword" }, tool.ToolTip) ~= nil
                    or tool:FindFirstChild("Melee") or tool:FindFirstChild("LeftClickRemote")
    if tool.ToolTip == "Blox Fruit" and not _G.UseFruitM1 then return end
    if not isMelee and tool.ToolTip ~= "Blox Fruit" then return end
    local hits = FindNearbyAttackTargets(char, nil, _G.FADistance or 8)
    RegisterAttack:FireServer(0)
    if #hits > 0 then
        RegisterHit:FireServer(hits[1][2], hits)
    end
end

local function UpdateFastAttack()                                          
    if _G.FastAttackEnabled then M1Combo:PerformAttack() end
end

-------------------------------------------------------------------------------
-- Feature loops 
-------------------------------------------------------------------------------
local function MaintainUnbreakableSkills()                                   
    while true do
        task.wait(0.1)
        if _G.UnbreakableSkills and LocalPlayer.Character then
            pcall(function() LocalPlayer.Character:SetAttribute("UnbreakableAll", true) end)
        end
    end
end

local function UpdateRaceAbilities()                                            
    while task.wait(0.5) do
        if _G.AutoRaceV3 then
            ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
            task.wait(30)
        end
        if _G.AutoRaceV4 then
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local main = playerGui:FindFirstChild("Main")
            local fill = main and main:FindFirstChild("RaceEnergy") and main.RaceEnergy:FindFirstChild("Fill")
            if fill and fill.Size.X.Scale >= 0.9 then
                local backpack  = LocalPlayer:WaitForChild("Backpack")
                local char      = LocalPlayer.Character
                local awakening = backpack:FindFirstChild("Awakening") or (char and char:FindFirstChild("Awakening"))
                if awakening then
                    local rf = awakening:FindFirstChild("RemoteFunction")
                    if rf then rf:InvokeServer(true); task.wait(5) end
                end
            end
        end
    end
end

local function UpdateWaterWalk()                                         
    while task.wait(0.1) do
        local water = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")
        if water then
            water.Size = _G.WalkOnWater and Vector3.new(1000, 112, 1000) or Vector3.new(1000, 10, 1000)
        end
    end
end

local function MaintainInfiniteEnergy()                                      
    while true do
        local char   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local energy = char:WaitForChild("Energy", 10)
        if energy then
            local conn = energy.Changed:Connect(function()
                if _G.InfiniteEnergy and energy.Value < energy.MaxValue then
                    energy.Value = energy.MaxValue
                end
            end)
            LocalPlayer.CharacterAdded:Wait()
            conn:Disconnect()
        else
            task.wait(1)
        end
    end
end

local function UpdatePlayerESP()                                           
    if _G.PlayerEsp then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                local gui = plr.Character:FindFirstChild("SurumESP") or Instance.new("BillboardGui", plr.Character)
                gui.Name, gui.Size, gui.StudsOffset = "SurumESP", UDim2.new(0, 200, 0, 70), Vector3.new(0, 2, 0)
                gui.AlwaysOnTop, gui.Adornee, gui.Enabled = true, plr.Character.Head, true
                local label = gui:FindFirstChild("Label") or Instance.new("TextLabel", gui)
                label.Name, label.BackgroundTransparency, label.Size = "Label", 1, UDim2.new(1, 0, 1, 0)
                label.Font, label.RichText, label.TextSize = Enum.Font.Jura, true, 15
                label.TextStrokeTransparency, label.TextStrokeColor3 = 0.4, Color3.fromRGB(3, 16, 40)
                local distance = math.floor((plr.Character.Head.Position - Camera.CFrame.Position).Magnitude)
                local health   = math.floor(plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health or 0)
                local pvpOff   = plr:GetAttribute("PvpDisabled") or false
                local pvpTag   = pvpOff and '<font color="#FF0000">[PvP OFF]</font>' or '<font color="#00FF00">[PvP ON]</font>'
                label.TextColor3 = (plr.Team and plr.Team.Name == "Marines") and Color3.fromRGB(0, 35, 100) or Color3.fromRGB(100, 0, 0)
                label.Text = string.format("<b>%s</b> [Lvl %s] %s\n%d HP | %d M", plr.Name, tostring(GetPlayerLevel(plr)), pvpTag, health, distance)
            end
        end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            local gui = plr.Character and plr.Character:FindFirstChild("SurumESP")
            if gui then gui.Enabled = false end
        end
    end
end

local SpeedBoxValue, DashBoxValue = Setting.Data.SpeedValue, Setting.Data.DashValue
local function UpdateMovementFeatures()                                            
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp      = char:FindFirstChild("HumanoidRootPart")
    if SpeedEnabled and humanoid then
        humanoid.WalkSpeed = SpeedBoxValue or Setting.Data.SpeedValue or 16
    end
    if DashEnabled then
        char:SetAttribute("DashLength", DashBoxValue or Setting.Data.DashValue or 300)
    end
    if _G.AntiStun and hrp and humanoid and humanoid.MoveDirection.Magnitude > 0 then
        local busy = false
        if humanoid.WalkSpeed == 0 then
            busy = true
        else
            for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
                if track.IsPlaying and (track.Animation.AnimationId:find("attack") or track.Animation.AnimationId:find("skill")) then
                    busy = true
                    break
                end
            end
        end
        if not busy then hrp.CFrame = hrp.CFrame + humanoid.MoveDirection.Unit * 1.7 end
    end
end

local function UpdateNearestNPCTarget()                                           
    while task.wait(0.1) do
        if AimbotNPC then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then NPCTarget = FindNearestNPC(hrp) end
        else
            NPCTarget = nil
        end
    end
end

local function UpdateNearestPlayerTarget()                                        
    while task.wait(0.1) do
        if AimbotPlayer then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then PlayerTarget = FindNearestValidPlayer(hrp) end
        else
            PlayerTarget = nil
        end
    end
end

local function UpdateNPCAimPoint()                                              
    if not AimbotNPC or not NPCTarget or not NPCTarget.Parent then
        NPCAimPoint, NPCLine.Visible = nil, false
        return
    end
    local char  = LocalPlayer.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    local part  = NPCTarget:FindFirstChild("HumanoidRootPart") or NPCTarget:FindFirstChild("UpperTorso")
    if not myHrp or not part or (part.Position - myHrp.Position).Magnitude > Setting.MaxDistance then
        NPCAimPoint, NPCLine.Visible = nil, false
        return
    end
    NPCAimPoint = PredictTargetPosition(part)
    if NPCTracers and NPCAimPoint then
        local from, a = Camera:WorldToViewportPoint(myHrp.Position)
        local to,   b = Camera:WorldToViewportPoint(NPCAimPoint)
        if a and b then
            NPCLine.From, NPCLine.To, NPCLine.Visible = Vector2.new(from.X, from.Y), Vector2.new(to.X, to.Y), true
        else
            NPCLine.Visible = false
        end
    else
        NPCLine.Visible = false
    end
end

local function UpdatePlayerAimPoint()                                           
    if not AimbotPlayer or not PlayerTarget then
        PlayerAimPoint, PlayerLine.Visible = nil, false
        return
    end
    local char  = LocalPlayer.Character
    local myHrp = char and char:FindFirstChild("HumanoidRootPart")
    local tChar = PlayerTarget.Character
    local tHrp  = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if not myHrp or not tHrp or (tHrp.Position - myHrp.Position).Magnitude > Setting.MaxDistance then
        PlayerAimPoint, PlayerLine.Visible = nil, false
        return
    end
    PlayerAimPoint = PredictTargetPosition(tHrp)
    if PlayerTracers and PlayerAimPoint then
        local from, a = Camera:WorldToViewportPoint(myHrp.Position)
        local to,   b = Camera:WorldToViewportPoint(PlayerAimPoint)
        if a and b then
            PlayerLine.From, PlayerLine.To, PlayerLine.Visible = Vector2.new(from.X, from.Y), Vector2.new(to.X, to.Y), true
        else
            PlayerLine.Visible = false
        end
    else
        PlayerLine.Visible = false
    end
end

local function GetCurrentAimPoint()
    return PlayerAimPoint or NPCAimPoint
end

-------------------------------------------------------------------------------
-- Aimbot Skills hook  
-------------------------------------------------------------------------------
do
    local CombatUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatUtil"))
    local original
    original = hookfunction(CombatUtil.GetTargetPosition, function(a, b, hitArg, d, ...)    
        if (AimbotPlayer or AimbotNPC) and GetCurrentAimPoint() then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local isMelee = tool and (tool:FindFirstChild("Melee") or tool.ToolTip == "Melee")
            if not isMelee then hitArg = GetCurrentAimPoint() end
        end
        return original(a, b, hitArg, d, ...)
    end)
end

-------------------------------------------------------------------------------
-- Mouse Hit/Target redirection                                   
-------------------------------------------------------------------------------
do
    local mt = getrawmetatable(Mouse)
    setreadonly(mt, false)
    local realIndex, realNewIndex = rawget(mt, "__index"), rawget(mt, "__newindex")
    local proxy = setmetatable({}, {
        __index = function(_, key)                                       
            if key == "Hit" then
                if (AimbotPlayer or AimbotNPC) and GetCurrentAimPoint() then return CFrame.new(GetCurrentAimPoint()) end
                return MouseShadow.Hit or Mouse.Hit
            elseif key == "Target" then
                if (AimbotPlayer or AimbotNPC) and GetCurrentAimPoint() then return GetCurrentAimPoint() end
                return MouseShadow.Target or Mouse.Target
            end
        end,
        __newindex = function(t, key, value)                             
            if key == "Hit" or key == "Target" then
                MouseShadow[key] = value
            else
                rawset(t, key, value)
            end
        end,
    })
    rawset(mt, "__index", function(self, key)
        if self == Mouse and (key == "Hit" or key == "Target") then return proxy[key] end
        return realIndex(self, key)
    end)
    rawset(mt, "__newindex", function(self, key, value)
        if self == Mouse and (key == "Hit" or key == "Target") then proxy[key] = value return end
        return realNewIndex(self, key, value)
    end)
    setreadonly(mt, true)
end

do
    local gmt = getrawmetatable(game)
    setreadonly(gmt, false)
    local oldNamecall = gmt.__namecall
    gmt.__namecall = newcclosure(function(self, ...)
        local args = { ... }
        if getnamecallmethod() == "FireServer" and self.Name == "LeftClickRemote" and (AimbotPlayer or AimbotNPC) then
            local point = GetCurrentAimPoint()
            local char  = LocalPlayer.Character
            if point and char then
                args[1] = (point - char:GetPivot().Position).Unit
                return oldNamecall(self, unpack(args))
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(gmt, true)
end

-------------------------------------------------------------------------------
-- Wind UI Implementation Initialization
-------------------------------------------------------------------------------
local WindUI = loadstring(game:HttpGet("https://treehub.netlify.app/script/windui.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Xen Hub",
    Icon = "rbxassetid://103239668295637",
    Author = "Xen Hub",
    Folder = "XenHubConfigs",
    Size = UDim2.fromOffset(540, 440),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 140,
    HasOutline = true,
})

-- Tabs Setup
local HomeTab = Window:Tab({ Title = "Home", Icon = "home" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "sword" })
local PlayerTab = Window:Tab({ Title = "Player", Icon = "user" })
local VisualsTab = Window:Tab({ Title = "Visuals", Icon = "eye" })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "layout-grid" })

-------------------------------------------------------------------------------
-- Home Tab Content
-------------------------------------------------------------------------------
HomeTab:Section({ Title = "Information" })
HomeTab:Paragraph({
    Title = "Xen Hub",
    Desc = "Compact control panel • UI preview loaded with Wind UI.",
})
HomeTab:Paragraph({
    Title = "Status",
    Desc = "Interface loaded successfully.",
})

-------------------------------------------------------------------------------
-- Combat Tab Content
-------------------------------------------------------------------------------
CombatTab:Section({ Title = "Aimbot & Targeting" })

CombatTab:Toggle({
    Title = "Aimbot NPC",
    Default = AimbotNPC,
    Callback = function(v)
        AimbotNPC = v
        Setting.Data.AimbotSkillsNPC = AimbotNPC
        NPCLine.Visible = false
        SaveSettings()
    end
})

CombatTab:Toggle({
    Title = "Aimbot Player",
    Default = AimbotPlayer,
    Callback = function(v)
        AimbotPlayer = v
        Setting.Data.AimbotSkillsPlayer = AimbotPlayer
        PlayerLine.Visible = false
        SaveSettings()
    end
})

CombatTab:Toggle({
    Title = "NPC Tracers",
    Default = NPCTracers,
    Callback = function(v)
        NPCTracers = v
        Setting.Data.NPCTracers = v
        NPCLine.Visible = false
        SaveSettings()
    end
})

CombatTab:Toggle({
    Title = "Player Tracers",
    Default = PlayerTracers,
    Callback = function(v)
        PlayerTracers = v
        Setting.Data.PlayerTracers = v
        PlayerLine.Visible = false
        SaveSettings()
    end
})

CombatTab:Section({ Title = "Combat & Macros" })

CombatTab:Button({
    Title = "Auto Combo Macro",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/JustParadozCode/Surum V1-Hub/refs/heads/main/Auto%20Combo%20V3.xyz"))()
    end
})

CombatTab:Toggle({
    Title = "Fast Attack",
    Default = _G.FastAttackEnabled,
    Callback = function(v)
        _G.FastAttackEnabled = v
        Setting.Data.FastAttack = v
        SaveSettings()
    end
})

CombatTab:Input({
    Title = "Attack Distance",
    Default = tostring(Setting.Data.FADistance),
    Callback = function(text)
        local n = tonumber(text)
        if n then
            _G.FADistance, Setting.Data.FADistance = n, n
            SaveSettings()
        end
    end
})

CombatTab:Toggle({
    Title = "Anti Stun",
    Default = _G.AntiStun,
    Callback = function(v)
        _G.AntiStun = v
        Setting.Data.AntiStun = v
        SaveSettings()
    end
})

CombatTab:Toggle({
    Title = "Unbreakable Skills",
    Default = _G.UnbreakableSkills,
    Callback = function(v)
        _G.UnbreakableSkills = v
        Setting.Data.UnbreakableSkills = v
        SaveSettings()
    end
})

CombatTab:Button({
    Title = "Soru Flash Step (Nearest Player)",
    Callback = function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if playerGui:FindFirstChild("SoruFloatingBtn") then
            playerGui.SoruFloatingBtn:Destroy()
            return
        end
        local Util   = require(ReplicatedStorage:WaitForChild("Util"))
        local Effect = Util.Effect
        local Anims  = Util.Anims

        local btn = Instance.new("TextButton", playerGui)
        btn.Name, btn.Size, btn.Position = "SoruFloatingBtn", UDim2.new(0, 110, 0, 35), UDim2.new(0.5, -55, 0.8, 0)
        btn.Text, btn.Font, btn.TextSize, btn.Active = "SORU FLASH STEP", Enum.Font.Jura, 11, true
        btn.TextColor3, btn.BackgroundColor3, btn.BackgroundTransparency = Color3.fromRGB(0, 170, 255), Color3.fromRGB(3, 16, 40), 0.4

        local dragging, dragStart, startPos = false, nil, nil
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging, dragStart, startPos = true, input.Position, btn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then dragging = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        local lastSoru = 0
        btn.MouseButton1Click:Connect(function()
            if tick() - lastSoru < 0.5 then return end
            lastSoru = tick()
            local char  = LocalPlayer.Character
            local myHrp = char and char:FindFirstChild("HumanoidRootPart")
            if not myHrp then return end

            local nearest, bestDist = nil, 250
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (plr.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                    if d < bestDist then bestDist, nearest = d, plr end
                end
            end
            if not nearest then
                btn.Text, btn.TextColor3 = "NO TARGET", Color3.fromRGB(255, 0, 0)
                task.delay(1, function()
                    btn.Text, btn.TextColor3 = "SORU FLASH STEP", Color3.fromRGB(0, 170, 255)
                end)
                return
            end

            local targetHrp = nearest.Character.HumanoidRootPart
            pcall(function() Anims:Get("FlashStepRegular"):Play() end)
            pcall(function() Effect.play("Shared.Soru", { player = LocalPlayer, Mode = 1 }) end)
            ReplicatedStorage.Remotes.CommE:FireServer("Soru", { Mode = 1 }, workspace:GetServerTimeNow() + 900000000)

            local dest = targetHrp.CFrame * CFrame.new(math.random(-3, 3), 2, 5)
            char:PivotTo(CFrame.new(dest.Position, targetHrp.Position))
            char.HumanoidRootPart.CFrame = CFrame.new(dest.Position, targetHrp.Position + targetHrp.CFrame.LookVector * 7)

            btn.Text, btn.TextColor3 = "GO!", Color3.fromRGB(0, 255, 150)
            task.delay(0.5, function()
                btn.Text, btn.TextColor3 = "SORU FLASH STEP", Color3.fromRGB(0, 170, 255)
            end)
        end)
    end
})

CombatTab:Button({
    Title = "Camlock (Nearest Crosshair Target)",
    Callback = function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if playerGui:FindFirstChild("CamLockUI") then return end
        local ui = Instance.new("TextButton", playerGui)
        ui.Name, ui.Size, ui.Position = "CamLockUI", UDim2.new(0, 200, 0, 50), UDim2.new(0.5, -100, 0.2, 0)
        ui.Text, ui.Font, ui.TextSize = "CAMLOCK: OFF", Enum.Font.Jura, 18
        ui.TextColor3, ui.BackgroundColor3, ui.Active, ui.Draggable = Color3.fromRGB(255, 255, 255), Color3.fromRGB(3, 16, 40), true, true
        Instance.new("UICorner", ui).CornerRadius = UDim.new(0, 8)
        local border = Instance.new("UIStroke", ui)
        border.Name, border.Thickness, border.ApplyStrokeMode = "Border", 1, Enum.ApplyStrokeMode.Border
        border.Color = Color3.fromRGB(0, 255, 255)

        local function DisableCameraLock()
            CamlockEnabled, Setting.Data.CamlockEnabled = false, false
            if CamlockConn then CamlockConn:Disconnect(); CamlockConn = nil end
            ui.Text, ui.TextColor3 = "CAMLOCK: OFF", Color3.fromRGB(255, 255, 255)
        end

        local function UpdateCameraLock()
            if CamlockEnabled and CamlockTarget and CamlockTarget.Parent then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position,
                    CamlockTarget.Position + (CamlockTarget.Velocity * Setting.Data.PredictionAmount))
            else
                if CamlockConn then CamlockConn:Disconnect() end
                CamlockEnabled, Setting.Data.CamlockEnabled = false, false
                DisableCameraLock()
                ui.Text, ui.TextColor3 = "CAMLOCK: OFF", Color3.fromRGB(255, 255, 255)
            end
        end

        ui.MouseButton1Click:Connect(function()
            if CamlockEnabled then
                DisableCameraLock()
                return
            end
            CamlockTarget = FindPlayerClosestToCrosshair()
            if not CamlockTarget then return end
            CamlockEnabled, Setting.Data.CamlockEnabled = true, true
            ui.Text, ui.TextColor3 = "CAMLOCK: ON", Color3.fromRGB(0, 255, 0)
            if CamlockConn then CamlockConn:Disconnect() end
            CamlockConn = RunService.RenderStepped:Connect(UpdateCameraLock)
        end)
    end
})

-------------------------------------------------------------------------------
-- Player Tab Content
-------------------------------------------------------------------------------
PlayerTab:Section({ Title = "Character Upgrades" })

PlayerTab:Toggle({
    Title = "Auto Race V3",
    Default = _G.AutoRaceV3,
    Callback = function(v)
        _G.AutoRaceV3 = v
        Setting.Data.AutoRaceV3 = v
        SaveSettings()
    end
})

PlayerTab:Toggle({
    Title = "Auto Race V4",
    Default = _G.AutoRaceV4,
    Callback = function(v)
        _G.AutoRaceV4 = v
        Setting.Data.AutoRaceV4 = v
        SaveSettings()
    end
})

PlayerTab:Toggle({
    Title = "Water Walk",
    Default = _G.WalkOnWater,
    Callback = function(v)
        _G.WalkOnWater = v
        Setting.Data.WalkOnWater = v
        SaveSettings()
    end
})

PlayerTab:Toggle({
    Title = "Infinite Energy",
    Default = _G.InfiniteEnergy,
    Callback = function(v)
        _G.InfiniteEnergy = v
        Setting.Data.InfiniteEnergy = v
        SaveSettings()
    end
})

PlayerTab:Button({
    Title = "Jump Boost",
    Callback = function()
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if playerGui:FindFirstChild("JumpBtn") then return end
        local jump = Instance.new("TextButton", playerGui)
        jump.Name, jump.Size, jump.Position = "JumpBtn", UDim2.new(0, 100, 0, 35), UDim2.new(0.5, -50, 0.7, 0)
        jump.Text, jump.Font, jump.TextColor3 = "JUMP", Enum.Font.Jura, Color3.new(1, 1, 1)
        jump.BackgroundColor3, jump.Active, jump.Draggable = Color3.new(0, 0, 0), true, true
        local conn
        jump.MouseButton1Down:Connect(function()
            jump.Text = "GO!"
            conn = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.UseJumpPower, hum.JumpPower = true, 100
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
            task.delay(0.5, function()
                if conn then conn:Disconnect(); conn = nil end
                local char = LocalPlayer.Character
                local hum  = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = 50 end
                jump.Text = "JUMP"
            end)
        end)
        jump.MouseButton1Up:Connect(function()
            if conn then conn:Disconnect(); conn = nil end
        end)
    end
})

PlayerTab:Section({ Title = "Movement Modifications" })

PlayerTab:Toggle({
    Title = "Speed Enable",
    Default = SpeedEnabled,
    Callback = function(v)
        SpeedEnabled = v
        Setting.Data.SpeedEnabled = v
        SaveSettings()
    end
})

PlayerTab:Input({
    Title = "WalkSpeed Value",
    Default = tostring(Setting.Data.SpeedValue),
    Callback = function(text)
        local n = tonumber(text)
        if n then
            SpeedBoxValue = n
            Setting.Data.SpeedValue = n
            SaveSettings()
        end
    end
})

PlayerTab:Toggle({
    Title = "Dash Enable",
    Default = DashEnabled,
    Callback = function(v)
        DashEnabled = v
        Setting.Data.DashEnabled = v
        SaveSettings()
    end
})

PlayerTab:Input({
    Title = "Dash Length Value",
    Default = tostring(Setting.Data.DashValue),
    Callback = function(text)
        local n = tonumber(text)
        if n then
            DashBoxValue = n
            Setting.Data.DashValue = n
            SaveSettings()
        end
    end
})

-------------------------------------------------------------------------------
-- Visuals Tab Content
-------------------------------------------------------------------------------
VisualsTab:Section({ Title = "ESP & Render" })

VisualsTab:Toggle({
    Title = "Player ESP",
    Default = _G.PlayerEsp,
    Callback = function(v)
        _G.PlayerEsp = v
        Setting.Data.PlayerEsp = v
        SaveSettings()
    end
})

-------------------------------------------------------------------------------
-- Character hooks & Loop Starters
-------------------------------------------------------------------------------
local function HandleCharacterAdded(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child:FindFirstChild("LeftClickRemote") then
        end
    end)
    char.ChildRemoved:Connect(function() end)
end
if LocalPlayer.Character then HandleCharacterAdded(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(HandleCharacterAdded)

task.spawn(MaintainUnbreakableSkills)
task.spawn(UpdateRaceAbilities)
task.spawn(UpdateWaterWalk)
task.spawn(MaintainInfiniteEnergy)
task.spawn(UpdateNearestNPCTarget)
task.spawn(UpdateNearestPlayerTarget)

RunService.RenderStepped:Connect(function()
    pcall(UpdateMovementFeatures)
    pcall(UpdateNPCAimPoint)
    pcall(UpdatePlayerAimPoint)
end)
RunService.Heartbeat:Connect(function()
    pcall(UpdateFastAttack)
end)
task.spawn(function()
    while task.wait(0.3) do pcall(UpdatePlayerESP) end
end)

Window:SelectTab(1)
print("Xen Hub Fully Loaded with Wind UI!")
