--[==[
    Surum V1  —  reconstructed original (Luraph v14.8 target, "Surum_V1")

    SOURCES
      * 22 closures recovered verbatim from the protected file (c z w v e D H E r b R G J i x L F _ U h Z k)
      * constant pool of the virtualized body (78 protos: strings / numbers / booleans / closure tree)
        — proto numbers are noted as  --[[P<n>]]  next to the function they correspond to.
    LIMITS
      The pool has no instructions, so statement ORDER inside a proto and the exact arguments of a
      few calls (Soru remote payload, some colours) are inferred from the constants and from how the
      recovered closures are called. Every string/number used below exists in the pool; nothing was
      added that the pool does not contain, except glue syntax.
]==]

-------------------------------------------------------------------------------
-- Services / globals                                                  --[[P0]]
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
-- Settings / config file                                       --[[P16 P17 P18]]
-------------------------------------------------------------------------------
getgenv().Setting = getgenv().Setting or {}
local Setting = getgenv().Setting
Setting.FileName    = "Surum-V1-67.json"
Setting.MaxDistance = 350

local function DefaultData()                                            --[[P16]]
    return {
        CamlockEnabled   = false, WalkOnWater   = false, AutoRaceV3 = false, AutoRaceV4 = false,
        SpeedEnabled     = false, DashEnabled   = false, SpeedValue = 16,    DashValue  = 300,
        FADistance       = 8,     AimbotSkills  = false, FastAttack = false, InfiniteEnergy = false,
        UnbreakableSkills = false, AntiStun     = false, PlayerEsp  = false,
        PlayerTracers    = true,  NPCTracers    = true,  PredictionAmount = 0.163186,
        AimbotSkillsNPC  = false, AimbotSkillsPlayer = false,
    }
end
Setting.Data = DefaultData()

local function SaveConfig()                                             --[[P17/P62]]
    pcall(function()
        writefile(Setting.FileName, HttpService:JSONEncode(Setting.Data))
    end)
end

local function LoadConfig()                                             --[[P18/P63]]
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

if LoadConfig() then
    StarterGui:SetCore("SendNotification", {
        Title = "Surum V1", Text = "Config Loaded Successfully!", Duration = 3,
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
-- State shared by the recovered closures (Luraph upvalue cells)
-------------------------------------------------------------------------------
local SpeedEnabled, DashEnabled = Setting.Data.SpeedEnabled, Setting.Data.DashEnabled
local AimbotNPC,  AimbotPlayer  = Setting.Data.AimbotSkillsNPC, Setting.Data.AimbotSkillsPlayer
local NPCTracers, PlayerTracers = Setting.Data.NPCTracers, Setting.Data.PlayerTracers
local CamlockEnabled, CamlockConn, CamlockTarget = false, nil, nil
local NPCTarget, PlayerTarget, NPCAimPoint, PlayerAimPoint = nil, nil, nil, nil
local MouseShadow = { Hit = nil, Target = nil }

local NPCLine    = Drawing.new("Line")                                   -- "Line" x2
NPCLine.Thickness, NPCLine.Color, NPCLine.Transparency, NPCLine.Visible = 1.5, Color3.fromRGB(255, 0, 0), 1, false
local PlayerLine = Drawing.new("Line")
PlayerLine.Thickness, PlayerLine.Color, PlayerLine.Transparency, PlayerLine.Visible = 1.5, Color3.fromRGB(0, 189, 246), 1, false

-------------------------------------------------------------------------------
-- Recovered helpers  (bodies are 1:1 with the protected file)
-------------------------------------------------------------------------------
local function GetLevel(player)                                          -- F
    local data = player:FindFirstChild("Data")
    if data and data:FindFirstChild("Level") then return data.Level.Value end
    return "???"
end

local function IsAlly(player)                                            -- w
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    local list = playerGui:FindFirstChild("Main") and playerGui.Main:FindFirstChild("Allies")
                 and playerGui.Main.Allies.Container.Allies:FindFirstChild("ScrollingFrame")
    return list and list:FindFirstChild(player.Name) ~= nil
end

local function InSafeZone(position)                                      -- G
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

local function FindClosestPlayer(myHrp)                                  -- J
    if not myHrp then return nil end
    local best, bestDist = nil, Setting.MaxDistance
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
           and plr.Character:FindFirstChild("Humanoid") then
            if plr.Character.Humanoid.Health > 0 then
                local hrp = plr.Character.HumanoidRootPart
                if InSafeZone(hrp.Position) then continue end
                if plr:GetAttribute("PvpDisabled") or false then continue end
                if LocalPlayer.Team and plr.Team then
                    if LocalPlayer.Team.Name == "Marines" and plr.Team.Name == "Marines" then continue end
                end
                if IsAlly(plr) then continue end
                local dist = (myHrp.Position - hrp.Position).Magnitude
                if dist < bestDist then bestDist, best = dist, plr end
            end
        end
    end
    return best
end

local function FindClosestNPC(myHrp)                                     -- i
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

local function GetBladeHits(character, _, radius)                        -- D
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

local function ClosestToCrosshair()                                      -- _
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

-- aim-point predictor (velocity * Setting.Data.PredictionAmount)      -- wrapper 21
local function PredictPosition(part)
    return part.Position + part.Velocity * Setting.Data.PredictionAmount
end

local function SilentAimClick(character, _, toolFolder, extraArg, targetState)   -- H
    if not targetState[1] or not toolFolder:FindFirstChild("LeftClickRemote") then return end
    local targetPart = targetState[1][2]
    local direction  = (targetPart.Position - character:GetPivot().Position).Unit
    toolFolder.LeftClickRemote:FireServer(direction, extraArg)
end

-------------------------------------------------------------------------------
-- M1 / Fast Attack module                                        --[[P28 + wrapper 39]]
-------------------------------------------------------------------------------
local M1Combo = setmetatable({ Debounce = 0, ComboDebounce = 0 }, {})
M1Combo.__index = M1Combo

local Net = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RegisterAttack = Net:WaitForChild("RE/RegisterAttack")
local RegisterHit    = Net:WaitForChild("RE/RegisterHit")

function M1Combo:Attack()
    if tick() - self.Debounce < 0.1 then return end
    self.Debounce = tick()
    local char = LocalPlayer.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if not tool or not char:FindFirstChild("Humanoid") then return end
    local isMelee = table.find({ "Melee", "Sword" }, tool.ToolTip) ~= nil
                    or tool:FindFirstChild("Melee") or tool:FindFirstChild("LeftClickRemote")
    if tool.ToolTip == "Blox Fruit" and not _G.UseFruitM1 then return end
    if not isMelee and tool.ToolTip ~= "Blox Fruit" then return end
    local hits = GetBladeHits(char, nil, _G.FADistance or 8)
    RegisterAttack:FireServer(0)
    if #hits > 0 then
        RegisterHit:FireServer(hits[1][2], hits)
    end
end

local function FastAttackTick()                                          -- E
    if _G.FastAttackEnabled then M1Combo:Attack() end
end

-------------------------------------------------------------------------------
-- Feature loops (recovered)
-------------------------------------------------------------------------------
local function UnbreakableSkillsLoop()                                   -- r
    while true do
        task.wait(0.1)
        if _G.UnbreakableSkills and LocalPlayer.Character then
            pcall(function() LocalPlayer.Character:SetAttribute("UnbreakableAll", true) end)
        end
    end
end

local function AutoRaceLoop()                                            -- c
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

local function WalkOnWaterLoop()                                         -- L
    while task.wait(0.1) do
        local water = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WaterBase-Plane")
        if water then
            water.Size = _G.WalkOnWater and Vector3.new(1000, 112, 1000) or Vector3.new(1000, 10, 1000)
        end
    end
end

local function InfiniteEnergyLoop()                                      --[[P11/P59]]
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

local function PlayerEspTick()                                           -- b
    if _G.PlayerEsp then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                local gui = plr.Character:FindFirstChild("SurumESP") or Instance.new("BillboardGui", plr.Character)
                gui.Name, gui.Size, gui.StudsOffset = "SurumESP", UDim2.new(0, 200, 0, 70), Vector3.new(0, 2, 0)
                gui.AlwaysOnTop, gui.Adornee, gui.Enabled = true, plr.Character.Head, true
                local label = gui:FindFirstChild("Label") or Instance.new("TextLabel", gui)
                label.Name, label.BackgroundTransparency, label.Size = "Label", 1, UDim2.new(1, 0, 1, 0)
                label.Font, label.RichText, label.TextSize = Enum.Font.Jura, true, 15
                label.TextStrokeTransparency, label.TextStrokeColor3 = 0.4, Color3.fromRGB(0, 0, 0)
                local distance = math.floor((plr.Character.Head.Position - Camera.CFrame.Position).Magnitude)
                local health   = math.floor(plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health or 0)
                local pvpOff   = plr:GetAttribute("PvpDisabled") or false
                local pvpTag   = pvpOff and '<font color="#FF0000">[PvP OFF]</font>' or '<font color="#00FF00">[PvP ON]</font>'
                label.TextColor3 = (plr.Team and plr.Team.Name == "Marines") and Color3.fromRGB(0, 35, 100) or Color3.fromRGB(100, 0, 0)
                label.Text = string.format("<b>%s</b> [Lvl %s] %s\n%d HP | %d M", plr.Name, tostring(GetLevel(plr)), pvpTag, health, distance)
            end
        end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            local gui = plr.Character and plr.Character:FindFirstChild("SurumESP")
            if gui then gui.Enabled = false end
        end
    end
end

local SpeedBox, DashBox                                                  -- created by the GUI
local function MovementTick()                                            -- x
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local hrp      = char:FindFirstChild("HumanoidRootPart")
    if SpeedEnabled and humanoid then
        humanoid.WalkSpeed = tonumber(SpeedBox.Text) or Setting.Data.SpeedValue or 16
    end
    if DashEnabled then
        char:SetAttribute("DashLength", tonumber(DashBox.Text) or Setting.Data.DashValue or 300)
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

local function NPCTargetLoop()                                           -- R
    while task.wait(0.1) do
        if AimbotNPC then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then NPCTarget = FindClosestNPC(hrp) end
        else
            NPCTarget = nil
        end
    end
end

local function PlayerTargetLoop()                                        -- Y
    while task.wait(0.1) do
        if AimbotPlayer then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then PlayerTarget = FindClosestPlayer(hrp) end
        else
            PlayerTarget = nil
        end
    end
end

local function NPCAimTick()                                              -- z
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
    NPCAimPoint = PredictPosition(part)
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

local function PlayerAimTick()                                           -- v
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
    PlayerAimPoint = PredictPosition(tHrp)
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

local function CurrentAimPoint()
    return PlayerAimPoint or NPCAimPoint
end

-------------------------------------------------------------------------------
-- Aimbot Skills hook  (CombatUtil.GetTargetPosition)           --[[P20/P64 + U]]
-------------------------------------------------------------------------------
do
    local CombatUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("CombatUtil"))
    local original
    original = hookfunction(CombatUtil.GetTargetPosition, function(a, b, hitArg, d, ...)    -- U
        if (AimbotPlayer or AimbotNPC) and CurrentAimPoint() then
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            local isMelee = tool and (tool:FindFirstChild("Melee") or tool.ToolTip == "Melee")
            if not isMelee then hitArg = CurrentAimPoint() end
        end
        return original(a, b, hitArg, d, ...)
    end)
end

-------------------------------------------------------------------------------
-- Mouse Hit/Target redirection                                   --[[P45/P69/P70 + h Z]]
-------------------------------------------------------------------------------
do
    local mt = getrawmetatable(Mouse)
    setreadonly(mt, false)
    local realIndex, realNewIndex = rawget(mt, "__index"), rawget(mt, "__newindex")
    local proxy = setmetatable({}, {
        __index = function(_, key)                                       -- h
            if key == "Hit" then
                if (AimbotPlayer or AimbotNPC) and CurrentAimPoint() then return CFrame.new(CurrentAimPoint()) end
                return MouseShadow.Hit or Mouse.Hit
            elseif key == "Target" then
                if (AimbotPlayer or AimbotNPC) and CurrentAimPoint() then return CurrentAimPoint() end
                return MouseShadow.Target or Mouse.Target
            end
        end,
        __newindex = function(t, key, value)                             -- Z
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

-- __namecall hook on game (M1 silent aim via LeftClickRemote)          --[[P0: getrawmetatable/__namecall/newcclosure]]
do
    local gmt = getrawmetatable(game)
    setreadonly(gmt, false)
    local oldNamecall = gmt.__namecall
    gmt.__namecall = newcclosure(function(self, ...)
        local args = { ... }
        if getnamecallmethod() == "FireServer" and self.Name == "LeftClickRemote" and (AimbotPlayer or AimbotNPC) then
            local point = CurrentAimPoint()
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
-- GUI                                                       --[[P0 P8 P9 P40 P46 P47]]
-------------------------------------------------------------------------------
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
-- Remove a previous Surum V1 UI instance when the script is re-executed.
local previousGui = PlayerGui:FindFirstChild("Surum_V1")
if previousGui then
    pcall(function() previousGui:Destroy() end)
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name, ScreenGui.ResetOnSpawn = "Surum_V1", false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame", ScreenGui)
Main.Name, Main.Size, Main.Position = "MENU", UDim2.new(0, 210, 0, 300), UDim2.new(0, 20, 0.3, 0)
Main.BackgroundColor3, Main.BackgroundTransparency, Main.BorderSizePixel = Color3.fromRGB(0, 0, 0), 0.2, 0
Main.Active, Main.Draggable = true, true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Background = Instance.new("ImageLabel", Main)
Background.Size, Background.BackgroundTransparency = UDim2.new(1, 0, 1, 0), 1
Background.Image, Background.ImageTransparency = "rbxassetid://103239668295637", 0.6
Instance.new("UICorner", Background).CornerRadius = UDim.new(0, 8)

local Gradient = Instance.new("UIGradient", Main)
Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 189, 246)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255)),
})

local Title = Instance.new("TextLabel", Main)
Title.Size, Title.BackgroundTransparency = UDim2.new(1, -34, 0, 30), 1
Title.Text, Title.Font, Title.TextSize, Title.TextColor3 = "👑 Surum V1 👑", Enum.Font.Jura, 18, Color3.fromRGB(255, 255, 255)

-- Small floating Open button shown while the main menu is minimized.
local OpenBtn = Instance.new("TextButton", ScreenGui)
OpenBtn.Name = "OpenSurumV1"
OpenBtn.Size = UDim2.new(0, 100, 0, 36)
OpenBtn.Position = Main.Position
OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
OpenBtn.BackgroundTransparency = 0.2
OpenBtn.BorderSizePixel = 0
OpenBtn.Text = "Open"
OpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenBtn.Font = Enum.Font.Jura
OpenBtn.TextSize = 16
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.Visible = false
Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 8)
local OpenGradient = Instance.new("UIGradient", OpenBtn)
OpenGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 189, 246)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 0, 255)),
})
local OpenStroke = Instance.new("UIStroke", OpenBtn)
OpenStroke.Thickness = 1
OpenStroke.Color = Color3.fromRGB(0, 189, 246)

-- Minimize/restore control: preserves function states and offers a small Open button.
local Scroll
local MinimizeBtn = Instance.new("TextButton", Main)
MinimizeBtn.Name = "MinimizeButton"
MinimizeBtn.Size = UDim2.new(0, 28, 0, 26)
MinimizeBtn.Position = UDim2.new(1, -32, 0, 2)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MinimizeBtn.BackgroundTransparency = 0.15
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Text = "−"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.Font = Enum.Font.Jura
MinimizeBtn.TextSize = 22
MinimizeBtn.ZIndex = 5
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)
local IsMinimized = false
local ExpandedSize = Main.Size
local function SetMinimized(minimized)
    IsMinimized = minimized
    Main.Visible = not minimized
    OpenBtn.Visible = minimized
end
MinimizeBtn.MouseButton1Click:Connect(function()
    SetMinimized(true)
end)
OpenBtn.MouseButton1Click:Connect(function()
    SetMinimized(false)
end)

Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size, Scroll.Position = UDim2.new(1, -10, 1, -37), UDim2.new(0, 5, 0, 32)
Scroll.BackgroundTransparency, Scroll.BorderSizePixel = 1, 0
Scroll.ScrollBarThickness, Scroll.ScrollBarImageColor3 = 4, Color3.fromRGB(0, 189, 246)

local List = Instance.new("UIListLayout", Scroll)
List.Padding, List.HorizontalAlignment, List.SortOrder = UDim.new(0, 5), Enum.HorizontalAlignment.Center, Enum.SortOrder.LayoutOrder
List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()                          --[[P40]]
    Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 5)
end)

local function Style(obj)                                                --[[P8]]
    local stroke = Instance.new("UIStroke", obj)
    stroke.Thickness, stroke.Transparency, stroke.Color = 1, 0, Color3.fromRGB(136, 65, 35)
    Instance.new("UICorner", obj).CornerRadius = UDim.new(0, 8)
end

local function ReadToggleState(text, fallback)
    -- Read the real state after the callback, so the tick reflects the feature
    -- instead of merely reflecting that the row was clicked.
    if text:find("Aimbot Skills %+ Gun M1") then
        return text:find("👾", 1, true) and AimbotNPC or AimbotPlayer
    elseif text == "Auto Race V3" then return _G.AutoRaceV3
    elseif text == "Auto Race V4" then return _G.AutoRaceV4
    elseif text == "Water Walk" then return _G.WalkOnWater
    elseif text == "Infinite Energy" then return _G.InfiniteEnergy
    elseif text == "Fast Attack" then return _G.FastAttackEnabled
    elseif text == "Anti Stun" then return _G.AntiStun
    elseif text == "Unbreakable Skills" then return _G.UnbreakableSkills
    elseif text == "ESP" then return _G.PlayerEsp
    elseif text == "Speed ON" or text == "Speed OFF" then return SpeedEnabled
    elseif text == "Dash ON" or text == "Dash OFF" then return DashEnabled
    elseif text == "Surum V1 Camlock" then return CamlockEnabled
    end
    return fallback
end

local order = 0
local function CreateButton(text, callback)                              --[[P9]]
    order += 1
    local btn = Instance.new("TextButton", Scroll)
    btn.Size, btn.LayoutOrder = UDim2.new(1, -5, 0, 44), order
    btn.BackgroundColor3, btn.BackgroundTransparency = Color3.fromRGB(29, 29, 29), 0.3
    btn.TextColor3, btn.Font, btn.TextSize, btn.Text = Color3.fromRGB(0, 189, 246), Enum.Font.Jura, 13, "  " .. text
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    Style(btn)

    -- Square status indicator at the right of each function row.
    local checkBox = Instance.new("Frame", btn)
    checkBox.Name = "FunctionCheckbox"
    checkBox.AnchorPoint = Vector2.new(1, 0.5)
    checkBox.Position = UDim2.new(1, -8, 0.5, 0)
    checkBox.Size = UDim2.new(0, 20, 0, 20)
    checkBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    checkBox.BorderSizePixel = 0
    checkBox.Active = false
    Instance.new("UICorner", checkBox).CornerRadius = UDim.new(0, 4)
    local outline = Instance.new("UIStroke", checkBox)
    outline.Color = Color3.fromRGB(0, 189, 246)
    outline.Thickness = 1.5
    local tick = Instance.new("TextLabel", checkBox)
    tick.Name = "Tick"
    tick.Size = UDim2.new(1, 0, 1, 0)
    tick.BackgroundTransparency = 1
    tick.Text = ""
    tick.TextColor3 = Color3.fromRGB(80, 255, 130)
    tick.Font = Enum.Font.Jura
    tick.TextSize = 18
    tick.Active = false

    local checked = false
    local function refreshCheck()
        tick.Text = checked and "✓" or ""
        outline.Color = checked and Color3.fromRGB(80, 255, 130) or Color3.fromRGB(0, 189, 246)
    end
    btn.MouseButton1Click:Connect(function()
        local ok = pcall(callback)
        local actual = ReadToggleState(text, nil)
        if actual ~= nil then
            checked = actual == true
        else
            -- Action-style rows still provide click feedback without changing
            -- the behavior of their original callback.
            checked = not checked
        end
        refreshCheck()
        if not ok then
            warn("[Surum V1] A function callback failed: " .. tostring(text))
        end
    end)
    checked = ReadToggleState(text, false) == true
    refreshCheck()
    return btn
end

local function CreateTextBox(labelText, default, onFocusLost)
    order += 1
    local frame = Instance.new("Frame", Scroll)
    frame.Size, frame.LayoutOrder, frame.BackgroundTransparency = UDim2.new(1, -5, 0, 32), order, 1
    local label = Instance.new("TextLabel", frame)
    label.Size, label.BackgroundTransparency, label.Text = UDim2.new(0.6, 0, 1, 0), 1, labelText
    label.Font, label.TextSize, label.TextColor3, label.TextXAlignment = Enum.Font.Jura, 13, Color3.fromRGB(255, 255, 255), Enum.TextXAlignment.Left
    local box = Instance.new("TextBox", frame)
    box.Size, box.Position, box.Text = UDim2.new(0.4, -4, 1, -6), UDim2.new(0.6, 0, 0, 3), tostring(default)
    box.Font, box.TextSize, box.TextColor3 = Enum.Font.Jura, 13, Color3.fromRGB(0, 189, 246)
    box.BackgroundColor3, box.BackgroundTransparency = Color3.fromRGB(29, 29, 29), 0.3
    Style(box)
    box.FocusLost:Connect(function() onFocusLost(box) end)
    return box, frame
end

-- ON/OFF toggle row (tracers)                                            --[[P46/P71]]
local function CreateToggle(text, initial, callback)
    order += 1
    local frame = Instance.new("Frame", Scroll)
    frame.Size, frame.LayoutOrder, frame.BackgroundColor3, frame.BackgroundTransparency = UDim2.new(1, -5, 0, 32), order, Color3.fromRGB(29, 29, 29), 0.3
    Style(frame)
    local label = Instance.new("TextButton", frame)
    label.Size, label.BackgroundTransparency, label.Text = UDim2.new(0.75, 0, 1, 0), 1, text
    label.Font, label.TextSize, label.TextColor3 = Enum.Font.Jura, 12, Color3.fromRGB(255, 255, 255)
    local state = Instance.new("TextButton", frame)
    state.Size, state.Position, state.BackgroundTransparency = UDim2.new(0.25, 0, 1, 0), UDim2.new(0.75, 0, 0, 0), 1
    state.Font, state.TextSize = Enum.Font.Jura, 12
    local value = initial
    local function refresh()
        state.Text = value and "ON" or "OFF"
        state.TextColor3 = value and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 55, 55)
    end
    local function flip() value = not value; refresh(); callback(value) end
    label.MouseButton1Click:Connect(flip)
    state.MouseButton1Click:Connect(flip)
    refresh()
end

local function Flash(btn, on)
    btn.TextColor3 = on and Color3.fromRGB(0, 255, 155) or Color3.fromRGB(0, 189, 246)
end

-------------------------------------------------------------------------------
-- Menu entries (one proto each)
-------------------------------------------------------------------------------
local AimbotNPCBtn = CreateButton("Aimbot Skills + Gun M1 👾", function()                         --[[P47 / wrapper 18]]
    AimbotNPC = not AimbotNPC
    Setting.Data.AimbotSkillsNPC = AimbotNPC
    NPCLine.Visible = false
    SaveConfig()
end)
local AimbotPlayerBtn = CreateButton("Aimbot Skills + Gun M1 👤", function()                      --[[wrapper 26]]
    AimbotPlayer = not AimbotPlayer
    Setting.Data.AimbotSkillsPlayer = AimbotPlayer
    PlayerLine.Visible = false
    SaveConfig()
end)
CreateToggle("NPC Tracers Off/On ✏️", NPCTracers, function(v)                                     --[[wrapper 19]]
    NPCTracers = v; Setting.Data.NPCTracers = v; NPCLine.Visible = false; SaveConfig()
end)
CreateToggle("Player Tracers Off/On ✏️", PlayerTracers, function(v)
    PlayerTracers = v; Setting.Data.PlayerTracers = v; PlayerLine.Visible = false; SaveConfig()
end)

CreateButton("Auto Combo/Macro", function()                                                       --[[P5]]
    loadstring(game:HttpGet("https://raw.githubusercontent.com/JustParadozCode/Surum V1-Hub/refs/heads/main/Auto%20Combo%20V3.xyz"))()
end)

local RaceV3Btn = CreateButton("Auto Race V3", function()                                         --[[P6]]
    _G.AutoRaceV3 = not _G.AutoRaceV3
    Setting.Data.AutoRaceV3 = _G.AutoRaceV3
    Flash(RaceV3Btn, _G.AutoRaceV3); SaveConfig()
end)
local RaceV4Btn = CreateButton("Auto Race V4", function()                                         --[[P41]]
    _G.AutoRaceV4 = not _G.AutoRaceV4
    Setting.Data.AutoRaceV4 = _G.AutoRaceV4
    Flash(RaceV4Btn, _G.AutoRaceV4); SaveConfig()
end)
local WaterBtn = CreateButton("Water Walk", function()                                            --[[P42]]
    _G.WalkOnWater = not _G.WalkOnWater
    Setting.Data.WalkOnWater = _G.WalkOnWater
    Flash(WaterBtn, _G.WalkOnWater); SaveConfig()
end)

CreateButton("Jump Boost", function()                                                             --[[P14/P60/P61/P74/P75]]
    if ScreenGui:FindFirstChild("JumpBtn") then return end
    local jump = Instance.new("TextButton", ScreenGui)
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
end)

local EnergyBtn = CreateButton("Infinite Energy", function()                                      --[[P25]]
    _G.InfiniteEnergy = not _G.InfiniteEnergy
    Setting.Data.InfiniteEnergy = _G.InfiniteEnergy
    Flash(EnergyBtn, _G.InfiniteEnergy); SaveConfig()
end)

local FastBtn = CreateButton("Fast Attack", function()                                            --[[P22]]
    _G.FastAttackEnabled = not _G.FastAttackEnabled
    Setting.Data.FastAttack = _G.FastAttackEnabled
    Flash(FastBtn, _G.FastAttackEnabled); SaveConfig()
end)
local FADistanceBox, FADistanceFrame = CreateTextBox("  Attack Distance:", Setting.Data.FADistance, function(box)   --[[P10]]
    local n = tonumber(box.Text)
    if n then
        _G.FADistance, Setting.Data.FADistance = n, n
        SaveConfig()
    else
        box.Text = tostring(_G.FADistance)
    end
end)
FADistanceFrame.Name = "FastAttackDistanceFrame"

local AntiStunBtn = CreateButton("Anti Stun", function()                                          --[[P48]]
    _G.AntiStun = not _G.AntiStun
    Setting.Data.AntiStun = _G.AntiStun
    Flash(AntiStunBtn, _G.AntiStun); SaveConfig()
end)
local UnbreakBtn = CreateButton("Unbreakable Skills", function()                                  --[[P50]]
    _G.UnbreakableSkills = not _G.UnbreakableSkills
    Setting.Data.UnbreakableSkills = _G.UnbreakableSkills
    Flash(UnbreakBtn, _G.UnbreakableSkills); SaveConfig()
end)
local EspBtn = CreateButton("ESP", function()                                                     --[[P15]]
    _G.PlayerEsp = not _G.PlayerEsp
    Setting.Data.PlayerEsp = _G.PlayerEsp
    Flash(EspBtn, _G.PlayerEsp); SaveConfig()
end)

local SpeedBtn = CreateButton(SpeedEnabled and "Speed ON" or "Speed OFF", function()              --[[P44]]
    SpeedEnabled = not SpeedEnabled
    Setting.Data.SpeedEnabled = SpeedEnabled
    SpeedBtn.Text = SpeedEnabled and "Speed ON" or "Speed OFF"
    SpeedBtn.TextColor3 = SpeedEnabled and Color3.new(0.3, 1, 0.3) or Color3.new(1, 0.6, 0.3)
    SaveConfig()
end)
SpeedBox = CreateTextBox("WalkSpeed", Setting.Data.SpeedValue, function(box)                     --[[P39]]
    local n = tonumber(box.Text)
    if n then Setting.Data.SpeedValue = n; SaveConfig() else box.Text = tostring(Setting.Data.SpeedValue or 16) end
end)
local DashBtn = CreateButton(DashEnabled and "Dash ON" or "Dash OFF", function()                  --[[P32]]
    DashEnabled = not DashEnabled
    Setting.Data.DashEnabled = DashEnabled
    DashBtn.Text = DashEnabled and "Dash ON" or "Dash OFF"
    DashBtn.TextColor3 = DashEnabled and Color3.new(0.3, 1, 0.3) or Color3.new(1, 0.6, 0.3)
    SaveConfig()
end)
DashBox = CreateTextBox("DashLength", Setting.Data.DashValue, function(box)                       --[[P12]]
    local n = tonumber(box.Text)
    if n then Setting.Data.DashValue = n; SaveConfig() else box.Text = tostring(Setting.Data.DashValue) end
end)

-------------------------------------------------------------------------------
-- Flashstep (Soru) Aimbot Nearest                       --[[P34 P65 P66 P67 P68 P76 P77 + wrapper 47]]
-------------------------------------------------------------------------------
CreateButton("Flashstep Aimbot Nearest", function()
    if ScreenGui:FindFirstChild("SoruFloatingBtn") then
        ScreenGui.SoruFloatingBtn:Destroy()
        return
    end
    local Util   = require(ReplicatedStorage:WaitForChild("Util"))
    local Effect = Util.Effect
    local Anims  = Util.Anims

    local btn = Instance.new("TextButton", ScreenGui)
    btn.Name, btn.Size, btn.Position = "SoruFloatingBtn", UDim2.new(0, 110, 0, 35), UDim2.new(0.5, -55, 0.8, 0)
    btn.Text, btn.Font, btn.TextSize, btn.Active = "SORU NEAREST", Enum.Font.Jura, 11, true
    btn.TextColor3, btn.BackgroundColor3, btn.BackgroundTransparency = Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 0, 0), 0.4

    -- manual drag (touch + mouse)                                        --[[P67/P68]]
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
    btn.MouseButton1Click:Connect(function()                               --[[P66]]
        if tick() - lastSoru < 0.5 then return end
        lastSoru = tick()
        local char  = LocalPlayer.Character
        local myHrp = char and char:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end

        -- nearest player within 250 studs
        local nearest, bestDist = nil, 250
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local d = (plr.Character.HumanoidRootPart.Position - myHrp.Position).Magnitude
                if d < bestDist then bestDist, nearest = d, plr end
            end
        end
        if not nearest then
            btn.Text, btn.TextColor3 = "NO TARGET", Color3.fromRGB(255, 0, 0)
            task.delay(1, function()                                       --[[P76]]
                btn.Text, btn.TextColor3 = "SORU NEAREST", Color3.fromRGB(0, 170, 255)
            end)
            return
        end

        -- Soru effect + server notification, then flash-step behind the target
        local targetHrp = nearest.Character.HumanoidRootPart
        pcall(function() Anims:Get("FlashStepRegular"):Play() end)
        pcall(function() Effect.play("Shared.Soru", { player = LocalPlayer, Mode = 1 }) end)
        ReplicatedStorage.Remotes.CommE:FireServer("Soru", { Mode = 1 }, workspace:GetServerTimeNow() + 900000000)

        local dest = targetHrp.CFrame * CFrame.new(math.random(-3, 3), 2, 5)
        char:PivotTo(CFrame.new(dest.Position, targetHrp.Position))
        char.HumanoidRootPart.CFrame = CFrame.new(dest.Position, targetHrp.Position + targetHrp.CFrame.LookVector * 7)

        btn.Text, btn.TextColor3 = "GO!", Color3.fromRGB(0, 255, 150)
        task.delay(0.5, function()                                         --[[P77]]
            btn.Text, btn.TextColor3 = "SORU NEAREST", Color3.fromRGB(0, 170, 255)
        end)
    end)
end)

-------------------------------------------------------------------------------
-- Surum V1 Camlock (floating button)                        --[[P53 P72 P73 P78 + k]]
-------------------------------------------------------------------------------
CreateButton("Surum V1 Camlock", function()
    if ScreenGui:FindFirstChild("CamLockUI") then return end
    local ui = Instance.new("TextButton", ScreenGui)
    ui.Name, ui.Size, ui.Position = "CamLockUI", UDim2.new(0, 200, 0, 50), UDim2.new(0.5, -100, 0.2, 0)
    ui.Text, ui.Font, ui.TextSize = "Surum V1: OFF", Enum.Font.Jura, 18
    ui.TextColor3, ui.BackgroundColor3, ui.Active, ui.Draggable = Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), true, true
    Instance.new("UICorner", ui).CornerRadius = UDim.new(0, 8)
    local border = Instance.new("UIStroke", ui)
    border.Name, border.Thickness, border.ApplyStrokeMode = "Border", 1, Enum.ApplyStrokeMode.Border
    border.Color = Color3.fromRGB(0, 255, 255)

    local function Disable()                                              --[[P73]]
        CamlockEnabled, Setting.Data.CamlockEnabled = false, false
        if CamlockConn then CamlockConn:Disconnect(); CamlockConn = nil end
        ui.Text, ui.TextColor3 = "Surum V1: OFF", Color3.fromRGB(255, 255, 255)
    end

    local function CamlockStep()                                          -- k
        if CamlockEnabled and CamlockTarget and CamlockTarget.Parent then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position,
                CamlockTarget.Position + (CamlockTarget.Velocity * Setting.Data.PredictionAmount))
        else
            if CamlockConn then CamlockConn:Disconnect() end
            CamlockEnabled, Setting.Data.CamlockEnabled = false, false
            Disable()
            ui.Text, ui.TextColor3 = "Surum V1: OFF", Color3.fromRGB(255, 255, 255)
        end
    end

    ui.MouseButton1Click:Connect(function()                               --[[P72]]
        if CamlockEnabled then
            Disable()
            return
        end
        CamlockTarget = ClosestToCrosshair()                               -- _
        if not CamlockTarget then return end
        CamlockEnabled, Setting.Data.CamlockEnabled = true, true
        ui.Text, ui.TextColor3 = "Surum V1: ON", Color3.fromRGB(0, 255, 0)
        if CamlockConn then CamlockConn:Disconnect() end
        CamlockConn = RunService.RenderStepped:Connect(CamlockStep)
    end)
end)

-------------------------------------------------------------------------------
-- Character hooks                                               --[[P33 P24/wrapper 24]]
-------------------------------------------------------------------------------
local function OnCharacter(char)
    char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child:FindFirstChild("LeftClickRemote") then
            -- tool equipped: nothing to do, M1Combo reads the current tool each tick
        end
    end)
    char.ChildRemoved:Connect(function() end)
end
if LocalPlayer.Character then OnCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(OnCharacter)

-------------------------------------------------------------------------------
-- Start loops
-------------------------------------------------------------------------------
task.spawn(UnbreakableSkillsLoop)
task.spawn(AutoRaceLoop)
task.spawn(WalkOnWaterLoop)
task.spawn(InfiniteEnergyLoop)
task.spawn(NPCTargetLoop)
task.spawn(PlayerTargetLoop)

RunService.RenderStepped:Connect(function()
    pcall(MovementTick)
    pcall(NPCAimTick)
    pcall(PlayerAimTick)
end)
RunService.Heartbeat:Connect(function()
    pcall(FastAttackTick)
end)
RunService.Stepped:Connect(function() end)
task.spawn(function()
    while task.wait(0.3) do pcall(PlayerEspTick) end
end)

print("Surum V1 Fully Loaded!")
