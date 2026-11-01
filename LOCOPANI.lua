-- LOCOPANI PRIVATE LOADER
-- O V23 permanece no Storage privado e só e entregue apos validacao no servidor.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local LOADER_URL = "https://hshqmleifwkvzjrefabj.supabase.co/functions/v1/locopani-loader"
local KEY_FILE = "locopani_key.dat"
local ARGON_URL = "https://raw.githubusercontent.com/JirkaachS/argon-ui/main/argon-ui.luau"

local env = _G
if type(getgenv) == "function" then
    local ok, executorEnv = pcall(getgenv)
    if ok and type(executorEnv) == "table" then
        env = executorEnv
    end
end

local function getFunction(name)
    if type(env[name]) == "function" then
        return env[name]
    end
    local ok, value = pcall(function()
        return _G[name]
    end)
    if ok and type(value) == "function" then
        return value
    end
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
    local isfileFn = getFunction("isfile")
    local readfileFn = getFunction("readfile")
    if not isfileFn or not readfileFn then
        return nil
    end
    local ok, exists = pcall(isfileFn, KEY_FILE)
    if not ok or not exists then
        return nil
    end
    local okRead, value = pcall(readfileFn, KEY_FILE)
    if not okRead or type(value) ~= "string" then
        return nil
    end
    value = string.upper((value:gsub("%s+", "")))
    return value ~= "" and value or nil
end

local function saveKey(key)
    local writefileFn = getFunction("writefile")
    if writefileFn then
        pcall(writefileFn, KEY_FILE, key)
    end
end

local statusLabel
local keyWindow

local function setStatus(message)
    if statusLabel and statusLabel.Set then
        pcall(function()
            statusLabel:Set(message)
        end)
    end
end

local function closeWindow()
    if not keyWindow then
        return
    end
    pcall(function()
        keyWindow:Close()
    end)
    pcall(function()
        if keyWindow.ScreenGui then
            keyWindow.ScreenGui:Destroy()
        end
    end)
    pcall(function()
        if keyWindow.CursorGui then
            keyWindow.CursorGui:Destroy()
        end
    end)
end

local busy = false
local finished = false
local enteredKey = ""

local function deliver(key)
    if busy or finished then
        return
    end
    busy = true

    if not requestFn then
        setStatus("Este executor nao oferece suporte HTTP compativel.")
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
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)

    if not ok or type(response) ~= "table" then
        setStatus("Nao foi possivel contactar o servidor LOCOPANI.")
        busy = false
        return
    end

    local code = tonumber(response.StatusCode or response.Status or 0) or 0
    local source = response.Body
    if code < 200 or code >= 300 or type(source) ~= "string" or #source < 1000 then
        local message = "Acesso recusado ou erro no servidor (HTTP " .. tostring(code) .. ")."
        local decodedOK, decoded = pcall(function()
            return HttpService:JSONDecode(tostring(source or ""))
        end)
        if decodedOK and type(decoded) == "table" then
            message = "Acesso recusado: " .. tostring(decoded.status or decoded.error or "key invalida")
        end
        setStatus(message)
        busy = false
        return
    end

    local compiler = getFunction("loadstring") or loadstring
    if type(compiler) ~= "function" then
        setStatus("Este executor nao disponibiliza loadstring.")
        busy = false
        return
    end

    local compileOK, chunk = pcall(compiler, source)
    if not compileOK or type(chunk) ~= "function" then
        setStatus("O source recebido nao passou na compilacao.")
        busy = false
        return
    end

    saveKey(key)
    env.LOCOPANI_BOOTSTRAP_AUTHORIZED = true
    finished = true
    closeWindow()

    local runOK, runError = pcall(chunk)
    if not runOK then
        warn("LOCOPANI bootstrap execution error: " .. tostring(runError))
    end
end

-- Primeiro tenta a key salva; o servidor revalida em toda execucao.
local savedKey = readSavedKey()
if savedKey then
    deliver(savedKey)
    if finished then
        return
    end
end

-- Carrega a interface Argon separadamente para manter este loader menor.
local argonOK, argonSource = pcall(function()
    return game:HttpGet(ARGON_URL)
end)
if not argonOK or type(argonSource) ~= "string" or argonSource == "" then
    warn("LOCOPANI: nao foi possivel baixar a interface de key.")
    return
end

local compiler = getFunction("loadstring") or loadstring
if type(compiler) ~= "function" then
    warn("LOCOPANI: este executor nao disponibiliza loadstring.")
    return
end

local argonCompileOK, argonChunk = pcall(compiler, argonSource)
if not argonCompileOK or type(argonChunk) ~= "function" then
    warn("LOCOPANI: falha ao compilar a interface de key.")
    return
end

local argonRunOK, Argon = pcall(argonChunk)
if not argonRunOK or type(Argon) ~= "table" or type(Argon.CreateWindow) ~= "function" then
    warn("LOCOPANI: a interface Argon nao iniciou corretamente.")
    return
end

keyWindow = Argon:CreateWindow({
    Name = "LOCOPANI KEY SYSTEM",
    Subtitle = "CRISTAL ROXO 777",
    Theme = "Amethyst",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    PlayerList = false,
    KeybindList = false,
    ConfigurationSaving = { Enabled = false },
    GuiName = "LOCOPANIKeyArgonUI",
})

pcall(function()
    keyWindow:SetSize(Vector2.new(620, 430))
end)

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
        local clipboardFn = getFunction("setclipboard")
            or getFunction("toclipboard")
            or getFunction("set_clipboard")
        local copied = clipboardFn and pcall(clipboardFn, userId)
        setStatus(copied and ("ID do Roblox copiado: " .. userId)
            or ("Seu ID do Roblox: " .. userId .. " (copie manualmente)"))
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
            setStatus("Digite sua key de acesso.")
            return
        end
        setStatus("Validando e buscando LOCOPANI no servidor...")
        deliver(key)
    end,
})

pcall(function()
    keyWindow:FinishLoading()
end)
