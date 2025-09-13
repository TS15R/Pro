local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local Survivors = workspace:WaitForChild("Players"):WaitForChild("Survivors")

-- สร้าง ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = PlayerGui
ScreenGui.Name = "ToggleFollowGui"

-- สร้าง Frame สำหรับ GUI
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 100, 0, 100)
Frame.Position = UDim2.new(0.625, 0,0.08, 0)
Frame.BackgroundTransparency = 1
Frame.Parent = ScreenGui

-- สร้าง ImageButton
local Button = Instance.new("ImageButton")
Button.Size = UDim2.new(1,0,1,0)
Button.BackgroundTransparency = 1
Button.Image = "rbxassetid://111617770896173" -- ปิดเริ่มต้น
Button.Parent = Frame

-- วาป Q
local Ch = player.Character or player.CharacterAdded:Wait()
local HRP = Ch:WaitForChild("HumanoidRootPart")
local Camera = workspace.CurrentCamera
local teleporting = false
local trackingEnabled = false
local savedCFrame = nil

-- Drag GUI
local dragging = false
local mouseOffset = Vector2.new(0,0)

-- เก็บ BillboardGui เพื่อเปิด/ปิด
local healthBillboards = {}

-- ฟังก์ชันหา Player เลือดน้อยสุด
local function getLowestHealthPlayer()
	local lowest = nil
	for _, plr in ipairs(Survivors:GetChildren()) do
		if plr ~= Ch and plr:FindFirstChild("Humanoid") and plr:FindFirstChild("HumanoidRootPart") then
			if not lowest or plr.Humanoid.Health < lowest.Humanoid.Health then
				lowest = plr
			end
		end
	end
	return lowest
end

-- วาปไปด้านหลังและหันหน้า
local function startTracking()
	local target = getLowestHealthPlayer()
	if target and target:FindFirstChild("HumanoidRootPart") then
		savedCFrame = HRP.CFrame
		teleporting = true
		RunService:BindToRenderStep("FollowTarget", Enum.RenderPriority.Camera.Value + 1, function()
			if not teleporting or not target.Parent then
				RunService:UnbindFromRenderStep("FollowTarget")
				return
			end
			local targetHRP = target.HumanoidRootPart
			local behindCFrame = targetHRP.CFrame * CFrame.new(0,0,-3)
			local lookAtCFrame = CFrame.new(behindCFrame.Position, targetHRP.Position)
			HRP.CFrame = lookAtCFrame
			Camera.CFrame = HRP.CFrame
		end)
	end
end

local function stopTracking()
	if teleporting then
		RunService:UnbindFromRenderStep("FollowTarget")
		if savedCFrame then
			HRP.CFrame = savedCFrame
			Camera.CFrame = savedCFrame
		end
		teleporting = false
	end
end

-- สร้าง BillboardGui แสดง HP
local function createHealthBillboard(character)
	if not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then return end
	if healthBillboards[character] then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "HealthBillboard"
	billboard.Adornee = character.HumanoidRootPart
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = character

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1,0,1,0)
	textLabel.BackgroundTransparency = 1
	textLabel.TextColor3 = Color3.fromRGB(255,0,0)
	textLabel.TextStrokeTransparency = 0
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	-- อัพเดทเลือด
	local humanoid = character.Humanoid
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if humanoid.Health <= 0 or not character.Parent then
			billboard:Destroy()
			if conn then conn:Disconnect() end
			healthBillboards[character] = nil
			return
		end
		textLabel.Text = math.floor(humanoid.Health) .. " HP"
	end)

	healthBillboards[character] = billboard
end

-- ลบ BillboardGui ทั้งหมด
local function removeAllBillboards()
	for char, bb in pairs(healthBillboards) do
		if bb then
			bb:Destroy()
		end
	end
	healthBillboards = {}
end

-- Toggle เปิด/ปิดการใช้งานปุ่ม Q และ Billboard
Button.MouseButton1Click:Connect(function()
	trackingEnabled = not trackingEnabled
	if trackingEnabled then
		Button.Image = "rbxassetid://115952781445669" -- เปิด
		-- สร้าง BillboardGui ให้ทุกตัว
		for _, survivor in ipairs(Survivors:GetChildren()) do
			createHealthBillboard(survivor)
		end
	else
		Button.Image = "rbxassetid://111617770896173" -- ปิด
		removeAllBillboards()
	end
end)

-- กด Q ค้างเพื่อวาป
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Q and trackingEnabled then
		startTracking()
	elseif input.KeyCode == Enum.KeyCode.L then
		-- เริ่มลาก GUI ตามเมาส์
		dragging = true
		local mousePos = UserInputService:GetMouseLocation()
		local absPos = Frame.AbsolutePosition
		mouseOffset = Vector2.new(mousePos.X - absPos.X, mousePos.Y - absPos.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.Q and trackingEnabled then
		stopTracking()
	elseif input.KeyCode == Enum.KeyCode.L then
		dragging = false
	end
end)

-- Update GUI ตามเมาส์
RunService.RenderStepped:Connect(function()
	if dragging then
		local mousePos = UserInputService:GetMouseLocation()
		Frame.Position = UDim2.new(0, mousePos.X - mouseOffset.X, 0, mousePos.Y - mouseOffset.Y)
	end
end)

-- เพิ่ม Billboard ให้ตัวละครใหม่
Survivors.ChildAdded:Connect(function(child)
	if trackingEnabled then
		createHealthBillboard(child)
	end
end)
