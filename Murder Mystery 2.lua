local L_1_ = {}

-- Services -------------------------------------------------------------------

local L_2_ = game:GetService("Players")
local L_3_ = game:GetService("ReplicatedStorage")
local L_4_ = game:GetService("RunService")
local L_5_ = game:GetService("UserInputService")
local L_6_ = game:GetService("TweenService")
local L_7_ = game:GetService("Lighting")
local L_8_ = game:GetService("TeleportService")
local L_9_ = game:GetService("HttpService")
local L_10_ = workspace

local L_11_ = L_2_.LocalPlayer
local L_12_ = L_10_.CurrentCamera

local L_13_ = (getgenv and getgenv()) or _G
local L_14_ = L_13_._MM2Flags or {}
L_13_._MM2Flags = L_14_

L_1_.State = L_14_

-- The original receives the Snowy UI object from the outer application.
local L_15_ = nil

local function L_16_func(L_59_arg0, L_60_arg1, L_61_arg2)
	if L_15_ and type(L_15_.Notify) == "function" then
		pcall(function()
			L_15_:Notify(L_61_arg2 or "MM2", L_59_arg0, L_60_arg1 or 3)
		end)
	end
end

function L_1_.setUI(L_62_arg0)
	L_15_ = L_62_arg0
end

-- Player / character helpers -------------------------------------------------

local function L_17_func(L_63_arg0)
	return L_63_arg0 and L_63_arg0.Character or nil
end

local function L_18_func(L_64_arg0)
	local L_65_ = L_17_func(L_64_arg0)
	return L_65_ and L_65_:FindFirstChildWhichIsA("Humanoid") or nil
end

local function L_19_func(L_66_arg0)
	local L_67_ = L_17_func(L_66_arg0)
	return L_67_ and L_67_:FindFirstChild("HumanoidRootPart") or nil
end

local function L_20_func(L_68_arg0, L_69_arg1)
	if not L_68_arg0 then
		return nil
	end
	L_69_arg1 = string.lower(L_69_arg1)
	local L_70_ = {
		L_68_arg0:FindFirstChild("Backpack"),
		L_68_arg0.Character,
	}
	for L_71_forvar0, L_72_forvar1 in ipairs(L_70_) do
		if L_72_forvar1 then
			for L_73_forvar0, L_74_forvar1 in ipairs(L_72_forvar1:GetChildren()) do
				if L_74_forvar1:IsA("Tool") and string.find(string.lower(L_74_forvar1.Name), L_69_arg1) then
					return L_74_forvar1
				end
			end
		end
	end
	return nil
end

local function L_21_func(L_75_arg0)
	if L_20_func(L_75_arg0, "knife") then
		return "Murderer"
	end
	if L_20_func(L_75_arg0, "gun") then
		return "Sheriff"
	end
	return "Innocent"
end

local function L_22_func(L_76_arg0)
	for L_77_forvar0, L_78_forvar1 in ipairs(L_2_:GetPlayers()) do
		if L_78_forvar1 ~= L_11_ and L_21_func(L_78_forvar1) == L_76_arg0 then
			return L_78_forvar1
		end
	end
	return nil
end

local function L_23_func(L_79_arg0, L_80_arg1)
	local L_81_ = L_19_func(L_79_arg0)
	local L_82_ = L_19_func(L_80_arg1)
	if not L_81_ or not L_82_ then
		return nil
	end
	return (L_81_.Position - L_82_.Position).Magnitude
end

local function L_24_func(L_83_arg0)
	local L_84_ = L_19_func(L_11_)
	if not L_84_ then
		return false
	end
	return pcall(function()
		L_84_.CFrame = L_83_arg0
	end)
end

local function L_25_func(L_85_arg0, L_86_arg1)
	local L_87_ = L_19_func(L_85_arg0)
	local L_88_ = L_19_func(L_11_)
	if not L_87_ or not L_88_ then
		return false
	end
	L_86_arg1 = L_86_arg1 or CFrame.new(0, 0, -3)
	return pcall(function()
		L_88_.CFrame = L_87_.CFrame * L_86_arg1
	end)
end

L_1_.getCharacter = L_17_func
L_1_.getHumanoid = L_18_func
L_1_.getRoot = L_19_func
L_1_.findTool = L_20_func
L_1_.classifyRole = L_21_func
L_1_.findPlayerByRole = L_22_func
L_1_.distanceBetweenPlayers = L_23_func

-- Round information ----------------------------------------------------------

function L_1_.updateRoleLabels(L_89_arg0, L_90_arg1, L_91_arg2)
	local L_92_ = L_22_func("Murderer")
	local L_93_ = L_22_func("Sheriff")
	L_89_arg0:Set("Your Role: " .. L_21_func(L_11_))
	L_90_arg1:Set("Murderer: " .. (L_92_ and L_92_.Name or "Unknown / Innocent turn"))
	L_91_arg2:Set("Sheriff: " .. (L_93_ and L_93_.Name or "Unknown / Innocent turn"))
end

function L_1_.startRoleLabelLoop(L_94_arg0, L_95_arg1, L_96_arg2)
	task.spawn(function()
		while true do
			pcall(L_1_.updateRoleLabels, L_94_arg0, L_95_arg1, L_96_arg2)
			task.wait(0.5)
		end
	end)
end

function L_1_.copyMurdererName()
	local L_97_ = L_22_func("Murderer")
	if not L_97_ then
		L_16_func("No murderer found")
		return
	end
	if type(setclipboard) == "function" then
		pcall(setclipboard, L_97_.Name)
	end
	L_16_func("Copied: " .. L_97_.Name)
end

-- Combat: Murderer -----------------------------------------------------------

function L_1_.killAuraTick()
	local L_98_ = L_20_func(L_11_, "knife")
	local L_99_ = L_19_func(L_11_)
	if not L_98_ or not L_99_ then
		return
	end
	local L_100_ = L_11_.Character
	if L_98_.Parent ~= L_100_ then
		local L_101_ = L_18_func(L_11_)
		if L_101_ then
			L_101_:EquipTool(L_98_)
		end
	end
	for L_102_forvar0, L_103_forvar1 in ipairs(L_2_:GetPlayers()) do
		if L_103_forvar1 ~= L_11_ then
			local L_104_ = L_19_func(L_103_forvar1)
			local L_105_ = L_18_func(L_103_forvar1)
			if L_104_ and L_105_ and L_105_.Health > 0 then
				local L_106_ = (L_104_.Position - L_99_.Position).Magnitude

                -- The recovered implementation uses 12 studs even though the UI
                -- description says 10 studs.
				if L_106_ <= 12 then
					local L_107_ = L_99_.CFrame
					pcall(function()
						L_99_.CFrame = L_104_.CFrame
					end)
					task.wait()
					pcall(function()
						L_98_:Activate()
					end)
					task.wait(0.05)
					pcall(function()
						L_99_.CFrame = L_107_
					end)
				end
			end
		end
	end
end

local function L_26_func()
	while L_14_.KillAura do
		pcall(L_1_.killAuraTick)
		task.wait(0.15)
	end
end

function L_1_.setKillAura(L_108_arg0)
	L_14_.KillAura = L_108_arg0
	if L_108_arg0 then
		task.spawn(L_26_func)
	end
end

-- Combat: Sheriff ------------------------------------------------------------

function L_1_.shootMurderer()
	local L_109_ = L_20_func(L_11_, "gun")
	if not L_109_ then
		L_16_func("You don't have a gun")
		return
	end
	local L_110_ = L_22_func("Murderer")
	if not L_110_ or not L_110_.Character then
		L_16_func("No murderer")
		return
	end
	local L_111_ = L_19_func(L_110_)
	local L_112_ = L_19_func(L_11_)
	if not L_111_ or not L_112_ then
		return
	end
	local L_113_ = L_112_.CFrame
	if L_109_.Parent ~= L_11_.Character then
		local L_114_ = L_18_func(L_11_)
		if L_114_ then
			L_114_:EquipTool(L_109_)
		end
	end
	task.wait(0.1)
	pcall(function()
		L_112_.CFrame = L_111_.CFrame * CFrame.new(0, 0, -3)
	end)
	task.wait(0.05)
	pcall(function()
		L_109_:Activate()
	end)
	task.wait(0.15)
	pcall(function()
		L_112_.CFrame = L_113_
	end)
end

function L_1_.shootMurdererOnce()
	local L_115_ = L_20_func(L_11_, "gun")
	local L_116_ = L_22_func("Murderer")
	local L_117_ = L_116_ and L_19_func(L_116_)
	if not L_115_ or not L_117_ then
		return
	end
	if L_115_.Parent ~= L_11_.Character then
		local L_118_ = L_18_func(L_11_)
		if L_118_ then
			L_118_:EquipTool(L_115_)
		end
	end
	pcall(function()
		L_12_ = L_10_.CurrentCamera
		L_12_.CFrame = CFrame.new(L_12_.CFrame.Position, L_117_.Position)
	end)
	pcall(function()
		L_115_:Activate()
	end)
end

local function L_27_func()
	while L_14_.AutoShoot do
		pcall(L_1_.shootMurdererOnce)
		task.wait(0.25)
	end
end

function L_1_.setAutoShoot(L_119_arg0)
	L_14_.AutoShoot = L_119_arg0
	if L_119_arg0 then
		task.spawn(L_27_func)
	end
end

-- Silent aim -----------------------------------------------------------------

local function L_28_func()
	if L_14_._origNC and type(hookmetamethod) == "function" then
		hookmetamethod(game, "__namecall", L_14_._origNC)
	end
end

local function L_29_func(L_120_arg0, ...)
	local L_121_ = type(getnamecallmethod) == "function" and getnamecallmethod() or nil
	if L_14_.SilentAim and (
        L_121_ == "FindPartOnRay"
        or L_121_ == "FindPartOnRayWithIgnoreList"
        or L_121_ == "Raycast"
    ) then
		local L_122_ = L_22_func("Murderer")
		local L_123_ = L_122_ and L_19_func(L_122_)
		if L_123_ then
			return L_123_, L_123_.Position, Vector3.new(0, 1, 0), Enum.Material.Plastic
		end
	end
	return L_14_._origNC(L_120_arg0, ...)
end

function L_1_.installSilentAimHook()
	if type(hookmetamethod) ~= "function" then
		L_16_func("Silent Aim needs hookmetamethod")
		return false
	end
	local L_124_ = getrawmetatable(game)
	local L_125_ = L_124_.__namecall
	if type(setreadonly) == "function" then
		setreadonly(L_124_, false)
	end
	L_14_._origNC = L_125_
	L_124_.__namecall = type(newcclosure) == "function" and newcclosure(L_29_func) or L_29_func
	if type(setreadonly) == "function" then
		setreadonly(L_124_, true)
	end
	L_14_._silentHook = true
	return true
end

function L_1_.setSilentAim(L_126_arg0)
	L_14_.SilentAim = L_126_arg0
	if L_126_arg0 then
		if not L_14_._silentHook then
			pcall(L_1_.installSilentAimHook)
		end
	else
		if L_14_._silentHook then
			pcall(L_28_func)
			L_14_._silentHook = nil
		end
	end
end

-- Dropped gun / knife --------------------------------------------------------

local function L_30_func(L_127_arg0)
	L_127_arg0 = string.lower(L_127_arg0)
	for L_128_forvar0, L_129_forvar1 in ipairs(L_10_:GetChildren()) do
		if L_129_forvar1:IsA("Tool") and string.find(string.lower(L_129_forvar1.Name), L_127_arg0) then
			local L_130_ = L_129_forvar1:FindFirstChild("Handle")
			if L_130_ then
				return L_129_forvar1, L_130_
			end
		end
	end
	return nil, nil
end

local function L_31_func(L_131_arg0)
	local L_132_, L_133_ = L_30_func(L_131_arg0)
	local L_134_ = L_19_func(L_11_)
	if not L_133_ or not L_134_ then
		return false
	end
	return pcall(function()
		L_134_.CFrame = L_133_.CFrame
	end)
end

function L_1_.teleportToDroppedGun()
	if L_31_func("gun") then
		L_16_func("Teleported to gun")
	else
		L_16_func("No dropped gun found")
	end
end

local function L_32_func()
	while L_14_.AutoGrabGun do
		pcall(L_31_func, "gun")
		task.wait(0.5)
	end
end

function L_1_.setAutoGrabGun(L_135_arg0)
	L_14_.AutoGrabGun = L_135_arg0
	if L_135_arg0 then
		task.spawn(L_32_func)
	end
end

local function L_33_func()
	while L_14_.AutoGrabKnife do
		pcall(L_31_func, "knife")
		task.wait(0.5)
	end
end

function L_1_.setAutoGrabKnife(L_136_arg0)
	L_14_.AutoGrabKnife = L_136_arg0
	if L_136_arg0 then
		task.spawn(L_33_func)
	end
end

-- Basic movement -------------------------------------------------------------

function L_1_.setWalkSpeed(L_137_arg0)
	L_13_.MM2Walk = L_137_arg0
	local L_138_ = L_18_func(L_11_)
	if L_138_ then
		L_138_.WalkSpeed = L_137_arg0
	end
end

function L_1_.setJumpPower(L_139_arg0)
	L_13_.MM2Jump = L_139_arg0
	local L_140_ = L_18_func(L_11_)
	if L_140_ then
		L_140_.UseJumpPower = true
		L_140_.JumpPower = L_139_arg0
	end
end

function L_1_.reapplyMovement(L_141_arg0)
	task.wait(0.5)
	local L_142_ = L_141_arg0 and L_141_arg0:FindFirstChildWhichIsA("Humanoid")
	if not L_142_ then
		return
	end
	if L_13_.MM2Walk then
		L_142_.WalkSpeed = L_13_.MM2Walk
	end
	if L_13_.MM2Jump then
		L_142_.UseJumpPower = true
		L_142_.JumpPower = L_13_.MM2Jump
	end
end

local function L_34_func()
	local L_143_ = L_18_func(L_11_)
	if L_143_ then
		L_143_:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end

function L_1_.setInfiniteJump(L_144_arg0)
	L_14_.InfJump = L_144_arg0
	if L_14_._infJumpConn then
		L_14_._infJumpConn:Disconnect()
		L_14_._infJumpConn = nil
	end
	if L_144_arg0 then
		L_14_._infJumpConn = L_5_.JumpRequest:Connect(L_34_func)
	end
end

local function L_35_func()
	local L_145_ = L_11_.Character
	if not L_145_ then
		return
	end
	for L_146_forvar0, L_147_forvar1 in ipairs(L_145_:GetDescendants()) do
		if L_147_forvar1:IsA("BasePart") then
			L_147_forvar1.CanCollide = false
		end
	end
end

function L_1_.setNoClip(L_148_arg0)
	L_14_.NoClip = L_148_arg0
	if L_14_._noClipConn then
		L_14_._noClipConn:Disconnect()
		L_14_._noClipConn = nil
	end
	if L_148_arg0 then
		L_14_._noClipConn = L_4_.Stepped:Connect(L_35_func)
	end
end

-- Basic free-camera-style fly (first Movement section) -----------------------

function L_1_.setBasicFlySpeed(L_149_arg0)
	L_13_.MM2FlySpeed = L_149_arg0
end

local function L_36_func()
	if L_14_._flyBV then
		L_14_._flyBV:Destroy()
		L_14_._flyBV = nil
	end
	if L_14_._flyBG then
		L_14_._flyBG:Destroy()
		L_14_._flyBG = nil
	end
end

local function L_37_func()
	while L_14_.Fly do
		local L_150_ = L_19_func(L_11_)
		if not L_150_ then
			L_4_.Heartbeat:Wait()
		else
			if not L_14_._flyBV or L_14_._flyBV.Parent ~= L_150_ then
				L_36_func()
				local L_152_ = Instance.new("BodyVelocity", L_150_)
				L_152_.MaxForce = Vector3.new(1000000, 1000000, 1000000)
				L_152_.Velocity = Vector3.new(0, 0, 0)
				local L_153_ = Instance.new("BodyGyro", L_150_)
				L_153_.MaxTorque = Vector3.new(1000000, 1000000, 1000000)
				L_153_.P = 10000
				L_153_.D = 500
				L_14_._flyBV = L_152_
				L_14_._flyBG = L_153_
			end
			L_12_ = L_10_.CurrentCamera
			local L_151_ = Vector3.new(0, 0, 0)
			if L_5_:IsKeyDown(Enum.KeyCode.W) then
				L_151_ = L_151_ + L_12_.CFrame.LookVector
			end
			if L_5_:IsKeyDown(Enum.KeyCode.S) then
				L_151_ = L_151_ - L_12_.CFrame.LookVector
			end
			if L_5_:IsKeyDown(Enum.KeyCode.A) then
				L_151_ = L_151_ - L_12_.CFrame.RightVector
			end
			if L_5_:IsKeyDown(Enum.KeyCode.D) then
				L_151_ = L_151_ + L_12_.CFrame.RightVector
			end
			if L_5_:IsKeyDown(Enum.KeyCode.Space) then
				L_151_ = L_151_ + Vector3.new(0, 1, 0)
			end
			if L_5_:IsKeyDown(Enum.KeyCode.LeftControl) then
				L_151_ = L_151_ - Vector3.new(0, 1, 0)
			end
			L_14_._flyBV.Velocity = L_151_ * (L_13_.MM2FlySpeed or 80)
			L_14_._flyBG.CFrame = L_12_.CFrame
			L_4_.Heartbeat:Wait()
		end
	end
end

function L_1_.setBasicFly(L_154_arg0)
	L_14_.Fly = L_154_arg0
	L_36_func()
	if L_154_arg0 then
		task.spawn(L_37_func)
	end
end

-- Teleports / saved position -------------------------------------------------

function L_1_.teleportToMurderer()
	local L_155_ = L_22_func("Murderer")
	if not L_155_ then
		L_16_func("No murderer")
		return
	end
	L_25_func(L_155_, CFrame.new(0, 0, -3))
end

function L_1_.teleportToSheriff()
	local L_156_ = L_22_func("Sheriff")
	if not L_156_ then
		L_16_func("No sheriff")
		return
	end
	L_25_func(L_156_, CFrame.new(0, 0, -3))
end

function L_1_.savePosition()
	local L_157_ = L_19_func(L_11_)
	if not L_157_ then
		return
	end
	L_13_.MM2SavedCF = L_157_.CFrame
	L_16_func("Position saved")
end

function L_1_.loadPosition()
	local L_158_ = L_19_func(L_11_)
	local L_159_ = L_13_.MM2SavedCF
	if not L_158_ or not L_159_ then
		L_16_func("No saved position")
		return
	end
	L_158_.CFrame = L_159_
end

-- Coins ----------------------------------------------------------------------

function L_1_.findCoins()
	local L_160_ = {}
	for L_161_forvar0, L_162_forvar1 in ipairs(L_10_:GetDescendants()) do
		if L_162_forvar1:IsA("BasePart") and string.find(string.lower(L_162_forvar1.Name), "coin") then
			L_160_[#L_160_ + 1] = L_162_forvar1
		end
	end
	return L_160_
end

function L_1_.collectAllCoins()
	local L_163_ = L_19_func(L_11_)
	if not L_163_ then
		return
	end
	local L_164_ = L_163_.CFrame
	local L_165_ = L_1_.findCoins()
	L_16_func("Collecting " .. tostring(#L_165_) .. " coins...", 2)
	for L_166_forvar0, L_167_forvar1 in ipairs(L_165_) do
		if L_167_forvar1.Parent then
			pcall(function()
				L_163_.CFrame = L_167_forvar1.CFrame
			end)
			task.wait(0.08)
		end
	end
	pcall(function()
		L_163_.CFrame = L_164_
	end)
	L_16_func("Coin sweep complete", 2)
end

local function L_38_func()
	while L_14_.AutoCoin do
		local L_168_ = L_19_func(L_11_)
		if L_168_ then
			for L_169_forvar0, L_170_forvar1 in ipairs(L_1_.findCoins()) do
				if not L_14_.AutoCoin then
					break
				end
				if L_170_forvar1.Parent then
					pcall(function()
						L_168_.CFrame = L_170_forvar1.CFrame
					end)
				end
				task.wait(0.06)
			end
		end
		task.wait(1)
	end
end

function L_1_.setAutoCoin(L_171_arg0)
	L_14_.AutoCoin = L_171_arg0
	if L_171_arg0 then
		task.spawn(L_38_func)
	end
end

function L_1_.teleportToNearestCoin()
	local L_172_ = L_19_func(L_11_)
	if not L_172_ then
		return
	end
	local L_173_ = nil
	local L_174_ = nil
	for L_175_forvar0, L_176_forvar1 in ipairs(L_1_.findCoins()) do
		local L_177_ = (L_176_forvar1.Position - L_172_.Position).Magnitude
		if L_174_ == nil or L_177_ < L_174_ then
			L_173_ = L_176_forvar1
			L_174_ = L_177_
		end
	end
	if L_173_ then
		pcall(function()
			L_172_.CFrame = L_173_.CFrame
		end)
	else
		L_16_func("No coins found", 2)
	end
end

-- Detailed role ESP ----------------------------------------------------------

local L_39_ = {
	Murderer = Color3.fromRGB(255, 60, 60),
	Sheriff = Color3.fromRGB(60, 160, 255),
	Innocent = Color3.fromRGB(90, 220, 120),
}

local function L_40_func(L_178_arg0, L_179_arg1)
	local L_180_ = L_178_arg0 and L_178_arg0:FindFirstChild(L_179_arg1)
	if L_180_ then
		L_180_:Destroy()
	end
end

function L_1_.clearRoleESP()
	for L_181_forvar0, L_182_forvar1 in ipairs(L_2_:GetPlayers()) do
		local L_183_ = L_182_forvar1.Character
		if L_183_ then
			L_40_func(L_183_, "MM2ESP_Hl")
			L_40_func(L_183_, "MM2ESP_Name")
		end
	end
end

function L_1_.updateRoleESP()
	local L_184_ = L_19_func(L_11_)
	for L_185_forvar0, L_186_forvar1 in ipairs(L_2_:GetPlayers()) do
		if L_186_forvar1 ~= L_11_ and L_186_forvar1.Character then
			local L_187_ = L_186_forvar1.Character
			local L_188_ = L_21_func(L_186_forvar1)
			local L_189_ =
                (L_188_ == "Murderer" and L_14_.ESPMurd)
                or (L_188_ == "Sheriff" and L_14_.ESPSher)
                or (L_188_ == "Innocent" and L_14_.ESPInno)
			if L_189_ then
				local L_190_ = L_39_[L_188_]
				local L_191_ = L_187_:FindFirstChild("MM2ESP_Hl")
				if not L_191_ then
					L_191_ = Instance.new("Highlight")
					L_191_.Name = "MM2ESP_Hl"
					L_191_.FillTransparency = 0.65
					L_191_.OutlineTransparency = 0
					L_191_.Parent = L_187_
				end
				L_191_.FillColor = L_190_
				L_191_.OutlineColor = L_190_
				local L_192_ = L_187_:FindFirstChild("Head")
				if L_192_ then
					local L_193_ = L_187_:FindFirstChild("MM2ESP_Name")
					if not L_193_ then
						L_193_ = Instance.new("BillboardGui")
						L_193_.Name = "MM2ESP_Name"
						L_193_.Size = UDim2.new(0, 180, 0, 40)
						L_193_.StudsOffset = Vector3.new(0, 2.5, 0)
						L_193_.AlwaysOnTop = true
						L_193_.Adornee = L_192_
						L_193_.Parent = L_187_
					end
					local L_194_ = L_193_:FindFirstChildWhichIsA("TextLabel")
					if not L_194_ then
						L_194_ = Instance.new("TextLabel")
						L_194_.BackgroundTransparency = 1
						L_194_.Size = UDim2.new(1, 0, 1, 0)
						L_194_.Font = Enum.Font.GothamBlack
						L_194_.TextSize = 13
						L_194_.TextStrokeTransparency = 0
						L_194_.Parent = L_193_
					end
					local L_195_ = L_19_func(L_186_forvar1)
					local L_196_ = nil
					if L_195_ and L_184_ then
						L_196_ = (L_195_.Position - L_184_.Position).Magnitude
					end
					local L_197_ = L_196_ and string.format(" [%dm]", math.floor(L_196_)) or ""
					L_194_.Text = string.format("[%s] %s%s", L_188_, L_186_forvar1.Name, L_197_)
					L_194_.TextColor3 = L_190_
				end
			else
				L_40_func(L_187_, "MM2ESP_Hl")
				L_40_func(L_187_, "MM2ESP_Name")
			end
		end
	end
end

local function L_41_func()
	while L_14_.ESPMurd or L_14_.ESPSher or L_14_.ESPInno do
		pcall(L_1_.updateRoleESP)
		task.wait(0.5)
	end
	L_1_.clearRoleESP()
	L_14_._espLoopRunning = false
end

local function L_42_func()
	if not L_14_._espLoopRunning then
		L_14_._espLoopRunning = true
		task.spawn(L_41_func)
	end
end

function L_1_.setMurdererESP(L_198_arg0)
	L_14_.ESPMurd = L_198_arg0
	if L_198_arg0 then
		L_42_func()
	end
end

function L_1_.setSheriffESP(L_199_arg0)
	L_14_.ESPSher = L_199_arg0
	if L_199_arg0 then
		L_42_func()
	end
end

function L_1_.setInnocentESP(L_200_arg0)
	L_14_.ESPInno = L_200_arg0
	if L_200_arg0 then
		L_42_func()
	end
end

-- Dropped tool / coin ESP ----------------------------------------------------

local function L_43_func(L_201_arg0, L_202_arg1)
	if L_201_arg0:FindFirstChild("MM2ESP_Hl") then
		return
	end
	local L_203_ = Instance.new("Highlight", L_201_arg0)
	L_203_.Name = "MM2ESP_Hl"
	L_203_.FillColor = L_202_arg1
	L_203_.OutlineColor = Color3.fromRGB(255, 255, 255)
	return L_203_
end

function L_1_.updateGunESP()
	for L_204_forvar0, L_205_forvar1 in ipairs(L_10_:GetChildren()) do
		if L_205_forvar1:IsA("Tool") and string.find(string.lower(L_205_forvar1.Name), "gun") then
			L_43_func(L_205_forvar1, Color3.fromRGB(100, 200, 255))
		end
	end
end

function L_1_.updateKnifeESP()
	for L_206_forvar0, L_207_forvar1 in ipairs(L_10_:GetChildren()) do
		if L_207_forvar1:IsA("Tool") and string.find(string.lower(L_207_forvar1.Name), "knife") then
			L_43_func(L_207_forvar1, Color3.fromRGB(255, 60, 60))
		end
	end
end

function L_1_.updateCoinESP()
	for L_208_forvar0, L_209_forvar1 in ipairs(L_1_.findCoins()) do
		local L_210_ = L_43_func(L_209_forvar1, Color3.fromRGB(255, 215, 0))
		if L_210_ then
			L_210_.FillTransparency = 0.5
		end
	end
end

local function L_44_func(L_211_arg0)
	L_211_arg0 = string.lower(L_211_arg0)
	for L_212_forvar0, L_213_forvar1 in ipairs(L_10_:GetDescendants()) do
		if string.find(string.lower(L_213_forvar1.Name), L_211_arg0) then
			L_40_func(L_213_forvar1, "MM2ESP_Hl")
		end
	end
end

function L_1_.setGunESP(L_214_arg0)
	L_14_.ESPGun = L_214_arg0
	if L_214_arg0 then
		task.spawn(function()
			while L_14_.ESPGun do
				pcall(L_1_.updateGunESP)
				task.wait(1)
			end
		end)
	else
		L_44_func("gun")
	end
end

function L_1_.setKnifeESP(L_215_arg0)
	L_14_.ESPKnife = L_215_arg0
	if L_215_arg0 then
		task.spawn(function()
			while L_14_.ESPKnife do
				pcall(L_1_.updateKnifeESP)
				task.wait(1)
			end
		end)
	else
		L_44_func("knife")
	end
end

function L_1_.setCoinESP(L_216_arg0)
	L_14_.ESPCoin = L_216_arg0
	if L_216_arg0 then
		task.spawn(function()
			while L_14_.ESPCoin do
				pcall(L_1_.updateCoinESP)
				task.wait(2)
			end
		end)
	else
		L_44_func("coin")
	end
end

-- Visuals --------------------------------------------------------------------

function L_1_.setFullbright(L_217_arg0)
	L_14_.Fullbright = L_217_arg0
	if L_217_arg0 then
		L_14_._oldAmbient = L_7_.Ambient
		L_14_._oldBrightness = L_7_.Brightness
		L_14_._oldOutdoorAmbient = L_7_.OutdoorAmbient
		L_7_.Ambient = Color3.new(1, 1, 1)
		L_7_.Brightness = 2
		L_7_.OutdoorAmbient = Color3.new(1, 1, 1)
	else
		if L_14_._oldAmbient then
			L_7_.Ambient = L_14_._oldAmbient
		end
		if L_14_._oldBrightness then
			L_7_.Brightness = L_14_._oldBrightness
		end
		if L_14_._oldOutdoorAmbient then
			L_7_.OutdoorAmbient = L_14_._oldOutdoorAmbient
		end
	end
end

function L_1_.setNoFog(L_218_arg0)
	L_14_.NoFog = L_218_arg0
	if L_218_arg0 then
		L_14_._oldFogEnd = L_7_.FogEnd
		L_7_.FogEnd = 1000000
	elseif L_14_._oldFogEnd then
		L_7_.FogEnd = L_14_._oldFogEnd
	end
end

function L_1_.setFOV(L_219_arg0)
	L_13_.MM2FOV = L_219_arg0
	pcall(function()
		L_10_.CurrentCamera.FieldOfView = L_219_arg0
	end)
end

function L_1_.setHideOwnName(L_220_arg0)
	L_14_.HideName = L_220_arg0
	local L_221_ = L_11_.Character
	local L_222_ = L_221_ and L_221_:FindFirstChild("Head")
	if not L_222_ then
		return
	end
	for L_223_forvar0, L_224_forvar1 in ipairs(L_222_:GetChildren()) do
		if L_224_forvar1:IsA("BillboardGui") then
			L_224_forvar1.Enabled = not L_220_arg0
		end
	end
end

-- Anti-AFK / anti-slip / anti-fling ----------------------------------------

local function L_45_func()
	local L_225_ = game:GetService("VirtualUser")
	L_225_:CaptureController()
	L_225_:ClickButton2(Vector2.new())
end

function L_1_.setAntiAFK(L_226_arg0)
	L_14_.AntiAFK = L_226_arg0
	if L_14_._afkConn then
		L_14_._afkConn:Disconnect()
		L_14_._afkConn = nil
	end
	if L_226_arg0 then
		L_14_._afkConn = L_11_.Idled:Connect(function()
			pcall(L_45_func)
		end)
	end
end

local function L_46_func()
	local L_227_ = L_19_func(L_11_)
	local L_228_ = L_18_func(L_11_)
	if not L_227_ or not L_228_ then
		return
	end
	if L_228_.MoveDirection.Magnitude < 0.1 then
		local L_229_ = L_227_.AssemblyLinearVelocity
		L_227_.AssemblyLinearVelocity = Vector3.new(0, L_229_.Y, 0)
	end
end

function L_1_.setAntiSlip(L_230_arg0)
	L_14_.AntiSlip = L_230_arg0
	if L_230_arg0 then
		task.spawn(function()
			while L_14_.AntiSlip do
				pcall(L_46_func)
				task.wait(0.1)
			end
		end)
	end
end

local function L_47_func()
	local L_231_ = L_19_func(L_11_)
	if not L_231_ then
		return
	end
	local L_232_ = L_231_.AssemblyLinearVelocity.Magnitude
	if L_231_.Position.Y > -100 and L_232_ < 250 then
		L_14_._safeCFrame = L_231_.CFrame
		return
	end
	if L_14_._safeCFrame then
		L_231_.CFrame = L_14_._safeCFrame
		L_231_.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	end
end

function L_1_.setAntiFling(L_233_arg0)
	L_14_.AntiFling = L_233_arg0
	if L_233_arg0 then
		task.spawn(function()
			while L_14_.AntiFling do
				pcall(L_47_func)
				task.wait(0.2)
			end
		end)
	end
end

-- Server utilities -----------------------------------------------------------

function L_1_.rejoinServer()
	pcall(function()
		L_8_:Teleport(game.PlaceId, L_11_)
	end)
end

function L_1_.serverHop()
	pcall(function()
		local L_234_, L_235_ = pcall(function()
			return game:HttpGet(
                "https://games.roblox.com/v1/games/"
                .. tostring(game.PlaceId)
                .. "/servers/Public?sortOrder=Asc&limit=100"
            )
		end)
		if not L_234_ or not L_235_ then
			L_16_func("Server list failed", 3)
			return
		end
		local L_236_ = L_9_:JSONDecode(L_235_)
		for L_237_forvar0, L_238_forvar1 in ipairs(L_236_.data or {}) do
			if L_238_forvar1.playing and L_238_forvar1.maxPlayers
                and L_238_forvar1.playing < L_238_forvar1.maxPlayers
                and L_238_forvar1.id ~= game.JobId
            then
				pcall(function()
					L_8_:TeleportToPlaceInstance(game.PlaceId, L_238_forvar1.id, L_11_)
				end)
				return
			end
		end
		L_16_func("No joinable servers", 3)
	end)
end

-- Simple role ESP used by the second MM2 panel ------------------------------

local L_48_ = {
	Murderer = {
		fill = Color3.fromRGB(255, 50, 50),
		outline = Color3.fromRGB(200, 0, 0),
	},
	Sheriff = {
		fill = Color3.fromRGB(50, 100, 255),
		outline = Color3.fromRGB(0, 50, 200),
	},
	Innocent = {
		fill = Color3.fromRGB(50, 220, 80),
		outline = Color3.fromRGB(0, 180, 50),
	},
}

function L_1_.updateSimpleRoleESP()
	for L_239_forvar0, L_240_forvar1 in pairs(L_2_:GetPlayers()) do
		if L_240_forvar1 ~= L_11_ and L_240_forvar1.Character then
			local L_241_ = L_21_func(L_240_forvar1)
			local L_242_ = L_48_[L_241_]
			local L_243_ = L_240_forvar1.Character
			local L_244_ = L_243_:FindFirstChild("MM2_SnowyESP")
			if not L_244_ then
				L_244_ = Instance.new("Highlight")
				L_244_.Name = "MM2_SnowyESP"
				L_244_.FillTransparency = 0.5
				L_244_.OutlineTransparency = 0.2
				L_244_.Parent = L_243_
			end
			L_244_.FillColor = L_242_.fill
			L_244_.OutlineColor = L_242_.outline
		end
	end
end

function L_1_.clearSimpleRoleESP(L_245_arg0)
	local L_246_ = L_245_arg0 and L_245_arg0.Character
	if L_246_ then
		L_40_func(L_246_, "MM2_SnowyESP")
	end
end

function L_1_.clearAllSimpleRoleESP()
	for L_247_forvar0, L_248_forvar1 in ipairs(L_2_:GetPlayers()) do
		pcall(L_1_.clearSimpleRoleESP, L_248_forvar1)
	end
end

function L_1_.setSimpleRoleESP(L_249_arg0)
	L_14_.RoleESP = L_249_arg0
	if L_13_.MM2_ESP_Conn then
		L_13_.MM2_ESP_Conn:Disconnect()
		L_13_.MM2_ESP_Conn = nil
	end
	if L_249_arg0 then
		L_13_.MM2_ESP_Conn = L_4_.RenderStepped:Connect(function()
			if L_14_.RoleESP then
				pcall(L_1_.updateSimpleRoleESP)
			end
		end)
		if L_15_ and type(L_15_.Notify) == "function" then
			L_15_:Notify("ESP Active", "Tracking roles: Red=Murderer, Blue=Sheriff, Green=Innocent", 3, false)
		end
	else
		L_1_.clearAllSimpleRoleESP()
	end
end

-- Direct knife / gun actions -------------------------------------------------

function L_1_.attackWithKnife(L_250_arg0)
	local L_251_ = L_250_arg0 and L_250_arg0.Character
	local L_252_ = L_11_.Character
	if not L_251_ or not L_252_ then
		return
	end
	local L_253_ = L_252_:FindFirstChild("Knife")
	local L_254_ = L_253_ and L_253_:FindFirstChild("Handle")
	local L_255_ = L_19_func(L_250_arg0)
	local L_256_ = L_19_func(L_11_)
	local L_257_ = L_18_func(L_250_arg0)
	if not L_253_ or not L_255_ or not L_256_ or not L_257_ then
		return
	end
	local L_258_ = game:GetService("VirtualInputManager")
	local L_259_ = 0
	while L_257_.Health > 0 and L_259_ < 40 do
		L_259_ = L_259_ + 1
		L_256_.CFrame = L_255_.CFrame
		pcall(function()
			L_253_:Activate()
		end)
		L_12_ = L_10_.CurrentCamera
		local L_260_ = L_12_.ViewportSize / 2
		L_258_:SendMouseButtonEvent(L_260_.X, L_260_.Y, 0, true, game, 0)
		L_258_:SendMouseButtonEvent(L_260_.X, L_260_.Y, 0, false, game, 0)
		if L_254_ and type(firetouchinterest) == "function" then
			pcall(function()
				firetouchinterest(L_254_, L_255_, 0)
				firetouchinterest(L_254_, L_255_, 1)
			end)
		end
		task.wait(0.05)
	end
end

function L_1_.shootWithGun(L_261_arg0)
	local L_262_ = L_261_arg0 and L_261_arg0.Character
	local L_263_ = L_11_.Character
	if not L_262_ or not L_263_ then
		return
	end
	local L_264_ = L_263_:FindFirstChild("Gun")
	local L_265_ = L_19_func(L_261_arg0)
	local L_266_ = L_19_func(L_11_)
	if not L_264_ or not L_265_ or not L_266_ then
		return
	end
	local L_267_ = game:GetService("VirtualInputManager")
	L_266_.CFrame = L_265_.CFrame * CFrame.new(0, 0, 3)
	L_12_ = L_10_.CurrentCamera
	L_12_.CFrame = CFrame.lookAt(L_12_.CFrame.Position, L_265_.Position)
	task.wait(0.1)
	pcall(function()
		L_264_:Activate()
	end)
	local L_268_ = L_12_.ViewportSize / 2
	L_267_:SendMouseButtonEvent(L_268_.X, L_268_.Y, 0, true, game, 0)
	task.wait(0.05)
	L_267_:SendMouseButtonEvent(L_268_.X, L_268_.Y, 0, false, game, 0)
end

-- GunDrop monitor / auto-grab ------------------------------------------------

function L_1_.grabGunAndReturn()
	local L_269_ = L_10_:FindFirstChild("GunDrop", true)
	local L_270_ = L_19_func(L_11_)
	if not L_269_ or not L_270_ then
		if L_15_ and type(L_15_.Notify) == "function" then
			L_15_:Notify("Not Found", "No dropped gun exists in the map.", 3, false)
		end
		return
	end
	local L_271_ = L_270_.CFrame
	L_270_.CFrame = L_269_.CFrame
	task.wait(0.2)
	if type(firetouchinterest) == "function" then
		pcall(function()
			firetouchinterest(L_270_, L_269_, 0)
			firetouchinterest(L_270_, L_269_, 1)
		end)
	end
	task.wait(0.2)
	L_270_.CFrame = L_271_
	if L_15_ and type(L_15_.Notify) == "function" then
		L_15_:Notify("Gun Grabbed", "Teleported to gun and returned!", 3, false)
	end
end

local function L_49_func(L_272_arg0)
	if L_14_.AutoGrab and L_272_arg0.Name == "GunDrop" then
		task.wait(0.1)
		L_1_.grabGunAndReturn()
	end
end

function L_1_.setAutoGrabDroppedGun(L_273_arg0)
	L_14_.AutoGrab = L_273_arg0
	if L_13_.MM2_AutoGrab_Conn then
		L_13_.MM2_AutoGrab_Conn:Disconnect()
		L_13_.MM2_AutoGrab_Conn = nil
	end
	if L_273_arg0 then
		L_13_.MM2_AutoGrab_Conn = L_10_.DescendantAdded:Connect(L_49_func)
	end
end

-- Anti murderer --------------------------------------------------------------

local function L_50_func()
	for L_274_forvar0, L_275_forvar1 in ipairs(L_2_:GetPlayers()) do
		if L_275_forvar1 ~= L_11_ and L_275_forvar1.Character then
			local L_276_ = L_18_func(L_275_forvar1)
			if L_276_ and L_276_.Health > 0 and L_20_func(L_275_forvar1, "knife") then
				return L_275_forvar1
			end
		end
	end
	return nil
end

function L_1_.autoEvadeMurdererTick()
	if not L_14_.AutoEvade then
		return
	end
	local L_277_ = L_19_func(L_11_)
	local L_278_ = L_50_func()
	local L_279_ = L_278_ and L_19_func(L_278_)
	if not L_277_ or not L_279_ then
		return
	end
	local L_280_ = L_277_.Position - L_279_.Position
	if L_280_.Magnitude >= 15 then
		return
	end
	local L_281_ = L_280_.Unit
    -- The original explicitly guards against NaN with `away == away`.
	if not (L_281_ == L_281_) then
		L_281_ = Vector3.new(0, 1, 0)
	end
	L_277_.CFrame = L_277_.CFrame + L_281_ * 30
end

function L_1_.setAutoEvade(L_282_arg0)
	L_14_.AutoEvade = L_282_arg0
	if L_13_.MM2_Evade_Conn then
		L_13_.MM2_Evade_Conn:Disconnect()
		L_13_.MM2_Evade_Conn = nil
	end
	if L_282_arg0 then
		L_13_.MM2_Evade_Conn = L_4_.Heartbeat:Connect(L_1_.autoEvadeMurdererTick)
	end
end

-- Targeted combat buttons ----------------------------------------------------

function L_1_.killAllPlayers()
	local L_283_ = L_11_.Character
	if not L_283_ or not L_283_:FindFirstChild("Knife") then
		L_16_func("You must be the Murderer first!", 3, "Missing Knife")
		return
	end
	for L_284_forvar0, L_285_forvar1 in ipairs(L_2_:GetPlayers()) do
		if L_285_forvar1 ~= L_11_ then
			local L_286_ = L_18_func(L_285_forvar1)
			if L_286_ and L_286_.Health > 0 then
				L_1_.attackWithKnife(L_285_forvar1)
			end
		end
	end
end

function L_1_.killSheriff()
	local L_287_ = L_11_.Character
	if not L_287_ or not L_287_:FindFirstChild("Knife") then
		L_16_func("You must be the Murderer first!", 3, "Missing Knife")
		return
	end
	for L_288_forvar0, L_289_forvar1 in ipairs(L_2_:GetPlayers()) do
		if L_289_forvar1 ~= L_11_ then
			local L_290_ = L_18_func(L_289_forvar1)
			if L_290_ and L_290_.Health > 0 and L_20_func(L_289_forvar1, "gun") then
				L_16_func("Teleporting to the Sheriff...", 3, "Targeting")
				L_1_.attackWithKnife(L_289_forvar1)
				return
			end
		end
	end
	if L_15_ and type(L_15_.Notify) == "function" then
		L_15_:Notify("Not Found", "Could not find a living Sheriff.", 3, false)
	end
end

function L_1_.killMurderer()
	local L_291_ = L_11_.Character
	if not L_291_ or not L_291_:FindFirstChild("Gun") then
		if L_15_ and type(L_15_.Notify) == "function" then
			L_15_:Notify("Missing Gun", "You need to have the Sheriff gun equipped!", 3, false)
		end
		return
	end
	for L_292_forvar0, L_293_forvar1 in ipairs(L_2_:GetPlayers()) do
		if L_293_forvar1 ~= L_11_ then
			local L_294_ = L_18_func(L_293_forvar1)
			if L_294_ and L_294_.Health > 0 and L_20_func(L_293_forvar1, "knife") then
				L_16_func("Teleporting to the Murderer...", 3, "Targeting")
				L_1_.shootWithGun(L_293_forvar1)
				return
			end
		end
	end
	if L_15_ and type(L_15_.Notify) == "function" then
		L_15_:Notify("Not Found", "Could not find a living Murderer.", 3, false)
	end
end

-- Second-panel noclip ---------------------------------------------------------
-- This is distinct from State.NoClip. The original stores the connection in
-- `_G.MM2_Noclip_Conn` and, despite the "Collisions restored" notification,
-- only disconnects the loop when disabled; it does not explicitly restore the
-- previous CanCollide values.

local function L_51_func()
	local L_295_ = L_11_.Character
	if not L_295_ then
		return
	end
	for L_296_forvar0, L_297_forvar1 in pairs(L_295_:GetDescendants()) do
		if L_297_forvar1:IsA("BasePart") and L_297_forvar1.CanCollide then
			L_297_forvar1.CanCollide = false
		end
	end
end

function L_1_.setPremiumNoClip(L_298_arg0)
	if _G.MM2_Noclip_Conn then
		_G.MM2_Noclip_Conn:Disconnect()
		_G.MM2_Noclip_Conn = nil
	end
	if L_298_arg0 then
		_G.MM2_Noclip_Conn = L_4_.Stepped:Connect(L_51_func)
		if L_15_ and type(L_15_.Notify) == "function" then
			L_15_:Notify("Noclip", "Walk through walls enabled.", 2, false)
		end
	else
		if L_15_ and type(L_15_.Notify) == "function" then
			L_15_:Notify("Noclip", "Collisions restored.", 2, false)
		end
	end
end

-- Player fly -----------------------------------------------------------------

local L_52_ = false
local L_53_ = 50
local L_54_ = nil
local L_55_ = nil

local function L_56_func()
	if L_54_ then
		L_54_:Destroy()
		L_54_ = nil
	end
	if L_55_ then
		L_55_:Destroy()
		L_55_ = nil
	end
end

local function L_57_func()
	while L_52_ do
		local L_300_ = L_19_func(L_11_)
		local L_301_ = L_18_func(L_11_)
		if not L_300_ then
			break
		end
		L_12_ = L_10_.CurrentCamera
		local L_302_ = Vector3.new(0, 0, 0)
		if L_5_:IsKeyDown(Enum.KeyCode.W) then
			L_302_ = L_302_ + L_12_.CFrame.LookVector
		end
		if L_5_:IsKeyDown(Enum.KeyCode.S) then
			L_302_ = L_302_ - L_12_.CFrame.LookVector
		end
		if L_5_:IsKeyDown(Enum.KeyCode.A) then
			L_302_ = L_302_ - L_12_.CFrame.RightVector
		end
		if L_5_:IsKeyDown(Enum.KeyCode.D) then
			L_302_ = L_302_ + L_12_.CFrame.RightVector
		end
		if L_5_:IsKeyDown(Enum.KeyCode.Space) then
			L_302_ = L_302_ + Vector3.new(0, 1, 0)
		end
		if L_5_:IsKeyDown(Enum.KeyCode.LeftShift) then
			L_302_ = L_302_ - Vector3.new(0, 1, 0)
		end
		if L_54_ then
			if L_302_.Magnitude > 0 then
				L_54_.Velocity = L_302_.Unit * L_53_
			else
				L_54_.Velocity = Vector3.new(0, math.sin(tick() * 3) * 1.5, 0)
			end
		end
		if L_55_ then
			local L_303_ = L_12_.CFrame.LookVector
			L_55_.CFrame = CFrame.new(
                L_300_.Position,
                L_300_.Position + Vector3.new(L_303_.X, 0, L_303_.Z)
            )
		end
		if L_301_ then
			L_301_.PlatformStand = true
			for L_304_forvar0, L_305_forvar1 in ipairs(L_301_:GetPlayingAnimationTracks()) do
				L_305_forvar1:Stop()
			end
		end
		task.wait()
	end
	L_56_func()
	local L_299_ = L_18_func(L_11_)
	if L_299_ then
		L_299_.PlatformStand = false
	end
end

function L_1_.setPlayerFly(L_306_arg0)
	L_52_ = L_306_arg0
	local L_307_ = L_19_func(L_11_)
	local L_308_ = L_18_func(L_11_)
	if not L_307_ then
		return
	end
	if L_306_arg0 then
		L_56_func()
		L_54_ = Instance.new("BodyVelocity")
		L_54_.Name = "MM2FlyBV"
		L_54_.MaxForce = Vector3.new(1, 1, 1)
		L_54_.Velocity = Vector3.new(0, 0, 0)
		L_54_.Parent = L_307_
		L_55_ = Instance.new("BodyGyro")
		L_55_.Name = "MM2FlyBG"
		L_55_.MaxTorque = Vector3.new(1, 1, 1)
		L_55_.CFrame = L_307_.CFrame
		L_55_.Parent = L_307_
		if L_308_ then
			L_308_.PlatformStand = true
		end
		task.spawn(L_57_func)
	else
		L_56_func()
		if L_308_ then
			L_308_.PlatformStand = false
			L_308_:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

function L_1_.setPlayerFlySpeed(L_309_arg0)
	L_53_ = L_309_arg0
end

-- Gun-drop notification / lobby / Discord -----------------------------------

local function L_58_func(L_310_arg0)
	if L_14_.NotifyGun and L_310_arg0.Name == "GunDrop" and L_15_ and type(L_15_.Notify) == "function" then
		L_15_:Notify(
            "SHERIFF DIED!",
            "The gun dropped! Go grab it from Combat tab.",
            8,
            true
        )
	end
end

function L_1_.setGunDropNotification(L_311_arg0)
	L_14_.NotifyGun = L_311_arg0
	if L_13_.MM2_GunDrop_Conn then
		L_13_.MM2_GunDrop_Conn:Disconnect()
		L_13_.MM2_GunDrop_Conn = nil
	end
	if L_311_arg0 then
		L_13_.MM2_GunDrop_Conn = L_10_.DescendantAdded:Connect(L_58_func)
	end
end

function L_1_.teleportToLobby()
	local L_312_ = L_19_func(L_11_)
	if L_312_ then
		L_312_.CFrame = CFrame.new(-109.5, 138, 38)
		if L_15_ and type(L_15_.Notify) == "function" then
			L_15_:Notify("Teleported", "Returned to Lobby.", 2, false)
		end
	end
end

function L_1_.copyDiscord()
	if type(setclipboard) == "function" then
		pcall(setclipboard, "https://discord.gg/getsnowy")
	end
	if L_15_ and type(L_15_.Notify) == "function" then
		L_15_:Notify("Discord", "discord.gg/getsnowy copied!", 3, false)
	end
end

-- Human-readable UI definition ----------------------------------------------
--
-- The VM contained two MM2 UI groups. Rather than reproducing register-level
-- setup, this table documents the recovered controls and their callbacks.

L_1_.Controls = {
	RoundInfo = {
		{
			kind = "button",
			name = "Copy Murderer Name",
			callback = L_1_.copyMurdererName
		},
	},
	Combat = {
		{
			kind = "toggle",
			name = "Kill Aura (as Murderer)",
			callback = L_1_.setKillAura
		},
		{
			kind = "button",
			name = "Auto-Kill Murderer (as Sheriff)",
			callback = L_1_.shootMurderer
		},
		{
			kind = "premiumToggle",
			name = "Auto-Shoot Murderer",
			callback = L_1_.setAutoShoot
		},
		{
			kind = "premiumToggle",
			name = "Silent Aim (redirect shots)",
			callback = L_1_.setSilentAim
		},
		{
			kind = "button",
			name = "Grab Dropped Gun",
			callback = L_1_.teleportToDroppedGun
		},
		{
			kind = "toggle",
			name = "Auto-Grab Gun",
			callback = L_1_.setAutoGrabGun
		},
		{
			kind = "premiumToggle",
			name = "Auto-Grab Knife",
			callback = L_1_.setAutoGrabKnife
		},
	},
	Movement = {
		{
			kind = "slider",
			name = "Walk Speed",
			max = 200,
			default = 16,
			callback = L_1_.setWalkSpeed
		},
		{
			kind = "slider",
			name = "Jump Power",
			max = 350,
			default = 50,
			callback = L_1_.setJumpPower
		},
		{
			kind = "toggle",
			name = "Infinite Jump",
			callback = L_1_.setInfiniteJump
		},
		{
			kind = "premiumToggle",
			name = "No Clip",
			callback = L_1_.setNoClip
		},
		{
			kind = "premiumSlider",
			name = "Fly Speed",
			max = 500,
			default = 30,
			callback = L_1_.setBasicFlySpeed
		},
		{
			kind = "premiumToggle",
			name = "Fly (WASD+Space/Ctrl)",
			callback = L_1_.setBasicFly
		},
		{
			kind = "button",
			name = "Teleport to Murderer",
			callback = L_1_.teleportToMurderer
		},
		{
			kind = "button",
			name = "Teleport to Sheriff",
			callback = L_1_.teleportToSheriff
		},
		{
			kind = "button",
			name = "Save Position",
			callback = L_1_.savePosition
		},
		{
			kind = "button",
			name = "Load Position",
			callback = L_1_.loadPosition
		},
	},
	CoinFarm = {
		{
			kind = "button",
			name = "Collect All Coins (instant)",
			callback = L_1_.collectAllCoins
		},
		{
			kind = "premiumToggle",
			name = "Auto-Collect Coins (loop)",
			callback = L_1_.setAutoCoin
		},
		{
			kind = "button",
			name = "TP to Nearest Coin",
			callback = L_1_.teleportToNearestCoin
		},
	},
	ESP = {
		{
			kind = "premiumToggle",
			name = "ESP: Murderer",
			callback = L_1_.setMurdererESP
		},
		{
			kind = "premiumToggle",
			name = "ESP: Sheriff",
			callback = L_1_.setSheriffESP
		},
		{
			kind = "toggle",
			name = "ESP: Innocents",
			callback = L_1_.setInnocentESP
		},
		{
			kind = "toggle",
			name = "ESP: Gun Drop",
			callback = L_1_.setGunESP
		},
		{
			kind = "toggle",
			name = "ESP: Knife Drop",
			callback = L_1_.setKnifeESP
		},
		{
			kind = "premiumToggle",
			name = "ESP: Coins",
			callback = L_1_.setCoinESP
		},
	},
	Visuals = {
		{
			kind = "toggle",
			name = "Fullbright",
			callback = L_1_.setFullbright
		},
		{
			kind = "toggle",
			name = "No Fog",
			callback = L_1_.setNoFog
		},
		{
			kind = "slider",
			name = "Camera FOV",
			max = 120,
			default = 70,
			callback = L_1_.setFOV
		},
		{
			kind = "toggle",
			name = "Hide Own Name",
			callback = L_1_.setHideOwnName
		},
	},
	QualityOfLife = {
		{
			kind = "toggle",
			name = "Anti-AFK (never kicked)",
			callback = L_1_.setAntiAFK
		},
		{
			kind = "toggle",
			name = "Anti-Slip (lock Y axis on ice)",
			callback = L_1_.setAntiSlip
		},
		{
			kind = "toggle",
			name = "Anti-Fling / Anti-Void",
			callback = L_1_.setAntiFling
		},
		{
			kind = "button",
			name = "Rejoin Server",
			callback = L_1_.rejoinServer
		},
		{
			kind = "button",
			name = "Server Hop",
			callback = L_1_.serverHop
		},
	},
	SecondaryCombat = {
		{
			kind = "toggle",
			name = "Role ESP (Red=Murderer, Blue=Sheriff)",
			callback = L_1_.setSimpleRoleESP
		},
		{
			kind = "toggle",
			name = "Auto Grab Dropped Gun",
			callback = L_1_.setAutoGrabDroppedGun
		},
		{
			kind = "toggle",
			name = "Anti-Murderer (Auto Evade)",
			callback = L_1_.setAutoEvade
		},
		{
			kind = "button",
			name = "Grab Dropped Gun (Manual)",
			callback = L_1_.grabGunAndReturn
		},
		{
			kind = "button",
			name = "Kill All (Requires Murderer)",
			callback = L_1_.killAllPlayers
		},
		{
			kind = "button",
			name = "Kill Sheriff (Requires Knife)",
			callback = L_1_.killSheriff
		},
		{
			kind = "button",
			name = "Kill Murderer (Requires Gun)",
			callback = L_1_.killMurderer
		},
		{
			kind = "toggle",
			name = "Noclip (Walk Through Walls)",
			callback = L_1_.setPremiumNoClip
		},
		{
			kind = "premiumToggle",
			name = "Realistic Player Fly",
			callback = L_1_.setPlayerFly
		},
		{
			kind = "premiumSlider",
			name = "Fly Speed",
			max = 200,
			default = 10,
			callback = L_1_.setPlayerFlySpeed
		},
		{
			kind = "toggle",
			name = "Notify When Sheriff Dies (Gun Drop)",
			callback = L_1_.setGunDropNotification
		},
		{
			kind = "button",
			name = "Teleport to Lobby",
			callback = L_1_.teleportToLobby
		},
		{
			kind = "button",
			name = "Copy Discord",
			callback = L_1_.copyDiscord
		},
	},
}

-- Startup hooks that were created by the original MM2 branch ----------------

function L_1_.start()
	if L_11_.CharacterAdded then
		L_14_._movementRespawnConn = L_11_.CharacterAdded:Connect(L_1_.reapplyMovement)
	end
	return L_1_
end

return L_1_