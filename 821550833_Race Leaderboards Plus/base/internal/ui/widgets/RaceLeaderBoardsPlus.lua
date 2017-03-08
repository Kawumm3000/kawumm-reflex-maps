--------------------------------------------------------------------------------
-- This code is based on Reflex 0.48.0 ScoreboardPlusRace widget, cloned and modified by Kawumm to add leaderboards for race mode
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"
require "base/internal/ui/widgets/Scoreboard"
require "LeaderboardHelpers"

RaceLeaderboardsPlus =
{
	canPosition = false,
	canHide = false,
	replacedFlag = false,
};

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local colScores = Color(190, 170, 170);
local colBackground = Color(0,0,0,160);
local colBorder = Color(150, 150, 150, 150);
local alphaFade = 150;
local padx = 15;

local RATING_CHANGE_TIME = 7

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
	SparksEmitter.sparks[i].cs = Color(255,255,255,255);
	SparksEmitter.sparks[i].ce = Color(255,255,255,255);
end

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


function RaceLeaderboardsPlus:show() 
	local user = self.userData
	if user.enabled and not self.replacedFlag then
		if _G["Scoreboard"].drawPlayerCard ~=nil then
			Scoreboard.orgPlayerCard = _G["Scoreboard"].drawPlayerCard;
			_G["Scoreboard"].drawPlayerCard = Scoreboard.drawNewPlayerCard;
			self.replacedFlag = true;
		else
			consolePrint("(Race Leaderboards Plus) Failed to modify reflex scoreboard. Are you using a custom scoreboard widget?")
		end
		consolePerformCommand("ui_show_widget Scoreboard");
	end
end

function Scoreboard:drawNewPlayerCard(x, y, w, h, player, otherPlayer, isRight)
	if isRight or not isRaceMode() then
		self:orgPlayerCard(x, y, w, h, player, otherPlayer, isRight)
		return;
	end
	
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
	Scoreboard:drawNewRaceStats(x, y, w, isRight, player, isPlaying);
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
		local i = rank;

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

--edited by Kawumm
function Scoreboard:drawNewRaceStats(x, y, w, isRight, player, isPlaying)
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

function RaceLeaderboardsPlus:draw()
end

function RaceLeaderboardsPlus:initialize()
	self.userData = loadUserData();
	CheckSetDefaultValue(self, "userData", "table", {});
	CheckSetDefaultValue(self.userData, "enabled", "boolean", true);
end

function RaceLeaderboardsPlus:drawOptions(x, y, intensity)
	local optargs = {};
	optargs.intensity = intensity;
	 
	local user = self.userData;
	user.enabled = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Enabled (requires restart)", user.enabled, optargs);
	y = y + 60;
	 
	
	saveUserData(user);
end

registerWidget("RaceLeaderboardsPlus");