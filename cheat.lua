-- 🔥DBCheat🔥 v3
if not game:IsLoaded() then game.Loaded:Wait() end

-- ==================== АВТОЗАКРЫТИЕ СТАРОЙ ВЕРСИИ ====================
-- При повторном запуске старая копия сама закрывается (по id сессии и по флагу).
local env = shared
local myId = (tonumber(env.DBCheatId) or 0) + 1
env.DBCheatId = myId
if env.DBCheatRunning then
    env.DBCheatClose = true
    task.wait(0.6)
end
env.DBCheatRunning = true
env.DBCheatClose = false

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CAS = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
while not Player do
    task.wait()
    Player = Players.LocalPlayer
end
local Mouse = Player:GetMouse()
local function cam() return workspace.CurrentCamera end

local ZERO = Vector3.new(0, 0, 0)
local UP = Vector3.new(0, 1, 0)

-- ==================== НАСТРОЙКИ ====================
-- Горячие клавиши только для основных функций.
-- Остальное работает через переключатели в меню.
local Keybinds = {
    Speed = Enum.KeyCode.R,
    Fly = Enum.KeyCode.F,
    Freecam = Enum.KeyCode.G,
    Menu = Enum.KeyCode.RightControl,
}

local Settings = {
    WalkSpeed = 40,
    JumpPower = 100,
    InfJumpPower = 40,
    FlySpeed = 60,
    FreecamSpeed = 60,
    ChairCount = 5,
}

local Limits = {
    WalkSpeed = {0, 1000},
    JumpPower = {0, 1000},
    InfJumpPower = {0, 1000},
    FlySpeed = {0, 1000},
    FreecamSpeed = {0, 1000},
    ChairCount = {1, 50},
}

local State = {
    Speed = false, JumpBoost = false, InfJump = false,
    Fly = false, Noclip = false,
    Chairs = false, ChairsHide = false,
    ESP = false, FreecamArmed = false, FreecamActive = false,
    Teleport = false, DayNightTouched = false, IsNight = false,
}

local Conns, Toggles = {}, {}
local Originals = {WalkSpeed = 16, JumpPower = 50}
local flyBV, flyBG
local highlights = {}
local savedClock
local fcPos, fcYaw, fcPitch, fcRMB = ZERO, 0, 0, false
local Closing, Silent = false, true
local frame, dnBtn
local chairFolder

-- ==================== СОХРАНЕНИЕ НАСТРОЕК ====================
local SAVE_FILE = "DBCheat_settings.json"
local SAVE_VERSION = 3
local canSave = type(writefile) == "function"
    and type(readfile) == "function"
    and type(isfile) == "function"
local noSave = false
local saveQueued = false
local Saved = {}

local ToggleOf = {
    Speed = "Speed", JumpBoost = "JumpBoost", InfJump = "InfJump",
    Noclip = "Noclip", ESP = "ESP", FreecamArmed = "Freecam", Teleport = "Teleport",
}

if canSave then
    local ok, data = pcall(function()
        if isfile(SAVE_FILE) then
            return HttpService:JSONDecode(readfile(SAVE_FILE))
        end
    end)
    if ok and type(data) == "table" then Saved = data end
end

if type(Saved.settings) == "table" then
    -- в старых сохранениях высота беск. прыжка была другой: сбрасываем на 40
    if (tonumber(Saved.version) or 0) < 3 then Saved.settings.InfJumpPower = nil end
    for k, v in pairs(Saved.settings) do
        if Settings[k] ~= nil and type(v) == "number" then
            local lim = Limits[k]
            Settings[k] = math.clamp(v, lim[1], lim[2])
        end
    end
end

if type(Saved.keys) == "table" then
    for id, name in pairs(Saved.keys) do
        if Keybinds[id] and type(name) == "string" then
            local ok, kc = pcall(function() return Enum.KeyCode[name] end)
            if ok and kc then Keybinds[id] = kc end
        end
    end
end

local function saveNow()
    if not canSave or noSave then return false end
    local keys = {}
    for id, k in pairs(Keybinds) do keys[id] = k.Name end
    local states = {}
    for stateId in pairs(ToggleOf) do states[stateId] = State[stateId] and true or false end
    local data = {
        version = SAVE_VERSION,
        settings = Settings,
        keys = keys,
        states = states,
        dayNight = {touched = State.DayNightTouched, night = State.IsNight},
    }
    if frame then
        local p = frame.Position
        data.pos = {p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset}
    end
    local ok = pcall(function() writefile(SAVE_FILE, HttpService:JSONEncode(data)) end)
    return ok
end

local function queueSave()
    if saveQueued or not canSave or Closing then return end
    saveQueued = true
    task.delay(1, function()
        saveQueued = false
        saveNow()
    end)
end

-- ==================== УТИЛИТЫ ====================
local function keyName(k) return k.Name end

local function getChar()
    local c = Player.Character
    if not c then return end
    return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end

local function moveVector(cf)
    local d = ZERO
    if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cf.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cf.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then d = d + UP end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then d = d - UP end
    return d
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isCharacterPart(inst)
    local m = inst:FindFirstAncestorOfClass("Model")
    return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end

local function getGuiParent()
    if type(gethui) == "function" then
        local ok, r = pcall(gethui)
        if ok and r then return r end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local probe = Instance.new("Folder")
        local ok2 = pcall(function() probe.Parent = cg end)
        probe:Destroy()
        if ok2 then return cg end
    end
    return Player:WaitForChild("PlayerGui")
end

local function killOld(parent)
    if not parent then return end
    pcall(function()
        local o = parent:FindFirstChild("DBCheatGui")
        if o then o:Destroy() end
    end)
end

-- ==================== ТЕМА ====================
local C = {
    Bg = Color3.fromRGB(16, 16, 24),
    Panel = Color3.fromRGB(24, 24, 36),
    Row = Color3.fromRGB(34, 34, 50),
    Text = Color3.fromRGB(240, 240, 250),
    Dim = Color3.fromRGB(150, 150, 180),
    Accent = Color3.fromRGB(255, 110, 40),
    Accent2 = Color3.fromRGB(255, 50, 80),
    Off = Color3.fromRGB(70, 70, 95),
    On = Color3.fromRGB(255, 110, 40),
}
local TI = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function tween(o, props) TweenService:Create(o, TI, props):Play() end

local function round(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = o
    return c
end

local function fireGradient(o)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(C.Accent, C.Accent2)
    g.Rotation = 20
    g.Parent = o
    return g
end

-- ==================== GUI: ОСНОВА ====================
local guiParent = getGuiParent()
killOld(guiParent)
killOld(Player:FindFirstChild("PlayerGui"))
pcall(function() killOld(game:GetService("CoreGui")) end)

local gui = Instance.new("ScreenGui")
gui.Name = "DBCheatGui"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 400)
frame.Position = UDim2.new(0.5, -280, 0.5, -200)
frame.BackgroundColor3 = C.Bg
frame.BorderSizePixel = 0
frame.Parent = gui
round(frame, 12)

if type(Saved.pos) == "table" and #Saved.pos == 4 then
    local p = Saved.pos
    if type(p[1]) == "number" and type(p[2]) == "number"
        and type(p[3]) == "number" and type(p[4]) == "number" then
        frame.Position = UDim2.new(p[1], p[2], p[3], p[4])
    end
end
task.defer(function() -- если окно оказалось за экраном, вернуть в центр
    local vs = gui.AbsoluteSize
    local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
    if vs.X > 0 and (ap.X + as.X < 80 or ap.X > vs.X - 80 or ap.Y < -10 or ap.Y > vs.Y - 60) then
        frame.Position = UDim2.new(0.5, -280, 0.5, -200)
    end
end)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.new(1, 1, 1)
stroke.Parent = frame
fireGradient(stroke)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = C.Panel
header.BorderSizePixel = 0
header.Active = true
header.Parent = frame
round(header, 12)

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 12)
headerFix.Position = UDim2.new(0, 0, 1, -12)
headerFix.BackgroundColor3 = C.Panel
headerFix.BorderSizePixel = 0
headerFix.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🔥DBCheat🔥"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBlack
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header
fireGradient(title)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 7)
closeBtn.BackgroundColor3 = C.Accent2
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = header
round(closeBtn, 8)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(0, 130, 1, -62)
tabBar.Position = UDim2.new(0, 10, 0, 54)
tabBar.BackgroundColor3 = C.Panel
tabBar.BorderSizePixel = 0
tabBar.Parent = frame
round(tabBar, 10)
local tbl = Instance.new("UIListLayout")
tbl.Padding = UDim.new(0, 6)
tbl.SortOrder = Enum.SortOrder.LayoutOrder
tbl.Parent = tabBar
local tbp = Instance.new("UIPadding")
tbp.PaddingTop = UDim.new(0, 8)
tbp.PaddingLeft = UDim.new(0, 8)
tbp.PaddingRight = UDim.new(0, 8)
tbp.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -162, 1, -62)
content.Position = UDim2.new(0, 150, 0, 54)
content.BackgroundColor3 = C.Panel
content.BorderSizePixel = 0
content.Parent = frame
round(content, 10)

-- ==================== УВЕДОМЛЕНИЯ ====================
local lastNote
local function notify(text)
    if Closing or Silent then return end
    if lastNote then pcall(function() lastNote:Destroy() end) end
    local t = Instance.new("TextLabel")
    lastNote = t
    t.Size = UDim2.new(0, 300, 0, 34)
    t.Position = UDim2.new(0.5, -150, 1, 0)
    t.BackgroundColor3 = C.Bg
    t.TextColor3 = C.Text
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.Text = text
    t.Parent = gui
    round(t, 8)
    local s = Instance.new("UIStroke")
    s.Thickness = 1.5
    s.Color = Color3.new(1, 1, 1)
    s.Parent = t
    fireGradient(s)
    tween(t, {Position = UDim2.new(0.5, -150, 1, -60)})
    task.delay(1.8, function()
        if t.Parent then
            tween(t, {Position = UDim2.new(0.5, -150, 1, 0), BackgroundTransparency = 1, TextTransparency = 1})
            task.wait(0.25)
            if t.Parent then t:Destroy() end
        end
    end)
end

-- ==================== GUI: ХЕЛПЕРЫ ====================
local orderCounter = {}
local function nextOrder(parent)
    orderCounter[parent] = (orderCounter[parent] or 0) + 1
    return orderCounter[parent]
end

local function newPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, -12, 1, -12)
    p.Position = UDim2.new(0, 6, 0, 6)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = C.Accent
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Visible = false
    p.Parent = content
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return p
end

local function createRow(parent, h)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, h or 36)
    row.BackgroundColor3 = C.Row
    row.BorderSizePixel = 0
    row.LayoutOrder = nextOrder(parent)
    row.Parent = parent
    round(row, 8)
    return row
end

local function rowLabel(row, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -90, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C.Text
    l.Font = Enum.Font.GothamMedium
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = row
    return l
end

local function createLabel(parent, text, h)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, h or 40)
    l.BackgroundTransparency = 1
    l.TextWrapped = true
    l.Text = text
    l.TextColor3 = C.Dim
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.LayoutOrder = nextOrder(parent)
    l.Parent = parent
    return l
end

-- числовое поле, привязанное к Settings[key]
local function makeNumberBox(row, key, x, onChange)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 70, 0, 24)
    box.Position = UDim2.new(1, x, 0.5, -12)
    box.BackgroundColor3 = C.Bg
    box.TextColor3 = C.Accent
    box.Font = Enum.Font.GothamBold
    box.TextSize = 14
    box.Text = tostring(Settings[key])
    box.ClearTextOnFocus = false
    box.Parent = row
    round(box, 6)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then
            local lim = Limits[key]
            Settings[key] = math.clamp(n, lim[1], lim[2])
            queueSave()
            if onChange then pcall(onChange, Settings[key]) end
        end
        box.Text = tostring(Settings[key])
    end)
    return box
end

-- переключатель; opts = {key = "...", name = "...", onChange = fn}
-- с opts.key в ОДНОЙ строке: название, поле значения, переключатель
local function createToggle(parent, text, callback, suffix, opts)
    local hasBox = opts ~= nil and opts.key ~= nil
    local nname = (opts and opts.name) or text
    local row = createRow(parent)
    local lbl = rowLabel(row, text)
    lbl.Size = UDim2.new(1, hasBox and -140 or -70, 1, 0)

    if hasBox then
        makeNumberBox(row, opts.key, -132, opts.onChange)
    end

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 42, 0, 22)
    pill.Position = UDim2.new(1, -54, 0.5, -11)
    pill.BackgroundColor3 = C.Off
    pill.BorderSizePixel = 0
    pill.Parent = row
    round(pill, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    round(knob, 9)

    local state = false
    local obj = {}
    function obj.Refresh()
        lbl.Text = text .. (suffix and suffix() or "")
        tween(pill, {BackgroundColor3 = state and C.On or C.Off})
        tween(knob, {Position = state and UDim2.new(0, 22, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)})
    end
    function obj.Set(v)
        state = v
        callback(v)
        obj.Refresh()
        notify(nname .. (v and ": ВКЛ" or ": ВЫКЛ"))
        queueSave()
    end
    function obj.Get() return state end

    local hitLabel = Instance.new("TextButton")
    hitLabel.Size = UDim2.new(1, hasBox and -140 or 0, 1, 0)
    hitLabel.BackgroundTransparency = 1
    hitLabel.Text = ""
    hitLabel.Parent = row
    hitLabel.MouseButton1Click:Connect(function() obj.Set(not state) end)

    if hasBox then
        local hitPill = Instance.new("TextButton")
        hitPill.Size = UDim2.new(0, 60, 1, 0)
        hitPill.Position = UDim2.new(1, -60, 0, 0)
        hitPill.BackgroundTransparency = 1
        hitPill.Text = ""
        hitPill.Parent = row
        hitPill.MouseButton1Click:Connect(function() obj.Set(not state) end)
    end

    obj.Refresh()
    return obj
end

local function createButton(parent, text, callback)
    local row = createRow(parent)
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = text
    hit.TextColor3 = C.Text
    hit.Font = Enum.Font.GothamMedium
    hit.TextSize = 14
    hit.Parent = row
    hit.MouseButton1Click:Connect(function() callback(hit) end)
    return hit
end

local function createInput(parent, label, key, onChange)
    local row = createRow(parent)
    rowLabel(row, label)
    makeNumberBox(row, key, -82, onChange)
end

local pages, tabButtons = {}, {}
local function selectTab(name)
    for n, p in pairs(pages) do
        p.Visible = (n == name)
        tween(tabButtons[n], {BackgroundColor3 = (n == name) and C.Accent or C.Row})
    end
end

local function createTab(name)
    local page = newPage()
    pages[name] = page
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = C.Row
    b.Text = name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.LayoutOrder = nextOrder(tabBar)
    b.Parent = tabBar
    round(b, 8)
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

-- ==================== ЛОГИКА: ДВИЖЕНИЕ ====================
table.insert(Conns, RunService.Heartbeat:Connect(function()
    local _, hum = getChar()
    if not hum then return end
    if State.Speed then hum.WalkSpeed = Settings.WalkSpeed end
    if State.JumpBoost then
        hum.UseJumpPower = true
        hum.JumpPower = Settings.JumpPower
    end
end))

table.insert(Conns, UIS.JumpRequest:Connect(function()
    if not State.InfJump then return end
    local _, hum, root = getChar()
    if not hum or not root then return end
    local v = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(v.X, Settings.InfJumpPower, v.Z)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)
end))

-- ==================== ЛОГИКА: СТУЛЬЯ ====================
local function clearChairs()
    if chairFolder then
        chairFolder:Destroy()
        chairFolder = nil
    end
end

-- Стулья создаются на клиенте: видны только вам.
local function buildChairs()
    clearChairs()
    local _, _, root = getChar()
    if not root then return false end

    local n = math.floor(Settings.ChairCount)
    local perRow = 5
    local spacingX, spacingZ = 2.8, 3.2
    local startZ = State.ChairsHide and 0 or 3.2

    chairFolder = Instance.new("Folder")
    chairFolder.Name = "DBCheatChairs"
    chairFolder.Parent = workspace

    for i = 0, n - 1 do
        local row = math.floor(i / perRow)
        local col = i % perRow
        local inRow = math.min(perRow, n - row * perRow)
        local x = (col - (inRow - 1) / 2) * spacingX
        local z = startZ + row * spacingZ
        local base = root.CFrame * CFrame.new(x, -1, z)

        local seat = Instance.new("Part")
        seat.Name = "Seat"
        seat.Size = Vector3.new(2, 0.4, 2)
        seat.Color = Color3.fromRGB(160, 105, 60)
        seat.Material = Enum.Material.Wood
        seat.CFrame = base

        local back = Instance.new("Part")
        back.Name = "Back"
        back.Size = Vector3.new(2, 2, 0.3)
        back.Color = Color3.fromRGB(255, 110, 40)
        back.Material = Enum.Material.Wood
        back.CFrame = base * CFrame.new(0, 1.2, 0.85)

        for _, p in ipairs({seat, back}) do
            p.Anchored = false
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.Massless = true
            p.CastShadow = false
            p.Parent = chairFolder
        end

        local w1 = Instance.new("WeldConstraint")
        w1.Part0 = root
        w1.Part1 = seat
        w1.Parent = seat
        local w2 = Instance.new("WeldConstraint")
        w2.Part0 = seat
        w2.Part1 = back
        w2.Parent = back
    end
    return true
end

-- ==================== ЛОГИКА: ПОЛЁТ + NOCLIP ====================
local function stopFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    local _, hum = getChar()
    if hum then hum.PlatformStand = false end
end

local function startFly()
    local _, hum, root = getChar()
    if not hum or not root then return false end
    stopFly()
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity = ZERO
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 9e4
    flyBG.CFrame = cam().CFrame
    flyBG.Parent = root
    hum.PlatformStand = true
    return true
end

table.insert(Conns, RunService.RenderStepped:Connect(function()
    if not State.Fly or not flyBV or not flyBG then return end
    if State.FreecamActive then
        flyBV.Velocity = ZERO
        return
    end
    local cf = cam().CFrame
    local dir = moveVector(cf)
    if dir.Magnitude > 0 then
        flyBV.Velocity = dir.Unit * Settings.FlySpeed
    else
        flyBV.Velocity = ZERO
    end
    if State.Chairs then
        -- со стульями держим персонажа ровно (только поворот влево-вправо)
        local lv = cf.LookVector
        local flat = Vector3.new(lv.X, 0, lv.Z)
        if flat.Magnitude > 0.05 then flyBG.CFrame = CFrame.new(ZERO, flat) end
    else
        flyBG.CFrame = cf
    end
end))

-- Noclip: запоминаем исходный CanCollide и ВОЗВРАЩАЕМ при выключении
-- (раньше детали оставались «проходимыми», пока не перезапустишь полёт)
local noclipOrig = {}
local noclipActive = false

local function restoreCollide()
    for part, was in pairs(noclipOrig) do
        if part and part.Parent then part.CanCollide = was end
    end
    noclipOrig = {}
end

table.insert(Conns, RunService.Stepped:Connect(function()
    if State.Fly and State.Noclip then
        local c = getChar()
        if not c then return end
        noclipActive = true
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                if noclipOrig[p] == nil then noclipOrig[p] = p.CanCollide end
                p.CanCollide = false
            end
        end
    elseif noclipActive then
        noclipActive = false
        restoreCollide()
    end
end))

table.insert(Conns, Player.CharacterAdded:Connect(function()
    noclipOrig = {}
    noclipActive = false
    if State.Fly and Toggles.Fly then Toggles.Fly.Set(false) end
end))

table.insert(Conns, Player.CharacterRemoving:Connect(function()
    if State.Chairs and Toggles.Chairs then Toggles.Chairs.Set(false) end
end))

-- ==================== ПРОЗРАЧНОСТЬ ПЕРСОНАЖА ====================
-- 1) Fly + Noclip: если между камерой и персонажем стена или персонаж внутри
--    стены, он становится полупрозрачным.
-- 2) Стулья + «Скрыть персонажа»: персонаж невидим.
local wallMod, lastMod = 0, 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() rayParams.RespectCanCollide = true end)
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function isObstructed(char, root)
    local c = cam()
    if not c then return false end
    local origin = c.CFrame.Position
    local ignore = {char}
    if chairFolder then table.insert(ignore, chairFolder) end

    for _ = 1, 4 do
        rayParams.FilterDescendantsInstances = ignore
        local hit = workspace:Raycast(origin, root.Position - origin, rayParams)
        if not hit then break end
        local inst = hit.Instance
        if isCharacterPart(inst) then
            local m = inst:FindFirstAncestorOfClass("Model")
            table.insert(ignore, m)
        elseif inst == workspace.Terrain or inst.Transparency < 0.95 then
            return true
        else
            table.insert(ignore, inst)
        end
    end

    overlapParams.FilterDescendantsInstances = ignore
    for _, p in ipairs(workspace:GetPartBoundsInRadius(root.Position, 2, overlapParams)) do
        if p.CanCollide and p.Transparency < 0.95 and not isCharacterPart(p) then
            return true
        end
    end
    return false
end

local function applyMod(char, mod)
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            d.LocalTransparencyModifier = mod
        elseif d:IsA("Decal") then
            pcall(function() d.LocalTransparencyModifier = mod end)
        end
    end
end

local function updateTransparency(dt)
    if Closing then return end
    local char, _, root = getChar()
    if not char or not root then return end

    local target = 0
    if State.Fly and State.Noclip then
        local ok, obstructed = pcall(isObstructed, char, root)
        if ok and obstructed then target = 0.75 end
    end
    wallMod = wallMod + (target - wallMod) * math.min(1, dt * 12)
    if math.abs(wallMod - target) < 0.01 then wallMod = target end

    local hideMod = (State.Chairs and State.ChairsHide) and 1 or 0
    local mod = math.max(wallMod, hideMod)
    if mod > 0 or lastMod > 0 then
        applyMod(char, mod)
    end
    lastMod = mod
end

pcall(function() RunService:UnbindFromRenderStep("DBCheatTransparency") end)
RunService:BindToRenderStep("DBCheatTransparency", Enum.RenderPriority.Camera.Value + 1, updateTransparency)

-- ==================== ЛОГИКА: ВИЗУАЛ ====================
table.insert(Conns, RunService.Heartbeat:Connect(function()
    if State.DayNightTouched then
        Lighting.ClockTime = State.IsNight and 0 or 14
    end
end))

local function clearESP()
    for _, h in pairs(highlights) do pcall(function() h:Destroy() end) end
    highlights = {}
end

local function updateESP()
    if not State.ESP then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Character then
            local h = highlights[p]
            if not h or h.Parent ~= p.Character then
                if h then h:Destroy() end
                h = Instance.new("Highlight")
                h.FillColor = Color3.fromRGB(255, 40, 40)
                h.OutlineColor = Color3.fromRGB(40, 120, 255)
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Adornee = p.Character
                h.Parent = p.Character
                highlights[p] = h
            end
        end
    end
    for p, h in pairs(highlights) do
        if not p.Parent then
            h:Destroy()
            highlights[p] = nil
        end
    end
end

task.spawn(function()
    while gui.Parent do
        pcall(updateESP)
        task.wait(0.5)
    end
end)

-- Freecam
local function sinkInput() return Enum.ContextActionResult.Sink end

local function stopFreecam()
    if not State.FreecamActive then return end
    State.FreecamActive = false
    CAS:UnbindAction("DBFreecamSink")
    UIS.MouseBehavior = Enum.MouseBehavior.Default
    cam().CameraType = Enum.CameraType.Custom
end

local function startFreecam()
    if State.FreecamActive or not State.FreecamArmed then return end
    State.FreecamActive = true
    local cf = cam().CFrame
    fcPos = cf.Position
    fcPitch, fcYaw = cf:ToOrientation()
    cam().CameraType = Enum.CameraType.Scriptable
    CAS:BindActionAtPriority("DBFreecamSink", sinkInput, false,
        Enum.ContextActionPriority.High.Value,
        Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
        Enum.KeyCode.Space, Enum.KeyCode.LeftControl, Enum.KeyCode.LeftShift)
end

table.insert(Conns, RunService.RenderStepped:Connect(function(dt)
    if not State.FreecamActive then return end
    local c = cam()
    c.CameraType = Enum.CameraType.Scriptable
    local rot = CFrame.fromOrientation(fcPitch, fcYaw, 0)
    local dir = moveVector(rot)
    local speed = Settings.FreecamSpeed * (UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
    if dir.Magnitude > 0 then fcPos = fcPos + dir.Unit * speed * dt end
    c.CFrame = CFrame.new(fcPos) * rot
end))

table.insert(Conns, UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and State.FreecamActive then
        fcRMB = true
        UIS.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
    end
end))
table.insert(Conns, UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        fcRMB = false
        if State.FreecamActive then UIS.MouseBehavior = Enum.MouseBehavior.Default end
    end
end))
table.insert(Conns, UIS.InputChanged:Connect(function(input)
    if State.FreecamActive and fcRMB and input.UserInputType == Enum.UserInputType.MouseMovement then
        fcYaw = fcYaw - input.Delta.X * 0.004
        fcPitch = math.clamp(fcPitch - input.Delta.Y * 0.004, -1.5, 1.5)
    end
end))

-- Телепорт: Ctrl + клик (только при включённом переключателе)
table.insert(Conns, UIS.InputBegan:Connect(function(input, gp)
    if gp or not State.Teleport then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not UIS:IsKeyDown(Enum.KeyCode.LeftControl) then return end
    if not Mouse.Target then return end
    local _, _, root = getChar()
    if root then
        root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        notify("📍 Телепорт выполнен")
    end
end))

-- ==================== ВКЛАДКИ ====================
-- Движение: в каждой строке название, поле значения и переключатель
local moveP = createTab("🏃 Движение")
Toggles.Speed = createToggle(moveP, "Скорость", function(v)
    local _, hum = getChar()
    if v then
        if hum and not State.Speed then Originals.WalkSpeed = hum.WalkSpeed end
    elseif hum then
        hum.WalkSpeed = Originals.WalkSpeed
    end
    State.Speed = v
end, nil, {key = "WalkSpeed", name = "Своя скорость"})

Toggles.JumpBoost = createToggle(moveP, "Высота прыжка", function(v)
    local _, hum = getChar()
    if v then
        if hum and not State.JumpBoost then Originals.JumpPower = hum.JumpPower end
    elseif hum then
        hum.JumpPower = Originals.JumpPower
    end
    State.JumpBoost = v
end, nil, {key = "JumpPower", name = "Своя высота прыжка"})

Toggles.InfJump = createToggle(moveP, "Беск. прыжок (высота)", function(v)
    State.InfJump = v
end, nil, {key = "InfJumpPower", name = "Бесконечный прыжок"})

createLabel(moveP, "Значение вводится в поле, функция включается переключателем справа.", 30)

-- Полёт
local flyP = createTab("🚀 Полёт")
createInput(flyP, "Скорость полёта", "FlySpeed")
Toggles.Fly = createToggle(flyP, "Полёт", function(v)
    if v then
        if startFly() then
            State.Fly = true
        else
            State.Fly = false
            task.defer(function()
                if Toggles.Fly then Toggles.Fly.Set(false) end
            end)
        end
    else
        State.Fly = false
        stopFly()
    end
    if Toggles.Noclip then Toggles.Noclip.Refresh() end
end)
Toggles.Noclip = createToggle(flyP, "Noclip", function(v)
    State.Noclip = v
end, function()
    if State.Noclip and not State.Fly then return " (с полётом)" end
    return ""
end)
Toggles.Chairs = createToggle(flyP, "Стулья (кол-во мест)", function(v)
    State.Chairs = v
    if v then
        if not buildChairs() then
            State.Chairs = false
            task.defer(function()
                if Toggles.Chairs then Toggles.Chairs.Set(false) end
            end)
        end
    else
        clearChairs()
    end
end, nil, {
    key = "ChairCount",
    name = "Стулья",
    onChange = function()
        if State.Chairs then buildChairs() end
    end,
})
Toggles.ChairsHide = createToggle(flyP, "Скрыть персонажа (стулья)", function(v)
    State.ChairsHide = v
    if State.Chairs then buildChairs() end
end)
createLabel(flyP, "WASD — движение, Space — вверх, Ctrl — вниз.\nNoclip работает только в полёте. Если за стеной персонаж оказывается между камерой и стеной или внутри неё, он становится полупрозрачным. Выбор Noclip запоминается и возвращается при следующем полёте.\nСтулья: 5 в ряд, следующие ряды идут назад. ⚠ Стулья создаются на вашей стороне: другие игроки их не увидят и сесть на них не смогут.", 130)

-- Визуал
local visP = createTab("👀 Визуал")
Toggles.ESP = createToggle(visP, "ESP (игроки)", function(v)
    State.ESP = v
    if v then pcall(updateESP) else clearESP() end
end)
Toggles.Freecam = createToggle(visP, "Freecam", function(v)
    State.FreecamArmed = v
    if not v then stopFreecam() end
end)
createInput(visP, "Скорость камеры", "FreecamSpeed")
createLabel(visP, "Freecam: включите функцию, затем нажмите назначенную клавишу. ПКМ — вращение, Shift — ускорение.", 40)

local function updateDnText()
    if dnBtn then
        dnBtn.Text = State.IsNight and "🌙 Ночь (нажмите для дня)" or "☀️ День (нажмите для ночи)"
    end
end
local function toggleDayNight()
    if not savedClock then savedClock = Lighting.ClockTime end
    State.DayNightTouched = true
    State.IsNight = not State.IsNight
    updateDnText()
    notify(State.IsNight and "🌙 Ночь" or "☀️ День")
    queueSave()
end
dnBtn = createButton(visP, "☀️ Сменить день / ночь", toggleDayNight)
Toggles.Teleport = createToggle(visP, "Teleport (Ctrl + клик)", function(v) State.Teleport = v end)

-- Телепорт к игрокам
local tpP = createTab("📍 К игрокам")

local function matchesQuery(p, q)
    if q == "" then return true end
    q = q:lower()
    return p.Name:lower():find(q, 1, true) ~= nil
        or p.DisplayName:lower():find(q, 1, true) ~= nil
end

local function findPlayer(query)
    local q = trim(query):lower()
    if q == "" then return nil end
    local partial
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local n, d = p.Name:lower(), p.DisplayName:lower()
            if n == q or d == q then return p end
            if not partial and (n:find(q, 1, true) or d:find(q, 1, true)) then
                partial = p
            end
        end
    end
    return partial
end

local function teleportToPlayer(p)
    local _, _, root = getChar()
    if not root then
        notify("⚠ Ваш персонаж не найден")
        return
    end
    local tc = p and p.Character
    local troot = tc and tc:FindFirstChild("HumanoidRootPart")
    if not troot then
        notify("⚠ Персонаж игрока не найден")
        return
    end
    root.CFrame = troot.CFrame * CFrame.new(0, 2, 4)
    notify("📍 Телепорт к " .. p.Name)
end

local searchRow = createRow(tpP)
local searchLbl = rowLabel(searchRow, "Ник")
searchLbl.Size = UDim2.new(0, 50, 1, 0)
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -76, 0, 24)
searchBox.Position = UDim2.new(0, 64, 0.5, -12)
searchBox.BackgroundColor3 = C.Bg
searchBox.TextColor3 = C.Accent
searchBox.PlaceholderText = "ник или часть ника"
searchBox.PlaceholderColor3 = C.Dim
searchBox.Font = Enum.Font.GothamBold
searchBox.TextSize = 14
searchBox.Text = ""
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchRow
round(searchBox, 6)

local function tpToQuery()
    local p = findPlayer(searchBox.Text)
    if not p then
        notify("⚠ Игрок не найден")
        return
    end
    teleportToPlayer(p)
end

createButton(tpP, "🎯 Телепорт к игроку", tpToQuery)
createLabel(tpP, "Введите ник (можно часть) и нажмите кнопку или Enter. Либо выберите игрока из списка ниже.", 40)

local listFrame = Instance.new("Frame")
listFrame.Name = "PlayerList"
listFrame.Size = UDim2.new(1, -8, 0, 0)
listFrame.AutomaticSize = Enum.AutomaticSize.Y
listFrame.BackgroundTransparency = 1
listFrame.LayoutOrder = nextOrder(tpP)
listFrame.Parent = tpP
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 4)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

local function refreshPlayerList()
    for _, ch in ipairs(listFrame:GetChildren()) do
        if not ch:IsA("UIListLayout") then ch:Destroy() end
    end
    local q = searchBox.Text
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player and p.Parent == Players and matchesQuery(p, q) then
            table.insert(list, p)
        end
    end
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)

    if #list == 0 then
        local e = Instance.new("TextLabel")
        e.Size = UDim2.new(1, 0, 0, 26)
        e.BackgroundTransparency = 1
        e.Text = "Игроков не найдено"
        e.TextColor3 = C.Dim
        e.Font = Enum.Font.Gotham
        e.TextSize = 13
        e.Parent = listFrame
        return
    end

    for i, p in ipairs(list) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = C.Row
        b.TextColor3 = C.Text
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 13
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.LayoutOrder = i
        if p.DisplayName == p.Name then
            b.Text = "  " .. p.Name
        else
            b.Text = "  " .. p.DisplayName .. "  (@" .. p.Name .. ")"
        end
        b.Parent = listFrame
        round(b, 6)
        b.MouseButton1Click:Connect(function() teleportToPlayer(p) end)
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(refreshPlayerList)
searchBox.FocusLost:Connect(function(enter)
    if enter then tpToQuery() end
end)
table.insert(Conns, Players.PlayerAdded:Connect(function()
    task.wait(0.3)
    refreshPlayerList()
end))
table.insert(Conns, Players.PlayerRemoving:Connect(function()
    task.delay(0.3, refreshPlayerList)
end))
refreshPlayerList()

-- Клавиши (только основные)
local keyP = createTab("🎹 Клавиши")
local waitingFor = nil
local keyButtons = {}
local keyList = {
    {"Speed", "Скорость"},
    {"Fly", "Полёт"},
    {"Freecam", "Freecam"},
    {"Menu", "Скрыть меню"},
}
for _, item in ipairs(keyList) do
    local id, label = item[1], item[2]
    local row = createRow(keyP)
    rowLabel(row, label)
    local kb = Instance.new("TextButton")
    kb.Size = UDim2.new(0, 110, 0, 24)
    kb.Position = UDim2.new(1, -122, 0.5, -12)
    kb.BackgroundColor3 = C.Bg
    kb.TextColor3 = C.Accent
    kb.Font = Enum.Font.GothamBold
    kb.TextSize = 12
    kb.Text = keyName(Keybinds[id])
    kb.Parent = row
    round(kb, 6)
    keyButtons[id] = kb
    kb.MouseButton1Click:Connect(function()
        if waitingFor and keyButtons[waitingFor] then
            keyButtons[waitingFor].Text = keyName(Keybinds[waitingFor])
        end
        waitingFor = id
        kb.Text = "нажмите..."
    end)
end
createLabel(keyP, "Нажмите на клавишу справа, затем новую кнопку. Escape — отмена. Остальные функции (прыжки, Noclip, стулья, день/ночь, телепорт) работают только через переключатели в меню.", 70)

createButton(keyP, "💾 Сохранить сейчас", function()
    if not canSave then
        notify("⚠ Сохранение не поддерживается в вашем executor")
    elseif noSave then
        notify("Сохранение отключено до перезапуска")
    elseif saveNow() then
        notify("💾 Настройки сохранены")
    else
        notify("⚠ Не удалось сохранить")
    end
end)
createButton(keyP, "🗑 Сбросить сохранение", function()
    if canSave and type(delfile) == "function" then
        pcall(function()
            if isfile(SAVE_FILE) then delfile(SAVE_FILE) end
        end)
        noSave = true
        notify("Сохранение удалено. Перезапустите чит")
    else
        notify("⚠ Удаление файлов не поддерживается")
    end
end)

selectTab("🏃 Движение")

-- ==================== ГОРЯЧИЕ КЛАВИШИ ====================
local Actions = {
    Speed = function() Toggles.Speed.Set(not Toggles.Speed.Get()) end,
    Fly = function() Toggles.Fly.Set(not Toggles.Fly.Get()) end,
    Freecam = function()
        if not State.FreecamArmed then
            notify("Сначала включите Freecam во вкладке Визуал")
            return
        end
        if State.FreecamActive then stopFreecam() else startFreecam() end
    end,
    Menu = function() frame.Visible = not frame.Visible end,
}

table.insert(Conns, UIS.InputBegan:Connect(function(input, gp)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    if waitingFor then
        local id = waitingFor
        waitingFor = nil
        if input.KeyCode ~= Enum.KeyCode.Escape then
            local taken
            for otherId, k in pairs(Keybinds) do
                if otherId ~= id and k == input.KeyCode then taken = otherId end
            end
            if taken then
                notify("Клавиша " .. keyName(input.KeyCode) .. " уже занята")
            else
                Keybinds[id] = input.KeyCode
                queueSave()
            end
        end
        keyButtons[id].Text = keyName(Keybinds[id])
        return
    end

    if gp then return end
    for id, key in pairs(Keybinds) do
        if input.KeyCode == key and Actions[id] then
            Actions[id]()
            break
        end
    end
end))

-- ==================== ПЕРЕТАСКИВАНИЕ ====================
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)
table.insert(Conns, UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                   startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end))
table.insert(Conns, UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
        dragging = false
        queueSave()
    end
end))

-- ==================== ЗАКРЫТИЕ ====================
local function Close()
    if Closing then return end
    saveNow() -- сохраняем до сброса переключателей
    Closing = true
    stopFreecam()
    for _, name in ipairs({"Speed", "JumpBoost", "InfJump", "Fly", "Chairs", "ESP", "Teleport"}) do
        if Toggles[name] then pcall(Toggles[name].Set, false) end
    end
    pcall(function() RunService:UnbindFromRenderStep("DBCheatTransparency") end)
    State.DayNightTouched = false
    if savedClock then pcall(function() Lighting.ClockTime = savedClock end) end
    stopFly()
    clearChairs()
    clearESP()
    restoreCollide()
    local char = getChar()
    if char then pcall(applyMod, char, 0) end
    for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
    if env.DBCheatId == myId then env.DBCheatRunning = false end
    gui:Destroy()
end

closeBtn.MouseButton1Click:Connect(Close)

-- Автозакрытие: если запущена новая копия (id изменился или выставлен флаг),
-- эта копия аккуратно закрывается. Закрывается и при удалении окна извне.
task.spawn(function()
    while true do
        if env.DBCheatClose == true or env.DBCheatId ~= myId or not gui.Parent then
            Close()
            break
        end
        task.wait(0.2)
    end
end)

-- ==================== ВОССТАНОВЛЕНИЕ СОХРАНЁННОГО ====================
if type(Saved.states) == "table" then
    for stateId, toggleId in pairs(ToggleOf) do
        if Saved.states[stateId] == true and Toggles[toggleId] then
            pcall(Toggles[toggleId].Set, true)
        end
    end
end
if type(Saved.dayNight) == "table" and Saved.dayNight.touched == true then
    savedClock = Lighting.ClockTime
    State.DayNightTouched = true
    State.IsNight = Saved.dayNight.night == true
    updateDnText()
end

Silent = false
if canSave then
    notify(next(Saved) and "🔥 DBCheat загружен, настройки восстановлены" or "🔥 DBCheat загружен")
else
    notify("🔥 DBCheat загружен (сохранение недоступно)")
end
