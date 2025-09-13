local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Gui = player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Ch = player.Character or player.CharacterAdded:Wait()

-- หา QueryHitbox ในตัวละคร
-- สร้าง ScreenGui
local HumanoidRootPart = Ch.HumanoidRootPart
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Gui

-- Frame หลัก
local Frame = Instance.new("Frame")
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.25
Frame.Position = UDim2.new(0.662, 0, 0.055, 0)
Frame.Size = UDim2.new(0, 283, 0, 136)
Frame.Parent = ScreenGui

local UICorner_1 = Instance.new("UICorner")
UICorner_1.CornerRadius = UDim.new(0, 8)
UICorner_1.Parent = Frame

-- ปุ่ม OFF
local ToggleButton = Instance.new("TextButton")
ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleButton.BackgroundTransparency = 0.4
ToggleButton.Position = UDim2.new(0.145, 0, 0.559, 0)
ToggleButton.Size = UDim2.new(0, 200, 0, 50)
ToggleButton.Font = Enum.Font.Fondamento
ToggleButton.TextScaled = true
ToggleButton.Text = "OFF"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)	
ToggleButton.Parent = Frame

local UICorner_3 = Instance.new("UICorner")
UICorner_3.CornerRadius = UDim.new(0, 4)
UICorner_3.Parent = ToggleButton

-- Label (ทำให้กดได้เหมือนปุ่ม)
local ToggleLabel = Instance.new("TextLabel")
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Position = UDim2.new(0.145, 0, 0.132, 0)
ToggleLabel.Size = UDim2.new(0, 200, 0, 50)
ToggleLabel.Font = Enum.Font.Fondamento
ToggleLabel.Text = "Noclip"
ToggleLabel.TextColor3 = Color3.new(1, 1, 1)
ToggleLabel.TextScaled = true
ToggleLabel.Parent = Frame

-- ระบบ Toggle เปิด/ปิด
local noclipEnabled = false

local function toggleNoclip()
	noclipEnabled = not noclipEnabled
	if noclipEnabled then
		ToggleButton.Text = "ON"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		local hitbox = Ch:WaitForChild("QueryHitbox")
		local connector = hitbox:WaitForChild("CollisionConnector")
		connector.Enabled = true
		wait(4)
		HumanoidRootPart.Anchored = true
	else
		ToggleButton.Text = "OFF"
		ToggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
		local hitbox = Ch:WaitForChild("QueryHitbox")
		local connector = hitbox:WaitForChild("CollisionConnector")
		connector.Enabled = false
		wait(4)
		HumanoidRootPart.Anchored = false
	end
end

-- ให้กดได้ทั้งปุ่มกับ Label
ToggleButton.MouseButton1Click:Connect(toggleNoclip)
