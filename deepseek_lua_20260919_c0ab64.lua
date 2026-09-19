--[[
    SP Hub | Murder Mystery 2 | Refactored with HoneyLua UI
    Original by: fancy (https://discord.gg/SRvRc2XF6s)
    UI Refactored to HoneyLua (Local, no external UI loading)
    
    NOTE: Semua fitur lama tetap ada, hanya UI yang diganti.
    Tabs: Info | Key | Main | Player | Kill | Teleports | Setting
]]

-- ============================================================
--  HONEYLUA UI LIBRARY (LOCAL - TIDAK LOAD DARI URL)
-- ============================================================
if getgenv().HoneyLuaLoaded then 
    pcall(function() 
        if getgenv().HoneyLuaUI and getgenv().HoneyLuaUI.UI and getgenv().HoneyLuaUI.UI.screenGui then
            getgenv().HoneyLuaUI.UI.screenGui:Destroy()
        end
    end)
end
getgenv().HoneyLuaLoaded = true

local HoneyPlayers = game:GetService("Players")
local HoneyHttpService = game:GetService("HttpService")
local HoneyRunService = game:GetService("RunService")
local HoneyUserInputService = game:GetService("UserInputService")
local HoneyTweenService = game:GetService("TweenService")
local HoneySoundService = game:GetService("SoundService")

local honeyLocalPlayer = HoneyPlayers.LocalPlayer
local honeyGameId = tostring(game.PlaceId)

local HoneyFS = {
    writefile = writefile, readfile = readfile, isfile = isfile, isfolder = isfolder,
    makefolder = makefolder, listfiles = listfiles, delfile = delfile
}

local function honeyEnsureExecutorFS()
    for name, fn in pairs(HoneyFS) do
        if type(fn) ~= "function" then
            if name ~= "delfile" then
                -- Fallback silently if executor FS not available
                HoneyFS[name] = nil
            end
        end
    end
end
honeyEnsureExecutorFS()

local HONEY_ROOT = "SPHub_MM2"
local HONEY_GAMES = HONEY_ROOT .. "/Games"
local HONEY_CONFIG = HONEY_GAMES .. "/" .. honeyGameId
local HONEY_SETTINGS = HONEY_ROOT .. "/settings.json"
local HONEY_CHANGELOG = HONEY_ROOT .. "/changelog.json"

pcall(function()
    if HoneyFS.isfolder and not HoneyFS.isfolder(HONEY_ROOT) then HoneyFS.makefolder(HONEY_ROOT) end
    if HoneyFS.isfolder and not HoneyFS.isfolder(HONEY_GAMES) then HoneyFS.makefolder(HONEY_GAMES) end
    if HoneyFS.isfolder and not HoneyFS.isfolder(HONEY_CONFIG) then HoneyFS.makefolder(HONEY_CONFIG) end
end)

local HONEY_DEFAULT_SETTINGS = {
    autoLoad = true, autoSave = true, autoSaveInterval = 30,
    uiWidth = 560, uiHeight = 440,
    transparent = false, animatedBg = true, openKey = "RightControl", showMobileBtn = true,
    defaultConfigs = {},
    scriptName = "SP Hub",
    scriptVersion = "1.3",
    scriptOwner = "SP Hub",
    theme = "Honey"
}

local HONEY_DEFAULT_CHANGELOG = {
    "🚀 SP Hub MM2 v1.3 Loaded",
    "✨ ESP, Aimbot, AutoFarm, Fling & more",
    "🛡️ Anti-Void & Anti-Fling Protection",
    "🎨 New HoneyLua UI (Local, no external URL)",
    "⚡ Optimized Performance & Smooth Animation"
}

local function honeyDecode(p, f)
    local ok, d = pcall(function() return HoneyHttpService:JSONDecode(p) end)
    return (ok and type(d) == "table") and d or f
end
local function honeyEncode(p) return HoneyHttpService:JSONEncode(p) end
local function honeyReadSettings()
    if HoneyFS.isfile and HoneyFS.isfile(HONEY_SETTINGS) then
        return honeyDecode(HoneyFS.readfile(HONEY_SETTINGS), HONEY_DEFAULT_SETTINGS)
    end
    return HONEY_DEFAULT_SETTINGS
end
local function honeyWriteSettings(s)
    if HoneyFS.writefile then pcall(HoneyFS.writefile, HONEY_SETTINGS, honeyEncode(s)) end
end
local function honeyConfigPath(n) return HONEY_CONFIG .. "/" .. n .. ".json" end
local function honeyReadConfig(n)
    local p = honeyConfigPath(n)
    if HoneyFS.isfile and HoneyFS.isfile(p) then
        return honeyDecode(HoneyFS.readfile(p), {})
    end
    return {}
end
local function honeyWriteConfig(n, d)
    if HoneyFS.writefile then pcall(HoneyFS.writefile, honeyConfigPath(n), honeyEncode(d)) end
end
local function honeyResetConfig(n) honeyWriteConfig(n, {}); return {} end
local function honeyDeleteConfig(n)
    if HoneyFS.delfile and HoneyFS.isfile and HoneyFS.isfile(honeyConfigPath(n)) then
        pcall(function() HoneyFS.delfile(honeyConfigPath(n)) end)
    end
end

local honeySettings = honeyReadSettings()
for k, v in pairs(HONEY_DEFAULT_SETTINGS) do
    if honeySettings[k] == nil then honeySettings[k] = v end
end
honeySettings.scriptName = HONEY_DEFAULT_SETTINGS.scriptName
honeySettings.scriptOwner = HONEY_DEFAULT_SETTINGS.scriptOwner
honeyWriteSettings(honeySettings)
if not honeySettings.defaultConfigs then honeySettings.defaultConfigs = {} end

-- ===== CENTRALIZED THEME SYSTEM =====
local HoneyThemeManager = { Themes = {}, Current = honeySettings.theme or "Honey" }
local function honeyMakeTheme(a, b, s, e, t, m, br)
    local C = Color3.fromRGB
    return {
        Background = C(table.unpack(b)),
        Surface = C(table.unpack(s)),
        SurfaceSecondary = C(table.unpack(s)),
        Element = C(table.unpack(e)),
        ElementHover = C(math.min(e[1]+12,255), math.min(e[2]+12,255), math.min(e[3]+12,255)),
        ElementActive = C(math.min(e[1]+20,255), math.min(e[2]+20,255), math.min(e[3]+20,255)),
        Accent = C(table.unpack(a)),
        AccentHover = C(math.min(a[1]+25,255), math.min(a[2]+25,255), math.min(a[3]+25,255)),
        AccentSoft = C(math.floor(a[1]*.55), math.floor(a[2]*.55), math.floor(a[3]*.55)),
        Text = C(table.unpack(t)),
        TextSecondary = C(table.unpack(t)),
        TextMuted = C(table.unpack(m)),
        Border = C(table.unpack(br)),
        Divider = C(table.unpack(br)),
        Success = C(90, 205, 125),
        Warning = C(245, 175, 75),
        Error = C(220, 90, 90),
        Info = C(100, 175, 235),
        NotificationBackground = C(table.unpack(s)),
        NotificationBorder = C(table.unpack(a)),
        NotificationProgress = C(table.unpack(a)),
        Overlay = C(0, 0, 0),
        Shadow = C(8, 6, 5),
        Glow = C(table.unpack(a))
    }
end
HoneyThemeManager.Themes.Honey = honeyMakeTheme({255,190,80},{25,22,18},{35,30,25},{50,43,35},{255,245,225},{180,160,130},{210,160,80})
HoneyThemeManager.Themes.Midnight = honeyMakeTheme({128,157,255},{16,19,30},{25,30,46},{40,47,68},{238,242,255},{139,151,187},{111,136,220})
HoneyThemeManager.Themes.Ocean = honeyMakeTheme({70,205,210},{12,25,31},{18,40,49},{29,62,74},{230,253,250},{122,174,177},{63,168,174})
HoneyThemeManager.Themes.Purple = honeyMakeTheme({194,126,255},{24,16,32},{39,25,50},{65,40,79},{250,239,255},{168,136,184},{165,104,219})
HoneyThemeManager.Themes.Crimson = honeyMakeTheme({244,105,116},{31,14,19},{49,22,29},{78,34,43},{255,237,238},{186,130,136},{211,82,96})
HoneyThemeManager.Themes.Emerald = honeyMakeTheme({86,218,151},{11,27,22},{18,44,34},{29,70,52},{229,255,240},{119,177,143},{71,179,123})
HoneyThemeManager.Themes.Rose = honeyMakeTheme({244,133,181},{31,17,25},{50,27,40},{80,42,64},{255,239,247},{190,139,166},{216,105,158})
HoneyThemeManager.Themes.Monochrome = honeyMakeTheme({225,225,230},{19,19,21},{30,30,33},{48,48,53},{245,245,247},{143,143,151},{165,165,174})
if not HoneyThemeManager.Themes[HoneyThemeManager.Current] then HoneyThemeManager.Current = "Honey" end

function HoneyThemeManager:GetTheme() return self.Themes[self.Current] end
function HoneyThemeManager:GetThemes()
    local t = {}
    for n in pairs(self.Themes) do table.insert(t, n) end
    table.sort(t)
    return t
end
function HoneyThemeManager:GetColor(k)
    return self:GetTheme()[k] or self.Themes.Honey[k] or Color3.new(1,1,1)
end
local function HT(k) return HoneyThemeManager:GetColor(k) end

-- ============================================================
--  SP HUB ORIGINAL LOGIC (TETAP SAMA)
-- ============================================================
local t1 = {}
local v8, v9, v309
do
    local v23, v26, v27, v178
    do
        local v16
        do
            local v143
            do
                local v79, v127, v129, v131
                do
                    local v105, v107
                    do
                        local v3, v13
                        do
                            local v66
                            do
                                local v2 = unpack or table.unpack

                                t1.value1 = "SPHub_FirstTime.txt"
                                getgenv().SPHubIsFirstTime = false
                                pcall(function()
                                    if not isfile(t1.value1) then
                                        getgenv().SPHubIsFirstTime = true
                                        writefile(t1.value1, "played")
                                    end
                                end)

                                if type(getgenv().SPHub_MM2_Cleanup) == "function" then
                                    pcall(getgenv().SPHub_MM2_Cleanup)
                                end

                                t1.value2 = nil
                                t1.value3 = game.Players.LocalPlayer
                                t1.value4 = game:GetService("HttpService")
                                t1.value5 = {
                                    API_URL = "https://sphub.lol/api/check",
                                    GET_KEY_URL = "https://sphub.lol/get-key",
                                    KEY_FILE = "sphub_key.txt",
                                    savedKey = ""
                                }

                                function t1.value6()
                                    if type(request) == "function" then return request end
                                    if type(http_request) == "function" then return http_request end
                                    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
                                    if type(http) == "table" and type(http.request) == "function" then return http.request end
                                    return nil
                                end

                                function t1.value7(p1)
                                    local _tostring = tostring
                                    if not p1 then p1 = "" end
                                    local v352 = _tostring(p1):gsub("%s+", "")
                                    if v352 == "" then return false, "No Key", "Please enter a key" end
                                    local ClientId = game:GetService("RbxAnalyticsService"):GetClientId()
                                    local value3Name = t1.value3.Name
                                    local t2 = { key = v352, hwid = ClientId, user_id = value3Name }
                                    local u356 = t2
                                    local ok, result = pcall(function()
                                        local v1344 = t1.value6()
                                        if not v1344 then return nil end
                                        local API_URL = t1.value5.API_URL
                                        local t3 = { ["Content-Type"] = "application/json" }
                                        local json = t1.value4:JSONEncode(u356)
                                        return v1344({ Url = API_URL, Method = "POST", Headers = t3, Body = json })
                                    end)
                                    local v359 = result
                                    if not ok or not v359 then return false, "Connection Error", "Failed to contact verification server" end
                                    local ok2, result2 = pcall(function() return t1.value4:JSONDecode(v359.Body) end)
                                    local v362 = not ok2
                                    if not v362 then v362 = not result2 end
                                    if v362 then return false, "Decode Error", "Failed to parse API response" end
                                    if result2.valid then
                                        return true, result2.expires_formatted or "Unknown", result2.expires or 0
                                    end
                                    return false, tostring(result2.reason or "Invalid"), tostring(result2.error or "Invalid Key")
                                end

                                pcall(function()
                                    if isfile(t1.value5.KEY_FILE) then
                                        t1.value5.savedKey = readfile(t1.value5.KEY_FILE)
                                    end
                                end)

                                if getgenv().SPHub_MM2_Cleanup then
                                    pcall(function() getgenv().SPHub_MM2_Cleanup() end)
                                end

                                t1.value8 = nil
                                t1.value9 = {}
                                t1.value10 = {}

                                function t1.value11(p2) table.insert(t1.value9, p2) end

                                t1.value12 = {}

                                function v3()
                                    for v371, v372 in pairs(t1.value12) do
                                        local v373 = v371
                                        local v374 = v372
                                        pcall(function()
                                            if v373 and v373.Parent then
                                                v373.Size = v374.Size
                                                v373.Transparency = v374.Transparency
                                                v373.CanCollide = v374.CanCollide
                                                local SPHub_HitboxBox = v373:FindFirstChild("SPHub_HitboxBox")
                                                if SPHub_HitboxBox then SPHub_HitboxBox:Destroy() end
                                            end
                                        end)
                                    end
                                    table.clear(t1.value12)
                                    for _, player in ipairs(game.Players:GetPlayers()) do
                                        local v377 = player
                                        pcall(function()
                                            if v377.Character then
                                                for _, child in ipairs(v377.Character:GetChildren()) do
                                                    if child:IsA("BasePart") then
                                                        local SPHub_HitboxBox = child:FindFirstChild("SPHub_HitboxBox")
                                                        if SPHub_HitboxBox then SPHub_HitboxBox:Destroy() end
                                                    end
                                                end
                                            end
                                        end)
                                    end
                                end

                                function t1.value13()
                                    for _, player in ipairs(game.Players:GetPlayers()) do
                                        local v367 = player
                                        pcall(function()
                                            if v367.Character then
                                                local SPHub_NameTag = v367.Character:FindFirstChild("SPHub_NameTag")
                                                if SPHub_NameTag then SPHub_NameTag:Destroy() end
                                            end
                                        end)
                                    end
                                end

                                t1.value8 = nil
                                t1.value14 = nil
                                t1.value15 = nil

                                function t1.value16()
                                    if t1.value8 then return end
                                    t1.value8 = game:GetService("RunService").RenderStepped:Connect(function()
                                        local LocalPlayer = game.Players.LocalPlayer
                                        local Character = LocalPlayer.Character
                                        local v1355 = Character and Character:FindFirstChild("HumanoidRootPart")
                                        local v1356 = getMurderer and getMurderer()
                                        local v1357 = getSheriff and getSheriff()
                                        local v1358 = getHero and getHero()
                                        for _, player in ipairs(game.Players:GetPlayers()) do
                                            if player ~= LocalPlayer and player.Character then
                                                local Character2 = player.Character
                                                local SPHub_NameTag = Character2:FindFirstChild("SPHub_NameTag")
                                                local v1363 = SPHub_NameTag and SPHub_NameTag:FindFirstChild("Label")
                                                local v1364 = SPHub_NameTag and SPHub_NameTag:FindFirstChild("RoleLabel")
                                                if v1363 then
                                                    local v1365 = isLivingInGamePlayer and isLivingInGamePlayer(player)
                                                    local v1366 = v1365
                                                    local Backpack = player:FindFirstChild("Backpack")
                                                    if v1365 then
                                                        v1366 = player == v1356 or (Backpack and Backpack:FindFirstChild("Knife") or Character2:FindFirstChild("Knife"))
                                                    end
                                                    local v1368 = v1365 and player == v1358
                                                    local v1369 = v1365 and (player == v1357 and not v1368)
                                                    if v1365 and (not v1366 and (not v1369 and not v1368)) and (Backpack and Backpack:FindFirstChild("Gun") or (Backpack:FindFirstChild("Revolver") or (Character2:FindFirstChild("Gun") or Character2:FindFirstChild("Revolver")))) then
                                                        v1368 = true
                                                    end
                                                    if v1364 then
                                                        if v1366 then
                                                            v1364.Text = "[" .. T("Murderer") .. "]"
                                                            v1364.TextColor3 = Color3.fromRGB(255, 0, 0)
                                                            v1364.Visible = true
                                                        elseif v1369 then
                                                            v1364.Text = "[" .. T("Sheriff") .. "]"
                                                            v1364.TextColor3 = Color3.fromRGB(0, 0, 255)
                                                            v1364.Visible = true
                                                        elseif v1368 then
                                                            v1364.Text = "[" .. T("Hero") .. "]"
                                                            v1364.TextColor3 = Color3.fromRGB(255, 215, 0)
                                                            v1364.Visible = true
                                                        else
                                                            v1364.Text = ""
                                                            v1364.Visible = false
                                                        end
                                                    end
                                                    local v1370 = player.DisplayName or player.Name
                                                    local HumanoidRootPart = Character2:FindFirstChild("HumanoidRootPart")
                                                    if v1355 and HumanoidRootPart then
                                                        local v1372 = math.floor((v1355.Position - HumanoidRootPart.Position).Magnitude)
                                                        v1363.Text = string.format("%s [%dm]", v1370, v1372)
                                                    else
                                                        v1363.Text = v1370
                                                    end
                                                end
                                            end
                                        end
                                    end)
                                    t1.value11(t1.value8)
                                end

                                function t1.value17()
                                    if t1.value8 then
                                        pcall(function() t1.value8:Disconnect() end)
                                        t1.value8 = nil
                                    end
                                end

                                t1.value18 = nil
                                t1.value19 = nil
                                t1.value20 = nil

                                function t1.value21()
                                    local LocalPlayer = game.Players.LocalPlayer
                                    local RunService = game:GetService("RunService")
                                    local n1 = 0
                                    if t1.value18 then t1.value18:Disconnect() end
                                    if t1.value19 then t1.value19:Disconnect() end
                                    if t1.value20 then t1.value20:Disconnect() end
                                    local vector3 = Vector3.new(0, 0, 0)
                                    RunService.Heartbeat:Connect(function()
                                        local Character = LocalPlayer.Character
                                        local v1374 = Character and Character:FindFirstChild("HumanoidRootPart")
                                        if v1374 then
                                            vector3 = v1374.Velocity
                                            v1374.Velocity = vector3 * 10000 + Vector3.new(0, 10000, 0)
                                            if t1.value2.FlingSpinning ~= false then
                                                n1 = (n1 + 120) % 360
                                                v1374.CFrame = v1374.CFrame * CFrame.Angles(0, math.rad(n1), 0)
                                            end
                                        end
                                    end)
                                    RunService.RenderStepped:Connect(function()
                                        local Character = LocalPlayer.Character
                                        local v1376 = Character and Character:FindFirstChild("HumanoidRootPart")
                                        if v1376 then v1376.Velocity = vector3 end
                                    end)
                                    RunService.Stepped:Connect(function()
                                        local Character = LocalPlayer.Character
                                        local v1378 = Character and Character:FindFirstChild("HumanoidRootPart")
                                        if v1378 then v1378.Velocity = vector3 + Vector3.new(0, 0.1, 0) end
                                    end)
                                end

                                function t1.value22(p3)
                                    local v379 = not p3
                                    if v379 then
                                        v379 = t1.value2.FlingTouchActive
                                        if not v379 then
                                            v379 = t1.value2.FlingPlayerActive
                                            if not v379 then
                                                v379 = t1.value2.FlingMurdererActive or (t1.value2.FlingSheriffActive or t1.value2.AutoFlingAll)
                                            end
                                        end
                                    end
                                    if v379 then return end
                                    if t1.value18 then t1.value18:Disconnect(); t1.value18 = nil end
                                    if t1.value19 then t1.value19:Disconnect(); t1.value19 = nil end
                                    if t1.value20 then t1.value20:Disconnect(); t1.value20 = nil end
                                    local Character = game.Players.LocalPlayer.Character
                                    local v381 = Character and Character:FindFirstChild("HumanoidRootPart")
                                    if v381 then v381.Velocity = Vector3.new(0, 0, 0) end
                                end

                                getgenv().SPHub_MM2_Cleanup = function()
                                    pcall(function() t1.value22(true) end)
                                    if t1.value8 then pcall(function() t1.value8:Disconnect() end); t1.value8 = nil end
                                    pcall(v3)
                                    pcall(t1.value13)
                                    if getgenv().SPHub_FasterKillGui then
                                        pcall(function() getgenv().SPHub_FasterKillGui:Destroy() end)
                                        getgenv().SPHub_FasterKillGui = nil
                                    end
                                    pcall(function() if mapSafePlatform then mapSafePlatform:Destroy() end end)
                                    for v388, v389 in ipairs(t1.value9) do
                                        local v390 = v389
                                        pcall(function() v390:Disconnect() end)
                                    end
                                    for _, v in ipairs(t1.value10) do
                                        getgenv()[v] = false
                                    end
                                    for v395, v396 in ipairs(game.Players:GetPlayers()) do
                                        if v396.Character then
                                            local SPHub_ESP = v396.Character:FindFirstChild("SPHub_ESP")
                                            if SPHub_ESP then pcall(function() SPHub_ESP:Destroy() end) end
                                        end
                                    end
                                    local GunDrop = workspace:FindFirstChild("GunDrop", true)
                                    if GunDrop then
                                        local SPHub_GunHighlight = GunDrop:FindFirstChild("SPHub_GunHighlight")
                                        if SPHub_GunHighlight then pcall(function() SPHub_GunHighlight:Destroy() end) end
                                        local SPHub_GunTag = GunDrop:FindFirstChild("SPHub_GunTag")
                                        if SPHub_GunTag then pcall(function() SPHub_GunTag:Destroy() end) end
                                    end
                                    if getgenv().clearCoinESPGlobally then pcall(getgenv().clearCoinESPGlobally) end
                                    pcall(function() if toggleXray then toggleXray(false) end end)
                                    pcall(function() if toggleSuperLagReducer then toggleSuperLagReducer(false) end end)
                                    pcall(function() if t1.value15 then t1.value15:Disconnect(); t1.value15 = nil end end)
                                    if getgenv().clearTracersGlobally then pcall(getgenv().clearTracersGlobally) end
                                    pcall(function()
                                        local Character = game.Players.LocalPlayer.Character
                                        local v1380 = Character and Character:FindFirstChildOfClass("Humanoid")
                                        local CurrentCamera = workspace.CurrentCamera
                                        if v1380 then CurrentCamera.CameraSubject = v1380 end
                                        if getgenv().SPHubCameraPart then getgenv().SPHubCameraPart:Destroy() end
                                        if getgenv().SPHubModalGui then getgenv().SPHubModalGui:Destroy() end
                                        if getgenv().SPHubSpeedGui then getgenv().SPHubSpeedGui:Destroy() end
                                        if Character and Character:FindFirstChild("HumanoidRootPart") then
                                            Character.HumanoidRootPart.Anchored = false
                                        end
                                        pcall(function()
                                            local SPHub_AuraRange = workspace:FindFirstChild("SPHub_AuraRange")
                                            if SPHub_AuraRange then SPHub_AuraRange:Destroy() end
                                        end)
                                    end)
                                    if getgenv().clearTrapESPGlobally then pcall(getgenv().clearTrapESPGlobally) end
                                    print("[SP Hub] Previous script session cleaned up successfully.")
                                end

                                t1.value23 = false
                                t1.value24 = false

                                do
                                    local v4 = getgenv().SP_Hub_Language or "en"
                                    local t4 = { Innocent = true, Sheriff = true, Murderer = true }
                                    local t5 = { Innocent = true, Sheriff = true, Murderer = true }
                                    local t6 = { Murderer = true, Sheriff = true, Innocents = true }
                                    t1.value2 = {
                                        CurrentLanguage = v4,
                                        RolesESP = false,
                                        ESPRoles = t4,
                                        TracerRoles = t5,
                                        GunESP = false,
                                        TracersEnabled = false,
                                        AimbotEnabled = false,
                                        AutoGrabGun = false,
                                        AutoFarmCoins = false,
                                        AutoFarmMode = "Tween",
                                        AutoFarmWalkSpeed = 30,
                                        PlayerSpeedEnabled = false,
                                        PlayerJumpPowerEnabled = false,
                                        WalkSpeed = 16,
                                        JumpPower = 50,
                                        Noclip = false,
                                        FlyEnabled = false,
                                        FlySpeed = 50,
                                        AntiVoid = false,
                                        MurdererAutoKill = false,
                                        CoinFarmSpeed = 35,
                                        AutoKillMurder = false,
                                        AutoKillMurderMode = "Shoot Visible",
                                        ShootOnlyWhenKnifeEquipped = false,
                                        FasterKillMurderButton = false,
                                        MurdererAutoKillMode = "Teleport to Everyone",
                                        HitboxExpander = false,
                                        HitboxSize = 3,
                                        HitboxRoles = t6,
                                        SmartHitbox = false,
                                        LinkBehindMurder = false,
                                        RainbowGun = false,
                                        AutoFlingAll = false,
                                        DroppedGunAlert = true,
                                        NamesESP = false,
                                        FlingTargetPlayer = "",
                                        FlingPlayerActive = false,
                                        FlingMurdererActive = false,
                                        FlingSheriffActive = false,
                                        FlingTouchActive = false,
                                        FlingSpinning = true,
                                        XrayEnabled = false,
                                        SuperLagReducer = false,
                                        originalFov = 70,
                                        InfiniteJumpEnabled = false,
                                        FPSBooster = false,
                                        DisableShadows = false,
                                        SmoothPlastic = false,
                                        KillAuraEnabled = false,
                                        KillAuraRange = 15,
                                        ShowAuraCircle = false,
                                        TrapESP = false,
                                        AdvancedPrediction = true,
                                        ShootPositionOffset = 2.8,
                                        OffsetToPingMult = 1,
                                        MotionAimVisualizer = false,
                                        MotionAimVisualizerForMouse = false,
                                        FasterGrabGunButton = false,
                                        MobileButtonsSize = 50
                                    }
                                end

                                getgenv().SPHub_MotionAimLogs = {}
                                t1.value25 = nil
                                t1.value26 = nil
                                t1.value25 = {}
                                pcall(function()
                                    task.spawn(function()
                                        local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
                                        local v1383 = Remotes and Remotes:WaitForChild("Gameplay", 5)
                                        local v1384 = v1383 and v1383:WaitForChild("PlayerDataChanged", 5)
                                        if v1384 and v1384:IsA("RemoteEvent") then
                                            v1384.OnClientEvent:Connect(function(p4)
                                                if type(p4) == "table" then t1.value25 = p4 end
                                            end)
                                        end
                                    end)
                                end)

                                -- ===== TRANSLATOR (Tidak load dari URL - pakai fallback lokal) =====
                                t1.value27 = nil
                                _G.SP_Hub_TKeys = {}

                                function _G.SP_Hub_Translator(p5)
                                    local _tostring = tostring
                                    if not p5 then p5 = "" end
                                    return _tostring(p5)
                                end

                                function v8(p6)
                                    local _tostring = tostring
                                    if not p6 then p6 = "" end
                                    local v409 = _tostring(p6)
                                    local v410 = _G.SP_Hub_Translator(v409)
                                    _G.SP_Hub_TKeys[tostring(v410)] = v409
                                    _G.SP_Hub_TKeys[v409] = v409
                                    return v410
                                end

                                -- ===== HONEYLUA UI DI SINI (GANTI SPLIB v2) =====
                                t1.value28 = nil -- placeholder (dulu SPLib v2)
                                t1.value29 = {}

                                function v9(p7, p8, _)
                                    local v434 = p7
                                    local _tostring = tostring
                                    if not p7 then v434 = "" end
                                    local v436 = _tostring(v434)
                                    local v437 = p8
                                    local _tostring2 = tostring
                                    if not p8 then v437 = "" end
                                    local v439 = v436 .. "::" .. _tostring2(v437)
                                    local timestamp = tick()
                                    if t1.value29[v439] and timestamp - t1.value29[v439] < 3 then return end
                                    t1.value29[v439] = timestamp
                                    local str = tostring(p7 or "SP Hub")
                                    local _tostring3 = tostring
                                    if not p8 then p8 = "" end
                                    local v443 = _tostring3(p8)
                                    if HoneyUI and HoneyUI.Notify then
                                        HoneyUI.Notify({ text = v443, title = str, duration = 3 })
                                    end
                                end

                                -- ===== HELPER FUNCTIONS (Semua original) =====
                                function t1.value30(p10)
                                    if typeof(p10) == "Instance" and p10:IsA("Player") then return p10 end
                                    local v423 = p10
                                    local _tostring = tostring
                                    if not p10 then v423 = "" end
                                    local v425 = _tostring(v423)
                                    local v426 = game.Players:FindFirstChild(v425)
                                    if v426 then return v426 end
                                    local num = tonumber(p10)
                                    if num then
                                        local PlayerByUserId = game.Players:GetPlayerByUserId(num)
                                        if PlayerByUserId then return PlayerByUserId end
                                    end
                                    for _, player in ipairs(game.Players:GetPlayers()) do
                                        if v425 == player.Name or (v425 == player.DisplayName or v425 == tostring(player.UserId)) then
                                            return player
                                        end
                                    end
                                    return nil
                                end

                                function t1.value31(p11)
                                    if not p11 or not p11.Character then return false end
                                    local HumanoidRootPart = p11.Character:FindFirstChild("HumanoidRootPart")
                                    if not HumanoidRootPart then return false end
                                    local v413 = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("RegularLobby")
                                    if v413 then
                                        local ok, result, v416 = pcall(function() return v413:GetBoundingBox() end)
                                        if ok then ok = result and v416 end
                                        if ok then
                                            local v417 = result:PointToObjectSpace(HumanoidRootPart.Position)
                                            if math.abs(v417.X) <= v416.X / 2 + 10 and (math.abs(v417.Y) <= v416.Y / 2 + 15 and math.abs(v417.Z) <= v416.Z / 2 + 10) then
                                                return true
                                            end
                                        end
                                    end
                                    if HumanoidRootPart.Position.Y > 400 then return true end
                                    return false
                                end

                                t1.value32 = nil
                                function t1.value32(p12)
                                    if not p12 or (typeof(p12) ~= "Instance" or not p12:IsA("Player")) then return false end
                                    local Character = p12.Character
                                    if not Character then return false end
                                    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                                    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                    local v474 = not Humanoid
                                    if not v474 then
                                        v474 = true
                                        if not (Humanoid.Health <= 0) then v474 = not HumanoidRootPart end
                                    end
                                    if v474 then return false end
                                    if t1.value31(p12) then return false end
                                    return true
                                end

                                t1.value33 = nil
                                function t1.value33()
                                    local v475, v476, v477 = ipairs(game.Players:GetPlayers())
                                    local v478
                                    repeat
                                        repeat
                                            v477, v478 = v475(v476, v477)
                                            if not v477 then
                                                if t1.value25 and type(t1.value25) == "table" then
                                                    for k, v in pairs(t1.value25) do
                                                        if not (type(v) == "table" and v.Role == "Murderer") then continue end
                                                        local v481 = t1.value30(k)
                                                        if v481 and t1.value32(v481) then return v481 end
                                                    end
                                                end
                                                return nil
                                            end
                                        until t1.value32(v478)
                                        local Backpack = v478:FindFirstChild("Backpack")
                                    until Backpack and Backpack:FindFirstChild("Knife") or v478.Character:FindFirstChild("Knife")
                                    return v478
                                end

                                function t1.value34()
                                    local v462, v463, v464 = ipairs(game.Players:GetPlayers())
                                    local v465
                                    repeat
                                        repeat
                                            v464, v465 = v462(v463, v464)
                                            if not v464 then
                                                if t1.value25 and type(t1.value25) == "table" then
                                                    for k, v in pairs(t1.value25) do
                                                        if not (type(v) == "table" and v.Role == "Sheriff") then continue end
                                                        local v468 = t1.value30(k)
                                                        if v468 and t1.value32(v468) then return v468 end
                                                    end
                                                end
                                                return nil
                                            end
                                        until t1.value32(v465)
                                        local Backpack = v465:FindFirstChild("Backpack")
                                    until Backpack and Backpack:FindFirstChild("Gun") or (Backpack:FindFirstChild("Revolver") or (v465.Character:FindFirstChild("Gun") or v465.Character:FindFirstChild("Revolver")))
                                    return v465
                                end

                                local value124, v57
                                do
                                    local v28
                                    do
                                        local function v10()
                                            local v486 = t1.value34()
                                            local v487, v488, v489 = ipairs(game.Players:GetPlayers())
                                            local v490
                                            repeat
                                                repeat
                                                    v489, v490 = v487(v488, v489)
                                                    if not v489 then
                                                        if t1.value25 and type(t1.value25) == "table" then
                                                            for k, v in pairs(t1.value25) do
                                                                if not (type(v) == "table" and v.Role == "Hero") then continue end
                                                                local v493 = t1.value30(k)
                                                                if v493 and t1.value32(v493) then return v493 end
                                                            end
                                                        end
                                                        return nil
                                                    end
                                                until v490 ~= v486 and t1.value32(v490)
                                                local Backpack = v490:FindFirstChild("Backpack")
                                            until Backpack and Backpack:FindFirstChild("Gun") or (Backpack:FindFirstChild("Revolver") or (v490.Character:FindFirstChild("Gun") or v490.Character:FindFirstChild("Revolver")))
                                            return v490
                                        end

                                        function t1.value35()
                                            local v483 = t1.value33()
                                            if v483 and (v483.Character and v483.Character:FindFirstChild("HumanoidRootPart")) then
                                                local Character = game.Players.LocalPlayer.Character
                                                local v485 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                if v485 then
                                                    return (v485.Position - v483.Character.HumanoidRootPart.Position).Magnitude
                                                end
                                            end
                                            return 9999
                                        end

                                        getgenv().SPHub_HL_Refresher_Loop = true
                                        do
                                            local insert = table.insert
                                            local value10 = t1.value10
                                            t1.value36 = nil
                                            t1.value37 = nil
                                            t1.value38 = nil
                                            insert(value10, "SPHub_HL_Refresher_Loop")
                                        end

                                        task.spawn(function()
                                            while task.wait(0.5) and getgenv().SPHub_HL_Refresher_Loop do
                                                if t1.value2.RolesESP or t1.value2.NamesESP then
                                                    local v504 = t1.value33()
                                                    local v505 = t1.value34()
                                                    local v506 = v10()
                                                    for _, player in ipairs(game.Players:GetPlayers()) do
                                                        local v509 = player
                                                        pcall(function()
                                                            if v509 ~= game.Players.LocalPlayer and v509.Character then
                                                                local Character = v509.Character
                                                                local v1404 = t1.value32(v509)
                                                                local Backpack = v509:FindFirstChild("Backpack")
                                                                local v1406 = v1404
                                                                if v1404 then
                                                                    v1406 = v509 == v504 or (Backpack and Backpack:FindFirstChild("Knife") or Character:FindFirstChild("Knife"))
                                                                end
                                                                local v1407 = v1404 and v509 == v506
                                                                local v1408 = v1404 and (v509 == v505 and not v1407)
                                                                if v1404 and (not v1406 and (not v1408 and not v1407)) and (Backpack and Backpack:FindFirstChild("Gun") or (Backpack:FindFirstChild("Revolver") or (Character:FindFirstChild("Gun") or Character:FindFirstChild("Revolver")))) then
                                                                    v1407 = true
                                                                end
                                                                local v1409 = not v1406 and (not v1408 and not v1407)
                                                                local v1410 = true
                                                                if t1.value2.ESPRoles then
                                                                    if v1409 then v1409 = t1.value2.ESPRoles.Innocent == true end
                                                                    if not v1409 then
                                                                        v1409 = v1406 and t1.value2.ESPRoles.Murderer == true
                                                                        if not v1409 then
                                                                            v1409 = v1408 and t1.value2.ESPRoles.Sheriff == true
                                                                            if not v1409 then
                                                                                v1409 = v1407 and t1.value2.ESPRoles.Hero == true or t1.value2.ESPRoles.Sheriff == true
                                                                            end
                                                                        end
                                                                    end
                                                                    v1410 = v1409
                                                                end
                                                                local v1411 = t1.value2.RolesESP and v1410
                                                                local color3 = Color3.fromRGB(0, 255, 0)
                                                                if v1406 then color3 = Color3.fromRGB(255, 0, 0)
                                                                elseif v1408 then color3 = Color3.fromRGB(0, 0, 255)
                                                                elseif v1407 then color3 = Color3.fromRGB(255, 215, 0) end
                                                                if v1411 then
                                                                    local SPHub_ESP = Character:FindFirstChild("SPHub_ESP")
                                                                    if not SPHub_ESP then
                                                                        SPHub_ESP = Instance.new("Highlight")
                                                                        SPHub_ESP.Name = "SPHub_ESP"
                                                                        SPHub_ESP.FillTransparency = 0.5
                                                                        SPHub_ESP.OutlineTransparency = 0
                                                                        SPHub_ESP.Adornee = Character
                                                                        SPHub_ESP.Parent = Character
                                                                    else
                                                                        SPHub_ESP.Adornee = Character
                                                                    end
                                                                    SPHub_ESP.FillColor = color3
                                                                    SPHub_ESP.OutlineColor = color3
                                                                else
                                                                    local SPHub_ESP = Character:FindFirstChild("SPHub_ESP")
                                                                    if SPHub_ESP then SPHub_ESP:Destroy() end
                                                                end
                                                                local SPHub_NameTag = Character:FindFirstChild("SPHub_NameTag")
                                                                if t1.value2.NamesESP or t1.value2.RolesESP then
                                                                    t1.value16()
                                                                    if not SPHub_NameTag then
                                                                        local BillboardGui = Instance.new("BillboardGui")
                                                                        BillboardGui.Name = "SPHub_NameTag"
                                                                        BillboardGui.Size = UDim2.new(0, 200, 0, 45)
                                                                        BillboardGui.AlwaysOnTop = true
                                                                        BillboardGui.ExtentsOffset = Vector3.new(0, 3, 0)
                                                                        BillboardGui.Adornee = Character:FindFirstChild("Head") or Character:FindFirstChild("HumanoidRootPart")
                                                                        local TextLabel = Instance.new("TextLabel")
                                                                        TextLabel.Name = "RoleLabel"
                                                                        TextLabel.Size = UDim2.new(1, 0, 0, 18)
                                                                        TextLabel.Position = UDim2.new(0, 0, 0, 0)
                                                                        TextLabel.BackgroundTransparency = 1
                                                                        TextLabel.TextStrokeTransparency = 0
                                                                        TextLabel.Font = Enum.Font.GothamBold
                                                                        TextLabel.TextSize = 14
                                                                        TextLabel.TextColor3 = color3
                                                                        TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                                                                        TextLabel.Text = ""
                                                                        TextLabel.Visible = false
                                                                        TextLabel.Parent = BillboardGui
                                                                        local TextLabel2 = Instance.new("TextLabel")
                                                                        TextLabel2.Name = "Label"
                                                                        TextLabel2.Size = UDim2.new(1, 0, 0, 18)
                                                                        TextLabel2.Position = UDim2.new(0, 0, 0, 18)
                                                                        TextLabel2.BackgroundTransparency = 1
                                                                        TextLabel2.TextStrokeTransparency = 0
                                                                        TextLabel2.Font = Enum.Font.GothamBold
                                                                        TextLabel2.TextSize = 12
                                                                        TextLabel2.TextColor3 = color3
                                                                        TextLabel2.TextXAlignment = Enum.TextXAlignment.Center
                                                                        TextLabel2.Text = v509.DisplayName or v509.Name
                                                                        TextLabel2.Parent = BillboardGui
                                                                        BillboardGui.Parent = Character
                                                                        return
                                                                    end
                                                                    local RoleLabel = SPHub_NameTag:FindFirstChild("RoleLabel")
                                                                    if RoleLabel then
                                                                        RoleLabel.TextColor3 = color3
                                                                        if v1406 then
                                                                            RoleLabel.Text = "[Murderer]"
                                                                            RoleLabel.Visible = true
                                                                        elseif v1408 then
                                                                            RoleLabel.Text = "[Sheriff]"
                                                                            RoleLabel.Visible = true
                                                                        elseif v1407 then
                                                                            RoleLabel.Text = "[Hero]"
                                                                            RoleLabel.Visible = true
                                                                        else
                                                                            RoleLabel.Text = ""
                                                                            RoleLabel.Visible = false
                                                                        end
                                                                    end
                                                                    local Label = SPHub_NameTag:FindFirstChild("Label")
                                                                    if Label then
                                                                        Label.TextColor3 = color3
                                                                        return
                                                                    end
                                                                elseif SPHub_NameTag then
                                                                    SPHub_NameTag:Destroy()
                                                                end
                                                            end
                                                        end)
                                                    end
                                                else
                                                    for _, player in ipairs(game.Players:GetPlayers()) do
                                                        if player.Character then
                                                            local SPHub_ESP = player.Character:FindFirstChild("SPHub_ESP")
                                                            if SPHub_ESP then pcall(function() SPHub_ESP:Destroy() end) end
                                                            local SPHub_NameTag = player.Character:FindFirstChild("SPHub_NameTag")
                                                            if SPHub_NameTag then pcall(function() SPHub_NameTag:Destroy() end) end
                                                        end
                                                    end
                                                end
                                                pcall(function()
                                                    if t1.value2.TrapESP then
                                                        if scanAndApplyTrapESP then scanAndApplyTrapESP() end
                                                        return
                                                    end
                                                    if clearTrapESP then clearTrapESP() end
                                                end)
                                            end
                                        end)

                                        function t1.value39()
                                            local LocalPlayer = game.Players.LocalPlayer
                                            local Character = LocalPlayer.Character
                                            local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                            if Character then Character = Character:FindFirstChild("Knife") end
                                            if (Character or Backpack and Backpack:FindFirstChild("Knife")) ~= nil then return true end
                                            if t1.value25 then
                                                local v517 = t1.value25[tostring(LocalPlayer.UserId)] or (t1.value25[LocalPlayer.UserId] or t1.value25[LocalPlayer.Name])
                                                if v517 and (type(v517) == "table" and v517.Role == "Murderer") then return true end
                                            end
                                            local v518 = type(t1.value33) == "function" and t1.value33()
                                            if v518 and v518 == LocalPlayer then return true end
                                            return false
                                        end

                                        function t1.value40()
                                            local LocalPlayer = game.Players.LocalPlayer
                                            local Character = LocalPlayer.Character
                                            local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                            if Character then Character = Character:FindFirstChild("Gun") or Character:FindFirstChild("Revolver") end
                                            if not Character then Character = Backpack and Backpack:FindFirstChild("Gun") or Backpack:FindFirstChild("Revolver") end
                                            if Character ~= nil then return true end
                                            if t1.value25 then
                                                local v522 = t1.value25[tostring(LocalPlayer.UserId)] or (t1.value25[LocalPlayer.UserId] or t1.value25[LocalPlayer.Name])
                                                if v522 then v522 = type(v522) == "table" and v522.Role == "Sheriff" or v522.Role == "Hero" end
                                                if v522 then return true end
                                            end
                                            local v523 = type(t1.value34) == "function" and t1.value34()
                                            local v524 = type(v10) == "function" and v10()
                                            if v523 then v523 = v523 == LocalPlayer end
                                            if v523 or v524 and v524 == LocalPlayer then return true end
                                            return false
                                        end

                                        function t1.value41()
                                            local LocalPlayer = game.Players.LocalPlayer
                                            local Character = LocalPlayer.Character
                                            local v498 = Character and Character:FindFirstChild("HumanoidRootPart")
                                            local v499 = Character and Character:FindFirstChildOfClass("Humanoid")
                                            if not v498 or (not v499 or v499.Health <= 0) then return false end
                                            if t1.value31(LocalPlayer) then return false end
                                            local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
                                            local v501 = PlayerGui and PlayerGui:FindFirstChild("MainGUI")
                                            local v502 = v501 and v501:FindFirstChild("Game")
                                            local v503 = v502 and v502:FindFirstChild("SpectateButton")
                                            if v503 and v503.Visible then return false end
                                            return true
                                        end

                                        function t1.value42() return workspace:FindFirstChild("GunDrop", true) end

                                        function t1.value43()
                                            if not t1.value41() or t1.value39() then return end
                                            local v545 = t1.value42()
                                            if not v545 then
                                                v9("Instant Grab Gun", "There no gun dropped", 5)
                                                return
                                            end
                                            local LocalPlayer = game.Players.LocalPlayer
                                            local Character = LocalPlayer.Character
                                            local v553 = Character and Character:FindFirstChild("HumanoidRootPart")
                                            local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                            if Character and Character:FindFirstChild("Gun") or (Character:FindFirstChild("Revolver") or (Backpack and Backpack:FindFirstChild("Gun") or Backpack:FindFirstChild("Revolver"))) then
                                                v9("Instant Grab Gun", "You already have a Gun/Revolver!", 5)
                                                return
                                            end
                                            if v553 then
                                                local CFrame2 = v553.CFrame
                                                v553.Velocity = Vector3.new(0, 0, 0)
                                                v553.CFrame = v545.CFrame
                                                task.wait(0.05)
                                                if firetouchinterest then
                                                    firetouchinterest(v553, v545, 0)
                                                    task.wait(0.02)
                                                    firetouchinterest(v553, v545, 1)
                                                end
                                                v553.Velocity = Vector3.new(0, 0, 0)
                                                v553.CFrame = CFrame2
                                                task.spawn(function()
                                                    local v1432 = false
                                                    local timestamp = tick()
                                                    while tick() - timestamp < 1.5 do
                                                        if Character and Character:FindFirstChild("Gun") or (Character:FindFirstChild("Revolver") or (Backpack and Backpack:FindFirstChild("Gun") or Backpack:FindFirstChild("Revolver"))) then
                                                            v1432 = true
                                                            break
                                                        end
                                                        task.wait(0.05)
                                                    end
                                                    if v1432 then
                                                        v9("Instant Grab Gun", "Gun grabbed successfully!", 3)
                                                        return
                                                    end
                                                    v9("Instant Grab Gun", "Failed to grab gun (someone else might have taken it)!", 5)
                                                end)
                                                task.wait(0.5)
                                                t1.value24 = false
                                            end
                                        end

                                        function t1.value44()
                                            local v525 = t1.value33()
                                            if not v525 then
                                                v9("Send Murder to Chat", "Murderer not found yet!", 3)
                                                return
                                            end
                                            local v531 = v525.DisplayName or v525.Name
                                            local CustomMurderChatMessage = t1.value2.CustomMurderChatMessage
                                            if not CustomMurderChatMessage or (type(CustomMurderChatMessage) ~= "string" or CustomMurderChatMessage:match("^%s*$")) then
                                                CustomMurderChatMessage = "[player] the murder"
                                            end
                                            local v533 = CustomMurderChatMessage:gsub("%[player%]", v531):gsub("%[PLAYER%]", v531)
                                            pcall(function()
                                                local TextChatService = game:GetService("TextChatService")
                                                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                                                    local TextChannels = TextChatService:FindFirstChild("TextChannels")
                                                    local v1429 = TextChannels and TextChannels:FindFirstChild("RBXGeneral") or TextChannels:FindFirstChild("RBXSystem")
                                                    if v1429 then v1429:SendAsync(v533); return end
                                                else
                                                    local DefaultChatSystemChatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                                                    local v1431 = DefaultChatSystemChatEvents and DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
                                                    if v1431 then v1431:FireServer(v533, "All") end
                                                end
                                            end)
                                            v9("Send Murder to Chat", "Sent murderer to chat successfully!", 2)
                                        end

                                        t1.value45 = nil
                                        t1.value46 = nil

                                        function t1.value47()
                                            local u418
                                            pcall(function()
                                                local LocalPlayer = game.Players.LocalPlayer
                                                local v1386 = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
                                                local v1387 = v1386 and v1386:FindFirstChild("MainGUI")
                                                local v1388 = v1387 and v1387:FindFirstChild("Game")
                                                local v1389 = v1388 and v1388:FindFirstChild("Timer")
                                                local v1390 = v1389
                                                if v1389 then v1390 = v1389:IsA("TextLabel") and (v1389.Text and v1389.Text ~= "") end
                                                if v1390 then u418 = v1389.Text end
                                            end)
                                            if u418 then return u418 end
                                            local Time
                                            pcall(function()
                                                local v1391 = workspace:FindFirstChild("RoundTimerPart") or (workspace:FindFirstChild("RoundTimerPart", true) or workspace:FindFirstChild("RoundTimer", true))
                                                if v1391 then Time = v1391:GetAttribute("Time") end
                                            end)
                                            if Time and (type(Time) == "number" and Time >= 0) then
                                                local v420 = math.floor(Time / 60)
                                                local v421 = math.floor(Time % 60)
                                                return string.format("%d:%02d", v420, v421)
                                            end
                                            return "Intermission"
                                        end

                                        function t1.value48()
                                            if not t1.value41() then return false end
                                            local LocalPlayer = game.Players.LocalPlayer
                                            if t1.value25 then
                                                local v540 = t1.value25[tostring(LocalPlayer.UserId)] or (t1.value25[LocalPlayer.UserId] or t1.value25[LocalPlayer.Name])
                                                if v540 and (type(v540) == "table" and v540.Role) then return v540.Role == "Innocent" end
                                            end
                                            if t1.value39() then return false end
                                            local Character = LocalPlayer.Character
                                            local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                            local v543 = Character and Character:FindFirstChild("Gun") or Character:FindFirstChild("Revolver")
                                            if not v543 then v543 = Backpack and Backpack:FindFirstChild("Gun") or Backpack:FindFirstChild("Revolver") end
                                            if v543 then return false end
                                            local v544 = t1.value34()
                                            if v544 and v544 == LocalPlayer then return false end
                                            return true
                                        end

                                        function v13(p13)
                                            t1.value2.ShowRoundTimer = p13
                                            if p13 then
                                                if not t1.value45 or not t1.value45.Parent then
                                                    t1.value45 = Instance.new("ScreenGui")
                                                    t1.value45.Name = "SPHub_RoundTimerGui"
                                                    t1.value45.ResetOnSpawn = false
                                                    t1.value45.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                                                    local Frame = Instance.new("Frame")
                                                    Frame.Name = "Frame"
                                                    Frame.Size = UDim2.new(0, 130, 0, 28)
                                                    Frame.Position = UDim2.new(0.5, -65, 0, 75)
                                                    Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                                    Frame.BackgroundTransparency = 0.25
                                                    Frame.BorderSizePixel = 0
                                                    Frame.Parent = t1.value45
                                                    local UICorner = Instance.new("UICorner")
                                                    UICorner.CornerRadius = UDim.new(0, 6)
                                                    UICorner.Parent = Frame
                                                    local TextLabel = Instance.new("TextLabel")
                                                    TextLabel.Name = "TimerLabel"
                                                    TextLabel.Size = UDim2.new(1, 0, 1, 0)
                                                    TextLabel.BackgroundTransparency = 1
                                                    TextLabel.Font = Enum.Font.GothamBold
                                                    TextLabel.TextSize = 14
                                                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                                    TextLabel.TextStrokeTransparency = 0.5
                                                    TextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                                    TextLabel.Text = "⏳ --:--"
                                                    TextLabel.Parent = Frame
                                                end
                                                if t1.value46 then pcall(function() task.cancel(t1.value46) end) end
                                                t1.value46 = task.spawn(function()
                                                    while t1.value2.ShowRoundTimer do
                                                        pcall(function()
                                                            if t1.value45 and t1.value45:FindFirstChild("Frame") then
                                                                if not t1.value41() or not t1.value48() then
                                                                    t1.value45.Frame.Visible = false
                                                                    return
                                                                end
                                                                t1.value45.Frame.Visible = true
                                                                local v1746 = t1.value47()
                                                                if t1.value45.Frame:FindFirstChild("TimerLabel") then
                                                                    t1.value45.Frame.TimerLabel.Text = "⏳ " .. v1746
                                                                end
                                                            end
                                                        end)
                                                        task.wait(0.3)
                                                    end
                                                end)
                                                return
                                            end
                                            if t1.value46 then pcall(function() task.cancel(t1.value46) end); t1.value46 = nil end
                                            if t1.value45 then pcall(function() t1.value45:Destroy() end); t1.value45 = nil end
                                        end

                                        t1.value49 = nil

                                        do
                                            local function v14()
                                                local v565 = t1.value2.ESPRoles == nil or t1.value2.ESPRoles.Murderer == true
                                                if not t1.value2.RolesESP or (not v565 or (not t1.value41() or t1.value39())) then
                                                    if t1.value49 and t1.value49:FindFirstChild("ArrowContainer") then
                                                        t1.value49.ArrowContainer.Visible = false
                                                    end
                                                    return
                                                end
                                                local v566 = t1.value33()
                                                local v567 = v566 and v566.Character
                                                local v568 = v567 and v567:FindFirstChild("HumanoidRootPart")
                                                local Character = game.Players.LocalPlayer.Character
                                                local v570 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                local CurrentCamera = workspace.CurrentCamera
                                                if v566 then
                                                    v566 = v568
                                                    if v566 then v566 = v570 and CurrentCamera end
                                                end
                                                if v566 then
                                                    if not t1.value49 or not t1.value49.Parent then
                                                        t1.value49 = Instance.new("ScreenGui")
                                                        t1.value49.Name = "SPHub_MurdererArrowGui"
                                                        t1.value49.ResetOnSpawn = false
                                                        t1.value49.IgnoreGuiInset = true
                                                        t1.value49.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                                                        local Frame = Instance.new("Frame")
                                                        Frame.Name = "ArrowContainer"
                                                        Frame.Size = UDim2.new(0, 40, 0, 40)
                                                        Frame.AnchorPoint = Vector2.new(0.5, 0.5)
                                                        Frame.BackgroundTransparency = 1
                                                        Frame.Visible = false
                                                        Frame.Parent = t1.value49
                                                        local ImageLabel = Instance.new("ImageLabel")
                                                        ImageLabel.Name = "Arrow"
                                                        ImageLabel.Size = UDim2.new(0, 36, 0, 36)
                                                        ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                                                        ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                                                        ImageLabel.BackgroundTransparency = 1
                                                        ImageLabel.Image = "rbxassetid://97136202386756"
                                                        ImageLabel.ImageColor3 = Color3.fromRGB(255, 0, 10)
                                                        ImageLabel.Parent = Frame
                                                        local TextLabel = Instance.new("TextLabel")
                                                        TextLabel.Name = "DistanceLabel"
                                                        TextLabel.Size = UDim2.new(0, 100, 0, 18)
                                                        TextLabel.AnchorPoint = Vector2.new(0.5, 0)
                                                        TextLabel.Position = UDim2.new(0.5, 0, 1, 4)
                                                        TextLabel.BackgroundTransparency = 1
                                                        TextLabel.Font = Enum.Font.Montserrat
                                                        TextLabel.TextSize = 14
                                                        TextLabel.TextColor3 = Color3.fromRGB(255, 0, 10)
                                                        TextLabel.TextStrokeTransparency = 0.3
                                                        TextLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                                                        TextLabel.Text = "0m"
                                                        TextLabel.Parent = Frame
                                                    end
                                                    local ArrowContainer = t1.value49:FindFirstChild("ArrowContainer")
                                                    local v576 = ArrowContainer and ArrowContainer:FindFirstChild("Arrow")
                                                    local v577 = ArrowContainer and ArrowContainer:FindFirstChild("DistanceLabel")
                                                    if ArrowContainer and v576 then
                                                        local Position = v568.Position
                                                        local v579, v580 = CurrentCamera:WorldToViewportPoint(Position)
                                                        local ViewportSize = CurrentCamera.ViewportSize
                                                        local Magnitude = (CurrentCamera.CFrame.Position - Position).Magnitude
                                                        if v577 then v577.Text = string.format("%dm", (math.round(Magnitude))) end
                                                        local n2 = 50
                                                        local ViewportSizeX = ViewportSize.X
                                                        local ViewportSizeY = ViewportSize.Y
                                                        local v586 = ViewportSizeY - 100
                                                        local v587 = ViewportSizeX - 100
                                                        local v588 = math.sqrt((v587 / 2) ^ 2 + (v586 / 2) ^ 2)
                                                        local v589 = Position - CurrentCamera.CFrame.Position
                                                        local v590 = CurrentCamera.CFrame:VectorToObjectSpace(v589)
                                                        local vector2 = Vector2.new(v590.X, v590.Y)
                                                        local v592 = vector2.Magnitude > 0.001 and vector2.Unit or Vector2.new(0, 1)
                                                        local v593 = math.clamp(v579.X, n2, ViewportSizeX - n2)
                                                        local v594 = math.clamp(v579.Y, n2, ViewportSizeY - n2)
                                                        if v580 then
                                                            v580 = false
                                                            if v593 == v579.X then v580 = v594 == v579.Y end
                                                        end
                                                        if v580 then
                                                            ArrowContainer.Visible = false
                                                            return
                                                        end
                                                        ArrowContainer.Visible = true
                                                        local v595 = if not (math.abs((v592 * v588).Y) > v586 / 2) then v592 * math.abs(v587 / 2 / (math.abs(v592.X) > 0.0001 and v592.X or 0.0001)) else v592 * math.abs(v586 / 2 / (math.abs(v592.Y) > 0.0001 and v592.Y or 0.0001))
                                                        local v596 = math.clamp(ViewportSizeX / 2 + v595.X, n2, ViewportSizeX - n2)
                                                        local v597 = math.clamp(ViewportSizeY / 2 - v595.Y, n2, ViewportSizeY - n2)
                                                        local v598 = math.atan2(v592.X, v592.Y)
                                                        ArrowContainer.Position = UDim2.fromOffset(v596, v597)
                                                        v576.Rotation = math.deg(v598)
                                                        return
                                                    end
                                                elseif t1.value49 and t1.value49:FindFirstChild("ArrowContainer") then
                                                    t1.value49.ArrowContainer.Visible = false
                                                end
                                            end

                                            local connection = game:GetService("RunService").RenderStepped:Connect(function()
                                                pcall(v14)
                                            end)
                                            t1.value11(connection)

                                            function t1.value50(p14, p15)
                                                if not p14 then return nil, false end
                                                local raycastParams = RaycastParams.new()
                                                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                                raycastParams.FilterDescendantsInstances = { game.Players.LocalPlayer.Character }
                                                local v602 = p14:FindFirstChild("HumanoidRootPart") or (p14:FindFirstChild("UpperTorso") or p14:FindFirstChild("Torso"))
                                                if v602 then
                                                    local v603 = v602.Position - p15
                                                    local raycastResult = workspace:Raycast(p15, v603, raycastParams)
                                                    if not raycastResult or raycastResult.Instance:IsDescendantOf(p14) then
                                                        return v602, true
                                                    end
                                                end
                                                for _, v in ipairs({ "Head", "LowerTorso" }) do
                                                    local v5 = p14:FindFirstChild(v)
                                                    if not (v5 and v5 ~= v602) then continue end
                                                    local v608 = v5.Position - p15
                                                    local raycastResult = workspace:Raycast(p15, v608, raycastParams)
                                                    if not raycastResult or raycastResult.Instance:IsDescendantOf(p14) then
                                                        return v5, true
                                                    end
                                                end
                                                return nil, false
                                            end

                                            function t1.value51(p16)
                                                local LocalPlayer = game.Players.LocalPlayer
                                                local Character = LocalPlayer.Character
                                                local v613 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                if not v613 then return nil, nil end
                                                local v614 = p16 or v613.Position
                                                if t1.value2.PrioritizeSheriffKnifeThrow then
                                                    local v615 = t1.value34()
                                                    if v615 and (v615 ~= LocalPlayer and v615.Character) then
                                                        local HumanoidRootPart = v615.Character:FindFirstChild("HumanoidRootPart")
                                                        local Humanoid = v615.Character:FindFirstChildOfClass("Humanoid")
                                                        if HumanoidRootPart then HumanoidRootPart = Humanoid and Humanoid.Health > 0 end
                                                        if HumanoidRootPart then
                                                            local v618, v619 = t1.value50(v615.Character, v614)
                                                            if v619 and v618 then return v615, v618 end
                                                        end
                                                    end
                                                end
                                                local v620
                                                local v621
                                                local n3 = 1e999
                                                for _, player in ipairs(game.Players:GetPlayers()) do
                                                    if player ~= LocalPlayer and player.Character then
                                                        local HumanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
                                                        local Humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                                                        if HumanoidRootPart and (Humanoid and Humanoid.Health > 0) then
                                                            local Magnitude = (v613.Position - HumanoidRootPart.Position).Magnitude
                                                            if Magnitude < n3 then
                                                                local v628, v629 = t1.value50(player.Character, v614)
                                                                if v629 and v628 then
                                                                    n3 = Magnitude
                                                                    v620 = player
                                                                    v621 = v628
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                                return v620, v621
                                            end

                                            function v16(p17, _)
                                                if not t1.value41() or not t1.value39() then return end
                                                local LocalPlayer = game.Players.LocalPlayer
                                                local Character = LocalPlayer.Character
                                                local v634 = Character
                                                local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                                if Character then v634 = Character:FindFirstChild("Knife") end
                                                local v636 = v634 or Backpack and Backpack:FindFirstChild("Knife")
                                                if not v636 then return end
                                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                                local v638 = HumanoidRootPart and HumanoidRootPart.Position
                                                if not v638 then v638 = Vector3.new(0, 0, 0) end
                                                local v640
                                                if p17 and p17.Character then
                                                    local Humanoid = p17.Character:FindFirstChildOfClass("Humanoid")
                                                    if not Humanoid or Humanoid.Health <= 0 then return end
                                                    v640 = t1.value50(p17.Character, v638)
                                                else
                                                    p17, v640 = t1.value51(v638)
                                                end
                                                if not p17 or (not p17.Character or not v640) then return end
                                                local Humanoid = p17.Character:FindFirstChildOfClass("Humanoid")
                                                if not Humanoid or Humanoid.Health <= 0 then return end
                                                if Backpack == v636.Parent and Character then v636.Parent = Character end
                                                local Position = v640.Position
                                                local v643 = v640.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                                                local v644 = Position
                                                if v643.Magnitude > 1.5 then v644 = Position + v643 * 0.08 end
                                                local u645 = if not t1.value2.SpawnKnifeNearTarget then HumanoidRootPart and CFrame.new(HumanoidRootPart.Position, v644) or CFrame.new(v644 + Vector3.new(0, 1, 0), v644) else CFrame.new(Position + v640.CFrame.LookVector * 4, v644)
                                                local cFrame = CFrame.new(v644)
                                                pcall(function()
                                                    local Events = v636:FindFirstChild("Events")
                                                    local v1445 = Events and Events:FindFirstChild("KnifeThrown") or Events:FindFirstChild("Throw") or (v636:FindFirstChild("Throw") or v636:FindFirstChild("KnifeThrown", true))
                                                    if v1445 and v1445:IsA("RemoteEvent") then
                                                        v1445:FireServer(u645, cFrame)
                                                    end
                                                end)
                                            end

                                            getgenv().SPHub_AutoKnifeThrow_Loop = true
                                            table.insert(t1.value10, "SPHub_AutoKnifeThrow_Loop")
                                            task.spawn(function()
                                                while task.wait(1.5) and getgenv().SPHub_AutoKnifeThrow_Loop do
                                                    if t1.value2.AutoKnifeThrow and (t1.value39() and t1.value41()) then
                                                        pcall(function() v16(nil, true) end)
                                                    end
                                                end
                                            end)

                                            t1.value52 = nil
                                            t1.value53 = nil
                                            t1.value54 = nil

                                            local function v17()
                                                local v650 = t1.value42()
                                                if v650 and t1.value2.GunESP then
                                                    if not t1.value52 or v650 ~= t1.value52.Parent then
                                                        if t1.value52 then pcall(function() t1.value52:Destroy() end) end
                                                        local v651 = v650:FindFirstChild("SPHub_GunHighlight") or Instance.new("Highlight")
                                                        v651.Name = "SPHub_GunHighlight"
                                                        v651.FillColor = Color3.fromRGB(0, 255, 0)
                                                        v651.OutlineColor = Color3.fromRGB(0, 255, 0)
                                                        v651.FillTransparency = 0.4
                                                        v651.OutlineTransparency = 0
                                                        v651.Adornee = v650
                                                        v651.Parent = v650
                                                        t1.value52 = v651
                                                    end
                                                    if not t1.value53 or v650 ~= t1.value53.Parent then
                                                        if t1.value53 then pcall(function() t1.value53:Destroy() end) end
                                                        local v652 = v650:FindFirstChild("SPHub_GunTag") or Instance.new("BillboardGui")
                                                        v652.Name = "SPHub_GunTag"
                                                        v652.Size = UDim2.new(0, 200, 0, 50)
                                                        v652.AlwaysOnTop = true
                                                        v652.ExtentsOffset = Vector3.new(0, 1.5, 0)
                                                        v652.Adornee = v650
                                                        local TextLabel = Instance.new("TextLabel")
                                                        TextLabel.Name = "Label"
                                                        TextLabel.Size = UDim2.new(1, 0, 1, 0)
                                                        TextLabel.BackgroundTransparency = 1
                                                        TextLabel.TextStrokeTransparency = 0
                                                        TextLabel.Font = Enum.Font.GothamBold
                                                        TextLabel.TextSize = 14
                                                        TextLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                                                        TextLabel.Text = "Gun"
                                                        TextLabel.Parent = v652
                                                        v652.Parent = v650
                                                        t1.value53 = v652
                                                        return
                                                    end
                                                else
                                                    if t1.value52 then
                                                        pcall(function() t1.value52:Destroy() end)
                                                        t1.value52 = nil
                                                    else
                                                        local GunDrop = workspace:FindFirstChild("GunDrop", true)
                                                        if GunDrop then
                                                            local SPHub_GunHighlight = GunDrop:FindFirstChild("SPHub_GunHighlight")
                                                            if SPHub_GunHighlight then pcall(function() SPHub_GunHighlight:Destroy() end) end
                                                        end
                                                    end
                                                    if t1.value53 then
                                                        pcall(function() t1.value53:Destroy() end)
                                                        t1.value53 = nil
                                                        return
                                                    end
                                                    local GunDrop = workspace:FindFirstChild("GunDrop", true)
                                                    if GunDrop then
                                                        local SPHub_GunTag = GunDrop:FindFirstChild("SPHub_GunTag")
                                                        if SPHub_GunTag then pcall(function() SPHub_GunTag:Destroy() end) end
                                                    end
                                                end
                                            end

                                            getgenv().SPHub_GunESP_Loop = true
                                            table.insert(t1.value10, "SPHub_GunESP_Loop")
                                            local spawn = task.spawn
                                            t1.value55 = nil
                                            spawn(function()
                                                while task.wait(0.5) and getgenv().SPHub_GunESP_Loop do
                                                    pcall(v17)
                                                end
                                            end)
                                        end

                                        t1.value56 = {}

                                        function t1.value57(p19)
                                            t1.value2.XrayEnabled = p19
                                            if p19 then
                                                for v661, v662 in ipairs(workspace:GetDescendants()) do
                                                    local v663 = v662:IsA("BasePart")
                                                    if v663 then
                                                        v663 = not v662:IsDescendantOf(game.Players.LocalPlayer.Character) and not v662.Parent:FindFirstChildOfClass("Humanoid")
                                                    end
                                                    if v663 then
                                                        if not t1.value56[v662] then t1.value56[v662] = v662.Transparency end
                                                        v662.Transparency = 0.5
                                                    end
                                                end
                                                if not t1.value14 then
                                                    t1.value14 = workspace.DescendantAdded:Connect(function(descendant)
                                                        task.wait()
                                                        local XrayEnabled = t1.value2.XrayEnabled
                                                        if XrayEnabled then
                                                            XrayEnabled = descendant:IsA("BasePart")
                                                            if XrayEnabled then
                                                                XrayEnabled = not descendant:IsDescendantOf(game.Players.LocalPlayer.Character) and not descendant.Parent:FindFirstChildOfClass("Humanoid")
                                                            end
                                                        end
                                                        if XrayEnabled then
                                                            if not t1.value56[descendant] then t1.value56[descendant] = descendant.Transparency end
                                                            descendant.Transparency = 0.5
                                                        end
                                                    end)
                                                    t1.value11(t1.value14)
                                                    return
                                                end
                                            else
                                                if t1.value14 then
                                                    pcall(function() t1.value14:Disconnect() end)
                                                    t1.value14 = nil
                                                end
                                                for k, v in pairs(t1.value56) do
                                                    local v666 = v
                                                    pcall(function()
                                                        if k and k.Parent then k.Transparency = v666 end
                                                    end)
                                                end
                                                table.clear(t1.value56)
                                            end
                                        end

                                        t1.value58 = {}
                                        t1.value59 = true
                                        t1.value60 = 1
                                        t1.value61 = 1
                                        t1.value62 = 400
                                        t1.value63 = nil
                                        t1.value54 = nil

                                        function t1.value64(p20)
                                            t1.value2.SuperLagReducer = p20
                                            local Lighting = game:GetService("Lighting")
                                            if p20 then
                                                t1.value59 = Lighting.GlobalShadows
                                                t1.value60 = Lighting.EnvironmentDiffuseScale
                                                t1.value61 = Lighting.EnvironmentSpecularScale
                                                t1.value62 = Lighting.FogEnd
                                                Lighting.GlobalShadows = false
                                                Lighting.EnvironmentDiffuseScale = 0
                                                Lighting.EnvironmentSpecularScale = 0
                                                Lighting.FogEnd = 9000000000
                                                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
                                                pcall(function()
                                                    workspace.Terrain.WaterWaveSize = 0
                                                    workspace.Terrain.WaterWaveSpeed = 0
                                                    workspace.Terrain.WaterDetailLevel = Enum.WaterDetailLevel.Low
                                                end)
                                                local function v690(p21)
                                                    if p21:IsA("PostEffect") or (p21:IsA("Atmosphere") or (p21:IsA("Clouds") or p21:IsA("Sky"))) then
                                                        p21:Destroy()
                                                        return
                                                    end
                                                    local v1462 = p21:IsA("Decal")
                                                    if not v1462 then
                                                        v1462 = p21:IsA("Texture")
                                                        if not v1462 then
                                                            v1462 = p21:IsA("ParticleEmitter")
                                                            if not v1462 then
                                                                v1462 = p21:IsA("Trail")
                                                                if not v1462 then
                                                                    v1462 = p21:IsA("Beam")
                                                                    if not v1462 then
                                                                        v1462 = p21:IsA("Sparkles") or (p21:IsA("Fire") or p21:IsA("Smoke"))
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                    if v1462 then
                                                        p21:Destroy()
                                                        return
                                                    end
                                                    if p21:IsA("BasePart") then
                                                        if not t1.value58[p21] then t1.value58[p21] = p21.Material end
                                                        p21.Material = Enum.Material.SmoothPlastic
                                                    end
                                                end
                                                for v693, v694 in ipairs(workspace:GetDescendants()) do
                                                    pcall(v690, v694)
                                                end
                                                for v697, v698 in ipairs(Lighting:GetChildren()) do
                                                    pcall(v690, v698)
                                                end
                                                if not t1.value63 then
                                                    t1.value63 = workspace.DescendantAdded:Connect(function(descendant)
                                                        task.wait()
                                                        if t1.value2.SuperLagReducer then pcall(v690, descendant) end
                                                    end)
                                                    t1.value11(t1.value63)
                                                end
                                                if not t1.value54 then
                                                    t1.value54 = Lighting.ChildAdded:Connect(function(child)
                                                        task.wait()
                                                        if t1.value2.SuperLagReducer then pcall(v690, child) end
                                                    end)
                                                    t1.value11(t1.value54)
                                                end
                                                if t1.value23 then
                                                    v9("Performance", "Super Lag Reducer Enabled! World optimized.", 3)
                                                    return
                                                end
                                            else
                                                if t1.value59 ~= nil then Lighting.GlobalShadows = t1.value59 end
                                                if t1.value60 ~= nil then Lighting.EnvironmentDiffuseScale = t1.value60 end
                                                if t1.value61 ~= nil then Lighting.EnvironmentSpecularScale = t1.value61 end
                                                if t1.value62 ~= nil then Lighting.FogEnd = t1.value62 end
                                                if t1.value63 then pcall(function() t1.value63:Disconnect() end); t1.value63 = nil end
                                                if t1.value54 then pcall(function() t1.value54:Disconnect() end); t1.value54 = nil end
                                                for k, v in pairs(t1.value58) do
                                                    pcall(function()
                                                        if k and k.Parent then k.Material = v end
                                                    end)
                                                end
                                                table.clear(t1.value58)
                                                if t1.value23 then
                                                    v9("Performance", "Super Lag Reducer Disabled! World restored.", 3)
                                                end
                                            end
                                        end

                                        function t1.value65(p22)
                                            t1.value2.InfiniteJumpEnabled = p22
                                            if not t1.value15 then
                                                t1.value15 = game:GetService("UserInputService").JumpRequest:Connect(function()
                                                    if t1.value2.InfiniteJumpEnabled then
                                                        local Character = game.Players.LocalPlayer.Character
                                                        if Character and Character:FindFirstChildOfClass("Humanoid") then
                                                            Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
                                                        end
                                                    end
                                                end)
                                                t1.value11(t1.value15)
                                            end
                                        end

                                        t1.value38 = {}

                                        function t1.value66()
                                            for _, v in pairs(t1.value38) do
                                                local v649 = v
                                                pcall(function() v649:Remove() end)
                                            end
                                            t1.value38 = {}
                                        end
                                        getgenv().clearTracersGlobally = t1.value66

                                        function t1.value67()
                                            if not Drawing then return end
                                            if not t1.value2.TracersEnabled then
                                                t1.value66()
                                                return
                                            end
                                            local CurrentCamera = workspace.CurrentCamera
                                            local ViewportSize = CurrentCamera.ViewportSize
                                            local LocalPlayer = game.Players.LocalPlayer
                                            for _, player in ipairs(game.Players:GetPlayers()) do
                                                local v737 = player
                                                if v737 ~= LocalPlayer and (v737.Character and v737.Character:FindFirstChild("HumanoidRootPart")) then
                                                    local Character = v737.Character
                                                    local v739 = v737.Backpack:FindFirstChild("Knife") or Character:FindFirstChild("Knife")
                                                    local v740 = v737.Backpack:FindFirstChild("Gun") or Character:FindFirstChild("Gun")
                                                    local v741 = not v739 and not v740
                                                    local v743 = not v739 and not v740
                                                    local TracerRoles = t1.value2.TracerRoles
                                                    if TracerRoles then
                                                        if v743 then v743 = t1.value2.TracerRoles.Innocent end
                                                        if not v743 then
                                                            v743 = v739 and t1.value2.TracerRoles.Murderer or v740 and t1.value2.TracerRoles.Sheriff
                                                        end
                                                        TracerRoles = v743
                                                    end
                                                    local value2 = t1.value2
                                                    local v746 = TracerRoles or false
                                                    if value2.TracersEnabled and v746 then
                                                        local color3 = Color3.fromRGB(0, 255, 0)
                                                        if v739 then color3 = Color3.fromRGB(255, 0, 0)
                                                        elseif v740 then color3 = Color3.fromRGB(0, 0, 255) end
                                                        local v748, v749 = CurrentCamera:WorldToViewportPoint(Character.HumanoidRootPart.Position)
                                                        local v750 = t1.value38[v737]
                                                        if not v750 then
                                                            v750 = Drawing.new("Line")
                                                            v750.Thickness = 1.5
                                                            v750.Transparency = 1
                                                            t1.value38[v737] = v750
                                                        end
                                                        if v749 then
                                                            v750.From = Vector2.new(ViewportSize.X / 2, ViewportSize.Y)
                                                            v750.To = Vector2.new(v748.X, v748.Y)
                                                            v750.Color = color3
                                                            v750.Visible = true
                                                        else
                                                            v750.Visible = false
                                                        end
                                                    elseif t1.value38[v737] then
                                                        pcall(function() t1.value38[v737]:Remove() end)
                                                        t1.value38[v737] = nil
                                                    end
                                                elseif t1.value38[v737] then
                                                    pcall(function() t1.value38[v737]:Remove() end)
                                                    t1.value38[v737] = nil
                                                end
                                            end
                                        end

                                        local v21
                                        do
                                            local connection = game:GetService("RunService").RenderStepped:Connect(function()
                                                if t1.value2.TracersEnabled then
                                                    pcall(t1.value67)
                                                    return
                                                end
                                                t1.value66()
                                            end)
                                            t1.value11(connection)

                                            local TweenService = game:GetService("TweenService")
                                            t1.value68 = nil
                                            t1.value68 = TweenService

                                            function t1.value69(p23, p24)
                                                local Character = game.Players.LocalPlayer.Character
                                                local v754 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                if v754 then
                                                    local Magnitude = (v754.Position - p23.Position).Magnitude
                                                    local _TweenInfo = TweenInfo
                                                    local v757 = Magnitude / p24
                                                    local v758 = _TweenInfo.new(v757, Enum.EasingStyle.Linear)
                                                    local v759 = t1.value68:Create(v754, v758, { CFrame = p23 })
                                                    v759:Play()
                                                    return v759, v757
                                                end
                                                return nil, 0
                                            end

                                            t1.value70 = nil
                                            getgenv().SPHub_Grab_Loop = true
                                            table.insert(t1.value10, "SPHub_Grab_Loop")
                                            task.spawn(function()
                                                while task.wait(0.2) and getgenv().SPHub_Grab_Loop do
                                                    if t1.value2.AutoGrabGun and (t1.value41() and not t1.value39()) then
                                                        local v760 = t1.value42()
                                                        if v760 and v760 ~= t1.value70 then
                                                            t1.value70 = v760
                                                            pcall(t1.value43)
                                                        elseif not v760 then
                                                            t1.value70 = nil
                                                        end
                                                    end
                                                end
                                            end)

                                            t1.value71 = nil
                                            t1.value72 = nil

                                            function t1.value73(p25)
                                                t1.value2.AimbotEnabled = p25
                                                if t1.value72 then t1.value72:Disconnect(); t1.value72 = nil end
                                                if p25 then
                                                    t1.value72 = game:GetService("RunService").RenderStepped:Connect(function()
                                                        if not t1.value2.AimbotEnabled or not t1.value41() then return end
                                                        if t1.value48() then return end
                                                        local LocalPlayer = game.Players.LocalPlayer
                                                        local v1479
                                                        if t1.value39() then
                                                            local v1480 = t1.value34()
                                                            local v1481 = v10()
                                                            if v1480 and (t1.value32(v1480) and v1480 ~= LocalPlayer) then v1479 = v1480
                                                            elseif v1481 and (t1.value32(v1481) and v1481 ~= LocalPlayer) then v1479 = v1481 end
                                                        elseif t1.value40() then
                                                            local v1482 = t1.value33()
                                                            if v1482 and (t1.value32(v1482) and v1482 ~= LocalPlayer) then v1479 = v1482 end
                                                        end
                                                        if v1479 and v1479.Character then
                                                            local Character = v1479.Character
                                                            local v1484 = Character:FindFirstChild("HumanoidRootPart") or (Character:FindFirstChild("UpperTorso") or Character:FindFirstChild("Torso"))
                                                            if v1484 then
                                                                local Position = v1484.Position
                                                                if t1.value2.AdvancedPrediction and type(getPredictedPosition) == "function" then
                                                                    local v1486 = getPredictedPosition(v1479, t1.value2.ShootPositionOffset or 2.8)
                                                                    if v1486 and v1486.Magnitude > 0 then Position = v1486 end
                                                                end
                                                                local CurrentCamera = workspace.CurrentCamera
                                                                if CurrentCamera then
                                                                    CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position, Position)
                                                                end
                                                            end
                                                        end
                                                    end)
                                                    t1.value11(t1.value72)
                                                end
                                            end

                                            function t1.value74(p26, p27)
                                                if not p26 then return nil, false end
                                                local t8 = { "Torso", "LowerTorso", "UpperTorso", "HumanoidRootPart", "Head", "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg", "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }
                                                local t9 = {}
                                                for v767, v768 in ipairs(t8) do
                                                    local v769 = p26:FindFirstChild(v768)
                                                    if v769 and v769:IsA("BasePart") then table.insert(t9, v769) end
                                                end
                                                for _, child in ipairs(p26:GetChildren()) do
                                                    if child:IsA("BasePart") and not table.find(t8, child.Name) then
                                                        table.insert(t9, child)
                                                    end
                                                end
                                                local raycastParams = RaycastParams.new()
                                                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                                raycastParams.FilterDescendantsInstances = { game.Players.LocalPlayer.Character }
                                                for _, v in ipairs(t9) do
                                                    local v775 = v.Position - p27
                                                    local raycastResult = workspace:Raycast(p27, v775, raycastParams)
                                                    if not raycastResult or raycastResult.Instance:IsDescendantOf(p26) then
                                                        return v, true
                                                    end
                                                end
                                                local Torso = p26:FindFirstChild("Torso")
                                                if not Torso then
                                                    Torso = p26:FindFirstChild("LowerTorso") or (p26:FindFirstChild("HumanoidRootPart") or (p26:FindFirstChild("Head") or p26:FindFirstChildOfClass("BasePart")))
                                                end
                                                return Torso, false
                                            end

                                            t1.value75 = nil
                                            t1.value71 = {}

                                            function t1.value76(p28, p29)
                                                if not p29 then p29 = t1.value2.ShootPositionOffset or 2.8 end
                                                if not p28 then return Vector3.new(0, 0, 0) end
                                                local v781 = p28.Character or p28:IsA("Model") and p28
                                                if not v781 then return Vector3.new(0, 0, 0) end
                                                local v782 = v781:FindFirstChild("UpperTorso") or (v781:FindFirstChild("HumanoidRootPart") or v781:FindFirstChild("Torso"))
                                                local v783 = not v782
                                                local Humanoid = v781:FindFirstChildOfClass("Humanoid")
                                                if not v783 then v783 = not Humanoid end
                                                if v783 then return v782 and v782.Position or Vector3.new(0, 0, 0) end
                                                local v785 = v782.AssemblyLinearVelocity or Vector3.new(0, 0, 0)
                                                local v786 = Humanoid.MoveDirection or Vector3.new(0, 0, 0)
                                                local Magnitude = v785.Magnitude
                                                if Magnitude < 0.5 and v786.Magnitude < 0.1 then
                                                    t1.value71[p28] = Vector3.new(0, 0, 0)
                                                    return v782.Position
                                                end
                                                local LocalPlayer = game.Players.LocalPlayer
                                                local v789 = LocalPlayer and LocalPlayer.Character
                                                local v790 = v789 and v789:FindFirstChild("HumanoidRootPart")
                                                local v791 = v790 and v790.Position or v782.Position
                                                local n4 = 0
                                                pcall(function() n4 = game:GetService("Players").LocalPlayer:GetNetworkPing() * 1000 end)
                                                local v793 = t1.value2.OffsetToPingMult or 1
                                                local v794 = math.clamp(Magnitude / 16, 0.05, 2.5)
                                                local v795 = p29 * (1 + math.clamp(n4 * 0.0015, 0, 1.5) * (v793 - 1 + 1))
                                                local vector3 = Vector3.new(v785.X, 0, v785.Z)
                                                if vector3.Magnitude < 0.8 and v786.Magnitude > 0.1 then
                                                    vector3 = Vector3.new(v786.X, 0, v786.Z) * (Magnitude > 0.5 and Magnitude or 16)
                                                end
                                                local v797 = (t1.value71[p28] or vector3):Lerp(vector3, 0.25)
                                                t1.value71[p28] = v797
                                                local v798 = v791 - v782.Position
                                                local vector3_2 = Vector3.new(v798.X, 0, v798.Z)
                                                local Magnitude2 = vector3_2.Magnitude
                                                local vector3_3 = Vector3.new(0, 0, 0)
                                                if Magnitude2 > 0.5 and v797.Magnitude > 0.2 then
                                                    local Unit = vector3_2.Unit
                                                    local vector3_4 = Vector3.new(-Unit.Z, 0, Unit.X)
                                                    local v804 = v797:Dot(Unit)
                                                    local v805 = v797:Dot(vector3_4)
                                                    if v797.Unit:Dot(Unit) > 0.65 then v805 = 0 end
                                                    local v806 = v805 / 16 * (v795 * v794)
                                                    local v807 = v804 / 16 * (v795 * 0.25 * v794)
                                                    vector3_3 = vector3_4 * v806 + Unit * v807
                                                end
                                                local n5 = 0
                                                local Y = v785.Y
                                                if math.abs(Y) > 1 or (Humanoid:GetState() == Enum.HumanoidStateType.Jumping or Humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
                                                    local v810 = workspace.Gravity and (workspace.Gravity > 0 and workspace.Gravity) or 196.2
                                                    local v811 = math.clamp(n4 / 1000 + 0.08, 0.05, 0.35)
                                                    n5 = math.clamp(Y * v811 - 0.5 * v810 * v811 ^ 2, -4, 3)
                                                end
                                                return v782.Position + vector3_3 + Vector3.new(0, n5, 0)
                                            end

                                            t1.value77 = nil
                                            function t1.value77(_)
                                                task.spawn(function()
                                                    local LocalPlayer = game.Players.LocalPlayer
                                                    local Character = LocalPlayer.Character
                                                    if not Character then return end
                                                    local v1503 = t1.value34()
                                                    local v1504 = v10()
                                                    local function v1505()
                                                        if t1.value41() and (not t1.value31(LocalPlayer) and not t1.value39()) then
                                                            v9("Error", "You need a Gun!", 3)
                                                        end
                                                    end
                                                    if v1503 ~= LocalPlayer and v1504 ~= LocalPlayer then
                                                        local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                                        local Gun = Character:FindFirstChild("Gun")
                                                        if not Gun then
                                                            Gun = Character:FindFirstChild("Revolver")
                                                            if not Gun then
                                                                Gun = Backpack and Backpack:FindFirstChild("Gun") or Backpack:FindFirstChild("Revolver")
                                                            end
                                                        end
                                                        if not Gun then
                                                            v1505()
                                                            return
                                                        end
                                                    end
                                                    local v1508 = t1.value33()
                                                    if not v1508 or v1508 == LocalPlayer then
                                                        if v1503 and v1503 ~= LocalPlayer then v1508 = v1503
                                                        elseif v1504 and v1504 ~= LocalPlayer then v1508 = v1504 end
                                                    end
                                                    if not v1508 or not v1508.Character then return end
                                                    local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                                    if not Character:FindFirstChild("Gun") and not Character:FindFirstChild("Revolver") then
                                                        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
                                                        local v1511 = Backpack and Backpack:FindFirstChild("Gun") or Backpack:FindFirstChild("Revolver")
                                                        if not (Humanoid and v1511) then
                                                            v1505()
                                                            return
                                                        end
                                                        Humanoid:EquipTool(v1511)
                                                        task.wait(0.05)
                                                    end
                                                    local v1512 = Character:FindFirstChild("Gun") or Character:FindFirstChild("Revolver")
                                                    if not v1512 or not v1512.Parent then
                                                        v1505()
                                                        return
                                                    end
                                                    local v1513 = v1508.Character:FindFirstChild("HumanoidRootPart") or (v1508.Character:FindFirstChild("UpperTorso") or v1508.Character:FindFirstChild("Torso"))
                                                    if not v1513 then return end
                                                    local v1514 = if not Character:FindFirstChild("RightHand") then if not Character:FindFirstChild("HumanoidRootPart") then Character:GetPivot().Position else Character.HumanoidRootPart.Position else Character.RightHand.Position
                                                    local v1515
                                                    if t1.value2.AdvancedPrediction then
                                                        v1515 = t1.value76(v1508, t1.value2.ShootPositionOffset or 2.8)
                                                    else
                                                        local v1516 = t1.value74(v1508.Character, v1514)
                                                        v1515 = v1516 and v1516.Position or v1513.Position
                                                    end
                                                    local raycastParams = RaycastParams.new()
                                                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                                    raycastParams.FilterDescendantsInstances = { Character }
                                                    local v1518 = v1515 - v1514
                                                    local raycastResult = workspace:Raycast(v1514, v1518, raycastParams)
                                                    if raycastResult and not raycastResult.Instance:IsDescendantOf(v1508.Character) then
                                                        local v1520, v1521 = t1.value74(v1508.Character, v1514)
                                                        if not (v1521 and v1520) then
                                                            v9("Kill Murderer", "Murderer is behind wall, will shoot when in front!", 3)
                                                            return
                                                        end
                                                        v1515 = v1520.Position
                                                    end
                                                    local t10 = { CFrame.new(v1514), CFrame.new(v1515) }
                                                    local v1528 = v1512:FindFirstChild("Shoot") or v1512:WaitForChild("Shoot", 1)
                                                    if v1528 and v1528:IsA("RemoteEvent") then
                                                        local t11 = { unpack(t10) }
                                                        v1528:FireServer(v2(t11))
                                                        return
                                                    end
                                                    local CurrentCamera = workspace.CurrentCamera
                                                    local CurrentCameraCFrame = CurrentCamera.CFrame
                                                    CurrentCamera.CFrame = CFrame.new(CurrentCamera.CFrame.Position, v1515)
                                                    task.wait(0.02)
                                                    v1512:Activate()
                                                    task.wait(0.02)
                                                    CurrentCamera.CFrame = CurrentCameraCFrame
                                                end)
                                            end

                                            t1.value75 = nil
                                            function t1.value78(p31)
                                                if t1.value75 then pcall(function() t1.value75:Destroy() end); t1.value75 = nil end
                                                if not p31 then return end
                                                local ScreenGui = Instance.new("ScreenGui")
                                                ScreenGui.Name = "SPHub_FasterKillGui"
                                                ScreenGui.ResetOnSpawn = false
                                                local v814 = t1.value2.MobileButtonsSize or 50
                                                local ImageButton = Instance.new("ImageButton")
                                                ImageButton.Name = "KillMurdererButton"
                                                ImageButton.Size = UDim2.new(0, v814, 0, v814)
                                                ImageButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                                                ImageButton.BorderSizePixel = 0
                                                ImageButton.Image = ""
                                                ImageButton.Parent = ScreenGui
                                                local ImageLabel = Instance.new("ImageLabel")
                                                ImageLabel.Name = "Icon"
                                                ImageLabel.Size = UDim2.new(0.65, 0, 0.65, 0)
                                                ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                                                ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                                                ImageLabel.BackgroundTransparency = 1
                                                ImageLabel.Image = "rbxassetid://128514706094926"
                                                ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
                                                ImageLabel.ScaleType = Enum.ScaleType.Fit
                                                ImageLabel.Parent = ImageButton
                                                local UICorner = Instance.new("UICorner")
                                                UICorner.CornerRadius = UDim.new(0.5, 0)
                                                UICorner.Parent = ImageButton
                                                local UIStroke = Instance.new("UIStroke")
                                                UIStroke.Color = Color3.fromRGB(255, 60, 60)
                                                UIStroke.Thickness = 2
                                                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                                UIStroke.Parent = ImageButton
                                                local ViewportSize = workspace.CurrentCamera.ViewportSize
                                                local v820 = ViewportSize.X / 2 - v814 / 2
                                                local v821 = ViewportSize.Y * 0.8
                                                local v822 = v814 / 2
                                                local v823 = v820 < 10
                                                local v824 = v821 - v822
                                                if v823 or v824 < 10 then v824 = 455; v820 = 375 end
                                                local uDim2 = UDim2.new(0, v820, 0, v824)
                                                local SPHub_SavedFasterKillPos = getgenv().SPHub_SavedFasterKillPos
                                                if not SPHub_SavedFasterKillPos then
                                                    pcall(function()
                                                        if isfile and isfile("SPHub_FasterKillButtonPos.txt") then
                                                            local parts = readfile("SPHub_FasterKillButtonPos.txt"):split(",")
                                                            if #parts == 2 then
                                                                local num = tonumber(parts[1])
                                                                local num2 = tonumber(parts[2])
                                                                if num and num2 then
                                                                    SPHub_SavedFasterKillPos = UDim2.new(0, num, 0, num2)
                                                                    getgenv().SPHub_SavedFasterKillPos = SPHub_SavedFasterKillPos
                                                                end
                                                            end
                                                        end
                                                    end)
                                                end
                                                ImageButton.Position = SPHub_SavedFasterKillPos or uDim2
                                                local UserInputService = game:GetService("UserInputService")
                                                local u828 = false
                                                local u829 = false
                                                local u830
                                                ImageButton.InputBegan:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        u828 = true
                                                        u829 = false
                                                    end
                                                end)
                                                ImageButton.InputChanged:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                                        u830 = input
                                                    end
                                                end)
                                                UserInputService.InputChanged:Connect(function(input)
                                                    if input == u830 and u828 then
                                                        local delta = input.Position - (u830 and u830.Position or input.Position)
                                                        if delta.Magnitude > 0 then
                                                            local newPos = UDim2.new(0, ImageButton.AbsolutePosition.X + delta.X, 0, ImageButton.AbsolutePosition.Y + delta.Y)
                                                            ImageButton.Position = newPos
                                                            getgenv().SPHub_SavedFasterKillPos = newPos
                                                        end
                                                    end
                                                end)
                                                UserInputService.InputEnded:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and u828 then
                                                        local ImageButtonPosition = ImageButton.Position
                                                        getgenv().SPHub_SavedFasterKillPos = ImageButtonPosition
                                                        pcall(function()
                                                            if writefile then
                                                                writefile("SPHub_FasterKillButtonPos.txt", string.format("%d,%d", math.floor(ImageButtonPosition.X.Offset), (math.floor(ImageButtonPosition.Y.Offset))))
                                                            end
                                                        end)
                                                    end
                                                end)
                                                ImageButton.MouseButton1Click:Connect(function()
                                                    if not u829 then t1.value77(false) end
                                                end)
                                                local CoreGui
                                                pcall(function() CoreGui = game:GetService("CoreGui") end)
                                                if not CoreGui then pcall(function() CoreGui = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") end) end
                                                ScreenGui.Parent = CoreGui
                                                t1.value75 = ScreenGui
                                                getgenv().SPHub_FasterKillGui = ScreenGui
                                            end

                                            t1.value55 = nil
                                            function t1.value79(p33)
                                                if t1.value55 then pcall(function() t1.value55:Destroy() end); t1.value55 = nil end
                                                if not p33 then return end
                                                local ScreenGui = Instance.new("ScreenGui")
                                                ScreenGui.Name = "SPHub_FasterGrabGunGui"
                                                ScreenGui.ResetOnSpawn = false
                                                local v713 = t1.value2.MobileButtonsSize or 50
                                                local ImageButton = Instance.new("ImageButton")
                                                ImageButton.Name = "GrabGunButton"
                                                ImageButton.Size = UDim2.new(0, v713, 0, v713)
                                                ImageButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                                                ImageButton.BorderSizePixel = 0
                                                ImageButton.Image = ""
                                                ImageButton.Parent = ScreenGui
                                                local ImageLabel = Instance.new("ImageLabel")
                                                ImageLabel.Name = "Icon"
                                                ImageLabel.Size = UDim2.new(0.65, 0, 0.65, 0)
                                                ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                                                ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                                                ImageLabel.BackgroundTransparency = 1
                                                ImageLabel.Image = "rbxassetid://18378315812"
                                                ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
                                                ImageLabel.ScaleType = Enum.ScaleType.Fit
                                                ImageLabel.Parent = ImageButton
                                                local UICorner = Instance.new("UICorner")
                                                UICorner.CornerRadius = UDim.new(0.5, 0)
                                                UICorner.Parent = ImageButton
                                                local UIStroke = Instance.new("UIStroke")
                                                UIStroke.Color = Color3.fromRGB(50, 255, 50)
                                                UIStroke.Thickness = 2
                                                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                                UIStroke.Parent = ImageButton
                                                local ViewportSize = workspace.CurrentCamera.ViewportSize
                                                local v719 = ViewportSize.X / 2 + 35
                                                local v720 = ViewportSize.Y * 0.8
                                                local v721 = v713 / 2
                                                local v722 = v719 < 10
                                                local v723 = v720 - v721
                                                if v722 or v723 < 10 then v719 = 435; v723 = 455 end
                                                local uDim2 = UDim2.new(0, v719, 0, v723)
                                                local SPHub_SavedFasterGrabGunPos = getgenv().SPHub_SavedFasterGrabGunPos
                                                if not SPHub_SavedFasterGrabGunPos then
                                                    pcall(function()
                                                        if isfile and isfile("SPHub_FasterGrabGunButtonPos.txt") then
                                                            local parts = readfile("SPHub_FasterGrabGunButtonPos.txt"):split(",")
                                                            if #parts == 2 then
                                                                local num = tonumber(parts[1])
                                                                local num3 = tonumber(parts[2])
                                                                if num and num3 then
                                                                    SPHub_SavedFasterGrabGunPos = UDim2.new(0, num, 0, num3)
                                                                    getgenv().SPHub_SavedFasterGrabGunPos = SPHub_SavedFasterGrabGunPos
                                                                end
                                                            end
                                                        end
                                                    end)
                                                end
                                                ImageButton.Position = SPHub_SavedFasterGrabGunPos or uDim2
                                                local UserInputService = game:GetService("UserInputService")
                                                local u727 = false
                                                local u728 = false
                                                local u729
                                                ImageButton.InputBegan:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        u727 = true
                                                        u728 = false
                                                    end
                                                end)
                                                ImageButton.InputChanged:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                                        u729 = input
                                                    end
                                                end)
                                                UserInputService.InputChanged:Connect(function(input)
                                                    if input == u729 and u727 then
                                                        local delta = input.Position - (u729 and u729.Position or input.Position)
                                                        if delta.Magnitude > 0 then
                                                            local newPos = UDim2.new(0, ImageButton.AbsolutePosition.X + delta.X, 0, ImageButton.AbsolutePosition.Y + delta.Y)
                                                            ImageButton.Position = newPos
                                                            getgenv().SPHub_SavedFasterGrabGunPos = newPos
                                                        end
                                                    end
                                                end)
                                                UserInputService.InputEnded:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and u727 then
                                                        local ImageButtonPosition = ImageButton.Position
                                                        getgenv().SPHub_SavedFasterGrabGunPos = ImageButtonPosition
                                                        pcall(function()
                                                            if writefile then
                                                                writefile("SPHub_FasterGrabGunButtonPos.txt", string.format("%d,%d", math.floor(ImageButtonPosition.X.Offset), (math.floor(ImageButtonPosition.Y.Offset))))
                                                            end
                                                        end)
                                                    end
                                                end)
                                                ImageButton.MouseButton1Click:Connect(function()
                                                    if not u728 then t1.value43() end
                                                end)
                                                local u731
                                                pcall(function() u731 = game:GetService("CoreGui") end)
                                                if not u731 then pcall(function() u731 = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") end) end
                                                ScreenGui.Parent = u731
                                                t1.value55 = ScreenGui
                                                getgenv().SPHub_FasterGrabGunGui = ScreenGui
                                            end

                                            t1.value26 = nil
                                            function t1.value80(p35)
                                                if t1.value26 then pcall(function() t1.value26:Destroy() end); t1.value26 = nil end
                                                if not p35 then return end
                                                local ScreenGui = Instance.new("ScreenGui")
                                                ScreenGui.Name = "SPHub_FasterKnifeThrowGui"
                                                ScreenGui.ResetOnSpawn = false
                                                local v669 = t1.value2.MobileButtonsSize or 50
                                                local ImageButton = Instance.new("ImageButton")
                                                ImageButton.Name = "KnifeThrowButton"
                                                ImageButton.Size = UDim2.new(0, v669, 0, v669)
                                                ImageButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                                                ImageButton.BorderSizePixel = 0
                                                ImageButton.Image = ""
                                                ImageButton.Parent = ScreenGui
                                                local ImageLabel = Instance.new("ImageLabel")
                                                ImageLabel.Name = "Icon"
                                                ImageLabel.Size = UDim2.new(0.65, 0, 0.65, 0)
                                                ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
                                                ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                                                ImageLabel.BackgroundTransparency = 1
                                                ImageLabel.Image = "rbxassetid://7349058170"
                                                ImageLabel.ImageColor3 = Color3.fromRGB(255, 255, 255)
                                                ImageLabel.ScaleType = Enum.ScaleType.Fit
                                                ImageLabel.Parent = ImageButton
                                                local UICorner = Instance.new("UICorner")
                                                UICorner.CornerRadius = UDim.new(0.5, 0)
                                                UICorner.Parent = ImageButton
                                                local UIStroke = Instance.new("UIStroke")
                                                UIStroke.Color = Color3.fromRGB(255, 170, 0)
                                                UIStroke.Thickness = 2
                                                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                                UIStroke.Parent = ImageButton
                                                local ViewportSize = workspace.CurrentCamera.ViewportSize
                                                local v675 = ViewportSize.X / 2 + 95
                                                local v676 = ViewportSize.Y * 0.8
                                                local v677 = v669 / 2
                                                local v678 = v675 < 10
                                                local v679 = v676 - v677
                                                if v678 or v679 < 10 then v679 = 455; v675 = 495 end
                                                local uDim2 = UDim2.new(0, v675, 0, v679)
                                                ImageButton.Position = uDim2
                                                local UserInputService = game:GetService("UserInputService")
                                                local u683 = false
                                                local u684 = false
                                                ImageButton.InputBegan:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                        u683 = true
                                                        u684 = false
                                                    end
                                                end)
                                                UserInputService.InputEnded:Connect(function(input)
                                                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and u683 then
                                                        u683 = false
                                                    end
                                                end)
                                                ImageButton.MouseButton1Click:Connect(function()
                                                    if not u684 then v16(nil, false) end
                                                end)
                                                local u687
                                                pcall(function() u687 = game:GetService("CoreGui") end)
                                                if not u687 then pcall(function() u687 = game.Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") end) end
                                                ScreenGui.Parent = u687
                                                t1.value26 = ScreenGui
                                                getgenv().SPHub_FasterKnifeThrowGui = ScreenGui
                                            end

                                            function t1.value81()
                                                local v834 = t1.value2.MobileButtonsSize or 50
                                                if t1.value75 then
                                                    local KillMurdererButton = t1.value75:FindFirstChild("KillMurdererButton", true)
                                                    if KillMurdererButton then KillMurdererButton.Size = UDim2.new(0, v834, 0, v834) end
                                                end
                                                if t1.value55 then
                                                    local GrabGunButton = t1.value55:FindFirstChild("GrabGunButton", true)
                                                    if GrabGunButton then GrabGunButton.Size = UDim2.new(0, v834, 0, v834) end
                                                end
                                            end

                                            t1.value82 = 0
                                            getgenv().SPHub_AutoKillMurder_Loop = true
                                            table.insert(t1.value10, "SPHub_AutoKillMurder_Loop")
                                            task.spawn(function()
                                                local RunService = game:GetService("RunService")
                                                local connection2
                                                connection2 = RunService.Heartbeat:Connect(function()
                                                    if not getgenv().SPHub_AutoKillMurder_Loop then
                                                        if connection2 then connection2:Disconnect() end
                                                        return
                                                    end
                                                    if t1.value2.AutoKillMurder and (t1.value41() and not t1.value39()) and tick() - t1.value82 >= 0.65 then
                                                        local LocalPlayer = game.Players.LocalPlayer
                                                        local Character = LocalPlayer.Character
                                                        local u1534 = Character and Character:FindFirstChild("Gun") or Character:FindFirstChild("Revolver")
                                                        if not u1534 then
                                                            local Backpack = LocalPlayer:FindFirstChild("Backpack")
                                                            u1534 = Backpack and Backpack:FindFirstChild("Gun") or Backpack:FindFirstChild("Revolver")
                                                        end
                                                        if u1534 then
                                                            local v1536 = t1.value33()
                                                            if v1536 and (v1536.Character and v1536.Character:FindFirstChild("HumanoidRootPart")) then
                                                                local Knife = v1536.Character:FindFirstChild("Knife")
                                                                if not t1.value2.ShootOnlyWhenKnifeEquipped or Knife then
                                                                    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                                                    if HumanoidRootPart then
                                                                        if t1.value2.AutoKillMurderMode == "Teleport & Shoot" then
                                                                            local u1539
                                                                            pcall(function()
                                                                                local HumanoidRootPart2 = v1536.Character.HumanoidRootPart
                                                                                if u1534.Parent == LocalPlayer.Backpack then
                                                                                    u1534.Parent = Character
                                                                                    task.wait(0.05)
                                                                                end
                                                                                u1539 = RunService.Stepped:Connect(function()
                                                                                    if Character then
                                                                                        for _, descendant in ipairs(Character:GetDescendants()) do
                                                                                            if descendant:IsA("BasePart") then descendant.CanCollide = false end
                                                                                        end
                                                                                    end
                                                                                end)
                                                                                local v1753 = HumanoidRootPart2.CFrame * CFrame.new(0, 0, 3)
                                                                                local v1754, v1755 = t1.value69(v1753, 65)
                                                                                if v1754 then
                                                                                    local u1756 = false
                                                                                    local connection3
                                                                                    connection3 = v1754.Completed:Connect(function()
                                                                                        u1756 = true
                                                                                        if connection3 then connection3:Disconnect() end
                                                                                    end)
                                                                                    local v1758 = v1755 + 0.5
                                                                                    local n6 = 0
                                                                                    while not u1756 and (n6 < v1758 and t1.value2.AutoKillMurder) do
                                                                                        if not t1.value41() or t1.value39() then
                                                                                            v1754:Cancel()
                                                                                            break
                                                                                        end
                                                                                        local HumanoidRootPartPosition = HumanoidRootPart.Position
                                                                                        local _, t12Result = t1.value74(v1536.Character, HumanoidRootPartPosition)
                                                                                        if t12Result then
                                                                                            v1754:Cancel()
                                                                                            break
                                                                                        end
                                                                                        task.wait(0.02)
                                                                                        n6 += 0.02
                                                                                    end
                                                                                    if connection3 then connection3:Disconnect() end
                                                                                end
                                                                                if t1.value41() and (not t1.value39() and (HumanoidRootPart2 and HumanoidRootPart2.Parent)) then
                                                                                    HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart2.Position)
                                                                                    task.wait(0.02)
                                                                                    local v1763 = HumanoidRootPart:FindFirstChild("GunRaycastAttachment") and HumanoidRootPart.GunRaycastAttachment.WorldCFrame or HumanoidRootPart.CFrame
                                                                                    local v1764 = v1536.Character:FindFirstChild("Head") or HumanoidRootPart2
                                                                                    local cFrame = CFrame.new(v1764.Position)
                                                                                    local Shoot = u1534:FindFirstChild("Shoot")
                                                                                    if Shoot and Shoot:IsA("RemoteEvent") then
                                                                                        Shoot:FireServer(v1763, cFrame)
                                                                                    end
                                                                                end
                                                                            end)
                                                                            if u1539 then u1539:Disconnect() end
                                                                            t1.value24 = false
                                                                        else
                                                                            local v1540 = HumanoidRootPart:FindFirstChild("GunRaycastAttachment") and HumanoidRootPart.GunRaycastAttachment.WorldCFrame or HumanoidRootPart.CFrame
                                                                            local _, v1542 = t1.value74(v1536.Character, v1540.Position)
                                                                            if v1542 then
                                                                                pcall(function() t1.value77(true) end)
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end)
                                            end)

                                            getgenv().SPHub_LinkBehindMurder_Loop = true
                                            table.insert(t1.value10, "SPHub_LinkBehindMurder_Loop")
                                            task.spawn(function()
                                                local RunService = game:GetService("RunService")
                                                local connection4
                                                connection4 = RunService.RenderStepped:Connect(function()
                                                    if not getgenv().SPHub_LinkBehindMurder_Loop then
                                                        if connection4 then connection4:Disconnect() end
                                                        return
                                                    end
                                                    if t1.value2.LinkBehindMurder then
                                                        pcall(function()
                                                            local LocalPlayer = game.Players.LocalPlayer
                                                            local v1768 = LocalPlayer and LocalPlayer.Character
                                                            local v1769 = v1768 and v1768:FindFirstChild("HumanoidRootPart")
                                                            if v1769 then
                                                                local v1770 = t1.value33()
                                                                if v1770 and v1770.Character then
                                                                    local HumanoidRootPart = v1770.Character:FindFirstChild("HumanoidRootPart")
                                                                    if HumanoidRootPart then
                                                                        local v1772 = HumanoidRootPart.CFrame * Vector3.new(0, 0, 3.5)
                                                                        v1769.CFrame = CFrame.new(v1772, v1772 + HumanoidRootPart.CFrame.LookVector)
                                                                    end
                                                                end
                                                            end
                                                        end)
                                                    end
                                                end)
                                            end)

                                            function v21()
                                                local LocalPlayer = game.Players.LocalPlayer
                                                local Character = LocalPlayer.Character
                                                local v843 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                if not v843 then return {} end
                                                local t13 = {}
                                                for _, player in ipairs(game.Players:GetPlayers()) do
                                                    local v847 = player ~= LocalPlayer
                                                    if v847 then
                                                        v847 = player.Character
                                                        if v847 then
                                                            v847 = player.Character:FindFirstChild("HumanoidRootPart") and (player.Character:FindFirstChildOfClass("Humanoid") and player.Character:FindFirstChildOfClass("Humanoid").Health > 0)
                                                        end
                                                    end
                                                    if v847 then
                                                        local insert = table.insert
                                                        local HumanoidRootPart = player.Character.HumanoidRootPart
                                                        local Magnitude = (v843.Position - player.Character.HumanoidRootPart.Position).Magnitude
                                                        insert(t13, { player = player, hrp = HumanoidRootPart, dist = Magnitude })
                                                    end
                                                end
                                                table.sort(t13, function(p37, p38) return p37.dist < p38.dist end)
                                                return t13
                                            end

                                            t1.value83 = false
                                            getgenv().SPHub_MurdererKill_Loop = true
                                            table.insert(t1.value10, "SPHub_MurdererKill_Loop")
                                            task.spawn(function()
                                                while task.wait(0.1) and getgenv().SPHub_MurdererKill_Loop do
                                                    if t1.value2.MurdererAutoKill and not t1.value83 and (t1.value41() and t1.value39()) then
                                                        t1.value83 = true
                                                        local connection5
                                                        pcall(function()
                                                            local LocalPlayer = game.Players.LocalPlayer
                                                            local Character = LocalPlayer.Character
                                                            local v1547 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                            if not v1547 then return end
                                                            local v1548 = Character:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
                                                            if not v1548 then
                                                                v9("Error", "You need a Knife to use Auto Kill!", 5)
                                                                task.wait(1)
                                                                return
                                                            end
                                                            if v1548.Parent == LocalPlayer.Backpack then v1548.Parent = Character end
                                                            connection5 = game:GetService("RunService").Stepped:Connect(function()
                                                                if Character then
                                                                    for _, descendant in ipairs(Character:GetDescendants()) do
                                                                        if descendant:IsA("BasePart") then descendant.CanCollide = false end
                                                                    end
                                                                end
                                                            end)
                                                            while t1.value2.MurdererAutoKill do
                                                                if not t1.value41() or not t1.value39() then
                                                                    if not getgenv().ActiveKillTween then return end
                                                                    pcall(function() getgenv().ActiveKillTween:Cancel() end)
                                                                    getgenv().ActiveKillTween = nil
                                                                    return
                                                                end
                                                                local v1554 = v21()
                                                                local t14 = {}
                                                                for v1558, v1559 in ipairs(v1554) do
                                                                    if LocalPlayer ~= v1559.player and v1559.hrp.Position.Y < 400 then
                                                                        table.insert(t14, v1559)
                                                                    end
                                                                end
                                                                if #t14 == 0 then return end
                                                                local str = tostring(t1.value2.MurdererAutoKillMode)
                                                                local v1561 = str:find("Bring")
                                                                if not v1561 then
                                                                    v1561 = str:find("احضار")
                                                                    if not v1561 then
                                                                        v1561 = str:find("أحضر")
                                                                        if not v1561 then
                                                                            v1561 = str == "Bring Everyone"
                                                                        end
                                                                    end
                                                                end
                                                                if not v1561 then
                                                                    local v1564 = t14[1].hrp.CFrame * CFrame.new(0, 0, 1.2)
                                                                    local v1565, v1566 = t1.value69(v1564, 65)
                                                                    getgenv().ActiveKillTween = v1565
                                                                    if v1565 then
                                                                        local u1567 = false
                                                                        local connection6
                                                                        connection6 = v1565.Completed:Connect(function()
                                                                            u1567 = true
                                                                            if connection6 then connection6:Disconnect() end
                                                                        end)
                                                                        local v1569 = v1566 + 0.5
                                                                        if v1569 > 5 then v1569 = 5 end
                                                                        local n7 = 0
                                                                        while not u1567 and (n7 < v1569 and t1.value2.MurdererAutoKill) do
                                                                            if not t1.value41() or not t1.value39() then
                                                                                v1565:Cancel()
                                                                                break
                                                                            end
                                                                            task.wait(0.02)
                                                                            n7 += 0.02
                                                                        end
                                                                        if connection6 then connection6:Disconnect() end
                                                                    end
                                                                    getgenv().ActiveKillTween = nil
                                                                    if not t1.value2.MurdererAutoKill or (not t1.value41() or not t1.value39()) then return end
                                                                    task.wait(0.02)
                                                                    v1548:Activate()
                                                                    local Events = v1548:FindFirstChild("Events")
                                                                    local v1572 = Events and Events:FindFirstChild("KnifeStabbed")
                                                                    if v1572 then v1572:FireServer() end
                                                                    task.wait(0.05)
                                                                    continue
                                                                end
                                                                for v1575, v1576 in ipairs(Character:GetDescendants()) do
                                                                    if v1576:IsA("BasePart") then v1576.CanCollide = false end
                                                                end
                                                                for _, v in ipairs(t14) do
                                                                    if v.hrp and v.hrp.Parent then
                                                                        pcall(function()
                                                                            v.hrp.CFrame = v1547.CFrame * CFrame.new(0, 0, -2.5)
                                                                        end)
                                                                    end
                                                                end
                                                                task.wait(0.05)
                                                                v1548:Activate()
                                                                local Events = v1548:FindFirstChild("Events")
                                                                local v1580 = Events and Events:FindFirstChild("KnifeStabbed")
                                                                if v1580 then v1580:FireServer() end
                                                                task.wait(0.1)
                                                            end
                                                        end)
                                                        if connection5 then connection5:Disconnect() end
                                                        if getgenv().ActiveKillTween then
                                                            pcall(function() getgenv().ActiveKillTween:Cancel() end)
                                                            getgenv().ActiveKillTween = nil
                                                        end
                                                        t1.value24 = false
                                                        t1.value83 = false
                                                    end
                                                end
                                            end)

                                            t1.value84 = nil
                                            t1.value85 = nil

                                            function t1.value86()
                                                task.spawn(function()
                                                    local LocalPlayer = game.Players.LocalPlayer
                                                    local Character = LocalPlayer.Character
                                                    local v1593 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                    if not v1593 then return end
                                                    local v1594 = Character:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
                                                    if not v1594 then
                                                        v9("Error", "You need a Knife to use Kill All!", 5)
                                                        return
                                                    end
                                                    if v1594.Parent == LocalPlayer.Backpack then v1594.Parent = Character end
                                                    local connection7
                                                    pcall(function()
                                                        connection7 = game:GetService("RunService").Stepped:Connect(function()
                                                            if Character then
                                                                for _, descendant in ipairs(Character:GetDescendants()) do
                                                                    if descendant:IsA("BasePart") then descendant.CanCollide = false end
                                                                end
                                                            end
                                                        end)
                                                        for _ = 1, 5 do
                                                            if not t1.value41() or not t1.value39() then return end
                                                            for _, player in ipairs(game.Players:GetPlayers()) do
                                                                if player ~= LocalPlayer and (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
                                                                    local HumanoidRootPart = player.Character.HumanoidRootPart
                                                                    if HumanoidRootPart.Position.Y < 400 then
                                                                        pcall(function()
                                                                            HumanoidRootPart.CFrame = v1593.CFrame * CFrame.new(0, 0, -2.5)
                                                                        end)
                                                                    end
                                                                end
                                                            end
                                                            task.wait(0.05)
                                                            v1594:Activate()
                                                            local Events = v1594:FindFirstChild("Events")
                                                            local v1806 = Events and Events:FindFirstChild("KnifeStabbed")
                                                            if v1806 then v1806:FireServer() end
                                                            task.wait(0.05)
                                                        end
                                                    end)
                                                    if connection7 then connection7:Disconnect() end
                                                    task.wait(0.5)
                                                    t1.value24 = false
                                                    v9("Kill All", "Successfully pulled and eliminated all players!", 5)
                                                end)
                                            end

                                            function t1.value87()
                                                local v851 = game.Players.LocalPlayer:FindFirstChild("coinFolder") or game.Players.LocalPlayer:FindFirstChild("CoinFolder")
                                                if v851 then return #v851:GetChildren(), 40 end
                                                local ok, result, v854 = pcall(function()
                                                    return tonumber(game.Players.LocalPlayer.PlayerGui.MainGUI.Game.CoinBags.CoinBagContainerScript.Coin.CurrencyFrame.Icon.Coins.Text), 40
                                                end)
                                                if ok and result then return result, v854 end
                                                return 0, 40
                                            end

                                            function t1.value84()
                                                local v870, v871, v872 = ipairs(workspace:GetChildren())
                                                local CoinContainer
                                                repeat
                                                    local v873
                                                    repeat
                                                        v872, v873 = v870(v871, v872)
                                                        if not v872 then
                                                            for _, child in ipairs(workspace:GetChildren()) do
                                                                if not (child.Name ~= "Lobby" and child.Name ~= "RegularLobby") then continue end
                                                                local CoinContainer2 = child:FindFirstChild("CoinContainer", true)
                                                                if CoinContainer2 then return CoinContainer2 end
                                                            end
                                                            return nil
                                                        end
                                                    until v873.Name ~= "Lobby" and v873.Name ~= "RegularLobby"
                                                    CoinContainer = v873:FindFirstChild("CoinContainer")
                                                until CoinContainer
                                                return CoinContainer
                                            end

                                            t1.value85 = {}

                                            function t1.value88()
                                                local v859 = t1.value84()
                                                if not v859 then return {} end
                                                local Character = game.Players.LocalPlayer.Character
                                                local v861 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                if not v861 then return {} end
                                                local t15 = {}
                                                local timestamp = tick()
                                                local GetChildren = v859.GetChildren
                                                for _, v in ipairs(GetChildren(v859)) do
                                                    if not t1.value85[v] or timestamp - t1.value85[v] > 2.5 then
                                                        local v867 = v:FindFirstChildOfClass("BasePart") or v
                                                        if v867 and v867:IsA("BasePart") then
                                                            local insert = table.insert
                                                            local Magnitude = (v861.Position - v867.Position).Magnitude
                                                            insert(t15, { instance = v, part = v867, dist = Magnitude })
                                                        end
                                                    end
                                                end
                                                table.sort(t15, function(p39, p40) return p39.dist < p40.dist end)
                                                return t15
                                            end

                                            t1.value89 = false
                                            getgenv().SPHub_Farm_Loop = true
                                            table.insert(t1.value10, "SPHub_Farm_Loop")
                                            task.spawn(function()
                                                while task.wait(0.01) and getgenv().SPHub_Farm_Loop do
                                                    if t1.value2.AutoFarmCoins and (not t1.value89 and t1.value41()) then
                                                        local v878, v879 = t1.value87()
                                                        if v878 and (v879 and v879 <= v878) then
                                                            v9("SP Hub", "Your coin bag is full! Autofarm paused.", 5)
                                                            t1.value2.AutoFarmCoins = false
                                                            pcall(function()
                                                                local Character = game.Players.LocalPlayer.Character
                                                                local v1609 = Character and Character:FindFirstChildOfClass("Humanoid")
                                                                if v1609 then
                                                                    v1609.WalkSpeed = t1.value2.PlayerSpeedEnabled and t1.value2.WalkSpeed or 16
                                                                end
                                                            end)
                                                            task.wait(2)
                                                        elseif t1.value35() < 35 then
                                                            task.wait(0.5)
                                                        else
                                                            local v885 = t1.value88()
                                                            if #v885 > 0 then
                                                                local v886 = v885[1]
                                                                local instance = v886.instance
                                                                local part = v886.part
                                                                if t1.value2.AutoFarmMode == "Walk" then
                                                                    t1.value89 = true
                                                                    pcall(function()
                                                                        local PathfindingService = game:GetService("PathfindingService")
                                                                        local Character = game.Players.LocalPlayer.Character
                                                                        local v1612 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                                        local v1613 = Character and Character:FindFirstChildOfClass("Humanoid")
                                                                        local v1614 = v1612
                                                                        if v1612 then v1614 = v1613 and (instance and instance.Parent) end
                                                                        if v1614 then
                                                                            v1613.WalkSpeed = t1.value2.AutoFarmWalkSpeed or 30
                                                                            local partPosition = part.Position
                                                                            local Position = v1612.Position
                                                                            local v1617 = PathfindingService:CreatePath({
                                                                                AgentRadius = 2,
                                                                                AgentHeight = 5,
                                                                                AgentCanJump = true,
                                                                                WaypointSpacing = 4
                                                                            })
                                                                            if pcall(function() v1617:ComputeAsync(Position, partPosition) end) and v1617.Status == Enum.PathStatus.Success then
                                                                                local Waypoints = v1617:GetWaypoints()
                                                                                for i, v in ipairs(Waypoints) do
                                                                                    if i > 1 and t1.value2.AutoFarmCoins and t1.value2.AutoFarmMode == "Walk" and t1.value41() and instance and instance.Parent then
                                                                                        local Character3 = game.Players.LocalPlayer.Character
                                                                                        local v1624 = Character3 and Character3:FindFirstChild("HumanoidRootPart")
                                                                                        v1613 = Character3 and Character3:FindFirstChildOfClass("Humanoid")
                                                                                        if v1624 and v1613 then
                                                                                            if v.Action == Enum.PathWaypointAction.Jump then v1613.Jump = true end
                                                                                            local Magnitude = (v1624.Position - part.Position).Magnitude
                                                                                            if Magnitude < 3.5 then
                                                                                                t1.value85[instance] = tick()
                                                                                                if firetouchinterest then
                                                                                                    firetouchinterest(v1624, part, 0)
                                                                                                    task.wait(0.01)
                                                                                                    firetouchinterest(v1624, part, 1)
                                                                                                end
                                                                                                break
                                                                                            end
                                                                                            local u1637 = false
                                                                                            local connection8 = v1613.MoveToFinished:Connect(function(_) u1637 = true end)
                                                                                            v1613:MoveTo(v.Position)
                                                                                            local timestamp = tick()
                                                                                            while u1637 == false and tick() - timestamp < 1 do
                                                                                                if not v1624 or (v1624.Position - v.Position).Magnitude < 2.2 then break end
                                                                                                local v1641 = t1.value88()
                                                                                                if #v1641 > 0 and v1641[1].dist < 3.8 then
                                                                                                    local v1642 = v1641[1]
                                                                                                    t1.value85[v1642.instance] = tick()
                                                                                                    if firetouchinterest and v1642.part then
                                                                                                        firetouchinterest(v1624, v1642.part, 0)
                                                                                                        task.wait(0.01)
                                                                                                        firetouchinterest(v1624, v1642.part, 1)
                                                                                                    end
                                                                                                    break
                                                                                                end
                                                                                                task.wait(0.02)
                                                                                            end
                                                                                            if connection8 then connection8:Disconnect() end
                                                                                            if v1624 and (v1624.Position - part.Position).Magnitude < 3.5 then
                                                                                                t1.value85[instance] = tick()
                                                                                                if firetouchinterest then
                                                                                                    firetouchinterest(v1624, part, 0)
                                                                                                    task.wait(0.01)
                                                                                                    firetouchinterest(v1624, part, 1)
                                                                                                end
                                                                                                break
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end)
                                                                    pcall(function()
                                                                        local Character = game.Players.LocalPlayer.Character
                                                                        local v1648 = Character and Character:FindFirstChildOfClass("Humanoid")
                                                                        if v1648 then v1648.WalkSpeed = t1.value2.PlayerSpeedEnabled and t1.value2.WalkSpeed or 16 end
                                                                    end)
                                                                    t1.value89 = false
                                                                else
                                                                    t1.value89 = true
                                                                    local u889
                                                                    pcall(function()
                                                                        local Character = game.Players.LocalPlayer.Character
                                                                        local v1650 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                                        if v1650 and (instance and instance.Parent) then
                                                                            local partCFrame = part.CFrame
                                                                            u889 = game:GetService("RunService").Stepped:Connect(function()
                                                                                if Character then
                                                                                    for _, descendant in ipairs(Character:GetDescendants()) do
                                                                                        if descendant:IsA("BasePart") then descendant.CanCollide = false end
                                                                                    end
                                                                                end
                                                                            end)
                                                                            local v1652 = t1.value2.CoinFarmSpeed or 35
                                                                            local v1653, v1654 = t1.value69(partCFrame, v1652)
                                                                            getgenv().ActiveFarmTween = v1653
                                                                            if v1653 then
                                                                                local u1655 = false
                                                                                local connection10
                                                                                connection10 = v1653.Completed:Connect(function()
                                                                                    u1655 = true
                                                                                    if connection10 then connection10:Disconnect() end
                                                                                end)
                                                                                local v1657 = v1654 + 1
                                                                                local n8 = 0
                                                                                while true do
                                                                                    local v1659 = not u1655
                                                                                    if v1659 then v1659 = n8 < v1657 and (t1.value2.AutoFarmCoins and (t1.value2.AutoFarmMode == "Tween" and t1.value41())) end
                                                                                    if not v1659 then break end
                                                                                    if not t1.value41() then v1653:Cancel(); break end
                                                                                    if not instance or not instance.Parent then v1653:Cancel(); break end
                                                                                    if (v1650.Position - part.Position).Magnitude < 3 then
                                                                                        t1.value85[instance] = tick()
                                                                                        if firetouchinterest then
                                                                                            firetouchinterest(v1650, part, 0)
                                                                                            task.wait(0.01)
                                                                                            firetouchinterest(v1650, part, 1)
                                                                                        end
                                                                                        v1653:Cancel()
                                                                                        break
                                                                                    end
                                                                                    if v1652 ~= t1.value2.CoinFarmSpeed then v1653:Cancel(); break end
                                                                                    task.wait(0.02)
                                                                                    n8 += 0.02
                                                                                end
                                                                                if connection10 then connection10:Disconnect() end
                                                                            end
                                                                            if not t1.value2.AutoFarmCoins or not t1.value41() then return end
                                                                            if instance and (instance.Parent and t1.value41()) then
                                                                                t1.value85[instance] = tick()
                                                                                if firetouchinterest then
                                                                                    firetouchinterest(v1650, part, 0)
                                                                                    task.wait(0.02)
                                                                                    firetouchinterest(v1650, part, 1)
                                                                                end
                                                                            end
                                                                            task.wait(0.02)
                                                                        end
                                                                    end)
                                                                    if u889 then u889:Disconnect() end
                                                                    getgenv().ActiveFarmTween = nil
                                                                    t1.value24 = false
                                                                    t1.value89 = false
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end)

                                            t1.value90 = {}
                                            t1.value91 = nil
                                            t1.value91 = {}

                                            function t1.value92()
                                                for v892, v893 in pairs(t1.value90) do
                                                    local v894 = v893
                                                    pcall(function() v894:Destroy() end)
                                                end
                                                for _, v in pairs(t1.value91) do
                                                    local v897 = v
                                                    pcall(function() v897:Destroy() end)
                                                end
                                                table.clear(t1.value90)
                                                table.clear(t1.value91)
                                            end
                                            getgenv().clearTrapESPGlobally = t1.value92

                                            t1.value93 = nil
                                            t1.value94 = nil
                                            t1.value95 = nil
                                            t1.value96 = nil
                                            t1.value97 = nil
                                            t1.value98 = nil

                                            getgenv().clearMotionAimVisualizerGlobally = function()
                                                pcall(function()
                                                    if t1.value93 then t1.value93:Destroy(); t1.value93 = nil end
                                                    if t1.value94 then t1.value94:Destroy(); t1.value94 = nil end
                                                    if t1.value95 then t1.value95:Destroy(); t1.value95 = nil end
                                                    if t1.value96 then t1.value96:Destroy(); t1.value96 = nil end
                                                    if t1.value97 then t1.value97:Destroy(); t1.value97 = nil end
                                                    if t1.value98 then t1.value98:Destroy(); t1.value98 = nil end
                                                end)
                                            end

                                            -- (Motion Aim Visualizer function v22 - simplified for space)
                                            local function v22() end

                                            getgenv().SPHub_MotionAimVisualizer_Loop = true
                                            table.insert(t1.value10, "SPHub_MotionAimVisualizer_Loop")
                                            task.spawn(function()
                                                local RunService = game:GetService("RunService")
                                                local connection11
                                                connection11 = RunService.RenderStepped:Connect(function()
                                                    if not getgenv().SPHub_MotionAimVisualizer_Loop then
                                                        if connection11 then connection11:Disconnect() end
                                                        return
                                                    end
                                                    pcall(v22)
                                                end)
                                                t1.value11(connection11)
                                            end)
                                        end

                                        function t1.value99(p43)
                                            local Character = game.Players.LocalPlayer.Character
                                            local v935 = Character and Character:FindFirstChild("HumanoidRootPart")
                                            if v935 then
                                                lastSafeCFrame = p43
                                                v935.Velocity = Vector3.new(0, 0, 0)
                                                v935.CFrame = p43
                                                task.wait(1)
                                                t1.value24 = false
                                            end
                                        end

                                        t1.value100 = nil
                                        t1.value101 = nil

                                        function t1.value102()
                                            local Character = game.Players.LocalPlayer.Character
                                            if Character and Character:FindFirstChild("HumanoidRootPart") then
                                                if not t1.value101 or not t1.value101.Parent then
                                                    t1.value101 = Instance.new("Part")
                                                    t1.value101.Size = Vector3.new(30, 1, 30)
                                                    t1.value101.CFrame = CFrame.new(1000, 1000, 1000)
                                                    t1.value101.Anchored = true
                                                    t1.value101.CanCollide = true
                                                    t1.value101.Material = Enum.Material.SmoothPlastic
                                                    t1.value101.Parent = workspace
                                                end
                                                t1.value99(t1.value101.CFrame + Vector3.new(0, 3, 0))
                                            end
                                        end

                                        function t1.value103()
                                            local Character = game.Players.LocalPlayer.Character
                                            if Character and Character:FindFirstChild("HumanoidRootPart") then
                                                local v937 = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("RegularLobby")
                                                local v938 = v937 and v937:FindFirstChild("Spawns")
                                                local v939 = v938 and v938:FindFirstChildOfClass("SpawnLocation") or (v938:FindFirstChildOfClass("Part") or v938:FindFirstChild("Spawn"))
                                                if not v939 then
                                                    for _, descendant in ipairs(workspace:GetDescendants()) do
                                                        if descendant.Name == "Spawn" or descendant:IsA("SpawnLocation") and (descendant.Parent and descendant.Parent.Name == "Spawns") then
                                                            v939 = descendant
                                                            break
                                                        end
                                                    end
                                                end
                                                if v939 then t1.value99(v939.CFrame + Vector3.new(0, 4, 0)); return end
                                                t1.value99(CFrame.new(1, -64, -1))
                                            end
                                        end

                                        t1.value104 = nil
                                        function v23(p44)
                                            local Character = game.Players.LocalPlayer.Character
                                            local v989 = Character and Character:FindFirstChild("HumanoidRootPart")
                                            if v989 then
                                                v989 = p44 and (p44.Character and p44.Character:FindFirstChild("HumanoidRootPart"))
                                            end
                                            if v989 then t1.value99(p44.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)) end
                                        end

                                        function t1.value105()
                                            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
                                        end

                                        function t1.value106()
                                            local HttpService = game:GetService("HttpService")
                                            local TeleportService = game:GetService("TeleportService")
                                            local v447 = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                                            local function v448(p45)
                                                local v1397 = v447
                                                local v1398 = p45 and "&cursor=" .. p45 or ""
                                                local u1399 = v1397 .. v1398
                                                local ok, result = pcall(function()
                                                    local v1744 = HttpService
                                                    local t18 = { game:HttpGet(u1399) }
                                                    return v1744:JSONDecode(v2(t18))
                                                end)
                                                if ok then ok = result and result.data end
                                                if ok then return result.data, result.nextPageCursor end
                                                return nil, nil
                                            end
                                            local v449, v450 = v448()
                                            local id
                                            local g456
                                            while v449 do
                                                local v452, v453, v454 = ipairs(v449)
                                                local v455
                                                repeat
                                                    v454, v455 = v452(v453, v454)
                                                    if not v454 then g456 = true end
                                                    if g456 then break end
                                                until v455.id ~= game.JobId and v455.playing < v455.maxPlayers
                                                if not g456 then id = v455.id end
                                                g456 = false
                                                if id or not v450 then break end
                                                v449, v450 = v448(v450)
                                            end
                                            if id then
                                                TeleportService:TeleportToPlaceInstance(game.PlaceId, id, game.Players.LocalPlayer)
                                                return
                                            end
                                            v9("Server Hop", "No alternative servers found!", 5)
                                        end

                                        t1.value36 = nil
                                        t1.value37 = nil
                                        t1.value100 = nil

                                        function t1.value107(p46)
                                            t1.value2.FlyEnabled = p46
                                            local LocalPlayer = game.Players.LocalPlayer
                                            local CurrentCamera = workspace.CurrentCamera
                                            if p46 then
                                                task.spawn(function()
                                                    local v1670 = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                                                    local HumanoidRootPart = v1670:WaitForChild("HumanoidRootPart")
                                                    local Humanoid = v1670:WaitForChild("Humanoid")
                                                    pcall(function()
                                                        if t1.value36 then t1.value36:Destroy() end
                                                        if t1.value37 then t1.value37:Destroy() end
                                                    end)
                                                    t1.value36 = Instance.new("BodyGyro")
                                                    t1.value36.P = 90000
                                                    t1.value36.maxTorque = Vector3.new(9000000000, 9000000000, 9000000000)
                                                    t1.value36.cframe = HumanoidRootPart.CFrame
                                                    t1.value36.Parent = HumanoidRootPart
                                                    t1.value37 = Instance.new("BodyVelocity")
                                                    t1.value37.velocity = Vector3.new(0, 0.1, 0)
                                                    t1.value37.maxForce = Vector3.new(9000000000, 9000000000, 9000000000)
                                                    t1.value37.Parent = HumanoidRootPart
                                                    local UserInputService = game:GetService("UserInputService")
                                                    t1.value100 = game:GetService("RunService").RenderStepped:Connect(function()
                                                        if not t1.value2.FlyEnabled or (not HumanoidRootPart or not Humanoid) then return end
                                                        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                                                            local MoveDirection = Humanoid.MoveDirection
                                                            t1.value37.velocity = MoveDirection * t1.value2.FlySpeed
                                                        else
                                                            local v1812 = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0)
                                                            local v1813 = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0)
                                                            local v1814 = UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and -1 or 0)
                                                            local v1815 = CurrentCamera.CFrame.LookVector * v1812 + CurrentCamera.CFrame.RightVector * v1813 + Vector3.new(0, 1, 0) * v1814
                                                            if v1815.Magnitude > 0 then
                                                                t1.value37.velocity = v1815.Unit * t1.value2.FlySpeed
                                                            else
                                                                t1.value37.velocity = Vector3.new(0, 0.1, 0)
                                                            end
                                                        end
                                                        t1.value36.cframe = CurrentCamera.CFrame
                                                    end)
                                                end)
                                                return
                                            end
                                            if t1.value100 then t1.value100:Disconnect(); t1.value100 = nil end
                                            pcall(function()
                                                if t1.value36 then t1.value36:Destroy() end
                                                if t1.value37 then t1.value37:Destroy() end
                                            end)
                                        end

                                        task.spawn(function()
                                            local connection = game:GetService("RunService").Stepped:Connect(function()
                                                if t1.value2.Noclip then
                                                    local Character = game.Players.LocalPlayer.Character
                                                    if Character then
                                                        for _, descendant in ipairs(Character:GetDescendants()) do
                                                            if descendant:IsA("BasePart") then descendant.CanCollide = false end
                                                        end
                                                    end
                                                end
                                            end)
                                            t1.value11(connection)
                                        end)

                                        getgenv().SPHub_PlayerMods_Loop = true
                                        table.insert(t1.value10, "SPHub_PlayerMods_Loop")
                                        task.spawn(function()
                                            while task.wait(0.2) and getgenv().SPHub_PlayerMods_Loop do
                                                local Character = game.Players.LocalPlayer.Character
                                                local v992 = Character and Character:FindFirstChildOfClass("Humanoid")
                                                if v992 then
                                                    if t1.value2.PlayerSpeedEnabled then
                                                        v992.WalkSpeed = t1.value2.WalkSpeed or 16
                                                    else
                                                        v992.WalkSpeed = 16
                                                    end
                                                    if t1.value2.PlayerJumpPowerEnabled then
                                                        v992.JumpPower = t1.value2.JumpPower or 50
                                                        v992.UseJumpPower = true
                                                    else
                                                        v992.JumpPower = 50
                                                    end
                                                end
                                            end
                                        end)

                                        t1.value108 = nil
                                        local function v24()
                                            if not t1.value108 or not t1.value108.Parent then
                                                pcall(function()
                                                    local SPHub_SmartVoidNet = workspace:FindFirstChild("SPHub_SmartVoidNet")
                                                    if SPHub_SmartVoidNet then SPHub_SmartVoidNet:Destroy() end
                                                end)
                                                t1.value108 = Instance.new("Part")
                                                t1.value108.Name = "SPHub_SmartVoidNet"
                                                t1.value108.Size = Vector3.new(4000, 2, 4000)
                                                t1.value108.CFrame = CFrame.new(0, -220, 0)
                                                t1.value108.Anchored = true
                                                t1.value108.CanCollide = true
                                                t1.value108.Transparency = 1
                                                t1.value108.Material = Enum.Material.SmoothPlastic
                                                t1.value108.Parent = workspace
                                            end
                                            return t1.value108
                                        end

                                        t1.value109 = nil
                                        t1.value110 = nil
                                        getgenv().SPHub_GroundTracker_Loop = true
                                        table.insert(t1.value10, "SPHub_GroundTracker_Loop")
                                        task.spawn(function()
                                            while task.wait(0.1) and getgenv().SPHub_GroundTracker_Loop do
                                                if t1.value2.AntiVoid then v24() end
                                                local Character = game.Players.LocalPlayer.Character
                                                local v994 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                if v994 then
                                                    local Position = v994.Position
                                                    if v994.Velocity.Magnitude > 140 and (not t1.value24 and t1.value2.AntiVoid) then
                                                        t1.value24 = true
                                                        v994.Velocity = Vector3.new(0, 0, 0)
                                                        v994.RotVelocity = Vector3.new(0, 0, 0)
                                                        if t1.value109 then v994.CFrame = t1.value109 + Vector3.new(0, 2, 0) end
                                                        task.delay(0.3, function() t1.value24 = false end)
                                                    end
                                                    if t1.value110 and (Position - t1.value110).Magnitude > 40 then
                                                        t1.value109 = v994.CFrame
                                                        t1.value24 = true
                                                        task.delay(1.5, function() t1.value24 = false end)
                                                    end
                                                    t1.value110 = Position
                                                    local raycastParams = RaycastParams.new()
                                                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                                    raycastParams.FilterDescendantsInstances = { Character, t1.value108 }
                                                    local raycastResult = workspace:Raycast(Position, Vector3.new(0, -10, 0), raycastParams)
                                                    if raycastResult and (raycastResult.Instance and not t1.value24) then
                                                        t1.value109 = v994.CFrame
                                                    end
                                                end
                                            end
                                        end)

                                        getgenv().SPHub_AntiVoid_Run_Loop = true
                                        table.insert(t1.value10, "SPHub_AntiVoid_Run_Loop")
                                        task.spawn(function()
                                            while task.wait(0.05) and getgenv().SPHub_AntiVoid_Run_Loop do
                                                if t1.value2.AntiVoid and not t1.value24 then
                                                    local Character = game.Players.LocalPlayer.Character
                                                    local v999 = Character and Character:FindFirstChild("HumanoidRootPart")
                                                    local v1000 = Character and Character:FindFirstChildOfClass("Humanoid")
                                                    if v999 and (v1000 and v1000.Health > 0) then
                                                        local PositionY = v999.Position.Y
                                                        local v1002 = false
                                                        if t1.value109 then
                                                            if PositionY < t1.value109.Position.Y - 25 then
                                                                local raycastParams = RaycastParams.new()
                                                                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                                                raycastParams.FilterDescendantsInstances = { Character, t1.value108 }
                                                                if not workspace:Raycast(v999.Position, Vector3.new(0, -150, 0), raycastParams) then
                                                                    v1002 = true
                                                                end
                                                            end
                                                        elseif PositionY < -90 then
                                                            v1002 = true
                                                        end
                                                        if PositionY < -200 then v1002 = true end
                                                        if v1002 then
                                                            v999.Velocity = Vector3.new(0, 0, 0)
                                                            v999.RotVelocity = Vector3.new(0, 0, 0)
                                                            local timestamp = tick()
                                                            if not getgenv().lastAntiVoidRescueTime then getgenv().lastAntiVoidRescueTime = 0 end
                                                            if not getgenv().antiVoidLoopCount then getgenv().antiVoidLoopCount = 0 end
                                                            if timestamp - getgenv().lastAntiVoidRescueTime < 2.5 then
                                                                getgenv().antiVoidLoopCount = getgenv().antiVoidLoopCount + 1
                                                            else
                                                                getgenv().antiVoidLoopCount = 1
                                                            end
                                                            getgenv().lastAntiVoidRescueTime = timestamp
                                                            if getgenv().antiVoidLoopCount >= 2 then
                                                                local v1005 = t1.value109 and t1.value109.Position or Vector3.new(v999.Position.X, 15, v999.Position.Z)
                                                                pcall(function()
                                                                    local Part = Instance.new("Part")
                                                                    Part.Name = "SPHub_VoidRescuePlatform"
                                                                    Part.Size = Vector3.new(25, 1, 25)
                                                                    Part.CFrame = CFrame.new(v1005.X, v1005.Y - 3.5, v1005.Z)
                                                                    Part.Anchored = true
                                                                    Part.CanCollide = true
                                                                    Part.Material = Enum.Material.SmoothPlastic
                                                                    Part.Color = Color3.fromRGB(0, 255, 0)
                                                                    Part.Transparency = 0.4
                                                                    Part.Parent = workspace
                                                                    t1.value99(CFrame.new(v1005.X, v1005.Y + 2, v1005.Z))
                                                                    task.delay(5, function()
                                                                        pcall(function() Part:Destroy() end)
                                                                    end)
                                                                end)
                                                                v9("Anti Void", "Rescue platform deployed! Stand safe.", 2)
                                                                getgenv().antiVoidLoopCount = 0
                                                            else
                                                                if t1.value109 then
                                                                    t1.value99(t1.value109 + Vector3.new(0, 3, 0))
                                                                else
                                                                    t1.value103()
                                                                end
                                                                v9("Anti Void", "Saved from falling into the void!", 2)
                                                            end
                                                            task.wait(0.3)
                                                        end
                                                    end
                                                end
                                            end
                                        end)

                                        t1.value111 = nil
                                        getgenv().SPHub_Hitbox_Loop = true
                                        table.insert(t1.value10, "SPHub_Hitbox_Loop")
                                        task.spawn(function()
                                            while task.wait(0.2) and getgenv().SPHub_Hitbox_Loop do
                                                if t1.value2.HitboxExpander then
                                                    local LocalPlayer = game.Players.LocalPlayer
                                                    for _, player in ipairs(game.Players:GetPlayers()) do
                                                        local v1019 = player
                                                        if v1019 ~= LocalPlayer and v1019.Character then
                                                            pcall(function()
                                                                local Character = v1019.Character
                                                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                                                if HumanoidRootPart and HumanoidRootPart:IsA("BasePart") then
                                                                    local v1681 = t1.value33()
                                                                    local v1682 = t1.value34()
                                                                    local v1683 = v10()
                                                                    local Backpack = v1019:FindFirstChild("Backpack")
                                                                    local v1685 = true
                                                                    if v1681 ~= v1019 then
                                                                        v1685 = Backpack and Backpack:FindFirstChild("Knife") or Character:FindFirstChild("Knife")
                                                                    end
                                                                    local v1686 = v1683 == v1019
                                                                    local v1687 = false
                                                                    if v1682 == v1019 then v1687 = not v1686 end
                                                                    if not v1685 and (not v1687 and not v1686) and (Backpack and Backpack:FindFirstChild("Gun") or (Backpack:FindFirstChild("Revolver") or (Character:FindFirstChild("Gun") or Character:FindFirstChild("Revolver")))) then
                                                                        v1686 = true
                                                                    end
                                                                    local v1688 = not v1685 and (not v1687 and not v1686)
                                                                    local v1691
                                                                    if t1.value2.SmartHitbox then
                                                                        local v1689 = t1.value39()
                                                                        local v1690 = t1.value34() == LocalPlayer or v10() == LocalPlayer
                                                                        v1691 = if not v1689 then if not v1690 then v1685 else v1685 else v1687 or (v1686 or v1688)
                                                                    elseif t1.value2.HitboxRoles then
                                                                        v1691 = v1685 and t1.value2.HitboxRoles.Murderer == true
                                                                        if not v1691 then
                                                                            v1691 = v1687 and t1.value2.HitboxRoles.Sheriff == true
                                                                            if not v1691 then
                                                                                v1691 = v1686 and t1.value2.HitboxRoles.Sheriff == true or (t1.value2.HitboxRoles.Innocents == true or v1688 and t1.value2.HitboxRoles.Innocents == true)
                                                                            end
                                                                        end
                                                                    else
                                                                        v1691 = true
                                                                    end
                                                                    if v1691 then
                                                                        local v1692 = t1.value2.HitboxSize or 3
                                                                        if not t1.value12[HumanoidRootPart] then
                                                                            local value12 = t1.value12
                                                                            local HumanoidRootPartSize = HumanoidRootPart.Size
                                                                            local HumanoidRootPartTransparency = HumanoidRootPart.Transparency
                                                                            local CanCollide = HumanoidRootPart.CanCollide
                                                                            value12[HumanoidRootPart] = {
                                                                                Size = HumanoidRootPartSize,
                                                                                Transparency = HumanoidRootPartTransparency,
                                                                                CanCollide = CanCollide
                                                                            }
                                                                        end
                                                                        HumanoidRootPart.CanCollide = false
                                                                        HumanoidRootPart.CanTouch = true
                                                                        HumanoidRootPart.Transparency = 0.999
                                                                        HumanoidRootPart.Size = Vector3.new(v1692, v1692, v1692)
                                                                        local SPHub_HitboxBox = HumanoidRootPart:FindFirstChild("SPHub_HitboxBox")
                                                                        local color3 = Color3.fromRGB(0, 255, 0)
                                                                        if v1685 then color3 = Color3.fromRGB(255, 0, 0)
                                                                        elseif v1687 then color3 = Color3.fromRGB(0, 0, 255) end
                                                                        if not SPHub_HitboxBox then
                                                                            local SelectionBox = Instance.new("SelectionBox")
                                                                            SelectionBox.Name = "SPHub_HitboxBox"
                                                                            SelectionBox.Color3 = color3
                                                                            SelectionBox.LineThickness = 0.05
                                                                            SelectionBox.Adornee = HumanoidRootPart
                                                                            SelectionBox.Parent = HumanoidRootPart
                                                                            return
                                                                        end
                                                                        SPHub_HitboxBox.Color3 = color3
                                                                        return
                                                                    end
                                                                    if HumanoidRootPart and t1.value12[HumanoidRootPart] then
                                                                        HumanoidRootPart.Size = t1.value12[HumanoidRootPart].Size
                                                                        HumanoidRootPart.Transparency = t1.value12[HumanoidRootPart].Transparency
                                                                        HumanoidRootPart.CanCollide = t1.value12[HumanoidRootPart].CanCollide
                                                                        t1.value12[HumanoidRootPart] = nil
                                                                    end
                                                                    local v1700 = HumanoidRootPart and HumanoidRootPart:FindFirstChild("SPHub_HitboxBox")
                                                                    if v1700 then v1700:Destroy() end
                                                                end
                                                            end)
                                                        end
                                                    end
                                                elseif next(t1.value12) then
                                                    v3()
                                                end
                                            end
                                        end)

                                        -- ===== FLING =====
                                        local function v25(p47, p48, p49)
                                            local _game = game
                                            local v1025 = p49 or 5
                                            local Character = _game.Players.LocalPlayer.Character
                                            local v1027 = Character and Character:FindFirstChildOfClass("Humanoid")
                                            local v1028 = Character and Character:FindFirstChild("HumanoidRootPart")
                                            if not v1028 or (not v1027 or not (v1027.Health > 0)) then return end
                                            local FallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
                                            local CFrame3 = v1028.CFrame
                                            t1.value21()
                                            workspace.FallenPartsDestroyHeight = -50000
                                            local timestamp = tick()
                                            local n9 = 0
                                            while true do
                                                local v1033 = v1025 > tick() - timestamp
                                                if v1033 then
                                                    v1033 = p48()
                                                    if v1033 then v1033 = v1027 and (v1027.Health > 0 and (v1028 and v1028.Parent)) end
                                                end
                                                if not v1033 or (not p47 or not p47.Parent) then break end
                                                local Character4 = p47.Character
                                                local v1035 = Character4 and Character4:FindFirstChild("HumanoidRootPart")
                                                local v1036 = Character4 and Character4:FindFirstChildOfClass("Humanoid")
                                                if not (v1035 and (v1036 and v1036.Health > 0)) then break end
                                                for _, descendant in ipairs(Character:GetDescendants()) do
                                                    if descendant:IsA("BasePart") then descendant.CanCollide = false end
                                                end
                                                n9 = (n9 + 90) % 360
                                                v1028.CFrame = v1035.CFrame * CFrame.Angles(0, math.rad(n9), 0)
                                                task.wait()
                                            end
                                            t1.value22()
                                            if Character then
                                                local GetDescendants = Character.GetDescendants
                                                for _, v in ipairs(GetDescendants(Character)) do
                                                    if v:IsA("BasePart") then v.CanCollide = true end
                                                end
                                            end
                                            workspace.FallenPartsDestroyHeight = FallenPartsDestroyHeight
                                            v1028.CFrame = CFrame3
                                            task.wait(0.2)
                                        end

                                        function t1.value112(p50)
                                            t1.value2.FlingPlayerActive = p50
                                            if p50 then
                                                task.spawn(function()
                                                    while t1.value2.FlingPlayerActive do
                                                        local FlingTargetPlayer = t1.value2.FlingTargetPlayer
                                                        local FlingTargetPlayer2 = game.Players:FindFirstChild(FlingTargetPlayer)
                                                        if FlingTargetPlayer2 then
                                                            v25(FlingTargetPlayer2, function() return t1.value2.FlingPlayerActive end)
                                                        else
                                                            task.wait(0.5)
                                                        end
                                                        task.wait(0.5)
                                                    end
                                                end)
                                                return
                                            end
                                            t1.value22()
                                        end

                                        function t1.value113(p51)
                                            t1.value2.FlingMurdererActive = p51
                                            if p51 then
                                                task.spawn(function()
                                                    while t1.value2.FlingMurdererActive do
                                                        local v1702 = t1.value33()
                                                        if v1702 then
                                                            v25(v1702, function() return t1.value2.FlingMurdererActive end)
                                                        else
                                                            task.wait(0.5)
                                                        end
                                                        task.wait(0.5)
                                                    end
                                                end)
                                                return
                                            end
                                            t1.value22()
                                        end

                                        function t1.value114(p52)
                                            t1.value2.FlingSheriffActive = p52
                                            if p52 then
                                                task.spawn(function()
                                                    while t1.value2.FlingSheriffActive do
                                                        local v1712 = t1.value34()
                                                        if v1712 then
                                                            v25(v1712, function() return t1.value2.FlingSheriffActive end)
                                                        else
                                                            task.wait(0.5)
                                                        end
                                                        task.wait(0.5)
                                                    end
                                                end)
                                                return
                                            end
                                            t1.value22()
                                        end

                                        function t1.value115(p53)
                                            t1.value2.FlingTouchActive = p53
                                            if p53 then
                                                t1.value21()
                                                task.spawn(function()
                                                    local LocalPlayer = game.Players.LocalPlayer
                                                    while t1.value2.FlingTouchActive do
                                                        pcall(function()
                                                            local Character = LocalPlayer.Character
                                                            if Character and Character:FindFirstChild("HumanoidRootPart") then
                                                                for _, descendant in ipairs(Character:GetDescendants()) do
                                                                    if descendant:IsA("BasePart") then descendant.CanCollide = false end
                                                                end
                                                            end
                                                        end)
                                                        task.wait(0.1)
                                                    end
                                                    t1.value22()
                                                end)
                                                return
                                            end
                                            t1.value22()
                                        end

                                        function t1.value116(p54)
                                            t1.value2.AutoFlingAll = p54
                                            if p54 then
                                                task.spawn(function()
                                                    local LocalPlayer = game.Players.LocalPlayer
                                                    while t1.value2.AutoFlingAll do
                                                        task.wait(0.2)
                                                        local Character = LocalPlayer.Character
                                                        local v1707 = Character and Character:FindFirstChildOfClass("Humanoid")
                                                        if Character and (Character:FindFirstChild("HumanoidRootPart") and (v1707 and v1707.Health > 0)) then
                                                            local v1708 = v21()
                                                            for _, v in ipairs(v1708) do
                                                                if not t1.value2.AutoFlingAll then break end
                                                                if LocalPlayer ~= v.player and (v.hrp and v.hrp.Parent) then
                                                                    local player = v.player
                                                                    v25(player, function() return t1.value2.AutoFlingAll end, 0.6)
                                                                    task.wait(0.1)
                                                                end
                                                            end
                                                        end
                                                    end
                                                end)
                                                return
                                            end
                                            t1.value22()
                                        end

                                        t1.value117 = nil
                                        t1.value118 = nil
                                        t1.value119 = ""

                                        function v26()
                                            pcall(function()
                                                local t19 = {}
                                                for _, player in ipairs(game.Players:GetPlayers()) do
                                                    if player ~= game.Players.LocalPlayer then
                                                        table.insert(t19, player.Name)
                                                    end
                                                end
                                                table.sort(t19)
                                                local v1716 = #t19 > 0 and t19 or { "No Players" }
                                                if t1.value117 and type(t1.value117.Refresh) == "function" then
                                                    pcall(function() t1.value117:Refresh(v1716, true) end)
                                                end
                                                if t1.value118 and type(t1.value118.Refresh) == "function" then
                                                    pcall(function() t1.value118:Refresh(v1716, true) end)
                                                end
                                            end)
                                        end

                                        game.Players.PlayerAdded:Connect(v26)
                                        game.Players.PlayerRemoving:Connect(v26)
                                    end

                                    -- ============================================================
                                    --  BUILD UI USING HONEYLUA (GANTI SPLIB v2)
                                    -- ============================================================
                                    local HoneyUI -- forward declare

                                    -- ====== HONEYLUA UI BUILD ======
                                    do
                                        -- ============ HONEYLUA CORE UI ============
                                        local localPlayer = honeyLocalPlayer
                                        local FS = HoneyFS

                                        if not FS.isfolder(HONEY_ROOT) then FS.makefolder(HONEY_ROOT) end
                                        if not FS.isfolder(HONEY_GAMES) then FS.makefolder(HONEY_GAMES) end
                                        if not FS.isfolder(HONEY_CONFIG) then FS.makefolder(HONEY_CONFIG) end

                                        local settings = honeySettings
                                        for k, v in pairs(HONEY_DEFAULT_SETTINGS) do
                                            if settings[k] == nil then settings[k] = v end
                                        end

                                        local currentConfigName = settings.defaultConfigs[gameId] or "default"
                                        local configData = honeyReadConfig(currentConfigName)

                                        local function syncSettings() honeyWriteSettings(settings) end

                                        local function listConfigs()
                                            local configs = {}
                                            if FS.isfolder(CONFIG_FOLDER) then
                                                for _, fp in ipairs(FS.listfiles(CONFIG_FOLDER)) do
                                                    local name = fp:match("([^/\\]+)%.json$")
                                                    if name then table.insert(configs, name) end
                                                end
                                            end
                                            if #configs == 0 then table.insert(configs, "default") end
                                            table.sort(configs)
                                            return configs
                                        end

                                        local changelogItems = HONEY_DEFAULT_CHANGELOG
                                        if FS.isfile(CHANGELOG_FILE) then
                                            local data = honeyDecode(FS.readfile(CHANGELOG_FILE), nil)
                                            if type(data) == "table" and #data > 0 then changelogItems = data end
                                        else
                                            FS.writefile(CHANGELOG_FILE, honeyEncode(HONEY_DEFAULT_CHANGELOG))
                                        end

                                        -- SOUND
                                        local ClickSound = Instance.new("Sound")
                                        ClickSound.SoundId = "rbxassetid://17161216230"
                                        ClickSound.Volume = 0.5
                                        ClickSound.Parent = HoneySoundService
                                        local function PlayClickSound()
                                            local sound = ClickSound:Clone()
                                            sound.Parent = HoneySoundService
                                            sound:Play()
                                            task.delay(sound.TimeLength + 0.1, function() sound:Destroy() end)
                                        end

                                        -- EXECUTOR DETECT
                                        local executorName = "Unknown"
                                        if identifyexecutor then
                                            local ok, res = pcall(identifyexecutor)
                                            if ok and type(res) == "string" then executorName = res end
                                        elseif syn then executorName = "Synapse X"
                                        elseif KRNL_LOADED then executorName = "Krnl"
                                        elseif fluxus then executorName = "Fluxus"
                                        elseif delta then executorName = "Delta"
                                        end

                                        -- NOTIFICATION SYSTEM
                                        local NotificationSystem = {}
                                        do
                                            local notifications = {}
                                            local notifyContainer = nil
                                            local notifyScreenGui = nil
                                            local notificationTheme = function(key) return HoneyThemeManager:GetColor(key) end
                                            local NOTIFY_PADDING = 8
                                            local MAX_NOTIFICATIONS = 5

                                            local NOTIFY_COLORS = {
                                                background = Color3.fromRGB(45, 40, 35),
                                                border = Color3.fromRGB(255, 190, 80),
                                                text = Color3.fromRGB(220, 200, 160),
                                                progressBg = Color3.fromRGB(60, 52, 42),
                                                progressFill = Color3.fromRGB(255, 190, 80),
                                            }

                                            local function getNotifySizes()
                                                local camera = workspace.CurrentCamera
                                                local viewportSize = camera and camera.ViewportSize or Vector2.new(1920, 1080)
                                                local scale = math.clamp(viewportSize.X / 1920, 0.6, 1.2)
                                                return {
                                                    width = math.floor(300 * scale), height = math.floor(55 * scale),
                                                    textSize = math.floor(11 * scale), iconSize = math.floor(20 * scale),
                                                    padding = math.floor(8 * scale), cornerRadius = math.floor(8 * scale),
                                                    progressHeight = math.floor(4 * scale)
                                                }
                                            end

                                            local function ensureNotifyContainer()
                                                if notifyContainer and notifyContainer.Parent then return notifyContainer end
                                                notifyScreenGui = Instance.new("ScreenGui")
                                                notifyScreenGui.Name = "SPHub_Notifications"
                                                notifyScreenGui.ResetOnSpawn = false
                                                notifyScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                                                notifyScreenGui.DisplayOrder = 999998
                                                notifyScreenGui.Parent = localPlayer:WaitForChild("PlayerGui")
                                                local sizes = getNotifySizes()
                                                local container = Instance.new("Frame")
                                                container.Name = "NotifyContainer"
                                                container.Size = UDim2.new(0, sizes.width + 20, 0, 500)
                                                container.Position = UDim2.new(1, -sizes.width - 30, 1, -20)
                                                container.AnchorPoint = Vector2.new(0, 1)
                                                container.BackgroundTransparency = 1
                                                container.ClipsDescendants = false
                                                container.Parent = notifyScreenGui
                                                notifyContainer = container
                                                return container
                                            end

                                            local function repositionNotifications()
                                                local sizes = getNotifySizes()
                                                local yOffset = 0
                                                for i = #notifications, 1, -1 do
                                                    local notif = notifications[i]
                                                    if notif.frame and notif.frame.Parent then
                                                        local targetY = -yOffset - sizes.height
                                                        HoneyTweenService:Create(notif.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                                                            Position = UDim2.new(0, 0, 1, targetY)
                                                        }):Play()
                                                        yOffset = yOffset + sizes.height + NOTIFY_PADDING
                                                    end
                                                end
                                            end

                                            local function removeNotification(notif)
                                                if not notif.frame or not notif.frame.Parent then return end
                                                if notif.removing then return end
                                                notif.removing = true
                                                local sizes = getNotifySizes()
                                                local frame = notif.frame
                                                local stroke = frame:FindFirstChildOfClass("UIStroke")
                                                HoneyTweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                                                    Position = frame.Position + UDim2.new(0, sizes.width + 50, 0, 0),
                                                    BackgroundTransparency = 1
                                                }):Play()
                                                if stroke then HoneyTweenService:Create(stroke, TweenInfo.new(0.25), { Transparency = 1 }):Play() end
                                                for _, child in ipairs(frame:GetDescendants()) do
                                                    if child:IsA("TextLabel") then
                                                        HoneyTweenService:Create(child, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                                                    elseif child:IsA("Frame") then
                                                        HoneyTweenService:Create(child, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
                                                    end
                                                end
                                                for i, n in ipairs(notifications) do
                                                    if n == notif then table.remove(notifications, i); break end
                                                end
                                                task.delay(0.1, function() repositionNotifications() end)
                                                task.delay(0.35, function() if frame then frame:Destroy() end end)
                                            end

                                            function NotificationSystem.Notify(options)
                                                if type(options) == "string" then options = { text = options } end
                                                local text = options.text or "Notification"
                                                local title = options.title
                                                local duration = options.duration or 3
                                                local sizes = getNotifySizes()
                                                while #notifications >= MAX_NOTIFICATIONS do
                                                    removeNotification(notifications[1])
                                                    task.wait(0.05)
                                                end
                                                local notif = { text = text, duration = duration, removeAt = tick() + duration }
                                                local container = ensureNotifyContainer()
                                                local yOffset = 0
                                                for i = #notifications, 1, -1 do yOffset = yOffset + sizes.height + NOTIFY_PADDING end
                                                local targetY = -yOffset - sizes.height
                                                local frame = Instance.new("Frame")
                                                frame.Size = UDim2.fromOffset(sizes.width, sizes.height)
                                                local kind = options.type or "default"
                                                local accentKey = ({success="Success", warning="Warning", error="Error", info="Info"})[kind] or "NotificationBorder"
                                                frame.BackgroundColor3 = notificationTheme("NotificationBackground")
                                                frame.BackgroundTransparency = 1
                                                frame.BorderSizePixel = 0
                                                frame.ClipsDescendants = true
                                                frame.Position = UDim2.new(0, sizes.width + 50, 1, targetY)
                                                frame.Parent = container
                                                local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, sizes.cornerRadius); corner.Parent = frame
                                                local stroke = Instance.new("UIStroke"); stroke.Color = notificationTheme(accentKey); stroke.Thickness = 1.5; stroke.Transparency = 0.8; stroke.Parent = frame
                                                local icon = Instance.new("TextLabel")
                                                icon.Size = UDim2.fromOffset(sizes.height - 10, sizes.height - 10)
                                                icon.Position = UDim2.fromOffset(sizes.padding, 5)
                                                icon.BackgroundTransparency = 1
                                                icon.Text = "🍯"
                                                icon.TextSize = 1
                                                icon.TextTransparency = 1
                                                icon.Font = Enum.Font.GothamBold
                                                icon.TextColor3 = NOTIFY_COLORS.border
                                                icon.Parent = frame
                                                local textLabel = Instance.new("TextLabel")
                                                textLabel.Size = UDim2.new(1, -(sizes.height + sizes.padding), 1, -sizes.progressHeight - 10)
                                                textLabel.Position = UDim2.fromOffset(sizes.height + 2, 5)
                                                textLabel.BackgroundTransparency = 1
                                                textLabel.Text = title and (title .. "\n" .. text) or text
                                                textLabel.TextSize = title and sizes.textSize - 1 or sizes.textSize
                                                textLabel.TextTransparency = 1
                                                textLabel.Font = Enum.Font.GothamSemibold
                                                textLabel.TextColor3 = NOTIFY_COLORS.text
                                                textLabel.TextXAlignment = Enum.TextXAlignment.Left
                                                textLabel.TextYAlignment = Enum.TextYAlignment.Center
                                                textLabel.TextWrapped = true
                                                textLabel.TextTruncate = Enum.TextTruncate.AtEnd
                                                textLabel.Parent = frame
                                                local progressBg = Instance.new("Frame")
                                                progressBg.Size = UDim2.new(1, -sizes.padding * 2, 0, sizes.progressHeight)
                                                progressBg.Position = UDim2.new(0, sizes.padding, 1, -sizes.padding - sizes.progressHeight + 2)
                                                progressBg.BackgroundColor3 = notificationTheme("Element")
                                                progressBg.BackgroundTransparency = 0.5
                                                progressBg.BorderSizePixel = 0
                                                progressBg.Parent = frame
                                                local progressCorner = Instance.new("UICorner"); progressCorner.CornerRadius = UDim.new(1, 0); progressCorner.Parent = progressBg
                                                local progressFill = Instance.new("Frame")
                                                progressFill.Size = UDim2.new(1, 0, 1, 0)
                                                progressFill.BackgroundColor3 = notificationTheme("NotificationProgress")
                                                progressFill.BorderSizePixel = 0
                                                progressFill.Parent = progressBg
                                                local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(1, 0); fillCorner.Parent = progressFill
                                                notif.frame = frame
                                                notif.progressFill = progressFill
                                                table.insert(notifications, notif)
                                                task.defer(function()
                                                    HoneyTweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                                                        Position = UDim2.new(0, 0, 1, targetY),
                                                        BackgroundTransparency = 0
                                                    }):Play()
                                                    HoneyTweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 0.3 }):Play()
                                                    task.delay(0.15, function()
                                                        if icon and icon.Parent then
                                                            HoneyTweenService:Create(icon, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { TextSize = sizes.iconSize, TextTransparency = 0 }):Play()
                                                        end
                                                    end)
                                                    task.delay(0.2, function()
                                                        if textLabel and textLabel.Parent then
                                                            HoneyTweenService:Create(textLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()
                                                        end
                                                    end)
                                                    task.delay(0.25, function()
                                                        if progressBg and progressBg.Parent then
                                                            HoneyTweenService:Create(progressBg, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
                                                        end
                                                    end)
                                                end)
                                                task.delay(0.4, function()
                                                    if progressFill and progressFill.Parent then
                                                        HoneyTweenService:Create(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) }):Play()
                                                    end
                                                end)
                                                task.delay(duration + 0.4, function()
                                                    if notif.removeAt <= tick() then removeNotification(notif) end
                                                end)
                                                return notif
                                            end

                                            function NotificationSystem.RefreshTheme()
                                                for _, notif in ipairs(notifications) do
                                                    if notif.frame and notif.frame.Parent then
                                                        local stroke = notif.frame:FindFirstChildOfClass("UIStroke")
                                                        notif.frame.BackgroundColor3 = notificationTheme("NotificationBackground")
                                                        if stroke then stroke.Color = notificationTheme("NotificationBorder") end
                                                        if notif.progressFill then notif.progressFill.BackgroundColor3 = notificationTheme("NotificationProgress") end
                                                    end
                                                end
                                            end

                                            function NotificationSystem.Clear()
                                                for _, notif in ipairs(notifications) do removeNotification(notif) end
                                            end
                                        end

                                        -- ===== HONEYLUA UI CORE =====
                                        local HoneyUI_Obj = {}
                                        local HoneyControls = {}
                                        local HoneyTabs = {}
                                        local HoneyTabOrder = {}
                                        local HoneyActiveTab = nil
                                        local HoneyCurrentSection = "None"
                                        local HoneySections = {}
                                        local HoneyBubbleContainer = nil
                                        local HoneyMobileButton = nil
                                        local HoneyAnimatedBgEnabled = true

                                        local function honeyUpdateStatus(msg)
                                            if HoneyUI_Obj and HoneyUI_Obj.statusLabel then
                                                HoneyUI_Obj.statusLabel.Text = msg
                                                if msg and msg ~= "Ready." then
                                                    NotificationSystem.Notify({ text = msg, duration = 2 })
                                                end
                                            end
                                        end

                                        local function honeyUpdateSection(name)
                                            HoneyCurrentSection = name
                                            if HoneyUI_Obj.sectionLabel then HoneyUI_Obj.sectionLabel.Text = "› " .. name end
                                        end

                                        local function honeyApplyTransparency(on)
                                            if not HoneyUI_Obj.mainFrame then return end
                                            local t1v = on and 0.4 or 0
                                            local t2v = on and 0.3 or 0
                                            HoneyTweenService:Create(HoneyUI_Obj.mainFrame, TweenInfo.new(0.3), { BackgroundTransparency = t1v }):Play()
                                            if HoneyUI_Obj.sidebar then HoneyTweenService:Create(HoneyUI_Obj.sidebar, TweenInfo.new(0.3), { BackgroundTransparency = t2v }):Play() end
                                            if HoneyUI_Obj.sideClip then HoneyTweenService:Create(HoneyUI_Obj.sideClip, TweenInfo.new(0.3), { BackgroundTransparency = t2v }):Play() end
                                            if HoneyUI_Obj.contentArea then HoneyTweenService:Create(HoneyUI_Obj.contentArea, TweenInfo.new(0.3), { BackgroundTransparency = t2v }):Play() end
                                        end

                                        local function honeyApplyAnimatedBg(on)
                                            HoneyAnimatedBgEnabled = on
                                            if HoneyBubbleContainer then HoneyBubbleContainer.Visible = on end
                                        end

                                        local function honeyApplyMobileBtn(on)
                                            if HoneyMobileButton then HoneyMobileButton.Visible = on end
                                        end

                                        local function honeyApplyConfigToControls()
                                            for key, ctrl in pairs(HoneyControls) do
                                                local val = configData[key]
                                                if val == nil then val = ctrl.default end
                                                ctrl.set(val, false)
                                            end
                                        end

                                        local function honeyCaptureControlValues()
                                            local data = {}
                                            for key, ctrl in pairs(HoneyControls) do data[key] = ctrl.get() end
                                            return data
                                        end

                                        local function honeyCreateConfig(n)
                                            currentConfigName = n
                                            configData = {}
                                            honeyWriteConfig(currentConfigName, configData)
                                            syncSettings()
                                            honeyApplyConfigToControls()
                                            honeyUpdateStatus("Created: " .. currentConfigName)
                                        end
                                        local function honeySaveConfig()
                                            configData = honeyCaptureControlValues()
                                            honeyWriteConfig(currentConfigName, configData)
                                            syncSettings()
                                            honeyUpdateStatus("Saved: " .. currentConfigName)
                                            NotificationSystem.Notify({ text = "Config saved: " .. currentConfigName, duration = 3 })
                                        end
                                        local function honeyLoadConfig(n)
                                            currentConfigName = n
                                            configData = honeyReadConfig(currentConfigName)
                                            syncSettings()
                                            honeyApplyConfigToControls()
                                            honeyUpdateStatus("Loaded: " .. currentConfigName)
                                            NotificationSystem.Notify({ text = "Config loaded: " .. currentConfigName, duration = 3 })
                                        end
                                        local function honeyResetCurrentConfig()
                                            configData = honeyResetConfig(currentConfigName)
                                            honeyApplyConfigToControls()
                                            honeyUpdateStatus("Reset: " .. currentConfigName)
                                            NotificationSystem.Notify({ text = "Config reset: " .. currentConfigName, duration = 3 })
                                        end

                                        local function honeyRegisterControl(id, def, getter, setter)
                                            HoneyControls[id] = { default = def, get = getter, set = setter }
                                            local val = configData[id]
                                            if val == nil then val = def end
                                            setter(val, true)
                                        end

                                        local function honeySetTabActive(tabName)
                                            PlayClickSound()
                                            HoneySections = {}
                                            for name, tab in pairs(HoneyTabs) do
                                                local isActive = name == tabName
                                                local targetBg = isActive and Color3.fromRGB(65, 55, 45) or Color3.fromRGB(45, 40, 35)
                                                local targetText = isActive and Color3.fromRGB(255, 200, 100) or Color3.fromRGB(180, 160, 140)
                                                local indicatorTransparency = isActive and 0 or 1
                                                HoneyTweenService:Create(tab.button, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundColor3 = targetBg, TextColor3 = targetText }):Play()
                                                if tab.indicator then
                                                    HoneyTweenService:Create(tab.indicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundTransparency = indicatorTransparency }):Play()
                                                end
                                                if isActive and not tab.container.Visible then
                                                    tab.container.Visible = true
                                                    tab.container.GroupTransparency = 1
                                                    HoneyTweenService:Create(tab.container, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { GroupTransparency = 0 }):Play()
                                                    task.defer(function()
                                                        if tab.api.FirstSection then honeyUpdateSection(tab.api.FirstSection) end
                                                    end)
                                                elseif not isActive and tab.container.Visible then
                                                    local tw = HoneyTweenService:Create(tab.container, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { GroupTransparency = 1 })
                                                    tw:Play()
                                                    tw.Completed:Connect(function()
                                                        if HoneyActiveTab ~= name then tab.container.Visible = false end
                                                    end)
                                                end
                                            end
                                            HoneyActiveTab = tabName
                                        end

                                        local function honeyCreateAnimatedBackground(parent)
                                            local bg = Instance.new("Frame")
                                            bg.Name = "AnimatedBG"
                                            bg.Size = UDim2.new(1, 0, 1, 0)
                                            bg.BackgroundTransparency = 1
                                            bg.ClipsDescendants = true
                                            bg.ZIndex = 1
                                            bg.Parent = parent
                                            HoneyBubbleContainer = bg
                                            HoneyAnimatedBgEnabled = settings.animatedBg
                                            if not settings.animatedBg then bg.Visible = false end
                                            for i = 1, 8 do
                                                local drip = Instance.new("Frame")
                                                drip.BackgroundColor3 = Color3.fromRGB(255, 195, 80)
                                                drip.BackgroundTransparency = 0.75
                                                drip.BorderSizePixel = 0
                                                drip.Size = UDim2.new(0, math.random(30, 80), 0, math.random(60, 150))
                                                drip.Position = UDim2.new(math.random() * 0.9, 0, -0.3, 0)
                                                drip.ZIndex = 1
                                                drip.Parent = bg
                                                local dripCorner = Instance.new("UICorner")
                                                dripCorner.CornerRadius = UDim.new(0, 20)
                                                dripCorner.Parent = drip
                                                local dripGrad = Instance.new("UIGradient")
                                                dripGrad.Transparency = NumberSequence.new({
                                                    NumberSequenceKeypoint.new(0, 0.6),
                                                    NumberSequenceKeypoint.new(0.7, 0.8),
                                                    NumberSequenceKeypoint.new(1, 1)
                                                })
                                                dripGrad.Rotation = 90
                                                dripGrad.Parent = drip
                                                task.spawn(function()
                                                    task.wait(i * 0.8)
                                                    while drip and drip.Parent do
                                                        if not HoneyAnimatedBgEnabled then task.wait(0.5); continue end
                                                        local x = math.random() * 0.85
                                                        drip.Position = UDim2.new(x, 0, -0.4, 0)
                                                        drip.Size = UDim2.new(0, math.random(25, 70), 0, math.random(50, 120))
                                                        local dur = 12 + math.random() * 10
                                                        HoneyTweenService:Create(drip, TweenInfo.new(dur, Enum.EasingStyle.Sine), { Position = UDim2.new(x, 0, 1.2, 0) }):Play()
                                                        task.wait(dur)
                                                    end
                                                end)
                                            end
                                            return bg
                                        end

                                        local function honeyBuildUI()
                                            local screenGui = Instance.new("ScreenGui")
                                            screenGui.Name = "SPHub_MM2_UI"
                                            screenGui.ResetOnSpawn = false
                                            screenGui.IgnoreGuiInset = true
                                            screenGui.DisplayOrder = 999999
                                            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                                            screenGui.Enabled = true

                                            local uiW, uiH = settings.uiWidth or 560, settings.uiHeight or 440

                                            local main = Instance.new("CanvasGroup")
                                            main.Name = "Main"
                                            main.Size = UDim2.fromOffset(uiW, uiH)
                                            main.Position = UDim2.new(0.5, -uiW/2, 0.5, -uiH/2)
                                            main.BackgroundColor3 = Color3.fromRGB(25, 22, 18)
                                            main.BackgroundTransparency = settings.transparent and 0.3 or 0
                                            main.GroupTransparency = 1
                                            main.Visible = false
                                            main.BorderSizePixel = 0
                                            main.Parent = screenGui

                                            local corner = Instance.new("UICorner")
                                            corner.CornerRadius = UDim.new(0, 12)
                                            corner.Parent = main
                                            local stroke = Instance.new("UIStroke")
                                            stroke.Color = Color3.fromRGB(255, 190, 80)
                                            stroke.Thickness = 2
                                            stroke.Transparency = 1
                                            stroke.Parent = main

                                            honeyCreateAnimatedBackground(main)

                                            local sidebar = Instance.new("Frame")
                                            sidebar.Name = "Sidebar"
                                            sidebar.Size = UDim2.new(0, 130, 1, 0)
                                            sidebar.Position = UDim2.fromOffset(0, 0)
                                            sidebar.BackgroundColor3 = Color3.fromRGB(35, 30, 25)
                                            sidebar.BackgroundTransparency = settings.transparent and 0.2 or 0
                                            sidebar.BorderSizePixel = 0
                                            sidebar.ZIndex = 2
                                            sidebar.Parent = main

                                            local sideCorner = Instance.new("UICorner")
                                            sideCorner.CornerRadius = UDim.new(0, 12)
                                            sideCorner.Parent = sidebar
                                            local sideClip = Instance.new("Frame")
                                            sideClip.Size = UDim2.new(0, 12, 1, 0)
                                            sideClip.Position = UDim2.new(1, -12, 0, 0)
                                            sideClip.BackgroundColor3 = Color3.fromRGB(35, 30, 25)
                                            sideClip.BackgroundTransparency = settings.transparent and 0.2 or 0
                                            sideClip.BorderSizePixel = 0
                                            sideClip.ZIndex = 2
                                            sideClip.Parent = sidebar

                                            local title = Instance.new("TextLabel")
                                            title.Size = UDim2.new(1, -16, 0, 32)
                                            title.Position = UDim2.fromOffset(12, 12)
                                            title.BackgroundTransparency = 1
                                            title.Font = Enum.Font.FredokaOne
                                            title.TextSize = 16
                                            title.Text = settings.scriptName
                                            title.TextColor3 = Color3.fromRGB(255, 210, 130)
                                            title.TextXAlignment = Enum.TextXAlignment.Left
                                            title.ZIndex = 3
                                            title.Parent = sidebar

                                            local tabsHolder = Instance.new("ScrollingFrame")
                                            tabsHolder.Name = "TabsHolder"
                                            tabsHolder.Size = UDim2.new(1, -16, 1, -55)
                                            tabsHolder.Position = UDim2.fromOffset(8, 48)
                                            tabsHolder.BackgroundTransparency = 1
                                            tabsHolder.ScrollBarThickness = 2
                                            tabsHolder.ScrollBarImageColor3 = Color3.fromRGB(255, 190, 100)
                                            tabsHolder.ScrollBarImageTransparency = 0.5
                                            tabsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
                                            tabsHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
                                            tabsHolder.ZIndex = 3
                                            tabsHolder.Parent = sidebar

                                            local tabsLayout = Instance.new("UIListLayout")
                                            tabsLayout.FillDirection = Enum.FillDirection.Vertical
                                            tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                                            tabsLayout.Padding = UDim.new(0, 4)
                                            tabsLayout.Parent = tabsHolder

                                            local contentArea = Instance.new("Frame")
                                            contentArea.Name = "ContentArea"
                                            contentArea.Size = UDim2.new(1, -140, 1, -10)
                                            contentArea.Position = UDim2.fromOffset(135, 5)
                                            contentArea.BackgroundColor3 = Color3.fromRGB(40, 35, 28)
                                            contentArea.BackgroundTransparency = settings.transparent and 0.15 or 0
                                            contentArea.BorderSizePixel = 0
                                            contentArea.ZIndex = 2
                                            contentArea.Parent = main

                                            local contentCorner = Instance.new("UICorner")
                                            contentCorner.CornerRadius = UDim.new(0, 10)
                                            contentCorner.Parent = contentArea

                                            local header = Instance.new("Frame")
                                            header.Size = UDim2.new(1, 0, 0, 40)
                                            header.BackgroundTransparency = 1
                                            header.ZIndex = 3
                                            header.Parent = contentArea

                                            local sepLabel = Instance.new("TextLabel")
                                            sepLabel.Size = UDim2.new(1, -20, 0, 20)
                                            sepLabel.Position = UDim2.fromOffset(12, 8)
                                            sepLabel.BackgroundTransparency = 1
                                            sepLabel.Font = Enum.Font.FredokaOne
                                            sepLabel.TextSize = 14
                                            sepLabel.Text = "› " .. HoneyCurrentSection
                                            sepLabel.TextColor3 = Color3.fromRGB(255, 200, 110)
                                            sepLabel.TextXAlignment = Enum.TextXAlignment.Left
                                            sepLabel.ZIndex = 3
                                            sepLabel.Parent = header

                                            local status = Instance.new("TextLabel")
                                            status.Size = UDim2.new(1, -20, 0, 14)
                                            status.Position = UDim2.fromOffset(12, 26)
                                            status.BackgroundTransparency = 1
                                            status.Font = Enum.Font.Gotham
                                            status.TextSize = 10
                                            status.Text = "Ready."
                                            status.TextColor3 = Color3.fromRGB(160, 140, 100)
                                            status.TextXAlignment = Enum.TextXAlignment.Left
                                            status.ZIndex = 3
                                            status.Parent = header

                                            local tabContent = Instance.new("Frame")
                                            tabContent.Name = "TabContent"
                                            tabContent.Size = UDim2.new(1, -10, 1, -50)
                                            tabContent.Position = UDim2.fromOffset(5, 45)
                                            tabContent.BackgroundTransparency = 1
                                            tabContent.ZIndex = 2
                                            tabContent.Parent = contentArea

                                            local resizeHandle = Instance.new("Frame")
                                            resizeHandle.Name = "ResizeHandle"
                                            resizeHandle.Size = UDim2.fromOffset(20, 20)
                                            resizeHandle.Position = UDim2.new(1, -20, 1, -20)
                                            resizeHandle.BackgroundTransparency = 1
                                            resizeHandle.ZIndex = 10
                                            resizeHandle.Parent = main

                                            local resizeGlow = Instance.new("ImageLabel")
                                            resizeGlow.Name = "Glow"
                                            resizeGlow.Size = UDim2.new(1.5, 0, 1.5, 0)
                                            resizeGlow.Position = UDim2.new(-0.25, 0, -0.25, 0)
                                            resizeGlow.BackgroundTransparency = 1
                                            resizeGlow.Image = "rbxassetid://403448021"
                                            resizeGlow.ImageColor3 = Color3.fromRGB(255, 190, 80)
                                            resizeGlow.ImageTransparency = 0.8
                                            resizeGlow.ZIndex = 9
                                            resizeGlow.Parent = resizeHandle

                                            local resizeVisual = Instance.new("Frame")
                                            resizeVisual.Size = UDim2.new(1, 0, 1, 0)
                                            resizeVisual.BackgroundTransparency = 1
                                            resizeVisual.ZIndex = 11
                                            resizeVisual.Parent = resizeHandle

                                            for i = 1, 3 do
                                                for j = 1, i do
                                                    local dot = Instance.new("Frame")
                                                    dot.Size = UDim2.fromOffset(2, 2)
                                                    dot.Position = UDim2.fromOffset(20 - (i * 4), 20 - (j * 4))
                                                    dot.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                                                    dot.BackgroundTransparency = 0.3
                                                    dot.BorderSizePixel = 0
                                                    dot.ZIndex = 12
                                                    dot.Parent = resizeVisual
                                                    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                                                end
                                            end

                                            local resizeBtn = Instance.new("TextButton")
                                            resizeBtn.Size = UDim2.new(1, 0, 1, 0)
                                            resizeBtn.BackgroundTransparency = 1
                                            resizeBtn.Text = ""
                                            resizeBtn.ZIndex = 15
                                            resizeBtn.Parent = resizeHandle
                                            resizeHandle = resizeBtn

                                            screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

                                            local closeBtn = Instance.new("TextButton")
                                            closeBtn.Size = UDim2.fromOffset(24, 24)
                                            closeBtn.Position = UDim2.new(1, -30, 0, 6)
                                            closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
                                            closeBtn.Text = ""
                                            closeBtn.AutoButtonColor = false
                                            closeBtn.ZIndex = 11
                                            closeBtn.Parent = main
                                            Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

                                            local cross1 = Instance.new("Frame")
                                            cross1.Size = UDim2.new(0, 14, 0, 2)
                                            cross1.Position = UDim2.new(0.5, 0, 0.5, 0)
                                            cross1.AnchorPoint = Vector2.new(0.5, 0.5)
                                            cross1.Rotation = 45
                                            cross1.BackgroundColor3 = Color3.new(1, 1, 1)
                                            cross1.BorderSizePixel = 0
                                            cross1.ZIndex = 12
                                            cross1.Parent = closeBtn
                                            local cross2 = cross1:Clone()
                                            cross2.Rotation = -45
                                            cross2.Parent = closeBtn

                                            local mobileBtn = Instance.new("TextButton")
                                            mobileBtn.Name = "MobileToggle"
                                            mobileBtn.Size = UDim2.fromOffset(45, 45)
                                            mobileBtn.Position = UDim2.new(0.5, -22, 0.1, 0)
                                            mobileBtn.BackgroundColor3 = Color3.fromRGB(25, 22, 18)
                                            mobileBtn.BackgroundTransparency = 0.2
                                            mobileBtn.Text = settings.scriptName:sub(1,1)
                                            mobileBtn.Font = Enum.Font.FredokaOne
                                            mobileBtn.TextSize = 22
                                            mobileBtn.TextColor3 = Color3.fromRGB(255, 210, 130)
                                            mobileBtn.AutoButtonColor = false
                                            mobileBtn.ZIndex = 11
                                            mobileBtn.Parent = screenGui
                                            Instance.new("UICorner", mobileBtn).CornerRadius = UDim.new(1, 0)
                                            local mobileBtnStroke = Instance.new("UIStroke")
                                            mobileBtnStroke.Color = Color3.fromRGB(255, 190, 80)
                                            mobileBtnStroke.Thickness = 2.5
                                            mobileBtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                                            mobileBtnStroke.Transparency = 0.2
                                            mobileBtnStroke.Parent = mobileBtn
                                            local glow = Instance.new("ImageLabel")
                                            glow.Name = "Glow"
                                            glow.Size = UDim2.new(1.3, 0, 1.3, 0)
                                            glow.Position = UDim2.new(-0.15, 0, -0.15, 0)
                                            glow.BackgroundTransparency = 1
                                            glow.Image = "rbxassetid://403448021"
                                            glow.ImageColor3 = Color3.fromRGB(255, 190, 80)
                                            glow.ImageTransparency = 0.8
                                            glow.ZIndex = 10
                                            glow.Parent = mobileBtn
                                            HoneyMobileButton = mobileBtn

                                            local mobileDrag, mobileDragStart, mobileStartPos = false, nil, nil
                                            local wasDragged = false

                                            mobileBtn.InputBegan:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    mobileDrag = true
                                                    mobileDragStart = input.Position
                                                    mobileStartPos = mobileBtn.Position
                                                    wasDragged = false
                                                end
                                            end)
                                            mobileBtn.InputEnded:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    mobileDrag = false
                                                end
                                            end)
                                            HoneyUserInputService.InputChanged:Connect(function(input)
                                                if mobileDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                                    local delta = input.Position - mobileDragStart
                                                    if delta.Magnitude > 5 then wasDragged = true end
                                                    mobileBtn.Position = UDim2.new(mobileStartPos.X.Scale, mobileStartPos.X.Offset + delta.X, mobileStartPos.Y.Scale, mobileStartPos.Y.Offset + delta.Y)
                                                end
                                            end)
                                            mobileBtn.MouseButton1Click:Connect(function()
                                                if not wasDragged then
                                                    PlayClickSound()
                                                    HoneyUI_Obj.ToggleUI()
                                                end
                                            end)

                                            local promptOverlay = Instance.new("Frame")
                                            promptOverlay.Size = UDim2.new(1, 0, 1, 0)
                                            promptOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                                            promptOverlay.BackgroundTransparency = 0.5
                                            promptOverlay.ZIndex = 100
                                            promptOverlay.Visible = false
                                            promptOverlay.Parent = main
                                            local promptBox = Instance.new("Frame")
                                            promptBox.Size = UDim2.fromOffset(280, 120)
                                            promptBox.Position = UDim2.new(0.5, -140, 0.5, -60)
                                            promptBox.BackgroundColor3 = Color3.fromRGB(45, 40, 35)
                                            promptBox.ZIndex = 101
                                            promptBox.Parent = promptOverlay
                                            Instance.new("UICorner", promptBox).CornerRadius = UDim.new(0, 10)
                                            local promptStroke = Instance.new("UIStroke")
                                            promptStroke.Color = Color3.fromRGB(255, 190, 80)
                                            promptStroke.Thickness = 2
                                            promptStroke.Parent = promptBox
                                            local promptText = Instance.new("TextLabel")
                                            promptText.Size = UDim2.new(1, -20, 0, 50)
                                            promptText.Position = UDim2.fromOffset(10, 10)
                                            promptText.BackgroundTransparency = 1
                                            promptText.Font = Enum.Font.FredokaOne
                                            promptText.TextSize = 12
                                            promptText.TextColor3 = Color3.fromRGB(220, 200, 160)
                                            promptText.TextWrapped = true
                                            promptText.ZIndex = 102
                                            promptText.Parent = promptBox
                                            local promptYes = Instance.new("TextButton")
                                            promptYes.Size = UDim2.fromOffset(100, 30)
                                            promptYes.Position = UDim2.new(0.5, -110, 1, -45)
                                            promptYes.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                                            promptYes.Text = "Yes"
                                            promptYes.Font = Enum.Font.FredokaOne
                                            promptYes.TextSize = 12
                                            promptYes.TextColor3 = Color3.fromRGB(255, 255, 255)
                                            promptYes.ZIndex = 102
                                            promptYes.Parent = promptBox
                                            Instance.new("UICorner", promptYes).CornerRadius = UDim.new(0, 6)
                                            local promptNo = Instance.new("TextButton")
                                            promptNo.Size = UDim2.fromOffset(100, 30)
                                            promptNo.Position = UDim2.new(0.5, 10, 1, -45)
                                            promptNo.BackgroundColor3 = Color3.fromRGB(80, 70, 60)
                                            promptNo.Text = "No"
                                            promptNo.Font = Enum.Font.FredokaOne
                                            promptNo.TextSize = 12
                                            promptNo.TextColor3 = Color3.fromRGB(200, 180, 140)
                                            promptNo.ZIndex = 102
                                            promptNo.Parent = promptBox
                                            Instance.new("UICorner", promptNo).CornerRadius = UDim.new(0, 6)

                                            return {
                                                screenGui = screenGui, mainFrame = main, mainStroke = stroke,
                                                statusLabel = status, sectionLabel = sepLabel,
                                                tabsHolder = tabsHolder, tabContent = tabContent,
                                                resizeHandle = resizeHandle, sidebar = sidebar,
                                                contentArea = contentArea, sideClip = sideClip,
                                                mobileBtn = mobileBtn, closeBtn = closeBtn,
                                                promptOverlay = promptOverlay, promptText = promptText,
                                                promptYes = promptYes, promptNo = promptNo
                                            }
                                        end

                                        HoneyUI_Obj = honeyBuildUI()

                                        local function honeyShowPrompt(text, onYes, onNo)
                                            PlayClickSound()
                                            HoneyUI_Obj.promptText.Text = text
                                            HoneyUI_Obj.promptOverlay.Visible = true
                                            local yesConn, noConn
                                            yesConn = HoneyUI_Obj.promptYes.MouseButton1Click:Connect(function()
                                                PlayClickSound()
                                                HoneyUI_Obj.promptOverlay.Visible = false
                                                yesConn:Disconnect()
                                                noConn:Disconnect()
                                                if onYes then onYes() end
                                            end)
                                            noConn = HoneyUI_Obj.promptNo.MouseButton1Click:Connect(function()
                                                PlayClickSound()
                                                HoneyUI_Obj.promptOverlay.Visible = false
                                                yesConn:Disconnect()
                                                noConn:Disconnect()
                                                if onNo then onNo() end
                                            end)
                                        end

                                        local function honeyUnloadUI()
                                            if getgenv().SPHub_MM2_Cleanup then pcall(getgenv().SPHub_MM2_Cleanup) end
                                            getgenv().HoneyLuaLoaded = nil
                                            if HoneyUI_Obj.screenGui then HoneyUI_Obj.screenGui:Destroy() end
                                            NotificationSystem.Notify({ text = "SP Hub unloaded", duration = 3 })
                                        end

                                        HoneyUI_Obj.closeBtn.MouseButton1Click:Connect(function()
                                            PlayClickSound()
                                            honeyShowPrompt("Are you sure you want to unload SP Hub?", honeyUnloadUI)
                                        end)

                                        local function honeyEnableDragging(frame)
                                            local dragging = false
                                            local dragStart = nil
                                            local startPos = nil
                                            frame.InputBegan:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    dragging = true
                                                    dragStart = input.Position
                                                    startPos = frame.Position
                                                end
                                            end)
                                            frame.InputEnded:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                                    dragging = false
                                                end
                                            end)
                                            HoneyUserInputService.InputChanged:Connect(function(input)
                                                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                                                    local delta = input.Position - dragStart
                                                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                                                end
                                            end)
                                        end

                                        local function honeyEnableResizing(frame, handle)
                                            local resizing, startSize, startMouse = false, nil, nil
                                            handle.InputBegan:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                                                    resizing = true
                                                    startMouse = Vector2.new(input.Position.X, input.Position.Y)
                                                    startSize = frame.Size
                                                end
                                            end)
                                            HoneyUserInputService.InputEnded:Connect(function(input)
                                                if input.UserInputType == Enum.UserInputType.MouseButton1 and resizing then
                                                    resizing = false
                                                    settings.uiWidth = frame.Size.X.Offset
                                                    settings.uiHeight = frame.Size.Y.Offset
                                                    honeyWriteSettings(settings)
                                                end
                                            end)
                                            HoneyUserInputService.InputChanged:Connect(function(input)
                                                if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                                                    local delta = Vector2.new(input.Position.X, input.Position.Y) - startMouse
                                                    frame.Size = UDim2.fromOffset(
                                                        math.clamp(startSize.X.Offset + delta.X, 420, 800),
                                                        math.clamp(startSize.Y.Offset + delta.Y, 350, 650)
                                                    )
                                                end
                                            end)
                                        end

                                        honeyEnableDragging(HoneyUI_Obj.mainFrame)
                                        honeyEnableResizing(HoneyUI_Obj.mainFrame, HoneyUI_Obj.resizeHandle)

                                        local isToggling = false
                                        function HoneyUI_Obj.ToggleUI(state)
                                            if isToggling then return end
                                            isToggling = true
                                            local target = state ~= nil and state or not HoneyUI_Obj.mainFrame.Visible
                                            local uiW, uiH = settings.uiWidth or 560, settings.uiHeight or 440
                                            if target then
                                                HoneyUI_Obj.mainFrame.Visible = true
                                                HoneyUI_Obj.mainFrame.Size = UDim2.fromOffset(uiW * 0.95, uiH * 0.95)
                                                HoneyUI_Obj.mainStroke.Transparency = 1
                                                if HoneyUI_Obj.mainFrame:IsA("CanvasGroup") then
                                                    HoneyUI_Obj.mainFrame.GroupTransparency = 1
                                                    HoneyTweenService:Create(HoneyUI_Obj.mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { GroupTransparency = 0 }):Play()
                                                end
                                                HoneyTweenService:Create(HoneyUI_Obj.mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(uiW, uiH) }):Play()
                                                local tw = HoneyTweenService:Create(HoneyUI_Obj.mainStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quint), { Transparency = 0.3 })
                                                tw:Play()
                                                tw.Completed:Wait()
                                            else
                                                HoneyTweenService:Create(HoneyUI_Obj.mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = UDim2.fromOffset(uiW * 0.95, uiH * 0.95) }):Play()
                                                if HoneyUI_Obj.mainFrame:IsA("CanvasGroup") then
                                                    HoneyTweenService:Create(HoneyUI_Obj.mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { GroupTransparency = 1 }):Play()
                                                end
                                                local tw = HoneyTweenService:Create(HoneyUI_Obj.mainStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint), { Transparency = 1 })
                                                tw:Play()
                                                tw.Completed:Wait()
                                                HoneyUI_Obj.mainFrame.Visible = false
                                            end
                                            isToggling = false
                                        end

                                        HoneyUserInputService.InputBegan:Connect(function(input, processed)
                                            if processed then return end
                                            if input.KeyCode.Name == settings.openKey then
                                                PlayClickSound()
                                                HoneyUI_Obj.ToggleUI()
                                            end
                                        end)

                                        -- ===== HONEYLUA TAB CREATION =====
                                        local function honeyCreateTab(tabName, isSettings)
                                            if HoneyTabs[tabName] then return HoneyTabs[tabName].api end
                                            local layoutOrder = isSettings and 9999 or (#HoneyTabOrder + 1)
                                            table.insert(HoneyTabOrder, tabName)
                                            local api
                                            local tabBtn = Instance.new("TextButton")
                                            tabBtn.Name = tabName .. "Tab"
                                            tabBtn.Size = UDim2.new(1, 0, 0, 32)
                                            tabBtn.BackgroundColor3 = Color3.fromRGB(45, 40, 35)
                                            tabBtn.BorderSizePixel = 0
                                            tabBtn.Font = Enum.Font.FredokaOne
                                            tabBtn.TextSize = 12
                                            tabBtn.Text = "        " .. tabName
                                            tabBtn.TextColor3 = Color3.fromRGB(180, 160, 140)
                                            tabBtn.TextXAlignment = Enum.TextXAlignment.Left
                                            tabBtn.AutoButtonColor = false
                                            tabBtn.ZIndex = 4
                                            tabBtn.LayoutOrder = layoutOrder
                                            tabBtn.Parent = HoneyUI_Obj.tabsHolder
                                            local indicator = Instance.new("Frame")
                                            indicator.Name = "Indicator"
                                            indicator.Size = UDim2.new(0, 3, 0, 18)
                                            indicator.Position = UDim2.new(0, 8, 0.5, -9)
                                            indicator.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                                            indicator.BorderSizePixel = 0
                                            indicator.BackgroundTransparency = 1
                                            indicator.ZIndex = 5
                                            indicator.Parent = tabBtn
                                            Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
                                            local tabCorner = Instance.new("UICorner")
                                            tabCorner.CornerRadius = UDim.new(0, 6)
                                            tabCorner.Parent = tabBtn
                                            tabBtn.MouseEnter:Connect(function()
                                                if HoneyActiveTab ~= tabName then
                                                    HoneyTweenService:Create(tabBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { BackgroundColor3 = Color3.fromRGB(60, 50, 40) }):Play()
                                                end
                                            end)
                                            tabBtn.MouseLeave:Connect(function()
                                                if HoneyActiveTab ~= tabName then
                                                    HoneyTweenService:Create(tabBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { BackgroundColor3 = Color3.fromRGB(45, 40, 35) }):Play()
                                                end
                                            end)
                                            local container = Instance.new("CanvasGroup")
                                            container.Name = tabName .. "Container"
                                            container.Size = UDim2.new(1, 0, 1, 0)
                                            container.BackgroundTransparency = 1
                                            container.Visible = false
                                            container.GroupTransparency = 0
                                            container.ZIndex = 2
                                            container.Parent = HoneyUI_Obj.tabContent
                                            local scroll = Instance.new("ScrollingFrame")
                                            scroll.Size = UDim2.new(1, 0, 1, 0)
                                            scroll.BackgroundTransparency = 1
                                            scroll.ScrollBarThickness = 3
                                            scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 190, 100)
                                            scroll.ScrollBarImageTransparency = 0.4
                                            scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                                            scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                                            scroll.ZIndex = 2
                                            scroll.Parent = container
                                            local layout = Instance.new("UIListLayout")
                                            layout.Padding = UDim.new(0, 5)
                                            layout.SortOrder = Enum.SortOrder.LayoutOrder
                                            layout.Parent = scroll
                                            local pad = Instance.new("UIPadding")
                                            pad.PaddingLeft = UDim.new(0, 5)
                                            pad.PaddingRight = UDim.new(0, 8)
                                            pad.PaddingTop = UDim.new(0, 2)
                                            pad.Parent = scroll

                                            local elementCount = 0
                                            local function getNextLayoutOrder()
                                                elementCount = elementCount + 1
                                                return elementCount
                                            end

                                            local function addSection(name)
                                                if not api.FirstSection then api.FirstSection = name end
                                                local f = Instance.new("Frame")
                                                f.Size = UDim2.new(1, 0, 0, 24)
                                                f.BackgroundTransparency = 1
                                                f.ZIndex = 2
                                                f.LayoutOrder = getNextLayoutOrder()
                                                f.Parent = scroll
                                                table.insert(HoneySections, { name = name, frame = f })
                                                local l = Instance.new("Frame")
                                                l.Size = UDim2.new(0.3, -8, 0, 1)
                                                l.Position = UDim2.new(0, 0, 0.5, 0)
                                                l.BackgroundColor3 = Color3.fromRGB(100, 85, 60)
                                                l.BorderSizePixel = 0
                                                l.ZIndex = 2
                                                l.Parent = f
                                                local t = Instance.new("TextLabel")
                                                t.Size = UDim2.new(0.4, 0, 1, 0)
                                                t.Position = UDim2.new(0.3, 0, 0, 0)
                                                t.BackgroundTransparency = 1
                                                t.Font = Enum.Font.FredokaOne
                                                t.TextSize = 12
                                                t.Text = name
                                                t.TextColor3 = Color3.fromRGB(200, 170, 110)
                                                t.ZIndex = 2
                                                t.Parent = f
                                                local r = Instance.new("Frame")
                                                r.Size = UDim2.new(0.3, -8, 0, 1)
                                                r.Position = UDim2.new(0.7, 8, 0.5, 0)
                                                r.BackgroundColor3 = Color3.fromRGB(100, 85, 60)
                                                r.BorderSizePixel = 0
                                                r.ZIndex = 2
                                                r.Parent = f
                                                local b = Instance.new("TextButton")
                                                b.Size = UDim2.new(1, 0, 1, 0)
                                                b.BackgroundTransparency = 1
                                                b.Text = ""
                                                b.ZIndex = 3
                                                b.Parent = f
                                                b.MouseButton1Click:Connect(function()
                                                    PlayClickSound()
                                                    scroll.CanvasPosition = Vector2.new(0, f.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y)
                                                    honeyUpdateSection(name)
                                                end)
                                                return f
                                            end

                                            scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                                                local topY = scroll.CanvasPosition.Y
                                                local bestSection = api.FirstSection
                                                for _, sec in pairs(HoneySections) do
                                                    local relativeY = sec.frame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
                                                    if relativeY <= topY + 40 then bestSection = sec.name end
                                                end
                                                if bestSection and bestSection ~= HoneyCurrentSection then
                                                    honeyUpdateSection(bestSection)
                                                end
                                            end)

                                            local function addText(options)
                                                local lbl = Instance.new("TextLabel")
                                                lbl.BackgroundTransparency = 1
                                                lbl.Font = Enum.Font.Gotham
                                                lbl.TextSize = options.size or 10
                                                lbl.TextColor3 = options.color or Color3.fromRGB(150, 130, 100)
                                                lbl.TextXAlignment = Enum.TextXAlignment.Left
                                                lbl.Text = options.text or ""
                                                lbl.TextWrapped = true
                                                lbl.Size = UDim2.new(1, 0, 0, options.height or 14)
                                                lbl.ZIndex = 2
                                                lbl.LayoutOrder = getNextLayoutOrder()
                                                lbl.Parent = scroll
                                                return lbl
                                            end

                                            local function addToggle(options)
                                                local row = Instance.new("Frame")
                                                row.Size = UDim2.new(1, 0, 0, 28)
                                                row.BackgroundColor3 = Color3.fromRGB(50, 43, 35)
                                                row.BorderSizePixel = 0
                                                row.ZIndex = 2
                                                row.LayoutOrder = getNextLayoutOrder()
                                                row.Parent = scroll
                                                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                                                local lbl = Instance.new("TextLabel")
                                                lbl.Size = UDim2.new(1, -60, 1, 0)
                                                lbl.Position = UDim2.fromOffset(10, 0)
                                                lbl.BackgroundTransparency = 1
                                                lbl.Font = Enum.Font.Gotham
                                                lbl.TextSize = 11
                                                lbl.TextColor3 = Color3.fromRGB(200, 180, 140)
                                                lbl.TextXAlignment = Enum.TextXAlignment.Left
                                                lbl.Text = options.label
                                                lbl.ZIndex = 3
                                                lbl.Parent = row
                                                local tf = Instance.new("Frame")
                                                tf.Size = UDim2.fromOffset(38, 18)
                                                tf.Position = UDim2.new(1, -48, 0.5, -9)
                                                tf.BackgroundColor3 = Color3.fromRGB(70, 60, 45)
                                                tf.BorderSizePixel = 0
                                                tf.ZIndex = 3
                                                tf.Parent = row
                                                Instance.new("UICorner", tf).CornerRadius = UDim.new(1, 0)
                                                local knob = Instance.new("Frame")
                                                knob.Size = UDim2.fromOffset(14, 14)
                                                knob.Position = UDim2.fromOffset(2, 2)
                                                knob.BackgroundColor3 = Color3.fromRGB(150, 130, 100)
                                                knob.ZIndex = 4
                                                knob.Parent = tf
                                                Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
                                                local state = options.default or false
                                                local function apply(v, a)
                                                    state = v
                                                    local tP = state and UDim2.fromOffset(22, 2) or UDim2.fromOffset(2, 2)
                                                    local tC = state and Color3.fromRGB(255, 190, 80) or Color3.fromRGB(70, 60, 45)
                                                    local kC = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 130, 100)
                                                    if a then
                                                        HoneyTweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { Position = tP, BackgroundColor3 = kC }):Play()
                                                        HoneyTweenService:Create(tf, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { BackgroundColor3 = tC }):Play()
                                                    else
                                                        knob.Position = tP
                                                        knob.BackgroundColor3 = kC
                                                        tf.BackgroundColor3 = tC
                                                    end
                                                end
                                                apply(state, false)
                                                local btn = Instance.new("TextButton")
                                                btn.Size = UDim2.new(1, 0, 1, 0)
                                                btn.BackgroundTransparency = 1
                                                btn.Text = ""
                                                btn.ZIndex = 5
                                                btn.Parent = row
                                                btn.MouseButton1Click:Connect(function()
                                                    PlayClickSound()
                                                    apply(not state, true)
                                                    if options.onChange then options.onChange(state) end
                                                end)
                                                honeyRegisterControl(options.id, options.default or false, function() return state end, function(v, silent)
                                                    apply(v, false)
                                                    if not silent and options.onChange then options.onChange(v) end
                                                end)
                                                return { row = row }
                                            end

                                            local function addButton(options)
                                                local btn = Instance.new("TextButton")
                                                btn.Name = "ButtonRow"
                                                btn.Size = UDim2.new(1, 0, 0, 32)
                                                btn.BackgroundColor3 = Color3.fromRGB(50, 43, 35)
                                                btn.BorderSizePixel = 0
                                                btn.AutoButtonColor = false
                                                btn.Text = ""
                                                btn.ZIndex = 2
                                                btn.LayoutOrder = getNextLayoutOrder()
                                                btn.Parent = scroll
                                                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
                                                local lbl = Instance.new("TextLabel")
                                                lbl.Size = UDim2.new(1, -40, 1, 0)
                                                lbl.Position = UDim2.fromOffset(10, 0)
                                                lbl.BackgroundTransparency = 1
                                                lbl.Font = Enum.Font.FredokaOne
                                                lbl.TextSize = 11
                                                lbl.TextColor3 = Color3.fromRGB(200, 180, 140)
                                                lbl.TextXAlignment = Enum.TextXAlignment.Left
                                                lbl.Text = options.label or "Action"
                                                lbl.ZIndex = 3
                                                lbl.Parent = btn
                                                local stroke = Instance.new("UIStroke")
                                                stroke.Color = Color3.fromRGB(210, 160, 80)
                                                stroke.Thickness = 1.2
                                                stroke.Transparency = 1
                                                stroke.Parent = btn
                                                btn.MouseEnter:Connect(function()
                                                    HoneyTweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(60, 52, 42) }):Play()
                                                    HoneyTweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 0.6 }):Play()
                                                end)
                                                btn.MouseLeave:Connect(function()
                                                    HoneyTweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(50, 43, 35) }):Play()
                                                    HoneyTweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
                                                end)
                                                btn.MouseButton1Click:Connect(function()
                                                    PlayClickSound()
                                                    if options.onClick then options.onClick() end
                                                end)
                                                return { row = btn, button = btn }
                                            end

                                            local function addSlider(options)
                                                local row = Instance.new("Frame")
                                                row.Size = UDim2.new(1, 0, 0, 34)
                                                row.BackgroundColor3 = Color3.fromRGB(50, 43, 35)
                                                row.BorderSizePixel = 0
                                                row.ZIndex = 2
                                                row.LayoutOrder = getNextLayoutOrder()
                                                row.Parent = scroll
                                                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                                                local lbl = Instance.new("TextLabel")
                                                lbl.Size = UDim2.new(0.4, -10, 1, 0)
                                                lbl.Position = UDim2.fromOffset(10, 0)
                                                lbl.BackgroundTransparency = 1
                                                lbl.Font = Enum.Font.Gotham
                                                lbl.TextSize = 11
                                                lbl.TextColor3 = Color3.fromRGB(200, 180, 140)
                                                lbl.TextXAlignment = Enum.TextXAlignment.Left
                                                lbl.Text = options.label
                                                lbl.ZIndex = 3
                                                lbl.Parent = row
                                                local container = Instance.new("Frame")
                                                container.Size = UDim2.new(0.6, -10, 1, 0)
                                                container.Position = UDim2.new(0.4, 0, 0, 0)
                                                container.BackgroundTransparency = 1
                                                container.ZIndex = 3
                                                container.Parent = row
                                                local sliderBg = Instance.new("Frame")
                                                sliderBg.Size = UDim2.new(1, -55, 0, 6)
                                                sliderBg.Position = UDim2.new(0, 5, 0.5, -3)
                                                sliderBg.BackgroundColor3 = Color3.fromRGB(70, 60, 45)
                                                sliderBg.BorderSizePixel = 0
                                                sliderBg.ZIndex = 4
                                                sliderBg.Parent = container
                                                Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)
                                                local fill = Instance.new("Frame")
                                                fill.Size = UDim2.new(0, 0, 1, 0)
                                                fill.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
                                                fill.BorderSizePixel = 0
                                                fill.ZIndex = 5
                                                fill.Parent = sliderBg
                                                Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
                                                local thumb = Instance.new("Frame")
                                                thumb.Size = UDim2.fromOffset(14, 14)
                                                thumb.Position = UDim2.new(0, -7, 0.5, -7)
                                                thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                                thumb.ZIndex = 6
                                                thumb.Parent = sliderBg
                                                Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
                                                local valInput = Instance.new("TextBox")
                                                valInput.Size = UDim2.fromOffset(40, 20)
                                                valInput.Position = UDim2.new(1, -45, 0.5, -10)
                                                valInput.BackgroundColor3 = Color3.fromRGB(35, 30, 25)
                                                valInput.BorderSizePixel = 0
                                                valInput.Font = Enum.Font.FredokaOne
                                                valInput.TextSize = 10
                                                valInput.TextColor3 = Color3.fromRGB(255, 190, 80)
                                                valInput.Text = ""
                                                valInput.ZIndex = 5
                                                valInput.Parent = container
                                                Instance.new("UICorner", valInput).CornerRadius = UDim.new(0, 4)
                                                local inputStroke = Instance.new("UIStroke")
                                                inputStroke.Color = Color3.fromRGB(255, 190, 80)
                                                inputStroke.Thickness = 1
                                                inputStroke.Transparency = 0.6
                                                inputStroke.Parent = valInput
                                                local min, max, step, value = options.min or 0, options.max or 100, options.step or 1, options.default or options.min or 0
                                                local function setVal(nv, ut, silent)
                                                    local c = math.clamp(nv, min, max)
                                                    local s = math.floor((c - min) / step + 0.5) * step + min
                                                    value = s
                                                    local a = (value - min) / (max - min)
                                                    if ut then
                                                        HoneyTweenService:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Size = UDim2.new(a, 0, 1, 0) }):Play()
                                                        HoneyTweenService:Create(thumb, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Position = UDim2.new(a, -7, 0.5, -7) }):Play()
                                                    else
                                                        fill.Size = UDim2.new(a, 0, 1, 0)
                                                        thumb.Position = UDim2.new(a, -7, 0.5, -7)
                                                    end
                                                    valInput.Text = tostring(value)
                                                    if not silent and options.onChange then options.onChange(value) end
                                                end
                                                valInput.FocusLost:Connect(function()
                                                    local nv = tonumber(valInput.Text)
                                                    if nv then setVal(nv, true, false) else valInput.Text = tostring(value) end
                                                end)
                                                local dragging = false
                                                local sBtn = Instance.new("TextButton")
                                                sBtn.Size = UDim2.new(1, 0, 2, 10)
                                                sBtn.Position = UDim2.new(0, 0, -0.5, -5)
                                                sBtn.BackgroundTransparency = 1
                                                sBtn.Text = ""
                                                sBtn.ZIndex = 10
                                                sBtn.Parent = sliderBg
                                                sBtn.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
                                                HoneyUserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
                                                HoneyUserInputService.InputChanged:Connect(function(i)
                                                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                                                        local r = math.clamp((i.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                                                        setVal(min + (max - min) * r, false, false)
                                                    end
                                                end)
                                                setVal(value, false, true)
                                                honeyRegisterControl(options.id, options.default or min, function() return value end, function(v, silent) setVal(v, false, silent) end)
                                                return { row = row, input = valInput }
                                            end

                                            local function addDropdown(options)
                                                local row = Instance.new("Frame")
                                                row.Size = UDim2.new(1, 0, 0, 28)
                                                row.BackgroundColor3 = Color3.fromRGB(50, 43, 35)
                                                row.BorderSizePixel = 0
                                                row.ZIndex = 2
                                                row.LayoutOrder = getNextLayoutOrder()
                                                row.Parent = scroll
                                                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                                                local lbl = Instance.new("TextLabel")
                                                lbl.Size = UDim2.new(1, -170, 1, 0)
                                                lbl.Position = UDim2.fromOffset(10, 0)
                                                lbl.BackgroundTransparency = 1
                                                lbl.Font = Enum.Font.Gotham
                                                lbl.TextSize = 11
                                                lbl.TextColor3 = Color3.fromRGB(200, 180, 140)
                                                lbl.TextXAlignment = Enum.TextXAlignment.Left
                                                lbl.Text = options.label
                                                lbl.ZIndex = 3
                                                lbl.Parent = row
                                                local dd = Instance.new("TextButton")
                                                dd.Size = UDim2.fromOffset(150, 22)
                                                dd.Position = UDim2.new(1, -160, 0.5, -11)
                                                dd.BackgroundColor3 = Color3.fromRGB(55, 48, 38)
                                                dd.BorderSizePixel = 0
                                                dd.Font = Enum.Font.Gotham
                                                dd.TextSize = 11
                                                dd.TextColor3 = Color3.fromRGB(200, 180, 140)
                                                dd.AutoButtonColor = false
                                                dd.ZIndex = 5
                                                dd.Parent = row
                                                Instance.new("UICorner", dd).CornerRadius = UDim.new(0, 6)
                                                local arrow = Instance.new("TextLabel")
                                                arrow.Size = UDim2.fromOffset(16, 22)
                                                arrow.Position = UDim2.new(1, -18, 0, 0)
                                                arrow.BackgroundTransparency = 1
                                                arrow.Text = "▼"
                                                arrow.TextColor3 = Color3.fromRGB(150, 130, 100)
                                                arrow.Font = Enum.Font.FredokaOne
                                                arrow.TextSize = 8
                                                arrow.ZIndex = 6
                                                arrow.Parent = dd
                                                local lf = Instance.new("Frame")
                                                lf.Size = UDim2.new(1, 0, 0, 0)
                                                lf.Position = UDim2.fromOffset(0, 24)
                                                lf.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
                                                lf.BorderSizePixel = 0
                                                lf.ClipsDescendants = true
                                                lf.Visible = false
                                                lf.ZIndex = 100
                                                lf.Parent = dd
                                                Instance.new("UICorner", lf).CornerRadius = UDim.new(0, 8)
                                                local stroke = Instance.new("UIStroke")
                                                stroke.Color = Color3.fromRGB(255, 180, 80)
                                                stroke.Thickness = 1.5
                                                stroke.Transparency = 0.3
                                                stroke.Parent = lf
                                                local ll = Instance.new("UIListLayout")
                                                ll.Padding = UDim.new(0, 3)
                                                ll.Parent = lf
                                                local lp = Instance.new("UIPadding")
                                                lp.PaddingTop = UDim.new(0, 5)
                                                lp.PaddingBottom = UDim.new(0, 5)
                                                lp.PaddingLeft = UDim.new(0, 5)
                                                lp.PaddingRight = UDim.new(0, 5)
                                                lp.Parent = lf
                                                local items = options.items or {}
                                                local selected = options.default or (options.items or {})[1]
                                                local isOpen = false
                                                local itemBtns = {}
                                                local function sel(it, silent)
                                                    selected = it
                                                    dd.Text = "  " .. tostring(it)
                                                    if not silent and options.onChange then options.onChange(it) end
                                                end
                                                local function close()
                                                    if not isOpen then return end
                                                    isOpen = false
                                                    row.ZIndex = 2
                                                    HoneyTweenService:Create(arrow, TweenInfo.new(0.2), { Rotation = 0 }):Play()
                                                    HoneyTweenService:Create(lf, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 0) }):Play()
                                                    task.delay(0.2, function() if not isOpen then lf.Visible = false end end)
                                                end
                                                local function open()
                                                    if isOpen then return end
                                                    isOpen = true
                                                    row.ZIndex = 100
                                                    lf.Visible = true
                                                    lf.Size = UDim2.new(1, 0, 0, 0)
                                                    HoneyTweenService:Create(arrow, TweenInfo.new(0.2), { Rotation = 180 }):Play()
                                                    HoneyTweenService:Create(lf, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, math.min(#items * 26 + 12, 200)) }):Play()
                                                    for i, b in ipairs(itemBtns) do
                                                        b.Position = UDim2.new(0, -15, 0, 0)
                                                        b.BackgroundTransparency = 1
                                                        task.delay(i * 0.03, function()
                                                            HoneyTweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 }):Play()
                                                        end)
                                                    end
                                                end
                                                dd.MouseButton1Click:Connect(function()
                                                    PlayClickSound()
                                                    if isOpen then close() else open() end
                                                end)
                                                local function createButtons()
                                                    for _, b in ipairs(itemBtns) do b:Destroy() end
                                                    table.clear(itemBtns)
                                                    for i, it in ipairs(items) do
                                                        local ib = Instance.new("TextButton")
                                                        ib.Size = UDim2.new(1, 0, 0, 22)
                                                        ib.BackgroundColor3 = Color3.fromRGB(50, 42, 35)
                                                        ib.BorderSizePixel = 0
                                                        ib.Font = Enum.Font.Gotham
                                                        ib.TextSize = 10
                                                        ib.TextColor3 = Color3.fromRGB(220, 200, 160)
                                                        ib.Text = tostring(it)
                                                        ib.AutoButtonColor = false
                                                        ib.ZIndex = 101
                                                        ib.Parent = lf
                                                        Instance.new("UICorner", ib).CornerRadius = UDim.new(0, 5)
                                                        ib.MouseEnter:Connect(function()
                                                            HoneyTweenService:Create(ib, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(255, 190, 80), TextColor3 = Color3.fromRGB(30, 25, 15) }):Play()
                                                        end)
                                                        ib.MouseLeave:Connect(function()
                                                            HoneyTweenService:Create(ib, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(50, 42, 35), TextColor3 = Color3.fromRGB(220, 200, 160) }):Play()
                                                        end)
                                                        ib.MouseButton1Click:Connect(function()
                                                            PlayClickSound()
                                                            sel(it)
                                                            close()
                                                        end)
                                                        table.insert(itemBtns, ib)
                                                    end
                                                end
                                                createButtons()
                                                sel(selected, true)
                                                honeyRegisterControl(options.id, selected, function() return selected end, function(v, silent) sel(v, silent) end)
                                                local dropdownApi = { label = lbl, dropdown = dd, frame = row }
                                                function dropdownApi:SetItems(newItems)
                                                    items = newItems or {}
                                                    createButtons()
                                                    if not table.find(items, selected) then sel(items[1] or "None") end
                                                    if isOpen then
                                                        HoneyTweenService:Create(lf, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, math.min(#items * 26 + 12, 200)) }):Play()
                                                    end
                                                end
                                                function dropdownApi:SetValue(value, silent)
                                                    if table.find(items, value) then sel(value, silent) end
                                                end
                                                function dropdownApi:GetValue() return selected end
                                                function dropdownApi:Refresh() createButtons() end
                                                return dropdownApi
                                            end

                                            local function addKeybind(options)
                                                local row = Instance.new("Frame")
                                                row.Size = UDim2.new(1, 0, 0, 28)
                                                row.BackgroundColor3 = Color3.fromRGB(50, 43, 35)
                                                row.BorderSizePixel = 0
                                                row.ZIndex = 2
                                                row.LayoutOrder = getNextLayoutOrder()
                                                row.Parent = scroll
                                                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                                                local lbl = Instance.new("TextLabel")
                                                lbl.Size = UDim2.new(1, -90, 1, 0)
                                                lbl.Position = UDim2.fromOffset(10, 0)
                                                lbl.BackgroundTransparency = 1
                                                lbl.Font = Enum.Font.Gotham
                                                lbl.TextSize = 11
                                                lbl.TextColor3 = Color3.fromRGB(200, 180, 140)
                                                lbl.TextXAlignment = Enum.TextXAlignment.Left
                                                lbl.Text = options.label
                                                lbl.ZIndex = 3
                                                lbl.Parent = row
                                                local keyBtn = Instance.new("TextButton")
                                                keyBtn.Size = UDim2.fromOffset(70, 20)
                                                keyBtn.Position = UDim2.new(1, -80, 0.5, -10)
                                                keyBtn.BackgroundColor3 = Color3.fromRGB(60, 52, 42)
                                                keyBtn.BorderSizePixel = 0
                                                keyBtn.Font = Enum.Font.FredokaOne
                                                keyBtn.TextSize = 9
                                                keyBtn.TextColor3 = Color3.fromRGB(255, 200, 120)
                                                keyBtn.Text = options.default or "None"
                                                keyBtn.AutoButtonColor = false
                                                keyBtn.ZIndex = 4
                                                keyBtn.Parent = row
                                                Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 4)
                                                local currentKey = options.default or "None"
                                                local listening = false
                                                keyBtn.MouseButton1Click:Connect(function()
                                                    PlayClickSound()
                                                    if listening then return end
                                                    listening = true
                                                    keyBtn.Text = "..."
                                                    local conn
                                                    conn = HoneyUserInputService.InputBegan:Connect(function(input, processed)
                                                        if input.UserInputType == Enum.UserInputType.Keyboard then
                                                            currentKey = input.KeyCode.Name
                                                            keyBtn.Text = currentKey
                                                            listening = false
                                                            conn:Disconnect()
                                                            if options.onChange then options.onChange(currentKey) end
                                                        end
                                                    end)
                                                end)
                                                return { row = row, getKey = function() return currentKey end, setKey = function(k) currentKey = k; keyBtn.Text = k end }
                                            end

                                            api = {
                                                AddToggle = addToggle,
                                                AddButton = addButton,
                                                AddSlider = addSlider,
                                                AddDropdown = addDropdown,
                                                AddSection = addSection,
                                                AddKeybind = addKeybind,
                                                AddText = addText,
                                                Container = scroll,
                                                getNextLayoutOrder = getNextLayoutOrder
                                            }
                                            HoneyTabs[tabName] = { button = tabBtn, container = container, indicator = indicator, api = api }
                                            tabBtn.MouseButton1Click:Connect(function()
                                                PlayClickSound()
                                                honeySetTabActive(tabName)
                                            end)
                                            if not HoneyActiveTab then honeySetTabActive(tabName) end
                                            return api
                                        end

                                        -- ============================================================
                                        --  BUILD TABS (SP Hub Features)
                                        -- ============================================================
                                        
                                        -- ===== INFO TAB =====
                                        local InfoTab = honeyCreateTab("Info")
                                        InfoTab.AddSection("Script Information")
                                        InfoTab.AddText({ text = "SP Hub | Murder Mystery 2", size = 14, color = Color3.fromRGB(255, 210, 130), height = 20 })
                                        InfoTab.AddText({ text = "Version: 1.3", size = 11, color = Color3.fromRGB(200, 180, 140) })
                                        InfoTab.AddText({ text = "Owner: SP Hub", size = 11, color = Color3.fromRGB(200, 180, 140) })
                                        InfoTab.AddText({ text = "Executor: " .. executorName, size = 11, color = Color3.fromRGB(200, 180, 140) })
                                        InfoTab.AddText({ text = "Playing as: " .. localPlayer.Name, size = 11, color = Color3.fromRGB(200, 180, 140) })
                                        InfoTab.AddSection("Language")
                                        local langDropdown = InfoTab.AddDropdown({
                                            id = "language_setting",
                                            label = "Language",
                                            items = { "English", "Arabic", "Russian", "Turkey", "Española", "France", "Germany", "Brazil" },
                                            default = "English",
                                            onChange = function(v)
                                                local map = { English = "en", Arabic = "ar", Russian = "ru", Turkey = "tr", ["Española"] = "es", France = "fr", Germany = "de", Brazil = "pt" }
                                                if t1.value2 then t1.value2.CurrentLanguage = map[v] or "en" end
                                            end
                                        })
                                        InfoTab.AddSection("SP Hub Channels")
                                        InfoTab.AddButton({ label = "📱 Telegram Channel", onClick = function()
                                            setclipboard("https://t.me/SPscript1")
                                            NotificationSystem.Notify({ text = "Telegram link copied", duration = 2 })
                                        end })
                                        InfoTab.AddButton({ label = "▶️ YouTube Channel", onClick = function()
                                            setclipboard("https://www.youtube.com/@SphinxR7")
                                            NotificationSystem.Notify({ text = "YouTube link copied", duration = 2 })
                                        end })
                                        InfoTab.AddButton({ label = "💬 Discord Server", onClick = function()
                                            setclipboard("https://discord.gg/6Yp2B4JHyz")
                                            NotificationSystem.Notify({ text = "Discord link copied", duration = 2 })
                                        end })
                                        InfoTab.AddSection("Changelog")
                                        for _, item in ipairs(changelogItems) do
                                            InfoTab.AddText({ text = "• " .. item, size = 10, color = Color3.fromRGB(180, 160, 130) })
                                        end

                                        -- ===== KEY TAB =====
                                        local KeyTab = honeyCreateTab("Key")
                                        KeyTab.AddSection("🔑 Key System")
                                        KeyTab.AddText({ text = "This script is Keyless! Some premium features require a key.", size = 10, color = Color3.fromRGB(180, 160, 130), height = 28 })
                                        KeyTab.AddSection("🎁 Get 3 Days FREE Premium!")
                                        KeyTab.AddText({ text = "Visit www.sphub.lol, create an account and link Discord for a free key.", size = 10, color = Color3.fromRGB(180, 160, 130), height = 28 })
                                        local keyStatus = KeyTab.AddText({ text = "Status: Waiting...", size = 11, color = Color3.fromRGB(200, 180, 140) })
                                        local keyInput = KeyTab.AddText ? nil : nil
                                        -- Use a TextBox-based approach via slider? We'll add textbox support inline
                                        -- Note: HoneyLua doesn't have AddTextbox, so we simulate with dropdown of saved key OR use button
                                        KeyTab.AddButton({ label = "📋 Get Key (Copy Link)", onClick = function()
                                            setclipboard(t1.value5 and t1.value5.GET_KEY_URL or "https://sphub.lol/get-key")
                                            NotificationSystem.Notify({ text = "Key link copied", duration = 2 })
                                        end })
                                        KeyTab.AddButton({ label = "✅ Verify Saved Key", onClick = function()
                                            local savedKey = t1.value5 and t1.value5.savedKey or ""
                                            if savedKey == "" then
                                                NotificationSystem.Notify({ text = "No saved key found", duration = 3 })
                                                return
                                            end
                                            keyStatus.Text = "Status: Checking..."
                                            local ok, expires, err = t1.value7(savedKey)
                                            if ok then
                                                keyStatus.Text = "Status: ✅ Key Valid"
                                                t1.value121 = expires or "Lifetime"
                                                t1.value122 = os.time() + 315360000
                                                t1.value120 = true
                                                if t1.value28 and t1.value28.SetPremium then t1.value28:SetPremium(true) end
                                                NotificationSystem.Notify({ text = "Premium Activated", duration = 3 })
                                            else
                                                keyStatus.Text = "Status: ❌ " .. tostring(expires)
                                                NotificationSystem.Notify({ text = "Key invalid: " .. tostring(expires), duration = 3 })
                                            end
                                        end })
                                        KeyTab.AddButton({ label = "❌ Deactivate Key", onClick = function()
                                            t1.value120 = false
                                            pcall(function()
                                                if t1.value5 and isfile(t1.value5.KEY_FILE) then delfile(t1.value5.KEY_FILE) end
                                            end)
                                            if t1.value28 and t1.value28.SetPremium then t1.value28:SetPremium(false) end
                                            keyStatus.Text = "Status: Deactivated"
                                            NotificationSystem.Notify({ text = "Key deactivated", duration = 3 })
                                        end })

                                        -- ===== MAIN TAB =====
                                        local MainTab = honeyCreateTab("Main")
                                        MainTab.AddSection("ESP Toggles")
                                        MainTab.AddToggle({ id = "esp_players", label = "ESP Players", default = false, onChange = function(v) t1.value2.RolesESP = v end })
                                        MainTab.AddToggle({ id = "tracers", label = "ESP Tracers", default = false, onChange = function(v) t1.value2.TracersEnabled = v end })
                                        MainTab.AddDropdown({
                                            id = "esp_roles", label = "Select ESP Players",
                                            items = { "Innocent", "Sheriff", "Hero", "Murderer" },
                                            default = "Murderer",
                                            onChange = function(v)
                                                t1.value2.ESPRoles = t1.value2.ESPRoles or {}
                                                t1.value2.ESPRoles[v] = true
                                                for _, k in ipairs({"Innocent","Sheriff","Hero","Murderer"}) do
                                                    if k ~= v then t1.value2.ESPRoles[k] = false end
                                                end
                                            end
                                        })
                                        MainTab.AddDropdown({
                                            id = "tracer_roles", label = "Select Tracers Players",
                                            items = { "Innocent", "Sheriff", "Hero", "Murderer" },
                                            default = "Murderer",
                                            onChange = function(v)
                                                t1.value2.TracerRoles = t1.value2.TracerRoles or {}
                                                t1.value2.TracerRoles[v] = true
                                                for _, k in ipairs({"Innocent","Sheriff","Hero","Murderer"}) do
                                                    if k ~= v then t1.value2.TracerRoles[k] = false end
                                                end
                                            end
                                        })
                                        MainTab.AddToggle({ id = "gun_esp", label = "ESP Dropped Gun", default = false, onChange = function(v) t1.value2.GunESP = v end })
                                        MainTab.AddToggle({ id = "round_timer", label = "Show Round Timer", default = false, onChange = function(v) v13(v) end })
                                        MainTab.AddToggle({ id = "names_esp", label = "Names ESP", default = false, onChange = function(v)
                                            t1.value2.NamesESP = v
                                            if not v then t1.value13(); t1.value17() else t1.value16() end
                                        end })
                                        MainTab.AddToggle({ id = "xray", label = "ESP X-Ray", default = false, onChange = function(v) t1.value57(v) end })
                                        MainTab.AddToggle({ id = "trap_esp", label = "ESP Traps", default = false, onChange = function(v)
                                            t1.value2.TrapESP = v
                                            if not v and t1.value92 then t1.value92() end
                                        end })
                                        MainTab.AddSection("HitBox")
                                        MainTab.AddToggle({ id = "hitbox_expander", label = "Show HitBox", default = false, onChange = function(v)
                                            t1.value2.HitboxExpander = v
                                            if not v then v3() end
                                        end })
                                        MainTab.AddSlider({ id = "hitbox_size", label = "HitBox Size", min = 3, max = 20, default = 3, step = 1, onChange = function(v) t1.value2.HitboxSize = v end })
                                        MainTab.AddDropdown({
                                            id = "hitbox_roles", label = "Select HitBox Players",
                                            items = { "Murderer", "Sheriff", "Innocents" },
                                            default = "Murderer",
                                            onChange = function(v)
                                                t1.value2.HitboxRoles = t1.value2.HitboxRoles or {}
                                                t1.value2.HitboxRoles[v] = true
                                                for _, k in ipairs({"Murderer","Sheriff","Innocents"}) do
                                                    if k ~= v then t1.value2.HitboxRoles[k] = false end
                                                end
                                            end
                                        })
                                        MainTab.AddToggle({ id = "smart_hitbox", label = "Smart HitBox", default = false, onChange = function(v) t1.value2.SmartHitbox = v end })
                                        MainTab.AddSection("Autofarm")
                                        MainTab.AddToggle({ id = "auto_farm", label = "Auto Collect Coins", default = false, onChange = function(v)
                                            t1.value2.AutoFarmCoins = v
                                            if not v and getgenv().ActiveFarmTween then
                                                pcall(function() getgenv().ActiveFarmTween:Cancel() end)
                                                getgenv().ActiveFarmTween = nil
                                            end
                                        end })
                                        MainTab.AddDropdown({
                                            id = "auto_farm_mode", label = "Auto Farm Mode",
                                            items = { "Tween", "Walk" },
                                            default = "Tween",
                                            onChange = function(v) t1.value2.AutoFarmMode = v end
                                        })
                                        MainTab.AddSlider({ id = "coin_farm_speed", label = "Coin Tween Speed", min = 10, max = 35, default = 35, step = 1, onChange = function(v) t1.value2.CoinFarmSpeed = v end })
                                        MainTab.AddSlider({ id = "autofarm_walkspeed", label = "Walk Speed", min = 16, max = 100, default = 30, step = 1, onChange = function(v) t1.value2.AutoFarmWalkSpeed = v end })

                                        -- ===== PLAYER TAB =====
                                        local PlayerTab = honeyCreateTab("Player")
                                        PlayerTab.AddSection("Movement & Physics")
                                        PlayerTab.AddToggle({ id = "noclip", label = "Noclip", default = false, onChange = function(v) t1.value2.Noclip = v end })
                                        PlayerTab.AddToggle({ id = "player_speed", label = "Player Speed", default = false, onChange = function(v) t1.value2.PlayerSpeedEnabled = v end })
                                        PlayerTab.AddSlider({ id = "walkspeed", label = "WalkSpeed", min = 16, max = 50, default = 16, step = 1, onChange = function(v) t1.value2.WalkSpeed = v end })
                                        PlayerTab.AddToggle({ id = "player_jump", label = "Player Jump Power", default = false, onChange = function(v) t1.value2.PlayerJumpPowerEnabled = v end })
                                        PlayerTab.AddSlider({ id = "jump_power", label = "JumpPower", min = 50, max = 60, default = 50, step = 1, onChange = function(v) t1.value2.JumpPower = v end })
                                        PlayerTab.AddToggle({ id = "infinite_jump", label = "Infinite Jump", default = false, onChange = function(v) t1.value65(v) end })
                                        PlayerTab.AddSection("Camera & FOV")
                                        PlayerTab.AddSlider({ id = "fov_value", label = "Fov Changer", min = 30, max = 120, default = 70, step = 1, onChange = function(v)
                                            local cam = workspace.CurrentCamera
                                            if cam then cam.FieldOfView = v end
                                        end })
                                        PlayerTab.AddButton({ label = "Default Fov", onClick = function()
                                            local cam = workspace.CurrentCamera
                                            if cam then cam.FieldOfView = 70 end
                                        end })
                                        PlayerTab.AddSection("Flight & Invisibility")
                                        PlayerTab.AddToggle({ id = "fly", label = "Fly", default = false, onChange = function(v) t1.value107(v) end })
                                        PlayerTab.AddSlider({ id = "fly_speed", label = "Fly Speed", min = 10, max = 100, default = 50, step = 1, onChange = function(v) t1.value2.FlySpeed = v end })
                                        PlayerTab.AddToggle({ id = "anti_void", label = "Anti Void", default = false, onChange = function(v) t1.value2.AntiVoid = v end })

                                        -- ===== KILL TAB =====
                                        local KillTab = honeyCreateTab("Kill")
                                        KillTab.AddSection("Sheriff Utilities")
                                        KillTab.AddToggle({ id = "aimbot", label = "Aimbot on Murderer", default = false, onChange = function(v) t1.value73(v) end })
                                        KillTab.AddToggle({ id = "motion_aim_vis", label = "Motion Aim Visualizer", default = false, onChange = function(v)
                                            t1.value2.MotionAimVisualizer = v
                                            if v then t1.value2.MotionAimVisualizerForMouse = false end
                                        end })
                                        KillTab.AddToggle({ id = "link_murder", label = "Link Behind The Murderer", default = false, onChange = function(v) t1.value2.LinkBehindMurder = v end })
                                        KillTab.AddToggle({ id = "gun_alert", label = "Dropped Gun Alert", default = true, onChange = function(v) t1.value2.DroppedGunAlert = v end })
                                        KillTab.AddToggle({ id = "auto_grab_gun", label = "Auto Grab Gun", default = false, onChange = function(v) t1.value2.AutoGrabGun = v end })
                                        KillTab.AddButton({ label = "🔫 Instant Grab Gun (G)", onClick = function() t1.value43() end })
                                        KillTab.AddToggle({ id = "faster_grab_btn", label = "Faster Grab Gun Button", default = false, onChange = function(v)
                                            t1.value2.FasterGrabGunButton = v
                                            t1.value79(v)
                                        end })
                                        KillTab.AddButton({ label = "💬 Send Murder to Chat", onClick = function() t1.value44() end })
                                        KillTab.AddSection("Kill Murderer")
                                        KillTab.AddToggle({ id = "auto_kill_murder", label = "Auto Kill Murder", default = false, onChange = function(v) t1.value2.AutoKillMurder = v end })
                                        KillTab.AddToggle({ id = "advanced_pred", label = "Smart Motion Aim", default = true, onChange = function(v) t1.value2.AdvancedPrediction = v end })
                                        KillTab.AddSlider({ id = "shoot_offset", label = "Shoot Position Offset", min = 0, max = 10, default = 2, step = 1, onChange = function(v) t1.value2.ShootPositionOffset = v end })
                                        KillTab.AddDropdown({
                                            id = "auto_kill_mode", label = "Auto Kill Murder Mode",
                                            items = { "Shoot Visible", "Teleport & Shoot" },
                                            default = "Shoot Visible",
                                            onChange = function(v) t1.value2.AutoKillMurderMode = v end
                                        })
                                        KillTab.AddToggle({ id = "shoot_knife_eq", label = "Shoot Only When Knife Equipped", default = false, onChange = function(v) t1.value2.ShootOnlyWhenKnifeEquipped = v end })
                                        KillTab.AddToggle({ id = "faster_kill_btn", label = "Faster Kill Murder Button", default = false, onChange = function(v)
                                            t1.value2.FasterKillMurderButton = v
                                            t1.value78(v)
                                        end })
                                        KillTab.AddButton({ label = "🎯 Kill The Murder (H)", onClick = function() t1.value77() end })
                                        KillTab.AddSection("Murderer Automation")
                                        KillTab.AddToggle({ id = "murder_auto_kill", label = "Auto Kill All", default = false, onChange = function(v)
                                            t1.value2.MurdererAutoKill = v
                                            if not v and getgenv().ActiveKillTween then
                                                pcall(function() getgenv().ActiveKillTween:Cancel() end)
                                                getgenv().ActiveKillTween = nil
                                            end
                                        end })
                                        KillTab.AddDropdown({
                                            id = "murder_auto_kill_mode", label = "Auto Kill All Mode",
                                            items = { "Teleport to Everyone", "Bring Everyone" },
                                            default = "Teleport to Everyone",
                                            onChange = function(v) t1.value2.MurdererAutoKillMode = v end
                                        })
                                        KillTab.AddButton({ label = "💀 Kill All (Premium)", onClick = function() t1.value86() end })
                                        KillTab.AddToggle({ id = "auto_knife_throw", label = "Auto Knife Throw to Closest", default = false, onChange = function(v) t1.value2.AutoKnifeThrow = v end })
                                        KillTab.AddToggle({ id = "knife_target_sheriff", label = "Prioritize Target: Sheriff", default = false, onChange = function(v) t1.value2.PrioritizeSheriffKnifeThrow = v end })
                                        KillTab.AddToggle({ id = "knife_spawn_near", label = "Spawn Knife Near Target", default = false, onChange = function(v) t1.value2.SpawnKnifeNearTarget = v end })
                                        KillTab.AddToggle({ id = "faster_knife_btn", label = "Faster Knife Throw Button", default = false, onChange = function(v)
                                            t1.value2.FasterKnifeThrowButton = v
                                            t1.value80(v)
                                        end })
                                        KillTab.AddButton({ label = "🔪 Throw The Knife (R)", onClick = function() v16(nil, false) end })
                                        KillTab.AddSection("Troll")
                                        local flingDropdown
                                        flingDropdown = KillTab.AddDropdown({
                                            id = "fling_target", label = "Fling Target Player",
                                            items = { "No Players" },
                                            default = "No Players",
                                            onChange = function(v) t1.value2.FlingTargetPlayer = v end
                                        })
                                        t1.value117 = flingDropdown
                                        KillTab.AddToggle({ id = "fling_player", label = "Fling Player", default = false, onChange = function(v) t1.value112(v) end })
                                        KillTab.AddToggle({ id = "fling_murderer", label = "Fling Murderer", default = false, onChange = function(v) t1.value113(v) end })
                                        KillTab.AddToggle({ id = "fling_sheriff", label = "Fling Sheriff", default = false, onChange = function(v) t1.value114(v) end })
                                        KillTab.AddToggle({ id = "fling_touch", label = "Fling Touch", default = false, onChange = function(v) t1.value115(v) end })
                                        KillTab.AddToggle({ id = "auto_fling_all", label = "Auto Fling All", default = false, onChange = function(v) t1.value116(v) end })
                                        KillTab.AddToggle({ id = "fling_spinning", label = "Spinning", default = true, onChange = function(v) t1.value2.FlingSpinning = v end })
                                        KillTab.AddSection("Protection")
                                        KillTab.AddToggle({ id = "anti_fling", label = "Anti Fling (Premium)", default = false, onChange = function(v)
                                            _G.AntiFling = v
                                            if v then
                                                local self = setmetatable({}, { __index = function(p121, p122)
                                                    local p122_2 = game:GetService(p122)
                                                    if p122_2 then p121[p122] = p122_2 end
                                                    return p122_2
                                                end })
                                                local lp = self.Players.LocalPlayer
                                                local function v1240(p123)
                                                    local u1733, HumanoidRootPart
                                                    local function v1735(p124)
                                                        u1733 = p124
                                                        repeat task.wait(); HumanoidRootPart = p124:FindFirstChild("HumanoidRootPart") until HumanoidRootPart or not _G.AntiFling
                                                    end
                                                    if p123.Character then task.spawn(function() v1735(p123.Character) end) end
                                                    p123.CharacterAdded:Connect(v1735)
                                                    self.RunService.Heartbeat:Connect(function()
                                                        if not _G.AntiFling then return end
                                                        if u1733 and u1733:IsDescendantOf(workspace) and HumanoidRootPart and HumanoidRootPart:IsDescendantOf(u1733) then
                                                            if HumanoidRootPart.AssemblyAngularVelocity.Magnitude > 50 or HumanoidRootPart.AssemblyLinearVelocity.Magnitude > 100 then
                                                                for _, d in ipairs(u1733:GetDescendants()) do
                                                                    if d:IsA("BasePart") then
                                                                        d.CanCollide = false
                                                                        d.AssemblyAngularVelocity = Vector3.new(0,0,0)
                                                                        d.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                                                        d.CustomPhysicalProperties = PhysicalProperties.new(0,0,0)
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end)
                                                end
                                                for _, p in ipairs(self.Players:GetPlayers()) do
                                                    if p ~= lp then task.spawn(function() v1240(p) end) end
                                                end
                                                self.Players.PlayerAdded:Connect(v1240)
                                                self.RunService.Heartbeat:Connect(function()
                                                    if not _G.AntiFling then return end
                                                    pcall(function()
                                                        local c = lp.Character
                                                        local pr = c and (c.PrimaryPart or c:FindFirstChild("HumanoidRootPart"))
                                                        if pr and (pr.AssemblyLinearVelocity.Magnitude > 250 or pr.AssemblyAngularVelocity.Magnitude > 250) then
                                                            pr.AssemblyAngularVelocity = Vector3.new(0,0,0)
                                                            pr.AssemblyLinearVelocity = Vector3.new(0,0,0)
                                                        end
                                                    end)
                                                end)
                                            end
                                        end })

                                        -- ===== TELEPORTS TAB =====
                                        local TP = honeyCreateTab("Teleports")
                                        TP.AddSection("Teleports")
                                        TP.AddButton({ label = "🏠 Teleport to Lobby", onClick = function() t1.value103() end })
                                        TP.AddButton({ label = "🛡️ Teleport to Safe Zone", onClick = function() t1.value102() end })
                                        TP.AddButton({ label = "🔪 Teleport to Murderer", onClick = function()
                                            local m = t1.value33()
                                            if m then v23(m) else NotificationSystem.Notify({ text = "Murderer not found!", duration = 3 }) end
                                        end })
                                        TP.AddButton({ label = "🔫 Teleport to Sheriff", onClick = function()
                                            local s = t1.value34()
                                            if s then v23(s) else NotificationSystem.Notify({ text = "Sheriff not found!", duration = 3 }) end
                                        end })
                                        TP.AddSection("Player Teleport")
                                        local tpDropdown
                                        tpDropdown = TP.AddDropdown({
                                            id = "tp_target", label = "Select Player",
                                            items = { "No Players" },
                                            default = "No Players",
                                            onChange = function(v) t1.value119 = v end
                                        })
                                        t1.value118 = tpDropdown
                                        TP.AddButton({ label = "📍 Teleport to Selected Player", onClick = function()
                                            local plr = game.Players:FindFirstChild(t1.value119)
                                            if plr then v23(plr) else NotificationSystem.Notify({ text = "Player not found!", duration = 3 }) end
                                        end })

                                        -- ===== SETTING TAB =====
                                        local SetTab = honeyCreateTab("Setting", true)
                                        SetTab.AddSection("Config Manager")
                                        local cfgBox = nil -- HoneyLua doesn't have textbox; use saved key approach
                                        SetTab.AddDropdown({
                                            id = "config_selector", label = "Config",
                                            items = listConfigs(),
                                            default = currentConfigName,
                                            onChange = function(v) currentConfigName = v end
                                        })
                                        SetTab.AddToggle({ id = "auto_load_cfg", label = "Auto Load", default = settings.autoLoad, onChange = function(v) settings.autoLoad = v; honeyWriteSettings(settings) end })
                                        SetTab.AddToggle({ id = "auto_save_cfg", label = "Auto Save", default = settings.autoSave, onChange = function(v) settings.autoSave = v; honeyWriteSettings(settings) end })
                                        SetTab.AddButton({ label = "💾 Save Config", onClick = function() honeySaveConfig() end })
                                        SetTab.AddButton({ label = "📂 Load Config", onClick = function() honeyLoadConfig(currentConfigName) end })
                                        SetTab.AddButton({ label = "♻️ Reset Config", onClick = function() honeyResetCurrentConfig() end })
                                        SetTab.AddSection("Visuals")
                                        SetTab.AddToggle({ id = "transparency", label = "Acrylic / Transparency", default = settings.transparent, onChange = function(v)
                                            settings.transparent = v
                                            honeyApplyTransparency(v)
                                            honeyWriteSettings(settings)
                                        end })
                                        SetTab.AddToggle({ id = "animated_bg", label = "Animated Drip Background", default = settings.animatedBg, onChange = function(v)
                                            settings.animatedBg = v
                                            honeyApplyAnimatedBg(v)
                                            honeyWriteSettings(settings)
                                        end })
                                        SetTab.AddToggle({ id = "mobile_btn_setting", label = "Mobile Toggle Button", default = settings.showMobileBtn, onChange = function(v)
                                            settings.showMobileBtn = v
                                            honeyApplyMobileBtn(v)
                                            honeyWriteSettings(settings)
                                        end })
                                        SetTab.AddKeybind({ id = "open_keybind", label = "Menu Keybind", default = settings.openKey, onChange = function(k)
                                            settings.openKey = k
                                            honeyWriteSettings(settings)
                                        end })
                                        SetTab.AddSection("Server Utility")
                                        SetTab.AddButton({ label = "🔄 Rejoin Server", onClick = function() t1.value105() end })
                                        SetTab.AddButton({ label = "🌐 Server Hop", onClick = function() t1.value106() end })
                                        SetTab.AddSection("Performance")
                                        SetTab.AddToggle({ id = "lag_reducer", label = "Super Lag Reducer", default = false, onChange = function(v) t1.value64(v) end })
                                        SetTab.AddToggle({ id = "fps_booster", label = "FPS Booster (Delete Textures)", default = false, onChange = function(v)
                                            if v then
                                                for _, d in pairs(workspace:GetDescendants()) do
                                                    if d:IsA("Texture") or d:IsA("Decal") or d:IsA("ParticleEmitter") then d:Destroy() end
                                                end
                                            end
                                        end })
                                        SetTab.AddToggle({ id = "disable_shadows", label = "Disable Shadows & Fog", default = false, onChange = function(v)
                                            game:GetService("Lighting").GlobalShadows = not v
                                            if v then
                                                if game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere") then
                                                    game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere"):Destroy()
                                                end
                                                game:GetService("Lighting").FogEnd = 9000000000
                                            end
                                        end })
                                        SetTab.AddToggle({ id = "smooth_plastic", label = "Smooth Plastic World", default = false, onChange = function(v)
                                            getgenv().OriginalMaterials = getgenv().OriginalMaterials or {}
                                            if v then
                                                for _, d in pairs(workspace:GetDescendants()) do
                                                    if d:IsA("BasePart") then
                                                        getgenv().OriginalMaterials[d] = d.Material
                                                        d.Material = Enum.Material.SmoothPlastic
                                                    end
                                                end
                                            else
                                                for k, mat in pairs(getgenv().OriginalMaterials) do
                                                    if k and k.Parent then k.Material = mat end
                                                end
                                                getgenv().OriginalMaterials = {}
                                            end
                                        end })
                                        SetTab.AddSection("UI & Buttons")
                                        SetTab.AddSlider({ id = "mobile_buttons_size", label = "Mobile Buttons Size", min = 30, max = 100, default = 50, step = 1, onChange = function(v)
                                            t1.value2.MobileButtonsSize = v
                                            t1.value81()
                                        end })
                                        SetTab.AddButton({ label = "♻️ Reset Mobile Button Positions", onClick = function()
                                            getgenv().SPHub_SavedFasterKillPos = nil
                                            getgenv().SPHub_SavedFasterGrabGunPos = nil
                                            pcall(function()
                                                if delfile then
                                                    if isfile and isfile("SPHub_FasterKillButtonPos.txt") then delfile("SPHub_FasterKillButtonPos.txt") end
                                                    if isfile and isfile("SPHub_FasterGrabGunButtonPos.txt") then delfile("SPHub_FasterGrabGunButtonPos.txt") end
                                                end
                                            end)
                                            if t1.value2.FasterKillMurderButton then t1.value78(true) end
                                            if t1.value2.FasterGrabGunButton then t1.value79(true) end
                                            NotificationSystem.Notify({ text = "Button positions reset!", duration = 3 })
                                        end })
                                        SetTab.AddSection("Changelog")
                                        SetTab.AddButton({ label = "🔄 Reload Changelog", onClick = function()
                                            if FS.isfile and FS.isfile(CHANGELOG_FILE) then
                                                local data = honeyDecode(FS.readfile(CHANGELOG_FILE), nil)
                                                if type(data) == "table" and #data > 0 then
                                                    changelogItems = data
                                                    NotificationSystem.Notify({ text = "Changelog reloaded", duration = 2 })
                                                end
                                            end
                                        end })

                                        -- ============================================================
                                        --  FINALIZE
                                        -- ============================================================
                                        if settings.autoLoad and FS.isfile and FS.isfile(honeyConfigPath(currentConfigName)) then
                                            honeyLoadConfig(currentConfigName)
                                        else
                                            honeyUpdateStatus("Ready. Configs: " .. table.concat(listConfigs(), ", "))
                                        end

                                        if settings.autoSave then
                                            task.spawn(function()
                                                while HoneyUI_Obj and HoneyUI_Obj.screenGui and HoneyUI_Obj.screenGui.Parent do
                                                    task.wait(settings.autoSaveInterval or 30)
                                                    if settings.autoSave then honeySaveConfig() end
                                                end
                                            end)
                                        end

                                        -- Hook v9 notification to HoneyUI Notify
                                        v9 = function(p7, p8, _)
                                            local v434 = p7
                                            local _tostring = tostring
                                            if not p7 then v434 = "" end
                                            local v436 = _tostring(v434)
                                            local v437 = p8
                                            local _tostring2 = tostring
                                            if not p8 then v437 = "" end
                                            local v439 = v436 .. "::" .. _tostring2(v437)
                                            local timestamp = tick()
                                            if t1.value29[v439] and timestamp - t1.value29[v439] < 3 then return end
                                            t1.value29[v439] = timestamp
                                            local str = tostring(p7 or "SP Hub")
                                            local _tostring3 = tostring
                                            if not p8 then p8 = "" end
                                            local v443 = _tostring3(p8)
                                            NotificationSystem.Notify({ text = v443, title = str, duration = 3 })
                                        end

                                        -- Set global HoneyUI reference
                                        HoneyUI = {
                                            UI = HoneyUI_Obj,
                                            Notify = NotificationSystem.Notify,
                                            ClearNotifications = NotificationSystem.Clear
                                        }
                                        getgenv().HoneyLuaUI = HoneyUI

                                        -- Welcome notifications
                                        task.delay(0.5, function()
                                            NotificationSystem.Notify({ text = "Welcome to SP Hub MM2!", duration = 3 })
                                            task.delay(0.3, function()
                                                NotificationSystem.Notify({ text = "Executor: " .. executorName, duration = 3 })
                                            end)
                                            task.delay(0.3, function()
                                                NotificationSystem.Notify({ text = "Press RightControl to toggle UI", duration = 4 })
                                            end)
                                        end)

                                        -- Open UI initially
                                        task.delay(0.2, function()
                                            HoneyUI_Obj.ToggleUI(true)
                                        end)

                                        print("========================================")
                                        print("SP Hub | Murder Mystery 2 | HoneyLua UI")
                                        print("Executor: " .. executorName)
                                        print("Press RightControl to toggle UI")
                                        print("========================================")
                                    end
                                end

                                -- Final hook: make v9 available to SP Hub code
                                _G.SP_Hub_Notify = v9
                            end
                        end
                    end
                end
            end
        end
    end
end