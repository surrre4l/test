-- dwv2
-- toodo: impl dw dtc, just reuse :snitch logic :heart:
-- make this shit work
-- u gave me wrong base so :shrug:

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
-- Remote key/auth checks and execution telemetry removed.
local role = "unauthorized"
local displayName = player.DisplayName
local isHigherUp, isWhitelisted = false, false
_G.DWRole = role
_G.DWIsHigherUp = false
_G.DWIsWhitelisted = false
_G.DWBoundToken = nil
_G.DWDisplayName = displayName
_G.DWAuthKey = nil
_G.DWWorkerPost = nil
_DW_PERMS = {}
print("[Dramaware]: ready!")

-- Legacy compatibility
local DW_PERMS = rolen

if not cloneref then cloneref = function(x) return x end end
if not gethui then gethui = function() return game:GetService("CoreGui") end end
if not writefile then writefile = function() end end
if not readfile then readfile = function() return "" end end
if not makefolder then makefolder = function() end end
if not isfile then isfile = function() return false end end
if not isfolder then isfolder = function() return false end end
if not getcustomasset then getcustomasset = function() return "" end end
if not isrbxactive then isrbxactive = function() return true end end
if not protect_gui then protect_gui = function() end end
if not get_hidden_gui then get_hidden_gui = gethui end
if not getgenv then getgenv = function() return getfenv(0) end end

local SCRIPT_URL = ""
local Rayfield
local _rfSrc
local _ok1, _res1 = pcall(function() return game:HttpGet("https://sirius.menu/rayfield") end)
if _ok1 and _res1 and #_res1 > 500 the
_rfSrc = _res1
else
local _ok2, _res2 = pcall(function() return game:HttpGet("https://sirius.menu/rayfield") end)
if _ok2 and _res2 and #_res2 > 500 then
_rfSrc = _res2
end
end
if not _rfSrc then
warn("[DramaWare] Failed to load Rayfield, check your internet or executor HTTP access.")
return
end
local _loadedFunc, _loadErr = loadstring(_rfSrc)
if not _loadedFunc then
warn("[DramaWare] Rayfield syntax error: " .. tostring(_loadErr))
return
end
local _rfOk, _rfResult = pcall(_loadedFunc)
if not _rfOk then
warn("[DramaWare] Rayfield failed to initialize: " .. tostring(_rfResult))
return
end
Rayfield = _rfResult
local _DWHttp = game:GetService("HttpService")
local _DW_Elements = {}
local function DW_EnsureFolders()
    pcall(function()
        if not isfolder("DramaWare") then makefolder("DramaWare") end
        if not isfolder("DramaWare/Configs") then makefolder("DramaWare/Configs") end
    end)
end
local function DW_ListConfigs()
    local names = {}
    pcall(function()
        DW_EnsureFolders()
        local files = (listfiles and listfiles("DramaWare/Configs")) or {}
        for _, path in ipairs(files) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name and name ~= "" then table.insert(names, name) end
        end
    end)
    if #names == 0 then names = {"(no saved configs)"} end
    return names
end
local _DW_SkipFlags = { DWConfigDropdown = true }
local function DW_PackColor(c)
    return {R = math.floor(c.R * 255 + 0.5), G = math.floor(c.G * 255 + 0.5), B = math.floor(c.B * 255 + 0.5)}
end
local function DW_UnpackColor(t)
    return Color3.fromRGB(t.R or 0, t.G or 0, t.B or 0)
end
local function DW_SaveConfig(name)
    DW_EnsureFolders()
    local data = {}
    for flag, obj in pairs(Rayfield.Flags) do
        if not _DW_SkipFlags[flag] then
            pcall(function()
                if obj.Type == "ColorPicker" then
                    if obj.Color then
                        data[flag] = DW_PackColor(obj.Color)
                    end
                elseif typeof(obj.CurrentValue) == "boolean" then
                    data[flag] = obj.CurrentValue
                else
                    local v = obj.CurrentValue or obj.CurrentKeybind or obj.CurrentOption or obj.Color
                    if v ~= nil then data[flag] = v end
                end
            end)
        end
    end
    local ok, json = pcall(function() return _DWHttp:JSONEncode(data) end)
    if ok then
        pcall(function() writefile("DramaWare/Configs/" .. name .. ".json", json) end)
    end
end
local function DW_LoadConfig(name)
    local path = "DramaWare/Configs/" .. name .. ".json"
    local exists = false
    pcall(function() exists = isfile(path) end)
    if not exists then return false end
    local ok, data = pcall(function()
        return _DWHttp:JSONDecode(readfile(path))
    end)
    if ok and data then
        for flag, value in pairs(data) do
            if not _DW_SkipFlags[flag] then
                local f, v = flag, value
                task.spawn(function()
                    pcall(function()
                        local flagObj = Rayfield.Flags[f]
                        if flagObj and flagObj.Type == "ColorPicker" and type(v) == "table" then
                            v = DW_UnpackColor(v)
                        end
                        local el = _DW_Elements[f]
                        if el and el.Set then
                            el:Set(v)
                        elseif flagObj and flagObj.Set then
                            flagObj:Set(v)
                        end
                    end)
                end)
            end
        end
        return true
    end
    return false
end
local function DW_GetAutoLoad()
    local name = nil
    pcall(function()
        if isfile("DramaWare/AutoLoad.txt") then
            name = readfile("DramaWare/AutoLoad.txt"):match("^%s*(.-)%s*$")
        end
    end)
    return (name ~= "" and name) or nil
end
local function DW_SetAutoLoad(name)
    DW_EnsureFolders()
    pcall(function() writefile("DramaWare/AutoLoad.txt", name or "") end)
end
local function DW_PatchTab(tab)
    if not tab then return end
    for _, m in ipairs({"CreateToggle","CreateDropdown","CreateSlider","CreateColorPicker","CreateKeybind"}) do
        local orig = tab[m]
        if orig then
            tab[m] = function(s, cfg, ...)
                local el = orig(s, cfg, ...)
                if cfg and type(cfg) == "table" and cfg.Flag and el then
                    _DW_Elements[cfg.Flag] = el
                end
                return el
            end
        end
    end
end
local isCamp = game.PlaceId == 4939362930
local isLobby = game.PlaceId == 4889315193 or game.PlaceId == 14884976124
local isPractice = game.PlaceId == 15365802831
local isMovies = game.PlaceId == 4939362610
local isExpedition = game.PlaceId == 7172152072
local queueTeleport = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport) or nil
if queueTeleport and SCRIPT_URL ~= "" then
    queueTeleport('loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
end
local function saveTheme(theme)
    pcall(function()
        if not isfolder("DramaWare") then makefolder("DramaWare") end
        writefile("DramaWare/Theme.txt", theme)
    end)
end
local function loadTheme()
    local theme = nil
    pcall(function()
        if isfile("DramaWare/Theme.txt") then
            theme = readfile("DramaWare/Theme.txt"):match("^%s*(.-)%s*$")
        end
    end)
    return theme
end
if not isCamp and not isLobby and not isPractice and not isMovies and not isExpedition then
    Rayfield:Notify({
        Title = "Wrong Game",
        Content = "Execute this script in Total Roblox Drama: Camp or Movies",
        Duration = 6,
        Image = "alert-triangle",
    })
    return
end
if not request then request = http_request or (syn and syn.request) or (function() end) end
if not setclipboard then setclipboard = toclipboard or (Clipboard and Clipboard.set) or function() end end
if not firetouchinterest then firetouchinterest = function() end end
if not fireclickdetector then fireclickdetector = function() end end
local player = game:GetService("Players").LocalPlayer
local camera = workspace.CurrentCamera
-- ── Shortcuts: Floor Bounce & Lag High Jump ──────────────────────────────────
do
    local _RunService = game:GetService("RunService")
    local _UIS = game:GetService("UserInputService")
    local _lhj_enabled = true
    local _lhj_freeze = 0.15
    local _lhj_height = 69
    local _lhj_cooldown = 0.5
    local _lhj_last = 0

    local function _isChatFocused()
        return _UIS:GetFocusedTextBox() ~= nil
    end

    function dolaghighjump(skipChecks)
        if not _lhj_enabled then return end
        if not skipChecks and (tick() - _lhj_last) < _lhj_cooldown then return end
        local char = game.Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hrp and hum then
            if not skipChecks and hum.FloorMaterial == Enum.Material.Air then return end
            _lhj_last = tick()
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            task.wait(0.01)
            local s = os.clock()
            while os.clock() - s < _lhj_freeze do end
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                _lhj_height,
                hrp.AssemblyLinearVelocity.Z
            )
        end
    end

    function doFloorBounce()
        local char = game.Players.LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.FloorMaterial == Enum.Material.Air then return end
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        task.spawn(function()
            repeat task.wait() until hum.FloorMaterial == Enum.Material.Air
            repeat task.wait() until hum.FloorMaterial ~= Enum.Material.Air
            dolaghighjump(true)
        end)
    end

    -- ── FPS Bounce Boost ───────────────────────────────────────────────────────
    local _LedgeEnabled    = true
    local _LedgeReach      = 1.0
    _G._FpsBounceEnabled = false
    local _FpsPower        = 42
    local _FpsVertical     = 21
    local _lastClimbTime   = 0

    _RunService.Heartbeat:Connect(function()
        if not _LedgeEnabled then return end
        local char = game.Players.LocalPlayer.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if hum.FloorMaterial ~= Enum.Material.Air then return end
        if hum:GetState() == Enum.HumanoidStateType.Climbing then return end
        if (tick() - _lastClimbTime) < 0.1 then return end
        local forward = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
        local flatVel = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)
        if flatVel:Dot(forward) < 0.5 then return end
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {char}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local wallRay = workspace:Raycast(hrp.Position, forward * _LedgeReach, params)
        if not wallRay then return end
        local distToWall = (Vector3.new(wallRay.Position.X, hrp.Position.Y, wallRay.Position.Z) - hrp.Position).Magnitude
        local nativeRange = hrp.Size.Z / 2 + 0.6
        if distToWall <= nativeRange then return end
        local probeOrigin = Vector3.new(wallRay.Position.X, hrp.Position.Y + 3.5, wallRay.Position.Z)
        local topRay = workspace:Raycast(probeOrigin, Vector3.new(0, -5, 0), params)
        if not topRay then return end
        local heightDiff = topRay.Position.Y - hrp.Position.Y
        if heightDiff < -2.0 or heightDiff > 5.0 then return end
        if topRay.Normal.Y < 0.7 then return end
        local halfDepth = hrp.Size.Z / 2 + 0.05
        local snapPos   = wallRay.Position + wallRay.Normal * halfDepth
        hrp.CFrame = CFrame.new(
            Vector3.new(snapPos.X, hrp.Position.Y, snapPos.Z),
            Vector3.new(snapPos.X, hrp.Position.Y, snapPos.Z) + forward
        )
        _lastClimbTime = tick()
    end)

    _UIS.JumpRequest:Connect(function()
        local char = game.Players.LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then return end
        if hum:GetState() == Enum.HumanoidStateType.Climbing then
            if tick() - _lastClimbTime > 0.2 then
                if _G._FpsBounceEnabled then
                    local velocity = (-hrp.CFrame.LookVector * _FpsPower) + Vector3.new(0, _FpsVertical, 0)
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    task.spawn(function()
                        local s = tick()
                        while tick() - s < 0.12 do
                            hrp.AssemblyLinearVelocity = velocity
                            _RunService.Heartbeat:Wait()
                        end
                    end)
                end
            end
        end
    end)
    -- ──────────────────────────────────────────────────────────────────────────

    -- ALT keybind
    _RunService.Heartbeat:Connect(function()
        if _isChatFocused() then return end
        if _UIS:IsKeyDown(Enum.KeyCode.LeftAlt) then
            local char = game.Players.LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.FloorMaterial ~= Enum.Material.Air then
                dolaghighjump()
            end
        end
    end)
end
-- ─────────────────────────────────────────────────────────────────────────────

if isLobby then
    local Window = Rayfield:CreateWindow({
        Name = "DramaWare V2 (Lobby)",
        LoadingTitle = "DramaWare (Lobby)",
        LoadingSubtitle = "by kobi, callie, and irib",
        ShowText = "DramaWare",
        Theme = "DarkBlue",
        DisableRayfieldPrompts = false,
        DisableBuildWarnings = false,
        MinimizeKey = Enum.KeyCode.LeftControl,
        CustomUIStrings = {
            ["Rayfield"] = "DramaWare",
            ["Hide"] = "Hide",
            ["Show"] = "Show",
        },
    })
    local savedTheme = loadTheme()
    if savedTheme then pcall(function() Window.ModifyTheme(savedTheme) end) end
    local InfoTab = Window:CreateTab("Info", "info")
    InfoTab:CreateSection("DramaWare")
    InfoTab:CreateLabel("You are in the Lobby.")
    InfoTab:CreateLabel("All game modes supported: Camp, Movies, Expedition, Practice.")
    InfoTab:CreateButton({
        Name = "Fling People",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxcheatck/reanimatescript/main/script.lua", true))()
        end,
    })
    local UniversalTab = Window:CreateTab("Universal", "globe")
    local OtherTab = Window:CreateTab("Other", "package")
    _G.SelectedFont = nil
    _G.StaticColor = Color3.fromRGB(255, 182, 193)
    _G.StaticColorCustom = false
    _G.RainbowMode = false
    _G.RainbowSpeed = 0.5
    _G.CustomName = ""
    _G.UseCustomName = false
    OtherTab:CreateSection("Appearance")
    OtherTab:CreateInput({
       Name = "Custom Name",
       PlaceholderText = "Enter name here...",
       RemoveTextAfterFocusLost = false,
       Callback = function(Text)
           _G.CustomName = Text
           _G.UseCustomName = (Text ~= "")
       end,
    })
    OtherTab:CreateToggle({
       Name = "Rainbow Effect",
       CurrentValue = false,
       Flag = "RainbowToggle",
       Callback = function(Value)
          _G.RainbowMode = Value
       end,
    })
    OtherTab:CreateColorPicker({
        Name = "Static Color",
        Color = Color3.fromRGB(255, 182, 193),
        Flag = "ColorPicker",
        Callback = function(Value)
            _G.StaticColor = Value
            _G.StaticColorCustom = true
        end
    })
    OtherTab:CreateDropdown({
        Name = "UI Theme",
        Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
        CurrentOption = {"DarkBlue"},
        MultipleOptions = false,
        Flag = "ThemeDropdown",
        Callback = function(option)
            Window.ModifyTheme(option[1])
            saveTheme(option[1])
        end,
    })
    OtherTab:CreateSection("Fake Leaderboards")
    OtherTab:CreateButton({
        Name = "Fake #1 All Leaderboards (CLIENT)",
        Callback = function()
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=48&height=48&format=png"
            local boards = {
                workspace.Elements.MoviesWinLeaderboard,
                workspace.Elements.CampWinLeaderboard,
                workspace.Elements.ExpeditionWinLeaderboard
            }
            for _, board in pairs(boards) do
                local scrollFrame = board.SurfaceGui.ScrollingFrame
                for _, frame in pairs(scrollFrame:GetChildren()) do
                    if frame:IsA("Frame") then
                        local placeLabel = frame:FindFirstChild("Image") and frame.Image:FindFirstChild("Place")
                        if placeLabel and placeLabel.Text == "1" then
                            frame.PName.Text = player.Name
                            frame.Image.Image = avatarUrl
                            break
                        end
                    end
                end
            end
        end,
    })
    game:GetService("RunService").RenderStepped:Connect(function()
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                if _G.UseCustomName and _G.CustomName ~= "" then
                    obj.Text = _G.CustomName
                end
                if _G.RainbowMode then
                    local hue = (tick() * _G.RainbowSpeed) % 1
                    obj.TextColor3 = Color3.fromHSV(hue, 0.6, 1) 
                elseif _G.StaticColorCustom then
                    obj.TextColor3 = _G.StaticColor
                end
                obj.TextStrokeTransparency = 0.5
                obj.BackgroundTransparency = 1
            end
        end
    end)
    UniversalTab:CreateButton({
        Name = "Open Console",
        Callback = function()
            game:GetService('StarterGui'):SetCore('DevConsoleVisible', true)
        end,
    })
    UniversalTab:CreateButton({
        Name = "Instant Respawn",
        Callback = function()
            local character = game.Players.LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end,
    })
    UniversalTab:CreateButton({
        Name = "Fake Lag",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/ZynixMoz/Scripts/refs/heads/main/Official/SkyeMoz/Fake%20Lag%20%2B%20Egor%20Mode"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Mobile Lag Jump",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Mobile-lag-jump-for-r6-glitches-48710"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "PC Freeze Glitch",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Mobile-lag-jump-for-r6-glitches-48710"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Infinite Yield",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Energize",
        Callback = function()
            loadstring(game:HttpGet("https://pastebin.com/raw/Cfeu2ZPc"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Fly V3",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Sound Panel",
        Callback = function()
            loadstring(game:HttpGet("https://pastebin.com/raw/w3uzjgEq"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Fake Wallhop",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Utlimate-WallHop-Obby-BEST-FAKE-WALLHOP-SCRIPT-45056"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Shaders",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-PShade-Ultimate-not-made-by-me-138315"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Ladder Flick Macro",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-ladder-flicking-macro-execute-again-if-you-died-53200"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Hug People",
        Callback = function()
            loadstring(game:HttpGet("https://pastefy.app/fhUzn6vQ/raw"))()
        end,
    })
    local _lobbyIsAdmin = _G.DWIsWhitelisted
local _lobbyIsOwner = _G.DWIsHigherUp
    local AdminTab = Window:CreateTab("Admin", "crown")
    if _lobbyIsAdmin then
        AdminTab:CreateLabel("Welcome, " .. player.Name .. ". You are whitelisted.")
        AdminTab:CreateSection("Admin Commands")
        AdminTab:CreateLabel(":kick [name/all] - Kicks the player")
        AdminTab:CreateLabel(":ban [name/all] [reason] - Bans the player")
        AdminTab:CreateLabel(":kill [name/all] - Kills the player")
        AdminTab:CreateLabel(":freeze [name/all] - Freezes the player")
        AdminTab:CreateLabel(":unfreeze [name/all] - Unfreezes the player")
        AdminTab:CreateLabel(":void [name/all] - Sends player to the void")
        AdminTab:CreateLabel(":bring [name/all] - Brings player to you")
        AdminTab:CreateLabel(":fling [name/all] - Flings the player")
        AdminTab:CreateLabel(":clown [name/all] - Kidnaps and teleports the player")
                AdminTab:CreateToggle({
            Name = "FPS Bounce",
            CurrentValue = false,
            Flag = "FpsBounceLobby",
            Callback = function(Value)
                _G._FpsBounceEnabled = Value
            end,
        })
    else
        AdminTab:CreateLabel("This tab is for whitelisted users only.")
        AdminTab:CreateLabel("Join the Discord for more information.")
    end
    local DiscordTab = Window:CreateTab("Discord", "message-circle")
    DiscordTab:CreateSection("DramaWare Discord")
    DiscordTab:CreateLabel("Join the Discord for questions & suggestions!")
    DiscordTab:CreateButton({
        Name = "Copy Discord Server Link",
        Callback = function()
            setclipboard("https://discord.gg/JMVBUsqBCQ")
            Rayfield:Notify({
                Title = "Copied!",
                Content = "Discord link copied to clipboard.",
                Duration = 3,
            })
        end,
    })
    DiscordTab:CreateSection("Contact")
    DiscordTab:CreateLabel("Discord: kcf8")
    DiscordTab:CreateLabel("Discord: calfully")
    DiscordTab:CreateLabel("Discord: dbgrispresent")
    return
end
if isPractice then
    local Window = Rayfield:CreateWindow({
        Name = "DramaWare V2 (Practice)",
        LoadingTitle = "DramaWare (Practice)",
        LoadingSubtitle = "by kobi, callie, and irib",
        ShowText = "DramaWare",
        Theme = "DarkBlue",
        DisableRayfieldPrompts = false,
        DisableBuildWarnings = false,
        MinimizeKey = Enum.KeyCode.LeftControl,
        CustomUIStrings = {
            ["Rayfield"] = "DramaWare",
            ["Hide"] = "Hide",
            ["Show"] = "Show",
        },
    })
    local savedTheme = loadTheme()
    if savedTheme then pcall(function() Window.ModifyTheme(savedTheme) end) end
    local InfoTab = Window:CreateTab("Info", "info")
    InfoTab:CreateSection("DramaWare")
    InfoTab:CreateLabel("You are in the Practice Server.")
    InfoTab:CreateLabel("All game modes supported: Camp, Movies, Expedition, Practice.")
    InfoTab:CreateButton({
        Name = "Fling People",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxcheatck/reanimatescript/main/script.lua", true))()
        end,
    })
    local _swordKillAllConn = nil
    InfoTab:CreateToggle({
        Name = "Sword Kill All",
        CurrentValue = false,
        Flag = "PracticeSwordKillAll",
        Callback = function(Value)
            if Value then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local oldCFrame = hrp and hrp.CFrame
                game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("PracticeMap"):FireServer("Movies", "Beach")
                if oldCFrame then
                    task.wait(0.5)
                    local newChar = player.Character
                    local newHrp = newChar and newChar:FindFirstChild("HumanoidRootPart")
                    if newHrp then
                        newHrp.CFrame = oldCFrame
                    end
                end
                task.spawn(function()
                    local backpack = player:WaitForChild("Backpack")
                    local tool = nil
                    local waited = 0
                    while waited < 3 do
                        for _, t in ipairs(backpack:GetChildren()) do
                            if t:IsA("Tool") then
                                tool = t
                                break
                            end
                        end
                        if tool then break end
                        task.wait(0.1)
                        waited = waited + 0.1
                    end
                    if tool then
                        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                        if hum then
                            hum:EquipTool(tool)
                        end
                    end
                end)
                local range = 1000000
                _swordKillAllConn = game:GetService("RunService").RenderStepped:Connect(function()
                    local p = game.Players:GetPlayers()
                    for i = 2, #p do 
                        local v = p[i].Character
                        if v and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 and v:FindFirstChild("HumanoidRootPart") and player:DistanceFromCharacter(v.HumanoidRootPart.Position) <= range then
                            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                            if tool and tool:FindFirstChild("Handle") then
                                tool:Activate()
                                for _, part in next, v:GetChildren() do
                                    if part:IsA("BasePart") then
                                        firetouchinterest(tool.Handle, part, 0)
                                        firetouchinterest(tool.Handle, part, 1)
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                if _swordKillAllConn then
                    _swordKillAllConn:Disconnect()
                    _swordKillAllConn = nil
                end
            end
        end,
    })
    local UniversalTab = Window:CreateTab("Universal", "globe")
    UniversalTab:CreateButton({
        Name = "Open Console",
        Callback = function()
            game:GetService('StarterGui'):SetCore('DevConsoleVisible', true)
        end,
    })
    UniversalTab:CreateButton({
        Name = "Instant Respawn",
        Callback = function()
            local character = game.Players.LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end,
    })
    UniversalTab:CreateButton({
        Name = "Fake Lag",
        Callback = function()
            local ScreenGui = Instance.new("ScreenGui")
            local Frame = Instance.new("Frame")
            local Frame_2 = Instance.new("Frame")
            local TextLabel = Instance.new("TextLabel")
            local TextButton = Instance.new("TextButton")
            ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
            ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            ScreenGui.ResetOnSpawn = false
            Frame.Parent = ScreenGui
            Frame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
            Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Frame.BorderSizePixel = 0
            Frame.Position = UDim2.new(0.388539821, 0, 0.427821517, 0)
            Frame.Size = UDim2.new(0, 158, 0, 100)
            Frame_2.Parent = Frame
            Frame_2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Frame_2.BorderSizePixel = 0
            Frame_2.Size = UDim2.new(0, 158, 0, 25)
            TextLabel.Parent = Frame_2
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.BackgroundTransparency = 1.000
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.Position = UDim2.new(0.112792775, 0, -0.0151660154, 0)
            TextLabel.Size = UDim2.new(0, 121, 0, 26)
            TextLabel.Font = Enum.Font.Sarpanch
            TextLabel.Text = "Fake Lag"
            TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.TextSize = 16.000
            TextButton.Parent = Frame
            TextButton.BackgroundColor3 = Color3.fromRGB(205, 84, 75)
            TextButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
            TextButton.BorderSizePixel = 0
            TextButton.Position = UDim2.new(0.113924049, 0, 0.4, 0)
            TextButton.Size = UDim2.new(0, 121, 0, 37)
            TextButton.Font = Enum.Font.SourceSansItalic
            TextButton.Text = "Enable"
            TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            TextButton.TextSize = 20.000
            local fakeLagEnabled = false
            local fakeLagThread
            local function toggleFakeLag()
                local lp = game:GetService("Players").LocalPlayer
                while fakeLagEnabled do
                    task.wait()
                    local character = lp.Character
                    if character then
                        local hrp = character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Anchored = true
                            task.wait(0.2)
                            hrp.Anchored = false
                            task.wait()
                        end
                    end
                end
            end
            TextButton.MouseButton1Click:Connect(function()
                fakeLagEnabled = not fakeLagEnabled
                TextButton.Text = fakeLagEnabled and "Enabled" or "Enable"
                if fakeLagEnabled then
                    fakeLagThread = coroutine.create(toggleFakeLag)
                    coroutine.resume(fakeLagThread)
                end
            end)
            Frame.Active = true
            Frame.Draggable = true
        end,
    })
    UniversalTab:CreateButton({
        Name = "PC Freeze Glitch",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Mobile-lag-jump-for-r6-glitches-48710"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Infinite Yield",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Energize",
        Callback = function()
            loadstring(game:HttpGet("https://pastebin.com/raw/Cfeu2ZPc"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Fly V3",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Sound Panel",
        Callback = function()
            loadstring(game:HttpGet("https://pastebin.com/raw/w3uzjgEq"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Fake Wallhop",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Utlimate-WallHop-Obby-BEST-FAKE-WALLHOP-SCRIPT-45056"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Shaders",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-PShade-Ultimate-not-made-by-me-138315"))()
        end,
    })
    UniversalTab:CreateButton({
        Name = "Ladder Flick Macro (Re-Execute if You Died)",
        Callback = function()
            loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-ladder-flicking-macro-execute-again-if-you-died-53200"))()
        end,
    })
    do
        local _Players = game:GetService("Players")
        local _LocalPlayer = _Players.LocalPlayer
        local _hideEnabled = false
        local _playerConns = {}
        local function _isFriend(p)
            return _LocalPlayer:IsFriendsWith(p.UserId)
        end
        local function _hideChar(char)
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Decal") then
                    obj.Transparency = 1
                elseif obj:IsA("BillboardGui") then
                    obj.Enabled = false
                end
            end
        end
        local function _showChar(char)
            for _, obj in pairs(char:GetDescendants()) do
                if obj:IsA("BasePart") or obj:IsA("Decal") then
                    if obj.Name == "HumanoidRootPart" then
                        obj.Transparency = 1
                    else
                        obj.Transparency = 0
                    end
                elseif obj:IsA("BillboardGui") then
                    obj.Enabled = true
                end
            end
        end
        local function _applyToPlayer(p)
            if p == _LocalPlayer then return end
            if _hideEnabled and not _isFriend(p) then
                if p.Character then _hideChar(p.Character) end
            else
                if p.Character then _showChar(p.Character) end
            end
        end
        local function _updateAll()
            for _, p in pairs(_Players:GetPlayers()) do
                _applyToPlayer(p)
            end
        end
        UniversalTab:CreateToggle({
            Name = "Hide All Players (Except Friends)",
            CurrentValue = false,
            Flag = "HideNonFriendsPractice",
            Callback = function(state)
                _hideEnabled = state
                _updateAll()
                if state then
                    _playerConns["added"] = _Players.PlayerAdded:Connect(function(p)
                        local c = p.CharacterAdded:Connect(function(char)
                            if _hideEnabled and not _isFriend(p) then
                                _hideChar(char)
                            end
                        end)
                        _playerConns["char_" .. p.UserId] = c
                        _applyToPlayer(p)
                    end)
                else
                    for k, conn in pairs(_playerConns) do
                        if typeof(conn) == "RBXScriptConnection" then
                            conn:Disconnect()
                        end
                        _playerConns[k] = nil
                    end
                    _updateAll()
                end
            end,
        })
    end
local OtherTab = Window:CreateTab("Other", "package")
_G.SelectedFont = nil
_G.StaticColor = Color3.fromRGB(255, 182, 193)
_G.StaticColorCustom = false
_G.RainbowMode = false
_G.RainbowSpeed = 0.5
_G.CustomName = ""
_G.UseCustomName = false
OtherTab:CreateSection("Fake Leaderboards")
OtherTab:CreateButton({
    Name = "Fake #1 All Leaderboards (CLIENT)",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=48&height=48&format=png"
        local boards = {
            workspace.Elements.MoviesWinLeaderboard,
            workspace.Elements.CampWinLeaderboard,
            workspace.Elements.ExpeditionWinLeaderboard
        }
        for _, board in pairs(boards) do
            local scrollFrame = board.SurfaceGui.ScrollingFrame
            for _, frame in pairs(scrollFrame:GetChildren()) do
                if frame:IsA("Frame") then
                    local placeLabel = frame:FindFirstChild("Image") and frame.Image:FindFirstChild("Place")
                    if placeLabel and placeLabel.Text == "1" then
                        frame.PName.Text = player.Name
                        frame.Image.Image = avatarUrl
                        break
                    end
                end
            end
        end
    end,
})
OtherTab:CreateSection("Appearance")
OtherTab:CreateInput({
   Name = "Custom Name",
   PlaceholderText = "Enter name here...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       _G.CustomName = Text
       _G.UseCustomName = (Text ~= "")
   end,
})
OtherTab:CreateToggle({
   Name = "Rainbow Effect",
   CurrentValue = false,
   Flag = "RainbowToggle",
   Callback = function(Value)
      _G.RainbowMode = Value
   end,
})
OtherTab:CreateColorPicker({
    Name = "Static Color",
    Color = Color3.fromRGB(255, 182, 193),
    Flag = "ColorPicker",
    Callback = function(Value)
        _G.StaticColor = Value
        _G.StaticColorCustom = true
    end
})
OtherTab:CreateDropdown({
    Name = "UI Theme",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = {"DarkBlue"},
    MultipleOptions = false,
    Flag = "ThemeDropdown",
    Callback = function(option)
        Window.ModifyTheme(option[1])
        saveTheme(option[1])
    end,
})
game:GetService("RunService").RenderStepped:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if _G.UseCustomName and _G.CustomName ~= "" then
                obj.Text = _G.CustomName
            end
            if _G.RainbowMode then
                local hue = (tick() * _G.RainbowSpeed) % 1
                obj.TextColor3 = Color3.fromHSV(hue, 0.6, 1) 
            elseif _G.StaticColorCustom then
                obj.TextColor3 = _G.StaticColor
            end
            obj.TextStrokeTransparency = 0.5
            obj.BackgroundTransparency = 1
        end
    end
end)
    local _practiceLocalPlayer = game.Players.LocalPlayer
local _practiceIsAdmin = _G.DWIsWhitelisted
local _practiceIsOwner = _G.DWIsHigherUp
    local _DWAdminNames = {tomorrownevercam3=true,urnanhasimplants=true,tomorownevercam3=true,enigmapopstvr=true,calfully=true,pwupiify=true,miss_minutess=true,pleaseunba123=true,i_loveseals333333=true,URR3M=true,urr6m=true,vkyoubvh7=true,yousolatido=true,["1millioneuross"]=true,Timmy977272=true,Blushingxsha=true,natkingOMG123=true,BananaPogoStickBoom=true,hccy0=true,lLOVE_RAVIES=true,["3hrae"]=true,FunderscoreExtras=true,LifeDoesCoolThings=true,vxr2uue=true,hellruIer2=true,ILOVE_RAVIES=true,Cropped=true,LVL9T=true,P4UOM=true,SYK8I=true,totallydexterr=true,leahvzp=true,rainbowpoo011=true,iihobo_trash=true,lcyCoIa=true,["16kbrxkxn"]=true}
local function _practiceIsOwnerName(name)
    local _ownerNames = {tomorrownevercam3=true,urnanhasimplants=true,tomorownevercam3=true,enigmapopstvr=true,calfully=true}
    return _ownerNames[name:lower()] == true
end
local function _practiceIsAdminName(name)
    return _DWAdminNames[name:lower()] == true
end
    local PracticeAdminTab = Window:CreateTab("Admin", "crown")
    if _practiceIsAdmin then
        PracticeAdminTab:CreateLabel("Welcome, " .. _practiceLocalPlayer.Name .. ". You are whitelisted.")
        PracticeAdminTab:CreateSection("Admin Status")
        PracticeAdminTab:CreateSection("Admin Commands (Works on DramaWare Users)")
        PracticeAdminTab:CreateLabel(":kick [name/all] - Kicks the player")
        PracticeAdminTab:CreateLabel(":ban [name/all] [reason] - Bans the player")
        PracticeAdminTab:CreateLabel(":kill [name/all] - Kills the player")
        PracticeAdminTab:CreateLabel(":freeze [name/all] - Freezes the player")
        PracticeAdminTab:CreateLabel(":unfreeze [name/all] - Unfreezes the player")
        PracticeAdminTab:CreateLabel(":void [name/all] - Sends player to the void")
        PracticeAdminTab:CreateLabel(":bring [name/all] - Brings player to you")
        PracticeAdminTab:CreateLabel(":fling [name/all] - Flings the player")
        PracticeAdminTab:CreateLabel(":clown [name/all] - Kidnaps and teleports the player")
                PracticeAdminTab:CreateToggle({
            Name = "FPS Bounce",
            CurrentValue = false,
            Flag = "FpsBouncePractice",
            Callback = function(Value)
                _G._FpsBounceEnabled = Value
            end,
        })
        PracticeAdminTab:CreateSection("Admin Panel")
        PracticeAdminTab:CreateButton({
            Name = "Admin Panel Broken (In Beta)",
            Callback = function()
                local rs = game:GetService("ReplicatedStorage")
                local gui = rs:WaitForChild("Products"):WaitForChild("GUIs"):WaitForChild("Settings"):Clone()
                gui.Parent = _practiceLocalPlayer:WaitForChild("PlayerGui")
                gui.Enabled = true
                for _, v in pairs(gui:GetDescendants()) do
                    if v:IsA("Frame") or v:IsA("TextLabel") or v:IsA("ImageLabel") then
                        v.Visible = true
                    end
                    if v:IsA("TextButton") or v:IsA("ImageButton") then
                        v.Visible = true
                        v.Active = true
                    end
                end
            end,
        })
        PracticeAdminTab:CreateSection("Shortcuts")
        PracticeAdminTab:CreateButton({
            Name = "Lag High Jump",
            Callback = function()
                dolaghighjump()
            end,
        })
        PracticeAdminTab:CreateButton({
            Name = "Floor Bounce",
            Callback = function()
                doFloorBounce()
            end,
        })
    else
        PracticeAdminTab:CreateLabel("This tab is for whitelisted users only.")
        PracticeAdminTab:CreateLabel("Join the Discord for more information.")
    end
    local function _practiceHandleCommand(senderName, msg)
        if not _practiceIsAdminName(senderName) then return end
        msg = msg:lower():gsub("^%s+", "")
        if msg:sub(1,1) ~= ":" then return end
        local parts = {}
        for part in msg:gmatch("%S+") do table.insert(parts, part) end
        local command = parts[1] and parts[1]:sub(2) or ""
        local targetName = parts[2] or ""
        local param = parts[3] or ""
        local lp = game.Players.LocalPlayer
        if targetName ~= "all" and lp.Name:lower() ~= targetName:lower() then return end
        if _practiceIsOwnerName(lp.Name) and not _practiceIsOwnerName(senderName) then return end
        if command == "kick" then
            lp:Kick("You have been kicked.\nModerator: " .. senderName .. "\nReason: Kicked via DramaWare 5")
        elseif command == "ban" then
            local reason = (param and param ~= "") and param or "Exploiting"
            lp:Kick("You have been banned.\nModerator: " .. senderName .. "\nReason: " .. reason .. "\nExpires: Never\nBan ID: " .. math.random(100000, 999999))
        elseif command == "kill" then
            if lp.Character and lp.Character:FindFirstChild("Humanoid") then
                lp.Character.Humanoid.Health = 0
            end
        elseif command == "freeze" then
            if lp.Character then
                if lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = true end
                if lp.Character:FindFirstChild("Torso") then lp.Character.Torso.Anchored = true end
            end
        elseif command == "unfreeze" or command == "thaw" then
            if lp.Character then
                if lp.Character:FindFirstChild("HumanoidRootPart") then lp.Character.HumanoidRootPart.Anchored = false end
                if lp.Character:FindFirstChild("Torso") then lp.Character.Torso.Anchored = false end
            end
        elseif command == "void" then
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = CFrame.new(0, -10000, 0)
            end
        elseif command == "bring" then
            local sender = game.Players:FindFirstChild(senderName)
            if sender and sender.Character and sender.Character:FindFirstChild("HumanoidRootPart") and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = sender.Character.HumanoidRootPart.CFrame
            end
        elseif command == "fling" then
            if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(math.random(-200,200), 500, math.random(-200,200))
            end
        end
    end
    local function _practiceConnectOldChat()
        for _, p in ipairs(game.Players:GetPlayers()) do
            if _practiceIsAdminName(p.Name) then
                p.Chatted:Connect(function(msg) _practiceHandleCommand(p.Name, msg) end)
            end
        end
        game.Players.PlayerAdded:Connect(function(p)
            if _practiceIsAdminName(p.Name) then
                p.Chatted:Connect(function(msg) _practiceHandleCommand(p.Name, msg) end)
            end
        end)
    end
    local function _practiceConnectNewChat()
        local tcs = game:GetService("TextChatService")
        if tcs and tcs.MessageReceived then
            tcs.MessageReceived:Connect(function(msg)
                if msg and msg.TextSource then
                    _practiceHandleCommand(msg.TextSource.Name, msg.Text or "")
                end
            end)
        end
    end
    pcall(_practiceConnectOldChat)
    pcall(_practiceConnectNewChat)
    local DiscordTab = Window:CreateTab("Discord", "message-circle")
    DiscordTab:CreateSection("DramaWare Discord")
    DiscordTab:CreateLabel("Join the Discord for questions & suggestions!")
    DiscordTab:CreateButton({
        Name = "Copy Discord Server Link",
        Callback = function()
            setclipboard("https://discord.gg/JMVBUsqBCQ")
            Rayfield:Notify({
                Title = "Copied!",
                Content = "Discord link copied to clipboard.",
                Duration = 3,
            })
        end,
    })
    DiscordTab:CreateSection("Contact")
    DiscordTab:CreateLabel("Discord: kcf8")
    DiscordTab:CreateLabel("Discord: calfully")
    DiscordTab:CreateLabel("Discord: dbgrispresent")
    return
end
local Window = Rayfield:CreateWindow({
    Name = "DramaWare V2 (" .. (isCamp and "Camp" or isMovies and "Movies" or isExpedition and "Expedition" or "Unknown") .. ")",
    LoadingTitle = "DramaWare (" .. (isCamp and "Camp" or isMovies and "Movies" or isExpedition and "Expedition" or "Unknown") .. ")",
    LoadingSubtitle = "by kobi, callie, and irib",
    ShowText = "DramaWare",
    Theme = "DarkBlue",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    MinimizeKey = Enum.KeyCode.LeftControl,
    CustomUIStrings = {
        ["Rayfield"] = "DramaWare",
        ["Hide"] = "Hide",
        ["Show"] = "Show"
    },
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "DramaWare",
        FileName = "Config"
    },
})
local savedTheme = loadTheme()
if savedTheme then pcall(function() Window.ModifyTheme(savedTheme) end) end
local isAdmin = _G.DWIsWhitelisted
local isOwner = _G.DWIsHigherUp
if isOwner then
    print("Owner permissions are avaliable.")
elseif isAdmin then
   print("Admin permissions are avaliable")
end
local ChallengesTab = Window:CreateTab("Challenges", "trophy")
local MainTab = Window:CreateTab("Main", "star")
local CharactersTab = Window:CreateTab("Characters", "shirt")
local PlayerTab = Window:CreateTab("Player", "user")
local StatsTab = Window:CreateTab("Stats Viewer", "sticky-note")
local TeleportsTab = Window:CreateTab("Teleports", "map-pin")
local UniversalTab = Window:CreateTab("Universal", "globe")
local OtherTab = Window:CreateTab("Other", "package")
local VIPTab = Window:CreateTab("Admin", "crown")
local DiscordTab = Window:CreateTab("Discord", "message-circle")
local AutoPlayTab = Window:CreateTab("Auto Play", "play")
for _, _tab in ipairs({ChallengesTab, MainTab, CharactersTab, PlayerTab, StatsTab, TeleportsTab, UniversalTab, OtherTab, VIPTab, DiscordTab, AutoPlayTab}) do
    DW_PatchTab(_tab)
end
local TAS_Players = game:GetService("Players")
local TAS_RunService = game:GetService("RunService")
local TAS_HttpService = game:GetService("HttpService")
local TAS_Workspace = game:GetService("Workspace")
local TAS_UserInputService = game:GetService("UserInputService")
local TAS_PathfindingService = game:GetService("PathfindingService")
local TAS_LocalPlayer = TAS_Players.LocalPlayer
local TAS_ViewingTAS = false
local TAS_PlaybackConnection = nil
local TAS_FinishTouchConnection = nil
local TAS_CurrentAppliedShiftLock = false
local TAS_DisableShiftlockAndCamera = not isAdmin
local TAS_PathfindToStart = false
local TAS_ActivePathfindId = 0
local TAS_LastMapName = nil
local TAS_LastMapDetectTime = 0
local TAS_SelectedCaveChaos = "Cave Chaos"
local TAS_SelectedUnstableSavannah = "Unstable Savannah"
local TAS_RouteSources = {
    ["Bootcamp Team 1"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Bootcamp%20Team%201.json"},
    ["Bootcamp Team 2"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Bootcamp%20Team%202.json"},
    ["Bootcamp Team 3"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Bootcamp%20Team%203.json"},
    ["Cave Chaos Clip"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Cave%20Chaos%20Clip.json"},
    ["Cave Chaos"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Cave%20Chaos.json"},
    ["Colosseum Climb"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Colosseum.json"},
    ["Construct Course"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Construct%20Course.json"},
    ["Hill Hike"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Hill%20HIke.json"},
    ["Lava Dash"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Lava%20Dash.json"},
    ["Obstacle Course"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Obstacle%20Course.json"},
    ["Pond Pier"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Pond%20Pier.json"},
    ["Rickety Rails"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Rickety%20Rails.json"},
    ["Rock Wall Team 1"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Rock%20Wall%20Team%201.json"},
    ["Rock Wall Team 2"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Rock%20Wall%20Team%202.json"},
    ["Rock Wall Team 3"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Rock%20Wall%20Team%203.json"},
    ["Spinner"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Spinner"},
    ["Sweeper"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Sweeper.json"},
    ["Tightrope"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Tightrope%20Obby.json"},
    ["Unstable Savannah Clip"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Unstable%20Savannah%20Clip.json"},
    ["Unstable Savannah"] = {type = "url", source = "https://raw.githubusercontent.com/callienew/tas-skid-skid-skid/refs/heads/main/Unstable%20Savannah.json"},
}

local function TAS_FetchFromURL(url)
    local success, content = pcall(function() return game:HttpGet(url, true) end)
    if not success then return nil end
    local parseOk, data = pcall(function() return TAS_HttpService:JSONDecode(content) end)
    if not parseOk or type(data) ~= "table" then return nil end
    return data
end

local function TAS_FetchFromLoadstring(url)
    local success, content = pcall(function() return game:HttpGet(url, true) end)
    if not success then return nil end
    local fnOk, fn = pcall(function() return loadstring(content) end)
    if not fnOk or type(fn) ~= "function" then return nil end
    local execOk, data = pcall(fn)
    if not execOk or type(data) ~= "table" then return nil end
    return data
end

local function TAS_LoadFromSource(sourceInfo)
    if type(sourceInfo) == "string" then
        if not isfile or not readfile then return nil end
        if not isfile(sourceInfo) then return nil end
        local success, data = pcall(function() return TAS_HttpService:JSONDecode(readfile(sourceInfo)) end)
        if not success or type(data) ~= "table" then return nil end
        return data
    elseif type(sourceInfo) == "table" then
        if sourceInfo.type == "url" then return TAS_FetchFromURL(sourceInfo.source)
        elseif sourceInfo.type == "loadstring" then return TAS_FetchFromLoadstring(sourceInfo.source)
        elseif sourceInfo.type == "raw" and type(sourceInfo.data) == "table" then return sourceInfo.data
        else return nil end
    end
    return nil
end

local function TAS_ApplyShiftLock(enabled)
    local actuallyEnabled = TAS_UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
    if enabled == actuallyEnabled then return end
    TAS_CurrentAppliedShiftLock = enabled
    keypress(0xA0)
    task.wait()
    keyrelease(0xA0)
end

local function TAS_StopPlayback()
    if TAS_PlaybackConnection then
        TAS_PlaybackConnection:Disconnect()
        TAS_PlaybackConnection = nil
    end
    if TAS_FinishTouchConnection then
        TAS_FinishTouchConnection:Disconnect()
        TAS_FinishTouchConnection = nil
    end
    TAS_ViewingTAS = false
    if TAS_LocalPlayer.Character and TAS_LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        TAS_LocalPlayer.Character.HumanoidRootPart.Anchored = false
    end
    if not TAS_DisableShiftlockAndCamera then
        task.spawn(TAS_ApplyShiftLock, false)
    end
end

local function TAS_PlayEmoteOrAnimation(Hum, name)
    if not Hum or not Hum.Parent then return end
    local Character = Hum.Parent
    local Animate = Character:FindFirstChild("Animate")
    if Animate then
        local PlayEmote = Animate:FindFirstChild("PlayEmote")
        if PlayEmote and PlayEmote:IsA("BindableFunction") then
            local ok = pcall(function() PlayEmote:Invoke(name) end)
            if ok then return end
        end
    end
    local Animator = Hum:FindFirstChildOfClass("Animator")
    if Animator then
        for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
            if track.Name == name then
                if not track.IsPlaying then track:Play() end
                track:AdjustSpeed(1)
                return
            end
        end
        local animObj = Character:FindFirstChild(name, true)
        if animObj and animObj:IsA("Animation") then
            local track = Animator:LoadAnimation(animObj)
            track.Name = name
            track:Play()
            track:AdjustSpeed(1)
            return
        end
        if Animate then
            local EmotesFolder = Animate:FindFirstChild("Emotes")
            if EmotesFolder then
                local EmoteEntry = EmotesFolder:FindFirstChild(name)
                if EmoteEntry then
                    local anim = EmoteEntry:FindFirstChildOfClass("Animation")
                    if anim then
                        local track = Animator:LoadAnimation(anim)
                        track.Name = name
                        track:Play()
                        track:AdjustSpeed(1)
                        return
                    end
                end
            end
        end
    end
    if Hum.PlayEmote then pcall(function() Hum:PlayEmote(name) end) end
    local ChatEvents = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
    if ChatEvents then
        local SayEvent = ChatEvents:FindFirstChild("SayMessageRequest")
        if SayEvent then SayEvent:FireServer("/e " .. name, "All") end
    end
end

local function TAS_GetFramePosition(frame)
    return Vector3.new(frame.CCFrame[1], frame.CCFrame[2], frame.CCFrame[3])
end

local function TAS_ComputePathTime(path, fromPos)
    if path.Status ~= Enum.PathStatus.Success then return math.huge end
    local waypoints = path:GetWaypoints()
    if #waypoints == 0 then return math.huge end
    local length = 0
    local last = fromPos
    for _, wp in ipairs(waypoints) do
        length = length + (wp.Position - last).Magnitude
        last = wp.Position
    end
    return length / 16
end

local function TAS_FindBestSyncFrame(TAS, currentPos)
    if #TAS == 0 then return 1 end
    local maxFrame = math.min(120, #TAS)
    local bestEstIndex = 1
    local bestEstSaved = -math.huge
    local closestIndex = 1
    local closestDist = math.huge
    for i = 1, maxFrame do
        local frame = TAS[i]
        local pos = TAS_GetFramePosition(frame)
        local dist = (pos - currentPos).Magnitude
        local estTime = dist / 16
        local estSaved = frame.time - estTime
        if dist < closestDist then
            closestDist = dist
            closestIndex = i
        end
        if estSaved > bestEstSaved and frame.time >= estTime then
            bestEstSaved = estSaved
            bestEstIndex = i
        end
    end
    if bestEstSaved == -math.huge then return closestIndex end
    local searchStart = math.max(1, bestEstIndex - 10)
    local searchEnd = math.min(maxFrame, bestEstIndex + 10)
    local bestIndex = bestEstIndex
    local bestSaved = bestEstSaved
    for i = searchStart, searchEnd do
        local frame = TAS[i]
        local pos = TAS_GetFramePosition(frame)
        local path = TAS_PathfindingService:CreatePath({AgentRadius = 0.5, AgentHeight = 2, AgentCanJump = true})
        local ok = pcall(function() path:ComputeAsync(currentPos, pos) end)
        local pathTime
        if ok and path.Status == Enum.PathStatus.Success then
            pathTime = TAS_ComputePathTime(path, currentPos)
        else
            pathTime = (pos - currentPos).Magnitude / 16
        end
        local saved = frame.time - pathTime
        if saved > bestSaved and frame.time >= pathTime then
            bestSaved = saved
            bestIndex = i
        end
    end
    return bestIndex
end

local function TAS_ViewPlayback(TAS, startIndex)
    startIndex = startIndex or 1
    if TAS_ViewingTAS or #TAS == 0 then return end
    TAS_ViewingTAS = true
    local syncFrame = TAS[startIndex]
    local StartTime = tick() - syncFrame.time
    local CurrentFrameIndex = startIndex
    local Character = TAS_LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        TAS_ViewingTAS = false
        return
    end
    local RootPart = Character.HumanoidRootPart
    local Hum = Character.Humanoid
    RootPart.Anchored = false
    local assets = TAS_Workspace:FindFirstChild("Assets")
    local finishPart = assets and assets:FindFirstChild("Finish", true)
    local mapFolder = finishPart and finishPart:FindFirstAncestorOfClass("Folder") or finishPart and finishPart:FindFirstAncestorOfClass("Model")
    if finishPart then
        TAS_FinishTouchConnection = finishPart.Touched:Connect(function(hit)
            if hit and hit.Parent == Character then
                TAS_StopPlayback()
                return
            end
            if mapFolder and not assets:FindFirstChild(mapFolder.Name) then
                TAS_StopPlayback()
            end
        end)
    end
    TAS_PlaybackConnection = TAS_RunService.Heartbeat:Connect(function()
        if not RootPart or not RootPart.Parent then
            TAS_StopPlayback()
            return
        end
        if not TAS_ViewingTAS then return end
        local ElapsedTime = tick() - StartTime
        local TargetFrame = nil
        while CurrentFrameIndex <= #TAS and TAS[CurrentFrameIndex].time <= ElapsedTime do
             TargetFrame = TAS[CurrentFrameIndex]
             CurrentFrameIndex = CurrentFrameIndex + 1
        end
        if TargetFrame then
             local cf = TargetFrame.CCFrame
             local cam = TargetFrame.CCameraCFrame
             RootPart.CFrame = CFrame.new(cf[1], cf[2], cf[3], cf[4], cf[5], cf[6], cf[7], cf[8], cf[9], cf[10], cf[11], cf[12])
             RootPart.Velocity = Vector3.new(TargetFrame.VVelocity[1], TargetFrame.VVelocity[2], TargetFrame.VVelocity[3])
             if not TAS_DisableShiftlockAndCamera then
                 TAS_Workspace.CurrentCamera.CFrame = CFrame.new(cam[1], cam[2], cam[3], cam[4], cam[5], cam[6], cam[7], cam[8], cam[9], cam[10], cam[11], cam[12])
             end
             local AnimInfo = TargetFrame.AAnimation
             if AnimInfo and Hum and Hum.Parent then
                 TAS_PlayEmoteOrAnimation(Hum, AnimInfo.Name)
             end
             if not TAS_DisableShiftlockAndCamera and TargetFrame.ShiftLock ~= nil then
                 task.spawn(TAS_ApplyShiftLock, TargetFrame.ShiftLock)
             end
        end
        if CurrentFrameIndex > #TAS then
            TAS_StopPlayback()
        end
    end)
end

local function TAS_ComputePathToSync(TAS, currentPos, forcePathfind)
    local syncIndex = 1
    if TAS_PathfindToStart or forcePathfind then
        syncIndex = TAS_FindBestSyncFrame(TAS, currentPos)
    end
    local syncPos = TAS_GetFramePosition(TAS[syncIndex])
    if (syncPos - currentPos).Magnitude < 5 then
        return syncIndex, nil, syncPos
    end
    local path = TAS_PathfindingService:CreatePath({AgentRadius = 1.5, AgentHeight = 4, AgentCanJump = true})
    local ok = pcall(function() path:ComputeAsync(currentPos, syncPos) end)
    if not ok or path.Status ~= Enum.PathStatus.Success then
        return syncIndex, nil, syncPos
    end
    return syncIndex, path, syncPos
end

local function TAS_ExecutePathAndPlay(TAS, syncIndex, path, syncPos)
    local Character = TAS_LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        TAS_ViewPlayback(TAS, syncIndex)
        return
    end
    local RootPart = Character.HumanoidRootPart
    local Hum = Character.Humanoid
    if not Hum then
        RootPart.CFrame = CFrame.new(syncPos)
        TAS_ViewPlayback(TAS, syncIndex)
        return
    end
    RootPart.Anchored = false
    pcall(function()
        Hum.Sit = false
        Hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
    if not path then
        RootPart.CFrame = CFrame.new(syncPos)
        TAS_ViewPlayback(TAS, syncIndex)
        return
    end
    TAS_ActivePathfindId = TAS_ActivePathfindId + 1
    local thisId = TAS_ActivePathfindId
    local waypoints = path:GetWaypoints()
    task.spawn(function()
        for i, waypoint in ipairs(waypoints) do
            if TAS_ActivePathfindId ~= thisId then return end
            if not Hum or not Hum.Parent then return end
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                Hum.Jump = true
                if RootPart then
                    RootPart.Velocity = Vector3.new(RootPart.Velocity.X, math.max(RootPart.Velocity.Y, 40), RootPart.Velocity.Z)
                end
                task.wait(0.15)
            end
            Hum:MoveTo(waypoint.Position)
            local reached = false
            local con = Hum.MoveToFinished:Connect(function(ok) reached = ok end)
            local startWait = tick()
            while not reached and (tick() - startWait) < 6 do
                if TAS_ActivePathfindId ~= thisId then
                    con:Disconnect()
                    return
                end
                if waypoint.Action == Enum.PathWaypointAction.Jump and Hum and RootPart then
                    Hum.Jump = true
                end
                task.wait(0.05)
            end
            con:Disconnect()
            if not reached then
                if TAS_ActivePathfindId ~= thisId then return end
                RootPart.CFrame = CFrame.new(syncPos)
                break
            end
        end
        if TAS_ActivePathfindId ~= thisId then return end
        if RootPart and (syncPos - RootPart.Position).Magnitude > 10 then
            RootPart.CFrame = CFrame.new(syncPos)
        end
        TAS_ViewPlayback(TAS, syncIndex)
    end)
end

local function TAS_PathfindAndPlay(TAS)
    if #TAS == 0 then return end
    local Character = TAS_LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then
        TAS_ViewPlayback(TAS, 1)
        return
    end
    local currentPos = Character.HumanoidRootPart.Position
    local syncIndex, path, syncPos = TAS_ComputePathToSync(TAS, currentPos, true)
    if not path then
        if (syncPos - currentPos).Magnitude < 5 then
            TAS_ViewPlayback(TAS, syncIndex)
        else
            Character.HumanoidRootPart.CFrame = CFrame.new(syncPos)
            TAS_ViewPlayback(TAS, syncIndex)
        end
        return
    end
    TAS_ExecutePathAndPlay(TAS, syncIndex, path, syncPos)
end

local function TAS_LoadAndPlay(source)
    local data = TAS_LoadFromSource(source)
    if not data then return end
    TAS_ActivePathfindId = TAS_ActivePathfindId + 1
    TAS_StopPlayback()
    if TAS_PathfindToStart then
        TAS_PathfindAndPlay(data)
    else
        TAS_ViewPlayback(data)
    end
end

local function TAS_NormalizeName(name)
    if type(name) == "table" then name = name[1] or "" end
    if type(name) ~= "string" then name = tostring(name) end
    return name:gsub("[^%w]", ""):lower()
end

local function TAS_GetTeamSpawnPosition(teamFolder)
    if not teamFolder then return nil end
    local spawnLoc = teamFolder:FindFirstChildOfClass("SpawnLocation")
    if spawnLoc then return spawnLoc.Position end
    for _, child in ipairs(teamFolder:GetDescendants()) do
        if child:IsA("BasePart") then return child.Position end
    end
    return nil
end

local function TAS_ScoreMapToFile(normMap, normFile)
    if normFile == normMap then return 100 end
    if normFile:find(normMap, 1, true) or normMap:find(normFile, 1, true) then return 50 end
    local score = 0
    for i = 3, math.min(#normMap, 8) do
        local chunk = normMap:sub(1, i)
        if normFile:find(chunk, 1, true) then score = math.max(score, i) end
    end
    return score
end

local function TAS_GetMapTasFile()
    local assets = TAS_Workspace:FindFirstChild("Assets")
    if not assets then return nil end
    local allRoutes = {}
    for name, info in pairs(TAS_RouteSources) do
        table.insert(allRoutes, {name = name, info = info})
    end
    if isfolder and isfolder("TAS_Recorder") and listfiles then
        for _, path in ipairs(listfiles("TAS_Recorder")) do
            if path:match("%.json$") then
                local fileName = path:match("([^/\]+)$") or path
                local baseName = fileName:gsub("%.json$", "")
                table.insert(allRoutes, {name = baseName, info = path})
            end
        end
    end
    if #allRoutes == 0 then return nil end
    local bestFolder = nil
    local bestFolderScore = 0
    local bestCandidate = nil
    for _, child in ipairs(assets:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            local normMap = TAS_NormalizeName(child.Name)
            local folderBestScore = 0
            local folderBestCandidate = nil
            for _, route in ipairs(allRoutes) do
                local normFile = TAS_NormalizeName(route.name)
                local score = TAS_ScoreMapToFile(normMap, normFile)
                if score > folderBestScore then
                    folderBestScore = score
                    folderBestCandidate = {path = route.info, name = route.name, norm = normFile, score = score, team = normFile:match("team(%d)")}
                end
            end
            if folderBestScore > bestFolderScore then
                bestFolderScore = folderBestScore
                bestFolder = child
                bestCandidate = folderBestCandidate
            end
        end
    end
    if not bestFolder or bestFolderScore < 5 then return nil end
    local mapName = bestFolder.Name
    if TAS_LastMapName ~= mapName then
        TAS_LastMapName = mapName
        TAS_LastMapDetectTime = tick()
        return nil
    end
    if tick() - TAS_LastMapDetectTime < 1 then return nil end
    local preferredTeam = nil
    local teamFolders = {}
    for _, child in ipairs(bestFolder:GetChildren()) do
        local teamNum = child.Name:match("^Team(%d+)$")
        if teamNum then table.insert(teamFolders, {folder = child, num = tonumber(teamNum)}) end
    end
    if #teamFolders > 1 then
        local char = TAS_LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local closestTeam = nil
            local closestDist = math.huge
            for _, info in ipairs(teamFolders) do
                local pos = TAS_GetTeamSpawnPosition(info.folder)
                if pos then
                    local dist = (pos - hrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestTeam = info.num
                    end
                end
            end
            if closestTeam then preferredTeam = closestTeam end
        end
    end
    local mapPrefix = bestCandidate.norm:gsub("team%d+", "")
    local candidates = {}
    for _, route in ipairs(allRoutes) do
        local normFile = TAS_NormalizeName(route.name)
        local candPrefix = normFile:gsub("team%d+", "")
        if candPrefix == mapPrefix or normFile:sub(1, #mapPrefix) == mapPrefix then
            table.insert(candidates, {path = route.info, name = route.name, norm = normFile, team = normFile:match("team(%d)")})
        end
    end
    if preferredTeam then
        for _, cand in ipairs(candidates) do
            if cand.team and tonumber(cand.team) == preferredTeam then return cand.path end
        end
    end
    for _, cand in ipairs(candidates) do
        if cand.norm:find("team1") then return cand.path end
    end
    local mapNameLower = mapName:lower()
    if mapNameLower:find("cave") and mapNameLower:find("chaos") then
        for _, route in ipairs(allRoutes) do
            if route.name:lower() == TAS_SelectedCaveChaos:lower() then return route.info end
        end
        if listfiles then
            for _, path in ipairs(listfiles("TAS_Recorder")) do
                local fileName = path:match("([^/\]+)$") or path
                local baseName = fileName:gsub("%.json$", "")
                if baseName:lower() == TAS_SelectedCaveChaos:lower() then return path end
            end
        end
    elseif mapNameLower:find("unstable") and mapNameLower:find("savannah") then
        for _, route in ipairs(allRoutes) do
            if route.name:lower() == TAS_SelectedUnstableSavannah:lower() then return route.info end
        end
        if listfiles then
            for _, path in ipairs(listfiles("TAS_Recorder")) do
                local fileName = path:match("([^/\]+)$") or path
                local baseName = fileName:gsub("%.json$", "")
                if baseName:lower() == TAS_SelectedUnstableSavannah:lower() then return path end
            end
        end
    end
    return bestCandidate.path
end

local function TAS_AutoRunCurrentMap()
    local file = TAS_GetMapTasFile()
    if not file then
        for i = 1, 10 do
            task.wait(0.2)
            file = TAS_GetMapTasFile()
            if file then break end
        end
    end
    if not file then return end
    local data = TAS_LoadFromSource(file)
    if not data then return end
    TAS_ActivePathfindId = TAS_ActivePathfindId + 1
    TAS_StopPlayback()
    local Hum = TAS_LocalPlayer.Character and TAS_LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if Hum and Hum.WalkSpeed == 0 then
        local Character = TAS_LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local currentPos = Character.HumanoidRootPart.Position
            local syncIndex, path, syncPos = TAS_ComputePathToSync(data, currentPos, true)
            while Hum and Hum.WalkSpeed == 0 do task.wait(0.05) end
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then
                TAS_ViewPlayback(data, syncIndex)
                return
            end
            TAS_ExecutePathAndPlay(data, syncIndex, path, syncPos)
        else
            while Hum and Hum.WalkSpeed == 0 do task.wait(0.05) end
            if TAS_PathfindToStart then TAS_PathfindAndPlay(data) else TAS_ViewPlayback(data) end
        end
    else
        if TAS_PathfindToStart then TAS_PathfindAndPlay(data) else TAS_ViewPlayback(data) end
    end
end

local TAS_AutoplayEnabled = false
local function TAS_IsInChallenge()
    local challengePlayers = TAS_Workspace:FindFirstChild("ChallengePlayers")
    if not challengePlayers then return false end
    return challengePlayers:FindFirstChild(TAS_LocalPlayer.Name) ~= nil
end

local function TAS_RunAutoPlayWithPathfind()
    if not TAS_IsInChallenge() then return end
    local file = TAS_GetMapTasFile()
    if not file then
        for i = 1, 10 do
            task.wait(0.2)
            if not TAS_IsInChallenge() then return end
            file = TAS_GetMapTasFile()
            if file then break end
        end
    end
    if not file then return end
    local data = TAS_LoadFromSource(file)
    if not data then return end
    TAS_ActivePathfindId = TAS_ActivePathfindId + 1
    TAS_StopPlayback()
    local Hum = TAS_LocalPlayer.Character and TAS_LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if Hum and Hum.WalkSpeed == 0 then
        local Character = TAS_LocalPlayer.Character
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local currentPos = Character.HumanoidRootPart.Position
            local syncIndex, path, syncPos = TAS_ComputePathToSync(data, currentPos, true)
            if not (Hum and Hum.WalkSpeed >= 16) then
                while true do
                    if not TAS_IsInChallenge() then return end
                    Hum = TAS_LocalPlayer.Character and TAS_LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if Hum and Hum.WalkSpeed >= 16 then break end
                    task.wait(0.05)
                end
            end
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then
                TAS_ViewPlayback(data, syncIndex)
                return
            end
            TAS_ExecutePathAndPlay(data, syncIndex, path, syncPos)
        else
            if not (Hum and Hum.WalkSpeed >= 16) then
                while true do
                    if not TAS_IsInChallenge() then return end
                    Hum = TAS_LocalPlayer.Character and TAS_LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if Hum and Hum.WalkSpeed >= 16 then break end
                    task.wait(0.05)
                end
            end
            TAS_PathfindAndPlay(data)
        end
    else
        if not (Hum and Hum.WalkSpeed >= 16) then
            while true do
                if not TAS_IsInChallenge() then return end
                Hum = TAS_LocalPlayer.Character and TAS_LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if Hum and Hum.WalkSpeed >= 16 then break end
                task.wait(0.05)
            end
        end
        TAS_PathfindAndPlay(data)
    end
end

AutoPlayTab:CreateToggle({
   Name = "Autoplay",
   CurrentValue = false,
   Flag = "AutoplayToggle",
   Callback = function(Value)
       TAS_AutoplayEnabled = Value
       if Value then
           task.spawn(function()
                while TAS_AutoplayEnabled do
                   if TAS_IsInChallenge() then
                       local Hum = TAS_LocalPlayer.Character and TAS_LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                       if Hum and Hum.WalkSpeed == 0 then
                           TAS_RunAutoPlayWithPathfind()
                       end
                   end
                   task.wait(0.5)
                end
            end)
        end
    end,
 })

if isAdmin then
 AutoPlayTab:CreateToggle({
    Name = "Disable Shiftlock / Camera",
    CurrentValue = false,
    Flag = "DisableShiftlockCameraToggle",
    Callback = function(Value)
        TAS_DisableShiftlockAndCamera = Value
    end,
 })
end

 AutoPlayTab:CreateButton({
    Name = "Autoplay This Round",
    Callback = function()
        TAS_RunAutoPlayWithPathfind()
    end,
 })

AutoPlayTab:CreateDropdown({
   Name = "Cave Chaos",
   Options = {"Cave Chaos", "Cave Chaos Clip"},
   CurrentOption = "Cave Chaos",
   Flag = "CaveChaosDropdown",
   Callback = function(Option)
       if type(Option) == "table" then
           TAS_SelectedCaveChaos = Option[1] or Option.Option or "Cave Chaos"
       else
           TAS_SelectedCaveChaos = Option
       end
   end,
})

AutoPlayTab:CreateDropdown({
   Name = "Unstable Savannah",
   Options = {"Unstable Savannah", "Unstable Savannah Clip"},
   CurrentOption = "Unstable Savannah",
   Flag = "UnstableSavannahDropdown",
   Callback = function(Option)
       if type(Option) == "table" then
           TAS_SelectedUnstableSavannah = Option[1] or Option.Option or "Unstable Savannah"
       else
           TAS_SelectedUnstableSavannah = Option
       end
   end,
})

local autoWinObby = false
local voteConn = nil
local juryVoteConns = nil
local printVotesConn = nil
local exposeVotesConn = nil
local playerHighlight = nil
local rainbowNameConn = nil
local function grabStatue(v)
    v.hit.CanCollide = false
    v.hit.Transparency = 1
    wait()
    v.hit.Position = player.Character.Torso.Position
end
OtherTab:CreateSection("Theme")
OtherTab:CreateDropdown({
    Name = "UI Theme",
    Options = {"Default", "AmberGlow", "Amethyst", "Bloom", "DarkBlue", "Green", "Light", "Ocean", "Serenity"},
    CurrentOption = {"DarkBlue"},
    MultipleOptions = false,
    Flag = "ThemeDropdown",
    Callback = function(option)
        Window.ModifyTheme(option[1])
        saveTheme(option[1])
    end,
})
OtherTab:CreateSection("Visuals")
OtherTab:CreateToggle({
    Name = "Show All Usernames",
    CurrentValue = false,
    Flag = "ShowUsernames",
    Callback = function(Value)
        if Value == true then
            loadstring(game:HttpGet("https://pastefy.app/O42FgG2q/raw"))()
        elseif Value == false then
            loadstring(game:HttpGet("https://pastefy.app/BmaxmIzK/raw"))()
        end
    end,
})
OtherTab:CreateButton({
    Name = "Get All Skins",
    Callback = function()
        local _rs = game:GetService("ReplicatedStorage")
        local _lp = game:GetService("Players").LocalPlayer
        local _DataStore = _lp:WaitForChild("DataStore")
        for _, _category in ipairs(_rs.Products.Shop.Items:GetChildren()) do
            for _, _item in ipairs(_DataStore[_category.Name]:GetChildren()) do
                _item:Destroy()
            end
            for _, _item in ipairs(_category:GetChildren()) do
                _item:Clone().Parent = _DataStore[_category.Name]
            end
        end
    end,
})
OtherTab:CreateButton({
    Name = "Halloween Map",
    Callback = function()
        loadstring(game:HttpGet('https://pastebin.com/raw/nVKRChaK'))()
    end,
})
if isCamp then
    OtherTab:CreateButton({
        Name = "Christmas Map",
        Callback = function()
            loadstring(game:HttpGet('https://pastebin.com/raw/ju6mhwzn'))()
        end,
    })
    OtherTab:CreateButton({
        Name = "Valentines Map",
        Callback = function()
            local winterColor = Color3.fromRGB(255, 152, 220)
            local greenColor = Color3.fromRGB(148, 190, 129)
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local bcName = obj.BrickColor.Name:lower()
                    if bcName == "olivine" or bcName:find("green") then
                        obj.Color = greenColor
                        obj.Material = Enum.Material.SmoothPlastic
                    end
                end
                if obj:IsA("MeshPart") and obj.Name == "Leaves" then
                    obj.Color = winterColor
                    obj.Material = Enum.Material.SmoothPlastic
                end
            end
            local bgMountains = workspace.Map["Roblox Drama: Camp"].Map.Mountains["Background Mountains"]
            for _, v in pairs(bgMountains:GetDescendants()) do
                if v:IsA("MeshPart") and v.Name == "MeshPart" then
                    if v.BrickColor == BrickColor.new("Grime") then
                        v.Color = winterColor
                        v.Material = Enum.Material.SmoothPlastic
                    end
                end
                if v:IsA("MeshPart") and v.Name == "Water" then
                    if v.BrickColor == BrickColor.new("Bright bluish green") then
                        v.Color = winterColor
                        v.Material = Enum.Material.Glass
                    end
                end
            end
            local lakeWater = workspace.Map["Roblox Drama: Camp"].Map.Lake:FindFirstChild("Water")
            if lakeWater and lakeWater:IsA("MeshPart") then
                lakeWater.Color = winterColor
                lakeWater.Material = Enum.Material.Glass
            end
        end,
    })
end
OtherTab:CreateSection("Utilities")
OtherTab:CreateButton({
    Name = "FE Genesis Sniper",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/GenesisFE/Genesis/main/Obfuscations/Sniper"))()
    end,
})
OtherTab:CreateButton({
    Name = "Confessional Changer",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Total-Roblox-Drama-CONFESSIONAL-CHANGER-W-FONTS-51365"))()
    end,
})
OtherTab:CreateButton({
    Name = "Auto Reset Finale",
    Callback = function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        autoWinObby = true
        task.spawn(function()
            while autoWinObby do
                local assets = workspace:FindFirstChild("Assets")
                if assets then
                    local finish = assets:FindFirstChild("Finish", true)
                    if finish then
                        finish.CanCollide = false
                        finish.Transparency = 1
                        task.wait()
                        finish.Position = player.Character.HumanoidRootPart.Position
                    end
                end
                task.wait(0.1)
            end
        end)
        local DataStore = LocalPlayer:WaitForChild("DataStore")
        local winsValue = isCamp and "CampWins" or isExpedition and "ExpeditionWins" or "MoviesWins"
        local CampWins = DataStore:WaitForChild(winsValue)
        print("Watching " .. winsValue .. ": " .. tostring(CampWins.Value))
        CampWins.Changed:Connect(function(newValue)
            print("Challenge won! Executing script...")
            loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxcheatck/reanimatescript/main/script.lua", true))()
            task.wait(25)
            print("Stopping reanimate...")
            if Stop then Stop() end
        end)
        Rayfield:Notify({
            Title = "Auto Reset Finale",
            Content = "Auto Reset Finale Enabled!",
            Duration = 4,
            Image = "bell-ring",
        })
    end,
})
OtherTab:CreateSection("Configuration")
local _dwConfigList = DW_ListConfigs()
local _dwConfigName = (_dwConfigList[1] ~= "(no saved configs)") and _dwConfigList[1] or "Default"
local _dwNewConfigName = "Default"
local _dwConfigDropdown = OtherTab:CreateDropdown({
    Name = "Saved Configs",
    Options = _dwConfigList,
    CurrentOption = {_dwConfigList[1]},
    MultipleOptions = false,
    Flag = "DWConfigDropdown",
    Callback = function(Options)
        if Options[1] and Options[1] ~= "(no saved configs)" then
            _dwConfigName = Options[1]
        end
    end,
})
OtherTab:CreateButton({
    Name = "Refresh Config List",
    Callback = function()
        local newList = DW_ListConfigs()
        _dwConfigDropdown:Refresh(newList)
        if newList[1] ~= "(no saved configs)" then _dwConfigName = newList[1] end
        Rayfield:Notify({
            Title = "Config List Refreshed",
            Content = "Found " .. #newList .. " saved config(s).",
            Duration = 3,
            Image = "refresh-cw",
        })
    end,
})
OtherTab:CreateButton({
    Name = "Load Selected Config",
    Callback = function()
        if not _dwConfigName or _dwConfigName == "" or _dwConfigName == "(no saved configs)" then
            Rayfield:Notify({ Title = "Nothing Selected", Content = "Pick a config from the dropdown first.", Duration = 4, Image = "alert-circle" })
            return
        end
        local ok = DW_LoadConfig(_dwConfigName)
        if ok then
            Rayfield:Notify({ Title = "Config Loaded", Content = 'Loaded "' .. _dwConfigName .. '".', Duration = 4, Image = "refresh-cw" })
        else
            Rayfield:Notify({ Title = "Config Not Found", Content = '"' .. _dwConfigName .. '" doesn\'t exist.', Duration = 4, Image = "alert-circle" })
        end
    end,
})
OtherTab:CreateButton({
    Name = "Set Selected as Auto-Load",
    Callback = function()
        if not _dwConfigName or _dwConfigName == "" or _dwConfigName == "(no saved configs)" then
            Rayfield:Notify({ Title = "Nothing Selected", Content = "Pick a config from the dropdown first.", Duration = 4, Image = "alert-circle" })
            return
        end
        DW_SetAutoLoad(_dwConfigName)
        Rayfield:Notify({ Title = "Auto-Load Set", Content = '"' .. _dwConfigName .. '" will auto-load on execute.', Duration = 5, Image = "star" })
    end,
})
OtherTab:CreateButton({
    Name = "Delete Selected Config",
    Callback = function()
        if not _dwConfigName or _dwConfigName == "" or _dwConfigName == "(no saved configs)" then
            Rayfield:Notify({ Title = "Nothing Selected", Content = "Pick a config from the dropdown first.", Duration = 4, Image = "alert-circle" })
            return
        end
        local path = "DramaWare/Configs/" .. _dwConfigName .. ".json"
        local deleted = false
        pcall(function()
            if isfile(path) then delfile(path) deleted = true end
        end)
        if deleted then
            Rayfield:Notify({ Title = "Config Deleted", Content = '"' .. _dwConfigName .. '" deleted.', Duration = 4, Image = "trash-2" })
            local newList = DW_ListConfigs()
            _dwConfigDropdown:Refresh(newList)
            _dwConfigName = (newList[1] ~= "(no saved configs)") and newList[1] or "Default"
        else
            Rayfield:Notify({ Title = "Not Found", Content = 'No config named "' .. _dwConfigName .. '".', Duration = 4, Image = "alert-circle" })
        end
    end,
})
OtherTab:CreateButton({
    Name = "Clear Auto-Load",
    Callback = function()
        DW_SetAutoLoad("")
        Rayfield:Notify({ Title = "Auto-Load Cleared", Content = "Nothing will auto-load on execute.", Duration = 4, Image = "x-circle" })
    end,
})
OtherTab:CreateSection("Save New Config")
OtherTab:CreateInput({
    Name = "New Config Name",
    PlaceholderText = "e.g. Default, PvP, AFK...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        if text and text ~= "" then _dwNewConfigName = text end
    end,
})
OtherTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        if not _dwNewConfigName or _dwNewConfigName == "" then
            Rayfield:Notify({ Title = "No Name", Content = "Enter a config name in the input above.", Duration = 4, Image = "alert-circle" })
            return
        end
        DW_SaveConfig(_dwNewConfigName)
        Rayfield:Notify({ Title = "Config Saved", Content = 'Saved as "' .. _dwNewConfigName .. '".', Duration = 4, Image = "save" })
        local newList = DW_ListConfigs()
        _dwConfigDropdown:Refresh(newList)
        _dwConfigName = _dwNewConfigName
    end,
})
MainTab:CreateSection("Statue")
MainTab:CreateButton({
    Name = "Get Safety Statue",
    Callback = function()
        for i, v in pairs(workspace.Idols:GetDescendants()) do
            if v.Name == "Bag" then
                v.hit.CanCollide = false
                v.hit.Transparency = 1
                wait()
                v.hit.Position = player.Character.Torso.Position
                wait()
            elseif v.Name == "SafetyStatue" then
                v.hit.CanCollide = false
                v.hit.Transparency = 1
                wait()
                v.hit.Position = player.Character.Torso.Position
                wait()
            end
        end
    end,
})
MainTab:CreateButton({
    Name = "Get Statue When It Spawns",
    Callback = function()
        local function tryGrab(v)
            if v:IsA("BasePart") and v.Name == "hit" then
                local parent = v.Parent
                if parent and (parent.Name == "Bag" or parent.Name == "SafetyStatue") then
                    task.wait(0.1)
                    v.CanCollide = false
                    v.Transparency = 1
                    task.spawn(function()
                        while v and v.Parent do
                            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                                v.CFrame = player.Character.HumanoidRootPart.CFrame
                            end
                            task.wait(0.05)
                        end
                    end)
                end
            end
        end
        workspace.DescendantAdded:Connect(function(v)
            tryGrab(v)
        end)
        for _, v in pairs(workspace:GetDescendants()) do
            tryGrab(v)
        end
    end,
})
MainTab:CreateButton({
    Name = "Notify Who Has Statue",
    Callback = function()
        local v = game.ReplicatedStorage.Season.Twists.Idol
        if v.Value == "" then
            Rayfield:Notify({
                Title = "Statue Owner",
                Content = "No one currently has the statue or it didn't spawn.",
                Duration = 4,
                Image = "bell-ring",
            })
        else
            local c = game.ReplicatedStorage.Season.Players:FindFirstChild(v.Value).Value
            Rayfield:Notify({
                Title = "Statue Owner",
                Content = c .. " has the statue",
                Duration = 4,
                Image = "bell-ring",
            })
        end
    end,
})
MainTab:CreateSection("Round Info")
MainTab:CreateButton({
    Name = "Detect Round",
    Callback = function()
        local t = game.ReplicatedStorage.Season.Twists:FindFirstChild("CurrentTwist")
        if t.Value == "Undecided" then
            Rayfield:Notify({ Title = "Round Undecided", Content = "The round hasn't been decided yet. Please wait.", Duration = 4, Image = "bell-ring" })
        elseif t.Value == "normal" then
            Rayfield:Notify({ Title = "Normal Round", Content = "This will be a casual round. (Nothing special)", Duration = 4, Image = "bell-ring" })
        elseif t.Value == "purge" then
            Rayfield:Notify({ Title = "Purge Round", Content = "This will be a purge round.", Duration = 4, Image = "bell-ring" })
        elseif t.Value == "double" then
            Rayfield:Notify({ Title = "Double Elimination", Content = "Two people will be eliminated this round.", Duration = 4, Image = "bell-ring" })
        elseif t.Value == "singleswap" then
            Rayfield:Notify({ Title = "Sike Round", Content = "The player that will be eliminated this round will be transferred to another team.", Duration = 4, Image = "bell-ring" })
        elseif t.Value == "exile" then
            Rayfield:Notify({ Title = "Exile Vote Round", Content = "There will be an exile vote this round.", Duration = 4, Image = "bell-ring" })
        elseif t.Value == "votereveal" then
            Rayfield:Notify({ Title = "Vote Reveal", Content = "Kyle will expose/reveal the votes this round.", Duration = 6.5, Image = "bell-ring" })
        end
    end,
})
MainTab:CreateButton({
    Name = "Fling/Restart Day (Reanimate)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxcheatck/reanimatescript/main/script.lua", true))()
    end,
})
MainTab:CreateButton({
    Name = "Limb Reanimation",
    Callback = function()
        local settings = _G
        settings["Use default animations"] = true
        settings["Local character transparency level"] = 1
        settings["Disable character scripts"] = true
        settings["Fake character should collide"] = true
        settings["Parent real character to fake character"] = false
        settings["Respawn character"] = true
        settings["Instant respawn"] = false
        settings["Hide HumanoidRootPart"] = false
        settings["PermaDeath fake character"] = true
        settings["R15 Reanimate"] = false
        settings["Click Fling"] = false
        settings["Anti-Fling"] = true
        settings["Hide RootPart Distance"] = CFrame.new(255, 255, 0)
        settings["Allow tool equipping"] = false
        settings["Client sided display mode"] = 1
        settings["Fallback prompt"] = true
        settings["Respawn mode"] = "ServerBreakJoints"
        settings["Names to exclude from transparency"] = {}
        loadstring(game:HttpGet("https://raw.githubusercontent.com/somethingsimade/CurrentAngleV4/refs/heads/main/v4.lua"))()
    end,
})
local autoDetectRoundConn = nil
MainTab:CreateToggle({
    Name = "Auto Detect Round",
    CurrentValue = false,
    Flag = "AutoDetectRound",
    Callback = function(Value)
        if Value then
            local t = game.ReplicatedStorage.Season.Twists:FindFirstChild("CurrentTwist")
            autoDetectRoundConn = t:GetPropertyChangedSignal("Value"):Connect(function()
                local roundNames = {
                    normal = "Normal Round - Casual round, nothing special.",
                    purge = "Purge Round - This will be a purge round.",
                    ["double"] = "Double Elimination - Two people will be eliminated.",
                    singleswap = "Sike Round - Eliminated player gets swapped to another team.",
                    exile = "Exile Vote Round - There will be an exile vote.",
                    votereveal = "Vote Reveal - Kyle will expose the votes this round.",
                }
                local content = roundNames[t.Value]
                if content then
                    Rayfield:Notify({ Title = "Round Detected", Content = content, Duration = 6, Image = "bell-ring" })
                end
            end)
        else
            if autoDetectRoundConn then
                autoDetectRoundConn:Disconnect()
                autoDetectRoundConn = nil
            end
        end
    end,
})
MainTab:CreateButton({
    Name = "Detect Teamers",
    Callback = function()
        local Players = game:GetService("Players")
        local RS = game:GetService("ReplicatedStorage")
        local season = RS:FindFirstChild("Season")
        if not season then return end
        local playersFolder = season:FindFirstChild("Players")
        if not playersFolder then return end
        local function getInGameName(p)
            local data = playersFolder:FindFirstChild(p.Name)
            if data and data.Value ~= "" then
                return data.Value
            end
            return p.Name
        end
        local found = false
        for i, p1 in ipairs(Players:GetPlayers()) do
            for j, p2 in ipairs(Players:GetPlayers()) do
                if j > i then
                    local ok, areFriends = pcall(function()
                        return p1:IsFriendsWith(p2.UserId)
                    end)
                    if ok and areFriends then
                        local igName1 = getInGameName(p1)
                        local igName2 = getInGameName(p2)
                        found = true
                        Rayfield:Notify({
                            Title = "Teamer Detected!",
                            Content = igName1 .. " is teaming with " .. igName2,
                            Duration = 8,
                            Image = "shield-alert",
                        })
                        task.wait(0.6)
                    end
                end
            end
        end
        if not found then
            Rayfield:Notify({
                Title = "No Teamers Found",
                Content = "No friend pairs detected in this lobby.",
                Duration = 5,
                Image = "check-circle",
            })
        end
    end,
})
MainTab:CreateButton({
    Name = "Destroy Long Names",
    Callback = function()
        local function destroyLongTextElements(parent)
            for _, element in ipairs(parent:GetDescendants()) do
                if pcall(function() return element.Text end) and type(element.Text) == "string" and #element.Text > 750 then
                    element:Destroy()
                end
            end
        end
        local function scanGame()
            for _, service in ipairs(game:GetChildren()) do
                destroyLongTextElements(service)
            end
            destroyLongTextElements(game:GetService("Players").LocalPlayer.PlayerGui)
            destroyLongTextElements(game:GetService("ReplicatedStorage"))
            destroyLongTextElements(game:GetService("Workspace"))
        end
        scanGame()
        game.DescendantAdded:Connect(function(descendant)
            if pcall(function() return descendant.Text end) and type(descendant.Text) == "string" and #descendant.Text > 750 then
                descendant:Destroy()
            end
        end)
    end,
})
MainTab:CreateButton({
    Name = "Remove Cutscene",
    Callback = function()
        local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
        local camEvent = events and events:FindFirstChild("Camera")
        if camEvent then
            camEvent:Destroy()
        end
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                camera.CameraType = Enum.CameraType.Custom
                camera.CameraSubject = hum
            end
        end
    end,
})
MainTab:CreateSection("ESP")
MainTab:CreateToggle({
    Name = "Safety Bag ESP",
    CurrentValue = false,
    Flag = "SafetyBagESP",
    Callback = function(Value)
        if Value then
            for _, bag in ipairs(workspace.Idols:GetDescendants()) do
                if bag.Name == "Bag" and bag:IsA("Model") then
                    local part = bag.PrimaryPart or bag:FindFirstChildWhichIsA("BasePart")
                    if part then
                    if not bag:FindFirstChild("BagHighlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "BagHighlight"
                        highlight.FillTransparency = 1
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.Parent = bag
                    end
                    if not bag:FindFirstChild("BagESP") then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "BagESP"
                        billboard.Size = UDim2.new(0, 220, 0, 60)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Adornee = part
                        billboard.Parent = bag
                        local text = Instance.new("TextLabel")
                        text.Size = UDim2.new(1, 0, 1, 0)
                        text.BackgroundTransparency = 1
                        text.Text = "SAFETY BAG"
                        text.TextColor3 = Color3.fromRGB(255, 255, 255)
                        text.TextStrokeTransparency = 0
                        text.TextScaled = true
                        text.Font = Enum.Font.GothamBold
                        text.Parent = billboard
                    end
                    end
                end
            end
        else
            for _, bag in ipairs(workspace:GetDescendants()) do
                if bag.Name == "Bag" then
                    if bag:FindFirstChild("BagHighlight") then bag.BagHighlight:Destroy() end
                    if bag:FindFirstChild("BagESP") then bag.BagESP:Destroy() end
                end
            end
        end
    end,
})
MainTab:CreateToggle({
    Name = "Safety Statue ESP",
    CurrentValue = false,
    Flag = "SafetyStatueESP",
    Callback = function(Value)
        if Value then
            for _, statue in ipairs(workspace.Idols:GetDescendants()) do
                if statue.Name == "SafetyStatue" and statue:IsA("Model") then
                    local part = statue.PrimaryPart or statue:FindFirstChildWhichIsA("BasePart")
                    if part then
                    if not statue:FindFirstChild("StatueHighlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "StatueHighlight"
                        highlight.FillTransparency = 1
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.Parent = statue
                    end
                    if not statue:FindFirstChild("StatueESP") then
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "StatueESP"
                        billboard.Size = UDim2.new(0, 260, 0, 70)
                        billboard.StudsOffset = Vector3.new(0, 4, 0)
                        billboard.AlwaysOnTop = true
                        billboard.Adornee = part
                        billboard.Parent = statue
                        local text = Instance.new("TextLabel")
                        text.Size = UDim2.new(1, 0, 1, 0)
                        text.BackgroundTransparency = 1
                        text.Text = "SAFETY STATUE"
                        text.TextColor3 = Color3.fromRGB(255, 255, 255)
                        text.TextStrokeTransparency = 0
                        text.TextScaled = true
                        text.Font = Enum.Font.GothamBold
                        text.Parent = billboard
                    end
                    end
                end
            end
        else
            for _, statue in ipairs(workspace:GetDescendants()) do
                if statue.Name == "SafetyStatue" then
                    if statue:FindFirstChild("StatueHighlight") then statue.StatueHighlight:Destroy() end
                    if statue:FindFirstChild("StatueESP") then statue.StatueESP:Destroy() end
                end
            end
        end
    end,
})
MainTab:CreateSection("Voting")
MainTab:CreateToggle({
    Name = "Notify Votes",
    CurrentValue = false,
    Flag = "NotifyVotes",
    Callback = function(Value)
        if Value then
            voteConn = game.ReplicatedStorage.Season.Voting.Votes.ChildAdded:Connect(function(v)
                local r = game.ReplicatedStorage.Season.Players[v.Value].Value
                local d = game.ReplicatedStorage.Season.Players[v.Name].Value
                Rayfield:Notify({ Title = "Vote Update", Content = r .. " voted for " .. d, Duration = 3, Image = "bell-ring" })
            end)
        else
            if voteConn then voteConn:Disconnect() voteConn = nil end
        end
    end,
})
MainTab:CreateToggle({
    Name = "Print Votes in /console",
    CurrentValue = false,
    Flag = "PrintVotes",
    Callback = function(Value)
        if Value then
            printVotesConn = game.ReplicatedStorage.Season.Voting.Votes.ChildAdded:Connect(function(v)
                local r = game.ReplicatedStorage.Season.Players[v.Value].Value
                local d = game.ReplicatedStorage.Season.Players[v.Name].Value
                print(r .. " voted for " .. d)
            end)
        else
            if printVotesConn then printVotesConn:Disconnect() printVotesConn = nil end
        end
    end,
})
MainTab:CreateToggle({
    Name = "Expose Votes",
    CurrentValue = false,
    Flag = "ExposeVotes",
    Callback = function(Value)
        if Value then
            exposeVotesConn = game.ReplicatedStorage.Season.Voting.Votes.ChildAdded:Connect(function(v)
                local r = game.ReplicatedStorage.Season.Players[v.Value].Value
                local d = game.ReplicatedStorage.Season.Players[v.Name].Value
                game.TextChatService.TextChannels.RBXGeneral:SendAsync(r .. " voted for " .. d)
            end)
        else
            if exposeVotesConn then exposeVotesConn:Disconnect() exposeVotesConn = nil end
        end
    end,
})
MainTab:CreateToggle({
    Name = "Notify Jury Votes",
    CurrentValue = false,
    Flag = "NotifyJuryVotes",
    Callback = function(Value)
        if Value then
            juryVoteConns = {}
            local function watchJuror(j)
                local l = j:WaitForChild("List")
                local conn = l.ChildAdded:Connect(function(v)
                    local voter = j.Value
                    local votee = v.Value
                    if game.ReplicatedStorage.Season.Players:FindFirstChild(v.Name) then
                        votee = game.ReplicatedStorage.Season.Players[v.Name].Value
                    end
                    Rayfield:Notify({ Title = "Jury Vote", Content = voter .. " voted for " .. votee, Duration = 3, Image = "bell-ring" })
                end)
                table.insert(juryVoteConns, conn)
            end
            for _, j in pairs(game.ReplicatedStorage.Season.Jury:GetChildren()) do
                watchJuror(j)
            end
            local addConn = game.ReplicatedStorage.Season.Jury.ChildAdded:Connect(watchJuror)
            table.insert(juryVoteConns, addConn)
        else
            if juryVoteConns then
                for _, c in pairs(juryVoteConns) do c:Disconnect() end
                juryVoteConns = nil
            end
        end
    end,
})
PlayerTab:CreateSection("Movement")
PlayerTab:CreateSlider({
    Name = "Walkspeed",
    Range = {1, 350},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        workspace[player.Name].Humanoid.WalkSpeed = Value
    end,
})
PlayerTab:CreateSlider({
    Name = "Jump Power",
    Range = {1, 350},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        workspace[player.Name].Humanoid.JumpPower = Value
    end,
})
PlayerTab:CreateSlider({
    Name = "Field of View",
    Range = {30, 120},
    Increment = 1,
    Suffix = "FOV",
    CurrentValue = 70,
    Flag = "FieldOfView",
    Callback = function(Value)
        workspace.CurrentCamera.FieldOfView = Value
    end,
})
if isCamp then
PlayerTab:CreateToggle({
    Name = "Walk on Water",
    CurrentValue = false,
    Flag = "WalkOnWater",
    Callback = function(Value)
        workspace.Map["Roblox Drama: Camp"].Map.Lake.Water.CanCollide = Value
    end,
})
PlayerTab:CreateButton({
    Name = "Lake God-Mode",
    Callback = function()
        pcall(function()
            workspace.Map["Roblox Drama: Camp"].Sand.TouchInterest:Destroy()
        end)
    end,
})
end
PlayerTab:CreateButton({
    Name = "Remove Barriers",
    Callback = function()
        for i, v in pairs(workspace:GetDescendants()) do
            if v.Name == "Glass" or v.Name == "ChallengeGlass" or v.Name == "AwardCeremony" or v.Name == "Drop-Off" then
                v:Destroy()
            end
        end
    end,
})
PlayerTab:CreateSection("Player Actions")
PlayerTab:CreateInput({
    Name = "Custom Coins (CLIENT)",
    CurrentValue = "",
    PlaceholderText = "Numbers only...",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomCoins",
    Callback = function(Text)
        game.Players.LocalPlayer.DataStore.Coins.Value = Text
    end,
})
PlayerTab:CreateInput({
    Name = "Custom Camp Wins (CLIENT)",
    CurrentValue = "",
    PlaceholderText = "Numbers only...",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomCampWins",
    Callback = function(Text)
        game.Players.LocalPlayer.DataStore.CampWins.Value = Text
    end,
})
PlayerTab:CreateInput({
    Name = "Custom Movies Wins (CLIENT)",
    CurrentValue = "",
    PlaceholderText = "Numbers only...",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomMoviesWins",
    Callback = function(Text)
        game.Players.LocalPlayer.DataStore.MoviesWins.Value = Text
    end,
})
PlayerTab:CreateInput({
    Name = "Custom Expedition Wins (CLIENT)",
    CurrentValue = "",
    PlaceholderText = "Numbers only...",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomExpeditionWins",
    Callback = function(Text)
        game.Players.LocalPlayer.DataStore.ExpeditionWins.Value = Text
    end,
})
PlayerTab:CreateInput({
    Name = "Custom Official Wins (CLIENT)",
    CurrentValue = "",
    PlaceholderText = "Numbers only...",
    RemoveTextAfterFocusLost = false,
    Flag = "CustomOfficialWins",
    Callback = function(Text)
        game.Players.LocalPlayer.DataStore.OfficialWins.Value = Text
    end,
})
PlayerTab:CreateButton({
    Name = "Fake #1 Leaderboard (CLIENT)",
    Callback = function()
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=48&height=48&format=png"
        local scrollFrame = workspace.WinLeaderboard.SurfaceGui.ScrollingFrame
        for _, frame in pairs(scrollFrame:GetChildren()) do
            if frame:IsA("Frame") then
                local placeLabel = frame:FindFirstChild("Image") and frame.Image:FindFirstChild("Place")
                if placeLabel and placeLabel.Text == "1" then
                    frame.PName.Text = player.Name
                    frame.Image.Image = avatarUrl
                    break
                end
            end
        end
    end,
})
local stat = ""
local list = {}
pcall(function()
    for _, v in ipairs(game.ReplicatedStorage.Season.Players:GetChildren()) do
        if v.Name ~= player.Name then
            table.insert(list, v.Value)
        end
    end
end)
PlayerTab:CreateSection("Target Player")
local Dropdownoo = PlayerTab:CreateDropdown({
    Name = "Choose Player",
    Options = list,
    CurrentOption = {list[1]},
    MultipleOptions = false,
    Flag = "ChoosePlayer",
    Callback = function(Options)
        stat = Options[1]
    end,
})
PlayerTab:CreateButton({
    Name = "Refresh List",
    Callback = function()
        local nlist = {}
        for _, v in ipairs(game.ReplicatedStorage:WaitForChild("Season"):WaitForChild("Players"):GetChildren()) do
            if v:IsA("ValueBase") and v.Name ~= player.Name then
                table.insert(nlist, tostring(v.Value))
            end
        end
        Dropdownoo:Refresh(nlist)
        if #nlist > 0 then
            Dropdownoo:Set({nlist[1]})
        end
    end,
})
PlayerTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        for i, v in ipairs(game.ReplicatedStorage.Season.Players:GetChildren()) do
            if v.Value == stat then
                player.Character.HumanoidRootPart.CFrame = game.Players:FindFirstChild(v.Name).Character.HumanoidRootPart.CFrame
                break
            end
        end
    end,
})
PlayerTab:CreateToggle({
    Name = "Highlight Player",
    CurrentValue = false,
    Flag = "HighlightPlayer",
    Callback = function(Value)
        for _, v in ipairs(game.ReplicatedStorage.Season.Players:GetChildren()) do
            if v.Value == stat then
                local targetPlayer = game.Players:FindFirstChild(v.Name)
                if not targetPlayer or not targetPlayer.Character then return end
                if Value then
                    if playerHighlight then playerHighlight:Destroy() end
                    playerHighlight = Instance.new("Highlight")
                    playerHighlight.FillColor = Color3.fromRGB(255, 221, 0)
                    playerHighlight.OutlineColor = Color3.fromRGB(255, 221, 0)
                    playerHighlight.FillTransparency = 0.5
                    playerHighlight.OutlineTransparency = 0
                    playerHighlight.Parent = targetPlayer.Character
                else
                    if playerHighlight then
                        playerHighlight:Destroy()
                        playerHighlight = nil
                    end
                end
                break
            end
        end
    end,
})
PlayerTab:CreateSection("Misc")
PlayerTab:CreateButton({
    Name = "Player Collision (CLIENT)",
    Callback = function()
        LP = game.Players.LocalPlayer
        for i,v in pairs(game.Players:GetDescendants()) do
            if v:IsA("Player") and workspace:FindFirstChild(v.Name) and v ~= LP and workspace[v.Name]:FindFirstChild("CHECKER") == nil then
                local checker = Instance.new("BoolValue", workspace[v.Name])
                checker.Name = "CHECKER"
                for i,v in pairs(workspace:WaitForChild(v.Name):GetDescendants()) do
                    if v:IsA("Part") or v:IsA("MeshPart") then
                        local collider = Instance.new("Part", v)
                        collider.Size = v.Size
                        collider.Position = v.Position
                        collider.Transparency = 1
                        local weld = Instance.new("Weld", v)
                        weld.Part0 = v
                        weld.Part1 = collider
                    end
                end
            end
        end
    end,
})
CharactersTab:CreateSection("FREE")
CharactersTab:CreateButton({
    Name = "Male Character",
    Callback = function()
        game:GetService("ReplicatedStorage").Events.Buy:FireServer("Gender", "Male")
    end,
})
CharactersTab:CreateButton({
    Name = "Female Character",
    Callback = function()
        game:GetService("ReplicatedStorage").Events.Buy:FireServer("Gender", "Female")
    end,
})
CharactersTab:CreateSection("PAID")
CharactersTab:CreateButton({
    Name = "Crash Server",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/shsicidjdhisjs/crash-server/main/crash"))()
    end,
})
local ArtCharMap = {
    ["Swastika"] = [[
    ████╗░░░████████████╗
    ████║░░░████████████║
    ████║░░░████╔═══════╝
    ████║░░░████║░░░░░░░░
    ████████████████████╗
    ████████████████████║
    ╚═══════████╔═══████║
    ░░░░░░░░████║░░░████║
    ████████████║░░░████║
    ████████████║░░░████║
    ╚═══════════╝░░░╚═══╝
    ]],
    ["Skull"] = [[
    ███████████████████████████
    ███████▀▀▀░░░░░░░▀▀▀███████
    ████▀░░░░░░░░░░░░░░░░░▀████
    ███│░░░░░░░░░░░░░░░░░░░│███
    ██▌│░░░░░░░░░░░░░░░░░░░│▐██
    ██░└┐░░░░░░░░░░░░░░░░░┌┘░██
    ██░░└┐░░░░░░░░░░░░░░░┌┘░░██
    ██░░┌┘▄▄▄▄▄░░░░░▄▄▄▄▄└┐░░██
    ██▌░│██████▌░░░▐██████│░▐██
    ███░│▐███▀▀░░▄░░▀▀███▌│░███
    ██▀─┘░░░░░░░▐█▌░░░░░░░└─▀██
    ██▄░░░▄▄▄▓░░▀█▀░░▓▄▄▄░░░▄██
    ████▄─┘██▌░░░░░░░▐██└─▄████
    █████░░▐█─┬┬┬┬┬┬┬─█▌░░█████
    ████▌░░░▀┬┼┼┼┼┼┼┼┬▀░░░▐████
    █████▄░░░└┴┴┴┴┴┴┴┘░░░▄█████
    ███████▄░░░░░░░░░░░▄███████
    ██████████▄▄▄▄▄▄▄██████████
    ███████████████████████████
    ]],
    ["Guy"] = [[
    ───────▄▀▀▀▀▀▀▀▀▀▀▄▄
    ────▄▀▀░░░░░░░░░░░░░▀▄
    ──▄▀░░░░░░░░░░░░░░░░░░▀▄
    ──█░░░░░░░░░░░░░░░░░░░░░▀▄
    ─▐▌░░░░░░░░▄▄▄▄▄▄▄░░░░░░░▐▌
    ─█░░░░░░░░░░░▄▄▄▄░░▀▀▀▀▀░░█
    ▐▌░░░░░░░▀▀▀▀░░░░░▀▀▀▀▀░░░▐▌
    █░░░░░░░░░▄▄▀▀▀▀▀░░░░▀▀▀▀▄░█
    █░░░░░░░░░░░░░░░░▀░░░▐░░░░░▐▌
    ▐▌░░░░░░░░░▐▀▀██▄░░░░░░▄▄▄░▐▌
    ─█░░░░░░░░░░░▀▀▀░░░░░░▀▀██░░█
    ─▐▌░░░░▄░░░░░░░░░░░░░▌░░░░░░█
    ──▐▌░░▐░░░░░░░░░░░░░░▀▄░░░░░█
    ───█░░░▌░░░░░░░░▐▀░░░░▄▀░░░▐▌
    ───▐▌░░▀▄░░░░░░░░▀░▀░▀▀░░░▄▀
    ───▐▌░░▐▀▄░░░░░░░░░░░░░░░░█
    ───▐▌░░░▌░▀▄░░░░▀▀▀▀▀▀░░░█
    ───█░░░▀░░░░▀▄░░░░░░░░░░▄▀
    ──▐▌░░░░░░░░░░▀▄░░░░░░▄▀
    ─▄▀░░░▄▀░░░░░░░░▀▀▀▀█▀
    ▀░░░▄▀░░░░░░░░░░▀░░░▀▀▀▀▄▄▄▄▄
    ]],
    ["Hacker"] = [[
    ███████████████████████████████
    ████╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬████
    ██╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬██
    █╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█
    █╬╬╬███████╬╬╬╬╬╬╬╬╬███████╬╬╬█
    █╬╬██╬╬╬╬███╬╬╬╬╬╬╬███╬╬╬╬██╬╬█
    █╬██╬╬╬╬╬╬╬██╬╬╬╬╬██╬╬╬╬╬╬╬██╬█
    █╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█
    █╬╬╬╬█████╬╬╬╬╬╬╬╬╬╬╬█████╬╬╬╬█
    █╬╬█████████╬╬╬╬╬╬╬█████████╬╬█
    █╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬█
    █╬╬╬╬╬╬╬╬╬╬╬╬╬╬█╬╬╬╬╬╬╬╬╬╬╬╬╬╬█
    █╬╬╬╬╬╬╬╬╬╬╬╬╬╬█╬╬╬╬╬╬╬╬╬╬╬╬╬╬█
    █╬╬╬╬╬╬╬╬╬╬╬╬╬╬█╬╬╬╬╬╬╬╬╬╬╬╬╬╬█
    █╬╬╬▓▓▓▓╬╬╬╬╬╬╬█╬╬╬╬╬╬╬▓▓▓▓╬╬╬█
    █╬╬▓▓▓▓▓▓╬╬█╬╬╬█╬╬╬█╬╬▓▓▓▓▓▓╬╬█
    █╬╬╬▓▓▓▓╬╬██╬╬╬█╬╬╬██╬╬▓▓▓▓╬╬╬█
    █╬╬╬╬╬╬╬╬██╬╬╬╬█╬╬╬╬██╬╬╬╬╬╬╬╬█
    █╬╬╬╬╬████╬╬╬╬███╬╬╬╬████╬╬╬╬╬█
    █╬╬╬╬╬╬╬╬╬╬╬╬╬███╬╬╬╬╬╬╬╬╬╬╬╬╬█
    ██╬╬█╬╬╬╬╬╬╬╬█████╬╬╬╬╬╬╬╬█╬╬██
    ██╬╬██╬╬╬╬╬╬███████╬╬╬╬╬╬██╬╬██
    ██╬╬▓███╬╬╬████╬████╬╬╬███▓╬╬██
    ███╬╬▓▓███████╬╬╬███████▓▓╬╬███
    ███╬╬╬╬▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬███
    ████╬╬╬╬╬╬╬╬╬╬███╬╬╬╬╬╬╬╬╬╬████
    █████╬╬╬╬╬╬╬╬╬╬█╬╬╬╬╬╬╬╬╬╬█████
    ██████╬╬╬╬╬╬╬╬███╬╬╬╬╬╬╬╬██████
    ███████╬╬╬╬╬╬╬███╬╬╬╬╬╬╬███████
    ████████╬╬╬╬╬╬███╬╬╬╬╬╬████████
    █████████╬╬╬╬╬███╬╬╬╬╬█████████
    ███████████╬╬╬╬█╬╬╬╬███████████
    ███████████████████████████████
    ]],
    ["Middle Finger"] = [[
    ________________$$$$$
    ______________$$____$$
    ______________$$____$$
    ______________$$____$$
    ______________$$____$$
    ______________$$____$$
    __________$$$$$$____$$$$$$
    ________$$____$$____$$____$$$$
    ________$$____$$____$$____$$__$$
    $$$$$$__$$____$$____$$____$$____$$
    $$____$$$$________________$$____$$
    $$______$$______________________$$
    __$$____$$______________________$$
    ___$$$__$$______________________$$
    ____$$__________________________$$
    _____$$$________________________$$
    ______$$______________________$$$
    _______$$$____________________$$
    ________$$____________________$$
    _________$$$________________$$$
    __________$$________________$$
    __________$$$$$$$$$$$$$$$$$$$$
    ]],
}
local selectedArtChar = "Swastika"
CharactersTab:CreateDropdown({
    Name = "ASCII Art Character Names",
    Options = { "Swastika", "Skull", "Guy", "Hacker", "Middle Finger" },
    CurrentOption = {"Swastika"},
    MultipleOptions = false,
    Flag = "ArtCharDropdown",
    Callback = function(Options)
        selectedArtChar = Options[1]
    end,
})
CharactersTab:CreateButton({
    Name = "Buy Symbol Character (@60)",
    Callback = function()
        game:GetService("ReplicatedStorage").Events.Buy:FireServer("Character", ArtCharMap[selectedArtChar])
    end,
})
local selectedSymbol = ""
local characterName = ""
local symbolMap = {
    ["Nothing"] = "",
    [" Verified"] = "\u{e000}",
    [" Premium"] = "\u{e001}",
    [" Robux"] = "\u{e002}",
}
CharactersTab:CreateDropdown({
    Name = "Select a Symbol for Buy Character",
    Options = { "Nothing", " Verified", " Premium", " Robux" },
    CurrentOption = {"Nothing"},
    MultipleOptions = false,
    Flag = "SymbolDropdown",
    Callback = function(Options)
        selectedSymbol = symbolMap[Options[1]] or ""
    end,
})
CharactersTab:CreateInput({
    Name = "Enter the Character Name You Want",
    CurrentValue = "",
    PlaceholderText = "Character Name Here...",
    RemoveTextAfterFocusLost = false,
    Flag = "CharacterNameInput",
    Callback = function(Text)
        characterName = Text
    end,
})
CharactersTab:CreateButton({
    Name = "Buy Character (@60)",
    Callback = function()
        if characterName == "" then return end
        local finalText = characterName
        if selectedSymbol ~= "" then
            finalText = characterName .. " " .. selectedSymbol
        end
        game:GetService("ReplicatedStorage").Events.Buy:FireServer("Character", finalText)
    end,
})
_G.SelectedFont = nil
_G.StaticColor = Color3.fromRGB(255, 182, 193)
_G.StaticColorCustom = false
_G.RainbowMode = false
_G.RainbowSpeed = 0.5
_G.CustomName = ""
_G.UseCustomName = false
CharactersTab:CreateSection("Appearance (CLIENT)")
CharactersTab:CreateButton({
    Name = "Skin Select by kobi (CLIENT)",
    Callback = function()
        loadstring([=[
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CSRoot = game:GetService("ReplicatedStorage").Products.CharacterSelection.Characters
local marshmallowData = {
    ["Marshmallow"] = "http://www.roblox.com/asset/?id=4921967564",
    ["Mr.Coconut Marshmallow"] = "http://www.roblox.com/asset/?id=4993225404",
    ["Cook Surprise Marshmallow"] = "http://www.roblox.com/asset/?id=4993211976",
    ["Soda Marshmallow"] = "http://www.roblox.com/asset/?id=13424792834",
    ["Dino Marshmallow"] = "http://www.roblox.com/asset/?id=13424788699",
    ["Official 3-4 Marshmallow"] = "http://www.roblox.com/asset/?id=9005433388",
    ["Furious Trout Marshmallow"] = "http://www.roblox.com/asset/?id=13557360275",
    ["Orange Marshmallow"] = "http://www.roblox.com/asset/?id=4993231360",
    ["Cabbage Marshmallow"] = "http://www.roblox.com/asset/?id=13424785412",
    ["Toxic Marshmallow"] = "http://www.roblox.com/asset/?id=4939073413",
    ["Grip Marshmallow"] = "http://www.roblox.com/asset/?id=14253207872",
    ["Vote Me Marshmallow"] = "http://www.roblox.com/asset/?id=13424797492",
    ["Honey Dipped Marshmallow"] = "http://www.roblox.com/asset/?id=13424799638",
    ["Banana Marshmallow"] = "http://www.roblox.com/asset/?id=4922748526",
    ["Cursed Idol Marshmallow"] = "http://www.roblox.com/asset/?id=4993221853",
    ["Choc Dipped Marshmallow"] = "http://www.roblox.com/asset/?id=10420319581",
    ["Candyfloss Marshmallow"] = "http://www.roblox.com/asset/?id=4939071806",
    ["Guilty Gift Marshmallow"] = "http://www.roblox.com/asset/?id=13424790186",
    ["Coconut Marshmallow"] = "http://www.roblox.com/asset/?id=4922749819",
    ["Official Marshmallow"] = "http://www.roblox.com/asset/?id=6190482040",
    ["Chocolate Marshmallow"] = "http://www.roblox.com/asset/?id=8989965765",
    ["Toasted Marshmallow"] = "http://www.roblox.com/asset/?id=11109548044",
    ["Surfboard Marshmallow"] = "http://www.roblox.com/asset/?id=14253216830",
    ["Official 2 Marshmallow"] = "http://www.roblox.com/asset/?id=6918605850",
    ["Stink Bomb Marshmallow"] = "http://www.roblox.com/asset/?id=14253212538",
    ["Deathly Frog Marshmallow"] = "http://www.roblox.com/asset/?id=13557357445",
    ["Heart Marshmallow"] = "http://www.roblox.com/asset/?id=11109545563",
    ["Burnt Marshmallow"] = "http://www.roblox.com/asset/?id=4939257688",
    ["Spooky Skull Marshmallow"] = "http://www.roblox.com/asset/?id=13424794215",
    ["Camo Marshmallow"] = "http://www.roblox.com/asset/?id=4993218908",
    ["Star Barrel Marshmallow"] = "http://www.roblox.com/asset/?id=13557362587",
    ["Candycane Marshmallow"] = "http://www.roblox.com/asset/?id=8087099712",
    ["Claus Marshmallow"] = "http://www.roblox.com/asset/?id=8087103731",
    ["Gingerbread Marshmallow"] = "http://www.roblox.com/asset/?id=8087104305",
    ["Snowflake Marshmallow"] = "http://www.roblox.com/asset/?id=8087108522",
    ["Snowman Marshmallow"] = "http://www.roblox.com/asset/?id=8087109234",
    ["Xmas Tree Marshmallow"] = "http://www.roblox.com/asset/?id=8087102391",
    ["Official 5 Marshmallow"] = "http://www.roblox.com/asset/?id=12089683577",
    ["Refresher Marshmallow"] = "http://www.roblox.com/asset/?id=10420322407",
    ["Friendly Fish Marshmallow"] = "http://www.roblox.com/asset/?id=6213300124",
    ["Popcorn Marshmallow"] = "http://www.roblox.com/asset/?id=14253210682",
    ["Salt&Pepper Marshmallow"] = "http://www.roblox.com/asset/?id=4939073043",
    ["Grape Marshmallow"] = "http://www.roblox.com/asset/?id=4939072171",
    ["Mutant Marshmallow"] = "http://www.roblox.com/asset/?id=4993228141",
    ["Blue Sky Marshmallow"] = "http://www.roblox.com/asset/?id=6213301823",
    ["Rainbow Marshmallow"] = "http://www.roblox.com/asset/?id=11109546611",
    ["Animatronic Marshmallow"] = "http://www.roblox.com/asset/?id=14253197608",
    ["Fly Trap Marshmallow"] = "http://www.roblox.com/asset/?id=13557358447",
    ["Lightning Marshmallow"] = "http://www.roblox.com/asset/?id=6213299603",
    ["Official 6 Marshmallow"] = "http://www.roblox.com/asset/?id=13883154348",
    ["Cave Marshmallow"] = "http://www.roblox.com/asset/?id=14253202968",
    ["Briefcase Marshmallow"] = "http://www.roblox.com/asset/?id=14253200770",
    ["Alien Slime Marshmallow"] = "http://www.roblox.com/asset/?id=14253195386",
    ["Strawberry Marshmallow"] = "http://www.roblox.com/asset/?id=8989965284",
    ["Gaffer Marshmallow"] = "http://www.roblox.com/asset/?id=14253205269",
    ["Bane Marshmallow"] = "http://www.roblox.com/asset/?id=4939072726",
    ["All Star Marshmallow"] = "http://www.roblox.com/asset/?id=4993216167",
    ["Voting Machine Marshmallow"] = "http://www.roblox.com/asset/?id=14253219599",
    ["Mint Choc Chip Marshmallow"] = "http://www.roblox.com/asset/?id=10420505533",
    ["Dropped Marshmallow"] = "http://www.roblox.com/asset/?id=6213298209",
    ["Spiderweb Marshmallow"] = "http://www.roblox.com/asset/?id=14891850347",
    ["Mummy Marshmallow"] = "http://www.roblox.com/asset/?id=14891849082",
    ["Jack-o-lantern Marshmallow"] = "http://www.roblox.com/asset/?id=14891848232",
    ["Cauldron Marshmallow"] = "http://www.roblox.com/asset/?id=14891845147",
    ["Ghost Marshmallow"] = "http://www.roblox.com/asset/?id=14891847267",
    ["Candy Corn Marshmallow"] = "http://www.roblox.com/asset/?id=14891843386",
    ["Black Cat Marshmallow"] = "http://www.roblox.com/asset/?id=14891842127",
    ["Frankenstein Marshmallow"] = "http://www.roblox.com/asset/?id=14891846020",
    ["Candy Cane Marshmallow"] = "http://www.roblox.com/asset/?id=15484725814",
    ["Christmas Gift Marshmallow"] = "http://www.roblox.com/asset/?id=15484726913",
    ["Christmas Tree Marshmallow"] = "http://www.roblox.com/asset/?id=15484727551",
    ["Festive Lights Marshmallow"] = "http://www.roblox.com/asset/?id=15484728253",
    ["Frosted Marshmallow"] = "http://www.roblox.com/asset/?id=15484728905",
    ["Hot Chocolate Marshmallow"] = "http://www.roblox.com/asset/?id=15484729538",
    ["Jingle Bell Marshmallow"] = "http://www.roblox.com/asset/?id=15484730291",
    ["Mr Snow Marshmallow"] = "http://www.roblox.com/asset/?id=15484731148",
    ["Reindeer Marshmallow"] = "http://www.roblox.com/asset/?id=15484731823",
    ["Santa Suit Marshmallow"] = "http://www.roblox.com/asset/?id=15484732509",
    ["Snowglobe Marshmallow"] = "http://www.roblox.com/asset/?id=15484733560",
    ["The Grunch Marshmallow"] = "http://www.roblox.com/asset/?id=15484734379",
    ["Bacon Grease Marshmallow"] = "http://www.roblox.com/asset/?id=16029143731",
    ["Pink Paint Marshmallow"] = "http://www.roblox.com/asset/?id=16029151877",
    ["Skunk Tail Marshmallow"] = "http://www.roblox.com/asset/?id=16029163767",
    ["Rodent Face Marshmallow"] = "http://www.roblox.com/asset/?id=16029162747",
    ["Candy Marshmallow"] = "http://www.roblox.com/asset/?id=16029146948",
    ["Lychee Soda Marshmallow"] = "http://www.roblox.com/asset/?id=16029149121",
    ["Banana Soda Marshmallow"] = "http://www.roblox.com/asset/?id=16029144639",
    ["The Wolves Marshmallow"] = "http://www.roblox.com/asset/?id=16029164794",
    ["Young Chester Marshmallow"] = "http://www.roblox.com/asset/?id=16029185414",
    ["Owl Mascot Marshmallow"] = "http://www.roblox.com/asset/?id=16029150192",
    ["Racoon Marshmallow"] = "http://www.roblox.com/asset/?id=16029160256",
    ["Abstract Cake Marshmallow"] = "http://www.roblox.com/asset/?id=16029142769",
    ["Circus Snake Marshmallow"] = "http://www.roblox.com/asset/?id=16029148014",
    ["Bogey Marshmallow"] = "http://www.roblox.com/asset/?id=16029145643",
    ["Sap Removal Marshmallow"] = "http://www.roblox.com/asset/?id=16029165998",
    ["Carrot Marshmallow"] = "http://www.roblox.com/asset/?id=16735788642",
    ["Easter Basket Marshmallow"] = "http://www.roblox.com/asset/?id=16735790050",
    ["Easter Bunny Marshmallow"] = "http://www.roblox.com/asset/?id=16726342799",
    ["Easter Chick Marshmallow"] = "http://www.roblox.com/asset/?id=16735787584",
    ["Easter Egg Marshmallow"] = "http://www.roblox.com/asset/?id=16735791814",
    ["Lion Marshmallow"] = "http://www.roblox.com/asset/?id=16726346946",
    ["Official 7 Marshmallow"] = "http://www.roblox.com/asset/?id=16752097514",
}
local marshmallowList = {}
for name in pairs(marshmallowData) do
    table.insert(marshmallowList, name)
end
table.sort(marshmallowList)
local function applyMarshmallow(texture)
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    local gui = head:FindFirstChild("MarshmallowGUI")
    if not gui then return end
    local sector = gui:FindFirstChild("Sector")
    if not sector then return end
    local imageLabel = sector:FindFirstChildOfClass("ImageLabel")
    if imageLabel then
        imageLabel.Image = texture
    end
end
local skinList = {}
local skinMap = {}
local skinFaceMap = {}
local charSkinIndex = {}
for _, gender in ipairs(CSRoot:GetChildren()) do
    for _, character in ipairs(gender:GetChildren()) do
        local skins = character:FindFirstChild("Skins")
        if skins then
            local charKey = gender.Name .. " | " .. character.Name
            if not charSkinIndex[charKey] then charSkinIndex[charKey] = 0 end
            for _, skin in ipairs(skins:GetChildren()) do
                local label = charKey .. " | " .. skin.Name
                table.insert(skinList, label)
                skinMap[label] = skin
                charSkinIndex[charKey] += 1
                local faceDecal = skin:FindFirstChildOfClass("Decal")
                if faceDecal then
                    skinFaceMap[label] = faceDecal.Texture
                else
                    local charFaceDecal = character:FindFirstChildOfClass("Decal")
                    skinFaceMap[label] = charFaceDecal and charFaceDecal.Texture or ""
                end
            end
        end
    end
end
local function findAttachmentInChar(char, attName)
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("Attachment") and part.Name == attName then return part end
    end
end
local function applySkin(skinObj, faceTexture)
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("Accessory")
        or v:IsA("ShirtGraphic") or v:IsA("CharacterMesh") or v:IsA("Hat") then
            v:Destroy()
        end
    end
    local function doApplyFace()
        local head = char:FindFirstChild("Head")
        if not head or not faceTexture or faceTexture == "" then return end
        local fc = head:FindFirstChildOfClass("FaceControls")
        if fc then fc:Destroy() end
        local sa = head:FindFirstChildOfClass("SurfaceAppearance")
        if sa then sa.ColorMap = faceTexture end
        local decal = head:FindFirstChildOfClass("Decal")
        if not decal then
            decal = Instance.new("Decal")
            decal.Name = "face"
            decal.Face = Enum.NormalId.Front
            decal.Parent = head
        end
        decal.Texture = faceTexture
    end
    doApplyFace()
    task.delay(0.2, doApplyFace)
    task.delay(0.7, doApplyFace)
    local clothesFolder = skinObj:FindFirstChild("Clothes")
    if not clothesFolder then return end
    local shirt = clothesFolder:FindFirstChildOfClass("Shirt")
    if shirt then shirt:Clone().Parent = char end
    local pants = clothesFolder:FindFirstChildOfClass("Pants")
    if pants then pants:Clone().Parent = char end
    local bodyColors = clothesFolder:FindFirstChildOfClass("BodyColors")
    if bodyColors then
        local existing = char:FindFirstChildOfClass("BodyColors")
        if existing then existing:Destroy() end
        bodyColors:Clone().Parent = char
    end
    for _, v in ipairs(clothesFolder:GetChildren()) do
        if v:IsA("CharacterMesh") then v:Clone().Parent = char end
    end
    for _, v in ipairs(clothesFolder:GetChildren()) do
        if v:IsA("Accessory") then
            local clone = v:Clone()
            local handle = clone:FindFirstChild("Handle")
            if handle then
                handle.Massless = true
                local handleAtt = nil
                for _, child in ipairs(handle:GetDescendants()) do
                    if child:IsA("Attachment") then handleAtt = child break end
                end
                if handleAtt then
                    local charAtt = findAttachmentInChar(char, handleAtt.Name)
                    if charAtt then
                        local rigid = Instance.new("RigidConstraint")
                        rigid.Attachment0 = charAtt
                        rigid.Attachment1 = handleAtt
                        rigid.Parent = clone
                    end
                end
            end
            clone.Parent = char
        elseif v:IsA("Hat") then
            v:Clone().Parent = char
        end
    end
    -- Fix: disable collision on all character parts after skin apply
    local function disableCollision()
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    disableCollision()
    task.delay(0.1, disableCollision)
    task.delay(0.5, disableCollision)
end
local UIS = game:GetService("UserInputService")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TRDSelector"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui
local EXPANDED_HEIGHT = 360
local COLLAPSED_HEIGHT = 34
local WINDOW_WIDTH = 260
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, WINDOW_WIDTH, 0, EXPANDED_HEIGHT)
Main.Position = UDim2.new(0.5, -WINDOW_WIDTH / 2, 0.5, -EXPANDED_HEIGHT / 2)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, COLLAPSED_HEIGHT)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 8, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Skin Changer"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar
local minimised = false
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 24, 0, 24)
MinBtn.Position = UDim2.new(1, -58, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Main:Destroy() end)
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -COLLAPSED_HEIGHT)
ContentFrame.Position = UDim2.new(0, 0, 0, COLLAPSED_HEIGHT)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ClipsDescendants = false
ContentFrame.Visible = true
ContentFrame.Parent = Main
MinBtn.MouseButton1Click:Connect(function()
    minimised = not minimised
    ContentFrame.Visible = not minimised
    TweenService:Create(Main, TweenInfo.new(0.15), {
        Size = UDim2.new(0, WINDOW_WIDTH, 0, minimised and COLLAPSED_HEIGHT or EXPANDED_HEIGHT)
    }):Play()
    MinBtn.Text = minimised and "+" or "-"
end)
local TAB_BAR_Y = 0
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 28)
TabBar.Position = UDim2.new(0, 0, 0, TAB_BAR_Y)
TabBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabBar.BorderSizePixel = 0
TabBar.Parent = ContentFrame
local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar
local CONTENT_Y = 28
local function makeTabContent()
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 1, -(CONTENT_Y + 30))
    Container.Position = UDim2.new(0, 0, 0, CONTENT_Y)
    Container.BackgroundTransparency = 1
    Container.Visible = false
    Container.Parent = ContentFrame
    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, -16, 0, 26)
    SearchBox.Position = UDim2.new(0, 8, 0, 4)
    SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SearchBox.BorderSizePixel = 0
    SearchBox.PlaceholderText = "Search..."
    SearchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchBox.TextSize = 12
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.Parent = Container
    Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, -16, 1, -36)
    ScrollFrame.Position = UDim2.new(0, 8, 0, 34)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 3
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    ScrollFrame.Parent = Container
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, 3)
    ListLayout.Parent = ScrollFrame
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 4)
    end)
    return Container, SearchBox, ScrollFrame
end
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -16, 0, 24)
StatusLabel.Position = UDim2.new(0, 8, 1, -28)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = ContentFrame
local function makeButton(parent, label, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 28)
    Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Btn.BorderSizePixel = 0
    Btn.Text = label
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.TextSize = 11
    Btn.Font = Enum.Font.Gotham
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.TextTruncate = Enum.TextTruncate.AtEnd
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local P = Instance.new("UIPadding", Btn)
    P.PaddingLeft = UDim.new(0, 7)
    Btn.MouseButton1Click:Connect(function()
        callback()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60,60,60)}):Play()
        task.delay(0.2, function()
            TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
        end)
    end)
    return Btn
end
local tabs = {}
local activeTab = nil
local function makeTab(name, order)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0, WINDOW_WIDTH / 2, 1, 0)
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    TabBtn.TextSize = 11
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.LayoutOrder = order
    TabBtn.Parent = TabBar
    Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 0)
    local Container, SearchBox, ScrollFrame = makeTabContent()
    local tabData = {
        btn = TabBtn,
        container = Container,
        search = SearchBox,
        scroll = ScrollFrame,
        buttons = {}
    }
    table.insert(tabs, tabData)
    TabBtn.MouseButton1Click:Connect(function()
        for _, t in ipairs(tabs) do
            t.container.Visible = false
            t.btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            t.btn.TextColor3 = Color3.fromRGB(180, 180, 180)
        end
        Container.Visible = true
        TabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        activeTab = tabData
    end)
    return tabData
end
local skinTab = makeTab("Skins", 1)
local mallowTab = makeTab("Marshmallows", 2)
skinTab.container.Visible = true
skinTab.btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
skinTab.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
activeTab = skinTab
table.sort(skinList)
for _, label in ipairs(skinList) do
    local btn = makeButton(skinTab.scroll, label, function()
        local skin = skinMap[label]
        local face = skinFaceMap[label]
        if skin then
            applySkin(skin, face)
            StatusLabel.Text = "✓ " .. skin.Name
        end
    end)
    table.insert(skinTab.buttons, {btn = btn, label = label})
end
skinTab.search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = skinTab.search.Text:lower()
    for _, item in ipairs(skinTab.buttons) do
        item.btn.Visible = item.label:lower():find(q) ~= nil
    end
end)
for _, name in ipairs(marshmallowList) do
    local btn = makeButton(mallowTab.scroll, name, function()
        applyMarshmallow(marshmallowData[name])
        StatusLabel.Text = "✓ " .. name
    end)
    table.insert(mallowTab.buttons, {btn = btn, label = name})
end
mallowTab.search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = mallowTab.search.Text:lower()
    for _, item in ipairs(mallowTab.buttons) do
        item.btn.Visible = item.label:lower():find(q) ~= nil
    end
end)
]=])()
    end,
})
CharactersTab:CreateInput({
   Name = "Custom Name",
   PlaceholderText = "Enter name here...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
       _G.CustomName = Text
       _G.UseCustomName = (Text ~= "")
   end,
})
CharactersTab:CreateDropdown({
   Name = "Font",
   Options = {
       "Default", "Cartoon", "Fredoka", "Indie Flower", "Kalam", "Creepster",
       "Typewriter", "Lilita", "Handwritten", "Pixel", "Sci-Fi", "Sarpanch",
       "Bangers", "Luckiest Guy", "Oswald", "Nunito", "Marker", "Grenze",
       "Fondamento", "Code", "Fraktur", "Mono", "Vintage", "Titillium", "Bodoni"
   },
   CurrentOption = "Default",
   Callback = function(Option)
      local choice = Option[1]
      local fonts = {
          ["Default"] = nil,
          ["Cartoon"] = Enum.Font.Cartoon,
          ["Fredoka"] = Enum.Font.FredokaOne,
          ["Indie Flower"] = Enum.Font.IndieFlower,
          ["Kalam"] = Enum.Font.Kalam,
          ["Creepster"] = Enum.Font.Creepster,
          ["Typewriter"] = Enum.Font.SpecialElite,
          ["Lilita"] = Enum.Font.LilitaOne,
          ["Handwritten"] = Enum.Font.PatrickHand,
          ["Pixel"] = Enum.Font.Arcade,
          ["Sci-Fi"] = Enum.Font.SciFi,
          ["Sarpanch"] = Enum.Font.Sarpanch,
          ["Bangers"] = Enum.Font.Bangers,
          ["Luckiest Guy"] = Enum.Font.LuckiestGuy,
          ["Oswald"] = Enum.Font.Oswald,
          ["Nunito"] = Enum.Font.Nunito,
          ["Marker"] = Enum.Font.PermanentMarker,
          ["Grenze"] = Enum.Font.GrenzeGotisch,
          ["Fondamento"] = Enum.Font.Fondamento,
          ["Code"] = Enum.Font.Code,
          ["Fraktur"] = Enum.Font.UnifrakturMaguntia,
          ["Mono"] = Enum.Font.RobotoMono,
          ["Vintage"] = Enum.Font.Antique,
          ["Titillium"] = Enum.Font.TitilliumWeb,
          ["Bodoni"] = Enum.Font.Bodoni
      }
      _G.SelectedFont = fonts[choice]
   end,
})
CharactersTab:CreateSlider({
   Name = "Rainbow Speed",
   Range = {0, 5},
   Increment = 0.1,
   Suffix = "x",
   CurrentValue = 0.5,
   Flag = "SpeedSlider",
   Callback = function(Value)
      _G.RainbowSpeed = Value
   end,
})
CharactersTab:CreateToggle({
   Name = "Rainbow Effect",
   CurrentValue = false,
   Flag = "RainbowToggle",
   Callback = function(Value)
      _G.RainbowMode = Value
   end,
})
CharactersTab:CreateColorPicker({
    Name = "Static Color",
    Color = Color3.fromRGB(255, 182, 193),
    Flag = "ColorPicker",
    Callback = function(Value)
        _G.StaticColor = Value
        _G.StaticColorCustom = true
    end
})
game:GetService("RunService").RenderStepped:Connect(function()
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            if _G.UseCustomName and _G.CustomName ~= "" then
                obj.Text = _G.CustomName
            end
            if _G.SelectedFont then 
                obj.Font = _G.SelectedFont 
            end
            obj.TextScaled = true
            if _G.RainbowMode then
                local hue = (tick() * _G.RainbowSpeed) % 1
                obj.TextColor3 = Color3.fromHSV(hue, 0.6, 1) 
            elseif _G.StaticColorCustom then
                obj.TextColor3 = _G.StaticColor
            end
            obj.TextStrokeTransparency = 0.5
            obj.BackgroundTransparency = 1
        end
    end
end)
local ply = {}
for _, v in ipairs(game.Players:GetPlayers()) do
    table.insert(ply, v.Name)
end
local stato = ply[1]
StatsTab:CreateSection("Select Player")
local Dropdownee = StatsTab:CreateDropdown({
    Name = "Choose Player",
    Options = ply,
    CurrentOption = {stato},
    MultipleOptions = false,
    Flag = "Dropdownee",
    Callback = function(value)
        stato = value[1]
    end,
})
StatsTab:CreateButton({
    Name = "Refresh List",
    Callback = function()
        local nlist = {}
        for _, v in ipairs(game.Players:GetChildren()) do
            table.insert(nlist, v.Name)
        end
        Dropdownee:Refresh(nlist)
    end,
})
StatsTab:CreateSection("Stats")
StatsTab:CreateButton({
    Name = "Print Skins (Check /console)",
    Callback = function()
        local skins = game.Players[stato].DataStore.Skins
        if #skins:GetChildren() == 0 then
            print(stato .. " has no skins.")
        else
            print(stato .. " has these skins: ")
            for i, v in ipairs(skins:GetChildren()) do print(v.Name) end
        end
    end,
})
StatsTab:CreateButton({
    Name = "Print Marshmallows (Check /console)",
    Callback = function()
        local skins = game.Players[stato].DataStore.Marshmallows
        if #skins:GetChildren() == 0 then
            print(stato .. " has no marshmallows.")
        else
            print(stato .. " has these marshmallows: ")
            for i, v in ipairs(skins:GetChildren()) do print(v.Name) end
        end
    end,
})
StatsTab:CreateButton({
    Name = "Notify Camp Wins",
    Callback = function()
        local skins = game.Players[stato].DataStore.CampWins
        Rayfield:Notify({ Title = "Camp Wins", Content = stato .. " has " .. skins.Value .. " camp wins.", Duration = 4, Image = "hash" })
    end,
})
StatsTab:CreateButton({
    Name = "Notify Movies Wins",
    Callback = function()
        local skins = game.Players[stato].DataStore.MoviesWins
        Rayfield:Notify({ Title = "Movies Wins", Content = stato .. " has " .. skins.Value .. " movies wins.", Duration = 4, Image = "hash" })
    end,
})
StatsTab:CreateButton({
    Name = "Notify Expedition Wins",
    Callback = function()
        local skins = game.Players[stato].DataStore.ExpeditionWins
        Rayfield:Notify({ Title = "Expedition Wins", Content = stato .. " has " .. skins.Value .. " expedition wins.", Duration = 4, Image = "hash" })
    end,
})
StatsTab:CreateButton({
    Name = "Notify Coins",
    Callback = function()
        local skins = game.Players[stato].DataStore.Coins
        Rayfield:Notify({ Title = "Coins", Content = stato .. " has " .. skins.Value .. " coins.", Duration = 4, Image = "hash" })
    end,
})
StatsTab:CreateButton({
    Name = "Notify Comeback Wins",
    Callback = function()
        local skins = game.Players[stato].DataStore.ComebackWins
        Rayfield:Notify({ Title = "Comeback Wins", Content = stato .. " has " .. skins.Value .. " comeback wins.", Duration = 4, Image = "hash" })
    end,
})
StatsTab:CreateButton({
    Name = "Notify Games Played",
    Callback = function()
        local skins = game.Players[stato].DataStore.GamesPlayed
        Rayfield:Notify({ Title = "Games Played", Content = stato .. " played a total of " .. skins.Value .. " games.", Duration = 4, Image = "hash" })
    end,
})
StatsTab:CreateButton({
    Name = "Notify Idols Found",
    Callback = function()
        local skins = game.Players[stato].DataStore.IdolsFound
        Rayfield:Notify({ Title = "Idols Collected", Content = stato .. " found " .. skins.Value .. " total idols.", Duration = 4, Image = "hash" })
    end,
})
StatsTab:CreateButton({
    Name = "Notify Confessional",
    Callback = function()
        local skins = game.Players[stato].DataStore.Confessional
        Rayfield:Notify({ Title = stato .. "'s Confessional", Content = skins.Value, Duration = 4, Image = "hash" })
    end,
})
if isCamp then
TeleportsTab:CreateSection("Teleports")
TeleportsTab:CreateButton({
    Name = "Spectator Island",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(33, -16, 31)
    end,
})
TeleportsTab:CreateButton({
    Name = "Main Island",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(150, -17, -417)
    end,
})
TeleportsTab:CreateButton({
    Name = "Exile Island",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(-116, -14, -166)
    end,
})
TeleportsTab:CreateButton({
    Name = "Voting Area",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(-23, 95, -514)
    end,
})
TeleportsTab:CreateButton({
    Name = "Boat",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(47, -20, -297)
    end,
})
TeleportsTab:CreateButton({
    Name = "Bathroom",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(302, -15, -325)
    end,
})
end
if isMovies then
TeleportsTab:CreateButton({
    Name = "Dock",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(-187, 52, 5)
    end,
})
TeleportsTab:CreateButton({
    Name = "Voting Area",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(89, 63, -148)
    end,
})
TeleportsTab:CreateButton({
    Name = "Confessionals",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(17, 65, -24)
    end,
})
TeleportsTab:CreateButton({
    Name = "Challenge",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(357, 64, -257)
    end,
})
TeleportsTab:CreateButton({
    Name = "Aftermath",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(-669, -66, -666)
    end,
})
end
if isExpedition then
TeleportsTab:CreateButton({
    Name = "Drop-Off",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(-116, 106, -32)
    end,
})
TeleportsTab:CreateButton({
    Name = "Confessionals",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(2, 102, -23)
    end,
})
TeleportsTab:CreateButton({
    Name = "First Class",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(172, 105, -35)
    end,
})
TeleportsTab:CreateButton({
    Name = "Spectator Island",
    Callback = function()
        player.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(-157, -22, -885)
    end,
})
end
if not isMovies then
ChallengesTab:CreateSection("Challenges")
ChallengesTab:CreateButton({
    Name = "Sword Damage Amplifier",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Sword-script-damage-amplifier-110941"))()
    end,
})
end
local autoWinAll = false
if isCamp then
local _arActiveCamp = false
local _arFiredCamp  = false
ChallengesTab:CreateToggle({
    Name = "Auto Restart Day",
    CurrentValue = false,
    Flag = "AutoRestartDayCamp",
    Callback = function(Value)
        _arActiveCamp = Value
        _arFiredCamp  = false
        if Value then
            Rayfield:Notify({ Title = "Auto Restart Day", Content = "Active — watching for round timer...", Duration = 3, Image = "bell-ring" })
            task.spawn(function()
                while _arActiveCamp do
                    local timerVisible = false
                    pcall(function()
                        timerVisible = player.PlayerGui.Timer.Background.Timer.Visible
                    end)
                    if timerVisible and not _arFiredCamp then
                        _arFiredCamp = true
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxcheatck/reanimatescript/main/script.lua", true))()
                    end
                    if not timerVisible then
                        _arFiredCamp = false
                    end
                    task.wait(0.05)
                end
            end)
        else
            Rayfield:Notify({ Title = "Auto Restart Day", Content = "Stopped.", Duration = 3, Image = "bell-ring" })
        end
    end,
})
ChallengesTab:CreateToggle({
    Name = "Auto Win All Challenges",
    CurrentValue = false,
    Flag = "AutoWinAll",
    Callback = function(Value)
        autoWinAll = Value
        if Value then
            task.spawn(function()
                while autoWinAll do
                    local assets = workspace:FindFirstChild("Assets")
                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if assets and char and root then
                        local finish = assets:FindFirstChild("Finish", true)
                        if finish then
                            finish.CanCollide = false
                            finish.Transparency = 1
                            finish.Position = root.Position
                        end
                        local spleef = assets:FindFirstChild("Spleef")
                        if spleef and not _G.spleefDone then
                            _G.spleefDone = true
                            task.spawn(function()
                                task.wait(11)
                                local part = spleef:FindFirstChild("Part")
                                if part then
                                    local touch = part:FindFirstChild("TouchInterest")
                                    if touch then touch:Destroy() end
                                end
                                for _, v in pairs(spleef:GetDescendants()) do
                                    if v.Name == "SpleefPart" then
                                        firetouchinterest(root, v, 0)
                                    end
                                end
                            end)
                        end
                        if not assets:FindFirstChild("Spleef") then _G.spleefDone = false end
                        for _, v in pairs(assets:GetDescendants()) do
                            if v.Name == "Coin" or v.Name == "Gem" then
                                if v:IsA("BasePart") then
                                    v.CanCollide = false
                                    v.Position = root.Position
                                end
                            end
                        end
                        local hasPancake = false
                        for _, v in pairs(assets:GetDescendants()) do
                            if v.Name == player.Name and v:FindFirstChild("ClickDetector") then
                                hasPancake = true
                                break
                            end
                        end
                        if hasPancake and not _G.pancakeDone then
                            _G.pancakeDone = true
                            task.spawn(function()
                                task.wait(11)
                                for _, v in pairs(assets:GetDescendants()) do
                                    if v.Name == player.Name and v:FindFirstChild("ClickDetector") then
                                        for _ = 1, 80 do fireclickdetector(v.ClickDetector) end
                                    end
                                end
                            end)
                        end
                        if not hasPancake then _G.pancakeDone = false end
                        local singularBox = assets:FindFirstChild("SingularBox", true)
                        if singularBox and not _G.blockPushDone then
                            _G.blockPushDone = true
                            task.spawn(function()
                                task.wait(11)
                                while assets and assets.Parent do
                                    local pushed = false
                                    for _, v in ipairs(assets:GetDescendants()) do
                                        if v:IsA("Part") and v.Name == "SingularBox" then
                                            for _, v2 in ipairs(assets:GetDescendants()) do
                                                if v2:IsA("Part") and v2.Name == "Gold" then
                                                    v.Position = v2.Position + Vector3.new(0, 3, 0)
                                                    root.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                                                    pushed = true
                                                    break
                                                end
                                            end
                                        end
                                        if pushed then break end
                                    end
                                    task.wait(1)
                                end
                            end)
                        end
                        if not assets:FindFirstChild("SingularBox", true) then _G.blockPushDone = false end
                        local backpack = player:FindFirstChild("Backpack")
                        if backpack then
                            local tool = nil
                            for _, t in ipairs(backpack:GetChildren()) do
                                if t:IsA("Tool") and t.Name:lower():find("sword") then
                                    tool = t
                                    break
                                end
                            end
                            local humanoid = char:FindFirstChildOfClass("Humanoid")
                            if tool and humanoid then humanoid:EquipTool(tool) end
                        end
                        local equippedTool = char and char:FindFirstChildOfClass("Tool")
                        if equippedTool and equippedTool:FindFirstChild("Handle") then
                            local players = game.Players:GetPlayers()
                            for i = 2, #players do
                                local otherPlayer = players[i]
                                local pchar = otherPlayer.Character
                                if pchar and not player:IsFriendsWith(otherPlayer.UserId) then
                                    equippedTool:Activate()
                                    for _, part in next, pchar:GetChildren() do
                                        if part:IsA("BasePart") then
                                            firetouchinterest(equippedTool.Handle, part, 0)
                                            firetouchinterest(equippedTool.Handle, part, 1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    local mathManiaGui = player.PlayerGui:FindFirstChild("MathMania")
                    if mathManiaGui then
                        for number = 1, 10 do
                            if not autoWinAll then break end
                            local questionGui = mathManiaGui:FindFirstChild(tostring(number))
                            if questionGui then
                                local s = questionGui.MainText.Text
                                local clean = s:gsub("=", ""):gsub("?", ""):gsub(" ", "")
                                local result = loadstring("return " .. clean)()
                                if result then
                                    questionGui.Box.Text = tostring(result)
                                    local button = questionGui:FindFirstChild("Enter")
                                    if button then
                                        for _, event in pairs({"MouseButton1Click", "MouseButton1Down", "Activated"}) do
                                            if getconnections and button[event] then
                                                for _, connection in pairs(getconnections(button[event])) do
                                                    if connection.Function then connection:Fire() end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})
ChallengesTab:CreateToggle({
    Name = "Auto-Win Obby",
    CurrentValue = false,
    Flag = "AutoWinObby",
    Callback = function(Value)
        autoWinObby = Value
        if Value then
            task.spawn(function()
                while autoWinObby do
                    local assets = workspace:FindFirstChild("Assets")
                    if assets then
                        local finish = assets:FindFirstChild("Finish", true)
                        if finish then
                            finish.CanCollide = false
                            finish.Transparency = 1
                            task.wait()
                            finish.Position = player.Character.HumanoidRootPart.Position
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})
local autoCollect = false
ChallengesTab:CreateToggle({
    Name = "Auto Collect Coins & Gems",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(Value)
        autoCollect = Value
        if Value then
            task.spawn(function()
                while autoCollect do
                    task.wait(0.5)
                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        for i, v in pairs(workspace.Assets:GetDescendants()) do
                            if v.Name == "Coin" or v.Name == "Gem" then
                                if v:IsA("BasePart") then
                                    v.CanCollide = false
                                    v.Position = root.Position
                                end
                            end
                        end
                    end
                end
            end)
        end
    end,
})
local autoMath = false
ChallengesTab:CreateToggle({
    Name = "Auto-Win Math Mania",
    CurrentValue = false,
    Flag = "AutoWinMath",
    Callback = function(Value)
        autoMath = Value
        if Value then
            task.spawn(function()
                while autoMath do
                    local mathManiaGui = player.PlayerGui:FindFirstChild("MathMania")
                    if mathManiaGui then
                        for number = 1, 10 do
                            if not autoMath then break end
                            local questionGui = mathManiaGui:FindFirstChild(tostring(number))
                            if questionGui then
                                local s = questionGui.MainText.Text
                                local clean = s:gsub("=", ""):gsub("?", ""):gsub(" ", "")
                                local result = loadstring("return " .. clean)()
                                if result then
                                    questionGui.Box.Text = tostring(result)
                                    local button = questionGui:FindFirstChild("Enter")
                                    if button then
                                        local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
                                        for _, event in pairs(events) do
                                            if getconnections and button[event] then
                                                for _, connection in pairs(getconnections(button[event])) do
                                                    if connection.Function then connection:Fire() end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    task.wait()
                end
            end)
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Win Obby",
    Callback = function()
        local finish = workspace.Assets:FindFirstChild("Finish", true)
        if finish then
            finish.CanCollide = false
            finish.Transparency = 1
            wait()
            finish.Position = player.Character.Torso.Position
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Finish Pancake",
    Callback = function()
        for i, v in pairs(workspace.Assets:GetDescendants()) do
            if v.Name == player.Name then
                for _ = 1, 80 do
                    fireclickdetector(v.ClickDetector)
                end
            end
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Part Controller (Block Push)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Better-Part-controller-57507"))()
    end,
})
ChallengesTab:CreateButton({
    Name = "Win Block Push",
    Callback = function()
        for i, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Part") and v.Name == "SingularBox" then
                local distance = (v.Position - player.Character.HumanoidRootPart.Position).Magnitude
                if distance <= 100 then
                    for i2, v2 in ipairs(workspace:GetDescendants()) do
                        if v2:IsA("Part") and v2.Name == "Gold" then
                            v.Position = v2.Position + Vector3.new(0, 3, 0)
                            player.Character.HumanoidRootPart.CFrame = CFrame.new(v.Position + Vector3.new(0, 3, 0))
                            break
                        end
                    end
                    break
                end
            end
        end
    end,
})
local autoDodgeballEnabled = false
local function getDodgeballCount()
    local count = 0
    local backpack = player:FindFirstChild("Backpack")
    local char = player.Character
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("dodgeball") then count = count + 1 end
        end
    end
    if char then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("dodgeball") then count = count + 1 end
        end
    end
    return count
end
ChallengesTab:CreateToggle({
    Name = "Auto Get Dodgeballs",
    CurrentValue = false,
    Flag = "AutoGetDodgeballs",
    Callback = function(Value)
        autoDodgeballEnabled = Value
        if Value then
            task.spawn(function()
                while autoDodgeballEnabled do
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local giver = workspace:FindFirstChild("DodgeballGiver", true)
                    if hrp and giver then
                        local color = giver.Color
                        local isWhite = color.R > 0.9 and color.G > 0.9 and color.B > 0.9
                        if isWhite and getDodgeballCount() < 2 then
                            giver.CanCollide = false
                            giver.CFrame = hrp.CFrame
                            task.wait(0.1)
                        end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Sword Fight Hitbox Extender",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Universal-Sword-Kill-Aura-46531"))()
    end,
})
local paintballProtection = false
local dbProtection = false
ChallengesTab:CreateToggle({
    Name = "Paintball Protection",
    CurrentValue = false,
    Flag = "PaintballProtection",
    Callback = function(Value)
        paintballProtection = Value
        if Value then
            task.spawn(function()
                local triggered = false
                while paintballProtection do
                    local assets = workspace:FindFirstChild("Assets")
                    if assets then
                        local paintball = assets:FindFirstChild("Paintball", true) or assets:FindFirstChild("PaintballArena", true)
                        if paintball and not triggered then
                            triggered = true
                            player.Character.Humanoid.Health = 0
                        end
                        if not paintball then triggered = false end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})
ChallengesTab:CreateToggle({
    Name = "Dodgeball Protection",
    CurrentValue = false,
    Flag = "DodgeballProtection",
    Callback = function(Value)
        dbProtection = Value
        if Value then
            task.spawn(function()
                local triggered = false
                while dbProtection do
                    local assets = workspace:FindFirstChild("Assets")
                    if assets then
                        local dbGiver = assets:FindFirstChild("DodgeballGiver", true)
                        if dbGiver and not triggered then
                            triggered = true
                            player.Character.Humanoid.Health = 0
                        end
                        if not dbGiver then triggered = false end
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Auto Dodge Dodgeball",
    Callback = function()
        Rayfield:Notify({ Title = "Coming Soon", Content = "This feature is coming soon!", Duration = 3, Image = "clock" })
    end,
})
ChallengesTab:CreateButton({
    Name = "Obby God-Mode",
    Callback = function()
        local klp = {"Mud", "Water", "Lava"}
        for _, v in pairs(workspace.Assets:GetDescendants()) do
            if table.find(klp, v.Name) then
                local touch = v:FindFirstChild("TouchInterest")
                if touch then touch:Destroy() end
            end
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Spleef God-Mode",
    Callback = function()
        local assets = workspace:FindFirstChild("Assets")
        if assets then
            local spleef = assets:FindFirstChild("Spleef")
            if spleef then
                local part = spleef:FindFirstChild("Part")
                if part then
                    local touch = part:FindFirstChild("TouchInterest")
                    if touch then touch:Destroy() end
                end
            end
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Remove All Particles in Spleef",
    Callback = function()
        for i, v in pairs(game.Workspace.Assets:GetDescendants()) do
            if v.Name == "SpleefPart" then
                firetouchinterest(player.Character.HumanoidRootPart, v, 0)
            end
        end
    end,
})
local swordFightEnabled = false
local swordFightConnection = nil
ChallengesTab:CreateToggle({
    Name = "Kill Everyone In Sword Fight",
    CurrentValue = false,
    Flag = "SwordFightKill",
    Callback = function(Value)
        swordFightEnabled = Value
        if Value then
            task.spawn(function()
                while swordFightEnabled do
                    local backpack = player:FindFirstChild("Backpack")
                    local char = player.Character
                    if backpack and char then
                        local tool = nil
                        for _, t in ipairs(backpack:GetChildren()) do
                            if t:IsA("Tool") and t.Name:lower():find("sword") then
                                tool = t
                                break
                            end
                        end
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if tool and humanoid then humanoid:EquipTool(tool) end
                    end
                    task.wait()
                end
            end)
            if swordFightConnection then swordFightConnection:Disconnect() end
            swordFightConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local players = game.Players:GetPlayers()
                for i = 2, #players do
                    local otherPlayer = players[i]
                    local character = otherPlayer.Character
                    if character and not player:IsFriendsWith(otherPlayer.UserId) then
                        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                        if tool and tool:FindFirstChild("Handle") then
                            tool:Activate()
                            for _, part in next, character:GetChildren() do
                                if part:IsA("BasePart") then
                                    firetouchinterest(tool.Handle, part, 0)
                                    firetouchinterest(tool.Handle, part, 1)
                                end
                            end
                        end
                    end
                end
            end)
        else
            if swordFightConnection then
                swordFightConnection:Disconnect()
                swordFightConnection = nil
            end
        end
    end,
})
ChallengesTab:CreateLabel("Must be in first person for aimbot to work!")
ChallengesTab:CreateButton({
    Name = "Aimbot (Paintball / Dodgeball)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Camlock-universal-Open-source-165899"))()
    end,
})
ChallengesTab:CreateButton({
    Name = "Disable Spinner/Sweeper Parts",
    Callback = function()
        local function disableTouchInterest(part)
            for _, v in ipairs(part:GetChildren()) do
                if v:IsA("TouchTransmitter") then
                    v:Destroy()
                end
            end
        end
        local function processWorkspace()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("UnionOperation") then
                    disableTouchInterest(obj)
                end
            end
        end
        processWorkspace()
        workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("UnionOperation") then
                task.wait()
                disableTouchInterest(obj)
            end
        end)
    end,
})
local _cliffDivingESP = false
local _cliffDivingObjects = {}
local _cliffDivingConn1, _cliffDivingConn2, _cliffDivingUpdateConn
ChallengesTab:CreateToggle({
    Name = "Cliff Diving ESP",
    CurrentValue = false,
    Flag = "CliffDivingESP",
    Callback = function(Value)
        _cliffDivingESP = Value
        if Value then
            local _cdESP_COLOR = Color3.fromRGB(0, 255, 0)
            local _cdMAX_DIST = 500
            local function _createCliffESP(part)
                if _cliffDivingObjects[part] then return end
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 200, 0, 80)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = part
                bb.Parent = part
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0.5, 0)
                lbl.TextColor3 = _cdESP_COLOR
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lbl.TextSize = 28
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = "🏁 FINISH"
                lbl.Parent = bb
                local distLbl = Instance.new("TextLabel")
                distLbl.BackgroundTransparency = 1
                distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                distLbl.TextStrokeTransparency = 0
                distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                distLbl.TextSize = 22
                distLbl.Font = Enum.Font.Gotham
                distLbl.Text = ""
                distLbl.Parent = bb
                _cliffDivingObjects[part] = { billboard = bb, distLabel = distLbl }
            end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower() == "finish" then
                    _createCliffESP(obj)
                end
            end
            _cliffDivingConn1 = workspace.DescendantAdded:Connect(function(obj)
                if _cliffDivingESP and obj:IsA("BasePart") and obj.Name:lower() == "finish" then
                    _createCliffESP(obj)
                end
            end)
            _cliffDivingConn2 = workspace.DescendantRemoving:Connect(function(obj)
                if _cliffDivingObjects[obj] then
                    pcall(function() _cliffDivingObjects[obj].billboard:Destroy() end)
                    _cliffDivingObjects[obj] = nil
                end
            end)
            _cliffDivingUpdateConn = game:GetService("RunService").RenderStepped:Connect(function()
                if not _cliffDivingESP then return end
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                for part, esp in pairs(_cliffDivingObjects) do
                    local dist = (part.Position - root.Position).Magnitude
                    esp.billboard.Enabled = dist <= _cdMAX_DIST
                    if dist <= _cdMAX_DIST then
                        esp.distLabel.Text = string.format("%.1f studs", dist)
                    end
                end
            end)
        else
            for part, esp in pairs(_cliffDivingObjects) do
                pcall(function() esp.billboard:Destroy() end)
            end
            _cliffDivingObjects = {}
            if _cliffDivingConn1 then _cliffDivingConn1:Disconnect(); _cliffDivingConn1 = nil end
            if _cliffDivingConn2 then _cliffDivingConn2:Disconnect(); _cliffDivingConn2 = nil end
            if _cliffDivingUpdateConn then _cliffDivingUpdateConn:Disconnect(); _cliffDivingUpdateConn = nil end
        end
    end,
})
end
if isMovies then
ChallengesTab:CreateSection("Challenges")
ChallengesTab:CreateLabel("Must be in first person for aimbot to work!")
ChallengesTab:CreateButton({
    Name = "Aimbot (Western Raygun Challenge)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Camlock-universal-Open-source-165899"))()
    end,
})
local _stuntMovieESP = false
local _stuntMovieObjects = {}
local _stuntMovieConn1, _stuntMovieConn2, _stuntMovieUpdateConn
ChallengesTab:CreateToggle({
    Name = "Stunt Movie ESP",
    CurrentValue = false,
    Flag = "StuntMovieESP",
    Callback = function(Value)
        _stuntMovieESP = Value
        if Value then
            local _smESP_COLOR = Color3.fromRGB(0, 255, 0)
            local _smMAX_DIST = 500
            local function _createStuntESP(part)
                if _stuntMovieObjects[part] then return end
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 200, 0, 80)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = part
                bb.Parent = part
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0.5, 0)
                lbl.TextColor3 = _smESP_COLOR
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lbl.TextSize = 28
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = "🎬 FINISH"
                lbl.Parent = bb
                local distLbl = Instance.new("TextLabel")
                distLbl.BackgroundTransparency = 1
                distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                distLbl.TextStrokeTransparency = 0
                distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                distLbl.TextSize = 22
                distLbl.Font = Enum.Font.Gotham
                distLbl.Text = ""
                distLbl.Parent = bb
                _stuntMovieObjects[part] = { billboard = bb, distLabel = distLbl }
            end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower() == "finish" then
                    _createStuntESP(obj)
                end
            end
            _stuntMovieConn1 = workspace.DescendantAdded:Connect(function(obj)
                if _stuntMovieESP and obj:IsA("BasePart") and obj.Name:lower() == "finish" then
                    _createStuntESP(obj)
                end
            end)
            _stuntMovieConn2 = workspace.DescendantRemoving:Connect(function(obj)
                if _stuntMovieObjects[obj] then
                    pcall(function() _stuntMovieObjects[obj].billboard:Destroy() end)
                    _stuntMovieObjects[obj] = nil
                end
            end)
            _stuntMovieUpdateConn = game:GetService("RunService").RenderStepped:Connect(function()
                if not _stuntMovieESP then return end
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                for part, esp in pairs(_stuntMovieObjects) do
                    local dist = (part.Position - root.Position).Magnitude
                    esp.billboard.Enabled = dist <= _smMAX_DIST
                    if dist <= _smMAX_DIST then
                        esp.distLabel.Text = string.format("%.1f studs", dist)
                    end
                end
            end)
        else
            for part, esp in pairs(_stuntMovieObjects) do
                pcall(function() esp.billboard:Destroy() end)
            end
            _stuntMovieObjects = {}
            if _stuntMovieConn1 then _stuntMovieConn1:Disconnect(); _stuntMovieConn1 = nil end
            if _stuntMovieConn2 then _stuntMovieConn2:Disconnect(); _stuntMovieConn2 = nil end
            if _stuntMovieUpdateConn then _stuntMovieUpdateConn:Disconnect(); _stuntMovieUpdateConn = nil end
        end
    end,
})
local _arActiveMovies = false
local _arFiredMovies  = false
ChallengesTab:CreateToggle({
    Name = "Auto Restart Day",
    CurrentValue = false,
    Flag = "AutoRestartDayMovies",
    Callback = function(Value)
        _arActiveMovies = Value
        _arFiredMovies  = false
        if Value then
            Rayfield:Notify({ Title = "Auto Restart Day", Content = "Active — watching for round timer...", Duration = 3, Image = "bell-ring" })
            task.spawn(function()
                while _arActiveMovies do
                    local timerVisible = false
                    pcall(function()
                        timerVisible = player.PlayerGui.Timer.Background.Timer.Visible
                    end)
                    if timerVisible and not _arFiredMovies then
                        _arFiredMovies = true
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxcheatck/reanimatescript/main/script.lua", true))()
                    end
                    if not timerVisible then
                        _arFiredMovies = false
                    end
                    task.wait(0.05)
                end
            end)
        else
            Rayfield:Notify({ Title = "Auto Restart Day", Content = "Stopped.", Duration = 3, Image = "bell-ring" })
        end
    end,
})
local _disableFiresConn = nil
ChallengesTab:CreateToggle({
    Name = "Disable Fires",
    CurrentValue = false,
    Flag = "DisableFiresMovies",
    Callback = function(Value)
        if Value then
            local function removeFireTouchInterest()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("TouchTransmitter") then
                        pcall(function() v:Destroy() end)
                    end
                end
            end
            removeFireTouchInterest()
            _disableFiresConn = game:GetService("RunService").Stepped:Connect(function()
                removeFireTouchInterest()
            end)
            Rayfield:Notify({ Title = "Disable Fires", Content = "Fires disabled.", Duration = 3, Image = "flame" })
        else
            if _disableFiresConn then
                _disableFiresConn:Disconnect()
                _disableFiresConn = nil
            end
            Rayfield:Notify({ Title = "Disable Fires", Content = "Stopped.", Duration = 3, Image = "flame" })
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Win Obby",
    Callback = function()
        local f = workspace.Assets:FindFirstChild("Finish", true)
        if f and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            f.CanCollide = false; f.Transparency = 1; f.Position = player.Character.HumanoidRootPart.Position
        end
    end,
})
local _movObby = false
ChallengesTab:CreateToggle({
    Name = "Auto-Win Obby",
    CurrentValue = false,
    Flag = "MoviesAutoWinObby",
    Callback = function(Value)
        _movObby = Value
        if Value then task.spawn(function() while _movObby do
            local f = workspace.Assets:FindFirstChild("Finish", true)
            if f and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                f.CanCollide = false; f.Transparency = 1; f.Position = player.Character.HumanoidRootPart.Position
            end; task.wait(0.5)
        end end) end
    end,
})
ChallengesTab:CreateButton({
    Name = "Collect Keys & Open Chests",
    Callback = function()
        local pa = workspace.Assets:FindFirstChild("Pirate"); if not pa then return end
        local function getKey()
            for _, v in ipairs(player.Backpack:GetChildren()) do if v:IsA("Tool") then return v end end
            for _, v in ipairs(player.Character:GetChildren()) do if v:IsA("Tool") then return v end end
        end
        while true do
            local kf; for _, v in ipairs(pa:GetDescendants()) do if v.Name == "MainKey" then kf = v; break end end
            if not kf then break end
            player.Character.HumanoidRootPart.CFrame = kf.CFrame; task.wait(0.25)
            local kt, t = nil, 0
            while t < 5 and not kt do kt = getKey(); if not kt then task.wait(0.1); t = t + 0.1 end end
            if not kt then break end
            kt.Parent = player.Character; task.wait(0.05)
            local cf = pa:FindFirstChild("Chests")
            if cf then local cm = cf:FindFirstChild(kt.Name); if cm then local ch = cm:FindFirstChild("Chest"); if ch then player.Character.HumanoidRootPart.CFrame = ch.CFrame; task.wait(0.15) end end end
        end
    end,
})
local beachFightEnabled = false
local beachFightConnection = nil
ChallengesTab:CreateToggle({
    Name = "Kill Everyone In Beach Fight",
    CurrentValue = false,
    Flag = "MoviesBeachFightKill",
    Callback = function(Value)
        beachFightEnabled = Value
        if Value then
            task.spawn(function()
                while beachFightEnabled do
                    local backpack = player:FindFirstChild("Backpack")
                    local char = player.Character
                    if backpack and char then
                        local tool = nil
                        for _, t in ipairs(backpack:GetChildren()) do
                            if t:IsA("Tool") and t.Name:lower():find("pool noodle") then
                                tool = t
                                break
                            end
                        end
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if tool and humanoid then humanoid:EquipTool(tool) end
                    end
                    task.wait()
                end
            end)
            if beachFightConnection then beachFightConnection:Disconnect() end
            beachFightConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local players = game.Players:GetPlayers()
                for i = 2, #players do
                    local otherPlayer = players[i]
                    local character = otherPlayer.Character
                    if character and not player:IsFriendsWith(otherPlayer.UserId) then
                        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                        if tool and tool:FindFirstChild("Handle") then
                            tool:Activate()
                            for _, part in next, character:GetChildren() do
                                if part:IsA("BasePart") then
                                    firetouchinterest(tool.Handle, part, 0)
                                    firetouchinterest(tool.Handle, part, 1)
                                end
                            end
                        end
                    end
                end
            end)
        else
            if beachFightConnection then
                beachFightConnection:Disconnect()
                beachFightConnection = nil
            end
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Monster Godmode",
    Callback = function()
        local m = workspace.Assets:FindFirstChild("Monster"); if m then local n = m:FindFirstChild("MonsterNPC"); if n then n:Destroy() end end
    end,
})
ChallengesTab:CreateButton({
    Name = "Collect Egg",
    Callback = function()
        local RS = game:GetService("ReplicatedStorage")
        local alien = workspace.Assets:WaitForChild("Alien"); if not alien then return end
        local char = RS.Season.Players:FindFirstChild(player.Name); local cv = char and char.Value; if not cv then return end
        for _, v in pairs(alien:GetDescendants()) do
            if v.ClassName == "TextLabel" and v.Text == cv then
                local root = v.Parent.Parent.Parent; root.CFrame = player.Character.HumanoidRootPart.CFrame; root.CanCollide = false
            end
        end
    end,
})
local _alienEggESP = false
local _alienEggObjects = {}
local _alienEggConn1, _alienEggConn2, _alienEggUpdateConn
ChallengesTab:CreateToggle({
    Name = "Alien Egg ESP",
    CurrentValue = false,
    Flag = "AlienEggESP",
    Callback = function(Value)
        _alienEggESP = Value
        if Value then
            local _aeESP_COLOR = Color3.fromRGB(0, 255, 0)
            local _aeMAX_DIST = 500
            local function _createAlienEggESP(part)
                if _alienEggObjects[part] then return end
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 200, 0, 80)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = part
                bb.Parent = part
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0.5, 0)
                lbl.TextColor3 = _aeESP_COLOR
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lbl.TextSize = 28
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = "Your Alien Egg"
                lbl.Parent = bb
                local distLbl = Instance.new("TextLabel")
                distLbl.BackgroundTransparency = 1
                distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                distLbl.TextStrokeTransparency = 0
                distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                distLbl.TextSize = 22
                distLbl.Font = Enum.Font.Gotham
                distLbl.Text = ""
                distLbl.Parent = bb
                _alienEggObjects[part] = { billboard = bb, distLabel = distLbl }
            end
            local RS = game:GetService("ReplicatedStorage")
            local _aePlayerChar = RS.Season.Players:FindFirstChild(player.Name)
            local _aeCv = _aePlayerChar and _aePlayerChar.Value
            local alien = workspace.Assets:FindFirstChild("Alien")
            if alien and _aeCv then
                local seen = {}
                for _, v in pairs(alien:GetDescendants()) do
                    if v.ClassName == "TextLabel" and v.Text == _aeCv then
                        local root = v.Parent and v.Parent.Parent and v.Parent.Parent.Parent
                        if root and root:IsA("BasePart") and not seen[root] then
                            seen[root] = true
                            _createAlienEggESP(root)
                        end
                    end
                end
            end
            _alienEggConn1 = workspace.DescendantAdded:Connect(function(obj)
                if _alienEggESP and obj.ClassName == "TextLabel" then
                    local _aePC = RS.Season.Players:FindFirstChild(player.Name)
                    local _aeCv2 = _aePC and _aePC.Value
                    if obj.Text == _aeCv2 then
                        local root = obj.Parent and obj.Parent.Parent and obj.Parent.Parent.Parent
                        if root and root:IsA("BasePart") and root:FindFirstAncestor("Alien") then
                            _createAlienEggESP(root)
                        end
                    end
                end
            end)
            _alienEggConn2 = workspace.DescendantRemoving:Connect(function(obj)
                if _alienEggObjects[obj] then
                    pcall(function() _alienEggObjects[obj].billboard:Destroy() end)
                    _alienEggObjects[obj] = nil
                end
            end)
            _alienEggUpdateConn = game:GetService("RunService").RenderStepped:Connect(function()
                if not _alienEggESP then return end
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                for part, esp in pairs(_alienEggObjects) do
                    local dist = (part.Position - root.Position).Magnitude
                    esp.billboard.Enabled = dist <= _aeMAX_DIST
                    if dist <= _aeMAX_DIST then
                        esp.distLabel.Text = string.format("%.1f studs", dist)
                    end
                end
            end)
        else
            for part, esp in pairs(_alienEggObjects) do
                pcall(function() esp.billboard:Destroy() end)
            end
            _alienEggObjects = {}
            if _alienEggConn1 then _alienEggConn1:Disconnect(); _alienEggConn1 = nil end
            if _alienEggConn2 then _alienEggConn2:Disconnect(); _alienEggConn2 = nil end
            if _alienEggUpdateConn then _alienEggUpdateConn:Disconnect(); _alienEggUpdateConn = nil end
        end
    end,
})
local _ancientConn
ChallengesTab:CreateToggle({
    Name = "Auto Collect Ancient Artifacts",
    CurrentValue = false,
    Flag = "MoviesAncientArtifacts",
    Callback = function(Value)
        if Value then
            local ph = workspace.Assets:WaitForChild("Pre-Historic")
            local cf = ph and ph:WaitForChild("Coins")
            if cf then _ancientConn = cf.ChildAdded:Connect(function(coin)
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    coin.Position = player.Character.HumanoidRootPart.Position; coin.Transparency = 0; coin.CanCollide = false
                end
            end) end
        else
            if _ancientConn then _ancientConn:Disconnect(); _ancientConn = nil end
        end
    end,
})
local _mathMov = false
ChallengesTab:CreateToggle({
    Name = "Auto-Win Math Trivia",
    CurrentValue = false,
    Flag = "MoviesMathMania",
    Callback = function(Value)
        _mathMov = Value
        if not Value then return end
        task.spawn(function()
            while _mathMov do
                local assets = workspace:FindFirstChild("Assets")
                local mathManiaGui = player.PlayerGui:FindFirstChild("MathTrivia") or player.PlayerGui:FindFirstChild("MathMania")
                if mathManiaGui and assets and (assets:FindFirstChild("Math Mania") or assets:FindFirstChild("Math Trivia") or assets:FindFirstChild("Singapore")) then
                    for i = 1, 10 do
                        if not _mathMov then break end
                        local questionGui = mathManiaGui:FindFirstChild(tostring(i))
                        if questionGui then
                            local clean = questionGui.MainText.Text:gsub("=", ""):gsub("?", ""):gsub(" ", "")
                            local ok, result = pcall(function() return loadstring("return " .. clean)() end)
                            if ok and result then
                                questionGui.Box.Text = tostring(result)
                                local btn = questionGui:FindFirstChild("Enter")
                                if btn then
                                    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
                                    for _, ev in pairs(events) do
                                        if getconnections and btn[ev] then
                                            for _, c in pairs(getconnections(btn[ev])) do
                                                if c.Function then c:Fire() end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait()
            end
        end)
    end,
})
ChallengesTab:CreateButton({
    Name = "Disable Spy Challenge Lasers",
    Callback = function()
        local function disableTouchInterest(part)
            for _, v in ipairs(part:GetChildren()) do
                if v:IsA("TouchTransmitter") then
                    v:Destroy()
                end
            end
        end
        local function processModel(model)
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") and part.Name:lower():find("laser") then
                    disableTouchInterest(part)
                end
            end
        end
        processModel(workspace)
        workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("BasePart") and obj.Name:lower():find("laser") then
                task.wait()
                disableTouchInterest(obj)
            end
        end)
    end,
})
ChallengesTab:CreateButton({
    Name = "Pool Noodle Damage Amplifier",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Sword-script-damage-amplifier-110941"))()
    end,
})
local _guitarCollecting = false
ChallengesTab:CreateToggle({
    Name = "Auto Collect Guitars",
    CurrentValue = false,
    Flag = "AutoCollectGuitars",
    Callback = function(v)
        _guitarCollecting = v
        if v then
            task.spawn(function()
                while _guitarCollecting do
                    task.wait(0.00001)
                    for _, obj in pairs(workspace:GetDescendants()) do
                        if obj.Name == "Gem" then
                            obj.Transparency = 1
                            task.wait()
                            obj.Position = player.Character.Torso.Position
                        elseif obj.Name == "Coin" then
                            obj.Transparency = 1
                            task.wait()
                            obj.Position = player.Character.Torso.Position
                        end
                    end
                end
            end)
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Finish Poison Food",
    Callback = function()
        for _, v in pairs(workspace.Assets:GetDescendants()) do
            if v.Name == player.Name and v:FindFirstChild("ClickDetector") then
                for _ = 1, 80 do
                    fireclickdetector(v.ClickDetector)
                end
            end
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Break Fairytale Bridge (Part Controller)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Better-Part-controller-57507"))()
    end,
})
local raygunProtection = false
local _raygunFired = false
ChallengesTab:CreateToggle({
    Name = "Raygun Protection",
    CurrentValue = false,
    Flag = "RaygunProtection",
    Callback = function(Value)
        raygunProtection = Value
        _raygunFired = false
        if Value then
            Rayfield:Notify({ Title = "Raygun Protection", Content = "Active — will auto reset on Movies/Western round.", Duration = 4, Image = "shield" })
            task.spawn(function()
                while raygunProtection do
                    local assets = workspace:FindFirstChild("Assets")
                    if assets then
                        local hasRaygun = false
                        for _, child in ipairs(assets:GetChildren()) do
                            local n = child.Name:lower()
                            if n:find("raygun") or n:find("western") then
                                hasRaygun = true
                                break
                            end
                        end
                        if hasRaygun and not _raygunFired then
                            _raygunFired = true
                            local char = player.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum.Health = 0
                            end
                            Rayfield:Notify({ Title = "Raygun Protection", Content = "Raygun/Western detected! Auto resetting character...", Duration = 3, Image = "shield" })
                        end
                        if not hasRaygun then
                            _raygunFired = false
                        end
                    end
                    task.wait(0.3)
                end
            end)
        else
            Rayfield:Notify({ Title = "Raygun Protection", Content = "Stopped.", Duration = 3, Image = "shield" })
        end
    end,
})
local _infectAllActive = false
ChallengesTab:CreateToggle({
    Name = "Infect All",
    CurrentValue = false,
    Flag = "InfectAllMovies",
    Callback = function(Value)
        _infectAllActive = Value
        if Value then
            Rayfield:Notify({ Title = "Infect All", Content = "Active — teleporting to all players...", Duration = 3, Image = "users" })
            task.spawn(function()
                while _infectAllActive do
                    local timerVisible = false
                    pcall(function()
                        timerVisible = player.PlayerGui.Timer.Background.Timer.Visible
                    end)
                    if not timerVisible then
                        _infectAllActive = false
                        Rayfield:Notify({ Title = "Infect All", Content = "Round ended — stopped.", Duration = 3, Image = "users" })
                        break
                    end
                    local char = player.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, p in ipairs(game.Players:GetPlayers()) do
                            if p ~= player and _infectAllActive then
                                local tChar = p.Character
                                local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
                                if tHRP then
                                    hrp.CFrame = tHRP.CFrame
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                    task.wait(0.1)
                end
            end)
        else
            Rayfield:Notify({ Title = "Infect All", Content = "Stopped.", Duration = 3, Image = "users" })
        end
    end,
})
end
if isExpedition then
local _hawaiiDigAll = false
ChallengesTab:CreateToggle({
    Name = "Hawaii Dig All",
    CurrentValue = false,
    Flag = "HawaiiDigAll",
    Callback = function(Value)
        _hawaiiDigAll = Value
        if Value then
            task.spawn(function()
                while _hawaiiDigAll do
                    task.wait()
                    local Assets = workspace:FindFirstChild("Assets")
                    if Assets and Assets:FindFirstChild("Hawaii") then
                        local ReplicatedStorage = game:GetService("ReplicatedStorage")
                        for _, v in ipairs(ReplicatedStorage.Seasons.Teams:GetChildren()) do
                            if v.Value == ReplicatedStorage.Seasons.Players.LocalPlayer.team.Value then
                                local Team = v.Name
                                local diggingSpots = Assets.Hawaii.DiggingSpots:FindFirstChild(Team)
                                if diggingSpots then
                                    for _, d in ipairs(diggingSpots:GetDescendants()) do
                                        if d.Name == "ClickDetector" then
                                            for i = 1, 40 do
                                                fireclickdetector(d)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end,
})
ChallengesTab:CreateLabel("Must be in first person for aimbot to work!")
ChallengesTab:CreateButton({
    Name = "Aimbot (Meatball Challenge)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Camlock-universal-Open-source-165899"))()
    end,
})
local _arActiveExp = false
local _arFiredExp  = false
ChallengesTab:CreateToggle({
    Name = "Auto Restart Day",
    CurrentValue = false,
    Flag = "AutoRestartDayExp",
    Callback = function(Value)
        _arActiveExp = Value
        _arFiredExp  = false
        if Value then
            Rayfield:Notify({ Title = "Auto Restart Day", Content = "Active — watching for round timer...", Duration = 3, Image = "bell-ring" })
            task.spawn(function()
                while _arActiveExp do
                    local timerVisible = false
                    pcall(function()
                        timerVisible = player.PlayerGui.Timer.Background.Timer.Visible
                    end)
                    if timerVisible and not _arFiredExp then
                        _arFiredExp = true
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/robloxcheatck/reanimatescript/main/script.lua", true))()
                    end
                    if not timerVisible then
                        _arFiredExp = false
                    end
                    task.wait(0.05)
                end
            end)
        else
            Rayfield:Notify({ Title = "Auto Restart Day", Content = "Stopped.", Duration = 3, Image = "bell-ring" })
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Win Obby",
    Callback = function()
        local f = workspace.Assets:FindFirstChild("Finish", true)
        if f and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            f.CanCollide = false; f.Transparency = 1; f.Position = player.Character.HumanoidRootPart.Position
        end
    end,
})
local _expObby = false
ChallengesTab:CreateToggle({
    Name = "Auto-Win Obby",
    CurrentValue = false,
    Flag = "ExpeditionAutoWinObby",
    Callback = function(Value)
        _expObby = Value
        if Value then task.spawn(function() while _expObby do
            local f = workspace.Assets:FindFirstChild("Finish", true)
            if f and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                f.CanCollide = false; f.Transparency = 1; f.Position = player.Character.HumanoidRootPart.Position
            end; task.wait(0.5)
        end end) end
    end,
})
local _clovers = false
ChallengesTab:CreateToggle({
    Name = "Auto-Collect Clovers",
    CurrentValue = false,
    Flag = "ExpeditionClovers",
    Callback = function(Value)
        _clovers = Value
        task.spawn(function() while _clovers do task.wait(0.1)
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "Gem" or obj.Name == "Coin" then obj.Transparency = 1; obj.Position = player.Character.Torso.Position end
            end
        end end)
    end,
})
local _rings = false
ChallengesTab:CreateToggle({
    Name = "Auto-Collect Rings",
    CurrentValue = false,
    Flag = "ExpeditionRings",
    Callback = function(Value)
        _rings = Value
        task.spawn(function() while _rings do task.wait(0.1)
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "RingHitbox" then obj.Transparency = 1; obj.Position = player.Character.Torso.Position end
            end
        end end)
    end,
})
local _mathExp = false
ChallengesTab:CreateToggle({
    Name = "Auto-Win Math Mania",
    CurrentValue = false,
    Flag = "ExpeditionMathMania",
    Callback = function(Value)
        _mathExp = Value
        if not Value then return end
        task.spawn(function()
            while _mathExp do
                local assets = workspace:FindFirstChild("Assets")
                local mathManiaGui = player.PlayerGui:FindFirstChild("MathTrivia") or player.PlayerGui:FindFirstChild("MathMania")
                if mathManiaGui and assets and (assets:FindFirstChild("Math Mania") or assets:FindFirstChild("Math Trivia") or assets:FindFirstChild("Singapore")) then
                    for i = 1, 10 do
                        if not _mathExp then break end
                        local questionGui = mathManiaGui:FindFirstChild(tostring(i))
                        if questionGui then
                            local clean = questionGui.MainText.Text:gsub("=", ""):gsub("?", ""):gsub(" ", "")
                            local ok, result = pcall(function() return loadstring("return " .. clean)() end)
                            if ok and result then
                                questionGui.Box.Text = tostring(result)
                                local btn = questionGui:FindFirstChild("Enter")
                                if btn then
                                    local events = {"MouseButton1Click", "MouseButton1Down", "Activated"}
                                    for _, ev in pairs(events) do
                                        if getconnections and btn[ev] then
                                            for _, c in pairs(getconnections(btn[ev])) do
                                                if c.Function then c:Fire() end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait()
            end
        end)
    end,
})
ChallengesTab:CreateButton({
    Name = "Auto Win Cheese Push",
    Callback = function()
        local player = game:GetService("Players").LocalPlayer
        local character = player.Character
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local myPos = rootPart.Position
        local closestCheese = nil
        local closestCheeseDist = math.huge
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name == "Cheese" then
                local pivot = v:GetPivot().Position
                local dist = (pivot - myPos).Magnitude
                if dist < closestCheeseDist then
                    closestCheeseDist = dist
                    closestCheese = v
                end
            end
        end
        local closestHitbox = nil
        local closestHitboxDist = math.huge
        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "Hitbox" and v:IsA("BasePart") then
                local dist = (v.Position - myPos).Magnitude
                if dist < closestHitboxDist then
                    closestHitboxDist = dist
                    closestHitbox = v
                end
            end
        end
        if not closestCheese then
            Rayfield:Notify({ Title = "Error", Content = "No Cheese found!", Duration = 3 })
            return
        end
        if not closestHitbox then
            Rayfield:Notify({ Title = "Error", Content = "No Hitbox found!", Duration = 3 })
            return
        end
        for _, part in ipairs(closestCheese:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Anchored = false
                part.CFrame = CFrame.new(closestHitbox.Position)
            end
        end
        Rayfield:Notify({ Title = "Cheese Push", Content = "Cheese teleported to hitbox!", Duration = 3 })
    end
})
local greeceKillEnabled = false
local greeceKillConnection = nil
ChallengesTab:CreateToggle({
    Name = "Kill Everyone in Greece",
    CurrentValue = false,
    Flag = "ExpeditionGreeceKill",
    Callback = function(Value)
        greeceKillEnabled = Value
        if Value then
            task.spawn(function()
                while greeceKillEnabled do
                    local backpack = player:FindFirstChild("Backpack")
                    local char = player.Character
                    if backpack and char then
                        local tool = nil
                        for _, t in ipairs(backpack:GetChildren()) do
                            if t:IsA("Tool") and t.Name:lower():find("sword") then
                                tool = t
                                break
                            end
                        end
                        local humanoid = char:FindFirstChildOfClass("Humanoid")
                        if tool and humanoid then humanoid:EquipTool(tool) end
                    end
                    task.wait()
                end
            end)
            if greeceKillConnection then greeceKillConnection:Disconnect() end
            greeceKillConnection = game:GetService("RunService").RenderStepped:Connect(function()
                local players = game.Players:GetPlayers()
                for i = 2, #players do
                    local otherPlayer = players[i]
                    local character = otherPlayer.Character
                    if character and not player:IsFriendsWith(otherPlayer.UserId) then
                        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                        if tool and tool:FindFirstChild("Handle") then
                            tool:Activate()
                            for _, part in next, character:GetChildren() do
                                if part:IsA("BasePart") then
                                    firetouchinterest(tool.Handle, part, 0)
                                    firetouchinterest(tool.Handle, part, 1)
                                end
                            end
                        end
                    end
                end
            end)
        else
            if greeceKillConnection then
                greeceKillConnection:Disconnect()
                greeceKillConnection = nil
            end
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Break Amazon (Spleef)",
    Callback = function()
        for _, v in pairs(workspace.Assets:GetDescendants()) do
            if v.Name == "SpleefPart" then firetouchinterest(player.Character.HumanoidRootPart, v, 0) end
        end
    end,
})
local _germanAlpsESP = false
local _germanAlpsObjects = {}
local _germanAlpsConn1, _germanAlpsConn2, _germanAlpsUpdateConn
ChallengesTab:CreateToggle({
    Name = "German Alps ESP",
    CurrentValue = false,
    Flag = "GermanAlpsESP",
    Callback = function(Value)
        _germanAlpsESP = Value
        if Value then
            local _gaESP_COLOR = Color3.fromRGB(0, 255, 0)
            local _gaMAX_DIST = 500
            local function _createGermanAlpsESP(part)
                if _germanAlpsObjects[part] then return end
                local bb = Instance.new("BillboardGui")
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 200, 0, 80)
                bb.StudsOffset = Vector3.new(0, 3, 0)
                bb.Adornee = part
                bb.Parent = part
                local lbl = Instance.new("TextLabel")
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.new(1, 0, 0.5, 0)
                lbl.TextColor3 = _gaESP_COLOR
                lbl.TextStrokeTransparency = 0
                lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                lbl.TextSize = 28
                lbl.Font = Enum.Font.GothamBold
                lbl.Text = "🏁 FINISH"
                lbl.Parent = bb
                local distLbl = Instance.new("TextLabel")
                distLbl.BackgroundTransparency = 1
                distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                distLbl.TextStrokeTransparency = 0
                distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                distLbl.TextSize = 22
                distLbl.Font = Enum.Font.Gotham
                distLbl.Text = ""
                distLbl.Parent = bb
                _germanAlpsObjects[part] = { billboard = bb, distLabel = distLbl }
            end
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower() == "finish" then
                    _createGermanAlpsESP(obj)
                end
            end
            _germanAlpsConn1 = workspace.DescendantAdded:Connect(function(obj)
                if _germanAlpsESP and obj:IsA("BasePart") and obj.Name:lower() == "finish" then
                    _createGermanAlpsESP(obj)
                end
            end)
            _germanAlpsConn2 = workspace.DescendantRemoving:Connect(function(obj)
                if _germanAlpsObjects[obj] then
                    pcall(function() _germanAlpsObjects[obj].billboard:Destroy() end)
                    _germanAlpsObjects[obj] = nil
                end
            end)
            _germanAlpsUpdateConn = game:GetService("RunService").RenderStepped:Connect(function()
                if not _germanAlpsESP then return end
                local char = player.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                for part, esp in pairs(_germanAlpsObjects) do
                    local dist = (part.Position - root.Position).Magnitude
                    esp.billboard.Enabled = dist <= _gaMAX_DIST
                    if dist <= _gaMAX_DIST then
                        esp.distLabel.Text = string.format("%.1f studs", dist)
                    end
                end
            end)
        else
            for part, esp in pairs(_germanAlpsObjects) do
                pcall(function() esp.billboard:Destroy() end)
            end
            _germanAlpsObjects = {}
            if _germanAlpsConn1 then _germanAlpsConn1:Disconnect(); _germanAlpsConn1 = nil end
            if _germanAlpsConn2 then _germanAlpsConn2:Disconnect(); _germanAlpsConn2 = nil end
            if _germanAlpsUpdateConn then _germanAlpsUpdateConn:Disconnect(); _germanAlpsUpdateConn = nil end
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Greece Damage Amplifier",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Sword-script-damage-amplifier-110941"))()
    end,
})
local meatballProtection = false
local _meatballFired = false
ChallengesTab:CreateToggle({
    Name = "Meatball Protection",
    CurrentValue = false,
    Flag = "MeatballProtection",
    Callback = function(Value)
        meatballProtection = Value
        _meatballFired = false
        if Value then
            Rayfield:Notify({ Title = "Meatball Protection", Content = "Active — will auto reset on Dodgeball or Paintball round.", Duration = 4, Image = "shield" })
            task.spawn(function()
                while meatballProtection do
                    local assets = workspace:FindFirstChild("Assets")
                    if assets then
                        local hasMeatball = false
                        for _, child in ipairs(assets:GetChildren()) do
                            local n = child.Name:lower()
                            if n:find("dodgeball") or n:find("paintball") or n:find("meatball") then
                                hasMeatball = true
                                break
                            end
                        end
                        if hasMeatball and not _meatballFired then
                            _meatballFired = true
                            local char = player.Character
                            local hum = char and char:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum.Health = 0
                            end
                            Rayfield:Notify({ Title = "Meatball Protection", Content = "Detected! Auto resetting character...", Duration = 3, Image = "shield" })
                        end
                        if not hasMeatball then
                            _meatballFired = false
                        end
                    end
                    task.wait(0.3)
                end
            end)
        else
            Rayfield:Notify({ Title = "Meatball Protection", Content = "Stopped.", Duration = 3, Image = "shield" })
        end
    end,
})
ChallengesTab:CreateButton({
    Name = "Finish China Food",
    Callback = function()
        for _, v in pairs(workspace.Assets:GetDescendants()) do
            if v.Name == player.Name and v:FindFirstChild("ClickDetector") then
                for _ = 1, 80 do
                    fireclickdetector(v.ClickDetector)
                end
            end
        end
    end,
})
end
UniversalTab:CreateSection("Universal")
UniversalTab:CreateButton({
    Name = "Open Console",
    Callback = function()
        game:GetService('StarterGui'):SetCore('DevConsoleVisible', true)
    end,
})
UniversalTab:CreateButton({
    Name = "Instant Respawn",
    Callback = function()
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end,
})
UniversalTab:CreateButton({
    Name = "Fake Lag",
    Callback = function()
        local ScreenGui = Instance.new("ScreenGui")
        local Frame = Instance.new("Frame")
        local Frame_2 = Instance.new("Frame")
        local TextLabel = Instance.new("TextLabel")
        local TextButton = Instance.new("TextButton")
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.ResetOnSpawn = false
        Frame.Parent = ScreenGui
        Frame.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
        Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame.BorderSizePixel = 0
        Frame.Position = UDim2.new(0.388539821, 0, 0.427821517, 0)
        Frame.Size = UDim2.new(0, 158, 0, 100)
        Frame_2.Parent = Frame
        Frame_2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Frame_2.BorderSizePixel = 0
        Frame_2.Size = UDim2.new(0, 158, 0, 25)
        TextLabel.Parent = Frame_2
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.BackgroundTransparency = 1.000
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.BorderSizePixel = 0
        TextLabel.Position = UDim2.new(0.112792775, 0, -0.0151660154, 0)
        TextLabel.Size = UDim2.new(0, 121, 0, 26)
        TextLabel.Font = Enum.Font.Sarpanch
        TextLabel.Text = "Fake Lag"
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextSize = 16.000
        TextButton.Parent = Frame
        TextButton.BackgroundColor3 = Color3.fromRGB(205, 84, 75)
        TextButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
        TextButton.BorderSizePixel = 0
        TextButton.Position = UDim2.new(0.113924049, 0, 0.4, 0)
        TextButton.Size = UDim2.new(0, 121, 0, 37)
        TextButton.Font = Enum.Font.SourceSansItalic
        TextButton.Text = "Enable"
        TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        TextButton.TextSize = 20.000
        local fakeLagEnabled = false
        local fakeLagThread
        local function toggleFakeLag()
            local lp = game:GetService("Players").LocalPlayer
            while fakeLagEnabled do
                task.wait()
                local character = lp.Character
                if character then
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Anchored = true
                        task.wait(0.2)
                        hrp.Anchored = false
                        task.wait()
                    end
                end
            end
        end
        TextButton.MouseButton1Click:Connect(function()
            fakeLagEnabled = not fakeLagEnabled
            TextButton.Text = fakeLagEnabled and "Enabled" or "Enable"
            if fakeLagEnabled then
                fakeLagThread = coroutine.create(toggleFakeLag)
                coroutine.resume(fakeLagThread)
            end
        end)
        Frame.Active = true
        Frame.Draggable = true
    end,
})
UniversalTab:CreateButton({
    Name = "Mobile Lag Jump",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Mobile-lag-jump-for-r6-glitches-48710"))()
    end,
})
UniversalTab:CreateButton({
    Name = "PC Freeze Glitch",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Mobile-lag-jump-for-r6-glitches-48710"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Energize",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/Cfeu2ZPc"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Fly V3",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Sound Panel",
    Callback = function()
        loadstring(game:HttpGet("https://pastebin.com/raw/w3uzjgEq"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Fake Wallhop",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Utlimate-WallHop-Obby-BEST-FAKE-WALLHOP-SCRIPT-45056"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Shaders",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-PShade-Ultimate-not-made-by-me-138315"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Ladder Flick Macro (Re-Execute if You Died)",
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-ladder-flicking-macro-execute-again-if-you-died-53200"))()
    end,
})
UniversalTab:CreateButton({
    Name = "Hug People",
    Callback = function()
        loadstring(game:HttpGet("https://pastefy.app/fhUzn6vQ/raw"))()
    end,
})
do
    local _Players = game:GetService("Players")
    local _LocalPlayer = _Players.LocalPlayer
    local _hideEnabled = false
    local _playerConns = {}
    local function _isFriend(p)
        return _LocalPlayer:IsFriendsWith(p.UserId)
    end
    local function _hideChar(char)
        for _, obj in pairs(char:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then
                obj.Transparency = 1
            elseif obj:IsA("BillboardGui") then
                obj.Enabled = false
            end
        end
    end
    local function _showChar(char)
        for _, obj in pairs(char:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Decal") then
                if obj.Name == "HumanoidRootPart" then
                    obj.Transparency = 1
                else
                    obj.Transparency = 0
                end
            elseif obj:IsA("BillboardGui") then
                obj.Enabled = true
            end
        end
    end
    local function _applyToPlayer(p)
        if p == _LocalPlayer then return end
        if _hideEnabled and not _isFriend(p) then
            if p.Character then _hideChar(p.Character) end
        else
            if p.Character then _showChar(p.Character) end
        end
    end
    local function _updateAll()
        for _, p in pairs(_Players:GetPlayers()) do
            _applyToPlayer(p)
        end
    end
    UniversalTab:CreateToggle({
        Name = "Hide All Players (Except Friends)",
        CurrentValue = false,
        Flag = "HideNonFriendsMain",
        Callback = function(state)
            _hideEnabled = state
            _updateAll()
            if state then
                _playerConns["added"] = _Players.PlayerAdded:Connect(function(p)
                    local c = p.CharacterAdded:Connect(function(char)
                        if _hideEnabled and not _isFriend(p) then
                            _hideChar(char)
                        end
                    end)
                    _playerConns["char_" .. p.UserId] = c
                    _applyToPlayer(p)
                end)
            else
                for k, conn in pairs(_playerConns) do
                    if typeof(conn) == "RBXScriptConnection" then
                        conn:Disconnect()
                    end
                    _playerConns[k] = nil
                end
                _updateAll()
            end
        end,
    })
end
local function vipOnly(callback)
    if isAdmin then
        callback()
    else
        Rayfield:Notify({
            Title = "VIP Only",
            Content = "Sorry, you can't use this! Join the Discord for more info.",
            Duration = 5,
            Image = "lock",
        })
    end
end
if isAdmin then
    VIPTab:CreateSection("Admin")
    VIPTab:CreateLabel("Welcome, " .. game.Players.LocalPlayer.Name .. ". You are whitelisted.")
    VIPTab:CreateLabel(":kick [name/all] - Kicks the player")
    VIPTab:CreateLabel(":ban [name/all] [reason] - Bans the player")
    VIPTab:CreateLabel(":kill [name/all] - Kills the player")
    VIPTab:CreateLabel(":freeze [name/all] - Freezes the player")
    VIPTab:CreateLabel(":unfreeze [name/all] - Unfreezes the player")
    VIPTab:CreateLabel(":void [name/all] - Sends player to the void")
    VIPTab:CreateLabel(":bring [name/all] - Brings player to you")
    VIPTab:CreateLabel(":fling [name/all] - Flings the player")
    VIPTab:CreateLabel(":clown [name/all] - Kidnaps and teleports the player")
    VIPTab:CreateButton({
        Name = "Admin Panel Broken (In Beta)",
        Callback = function()
            local player = game.Players.LocalPlayer
            local rs = game:GetService("ReplicatedStorage")
            local gui = rs:WaitForChild("Products"):WaitForChild("GUIs"):WaitForChild("Settings"):Clone()
            gui.Parent = player:WaitForChild("PlayerGui")
            gui.Enabled = true
            for _, v in pairs(gui:GetDescendants()) do
                if v:IsA("Frame") or v:IsA("TextLabel") or v:IsA("ImageLabel") then
                    v.Visible = true
                end
                if v:IsA("TextButton") or v:IsA("ImageButton") then
                    v.Visible = true
                    v.Active = true
                end
            end
        end,
    })
        VIPTab:CreateToggle({
        Name = "FPS Bounce",
        CurrentValue = false,
        Flag = "FpsBounce",
        Callback = function(Value)
            _G._FpsBounceEnabled = Value
        end,
    })
    VIPTab:CreateSection("Shortcuts")
    VIPTab:CreateButton({
        Name = "Lag High Jump",
        Callback = function()
            dolaghighjump()
        end,
    })
    VIPTab:CreateButton({
        Name = "Floor Bounce",
        Callback = function()
            doFloorBounce()
        end,
    })
else
    VIPTab:CreateLabel("This tab is for whitelisted users only.")
    VIPTab:CreateLabel("Join the Discord for more information.")
end

local lPlayer = game.Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Rank Validation
for user, rank in pairs(_DW_PERMS or {}) do
    local r = string.lower(tostring(rank))
    if r ~= "owner" and r ~= "admin" and r ~= "none" then
        lPlayer:Kick("Security Error: Invalid Rank detected.")
    end
end

local function getRank(name)
    return string.lower(_DW_PERMS[name:lower()] or "none")
end

local function isAdmin(name)
    local r = getRank(name)
    return r == "admin" or r == "owner"
end

local function isOwner(name)
    return getRank(name) == "owner"
end

local function nameMatches(target)
    local t = target:lower()
    if t == "all" then return true end
    if t == "me" or t == "self" then return lPlayer.Name:lower() == target:lower() end
    return string.find(lPlayer.Name:lower(), t, 1, true) ~= nil
end

local loopKillActive = {}

local function handleCommand(senderName, message)
    local command, argString = message:match("^:(%w+)%s*(.*)")
    if not command or not isAdmin(senderName) then return end
    
    command = command:lower()
    local targetName, param = (argString or ""):match("^(%S+)%s*(.*)$")
    if not targetName or not nameMatches(targetName) then return end

    if isOwner(lPlayer.Name) and not isOwner(senderName) then return end

    if command == "kick" then
        lPlayer:Kick("Kicked by " .. senderName)

    elseif command == "kill" then
        if lPlayer.Character and lPlayer.Character:FindFirstChild("Humanoid") then
            lPlayer.Character.Humanoid.Health = 0
        end

    elseif command == "clown" then
        task.spawn(function()
            local _TeleportService = game:GetService("TeleportService")
            local _Lighting = game:GetService("Lighting")
            local char = lPlayer.Character
            if not char then return end
            
            local root = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not root or not hum then return end

            local CLOWN_ASSET, CLOWN_GAME, DRIVE_TIME = "rbxassetid://3544143040", 16383449985, 5
            local ok, objects = pcall(function() return game:GetObjects(CLOWN_ASSET) end)
            if not ok or not objects[1] then return end

            local vanModel = objects[1]
            vanModel.Parent = workspace
            local mainPart = vanModel.PrimaryPart or vanModel:FindFirstChildWhichIsA("BasePart")
            
            for _, p in pairs(vanModel:GetDescendants()) do
                if p:IsA("BasePart") then p.Anchored, p.CanCollide = true, false end
            end

            local startCF = CFrame.new(root.Position) * CFrame.lookAt(Vector3.zero, Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z))
            vanModel:PivotTo(startCF)
            hum.PlatformStand = true
            root.CFrame = startCF * CFrame.new(0, 2, 3)

            local weld = Instance.new("WeldConstraint", mainPart)
            weld.Part0, weld.Part1 = mainPart, root

            local driveGoal = startCF * CFrame.new(0, 0, -300)
            local startClock, startTime = _Lighting.ClockTime, tick()

            while tick() - startTime < DRIVE_TIME do
                local alpha = (tick() - startTime) / DRIVE_TIME
                vanModel:PivotTo(startCF:Lerp(driveGoal, alpha))
                _Lighting.ClockTime = startClock + (0 - startClock) * alpha
                task.wait()
            end
            pcall(function() _TeleportService:Teleport(CLOWN_GAME, lPlayer) end)
        end)

    end
end

local function connectChat(p)
    p.Chatted:Connect(function(msg) handleCommand(p.Name, msg) end)
end

Players.PlayerAdded:Connect(connectChat)
for _, p in ipairs(Players:GetPlayers()) do connectChat(p) end

local tcs = game:GetService("TextChatService")
if tcs.MessageReceived then
    tcs.MessageReceived:Connect(function(msg)
        if msg.TextSource then handleCommand(msg.TextSource.Name, msg.Text) end
    end)
end

DiscordTab:CreateSection("Team")
DiscordTab:CreateLabel("kcf8")
DiscordTab:CreateLabel("calfully")
DiscordTab:CreateLabel("dbgrispresent")
DiscordTab:CreateSection("Community")
DiscordTab:CreateSection("Update Log")
DiscordTab:CreateLabel("- NSFW tab removed from admin to comply with ScriptBlox's rules and regulations.")
DiscordTab:CreateLabel("Contact us on Discord for bug reports, suggestions, or general support!")
DiscordTab:CreateButton({
    Name = "Join Our Discord",
    Callback = function()
        setclipboard("https://discord.gg/rQnFrKYz7")
        Rayfield:Notify({
            Title = "Discord Invite",
            Content = "Join us! 🔗 discord.gg/rQnFrKYz7 — copied to clipboard!",
            Duration = 6,
            Image = "message-circle",
        })
    end,
})
task.delay(3.5, function()
    Rayfield:Notify({
        Title = "Join Our Discord! 🎉",
        Content = "Come hang out — discord.gg/rQnFrKYz7",
        Duration = 7,
        Image = "message-circle",
    })
end)
task.delay(2, function()
    local autoName = DW_GetAutoLoad()
    if autoName then
        local ok = DW_LoadConfig(autoName)
        if ok then
            Rayfield:Notify({
                Title = "Config Auto-Loaded",
                Content = 'Loaded config: "' .. autoName .. '"',
                Duration = 5,
                Image = "settings",
            })
        else
            Rayfield:Notify({
                Title = "Auto-Load Failed",
                Content = 'Config "' .. autoName .. '" was not found. Check the config name.',
                Duration = 5,
                Image = "alert-circle",
            })
        end
    end
end)