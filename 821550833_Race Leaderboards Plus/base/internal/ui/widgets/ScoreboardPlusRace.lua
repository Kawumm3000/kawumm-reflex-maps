--------------------------------------------------------------------------------
-- This is the original Reflex 0.47.5 Scoreboard widget, cloned and modified by Kawumm to add leaderboards for race mode
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"
require "LeaderboardHelpers"

ScoreboardPlusRace =
{
	canPosition = false,
	readyTimer = 0,
	leftScrollData = {},
	rightScrollData = {},
	lastSecondsGrown = 0,
};
registerWidget("ScoreboardPlusRace");

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local colScores = Color(190, 170, 170);
local colBackground = Color(0,0,0,160);
local colBorder = Color(150, 150, 150, 150);
local alphaFade = 150;
local padx = 15;

local weaponStatsOffsetX =
{
	["Weapon"] = 25,
	["Hit/Shots"] = 250,
	["DamageDone"] = 360,
	["Effectiveness"] = 455,
	["Kills"] = 540,
};

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SPARKS_MAX = 64;

local SparksEmitter =
{
	sparks = {},
	nextIn = 0,
};

-- init sparks table so we're not allocating later
for i = 0, SPARKS_MAX-1 do
	SparksEmitter.sparks[i] = {};
	SparksEmitter.sparks[i].t = 90000;
	SparksEmitter.sparks[i].x = 0;
	SparksEmitter.sparks[i].y = 0;
	SparksEmitter.sparks[i].r = 0;
	SparksEmitter.sparks[i].vx = 0;
	SparksEmitter.sparks[i].vy = 0;
	SparksEmitter.sparks[i].vr = 0;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function SparksEmitter:addSpark(x, y)
	-- add new spark
	self.sparks[self.nextIn].x = x;
	self.sparks[self.nextIn].y = y;
	self.sparks[self.nextIn].r = 0;
	self.sparks[self.nextIn].vx = math.random(-50, -30);
	self.sparks[self.nextIn].vy = math.random(-40, 40);
	self.sparks[self.nextIn].vr = math.random(-2, 2);
	self.sparks[self.nextIn].t = 0;
	self.nextIn = (self.nextIn + 1) % SPARKS_MAX;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function SparksEmitter:update(dt)
	for i = 0, SPARKS_MAX-1 do
		--self.sparks[i].vy = self.sparks[i].vy + 600 * dt; -- grav
		self.sparks[i].x = self.sparks[i].x + self.sparks[i].vx * dt;
		self.sparks[i].y = self.sparks[i].y + self.sparks[i].vy * dt;
		self.sparks[i].r = self.sparks[i].r + self.sparks[i].vr * dt;
		self.sparks[i].t = self.sparks[i].t + dt;
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function SparksEmitter:draw(dt)
	local c = {};
	local lifeTime = .7;

	for i = 0, SPARKS_MAX-1 do
		local s = self.sparks[i];
		local life = s.t / lifeTime;	-- life goes 0->1 (this it's dead)
		if life < 1 then
			c.r = lerp(238, 232, life);
			c.g = lerp(185, 23, life);
			c.b = lerp(87, 32, life);
			c.a = lerp(255, 0, life);

			local scale = math.min(c.a / 256, (255 - c.a) / 4);
		
			nvgSave();
				nvgTranslate(s.x, s.y);
				nvgScale(scale, scale);
				nvgRotate(s.r);
				nvgBeginPath();
				nvgRoundedRect(-2, -2, 4, 4, 1);
				nvgFillColor(c);
				nvgFill();
			nvgRestore();
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local EXPLOSION_MAX = 256;

local ExplosionEmitter =
{
	Explosion = {},
	nextIn = 0,
};

-- init Explosion table so we're not allocating later
for i = 0, EXPLOSION_MAX-1 do
	ExplosionEmitter.Explosion[i] = {};
	ExplosionEmitter.Explosion[i].t = 90000;
	ExplosionEmitter.Explosion[i].x = 0;
	ExplosionEmitter.Explosion[i].y = 0;
	ExplosionEmitter.Explosion[i].r = 0;
	ExplosionEmitter.Explosion[i].vx = 0;
	ExplosionEmitter.Explosion[i].vy = 0;
	ExplosionEmitter.Explosion[i].vr = 0;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ExplosionEmitter:addSpark(x, y)
	-- add new spark
	self.Explosion[self.nextIn].x = x;
	self.Explosion[self.nextIn].y = y;
	self.Explosion[self.nextIn].r = 0;
	self.Explosion[self.nextIn].vx = math.random(-50, 50);
	self.Explosion[self.nextIn].vy = math.random(-100, -40);
	self.Explosion[self.nextIn].vr = math.random(-2, 2);
	self.Explosion[self.nextIn].t = math.random(0, .5);
	self.nextIn = (self.nextIn + 1) % EXPLOSION_MAX;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ExplosionEmitter:update(dt)
	for i = 0, EXPLOSION_MAX-1 do
		self.Explosion[i].vy = self.Explosion[i].vy + 100 * dt; -- grav
		self.Explosion[i].x = self.Explosion[i].x + self.Explosion[i].vx * dt;
		self.Explosion[i].y = self.Explosion[i].y + self.Explosion[i].vy * dt;
		self.Explosion[i].r = self.Explosion[i].r + self.Explosion[i].vr * dt;
		self.Explosion[i].t = self.Explosion[i].t + dt;
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ExplosionEmitter:draw(dt)
	local c = {};
	local lifeTime = 3;

	for i = 0, EXPLOSION_MAX-1 do
		local s = self.Explosion[i];
		local life = s.t / lifeTime;	-- life goes 0->1 (this it's dead)
		if life < 1 then
			c.r = lerp(255, 232, life);
			c.g = lerp(185, 23, life);
			c.b = lerp(127, 32, life);
			c.a = lerp(255, 0, life);

			local scale = math.min(c.a / 256, (255 - c.a) / 4);
		
			nvgSave();
				nvgTranslate(s.x, s.y);
				nvgScale(scale, scale);
				nvgRotate(s.r);
				nvgBeginPath();
				nvgRoundedRect(-2, -2, 4, 4, 1);
				nvgFillColor(c);
				nvgFill();
			nvgRestore();
		end
	end
end

--------------------------------------------------------------------------------
-- note: this is "effectiveness", not just accuracy. It's working out how much damage we've done.
-- and takes splash etc into account, so a splash hit rocket of 50 damage will be 50% effectiveness
--------------------------------------------------------------------------------
local function CalculateEffectiveness(weapon, weaponStats)
	local totalDamagePossible = weaponStats.shotsFired * weapon.damagePerPellet;
	local totalDamageDone = weaponStats.damageDone;
	local effectiveness = totalDamageDone > 0 and (totalDamageDone / totalDamagePossible) * 100 or 0;
	return effectiveness;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local GROW_TIME_START = 2;
local GROW_TIME_LEN = 15;
local function GetSecondsGrown()
	local s = math.max((world.gameTime / 1000) - GROW_TIME_START, 0);
	return s;
end
	
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function DrawExperienceBar(ix, iy, iw, ih, experienceBase, experienceGain, experience, optargs)
	local optargs = optargs or {};
	local intensity = optargs.intensity or 1;
	local experienceVars = GetExperienceVars(experience);
	local experienceBaseVars = GetExperienceVars(experienceBase);

	-- slot
	nvgBeginPath();
	nvgRoundedRect(ix, iy, iw, ih, 2);
	nvgFillColor(Color(0, 0, 0, 255*intensity));
	nvgFill();

	if not serverConnectedToSteam then
		-- grey it all out, not on steam
		nvgBeginPath();
		nvgRoundedRect(ix, iy, iw, ih, 2);
		nvgFillColor(Color(42, 42, 42, 255*intensity));
		nvgFill();
	else
		-- base experience
		if experienceBaseVars.level == experienceVars.level then
			nvgBeginPath();
			nvgRoundedRect(ix, iy, iw*experienceBaseVars.percentageCompletedLevel, ih, 2);
			nvgFillColor(Color(232, 32, 32, 255*intensity));
			nvgFill();
		end

		-- earned experience
		local startx = ix + iw*experienceBaseVars.percentageCompletedLevel;
		if experienceBaseVars.level ~= experienceVars.level then
			startx = ix;
		end
		local endx = ix + iw*experienceVars.percentageCompletedLevel;
		if endx > startx + 3 then
			startx = math.max(startx - 5, ix); -- bit of overlap to keep it nice
			nvgBeginPath();
			nvgRect(startx, iy, 3, ih, 2);	-- flat left edge
			nvgRoundedRect(startx, iy, endx - startx, ih, 2);
			nvgFillColor(Color(238, 185, 87, 255*intensity));
			nvgFill();
		end
			
		-- sparks while earning
		if experience ~= experienceBase and experience ~= experienceBase + experienceGain then
			if ScoreboardPlusRace.sparkFrame then
				SparksEmitter:addSpark(ix + iw*experienceVars.percentageCompletedLevel, iy+ih/2);
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ProcessExperience(experienceBase, experienceGain)

	local didLevelUp = false;
	local experience = experienceBase;

	-- show experience gain in post-game screen
	if world.gameState == GAME_STATE_GAMEOVER then
		local secondsGrown = GetSecondsGrown();
		
		local growSpeed = 200;									-- ie 200 experience per second
		local growSpeedNeeded = experienceGain / GROW_TIME_LEN;	-- how fast we must go to finish the experience growth in 15 seconds
		growSpeed = math.max(growSpeed, growSpeedNeeded);		-- ensure we will reach what the player received

		-- apply the growth!
		experience = math.min(experienceBase + growSpeed * secondsGrown, experienceBase + experienceGain);
		local experienceVars = GetExperienceVars(experience);

		-- did we level up?
		local lastExperience = experienceBase + growSpeed * ScoreboardPlusRace.lastSecondsGrown;
		local lastExperienceVars = GetExperienceVars(lastExperience);
		if lastExperienceVars.level ~= experienceVars.level and lastExperience < experienceBase + experienceGain then
			didLevelUp = true;
			playSound("internal/ui/sounds/levelUp");
		end
	end

	return experience, didLevelUp;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function sortByScore(a, b)
	-- sort by state first, so we get editor/specs at bottom
	if a.state ~= b.state then

		-- we want:
		-- ingame
		-- queued
		-- spec
		-- editor
		-- (so pull queued up just under ingame)
		local astate = a.state;
		local bstate = b.state;
		if astate == PLAYER_STATE_QUEUED then astate = PLAYER_STATE_INGAME + .1 end;
		if bstate == PLAYER_STATE_QUEUED then bstate = PLAYER_STATE_INGAME + .1 end;

		return astate < bstate;
	end

	-- sort by score next
	if a.score ~= b.score then
		return a.score > b.score;
	end

	-- otherwise, sort by name (so we don't get random sorting if two players have same score)
	return a.name < b.name;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function sortForRaceMode(a, b)
	-- sort by state first, so we get editor/specs at bottom
	if a.state ~= b.state then
		return a.state < b.state;
	end

	-- 0 (not finish) we want at bottom
	local ascore = a.score;
	local bscore = b.score;
	if ascore == 0 then ascore = 1000000000; end
	if bscore == 0 then bscore = 1000000000; end

	-- sort by score next
	-- (LOWER IS BETTER)
	if ascore ~= bscore then
		return ascore < bscore;
	end

	-- otherwise, sort by name (so we don't get random sorting if two players have same score)
	return a.name < b.name;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function sortForQueuePosition(a, b)
	-- sort by queue position, they can't be the same (assuming the players are actually in the queue)
	if a.queuePosition ~= b.queuePosition then
		return a.queuePosition < b.queuePosition;
	end

	-- otherwise, sort by name (so we don't get random sorting if two players have same score)
	return a.name < b.name;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function sortForName(a, b)
	return a.name < b.name;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function drawTinyStat(title, value, x, y, w, isNotZero, isRight)
	nvgSave();

	isRight = false;

	nvgTextAlign(isRight == true and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontBlur(0);
	nvgFontSize(32);
	
	nvgFontFace("TitilliumWeb-Regular");
	nvgFillColor(Color(170,170,170));
	nvgText(isRight and x+w-padx or x+padx, y, title);

	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(Color(232,232,232, isNotZero and 255 or alphaFade));
	nvgText(isRight and x+w-padx-200 or x+padx+200, y, value);

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function drawTinyStatComma(title, value, valueOther, x, y, w, isRight)
	nvgSave();

	isRight = false;

	local bright = value > valueOther;
	local valueFormatted = value > 0 and CommaValue(value) or "-";
	
	nvgTextAlign(isRight == true and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontBlur(0);
	nvgFontSize(32);
	
	nvgFontFace("TitilliumWeb-Regular");
	nvgFillColor(Color(170,170,170));
	nvgText(isRight and x+w-padx or x+padx, y, title);

	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(Color(232,232,232, bright and 255 or alphaFade));
	nvgText(isRight and x+w-padx-200 or x+padx+200, y, valueFormatted);

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function drawTakenStat(icon, iconColor, value, valueOtherPlayer, x, y)
	-- don't print empty stats
	if value == 0 then return 0 end;

	nvgSave();

	local bright = value > valueOtherPlayer;
	local ic = Color(iconColor.r, iconColor.g, iconColor.b, bright and 255 or alphaFade);
	local ox = 8;

	nvgFillColor(ic);
	nvgSvg(icon, x+ox, y, 8);
	ox = ox + 12;

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontBlur(0);
	nvgFontSize(32);
	
	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(Color(232,232,232, bright and 255 or 130));
	nvgText(x+ox, y, value);

	ox = ox + nvgTextWidth(value);

	-- post padding
	ox = ox + 10;

	nvgRestore();

	return ox;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function drawPowerupStat(icon, iconColor, value, valueOtherPlayer, x, y)
	-- don't print empty stats
	if value == 0 then return 0 end;

	nvgSave();

	local bright = value > valueOtherPlayer;
	local ic = Color(iconColor.r, iconColor.g, iconColor.b, bright and 255 or alphaFade);
	local ox = 8;

	nvgFillColor(ic);
	nvgSvg(icon, x+ox, y, 8);
	ox = ox + 12;

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontBlur(0);
	nvgFontSize(32);
	
	local text = string.format("%.1f", value);
	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(Color(232,232,232, bright and 255 or 130));
	nvgText(x+ox, y, text);

	ox = ox + nvgTextWidth(text);

	-- post padding
	ox = ox + 10;

	nvgRestore();

	return ox;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function drawWeaponStats(player, weapon, weaponStats, weaponIndex, x, y, weaponStatsOther)
	local iy = y;

	nvgSave();
	
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace("titilliumWeb-Regular");
	nvgFontBlur(0);
	nvgFontSize(32);
	
	-- icon
	local ix = x + weaponStatsOffsetX["Weapon"];
	local svgName = "internal/ui/icons/weapon"..weaponIndex;
	if (weaponIndex == 1) and (player.inventoryMelee ~= nil) then
		local def = inventoryDefinitions[player.inventoryMelee];
		if def ~= nil then
			svgName = def.asset;
		end
	end
	local iconColor = Color(
		weapon.color.r,
		weapon.color.g,
		weapon.color.b,
		alphaFade);
	nvgFillColor(iconColor);
	nvgSvg(svgName, ix, iy, 8);
	nvgFillColor(Color(170,170,170));
	nvgText(x + padx + 25, iy, weapon.name);
	
	nvgFontFace("titilliumWeb-Bold");

	-- hits/shots
	local brightHit = ((weaponStatsOther ~= nil) and (weaponStats.shotsHit > weaponStatsOther.shotsHit)) or ((weaponStatsOther == nil) and (weaponStats.shotsHit > 0));
	local brightFired = ((weaponStatsOther ~= nil) and (weaponStats.shotsFired > weaponStatsOther.shotsFired)) or ((weaponStatsOther == nil) and (weaponStats.shotsFired > 0));
	ix = x + weaponStatsOffsetX["Hit/Shots"];
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	nvgFillColor(Color(232,232,232, brightHit and 255 or alphaFade));
	nvgText(ix - 4, iy, weaponStats.shotsHit);
	
	nvgFillColor(Color(232,232,232, (brightHit and brightFired) and 255 or alphaFade));
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgText(ix, iy, "/");
	
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFillColor(Color(232,232,232, brightFired and 255 or alphaFade));
	nvgText(ix + 4, iy, weaponStats.shotsFired);

	-- damage done
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	local bright = ((weaponStatsOther == nil) and (weaponStats.damageDone > 0)) or ((weaponStatsOther ~= nil) and (weaponStats.damageDone > weaponStatsOther.damageDone));
	ix = x + weaponStatsOffsetX["DamageDone"];
	nvgFillColor(Color(232,232,232, bright and 255 or alphaFade));
	nvgText(ix, iy, CommaValue(weaponStats.damageDone));

	--
	local effectiveness = CalculateEffectiveness(weapon, weaponStats);
	local text = "-";
	local bright = false;
	if weaponStats.shotsFired > 0 then
		bright = (weaponStatsOther == nil) or weaponStatsOther.shotsFired == 0 or (effectiveness > CalculateEffectiveness(weapon, weaponStatsOther));
		text = string.format("%.0f%%", effectiveness);
	end
	ix = x + weaponStatsOffsetX["Effectiveness"];
	nvgFillColor(Color(232,232,232, bright and 255 or alphaFade));
	nvgText(ix, iy, text);
	if text ~= "-" and weaponStatsOther ~= nil then
		nvgFillColor(bright and Color(100,255,100) or Color(255,100,100));
		nvgSvg(bright and "internal/ui/icons/upArrow" or "internal/ui/icons/comboBoxArrow", ix + nvgTextWidth(text)/2+12, iy, 6);		
	end

	-- kills
	local bright = false;
	local text = "-";
	if weaponStats.kills > 0 then
		bright = (weaponStatsOther == nil) or (weaponStats.kills > weaponStatsOther.kills);
		text = weaponStats.kills;
	end
	ix = x + weaponStatsOffsetX["Kills"];
	nvgFillColor(Color(232,232,232, bright and 255 or alphaFade));
	nvgText(ix, iy, text);

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function drawWeaponStatsTitle(x, y, w, isRight)
	local iy = y;

	nvgSave();

	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgFontFace("TitilliumWeb-Regular");
	nvgFillColor(Color(130,130,130));
	nvgFontBlur(0);
	nvgFontSize(24);
	
	-- icon
	local ix = x + padx;
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(ix, iy, "WEAPON");
	
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);

	-- hits/shots
	ix = x + weaponStatsOffsetX["Hit/Shots"];
	nvgText(ix, iy, "H/S");

	-- damage done
	ix = x + weaponStatsOffsetX["DamageDone"];
	nvgText(ix, iy, "DAMAGE");

	-- effective %
	ix = x + weaponStatsOffsetX["Effectiveness"];
	nvgText(ix, iy, "EFF");

	-- kills
	ix = x + weaponStatsOffsetX["Kills"];
	nvgText(ix, iy, "KILLS");

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:initialize()
	widgetCreateConsoleVariable("leaderboard", "string", "friends");
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:finalize()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawStats(x, y, w, isRight, stats, otherStats)
	local h = 368;
	local iy = y + 24;
	
	drawTinyStatComma("Damage Done", stats.totalDamageDone, otherPlayer and otherStats.totalDamageDone or 0, x, iy, w, isRight);
	iy = iy + 24;
	drawTinyStatComma("Damage Received", stats.totalDamageReceived, otherPlayer and otherStats.totalDamageReceived or 0, x, iy, w, isRight);
	iy = iy + 24;
	drawTinyStatComma("Distance Travelled", stats.distanceTravelled, otherPlayer and otherStats.distanceTravelled or 0, x, iy, w, isRight);
	iy = iy + 24;
	
	-- powerup control
	local gotPowerup = stats.secondsHeldCarnage > 0 or stats.secondsHeldResist > 0;
	drawTinyStat("Powerups Held (s)", gotPowerup and "" or "-", x, iy, w, false, isRight);
	local ix = x + padx+ 200;
	ix = ix + drawPowerupStat("internal/ui/icons/carnage", Color(255,120,128), stats.secondsHeldCarnage, otherPlayer and otherStats.secondsHeldCarnage or 0, ix, iy);
	ix = ix + drawPowerupStat("internal/ui/icons/resist", Color(255,120,128), stats.secondsHeldResist, otherPlayer and otherStats.secondsHeldResist or 0, ix, iy);
	iy = iy + 24;
		
	-- item control
	local gotItem = stats.takenRA > 0 or stats.takenYA > 0 or stats.takenGA > 0 or stats.takenMega > 0;
	drawTinyStat("Item Control", gotItem and "" or "-", x, iy, w, false, isRight);
	local ix = x + padx+ 200;
	ix = ix + drawTakenStat("internal/ui/icons/armor", Color(255,0,0), stats.takenRA, otherPlayer and otherStats.takenRA or 0, ix, iy);
	ix = ix + drawTakenStat("internal/ui/icons/armor", Color(255,255,0), stats.takenYA, otherPlayer and otherStats.takenYA or 0, ix, iy);
	ix = ix + drawTakenStat("internal/ui/icons/armor", Color(0,255,0), stats.takenGA, otherPlayer and otherStats.takenGA or 0, ix, iy);
	ix = ix + drawTakenStat("internal/ui/icons/health", Color(60,80,255), stats.takenMega, otherPlayer and otherStats.takenMega or 0, ix, iy);
	iy = iy + 24;

	iy = iy + 26;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawTrainingStats(x, y, w, isRight, player, isPlaying)
	local isTraining = player.state == PLAYER_STATE_INGAME;
	local h = 368;
	local iy = y + 24;

	-- gather tokens
	local tokens = {};
	local tokensAchieved = 0;
	if isTraining then
		for k, pickup in pairs(pickupTimers) do
			if pickup.type == PICKUP_TYPE_TRAINING_TOKEN then
				tokens[pickup.tokenIndex] = {};
				tokens[pickup.tokenIndex].achieved = not pickup.isActive;
				if tokens[pickup.tokenIndex].achieved then
					tokensAchieved = tokensAchieved + 1;
				end
			end
		end
	end

	-- count tokens
	-- (we do this separately to gather tokens to ensure tokens with same tokenIndex ARE ignored - as that's how the leaderboard recording will work - and this will help visualise to the user there is a problem)
	local tokensTotal = 0;
	for k, v in pairs(tokens) do
		tokensTotal = tokensTotal + 1;
	end
	
	-- tokens
	drawTinyStat("Tokens", "", x, iy, w, isPlaying, isRight);
	local ir = 12;
	local istride = 32;
	local ix = x + 200 + padx + ir;
	for k, token in pairs(tokens) do
		local achieved = token.achieved;
		nvgFillColor(achieved and Color(232,232,232,255) or Color(70,70,70,255));
		nvgSvg("internal/items/training_token/training_token", ix, iy, ir);
		ix = ix + istride;
	end
	iy = iy + 24;
	
	-- goals
	local goalText = "-";
	local goalsDone = 0;
	local goalCount = 0;
	if isTraining then
		for k, v in pairs(goals) do
			if v.achieved then goalsDone = goalsDone + 1 end;
			goalCount = goalCount + 1;
		end
		goalText = goalsDone .. " / " .. goalCount;
	end
	drawTinyStat("Goals", goalText, x, iy, w, isTraining, isRight);
	iy = iy + 24;

	-- look up leaderboard entry for this player
	local entry = nil;
	local leaderboard = QuerySelfLeaderboard(world.mapName, "training");
	if leaderboard ~= nil then
		entry = leaderboard.friendsEntries[player.steamId];
	end
	
	-- best time
	local hasBestTime = false;
	local text = "none qualified";
	if entry ~= nil and entry.timeMillis > 0 then
		text = FormatTimeToDecimalTime(entry.timeMillis);
		hasBestTime = true;
	end
	drawTinyStat("Best Time", text, x, iy, w, hasBestTime, isRight);
	iy = iy + 24;

	-- current time
	local currentRaceTime = "-";
	if isTraining then
		currentRaceTime = 0;
		if player.raceActive then
			currentRaceTime = player.raceTimeCurrent;
		end
		if world.gameState == GAME_STATE_GAMEOVER then
			currentRaceTime = player.raceResults[1].time;
		end
		currentRaceTime = FormatTimeToDecimalTime(currentRaceTime);
	end
	drawTinyStat("Current Time", currentRaceTime, x, iy, w, isTraining, isRight);

	-- -- tick if we got all tokens
	-- if isTraining and tokensTotal > 0 and tokensAchieved >= tokensTotal then
	-- 	local intensity = 1;
	-- 	local hoverAmont = 0;
	-- 	local enabled = true;
	-- 	
	-- 	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREEN, intensity, hoverAmont, enabled));
	-- 	nvgSvg("internal/ui/icons/tick", x + 364, iy, 10);
	-- 
	-- 	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	-- 	nvgFontBlur(0);
	-- 	nvgFontSize(32);
	-- 
	-- 	nvgFontFace("TitilliumWeb-Regular");
	-- 	--nvgFillColor(Color(232,232,232, 255));
	-- 	nvgText(x + 380, iy, "all tokens collected");
	-- end
	-- inform player when they've qualified
	if true then--world.gameState == GAME_STATE_GAMEOVER then
		if (tokensAchieved >= tokensTotal) and (goalsDone >= goalCount) then
			local intensity = 1;
			local hoverAmont = 0;
			local enabled = true;
			
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREEN, intensity, hoverAmont, enabled));
			nvgSvg("internal/ui/icons/tick", x + 364, iy, 10);
			
			nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
			nvgFontBlur(0);
			nvgFontSize(32);
			
			nvgFontFace("TitilliumWeb-Regular");
			--nvgFillColor(Color(232,232,232, 255));
			nvgText(x + 380, iy, "qualified");
		end
	end
	iy = iy + 24;

	-- if true then--world.gameState == GAME_STATE_GAMEOVER then
	-- 	if (tokensAchieved < tokensTotal) or (goalsDone < goalCount) then
	-- 		local intensity = 1;
	-- 		local hoverAmont = 0;
	-- 		local enabled = true;
	-- 	
	-- 		nvgFillColor(ui2FormatColor(UI2_COLTYPE_FAVORITE, intensity, hoverAmont, enabled));
	-- 		nvgSvg("internal/ui/icons/skull", x + 230, iy, 10);
	-- 
	-- 		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	-- 		nvgFontBlur(0);
	-- 		nvgFontSize(28);
	-- 
	-- 		nvgFontFace("TitilliumWeb-Regular");
	-- 		--nvgFillColor(Color(232,232,232, 255));
	-- 		nvgText(x + 250, iy, "collect all tokens and goals to quality");
	-- 	end
	-- end
end

--edited by Kawumm
function ScoreboardPlusRace:drawRaceStats(x, y, w, isRight, player, isPlaying)
	local isTraining = player.state == PLAYER_STATE_INGAME;
	local h = 368;
	local iy = y + 24;

	-- gather tokens
	local tokens = {};
	local tokensAchieved = 0;
	if isTraining then
		for k, pickup in pairs(pickupTimers) do
			if pickup.type == PICKUP_TYPE_TRAINING_TOKEN then
				tokens[pickup.tokenIndex] = {};
				tokens[pickup.tokenIndex].achieved = not pickup.isActive;
				if tokens[pickup.tokenIndex].achieved then
					tokensAchieved = tokensAchieved + 1;
				end
			end
		end
	end

	-- count tokens
	-- (we do this separately to gather tokens to ensure tokens with same tokenIndex ARE ignored - as that's how the leaderboard recording will work - and this will help visualise to the user there is a problem)
	local tokensTotal = 0;
	for k, v in pairs(tokens) do
		tokensTotal = tokensTotal + 1;
	end
	
	-- tokens
	drawTinyStat("Tokens", "", x, iy, w, isPlaying, isRight);
	local ir = 12;
	local istride = 32;
	local ix = x + 200 + padx + ir;
	for k, token in pairs(tokens) do
		local achieved = token.achieved;
		nvgFillColor(achieved and Color(232,232,232,255) or Color(70,70,70,255));
		nvgSvg("internal/items/training_token/training_token", ix, iy, ir);
		ix = ix + istride;
	end
	iy = iy + 24;
	
	-- goals
	local goalText = "-";
	local goalsDone = 0;
	local goalCount = 0;
	if isTraining then
		for k, v in pairs(goals) do
			if v.achieved then goalsDone = goalsDone + 1 end;
			goalCount = goalCount + 1;
		end
		goalText = goalsDone .. " / " .. goalCount;
	end
	drawTinyStat("Goals", goalText, x, iy, w, isTraining, isRight);
	iy = iy + 24;

	-- look up leaderboard entry for this player
	local entry = nil;
	local leaderboard = QuerySelfLeaderboard(world.mapName, "race");
	if leaderboard ~= nil then
		entry = leaderboard.friendsEntries[player.steamId];
	end
	
	-- best time
	local hasBestTime = false;
	local text = "none qualified";
	if entry ~= nil and entry.timeMillis > 0 then
		text = FormatTimeToDecimalTime(entry.timeMillis);
		hasBestTime = true;
	end
	drawTinyStat("Best Time", text, x, iy, w, hasBestTime, isRight);
	iy = iy + 24;

	-- current time
	local currentRaceTime = "-";
	if isTraining then
		currentRaceTime = 0;
		if player.raceActive then
			currentRaceTime = player.raceTimeCurrent;
		end
		if world.gameState == GAME_STATE_GAMEOVER then
			currentRaceTime = player.raceResults[1].time;
		end
		currentRaceTime = FormatTimeToDecimalTime(currentRaceTime);
	end
	drawTinyStat("Current Time", currentRaceTime, x, iy, w, isTraining, isRight);

	-- -- tick if we got all tokens
	-- if isTraining and tokensTotal > 0 and tokensAchieved >= tokensTotal then
	-- 	local intensity = 1;
	-- 	local hoverAmont = 0;
	-- 	local enabled = true;
	-- 	
	-- 	nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREEN, intensity, hoverAmont, enabled));
	-- 	nvgSvg("internal/ui/icons/tick", x + 364, iy, 10);
	-- 
	-- 	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	-- 	nvgFontBlur(0);
	-- 	nvgFontSize(32);
	-- 
	-- 	nvgFontFace("TitilliumWeb-Regular");
	-- 	--nvgFillColor(Color(232,232,232, 255));
	-- 	nvgText(x + 380, iy, "all tokens collected");
	-- end
	-- inform player when they've qualified
	if true then--world.gameState == GAME_STATE_GAMEOVER then
		if (tokensAchieved >= tokensTotal) and (goalsDone >= goalCount) then
			local intensity = 1;
			local hoverAmont = 0;
			local enabled = true;
			
			nvgFillColor(ui2FormatColor(UI2_COLTYPE_TEXT_GREEN, intensity, hoverAmont, enabled));
			nvgSvg("internal/ui/icons/tick", x + 364, iy, 10);
			
			nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
			nvgFontBlur(0);
			nvgFontSize(32);
			
			nvgFontFace("TitilliumWeb-Regular");
			--nvgFillColor(Color(232,232,232, 255));
			nvgText(x + 380, iy, "qualified");
		end
	end
	iy = iy + 24;

	-- if true then--world.gameState == GAME_STATE_GAMEOVER then
	-- 	if (tokensAchieved < tokensTotal) or (goalsDone < goalCount) then
	-- 		local intensity = 1;
	-- 		local hoverAmont = 0;
	-- 		local enabled = true;
	-- 	
	-- 		nvgFillColor(ui2FormatColor(UI2_COLTYPE_FAVORITE, intensity, hoverAmont, enabled));
	-- 		nvgSvg("internal/ui/icons/skull", x + 230, iy, 10);
	-- 
	-- 		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	-- 		nvgFontBlur(0);
	-- 		nvgFontSize(28);
	-- 
	-- 		nvgFontFace("TitilliumWeb-Regular");
	-- 		--nvgFillColor(Color(232,232,232, 255));
	-- 		nvgText(x + 250, iy, "collect all tokens and goals to quality");
	-- 	end
	-- end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawBreakdown(player, otherPlayer, x, y, w, isRight)
	local h = 368;
	local iy = y + 24;

	-- powerups & item control
	self:drawStats(x, y, w, isRight, player.stats, otherPlayer ~= nil and otherPlayer.stats or nil);
	iy = iy + 146;
	
	-- weapon stats title
	drawWeaponStatsTitle(x, iy, w, isRight);
	iy = iy + 22;

	-- weapon stats
	for weaponIndex, weaponDef in ipairs(weaponDefinitions) do
		local weaponStats = player.weaponStats[weaponIndex];
		local weapon = player.weapons[weaponIndex];

		-- hacks for stake launcher experimental tests..
		local show = true;
		if weaponDef.name == "Bolt Rifle" and world.ruleset == "experimental_stake" then
			show = false;
		end

		if show then
			local weaponStatsOther = otherPlayer ~= nil and otherPlayer.weaponStats[weaponIndex] or nil;
			drawWeaponStats(player, weapon, weaponStats, weaponIndex, x, iy, weaponStatsOther);
			iy = iy + 24;
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawTrainingBreakdown(player, otherPlayer, x, y, w, isRight)
	local h = 368;
	local iy = y + 24;
	local optargs = {};
	optargs.nofont = true;

	nvgSave();

	-- powerups & item control
	local playerCameraAttachedTo = getPlayer();
	local isPlaying = player == playerCameraAttachedTo;
	self:drawTrainingStats(x, y, w, isRight, player, isPlaying);
	iy = iy + 120;

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace("TitilliumWeb-Regular");
	nvgFontBlur(0);

	-- leaderboard title
	nvgFillColor(Color(130,130,130));
	nvgFontSize(24);
	nvgText(x + padx, iy, "LEADERBOARDS");	
	
	-- leaderboard type
	local leaderboardType = widgetGetConsoleVariable("leaderboard");
	if leaderboardType ~= "friends" and leaderboardType ~= "global" and leaderboardType ~= "top" then
		leaderboardType = "friends"
	end
	local leaderboards =
	{
		"FRIENDS",
		"GLOBAL",
		"TOP"
	};
	local leaderboardTypeNew = string.lower(ui2Spinner(leaderboards, string.upper(leaderboardType), x + padx + 170, iy-20, 150, optargs));
	if leaderboardTypeNew ~= leaderboardType then
		widgetSetConsoleVariable("leaderboard", leaderboardTypeNew);
	end
	iy = iy + 26;

	local leadboard, entries, entryCount, useGlobalRank;
	if leaderboardType == "friends" then
		leaderboard = QueryFriendsLeaderboard(world.mapName, "training");
		entries, entryCount = ExtractFriendsLeaderboardEntries(leaderboard);
		useGlobalRank = false;
	elseif leaderboardType == "top" then
		leaderboard = QueryGlobalLeaderboard(world.mapName, "training", "toponly");
		entries, entryCount = ExtractGlobalLeaderboardEntries(leaderboard);
		useGlobalRank = true;
	else
		leaderboard = QueryGlobalLeaderboard(world.mapName, "training");
		entries, entryCount = ExtractGlobalLeaderboardEntries(leaderboard);
		useGlobalRank = true;
	end

	-- find our rank
	local myRank = 1;
	for i = 1, entryCount do
		if entries[i].steamId == steamId then
			myRank = i;
		end
	end

	-- find range
	local startRank = math.max(myRank - 3, 1);
	local endRank = math.min(myRank + 3, entryCount);
	startRank = math.max(endRank - 6, 1);
	endRank = math.min(startRank + 6, entryCount);

	-- determine rank width do we scale well (to big rank numbers :))
	local rankWidth = 0;
	if entryCount > 0 then 
		local entry = entries[endRank];
		local rank = useGlobalRank and entry.globalRank or endRank;
		rankWidth = string.len(rank) * 16;
		rankWidth = math.max(rankWidth, 32);
	end
	
	-- print entries
	nvgFontSize(32);
	for rank = startRank, endRank do
		local entry = entries[rank];
		local old = entry.old;

		local col = Color(170,170,170);
		if entry.steamId == steamId then
			nvgFontFace("TitilliumWeb-Bold");
		else
			nvgFontFace("TitilliumWeb-Regular");
		end

		-- rank
		local ix = x + padx;
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
		nvgFillColor(col);
		nvgText(ix + rankWidth/2, iy, useGlobalRank and entry.globalRank or rank);
		ix = ix + rankWidth;

		-- avatar
		local ih = 20;
		ix = ix + 10;
		nvgBeginPath();
		nvgRoundedRect(ix, iy-9, ih, ih, 4);
		nvgFillColor(Color(230,220,240));
		nvgFillImagePattern("$avatarSmall_"..entry.steamId, ix, iy-9, ih, ih);
		nvgFill();
		ix = ix + ih + 8;
		
		-- name
		local name = steamFriends[entry.steamId].personaName;
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgFillColor(col);
		nvgText(ix, iy, name);
			
		-- time
		local text = FormatTimeToDecimalTime(entry.timeMillis);
		if old then
			nvgFillColor(UI2_COLTYPE_FAVORITE.base);
		end
		nvgText(x + padx + 325, iy, text);

		if old then
			if entry.mapHash ~= leaderboard.mapHash then
				local optargs = {};
				optargs.optionalId = i;
				ui2TooltipBox("This result was obtained on an older version", x + padx + 415, iy-16, 250, optargs);
			end
		end

		iy = iy + 24;
	end
		
	nvgRestore();
end

-- edited by kawumm
function ScoreboardPlusRace:drawRaceLeaderboard(x, y, w, h, player, isRight)
	local iy = y + 24;
	local optargs = {};
	optargs.nofont = true;

	nvgSave();
	
	-- bg
	nvgBeginPath();
	nvgRoundedRect(x, y, w, h, 5);
	nvgFillColor(colBackground);
	nvgFill();
	
	--self:drawFfaHeader(x, iy, w, 80, "Race Leaderboard", Color(232,232,232), headerDetails, 5, isRight);
	--iy = iy + 108;

	-- powerups & item control
	local playerCameraAttachedTo = getPlayer();
	local isPlaying = player == playerCameraAttachedTo;
	self:drawRaceStats(x, y, w, isRight, player, isPlaying);
	iy = iy + 120;

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace("TitilliumWeb-Regular");
	nvgFontBlur(0);

	-- leaderboard title
	nvgFillColor(Color(130,130,130));
	nvgFontSize(24);
	nvgText(x + padx, iy, "LEADERBOARDS");	
	
	-- leaderboard type
	local leaderboardType = widgetGetConsoleVariable("leaderboard");
	if  leaderboardType ~= "friends" and leaderboardType ~= "global" and leaderboardType ~= "top" then
		leaderboardType = "friends"
	end
	local leaderboards =
	{
		"FRIENDS",
		"GLOBAL",
		"TOP"
	};
	local leaderboardTypeNew = string.lower(ui2Spinner(leaderboards, string.upper(leaderboardType), x + padx + 170, iy-20, 150, optargs));
	if leaderboardTypeNew ~= leaderboardType then
		widgetSetConsoleVariable("leaderboard", leaderboardTypeNew);
	end
	iy = iy + 26;

	local leadboard, entries, entryCount, useGlobalRank;
	if leaderboardType == "friends" then
		leaderboard = QueryFriendsLeaderboard(world.mapName, "race");
		entries, entryCount = ExtractFriendsLeaderboardEntries(leaderboard);
		useGlobalRank = false;
	elseif leaderboardType == "top" then
		leaderboard = QueryGlobalLeaderboard(world.mapName, "race", "toponly");
		entries, entryCount = ExtractGlobalLeaderboardEntries(leaderboard);
		useGlobalRank = true;
	else
		leaderboard = QueryGlobalLeaderboard(world.mapName, "race");
		entries, entryCount = ExtractGlobalLeaderboardEntries(leaderboard);
		useGlobalRank = true;
	end

	-- find our rank
	local myRank = 1;
	for i = 1, entryCount do
		if entries[i].steamId == steamId then
			myRank = i;
		end
	end

	-- find range
	
	
	local startRank = 1;
	local endRank = math.min(13, entryCount);
	if leaderboardType ~= "top" then
		startRank = math.max(myRank - 6, 1);
		endRank = math.min(myRank + 6, entryCount);
		startRank = math.max(endRank - 12, 1);
		endRank = math.min(startRank + 12, entryCount);
	end

	-- determine rank width do we scale well (to big rank numbers :))
	local rankWidth = 0;
	if entryCount > 0 then 
		local entry = entries[endRank];
		local rank = useGlobalRank and entry.globalRank or endRank;
		rankWidth = string.len(rank) * 16;
		rankWidth = math.max(rankWidth, 32);
	end
	
	-- print entries
	nvgFontSize(32);
	for rank = startRank, endRank do
		local entry = entries[rank];
		local old = entry.old;

		local col = Color(170,170,170);
		if entry.steamId == steamId then
			nvgFontFace("TitilliumWeb-Bold");
		else
			nvgFontFace("TitilliumWeb-Regular");
		end

		-- rank
		local ix = x + padx;
		nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
		nvgFillColor(col);
		nvgText(ix + rankWidth/2, iy, useGlobalRank and entry.globalRank or rank);
		ix = ix + rankWidth;

		-- avatar
		local ih = 20;
		ix = ix + 10;
		nvgBeginPath();
		nvgRoundedRect(ix, iy-9, ih, ih, 4);
		nvgFillColor(Color(230,220,240));
		nvgFillImagePattern("$avatarSmall_"..entry.steamId, ix, iy-9, ih, ih);
		nvgFill();
		ix = ix + ih + 8;
		
		-- name
		local name = "Name_Not_Available";
		if steamFriends[entry.steamId] ~= nil then
			name = steamFriends[entry.steamId].personaName;
		end
		
		nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
		nvgFillColor(col);
		nvgText(ix, iy, name);
			
		-- time
		local text = FormatTimeToDecimalTime(entry.timeMillis);
		if old then
			nvgFillColor(UI2_COLTYPE_FAVORITE.base);
		end
		nvgText(x + padx + 325, iy, text);
		
		-- diff time
		if rank~=startRank then
			text = "(+" .. FormatTimeToDecimalShort(entry.timeMillis-entries[startRank].timeMillis) .. ")";
			nvgText(x + padx + 430, iy, text);
		end
		
		if old then
			if entry.mapHash ~= leaderboard.mapHash then
				local optargs = {};
				optargs.optionalId = i;
				ui2TooltipBox("This result was obtained on an older version", x + padx + 535, iy-16, 250, optargs);
			end
		end
		

				
		iy = iy + 24;
	end
		
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawRaceBreakdown(player, x, y, w, isRight)
	local h = 368;
	local iy = y + 24;

	local offsets =
	{
		["Time"] = 0,
		["Distance"] = 225,
		["Avg Speed"] = 360,
		["Top Speed"] = 490
	};

	-- title
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgFontFace("TitilliumWeb-Regular");
	nvgFillColor(Color(130,130,130));
	nvgFontBlur(0);
	nvgFontSize(24);
	for k, v in pairs(offsets) do
		nvgTextAlign(v == 0 and NVG_ALIGN_LEFT or NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
		local ix = x + padx + v;
		nvgText(ix, iy, string.upper(k));
	end
	iy = iy + 24;

	-- scores
	nvgFontBlur(0);
	nvgFontSize(32);
	nvgFontFace("TitilliumWeb-Bold");
	for i = 1, 5 do
		for k, v in pairs(offsets) do
			nvgTextAlign(v == 0 and NVG_ALIGN_LEFT or NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
			local ix = x + padx + v;
			local results = player.raceResults[i];
			
			nvgFillColor(Color(232,232,232, results.time > 0 and 255 or alphaFade));

			if k == "Time" then
				nvgText(ix, iy, FormatTimeToDecimalTime(results.time));
			elseif k == "Distance" then
				nvgText(ix, iy, CommaValue(round(results.distanceTravelled)));
			elseif k == "Avg Speed" then
				nvgText(ix, iy, CommaValue(round(results.avgSpeed)));
			else
				nvgText(ix, iy, CommaValue(round(results.topSpeed)));
			end
		end
		iy = iy + 24;
	end
end

local scoreboardOffsetX =
{
	["Name"] = 25,
	["Score"] = 390,
	["Lag"] = 480,
	["PL"] = 540,
	--["Icons"] = 540,
};

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawScoresTitle(x, y)
	local iy = y;

	nvgSave();

	nvgFontFace("TitilliumWeb-Regular");
	nvgFillColor(Color(130,130,130));
	nvgFontBlur(0);
	nvgFontSize(28);

	local ix = x + padx;
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(ix, iy, "NAME");

	-- score
	local text = "READY?";
	if (world.gameState ~= GAME_STATE_WARMUP) then
		local gm = gamemodes[world.gameModeIndex];
		if gm.shortName == "ctf" then
			text = "CAPTURES";
		elseif gm.shortName == "race" then
			text = "BEST TIME";
		else
			text = "SCORE";
		end
	end
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	ix = x + scoreboardOffsetX["Score"];
	nvgText(ix, iy, text);

	-- lag
	ix = x + scoreboardOffsetX["Lag"];
	nvgText(ix, iy, "LAG");

	-- pl
	ix = x + scoreboardOffsetX["PL"];
	nvgText(ix, iy, "PL");

	-- pl
	--ix = x + scoreboardOffsetX["Icons"];
	--nvgText(ix, iy, "Icons");

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function DrawScores(x, y, row, player, isSelected, m, w, h, optargs)
	-- we say it's 42 high, but really it's 32 high, with 5 padding on either side
	h = h - 10;
	y = y + 5;
	w = w + 10;

	local iy = y;

	nvgSave();

	local intensity = 255;
	if player.isDead then
		intensity = 110;
	end

	-- mouse hover
	nvgBeginPath();
	nvgRect(x+padx, y-1, w-padx*2, h+2);
	nvgFillColor(Color(230,220,240, m.hoverAmount * 64));
	nvgFill();
	if m.leftUp then
		if optargs.isRight then
			ScoreboardPlusRace.rightPlayer = player.index;
		else
			ScoreboardPlusRace.leftPlayer = player.index;
		end
	end

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace("titilliumWeb-Bold");
	nvgFontBlur(0);
	nvgFontSize(36);

	-- avatar
	local ix = x + padx + 2;
	nvgBeginPath();
	nvgRect(ix, iy, h, h);
	nvgFillColor(Color(230,220,240));
	nvgFillImagePattern("$avatarSmall_"..player.steamId, ix, iy, 32, 32, 0, intensity);
	nvgFill();
	
	-- bar
	local primary = extendedColors[player.colorIndices[1]+1];
	local secondary = extendedColors[player.colorIndices[2]+1];
	ix = ix + 40;
	nvgBeginPath();
	nvgRect(ix, iy+1, 6, h/2-1);
	nvgFillColor(primary);
	nvgFill();
	nvgBeginPath();
	nvgRect(ix, iy+h/2, 6, h/2-1);
	nvgFillColor(secondary);
	nvgFill();

	-- align name & powerups
	local hasMega = player.hasMega;
	local hasFlag = player.hasFlag;
	local hasCarnage = player.carnageTimer > 0;
	local hasResist = player.resistTimer > 0;
	local hasDead = player.isDead;
	local pr = 10;
	local pstride = 26;
	local pcount = (hasMega and 1 or 0) + (hasFlag and 1 or 0) + (hasCarnage and 1 or 0) + (hasResist and 1 or 0) + (hasDead and 1 or 0);
	local nameWidth = 326 - pstride * pcount;
	
	-- name
	nvgSave();
	nvgIntersectScissor(ix, iy, nameWidth, 100);
	local col = Color(232,232,232);
	local gameMode = gamemodes[world.gameModeIndex];
	if gameMode.hasTeams then
		col = teamColors[player.team];
	end
	col = Color(col.r, col.g, col.b, intensity);
	nvgFillColor(col);
	nvgText(ix+18, iy+h/2-1, player.name);
	local len = nvgTextWidth(player.name);
	len = math.min(len, nameWidth - 38);
	nvgRestore();

	-- powerup(s)
	local px = ix + 38 + len + 5;
	local py = iy+h/2+1;
	if hasMega then
		nvgFillColor(Color(255,255,255, intensity));
		nvgSvg("internal/ui/icons/health", px+pstride/2, py, pr);
		px = px + pstride;
	end
	if hasFlag then
		nvgFillColor(Color(255,255,255, intensity));
		nvgSvg("internal/ui/icons/CTFflag", px+pstride/2, py, pr);
		px = px + pstride;
	end
	if hasCarnage then
		nvgFillColor(Color(255,255,255, intensity));
		nvgSvg("internal/ui/icons/carnage", px+pstride/2, py, pr);
		px = px + pstride;
	end
	if hasResist then
		nvgFillColor(Color(255,255,255, intensity));
		nvgSvg("internal/ui/icons/resist", px+pstride/2, py, pr);
		px = px + pstride;
	end
	if hasDead then
		nvgFillColor(Color(255,255,255, intensity));
		nvgSvg("internal/ui/icons/skull", px+pstride/2, py, pr);
		px = px + pstride;
	end
	
	-- score (or ready up?)
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgFontFace("titilliumWeb-Bold");
	nvgFillColor(Color(232,232,232,intensity));
	ix = x + scoreboardOffsetX["Score"];
	if (world.gameState == GAME_STATE_WARMUP) then
		if player.ready then
			nvgSvg("internal/ui/icons/tick", ix, iy+h/2, 10);
		end
	else
		local score = player.score;
		if (gamemodes[world.gameModeIndex].shortName == "ctf") then
			score = player.stats.flagsCaptued;
		elseif (gamemodes[world.gameModeIndex].shortName == "race") then
			if score == 0 then
				score = "-";
			else
				score = FormatTimeToDecimalTime(score);
			end
		end
		nvgText(ix, iy+h/2-1, score);
	end

	-- lag
	ix = x + scoreboardOffsetX["Lag"];
	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(Color(232,232,232,intensity));
	nvgText(ix, iy+h/2-1, player.latency);

	-- kills
	ix = x + scoreboardOffsetX["PL"];
	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(Color(232,232,232, intensity));
	nvgText(ix, iy+h/2-1, player.packetLoss);

	-- show experience gain in post-game screen
	if world.gameState == GAME_STATE_GAMEOVER then
		-- experience on transition only
		local growTime = GetSecondsGrown();
		local experienceAlpha = 0;
		experienceAlpha = LerpWithFunc(EaseIn, growTime, experienceAlpha, 0, .2, 0, 1);
		experienceAlpha = LerpWithFunc(EaseInOut, growTime, experienceAlpha, GROW_TIME_LEN+1.5, GROW_TIME_LEN + 2.5, 1, 0);
		if experienceAlpha > 0 then
			-- pull experience vars from player, and step it up as time goes on
			local experience, didLevelUp = ProcessExperience(player.experience, player.experienceGained);
			local experienceVars = GetExperienceVars(experience);
		
			local ix = x + scoreboardOffsetX["Score"] - 60;
			nvgFontFace("TitilliumWeb-Regular");
			nvgFontSize(20);
			nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
			nvgFillColor(Color(180, 180, 180, experienceAlpha*intensity));
			nvgText(ix, iy+19, "Rank: " .. experienceVars.level);
		
			-- level up explosion
			if didLevelUp then
				for i = 1, 5 do
					ExplosionEmitter:addSpark(
						math.random(ix - 5, ix + 5),
						math.random(iy+19 - 5, iy+19 + 5));
				end
			end

			local experienceWidth = 266;
			local optargs = {};
			optargs.intensity = experienceAlpha;
			DrawExperienceBar(ix - experienceWidth, iy+30, experienceWidth, 2, player.experience, player.experienceGained, experience, optargs);
		end
	end
	
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawTitle(x, y, w, h)
	-- draw bg
	nvgBeginPath();
	nvgRoundedRect(x, y, w, h, 5);
	nvgFillColor(colBackground);
	nvgFill();

	local ix = x + 49;
	nvgBeginPath();
	nvgCircle(ix, y+h/2, 45);
	nvgFillColor(Color(232,232,232));
	nvgFill();
	
	local gameMode = gamemodes[world.gameModeIndex];

	-- mode
	local text = string.upper(gameMode.shortName);
	local fontSize = 54 - math.max((string.len(text)-4),0) * 6;
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	nvgFontFace("titilliumWeb-Bold");
	nvgFontBlur(0);
	nvgFontSize(fontSize);
	nvgSave();
	nvgTextLetterSpacing(-1);
	nvgFillColor(Color(32,32,32));
	nvgText(ix, y+h/2-1, text);
	nvgRestore();

	-- map
	local mapTitle = world.mapTitle;
	if string.len(mapTitle) <= 0 then
		mapTitle = world.mapName;
	end
	ix = x + 106;
	
	nvgFontSize(54);
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace("titilliumWeb-Bold");
	nvgFillColor(Color(232,232,232));
	if serverConnectedToSteam then
		-- workshop buttons
		ScoreboardPlusRace:drawWorkshopButtons(ix, y+18, w, h);
		
		-- title
		local optargs = {}
		optargs.nofont = true;
		optargs.halign = NVG_ALIGN_LEFT;
		optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
		local tw = nvgTextWidth(mapTitle);
		if ui2Button(mapTitle, ix-3, y+h/2-1-31, tw+20, 32, optargs) then
			launchUrl("steam://url/CommunityFilePage/" .. world.mapWorkshopId)
		end
	else
		nvgText(ix, y+h/2-1, mapTitle);
	end
	
	-- hostname
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	nvgFontSize(32);
	nvgText(x+w-padx, y+28-1, world.hostName);

	-- ref: http://stackoverflow.com/questions/2421695/first-character-uppercase-lua
	function firstToUpper(str)
	    return (str:gsub("^%l", string.upper))
	end
	
	-- ruleset
	local text = "Ruleset: " .. firstToUpper(world.ruleset);
	--text = text .. ", Mutator: Instagib";
	--text = text .. ", IP: " .. world.serverIp..":"..world.serverPort;
	--text = string.upper(text);
	nvgFillColor(Color(160,160,160));
	nvgFontFace("titilliumWeb-Regular");
	nvgFontSize(26);
	nvgText(x+w-padx, y+52-1, text);

	if string.len(world.mutators) > 0 then
		local tw = nvgTextWidth(text);
		local ix = x+w-tw-padx - 14;
		local iy = y+53;
		local iconRad = 11;
		
		-- iterate mutators
		local upperCaseMutators = string.upper(world.mutators);
		for k, v in pairs(mutatorDefinitions) do
			if string.find(upperCaseMutators, k) ~= nil then
				-- name
				--local name = firstToUpper(string.lower(k));
				--local intensity = 1;
				--nvgFillColor(Color(160,160,160));
				--nvgText(ix, iy, name, NULL);
				--ix = ix - nvgTextWidth(k);

				-- icon
				local iconCol = v.col;
				nvgFillColor(Color(iconCol.r, iconCol.g, iconCol.b, 200));
				nvgSvg(v.icon, ix - iconRad+3, iy, iconRad-2);
				ix = ix - iconRad*2-6;
			end
		end
		
		ix = ix + 8;
		nvgFillColor(Color(160,160,160));
		text = "Mutators: ";
		nvgText(ix, y+52-1, text);
	end
end

function ScoreboardPlusRace:drawWorkshopButtons(ix, y, w, h)
	if self.queriedWorkshopId ~= world.mapWorkshopId then
		self.queriedWorkshopId = world.mapWorkshopId;
		self.authorName = "";
		workshopQuerySpecificMap(world.mapWorkshopId);
	end

	if workshopSpecificMap ~= nil and workshopSpecificMap.id == world.mapWorkshopId then
		self.authorName = workshopSpecificMap.ownerName;
	end

	local author = self.authorName;
	local voteUp, voteDown, favorite, subscribed = workshopGetMapFlags(world.mapWorkshopId);

	local intensity = 1;
	local hoverAmount = 0;
	local enabled = true;
	local col = ui2FormatColor(UI2_COLTYPE_DIM, intensity, hoverAmount, enabled);
	local optargs = {};
	optargs.intensity = intensity;
	optargs.enabled = enabled;

	--optargs.icon = "internal/ui/icons/workshop";

	local iconTop = y + h/2-15;
	local iconSize = 30;
	local iconPad = 4;

	nvgSave();
	
	optargs.coltype = UI2_COLTYPE_DIM;
	optargs.bgcoltype = UI2_COLTYPE_HOVERBUTTON;
	optargs.nofont = true;
	optargs.iconSize = 9;
	nvgFontSize(26);
	nvgFontFace(FONT_TEXT2);
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);

	-- rate up	
	if voteUp then
		optargs.coltype = UI2_COLTYPE_VOTEUP;
	end
	optargs.iconLeft = "internal/ui/icons/thumbsup";
	if ui2Button("", ix, iconTop, iconSize, iconSize, optargs) then
		workshopSetMapVote(world.mapWorkshopId, true);
	end
	optargs.iconLeft = nil;
	optargs.coltype = UI2_COLTYPE_DIM;
	ix = ix + iconSize + iconPad;

	-- rate down
	if voteDown then 
		optargs.coltype = UI2_COLTYPE_VOTEDOWN;
	end
	optargs.icon = "internal/ui/icons/thumbsdown";
	if ui2Button("", ix, iconTop, iconSize, iconSize, optargs) then
		workshopSetMapVote(world.mapWorkshopId, false);
	end
	optargs.coltype = UI2_COLTYPE_DIM;
	optargs.icon = nil;
	ix = ix + iconSize + iconPad;

	-- fav
	if favorite then
		optargs.coltype = UI2_COLTYPE_FAVORITE;
	end
	optargs.iconLeft = "internal/ui/icons/favourite";
	if ui2Button("", ix, iconTop, iconSize, iconSize, optargs) then
		workshopSetMapFavorite(world.mapWorkshopId, not favorite);
	end
	optargs.iconLeft = nil;
	optargs.coltype = UI2_COLTYPE_DIM;
	ix = ix + iconSize + iconPad;

	-- subscribe
	if subscribed then
		optargs.coltype = UI2_COLTYPE_SUBSCRIBE;
	end
	optargs.iconLeft = "internal/ui/icons/subscribe";
	if ui2Button("       Subscribe", ix, iconTop, 111, iconSize, optargs) then
		workshopSetMapSubscibed(world.mapWorkshopId, not subscribed);
	end
	optargs.iconLeft = nil;
	optargs.coltype = UI2_COLTYPE_DIM;
	ix = ix + 111 + iconPad;

	nvgRestore();

	return ix;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:getFooterHeight(queued, spectators, editors, referees)
	-- no footer if no-one to show
	if queued == 0 and spectators == 0 and editors == 0 and referees == 0 then
		return 0;
	end

	-- find spectators
	local h = 12;
	if queued > 0 then h = h + 24 end;
	if spectators > 0 then h = h + 24 end;
	if editors > 0 then h = h + 24 end;
	if referees > 0 then h = h + 24 end;
	h = h + 12;
	return h;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawFooter(x, y, w, 
	queuedPlayers, queued,
	spectatorPlayers, spectators,
	editorPlayers, editors,
	refereePlayers, referees)

	-- determine height in common function
	local h = self:getFooterHeight(queued, spectators, editors, referees);
	if h == 0 then
		return;
	end
	
	-- draw bg
	nvgBeginPath();
	nvgRoundedRect(x, y, w, h, 5);
	nvgFillColor(colBackground);
	nvgFill();

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFillColor(Color(232,232,232));
	nvgFontSize(32);

	local function drawPlayerListHorizontal(x, y, players, colorByTeam)
		local ix = x;
		local iy = y;
		local ih = 24;
		
		for k, player in ipairs(players) do
			local text = player.name .. " ("..player.latency..")";
			local iw = 18 + nvgTextWidth(text) + 30;
			
			-- mouse hover
			local m = mouseRegion(ix-20, iy-ih/2-1, iw, ih+2, k);
			nvgBeginPath();
			nvgRect(ix-20, iy-ih/2-1, iw, ih+2);
			nvgFillColor(Color(230,220,240, m.hoverAmount * 64));
			nvgFill();
			if m.leftUp then
				-- always put on right, so in FFA etc it still makes sense (in FFA local player is always on left)
				ScoreboardPlusRace.rightPlayer = player.index;
			end
			
			-- flag
			local iconName = "internal/ui/icons/flags/"..player.country;
			nvgFillColor(Color(255, 255, 255));
			nvgSvg(iconName, ix, iy, 12);
			ix = ix + 18;
	
			-- text
			local textCol = Color(255,255,255);
			if colorByTeam then
				textCol.r = teamColors[player.team].r;
				textCol.g = teamColors[player.team].g;
				textCol.b = teamColors[player.team].b;
			end
			nvgFillColor(textCol);
			nvgText(ix, iy, text);
			ix = ix + nvgTextWidth(text);

			-- pad
			ix = ix + 30;
		end
	end
	
	local iy = y + 24;
	nvgSave();
	nvgIntersectScissor(x, y, w-5, 140);

	-- queue
	if queued > 0 then
		local colorQueueByTeam = false;

		local gameMode = gamemodes[world.gameModeIndex];
		if gameMode.hasTeams then
			colorQueueByTeam = true;
		end
	
		nvgFontFace("titilliumWeb-Bold");
		nvgText(x+padx, iy, "In Queue ("..queued..")");
		nvgFontFace("titilliumWeb-Regular");
		drawPlayerListHorizontal(x+150, iy, queuedPlayers, colorQueueByTeam);
		iy = iy + 24;
	end
	
	-- spectators
	if spectators > 0 then
		nvgFontFace("titilliumWeb-Bold");
		nvgText(x+padx, iy, "Spectators");
		nvgFontFace("titilliumWeb-Regular");
		drawPlayerListHorizontal(x+150, iy, spectatorPlayers);
		iy = iy + 24;
	end
	
	-- editors
	if editors > 0 then
		nvgFontFace("titilliumWeb-Bold");
		nvgText(x+padx, iy, "Editors");
		nvgFontFace("titilliumWeb-Regular");
		drawPlayerListHorizontal(x+150, iy, editorPlayers);
		iy = iy + 24;
	end
	
	-- referees
	if referees > 0 then
		nvgFontFace("titilliumWeb-Bold");
		nvgText(x+padx, iy, "Referees");
		nvgFontFace("titilliumWeb-Regular");
		drawPlayerListHorizontal(x+150, iy, refereePlayers);
		iy = iy + 24;
	end

	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawTeamHeader(x, y, w, h, name, nameCol, details, score, isRight)
	local iy = y;

	nvgSave();

	local dirx = isRight and -1 or 1;
	local isWinning = true;
	local insidex = isRight and x or x+w;
	local outsidex = isRight and x+w or x;

	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(nameCol);
	nvgFontBlur(0);
	nvgFontSize(48);
	
	local ix = outsidex+padx*dirx;

	-- name
	nvgFillColor(nameCol);
	nvgTextAlign(isRight == true and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	name = string.upper(name);
	nvgSave();
	if isRight then
		nvgIntersectScissor(ix-310, iy, 310, 100);
	else
		nvgIntersectScissor(ix, iy, 310, 100);
	end
	nvgText(ix, iy+36, name);
	nvgRestore();
	
	-- ping/pl
	nvgFontFace("TitilliumWeb-Regular");
	nvgFillColor(Color(170,170,170));
	nvgFontSize(24);
	nvgTextAlign(isRight == true and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(ix, iy+60, details);
	
	-- score
	ix = isRight and x + 15 or x+w-15;
	nvgFontFace("TitilliumWeb-Bold");
	nvgTextAlign(isRight == true and NVG_ALIGN_LEFT or NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	nvgFillColor(isWinning and Color(232,232,232) or Color(170,170,170));
	nvgFontSize(128);
	nvgText(ix, iy+44, score);

	-- line
	nvgBeginPath();
	nvgMoveTo(x+padx, y+padx*2+64);
	nvgLineTo(x+w-padx, y+padx*2+64);
	nvgStrokeWidth(1);
	nvgStrokeColor(Color(130,130,130));
	nvgStroke();
	
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawFfaHeader(x, y, w, h, name, nameCol, details, score, isRight)
	local iy = y;

	nvgSave();

	local dirx = isRight and -1 or 1;
	local isWinning = true;
	local insidex = isRight and x or x+w;
	local outsidex = isRight and x+w or x;

	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(nameCol);
	nvgFontBlur(0);
	nvgFontSize(48);
	
	local ix = outsidex+padx*dirx;

	-- name
	nvgFillColor(nameCol);
	nvgTextAlign(isRight == true and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	name = string.upper(name);
	nvgSave();
	if isRight then
		nvgIntersectScissor(ix-310, iy, 310, 100);
	else
		nvgIntersectScissor(ix, iy, 310, 100);
	end
	nvgText(ix, iy+36, name);
	nvgRestore();
	
	-- ping/pl
	nvgFontFace("TitilliumWeb-Regular");
	nvgFillColor(Color(170,170,170));
	nvgFontSize(24);
	nvgTextAlign(isRight == true and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgText(ix, iy+60, details);
	
	---- score
	--ix = isRight and x + 15 or x+w-15;
	--nvgFontFace("TitilliumWeb-Bold");
	--nvgTextAlign(isRight == true and NVG_ALIGN_LEFT or NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
	--nvgFillColor(isWinning and Color(232,232,232) or Color(170,170,170));
	--nvgFontSize(128);
	--nvgText(ix, iy+44, score);

	-- line
	nvgBeginPath();
	nvgMoveTo(x+padx, y+padx*2+64);
	nvgLineTo(x+w-padx, y+padx*2+64);
	nvgStrokeWidth(1);
	nvgStrokeColor(Color(130,130,130));
	nvgStroke();
	
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawPlayerHeader(x, y, w, h, player, isRight, noScore)
	local iy = y;

	local name = player.name;
	local avatar = "$avatarMedium_"..player.steamId;
	local score = player.score;
	local iconName = "internal/ui/icons/flags/"..player.country;
	local nameCol = Color(232, 232, 232);
	local gameMode = gamemodes[world.gameModeIndex];
	if gameMode.hasTeams then
		nameCol = teamColors[player.team];
	end
	
	-- pull experience vars from player, and step it up as time goes on
	local experience, didLevelUp = ProcessExperience(player.experience, player.experienceGained);
	local experienceVars = GetExperienceVars(experience);

	-- if player isn't in game (i.e. he's spec / editor etc), just make his colour white
	if player.state ~= PLAYER_STATE_INGAME then
		nameCol = Color(212,212,212);
	end

	nvgSave();

	local dirx = isRight and -1 or 1;
	local isWinning = true;
	local insidex = isRight and x or x+w;
	local outsidex = isRight and x+w or x;
	local barw = w - 244;
	local barx = x + (padx + 10 + 64) * dirx;
	if isRight then barx = barx + w - barw end;
	
	nvgFontFace("TitilliumWeb-Bold");
	nvgFillColor(nameCol);
	nvgFontBlur(0);
	nvgFontSize(48);

	-- image
	--if profileIcon ~= nil then
		local ix = outsidex+padx*dirx;
		if isRight then ix = ix - 64 end;
		nvgBeginPath();
		nvgRect(ix, y+padx, 64, 64);
		nvgFillColor(Color(127, 127, 127, 255));
		nvgFillImagePattern(avatar, ix, y+padx, 64, 64, 0, 255);
		nvgFill();
	--end

	---- flag
	local ix = x + (padx + 91) * dirx;
	if isRight then ix = ix + w end;
	nvgFillColor(Color(255, 255, 255));
	nvgSvg(iconName, ix, iy+30, 16);
	ix = ix + 21 * dirx;

	-- name
	nvgFillColor(nameCol);
	nvgTextAlign(isRight == true and NVG_ALIGN_RIGHT or NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	name = string.upper(name);
	nvgSave();
	if isRight then
		nvgIntersectScissor(ix-310, iy, 310, 100);
	else
		nvgIntersectScissor(ix, iy, 310, 100);
	end
	nvgText(ix, iy+27, name);
	nvgRestore();
	
	-- second row
	local ix = x + (padx + 10 + 64) * dirx;
	if isRight then ix = ix + w end;
	iy = iy + 56;

	---- flag
	--ix = ix + 14 * dirx;
	--nvgFillColor(Color(255, 255, 255));
	--nvgSvg(iconName, ix, iy, 12);
	--ix = ix + 18 * dirx;
	
	-- rank: 20   XP Gained: 0
	local text = string.format("Rank: %d   XP Gained: %d", experienceVars.level, player.experienceGained);
	nvgFontFace("TitilliumWeb-Regular");
	nvgFontSize(24);
	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	if isRight == true then
		ix = ix - nvgTextWidth(text);
	end
	local col = Color(170,170,170);
	local rankx = ix;
	nvgFillColor(Color(232,232,232));
	nvgText(ix, iy, text);
	ix = ix + nvgTextWidth("Rank: ") + nvgTextWidth(experienceVars.level)/2;
	
	-- pretty exploisions
	if didLevelUp then
		for i = 1, 25 do
			ExplosionEmitter:addSpark(
				math.random(ix - 5, ix + 5),
				math.random(iy - 5, iy + 5)+5);
		end
	end

	-- ping
	ix = barx;
	if not isRight then
		ix = ix + barw;
		ix = ix - nvgTextWidth("Latency: " .. player.latency .. "   PL: " .. player.packetLoss);
	end
	nvgFillColor(col);
	nvgText(ix, iy, "Latency: ");
	ix = ix + nvgTextWidth("Latency: ");
	nvgFillColor(GetPingColor(player.latency, col));
	nvgText(ix, iy, player.latency);
	ix = ix + nvgTextWidth(player.latency);
	
	-- PL
	nvgFillColor(col);
	nvgText(ix, iy, "   PL: ");
	ix = ix + nvgTextWidth("   PL: ");
	nvgFillColor(GetPingColor(player.packetLoss, col));
	nvgText(ix, iy, player.packetLoss);
	ix = ix + nvgTextWidth(player.packetLoss);

	-- experience bar
	iy = iy + 16;
	DrawExperienceBar(barx, iy, barw, 5, player.experience, player.experienceGained, experience);
		
	-- score
	if noScore ~= true then
		local ix = isRight and x + 15 or x+w-15;
		nvgTextAlign(isRight == true and NVG_ALIGN_LEFT or NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
		if world.gameState == GAME_STATE_WARMUP then
			nvgFontFace("TitilliumWeb-Bold");
			nvgFontSize(64);
			nvgFillColor(player.ready and Color(232,232,232,255) or Color(92,92,92,128));
			nvgText(ix, y+46, "READY");
		else
			nvgFontFace("TitilliumWeb-Bold");
			nvgFillColor(isWinning and Color(232,232,232) or Color(170,170,170));
			nvgFontSize(128);
			nvgText(ix, y+44, score);
		end
	end

	-- line
	nvgBeginPath();
	nvgMoveTo(x+padx, y+padx*2+64);
	nvgLineTo(x+w-padx, y+padx*2+64);
	nvgStrokeWidth(1);
	nvgStrokeColor(Color(130,130,130));
	nvgStroke();
	
	nvgRestore();
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawPlayerFooter(x, y, w, h, player, isRight)
	local iy = y;
	local cannotAcceptNeedButtonOverlay = false;

	nvgSave();

	-- add friend button
	local buttonUrl = "";
	local buttonText = "";
	local buttonOverlay = "";
	local optargs = {};
	local steamFriend = steamFriends[player.steamId];
	if ((steamFriend ~= nil) and (steamFriend.relationship == "Friend")) or (player.steamId == getLocalPlayer().steamId) then -- (friend with myself :))
		buttonText = "FRIENDS";
		optargs.iconLeft = "internal/ui/icons/tick";
		optargs.coltype = UI2_COLTYPE_TEXT_GREEN;
	elseif (steamFriend ~= nil) and (steamFriend.relationship == "RequestRecipient") then
		buttonText = "ACCEPT FRIEND REQ..";
		if steamOverlayEnabled then
			buttonOverlay = "friendrequestaccept";
		else
			cannotAcceptNeedButtonOverlay = true;
		end
		optargs.iconLeft = "internal/ui/icons/thumbsup";
		optargs.coltype = UI2_COLTYPE_TEXT_YELLOW;
	elseif (steamFriend ~= nil) and (steamFriend.relationship == "RequestInitiator") then
		buttonText = "FRIEND REQUEST SENT";
		optargs.iconLeft = "internal/ui/icons/tick";
		optargs.coltype = UI2_COLTYPE_TEXT_YELLOW;
	else
		-- note: ignoring blocked / ignored etc..
		buttonUrl = "steam://friends/add/"..player.steamId;
		buttonText = "ADD FRIEND";
		if steamOverlayEnabled then
			buttonOverlay = "friendadd";
		end
		optargs.iconLeft = "internal/ui/icons/plus";
		optargs.coltype = UI2_COLTYPE_TEXT;
	end
	optargs.nofont = true;
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = (player.steamId ~= 0) and connectedToSteam and 
		(   (string.len(buttonOverlay) > 0)   or   (string.len(buttonUrl) > 0)   );
	ui2FontSmall();
	if ui2Button(buttonText, x+w/4-100+20, y+padx, 230, 30, optargs) then
		-- overlay takes precedence, if not fall back to url
		if string.len(buttonOverlay) > 0 then
			launchGameOverlayToUser(buttonOverlay, player.steamId);
		else
			launchUrl(buttonUrl);
		end
	end
	
	-- view steam profile button
	local optargs = {};
	optargs.nofont = true;
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	optargs.enabled = (player.steamId ~= 0) and connectedToSteam;
	ui2FontSmall();
	if ui2Button("VIEW STEAM PROFILE", x+w*(3/4)-100-20, y+padx, 220, 30, optargs) then
		launchUrl("steam://url/SteamIDPage/"..player.steamId);
	end

	-- back arrow
	local backArrow = ((isRight==true) and (self.rightPlayer ~= nil)) or ((isRight~=true) and (self.leftPlayer ~= nil));
	if backArrow then
		optargs.iconLeft = "internal/ui/icons/keyLeft";
		if ui2Button("", x + 15, y+padx, 35, 30, optargs) then
			if isRight then self.rightPlayer = nil end;
			if not isRight then self.leftPlayer = nil end;
		end
	end

	if cannotAcceptNeedButtonOverlay then
		-- had an overlay command, but no overlay :(
		ui2TooltipBox("Cannot accept from in game, Steam Overlay not found", x+w/4-100+220, y+padx-3, 220);
	end
	
	nvgRestore();
end

--------------------------------------------------------------------------------
-- player card shows single player statistics
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawPlayerCard(x, y, w, h, player, otherPlayer, isRight)
	local gameMode = gamemodes[world.gameModeIndex];
	local isRace = gameMode.shortName == "race";
	local ix = x;
	local iy = y;

	-- bg
	nvgBeginPath();
	nvgRoundedRect(ix, iy, w, h, 5);
	nvgFillColor(colBackground);
	nvgFill();

	-- header
	local hideScore = isRace or isTraining;
	self:drawPlayerHeader(ix, iy, w, 80, player, isRight, hideScore);
	iy = iy + 90;
	
	-- breakdown
	if isRace then
		self:drawRaceBreakdown(player, ix, iy, w, isRight);
	else
		self:drawBreakdown(player, otherPlayer, ix, iy, w, isRight);
	end
	iy = iy + 380;

	-- footer
	self:drawPlayerFooter(ix, iy, w, 30, player, isRight);
	iy = iy + 30;
end

--------------------------------------------------------------------------------
-- training card of current map environment
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawTrainingCard(x, y, w, h, isRight)
	--local gameMode = gamemodes[world.gameModeIndex];
	--local isTraining = gameMode.shortName == "training";
	--local isRace = gameMode.shortName == "race";
	local player = getPlayer();
	local otherPlayer = nil;
	local ix = x;
	local iy = y;
	
	-- bg
	nvgBeginPath();
	nvgRoundedRect(ix, iy, w, h, 5);
	nvgFillColor(colBackground);
	nvgFill();
	--
	---- header
	--local hideScore = isRace or isTraining;
	--self:drawPlayerHeader(ix, iy, w, 80, player, isRight, hideScore);

	nvgTextAlign(NVG_ALIGN_LEFT, NVG_ALIGN_MIDDLE);
	nvgFontFace("TitilliumWeb-Regular");
	nvgFontBlur(0);

	-- goal title
	nvgFillColor(Color(130,130,130));
	nvgFontSize(24);
	iy = iy + 22;
	nvgText(x + padx, iy, "TRAINING STATISTICS");

	--iy = iy + 90;
	--
	---- breakdown
	--if isTraining then
	self:drawTrainingBreakdown(player, otherPlayer, ix, iy, w, isRight);
	--elseif isRace then
	--	self:drawRaceBreakdown(player, ix, iy, w, isRight);
	--else
	--	self:drawBreakdown(player, otherPlayer, ix, iy, w, isRight);
	--end
	iy = iy + 448;
	--
	---- footer
	local optargs = {};
	optargs.nofont = true;
	optargs.bgcoltype = UI2_COLTYPE_BUTTON_BLACK;
	ui2FontSmall();
	if ui2Button("RESTART", x+w/4-100+20, iy+padx, 230, 30, optargs) then
		consolePerformCommand("callvote restart");
	end

	-- return to menu
	if world.gameState == GAME_STATE_GAMEOVER then
		-- go red at end of game
		optargs.bgcoltype = nil;
	end
	if ui2Button("RETURN TO MENU", x+w*(3/4)-100-20, iy+padx, 220, 30, optargs) then
		consolePerformCommand("disconnect");
	end
	optargs.bgcoltype = nil;
	iy = iy + 30;
end

--------------------------------------------------------------------------------
-- player list shows list of all players
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawPlayerList(x, y, w, h, players, playerCount, isRight)
	local ix = x;
	local iy = y;

	-- team header
	local headerDetails = playerCount == 1 and "1 Player" or playerCount .. " Players";
	nvgBeginPath();
	nvgRoundedRect(ix, iy, w, h, 5);
	nvgFillColor(colBackground);
	nvgFill();
	self:drawFfaHeader(ix, iy, w, 80, "Players", Color(232,232,232), headerDetails, 5, isRight);
	iy = iy + 108;
	
	-- player list header
	self:drawScoresTitle(ix, iy);
	iy = iy + 18;

	-- player list
	local scrollBarData = isRight and self.rightScrollData or self.leftScrollData;
	optargs = {};
	optargs.isRight = isRight;
	optargs.itemDrawFunction = DrawScores;
	optargs.itemHeight = 42;
	ui2ScrollSelection(players, nil, ix, iy, w-13, 388, scrollBarData, optargs);
end

--------------------------------------------------------------------------------
-- team card shows tema player list & team statistics
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawTeamCard(x, y, w, h, teamIndex, teamPlayers, teamPlayerCount, teamStats, otherTeamStats, isRight)
	local ix = x;
	local iy = y;
	
	-- team header
	local headerDetails = teamPlayerCount == 1 and "1 Player" or teamPlayerCount .. " Players";
	nvgBeginPath();
	nvgRoundedRect(ix, iy, w, h, 5);
	nvgFillColor(colBackground);
	nvgFill();
	self:drawTeamHeader(ix, iy, w, 80, world.teams[teamIndex].name, teamColors[teamIndex], headerDetails, world.teams[teamIndex].score, isRight);
	iy = iy + 108;
	local underheadery = iy;

	-- player list header
	self:drawScoresTitle(ix, iy);
	iy = iy + 18;

	-- player list
	local scrollBarData = isRight and self.rightScrollData or self.leftScrollData;
	optargs = {};
	optargs.isRight = isRight;
	optargs.itemDrawFunction = DrawScores;
	optargs.itemHeight = 42;
	ui2ScrollSelection(teamPlayers, nil, ix, iy, w-13, 260, scrollBarData, optargs);
	iy = underheadery + 270;

	-- team footer
	self:drawStats(ix, iy, w, isRight, teamStats, otherTeamStats);
	iy = iy + 190;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:drawGameplayReturnsTimer(x, y)
	if world.gameState == GAME_STATE_GAMEOVER then
		
		nvgSave();
		
		local secondsUntilPlay = math.max(math.ceil((world.gameTimeLimit - world.gameTime) / 1000), 0);
		local text = string.format("Gameplay returns in 0:%02d", secondsUntilPlay);
		
		nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);
		nvgFontFace("TitilliumWeb-Bold");
		nvgFontSize(32);

		nvgFontBlur(2);
		nvgFillColor(Color(60,60,60));
		nvgText(x, y, text);

		nvgFontBlur(0);
		nvgFillColor(Color(232,232,232));
		nvgText(x, y, text);
		
		nvgRestore();
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ScoreboardPlusRace:draw()

    -- Early out if HUD shouldn't be shown.
    --if not shouldShowHUD() then return end;
	local gameMode = gamemodes[world.gameModeIndex];
	if	(gameMode == nil) or
		(not showScores and world.gameState ~= GAME_STATE_GAMEOVER) or
		(replayName == "menu") or
		(isInMenu()) then 
		
		-- clear currently selected player if any
		self.leftPlayer = nil;
		self.rightPlayer = nil;
		self.leftScrollData = {};
		self.rightScrollData = {};
		return;
	end
	
	-- discover connected players
	local connectedPlayerCount = 0;
	local connectedPlayers = {};
	for k, v in pairs(players) do
		if v.connected then
			connectedPlayerCount = connectedPlayerCount + 1;
			connectedPlayers[connectedPlayerCount] = v;
		end
	end

	-- discover real players (aka players actually playing)
	local realPlayerCount = 0;
	local realPlayers = {};
	for index = 1, connectedPlayerCount do
		local player = connectedPlayers[index];
		if player.state == PLAYER_STATE_INGAME then
			realPlayerCount = realPlayerCount + 1;
			realPlayers[realPlayerCount] = player;
		end
	end
	table.sort(realPlayers, sortByScore);

	-- discover team players & team statistics
	local teamPlayerCount = {};
	local teamPlayers = {};
	local teamStats = {};
	for team = 1, 2 do
		teamStats[team] = {};
		teamPlayers[team] = {};
		teamPlayerCount[team] = 0;
		teamStats[team].totalDamageDone = 0;
		teamStats[team].totalDamageReceived = 0;
		teamStats[team].distanceTravelled = 0;
		teamStats[team].secondsHeldCarnage = 0;
		teamStats[team].secondsHeldResist = 0;
		teamStats[team].takenRA = 0;
		teamStats[team].takenYA = 0;
		teamStats[team].takenGA = 0;
		teamStats[team].takenMega = 0;
	end
	for index = 1, connectedPlayerCount do
		local player = connectedPlayers[index];
		if player.state == PLAYER_STATE_INGAME then
			local t = player.team;
			teamPlayerCount[t] = teamPlayerCount[t] + 1;
			teamPlayers[t][teamPlayerCount[t]] = player;
			teamStats[t].totalDamageDone = teamStats[t].totalDamageDone + player.stats.totalDamageDone;
			teamStats[t].totalDamageReceived = teamStats[t].totalDamageReceived + player.stats.totalDamageReceived;
			teamStats[t].distanceTravelled = teamStats[t].distanceTravelled + player.stats.distanceTravelled;
			teamStats[t].secondsHeldCarnage = teamStats[t].secondsHeldCarnage + player.stats.secondsHeldCarnage;
			teamStats[t].secondsHeldResist = teamStats[t].secondsHeldResist + player.stats.secondsHeldResist;
			teamStats[t].takenRA = teamStats[t].takenRA + player.stats.takenRA;
			teamStats[t].takenYA = teamStats[t].takenYA + player.stats.takenYA;
			teamStats[t].takenGA = teamStats[t].takenGA + player.stats.takenGA;
			teamStats[t].takenMega = teamStats[t].takenMega + player.stats.takenMega;
		end
	end
	table.sort(teamPlayers[1], sortByScore);
	table.sort(teamPlayers[2], sortByScore);

	-- discover other players
	local queuedPlayers = {};
	local queued = 0;
	local spectatorPlayers = {};
	local spectators = 0;
	local editorPlayers = {};
	local editors = 0;
	local refereePlayers = {};
	local referees = 0;	
	for k, player in ipairs(connectedPlayers) do
		-- queued?
		if player.state == PLAYER_STATE_QUEUED then
			queued = queued + 1;
			queuedPlayers[queued] = player;
		end
		-- specating?
		if player.state == PLAYER_STATE_SPECTATOR then
			spectators = spectators + 1;
			spectatorPlayers[spectators] = player;
		end
		-- editing
		if player.state == PLAYER_STATE_EDITOR then
			editors = editors + 1;
			editorPlayers[editors] = player;
		end
		-- referee
		if player.isReferee then
			referees = referees + 1;
			refereePlayers[referees] = player;
		end
	end
	table.sort(queuedPlayers, sortForQueuePosition);
	table.sort(spectatorPlayers, sortForName);
	table.sort(editorPlayers, sortForName);
	table.sort(refereePlayers, sortForName);

	-- temp
	-- spectatorPlayers = connectedPlayers;
	-- queuedPlayers = connectedPlayers;
	-- editorPlayers = connectedPlayers;
	-- refereePlayers = connectedPlayers;
	-- spectators = 1;
	-- editors = 1;
	-- referees = 1;
	-- queued = 1;
	-- for i = 2, 23 do
	-- 	realPlayers[i] = realPlayers[1];
	-- end
	-- realPlayerCount = 23;

	-- ready timer
	if world.gameState == GAME_STATE_WARMUP then
		self.readyTimer = self.readyTimer + deltaTimeRaw*4;
	else
		self.readyTimer = 0;
	end

	-- spark timer
	if self.sparkTimer == nil then
		self.sparkTimer = 0;
	end
	self.sparkTimer = self.sparkTimer + deltaTimeRaw;
	self.sparkTimer = math.min(self.sparkTimer, .5);
	self.sparkFrame = false;
	if self.sparkTimer > .05 then
		self.sparkFrame = true;
		self.sparkTimer = 0;
	end

	-- pre-calculate height so we can balance scoreboard vertically
	local w = 1200;
	local footerHeight = self:getFooterHeight(queued, spectators, editors, referees);
	local h = 120; -- title + pad
	h = h + 530; -- main content
	if footerHeight > 0 then
		h = h + 40; -- pad
		h = h + footerHeight;
	end
	
	-- start y
	local iy = -h/2;

	-- debug ruler :)
	-- nvgBeginPath();
	-- nvgMoveTo(-w/2-20, iy);
	-- nvgLineTo(-w/2-20, iy+h);
	-- nvgStrokeWidth(1);
	-- nvgStrokeColor(Color(255,0,0));
	-- nvgStroke();

	-- title
	self:drawTitle(-w/2, iy, w, 80);
	iy = iy + 120;
	local undertitley = iy;

	if gameMode.hasTeams then

		-- left team
		local ix = -w/2;
		iy = undertitley;
		if self.leftPlayer ~= nil and players[self.leftPlayer].connected then
			self:drawPlayerCard(ix, iy, w/2-padx, 530, players[self.leftPlayer], nil, false);
		else			
			self:drawTeamCard(ix, iy, w/2-padx, 530, 1, teamPlayers[1], teamPlayerCount[1], teamStats[1], teamStats[2], false);
		end
			
		-- right team
		local ix = padx;
		iy = undertitley;
		if self.rightPlayer ~= nil and players[self.rightPlayer].connected then
			self:drawPlayerCard(ix, iy, w/2-padx, 530, players[self.rightPlayer], nil, true);
		else
			self:drawTeamCard(ix, iy, w/2-padx, 530, 2, teamPlayers[2], teamPlayerCount[2], teamStats[2], teamStats[1], true);
		end
		iy = iy + 570;

	elseif gameMode.shortName == "1v1" or gameMode.shortName == "a1v1" then

		-- first player
		local player = realPlayers[1];
		if player ~= nil then
			local ix = -w/2;
			self:drawPlayerCard(ix, iy, w/2-padx, 530, player, realPlayers[2]);
		end

		-- second player
		-- (still need to handle rightPlayer being overridden, happens if you click on editor / spec)
		local ix = padx;
		if self.rightPlayer ~= nil and players[self.rightPlayer].connected then
			self:drawPlayerCard(ix, iy, w/2-padx, 530, players[self.rightPlayer], nil, true);
		else
			local player = realPlayers[2];
			if player ~= nil then
				iy = undertitley;
				self:drawPlayerCard(ix, iy, w/2-padx, 530, player, realPlayers[1], true);
			end
		end
		
		iy = undertitley + 570;

	elseif gameMode.shortName == "ffa" or gameMode.shortName == "affa" then

		-- detailed player on left
		local player = getPlayer();
		if player ~= nil then
			local ix = -w/2;
			self:drawPlayerCard(ix, iy, w/2-padx, 530, player);
			iy = iy + 570;
		end

		-- player list on right
		local ix = padx;
		iy = undertitley;
		if self.rightPlayer ~= nil and players[self.rightPlayer].connected then
			self:drawPlayerCard(ix, iy, w/2-padx, 530, players[self.rightPlayer], nil, true);
		else
			self:drawPlayerList(ix, iy, w/2-padx, 530, realPlayers, realPlayerCount, true);
		end
		iy = iy + 570;

	elseif gameMode.shortName == "training" then

		-- detailed player on left
		local player = getPlayer();
		if player ~= nil then
			local ix = -w/2;
			self:drawPlayerCard(ix, iy, w/2-padx, 530, player);
			iy = iy + 570;
		end

		-- player list on right
		local ix = padx;
		iy = undertitley;
		self:drawTrainingCard(ix, iy, w/2-padx, 530, true);
		iy = iy + 570;

	elseif gameMode.shortName == "race" then
		table.sort(realPlayers, sortForRaceMode);

		-- detailed player on left
		local player = getPlayer();
		if player ~= nil then
			local ix = -w/2;
			-- self:drawPlayerCard(ix, iy, w/2-padx, 530, player);
			self:drawRaceLeaderboard(ix, iy, w/2-padx, 530, player, false);
			iy = iy + 570;
		end
			

		-- player list on right
		local ix = padx;
		iy = undertitley;
		if self.rightPlayer ~= nil and players[self.rightPlayer].connected then
			self:drawPlayerCard(ix, iy, w/2-padx, 530, players[self.rightPlayer], nil, true);
		else
			self:drawPlayerList(ix, iy, w/2-padx, 530, realPlayers, realPlayerCount, true);
		end
		iy = iy + 570;

	end
	
	-- draw footer
	if footerHeight > 0 then
		self:drawFooter(-w/2, iy, w, 
			queuedPlayers, queued,
			spectatorPlayers, spectators,
			editorPlayers, editors,
			refereePlayers, referees);
		iy = iy + footerHeight;
		iy = iy + 40;
	end

	-- draw gameplay returns timer
	self:drawGameplayReturnsTimer(w/2-20, iy-20);

	-- draw sparks on top
	SparksEmitter:update(deltaTimeRaw);
	SparksEmitter:draw();

	-- draw explosions on top
	ExplosionEmitter:update(deltaTimeRaw);
	ExplosionEmitter:draw();

	-- state stuff for experience grown
	self.lastSecondsGrown = GetSecondsGrown();
end
