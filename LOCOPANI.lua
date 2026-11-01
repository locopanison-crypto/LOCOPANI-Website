-- LOCOPANI PRIVATE LOADER
-- O V23 e entregue pelo Supabase somente apos validacao da key + Roblox UserId.

-- LOCOPANI Matte Purple: fundo sólido, borda neon roxa e glow externo.
local function LOCOPANI_AddRainbowAccent(window)
    if not window or not window.Main then return end

    local main = window.Main
    if not main:IsA("GuiObject") then return end
    if main:FindFirstChild("LOCOPANI_RainbowBorder") then return end

    local purple = Color3.fromRGB(145, 65, 255)
    local deepPurple = Color3.fromRGB(25, 12, 43)

    pcall(function()
        main.BackgroundColor3 = deepPurple
        main.BackgroundTransparency = 0
    end)

    local sidebar = window.Sidebar
    if sidebar and sidebar:IsA("GuiObject") then
        pcall(function()
            sidebar.BackgroundColor3 = Color3.fromRGB(19, 10, 34)
            sidebar.BackgroundTransparency = 0
        end)
        local squareEdge = sidebar:FindFirstChild("SquareEdge")
        if squareEdge and squareEdge:IsA("GuiObject") then
            squareEdge.BackgroundTransparency = 0
            squareEdge.BackgroundColor3 = Color3.fromRGB(19, 10, 34)
        end
    end

    for _, child in ipairs(main:GetChildren()) do
        if child:IsA("UIStroke") then
            child.Enabled = false
        end
    end

    local outerGlow = Instance.new("UIStroke")
    outerGlow.Name = "LOCOPANI_RainbowGlow"
    outerGlow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outerGlow.Color = purple
    outerGlow.Thickness = 7
    outerGlow.Transparency = 0.48
    outerGlow.Parent = main

    local border = Instance.new("UIStroke")
    border.Name = "LOCOPANI_RainbowBorder"
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Color = Color3.fromRGB(180, 115, 255)
    border.Thickness = 1.8
    border.Transparency = 0.02
    border.Parent = main

    local pulseInfo = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    game:GetService("TweenService"):Create(outerGlow, pulseInfo, {
        Transparency = 0.68,
        Thickness = 5
    }):Play()
end

-- Partículas flutuam em várias direções; o brilho acompanha o cursor no ponto correto.
local function LOCOPANI_AddSiteEffects(window)
    if not window or not window.Main then return end

    local main = window.Main
    if not main:IsA("GuiObject") then return end
    if main:FindFirstChild("LOCOPANI_SiteEffects") then return end

    local tweenService = game:GetService("TweenService")
    local userInputService = game:GetService("UserInputService")
    local guiService = game:GetService("GuiService")
    local screenGui = window.ScreenGui

    local layer = Instance.new("Frame")
    layer.Name = "LOCOPANI_SiteEffects"
    layer.BackgroundTransparency = 1
    layer.BorderSizePixel = 0
    layer.Size = UDim2.fromScale(1, 1)
    layer.Position = UDim2.fromScale(0, 0)
    layer.ClipsDescendants = true
    layer.Active = false
    layer.Selectable = false
    layer.ZIndex = 20
    layer.Parent = main

    -- Slime trail: pequenas gotas elásticas que seguem o cursor e desaparecem suavemente.
    local trailFolder = Instance.new("Folder")
    trailFolder.Name = "LOCOPANI_SlimeTrail"
    trailFolder.Parent = layer

    local trailPool = {}
    local trailIndex = 0
    for i = 1, 9 do
        local blob = Instance.new("Frame")
        blob.Name = "SlimeBlob"
        blob.AnchorPoint = Vector2.new(0.5, 0.5)
        blob.Size = UDim2.fromOffset(18, 18)
        blob.BackgroundColor3 = Color3.fromRGB(165, 90, 255)
        blob.BackgroundTransparency = 0.18
        blob.BorderSizePixel = 0
        blob.Visible = false
        blob.ZIndex = 24
        blob.Parent = trailFolder
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = blob
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(220, 185, 255)
        stroke.Thickness = 1.2
        stroke.Transparency = 0.25
        stroke.Parent = blob
        trailPool[i] = {frame = blob, stroke = stroke}
    end

    local function spawnSlime(x, y, speed)
        trailIndex = trailIndex % #trailPool + 1
        local item = trailPool[trailIndex]
        local blob, stroke = item.frame, item.stroke
        if not blob.Parent then return end
        local size = math.random(9, 17)
        blob.Position = UDim2.fromOffset(x, y)
        blob.Size = UDim2.fromOffset(size * 1.35, size * 0.78)
        blob.Rotation = math.random(-25, 25)
        blob.BackgroundTransparency = 0.12
        stroke.Transparency = 0.18
        blob.Visible = true
        local duration = math.clamp(0.34 - (speed or 0) * 0.00012, 0.19, 0.34)
        tweenService:Create(blob, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(2, 2),
            BackgroundTransparency = 1,
            Rotation = blob.Rotation + math.random(-35, 35),
        }):Play()
        tweenService:Create(stroke, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1,
            Thickness = 0.2,
        }):Play()
        task.delay(duration + 0.03, function()
            if blob.Parent then blob.Visible = false end
        end)
    end

    -- Clique: anel que expande como uma bolha estourando + gotículas radiais.
    local function popBubble(x, y)
        local ring = Instance.new("Frame")
        ring.Name = "LOCOPANI_BubblePop"
        ring.AnchorPoint = Vector2.new(0.5, 0.5)
        ring.Position = UDim2.fromOffset(x, y)
        ring.Size = UDim2.fromOffset(8, 8)
        ring.BackgroundTransparency = 1
        ring.BorderSizePixel = 0
        ring.ZIndex = 27
        ring.Parent = layer
        local round = Instance.new("UICorner")
        round.CornerRadius = UDim.new(1, 0)
        round.Parent = ring
        local outline = Instance.new("UIStroke")
        outline.Color = Color3.fromRGB(205, 155, 255)
        outline.Thickness = 3
        outline.Transparency = 0.08
        outline.Parent = ring
        tweenService:Create(ring, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(76, 76),
        }):Play()
        tweenService:Create(outline, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1,
            Thickness = 0.4,
        }):Play()
        task.delay(0.42, function()
            if ring.Parent then ring:Destroy() end
        end)

        for i = 1, 8 do
            local angle = (math.pi * 2) * (i / 8)
            local distance = math.random(24, 48)
            local dot = Instance.new("Frame")
            dot.Name = "LOCOPANI_BubbleDroplet"
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Position = UDim2.fromOffset(x, y)
            local dotSize = math.random(4, 8)
            dot.Size = UDim2.fromOffset(dotSize, dotSize)
            dot.BackgroundColor3 = (i % 2 == 0)
                and Color3.fromRGB(225, 195, 255)
                or Color3.fromRGB(150, 75, 255)
            dot.BorderSizePixel = 0
            dot.ZIndex = 28
            dot.Parent = layer
            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(1, 0)
            dotCorner.Parent = dot
            local target = UDim2.fromOffset(x + math.cos(angle) * distance, y + math.sin(angle) * distance)
            tweenService:Create(dot, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = target,
                Size = UDim2.fromOffset(1, 1),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.36, function()
                if dot.Parent then dot:Destroy() end
            end)
        end
    end

    local lastCursorPosition
    local function getLocalCursorPosition()
        local mouse = userInputService:GetMouseLocation()
        local inset = Vector2.new(0, 0)
        if screenGui then
            pcall(function()
                if not screenGui.IgnoreGuiInset then
                    local topLeft = guiService:GetGuiInset()
                    inset = Vector2.new(topLeft.X, topLeft.Y)
                end
            end)
        end
        local correctedMouse = mouse - inset
        return correctedMouse - main.AbsolutePosition
    end

    local function updateCursorGlow()
        if not layer.Parent or not main.Parent then return nil end
        local enabled = main.Visible
        if screenGui then
            pcall(function() enabled = enabled and screenGui.Enabled end)
        end
        if not enabled then
            lastCursorPosition = nil
            return nil
        end
        local localPosition = getLocalCursorPosition()
        local inside = localPosition.X >= 0 and localPosition.Y >= 0
            and localPosition.X <= main.AbsoluteSize.X
            and localPosition.Y <= main.AbsoluteSize.Y
        if not inside then
            lastCursorPosition = nil
            return nil
        end
        return localPosition
    end

    local connections = {}
    table.insert(connections, userInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local pos = updateCursorGlow()
            if pos then
                local speed = 0
                if lastCursorPosition then
                    speed = (pos - lastCursorPosition).Magnitude
                end
                if not lastCursorPosition or speed >= 2.5 then
                    spawnSlime(pos.X, pos.Y, speed)
                end
                lastCursorPosition = pos
            end
        end
    end))
    table.insert(connections, userInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            local pos = updateCursorGlow()
            if pos then
                popBubble(pos.X, pos.Y)
            end
        end
    end))
    -- Transição de abertura: uma estrela LOCOPANI gira e desaparece.
    -- A animação é acionada quando a janela volta a ficar visível.
    local transitionStar = Instance.new("TextLabel")
    transitionStar.Name = "LOCOPANI_TransitionStar"
    transitionStar.AnchorPoint = Vector2.new(0.5, 0.5)
    transitionStar.Position = UDim2.fromScale(0.5, 0.5)
    transitionStar.Size = UDim2.fromOffset(76, 76)
    transitionStar.BackgroundTransparency = 1
    transitionStar.Text = "✦"
    transitionStar.TextColor3 = Color3.fromRGB(210, 170, 255)
    transitionStar.TextTransparency = 1
    transitionStar.TextSize = 56
    transitionStar.Font = Enum.Font.GothamBold
    transitionStar.ZIndex = 80
    transitionStar.Visible = false
    transitionStar.Parent = layer

    local transitionScale = Instance.new("UIScale")
    transitionScale.Scale = 0.35
    transitionScale.Parent = transitionStar

    local transitionBusy = false
    local function playStarTransition()
        if transitionBusy or not main.Visible then return end
        transitionBusy = true
        transitionStar.Visible = true
        transitionStar.Rotation = -90
        transitionStar.TextTransparency = 0.05
        transitionScale.Scale = 0.35
        local spin = tweenService:Create(
            transitionStar,
            TweenInfo.new(0.62, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Rotation = 450, TextTransparency = 1 }
        )
        local expand = tweenService:Create(
            transitionScale,
            TweenInfo.new(0.62, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1.45 }
        )
        spin:Play()
        expand:Play()
        task.delay(0.66, function()
            if transitionStar.Parent then transitionStar.Visible = false end
            transitionBusy = false
        end)
    end

    table.insert(connections, main:GetPropertyChangedSignal("Visible"):Connect(function()
        lastCursorPosition = nil
        if main.Visible then playStarTransition() end
    end))
    if screenGui then
        table.insert(connections, screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
            lastCursorPosition = nil
            if screenGui.Enabled and main.Visible then playStarTransition() end
        end))
    end

    local particleColors = {
        Color3.fromRGB(190, 130, 255),
        Color3.fromRGB(135, 90, 230),
        Color3.fromRGB(225, 195, 255),
        Color3.fromRGB(160, 90, 255),
    }

    -- Pool pequeno e fixo; cada partícula nasce em uma borda aleatória
    -- e atravessa a janela em uma direção diferente.
    for index = 1, 16 do
        local particle = Instance.new("Frame")
        particle.Name = "LOCOPANI_FloatingParticle"
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
        particle.BackgroundColor3 = particleColors[math.random(1, #particleColors)]
        particle.BackgroundTransparency = 1
        particle.BorderSizePixel = 0
        particle.Visible = false
        particle.Active = false
        particle.ZIndex = 23
        particle.Parent = layer

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = particle

        task.spawn(function()
            while particle.Parent and layer.Parent do
                local visible = main.Visible
                if screenGui then
                    pcall(function() visible = visible and screenGui.Enabled end)
                end

                if visible then
                    local width = math.max(main.AbsoluteSize.X, 2)
                    local height = math.max(main.AbsoluteSize.Y, 2)
                    local side = math.random(1, 4)
                    local startX, startY, endX, endY

                    if side == 1 then -- esquerda para direita
                        startX, startY = -8, math.random(0, math.floor(height))
                        endX, endY = width + 8, math.clamp(startY + math.random(-150, 150), 0, height)
                    elseif side == 2 then -- direita para esquerda
                        startX, startY = width + 8, math.random(0, math.floor(height))
                        endX, endY = -8, math.clamp(startY + math.random(-150, 150), 0, height)
                    elseif side == 3 then -- topo para baixo/diagonal
                        startX, startY = math.random(0, math.floor(width)), -8
                        endX, endY = math.clamp(startX + math.random(-160, 160), 0, width), height + 8
                    else -- baixo para cima/diagonal
                        startX, startY = math.random(0, math.floor(width)), height + 8
                        endX, endY = math.clamp(startX + math.random(-160, 160), 0, width), -8
                    end

                    local duration = math.random(7, 13)
                    particle.Position = UDim2.fromOffset(startX, startY)
                    particle.BackgroundTransparency = math.random(12, 30) / 100
                    particle.Visible = true

                    local tween = tweenService:Create(
                        particle,
                        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                        {
                            Position = UDim2.fromOffset(endX, endY),
                            BackgroundTransparency = 1,
                        }
                    )
                    tween:Play()
                    task.wait(duration + 0.1)
                    tween:Destroy()
                else
                    particle.Visible = false
                    task.wait(0.5)
                end
                if particle.Parent then
                    task.wait(math.random(10, 45) / 100)
                end
            end
        end)
    end

    window._LOCOPANI_SiteEffectConnections = connections
    window._LOCOPANI_SiteEffectsLayer = layer

    main.AncestryChanged:Connect(function(_, parent)
        if parent == nil then
            for _, connection in ipairs(connections) do
                pcall(function() connection:Disconnect() end)
            end
        end
    end)

    updateCursorGlow()
end


-- LOCOPANI interactive depth: soft purple hover glow + subtle 3D lift.
local function LOCOPANI_ApplyInteractivePolish(window)
    if not window then return end
    local root = window.ScreenGui or window.Main
    if not root then return end

    local TweenService = game:GetService("TweenService")
    local styled = setmetatable({}, { __mode = "k" })
    local purple = Color3.fromRGB(166, 92, 255)
    local brightPurple = Color3.fromRGB(210, 170, 255)

    local function replaceBranding(object)
        if not (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) then
            return
        end
        local ok, currentText = pcall(function() return object.Text end)
        if not ok or type(currentText) ~= "string" then return end
        local updated = currentText
        updated = updated:gsub("[Aa][Rr][Gg][Oo][Nn]%s+[Hh][Uu][Bb]", "LOCOPANI")
        updated = updated:gsub("[Aa][Rr][Gg][Oo][Nn]%s+[Oo][Nn][Ll][Ii][Nn][Ee]", "LOCOPANI ONLINE")
        updated = updated:gsub("[Aa][Rr][Gg][Oo][Nn]", "LOCOPANI")
        if updated ~= currentText then
            pcall(function() object.Text = updated end)
        end
    end

    local function styleButton(button)
        if not button:IsA("GuiButton") or styled[button] then return end
        styled[button] = true

        local stroke = Instance.new("UIStroke")
        stroke.Name = "LOCOPANI_InteractiveGlow"
        stroke.Color = purple
        stroke.Thickness = 1
        stroke.Transparency = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = button

        local scale = Instance.new("UIScale")
        scale.Name = "LOCOPANI_InteractiveDepth"
        scale.Scale = 1
        scale.Parent = button

        local hovering = false
        local function tweenTo(size, transparency, thickness, duration)
            if not button.Parent then return end
            TweenService:Create(scale, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Scale = size
            }):Play()
            TweenService:Create(stroke, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Transparency = transparency,
                Thickness = thickness,
            }):Play()
        end

        button.MouseEnter:Connect(function()
            hovering = true
            tweenTo(1.035, 0.12, 2.2, 0.16)
        end)

        button.MouseLeave:Connect(function()
            hovering = false
            tweenTo(1, 1, 1, 0.18)
        end)

        button.Activated:Connect(function()
            tweenTo(1.045, 0.02, 2.8, 0.09)
            task.delay(0.12, function()
                if not button.Parent then return end
                if hovering then
                    tweenTo(1.035, 0.12, 2.2, 0.14)
                else
                    tweenTo(1, 1, 1, 0.18)
                end
            end)
        end)

        button.Destroying:Connect(function()
            styled[button] = nil
        end)
    end

    local function process(object)
        replaceBranding(object)
        if object:IsA("GuiButton") then
            styleButton(object)
        end
    end

    for _, object in ipairs(root:GetDescendants()) do
        process(object)
    end

    root.DescendantAdded:Connect(function(object)
        process(object)
        -- Some controls build their text/children immediately after parenting.
        task.defer(function()
            if object.Parent then
                process(object)
                for _, child in ipairs(object:GetDescendants()) do
                    process(child)
                end
            end
        end)
    end)
end


local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local LOADER_URL = "https://hshqmleifwkvzjrefabj.supabase.co/functions/v1/locopani-loader"
local KEY_FILE = "locopani_key.dat"

local env = _G
if type(getgenv) == "function" then
    local ok, executorEnv = pcall(getgenv)
    if ok and type(executorEnv) == "table" then
        env = executorEnv
    end
end

local function getFunction(name)
    if type(env[name]) == "function" then return env[name] end
    local ok, value = pcall(function() return _G[name] end)
    if ok and type(value) == "function" then return value end
    return nil
end

local requestFn = getFunction("request") or getFunction("http_request")
if not requestFn then
    for _, containerName in ipairs({"syn", "http", "fluxus"}) do
        local container = env[containerName]
        if type(container) == "table" and type(container.request) == "function" then
            requestFn = container.request
            break
        end
    end
end

local function readSavedKey()
    local isfileFn, readfileFn = getFunction("isfile"), getFunction("readfile")
    if not isfileFn or not readfileFn then return nil end
    local ok, exists = pcall(isfileFn, KEY_FILE)
    if not ok or not exists then return nil end
    local okRead, value = pcall(readfileFn, KEY_FILE)
    if not okRead or type(value) ~= "string" then return nil end
    value = string.upper((value:gsub("%s+", "")))
    return value ~= "" and value or nil
end

local function saveKey(key)
    local writefileFn = getFunction("writefile")
    if writefileFn then pcall(writefileFn, KEY_FILE, key) end
end

local function closeWindow(window)
    pcall(function() window:Close() end)
    pcall(function()
        if window.ScreenGui then window.ScreenGui:Destroy() end
    end)
    pcall(function()
        if window.CursorGui then window.CursorGui:Destroy() end
    end)
end

local busy = false
local finished = false
local statusLabel
local keyWindow

local function deliver(key)
    if busy or finished then return end
    busy = true

    if not requestFn then
        if statusLabel and statusLabel.Set then
            statusLabel:Set("Este executor nao oferece suporte HTTP compativel.")
        end
        busy = false
        return
    end

    local body = HttpService:JSONEncode({
        key_code = key,
        roblox_user_id = tostring(player.UserId),
    })

    local ok, response = pcall(function()
        return requestFn({
            Url = LOADER_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body,
        })
    end)

    if not ok or type(response) ~= "table" then
        if statusLabel and statusLabel.Set then
            statusLabel:Set("Nao foi possivel contactar o servidor LOCOPANI.")
        end
        busy = false
        return
    end

    local code = tonumber(response.StatusCode or response.Status or 0) or 0
    local source = response.Body
    if code < 200 or code >= 300 or type(source) ~= "string" or #source < 1000 then
        local message = "Acesso recusado ou erro no servidor (HTTP " .. tostring(code) .. ")."
        local decodedOK, decoded = pcall(function() return HttpService:JSONDecode(tostring(source or "")) end)
        if decodedOK and type(decoded) == "table" then
            message = "Acesso recusado: " .. tostring(decoded.status or decoded.error or "key invalida")
        end
        if statusLabel and statusLabel.Set then statusLabel:Set(message) end
        busy = false
        return
    end

    local compiler = getFunction("loadstring")
    if not compiler then compiler = loadstring end
    if type(compiler) ~= "function" then
        if statusLabel and statusLabel.Set then
            statusLabel:Set("Este executor nao disponibiliza loadstring.")
        end
        busy = false
        return
    end

    local compileOK, chunk = pcall(compiler, source)
    if not compileOK or type(chunk) ~= "function" then
        if statusLabel and statusLabel.Set then
            statusLabel:Set("O source recebido nao passou na compilacao.")
        end
        busy = false
        return
    end

    saveKey(key)
    env.LOCOPANI_BOOTSTRAP_AUTHORIZED = true
    finished = true
    if keyWindow then closeWindow(keyWindow) end

    local runOK, runError = pcall(chunk)
    if not runOK then
        warn("LOCOPANI bootstrap execution error: " .. tostring(runError))
    end
end

-- Primeiro tenta a key salva; o servidor revalida em toda execucao.
local savedKey = readSavedKey()
if savedKey then
    deliver(savedKey)
    if finished then return end
end

-- Mantem a tela de key em estilo Argon/LOCOPANI quando for necessario digitar.
local enteredKey = ""
local argonSource = game:HttpGet("https://raw.githubusercontent.com/JirkaachS/argon-ui/main/argon-ui.luau")
local Argon = loadstring(argonSource)()
keyWindow = Argon:CreateWindow({
    Name = "LOCOPANI KEY SYSTEM",
    Subtitle = "CRISTAL ROXO 777",
    Theme = "Amethyst",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    PlayerList = false,
    KeybindList = false,
    ConfigurationSaving = {Enabled = false},
    GuiName = "LOCOPANIKeyArgonUI",
})
pcall(function() keyWindow:SetSize(Vector2.new(620, 430)) end)
pcall(function() LOCOPANI_AddRainbowAccent(keyWindow) end)
pcall(function() LOCOPANI_AddSiteEffects(keyWindow) end)
pcall(function() LOCOPANI_ApplyInteractivePolish(keyWindow) end)

local keyTab = keyWindow:CreateTab("Key System", "key-round")
keyTab:CreateSection("Acesso ao LOCOPANI")
keyTab:CreateInput({
    Name = "Access key",
    PlaceholderText = "LOCO-XXXX-XXXX",
    CurrentValue = "",
    Callback = function(value)
        enteredKey = tostring(value or "")
    end,
})
keyTab:CreateButton({
    Name = "PEGAR ID ROBLOX",
    Callback = function()
        local userId = tostring(player.UserId)
        local clipboardFn = getFunction("setclipboard") or getFunction("toclipboard")
            or getFunction("set_clipboard")
        local copied = clipboardFn and pcall(clipboardFn, userId)
        if statusLabel and statusLabel.Set then
            statusLabel:Set(copied and ("ID do Roblox copiado: " .. userId)
                or ("Seu ID do Roblox: " .. userId .. " (copie manualmente)"))
        end
    end,
})
statusLabel = keyTab:CreateParagraph({
    Title = "Status",
    Content = "Digite sua key e clique em Validar key.",
})
keyTab:CreateButton({
    Name = "Validar key",
    Callback = function()
        local key = string.upper((enteredKey:gsub("%s+", "")))
        if key == "" then
            statusLabel:Set("Digite sua key de acesso.")
            return
        end
        statusLabel:Set("Validando e buscando LOCOPANI no servidor...")
        deliver(key)
    end,
})
pcall(function() keyWindow:FinishLoading() end)
