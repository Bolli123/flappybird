// please dont

local PANEL = {}
local muted = false
// Materials
local birdMat = nil
local birdMats = {}

for i = 1, 3 do
	for j = 1, 4 do
		birdMat = Material("materials/Jarheads/Phone/birdup/bird" .. i .. "_" .. j .. ".png")
		table.insert(birdMats, birdMat)
	end
end

local pipes = { Material("materials/Jarheads/Phone/birdup/greypipe-up.png", "noclamp smooth"), Material("materials/Jarheads/Phone/birdup/greypipe-down.png", "noclamp smooth")}
local groundMat = Material("materials/Jarheads/Phone/birdup/base.png", "noclamp smooth")
local skyMats = { Material("materials/Jarheads/Phone/birdup/paralake-day.png", "noclamp smooth"), Material("materials/Jarheads/Phone/birdup/paralake-night.png", "noclamp smooth")}
local soundIcon = Material("voice/icntlk_sv", "noclamp smooth")
local crossIcon = Material("vgui/hud/vote_no", "noclamp smooth")
// Fonts
surface.CreateFont( "ScoreFont", {
	font = "BudgetLabel",
	size =  ScreenScale(22),
	weight = 700,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	additive = true
})
surface.CreateFont( "HighscoreCard", {
	font = "ScoreFont",
	size = ScreenScale(14)
})

surface.CreateFont( "ScoreCard", {
	font = "ScoreFont",
	size = ScreenScale(12)
})
surface.CreateFont( "RetryGame", {
	font = "ScoreFont",
	size = ScreenScale(6)
})
// Sounds
local wingSound = Sound("Jarheads/smartphone/birdup/wing.mp3")
local swoosh = Sound("Jarheads/smartphone/birdup/swoosh.mp3")
local pointSound = Sound("Jarheads/smartphone/birdup/point.mp3")
local hitSound = Sound("Jarheads/smartphone/birdup/hit.mp3")
local deathSound = Sound("Jarheads/smartphone/birdup/die.mp3")


function PANEL:Init()
	self.walls = {}
	self.grounds = {}
	self.backgrounds = {}
	self.gravity = 16
	self.birdPos = Vector(Smartphone_DisplayW / 4, Smartphone_DisplayH / 2.4, 0)
	self.birdVelocity = Vector(0, 0, 0)
	self.birdWidth = 62
	self.birdHeight = 45
	self.birdMatOffset = math.random(0, 2) * 4
	self.maxBirdAng = 25
	self.minBirdAng = -90
	self.birdAngle = 0
	self.groundHeight = Smartphone_DisplayH / 5
	self.wallSpeed = 200
	self.wallSize = 80
	self.wallGap = 80
	self.skyMat = math.random(1, 2)
	self.pipeColor = HSVToColor(math.random(0, 360), 0.8, 0.9)
	self.currentBirdMat = birdMats[1 + self.birdMatOffset]
	self.backgroundWidth = 1.6 * (Smartphone_DisplayW * (789 / 512)) + 200
	self.backgroundHeight = 1.6 * (Smartphone_DisplayH * (512 / 789))
	self.gameOver = false
	self.jump = false
	self.started = false
	self.upFlap = false
	self.newHigh = false
	self.score = 0
	self.lastGold = 0
	self.startTime = nil
	self.flash = 150
	// Starting textures
	local ground = {}
	ground.height = self.groundHeight
	ground.width = Smartphone_DisplayW
	ground.pos = Vector(0, Smartphone_DisplayH - ground.height, 0)
	table.insert(self.grounds, ground)
	local background = {}
	background.pos = Vector(0, 0, 0)
	background.height = self.backgroundHeight
	background.width = self.backgroundWidth
	table.insert(self.backgrounds, background)
	self:SetKeyboardInputEnabled(true)
end

function PANEL:GenerateBackground()
	// creates a new background at the end of the older one
	local background = {}
	local x = self.backgrounds[#self.backgrounds].pos.x + self.backgroundWidth
	background.pos = Vector(x, 0, 0)
	background.height = self.backgroundHeight
	background.width = self.backgroundWidth
	table.insert(self.backgrounds, background)
end

function PANEL:GenerateWall()
	local wall = {}
	local y = math.random(Smartphone_DisplayH / 1.7,  Smartphone_DisplayH / 5)
	local goldChance = math.random(self.lastGold, 100)
	wall.pos = Vector(Smartphone_DisplayW, y, 0)
	wall.height = Smartphone_DisplayH / 1.4
	if (goldChance == 50 && self.lastGold > 5) then
		wall.color = HSVToColor(50, 1, 1)
		wall.score = 3
		self.lastGold = 0
	else
		wall.color = self.pipeColor
		wall.scored = false
		wall.score = 1
		self.lastGold = self.lastGold + 1
	end
	table.insert(self.walls, wall)
end

function PANEL:GenerateGround()
	// creates a new ground at the end of the older one
	local ground = {}
	local x = self.grounds[#self.grounds].pos.x + self:GetWide()
	ground.height = self.groundHeight
	ground.width = self:GetWide()
	ground.pos = Vector(x, self:GetTall() - ground.height, 0)
	table.insert(self.grounds, ground)
end

function PANEL:CalculateBirdAngle(time)
	local rotation = self.birdAngle
	if (self.birdVelocity.y > 2.5 || self.gameOver) then
		rotation = rotation - 350 * time
	else
		rotation = rotation + 1000 * time
	end
	self.birdAngle = math.Clamp(rotation, self.minBirdAng, self.maxBirdAng)
/*

	self.birdAngle = math.deg(-math.atan2(self.birdVelocity.y, self:calculateWallMove(time).x))
	print(self.birdAngle, self:calculateWallMove(time).x, self.birdVelocity.y)*/
end

function PANEL:Restart()
	if (!muted) then
		surface.PlaySound(swoosh)
	end
	self:Init()
end

function PANEL:calculateWallMove(time)
	return Vector(self.wallSpeed, 0, 0) * time
end

function PANEL:calculateBackgroundMove(time)
	return Vector(self.wallSpeed / 6, 0, 0) * time
end

function PANEL:calculateBirdMove(time)
	return self.gravity * time
end

function PANEL:calculateBirdJump(time)
	return -self.gravity * 0.4
end

function PANEL:Passed(wall)
	if (wall.pos.x + self.wallSize + self.birdWidth / 2 < self.birdPos.x) then
		return true
	end
	return false
end

function PANEL:BirdFlap()
	if (!self.upFlap && table.KeyFromValue(birdMats, self.currentBirdMat) == 3 + self.birdMatOffset) then
		self.upFlap = true
		self.currentBirdMat = birdMats[2 + self.birdMatOffset]
		return
	end
	if (self.upFlap && table.KeyFromValue(birdMats, self.currentBirdMat) == 1 + self.birdMatOffset) then
		self.upFlap = false
		self.currentBirdMat = birdMats[2 + self.birdMatOffset]
		return
	end
	if (!self.upFlap) then
		self.currentBirdMat = birdMats[3 + self.birdMatOffset]
	else
		self.currentBirdMat = birdMats[1 + self.birdMatOffset]
	end
end


function PANEL:Touched(wall)
	if (wall.pos.y - self.wallGap - (self.birdHeight / 6) > self.birdPos.y || wall.pos.y + self.wallGap - self.birdHeight + (self.birdHeight / 5) < self.birdPos.y) then
		if (self.birdPos.x + self.birdWidth / 2 - (self.birdWidth / 6) > wall.pos.x && self.birdPos.x + self.birdWidth / 2 < wall.pos.x + self.wallSize) then
			return true
		elseif (self.birdPos.x - self.birdWidth / 2 - (self.birdWidth / 6) > wall.pos.x && self.birdPos.x  - self.birdWidth / 2 + self.birdWidth / 5 < wall.pos.x + self.wallSize) then
			return true
		end
	end
	return false
end

local lasttime = nil
local lastgenerated = 0
local nextgenerated = 1.5
local idleFlap = 0.1
local flapGap = 0.05
local lastFlap = 0
local maxBirdBob = 1
local restartDelay = 0
function PANEL:Think()
	if (self:IsVisible()) then
		self:RequestFocus()
	end
	if (!lasttime) then
		lasttime = RealTime()
		lastgenerated = RealTime()
		return
	end
	local timepassed = RealTime() - lasttime
	// if not focused pauses movement
	if (self:GetParent().transitionMode || !self:IsVisible() || !self:HasHierarchicalFocus() || !vgui.CursorVisible) then
		lasttime = RealTime()
		lastgenerated = lastgenerated + timepassed
		return
	end
	local flapTime = RealTime() - lastFlap
	if (flapGap < flapTime && !self.gameOver && self.started && self.birdAngle > -10) then
		self:BirdFlap()
		lastFlap = RealTime()
	elseif (!self.started && idleFlap < flapTime) then
		self:BirdFlap()
		lastFlap = RealTime()
	elseif (flapGap < flapTime && !self.gameOver && self.started && self.birdAngle < -10) then
		self.currentBirdMat = birdMats[2 + self.birdMatOffset]
	end
	// checks if latest ground is almost off screen before creating a new one
	if (self.grounds[#self.grounds] && self.grounds[#self.grounds].pos.x < 0) then
		self:GenerateGround()
	end
	// checks if latest background is almost off screen before creating a new one
	if (self.backgrounds[#self.backgrounds] && self.backgrounds[#self.backgrounds].pos.x < -self:GetWide()) then
		self:GenerateBackground()
	end
	if (!self.started) then
		self.birdPos.y = self.birdPos.y + math.sin(CurTime() * 7) * (maxBirdBob / 2)
	end
	if (self.started) then
		self:CalculateBirdAngle(timepassed)
		self.birdVelocity.y = self.birdVelocity.y + self:calculateBirdMove(timepassed)
		self.birdPos.y = self.birdPos.y + self.birdVelocity.y * FrameTime() * 100
		if (self.birdPos.y > Smartphone_DisplayH - self.groundHeight - self.birdHeight) then
			self.birdPos.y = Smartphone_DisplayH - self.groundHeight - self.birdHeight
			self.birdVelocity.y = 0
			if (!self.gameOver) then
				if (!muted) then
					surface.PlaySound(hitSound)
				end
				restartDelay = RealTime() + .5
			end
			self.gameOver = true
			if (self.score > Leaderboard:GetLocalScore(Leaderboard.BIRD_UP, 1)) then
				self.newHigh = true
				Leaderboard:SetScore(Leaderboard.BIRD_UP, 1, self.score)
			end
		end
	end
	// if the game is not over, moves the background and walls
	if (!self.gameOver) then
		for k, v in pairs(self.grounds) do
			v.pos = v.pos - self:calculateWallMove(timepassed)
		end
		for k, v in pairs(self.backgrounds) do
			v.pos = v.pos - self:calculateBackgroundMove(timepassed)
		end
	end
	if (self.jump && !self.gameOver) then
		if (self.birdVelocity.y > 0) then
			self.birdVelocity.y = self.birdVelocity.y / 4 + self:calculateBirdJump(timepassed)
		else
			self.birdVelocity.y = self:calculateBirdJump(timepassed)
		end
		self.jump = false
		if (!muted) then
			surface.PlaySound(wingSound)
		end
	end
	for k, v in pairs(self.walls) do
		if (!self.gameOver && self.started) then
			v.pos = v.pos - self:calculateWallMove(timepassed)
		end
		if (v.pos.x < -self:GetWide()) then
			table.remove(self.walls, k)
			continue
		end
		if (!v.scored && self:Passed(v)) then
			v.scored = true
			self.score = self.score + v.score
			if (!muted) then
				surface.PlaySound(pointSound)
			end
		end
		if (!self.gameOver && self:Touched(v)) then
			self.birdVelocity.y = 7
			if (!muted) then
				surface.PlaySound(hitSound)
				surface.PlaySound(deathSound)
			end
			self.gameOver = true
			self.currentBirdMat = birdMats[4 + self.birdMatOffset]
			if (self.score > Leaderboard:GetLocalScore(Leaderboard.BIRD_UP, 1)) then
				self.newHigh = true
				Leaderboard:SetScore(Leaderboard.BIRD_UP, 1, self.score)
			end
			restartDelay = RealTime() + .5
		end
	end
	if (RealTime() - lastgenerated > nextgenerated && self.started && self.startTime &&  RealTime() - self.startTime > 2) then
		self:GenerateWall()
		lastgenerated = RealTime()
	end
	for k, v in pairs(self.grounds) do
		if (v.pos.x < -self:GetWide()) then
			table.remove(self.grounds, k)
			continue
		end
	end
	for k, v in pairs(self.backgrounds) do
		if (v.pos.x < -self.backgroundWidth) then
			table.remove(self.backgrounds, k)
			continue
		end
	end
	lasttime = RealTime()
end
local textWidth = 0
function PANEL:Paint()
	surface.SetTexture(-1)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(skyMats[self.skyMat])
	// using DrawTexturedRectRotated because the other one has texture flickers, thanks garry
	for k, v in pairs(self.backgrounds) do
		surface.DrawTexturedRectRotated(v.pos.x + self:GetWide(), self:GetTall() / 2, v.width, v.height, 0)
	end

	for k, v in pairs(self.walls) do
		surface.SetDrawColor(v.color)
		surface.SetMaterial(pipes[2])
		surface.DrawTexturedRectRotatedPoint(v.pos.x, v.pos.y - v.height - self.wallGap, self.wallSize, v.height, 0, -self.wallSize / 2, v.height / 2)
		surface.SetMaterial(pipes[1])
		surface.DrawTexturedRectRotatedPoint(v.pos.x, v.pos.y + self.wallGap, self.wallSize, v.height, 0, -self.wallSize / 2, v.height / 2)
	end
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(groundMat)
	for k, v in pairs(self.grounds) do
		surface.DrawTexturedRectRotated(v.pos.x + v.width / 2, self:GetTall() - v.height / 2, v.width, v.height, 0)
	end
	surface.SetMaterial(self.currentBirdMat)
	surface.DrawTexturedRectRotatedPoint(self.birdPos.x, self.birdPos.y + self.birdHeight / 2, self.birdWidth, self.birdHeight, self.birdAngle, 0, 0)
	if (muted) then
		surface.SetMaterial(soundIcon)
		surface.DrawTexturedRect(self:GetWide() - self:GetWide() * 0.15, self:GetTall() * 0.017, self:GetWide() / 10, self:GetWide() / 10)
		surface.SetMaterial(crossIcon)
		surface.DrawTexturedRect(self:GetWide() - self:GetWide() * 0.15, self:GetTall() * 0.02, self:GetWide() / 12, self:GetWide() / 12)
	end
	if (self.gameOver) then
		self:HandleGameOver()
	elseif (!self.started) then
		self:InitGame()
	else
		surface.SetFont("ScoreFont")
		surface.SetTextColor(255, 255, 255)
		textWidth = surface.GetTextSize(self.score) / 2
		surface.SetTextPos(self:GetWide() / 2 - textWidth, self:GetTall() * 0.1)
		if (self.score == 69) then
			surface.DrawText("nice")
		else
			surface.DrawText(self.score)
		end
	end
end

function PANEL:HandleGameOver()
	surface.SetDrawColor(0, 0, 0, 220)
	surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
	surface.SetDrawColor(255, 255, 255, self.flash)
	surface.DrawRect(0, 0, self:GetWide(), self:GetTall())
	self.flash = math.max(0, self.flash - 20)
	surface.SetTextColor(255, 255, 255)
	if (self.newHigh) then
		surface.SetFont("HighscoreCard")
		textWidth = surface.GetTextSize(TranslationSystem:Translate("UI.Smartphone.BirdUp.Highscore")) / 2
		surface.SetTextPos(self:GetWide() / 2 - textWidth, self:GetTall() * 0.1)
		surface.DrawText(TranslationSystem:Translate("UI.Smartphone.BirdUp.Highscore"))
	end
	surface.SetFont("ScoreFont")
	textWidth = surface.GetTextSize(TranslationSystem:Translate("UI.Smartphone.BirdUp.GameOver")) / 2
	surface.SetTextPos(self:GetWide() / 2 - textWidth, self:GetTall() * 0.18)
	surface.DrawText(TranslationSystem:Translate("UI.Smartphone.BirdUp.GameOver"))
	surface.SetFont("ScoreCard")
	local scoreCard = TranslationSystem:Translate("UI.Smartphone.BirdUp.EndScore", self.score)
	textWidth = surface.GetTextSize(scoreCard) / 2
	surface.SetTextPos(self:GetWide() / 2 - textWidth, self:GetTall() * 0.3)
	surface.DrawText(scoreCard)
	surface.SetFont("RetryGame")
	textWidth = surface.GetTextSize(TranslationSystem:Translate("UI.Smartphone.BirdUp.Restart")) / 2
	surface.SetTextPos(self:GetWide() / 2 - textWidth, self:GetTall() * 0.4)
	surface.DrawText(TranslationSystem:Translate("UI.Smartphone.BirdUp.Restart"))
end

function PANEL:InitGame()
	surface.SetFont("ScoreCard")
	surface.SetTextColor(255, 255, 255)
	textWidth = surface.GetTextSize(TranslationSystem:Translate("UI.Smartphone.BirdUp.Start")) / 2
	surface.SetTextPos(self:GetWide() / 2 - textWidth, self.birdPos.y - self:GetTall() * 0.3)
	surface.DrawText(TranslationSystem:Translate("UI.Smartphone.BirdUp.Start"))
	local highScore = Leaderboard:GetLocalScore(Leaderboard.BIRD_UP, 1)
	local scoreText = TranslationSystem:Translate("UI.Smartphone.BirdUp.StartHighscore", highScore)
	textWidth = surface.GetTextSize(scoreText) / 2
	surface.SetTextPos(self:GetWide() / 2 - textWidth, self.birdPos.y - self:GetTall() * 0.25)
	surface.DrawText(scoreText)
	surface.SetFont("RetryGame")
	textWidth = surface.GetTextSize(TranslationSystem:Translate("UI.Smartphone.BirdUp.Mute")) / 2
	surface.SetTextPos(self:GetWide() / 2 - textWidth, self.birdPos.y - self:GetTall() * 0.20)
	surface.DrawText(TranslationSystem:Translate("UI.Smartphone.BirdUp.Mute"))
end

function PANEL:Start()
	if (self.started) then return end
	self.started = true
	self.startTime = RealTime()
end

function PANEL:OnKeyCodePressed(code)
	if (restartDelay > RealTime()) then return end
	if (self.gameOver) then
		if (code == KEY_SPACE) then
			self:Restart()
		end
		return
	end
	// bird up
	if (code == KEY_SPACE && self.birdPos.y > 0) then
		self:Start()
		self.jump = true
	elseif (code == KEY_M) then
		muted = !muted
	elseif (self.birdPos.y < 0) then
		self.birdMatOffset = math.random(0, 2) * 4
	end
end


vgui.Register("SmartPhone_BirdUp", PANEL)