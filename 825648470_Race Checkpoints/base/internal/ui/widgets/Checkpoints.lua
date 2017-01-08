--------------------------------------------------------------------------------
-- Race Checkpoints by Kawumm
--------------------------------------------------------------------------------
C_RACE_STATE_PRERUN = 1 -- mostly used for invalid runs. display nothing, wait for start.
C_RACE_STATE_RUN = 2 -- currently running and valid.
C_RACE_STATE_JUST_FINISHED = 3 -- do finish stuff.
C_RACE_STATE_FINISHED = 4 -- after run, display checkpoint table.

require "base/internal/ui/reflexcore"

Checkpoints =
{
	currentCheckpointTime = { },
	lastCheckpointTime = 0,
	currentCheckpointDistance = { },
	lastCheckpointDistance = 0,
	currentCheckpoint = 0,
	startDistance = 0,
	alpha = 1,
	lastMessage = "",
	raceState = C_RACE_STATE_PRERUN,
	recordNum = 0,
	lastPlayer = nil,
	currentPlayer = nil,
	lastLogIdRead = 0,
	speed = 0,
	raceTime = 0,
	checkPoints = { 
	},
	storedCheckpoints = {
	},
	showSpeed = true,
	showDistance = true,
	showDelta = true,
	useTotal = false,
	hideDuringRun = false,
	strictMessages = true,
	autoSave =false,
};
registerWidget("Checkpoints");

function Checkpoints:initialize()
    widgetCreateConsoleVariable("store","int","0");
	widgetCreateConsoleVariable("showSpeed","int","1");
	widgetCreateConsoleVariable("showDistance","int","1");
	widgetCreateConsoleVariable("useTotal","int","0");
	widgetCreateConsoleVariable("showDelta","int","1");
	widgetCreateConsoleVariable("beep","int","0");
	widgetCreateConsoleVariable("hideDuringRun","int","0");
	widgetCreateConsoleVariable("strictMessages","int","1");
	widgetCreateConsoleVariable("autoSave","int","0");
	
	self.userData = loadUserData();
	CheckSetDefaultValue(self, "userData", "table", {});
	CheckSetDefaultValue(self.userData, "maps", "table", {});
end

function Checkpoints:finalize()
	saveUserData(self.userData);
end

function Checkpoints:FormatTimeDelta(msTime) 
	if msTime < 0 then 
		return "-" .. FormatTimeToDecimalTime(-msTime);
	else
		return "+" .. FormatTimeToDecimalTime(msTime);
	end
end

function Checkpoints:reset() 
		self.checkPoints = { };
		self.currentCheckpoint = 0;
		self.lastCheckpointTime = 0;
		self.lastCheckpointDistance = 0;
		self.startDistance= self.player.stats.distanceTravelled;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Checkpoints:onNewCheckpoint() 
	-- if self.beep then playSound("internal/misc/chat"); end
	local newCheckpoint = {
		speed = self.speed;
		cTime = self.raceTime;
		distance = self.player.stats.distanceTravelled - self.startDistance;
		}
	table.insert(self.checkPoints, newCheckpoint);
	self.lastCheckpointTime = self.raceTime;
	self.lastCheckpointDistance = newCheckpoint.distance;
	self.currentCheckpoint = self.currentCheckpoint + 1;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Checkpoints:onFinish() 
	local newCheckpoint = {
		speed = self.speed;
		cTime = self.player.raceTimePrevious;
		distance = self.player.stats.distanceTravelled - self.startDistance;
		}
	table.insert(self.checkPoints, newCheckpoint);
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Checkpoints:drawTable()
	if self.hideDuringRun and self.player.raceActive then return end;
	
	local redColor = Color(230, 0, 0, self.alpha*255);
	local greenColor = Color(0, 230, 0, self.alpha*255);
	local whiteColor = Color(230, 230, 230, self.alpha*255);
	local blackColor = Color(0,0,0, self.alpha*255);
	
	local frameColor = Color(0,0,0,self.alpha*128);
    local frameWidth = 500;
    local frameHeight = 35;
	
	local colTimeWidth = 160;
	local colTimeDeltaWidth = 160;
	local colSpeedWidth = 150;
	local colSpeedDeltaWidth = 100;
	local colDistanceWidth = 150;
	local colDistanceDeltaWidth = 110;
	local col3width = 150;
	
	local deltaError = false;
	
	frameWidth = colTimeWidth;
	if self.showDelta then 
			frameWidth=frameWidth+colTimeDeltaWidth;
		end
	if self.showSpeed then 
		frameWidth=frameWidth+colSpeedWidth;
		if self.showDelta then 
			frameWidth=frameWidth+colSpeedDeltaWidth;
		end
	end
	if self.showDistance then 
		frameWidth=frameWidth+colDistanceWidth; 
		if self.showDelta then 
			frameWidth=frameWidth+colDistanceDeltaWidth;
		end
	end

    nvgBeginPath();
    nvgRoundedRect(-colTimeWidth-20, -frameHeight/2, frameWidth+40, (#self.checkPoints+1)*frameHeight*1.15, 5);
    nvgFillColor(frameColor); 
    nvgFill();


	local fontColor = Color(230, 230, 230, self.alpha*255);
    local fontSize = frameHeight * 1.15;
	
	local xOffset = 0
	
	nvgFontSize(fontSize);
	nvgFontFace(FONT_TEXT2_BOLD);
	nvgTextAlign(NVG_ALIGN_RIGHT, NVG_ALIGN_MIDDLE);

	nvgFontBlur(0);
	nvgFillColor(fontColor);
	
	local newSpeed = self.speed;
	local newTime = self.currentCheckpointTime.abs;
	local newDistance = self.currentCheckpointDistance.abs;
	
	local oldSpeed = 0; 
	local oldTime = 0;
	local oldDistance = 0;
	
	local deltaSpeed = 0;
	local deltaTime = 0;
	local deltaDistance = 0;
	
	local tmpText = "";
	
	if self.storedCheckpoints[self.currentCheckpoint+1] ~= nil then
		oldSpeed = self.storedCheckpoints[self.currentCheckpoint+1].speed;
		oldTime = self.storedCheckpoints[self.currentCheckpoint+1].cTime;
		oldDistance = self.storedCheckpoints[self.currentCheckpoint+1].distance;
	else
		deltaError = true;
	end
	
	if self.useTotal == false then
		newTime = self.currentCheckpointTime.abs - self.lastCheckpointTime;
		newDistance = self.currentCheckpointDistance.abs - self.lastCheckpointDistance;
		
		if self.currentCheckpoint > 0 and self.storedCheckpoints[self.currentCheckpoint] ~= nil then
		oldTime = oldTime - self.storedCheckpoints[self.currentCheckpoint].cTime;
		oldDistance = oldDistance - self.storedCheckpoints[self.currentCheckpoint].distance;
		end
	end
	
	deltaTime = newTime - oldTime;
	deltaDistance = newDistance - oldDistance;
	deltaSpeed = newSpeed - oldSpeed;
		
	nvgFontBlur(2);
	nvgFillColor(blackColor);
	nvgText(0, -1*fontSize, "(Kawumm)");
	nvgText(0, -1*fontSize, "(Kawumm)");
	nvgText(0, -1*fontSize, "(Kawumm)");
	nvgFontBlur(0);	
	nvgFillColor(fontColor);
	nvgText(0, -1*fontSize, "(Kawumm)");
		
	if self.player.raceActive == false or self.raceState == C_RACE_STATE_PRERUN then
		nvgText(0, (0)*fontSize, "---"); 
		if self.showDelta then
			xOffset = xOffset + colTimeDeltaWidth;
			nvgText(xOffset, (0)*fontSize, "(---)");  
		end
		xOffset = xOffset + colSpeedWidth;
		
		if self.showSpeed then 
			nvgText(xOffset, (0)*fontSize, "---"); 
			if self.showDelta then
				xOffset = xOffset + colSpeedDeltaWidth;
				nvgText(xOffset, (0)*fontSize, "(---)");  
			end
			xOffset = xOffset + colDistanceWidth; 
		end
		
		if self.showDistance then 
			nvgText(xOffset, (0)*fontSize, "---"); 
			if self.showDelta then
				xOffset = xOffset + colDistanceDeltaWidth;
				nvgText(xOffset, (0)*fontSize, "(---)");  
			end
			
			xOffset = xOffset + col3width; 
		end
	else
		nvgText(0, (0)*fontSize, FormatTimeToDecimalTime(newTime)); 
		if self.showDelta then
			xOffset = xOffset + colTimeDeltaWidth;
			
			if deltaError then 
				tmpText ="(---)"
			else
				tmpText ="(" .. Checkpoints:FormatTimeDelta(deltaTime) .. ")";
			end
			
			nvgText(xOffset, (0)*fontSize, tmpText);  
		end
		
		xOffset = xOffset + colSpeedWidth;
		
		if self.showSpeed then 
			nvgText(xOffset, (0)*fontSize, newSpeed .. "ups");
			if self.showDelta then
				xOffset = xOffset + colSpeedDeltaWidth;
				
				if deltaError then 
					tmpText ="(---)"
				else
					tmpText ="(" .. deltaSpeed .. ")";
				end
				
				nvgText(xOffset, (0)*fontSize, tmpText);  
			end
			xOffset = xOffset + colDistanceWidth; 
		end
		
		if self.showDistance then 
			nvgText(xOffset, (0)*fontSize, newDistance .. "u"); 
			
			if self.showDelta then
				xOffset = xOffset + colDistanceDeltaWidth;
				
				if deltaError then 
					tmpText ="(---)"
				else
					tmpText ="(" .. deltaDistance .. ")";
				end
				
				nvgText(xOffset, (0)*fontSize, tmpText);  
			end
			xOffset = xOffset + col3width; 
		end
		
	end
	
	deltaError = false;
	
	xOffset = 0;
	local yOffset = 0;
	
	for i, check in ipairs(self.checkPoints) do
	--	check.speed;
		--check.cTime;
	local newSpeed = check.speed;
	local newTime = check.cTime;
	local newDistance = check.distance;
	
	local oldSpeed = 0;
	local oldTime = 0;
	local oldDistance = 0;
	
	local deltaSpeed = 0;
	local deltaTime = 0;
	local deltaDistance = 0;
	
	if self.storedCheckpoints[i] ~= nil then
		oldSpeed = self.storedCheckpoints[i].speed;
		oldTime = self.storedCheckpoints[i].cTime;
		oldDistance = self.storedCheckpoints[i].distance;
	else
		deltaError = true;
	end

	local timeColor = whiteColor;
	local distColor = whiteColor;
	local speedColor = whiteColor;
	
	-- yOffset = #self.checkPoints-i+1; (old ordering)
	yOffset=i;
	
	if self.useTotal == false and i > 1 then
		newTime = check.cTime - self.checkPoints[i-1].cTime;
		newDistance = check.distance - self.checkPoints[i-1].distance;
		if self.storedCheckpoints[i-1] ~= nil then
			oldTime = oldTime - self.storedCheckpoints[i-1].cTime;
			oldDistance = oldDistance - self.storedCheckpoints[i-1].distance;
		end
	end
	

	deltaTime = newTime - oldTime;
	if deltaTime > 0 then timeColor = redColor else timeColor = greenColor; end
	deltaDistance = newDistance - oldDistance;
	if deltaDistance > 0 then distColor = redColor else distColor = greenColor; end
	deltaSpeed = newSpeed - oldSpeed;
	if deltaSpeed < 0 then speedColor = redColor else speedColor = greenColor; end

	
		nvgFillColor(whiteColor);
		nvgText(0, (yOffset)*fontSize, i .. ": " .. FormatTimeToDecimalTime(newTime)); 
		
		if self.showDelta then
			nvgFillColor(timeColor);
			xOffset = xOffset + colTimeDeltaWidth;
			if deltaError then 
				nvgFillColor(whiteColor);
				tmpText ="(---)"
			else
				tmpText ="(" .. Checkpoints:FormatTimeDelta(deltaTime) .. ")";
			end
			nvgText(xOffset, (yOffset)*fontSize, tmpText);  
		end
		
		xOffset = xOffset + colSpeedWidth;
		
		if self.showSpeed then 
			nvgFillColor(whiteColor);
			nvgText(xOffset, (yOffset)*fontSize, newSpeed .. "ups"); 
			
			if self.showDelta then
				nvgFillColor(speedColor);
				xOffset = xOffset + colSpeedDeltaWidth;
				if deltaError then 
					nvgFillColor(whiteColor);
					tmpText ="(---)"
				elseif deltaSpeed < 0 then 
					tmpText = "(" .. deltaSpeed.. ")" 
				else 
					tmpText = "(+" .. deltaSpeed.. ")" 
				end
				nvgText(xOffset, (yOffset)*fontSize, tmpText);  
			end
			
			xOffset = xOffset + colDistanceWidth; 
		end
		
		if self.showDistance then 
			nvgFillColor(whiteColor);
			nvgText(xOffset, (yOffset)*fontSize, newDistance .. "u"); 
			
			if self.showDelta then
				nvgFillColor(distColor);
				xOffset = xOffset + colDistanceDeltaWidth;
				
				if deltaError then 
					nvgFillColor(whiteColor);
					tmpText ="(---)"
				elseif deltaDistance < 0 then 
					tmpText = "(" .. deltaDistance.. ")" 
				else 
					tmpText = "(+" .. deltaDistance.. ")" 
				end
				nvgText(xOffset, (yOffset)*fontSize, tmpText);  
			end
			
			xOffset = xOffset + col3width;
		end

	deltaError = false;
	xOffset= 0;
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Checkpoints:draw()

	if not isRaceMode() then return end;

	
	

	if self.userData.maps["m_" .. world.mapName] ~= nil then self.storedCheckpoints = self.userData.maps["m_" .. world.mapName].checkPoints; end
	
	local store = widgetGetConsoleVariable("store");
	
	self.showSpeed = (widgetGetConsoleVariable("showSpeed") ~= 0);
	self.showDistance = (widgetGetConsoleVariable("showDistance") ~= 0);
	self.useTotal = (widgetGetConsoleVariable("useTotal") ~= 0);
	self.showDelta = (widgetGetConsoleVariable("showDelta") ~= 0);
	self.hideDuringRun = (widgetGetConsoleVariable("hideDuringRun") ~= 0);
	self.beep = (widgetGetConsoleVariable("beep") ~= 0);
	self.strictMessages = (widgetGetConsoleVariable("strictMessages") ~= 0);
	self.autoSave = (widgetGetConsoleVariable("autoSave") ~= 0);
	
	-- Autosave
	if self.autoSave and self.raceState == C_RACE_STATE_JUST_FINISHED then
		if self.storedCheckpoints[#self.checkPoints] == nil or self.checkPoints[#self.checkPoints].cTime < self.storedCheckpoints[#self.checkPoints].cTime then
			store = 1;
		end
	end
	
	-- Save
	if store ~= 0 then
		widgetSetConsoleVariable("store","0");
		
		self.userData.maps["m_" .. world.mapName] = { checkPoints = self.checkPoints, kaduudle = 435 }
		saveUserData(self.userData);
		self.userData = loadUserData();
	end	
	
	self.player = getPlayer()
	if not self.player then return end;
    self.speed = math.ceil(self.player.speed)
	self.raceTime = self.player.raceTimeCurrent;
	self.currentCheckpointTime = {
		rel = self.raceTime - self.lastCheckpointTime; 
		abs = self.raceTime;
		}
		
	self.currentCheckpointDistance = {
	rel = self.player.stats.distanceTravelled - self.startDistance - self.lastCheckpointDistance;
	abs = self.player.stats.distanceTravelled - self.startDistance;
}
	-- Check for player switch
	if self.lastPlayer ~= self.player.name then
		Checkpoints:reset();
		self.lastPlayer = self.player.name;
		self.raceState = C_RACE_STATE_PRERUN;
	end
	
	
	-- Check which state we are in
	if not self.player.raceActive then
		if self.raceState == C_RACE_STATE_RUN then
			self.raceState = C_RACE_STATE_FINISHED;
			-- Check for finish log entry (this part is taken from official RaceRecords widget)
			local logCount = 0;
			for k, v in pairs(log) do
				logCount = logCount + 1;
			end
			
			-- read log messages
			for i = 1, logCount do
				local logEntry = log[i];

				-- only read newer entries
				if self.lastLogIdRead < logEntry.id then
					self.lastLogIdRead = logEntry.id;
					
					if logEntry.type == LOG_TYPE_RACEEVENT and logEntry.racePlayerIndex == self.player.index then

						-- race finished? 
						if (logEntry.raceEvent == RACE_EVENT_FINISH) or (logEntry.raceEvent == RACE_EVENT_FINISHANDWASRECORD) then
							self.raceState = C_RACE_STATE_JUST_FINISHED;
						end

					end
				end
			end	
		else
			self.raceState = C_RACE_STATE_FINISHED;
		end
	elseif self.raceState == C_RACE_STATE_FINISHED then
		Checkpoints:reset();
		self.raceState = C_RACE_STATE_RUN;
	end
	
	-- Reached new Checkpoint?
	if string.len(message.text) > 0 and self.raceState == C_RACE_STATE_RUN then
		if (message.text == "Checkpoint " .. self.currentCheckpoint+1) or (string.find(message.text, "^Checkpoint " .. self.currentCheckpoint+1 .. "[^%d]")~=nil) or (not self.strictMessages) then
			if (message.text ~= self.lastMessage) then
				Checkpoints:onNewCheckpoint();
			end
		end
	
	end
	
	self.lastMessage = message.text;
	
	-- Add last Checkpoint when finished
	if self.raceState == C_RACE_STATE_JUST_FINISHED then
		Checkpoints:onFinish();
	end
	
	
    -- Actual Drawing
    if not shouldShowHUD() then return end;
	Checkpoints:drawTable();
end
