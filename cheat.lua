-- 🔥DBCheat🔥 v9
if not game:IsLoaded() then game.Loaded:Wait() end

-- ==================== АВТОЗАКРЫТИЕ СТАРОЙ ВЕРСИИ ====================
-- При повторном запуске старая копия сама закрывается (по id сессии и по флагу).
local env = shared
local myId = (tonumber(env.DBCheatId) or 0) + 1
env.DBCheatId = myId
if env.DBCheatRunning then
    env.DBCheatClose = true
    task.wait(0.35)
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
    Flinger = Enum.KeyCode.X,
    Menu = Enum.KeyCode.RightControl,
}

local Settings = {
    WalkSpeed = 40,
    JumpPower = 100,
    InfJumpPower = 40,
    FlySpeed = 60,
    FreecamSpeed = 60,
    ChairCount = 5,
    SplashMode = 1, -- 0 выкл, 1 быстрая, 2 полная
    GfxLevel = 3,   -- уровень низкой графики 1-3
    FlingPower = 50,
}

local Limits = {
    WalkSpeed = {0, 1000},
    JumpPower = {0, 1000},
    InfJumpPower = {0, 1000},
    FlySpeed = {0, 1000},
    FreecamSpeed = {0, 1000},
    ChairCount = {1, 50},
    SplashMode = {0, 2},
    GfxLevel = {1, 3},
    FlingPower = {1, 500},
}

local State = {
    Speed = false, JumpBoost = false, InfJump = false,
    Fly = false, Noclip = false,
    Chairs = false, ChairsHide = false, LowGfx = false, MM2 = false, Flinger = false,
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
local splashDone, onLoaded = false, nil
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
    LowGfx = "LowGfx", MM2 = "MM2",
}

-- При запуске все переключатели выключены (так меньше багов).
-- Запоминается только Noclip: он действует лишь во время полёта.
local RestoreStates = {Noclip = true}

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
    for stateId in pairs(RestoreStates) do states[stateId] = State[stateId] and true or false end
    local data = {
        version = SAVE_VERSION,
        settings = Settings,
        keys = keys,
        states = states,
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
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 560, 0, 400)
frame.Position = UDim2.new(0.5, -280, 0.5, -200)
frame.BackgroundColor3 = C.Bg
frame.BorderSizePixel = 0
frame.Parent = gui
frame.Visible = false -- покажем после приветствия
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

-- ==================== ЗАСТАВКА (ПРИВЕТСТВИЕ) ====================
-- Режимы (кнопка во вкладке «Клавиши»): 0 — выключена, 1 — быстрая (по умолчанию),
-- 2 — полная с эффектами. Клик по экрану пропускает заставку.
local frameScale = Instance.new("UIScale")
frameScale.Scale = 0.85
frameScale.Parent = frame

local splashAlive = false
local splashMode = math.clamp(math.floor(Settings.SplashMode), 0, 2)

local function circle(o)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0.5, 0)
    c.Parent = o
    return c
end

local function tw(obj, t, props, style, dir)
    TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local emberColors = {C.Accent, C.Accent2, Color3.fromRGB(255, 205, 90)}

local function runSplash()
    splashAlive = true
    local skipped = false
    local full = (splashMode == 2)
    local T
    if full then
        T = {intro = 0.5, letter = 0.07, sub = 0.45, bar = 0.3, progress = 2.4, fadeOut = 0.5, outWait = 0.55}
    else
        T = {intro = 0.25, letter = 0.03, sub = 0.12, bar = 0.1, progress = 0.7, fadeOut = 0.28, outWait = 0.32}
    end

    local group = Instance.new("CanvasGroup")
    group.Name = "Splash"
    group.Size = UDim2.new(1, 0, 1, 0)
    group.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    group.BackgroundTransparency = 0.12
    group.BorderSizePixel = 0
    group.GroupTransparency = 1
    group.ZIndex = 50
    group.Parent = gui

    local function alive() return not Closing and group.Parent ~= nil end
    local function sleep(t)
        local t0 = os.clock()
        while os.clock() - t0 < t and not skipped and alive() do task.wait() end
    end

    local embers = Instance.new("Frame")
    embers.Size = UDim2.new(1, 0, 1, 0)
    embers.BackgroundTransparency = 1
    embers.Parent = group
    local blur = nil

    -- тяжёлые эффекты только в полном режиме
    if full then
        -- фон медленно «дышит» цветом
        task.spawn(function()
            local c1 = Color3.fromRGB(8, 8, 14)
            local c2 = Color3.fromRGB(22, 10, 16)
            local t0 = os.clock()
            while splashAlive and alive() do
                local a = (math.sin((os.clock() - t0) * 0.6) + 1) / 2
                group.BackgroundColor3 = c1:Lerp(c2, a)
                task.wait()
            end
        end)

        -- виньетка: тёмные пульсирующие углы
        local vignette = Instance.new("Frame")
        vignette.Size = UDim2.new(1, 0, 1, 0)
        vignette.BackgroundTransparency = 1
        vignette.ZIndex = 15
        vignette.Parent = group
        local vg = Instance.new("UIGradient")
        vg.Rotation = 90
        vg.Parent = vignette
        task.spawn(function()
            while splashAlive and alive() do
                tw(vignette, 1.4, {BackgroundTransparency = 0.55})
                task.wait(1.4)
                if not (splashAlive and alive()) then break end
                tw(vignette, 1.4, {BackgroundTransparency = 0.8})
                task.wait(1.4)
            end
        end)
        vignette.BackgroundColor3 = Color3.new(0, 0, 0)

        -- редкие вспышки-молнии наискосок через весь экран
        task.spawn(function()
            while splashAlive and alive() do
                task.wait(0.6 + math.random() * 1.1)
                if not (splashAlive and alive()) then break end
                local bolt = Instance.new("Frame")
                bolt.AnchorPoint = Vector2.new(0.5, 0.5)
                bolt.Size = UDim2.new(0, 3, 0, 1400)
                bolt.Position = UDim2.new(math.random(), 0, 0.5, 0)
                bolt.Rotation = math.random(-25, 25)
                bolt.BackgroundColor3 = Color3.new(1, 1, 1)
                bolt.BackgroundTransparency = 0.25
                bolt.BorderSizePixel = 0
                bolt.ZIndex = 18
                bolt.Parent = group
                local bg = Instance.new("UIGradient")
                bg.Rotation = 90
                bg.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0.15),
                    NumberSequenceKeypoint.new(1, 1),
                })
                bg.Parent = bolt
                local tn = TweenService:Create(bolt,
                    TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {BackgroundTransparency = 1})
                tn.Completed:Connect(function() bolt:Destroy() end)
                tn:Play()
            end
        end)
        -- искры
        task.spawn(function()
            while splashAlive and alive() do
                local size = math.random(3, 9)
                local x = math.random()
                local e = Instance.new("Frame")
                e.AnchorPoint = Vector2.new(0.5, 0.5)
                e.Size = UDim2.new(0, size, 0, size)
                e.Position = UDim2.new(x, 0, 1.05, 0)
                e.BackgroundColor3 = emberColors[math.random(1, #emberColors)]
                e.BorderSizePixel = 0
                e.Parent = embers
                circle(e)
                local tn = TweenService:Create(e,
                    TweenInfo.new(2.2 + math.random() * 2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {
                        Position = UDim2.new(math.clamp(x + (math.random() - 0.5) * 0.25, 0, 1), 0, 0.1 + math.random() * 0.55, 0),
                        BackgroundTransparency = 1,
                    })
                tn.Completed:Connect(function() e:Destroy() end)
                tn:Play()
                task.wait(0.05)
            end
        end)

        -- вращающиеся лучи
        local rays = Instance.new("Frame")
        rays.AnchorPoint = Vector2.new(0.5, 0.5)
        rays.Position = UDim2.new(0.5, 0, 0.5, -110)
        rays.Size = UDim2.new(0, 760, 0, 760)
        rays.BackgroundTransparency = 1
        rays.Parent = group
        for i = 0, 11 do
            local bar = Instance.new("Frame")
            bar.AnchorPoint = Vector2.new(0.5, 0.5)
            bar.Position = UDim2.new(0.5, 0, 0.5, 0)
            bar.Size = UDim2.new(0, 5, 0, 760)
            bar.Rotation = i * 15
            bar.BackgroundColor3 = (i % 2 == 0) and C.Accent or C.Accent2
            bar.BackgroundTransparency = 0.65
            bar.BorderSizePixel = 0
            bar.Parent = rays
            local bg = Instance.new("UIGradient")
            bg.Rotation = 90
            bg.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            bg.Parent = bar
        end
        TweenService:Create(rays,
            TweenInfo.new(18, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            {Rotation = 360}):Play()

        -- волны
        task.spawn(function()
            task.wait(0.35)
            while splashAlive and alive() do
                local ring = Instance.new("Frame")
                ring.AnchorPoint = Vector2.new(0.5, 0.5)
                ring.Position = UDim2.new(0.5, 0, 0.5, -110)
                ring.Size = UDim2.new(0, 100, 0, 100)
                ring.BackgroundTransparency = 1
                ring.Parent = embers
                circle(ring)
                local st = Instance.new("UIStroke")
                st.Thickness = 3
                st.Color = C.Accent
                st.Transparency = 0.2
                st.Parent = ring
                tw(ring, 1.6, {Size = UDim2.new(0, 760, 0, 760)})
                local tn = TweenService:Create(st,
                    TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Transparency = 1})
                tn.Completed:Connect(function() ring:Destroy() end)
                tn:Play()
                task.wait(0.8)
            end
        end)

        -- звёздочки
        task.spawn(function()
            while splashAlive and alive() do
                local sp = Instance.new("TextLabel")
                sp.AnchorPoint = Vector2.new(0.5, 0.5)
                sp.Size = UDim2.new(0, 30, 0, 30)
                sp.Position = UDim2.new(0.5, math.random(-300, 300), 0.5, math.random(-230, 150))
                sp.BackgroundTransparency = 1
                sp.Text = "✦"
                sp.Font = Enum.Font.GothamBold
                sp.TextSize = math.random(10, 22)
                sp.TextColor3 = emberColors[math.random(1, #emberColors)]
                sp.TextTransparency = 1
                sp.Parent = embers
                local tn = TweenService:Create(sp,
                    TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true),
                    {TextTransparency = 0.05, Rotation = 90})
                tn.Completed:Connect(function() sp:Destroy() end)
                tn:Play()
                task.wait(0.1)
            end
        end)

        -- вспышка
        local flash = Instance.new("Frame")
        flash.Size = UDim2.new(1, 0, 1, 0)
        flash.BackgroundColor3 = Color3.fromRGB(255, 190, 120)
        flash.BackgroundTransparency = 0.35
        flash.BorderSizePixel = 0
        flash.ZIndex = 20
        flash.Parent = group
        tw(flash, 0.7, {BackgroundTransparency = 1})
        task.delay(0.8, function() flash:Destroy() end)

        -- размытие
        blur = Lighting:FindFirstChild("DBCheatBlur") or Instance.new("BlurEffect")
        blur.Name = "DBCheatBlur"
        blur.Size = 0
        blur.Parent = Lighting
        tw(blur, 0.6, {Size = 16})
    end

    -- логотип: свечение, два кольца и огонь
    local logo = Instance.new("Frame")
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0.5, 0, 0.5, -110)
    logo.Size = UDim2.new(0, 190, 0, 190)
    logo.BackgroundTransparency = 1
    logo.Parent = group
    local logoScale = Instance.new("UIScale")
    logoScale.Scale = 0.2
    logoScale.Parent = logo

    local glow = Instance.new("Frame")
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.Size = UDim2.new(0, 230, 0, 230)
    glow.BackgroundColor3 = C.Accent
    glow.BackgroundTransparency = 0.82
    glow.BorderSizePixel = 0
    glow.Parent = logo
    circle(glow)
    TweenService:Create(glow,
        TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {BackgroundTransparency = 0.94, Size = UDim2.new(0, 270, 0, 270)}):Play()

    local function makeRing(size, c1, c2, rotateTo, speed)
        local r = Instance.new("Frame")
        r.AnchorPoint = Vector2.new(0.5, 0.5)
        r.Position = UDim2.new(0.5, 0, 0.5, 0)
        r.Size = UDim2.new(0, size, 0, size)
        r.BackgroundTransparency = 1
        r.Parent = logo
        circle(r)
        local st = Instance.new("UIStroke")
        st.Thickness = 4
        st.Color = Color3.new(1, 1, 1)
        st.Parent = r
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new(c1, c2)
        g.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.55, 0),
            NumberSequenceKeypoint.new(0.6, 1),
            NumberSequenceKeypoint.new(1, 1),
        })
        g.Parent = st
        TweenService:Create(g,
            TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
            {Rotation = rotateTo}):Play()
        return r
    end
    makeRing(190, C.Accent, C.Accent2, 360, 1.6)
    makeRing(150, C.Accent2, Color3.fromRGB(255, 205, 90), -360, 2.2)

    if full then
        -- орбитальные искры вокруг логотипа, каждая на своей орбите
        for i = 1, 6 do
            local orbit = Instance.new("Frame")
            orbit.AnchorPoint = Vector2.new(0.5, 0.5)
            orbit.Position = UDim2.new(0.5, 0, 0.5, 0)
            orbit.Size = UDim2.new(0, 220 + i * 14, 0, 220 + i * 14)
            orbit.BackgroundTransparency = 1
            orbit.Rotation = (i / 6) * 360
            orbit.Parent = logo
            local dot = Instance.new("Frame")
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Position = UDim2.new(1, 0, 0.5, 0)
            dot.Size = UDim2.new(0, 7, 0, 7)
            dot.BackgroundColor3 = (i % 2 == 0) and C.Accent or C.Accent2
            dot.BackgroundTransparency = 0.15
            dot.BorderSizePixel = 0
            dot.Parent = orbit
            circle(dot)
            local dir = (i % 2 == 0) and 360 or -360
            TweenService:Create(orbit,
                TweenInfo.new(2.4 + i * 0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
                {Rotation = orbit.Rotation + dir}):Play()
        end
    end

    local flame = Instance.new("TextLabel")
    flame.Size = UDim2.new(1, 0, 1, 0)
    flame.BackgroundTransparency = 1
    flame.Text = "🔥"
    flame.TextSize = 70
    flame.Font = Enum.Font.GothamBlack
    flame.TextColor3 = Color3.new(1, 1, 1)
    flame.Parent = logo
    local flameScale = Instance.new("UIScale")
    flameScale.Parent = flame
    TweenService:Create(flameScale,
        TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Scale = 1.12}):Play()

    -- название
    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Position = UDim2.new(0.5, 0, 0.5, 10)
    title.Size = UDim2.new(0, 600, 0, 70)
    title.BackgroundTransparency = 1
    title.Text = "DBCheat"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 60
    title.Parent = group
    local titleGrad = fireGradient(title)
    TweenService:Create(titleGrad,
        TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1),
        {Rotation = 380}):Play()
    local titleStroke = Instance.new("UIStroke")
    titleStroke.Thickness = 2
    titleStroke.Color = C.Accent
    titleStroke.Transparency = 0.55
    titleStroke.Parent = title
    local titleScale = Instance.new("UIScale")
    titleScale.Parent = title
    local okTW = pcall(function() title.MaxVisibleGraphemes = 0 end)
    if not okTW then title.TextTransparency = 1 end

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0.5)
    sub.Position = UDim2.new(0.5, 0, 0.5, 72)
    sub.Size = UDim2.new(0, 600, 0, 28)
    sub.BackgroundTransparency = 1
    sub.Text = "DBCheat приветствует тебя, " .. Player.DisplayName .. "!"
    sub.TextColor3 = C.Text
    sub.TextTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 20
    sub.Parent = group

    -- полоса загрузки
    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(0.5, 0.5)
    track.Position = UDim2.new(0.5, 0, 0.5, 118)
    track.Size = UDim2.new(0, 340, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    track.BackgroundTransparency = 1
    track.BorderSizePixel = 0
    track.Parent = group
    round(track, 4)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.new(1, 1, 1)
    fill.BackgroundTransparency = 1
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, 4)
    fireGradient(fill).Rotation = 0

    local dot = Instance.new("Frame")
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(1, 0, 0.5, 0)
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.BackgroundColor3 = Color3.new(1, 1, 1)
    dot.BackgroundTransparency = 1
    dot.BorderSizePixel = 0
    dot.Parent = fill
    circle(dot)
    local dotStroke = Instance.new("UIStroke")
    dotStroke.Thickness = 4
    dotStroke.Color = C.Accent
    dotStroke.Transparency = 1
    dotStroke.Parent = dot

    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0.5)
    status.Position = UDim2.new(0.5, 0, 0.5, 140)
    status.Size = UDim2.new(0, 340, 0, 20)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = C.Dim
    status.TextTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.Parent = group

    local hint = Instance.new("TextLabel")
    hint.AnchorPoint = Vector2.new(0.5, 1)
    hint.Position = UDim2.new(0.5, 0, 1, -24)
    hint.Size = UDim2.new(0, 300, 0, 18)
    hint.BackgroundTransparency = 1
    hint.Text = "нажмите, чтобы пропустить"
    hint.TextColor3 = C.Dim
    hint.TextTransparency = 1
    hint.Font = Enum.Font.Gotham
    hint.TextSize = 12
    hint.Parent = group

    local skipBtn = Instance.new("TextButton")
    skipBtn.Size = UDim2.new(1, 0, 1, 0)
    skipBtn.BackgroundTransparency = 1
    skipBtn.Text = ""
    skipBtn.ZIndex = 100
    skipBtn.Parent = group
    skipBtn.MouseButton1Click:Connect(function() skipped = true end)

    -- ===== сценарий =====
    tw(group, full and 0.35 or 0.2, {GroupTransparency = 0})
    tw(logoScale, full and 0.7 or 0.4, {Scale = 1}, Enum.EasingStyle.Back)
    sleep(T.intro)
    if not alive() then return end

    if full then
        task.spawn(function()
            local base = group.Position
            for _ = 1, 10 do
                if skipped or not alive() then break end
                group.Position = base + UDim2.new(0, math.random(-3, 3), 0, math.random(-3, 3))
                task.wait(0.05)
            end
            group.Position = base
        end)
    end
    if okTW then
        for i = 1, 7 do
            if skipped or not alive() then break end
            title.MaxVisibleGraphemes = i
            titleScale.Scale = 1.08
            tw(titleScale, 0.14, {Scale = 1})
            sleep(T.letter)
        end
        title.MaxVisibleGraphemes = -1
    else
        tw(title, 0.3, {TextTransparency = 0})
    end
    tw(sub, full and 0.5 or 0.25, {TextTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 62)})
    sleep(T.sub)
    tw(track, 0.2, {BackgroundTransparency = 0})
    tw(fill, 0.2, {BackgroundTransparency = 0})
    tw(dot, 0.2, {BackgroundTransparency = 0.05})
    tw(dotStroke, 0.2, {Transparency = 0.5})
    tw(status, 0.2, {TextTransparency = 0})
    tw(hint, 0.2, {TextTransparency = 0.35})
    sleep(T.bar)
    if not alive() then return end

    local stages = {
        {0.00, "Инициализация модулей..."},
        {0.30, "Загрузка настроек..."},
        {0.60, "Подготовка интерфейса..."},
        {0.90, "Почти готово..."},
    }
    local t0 = os.clock()
    while alive() and not skipped do
        local a = math.min(1, (os.clock() - t0) / T.progress)
        local e = TweenService:GetValue(a, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        fill.Size = UDim2.new(e, 0, 1, 0)
        local label = stages[1][2]
        for _, st in ipairs(stages) do
            if e >= st[1] then label = st[2] end
        end
        status.Text = label .. " " .. math.floor(e * 100) .. "%"
        if a >= 1 then break end
        task.wait()
    end
    if not alive() then return end

    fill.Size = UDim2.new(1, 0, 1, 0)
    status.Text = "Готово! 100%"
    status.TextColor3 = C.Accent
    if full then
        -- ударная волна
        local shock = Instance.new("Frame")
        shock.AnchorPoint = Vector2.new(0.5, 0.5)
        shock.Position = UDim2.new(0.5, 0, 0.5, -110)
        shock.Size = UDim2.new(0, 40, 0, 40)
        shock.BackgroundTransparency = 1
        shock.ZIndex = 19
        shock.Parent = group
        circle(shock)
        local shockStroke = Instance.new("UIStroke")
        shockStroke.Thickness = 6
        shockStroke.Color = Color3.new(1, 1, 1)
        shockStroke.Parent = shock
        tw(shock, 0.5, {Size = UDim2.new(0, 900, 0, 900)}, Enum.EasingStyle.Quad)
        local sTn = TweenService:Create(shockStroke,
            TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Transparency = 1})
        sTn.Completed:Connect(function() shock:Destroy() end)
        sTn:Play()

        for i = 1, 28 do
            local ang = (i / 28) * math.pi * 2 + math.random() * 0.2
            local dist = 180 + math.random() * 160
            local sz = math.random(4, 8)
            local b = Instance.new("Frame")
            b.AnchorPoint = Vector2.new(0.5, 0.5)
            b.Position = UDim2.new(0.5, 0, 0.5, -110)
            b.Size = UDim2.new(0, sz, 0, sz)
            b.BackgroundColor3 = emberColors[math.random(1, #emberColors)]
            b.BorderSizePixel = 0
            b.Parent = group
            circle(b)
            local tn = TweenService:Create(b,
                TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {
                    Position = UDim2.new(0.5, math.cos(ang) * dist, 0.5, -110 + math.sin(ang) * dist),
                    BackgroundTransparency = 1,
                })
            tn.Completed:Connect(function() b:Destroy() end)
            tn:Play()
        end
        tw(logoScale, 0.18, {Scale = 1.18}, Enum.EasingStyle.Back)
        task.wait(0.2)
        tw(logoScale, 0.25, {Scale = 1})
        sleep(0.3)
    else
        sleep(0.05)
    end
    tw(group, T.fadeOut, {GroupTransparency = 1})
    if blur then tw(blur, T.fadeOut, {Size = 0}) end
    task.wait(T.outWait)
    splashAlive = false
    group:Destroy()
    if blur then blur:Destroy() end
end

task.spawn(function()
    if splashMode ~= 0 then pcall(runSplash) end
    splashAlive = false
    pcall(function()
        local b = Lighting:FindFirstChild("DBCheatBlur")
        if b then b:Destroy() end
    end)
    local g = gui:FindFirstChild("Splash")
    if g then g:Destroy() end
    if Closing then return end

    if splashMode == 0 then
        frameScale.Scale = 1
        frame.Visible = true
    else
        -- меню появляется с «выпрыгиванием»
        local base = frame.Position
        frame.Visible = true
        local popTime = (splashMode == 2) and 0.4 or 0.25
        local t1 = os.clock()
        while not Closing do
            local a = math.min(1, (os.clock() - t1) / popTime)
            local sc = 0.85 + 0.15 * TweenService:GetValue(a, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            frameScale.Scale = sc
            frame.Position = UDim2.new(base.X.Scale, base.X.Offset + (1 - sc) * 280,
                                       base.Y.Scale, base.Y.Offset + (1 - sc) * 200)
            if a >= 1 then break end
            task.wait()
        end
        frameScale.Scale = 1
        frame.Position = base
    end
    frameScale:Destroy()
    splashDone = true
    if onLoaded then onLoaded() end
end)

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

-- ==================== ФЛИНГЕР ====================
-- Работает незаметно: вы сами стоите и ходите как обычно (персонаж
-- не раскручивается и не меняется), а игроков, которые вас коснутся,
-- отбрасывает импульсом. Noclip не мешает, т.к. это не физика столкновений
-- вашего тела, а точечный импульс конкретному игроку при касании.
local flingerConns = {}
local flingerCooldown = {}

local function flingPlayer(victim)
    local vChar = victim.Character
    if not vChar then return end
    local vRoot = vChar:FindFirstChild("HumanoidRootPart")
    local vHum = vChar:FindFirstChildOfClass("Humanoid")
    if not vRoot or not vHum then return end

    local now = os.clock()
    if flingerCooldown[victim] and now - flingerCooldown[victim] < 0.4 then return end
    flingerCooldown[victim] = now

    local _, _, myRoot = getChar()
    local away = ZERO
    if myRoot then
        away = vRoot.Position - myRoot.Position
    end
    away = Vector3.new(away.X, 0, away.Z)
    if away.Magnitude < 0.05 then
        local a = math.random() * math.pi * 2
        away = Vector3.new(math.cos(a), 0, math.sin(a))
    else
        away = away.Unit
    end

    local power = Settings.FlingPower
    local vel = away * (power * 3) + Vector3.new(0, power * 2.2, 0)

    local bv = Instance.new("BodyVelocity")
    bv.Name = "DBFling"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.P = 1250
    bv.Velocity = vel
    bv.Parent = vRoot

    local wasPlatform = vHum.PlatformStand
    vHum.PlatformStand = true
    task.delay(0.15, function()
        if vHum and vHum.Parent then vHum.PlatformStand = wasPlatform end
    end)
    task.delay(0.25, function()
        if bv then bv:Destroy() end
    end)
end

local function clearFlingerTouch()
    for _, c in ipairs(flingerConns) do pcall(function() c:Disconnect() end) end
    flingerConns = {}
end

local function setupFlingerTouch()
    clearFlingerTouch()
    local char = Player.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local c = part.Touched:Connect(function(hit)
                if not State.Flinger then return end
                if hit:IsDescendantOf(char) then return end
                local m = hit:FindFirstAncestorOfClass("Model")
                if not m then return end
                local victim = Players:GetPlayerFromCharacter(m)
                if victim and victim ~= Player then
                    flingPlayer(victim)
                end
            end)
            table.insert(flingerConns, c)
        end
    end
end


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
    if State.Flinger then task.defer(setupFlingerTouch) end
end))

table.insert(Conns, Player.CharacterRemoving:Connect(function()
    if State.Chairs and Toggles.Chairs then Toggles.Chairs.Set(false) end
    clearFlingerTouch()
end))

-- ==================== ПРОЗРАЧНОСТЬ ====================
-- 1) Fly + Noclip: полупрозрачными становятся БЛОКИ, которых касается персонаж,
--    и блоки, закрывающие его от камеры. Персонаж остаётся виден.
--    (Только у вас на экране; ландшафт Terrain сделать прозрачным нельзя.)
-- 2) Стулья + «Скрыть персонажа»: персонаж невидим.
local WALL_ALPHA = 0.75
local faded = {}
local hideLast = 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
pcall(function() rayParams.RespectCanCollide = true end)
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function collectWallParts(char, root)
    local set = {}
    local ignore = {char}
    if chairFolder then table.insert(ignore, chairFolder) end

    -- блоки между камерой и персонажем
    local c = cam()
    if c then
        local origin = c.CFrame.Position
        local toRoot = root.Position - origin
        for _ = 1, 8 do
            rayParams.FilterDescendantsInstances = ignore
            local hit = workspace:Raycast(origin, toRoot, rayParams)
            if not hit then break end
            local inst = hit.Instance
            if isCharacterPart(inst) then
                table.insert(ignore, inst:FindFirstAncestorOfClass("Model"))
            else
                table.insert(ignore, inst)
                if inst ~= workspace.Terrain and inst.Transparency < 0.95 then
                    set[inst] = true
                end
            end
        end
    end

    -- блоки, которых касается персонаж
    overlapParams.FilterDescendantsInstances = ignore
    local parts = workspace:GetPartBoundsInBox(root.CFrame, Vector3.new(6, 7, 6), overlapParams)
    for _, p in ipairs(parts) do
        if not p:IsA("Terrain") and p.CanCollide and p.Transparency < 0.95
            and not isCharacterPart(p) then
            set[p] = true
        end
    end
    return set
end

-- плавно прячем блоки из set и возвращаем остальные
local function fadeWalls(dt, set)
    for p in pairs(set) do
        if faded[p] == nil then faded[p] = 0 end
    end
    local k = math.min(1, dt * 12)
    for p, cur in pairs(faded) do
        if not p.Parent then
            faded[p] = nil
        else
            local target = set[p] and WALL_ALPHA or 0
            local new = cur + (target - cur) * k
            if math.abs(new - target) < 0.01 then new = target end
            p.LocalTransparencyModifier = new
            if new == 0 and not set[p] then faded[p] = nil else faded[p] = new end
        end
    end
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
    if not (State.Fly and State.Noclip) and next(faded) == nil
        and not (State.Chairs and State.ChairsHide) and hideLast == 0 then
        return
    end
    local char, _, root = getChar()

    local set = {}
    if char and root and State.Fly and State.Noclip then
        local ok, res = pcall(collectWallParts, char, root)
        if ok and res then set = res end
    end
    fadeWalls(dt, set)

    if char then
        local hideMod = (State.Chairs and State.ChairsHide) and 1 or 0
        if hideMod > 0 or hideLast > 0 then applyMod(char, hideMod) end
        hideLast = hideMod
    end
end

pcall(function() RunService:UnbindFromRenderStep("DBCheatTransparency") end)
RunService:BindToRenderStep("DBCheatTransparency", Enum.RenderPriority.Camera.Value + 1, updateTransparency)

-- ==================== ПОНИЖЕНИЕ ГРАФИКИ ====================
-- Уровни: 1 — базовый, 2 — сильный, 3 — максимальный (самый высокий FPS).
-- Меняется только на вашей стороне, при выключении всё возвращается.
local gfx = {
    saved = setmetatable({}, {__mode = "k"}),
    detached = {},
    token = 0,
    active = false,
    conn = nil,
    quality = nil,
}

local function getProp(i, p) return i[p] end
local function setProp(i, p, v) i[p] = v end

local function gfxSet(inst, prop, value)
    local rec = gfx.saved[inst]
    if not rec then
        rec = {}
        gfx.saved[inst] = rec
    end
    if rec[prop] == nil then
        local ok, old = pcall(getProp, inst, prop)
        if not ok or old == nil then return end
        rec[prop] = old
    end
    pcall(setProp, inst, prop, value)
end

local SMOOTH = Enum.Material.SmoothPlastic

local function lowGfxInstance(inst, lvl)
    if inst:IsA("BasePart") then
        if inst:IsA("Terrain") then return end
        if inst.Material ~= SMOOTH then gfxSet(inst, "Material", SMOOTH) end
        if inst.Reflectance ~= 0 then gfxSet(inst, "Reflectance", 0) end
        if inst.CastShadow then gfxSet(inst, "CastShadow", false) end
        if lvl >= 2 and inst:IsA("MeshPart") then
            gfxSet(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
        end
    elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
        or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
        gfxSet(inst, "Enabled", false)
    elseif inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
        if lvl >= 3 then
            gfxSet(inst, "Enabled", false)
        else
            gfxSet(inst, "Shadows", false)
        end
    elseif inst:IsA("Texture") or inst:IsA("Decal") then
        if not isCharacterPart(inst) then gfxSet(inst, "Transparency", 1) end
    elseif lvl >= 2 and inst:IsA("SurfaceAppearance") then
        local par = inst.Parent
        if par then
            table.insert(gfx.detached, {inst, par})
            inst.Parent = nil
        end
    elseif lvl >= 3 and inst:IsA("Accessory") then
        local h = inst:FindFirstChild("Handle")
        if h then gfxSet(h, "Transparency", 1) end
    end
end

local function applyLowGfxGlobals(lvl)
    pcall(function()
        local r = settings().Rendering
        if gfx.quality == nil then gfx.quality = r.QualityLevel end
        r.QualityLevel = Enum.QualityLevel.Level01
    end)
    gfxSet(Lighting, "GlobalShadows", false)
    gfxSet(Lighting, "ShadowSoftness", 0)
    if lvl >= 2 then
        gfxSet(Lighting, "EnvironmentDiffuseScale", 0)
        gfxSet(Lighting, "EnvironmentSpecularScale", 0)
    end
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("PostEffect") then
            gfxSet(e, "Enabled", false)
        elseif lvl >= 2 and e:IsA("Atmosphere") then
            gfxSet(e, "Density", 0)
            gfxSet(e, "Haze", 0)
            gfxSet(e, "Glare", 0)
        elseif lvl >= 3 and e:IsA("Sky") then
            gfxSet(e, "StarCount", 0)
            gfxSet(e, "CelestialBodiesShown", false)
        end
    end
    local c = cam()
    if c then
        for _, e in ipairs(c:GetChildren()) do
            if e:IsA("PostEffect") then gfxSet(e, "Enabled", false) end
        end
    end
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then
        gfxSet(t, "Decoration", false)
        gfxSet(t, "WaterWaveSize", 0)
        gfxSet(t, "WaterWaveSpeed", 0)
        gfxSet(t, "WaterReflectance", 0)
        if lvl >= 2 then
            for _, e in ipairs(t:GetChildren()) do
                if e:IsA("Clouds") then gfxSet(e, "Enabled", false) end
            end
        end
    end
end

-- возвращает всё как было (порциями); false, если прервано
local function restoreAll(token)
    local n = 0
    for inst, props in pairs(gfx.saved) do
        if token ~= gfx.token then return false end
        for prop, v in pairs(props) do
            pcall(setProp, inst, prop, v)
        end
        gfx.saved[inst] = nil
        n = n + 1
        if n % 500 == 0 then task.wait() end
    end
    for i = #gfx.detached, 1, -1 do
        local d = gfx.detached[i]
        pcall(setProp, d[1], "Parent", d[2])
        gfx.detached[i] = nil
    end
    if gfx.quality ~= nil then
        pcall(function() settings().Rendering.QualityLevel = gfx.quality end)
        gfx.quality = nil
    end
    return true
end

-- on = true: применить уровень Settings.GfxLevel (при смене уровня сначала откат)
local function setLowGfx(on)
    gfx.token = gfx.token + 1
    local token = gfx.token
    gfx.active = false
    if gfx.conn then
        pcall(function() gfx.conn:Disconnect() end)
        gfx.conn = nil
    end
    local lvl = math.clamp(math.floor(Settings.GfxLevel), 1, 3)

    task.spawn(function()
        if not restoreAll(token) then return end
        if not on or token ~= gfx.token then return end
        gfx.active = true
        applyLowGfxGlobals(lvl)
        gfx.conn = workspace.DescendantAdded:Connect(function(inst)
            if gfx.active and not Closing then
                task.defer(function() pcall(lowGfxInstance, inst, lvl) end)
            end
        end)
        local n = 0
        for _, inst in ipairs(workspace:GetDescendants()) do
            if token ~= gfx.token then return end
            pcall(lowGfxInstance, inst, lvl)
            n = n + 1
            if n % 500 == 0 then task.wait() end
        end
    end)
end

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

-- ESP для Murder Mystery 2: роли определяются по предметам игрока.
-- Нож (Knife) = убийца (красный), пистолет (Gun) = шериф (синий), остальные = мирные (зелёные).
local MM2 = {}
local MM2_ROLES = {
    murderer = {Color3.fromRGB(255, 40, 40), "УБИЙЦА"},
    sheriff = {Color3.fromRGB(40, 120, 255), "ШЕРИФ"},
    innocent = {Color3.fromRGB(60, 220, 90), "МИРНЫЙ"},
}

local function mm2Flags(p)
    local knife, gun = false, false
    local function scan(container)
        if not container then return end
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife", 1, true) then knife = true end
                if n:find("gun", 1, true) or n:find("revolver", 1, true) then gun = true end
            end
        end
    end
    scan(p.Character)
    scan(p:FindFirstChildOfClass("Backpack"))
    return knife, gun
end

local function destroyMM2Item(p)
    local item = MM2[p]
    if item then
        pcall(function() item.hl:Destroy() end)
        pcall(function() item.bb:Destroy() end)
        MM2[p] = nil
    end
end

local function clearMM2()
    for p in pairs(MM2) do destroyMM2Item(p) end
end

local function updateMM2()
    if not State.MM2 then return end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
            if not (char and hum and head) or hum.Health <= 0 then
                destroyMM2Item(p)
            else
                local item = MM2[p]
                if not item or item.char ~= char then
                    destroyMM2Item(p)
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 0.45
                    hl.OutlineTransparency = 0
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Adornee = char
                    hl.Parent = char
                    local bb = Instance.new("BillboardGui")
                    bb.Size = UDim2.new(0, 140, 0, 36)
                    bb.StudsOffset = Vector3.new(0, 3.2, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = head
                    bb.Parent = char
                    local lbl = Instance.new("TextLabel")
                    lbl.Size = UDim2.new(1, 0, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamBold
                    lbl.TextSize = 13
                    lbl.TextStrokeTransparency = 0.3
                    lbl.Parent = bb
                    item = {char = char, hl = hl, bb = bb, lbl = lbl}
                    MM2[p] = item
                end
                local knife, gun = mm2Flags(p)
                local role = knife and MM2_ROLES.murderer or (gun and MM2_ROLES.sheriff or MM2_ROLES.innocent)
                item.hl.FillColor = role[1]
                item.hl.OutlineColor = role[1]
                item.lbl.TextColor3 = role[1]
                item.lbl.Text = p.Name .. "\n" .. role[2]
            end
        end
    end
    for p in pairs(MM2) do
        if not p.Parent then destroyMM2Item(p) end
    end
end

task.spawn(function()
    while gui.Parent do
        pcall(updateESP)
        pcall(updateMM2)
        task.wait(0.3)
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
Toggles.Flinger = createToggle(flyP, "Флингер (сила)", function(v)
    State.Flinger = v
    if v then
        setupFlingerTouch()
    else
        clearFlingerTouch()
        flingerCooldown = {}
    end
end, nil, {key = "FlingPower", name = "Флингер"})
Toggles.Chairs = createToggle(flyP, "Стулья: места (только у вас)", function(v)
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
createLabel(flyP, "WASD — движение, Space — вверх, Ctrl — вниз.\nNoclip работает только в полёте: блоки, которых касается персонаж или которые закрывают его от камеры, становятся полупрозрачными, а персонаж остаётся виден. Ландшафт (Terrain) прозрачным сделать нельзя. Выбор Noclip запоминается и возвращается при следующем полёте.\nФлингер: работает незаметно — вы спокойно стоите и ходите, а игроков, которые вас коснутся, отбрасывает. Сила 1–500 задаётся в поле, действует на земле и в полёте. Результат зависит от игры.\nСтулья: 5 в ряд, следующие ряды идут назад. ⚠ Стулья создаются только на вашей стороне: другие игроки их не видят и сесть на них не смогут (ограничение Roblox, скриптом не обходится).", 200)

-- Визуал
local visP = createTab("👀 Визуал")
Toggles.ESP = createToggle(visP, "ESP (игроки)", function(v)
    State.ESP = v
    if v then
        if State.MM2 and Toggles.MM2 then Toggles.MM2.Set(false) end
        pcall(updateESP)
    else
        clearESP()
    end
end)
Toggles.MM2 = createToggle(visP, "ESP MM2 (роли)", function(v)
    State.MM2 = v
    if v then
        if State.ESP and Toggles.ESP then Toggles.ESP.Set(false) end
        pcall(updateMM2)
    else
        clearMM2()
    end
end)
createLabel(visP, "MM2: убийца (нож) — красный, шериф (пистолет) — синий, мирные — зелёные. Роль определяется по предметам Knife и Gun у игрока (в руках или в рюкзаке). Если предмет лежит в рюкзаке и игра не передаёт его вам, роль появится, когда игрок достанет предмет. ESP и ESP MM2 включаются по очереди.", 85)
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
Toggles.LowGfx = createToggle(visP, "Низкая графика (уровень 1-3)", function(v)
    State.LowGfx = v
    setLowGfx(v)
end, nil, {
    key = "GfxLevel",
    name = "Низкая графика",
    onChange = function()
        if State.LowGfx then setLowGfx(true) end
    end,
})
createLabel(visP, "Уровень 1: без теней, эффектов и частиц, простые материалы, текстуры скрыты.\nУровень 2: ещё упрощённые модели, без PBR-текстур, дымки и облаков.\nУровень 3 (макс. FPS): ещё выключены источники света, скрыты аксессуары, нет звёзд. Уровень можно менять на лету. Действует только у вас, при выключении всё возвращается; на больших картах применяется порциями несколько секунд.", 120)

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
    {"Flinger", "Флингер"},
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

local splashNames = {[0] = "выключена", [1] = "быстрая", [2] = "полная"}
local splashBtn
splashBtn = createButton(keyP, "🎬 Заставка: " .. splashNames[splashMode], function()
    Settings.SplashMode = (math.clamp(math.floor(Settings.SplashMode), 0, 2) + 1) % 3
    splashBtn.Text = "🎬 Заставка: " .. splashNames[Settings.SplashMode]
    queueSave()
    notify("Заставка: " .. splashNames[Settings.SplashMode] .. " (со следующего запуска)")
end)
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
    Flinger = function() Toggles.Flinger.Set(not Toggles.Flinger.Get()) end,
    Freecam = function()
        if not State.FreecamArmed then
            notify("Сначала включите Freecam во вкладке Визуал")
            return
        end
        if State.FreecamActive then stopFreecam() else startFreecam() end
    end,
    Menu = function()
        if splashDone then frame.Visible = not frame.Visible end
    end,
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
    for _, name in ipairs({"Speed", "JumpBoost", "InfJump", "Fly", "Flinger", "Chairs", "ESP", "MM2", "Teleport", "LowGfx"}) do
        if Toggles[name] then pcall(Toggles[name].Set, false) end
    end
    clearFlingerTouch()
    pcall(function() RunService:UnbindFromRenderStep("DBCheatTransparency") end)
    State.DayNightTouched = false
    if savedClock then pcall(function() Lighting.ClockTime = savedClock end) end
    stopFly()
    clearChairs()
    clearESP()
    clearMM2()
    pcall(function()
        local b = Lighting:FindFirstChild("DBCheatBlur")
        if b then b:Destroy() end
    end)
    restoreCollide()
    for part in pairs(faded) do pcall(function() part.LocalTransparencyModifier = 0 end) end
    faded = {}
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
        task.wait(0.1)
    end
end)

-- ==================== ВОССТАНОВЛЕНИЕ СОХРАНЁННОГО ====================
if type(Saved.states) == "table" then
    for stateId, toggleId in pairs(ToggleOf) do
        if RestoreStates[stateId] and Saved.states[stateId] == true and Toggles[toggleId] then
            pcall(Toggles[toggleId].Set, true)
        end
    end
end

local function loadedNotice()
    Silent = false
    if canSave then
        notify(next(Saved) and "🔥 DBCheat загружен, настройки восстановлены" or "🔥 DBCheat загружен")
    else
        notify("🔥 DBCheat загружен (сохранение недоступно)")
    end
end
if splashDone then loadedNotice() else onLoaded = loadedNotice end
