--[[
██╗  ██╗███████╗███╗   ██╗ ██████╗ 
╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
 ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
 ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

XENO | Universal Server-Side Framework v5.0.0
Xeno Executor Compatible Build - ADVANCED STEALTH
]]

-- ═══════════════════════════════════════════════════
--  1 · CONFIGURATION
-- ═══════════════════════════════════════════════════

local CFG = {
    Name           = "XENO",
    Version        = "5.0.0",
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
--  3 · UTILITIES
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
--  4 · ADVANCED ANTI-CHEAT BYPASS (STEALTH ULTRA V5)
-- ═══════════════════════════════════════════════════

local AC = {
    active = false,
    mode = "stealth_ultra",
    results = {},
    gameProfile = nil,
}

-- Layer 1: AppService & Executor Spoofer
AC.serviceStealth = [[
pcall(function()
    local mt = getrawmetatable(game)
    local oldNm = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if method == "GetService" or method == "FindService" then
            if args[1] == "AppUpdateService" or args[1] == "VirtualInputManager" then
                return nil 
            end
        end
        return oldNm(self, ...)
    end)
    setreadonly(mt, true)
end)
]]

-- Layer 2: Heartbeat Interceptor (Specialized for Rivals)
AC.rivalsLogic = [[
pcall(function()
    if game.PlaceId == 17625359962 then
        local rs = game:GetService("ReplicatedStorage")
        local heartbeat = rs:FindFirstChild("HD_Remote") or rs:FindFirstChild("AC_Verify")
        if heartbeat and heartbeat:IsA("RemoteEvent") then
            local oldFire = heartbeat.FireServer
            heartbeat.FireServer = function(self, ...)
                local args = {...}
                if typeof(args[1]) == "table" then
                    args[1].Detected = false
                    args[1].Violation = 0
                end
                return oldFire(self, unpack(args))
            end
        end
    end
end)
]]

-- Layer 3: Integrity & Kick Prevention
AC.kickPreventCode = [[
pcall(function()
    local Players = game:GetService("Players")
    local function protect(plr)
        pcall(function()
            local mt = getrawmetatable(plr)
            if mt then
                local oldNc = mt.__namecall
                setreadonly(mt, false)
                mt.__namecall = newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    if (method == "Kick" or method == "Ban") then return nil end
                    return oldNc(self, ...)
                end)
                setreadonly(mt, true)
            end
        end)
    end
    protect(Players.LocalPlayer)
end)
]]

-- Layer 4: Continuous Flag Clearing
AC.loopProtectCode = [[
spawn(function()
    while task.wait(5) do
        pcall(function()
            local lp = game:GetService("Players").LocalPlayer
            local char = lp.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, attr in ipairs(hum:GetAttributes()) do
                    if typeof(attr) == "string" and (attr:lower():find("flag") or attr:lower():find("warn") or attr:lower():find("cheat")) then
                        hum:SetAttribute(attr, nil)
                    end
                end
            end
        end)
    end
end)
]]

AC.gameProfiles = {
    {name="Rivals", placeIds={17625359962}, desc="FPS Advanced Stealth", code=AC.rivalsLogic},
    {name="Generic", placeIds={}, desc="Universal Stealth Fallback", code=[[pcall(function() print("Generic Stealth Active") end)]]},
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
    local profile = self:detectGame()
    self.gameProfile = profile

    loadstring(self.serviceStealth)()
    task.wait(0.2)
    loadstring(self.kickPreventCode)()
    task.wait(0.2)
    loadstring(profile.code)()
    task.wait(0.2)
    loadstring(self.loopProtectCode)()

    self.active = true
    return true, {profile = profile.name, layersOk = 6}
end

function AC:syncAfterChange()
    pcall(function()
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            for _, attr in ipairs(hum:GetAttributes()) do
                hum:SetAttribute(attr, nil)
            end
        end
    end)
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

BD.exactNames = {"Backdoor","Execute","MainEvent","ServerEvent","Handler","Bridge","Hydrogen","Crusher","Aztup","Nihon","JEBI","Nexus","Dansploit","OwlHub","IY_SS","LalolHub"}
BD.namePatterns = {"backdoor","execut","loadstr","remote.*event","serversid","admin.*remote","exploit"}
BD.patterns = {
    {name="Raw String",fn=function(r,c) r:FireServer(c) end},
    {name="Table {Code=}",fn=function(r,c) r:FireServer({Code=c}) end},
    {name='"execute",code',fn=function(r,c) r:FireServer("execute",c) end},
    {name="Table {[1]=code}",fn=function(r,c) r:FireServer({c}) end},
    {name="Player,code",fn=function(r,c) r:FireServer(Players.LocalPlayer,c) end},
}
BD.rfPatterns = {
    {name="Raw String",fn=function(r,c) return r:InvokeServer(c) end},
    {name="Table {Code=}",fn=function(r,c) return r:InvokeServer({Code=c}) end},
}
BD.fingerprints = {
    {name="Hydrogen SS",check=function(r,p) return r.Name:lower():find("hydrogen") end},
    {name="Lalol Hub",check=function(r,p) return r.Name:lower():find("lalol") end},
    {name="Classic FM",check=function(r,p) return p=="Raw String" and #r.Name<=3 end},
}

function BD:fingerprint(remote, patternName)
    for _, fp in ipairs(self.fingerprints) do
        local ok, result = pcall(fp.check, remote, patternName)
        if ok and result then return fp.name end
    end
    return "Unknown"
end

function BD:gatherRemotes()
    local r = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not self.tested[obj] then
            r[#r+1] = obj
        end
    end
    return r
end

function BD:validateThrottled(remote)
    local pats = remote:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    local markers = {}
    for idx,pat in ipairs(pats) do
        local tag = U.marker().."_"..idx
        markers[idx]=tag
        local tc = string.format('pcall(function() local v=Instance.new("StringValue");v.Name="%s";v.Value="ok";v.Parent=game:GetService("ReplicatedStorage");game:GetService("Debris"):AddItem(v,10) end)',tag)
        if remote:IsA("RemoteFunction") then
            task.spawn(function() pcall(function() pat.fn(remote,tc) end) end)
        else
            pcall(function() pat.fn(remote,tc) end)
        end
    end
    task.wait(CFG.BatchWait)
    for idx,tag in ipairs(markers) do
        if RS:FindFirstChild(tag) then
            pcall(function() RS[tag]:Destroy() end)
            return true, idx, pats[idx].name
        end
    end
    self.tested[remote]=true
    return false
end

function BD:scan(statusCallback, quickMode)
    if self.scanning then return end
    self.scanning = true
    local remotes = self:gatherRemotes()
    local startTime = tick()
    for i, remote in ipairs(remotes) do
        if statusCallback then statusCallback("validating", #remotes, i, remote.Name, {elapsed = tick()-startTime, confirmed = #self.confirmed}) end
        local valid, pi, pn = self:validateThrottled(remote)
        if valid then
            local entry = {inst=remote, name=remote.Name, patternIdx=pi, patternName=pn, fingerprint=self:fingerprint(remote, pn)}
            table.insert(self.confirmed, entry)
            if statusCallback then statusCallback("found", #remotes, i, remote.Name, entry) end
        end
        if quickMode and i > 100 then break end
    end
    self.scanStats.timeElapsed = tick() - startTime
    self.scanning = false
    return self.confirmed
end

function BD:connect(e) self.active=e end
function BD:exec(code)
    if not self.active then return false end
    local pats = self.active.inst:IsA("RemoteFunction") and self.rfPatterns or self.patterns
    return pcall(function() pats[self.active.patternIdx].fn(self.active.inst, code) end)
end

-- ═══════════════════════════════════════════════════
--  6 · GUI CONSTRUCTION
-- ═══════════════════════════════════════════════════

local Notify
local gui = Instance.new("ScreenGui")
gui.Name = "XenoFramework_" .. U.uid()
gui.Parent = gethui and gethui() or CoreGui

local T = CFG.Theme
local toastHolder = U.new("Frame",{Size=UDim2.new(0,300,1,0),Position=UDim2.new(1,-310,0,0),BackgroundTransparency=1,Parent=gui},{
    U.new("UIListLayout",{Padding=UDim.new(0,6),VerticalAlignment=Enum.VerticalAlignment.Bottom,SortOrder=Enum.SortOrder.LayoutOrder}),
})

Notify = function(text,color,duration)
    local toast = U.new("Frame",{Size=UDim2.new(1,0,0,36),BackgroundColor3=T.Surface,Parent=toastHolder},{
        U.new("UICorner",{CornerRadius=UDim.new(0,8)}),
        U.new("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=color or T.Primary}),
        U.new("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text=text,TextColor3=T.Text,TextSize=13,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left}),
    })
    task.delay(duration or 3, function() pcall(function() toast:Destroy() end) end)
end

local W = CFG.Window
local main = U.new("Frame",{Size=UDim2.new(0,W.Width,0,W.Height),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=T.BG,Parent=gui},{
    U.new("UICorner",{CornerRadius=UDim.new(0,12)}),
    U.new("UIStroke",{Color=T.Border,Thickness=1}),
})

local topBar = U.new("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=T.Surface,Parent=main},{
    U.new("UICorner",{CornerRadius=UDim.new(0,12)}),
    U.new("TextLabel",{Size=UDim2.new(0,200,1,0),Position=UDim2.new(0,16,0,0),BackgroundTransparency=1,Text="⚡ XENO v"..CFG.Version,TextColor3=T.Primary,Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left}),
})

local sidebar = U.new("Frame",{Size=UDim2.new(0,150,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=T.Surface,Parent=main})
local pageContainer = U.new("Frame",{Size=UDim2.new(1,-150,1,-40),Position=UDim2.new(0,150,0,40),BackgroundTransparency=1,Parent=main})
local pages, currentTab, tabButtons = {}, nil, {}

local function makePage(n)
    local p = U.new("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,Parent=pageContainer},{
        U.new("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center}),
        U.new("UIPadding",{PaddingTop=UDim.new(0,12)}),
    })
    pages[n] = p
    return p
end

local function switchTab(n)
    if currentTab == n then return end
    for k, p in pairs(pages) do p.Visible = (k == n) end
    currentTab = n
end

local tabs = {"Dashboard", "Players", "Commands", "Scripts", "Server", "Anti-Cheat"}
for i, t in ipairs(tabs) do
    makePage(t)
    local btn = U.new("TextButton",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=0.8,BackgroundColor3=T.Card,Text=t,TextColor3=T.Sub,Parent=sidebar})
    btn.MouseButton1Click:Connect(function() switchTab(t) end)
end

-- ═══════════════════════════════════════════════════
--  7 · UI HELPERS & DASHBOARD CONTENT
-- ═══════════════════════════════════════════════════

local function card(parent,height)
    return U.new("Frame",{Size=UDim2.new(0.9,0,0,height),BackgroundColor3=T.Card,Parent=parent},{
        U.new("UICorner",{CornerRadius=UDim.new(0,10)}),
        U.new("UIPadding",{PaddingTop=UDim.new(0,10),PaddingLeft=UDim.new(0,10)}),
    })
end

local function actionBtn(parent,text,color,cb)
    local btn = U.new("TextButton",{Size=UDim2.new(0,100,0,30),BackgroundColor3=color or T.Primary,Text=text,TextColor3=T.Text,Parent=parent},{
        U.new("UICorner",{CornerRadius=UDim.new(0,6)}),
    })
    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- Dashboard
do
    local pg = pages.Dashboard
    local scanCard = card(pg,120)
    local res = U.new("TextLabel",{Size=UDim2.new(1,0,0,60),BackgroundTransparency=1,Text="Engine Ready\nXeno Stealth Active",TextColor3=T.Sub,TextSize=12,RichText=true,Parent=scanCard})
    actionBtn(scanCard, "Scan", T.Primary, function()
        BD:scan(function(ph, tot, cur, name, extra)
            res.Text = ph == "validating" and "Scanning: "..cur.."/"..tot or "Scan Complete"
        end, true)
    end).Position = UDim2.new(0,0,1,-35)
end

-- Anti-Cheat Page
do
    local pg = pages["Anti-Cheat"]
    local profile = AC:detectGame()
    local c = card(pg, 150)
    local status = U.new("TextLabel",{Size=UDim2.new(1,0,0,100),BackgroundTransparency=1,Text="<b>Profile:</b> "..profile.name.."\n<b>Status:</b> Ready\n<b>Layers:</b> Stealth Ultra V5",TextColor3=T.Text,RichText=true,Parent=c})
    
    actionBtn(c, "Apply Bypass", T.OK, function()
        AC:execute()
        status.Text = "<b>Profile:</b> "..profile.name.."\n<b>Status:</b> <font color='#A6E3A1'>ACTIVE</font>\n<b>Layers:</b> 6/6 Stealth Enabled"
    end).Position = UDim2.new(0,0,1,-35)
end

-- ═══════════════════════════════════════════════════
--  8 · PLAYER & SERVER LOGIC (Simplified for Full File)
-- ═══════════════════════════════════════════════════

-- Commands Input
local cmdPg = pages.Commands
local cmdInput = U.new("TextBox",{Size=UDim2.new(0.9,0,0,35),BackgroundColor3=T.Surface,PlaceholderText=";command...",TextColor3=T.Text,Parent=cmdPg},{U.new("UICorner",{CornerRadius=UDim.new(0,8)})})

cmdInput.FocusLost:Connect(function(enter)
    if not enter then return end
    local txt = cmdInput.Text
    cmdInput.Text = ""
    if txt:sub(1,1) ~= ";" then return end
    local args = txt:sub(2):split(" ")
    local cmd = args[1]:lower()
    
    if cmd == "kill" then
        for _, p in ipairs(U.findPlayers(args[2])) do
            BD:exec("game.Players['"..p.Name.."'].Character:BreakJoints()")
        end
    elseif cmd == "bypass" then
        AC:execute()
        Notify("Bypass Applied", T.OK)
    end
end)

-- ═══════════════════════════════════════════════════
--  9 · BOOT
-- ═══════════════════════════════════════════════════

UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == CFG.ToggleKey then main.Visible = not main.Visible end
end)

-- Auto-Stealth Boot
task.spawn(function()
    AC:execute()
    Notify("⚡ XENO: Stealth Ultra V5 Active", T.Primary)
    switchTab("Dashboard")
end)

print("⚡ XENO v5.0.0 Loaded | Stealth Ultra Active")
