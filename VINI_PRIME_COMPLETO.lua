--[[
 VINI PRIME | ORG PRIME
 Painel de desenvolvimento para Roblox Studio.
 Instale como LocalScript em StarterPlayer > StarterPlayerScripts.

 Inclui:
 - Interface com abas e botão flutuante arrastável
 - ESP de destaque, nome, vida e distância para jogadores da SUA experiência
 - Lista de jogadores e seleção
 - Teleporte para jogador (somente experiência própria/teste local)
 - Câmera de observação e retorno à própria câmera
 - Velocidade e pulo infinito para testes locais
 - FOV e modo noturno
 - Atualização ao entrar/sair/respawn
 Nota: copiar aparência e ações administrativas devem ser validadas no servidor
 do seu próprio jogo. Este arquivo não funciona como exploit universal.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local C = {
    bg = Color3.fromRGB(12, 16, 28),
    panel = Color3.fromRGB(20, 27, 44),
    card = Color3.fromRGB(28, 38, 60),
    accent = Color3.fromRGB(43, 174, 255),
    accent2 = Color3.fromRGB(80, 98, 240),
    text = Color3.fromRGB(240, 245, 255),
    muted = Color3.fromRGB(155, 173, 200),
    off = Color3.fromRGB(67, 79, 103),
    green = Color3.fromRGB(42, 170, 120),
    red = Color3.fromRGB(175, 65, 80),
}

local state = {
    esp = false,
    showName = true,
    showHealth = true,
    showDistance = true,
    speed = false,
    infiniteJump = false,
    night = false,
    spectating = false,
    selectedPlayer = nil,
}
local highlights = {}
local tags = {}
local saved = {
    walkSpeed = 16,
    jumpPower = 50,
    fov = camera and camera.FieldOfView or 70,
    ambient = Lighting.Ambient,
    outdoor = Lighting.OutdoorAmbient,
    brightness = Lighting.Brightness,
}
local savedCameraSubject, savedCameraType
local connections = {}
local activePage = "INÍCIO"
local pageFrames, navButtons = {}, {}

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function characterOf(plr)
    return plr and plr.Character
end

local function humanoidOf(plr)
    local character = characterOf(plr)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function rootOf(plr)
    local character = characterOf(plr)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function tween(obj, duration, props, style)
    local t = TweenService:Create(obj, TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, obj)
end

local gui = make("ScreenGui", {
    Name = "ViniPrimeOrgPrime",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local orb = make("TextButton", {
    Name = "FloatingButton",
    Size = UDim2.fromOffset(62, 62),
    Position = UDim2.new(0, 18, 0.45, 0),
    BackgroundColor3 = C.panel,
    Text = "VP",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBlack,
    TextSize = 22,
    AutoButtonColor = false,
    ZIndex = 10,
}, gui)
round(orb, 22)
make("UIStroke", {Color = C.accent, Thickness = 2}, orb)
make("UIGradient", {Color = ColorSequence.new(C.accent2, C.accent), Rotation = 35}, orb)

local main = make("Frame", {
    Name = "MainPanel",
    Size = UDim2.new(0, 730, 0, 500),
    Position = UDim2.new(0.5, -365, 0.5, -250),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Visible = false,
}, gui)
round(main, 18)
make("UIStroke", {Color = C.accent, Thickness = 1.5, Transparency = 0.18}, main)
make("UISizeConstraint", {MinSize = Vector2.new(320, 350), MaxSize = Vector2.new(850, 650)}, main)
local uiScale = make("UIScale", {Scale = 1}, main)

local function scaleToViewport()
    local vp = camera and camera.ViewportSize or Vector2.new(900, 700)
    uiScale.Scale = math.clamp(math.min(vp.X / 880, vp.Y / 700), 0.58, 1)
end
scaleToViewport()
if camera then connect(camera:GetPropertyChangedSignal("ViewportSize"), scaleToViewport) end

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 76),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, main)
round(top, 18)
make("Frame", {Size = UDim2.new(1, 0, 0, 18), Position = UDim2.new(0, 0, 1, -18), BackgroundColor3 = C.panel, BorderSizePixel = 0}, top)

make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(20, 10),
    Size = UDim2.new(1, -80, 0, 32),
    Text = "VINI PRIME",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBlack,
    TextSize = 23,
    TextXAlignment = Enum.TextXAlignment.Left,
}, top)
make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(21, 42),
    Size = UDim2.new(1, -80, 0, 18),
    Text = "ORG PRIME  •  STUDIO TOOLKIT",
    TextColor3 = C.accent,
    Font = Enum.Font.GothamBold,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, top)
local close = make("TextButton", {
    Size = UDim2.fromOffset(38, 38),
    Position = UDim2.new(1, -52, 0, 18),
    BackgroundColor3 = C.red,
    Text = "×",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 25,
    AutoButtonColor = false,
}, top)
round(close, 11)

local sidebar = make("Frame", {
    Position = UDim2.fromOffset(13, 90),
    Size = UDim2.new(0, 154, 1, -103),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, main)
round(sidebar, 13)
make("UIPadding", {PaddingTop = UDim.new(0, 9), PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7)}, sidebar)
make("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, sidebar)

local content = make("ScrollingFrame", {
    Position = UDim2.new(0, 178, 0, 90),
    Size = UDim2.new(1, -191, 1, -103),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.accent,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
}, main)
make("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 7), PaddingBottom = UDim.new(0, 12)}, content)

local function makePage(name, order)
    local nav = make("TextButton", {
        Name = name .. "Nav",
        Size = UDim2.new(1, 0, 0, 41),
        BackgroundColor3 = C.card,
        Text = name,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
        LayoutOrder = order,
    }, sidebar)
    round(nav, 10)
    navButtons[name] = nav

    local page = make("Frame", {
        Name = name .. "Page",
        Size = UDim2.new(1, -2, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Visible = false,
    }, content)
    make("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    pageFrames[name] = page
    nav.Activated:Connect(function()
        activePage = name
        for n, p in pairs(pageFrames) do p.Visible = n == name end
        for n, b in pairs(navButtons) do
            tween(b, 0.15, {BackgroundColor3 = n == name and Color3.fromRGB(32, 100, 150) or C.card})
        end
    end)
    return page
end

local function section(parent, title, desc)
    local f = make("Frame", {
        Size = UDim2.new(1, 0, 0, desc and 70 or 43),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
    }, parent)
    round(f, 11)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(13, 6),
        Size = UDim2.new(1, -26, 0, 24),
        Text = title,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    if desc then
        make("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(13, 31),
            Size = UDim2.new(1, -26, 0, 32),
            Text = desc,
            TextColor3 = C.muted,
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, f)
    end
    return f
end

local function button(parent, text, callback)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = Color3.fromRGB(29, 91, 135),
        Text = text,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
    }, parent)
    round(b, 10)
    b.Activated:Connect(function()
        tween(b, 0.1, {BackgroundColor3 = C.accent2})
        task.delay(0.12, function()
            if b.Parent then tween(b, 0.15, {BackgroundColor3 = Color3.fromRGB(29, 91, 135)}) end
        end)
        callback()
    end)
    return b
end

local function toggle(parent, title, desc, initial, callback)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = C.card,
        Text = "",
        AutoButtonColor = false,
    }, parent)
    round(b, 11)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 7),
        Size = UDim2.new(1, -78, 0, 22),
        Text = title,
        TextColor3 = C.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, b)
    make("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(12, 29),
        Size = UDim2.new(1, -78, 0, 25),
        Text = desc or "",
        TextColor3 = C.muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, b)
    local track = make("Frame", {
        Size = UDim2.fromOffset(40, 23),
        Position = UDim2.new(1, -52, 0.5, -11),
        BackgroundColor3 = initial and C.accent or C.off,
        BorderSizePixel = 0,
    }, b)
    round(track, 15)
    local knob = make("Frame", {
        Size = UDim2.fromOffset(17, 17),
        Position = initial and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, track)
    round(knob, 12)
    local value = initial == true
    local function set(v)
        value = v == true
        tween(track, 0.15, {BackgroundColor3 = value and C.accent or C.off})
        tween(knob, 0.15, {Position = value and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)})
        callback(value)
    end
    b.Activated:Connect(function() set(not value) end)
    return {Get = function() return value end, Set = set}
end

local function clearPlayerESP(plr)
    if highlights[plr] then highlights[plr]:Destroy(); highlights[plr] = nil end
    if tags[plr] then tags[plr]:Destroy(); tags[plr] = nil end
end

local function refreshPlayerESP(plr)
    if plr == localPlayer then return end
    local char = characterOf(plr)
    local hum = humanoidOf(plr)
    local root = rootOf(plr)

    if not state.esp or not char or not hum or not root or hum.Health <= 0 then
        clearPlayerESP(plr)
        return
    end

    if highlights[plr] and highlights[plr].Adornee ~= char then clearPlayerESP(plr) end

    if not highlights[plr] then
        local h = Instance.new("Highlight")
        h.Name = "ViniPrimeHighlight"
        h.Adornee = char
        h.FillColor = C.accent
        h.OutlineColor = Color3.new(1, 1, 1)
        h.FillTransparency = 0.82
        h.OutlineTransparency = 0
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = gui
        highlights[plr] = h

        local bb = Instance.new("BillboardGui")
        bb.Name = "ViniPrimePlayerTag"
        bb.Adornee = root
        bb.Size = UDim2.fromOffset(210, 60)
        bb.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
        bb.AlwaysOnTop = true
        bb.MaxDistance = 1200
        bb.Parent = gui

        local label = Instance.new("TextLabel")
        label.Name = "Info"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 1, 1)
        label.TextStrokeColor3 = Color3.new(0, 0, 0)
        label.TextStrokeTransparency = 0.1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 12
        label.TextWrapped = true
        label.Parent = bb
        tags[plr] = bb
    end

    highlights[plr].Adornee = char
    local bb = tags[plr]
    bb.Adornee = root
    local lines = {}
    if state.showName then table.insert(lines, plr.DisplayName .. " (@" .. plr.Name .. ")") end
    if state.showHealth then table.insert(lines, string.format("HP: %d/%d", math.max(0, math.floor(hum.Health)), math.floor(hum.MaxHealth))) end
    if state.showDistance then
        local myRoot = rootOf(localPlayer)
        if myRoot then table.insert(lines, math.floor((myRoot.Position - root.Position).Magnitude) .. " studs") end
    end
    bb.Info.Text = #lines > 0 and table.concat(lines, "\n") or "Player"
end

local function refreshAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do refreshPlayerESP(plr) end
    for plr in pairs(highlights) do
        if not plr.Parent then clearPlayerESP(plr) end
    end
end

local home = makePage("INÍCIO", 1)
local visual = makePage("VISUAL", 2)
local playersPage = makePage("JOGADORES", 3)
local movement = makePage("MOVIMENTO", 4)
local appearance = makePage("APARÊNCIA", 5)
local config = makePage("CONFIG", 6)

section(home, "Bem-vindo ao VINI PRIME", "Ferramentas para desenvolvimento e testes na sua própria experiência Roblox.")
button(home, "ATUALIZAR LISTA DE JOGADORES", function()
    refreshAllESP()
end)
button(home, "RESTAURAR CONFIGURAÇÕES", function()
    local hum = humanoidOf(localPlayer)
    if hum then
        hum.WalkSpeed = saved.walkSpeed
        hum.JumpPower = saved.jumpPower
    end
    if camera then camera.FieldOfView = saved.fov end
    Lighting.Ambient = saved.ambient
    Lighting.OutdoorAmbient = saved.outdoor
    Lighting.Brightness = saved.brightness
    state.speed = false
    state.infiniteJump = false
    state.night = false
end)

section(visual, "VISUAL / ESP", "Destaques e etiquetas de jogadores na sua própria experiência.")
toggle(visual, "ESP / caixa de destaque", "Contorno do personagem.", false, function(v)
    state.esp = v
    if v then refreshAllESP() else
        for plr in pairs(highlights) do clearPlayerESP(plr) end
    end
end)
toggle(visual, "Mostrar nome", "Nome e @usuário.", true, function(v) state.showName = v; refreshAllESP() end)
toggle(visual, "Mostrar vida", "Vida atual e máxima.", true, function(v) state.showHealth = v; refreshAllESP() end)
toggle(visual, "Mostrar distância", "Distância em studs.", true, function(v) state.showDistance = v; refreshAllESP() end)

section(playersPage, "LISTA DE JOGADORES", "Selecione alguém da sua experiência para as ferramentas de teste.")
local selectedLabel = make("TextLabel", {
    Size = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.card,
    Text = "Selecionado: ninguém",
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextWrapped = true,
}, playersPage)
round(selectedLabel, 10)

local listFrame = make("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
}, playersPage)
make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, listFrame)

local function rebuildPlayerList()
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            local b = button(listFrame, plr.DisplayName .. "  (@" .. plr.Name .. ")", function()
                state.selectedPlayer = plr
                selectedLabel.Text = "Selecionado: " .. plr.DisplayName .. " (@" .. plr.Name .. ")"
            end)
            b.Size = UDim2.new(1, 0, 0, 36)
        end
    end
end
rebuildPlayerList()

button(playersPage, "TELEPORTAR ATÉ SELECIONADO", function()
    local target = state.selectedPlayer
    local myRoot = rootOf(localPlayer)
    local targetRoot = rootOf(target)
    if myRoot and targetRoot then
        -- Para testes no seu próprio jogo. Produção deve validar a permissão no servidor.
        myRoot.CFrame = targetRoot.CFrame * CFrame.new(3, 0, 0)
    else
        selectedLabel.Text = "Jogador ou personagem indisponível."
    end
end)
button(playersPage, "OBSERVAR SELECIONADO", function()
    local targetHum = humanoidOf(state.selectedPlayer)
    if targetHum and camera then
        if not state.spectating then
            savedCameraSubject = camera.CameraSubject
            savedCameraType = camera.CameraType
        end
        state.spectating = true
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = targetHum
    else
        selectedLabel.Text = "Selecione um jogador vivo."
    end
end)
button(playersPage, "VOLTAR À MINHA CÂMERA", function()
    state.spectating = false
    if camera then
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoidOf(localPlayer)
    end
end)

section(movement, "MOVIMENTO", "Opções locais para testar mecânicas no seu próprio projeto.")
toggle(movement, "Velocidade extra", "Define WalkSpeed para 28.", false, function(v)
    local hum = humanoidOf(localPlayer)
    if not hum then return end
    if v then saved.walkSpeed = hum.WalkSpeed; hum.WalkSpeed = 28
    else hum.WalkSpeed = saved.walkSpeed end
    state.speed = v
end)
toggle(movement, "Pulo infinito", "Permite saltar novamente no ar.", false, function(v)
    state.infiniteJump = v
end)
button(movement, "RESTAURAR VELOCIDADE", function()
    local hum = humanoidOf(localPlayer)
    if hum then hum.WalkSpeed = saved.walkSpeed; hum.JumpPower = saved.jumpPower end
    state.speed = false
    state.infiniteJump = false
end)

section(appearance, "APARÊNCIA", "A troca de aparência de avatares deve ser feita pelo servidor do seu próprio jogo.")
button(appearance, "ABRIR DOCUMENTAÇÃO DE AVATARES", function()
    -- Abra manualmente a documentação no navegador:
    -- https://create.roblox.com/docs/characters/appearance
    selectedLabel.Text = "Consulte create.roblox.com/docs/characters/appearance"
end)

section(config, "CONFIGURAÇÕES", "Ajustes visuais locais.")
toggle(config, "Modo noturno", "Escurece a iluminação.", false, function(v)
    state.night = v
    if v then
        Lighting.Ambient = Color3.fromRGB(35, 43, 74)
        Lighting.OutdoorAmbient = Color3.fromRGB(20, 25, 48)
        Lighting.Brightness = 1
    else
        Lighting.Ambient = saved.ambient
        Lighting.OutdoorAmbient = saved.outdoor
        Lighting.Brightness = saved.brightness
    end
end)

local fovCard = make("Frame", {Size = UDim2.new(1, 0, 0, 68), BackgroundColor3 = C.card, BorderSizePixel = 0}, config)
round(fovCard, 10)
local fovLabel = make("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 5),
    Size = UDim2.new(1, -24, 0, 22),
    Text = "FOV da câmera: " .. tostring(saved.fov),
    TextColor3 = C.text,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, fovCard)
local fovBar = make("Frame", {Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 0, 8), BackgroundColor3 = C.off, BorderSizePixel = 0}, fovCard)
round(fovBar, 6)
local fovFill = make("Frame", {Size = UDim2.new(math.clamp((saved.fov - 50) / 60, 0, 1), 0, 1, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0}, fovBar)
round(fovFill, 6)
local fovHit = make("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = ""}, fovBar)
local function setFov(x)
    local fraction = math.clamp((x - fovBar.AbsolutePosition.X) / math.max(fovBar.AbsoluteSize.X, 1), 0, 1)
    local value = math.floor(50 + fraction * 60)
    fovLabel.Text = "FOV da câmera: " .. value
    fovFill.Size = UDim2.new(fraction, 0, 1, 0)
    if camera then camera.FieldOfView = value end
end
fovHit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        setFov(input.Position.X)
    end
end)
fovHit.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        setFov(input.Position.X)
    elseif input.UserInputType == Enum.UserInputType.Touch then
        setFov(input.Position.X)
    end
end)
button(config, "FECHAR PAINEL", function() main.Visible = false end)

-- Inicializa a primeira aba.
for name, page in pairs(pageFrames) do page.Visible = name == activePage end
for name, b in pairs(navButtons) do b.BackgroundColor3 = name == activePage and Color3.fromRGB(32, 100, 150) or C.card end

local function setOpen(open)
    if open then
        main.Visible = true
        main.Position = UDim2.new(0.5, -365, 0.5, -225)
        tween(main, 0.2, {Position = UDim2.new(0.5, -365, 0.5, -250)}, Enum.EasingStyle.Back)
    else
        tween(main, 0.14, {Position = UDim2.new(0.5, -365, 0.5, -225)})
        task.delay(0.15, function() main.Visible = false end)
    end
end
orb.Activated:Connect(function() setOpen(not main.Visible) end)
close.Activated:Connect(function() setOpen(false) end)

-- Arrastar painel e botão flutuante.
local function draggable(handle, target)
    local dragging, dragStart, startPos, activeInput = false, nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            activeInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            activeInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == activeInput or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
draggable(top, main)
draggable(orb, orb)

connect(UserInputService.JumpRequest, function()
    if state.infiniteJump then
        local hum = humanoidOf(localPlayer)
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

connect(Players.PlayerAdded, function(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.4)
        if state.esp then refreshPlayerESP(plr) end
    end)
    task.defer(rebuildPlayerList)
end)
connect(Players.PlayerRemoving, function(plr)
    clearPlayerESP(plr)
    if state.selectedPlayer == plr then
        state.selectedPlayer = nil
        selectedLabel.Text = "Selecionado: ninguém"
    end
    task.defer(rebuildPlayerList)
end)

connect(RunService.Heartbeat, function()
    if state.esp then refreshAllESP() end
end)

connect(localPlayer.CharacterAdded, function()
    task.wait(0.5)
    local hum = humanoidOf(localPlayer)
    if hum and state.speed then hum.WalkSpeed = 28 end
    if camera and state.spectating then
        camera.CameraSubject = hum
        state.spectating = false
    end
end)

script.Destroying:Connect(function()
    for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
    for plr in pairs(highlights) do clearPlayerESP(plr) end
    if camera then
        camera.FieldOfView = saved.fov
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoidOf(localPlayer)
    end
    Lighting.Ambient = saved.ambient
    Lighting.OutdoorAmbient = saved.outdoor
    Lighting.Brightness = saved.brightness
end)
