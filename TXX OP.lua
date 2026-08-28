-- 【第一部分：基礎設定、UI 面板與雷達函數】
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- 建立 UI 介面
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AIBotPremiumPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 350)
mainFrame.Position = UDim2.new(0, 50, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 27, 32)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 12)
uiCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 45)
titleLabel.BackgroundColor3 = Color3.fromRGB(35, 38, 46)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = " 🤖 AI 智慧導航系統"
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 12)

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0.9, 0, 0, 35)
refreshBtn.Position = UDim2.new(0.05, 0, 0, 55)
refreshBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 60)
refreshBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
refreshBtn.Text = "🔄 重新整理玩家清單"
refreshBtn.Font = Enum.Font.GothamSemibold
refreshBtn.Parent = mainFrame

Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 8)

local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(0.9, 0, 0, 175)
scrollList.Position = UDim2.new(0.05, 0, 0, 100)
scrollList.BackgroundColor3 = Color3.fromRGB(18, 19, 23)
scrollList.ScrollBarThickness = 4
scrollList.Parent = mainFrame

Instance.new("UICorner", scrollList).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.Parent = scrollList

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.9, 0, 0, 45)
toggleBtn.Position = UDim2.new(0.05, 0, 0, 290)
toggleBtn.BackgroundColor3 = Color3.fromRGB(209, 67, 67)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Text = "系統狀態：關閉"
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = mainFrame

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- 視覺與透視 Highlight
local pathFolder = Instance.new("Folder")
pathFolder.Name = "AI_VisualPath"
pathFolder.Parent = workspace

local espHighlight = Instance.new("Highlight")
espHighlight.Name = "AI_TargetESP"
espHighlight.FillColor = Color3.fromRGB(255, 0, 0)
espHighlight.FillTransparency = 0.5
espHighlight.OutlineColor = Color3.fromRGB(255, 255, 0)
espHighlight.OutlineTransparency = 0
espHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

local selectedPlayer = nil
local isRunning = false
local lastPosition = Vector3.new()
local lastCheckTime = os.clock()
local lastJumpTime = 0
local isStuck = false

local function clearVisualPath()
	pathFolder:ClearAllChildren()
end

local function updateESP(targetCharacter)
	espHighlight.Parent = targetCharacter or nil
end

local function forceExecuteJump()
	local now = os.clock()
	if now - lastJumpTime < 0.25 then return end 
	lastJumpTime = now
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	task.spawn(function()
		for p = 1, 3 do
			rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, humanoid.JumpPower * 0.95, rootPart.AssemblyLinearVelocity.Z)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function checkFrontObstacleAndJump()
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {character, pathFolder}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local startPos = rootPart.Position + Vector3.new(0, -0.8, 0)
	local direction = rootPart.CFrame.LookVector * 2.5
	local hitResult = workspace:Raycast(startPos, direction, raycastParams)
	
	if hitResult and hitResult.Instance and hitResult.Instance.CanCollide then
		local jumpHeightCheck = workspace:Raycast(startPos + Vector3.new(0, 4.5, 0), direction, raycastParams)
		if not jumpHeightCheck then 
			forceExecuteJump() 
		else 
			isStuck = true 
		end
	end
end

local function isPositionSafe(targetPos)
	local raycastParams = RaycastParams.new()
	local ignoreList = {character, pathFolder}
	if selectedPlayer and selectedPlayer.Character then 
		table.insert(ignoreList, selectedPlayer.Character) 
	end
	raycastParams.FilterDescendantsInstances = ignoreList
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local rayStart = targetPos + Vector3.new(0, 2, 0)
	local rayDirection = Vector3.new(0, -100, 0) 
	local rayResult = workspace:Raycast(rayStart, rayDirection, raycastParams)
	
	if rayResult then
		local hitInstance = rayResult.Instance
		if hitInstance.Name:lower():find("void") or hitInstance.Name:lower():find("kill") then 
			return false 
		end
		return true 
	else 
		return false 
	end
end
-- 【第二部分：路線繪製、介面綁定與 AI 主循環修正】
local function drawVisualPath(waypointsList)
	clearVisualPath()
	if #waypointsList < 2 then return end
	for i = 1, math.min(#waypointsList - 1, 25) do 
		local p1 = waypointsList[i].Position
		local p2 = waypointsList[i+1].Position
		local offsetVector = Vector3.new(0, 1.2, 0)
		
		local part1 = Instance.new("Part", pathFolder)
		part1.Anchored = true; part1.CanCollide = false; part1.Transparency = 1
		part1.Position = (p1 - Vector3.new(0, 2, 0)) + offsetVector
		
		local part2 = Instance.new("Part", pathFolder)
		part2.Anchored = true; part2.CanCollide = false; part2.Transparency = 1
		part2.Position = (p2 - Vector3.new(0, 2, 0)) + offsetVector
		
		local bm = Instance.new("Beam", part1)
		bm.Attachment0 = Instance.new("Attachment", part1)
		bm.Attachment1 = Instance.new("Attachment", part2)
		bm.Width0 = 0.7; bm.Width1 = 0.7
		bm.Color = (waypointsList[i+1].Action == Enum.PathWaypointAction.Jump) and ColorSequence.new(Color3.fromRGB(255, 100, 0)) or ColorSequence.new(Color3.fromRGB(0, 255, 150))
		bm.LightEmission = 1; bm.Texture = "rbxassetid://446111271"; bm.TextureSpeed = 2; bm.TextureLength = 1.5
	end
end

local function refreshPlayerList()
	for _, child in ipairs(scrollList:GetChildren()) do 
		if child:IsA("TextButton") then child:Destroy() end 
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer then
			local pBtn = Instance.new("TextButton", scrollList)
			pBtn.Size = UDim2.new(0.95, 0, 0, 32)
			pBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 48)
			pBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			pBtn.Text = p.DisplayName
			Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)
			
			pBtn.MouseButton1Click:Connect(function()
				selectedPlayer = p
				titleLabel.Text = " 🎯 目標: " .. p.Name
				if p.Character then updateESP(p.Character) end
			end)
		end
	end
	scrollList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end

refreshBtn.MouseButton1Click:Connect(refreshPlayerList)
refreshPlayerList()

toggleBtn.MouseButton1Click:Connect(function()
	isRunning = not isRunning
	if isRunning then
		toggleBtn.Text = "系統狀態：運作中"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(46, 184, 115)
		if selectedPlayer and selectedPlayer.Character then updateESP(selectedPlayer.Character) end
	else
		toggleBtn.Text = "系統狀態：關閉"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(209, 67, 67)
		humanoid:MoveTo(rootPart.Position)
		clearVisualPath()
		updateESP(nil)
	end
end)

-- AI 導航心跳主循環 (排版與修復修正版)
RunService.Heartbeat:Connect(function()
	if not isRunning or not selectedPlayer or not selectedPlayer.Character then 
		clearVisualPath()
		return 
	end
	
	local targetChar = selectedPlayer.Character
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
	if not targetRoot then updateESP(nil); return end
	if espHighlight.Parent ~= targetChar then updateESP(targetChar) end
	
	checkFrontObstacleAndJump()
	
	local now = os.clock()
	if now - lastCheckTime > 0.15 then
		local moveDistance = (rootPart.Position - lastPosition).Magnitude
		if moveDistance < 0.25 and humanoid.MoveDirection.Magnitude > 0 then
			isStuck = true
			forceExecuteJump()
		else 
			isStuck = false 
		end
		lastPosition = rootPart.Position
		lastCheckTime = now
	end
	
	local path = PathfindingService:CreatePath({
		AgentRadius = isStuck and 7.5 or 2.5, 
		AgentHeight = 5, 
		AgentCanJump = true, 
		WaypointSpacing = 3
	})
	
	local success, err = pcall(function() 
		path:ComputeAsync(rootPart.Position, targetRoot.Position) 
	end)
	
	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		drawVisualPath(waypoints)
		
		if #waypoints > 1 then
			-- 【重要修復】精確獲取下一個移動節點（陣列索引為 2）
			local nextPoint = waypoints[2]
			
			if isPositionSafe(nextPoint.Position) then
				humanoid:MoveTo(nextPoint.Position)
				if nextPoint.Action == Enum.PathWaypointAction.Jump or isStuck then 
					forceExecuteJump() 
				end
			else
				humanoid:MoveTo(rootPart.Position - (rootPart.CFrame.LookVector * 3.5))
				if isStuck then forceExecuteJump() end
			end
		end
	else
		clearVisualPath()
		if isStuck then forceExecuteJump() end
	end
end)

localPlayer.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = newChar:WaitForChild("Humanoid")
	rootPart = newChar:WaitForChild("HumanoidRootPart")
end)