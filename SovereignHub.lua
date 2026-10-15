-- Sovereign Hub | Wind UI Port
-- Game: Steal An Egg (Roblox)
-- UI Library: Wind UI (github.com/Footagesus/WindUI)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- ─── Session guard ───────────────────────────────────────────────────────────
local genv = getgenv and getgenv() or _G

if type(genv.__SenaV4HubShutdown) == "function" then
    pcall(genv.__SenaV4HubShutdown)
end

local senaV4HubSession = {}
genv.__SenaV4HubSession = senaV4HubSession

local function sessionAlive()
    return genv.__SenaV4HubSession == senaV4HubSession
end

-- ─── Config table ────────────────────────────────────────────────────────────
local senaV4Config = {
    AutoSteal            = false,
    AutoPlace            = false,
    AutoHatch            = false,
    AutoMutation         = false,
    AutoRingEvent        = false,
    AutoSell             = false,
    AutoSellEgg          = false,
    AutoFavorite         = false,
    AutoFusePets         = false,
    AutoEquipBest        = false,
    AutoClaimOffline     = false,
    AutoBaseUpgrade      = false,
    AutoClaimAlmanac     = false,
    Noclip               = false,
    BottingMode          = false,
    AntiCutscene         = false,
    AntiAfk              = true,
    AutoReconnect        = true,
    AutoExecute          = false,
    GodMode              = false,
    HelpFriend           = false,
    LowSpeedBoost        = true,
    StealPlayers         = false,
    RaceClaim            = false,
    RaceBuy              = false,
    RaceAuto             = false,
    StarAlert            = false,
    StarAutoCatch        = false,
    WispAutoQuest        = false,
    BanjoAuto            = false,
    ButterflyAutoNet     = false,
    ButterflyAutoCatch   = false,
    ButterflyEsp         = false,
    ButterflyAutoTrade   = false,
    ButterflyAutoCraft   = false,
    ScrambleAutoBuyShop  = false,
    ScrambleBossAuto     = false,
    ScrambleTradeInTrade = false,
    ScrambleTradeInReroll= false,
    WebhookEnabled       = false,
    WebhookDisconnect    = false,
    InfiniteJump         = false,
    InstantGrab          = false,
    FlyForCapture        = false,
    AutoStealCapture     = false,
    EggEsp               = false,
    StartupBoost         = false,
    BoostFps             = false,
    UncapFps             = true,
    AntiGuardKnockback   = true,
    AntiHitGuard         = false,
    HopNoMatch           = false,
    PrivateServerAuto    = false,
    AutoTreadmill        = false,
    TreadmillUpgrade     = false,
    AntiTreadmill        = false,
    AutoIndex            = false,
    SellNames            = {},
    SellRarities         = {},
    SellEggRarities      = {},
    PlaceRarities        = {},
    StealNames           = {},
    StealRarities        = {},
    StealAreas           = {},
    StealMutations       = {},
    StealPriority        = "Rarity",
    StealMode            = "Instant Steal (Recommended)",
    StealHold            = 5,
    HopCooldown          = 5,
    PrivateServerMax     = "2",
    FuseRule             = "Any Species",
    FuseRarities         = {},
    FuseSpecies          = {},
    FavoriteRule         = "Rarity",
    FavoriteRarities     = {},
    FavoriteSpecies      = {},
    MutationChoice       = "Any",
    MutationSpecies      = {},
    MutationRarity       = "Any",
    MutationMinValue     = "",
    MutationRetry        = false,
    EspDetails           = {"Name","Rarity","Value","Icon"},
    EspMinRarity         = "Any",
    EspMinValue          = "",
    BackpackRates        = false,
    StealPlayerRarities  = {},
    StealPlayerValue     = "",
    WebhookUrl           = "",
    WebhookRarities      = {},
    WebhookValue         = "",
    ScrambleShopBuyList  = {},
    ScrambleTradeInBanners= {},
    TaskOrder            = {},
    Waypoint             = "Respawn Point",
    AdminBoost           = false,
}

-- ─── Load Wind UI ─────────────────────────────────────────────────────────────
local WindUI
local ok, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not ok or not WindUI then
    -- Fallback: try alternative CDN
    pcall(function()
        WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
    end)
end

if not WindUI then
    error("[Sovereign] Failed to load Wind UI library. Check your internet connection.")
    return
end

-- ─── Helper stubs (replace with real runtime calls if available) ──────────────
local function stub(name)
    return function(val)
        -- wire to real genv runtime if present
        local runtime = genv["__SenaV4" .. name]
        if runtime and type(runtime.setEnabled) == "function" then
            pcall(runtime.setEnabled, runtime, val == true)
        end
    end
end

local function notify(title, content)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = 3 })
    end)
end

-- ─── Create Window ────────────────────────────────────────────────────────────
local Window = WindUI:CreateWindow({
    Title = "Sovereign Hub",
    Icon         = "hand",
    Author = "Sovereign Hub",
    Folder = "SovereignHub",
    Size         = UDim2.fromOffset(580, 460),
    Transparent  = true,
    Theme        = "Dark",
    Background = "",
    KeySystem    = false,
    SaveConfig   = true,
})

-- ─── Tabs ─────────────────────────────────────────────────────────────────────
local HomeTab     = Window:CreateTab({ Name = "Home",       Icon = "home"        })
local WindowsTab  = Window:CreateTab({ Name = "Windows",    Icon = "layout-grid" })
local StealTab    = Window:CreateTab({ Name = "Steal",      Icon = "grab"        })
local EggsTab     = Window:CreateTab({ Name = "Eggs & Plot",Icon = "egg"         })
local PetsTab     = Window:CreateTab({ Name = "Pets",       Icon = "sparkles"    })
local EventsTab   = Window:CreateTab({ Name = "Events",     Icon = "flame"       })
local FarmTab     = Window:CreateTab({ Name = "Farm",       Icon = "activity"    })
local ServerTab   = Window:CreateTab({ Name = "Server",     Icon = "server"      })
local SettingsTab = Window:CreateTab({ Name = "Settings",   Icon = "settings"    })

-- ═══════════════════════════════════════════════════════════════════════════════
--  HOME TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local TaskSection = HomeTab:CreateSection("Task Order")
    TaskSection:AddLabel("Auto tasks run in order: Steal → Place → Hatch → Mutate → Sell → Server Hop.")

    local RunOnce = HomeTab:CreateSection("Run Once")

    RunOnce:AddButton({
        Name    = "Place Everything Now",
        Info    = "Runs one pass of Auto Place, even while the toggle is off.",
        Callback = function()
            local r = genv.__SenaV4EggRuntime
            if r and type(r.AutoPlaceLoop) == "function" then pcall(r.AutoPlaceLoop) end
            notify("Run Once", "Auto Place triggered")
        end,
    })

    RunOnce:AddButton({
        Name    = "Hatch Everything Ready",
        Info    = "Runs one pass of Auto Hatch, even while the toggle is off.",
        Callback = function()
            local r = genv.__SenaV4EggRuntime
            if r and type(r.AutoHatchLoop) == "function" then pcall(r.AutoHatchLoop) end
            notify("Run Once", "Auto Hatch triggered")
        end,
    })

    RunOnce:AddButton({
        Name    = "Sell Pets Now",
        Info    = "Runs one pass of Auto Sell Pet using the filters above.",
        Callback = function()
            local r = genv.__SenaV4PetBarn
            if r and type(r.startAutoSellLoop) == "function" then pcall(r.startAutoSellLoop) end
            notify("Run Once", "Auto Sell triggered")
        end,
    })

    RunOnce:AddButton({
        Name    = "Sell Eggs Now",
        Info    = "Runs one pass of Auto Sell Egg using the filters above.",
        Callback = function()
            local r = genv.__SenaV4EggRuntime
            if r and type(r.startAutoSellEggLoop) == "function" then pcall(r.startAutoSellEggLoop) end
            notify("Run Once", "Auto Sell Egg triggered")
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  WINDOWS TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    local WinSection = WindowsTab:CreateSection("Windows")

    local panels = genv.__SenaV4Panels or {}

    WinSection:AddButton({ Name = "Egg Logs",         Info = "Live feed of every egg that spawns on the server.",                  Callback = function() pcall(panels.openLogs)      end })
    WinSection:AddButton({ Name = "Egg Board",        Info = "Sortable list of the eggs currently up for grabs.",                  Callback = function() pcall(panels.openBoard)     end })
    WinSection:AddButton({ Name = "Inventory & Base", Info = "Your pets, eggs and plot status in one window.",                     Callback = function() pcall(panels.openInventory) end })
    WinSection:AddButton({ Name = "Egg Checker",      Info = "Pick eggs off the field by hand, then send them all to the steal queue.", Callback = function() pcall(panels.openChecker) end })
    WinSection:AddButton({ Name = "Egg Data & History",Info = "Drop-table values per area, plus what has actually spawned this session.", Callback = function() pcall(panels.openAnalyst) end })
    WinSection:AddButton({ Name = "Farm Stats",       Info = "What is running now, money and income, steals and the Dr Scramble event at a glance.", Callback = function() pcall(panels.openStats) end })
    WinSection:AddButton({ Name = "Open All Windows", Info = "Opens every window at once.", Callback = function() pcall(panels.openAll) end })
    WinSection:AddButton({ Name = "Close All Windows",Info = "Closes every window.",        Callback = function() pcall(panels.closeAll) end })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  STEAL TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- Auto Steal Section
    local AutoStealSec = StealTab:CreateSection("Auto Steal")

    AutoStealSec:AddToggle({
        Name    = "Auto Steal",
        Info    = "Steals eggs that match your filters and brings them home.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoSteal = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setEnabled) == "function" then pcall(r.setEnabled, r, val) end
        end,
    })

    AutoStealSec:AddButton({
        Name    = "Open Hop UI",
        Info    = "Opens the Rare Egg Hop panel.",
        Callback = function()
            local h = genv.__SenaV4HopHunt
            if h then task.spawn(function() pcall(h.open) end) end
        end,
    })

    AutoStealSec:AddToggle({
        Name    = "Help Friend",
        Info    = "Instead of banking a stolen egg, drops it just before the safe zone line so a friend can pick it up.",
        Default = false,
        Callback = function(val) senaV4Config.HelpFriend = val end,
    })

    AutoStealSec:AddToggle({
        Name    = "Aura Bat",
        Info    = "God mode bat helper.",
        Default = false,
        Callback = function(val)
            senaV4Config.GodMode = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setGodMode) == "function" then pcall(r.setGodMode, r, val) end
        end,
    })

    AutoStealSec:AddDropdown({
        Name    = "Steal Mode",
        Info    = "Pick the movement style for Auto Steal.",
        Options = { "Instant Steal (Recommended)", "High Speed User Normal", "High Speed User (Fly)", "Zig-Zag High Speed User" },
        Default = "Instant Steal (Recommended)",
        Callback = function(val)
            senaV4Config.StealMode = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setStealMode) == "function" then pcall(r.setStealMode, r, val) end
        end,
    })

    AutoStealSec:AddSlider({
        Name    = "Instant Steal Multiplier",
        Info    = "For Instant Steal mode. Higher = faster grab, lower = safer.",
        Min     = 1,
        Max     = 10,
        Default = 5,
        Callback = function(val)
            senaV4Config.StealHold = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setStealHold) == "function" then pcall(r.setStealHold, r, val) end
        end,
    })

    AutoStealSec:AddToggle({
        Name    = "Boost For Instant Steal",
        Info    = "Faster steals for Instant Steal on every area except Forest. Keep it on when you use Instant Steal.",
        Default = true,
        Callback = function(val) senaV4Config.LowSpeedBoost = val end,
    })

    -- Egg Filter Section
    local EggFilterSec = StealTab:CreateSection("Egg Filter")
    EggFilterSec:AddLabel("─── Egg ───")

    EggFilterSec:AddMultiDropdown({
        Name    = "Filter By Egg Name",
        Info    = "Only steal these eggs. Leave empty for any egg.",
        Options = {},   -- populated at runtime from game data
        Default = {},
        Callback = function(val) senaV4Config.StealNames = val end,
    })

    EggFilterSec:AddMultiDropdown({
        Name    = "Filter By Rarity",
        Info    = "Only steal these rarities. Leave empty for any rarity.",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = {},
        Callback = function(val) senaV4Config.StealRarities = val end,
    })

    EggFilterSec:AddLabel("─── Area & Value ───")

    EggFilterSec:AddMultiDropdown({
        Name    = "Select Area",
        Info    = "Only steal from these areas. Leave empty for every area.",
        Options = { "Forest", "Angels & Demons", "Desert", "Arctic", "Volcano" },
        Default = {},
        Callback = function(val) senaV4Config.StealAreas = val end,
    })

    EggFilterSec:AddInput({
        Name        = "Steal By Value",
        Info        = "Minimum money per second. Supports k, m and b.",
        Default     = "",
        Placeholder = "e.g. 500k, 2m, 1b",
        Callback    = function(val) senaV4Config.StealValue = val end,
    })

    EggFilterSec:AddMultiDropdown({
        Name    = "Filter By Mutation",
        Info    = "Only steal eggs carrying one of these mutations. Leave empty for any egg.",
        Options = { "None", "Giant", "Tiny", "Shiny", "Rainbow", "Radiant", "Golden", "Crystal", "Cosmic" },
        Default = {},
        Callback = function(val) senaV4Config.StealMutations = val end,
    })

    EggFilterSec:AddInput({
        Name        = "Steal By Weight",
        Info        = "Minimum egg weight in kilograms. 0 accepts any weight.",
        Default     = "",
        Placeholder = "e.g. 12000",
        Callback    = function(val) senaV4Config.StealWeight = val end,
    })

    EggFilterSec:AddDropdown({
        Name    = "Steal Priority",
        Info    = "Which egg to go for first when more than one passes the filters.",
        Options = { "Rarity", "Highest Value", "Heaviest" },
        Default = "Rarity",
        Callback = function(val)
            senaV4Config.StealPriority = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setPriority) == "function" then pcall(r.setPriority, r, val) end
        end,
    })

    EggFilterSec:AddToggle({
        Name    = "Auto Index",
        Info    = "Also steal eggs whose pet is still missing from your Pet Index, in any area, on top of the filters above.",
        Default = false,
        Callback = function(val) senaV4Config.AutoIndex = val end,
    })

    -- Egg ESP Section
    local EspSec = StealTab:CreateSection("Egg ESP")

    EspSec:AddToggle({
        Name    = "Egg ESP",
        Info    = "Draws a label over every egg on the field so you can read it from across the map.",
        Default = false,
        Callback = function(val)
            senaV4Config.EggEsp = val
            local r = genv.__SenaV4EggEsp
            if r and type(r.setEnabled) == "function" then pcall(r.setEnabled, r, val) end
        end,
    })

    EspSec:AddMultiDropdown({
        Name    = "ESP Details",
        Info    = "What each label shows.",
        Options = { "Name", "Rarity", "Value", "Weight", "Mutation", "Placed Eggs", "Icon" },
        Default = { "Name", "Rarity", "Value", "Icon" },
        Callback = function(val) senaV4Config.EspDetails = val end,
    })

    EspSec:AddDropdown({
        Name    = "ESP Min Rarity",
        Info    = "Only label eggs of this rarity or rarer. Any labels every egg.",
        Options = { "Any", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = "Any",
        Callback = function(val) senaV4Config.EspMinRarity = val end,
    })

    EspSec:AddInput({
        Name        = "ESP Min Value",
        Info        = "Only label eggs making at least this much per second. Supports k, m and b.",
        Default     = "",
        Placeholder = "e.g. 500k, 2m, 1b",
        Callback    = function(val) senaV4Config.EspMinValue = val end,
    })

    -- Steal From Players Section
    local PlayerStealSec = StealTab:CreateSection("Steal From Players")

    PlayerStealSec:AddToggle({
        Name    = "Auto Steal From Players",
        Info    = "Chases anyone carrying an egg in the field, bats them until the egg drops, grabs it and banks it.",
        Default = false,
        Callback = function(val)
            senaV4Config.StealPlayers = val
            local r = genv.__SenaV4PlayerSteal
            if r and type(r.setEnabled) == "function" then pcall(r.setEnabled, r, val) end
        end,
    })

    PlayerStealSec:AddMultiDropdown({
        Name    = "Player Rarity Filter",
        Info    = "Only chase eggs of these rarities. Empty = uses the Auto Steal rarity filter.",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = {},
        Callback = function(val) senaV4Config.StealPlayerRarities = val end,
    })

    PlayerStealSec:AddInput({
        Name        = "Player Minimum Value",
        Info        = "Skip carriers holding less than this per second. Supports k, m and b.",
        Default     = "",
        Placeholder = "e.g. 500k, 2m, 1b",
        Callback    = function(val) senaV4Config.StealPlayerValue = val end,
    })

    -- Steal History Section
    local StealHistorySec = StealTab:CreateSection("Steal History")
    StealHistorySec:AddLabel("Steal history from players is shown in the Windows tab > Farm Stats.")
    StealHistorySec:AddButton({
        Name    = "Clear History",
        Info    = "Wipe the steal history list.",
        Callback = function()
            local r = genv.__SenaV4PlayerSteal
            if r and type(r.clearHistory) == "function" then pcall(r.clearHistory, r) end
            notify("Steal History", "History cleared")
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  EGGS & PLOT TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- Placed Eggs Section
    EggsTab:CreateSection("Placed Eggs"):AddLabel("Your placed egg list is shown in the Windows tab > Inventory & Base.")

    -- Auto Place & Hatch Section
    local EggMgmtSec = EggsTab:CreateSection("Place & Hatch")
    EggMgmtSec:AddLabel("─── Place ───")

    EggMgmtSec:AddToggle({
        Name    = "Auto Place",
        Info    = "Automatically places eggs onto your plot.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoPlace = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setAutoPlace) == "function" then pcall(r.setAutoPlace, r, val) end
        end,
    })

    EggMgmtSec:AddLabel("─── Hatch ───")

    EggMgmtSec:AddToggle({
        Name    = "Auto Hatch",
        Info    = "Hatches every egg on your plot as soon as it is ready.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoHatch = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setAutoHatch) == "function" then pcall(r.setAutoHatch, r, val) end
        end,
    })

    EggMgmtSec:AddLabel("─── Mutate ───")

    EggMgmtSec:AddToggle({
        Name    = "Auto Mutation",
        Info    = "Applies mutations to eggs that pass the filters below.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoMutation = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setAutoMutation) == "function" then pcall(r.setAutoMutation, r, val) end
        end,
    })

    EggMgmtSec:AddDropdown({
        Name    = "Mutation Choice",
        Info    = "Which mutation to try to apply.",
        Options = { "Any", "Giant", "Tiny", "Shiny", "Rainbow", "Radiant", "Golden", "Crystal", "Cosmic" },
        Default = "Any",
        Callback = function(val) senaV4Config.MutationChoice = val end,
    })

    EggMgmtSec:AddMultiDropdown({
        Name    = "Mutation Species",
        Info    = "Only mutate eggs of these species. Leave empty for any.",
        Options = {},
        Default = {},
        Callback = function(val) senaV4Config.MutationSpecies = val end,
    })

    EggMgmtSec:AddDropdown({
        Name    = "Mutation Rarity",
        Info    = "Only mutate eggs of this rarity or higher.",
        Options = { "Any", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = "Any",
        Callback = function(val) senaV4Config.MutationRarity = val end,
    })

    EggMgmtSec:AddInput({
        Name        = "Mutation Min Value",
        Info        = "Only mutate eggs worth this much per second or more.",
        Default     = "",
        Placeholder = "e.g. 500k, 2m, 1b",
        Callback    = function(val) senaV4Config.MutationMinValue = val end,
    })

    EggMgmtSec:AddToggle({
        Name    = "Mutation Retry",
        Info    = "Retry mutations on failed attempts.",
        Default = false,
        Callback = function(val) senaV4Config.MutationRetry = val end,
    })

    -- Egg Selling Section
    local EggSellSec = EggsTab:CreateSection("Egg Selling")

    EggSellSec:AddToggle({
        Name    = "Auto Sell Egg",
        Info    = "Sells unplaced eggs of the rarities below.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoSellEgg = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setAutoSellEgg) == "function" then pcall(r.setAutoSellEgg, r, val) end
        end,
    })

    EggSellSec:AddMultiDropdown({
        Name    = "Egg Rarity Filter",
        Info    = "Egg rarities to sell. Leave empty to sell none.",
        Options = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = {},
        Callback = function(val) senaV4Config.SellEggRarities = val end,
    })

    EggSellSec:AddInput({
        Name        = "Egg Sell By Value (max money/s)",
        Info        = "Only sell eggs whose money per second is this or lower. Blank = no value limit.",
        Default     = "",
        Placeholder = "e.g. 100k, 2m",
        Callback    = function(val) senaV4Config.SellEggValue = val end,
    })

    -- Equip & Collect Section
    local EquipSec = EggsTab:CreateSection("Equip & Collect")

    EquipSec:AddToggle({
        Name    = "Auto Equip Best",
        Info    = "Keeps your strongest pets equipped as better ones hatch.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoEquipBest = val
            local r = genv.__SenaV4PetBarn
            if r and type(r.setAutoEquip) == "function" then pcall(r.setAutoEquip, r, val) end
        end,
    })

    EquipSec:AddToggle({
        Name    = "Collect Offline Income",
        Info    = "Claims the money your base earned while you were away, as soon as there is any.",
        Default = false,
        Callback = function(val) senaV4Config.AutoClaimOffline = val end,
    })

    EquipSec:AddToggle({
        Name    = "Auto Upgrade Base",
        Info    = "Buys the next base tier the moment you can afford it.",
        Default = false,
        Callback = function(val) senaV4Config.AutoBaseUpgrade = val end,
    })

    EquipSec:AddToggle({
        Name    = "Auto Claim Almanac",
        Info    = "Redeems every Pet Index reward that is ready.",
        Default = false,
        Callback = function(val) senaV4Config.AutoClaimAlmanac = val end,
    })

    EquipSec:AddButton({
        Name    = "Upgrade Base Now",
        Info    = "Buys one base tier right away.",
        Callback = function()
            local r = genv.__SenaV4Upgrades
            local ok2, msg = false, "Upgrades not ready"
            if r and type(r.upgradeBase) == "function" then ok2, msg = pcall(r.upgradeBase) end
            notify("Base", ok2 and "Base upgraded" or tostring(msg))
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  PETS TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- Pet Selling Section
    local PetSellSec = PetsTab:CreateSection("Pet Selling")

    PetSellSec:AddToggle({
        Name    = "Auto Sell Pet",
        Info    = "Sells pets that match a filter below. Favorite, placed and equipped pets are kept.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoSell = val
            local r = genv.__SenaV4PetBarn
            if r and type(r.setAutoSell) == "function" then pcall(r.setAutoSell, r, val) end
        end,
    })

    PetSellSec:AddLabel("─── Filter ───")

    PetSellSec:AddMultiDropdown({
        Name    = "Pet Name Filter",
        Info    = "Pets to sell by name.",
        Options = {},
        Default = {},
        Callback = function(val) senaV4Config.SellNames = val end,
    })

    PetSellSec:AddMultiDropdown({
        Name    = "Pet Rarity Filter",
        Info    = "Pets to sell by rarity.",
        Options = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = {},
        Callback = function(val) senaV4Config.SellRarities = val end,
    })

    PetSellSec:AddInput({
        Name        = "Sell By Value (max money/s)",
        Info        = "Only sell pets whose money per second is this or lower. Blank = no value limit.",
        Default     = "",
        Placeholder = "e.g. 100k, 2m",
        Callback    = function(val) senaV4Config.SellPetValue = val end,
    })

    -- Pet Favorite Section
    local FavSec = PetsTab:CreateSection("Pet Favorite")

    FavSec:AddToggle({
        Name    = "Auto Favorite",
        Info    = "Marks every pet that matches the rule below as a favorite, so Auto Sell and Auto Fuse leave it alone.",
        Default = false,
        Callback = function(val) senaV4Config.AutoFavorite = val end,
    })

    FavSec:AddDropdown({
        Name    = "Favorite Rule",
        Info    = "Match pets by rarity or by species.",
        Options = { "Rarity", "Species" },
        Default = "Rarity",
        Callback = function(val) senaV4Config.FavoriteRule = val end,
    })

    FavSec:AddLabel("─── Only when Rule = Rarity ───")

    FavSec:AddMultiDropdown({
        Name    = "Rarities to Keep",
        Info    = "Pets of these rarities get favorited.",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = {},
        Callback = function(val) senaV4Config.FavoriteRarities = val end,
    })

    FavSec:AddLabel("─── Only when Rule = Species ───")

    FavSec:AddMultiDropdown({
        Name    = "Species to Keep",
        Info    = "Pets of these species get favorited.",
        Options = {},
        Default = {},
        Callback = function(val) senaV4Config.FavoriteSpecies = val end,
    })

    FavSec:AddButton({
        Name    = "Unfavorite Everything",
        Info    = "Clears the favorite flag on every pet you own.",
        Callback = function()
            local r = genv.__SenaV4PetBarn
            local count = 0
            if r and type(r.unfavoriteAll) == "function" then count = pcall(r.unfavoriteAll) or 0 end
            notify("Pet Favorite", tostring(count) .. " pets unfavorited")
        end,
    })

    -- Pet Fusion Section
    local FuseSec = PetsTab:CreateSection("Pet Fusion")

    FuseSec:AddToggle({
        Name    = "Auto Fuse",
        Info    = "Feeds three matching pets into the Fusion machine over and over. Favorited and equipped pets are never used.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoFusePets = val
            local r = genv.__SenaV4PetBarn
            if r and type(r.setAutoFuse) == "function" then pcall(r.setAutoFuse, r, val) end
        end,
    })

    FuseSec:AddDropdown({
        Name    = "Fusion Rule",
        Info    = "Fuse anything that passes the rarity filter, or only the species you pick below.",
        Options = { "Any Species", "Selected Species" },
        Default = "Any Species",
        Callback = function(val) senaV4Config.FuseRule = val end,
    })

    FuseSec:AddMultiDropdown({
        Name    = "Rarities to Fuse",
        Info    = "Only fuse pets of these rarities. Leave empty for any rarity.",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = {},
        Callback = function(val) senaV4Config.FuseRarities = val end,
    })

    FuseSec:AddLabel("─── Only when Rule = Selected Species ───")

    FuseSec:AddMultiDropdown({
        Name    = "Species to Fuse",
        Info    = "Only these species go into the machine.",
        Options = {},
        Default = {},
        Callback = function(val) senaV4Config.FuseSpecies = val end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  EVENTS TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- Capture The Egg
    local CaptureSec = EventsTab:CreateSection("Capture The Egg")

    CaptureSec:AddToggle({
        Name    = "Auto Steal Capture",
        Info    = "For the Capture The Egg event. Steals the event egg the Low Speed User way, then holds it high up so your time keeps going.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoStealCapture = val
            local r = genv.__SenaV4EggRuntime
            if r and type(r.setAutoStealCapture) == "function" then pcall(r.setAutoStealCapture, r, val) end
        end,
    })

    -- Movement Section
    local MoveSec = EventsTab:CreateSection("Movement")

    MoveSec:AddToggle({
        Name    = "Admin Abuse Boost",
        Info    = "Only works during Admin Abuse: Auto Steal goes straight to each egg and straight home, at full speed.",
        Default = false,
        Callback = function(val) senaV4Config.AdminBoost = val end,
    })

    MoveSec:AddToggle({
        Name    = "Fly For Capture",
        Info    = "For the Capture The Egg event. After you pick up an egg, you fly up and stay still in the air so nobody can take it.",
        Default = false,
        Callback = function(val)
            senaV4Config.FlyForCapture = val
            local r = genv.__SenaV4FlyRuntime
            if r and type(r.setEnabled) == "function" then pcall(r.setEnabled, r, val) end
        end,
    })

    MoveSec:AddToggle({
        Name    = "Instant Grab",
        Info    = "Picking up an egg only needs a quick tap instead of a long hold.",
        Default = false,
        Callback = function(val) senaV4Config.InstantGrab = val end,
    })

    MoveSec:AddToggle({
        Name    = "Infinite Jump",
        Info    = "Jump again in mid-air, as often as you like.",
        Default = false,
        Callback = function(val)
            senaV4Config.InfiniteJump = val
            local r = genv.__SenaV4JumpRuntime
            if r and type(r.setEnabled) == "function" then pcall(r.setEnabled, r, val) end
        end,
    })

    MoveSec:AddToggle({
        Name    = "Noclip",
        Info    = "Walk through walls and doors.",
        Default = false,
        Callback = function(val) senaV4Config.Noclip = val end,
    })

    -- Ring Event
    local RingSec = EventsTab:CreateSection("Ring Event")

    RingSec:AddToggle({
        Name    = "Auto Ring Event",
        Info    = "Starts at the safe zone, then glides Forest -> Angels & Demons -> back to Forest on a loop. Turn off Auto Steal while using this.",
        Default = false,
        Callback = function(val) senaV4Config.AutoRingEvent = val end,
    })

    -- Wisp Event
    local WispSec = EventsTab:CreateSection("Wisp Event")

    WispSec:AddLabel("Wisp progress: check the Farm Stats window for live status.")

    WispSec:AddToggle({
        Name    = "Auto Wisp Quest",
        Info    = "Meets the Baby Wisp, hunts the quest eggs, fuses an Enchanted Forest animal, claims every reward and flies the wisp home to unlock the Enchanted Tree. Needs 50B SpeedPower.",
        Default = false,
        Callback = function(val) senaV4Config.WispAutoQuest = val end,
    })

    WispSec:AddToggle({
        Name    = "Auto Banjo Cricket",
        Info    = "Goes into the Enchanted Tree, plays the Banjo Cricket's mushroom song back for all 5 stages, then claims the secret from Jitterbug. Needs the tree unlocked.",
        Default = false,
        Callback = function(val) senaV4Config.BanjoAuto = val end,
    })

    -- Butterfly Bloom
    local BloomSec = EventsTab:CreateSection("Butterfly Bloom")

    BloomSec:AddLabel("Bloom Status: check the Farm Stats window.")

    BloomSec:AddToggle({
        Name    = "Auto Claim Net",
        Info    = "Goes into the Enchanted Tree and claims your free Butterfly Net once.",
        Default = false,
        Callback = function(val) senaV4Config.ButterflyAutoNet = val end,
    })

    BloomSec:AddToggle({
        Name    = "Auto Catch",
        Info    = "During every Bloom (every 30 min, 5 min long) flies to the Enchanted Forest, equips the net and catches butterflies.",
        Default = false,
        Callback = function(val) senaV4Config.ButterflyAutoCatch = val end,
    })

    BloomSec:AddDropdown({
        Name    = "Catch Mode",
        Info    = "Tween to Butterfly chases one butterfly at a time. Stand waits in the thickest part, Zigzag sweeps back and forth, Circle loops around the swarm.",
        Options = { "Tween to Butterfly", "Stand", "Zigzag", "Circle" },
        Default = "Tween to Butterfly",
        Callback = function(val)
            local r = genv.__SenaV4ButterflyRuntime
            if r and type(r.setMode) == "function" then pcall(r.setMode, val) end
        end,
    })

    BloomSec:AddMultiDropdown({
        Name    = "Catch Tiers",
        Info    = "Only swing at these butterflies. Leave empty to catch every tier.",
        Options = { "Radiant", "Amethyst", "Sapphire", "Emerald" },
        Default = {},
        Callback = function(val)
            local r = genv.__SenaV4ButterflyRuntime
            if r and type(r.setTiers) == "function" then pcall(r.setTiers, val) end
        end,
    })

    BloomSec:AddToggle({
        Name    = "Butterfly ESP",
        Info    = "Shows every butterfly's tier and distance while a Bloom is live.",
        Default = false,
        Callback = function(val) senaV4Config.ButterflyEsp = val end,
    })

    BloomSec:AddLabel("─── Trade & Craft ───")

    BloomSec:AddToggle({
        Name    = "Auto Trade Up",
        Info    = "After each Bloom, trades your butterflies up at the machine inside the Enchanted Tree.",
        Default = false,
        Callback = function(val) senaV4Config.ButterflyAutoTrade = val end,
    })

    BloomSec:AddDropdown({
        Name    = "Trade Recipe",
        Info    = "Which trade Auto Trade Up runs.",
        Options = { "All Recipes" },
        Default = "All Recipes",
        Callback = function(val)
            local r = genv.__SenaV4ButterflyRuntime
            if r and type(r.setRecipe) == "function" then pcall(r.setRecipe, val) end
        end,
    })

    BloomSec:AddToggle({
        Name    = "Auto Craft Essence",
        Info    = "After each Bloom, crafts Enchanted Essence at the shrine once you hold the full recipe.",
        Default = false,
        Callback = function(val) senaV4Config.ButterflyAutoCraft = val end,
    })

    BloomSec:AddButton({
        Name    = "Claim Net Now",
        Info    = "Claims the Butterfly Net right now.",
        Callback = function()
            local r = genv.__SenaV4ButterflyRuntime
            if r and type(r.claimNet) == "function" then
                local ok2, res = pcall(r.claimNet)
                notify("Butterfly Bloom", ok2 and "Butterfly Net claimed" or tostring(res))
            end
        end,
    })

    BloomSec:AddButton({
        Name    = "Trade Up Now",
        Info    = "Runs the trade recipe once, even with Auto Trade Up off.",
        Callback = function()
            local r = genv.__SenaV4ButterflyRuntime
            if r and type(r.tradeUp) == "function" then
                local ok2, res = pcall(r.tradeUp)
                notify("Butterfly Bloom", ok2 and ("Traded up %d time(s)"):format(tonumber(res) or 0) or tostring(res))
            end
        end,
    })

    BloomSec:AddButton({
        Name    = "Craft Essence Now",
        Info    = "Crafts Enchanted Essence right now if you hold the full recipe.",
        Callback = function()
            local r = genv.__SenaV4ButterflyRuntime
            if r and type(r.craft) == "function" then
                local ok2, res = pcall(r.craft)
                notify("Butterfly Bloom", ok2 and ("Crafted %d Enchanted Essence"):format(tonumber(res) or 0) or tostring(res))
            end
        end,
    })

    -- Star Event
    local StarSec = EventsTab:CreateSection("Star Event")

    StarSec:AddToggle({
        Name    = "Star Alert",
        Info    = "Sends a notification when a star egg spawns on the server.",
        Default = false,
        Callback = function(val) senaV4Config.StarAlert = val end,
    })

    StarSec:AddToggle({
        Name    = "Auto Catch Star",
        Info    = "Automatically steals the star egg when one appears.",
        Default = false,
        Callback = function(val) senaV4Config.StarAutoCatch = val end,
    })

    -- Dr Scramble Event
    local ScrambleSec = EventsTab:CreateSection("Dr Scramble Event")

    ScrambleSec:AddLabel("Dr Scramble only runs during the live event. The shop, trade-in and boss fight are still up; the rest of the time these toggles sit idle.")

    ScrambleSec:AddToggle({
        Name    = "Auto Buy Shop",
        Info    = "Spends samples on the shop items you pick below, as soon as you can afford them.",
        Default = false,
        Callback = function(val) senaV4Config.ScrambleAutoBuyShop = val end,
    })

    ScrambleSec:AddMultiDropdown({
        Name    = "Shop Buy List",
        Info    = "Which shop items Auto Buy should purchase. This list fills in once the event shop is open.",
        Options = { "Biohazard Pets", "Experimental Pets", "Unstable DNA" },
        Default = {},
        Callback = function(val) senaV4Config.ScrambleShopBuyList = val end,
    })

    ScrambleSec:AddLabel("─── Trade-In (Experimental Pets) ───")

    ScrambleSec:AddToggle({
        Name    = "Auto Trade-In",
        Info    = "Auto-completes the recipe: uses the required eggs you already have, and auto-adds any you're missing to the Auto Steal hunt. Favorited / placed eggs are never spent.",
        Default = false,
        Callback = function(val) senaV4Config.ScrambleTradeInTrade = val end,
    })

    ScrambleSec:AddToggle({
        Name    = "Auto Free Reroll",
        Info    = "When pets are missing and a free reroll is left, rerolls the recipe instead of waiting.",
        Default = false,
        Callback = function(val) senaV4Config.ScrambleTradeInReroll = val end,
    })

    ScrambleSec:AddMultiDropdown({
        Name    = "Target Banners",
        Info    = "Only work the trade-in while one of these banners is up. Leave empty to accept any banner.",
        Options = { "Biohazard Pets", "Experimental Pets", "Unstable DNA" },
        Default = {},
        Callback = function(val) senaV4Config.ScrambleTradeInBanners = val end,
    })

    ScrambleSec:AddButton({
        Name    = "Trade-In Once",
        Info    = "Runs one sacrifice right now, even with Auto Trade-In off.",
        Callback = function()
            local r = genv.__SenaV4ScrambleTradeIn
            local ok2, msg = false, "Trade-In not ready"
            if r then ok2, msg = pcall(r.tradeOnce) end
            notify("Dr Scramble", ok2 and "Sacrifice complete" or tostring(msg))
        end,
    })

    ScrambleSec:AddButton({
        Name    = "Use Free Reroll",
        Info    = "Spends one of today's free rerolls on a new recipe.",
        Callback = function()
            local r = genv.__SenaV4ScrambleTradeIn
            local ok2, msg = false, "Trade-In not ready"
            if r then ok2, msg = pcall(r.reroll) end
            notify("Dr Scramble", ok2 and "Recipe rerolled" or tostring(msg))
        end,
    })

    ScrambleSec:AddButton({
        Name    = "Open Trade-In UI",
        Info    = "Opens Dr Scramble's Lab window so you can pick pets by hand.",
        Callback = function()
            if not pcall(function()
                require(ReplicatedStorage.Client.Tabs).Activate("DrScrambleTradeIn")
            end) then
                notify("Dr Scramble", "Could not open the trade-in window")
            end
        end,
    })

    ScrambleSec:AddLabel("─── Boss Fight ───")

    ScrambleSec:AddToggle({
        Name    = "Auto Boss",
        Info    = "When Dr Scramble's boss is live, walks into the arena portal, joins the fight, hits the nearest target and breaks free from grabs.",
        Default = false,
        Callback = function(val)
            senaV4Config.ScrambleBossAuto = val
            local r = genv.__SenaV4ScrambleBoss
            if r and type(r.setEnabled) == "function" then pcall(r.setEnabled, r, val) end
        end,
    })

    -- Race Event
    local RaceSec = EventsTab:CreateSection("Race Event")

    RaceSec:AddToggle({
        Name    = "Race Auto",
        Info    = "Automatically participates in the Race event.",
        Default = false,
        Callback = function(val) senaV4Config.RaceAuto = val end,
    })

    RaceSec:AddToggle({
        Name    = "Race Claim",
        Info    = "Automatically claims race rewards when available.",
        Default = false,
        Callback = function(val) senaV4Config.RaceClaim = val end,
    })

    RaceSec:AddToggle({
        Name    = "Race Buy",
        Info    = "Purchases race items from the buy list below.",
        Default = false,
        Callback = function(val) senaV4Config.RaceBuy = val end,
    })

    RaceSec:AddMultiDropdown({
        Name    = "Race Buy List",
        Info    = "Items to buy during the Race event.",
        Options = {},
        Default = {},
        Callback = function(val) senaV4Config.RaceBuyList = val end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  FARM TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- Treadmill
    local TreadSec = FarmTab:CreateSection("Treadmill")

    TreadSec:AddToggle({
        Name    = "Auto Treadmill",
        Info    = "Walks to your treadmill and farms speed whenever nothing else is running.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoTreadmill = val
            local r = genv.__SenaV4TreadmillRuntime
            if r and type(r.setEnabled) == "function" then pcall(r.setEnabled, r, val) end
        end,
    })

    TreadSec:AddToggle({
        Name    = "Auto Upgrade Treadmill",
        Info    = "Buys the next treadmill tier with cash as soon as you can afford it.",
        Default = false,
        Callback = function(val) senaV4Config.TreadmillUpgrade = val end,
    })

    -- Blocker
    local BlockSec = FarmTab:CreateSection("Blocker")

    BlockSec:AddToggle({
        Name    = "Anti Treadmill",
        Info    = "Never stay on a treadmill: any mount is dropped right away, and Auto Treadmill is held off while this is on.",
        Default = false,
        Callback = function(val) senaV4Config.AntiTreadmill = val end,
    })

    -- Roaming
    local RoamSec = FarmTab:CreateSection("Roaming")

    RoamSec:AddDropdown({
        Name    = "Waypoint",
        Info    = "Pick a place, then hit Teleport below.",
        Options = { "Respawn Point", "Forest", "Angels & Demons", "Desert", "Arctic", "Volcano", "Enchanted Forest" },
        Default = "Respawn Point",
        Callback = function(val) senaV4Config.Waypoint = val end,
    })

    RoamSec:AddButton({
        Name    = "Teleport To Waypoint",
        Info    = "Moves you straight to the waypoint you picked.",
        Callback = function()
            local r = genv.__SenaV4Roaming
            local success = false
            if r and type(r.teleportWaypoint) == "function" then
                success = pcall(r.teleportWaypoint, senaV4Config.Waypoint)
            end
            notify("Waypoint", success and ("Moved to " .. tostring(senaV4Config.Waypoint)) or "That waypoint is not in this server")
        end,
    })

    -- Webhook
    local WebhookSec = FarmTab:CreateSection("Webhook Alerts")

    WebhookSec:AddToggle({
        Name    = "Webhook Enabled",
        Info    = "Sends a Discord webhook when you steal a rare egg.",
        Default = false,
        Callback = function(val) senaV4Config.WebhookEnabled = val end,
    })

    WebhookSec:AddToggle({
        Name    = "Webhook On Disconnect",
        Info    = "Also sends a webhook when your account disconnects.",
        Default = false,
        Callback = function(val) senaV4Config.WebhookDisconnect = val end,
    })

    WebhookSec:AddInput({
        Name        = "Webhook URL",
        Info        = "Your Discord webhook URL.",
        Default     = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback    = function(val) senaV4Config.WebhookUrl = val end,
    })

    WebhookSec:AddMultiDropdown({
        Name    = "Webhook Rarities",
        Info    = "Only notify for these rarities.",
        Options = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Eternal", "Secret" },
        Default = { "Divine", "Eternal", "Secret" },
        Callback = function(val) senaV4Config.WebhookRarities = val end,
    })

    WebhookSec:AddInput({
        Name        = "Webhook Min Value",
        Info        = "Only notify for eggs worth this much per second or more.",
        Default     = "",
        Placeholder = "e.g. 500k, 2m, 1b",
        Callback    = function(val) senaV4Config.WebhookValue = val end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SERVER TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- Server Hop
    local HopSec = ServerTab:CreateSection("Server Hop")

    HopSec:AddToggle({
        Name    = "Hop When Nothing Matches",
        Info    = "Hop to the emptiest server when no egg matches your filters.",
        Default = false,
        Callback = function(val)
            senaV4Config.HopNoMatch = val
            local r = genv.__SenaV4HopRuntime
            if r and type(r.setHopNoMatch) == "function" then pcall(r.setHopNoMatch, r, val) end
        end,
    })

    HopSec:AddLabel("─── Limits ───")

    HopSec:AddSlider({
        Name    = "Hop Cooldown",
        Info    = "Seconds between auto hops and wait after rejoining.",
        Min     = 1,
        Max     = 60,
        Default = 5,
        Callback = function(val)
            senaV4Config.HopCooldown = val
            local r = genv.__SenaV4HopRuntime
            if r and type(r.setCooldown) == "function" then pcall(r.setCooldown, r, val) end
        end,
    })

    -- Find Private Server
    local PrivateSec = ServerTab:CreateSection("Find Private Server")

    PrivateSec:AddLabel("Now: " .. #Players:GetPlayers() .. " player(s) in this server.")

    PrivateSec:AddDropdown({
        Name    = "Max Players",
        Info    = "The most players you want in your server, you included. 2 (you + 1) is the easiest to find.",
        Options = { "1", "2", "3", "4", "5" },
        Default = "2",
        Callback = function(val)
            senaV4Config.PrivateServerMax = val
            local r = genv.__SenaV4HopRuntime
            if r and type(r.setPrivateMax) == "function" then pcall(r.setPrivateMax, r, tonumber(val)) end
        end,
    })

    PrivateSec:AddButton({
        Name    = "Hop Server Now",
        Info    = "Moves you to a quieter server right away.",
        Callback = function()
            local r = genv.__SenaV4HopRuntime
            if r and type(r.hopPrivateOnce) == "function" then
                task.spawn(function() pcall(r.hopPrivateOnce) end)
            end
            notify("Server", "Hopping to a quieter server...")
        end,
    })

    PrivateSec:AddToggle({
        Name    = "Auto Hop",
        Info    = "Keeps moving you to quieter servers until the player count is at or under your max.",
        Default = false,
        Callback = function(val)
            senaV4Config.PrivateServerAuto = val
            local r = genv.__SenaV4HopRuntime
            if r and type(r.setAutoHop) == "function" then pcall(r.setAutoHop, r, val) end
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════════════════════
--  SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════════════════════
do
    -- Performance
    local PerfSec = SettingsTab:CreateSection("Performance")

    PerfSec:AddToggle({
        Name    = "Startup Boost",
        Info    = "Lowers graphics when the script starts. Turn it off to get the graphics back; hidden pets and eggs return after a rejoin.",
        Default = false,
        Callback = function(val)
            senaV4Config.StartupBoost = val
            if val then
                game:GetService("Lighting").GlobalShadows = false
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            else
                game:GetService("Lighting").GlobalShadows = true
            end
        end,
    })

    PerfSec:AddToggle({
        Name    = "Boost FPS",
        Info    = "Removes extra map details and other players' plots for more FPS.",
        Default = false,
        Callback = function(val)
            senaV4Config.BoostFps = val
            local r = genv.__SenaV4FpsRuntime
            if r and type(r.setBoostFps) == "function" then pcall(r.setBoostFps, r, val) end
        end,
    })

    PerfSec:AddToggle({
        Name    = "Uncap FPS",
        Info    = "Raises the FPS cap to 1000.",
        Default = true,
        Callback = function(val)
            senaV4Config.UncapFps = val
            local setfpscap = rawget(_G, "setfpscap") or rawget(_G, "set_fps_cap")
            if type(setfpscap) == "function" then
                pcall(setfpscap, val and 1000 or 60)
            end
        end,
    })

    -- Guard
    local GuardSec = SettingsTab:CreateSection("Guard")

    GuardSec:AddToggle({
        Name    = "Anti Guard Knockback",
        Info    = "Cancels the knockback the Forest guard puts on you, so a hit never throws you off the lane.",
        Default = true,
        Callback = function(val)
            senaV4Config.AntiGuardKnockback = val
            local r = genv.__SenaV4GuardRuntime
            if r and type(r.setAntiKnockback) == "function" then pcall(r.setAntiKnockback, r, val) end
        end,
    })

    GuardSec:AddToggle({
        Name    = "Anti Hit Guard",
        Info    = "For eggs you pick up by hand. Pins you in the safe zone behind a look-alike clone until the guard goes back to sleep. Auto Steal has its own guard handling and always wins.",
        Default = false,
        Callback = function(val) senaV4Config.AntiHitGuard = val end,
    })

    -- Session
    local SessionSec = SettingsTab:CreateSection("Session")

    SessionSec:AddToggle({
        Name    = "Botting Mode",
        Info    = "Turns off 3D rendering and covers the screen in black. Everything keeps running, your GPU does not.",
        Default = false,
        Callback = function(val)
            senaV4Config.BottingMode = val
            if game:GetService("RunService"):IsClient() then
                local frame = game:GetService("CoreGui"):FindFirstChild("SenaBottingFrame")
                if val then
                    if not frame then
                        local sg = Instance.new("ScreenGui")
                        sg.Name = "SenaBottingFrame"
                        sg.ResetOnSpawn = false
                        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                        local f = Instance.new("Frame", sg)
                        f.Size = UDim2.fromScale(1, 1)
                        f.BackgroundColor3 = Color3.new(0, 0, 0)
                        f.BorderSizePixel = 0
                        f.ZIndex = 999
                        sg.Parent = game:GetService("CoreGui")
                    end
                    game:GetService("Lighting").GlobalShadows = false
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                else
                    if frame then frame:Destroy() end
                    game:GetService("Lighting").GlobalShadows = true
                end
            end
        end,
    })

    SessionSec:AddToggle({
        Name    = "Anti Cutscene",
        Info    = "Closes event cutscenes and the intro as soon as the game opens them, so nothing locks your camera.",
        Default = false,
        Callback = function(val) senaV4Config.AntiCutscene = val end,
    })

    SessionSec:AddButton({
        Name    = "Rejoin This Server",
        Info    = "Teleports you back into the exact server you are in now.",
        Callback = function()
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
            end)
        end,
    })

    SessionSec:AddButton({
        Name    = "Stop & Unload",
        Info    = "Turns every loop off and closes the hub. Run the script again to bring it back.",
        Callback = function()
            for k, _ in pairs(senaV4Config) do
                if type(senaV4Config[k]) == "boolean" then
                    senaV4Config[k] = false
                end
            end
            local shutdown = genv.__SenaV4HubShutdown
            if type(shutdown) == "function" then
                task.delay(0.2, function() pcall(shutdown) end)
            end
        end,
    })

    -- Player
    local PlayerSec = SettingsTab:CreateSection("Player")

    PlayerSec:AddToggle({
        Name    = "Anti AFK",
        Info    = "Blocks the game's idle kick while the script runs.",
        Default = true,
        Callback = function(val)
            senaV4Config.AntiAfk = val
            local VirtualUser = game:GetService("VirtualUser")
            if val then
                localPlayer.Idled:Connect(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end
        end,
    })

    PlayerSec:AddToggle({
        Name    = "Auto Reconnect",
        Info    = "Automatically reconnects you back to the server upon kick or disconnect.",
        Default = true,
        Callback = function(val)
            senaV4Config.AutoReconnect = val
            if val then
                game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
                    if state == Enum.TeleportState.Failed then
                        task.wait(5)
                        pcall(TeleportService.Teleport, TeleportService, game.PlaceId, localPlayer)
                    end
                end)
            end
        end,
    })

    PlayerSec:AddToggle({
        Name    = "Auto Execute (Rejoin)",
        Info    = "Prepares the bootstrapper so the script runs automatically after teleport or reconnect.",
        Default = false,
        Callback = function(val)
            senaV4Config.AutoExecute = val
            local queueOnTeleport = rawget(_G, "queue_on_teleport") or rawget(_G, "queueonteleport")
            if val and type(queueOnTeleport) == "function" then
                pcall(queueOnTeleport, "-- Sovereign Hub auto re-execute placeholder")
            end
        end,
    })
end

-- ─── Shutdown handler ─────────────────────────────────────────────────────────
genv.__SenaV4HubShutdown = function()
    for _, key in ipairs({ "AutoSteal", "AutoPlace", "AutoHatch", "AutoMutation", "AutoRingEvent", "AutoSell", "AutoSellEgg", "StealPlayers", "ScrambleBossAuto", "RaceAuto", "RaceClaim", "RaceBuy", "StarAutoCatch", "ButterflyAutoCatch", "ButterflyAutoNet", "ButterflyAutoTrade", "ButterflyAutoCraft" }) do
        senaV4Config[key] = false
    end
    -- Destroy Wind UI
    pcall(function() WindUI:Destroy() end)
end

-- ─── Anti-AFK heartbeat (immediate, lightweight) ─────────────────────────────
task.spawn(function()
    while sessionAlive() do
        task.wait(60)
        if senaV4Config.AntiAfk then
            pcall(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end
    end
end)

-- ─── FPS uncap on load ────────────────────────────────────────────────────────
do
    local setfpscap = rawget(_G, "setfpscap") or rawget(_G, "set_fps_cap")
    if type(setfpscap) == "function" then pcall(setfpscap, 1000) end
end

print("[Sovereign Hub] Hub loaded via Wind UI — discord.gg/sovereignhub")
