-- DB_CHEAT | ULTIMATE CHEAT MENU
-- ПОЛНАЯ ВЕРСИЯ (ТЕЛЕПОРТ + УБИЙСТВО С ЭФФЕКТАМИ + ВСЕ ФУНКЦИИ)
-- Автоматическое закрытие старой версии при повторном запуске
-- ИСПРАВЛЕНА РАЗБЛОКИРОВКА МЫШИ

if shared.DBCheatRunning then
    shared.DBCheatClose = true
    task.wait(0.5)
end

shared.DBCheatRunning = true
shared.DBCheatClose = false

local Player = game:GetService("Players").LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local Mouse = Player:GetMouse()
local GuiService = game:GetService("GuiService")

-- НАСТРОЙКИ КЛАВИШ
local Keybinds = {
    Fly = Enum.KeyCode.F,
    Sprint = Enum.KeyCode.R,
    Menu = Enum.KeyCode.RightControl,
    UnlockMouse = Enum.KeyCode.M
}

local function GetKeyName(keyCode)
    local name = tostring(keyCode):gsub("Enum.KeyCode.", "")
    if name == "LeftControl" then return "Ctrl"
    elseif name == "LeftShift" then return "Shift"
    elseif name == "Space" then return "Space"
    elseif name == "RightControl" then return "Right Ctrl"
    else return name end
end

-- СОСТОЯНИЯ
local Bober = {
    WS = 40, FS = 50, SS = 60,
    isFly = false, isNoc = false, isWall = false, 
    isEsp = false, isMM2 = false, isFog = false, isFree = false,
    isSpeedActive = false,
    isJumpActive = false,
    isSprintActive = false,
    isGodMode = false,
    isCtrlClickTeleport = false,
    isBanHammer = false,
    isChairMode = false,
    isSpinBlock = false,
    isFlinger = false,
    isMouseUnlocked = false,
    Target = nil, Active = true
}

local Fly_Conn
local notificationShown = false
local lastTouched = {}
local isSprinting = false
local waitingForKey = nil
local godModeConnection = nil
local spinConnection = nil
local originalCharacterState = {}
local spinBlockModel = nil
local flingerConnections = {}
local banHammerConnections = {}

-- ==================== РАЗБЛОКИРОВКА МЫШИ (ИСПРАВЛЕНА) ====================
local function ToggleMouseUnlock()
    Bober.isMouseUnlocked = not Bober.isMouseUnlocked
    
    if Bober.isMouseUnlocked then
        -- Разблокируем мышь через UserInputService
        pcall(function()
            UIS.MouseBehavior = Enum.MouseBehavior.Default
            UIS.MouseIconEnabled = true
        end)
        
        -- Показываем курсор через GuiService
        pcall(function()
            GuiService.MouseIconEnabled = true
        end)
        
        -- Создаём визуальный индикатор
        local gui = Instance.new("ScreenGui")
        gui.Name = "MouseUnlockIndicator"
        gui.Parent = Player:WaitForChild("PlayerGui")
        gui.ResetOnSpawn = false
        
        local frame = Instance.new("Frame", gui)
        frame.Size = UDim2.new(0, 200, 0, 40)
        frame.Position = UDim2.new(0.5, -100, 0.9, 0)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.5
        local corner = Instance.new("UICorner", frame)
        corner.CornerRadius = UDim.new(0, 10)
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.Text = "🖱️ МЫШЬ РАЗБЛОКИРОВАНА"
        label.TextColor3 = Color3.fromRGB(100, 255, 100)
        label.BackgroundTransparency = 1
        label.Font = "GothamBold"
        label.TextSize = 14
        
        print("🖱️ МЫШЬ РАЗБЛОКИРОВАНА! Нажмите " .. GetKeyName(Keybinds.UnlockMouse) .. " для блокировки")
    else
        -- Блокируем мышь
        pcall(function()
            UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
            UIS.MouseIconEnabled = false
            GuiService.MouseIconEnabled = false
        end)
        
        -- Удаляем индикатор
        pcall(function()
            local gui = Player.PlayerGui:FindFirstChild("MouseUnlockIndicator")
            if gui then gui:Destroy() end
        end)
        
        print("🖱️ МЫШЬ ЗАБЛОКИРОВАНА! Нажмите " .. GetKeyName(Keybinds.UnlockMouse) .. " для разблокировки")
    end
    
    -- Обновляем кнопку
    if MouseToggleBtn then
        MouseToggleBtn.Text = Bober.isMouseUnlocked and "🖱️ ЗАБЛОКИРОВАТЬ МЫШЬ" or "🖱️ РАЗБЛОКИРОВАТЬ МЫШЬ [" .. GetKeyName(Keybinds.UnlockMouse) .. "]"
        MouseToggleBtn.BackgroundColor3 = Bober.isMouseUnlocked and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
        MouseStatus.Text = Bober.isMouseUnlocked and "🖱️ Статус: РАЗБЛОКИРОВАНА ✅" or "🖱️ Статус: ЗАБЛОКИРОВАНА 🔒"
        MouseStatus.TextColor3 = Bober.isMouseUnlocked and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 180)
    end
end

-- ==================== СМЕНА ДНЯ И НОЧИ ====================
local isDayMode = true
local originalClockTime = nil
local originalBrightness = nil
local originalFogColor = nil
local originalAmbient = nil
local originalOutdoorAmbient = nil
local originalSkybox = nil
local DayNightBtn = nil
local DayNightStatus = nil

local function ToggleDayNight()
    local lighting = game:GetService("Lighting")
    
    if originalClockTime == nil then
        originalClockTime = lighting.ClockTime
        originalBrightness = lighting.Brightness
        originalFogColor = lighting.FogColor
        originalAmbient = lighting.Ambient
        originalOutdoorAmbient = lighting.OutdoorAmbient
        originalSkybox = {
            SkyboxBk = lighting.SkyboxBk,
            SkyboxDn = lighting.SkyboxDn,
            SkyboxFt = lighting.SkyboxFt,
            SkyboxLf = lighting.SkyboxLf,
            SkyboxRt = lighting.SkyboxRt,
            SkyboxUp = lighting.SkyboxUp,
        }
    end
    
    if isDayMode then
        lighting.ClockTime = 0
        lighting.Brightness = 0.3
        lighting.FogColor = Color3.fromRGB(10, 10, 25)
        lighting.Ambient = Color3.fromRGB(25, 25, 45)
        pcall(function()
            lighting.OutdoorAmbient = Color3.fromRGB(25, 25, 45)
            lighting.FogEnd = 400
            lighting.GlobalShadows = true
        end)
        
        pcall(function()
            lighting.SkyboxBk = "rbxassetid://186517980"
            lighting.SkyboxDn = "rbxassetid://186517997"
            lighting.SkyboxFt = "rbxassetid://186517993"
            lighting.SkyboxLf = "rbxassetid://186518001"
            lighting.SkyboxRt = "rbxassetid://186518005"
            lighting.SkyboxUp = "rbxassetid://186518009"
        end)
        
        pcall(function()
            if workspace:FindFirstChild("DBMoonLight") then workspace.DBMoonLight:Destroy() end
            if Camera:FindFirstChild("DBMoonLight2") then Camera.DBMoonLight2:Destroy() end
            
            local moonLight = Instance.new("PointLight")
            moonLight.Name = "DBMoonLight"
            moonLight.Brightness = 2.5
            moonLight.Range = 1500
            moonLight.Color = Color3.fromRGB(180, 180, 255)
            moonLight.Shadows = true
            moonLight.Parent = workspace.Terrain or workspace
            
            local moonLight2 = Instance.new("PointLight")
            moonLight2.Name = "DBMoonLight2"
            moonLight2.Brightness = 1.5
            moonLight2.Range = 1500
            moonLight2.Color = Color3.fromRGB(150, 150, 255)
            moonLight2.Parent = Camera
        end)
        
        if DayNightBtn then DayNightBtn.Text = "☀️ ДЕНЬ/НОЧЬ" end
        if DayNightStatus then
            DayNightStatus.Text = "🌙 Режим: НОЧЬ ✨"
            DayNightStatus.TextColor3 = Color3.fromRGB(150, 150, 255)
        end
        print("🌙 НОЧЬ: Звёздное небо, лунный свет!")
    else
        lighting.ClockTime = 14
        lighting.Brightness = 1.5
        lighting.FogColor = Color3.fromRGB(135, 206, 235)
        lighting.Ambient = Color3.fromRGB(180, 180, 200)
        pcall(function()
            lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 200)
            lighting.FogEnd = 100000
            lighting.GlobalShadows = true
        end)
        
        pcall(function()
            lighting.SkyboxBk = "rbxassetid://323191505"
            lighting.SkyboxDn = "rbxassetid://323191428"
            lighting.SkyboxFt = "rbxassetid://323191491"
            lighting.SkyboxLf = "rbxassetid://323191475"
            lighting.SkyboxRt = "rbxassetid://323191500"
            lighting.SkyboxUp = "rbxassetid://323191515"
        end)
        
        pcall(function()
            if workspace:FindFirstChild("DBMoonLight") then workspace.DBMoonLight:Destroy() end
            if Camera:FindFirstChild("DBMoonLight2") then Camera.DBMoonLight2:Destroy() end
        end)
        
        if DayNightBtn then DayNightBtn.Text = "🌙 ДЕНЬ/НОЧЬ" end
        if DayNightStatus then
            DayNightStatus.Text = "☀️ Режим: ДЕНЬ ☀️"
            DayNightStatus.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
        print("☀️ ДЕНЬ: Голубое небо, облака, солнечный свет!")
    end
    
    isDayMode = not isDayMode
end

-- ==================== ФУНКЦИИ УБИЙСТВА ====================
local function KillPlayer(targetPlayer)
    if not targetPlayer then return end
    if targetPlayer == Player then 
        print("⚠️ Нельзя убить себя!")
        return 
    end
    
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    
    if hum and hum.Health > 0 then
        local lightning = Instance.new("Part")
        lightning.Name = "KillEffect"
        lightning.Size = Vector3.new(1, 1, 1)
        lightning.Shape = Enum.PartType.Ball
        lightning.Color = Color3.fromRGB(255, 0, 0)
        lightning.Material = Enum.Material.Neon
        lightning.Transparency = 0.3
        lightning.Anchored = true
        lightning.CanCollide = false
        lightning.Position = root and root.Position or targetChar.PrimaryPart.Position
        lightning.Parent = workspace
        
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://9120386436"
        sound.Volume = 1
        sound.Parent = root or targetChar
        sound:Play()
        
        hum.Health = 0
        
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(math.random(-50, 50), 100, math.random(-50, 50))
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = root
            task.spawn(function()
                task.wait(0.5)
                if bv then bv:Destroy() end
            end)
        end
        
        task.spawn(function()
            task.wait(1)
            if lightning then lightning:Destroy() end
            if sound then sound:Destroy() end
        end)
        
        print("💀 УБИЙСТВО: " .. targetPlayer.Name .. " уничтожен!")
    end
end

local function ExplodePlayer(targetPlayer)
    if not targetPlayer then return end
    if targetPlayer == Player then 
        print("⚠️ Нельзя взорвать себя!")
        return 
    end
    
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    
    if hum and hum.Health > 0 then
        local pos = root and root.Position or targetChar.PrimaryPart.Position
        
        local explosion = Instance.new("Explosion")
        explosion.Position = pos
        explosion.BlastRadius = 10
        explosion.BlastPressure = 500000
        explosion.Visible = true
        explosion.Parent = workspace
        
        local fireBall = Instance.new("Part")
        fireBall.Size = Vector3.new(3, 3, 3)
        fireBall.Shape = Enum.PartType.Ball
        fireBall.Color = Color3.fromRGB(255, 100, 0)
        fireBall.Material = Enum.Material.Neon
        fireBall.Transparency = 0.2
        fireBall.Anchored = true
        fireBall.CanCollide = false
        fireBall.Position = pos
        fireBall.Parent = workspace
        
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://9120386436"
        sound.Volume = 1.5
        sound.Parent = root or targetChar
        sound:Play()
        
        hum.Health = 0
        
        if root then
            local bv = Instance.new("BodyVelocity")
            bv.Velocity = Vector3.new(math.random(-100, 100), 200, math.random(-100, 100))
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Parent = root
            task.spawn(function()
                task.wait(0.5)
                if bv then bv:Destroy() end
            end)
        end
        
        task.spawn(function()
            task.wait(1)
            if fireBall then 
                for i = 1, 5 do
                    fireBall.Transparency = fireBall.Transparency + 0.2
                    task.wait(0.1)
                end
                fireBall:Destroy()
            end
            if sound then sound:Destroy() end
        end)
        
        print("💣 ВЗРЫВ: " .. targetPlayer.Name .. " уничтожен с эффектом!")
    end
end

local function KillAllPlayers()
    local count = 0
    for _, p in pairs(game.Players:GetPlayers()) do
        if p ~= Player then
            KillPlayer(p)
            count = count + 1
            task.wait(0.1)
        end
    end
    print("💀 УБИТЫ ВСЕ ИГРОКИ! (" .. count .. " игроков)")
end

local function RevivePlayer(targetPlayer)
    if not targetPlayer then return end
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        hum.Health = 100
        local reviveEffect = Instance.new("Part")
        reviveEffect.Size = Vector3.new(2, 2, 2)
        reviveEffect.Shape = Enum.PartType.Ball
        reviveEffect.Color = Color3.fromRGB(0, 255, 0)
        reviveEffect.Material = Enum.Material.Neon
        reviveEffect.Transparency = 0.5
        reviveEffect.Anchored = true
        reviveEffect.CanCollide = false
        reviveEffect.Position = targetChar.HumanoidRootPart.Position
        reviveEffect.Parent = workspace
        task.spawn(function()
            task.wait(1)
            reviveEffect:Destroy()
        end)
        print("✨ ВОСКРЕШЕНИЕ: " .. targetPlayer.Name .. " возвращён к жизни!")
    end
end

-- ==================== ФЛИНГЕР ====================
local function FlingTarget(targetPlayer)
    if targetPlayer == Player then return end
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if lastTouched[targetPlayer] and tick() - lastTouched[targetPlayer] < 0.5 then return end
    lastTouched[targetPlayer] = tick()
    
    local force = Vector3.new(math.random(-300, 300), math.random(120, 200), math.random(-300, 300))
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = force
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = root
    if hum then
        hum.PlatformStand = true
        task.wait(0.5)
        hum.PlatformStand = false
    end
    task.spawn(function()
        task.wait(1)
        if bv then bv:Destroy() end
    end)
    print("💥 ФЛИНГЕР: " .. targetPlayer.Name .. " отброшен!")
end

local function SetupFlingerHandler()
    local char = Player.Character
    if not char then return end
    for _, conn in pairs(flingerConnections) do pcall(function() conn:Disconnect() end) end
    flingerConnections = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local connection = part.Touched:Connect(function(hit)
                if not Bober.isFlinger then return end
                if not Bober.Active then return end
                if hit:IsDescendantOf(char) then return end
                local character = hit:FindFirstAncestorWhichIsA("Model")
                if not character then return end
                local player = game.Players:GetPlayerFromCharacter(character)
                if player and player ~= Player then FlingTarget(player) end
            end)
            table.insert(flingerConnections, connection)
        end
    end
    print("💥 ФЛИНГЕР ВКЛЮЧЁН!")
end

local function ClearFlingerHandler()
    for _, conn in pairs(flingerConnections) do pcall(function() conn:Disconnect() end) end
    flingerConnections = {}
    print("💥 ФЛИНГЕР ВЫКЛЮЧЁН")
end

-- ==================== ПРЯМОУГОЛЬНИК ====================
local function TransformToSpinBlock()
    local char = Player.Character
    if not char then return end
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not rootPart or not hum then return end
    
    if spinBlockModel then spinBlockModel:Destroy() end
    if spinConnection then spinConnection:Disconnect() end
    
    originalCharacterState = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part ~= rootPart then
            originalCharacterState[part] = { Transparency = part.Transparency, CanCollide = part.CanCollide }
            part.Transparency = 1
            part.CanCollide = false
        end
    end
    
    hum.AutoRotate = false
    hum.PlatformStand = true
    
    spinBlockModel = Instance.new("Model")
    spinBlockModel.Name = "SpinBlockModel"
    spinBlockModel.Parent = char
    
    local block = Instance.new("Part")
    block.Size = Vector3.new(0.5, 1.5, 0.5)
    block.Shape = Enum.PartType.Block
    block.Color = Color3.fromRGB(255, 100, 50)
    block.Material = Enum.Material.Neon
    block.Transparency = 0.2
    block.Anchored = false
    block.CanCollide = true
    block.Parent = spinBlockModel
    
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = block
    selectionBox.Color3 = Color3.fromRGB(255, 50, 50)
    selectionBox.LineThickness = 0.1
    selectionBox.Transparency = 0.3
    selectionBox.Parent = block
    
    local weld = Instance.new("Weld")
    weld.Part0 = rootPart
    weld.Part1 = block
    weld.C0 = CFrame.new(0, 0, 0)
    weld.Parent = block
    
    local lastTime = tick()
    spinConnection = RunService.RenderStepped:Connect(function()
        if not spinBlockModel or not spinBlockModel.Parent then
            if spinConnection then spinConnection:Disconnect() end
            return
        end
        local delta = math.min(tick() - lastTime, 0.033)
        lastTime = tick()
        block.CFrame = block.CFrame * CFrame.Angles(math.rad(720 * delta), math.rad(540 * delta), math.rad(360 * delta))
    end)
    print("🟠 ПРЯМОУГОЛЬНИК АКТИВИРОВАН")
end

local function RevertFromSpinBlock()
    if spinConnection then spinConnection:Disconnect() end
    if spinBlockModel then spinBlockModel:Destroy() end
    local char = Player.Character
    if char then
        for part, state in pairs(originalCharacterState) do
            if part and part.Parent then
                part.Transparency = state.Transparency
                part.CanCollide = state.CanCollide
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.AutoRotate = true
            hum.PlatformStand = false
        end
    end
    originalCharacterState = {}
    print("🔴 ПРЯМОУГОЛЬНИК ДЕАКТИВИРОВАН")
end

local function ToggleSpinBlock()
    Bober.isSpinBlock = not Bober.isSpinBlock
    if Bober.isSpinBlock then
        if Bober.isFly then TransformToSpinBlock()
        else print("⚠️ Сначала включите ПОЛЁТ (E)") end
    else RevertFromSpinBlock() end
end

-- ==================== НЕВИДИМЫЙ СТУЛ ====================
local chairPart = nil
local originalChairTransparency = {}

local function ToggleChairMode()
    Bober.isChairMode = not Bober.isChairMode
    if Bober.isChairMode then
        local char = Player.Character
        if not char then print("❌ Персонаж не найден!"); Bober.isChairMode = false; return end
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not rootPart or not hum then print("❌ Ошибка!"); Bober.isChairMode = false; return end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then originalChairTransparency[part] = part.Transparency; part.Transparency = 1 end
        end
        for _, acc in pairs(char:GetChildren()) do
            if acc:IsA("Accessory") and acc.Handle then acc.Handle.Transparency = 1 end
        end
        
        chairPart = Instance.new("Part")
        chairPart.Size = Vector3.new(2, 1, 2)
        chairPart.Transparency = 1
        chairPart.CanCollide = true
        chairPart.Parent = char
        local sitAttachment = Instance.new("Attachment", chairPart)
        sitAttachment.Name = "SitAttachment"
        sitAttachment.Position = Vector3.new(0, 0.5, 0)
        local weld = Instance.new("Weld")
        weld.Part0 = rootPart
        weld.Part1 = chairPart
        weld.C0 = CFrame.new(0, 1.5, -0.5)
        weld.Parent = chairPart
        print("✅ НЕВИДИМЫЙ СТУЛ ВКЛЮЧЁН!")
    else
        if chairPart then chairPart:Destroy() end
        local char = Player.Character
        if char then
            for part, trans in pairs(originalChairTransparency) do
                if part and part.Parent then part.Transparency = trans end
            end
            for _, acc in pairs(char:GetChildren()) do
                if acc:IsA("Accessory") and acc.Handle then acc.Handle.Transparency = 0 end
            end
        end
        originalChairTransparency = {}
        print("❌ НЕВИДИМЫЙ СТУЛ ВЫКЛЮЧЁН")
    end
end

-- ==================== BAN HAMMER ====================
local function BanHammerFling(targetPlayer)
    if targetPlayer == Player then return end
    local targetChar = targetPlayer.Character
    if not targetChar then return end
    local root = targetChar:FindFirstChild("HumanoidRootPart")
    local hum = targetChar:FindFirstChildOfClass("Humanoid")
    if not root then return end
    if lastTouched[targetPlayer] and tick() - lastTouched[targetPlayer] < 0.5 then return end
    lastTouched[targetPlayer] = tick()
    
    local force = Vector3.new(math.random(-200, 200), math.random(100, 180), math.random(-200, 200))
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = force
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Parent = root
    if hum then
        hum.PlatformStand = true
        task.wait(0.5)
        hum.PlatformStand = false
    end
    task.spawn(function()
        task.wait(1)
        if bv then bv:Destroy() end
    end)
    print("🔨 BAN HAMMER: " .. targetPlayer.Name .. " улетел!")
end

local function SetupBanHammerHandler()
    local char = Player.Character
    if not char then return end
    for _, conn in pairs(banHammerConnections) do pcall(function() conn:Disconnect() end) end
    banHammerConnections = {}
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local connection = part.Touched:Connect(function(hit)
                if not Bober.isBanHammer then return end
                if not Bober.Active then return end
                if hit:IsDescendantOf(char) then return end
                local character = hit:FindFirstAncestorWhichIsA("Model")
                if not character then return end
                local player = game.Players:GetPlayerFromCharacter(character)
                if player and player ~= Player then BanHammerFling(player) end
            end)
            table.insert(banHammerConnections, connection)
        end
    end
    print("🔨 BAN HAMMER ВКЛЮЧЁН!")
end

-- ==================== GOD MODE ====================
local function ApplyGodMode()
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Bober.isGodMode then
        pcall(function()
            hum.MaxHealth = 9e9
            hum.Health = 9e9
            hum.BreakJointsOnDeath = false
        end)
        local function healLoop()
            while Bober.isGodMode and Bober.Active do
                pcall(function() if hum and hum.Parent then hum.Health = hum.MaxHealth end end)
                task.wait(0.1)
            end
        end
        if godModeConnection then pcall(function() godModeConnection:Disconnect() end) end
        godModeConnection = RunService.Heartbeat:Connect(healLoop)
        pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    else
        if godModeConnection then pcall(function() godModeConnection:Disconnect() end); godModeConnection = nil end
        pcall(function()
            hum.MaxHealth = 100
            hum.Health = 100
            hum.BreakJointsOnDeath = true
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        end)
    end
end

local function ToggleGodMode()
    Bober.isGodMode = not Bober.isGodMode
    ApplyGodMode()
    print("God Mode: " .. (Bober.isGodMode and "ON ✅" or "OFF ❌"))
end

-- ==================== ТЕЛЕПОРТ МЫШЬЮ ====================
local function TeleportToMouse()
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local ray = Ray.new(Camera.CFrame.Position, Mouse.UnitRay.Direction * 1000)
    local hit, position = workspace:FindPartOnRay(ray, char)
    if position then
        root.CFrame = CFrame.new(position.X, position.Y + 3, position.Z)
        print("Телепорт на место курсора!")
    end
end

-- ==================== ОБЩИЕ ФУНКЦИИ ====================
local function FullPhysicsReset()
    pcall(function()
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
                hum.JumpPower = 50
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
                if not Bober.isSpeedActive then hum.WalkSpeed = 16
                else hum.WalkSpeed = Bober.WS end
                if Bober.isSprintActive and isSprinting then hum.WalkSpeed = Bober.SS end
            end
            if root then
                root.Anchored = false
                for _, v in pairs(root:GetChildren()) do
                    if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
                end
            end
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
        Camera.CameraSubject = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") or nil
        Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
        if workspace:FindFirstChild("DBCamPart") then workspace.DBCamPart:Destroy() end
    end)
end

local function ForceSpeed()
    if not Bober.Active then return end
    local char = Player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local rPressed = UIS:IsKeyDown(Keybinds.Sprint)
    isSprinting = rPressed and Bober.isSprintActive
    if isSprinting then
        if hum.WalkSpeed ~= Bober.SS then hum.WalkSpeed = Bober.SS end
    elseif Bober.isSpeedActive then
        if hum.WalkSpeed ~= Bober.WS then hum.WalkSpeed = Bober.WS end
    else
        if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
    end
end

local function DoJump()
    local char = Player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bvJump = Instance.new("BodyVelocity")
    bvJump.Velocity = Vector3.new(0, 80, 0)
    bvJump.MaxForce = Vector3.new(0, 9e9, 0)
    bvJump.Parent = root
    task.spawn(function()
        task.wait(0.1)
        if bvJump then bvJump:Destroy() end
    end)
end

-- ==================== ПОЛЁТ ====================
local bv, bg
local function ToggleFly()
    Bober.isFly = not Bober.isFly
    if Bober.isFly then
        Bober.isWall = false
        FullPhysicsReset()
        task.wait(0.1)
        Bober.isFly = true
        local char = Player.Character
        if not char then return end
        local r = char.HumanoidRootPart
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = true end
        bg = Instance.new("BodyGyro", r)
        bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
        bg.P = 5e5
        bv = Instance.new("BodyVelocity", r)
        bv.MaxForce = Vector3.new(9e9,9e9,9e9)
        task.spawn(function()
            while Bober.isFly and Bober.Active do
                if shared.DBCheatClose then break end
                local cam = Camera.CFrame
                bg.CFrame = cam
                local d = Vector3.new(0,0,0)
                if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + cam.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - cam.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - cam.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + cam.RightVector end
                bv.Velocity = d.Magnitude > 0 and d.Unit * Bober.FS or Vector3.new(0,0,0)
                RunService.RenderStepped:Wait()
            end
            FullPhysicsReset()
        end)
        if Bober.isSpinBlock then TransformToSpinBlock() end
    else
        FullPhysicsReset()
        if Bober.isSpinBlock then RevertFromSpinBlock() end
    end
end

-- ==================== НАСТРОЙКА КЛАВИШ ====================
local function StartKeySetup(action, button, callback)
    waitingForKey = action
    button.Text = "..."
    button.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    
    local connection
    connection = UIS.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode
            if key ~= Enum.KeyCode.Unknown then
                Keybinds[action] = key
                button.Text = GetKeyName(key)
                button.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
                if callback then callback() end
                connection:Disconnect()
                waitingForKey = nil
            end
        end
    end)
end

-- ==================== GUI ====================
pcall(function() if Player and Player.PlayerGui:FindFirstChild("DBCheat") then Player.PlayerGui.DBCheat:Destroy() end end)

local sg = Instance.new("ScreenGui", Player:WaitForChild("PlayerGui"))
sg.Name = "DBCheat"
sg.ResetOnSpawn = false

local function ApplyCorner(o) local c = Instance.new("UICorner", o) c.CornerRadius = UDim.new(0, 8) end

local function CreateGradient(frame, color1, color2)
    local gradient = Instance.new("UIGradient", frame)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    })
    gradient.Rotation = 0
    return gradient
end

-- === ТЕЛЕПОРТ ОКНО ===
local TpWin = Instance.new("Frame", sg)
TpWin.Size = UDim2.new(0, 440, 0, 520)
TpWin.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
TpWin.BackgroundTransparency = 0.1
TpWin.Visible = false
ApplyCorner(TpWin)
TpWin.Active = true
TpWin.Draggable = true

CreateGradient(TpWin, Color3.fromRGB(15, 15, 25), Color3.fromRGB(80, 20, 20))

local TL = Instance.new("TextLabel", TpWin)
TL.Size = UDim2.new(1,0,0,40)
TL.Text = "📡 TELEPORT & KILL 💀"
TL.Font = "GothamBold"
TL.TextSize = 16
TL.BackgroundTransparency = 1
TL.TextColor3 = Color3.fromRGB(255, 100, 100)

local Container = Instance.new("Frame", TpWin)
Container.Size = UDim2.new(1, -10, 1, -50)
Container.Position = UDim2.new(0, 5, 0, 45)
Container.BackgroundTransparency = 1

-- ЛЕВАЯ КОЛОНКА - ТЕЛЕПОРТ
local TeleportFrame = Instance.new("Frame", Container)
TeleportFrame.Size = UDim2.new(0.48, -5, 1, 0)
TeleportFrame.Position = UDim2.new(0, 0, 0, 0)
TeleportFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TeleportFrame.BackgroundTransparency = 0.3
ApplyCorner(TeleportFrame)

local TeleportTitle = Instance.new("TextLabel", TeleportFrame)
TeleportTitle.Size = UDim2.new(1,0,0,30)
TeleportTitle.Text = "🚀 ТЕЛЕПОРТ"
TeleportTitle.Font = "GothamBold"
TeleportTitle.TextSize = 14
TeleportTitle.BackgroundTransparency = 1
TeleportTitle.TextColor3 = Color3.fromRGB(100, 200, 255)

local TeleportScroll = Instance.new("ScrollingFrame", TeleportFrame)
TeleportScroll.Size = UDim2.new(1, -10, 1, -80)
TeleportScroll.Position = UDim2.new(0, 5, 0, 35)
TeleportScroll.BackgroundTransparency = 1
TeleportScroll.ScrollBarThickness = 4
TeleportScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)

local TeleportLayout = Instance.new("UIListLayout", TeleportScroll)
TeleportLayout.Padding = UDim.new(0, 5)

local TpTarget = nil
local TpTargetBtn = nil

local function RefreshTeleportList()
    for _, v in pairs(TeleportScroll:GetChildren()) do 
        if v:IsA("TextButton") then 
            v:Destroy() 
        end 
    end
    for _, p in pairs(game.Players:GetPlayers()) do 
        if p ~= Player then
            local b = Instance.new("TextButton", TeleportScroll)
            b.Size = UDim2.new(1, 0, 0, 32)
            b.Text = p.Name
            b.BackgroundColor3 = (TpTarget == p) and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(50, 50, 70)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            ApplyCorner(b)
            b.MouseButton1Click:Connect(function() 
                TpTarget = (TpTarget == p) and nil or p
                if TpTargetBtn then
                    TpTargetBtn.Text = TpTarget and "🚀 ТЕЛЕПОРТ К " .. TpTarget.Name or "🚀 ТЕЛЕПОРТ"
                    TpTargetBtn.BackgroundColor3 = TpTarget and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
                end
                RefreshTeleportList()
            end)
        end
    end
end

local TpExec = Instance.new("TextButton", TeleportFrame)
TpExec.Size = UDim2.new(1, -10, 0, 35)
TpExec.Position = UDim2.new(0, 5, 1, -40)
TpExec.Text = "🚀 ТЕЛЕПОРТ"
TpExec.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
TpExec.TextColor3 = Color3.new(1,1,1)
TpExec.Font = "GothamBold"
ApplyCorner(TpExec)
TpTargetBtn = TpExec

TpExec.MouseButton1Click:Connect(function() 
    if TpTarget and TpTarget.Character and TpTarget.Character:FindFirstChild("HumanoidRootPart") then 
        local char = Player.Character
        if char then
            char:MoveTo(TpTarget.Character.HumanoidRootPart.Position)
            print("🚀 Телепорт к " .. TpTarget.Name)
        end
    end
end)

-- ПРАВАЯ КОЛОНКА - УБИЙСТВО
local KillFrame = Instance.new("Frame", Container)
KillFrame.Size = UDim2.new(0.48, -5, 1, 0)
KillFrame.Position = UDim2.new(0.52, 0, 0, 0)
KillFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
KillFrame.BackgroundTransparency = 0.3
ApplyCorner(KillFrame)

local KillTitle = Instance.new("TextLabel", KillFrame)
KillTitle.Size = UDim2.new(1,0,0,30)
KillTitle.Text = "💀 УБИЙСТВО"
KillTitle.Font = "GothamBold"
KillTitle.TextSize = 14
KillTitle.BackgroundTransparency = 1
KillTitle.TextColor3 = Color3.fromRGB(255, 80, 80)

local KillScroll = Instance.new("ScrollingFrame", KillFrame)
KillScroll.Size = UDim2.new(1, -10, 1, -210)
KillScroll.Position = UDim2.new(0, 5, 0, 35)
KillScroll.BackgroundTransparency = 1
KillScroll.ScrollBarThickness = 4
KillScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)

local KillLayout = Instance.new("UIListLayout", KillScroll)
KillLayout.Padding = UDim.new(0, 5)

local KillTarget = nil

local function RefreshKillList()
    for _, v in pairs(KillScroll:GetChildren()) do 
        if v:IsA("TextButton") then 
            v:Destroy() 
        end 
    end
    for _, p in pairs(game.Players:GetPlayers()) do 
        if p ~= Player then
            local b = Instance.new("TextButton", KillScroll)
            b.Size = UDim2.new(1, 0, 0, 32)
            b.Text = p.Name
            b.BackgroundColor3 = (KillTarget == p) and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(50, 50, 70)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            ApplyCorner(b)
            b.MouseButton1Click:Connect(function() 
                KillTarget = (KillTarget == p) and nil or p
                if KillNormalBtn then
                    KillNormalBtn.Text = KillTarget and "💀 УБИТЬ " .. KillTarget.Name or "💀 УБИТЬ"
                    KillNormalBtn.BackgroundColor3 = KillTarget and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
                end
                if KillExplodeBtn then
                    KillExplodeBtn.Text = KillTarget and "💣 ВЗОРВАТЬ " .. KillTarget.Name or "💣 ВЗОРВАТЬ"
                    KillExplodeBtn.BackgroundColor3 = KillTarget and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
                end
                if ReviveBtn then
                    ReviveBtn.Text = KillTarget and "✨ ВОСКРЕСИТЬ " .. KillTarget.Name or "✨ ВОСКРЕСИТЬ"
                    ReviveBtn.BackgroundColor3 = KillTarget and Color3.fromRGB(40, 80, 40) or Color3.fromRGB(40, 80, 40)
                end
                RefreshKillList()
            end)
        end
    end
end

local KillNormalBtn = Instance.new("TextButton", KillFrame)
KillNormalBtn.Size = UDim2.new(1, -10, 0, 35)
KillNormalBtn.Position = UDim2.new(0, 5, 1, -120)
KillNormalBtn.Text = "💀 УБИТЬ"
KillNormalBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
KillNormalBtn.TextColor3 = Color3.new(1,1,1)
KillNormalBtn.Font = "GothamBold"
ApplyCorner(KillNormalBtn)

KillNormalBtn.MouseButton1Click:Connect(function() 
    if KillTarget then
        KillPlayer(KillTarget)
    end
end)

local KillExplodeBtn = Instance.new("TextButton", KillFrame)
KillExplodeBtn.Size = UDim2.new(1, -10, 0, 35)
KillExplodeBtn.Position = UDim2.new(0, 5, 1, -80)
KillExplodeBtn.Text = "💣 ВЗОРВАТЬ"
KillExplodeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
KillExplodeBtn.TextColor3 = Color3.new(1,1,1)
KillExplodeBtn.Font = "GothamBold"
ApplyCorner(KillExplodeBtn)

KillExplodeBtn.MouseButton1Click:Connect(function() 
    if KillTarget then
        ExplodePlayer(KillTarget)
    end
end)

local ReviveBtn = Instance.new("TextButton", KillFrame)
ReviveBtn.Size = UDim2.new(1, -10, 0, 35)
ReviveBtn.Position = UDim2.new(0, 5, 1, -40)
ReviveBtn.Text = "✨ ВОСКРЕСИТЬ"
ReviveBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
ReviveBtn.TextColor3 = Color3.new(1,1,1)
ReviveBtn.Font = "GothamBold"
ApplyCorner(ReviveBtn)

ReviveBtn.MouseButton1Click:Connect(function() 
    if KillTarget then
        RevivePlayer(KillTarget)
    end
end)

local KillAllBtn = Instance.new("TextButton", KillFrame)
KillAllBtn.Size = UDim2.new(1, -10, 0, 30)
KillAllBtn.Position = UDim2.new(0, 5, 0, 38)
KillAllBtn.Text = "⚠️ УБИТЬ ВСЕХ ⚠️"
KillAllBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
KillAllBtn.TextColor3 = Color3.new(1,1,1)
KillAllBtn.Font = "GothamBold"
KillAllBtn.TextSize = 12
ApplyCorner(KillAllBtn)

KillAllBtn.MouseButton1Click:Connect(function() 
    KillAllPlayers()
end)

-- === ГЛАВНОЕ ОКНО ===
local Main = Instance.new("Frame", sg)
Main.Size = UDim2.new(0, 550, 0, 580)
Main.Position = UDim2.new(0.5, -275, 0.08, 0)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
Main.BackgroundTransparency = 0.1
Main.Active = true
Main.Draggable = true
ApplyCorner(Main)

CreateGradient(Main, Color3.fromRGB(10, 10, 20), Color3.fromRGB(120, 20, 20))

local Bar = Instance.new("Frame", Main)
Bar.Size = UDim2.new(1,0,0,45)
Bar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Bar.BackgroundTransparency = 0.3
ApplyCorner(Bar)

local TitleLabel = Instance.new("TextLabel", Bar)
TitleLabel.Size = UDim2.new(1,-100,1,0)
TitleLabel.Position = UDim2.new(0,10,0,0)
TitleLabel.Text = "🔥 DB_CHEAT 🔥"
TitleLabel.Font = "GothamBold"
TitleLabel.TextSize = 18
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 80, 80)

local function HBtn(txt, x, col, func)
    local b = Instance.new("TextButton", Bar)
    b.Size = UDim2.new(0, 35, 0, 32)
    b.Position = UDim2.new(0, x, 0, 6)
    b.Text = txt
    b.BackgroundColor3 = col
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = "GothamBold"
    b.TextSize = 14
    ApplyCorner(b)
    b.MouseButton1Click:Connect(func)
end

HBtn("📡", 5, Color3.fromRGB(180, 50, 50), function() 
    TpWin.Visible = not TpWin.Visible
    if TpWin.Visible then 
        RefreshTeleportList()
        RefreshKillList()
        local mainPos = Main.AbsolutePosition
        TpWin.Position = UDim2.new(0, mainPos.X - 450, 0, mainPos.Y)
    end
end)

HBtn("❌", 510, Color3.fromRGB(200, 40, 40), function() 
    Main.Visible = false
    TpWin.Visible = false
end)

local ScrollContainer = Instance.new("ScrollingFrame", Main)
ScrollContainer.Name = "ScrollContainer"
ScrollContainer.Size = UDim2.new(1, -10, 1, -55)
ScrollContainer.Position = UDim2.new(0, 5, 0, 50)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.ScrollBarThickness = 6
ScrollContainer.ScrollBarImageColor3 = Color3.fromRGB(200, 50, 50)
ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 1150)

local MainCont = Instance.new("Frame", ScrollContainer)
MainCont.Size = UDim2.new(1, 0, 1, 0)
MainCont.BackgroundTransparency = 1

-- 1. ДВИЖЕНИЕ + ПОЛЁТ
local TopRow = Instance.new("Frame", MainCont)
TopRow.Size = UDim2.new(1, 0, 0, 180)
TopRow.BackgroundTransparency = 1
local HorizontalContainer = Instance.new("Frame", TopRow)
HorizontalContainer.Size = UDim2.new(1, 0, 1, 0)
HorizontalContainer.BackgroundTransparency = 1

local MoveCategory = Instance.new("Frame", HorizontalContainer)
MoveCategory.Size = UDim2.new(0.5, -10, 1, -10)
MoveCategory.Position = UDim2.new(0, 5, 0, 0)
MoveCategory.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MoveCategory.BackgroundTransparency = 0.2
ApplyCorner(MoveCategory)

local MoveTitle = Instance.new("TextLabel", MoveCategory)
MoveTitle.Size = UDim2.new(1,0,0,30)
MoveTitle.Text = "🏃 ДВИЖЕНИЕ"
MoveTitle.Font = "GothamBold"
MoveTitle.TextSize = 14
MoveTitle.BackgroundTransparency = 1
MoveTitle.TextColor3 = Color3.fromRGB(255, 200, 100)

local SpeedInput = Instance.new("TextBox", MoveCategory)
SpeedInput.Size = UDim2.new(0.6,-10,0,32)
SpeedInput.Position = UDim2.new(0,10,0,38)
SpeedInput.Text = "40"
SpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SpeedInput.TextColor3 = Color3.new(1,1,1)
ApplyCorner(SpeedInput)

local SpeedToggle = Instance.new("TextButton", MoveCategory)
SpeedToggle.Size = UDim2.new(0.35,-10,0,32)
SpeedToggle.Position = UDim2.new(0.63,0,0,38)
SpeedToggle.Text = "⚡ OFF"
SpeedToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SpeedToggle.TextColor3 = Color3.new(1,1,1)
ApplyCorner(SpeedToggle)

local JumpInput = Instance.new("TextBox", MoveCategory)
JumpInput.Size = UDim2.new(0.6,-10,0,32)
JumpInput.Position = UDim2.new(0,10,0,78)
JumpInput.Text = "80"
JumpInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
JumpInput.TextColor3 = Color3.new(1,1,1)
ApplyCorner(JumpInput)

local JumpToggle = Instance.new("TextButton", MoveCategory)
JumpToggle.Size = UDim2.new(0.35,-10,0,32)
JumpToggle.Position = UDim2.new(0.63,0,0,78)
JumpToggle.Text = "🦘 OFF"
JumpToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
JumpToggle.TextColor3 = Color3.new(1,1,1)
ApplyCorner(JumpToggle)

local DefaultSpeedLabel = Instance.new("TextLabel", MoveCategory)
DefaultSpeedLabel.Size = UDim2.new(0.9,-10,0,18)
DefaultSpeedLabel.Position = UDim2.new(0,10,0,118)
DefaultSpeedLabel.Text = "📌 Стандартная скорость: 16"
DefaultSpeedLabel.Font = "Gotham"
DefaultSpeedLabel.TextSize = 11
DefaultSpeedLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
DefaultSpeedLabel.BackgroundTransparency = 1

local DefaultJumpLabel = Instance.new("TextLabel", MoveCategory)
DefaultJumpLabel.Size = UDim2.new(0.9,-10,0,18)
DefaultJumpLabel.Position = UDim2.new(0,10,0,138)
DefaultJumpLabel.Text = "📌 Стандартный прыжок: 50"
DefaultJumpLabel.Font = "Gotham"
DefaultJumpLabel.TextSize = 11
DefaultJumpLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
DefaultJumpLabel.BackgroundTransparency = 1

local FlyCategory = Instance.new("Frame", HorizontalContainer)
FlyCategory.Size = UDim2.new(0.5, -10, 1, -10)
FlyCategory.Position = UDim2.new(0.5, 5, 0, 0)
FlyCategory.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
FlyCategory.BackgroundTransparency = 0.2
ApplyCorner(FlyCategory)

local FlyTitle = Instance.new("TextLabel", FlyCategory)
FlyTitle.Size = UDim2.new(1,0,0,30)
FlyTitle.Text = "✈️ ПОЛЁТ"
FlyTitle.Font = "GothamBold"
FlyTitle.TextSize = 14
FlyTitle.BackgroundTransparency = 1
FlyTitle.TextColor3 = Color3.fromRGB(100, 200, 255)

local FlySpeedInput = Instance.new("TextBox", FlyCategory)
FlySpeedInput.Size = UDim2.new(0.9,-10,0,32)
FlySpeedInput.Position = UDim2.new(0,10,0,38)
FlySpeedInput.Text = "50"
FlySpeedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
FlySpeedInput.TextColor3 = Color3.new(1,1,1)
ApplyCorner(FlySpeedInput)

local FlyToggleBtn = Instance.new("TextButton", FlyCategory)
FlyToggleBtn.Size = UDim2.new(0.9,-10,0,32)
FlyToggleBtn.Position = UDim2.new(0,10,0,78)
FlyToggleBtn.Text = "🔘 FLY: OFF (" .. GetKeyName(Keybinds.Fly) .. ")"
FlyToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
FlyToggleBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(FlyToggleBtn)

local SpinBlockBtn = Instance.new("TextButton", FlyCategory)
SpinBlockBtn.Size = UDim2.new(0.9,-10,0,32)
SpinBlockBtn.Position = UDim2.new(0,10,0,118)
SpinBlockBtn.Text = "📐 ПРЯМОУГОЛЬНИК: OFF"
SpinBlockBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SpinBlockBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(SpinBlockBtn)

local NoclipBtn = Instance.new("TextButton", FlyCategory)
NoclipBtn.Size = UDim2.new(0.9,-10,0,32)
NoclipBtn.Position = UDim2.new(0,10,0,158)
NoclipBtn.Text = "🛡️ NOCLIP"
NoclipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
NoclipBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(NoclipBtn)

-- 2. БЕСКОНЕЧНЫЙ БЕГ
local SprintCategory = Instance.new("Frame", MainCont)
SprintCategory.Size = UDim2.new(1, -10, 0, 70)
SprintCategory.Position = UDim2.new(0, 5, 0, 200)
SprintCategory.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
SprintCategory.BackgroundTransparency = 0.2
ApplyCorner(SprintCategory)

local SprintTitle = Instance.new("TextLabel", SprintCategory)
SprintTitle.Size = UDim2.new(1,0,0,30)
SprintTitle.Text = "🏃 БЕСКОНЕЧНЫЙ БЕГ"
SprintTitle.Font = "GothamBold"
SprintTitle.TextSize = 14
SprintTitle.BackgroundTransparency = 1
SprintTitle.TextColor3 = Color3.fromRGB(100, 200, 255)

local SprintInput = Instance.new("TextBox", SprintCategory)
SprintInput.Size = UDim2.new(0.45,-10,0,32)
SprintInput.Position = UDim2.new(0.02,0,0,38)
SprintInput.Text = "60"
SprintInput.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
SprintInput.TextColor3 = Color3.new(1,1,1)
ApplyCorner(SprintInput)

local SprintToggle = Instance.new("TextButton", SprintCategory)
SprintToggle.Size = UDim2.new(0.45,-10,0,32)
SprintToggle.Position = UDim2.new(0.5,0,0,38)
SprintToggle.Text = "🏃 OFF (" .. GetKeyName(Keybinds.Sprint) .. ")"
SprintToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SprintToggle.TextColor3 = Color3.new(1,1,1)
ApplyCorner(SprintToggle)

-- 3. ВИЗУАЛ
local VisualCategory = Instance.new("Frame", MainCont)
VisualCategory.Size = UDim2.new(1, -10, 0, 310)
VisualCategory.Position = UDim2.new(0, 5, 0, 290)
VisualCategory.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
VisualCategory.BackgroundTransparency = 0.2
ApplyCorner(VisualCategory)

local VisualTitle = Instance.new("TextLabel", VisualCategory)
VisualTitle.Size = UDim2.new(1,0,0,30)
VisualTitle.Text = "👁️ ВИЗУАЛ"
VisualTitle.Font = "GothamBold"
VisualTitle.TextSize = 14
VisualTitle.BackgroundTransparency = 1
VisualTitle.TextColor3 = Color3.fromRGB(150, 255, 150)

local WallBtn = Instance.new("TextButton", VisualCategory)
WallBtn.Size = UDim2.new(0.32,-5,0,35)
WallBtn.Position = UDim2.new(0.01,0,0,38)
WallBtn.Text = "🧱 WALL CLIP"
WallBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
WallBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WallBtn.Font = "GothamBold"
ApplyCorner(WallBtn)

local EspBtn = Instance.new("TextButton", VisualCategory)
EspBtn.Size = UDim2.new(0.32,-5,0,35)
EspBtn.Position = UDim2.new(0.34,0,0,38)
EspBtn.Text = "👁️ ESP"
EspBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
EspBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EspBtn.Font = "GothamBold"
ApplyCorner(EspBtn)

local MM2Btn = Instance.new("TextButton", VisualCategory)
MM2Btn.Size = UDim2.new(0.32,-5,0,35)
MM2Btn.Position = UDim2.new(0.67,0,0,38)
MM2Btn.Text = "🔪 ESP (MM2)"
MM2Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MM2Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
MM2Btn.Font = "GothamBold"
ApplyCorner(MM2Btn)

local FogBtn = Instance.new("TextButton", VisualCategory)
FogBtn.Size = UDim2.new(0.32,-5,0,35)
FogBtn.Position = UDim2.new(0.01,0,0,82)
FogBtn.Text = "🌫️ NO FOG"
FogBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
FogBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FogBtn.Font = "GothamBold"
ApplyCorner(FogBtn)

local FreeCamBtn = Instance.new("TextButton", VisualCategory)
FreeCamBtn.Size = UDim2.new(0.32,-5,0,35)
FreeCamBtn.Position = UDim2.new(0.34,0,0,82)
FreeCamBtn.Text = "🎥 FREECAM"
FreeCamBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
FreeCamBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FreeCamBtn.Font = "GothamBold"
ApplyCorner(FreeCamBtn)

local BanHammerBtn = Instance.new("TextButton", VisualCategory)
BanHammerBtn.Size = UDim2.new(0.32,-5,0,35)
BanHammerBtn.Position = UDim2.new(0.67,0,0,82)
BanHammerBtn.Text = "🔨 BAN HAMMER: OFF"
BanHammerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
BanHammerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
BanHammerBtn.Font = "GothamBold"
ApplyCorner(BanHammerBtn)

local BanHammerStatus = Instance.new("TextLabel", VisualCategory)
BanHammerStatus.Size = UDim2.new(0.98,-10,0,18)
BanHammerStatus.Position = UDim2.new(0.01,0,0,125)
BanHammerStatus.Text = "🔨 Статус: OFF"
BanHammerStatus.Font = "Gotham"
BanHammerStatus.TextSize = 11
BanHammerStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
BanHammerStatus.BackgroundTransparency = 1

local FlingerBtn = Instance.new("TextButton", VisualCategory)
FlingerBtn.Size = UDim2.new(0.48,-10,0,35)
FlingerBtn.Position = UDim2.new(0.01,0,0,148)
FlingerBtn.Text = "💥 ФЛИНГЕР: OFF"
FlingerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
FlingerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingerBtn.Font = "GothamBold"
ApplyCorner(FlingerBtn)

local FlingerStatus = Instance.new("TextLabel", VisualCategory)
FlingerStatus.Size = UDim2.new(0.48,-10,0,18)
FlingerStatus.Position = UDim2.new(0.51,0,0,148)
FlingerStatus.Text = "💥 Статус: OFF"
FlingerStatus.Font = "Gotham"
FlingerStatus.TextSize = 11
FlingerStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
FlingerStatus.BackgroundTransparency = 1

DayNightBtn = Instance.new("TextButton", VisualCategory)
DayNightBtn.Size = UDim2.new(0.48,-10,0,35)
DayNightBtn.Position = UDim2.new(0.01,0,0,195)
DayNightBtn.Text = "🌙 ДЕНЬ/НОЧЬ"
DayNightBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
DayNightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DayNightBtn.Font = "GothamBold"
ApplyCorner(DayNightBtn)

DayNightStatus = Instance.new("TextLabel", VisualCategory)
DayNightStatus.Size = UDim2.new(0.48,-10,0,18)
DayNightStatus.Position = UDim2.new(0.51,0,0,195)
DayNightStatus.Text = "☀️ Режим: ДЕНЬ"
DayNightStatus.Font = "Gotham"
DayNightStatus.TextSize = 11
DayNightStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
DayNightStatus.BackgroundTransparency = 1

local ChairModeBtn = Instance.new("TextButton", VisualCategory)
ChairModeBtn.Size = UDim2.new(0.48,-10,0,35)
ChairModeBtn.Position = UDim2.new(0.01,0,0,242)
ChairModeBtn.Text = "🪑 НЕВИДИМЫЙ СТУЛ: OFF"
ChairModeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ChairModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ChairModeBtn.Font = "GothamBold"
ApplyCorner(ChairModeBtn)

local ChairModeStatus = Instance.new("TextLabel", VisualCategory)
ChairModeStatus.Size = UDim2.new(0.48,-10,0,18)
ChairModeStatus.Position = UDim2.new(0.51,0,0,242)
ChairModeStatus.Text = "🪑 Статус: OFF"
ChairModeStatus.Font = "Gotham"
ChairModeStatus.TextSize = 11
ChairModeStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
ChairModeStatus.BackgroundTransparency = 1

-- 4. ЗАЩИТА
local ProtectionCategory = Instance.new("Frame", MainCont)
ProtectionCategory.Size = UDim2.new(1, -10, 0, 160)
ProtectionCategory.Position = UDim2.new(0, 5, 0, 620)
ProtectionCategory.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ProtectionCategory.BackgroundTransparency = 0.2
ApplyCorner(ProtectionCategory)

local ProtectionTitle = Instance.new("TextLabel", ProtectionCategory)
ProtectionTitle.Size = UDim2.new(1,0,0,30)
ProtectionTitle.Text = "🛡️ ЗАЩИТА"
ProtectionTitle.Font = "GothamBold"
ProtectionTitle.TextSize = 14
ProtectionTitle.BackgroundTransparency = 1
ProtectionTitle.TextColor3 = Color3.fromRGB(255, 150, 100)

local GodModeBtn = Instance.new("TextButton", ProtectionCategory)
GodModeBtn.Size = UDim2.new(0.48,-10,0,40)
GodModeBtn.Position = UDim2.new(0.01,0,0,45)
GodModeBtn.Text = "💀 GOD MODE: OFF"
GodModeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
GodModeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GodModeBtn.Font = "GothamBold"
ApplyCorner(GodModeBtn)

local GodModeStatus = Instance.new("TextLabel", ProtectionCategory)
GodModeStatus.Size = UDim2.new(0.48,-10,0,18)
GodModeStatus.Position = UDim2.new(0.01,0,0,90)
GodModeStatus.Text = "📊 Статус: OFF"
GodModeStatus.Font = "Gotham"
GodModeStatus.TextSize = 11
GodModeStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
GodModeStatus.BackgroundTransparency = 1

local TeleportToggle = Instance.new("TextButton", ProtectionCategory)
TeleportToggle.Size = UDim2.new(0.48,-10,0,40)
TeleportToggle.Position = UDim2.new(0.51,0,0,45)
TeleportToggle.Text = "🔘 TELEPORT: OFF"
TeleportToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
TeleportToggle.TextColor3 = Color3.new(1,1,1)
ApplyCorner(TeleportToggle)

local TeleportStatus = Instance.new("TextLabel", ProtectionCategory)
TeleportStatus.Size = UDim2.new(0.48,-10,0,18)
TeleportStatus.Position = UDim2.new(0.51,0,0,90)
TeleportStatus.Text = "📊 Статус: OFF"
TeleportStatus.Font = "Gotham"
TeleportStatus.TextSize = 11
TeleportStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
TeleportStatus.BackgroundTransparency = 1

local TeleportHint = Instance.new("TextLabel", ProtectionCategory)
TeleportHint.Size = UDim2.new(0.98,-10,0,35)
TeleportHint.Position = UDim2.new(0,10,0,120)
TeleportHint.Text = "💡 Ctrl+Click в любое место для телепорта"
TeleportHint.Font = "Gotham"
TeleportHint.TextSize = 11
TeleportHint.TextColor3 = Color3.fromRGB(150, 150, 180)
TeleportHint.BackgroundTransparency = 1

-- 5. РАЗБЛОКИРОВКА МЫШИ
local MouseCategory = Instance.new("Frame", MainCont)
MouseCategory.Size = UDim2.new(1, -10, 0, 70)
MouseCategory.Position = UDim2.new(0, 5, 0, 800)
MouseCategory.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MouseCategory.BackgroundTransparency = 0.2
ApplyCorner(MouseCategory)

local MouseTitle = Instance.new("TextLabel", MouseCategory)
MouseTitle.Size = UDim2.new(1,0,0,30)
MouseTitle.Text = "🖱️ УПРАВЛЕНИЕ МЫШЬЮ"
MouseTitle.Font = "GothamBold"
MouseTitle.TextSize = 14
MouseTitle.BackgroundTransparency = 1
MouseTitle.TextColor3 = Color3.fromRGB(150, 255, 200)

local MouseToggleBtn = Instance.new("TextButton", MouseCategory)
MouseToggleBtn.Size = UDim2.new(0.48,-10,0,35)
MouseToggleBtn.Position = UDim2.new(0.01,0,0,38)
MouseToggleBtn.Text = "🖱️ РАЗБЛОКИРОВАТЬ МЫШЬ [" .. GetKeyName(Keybinds.UnlockMouse) .. "]"
MouseToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
MouseToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MouseToggleBtn.Font = "GothamBold"
ApplyCorner(MouseToggleBtn)

local MouseStatus = Instance.new("TextLabel", MouseCategory)
MouseStatus.Size = UDim2.new(0.48,-10,0,18)
MouseStatus.Position = UDim2.new(0.51,0,0,38)
MouseStatus.Text = "🖱️ Статус: ЗАБЛОКИРОВАНА 🔒"
MouseStatus.Font = "Gotham"
MouseStatus.TextSize = 11
MouseStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
MouseStatus.BackgroundTransparency = 1

local MouseHint = Instance.new("TextLabel", MouseCategory)
MouseHint.Size = UDim2.new(0.48,-10,0,18)
MouseHint.Position = UDim2.new(0.51,0,0,60)
MouseHint.Text = "📌 Нажмите " .. GetKeyName(Keybinds.UnlockMouse) .. " для разблокировки"
MouseHint.Font = "Gotham"
MouseHint.TextSize = 10
MouseHint.TextColor3 = Color3.fromRGB(150, 150, 180)
MouseHint.BackgroundTransparency = 1

-- 6. НАСТРОЙКА КЛАВИШ
local KeybindCategory = Instance.new("Frame", MainCont)
KeybindCategory.Size = UDim2.new(1, -10, 0, 200)
KeybindCategory.Position = UDim2.new(0, 5, 0, 890)
KeybindCategory.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
KeybindCategory.BackgroundTransparency = 0.2
ApplyCorner(KeybindCategory)

local KeybindTitle = Instance.new("TextLabel", KeybindCategory)
KeybindTitle.Size = UDim2.new(1,0,0,30)
KeybindTitle.Text = "⌨️ НАСТРОЙКА КЛАВИШ"
KeybindTitle.Font = "GothamBold"
KeybindTitle.TextSize = 14
KeybindTitle.BackgroundTransparency = 1
KeybindTitle.TextColor3 = Color3.fromRGB(255, 200, 100)

local FlyKeyLabel = Instance.new("TextLabel", KeybindCategory)
FlyKeyLabel.Size = UDim2.new(0.3, -10, 0, 35)
FlyKeyLabel.Position = UDim2.new(0.02,0,0,40)
FlyKeyLabel.Text = "✈️ Полёт:"
FlyKeyLabel.Font = "GothamBold"
FlyKeyLabel.TextSize = 13
FlyKeyLabel.BackgroundTransparency = 1
FlyKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local FlyKeyBtn = Instance.new("TextButton", KeybindCategory)
FlyKeyBtn.Size = UDim2.new(0.2, -10, 0, 35)
FlyKeyBtn.Position = UDim2.new(0.33,0,0,40)
FlyKeyBtn.Text = GetKeyName(Keybinds.Fly)
FlyKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
FlyKeyBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(FlyKeyBtn)

local SprintKeyLabel = Instance.new("TextLabel", KeybindCategory)
SprintKeyLabel.Size = UDim2.new(0.3, -10, 0, 35)
SprintKeyLabel.Position = UDim2.new(0.02,0,0,85)
SprintKeyLabel.Text = "🏃 Бег:"
SprintKeyLabel.Font = "GothamBold"
SprintKeyLabel.TextSize = 13
SprintKeyLabel.BackgroundTransparency = 1
SprintKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local SprintKeyBtn = Instance.new("TextButton", KeybindCategory)
SprintKeyBtn.Size = UDim2.new(0.2, -10, 0, 35)
SprintKeyBtn.Position = UDim2.new(0.33,0,0,85)
SprintKeyBtn.Text = GetKeyName(Keybinds.Sprint)
SprintKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
SprintKeyBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(SprintKeyBtn)

local MenuKeyLabel = Instance.new("TextLabel", KeybindCategory)
MenuKeyLabel.Size = UDim2.new(0.3, -10, 0, 35)
MenuKeyLabel.Position = UDim2.new(0.5,0,0,40)
MenuKeyLabel.Text = "🔑 Меню:"
MenuKeyLabel.Font = "GothamBold"
MenuKeyLabel.TextSize = 13
MenuKeyLabel.BackgroundTransparency = 1
MenuKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local MenuKeyBtn = Instance.new("TextButton", KeybindCategory)
MenuKeyBtn.Size = UDim2.new(0.2, -10, 0, 35)
MenuKeyBtn.Position = UDim2.new(0.78,0,0,40)
MenuKeyBtn.Text = GetKeyName(Keybinds.Menu)
MenuKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MenuKeyBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(MenuKeyBtn)

local MouseKeyLabel = Instance.new("TextLabel", KeybindCategory)
MouseKeyLabel.Size = UDim2.new(0.3, -10, 0, 35)
MouseKeyLabel.Position = UDim2.new(0.5,0,0,85)
MouseKeyLabel.Text = "🖱️ Мышь:"
MouseKeyLabel.Font = "GothamBold"
MouseKeyLabel.TextSize = 13
MouseKeyLabel.BackgroundTransparency = 1
MouseKeyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

local MouseKeyBtn = Instance.new("TextButton", KeybindCategory)
MouseKeyBtn.Size = UDim2.new(0.2, -10, 0, 35)
MouseKeyBtn.Position = UDim2.new(0.78,0,0,85)
MouseKeyBtn.Text = GetKeyName(Keybinds.UnlockMouse)
MouseKeyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
MouseKeyBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(MouseKeyBtn)

local ResetKeyBtn = Instance.new("TextButton", KeybindCategory)
ResetKeyBtn.Size = UDim2.new(0.3, -10, 0, 35)
ResetKeyBtn.Position = UDim2.new(0.35,0,0,145)
ResetKeyBtn.Text = "🔄 Сброс клавиш"
ResetKeyBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
ResetKeyBtn.TextColor3 = Color3.new(1,1,1)
ApplyCorner(ResetKeyBtn)

-- ==================== ОБРАБОТЧИКИ ====================
local freePart, antiy

local function UpdateAllButtons()
    FlyToggleBtn.Text = Bober.isFly and "🔴 FLY: ON (" .. GetKeyName(Keybinds.Fly) .. ")" or "🔘 FLY: OFF (" .. GetKeyName(Keybinds.Fly) .. ")"
    SprintToggle.Text = Bober.isSprintActive and "🏃 ON (" .. GetKeyName(Keybinds.Sprint) .. ")" or "🏃 OFF (" .. GetKeyName(Keybinds.Sprint) .. ")"
    FlyKeyBtn.Text = GetKeyName(Keybinds.Fly)
    SprintKeyBtn.Text = GetKeyName(Keybinds.Sprint)
    MenuKeyBtn.Text = GetKeyName(Keybinds.Menu)
    MouseKeyBtn.Text = GetKeyName(Keybinds.UnlockMouse)
    MouseToggleBtn.Text = Bober.isMouseUnlocked and "🖱️ ЗАБЛОКИРОВАТЬ МЫШЬ" or "🖱️ РАЗБЛОКИРОВАТЬ МЫШЬ [" .. GetKeyName(Keybinds.UnlockMouse) .. "]"
end

local function OnCharacterAdded()
    task.wait(0.5)
    if Bober.isGodMode then ApplyGodMode() end
    if Bober.isBanHammer then SetupBanHammerHandler() end
    if Bober.isFlinger then SetupFlingerHandler() end
    if Bober.isChairMode then
        task.wait(0.1)
        ToggleChairMode()
        Bober.isChairMode = true
        ToggleChairMode()
        Bober.isChairMode = true
    end
    if Bober.isFly and Bober.isSpinBlock then
        task.wait(0.2)
        TransformToSpinBlock()
    end
    UpdateAllButtons()
end

-- Обработчики кнопок
SpeedInput:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(SpeedInput.Text)
    if val and val > 0 and val < 500 then
        Bober.WS = val
        if Bober.isSpeedActive then ForceSpeed() end
    end
end)

SpeedToggle.MouseButton1Click:Connect(function()
    Bober.isSpeedActive = not Bober.isSpeedActive
    SpeedToggle.Text = Bober.isSpeedActive and "⚡ ON" or "⚡ OFF"
    SpeedToggle.BackgroundColor3 = Bober.isSpeedActive and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
    ForceSpeed()
end)

JumpToggle.MouseButton1Click:Connect(function()
    Bober.isJumpActive = not Bober.isJumpActive
    JumpToggle.Text = Bober.isJumpActive and "🦘 ON" or "🦘 OFF"
    JumpToggle.BackgroundColor3 = Bober.isJumpActive and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
end)

SprintInput:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(SprintInput.Text)
    if val and val > 0 and val < 500 then
        Bober.SS = val
        if Bober.isSprintActive and isSprinting then ForceSpeed() end
    end
end)

SprintToggle.MouseButton1Click:Connect(function()
    Bober.isSprintActive = not Bober.isSprintActive
    SprintToggle.Text = Bober.isSprintActive and "🏃 ON (" .. GetKeyName(Keybinds.Sprint) .. ")" or "🏃 OFF (" .. GetKeyName(Keybinds.Sprint) .. ")"
    SprintToggle.BackgroundColor3 = Bober.isSprintActive and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
    ForceSpeed()
end)

FlySpeedInput:GetPropertyChangedSignal("Text"):Connect(function()
    local val = tonumber(FlySpeedInput.Text)
    if val then Bober.FS = val end
end)

FlyToggleBtn.MouseButton1Click:Connect(function() 
    ToggleFly()
    UpdateAllButtons()
end)

SpinBlockBtn.MouseButton1Click:Connect(function() 
    ToggleSpinBlock()
    SpinBlockBtn.Text = Bober.isSpinBlock and "📐 ПРЯМОУГОЛЬНИК: ON" or "📐 ПРЯМОУГОЛЬНИК: OFF"
    SpinBlockBtn.BackgroundColor3 = Bober.isSpinBlock and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
end)

NoclipBtn.MouseButton1Click:Connect(function() if Bober.isFly then Bober.isNoc = not Bober.isNoc end end)

FlingerBtn.MouseButton1Click:Connect(function()
    Bober.isFlinger = not Bober.isFlinger
    if Bober.isFlinger then
        SetupFlingerHandler()
        FlingerBtn.Text = "💥 ФЛИНГЕР: ON"
        FlingerBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        FlingerStatus.Text = "💥 Статус: ON ✅"
        FlingerStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        ClearFlingerHandler()
        FlingerBtn.Text = "💥 ФЛИНГЕР: OFF"
        FlingerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        FlingerStatus.Text = "💥 Статус: OFF ❌"
        FlingerStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
    end
end)

BanHammerBtn.MouseButton1Click:Connect(function()
    Bober.isBanHammer = not Bober.isBanHammer
    if Bober.isBanHammer then
        SetupBanHammerHandler()
        BanHammerBtn.Text = "🔨 BAN HAMMER: ON"
        BanHammerBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        BanHammerStatus.Text = "🔨 Статус: ON ✅"
        BanHammerStatus.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        for _, conn in pairs(banHammerConnections) do pcall(function() conn:Disconnect() end) end
        banHammerConnections = {}
        BanHammerBtn.Text = "🔨 BAN HAMMER: OFF"
        BanHammerBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        BanHammerStatus.Text = "🔨 Статус: OFF ❌"
        BanHammerStatus.TextColor3 = Color3.fromRGB(150, 150, 180)
    end
end)

ChairModeBtn.MouseButton1Click:Connect(function()
    ToggleChairMode()
    ChairModeBtn.Text = Bober.isChairMode and "🪑 НЕВИДИМЫЙ СТУЛ: ON" or "🪑 НЕВИДИМЫЙ СТУЛ: OFF"
    ChairModeBtn.BackgroundColor3 = Bober.isChairMode and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
    ChairModeStatus.Text = Bober.isChairMode and "🪑 Статус: ON ✅" or "🪑 Статус: OFF ❌"
    ChairModeStatus.TextColor3 = Bober.isChairMode and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 180)
end)

DayNightBtn.MouseButton1Click:Connect(function() ToggleDayNight() end)

GodModeBtn.MouseButton1Click:Connect(function()
    ToggleGodMode()
    GodModeBtn.Text = Bober.isGodMode and "💀 GOD MODE: ON" or "💀 GOD MODE: OFF"
    GodModeBtn.BackgroundColor3 = Bober.isGodMode and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
    GodModeStatus.Text = Bober.isGodMode and "📊 Статус: ON ✅" or "📊 Статус: OFF ❌"
    GodModeStatus.TextColor3 = Bober.isGodMode and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 180)
end)

TeleportToggle.MouseButton1Click:Connect(function()
    Bober.isCtrlClickTeleport = not Bober.isCtrlClickTeleport
    TeleportToggle.Text = Bober.isCtrlClickTeleport and "✅ TELEPORT: ON" or "🔘 TELEPORT: OFF"
    TeleportToggle.BackgroundColor3 = Bober.isCtrlClickTeleport and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
    TeleportStatus.Text = Bober.isCtrlClickTeleport and "📊 Статус: ON ✅" or "📊 Статус: OFF ❌"
    TeleportStatus.TextColor3 = Bober.isCtrlClickTeleport and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 180)
end)

MouseToggleBtn.MouseButton1Click:Connect(function()
    ToggleMouseUnlock()
end)

WallBtn.MouseButton1Click:Connect(function()
    Bober.isWall = not Bober.isWall
    if Bober.isWall then Bober.isFly = false; FullPhysicsReset(); Bober.isWall = true end
end)

EspBtn.MouseButton1Click:Connect(function() Bober.isEsp = not Bober.isEsp end)
MM2Btn.MouseButton1Click:Connect(function() Bober.isMM2 = not Bober.isMM2 end)
FogBtn.MouseButton1Click:Connect(function() Bober.isFog = not Bober.isFog end)
FreeCamBtn.MouseButton1Click:Connect(function() Bober.isFree = not Bober.isFree end)

-- Настройка клавиш
FlyKeyBtn.MouseButton1Click:Connect(function()
    StartKeySetup("Fly", FlyKeyBtn, function()
        UpdateAllButtons()
    end)
end)

SprintKeyBtn.MouseButton1Click:Connect(function()
    StartKeySetup("Sprint", SprintKeyBtn, function()
        UpdateAllButtons()
    end)
end)

MenuKeyBtn.MouseButton1Click:Connect(function()
    StartKeySetup("Menu", MenuKeyBtn, function()
        UpdateAllButtons()
    end)
end)

MouseKeyBtn.MouseButton1Click:Connect(function()
    StartKeySetup("UnlockMouse", MouseKeyBtn, function()
        UpdateAllButtons()
        MouseHint.Text = "📌 Нажмите " .. GetKeyName(Keybinds.UnlockMouse) .. " для разблокировки"
    end)
end)

ResetKeyBtn.MouseButton1Click:Connect(function()
    Keybinds.Fly = Enum.KeyCode.F
    Keybinds.Sprint = Enum.KeyCode.R
    Keybinds.Menu = Enum.KeyCode.RightControl
    Keybinds.UnlockMouse = Enum.KeyCode.M
    UpdateAllButtons()
    MouseHint.Text = "📌 Нажмите " .. GetKeyName(Keybinds.UnlockMouse) .. " для разблокировки"
    print("Клавиши сброшены до стандартных!")
end)

-- CTRL+Click телепорт
Mouse.Button1Down:Connect(function()
    if Bober.isCtrlClickTeleport and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
        TeleportToMouse()
    end
end)

-- Обновление цветов кнопок
RunService.RenderStepped:Connect(function()
    if not Bober.Active then return end
    if shared.DBCheatClose then Bober.Active = false; return end
    pcall(function()
        WallBtn.BackgroundColor3 = Bober.isWall and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
        EspBtn.BackgroundColor3 = Bober.isEsp and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
        MM2Btn.BackgroundColor3 = Bober.isMM2 and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
        FogBtn.BackgroundColor3 = Bober.isFog and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
        FreeCamBtn.BackgroundColor3 = Bober.isFree and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(40, 40, 55)
        if Bober.isFly then
            NoclipBtn.BackgroundColor3 = Bober.isNoc and Color3.fromRGB(180, 50, 50) or Color3.fromRGB(60, 60, 80)
            NoclipBtn.Text = Bober.isNoc and "✅ NOCLIP" or "🛡️ NOCLIP"
        else
            NoclipBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
            NoclipBtn.Text = "🛡️ NOCLIP"
        end
    end)
end)

-- God Mode цикл
RunService.Heartbeat:Connect(function()
    if not Bober.Active then return end
    if Bober.isGodMode then
        local char = Player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end
                    if hum.MaxHealth ~= 9e9 then hum.MaxHealth = 9e9 end
                end)
            end
        end
    end
end)

-- Применение скорости
RunService.RenderStepped:Connect(function()
    if not Bober.Active then return end
    if shared.DBCheatClose then return end
    ForceSpeed()
end)

-- Основная логика
RunService.Stepped:Connect(function()
    if not Bober.Active then return end
    if shared.DBCheatClose then return end
    local char = Player.Character; if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    Player.DevCameraOcclusionMode = (Bober.isFly or Bober.isWall or Bober.isFree) and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
    
    if Bober.isFog then
        Lighting.FogEnd = 1e5
        pcall(function() for _,v in pairs(Lighting:GetDescendants()) do if v:IsA("Atmosphere") then v.Density = 0 end end end)
    end
    
    local shouldNoc = (Bober.isFly and Bober.isNoc) or (Bober.isWall and not Bober.isFly) or Bober.isFree
    for _, v in pairs(char:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = not shouldNoc end end
    
    if Bober.isWall and not Bober.isFly then
        hum.JumpPower = 0
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        if hum.FloorMaterial ~= Enum.Material.Air and not char.HumanoidRootPart:FindFirstChild("BAnchor") then
            antiy = Instance.new("BodyVelocity", char.HumanoidRootPart)
            antiy.Name = "BAnchor"
            antiy.Velocity = Vector3.new(0,0,0)
            antiy.MaxForce = Vector3.new(0,9e9,0)
        end
    elseif not Bober.isFly then
        if char.HumanoidRootPart:FindFirstChild("BAnchor") then char.HumanoidRootPart.BAnchor:Destroy() end
        if not Bober.isFree then
            hum.JumpPower = 50
            hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        end
    end
    
    if Bober.isFree then
        char.HumanoidRootPart.Anchored = true
        if not freePart then
            freePart = Instance.new("Part", workspace)
            freePart.Name = "DBCamPart"
            freePart.Transparency = 1
            freePart.Anchored = true
            freePart.CanCollide = false
            freePart.CFrame = Camera.CFrame
            Camera.CameraSubject = freePart
        end
        local d = Vector3.new(0,0,0)
        if UIS:IsKeyDown(Enum.KeyCode.W) then d = d + Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d = d - Camera.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d = d - Camera.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d = d + Camera.CFrame.RightVector end
        freePart.CFrame = freePart.CFrame + (d * (Bober.FS/100))
    else
        if freePart then freePart:Destroy(); freePart = nil; Camera.CameraSubject = char.Humanoid end
        if not Bober.isFly then char.HumanoidRootPart.Anchored = false end
    end
end)

-- ESP
RunService.RenderStepped:Connect(function()
    if not Bober.Active then return end
    if shared.DBCheatClose then return end
    for _, v in pairs(sg:GetChildren()) do
        if v.Name == "Extra" and v ~= TpWin and v ~= Main then v:Destroy() end
    end
    if Bober.isEsp or Bober.isMM2 then
        for _, p in pairs(game.Players:GetPlayers()) do
            if p ~= Player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local color = (Bober.isMM2 and (p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife")) and Color3.new(1,0,0)) or (Bober.isMM2 and (p.Backpack:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun") or p.Backpack:FindFirstChild("Revolver")) and Color3.new(0,0,1)) or (Bober.isMM2 and Color3.new(0,1,0)) or Color3.fromRGB(200,80,80)
                local h = Instance.new("Highlight", sg); h.Name = "Extra"; h.Adornee = p.Character; h.FillColor = color; h.OutlineColor = Color3.new(1,0,0)
                local b = Instance.new("BillboardGui", sg); b.Name = "Extra"; b.Adornee = p.Character.HumanoidRootPart; b.Size = UDim2.new(0, 120, 0, 35); b.AlwaysOnTop = true
                local l = Instance.new("TextLabel", b); l.Size = UDim2.new(1,0,1,0); l.Text = p.Name; l.TextColor3 = color; l.BackgroundTransparency = 1; l.Font = "GothamBold"; l.TextSize = 14
            end
        end
    end
end)

-- Управление клавишами
UIS.InputBegan:Connect(function(i, g)
    if g or not Bober.Active then return end
    if shared.DBCheatClose then return end
    if waitingForKey then return end
    if i.KeyCode == Keybinds.Menu then
        Main.Visible = not Main.Visible
        TpWin.Visible = false
    end
    if i.KeyCode == Keybinds.UnlockMouse then
        ToggleMouseUnlock()
    end
end)

UIS.InputBegan:Connect(function(i, g)
    if g or not Bober.Active then return end
    if shared.DBCheatClose then return end
    if waitingForKey then return end
    if i.KeyCode == Keybinds.Fly then ToggleFly(); UpdateAllButtons() end
end)

UIS.InputBegan:Connect(function(i, g)
    if g or not Bober.Active then return end
    if shared.DBCheatClose then return end
    if waitingForKey then return end
    if i.KeyCode == Enum.KeyCode.Space and Bober.isJumpActive and not Bober.isFly then DoJump() end
end)

Player.CharacterAdded:Connect(OnCharacterAdded)

Main:GetPropertyChangedSignal("Position"):Connect(function()
    if TpWin.Visible then
        local mainPos = Main.AbsolutePosition
        TpWin.Position = UDim2.new(0, mainPos.X - 450, 0, mainPos.Y)
    end
end)

-- Уведомление
local function ShowNotificationMsg()
    local notif = Instance.new("TextLabel", sg)
    notif.Size = UDim2.new(0, 400, 0, 50)
    notif.Position = UDim2.new(0.5, -200, 0.8, 0)
    notif.Text = "🔥 DB_CHEAT загружен! Нажмите " .. GetKeyName(Keybinds.Menu) .. " для закрытия меню "
    notif.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notif.BackgroundTransparency = 0.3
    notif.TextColor3 = Color3.fromRGB(255, 100, 100)
    notif.Font = Enum.Font.GothamBold
    notif.TextSize = 14
    ApplyCorner(notif)
    task.wait(4)
    notif:Destroy()
end

task.wait(0.5)
ForceSpeed()
ApplyGodMode()
UpdateAllButtons()
RefreshTeleportList()
RefreshKillList()
ShowNotificationMsg()

print("✅ DB_CHEAT ЗАГРУЖЕН | ВСЕ ФУНКЦИИ РАБОТАЮТ!")
print("🖱️ РАЗБЛОКИРОВКА МЫШИ - нажмите " .. GetKeyName(Keybinds.UnlockMouse) .. " для разблокировки/блокировки!")
print("⌨️ НАСТРОЙКА КЛАВИШ - все клавиши настраиваются в меню!")
