-- ================================================================
-- KNIFE SILENT AIM STANDALONE v1
-- Untuk Murder Mystery 2
-- ================================================================

-- ================================================================
-- COMPAT SHIM - Fix untuk executor mobile
-- ================================================================
if not task then
    local _osClock = (type(os) == "table" and type(os.clock) == "function") and os.clock or nil
    local _legacyWait = (type(wait) == "function") and wait
        or function(t)
            if _osClock then
                local t0 = _osClock() + math.min(t or 0, 0.5)
                repeat coroutine.yield() until _osClock() >= t0
            else
                coroutine.yield()
            end
        end
    local _legacySpawn = (type(spawn) == "function") and spawn or function(f, ...) local co = coroutine.wrap(f) co(...) end
    task = {
        wait = function(t) return _legacyWait(t or 0) end,
        spawn = function(f, ...) local a = {...}; _legacySpawn(function() f(table.unpack(a)) end) end,
        defer = function(f, ...) local a = {...}; _legacySpawn(function() _legacyWait(0); f(table.unpack(a)) end) end,
        delay = function(t, f, ...) local a = {...}; _legacyDelay(t or 0, function() f(table.unpack(a)) end) end,
    }
end

-- ================================================================
-- GET SERVICE
-- ================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- ================================================================
-- ROLE CACHE
-- ================================================================
local _roleCache = {
    murderer = nil,
    sheriff = nil,
    hero = nil,
    localRole = "Innocent"
}

-- Hook RoundStart
task.spawn(function()
    local ok, rem = pcall(function()
        return ReplicatedStorage:WaitForChild("Remotes", 10)
            :WaitForChild("Gameplay", 10)
            :WaitForChild("RoundStart", 10)
    end)
    if not ok or not rem then return end
    
    rem.OnClientEvent:Connect(function(_, playerData)
        if type(playerData) ~= "table" then return end
        _roleCache.murderer = nil
        _roleCache.sheriff = nil
        _roleCache.hero = nil
        
        for name, info in pairs(playerData) do
            if type(info) == "table" and info.Role then
                local role = tostring(info.Role)
                if name == LocalPlayer.Name then
                    _roleCache.localRole = role
                end
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Name == name then
                        if role == "Murderer" then 
                            _roleCache.murderer = p
                        elseif role == "Sheriff" then 
                            _roleCache.sheriff = p
                        elseif role == "Hero" then 
                            _roleCache.hero = p
                        end
                        break
                    end
                end
            end
        end
    end)
end)

function findMurderer()
    return _roleCache.murderer
end

function findSheriff()
    return _roleCache.sheriff
end

-- ================================================================
-- KNIFE SA STATE
-- ================================================================
local KnifeSAState = {
    enabled = false,
    target = "Closest",
    targetPart = "HumanoidRootPart",
    wallCheck = false,
    prediction = "Dynamic",
    range = 50,
    specificTarget = nil,
    _setupDone = false,
    _charConn = nil,
    _knifeConns = {},
    _lastTargetId = nil,
    _playThrowAnim = nil,
    _playThrowHoldAnim = nil,
    _playThrowKnifeAnim = nil,
    _animTracks = {},
    _lastEquipTime = 0,
    _origCanCollide = {},
    _mobileConns = {},
}

-- VARIABLE UNTUK KEYBIND
local _keybindConnected = false
local _toggleLock = false
local _throwCooldown = 0

-- ================================================================
-- PREDICTION SYSTEM - Riwayat posisi untuk prediksi
-- ================================================================
local _knifeSA_posHistory = {}
local _ksa_head = 1
local _ksa_count = 0
local _ksa_lastUpdate = 0

local _knifeSA_bodyParts = {
    "HumanoidRootPart",
    "UpperTorso",
    "LowerTorso",
    "Head",
    "LeftUpperArm",
    "RightUpperArm",
    "LeftUpperLeg",
    "RightUpperLeg",
}

local function _ksaPush(pos, vel)
    _knifeSA_posHistory[_ksa_head] = { pos = pos, vel = vel, t = os.clock() }
    _ksa_head = (_ksa_head % 90) + 1
    if _ksa_count < 90 then _ksa_count = _ksa_count + 1 end
end

local function _ksaRead(n)
    n = math.min(n or _ksa_count, _ksa_count)
    if n == 0 then return {} end
    local out = {}
    local startIdx = ((_ksa_head - 1 - _ksa_count + ((_ksa_count - n))) % 90) + 1
    for i = 1, n do
        out[i] = _knifeSA_posHistory[((startIdx - 1 + i - 1) % 90) + 1]
    end
    return out
end

-- ================================================================
-- KNIFE SA - GET BEST TARGET
-- ================================================================
function _KnifeSA_getBestTarget()
    local myChar = LocalPlayer.Character
    if not myChar then return nil end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    local cam = Workspace.CurrentCamera
    
    local targetMode = KnifeSAState.target
    
    if targetMode == "Murderer" then
        local murder = findMurderer()
        if murder and murder.Character then
            local hrp = murder.Character:FindFirstChild("HumanoidRootPart")
            local hum = murder.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then 
                return murder
            end
        end
        return nil
        
    elseif targetMode == "Sheriff" then
        local sher = findSheriff()
        if sher and sher.Character then
            local hrp = sher.Character:FindFirstChild("HumanoidRootPart")
            local hum = sher.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then 
                return sher
            end
        end
        return nil
        
    elseif targetMode == "Select Player" then
        local sp = KnifeSAState.specificTarget
        if sp and sp.Parent and sp.Character then
            local hrp = sp.Character:FindFirstChild("HumanoidRootPart")
            local hum = sp.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then 
                return sp
            end
        end
        return nil
        
    elseif targetMode == "All Players" then
        local best, bestDist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < bestDist then 
                        bestDist = d
                        best = p
                    end
                end
            end
        end
        return best
        
    elseif targetMode == "From Mouse" then
        local mousePos = UserInputService:GetMouseLocation()
        local best, bestDist = nil, math.huge
        local fovR = 9999
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local sp, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        if d < bestDist and d <= fovR then 
                            bestDist = d
                            best = p
                        end
                    end
                end
            end
        end
        return best
        
    else
        local best, bestDist = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < bestDist then 
                        bestDist = d
                        best = p
                    end
                end
            end
        end
        return best
    end
end

-- ================================================================
-- WALL CHECK
-- ================================================================
local _wcParams = RaycastParams.new()
_wcParams.FilterType = Enum.RaycastFilterType.Exclude

function wallCheckRaycast(from, to, extraExclude)
    local ignoreList = {LocalPlayer.Character}
    if extraExclude then table.insert(ignoreList, extraExclude) end
    _wcParams.FilterDescendantsInstances = ignoreList
    
    local direction = (to - from)
    local result = Workspace:Raycast(from, direction, _wcParams)
    
    if not result then return true end
    if result.Instance and (result.Instance.Transparency >= 0.95 or not result.Instance.CanCollide) then
        return true
    end
    return false
end

-- ================================================================
-- PREDICTION - Hitung posisi target di masa depan
-- ================================================================
function _KnifeSA_getPredictedPos(targetHRP, targetChar)
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return targetHRP.Position end
    
    local _partFallbacks = {
        Head = Vector3.new(0, 2.5, 0),
        UpperTorso = Vector3.new(0, 1.2, 0),
        LowerTorso = Vector3.new(0, -0.5, 0),
        HumanoidRootPart = Vector3.new(0, 0.0, 0),
        LeftUpperArm = Vector3.new(-1.5, 1.0, 0),
        RightUpperArm = Vector3.new(1.5, 1.0, 0),
        LeftUpperLeg = Vector3.new(-0.6, -1.0, 0),
        RightUpperLeg = Vector3.new(0.6, -1.0, 0),
    }
    
    local selectedPart = KnifeSAState.targetPart
    local basePos
    if selectedPart and selectedPart ~= "HumanoidRootPart" then
        local realPart = targetChar and targetChar:FindFirstChild(selectedPart)
        if realPart and realPart:IsA("BasePart") then
            basePos = realPart.Position
        else
            basePos = targetHRP.Position + (_partFallbacks[selectedPart] or Vector3.new(0, 1.4, 0))
        end
    else
        basePos = targetHRP.Position
    end
    if basePos.Y < 0.3 then basePos = Vector3.new(basePos.X, 0.3, basePos.Z) end
    
    if KnifeSAState.prediction == "None" or not myHRP then return basePos end
    
    local throwOrigin = myHRP.Position + Vector3.new(0, 1.5, 0)
    
    if KnifeSAState.prediction == "Static" then
        local pingMs = 80
        pcall(function() pingMs = math.clamp(LocalPlayer:GetNetworkPing() * 1000, 5, 400) end)
        local ping = (pingMs + 25) / 1000
        local knifeSpeed = 80
        local dist = math.max(0.1, (throwOrigin - basePos).Magnitude)
        local tof = math.clamp(dist / knifeSpeed + ping, 0.01, 4.0)
        local rawVel = targetHRP.AssemblyLinearVelocity or Vector3.new(0,0,0)
        
        local pred = Vector3.new(
            basePos.X + rawVel.X * tof,
            basePos.Y + rawVel.Y * tof,
            basePos.Z + rawVel.Z * tof
        )
        
        pred = Vector3.new(
            pred.X,
            math.clamp(pred.Y, basePos.Y - 2.4, basePos.Y + 3.2),
            pred.Z
        )
        
        local hOff = Vector3.new(pred.X - basePos.X, 0, pred.Z - basePos.Z)
        if hOff.Magnitude > 6 then
            local cl = basePos + Vector3.new(hOff.Unit.X, 0, hOff.Unit.Z) * 6
            pred = Vector3.new(cl.X, pred.Y, cl.Z)
        end
        
        if pred ~= pred then return basePos end
        return pred
    end
    
    local pingMs = 80
    pcall(function() pingMs = math.clamp(LocalPlayer:GetNetworkPing() * 1000, 5, 400) end)
    local pingComp = (pingMs + 22) / 1000
    local knifeSpeed = 80
    local multH = 1.0
    local multV = 1.0
    
    local _ksaBuf = _ksaRead()
    local n = #_ksaBuf
    local rawVel = targetHRP.AssemblyLinearVelocity or Vector3.new(0,0,0)
    
    local vel = rawVel
    if n >= 4 then
        local ema1, ema2, ema3 = rawVel, rawVel, rawVel
        ema1 = _ksaBuf[1].vel
        ema2 = _ksaBuf[1].vel
        ema3 = _ksaBuf[1].vel
        local prevVel = ema1
        
        for i = 2, n do
            local s = _ksaBuf[i]
            local dt = math.max(s.t - (_ksaBuf[i-1] and _ksaBuf[i-1].t or s.t), 0.001)
            
            local accel = (s.vel - prevVel).Magnitude / dt
            local prevAccel = i >= 3 and ((_ksaBuf[i-1].vel - _ksaBuf[i-2].vel).Magnitude / dt) or 0
            local jerk = math.abs(accel - prevAccel)
            
            local alpha = math.clamp(0.20 + accel * 0.012 + jerk * 0.008, 0.18, 0.90)
            ema1 = ema1:Lerp(s.vel, alpha)
            ema2 = ema2:Lerp(ema1, math.clamp(alpha * 0.55, 0.12, 0.65))
            ema3 = ema3:Lerp(ema2, math.clamp(alpha * 0.35, 0.08, 0.45))
            prevVel = s.vel
        end
        vel = rawVel * 0.08 + ema1 * 0.60 + ema2 * 0.32
    elseif n >= 2 then
        local ema = _ksaBuf[1].vel
        for i = 2, n do ema = ema:Lerp(_ksaBuf[i].vel, 0.45) end
        vel = ema:Lerp(rawVel, 0.30)
    end
    
    local velMag = vel.Magnitude
    if velMag > 110 then vel = vel * (110 / velMag) end
    
    local strafeFactor = 1.0
    if n >= 6 then
        local dotSum, dotCount = 0, 0
        for i = math.max(2, n - 5), n do
            local va = Vector3.new(_ksaBuf[i-1].vel.X, 0, _ksaBuf[i-1].vel.Z)
            local vb = Vector3.new(_ksaBuf[i].vel.X, 0, _ksaBuf[i].vel.Z)
            if va.Magnitude > 1.5 and vb.Magnitude > 1.5 then
                dotSum = dotSum + va.Unit:Dot(vb.Unit)
                dotCount = dotCount + 1
            end
        end
        if dotCount > 0 then
            local avgDot = dotSum / dotCount
            local t_sf = math.clamp((avgDot + 1) / 2, 0, 1)
            strafeFactor = 0.50 + 0.50 * (t_sf * t_sf)
        end
    end
    
    local jumpFactor = 1.0
    if n >= 4 then
        local sumY, cnt = 0, math.min(n, 5)
        for i = n - cnt + 1, n do sumY = sumY + _ksaBuf[i].vel.Y end
        local avgVelY = sumY / cnt
        
        local velYTrend = 0
        if n >= 3 then
            velYTrend = (_ksaBuf[n].vel.Y - _ksaBuf[n-2].vel.Y) / 2
        end
        
        if avgVelY > 6 then
            jumpFactor = math.clamp(1.0 + avgVelY * 0.022 + velYTrend * 0.010, 1.0, 1.30)
        elseif avgVelY < -4 then
            jumpFactor = math.clamp(1.0 + avgVelY * 0.022, 0.72, 1.0)
        end
    end
    
    local dist0 = math.max(0.1, (throwOrigin - basePos).Magnitude)
    local tof = math.clamp(dist0 / math.max(1, knifeSpeed) + pingComp, 0.01, 4.0)
    
    local predicted = basePos
    for iter = 1, 32 do
        local dX = vel.X * multH * strafeFactor * tof
        local dZ = vel.Z * multH * strafeFactor * tof
        local dY = vel.Y * multV * jumpFactor * tof
        
        local newPred = Vector3.new(
            basePos.X + dX,
            basePos.Y + dY,
            basePos.Z + dZ
        )
        
        local delta = (newPred - predicted).Magnitude
        predicted = newPred
        if delta < 0.001 then break end
        
        local newDist = math.max(0.1, (throwOrigin - predicted).Magnitude)
        tof = math.clamp(newDist / math.max(1, knifeSpeed) + pingComp, 0.01, 4.0)
    end
    
    local maxYUp = basePos.Y + 3.5
    local maxYDown = basePos.Y - 2.8
    predicted = Vector3.new(
        predicted.X,
        math.clamp(predicted.Y, maxYDown, maxYUp),
        predicted.Z
    )
    
    local hOff = Vector3.new(predicted.X - basePos.X, 0, predicted.Z - basePos.Z)
    if hOff.Magnitude > 6 then
        local clamped = basePos + Vector3.new(hOff.Unit.X, 0, hOff.Unit.Z) * 6
        predicted = Vector3.new(clamped.X, predicted.Y, clamped.Z)
    end
    
    if predicted ~= predicted or predicted.Magnitude ~= predicted.Magnitude then return basePos end
    
    return predicted
end

-- ================================================================
-- HISTORY UPDATER
-- ================================================================
local _histConn = nil
local _histLastUpdate = 0

function _startHistoryUpdater()
    if _histConn then _histConn:Disconnect() end
    _histConn = RunService.Heartbeat:Connect(function()
        if not KnifeSAState.enabled then return end
        
        local now = os.clock()
        if now - _histLastUpdate < 0.04 then return end
        _histLastUpdate = now
        
        local target = _KnifeSA_getBestTarget()
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local tid = target.UserId
                if tid ~= KnifeSAState._lastTargetId then
                    _knifeSA_posHistory = {}
                    _ksa_head = 1
                    _ksa_count = 0
                    KnifeSAState._lastTargetId = tid
                end
                local vel = hrp.AssemblyLinearVelocity or Vector3.new(0,0,0)
                _ksaPush(hrp.Position, vel)
            end
        end
    end)
end

-- ================================================================
-- EQUIP KNIFE
-- ================================================================
function EquipKnife()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return nil end
    
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local n = t.Name:lower()
            if n:find("knife") or n == "knife" then return t end
        end
    end
    
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if n:find("knife") or n == "knife" then
                    pcall(function() hum:EquipTool(t) end)
                    task.wait(0.15)
                    for _, c in ipairs(char:GetChildren()) do
                        if c:IsA("Tool") then
                            local cn = c.Name:lower()
                            if cn:find("knife") or cn == "knife" then return c end
                        end
                    end
                end
            end
        end
    end
    
    return nil
end

-- ================================================================
-- GET ANIMATOR
-- ================================================================
function _getAnimator()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum and hum:FindFirstChildOfClass("Animator")
end

-- ================================================================
-- PLAY ANIMATION
-- ================================================================
function _playKnifeAnim(animName, speed)
    speed = speed or 1.0
    local animator = _getAnimator()
    if not animator then return false end
    
    local char = LocalPlayer.Character
    local knife = char and char:FindFirstChild("Knife")
    if not knife then return false end
    
    local animObj = nil
    local kc = knife:FindFirstChild("KnifeClient")
    
    if kc then
        animObj = kc:FindFirstChild(animName) or kc:FindFirstChild(animName, true)
    end
    if not animObj then
        animObj = knife:FindFirstChild(animName, true)
    end
    if not animObj then return false end
    
    local ok, track = pcall(function() return animator:LoadAnimation(animObj) end)
    if not ok or not track then return false end
    
    track.Priority = Enum.AnimationPriority.Action
    pcall(function()
        if track.IsPlaying then track:Stop(0) end
        track:Play(0.05)
        track:AdjustSpeed(speed)
    end)
    
    return true
end

-- ================================================================
-- FIRE KNIFE
-- ================================================================
function _fireKnife(knife, handleCF, targetCF)
    if not knife then return end
    
    local events = knife:FindFirstChild("Events")
    if not events then return end
    
    local knifeThrown = events:FindFirstChild("KnifeThrown")
    if not knifeThrown then return end
    
    pcall(function() knifeThrown:FireServer(handleCF, targetCF) end)
end

-- ================================================================
-- THROW KNIFE FUNCTION - Untuk dipanggil dari mana saja
-- ================================================================
function ThrowKnifeSA()
    local now = os.clock()
    if now - _throwCooldown < 2 then return end
    _throwCooldown = now
    
    local char = LocalPlayer.Character
    local knife = char and char:FindFirstChild("Knife")
    if not knife then return end
    
    local target = _KnifeSA_getBestTarget()
    if not target or not target.Character then
        return
    end
    
    local tChar = target.Character
    local tHRP = tChar:FindFirstChild("HumanoidRootPart")
    local tHum = tChar:FindFirstChildOfClass("Humanoid")
    if not tHRP or not tHum or tHum.Health <= 0 then return end
    
    local myHRP = char:FindFirstChild("HumanoidRootPart")
    if not myHRP then return end
    
    if KnifeSAState.wallCheck then
        local eyePos = myHRP.Position + Vector3.new(0, 1.5, 0)
        local bodyPos = tHRP.Position + Vector3.new(0, 0.8, 0)
        if not wallCheckRaycast(eyePos, bodyPos, tChar) then
            return
        end
    end
    
    local predictedPos = _KnifeSA_getPredictedPos(tHRP, tChar)
    
    local throwOrigin = myHRP.Position + Vector3.new(0, 1.5, 0)
    if throwOrigin.Y < 0.5 then
        throwOrigin = Vector3.new(throwOrigin.X, 0.5, throwOrigin.Z)
    end
    
    local minY = math.max(0.3, tHRP.Position.Y - 1.5)
    if predictedPos.Y < minY then
        predictedPos = Vector3.new(predictedPos.X, tHRP.Position.Y + 0.5, predictedPos.Z)
    end
    
    local aimVec = predictedPos - throwOrigin
    if aimVec.Magnitude < 0.01 then aimVec = myHRP.CFrame.LookVector end
    local aimDir = aimVec.Unit
    
    local handleCF = CFrame.new(throwOrigin, throwOrigin + aimDir)
    
    local backDir = throwOrigin - predictedPos
    local targetCF = backDir.Magnitude > 0.1
        and CFrame.new(predictedPos, predictedPos + backDir.Unit)
        or CFrame.new(predictedPos)
    
    _fireKnife(knife, handleCF, targetCF)
end

-- ================================================================
-- KNIFE SA - SETUP KNIFE
-- ================================================================
function _KnifeSA_setupKnife(knife)
    if not KnifeSAState.enabled then return end
    
    local events = knife:FindFirstChild("Events")
    if not events then return end
    
    local knifeThrown = events:FindFirstChild("KnifeThrown")
    if not knifeThrown then return end
    
    local kc = knife:FindFirstChild("KnifeClient")
    if kc then kc.Disabled = true end
    
    local handle = knife:FindFirstChild("Handle")
    if handle then
        KnifeSAState._origCanCollide[handle] = handle.CanCollide
        pcall(function() handle.CanCollide = false end)
        for _, part in ipairs(knife:GetDescendants()) do
            if part:IsA("BasePart") then
                KnifeSAState._origCanCollide[part] = part.CanCollide
                pcall(function() part.CanCollide = false end)
            end
        end
    end
    
    local equipped = false
    local lastThrow = -999
    local conns = {}
    
    table.insert(conns, knife.Equipped:Connect(function()
        equipped = true
        if kc then kc.Disabled = true end
        if handle then pcall(function() handle.CanCollide = false end) end
        for _, part in ipairs(knife:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = false end) end
        end
        KnifeSAState._lastEquipTime = os.clock()
    end))
    
    table.insert(conns, knife.Unequipped:Connect(function()
        equipped = false
        for name in pairs(KnifeSAState._animTracks) do
            local t = KnifeSAState._animTracks[name]
            if t and t.IsPlaying then pcall(function() t:Stop(0.08) end) end
        end
    end))
    
    local _hbTknifeNC = 0
    local _knifeSetupId = (knife:GetAttribute("_SA_SetupId") or 0) + 1
    knife:SetAttribute("_SA_SetupId", _knifeSetupId)
    local mySetupId = _knifeSetupId
    
    table.insert(conns, RunService.Heartbeat:Connect(function()
        if not KnifeSAState.enabled then return end
        if knife:GetAttribute("_SA_SetupId") ~= mySetupId then return end
        _hbTknifeNC = _hbTknifeNC + 1
        if _hbTknifeNC < 12 then return end
        _hbTknifeNC = 0
        if not knife or not knife.Parent then return end
        if kc and not kc.Disabled then kc.Disabled = true end
        if not equipped then return end
        if handle and handle.CanCollide then pcall(function() handle.CanCollide = false end) end
    end))
    
    -- THROW (RMB) - Lempar pisau dengan Silent Aim
    table.insert(conns, UserInputService.InputBegan:Connect(function(input, gp)
        if gp or not equipped then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
        if not KnifeSAState.enabled then return end
        
        task.spawn(ThrowKnifeSA)
    end))
    
    for _, c in ipairs(conns) do
        table.insert(KnifeSAState._knifeConns, c)
    end
end

-- ================================================================
-- KNIFE SA - ACTIVATE / DEACTIVATE
-- ================================================================
function _KnifeSA_activate()
    for _, c in ipairs(KnifeSAState._knifeConns) do
        pcall(function() c:Disconnect() end)
    end
    KnifeSAState._knifeConns = {}
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local knife = char:FindFirstChild("Knife")
    if knife then
        task.spawn(function()
            task.wait(0.1)
            _KnifeSA_setupKnife(knife)
        end)
    end
    
    if KnifeSAState._charConn then KnifeSAState._charConn:Disconnect() end
    KnifeSAState._charConn = char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") and child.Name == "Knife" then
            task.wait(0.2)
            _KnifeSA_setupKnife(child)
        end
    end)
    
    _startHistoryUpdater()
end

function _KnifeSA_deactivate()
    KnifeSAState.enabled = false
    
    for _, c in ipairs(KnifeSAState._knifeConns) do
        pcall(function() c:Disconnect() end)
    end
    KnifeSAState._knifeConns = {}
    
    if KnifeSAState._charConn then
        KnifeSAState._charConn:Disconnect()
        KnifeSAState._charConn = nil
    end
    
    if _histConn then
        _histConn:Disconnect()
        _histConn = nil
    end
    
    local char = LocalPlayer.Character
    if char then
        local knife = char:FindFirstChild("Knife")
        if knife then
            local kc = knife:FindFirstChild("KnifeClient")
            if kc then kc.Disabled = false end
            
            local origCC = KnifeSAState._origCanCollide or {}
            local handle = knife:FindFirstChild("Handle")
            if handle then
                pcall(function() handle.CanCollide = (origCC[handle] ~= nil) and origCC[handle] or true end)
            end
            for _, part in ipairs(knife:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = (origCC[part] ~= nil) and origCC[part] or true end)
                end
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            local animr = hum and hum:FindFirstChildOfClass("Animator")
            if animr then
                for _, track in ipairs(animr:GetPlayingAnimationTracks()) do
                    local id = track.Animation and track.Animation.AnimationId or ""
                    if id:find("knife") or id:find("Knife") then
                        pcall(function() track:Stop(0.1) end)
                    end
                end
            end
        end
    end
    
    KnifeSAState._origCanCollide = {}
    _knifeSA_posHistory = {}
    _ksa_head = 1
    _ksa_count = 0
    KnifeSAState._lastTargetId = nil
end

-- ================================================================
-- TOGGLE KNIFE SILENT AIM
-- ================================================================
function ToggleKnifeSA(enabled)
    if _toggleLock then 
        print("[Knife SA] Toggle sedang diproses...")
        return false 
    end
    
    _toggleLock = true
    
    task.spawn(function()
        if enabled then
            local knife = EquipKnife()
            if not knife then
                print("[Knife SA] Tidak ada knife di inventory!")
                KnifeSAState.enabled = false
                _toggleLock = false
                Notify("KNIFE SA", "ERROR: Tidak ada knife!", 2)
                return
            end
            
            _KnifeSA_activate()
            print("[Knife SA] ON")
            Notify("KNIFE SA", "ON - E / Klik Kanan untuk lempar", 2)
            _toggleLock = false
        else
            _KnifeSA_deactivate()
            print("[Knife SA] OFF")
            Notify("KNIFE SA", "OFF", 2)
            _toggleLock = false
        end
    end)
    
    return true
end

-- ================================================================
-- MOBILE SUPPORT
-- ================================================================
local _isMobile = UserInputService.TouchEnabled
if _isMobile then
    task.spawn(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        
        local function findThrowButton(parent, depth)
            if not parent or depth > 8 then return nil end
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("GuiObject") then
                    local n = child.Name:lower()
                    if n:find("throw") or n == "throwig" then
                        return child
                    end
                end
                local found = findThrowButton(child, depth + 1)
                if found then return found end
            end
            return nil
        end
        
        local throwBtn = findThrowButton(pg, 0)
        if throwBtn then
            pcall(function()
                throwBtn.Activated:Connect(function()
                    if not KnifeSAState.enabled then return end
                    ThrowKnifeSA()
                end)
            end)
        end
    end)
end

-- ================================================================
-- KEYBINDS - F untuk Toggle, E untuk Throw
-- ================================================================
if not _keybindConnected then
    _keybindConnected = true
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F then
            task.spawn(function()
                local newState = not KnifeSAState.enabled
                ToggleKnifeSA(newState)
            end)
        end
        
        if input.KeyCode == Enum.KeyCode.E then
            if KnifeSAState.enabled then
                task.spawn(ThrowKnifeSA)
            end
        end
    end)
    
    print("[Knife SA] Keybinds: F = Toggle, E = Throw")
end

-- ================================================================
-- CHARACTER RESPAWN
-- ================================================================
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if KnifeSAState.enabled then
        _KnifeSA_activate()
    end
end)

-- ================================================================
-- NOTIFICATION SYSTEM
-- ================================================================
function Notify(title, msg, duration)
    duration = duration or 3
    local sg = Instance.new("ScreenGui")
    sg.Name = "KNSANotify"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 280, 0, 50)
    frame.Position = UDim2.new(0.5, -140, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 100, 50)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    
    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -10, 0, 22)
    titleLbl.Position = UDim2.new(0, 5, 0, 2)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Color3.fromRGB(255, 100, 50)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local msgLbl = Instance.new("TextLabel", frame)
    msgLbl.Size = UDim2.new(1, -10, 0, 20)
    msgLbl.Position = UDim2.new(0, 5, 0, 26)
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = msg
    msgLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    msgLbl.Font = Enum.Font.Gotham
    msgLbl.TextSize = 11
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        task.wait(0.25)
        sg:Destroy()
    end)
end

-- ================================================================
-- DRAGGABLE STATUS INDICATOR
-- ================================================================
local _statusGui = nil
local _dragging = false
local _dragStart = nil
local _dragStartPos = nil

function CreateStatusIndicator()
    if _statusGui then _statusGui:Destroy() end
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "KSAStatus"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    _statusGui = sg
    
    local frame = Instance.new("Frame", sg)
    frame.Size = UDim2.new(0, 160, 0, 70)
    frame.Position = UDim2.new(0, 10, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 100, 50)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    
    -- DRAG HANDLE (Header)
    local dragHandle = Instance.new("Frame", frame)
    dragHandle.Size = UDim2.new(1, 0, 0, 22)
    dragHandle.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
    dragHandle.BackgroundTransparency = 0.2
    dragHandle.BorderSizePixel = 0
    Instance.new("UICorner", dragHandle).CornerRadius = UDim.new(0, 8)
    
    -- Title di header
    local titleLbl = Instance.new("TextLabel", dragHandle)
    titleLbl.Size = UDim2.new(1, 0, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "☰ KNIFE SA"
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 11
    titleLbl.TextXAlignment = Enum.TextXAlignment.Center
    
    -- Toggle Button
    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0, 140, 0, 30)
    toggleBtn.Position = UDim2.new(0.5, -70, 0, 32)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    toggleBtn.BackgroundTransparency = 0.2
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 14
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
    
    -- Status label kecil
    local statusLbl = Instance.new("TextLabel", frame)
    statusLbl.Size = UDim2.new(1, 0, 0, 14)
    statusLbl.Position = UDim2.new(0, 0, 0, 6)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Status: OFF"
    statusLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextSize = 10
    statusLbl.TextXAlignment = Enum.TextXAlignment.Center
    
    -- Keybind info
    local keyLbl = Instance.new("TextLabel", frame)
    keyLbl.Size = UDim2.new(1, 0, 0, 12)
    keyLbl.Position = UDim2.new(0, 0, 0, 56)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text = "F: Toggle | E: Throw"
    keyLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    keyLbl.Font = Enum.Font.Gotham
    keyLbl.TextSize = 9
    keyLbl.TextXAlignment = Enum.TextXAlignment.Center
    
    -- DRAG FUNCTIONALITY
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            _dragging = true
            _dragStart = input.Position
            _dragStartPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    _dragging = false
                end
            end)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if _dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - _dragStart
            frame.Position = UDim2.new(
                _dragStartPos.X.Scale,
                _dragStartPos.X.Offset + delta.X,
                _dragStartPos.Y.Scale,
                _dragStartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- TOGGLE BUTTON FUNCTION
    toggleBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            local newState = not KnifeSAState.enabled
            ToggleKnifeSA(newState)
        end)
    end)
    
    -- Update loop
    task.spawn(function()
        while sg and sg.Parent do
            task.wait(0.3)
            if KnifeSAState.enabled then
                toggleBtn.Text = "ON"
                toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
                toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 50)
                stroke.Color = Color3.fromRGB(0, 255, 100)
                statusLbl.Text = "Status: ON ✓"
                statusLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
                keyLbl.Text = "F: Toggle | E: Throw"
            else
                toggleBtn.Text = "OFF"
                toggleBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
                toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
                stroke.Color = Color3.fromRGB(255, 100, 50)
                statusLbl.Text = "Status: OFF ✗"
                statusLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
                keyLbl.Text = "F: Toggle | E: Throw"
            end
        end
    end)
end

CreateStatusIndicator()

-- ================================================================
-- INSTRUKSI
-- ================================================================
print("========================================")
print("  KNIFE SILENT AIM STANDALONE v1")
print("========================================")
print("  F = Toggle ON/OFF")
print("  E = Lempar pisau dengan SA")
print("  Klik Kanan = Lempar pisau dengan SA")
print("  UI bisa di-drag")
print("  Bekerja hanya di Murder Mystery 2")
print("========================================")
Notify("KNIFE SA", "F: Toggle | E: Throw | Klik Kanan: Throw", 4)