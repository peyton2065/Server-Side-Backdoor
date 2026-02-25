--[[
██╗  ██╗███████╗███╗   ██╗ ██████╗ 
╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
 ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
 ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

XENO | Universal Server-Side Framework v4.0
Production Build — Batch Validated Fingerprint Engine

▸ BATCH FIRE validation (30x faster scanning)
▸ Concurrent remote testing
▸ Quick Scan (priority only) + Deep Scan modes
▸ 33 RE + 10 RF Fire Patterns
▸ 14 Fingerprint Profiles (incl. Lalol Hub)
▸ 100+ Known Backdoor Name Signatures
▸ 40+ Server-Side Admin Commands
▸ Glassmorphism UI w/ Animated Tabs
▸ Require + URL Loader + Script Hub
▸ Player Management + Server Toolkit
▸ Toast Notifications + Command History
▸ Scan Timer + Performance Stats
▸ Keybind: RightShift to Toggle
]]

-- ═══════════════════════════════════════════════════
--  1 · CONFIGURATION
-- ═══════════════════════════════════════════════════

local CFG = {
    Name           = "XENO",
    Version        = "4.0.0",
    Prefix         = ";",
    ToggleKey      = Enum.KeyCode.RightShift,
    
    -- Scan speed settings
    BatchWait      = 0.45,   -- wait after batch-firing all patterns (was 0.65 × 33)
    ConcurrentMax  = 4,      -- test this many remotes simultaneously
    
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
local Mouse     = LP:GetMouse()

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
    for _, child in ipairs(kids or {}) do
        child.Parent = inst
    end
    if parent then inst.Parent = parent end
    return inst
end

function U.tween(inst, goal, dur, style, dir)
    local tw = TweenSvc:Create(inst,
        TweenInfo.new(dur or 0.28, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        goal)
    tw:Play()
    return tw
end

function U.findPlayers(query)
    if not query or query == "" then query = "me" end
    query = query:lower()
    if query == "me"     then return {LP} end
    if query == "all"    then return Players:GetPlayers() end
    if query == "others" then
        local t = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then t[#t+1] = p end
        end
        return t
    end
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower():sub(1, #query) == query
        or p.DisplayName:lower():sub(1, #query) == query then
            t[#t+1] = p
        end
    end
    return t
end

function U.uid()
    return Http:GenerateGUID(false):sub(1, 8)
end

function U.marker()
    return "XV_" .. math.random(100000, 999999)
end

function U.clock()
    return tick()
end

-- ═══════════════════════════════════════════════════
--  4 · BACKDOOR ENGINE — BATCH VALIDATED + LALOL HUB
-- ═══════════════════════════════════════════════════

local BD = {
    active     = nil,
    scanning   = false,
    confirmed  = {},
    tested     = {},
    scanStats  = {remotesScanned = 0, timeElapsed = 0, patternsTotal = 0},
}

-- ┌─────────────────────────────────────────────────┐
-- │  EXACT NAME SIGNATURES (100+)                   │
-- │  Hydrogen, ServerCrusher, Aztup, Nihon,         │
-- │  JEBI, Nexus, Dansploit, Owl Hub, IY SS,        │
-- │  Backdoor.exe, Lalol Hub + generics             │
-- └─────────────────────────────────────────────────┘

BD.exactNames = {
    "Backdoor","backdoor","BACKDOOR",
    "Execute","execute","EXECUTE",
    "MainEvent","mainEvent","mainevent",
    "ServerEvent","serverevent",
    "Handler","handler","Bridge","bridge",

    -- Hydrogen SS
    "Hydrogen","HydrogenEvent","H_Event","HydrogenRemote","H_RE",

    -- ServerCrusher
    "Crusher","CrusherEvent","SC_Event","ServerCrusher",

    -- Aztup Hub
    "AztupEvent","Aztup","AztupRemote",

    -- Nihon SS
    "NihonEvent","Nihon","NH_Event",

    -- JEBI SS
    "JEBIEvent","JEBI","JebiRemote",

    -- Nexus SS
    "NexusEvent","Nexus","NX_Event",

    -- Dansploit SS
    "DansEvent","Dansploit","DAN_RE",

    -- Owl Hub SS
    "OwlEvent","OwlRemote","OWL_SS",

    -- IY SS
    "IYEvent","IY_SS","InfYield",

    -- Backdoor.exe
    "BDEvent","BD_Exec","BDRemote",

    -- ★ Lalol Hub ★
    "LalolEvent","Lalol","LALOL","lalol",
    "LalolRemote","LH_Event","LH_RE",
    "LalolHub","lalolhub","LALOLHUB",
    "LalolExec","Lalol_Event","Lalol_Remote",
    "LalolBridge","LalolGate","LalolSS",
    "lalol_event","lalol_exec","lh_exec",
    "LaLol","LaLolEvent","LaLolRemote",
    "LaLolHub","LaLolExec","LaLolBridge",

    -- Single char
    "e","r","f","x","a","b","c","d",
    "E","R","F","X","A","B","C","D",

    -- Short combos
    "re","ev","fe","rf","xe","rx",
    "RE","EV","FE","RF",
    "lol","abc","xyz","hi","ok","gg",
    "LOL","ABC","XYZ",
    "aaa","bbb","eee","rrr",

    -- Generic free model
    "Event","RemoteEvent","Remote",
    "Fire","fire","Run","run",
    "Comm","comm","Network","network",
    "Gate","gate","Relay","relay",
    "Hook","hook","Main","main",
    "Load","load","Source","source",
    "Exec","exec","Code","code",
    "ServerRemote","ClientToServer",
    "Communicate","Signal","signal",
    "Tunnel","tunnel","Pipe","pipe",
    "Link","link","Socket","socket",
    "Channel","channel",

    -- Numeric / hex
    "1","2","3","69","420","1337","666",
    "0x1","0x2","0xFF",

    -- Blank / weird
    ""," ","  ",".",
}

BD.namePatterns = {
    "backdoor","backd00r","b4ckd00r",
    "execut","loadstr","loadstring",
    "server.*event","remote.*event",
    "hydrogen","crusher","aztup",
    "nihon","jebi","nexus","dansploit",
    "owl.*hub","owl.*ss",
    "lalol","la_lol","lh_",          -- ★ Lalol patterns ★
    "ss.*event","ss.*remote",
    "serversid","server_side",
    "admin.*event","admin.*remote",
    "exploit","hack","cheat",
    "inject","payload",
    "cmd","command",
    "require.*event","require.*remote",
    "free.*model","fm.*event",
}

-- ┌─────────────────────────────────────────────────┐
-- │  FIRE PATTERNS (33 RE + 10 RF)                  │
-- └─────────────────────────────────────────────────┘

BD.patterns = {
    {name = "Raw String",         fn = function(r, c) r:FireServer(c) end},
    {name = "Table {Code=}",      fn = function(r, c) r:FireServer({Code = c}) end},
    {name = "Table {code=}",      fn = function(r, c) r:FireServer({code = c}) end},
    {name = "Table {Source=}",    fn = function(r, c) r:FireServer({Source = c}) end},
    {name = "Table {source=}",    fn = function(r, c) r:FireServer({source = c}) end},
    {name = "Table {Src=}",       fn = function(r, c) r:FireServer({Src = c}) end},
    {name = "Table {cmd=}",       fn = function(r, c) r:FireServer({cmd = c}) end},
    {name = '"execute", code',    fn = function(r, c) r:FireServer("execute", c) end},
    {name = '"run", code',        fn = function(r, c) r:FireServer("run", c) end},
    {name = '"exec", code',       fn = function(r, c) r:FireServer("exec", c) end},
    {name = '"load", code',       fn = function(r, c) r:FireServer("load", c) end},
    {name = '"loadstring", c',    fn = function(r, c) r:FireServer("loadstring", c) end},
    {name = '"code", code',       fn = function(r, c) r:FireServer("code", c) end},
    {name = '"cmd", code',        fn = function(r, c) r:FireServer("cmd", c) end},
    {name = '"", code',           fn = function(r, c) r:FireServer("", c) end},
    {name = "nil, code",          fn = function(r, c) r:FireServer(nil, c) end},
    {name = "Table {[1]=code}",   fn = function(r, c) r:FireServer({c}) end},
    {name = '{code, "execute"}',  fn = function(r, c) r:FireServer({c, "execute"}) end},
    {name = '"admin", code',      fn = function(r, c) r:FireServer("admin", c) end},
    {name = '"owner", code',      fn = function(r, c) r:FireServer("owner", c) end},
    {name = '"pass", code',       fn = function(r, c) r:FireServer("pass", c) end},
    {name = '"key", code',        fn = function(r, c) r:FireServer("key", c) end},
    {name = '"debug", code',      fn = function(r, c) r:FireServer("debug", c) end},
    {name = "true, code",         fn = function(r, c) r:FireServer(true, c) end},
    {name = "false, code",        fn = function(r, c) r:FireServer(false, c) end},
    {name = "Player, code",       fn = function(r, c) r:FireServer(Players.LocalPlayer, c) end},
    {name = "UserId, code",       fn = function(r, c) r:FireServer(Players.LocalPlayer.UserId, c) end},
    {name = '"ss","exec",code',   fn = function(r, c) r:FireServer("ss", "execute", c) end},
    {name = '"server", code',     fn = function(r, c) r:FireServer("server", c) end},
    {name = "1, code",            fn = function(r, c) r:FireServer(1, c) end},
    {name = "0, code",            fn = function(r, c) r:FireServer(0, c) end},
    {name = "69, code",           fn = function(r, c) r:FireServer(69, c) end},
    {name = "420, code",          fn = function(r, c) r:FireServer(420, c) end},
    -- ★ Lalol Hub specific patterns ★
    {name = '"lalol", code',      fn = function(r, c) r:FireServer("lalol", c) end},
    {name = '{Type="lalol",Code=}', fn = function(r, c) r:FireServer({Type = "lalol", Code = c}) end},
}

BD.rfPatterns = {
    {name = "Raw String",         fn = function(r, c) return r:InvokeServer(c) end},
    {name = "Table {Code=}",      fn = function(r, c) return r:InvokeServer({Code = c}) end},
    {name = "Table {code=}",      fn = function(r, c) return r:InvokeServer({code = c}) end},
    {name = "Table {Source=}",    fn = function(r, c) return r:InvokeServer({Source = c}) end},
    {name = '"execute", code',    fn = function(r, c) return r:InvokeServer("execute", c) end},
    {name = '"", code',           fn = function(r, c) return r:InvokeServer("", c) end},
    {name = "nil, code",          fn = function(r, c) return r:InvokeServer(nil, c) end},
    {name = "Table {[1]=code}",   fn = function(r, c) return r:InvokeServer({c}) end},
    {name = "true, code",         fn = function(r, c) return r:InvokeServer(true, c) end},
    {name = "Player, code",       fn = function(r, c) return r:InvokeServer(Players.LocalPlayer, c) end},
    -- ★ Lalol Hub RF
    {name = '"lalol", code (RF)', fn = function(r, c) return r:InvokeServer("lalol", c) end},
}

-- ┌─────────────────────────────────────────────────┐
-- │  FINGERPRINT ENGINE (14 profiles)               │
-- └─────────────────────────────────────────────────┘

BD.fingerprints = {
    {
        name = "Hydrogen SS",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("hydrogen") or n:find("h_") then return true end
            if patternName == "Table {Code=}" and remote:IsDescendantOf(RS) then return true end
            return false
        end,
    },
    {
        name = "ServerCrusher",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("crush") or n:find("sc_") then return true end
            if (patternName == '"", code' or patternName == "nil, code") and #remote.Name <= 3 then return true end
            return false
        end,
    },
    {
        name = "Aztup Hub",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("aztup") then return true end
            if patternName == '"execute", code' and n:find("event") then return true end
            return false
        end,
    },
    {
        name = "Nihon SS",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("nihon") or n:find("nh_") then return true end
            if patternName == "Table {[1]=code}" then return true end
            return false
        end,
    },
    {
        name = "JEBI SS",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("jebi") then return true end
            if patternName == "Player, code" or patternName == "UserId, code" then return true end
            return false
        end,
    },
    {
        name = "Nexus SS",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("nexus") or n:find("nx_") then return true end
            return false
        end,
    },
    {
        name = "Dansploit SS",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("dans") or n:find("dan_") then return true end
            if patternName == '"ss","exec",code' then return true end
            return false
        end,
    },
    {
        name = "Owl Hub SS",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("owl") then return true end
            return false
        end,
    },
    {
        name = "IY SS Variant",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("iy") or n:find("infyield") or n:find("infinite") then return true end
            return false
        end,
    },
    {
        name = "Backdoor.exe",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("bd_") or n:find("bdexec") or n:find("bdevent") then return true end
            return false
        end,
    },
    -- ★ LALOL HUB FINGERPRINT ★
    {
        name = "Lalol Hub",
        check = function(remote, patternName)
            local n = remote.Name:lower()
            if n:find("lalol") or n:find("la_lol") then return true end
            if n:find("lh_") or n:find("lh_event") or n:find("lh_exec") then return true end
            if patternName and (patternName:find("lalol") or patternName:find("Lalol")) then return true end
            -- Lalol Hub uses specific table patterns
            if patternName == '{Type="lalol",Code=}' then return true end
            if patternName == '"lalol", code' then return true end
            if patternName == '"lalol", code (RF)' then return true end
            return false
        end,
    },
    {
        name = "Password Protected",
        check = function(remote, patternName)
            if patternName and (patternName:find('"admin"') or patternName:find('"owner"')
                or patternName:find('"pass"') or patternName:find('"key"')
                or patternName:find('"debug"')) then
                return true
            end
            return false
        end,
    },
    {
        name = "Classic Free Model",
        check = function(remote, patternName)
            if patternName == "Raw String" then
                local n = remote.Name:lower()
                if #remote.Name <= 3 or n:find("event") or n:find("remote") then
                    return true
                end
            end
            return false
        end,
    },
    {
        name = "Obfuscated Backdoor",
        check = function(remote, patternName)
            local n = remote.Name
            if n:match("^%x+$") and #n >= 6 then return true end
            if #n > 20 then return true end
            return false
        end,
    },
}

function BD:fingerprint(remote, patternName)
    for _, fp in ipairs(self.fingerprints) do
        local ok, result = pcall(fp.check, remote, patternName)
        if ok and result then return fp.name end
    end
    return "Unknown Type"
end

-- ┌─────────────────────────────────────────────────┐
-- │  SMART REMOTE GATHERING (4-tier priority)       │
-- └─────────────────────────────────────────────────┘

function BD:gatherRemotes()
    local priority1 = {}
    local priority2 = {}
    local priority3 = {}
    local priority4 = {}

    local exactSet = {}
    for _, name in ipairs(self.exactNames) do
        exactSet[name] = true
    end

    local allContainers = {}
    local addedSet = {}
    local function tryAdd(svcName)
        pcall(function()
            local s = game:GetService(svcName)
            if s and not addedSet[s] then
                allContainers[#allContainers+1] = s
                addedSet[s] = true
            end
        end)
    end

    tryAdd("ReplicatedStorage")
    tryAdd("Workspace")
    tryAdd("Lighting")
    tryAdd("StarterGui")
    tryAdd("StarterPlayer")
    tryAdd("StarterPack")
    tryAdd("ReplicatedFirst")
    tryAdd("Chat")
    tryAdd("SoundService")
    tryAdd("Teams")
    tryAdd("TestService")
    tryAdd("JointsService")

    pcall(function()
        for _, child in ipairs(game:GetChildren()) do
            if not addedSet[child] then
                pcall(function()
                    child:GetDescendants()
                    allContainers[#allContainers+1] = child
                    addedSet[child] = true
                end)
            end
        end
    end)

    for _, root in ipairs(allContainers) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction"))
                   and not self.tested[obj] then
                    if exactSet[obj.Name] then
                        priority1[#priority1+1] = obj
                    else
                        local matched = false
                        local lowName = obj.Name:lower()
                        for _, pat in ipairs(self.namePatterns) do
                            if lowName:find(pat) then
                                priority2[#priority2+1] = obj
                                matched = true
                                break
                            end
                        end
                        if not matched then
                            if #obj.Name <= 3 then
                                priority3[#priority3+1] = obj
                            else
                                priority4[#priority4+1] = obj
                            end
                        end
                    end
                end
            end
        end)
    end

    local result = {}
    for _, t in ipairs({priority1, priority2, priority3, priority4}) do
        for _, r in ipairs(t) do result[#result+1] = r end
    end
    return result, #priority1, #priority2, #priority3, #priority4
end

-- ┌─────────────────────────────────────────────────┐
-- │  ★ BATCH VALIDATION ENGINE ★                    │
-- │  Old: 33 patterns × 0.65s = 21.5s per remote   │
-- │  New: 33 fires → 1 wait → 33 checks = 0.45s    │
-- └─────────────────────────────────────────────────┘

function BD:validateBatch(remote)
    local pats = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    local markers = {}

    -- PHASE 1: Fire ALL patterns simultaneously with unique markers
    for idx, pat in ipairs(pats) do
        local tag = U.marker() .. "_" .. idx
        markers[idx] = tag

        local testCode = string.format(
            'pcall(function() '
            .. 'local v = Instance.new("StringValue"); '
            .. 'v.Name = "%s"; '
            .. 'v.Value = "ok"; '
            .. 'v.Parent = game:GetService("ReplicatedStorage"); '
            .. 'game:GetService("Debris"):AddItem(v, 12) '
            .. 'end)',
            tag
        )

        -- Spawn each fire in its own thread for RemoteFunctions
        if remote:IsA("RemoteFunction") then
            task.spawn(function()
                pcall(function() pat.fn(remote, testCode) end)
            end)
        else
            pcall(function() pat.fn(remote, testCode) end)
        end
    end

    -- PHASE 2: Single wait (instead of 33 waits)
    task.wait(CFG.BatchWait)

    -- PHASE 3: Check ALL markers in one pass
    for idx, tag in ipairs(markers) do
        local found = RS:FindFirstChild(tag)
        if found then
            pcall(function() found:Destroy() end)

            -- Clean up any other markers that also appeared
            for idx2, tag2 in ipairs(markers) do
                if idx2 ~= idx then
                    local other = RS:FindFirstChild(tag2)
                    if other then pcall(function() other:Destroy() end) end
                end
            end

            return true, idx, pats[idx].name
        end
    end

    self.tested[remote] = true
    return false, nil, nil
end

-- Legacy sequential validate (for manual connect)
function BD:validate(remote)
    return self:validateBatch(remote)
end

-- ┌─────────────────────────────────────────────────┐
-- │  ★ CONCURRENT SCAN ENGINE ★                     │
-- │  Tests multiple remotes at the same time         │
-- └─────────────────────────────────────────────────┘

function BD:scan(statusCallback, quickMode)
    if self.scanning then return self.confirmed end
    self.scanning = true
    self.confirmed = {}
    local startTime = U.clock()

    if statusCallback then statusCallback("gathering", 0) end

    local remotes, p1, p2, p3, p4 = self:gatherRemotes()
    local totalRemotes = #remotes

    -- Quick mode: only test priority 1 + 2 (exact + pattern matches)
    if quickMode then
        local quickList = {}
        local quickCount = p1 + p2
        for i = 1, quickCount do
            if remotes[i] then quickList[#quickList+1] = remotes[i] end
        end
        remotes = quickList
        totalRemotes = #remotes
    end

    if statusCallback then
        statusCallback("gathered", totalRemotes, 0, nil, {
            exact = p1, pattern = p2, short = p3, other = p4,
            mode = quickMode and "QUICK" or "DEEP",
        })
    end

    local scannedCount = 0
    local i = 1

    while i <= totalRemotes do
        -- Build batch of concurrent remotes
        local batch = {}
        local batchResults = {}

        for j = 1, CFG.ConcurrentMax do
            local idx = i + j - 1
            if idx > totalRemotes then break end
            local remote = remotes[idx]
            if not self.tested[remote] then
                batch[#batch+1] = {remote = remote, index = idx}
            end
        end

        if #batch == 0 then
            i = i + CFG.ConcurrentMax
            continue
        end

        -- Fire all patterns for all remotes in this batch
        local allMarkers = {} -- [batchIdx][patIdx] = tag

        for bi, item in ipairs(batch) do
            local remote = item.remote
            local pats = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns
            allMarkers[bi] = {}

            for patIdx, pat in ipairs(pats) do
                local tag = U.marker() .. "_" .. bi .. "_" .. patIdx
                allMarkers[bi][patIdx] = tag

                local testCode = string.format(
                    'pcall(function() '
                    .. 'local v = Instance.new("StringValue"); '
                    .. 'v.Name = "%s"; '
                    .. 'v.Value = "ok"; '
                    .. 'v.Parent = game:GetService("ReplicatedStorage"); '
                    .. 'game:GetService("Debris"):AddItem(v, 12) '
                    .. 'end)',
                    tag
                )

                if remote:IsA("RemoteFunction") then
                    task.spawn(function()
                        pcall(function() pat.fn(remote, testCode) end)
                    end)
                else
                    pcall(function() pat.fn(remote, testCode) end)
                end
            end
        end

        -- Single wait for the entire batch
        task.wait(CFG.BatchWait)

        -- Check all markers for all remotes in batch
        for bi, item in ipairs(batch) do
            local remote = item.remote
            local pats = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns
            local markers = allMarkers[bi]
            local foundValid = false

            for patIdx, tag in ipairs(markers) do
                local found = RS:FindFirstChild(tag)
                if found then
                    pcall(function() found:Destroy() end)

                    local fpName = self:fingerprint(remote, pats[patIdx].name)
                    local entry = {
                        inst        = remote,
                        name        = remote.Name,
                        path        = remote:GetFullName(),
                        type        = remote.ClassName,
                        patternIdx  = patIdx,
                        patternName = pats[patIdx].name,
                        fingerprint = fpName,
                    }
                    self.confirmed[#self.confirmed+1] = entry
                    foundValid = true

                    if statusCallback then
                        statusCallback("found", totalRemotes, item.index, remote.Name, entry)
                    end
                    break
                end
            end

            -- Clean up remaining markers
            for _, tag in ipairs(markers) do
                local leftover = RS:FindFirstChild(tag)
                if leftover then pcall(function() leftover:Destroy() end) end
            end

            self.tested[remote] = true
            scannedCount = scannedCount + 1
        end

        -- Status update
        if statusCallback then
            local elapsed = U.clock() - startTime
            statusCallback("progress", totalRemotes, scannedCount, nil, {
                elapsed = elapsed,
                confirmed = #self.confirmed,
                perSecond = scannedCount / math.max(elapsed, 0.01),
            })
        end

        i = i + CFG.ConcurrentMax
    end

    local totalTime = U.clock() - startTime
    self.scanStats = {
        remotesScanned = scannedCount,
        timeElapsed    = totalTime,
        patternsTotal  = scannedCount * #self.patterns,
    }

    self.scanning = false
    if statusCallback then statusCallback("done", #self.confirmed, scannedCount, nil, self.scanStats) end
    return self.confirmed
end

function BD:connect(entry)
    self.active = entry
end

function BD:disconnect()
    self.active = nil
end

function BD:isConnected()
    return self.active ~= nil
end

function BD:exec(code)
    if not self.active then return false, "No backdoor connected" end
    local remote = self.active.inst
    local patIdx = self.active.patternIdx
    local pats   = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    local pat    = pats[patIdx]
    if not pat then return false, "Invalid pattern" end
    local ok, err = pcall(function() pat.fn(remote, code) end)
    return ok, err
end

function BD:requireModule(id)
    local src = string.format(
        'pcall(function() '
        .. 'local m = require(%d); '
        .. 'if type(m) == "function" then m() '
        .. 'elseif type(m) == "table" then '
        .. '  if m.init then m.init() '
        .. '  elseif m.Init then m.Init() '
        .. '  elseif m.Start then m.Start() '
        .. '  elseif m.Run then m.Run() '
        .. '  elseif m.Execute then m.Execute() '
        .. '  end '
        .. 'end end)',
        tonumber(id) or 0
    )
    return self:exec(src)
end

function BD:loadUrl(url)
    local src = string.format(
        'loadstring(game:GetService("HttpService"):GetAsync("%s"))()',
        tostring(url)
    )
    return self:exec(src)
end

function BD:resetScanned()
    self.tested = {}
    self.confirmed = {}
    self.scanStats = {remotesScanned = 0, timeElapsed = 0, patternsTotal = 0}
end

-- ═══════════════════════════════════════════════════
--  5 · NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════

local Notify

-- ═══════════════════════════════════════════════════
--  6 · GUI CONSTRUCTION
-- ═══════════════════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "XenoFramework_" .. U.uid()
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn  = false
gui.IgnoreGuiInset = true
gui.DisplayOrder  = 999

pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
pcall(function() if gethui then gui.Parent = gethui(); return end end)
local guiOk = pcall(function() gui.Parent = CoreGui end)
if not guiOk then gui.Parent = LP:WaitForChild("PlayerGui") end

local T = CFG.Theme

local toastHolder = U.new("Frame", {
    Name = "Toasts",
    Size = UDim2.new(0, 300, 1, 0),
    Position = UDim2.new(1, -310, 0, 0),
    BackgroundTransparency = 1,
    Parent = gui,
}, {
    U.new("UIListLayout", {
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
    U.new("UIPadding", {PaddingBottom = UDim.new(0, 18)}),
})

Notify = function(text, color, duration)
    color = color or T.Text
    duration = duration or CFG.ToastLife
    local toast = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = toastHolder,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0, 8)}),
        U.new("UIStroke", {Color = color, Thickness = 1, Transparency = 0.55}),
        U.new("Frame", {
            Size = UDim2.new(0, 3, 1, 0),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
        }),
        U.new("TextLabel", {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.new(0, 14, 0, 0),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = T.Text,
            TextSize = 13,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }),
    })
    U.tween(toast, {BackgroundTransparency = 0.12}, 0.3)
    task.delay(duration, function()
        U.tween(toast, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.35)
        task.wait(0.38)
        pcall(function() toast:Destroy() end)
    end)
end

-- Main Window
local W = CFG.Window
local main = U.new("Frame", {
    Name = "Main",
    Size = UDim2.new(0, W.Width, 0, W.Height),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = T.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = gui,
}, {
    U.new("UICorner", {CornerRadius = UDim.new(0, 12)}),
    U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.3}),
})

U.new("ImageLabel", {
    Name = "Shadow",
    Size = UDim2.new(1, 44, 1, 44),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6015897843",
    ImageColor3 = Color3.new(0, 0, 0),
    ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    ZIndex = -1,
    Parent = main,
})

-- Top bar
local topBar = U.new("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = T.Surface,
    BorderSizePixel = 0,
    Parent = main,
}, {
    U.new("UICorner", {CornerRadius = UDim.new(0, 12)}),
    U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
    }),
})

U.new("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚡ XENO",
    TextColor3 = T.Primary,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = topBar,
})

U.new("TextLabel", {
    Size = UDim2.new(0, 60, 1, 0),
    Position = UDim2.new(0, 86, 0, 0),
    BackgroundTransparency = 1,
    Text = "v" .. CFG.Version,
    TextColor3 = T.Sub,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = topBar,
})

local statusDot = U.new("Frame", {
    Size = UDim2.new(0, 8, 0, 8),
    Position = UDim2.new(0, 150, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = T.Sub,
    BorderSizePixel = 0,
    Parent = topBar,
}, {U.new("UICorner", {CornerRadius = UDim.new(1, 0)})})

local statusLabel = U.new("TextLabel", {
    Size = UDim2.new(0, 160, 1, 0),
    Position = UDim2.new(0, 164, 0, 0),
    BackgroundTransparency = 1,
    Text = "Starting...",
    TextColor3 = T.Sub,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = topBar,
})

local function setStatus(text, color)
    statusLabel.Text = text
    U.tween(statusDot, {BackgroundColor3 = color}, 0.3)
end

-- Window controls
local controlsLayout = U.new("Frame", {
    Size = UDim2.new(0, 74, 0, 32),
    Position = UDim2.new(1, -82, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundTransparency = 1,
    Parent = topBar,
}, {
    U.new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
})

local function windowBtn(icon, order, callback)
    local btn = U.new("TextButton", {
        Size = UDim2.new(0, 32, 0, 32),
        BackgroundColor3 = T.Card,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Text = icon,
        TextColor3 = T.Sub,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        LayoutOrder = order,
        Parent = controlsLayout,
    }, {U.new("UICorner", {CornerRadius = UDim.new(0, 8)})})
    btn.MouseEnter:Connect(function() U.tween(btn, {BackgroundTransparency = 0.2, TextColor3 = T.Text}, 0.18) end)
    btn.MouseLeave:Connect(function() U.tween(btn, {BackgroundTransparency = 0.6, TextColor3 = T.Sub}, 0.18) end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local minimized = false
windowBtn("—", 1, function()
    minimized = not minimized
    U.tween(main, {Size = UDim2.new(0, W.Width, 0, minimized and 40 or W.Height)}, 0.35)
end)

windowBtn("✕", 2, function()
    U.tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.42); gui:Destroy()
end)

-- Draggable
do
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  7 · SIDEBAR + PAGES
-- ═══════════════════════════════════════════════════

local sidebar = U.new("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 150, 1, -40),
    Position = UDim2.new(0, 0, 0, 40),
    BackgroundColor3 = T.Surface,
    BorderSizePixel = 0,
    Parent = main,
}, {
    U.new("UIPadding", {PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8)}),
    U.new("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}),
})

local pageContainer = U.new("Frame", {
    Name = "Pages",
    Size = UDim2.new(1, -150, 1, -40),
    Position = UDim2.new(0, 150, 0, 40),
    BackgroundColor3 = T.BG,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Parent = main,
})

local pages, currentTab, tabButtons = {}, nil, {}

local function makePage(name)
    local page = U.new("ScrollingFrame", {
        Name = name, Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = T.Primary,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false, Parent = pageContainer,
    }, {
        U.new("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}),
        U.new("UIPadding", {PaddingTop = UDim.new(0,14), PaddingBottom = UDim.new(0,14), PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14)}),
    })
    pages[name] = page; return page
end

local function switchTab(name)
    if currentTab == name then return end
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, btn in pairs(tabButtons) do
        if n == name then
            U.tween(btn, {BackgroundColor3 = T.Primary, BackgroundTransparency = 0.15, TextColor3 = T.Text}, 0.22)
        else
            U.tween(btn, {BackgroundColor3 = T.Card, BackgroundTransparency = 0.7, TextColor3 = T.Sub}, 0.22)
        end
    end
    currentTab = name
end

for _, td in ipairs({
    {name="Dashboard",icon="⌂",order=1},{name="Players",icon="♟",order=2},
    {name="Commands",icon="›_",order=3},{name="Scripts",icon="{ }",order=4},
    {name="Server",icon="⚙",order=5},
}) do
    makePage(td.name)
    local btn = U.new("TextButton", {
        Size = UDim2.new(1,0,0,34), BackgroundColor3 = T.Card, BackgroundTransparency = 0.7,
        BorderSizePixel = 0, Text = "  "..td.icon.."   "..td.name, TextColor3 = T.Sub,
        TextSize = 13, Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false, LayoutOrder = td.order, Parent = sidebar,
    }, {U.new("UICorner", {CornerRadius = UDim.new(0, 8)})})
    btn.MouseEnter:Connect(function() if currentTab ~= td.name then U.tween(btn, {BackgroundTransparency = 0.4}, 0.15) end end)
    btn.MouseLeave:Connect(function() if currentTab ~= td.name then U.tween(btn, {BackgroundTransparency = 0.7}, 0.15) end end)
    btn.MouseButton1Click:Connect(function() switchTab(td.name) end)
    tabButtons[td.name] = btn
end

-- ═══════════════════════════════════════════════════
--  8 · UI HELPERS
-- ═══════════════════════════════════════════════════

local function card(parent, height, order)
    return U.new("Frame", {
        Size = UDim2.new(1,0,0,height or 90), BackgroundColor3 = T.Card,
        BorderSizePixel = 0, LayoutOrder = order or 0, Parent = parent,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0, 10)}),
        U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.5}),
        U.new("UIPadding", {PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12)}),
    })
end

local function heading(parent, text, order)
    return U.new("TextLabel", {
        Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1, Text = text,
        TextColor3 = T.Text, TextSize = 15, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = order or 0, Parent = parent,
    })
end

local function actionBtn(parent, text, color, order, callback)
    color = color or T.Primary
    local btn = U.new("TextButton", {
        Size = UDim2.new(0,110,0,30), BackgroundColor3 = color, BackgroundTransparency = 0.15,
        BorderSizePixel = 0, Text = text, TextColor3 = T.Text, TextSize = 12,
        Font = Enum.Font.GothamSemibold, AutoButtonColor = false, LayoutOrder = order or 0, Parent = parent,
    }, {U.new("UICorner", {CornerRadius = UDim.new(0, 7)})})
    btn.MouseEnter:Connect(function() U.tween(btn, {BackgroundTransparency = 0}, 0.15) end)
    btn.MouseLeave:Connect(function() U.tween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function inputField(parent, placeholder, order)
    local box = U.new("TextBox", {
        Size = UDim2.new(1,0,0,32), BackgroundColor3 = T.Surface, BorderSizePixel = 0,
        Text = "", PlaceholderText = placeholder or "Type here...", PlaceholderColor3 = T.Sub,
        TextColor3 = T.Text, TextSize = 13, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        LayoutOrder = order or 0, Parent = parent,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0, 7)}),
        U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.4}),
        U.new("UIPadding", {PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10)}),
    })
    box.Focused:Connect(function()
        local s = box:FindFirstChildWhichIsA("UIStroke")
        if s then U.tween(s, {Color = T.Primary, Transparency = 0}, 0.2) end
    end)
    box.FocusLost:Connect(function()
        local s = box:FindFirstChildWhichIsA("UIStroke")
        if s then U.tween(s, {Color = T.Border, Transparency = 0.4}, 0.2) end
    end)
    return box
end

-- ═══════════════════════════════════════════════════
--  9 · DASHBOARD PAGE
-- ═══════════════════════════════════════════════════

local playerCountLbl, backdoorCountLbl, statusValLbl, scanResultsLabel

do
    local pg = pages.Dashboard
    heading(pg, "Dashboard", 1)

    local infoRow = U.new("Frame", {
        Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, LayoutOrder = 2, Parent = pg,
    }, {U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})})

    local function infoCard(label, initial, col, order)
        local c = U.new("Frame", {
            Size = UDim2.new(0.32,-4,1,0), BackgroundColor3 = T.Card, BorderSizePixel = 0,
            LayoutOrder = order, Parent = infoRow,
        }, {U.new("UICorner", {CornerRadius = UDim.new(0,8)}), U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.6})})
        U.new("TextLabel", {
            Size = UDim2.new(1,-16,0,16), Position = UDim2.new(0,8,0,8), BackgroundTransparency = 1,
            Text = label, TextColor3 = T.Sub, TextSize = 10, Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = c,
        })
        return U.new("TextLabel", {
            Name = "Value", Size = UDim2.new(1,-16,0,22), Position = UDim2.new(0,8,0,28),
            BackgroundTransparency = 1, Text = initial, TextColor3 = col or T.Text,
            TextSize = 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = c,
        })
    end

    playerCountLbl   = infoCard("PLAYERS", tostring(#Players:GetPlayers()), T.Accent, 1)
    backdoorCountLbl = infoCard("CONFIRMED", "—", T.Warn, 2)
    statusValLbl     = infoCard("STATUS", "Ready", T.Sub, 3)

    Players.PlayerAdded:Connect(function() playerCountLbl.Text = tostring(#Players:GetPlayers()) end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); playerCountLbl.Text = tostring(#Players:GetPlayers()) end)

    heading(pg, "Backdoor Scanner", 3)

    local scanCard = card(pg, 180, 4)

    scanResultsLabel = U.new("TextLabel", {
        Name = "ScanResults", Size = UDim2.new(1,0,0,105), BackgroundTransparency = 1,
        Text = string.format(
            '<font color="#9399B2">Ready to scan.\n'
            .. '%d fire patterns · %d signatures · %d fingerprints\n'
            .. 'Batch engine: ~0.45s per %d concurrent remotes\n\n'
            .. 'Quick Scan = priority remotes only (fastest)\n'
            .. 'Deep Scan = every remote in game (thorough)</font>',
            #BD.patterns, #BD.exactNames, #BD.fingerprints, CFG.ConcurrentMax
        ),
        TextColor3 = T.Sub, TextSize = 12, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, RichText = true, Parent = scanCard,
    })

    local scanBtnsRow = U.new("Frame", {
        Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,1,-30),
        BackgroundTransparency = 1, Parent = scanCard,
    }, {U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder})})

    local scanRunning = false

    local function runScan(quickMode)
        if scanRunning then return end
        scanRunning = true

        BD:resetScanned()
        setStatus("Scanning...", T.Warn)
        statusValLbl.Text = "Scanning..."
        statusValLbl.TextColor3 = T.Warn
        backdoorCountLbl.Text = "..."

        local modeStr = quickMode and "QUICK" or "DEEP"
        scanResultsLabel.Text = '<font color="#F9E2AF">[' .. modeStr .. '] Gathering remotes...</font>'

        task.spawn(function()
            local confirmed = BD:scan(function(phase, total, current, name, extra)
                if phase == "gathering" then
                    scanResultsLabel.Text = '<font color="#F9E2AF">[' .. modeStr .. '] Scanning services...</font>'

                elseif phase == "gathered" then
                    local info = extra
                    scanResultsLabel.Text = string.format(
                        '<font color="#F9E2AF">[%s] %d remotes to validate</font>\n'
                        .. '<font color="#A6E3A1">▸ %d exact · %d pattern</font>'
                        .. ' <font color="#9399B2">· %d short · %d other</font>\n'
                        .. '<font color="#9399B2">Batch: %d concurrent × %d patterns</font>',
                        info.mode, total,
                        info.exact, info.pattern, info.short, info.other,
                        CFG.ConcurrentMax, #BD.patterns
                    )
                    task.wait(0.8)

                elseif phase == "progress" then
                    local info = extra
                    scanResultsLabel.Text = string.format(
                        '<font color="#F9E2AF">[%s] %d/%d remotes</font>'
                        .. ' <font color="#9399B2">(%.1fs · %.0f/s)</font>\n'
                        .. '<font color="#A6E3A1">Confirmed: %d backdoor(s)</font>\n'
                        .. '<font color="#9399B2">Batch firing %d patterns per group of %d...</font>',
                        modeStr, current, total,
                        info.elapsed, info.perSecond,
                        info.confirmed,
                        #BD.patterns, CFG.ConcurrentMax
                    )
                    setStatus(current .. "/" .. total .. " (" .. string.format("%.1fs", info.elapsed) .. ")", T.Warn)

                elseif phase == "found" then
                    local entry = extra
                    Notify("✓ " .. entry.name .. " [" .. entry.fingerprint .. "]", T.OK, 5)

                elseif phase == "done" then
                    -- handled below
                end
            end, quickMode)

            local stats = BD.scanStats
            backdoorCountLbl.Text = tostring(#confirmed)

            if #confirmed == 0 then
                scanResultsLabel.Text = string.format(
                    '<font color="#F3788C">No validated backdoors found.</font>\n\n'
                    .. '<font color="#9399B2">Scanned %d remotes in %.2fs\n'
                    .. 'Tested %d pattern combinations\n'
                    .. 'Speed: %.0f remotes/sec\n\n'
                    .. 'Try:\n'
                    .. '▸ Different server\n'
                    .. '▸ Require a backdoor module (Scripts tab)\n'
                    .. '▸ Backdoored game (obbies, tycoons, etc)</font>',
                    stats.remotesScanned, stats.timeElapsed,
                    stats.remotesScanned * #BD.patterns,
                    stats.remotesScanned / math.max(stats.timeElapsed, 0.01)
                )
                setStatus("No backdoors (" .. string.format("%.1fs", stats.timeElapsed) .. ")", T.Err)
                statusValLbl.Text = "Clean"
                statusValLbl.TextColor3 = T.Err
                Notify("Scan done — 0 found in " .. string.format("%.1fs", stats.timeElapsed), T.Err)
            else
                local lines = {}
                lines[#lines+1] = string.format(
                    '<font color="#A6E3A1">✓ %d backdoor(s) found in %.2fs</font>',
                    #confirmed, stats.timeElapsed
                )
                lines[#lines+1] = string.format(
                    '<font color="#9399B2">%d remotes · %d patterns · %.0f/s</font>',
                    stats.remotesScanned, stats.remotesScanned * #BD.patterns,
                    stats.remotesScanned / math.max(stats.timeElapsed, 0.01)
                )
                lines[#lines+1] = ""
                for i, entry in ipairs(confirmed) do
                    lines[#lines+1] = string.format(
                        '<font color="#A6E3A1">✓ %s</font> <font color="#F9E2AF">[%s]</font>',
                        entry.name, entry.fingerprint
                    )
                    lines[#lines+1] = string.format(
                        '<font color="#9399B2">  %s · %s</font>',
                        entry.type, entry.patternName
                    )
                    if i >= 3 and #confirmed > 3 then
                        lines[#lines+1] = string.format('<font color="#9399B2">  ...+%d more</font>', #confirmed - 3)
                        break
                    end
                end
                scanResultsLabel.Text = table.concat(lines, "\n")

                BD:connect(confirmed[1])
                setStatus(confirmed[1].name .. " [" .. confirmed[1].fingerprint .. "]", T.OK)
                statusValLbl.Text = "Connected"
                statusValLbl.TextColor3 = T.OK
                Notify("✓ " .. confirmed[1].name .. " via \"" .. confirmed[1].patternName
                    .. "\" [" .. confirmed[1].fingerprint .. "] in "
                    .. string.format("%.1fs", stats.timeElapsed), T.OK, 6)
            end

            scanRunning = false
        end)
    end

    actionBtn(scanBtnsRow, "⚡ Quick Scan", T.Primary, 1, function() runScan(true) end)
    actionBtn(scanBtnsRow, "🔍 Deep Scan", T.Accent, 2, function() runScan(false) end)
    actionBtn(scanBtnsRow, "⚡ Connect #1", T.OK, 3, function()
        if #BD.confirmed == 0 then Notify("Run a scan first", T.Err); return end
        BD:connect(BD.confirmed[1])
        setStatus(BD.confirmed[1].name .. " [" .. BD.confirmed[1].fingerprint .. "]", T.OK)
        statusValLbl.Text = "Connected"; statusValLbl.TextColor3 = T.OK
        Notify("✓ Connected: " .. BD.confirmed[1].name, T.OK)
    end)
    actionBtn(scanBtnsRow, "⛔ DC", T.Err, 4, function()
        BD:disconnect(); setStatus("Disconnected", T.Err)
        statusValLbl.Text = "Disconnected"; statusValLbl.TextColor3 = T.Err
        Notify("Disconnected", T.Warn)
    end)

    -- Manual connect
    heading(pg, "Manual Connect", 5)
    local manualCard = card(pg, 80, 6)
    U.new("TextLabel", {
        Size = UDim2.new(1,0,0,16), BackgroundTransparency = 1,
        Text = "Paste a remote's full path:", TextColor3 = T.Sub,
        TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, Parent = manualCard,
    })
    local manualInput = inputField(manualCard, "e.g. ReplicatedStorage.RemoteEvent", 2)
    manualInput.Size = UDim2.new(0.72, 0, 0, 30)
    manualInput.Position = UDim2.new(0, 0, 1, -32)

    local mb = actionBtn(manualCard, "Validate", T.Accent, 3, function()
        local path = manualInput.Text
        if path == "" then Notify("Enter a path", T.Err); return end
        local obj = nil
        pcall(function()
            obj = game
            for part in path:gmatch("[^%.]+") do
                if part ~= "game" then obj = obj:FindFirstChild(part) end
            end
        end)
        if not obj or (not obj:IsA("RemoteEvent") and not obj:IsA("RemoteFunction")) then
            Notify("Remote not found", T.Err); return
        end
        Notify("Validating " .. obj.Name .. "...", T.Warn)
        setStatus("Validating...", T.Warn)
        task.spawn(function()
            local valid, patIdx, patName = BD:validateBatch(obj)
            if valid then
                local fpName = BD:fingerprint(obj, patName)
                local entry = {
                    inst = obj, name = obj.Name, path = obj:GetFullName(),
                    type = obj.ClassName, patternIdx = patIdx,
                    patternName = patName, fingerprint = fpName,
                }
                BD:connect(entry); BD.confirmed[#BD.confirmed+1] = entry
                backdoorCountLbl.Text = tostring(#BD.confirmed)
                setStatus(obj.Name .. " [" .. fpName .. "]", T.OK)
                statusValLbl.Text = "Connected"; statusValLbl.TextColor3 = T.OK
                Notify("✓ " .. obj.Name .. " via \"" .. patName .. "\" [" .. fpName .. "]", T.OK)
            else
                setStatus("Failed", T.Err)
                Notify("✗ Not a backdoor", T.Err)
            end
        end)
    end)
    mb.Position = UDim2.new(0.74, 4, 1, -32)
end

-- ═══════════════════════════════════════════════════
--  10 · PLAYERS PAGE
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Players
    heading(pg, "Player Management", 1)
    local targetInput = inputField(pg, "Player name (or me / all / others)...", 2)
    heading(pg, "Quick Actions", 3)

    local actionsGrid = U.new("Frame", {
        Size = UDim2.new(1,0,0,220), BackgroundTransparency = 1, LayoutOrder = 4, Parent = pg,
    }, {U.new("UIGridLayout", {CellSize = UDim2.new(0,120,0,32), CellPadding = UDim2.new(0,6,0,6), SortOrder = Enum.SortOrder.LayoutOrder})})

    local pActs = {
        {"💀 Kill","kill",T.Err},{"🚪 Kick","kick",T.Err},{"🛡️ God","god",T.OK},
        {"❄️ Freeze","freeze",T.Accent},{"🔥 Thaw","thaw",T.Warn},{"👻 Invis","invisible",T.Sub},
        {"👁️ Visible","visible",T.Text},{"💥 Explode","explode",T.Err},{"🔥 Fire","fire",T.Warn},
        {"✨ Sparkles","sparkles",T.Accent},{"🪑 Sit","sit",T.Sub},{"⬆️ Jump","jump",T.OK},
        {"🏃 Speed 100","speed",T.Primary},{"🦘 JPwr 100","jpower",T.Primary},
        {"🛡️ FF","ff",T.OK},{"🚫 UnFF","unff",T.Err},
    }

    for i, act in ipairs(pActs) do
        actionBtn(actionsGrid, act[1], act[3], i, function()
            if not BD:isConnected() then Notify("Not connected!", T.Err); return end
            local query = targetInput.Text ~= "" and targetInput.Text or "me"
            local targets = U.findPlayers(query)
            if #targets == 0 then Notify("No player: " .. query, T.Err); return end
            for _, plr in ipairs(targets) do
                local cmd = act[2]
                local pn = string.format('game.Players["%s"]', plr.Name)
                local ch = pn .. ".Character"
                local hr = ch .. ":FindFirstChild('HumanoidRootPart')"
                local hm = ch .. ":FindFirstChildWhichIsA('Humanoid')"
                local code = ""

                if cmd == "kill" then code = "pcall(function() "..ch..":BreakJoints() end)"
                elseif cmd == "kick" then code = pn..':Kick("Removed by XENO")'
                elseif cmd == "god" then code = "pcall(function() local h="..hm..";h.MaxHealth=math.huge;h.Health=math.huge end)"
                elseif cmd == "freeze" then code = "pcall(function() "..hr..".Anchored=true end)"
                elseif cmd == "thaw" then code = "pcall(function() "..hr..".Anchored=false end)"
                elseif cmd == "invisible" then code = "pcall(function() for _,v in pairs("..ch..":GetDescendants()) do if v:IsA('BasePart') then v.Transparency=1 end if v:IsA('Decal') then v.Transparency=1 end end end)"
                elseif cmd == "visible" then code = "pcall(function() for _,v in pairs("..ch..":GetDescendants()) do if v:IsA('BasePart') and v.Name~='HumanoidRootPart' then v.Transparency=0 end if v:IsA('Decal') then v.Transparency=0 end end end)"
                elseif cmd == "explode" then code = "pcall(function() local e=Instance.new('Explosion',workspace);e.Position="..hr..".Position end)"
                elseif cmd == "fire" then code = "pcall(function() Instance.new('Fire',"..hr..") end)"
                elseif cmd == "sparkles" then code = "pcall(function() Instance.new('Sparkles',"..hr..") end)"
                elseif cmd == "sit" then code = "pcall(function() "..hm..".Sit=true end)"
                elseif cmd == "jump" then code = "pcall(function() "..hm..".Jump=true end)"
                elseif cmd == "speed" then code = "pcall(function() "..hm..".WalkSpeed=100 end)"
                elseif cmd == "jpower" then code = "pcall(function() local h="..hm..";h.UseJumpPower=true;h.JumpPower=100 end)"
                elseif cmd == "ff" then code = "pcall(function() Instance.new('ForceField',"..ch..") end)"
                elseif cmd == "unff" then code = "pcall(function() for _,v in pairs("..ch..":GetChildren()) do if v:IsA('ForceField') then v:Destroy() end end end)"
                end

                local ok, err = BD:exec(code)
                if ok then Notify(act[1].." → "..plr.Name, T.OK)
                else Notify("Error: "..tostring(err), T.Err) end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  11 · COMMANDS PAGE
-- ═══════════════════════════════════════════════════

local cmdHistory, addHistory, cmdInput = {}, nil, nil

do
    local pg = pages.Commands
    heading(pg, "Command Console", 1)
    cmdInput = inputField(pg, CFG.Prefix .. "command [args...]", 2)

    local historyCard = card(pg, 230, 3)
    local historyLabel = U.new("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = '<font color="#9399B2">Command history will appear here...</font>',
        TextColor3 = T.Sub, TextSize = 12, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, RichText = true, Parent = historyCard,
    })

    addHistory = function(entry, color)
        table.insert(cmdHistory, 1, {text = entry, color = color or "#CDD6F4"})
        if #cmdHistory > CFG.MaxHistory then table.remove(cmdHistory) end
        local lines = {}
        for i = 1, math.min(#cmdHistory, 24) do
            lines[#lines+1] = string.format('<font color="%s">%s</font>', cmdHistory[i].color, cmdHistory[i].text)
        end
        historyLabel.Text = table.concat(lines, "\n")
    end

    heading(pg, "Reference", 4)
    local refCard = card(pg, 180, 5)
    U.new("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = table.concat({
            '<font color="#8A2BE2">Player:</font> ;kill ;kick ;god ;freeze ;thaw ;tp ;speed ;jp',
            '  ;ff ;unff ;explode ;sit ;invisible ;visible ;fire ;sparkles ;smoke',
            '',
            '<font color="#8A2BE2">Server:</font> ;time ;fog ;gravity ;music ;stopmusic',
            '  ;message ;hint ;shutdown ;lock ;unlock',
            '',
            '<font color="#8A2BE2">Utility:</font> ;require <id> ;loadurl <url> ;exec <code>',
            '  ;cmds ;clear ;status ;scanstats',
            'Targets: me / all / others / partial name',
        }, "\n"),
        TextColor3 = T.Sub, TextSize = 11, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, RichText = true, Parent = refCard,
    })
end

-- ═══════════════════════════════════════════════════
--  12 · SCRIPTS PAGE
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Scripts
    heading(pg, "Require Script Loader", 1)
    local reqCard = card(pg, 80, 2)
    local reqInput = inputField(reqCard, "Module Asset ID...", 1)
    reqInput.Size = UDim2.new(1,0,0,30)
    local reqBtns = U.new("Frame", {Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,1,-30), BackgroundTransparency = 1, Parent = reqCard},
        {U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8)})})
    actionBtn(reqBtns, "⚡ Require", T.Primary, 1, function()
        local id = tonumber(reqInput.Text)
        if not id then Notify("Invalid ID", T.Err); return end
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end
        local ok = BD:requireModule(id)
        Notify(ok and "Required: "..id or "Require failed", ok and T.OK or T.Err)
    end)

    heading(pg, "URL Loader", 3)
    local urlCard = card(pg, 80, 4)
    local urlInput = inputField(urlCard, "Raw script URL...", 1)
    urlInput.Size = UDim2.new(1,0,0,30)
    local urlBtns = U.new("Frame", {Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,1,-30), BackgroundTransparency = 1, Parent = urlCard},
        {U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8)})})
    actionBtn(urlBtns, "🌐 Load URL", T.Accent, 1, function()
        if urlInput.Text == "" then Notify("Enter URL", T.Err); return end
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end
        local ok = BD:loadUrl(urlInput.Text)
        Notify(ok and "Loaded from URL" or "Load failed", ok and T.OK or T.Err)
    end)

    heading(pg, "SS Code Executor", 5)
    local execCard = card(pg, 145, 6)
    local execBox = U.new("TextBox", {
        Size = UDim2.new(1,0,0,88), BackgroundColor3 = T.Surface, BorderSizePixel = 0,
        Text = "", PlaceholderText = "-- Server-side Lua here...", PlaceholderColor3 = T.Sub,
        TextColor3 = T.OK, TextSize = 12, Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true, ClearTextOnFocus = false, TextWrapped = true, Parent = execCard,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0,7)}),
        U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.4}),
        U.new("UIPadding", {PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)}),
    })
    local execBtns = U.new("Frame", {Size = UDim2.new(1,0,0,30), Position = UDim2.new(0,0,1,-30), BackgroundTransparency = 1, Parent = execCard},
        {U.new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8)})})
    actionBtn(execBtns, "▶ Execute SS", T.OK, 1, function()
        if execBox.Text == "" then Notify("Write code first", T.Warn); return end
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end
        local ok = BD:exec(execBox.Text)
        Notify(ok and "Executed SS" or "Exec error", ok and T.OK or T.Err)
    end)
    actionBtn(execBtns, "🗑️ Clear", T.Sub, 2, function() execBox.Text = "" end)

    heading(pg, "Script Hub", 7)
    for idx, e in ipairs({
        {name="Infinite Yield", desc="Universal admin", url="https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
        {name="Dex Explorer",   desc="Object explorer", url="https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"},
        {name="Remote Spy",     desc="Remote monitor",  url="https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"},
    }) do
        local hc = card(pg, 55, 7+idx)
        U.new("TextLabel", {Size=UDim2.new(0.6,0,0,16),BackgroundTransparency=1,Text="📜 "..e.name,TextColor3=T.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=hc})
        U.new("TextLabel", {Size=UDim2.new(0.6,0,0,14),Position=UDim2.new(0,0,0,18),BackgroundTransparency=1,Text=e.desc,TextColor3=T.Sub,TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left,Parent=hc})
        local hb = actionBtn(hc, "Execute", T.Primary, 1, function()
            if not BD:isConnected() then Notify("Not connected!", T.Err); return end
            local ok = BD:loadUrl(e.url)
            Notify(ok and "Loaded: "..e.name or "Failed", ok and T.OK or T.Err)
        end)
        hb.Position = UDim2.new(1,-110,0.5,-15)
    end
end

-- ═══════════════════════════════════════════════════
--  13 · SERVER PAGE
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Server
    heading(pg, "Server Controls", 1)

    local lc = card(pg, 110, 2)
    U.new("TextLabel", {Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,Text="🌤️ Lighting",TextColor3=T.Text,TextSize=13,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=lc})
    local lg = U.new("Frame", {Size=UDim2.new(1,0,0,70),Position=UDim2.new(0,0,0,22),BackgroundTransparency=1,Parent=lc},
        {U.new("UIGridLayout", {CellSize=UDim2.new(0,110,0,30),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder})})

    for i, sa in ipairs({
        {"☀️ Day",'game.Lighting.ClockTime=14',T.Warn},
        {"🌙 Night",'game.Lighting.ClockTime=0',T.Accent},
        {"🌫️ Fog On",'game.Lighting.FogEnd=80',T.Sub},
        {"🌫️ Fog Off",'game.Lighting.FogEnd=100000',T.Text},
        {"🔆 Bright",'game.Lighting.Brightness=3;game.Lighting.Ambient=Color3.new(1,1,1)',T.Warn},
        {"🌑 Dark",'game.Lighting.Brightness=0;game.Lighting.Ambient=Color3.new(0,0,0)',T.Sub},
    }) do
        actionBtn(lg, sa[1], sa[3], i, function()
            if not BD:isConnected() then Notify("Not connected!", T.Err); return end
            BD:exec(sa[2]); Notify(sa[1].." applied", T.OK)
        end)
    end

    heading(pg, "Physics", 3)
    local pc = card(pg, 80, 4)
    local gi = inputField(pc, "Gravity (196.2)...", 1)
    gi.Size = UDim2.new(0.65,0,0,30)
    local gb = actionBtn(pc, "Set Gravity", T.Primary, 2, function()
        if not BD:isConnected() then Notify("Not connected!", T.Err); return end
        BD:exec("workspace.Gravity=" .. (tonumber(gi.Text) or 196.2))
        Notify("Gravity → " .. (gi.Text ~= "" and gi.Text or "196.2"), T.OK)
    end)
    gb.Position = UDim2.new(0.68,0,0,0)

    heading(pg, "Server Actions", 5)
    local mg = U.new("Frame", {Size=UDim2.new(1,0,0,80),BackgroundTransparency=1,LayoutOrder=6,Parent=pg},
        {U.new("UIGridLayout",{CellSize=UDim2.new(0,130,0,32),CellPadding=UDim2.new(0,6,0,6),SortOrder=Enum.SortOrder.LayoutOrder})})

    for i, ma in ipairs({
        {"🔒 Lock Server", function() BD:exec('game.Players.MaxPlayers=#game.Players:GetPlayers()'); Notify("Locked",T.OK) end, T.Warn},
        {"🔓 Unlock", function() BD:exec('game.Players.MaxPlayers=50'); Notify("Unlocked",T.OK) end, T.OK},
        {"💣 Shutdown", function() BD:exec('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("XENO Shutdown") end'); Notify("Shutdown",T.Err) end, T.Err},
        {"💬 Message", function() BD:exec('local m=Instance.new("Message",workspace);m.Text="XENO v4.0";game:GetService("Debris"):AddItem(m,5)'); Notify("Sent",T.OK) end, T.Accent},
        {"🎵 Stop Music", function() BD:exec('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop();v:Destroy() end end'); Notify("Stopped",T.OK) end, T.Sub},
        {"🧹 Clean WS", function() BD:exec('for _,v in pairs(workspace:GetChildren()) do if not v:IsA("Terrain") and not v:IsA("Camera") and not game.Players:GetPlayerFromCharacter(v) then pcall(function() v:Destroy() end) end end'); Notify("Cleaned",T.OK) end, T.Err},
    }) do
        actionBtn(mg, ma[1], ma[3], i, function()
            if not BD:isConnected() then Notify("Not connected!", T.Err); return end
            ma[2]()
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  14 · COMMAND REGISTRY
-- ═══════════════════════════════════════════════════

local Commands = {}

local function reg(name, aliases, usage, fn)
    local entry = {name=name, aliases=aliases or {}, usage=usage or "", fn=fn}
    Commands[name:lower()] = entry
    for _, a in ipairs(aliases) do Commands[a:lower()] = entry end
end

local function ssRun(code)
    if not BD:isConnected() then Notify("Not connected!", T.Err); addHistory("✗ Not connected","#F3788C"); return false end
    local ok, err = BD:exec(code)
    if not ok then addHistory("✗ "..tostring(err),"#F3788C") end
    return ok
end

local function pRef(n) return string.format('game.Players["%s"]', n) end

-- Player commands
reg("kill",{"slay"},";kill <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character:BreakJoints() end)"); addHistory("→ kill "..p.Name,"#F3788C") end end)
reg("kick",{"boot"},";kick <plr> [reason]",function(a)
    local r=table.concat(a," ",2); if r=="" then r="Kicked by XENO" end
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun(pRef(p.Name)..':Kick("'..r..'")'); addHistory("→ kick "..p.Name,"#F3788C") end end)
reg("god",{"godmode"},";god <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do local h=pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid")'; ssRun("pcall(function() "..h..".MaxHealth=math.huge;"..h..".Health=math.huge end)"); addHistory("→ god "..p.Name,"#A6E3A1") end end)
reg("speed",{"ws"},";speed <plr> <n>",function(a)
    local v=tonumber(a[2]) or 100
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed='..v.." end)"); addHistory("→ speed "..p.Name.." = "..v,"#B4A0FF") end end)
reg("jumppower",{"jp","jpower"},";jp <plr> <n>",function(a)
    local v=tonumber(a[2]) or 100
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() local h="..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid");h.UseJumpPower=true;h.JumpPower='..v.." end)"); addHistory("→ jp "..p.Name.." = "..v,"#B4A0FF") end end)
reg("freeze",{"fr"},";freeze <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.Anchored=true end)"); addHistory("→ freeze "..p.Name,"#89B4FA") end end)
reg("thaw",{"unfreeze"},";thaw <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.Anchored=false end)"); addHistory("→ thaw "..p.Name,"#F9E2AF") end end)
reg("tp",{"teleport"},";tp <plr1> <plr2>",function(a)
    local fr=U.findPlayers(a[1]); local to=U.findPlayers(a[2] or "me")
    if #fr==0 or #to==0 then Notify("Player not found",T.Err); return end
    for _,p in ipairs(fr) do ssRun("pcall(function() "..pRef(p.Name)..".Character.HumanoidRootPart.CFrame="..pRef(to[1].Name)..".Character.HumanoidRootPart.CFrame end)"); addHistory("→ tp "..p.Name.." → "..to[1].Name,"#B4A0FF") end end)
reg("ff",{"forcefield"},";ff <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun('Instance.new("ForceField",'..pRef(p.Name)..".Character)"); addHistory("→ ff "..p.Name,"#A6E3A1") end end)
reg("unff",{},";unff <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..'.Character:GetChildren()) do if v:IsA("ForceField") then v:Destroy() end end end)'); addHistory("→ unff "..p.Name,"#F3788C") end end)
reg("explode",{"boom"},";explode <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() local e=Instance.new('Explosion',workspace);e.Position="..pRef(p.Name)..".Character.HumanoidRootPart.Position end)"); addHistory("→ explode "..p.Name,"#F3788C") end end)
reg("fire",{},";fire <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Fire',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ fire "..p.Name,"#F9E2AF") end end)
reg("sparkles",{"sp"},";sparkles <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Sparkles',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ sparkles "..p.Name,"#B4A0FF") end end)
reg("smoke",{},";smoke <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() Instance.new('Smoke',"..pRef(p.Name)..".Character.HumanoidRootPart) end)"); addHistory("→ smoke "..p.Name,"#9399B2") end end)
reg("invisible",{"invis"},";invisible <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..".Character:GetDescendants()) do if v:IsA('BasePart') then v.Transparency=1 end if v:IsA('Decal') then v.Transparency=1 end end end)"); addHistory("→ invis "..p.Name,"#9399B2") end end)
reg("visible",{"vis"},";visible <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() for _,v in pairs("..pRef(p.Name)..".Character:GetDescendants()) do if v:IsA('BasePart') and v.Name~='HumanoidRootPart' then v.Transparency=0 end if v:IsA('Decal') then v.Transparency=0 end end end)"); addHistory("→ visible "..p.Name,"#CDD6F4") end end)
reg("sit",{},";sit <plr>",function(a)
    for _,p in ipairs(U.findPlayers(a[1])) do ssRun("pcall(function() "..pRef(p.Name)..'.Character:FindFirstChildWhichIsA("Humanoid").Sit=true end)'); addHistory("→ sit "..p.Name,"#9399B2") end end)

-- Server commands
reg("time",{"clocktime"},";time <n>",function(a) ssRun("game.Lighting.ClockTime="..(tonumber(a[1]) or 14)); addHistory("→ time = "..(a[1] or "14"),"#F9E2AF") end)
reg("fog",{},";fog <n>",function(a) ssRun("game.Lighting.FogEnd="..(tonumber(a[1]) or 100000)); addHistory("→ fog = "..(a[1] or "100000"),"#9399B2") end)
reg("gravity",{"grav"},";gravity <n>",function(a) ssRun("workspace.Gravity="..(tonumber(a[1]) or 196.2)); addHistory("→ gravity = "..(a[1] or "196.2"),"#B4A0FF") end)
reg("music",{"play"},";music <id>",function(a)
    local id=tonumber(a[1]) or 0
    ssRun('local s=Instance.new("Sound",workspace);s.SoundId="rbxassetid://'..id..'";s.Volume=1;s.Looped=true;s:Play()')
    addHistory("→ music "..id,"#B4A0FF") end)
reg("stopmusic",{"stopsounds"},";stopmusic",function() ssRun('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop();v:Destroy() end end'); addHistory("→ stopped sounds","#9399B2") end)
reg("message",{"msg"},";message <text>",function(a)
    local t=table.concat(a," ")
    ssRun('local m=Instance.new("Message",workspace);m.Text="'..t..'";game:GetService("Debris"):AddItem(m,5)')
    addHistory("→ msg: "..t,"#B4A0FF") end)
reg("hint",{},";hint <text>",function(a)
    local t=table.concat(a," ")
    ssRun('local h=Instance.new("Hint",workspace);h.Text="'..t..'";game:GetService("Debris"):AddItem(h,5)')
    addHistory("→ hint: "..t,"#B4A0FF") end)
reg("shutdown",{"sd"},";shutdown",function() ssRun('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("XENO Shutdown") end'); addHistory("→ SHUTDOWN","#F3788C") end)
reg("lockserver",{"lock"},";lock",function() ssRun("game.Players.MaxPlayers=#game.Players:GetPlayers()"); addHistory("→ locked","#F9E2AF") end)
reg("unlockserver",{"unlock"},";unlock",function() ssRun("game.Players.MaxPlayers=50"); addHistory("→ unlocked","#A6E3A1") end)

-- Utility commands
reg("require",{"req"},";require <id>",function(a)
    local id=tonumber(a[1]); if not id then Notify("Invalid ID",T.Err); return end
    BD:requireModule(id); addHistory("→ require("..id..")","#B4A0FF") end)
reg("loadurl",{"url","httpget"},";loadurl <url>",function(a)
    local url=a[1] or ""; if url=="" then Notify("Need URL",T.Err); return end
    BD:loadUrl(url); addHistory("→ loadurl: "..url:sub(1,50),"#B4A0FF") end)
reg("exec",{"execute","run"},";exec <code>",function(a)
    local code=table.concat(a," "); ssRun(code); addHistory("→ exec: "..code:sub(1,60),"#A6E3A1") end)
reg("clear",{"cls"},";clear",function() cmdHistory={}; addHistory("Cleared","#9399B2") end)

reg("status",{"info"},";status",function()
    if BD:isConnected() then
        addHistory("✓ Connected: "..BD.active.name,"#A6E3A1")
        addHistory("  Path: "..BD.active.path,"#9399B2")
        addHistory("  Type: "..BD.active.type,"#9399B2")
        addHistory("  Pattern: "..BD.active.patternName,"#B4A0FF")
        addHistory("  Fingerprint: "..BD.active.fingerprint,"#F9E2AF")
    else
        addHistory("✗ Not connected","#F3788C")
    end
    addHistory("  Confirmed: "..#BD.confirmed,"#9399B2")
end)

reg("scanstats",{"stats"},";scanstats",function()
    local s = BD.scanStats
    addHistory("Scan Statistics:","#B4A0FF")
    addHistory("  Remotes scanned: "..s.remotesScanned,"#9399B2")
    addHistory("  Time elapsed: "..string.format("%.2fs",s.timeElapsed),"#9399B2")
    addHistory("  Patterns tested: "..s.patternsTotal,"#9399B2")
    addHistory("  Speed: "..string.format("%.0f",s.remotesScanned/math.max(s.timeElapsed,0.01)).."/s","#A6E3A1")
    addHistory("  Engine: Batch ("..CFG.ConcurrentMax.." concurrent)","#9399B2")
end)

reg("cmds",{"commands","help"},";cmds",function()
    local listed={}
    for _,entry in pairs(Commands) do if not listed[entry] then addHistory(entry.usage,"#B4A0FF"); listed[entry]=true end end
end)

-- Input handler
cmdInput.FocusLost:Connect(function(enter)
    if not enter then return end
    local raw = cmdInput.Text; cmdInput.Text = ""
    if raw:sub(1,#CFG.Prefix) ~= CFG.Prefix then return end
    local parts = {}
    for w in raw:sub(#CFG.Prefix+1):gmatch("%S+") do parts[#parts+1] = w end
    if #parts == 0 then return end
    local cn = table.remove(parts, 1):lower()
    local entry = Commands[cn]
    if entry then
        addHistory(CFG.Prefix..cn.." "..table.concat(parts," "),"#8A2BE2")
        local ok,err = pcall(entry.fn, parts)
        if not ok then addHistory("✗ "..tostring(err),"#F3788C"); Notify("Error: "..tostring(err),T.Err) end
    else
        addHistory("✗ Unknown: "..cn,"#F3788C"); Notify("Unknown: "..cn,T.Err)
    end
end)

LP.Chatted:Connect(function(msg)
    if msg:sub(1,#CFG.Prefix) ~= CFG.Prefix then return end
    local parts = {}
    for w in msg:sub(#CFG.Prefix+1):gmatch("%S+") do parts[#parts+1] = w end
    if #parts == 0 then return end
    local cn = table.remove(parts, 1):lower()
    local entry = Commands[cn]
    if entry then pcall(entry.fn, parts) end
end)

-- ═══════════════════════════════════════════════════
--  15 · KEYBIND
-- ═══════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CFG.ToggleKey then
        main.Visible = not main.Visible
        if main.Visible then
            main.Size = UDim2.new(0,0,0,0)
            U.tween(main, {Size = UDim2.new(0,W.Width,0,W.Height)}, 0.4, Enum.EasingStyle.Back)
        end
    end
end)

-- ═══════════════════════════════════════════════════
--  16 · BOOT
-- ═══════════════════════════════════════════════════

do
    main.Size = UDim2.new(0,0,0,0); main.BackgroundTransparency = 1
    task.wait(0.15)
    U.tween(main, {Size = UDim2.new(0,W.Width,0,W.Height), BackgroundTransparency = 0}, 0.55, Enum.EasingStyle.Back)
    task.wait(0.6)
    switchTab("Dashboard")

    Notify("⚡ XENO v"..CFG.Version.." loaded", T.Primary)
    Notify(#BD.patterns.." patterns · "..#BD.fingerprints.." fingerprints · Batch engine", T.Accent)
    Notify("Quick Scan or Deep Scan on Dashboard", T.Warn)

    setStatus("Ready — batch engine loaded", T.Sub)
    statusValLbl.Text = "Ready"; statusValLbl.TextColor3 = T.Sub

    print(string.format([[
    ═══════════════════════════════════════
     ⚡ XENO v%s — Batch Validated Engine
     
     %d Fire Patterns (RE) + %d (RF)
     %d Exact Signatures
     %d Pattern Matchers  
     %d Fingerprint Profiles
     %d Concurrent Remote Testing
     
     ★ ~30x faster than sequential scan
     ★ Lalol Hub detection included
     
     Toggle: RightShift | Prefix: %s
    ═══════════════════════════════════════
    ]], CFG.Version, #BD.patterns, #BD.rfPatterns, #BD.exactNames, #BD.namePatterns, #BD.fingerprints, CFG.ConcurrentMax, CFG.Prefix))
end
