-- Services
local Workspace = game:GetService("Workspace")

-- ตำแหน่ง CFrame ใหม่
local targetCFrame = CFrame.new(37.0001755, 0.900142491, 53.6997643)

-- ฟังก์ชันวาป Model หรือ Part
local function warpObjects(folder)
	if folder then
		for _, obj in pairs(folder:GetChildren()) do
			if obj:IsA("Model") then
				-- ถ้าเป็น Model ให้ย้าย RootPart ของมัน
				local root = obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildWhichIsA("BasePart")
				if root then
					-- ย้ายทั้งหมดของ Model โดยการตั้ง PrimaryPart CFrame
					obj:SetPrimaryPartCFrame(targetCFrame)
				end
			elseif obj:IsA("BasePart") then
				-- ถ้าเป็น Part ปกติ ให้ย้ายตรงๆ
				obj.CFrame = targetCFrame
			end
		end
	end
end

-- วาป Trucks และ AllSupplyBoxes
warpObjects(Workspace:FindFirstChild("Trucks"))
warpObjects(Workspace:FindFirstChild("AllSupplyBoxes"))
