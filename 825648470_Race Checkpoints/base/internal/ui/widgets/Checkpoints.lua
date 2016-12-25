--------------------------------------------------------------------------------
-- Race Checkpoints by Kawumm
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"

Checkpoints =
{
	currentCheckpointTime = 0,
	lastCheckpointTime = 0,
	currentCheckpointDistance = 0,
	lastCheckpointDistance = 0,
	currentCheckpoint = 0,
	startDistance = 0,
	alpha = 1,
	newRace = false,
	lastMessage = "",
	finishSwitch = true,
	checkPoints = { 
	},
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
	
	self.userData = loadUserData();
	CheckSetDefaultValue(self, "userData", "table", {});
	CheckSetDefaultValue(self.userData, "maps", "table", {});
end

function Checkpoints:finalize()
end

function Checkpoints:FormatTimeDelta(msTime) 
	if msTime < 0 then 
		return "-" .. FormatTimeToDecimalTime(-msTime);
	else
		return "+" .. FormatTimeToDecimalTime(msTime);
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function Checkpoints:draw()

	if not isRaceMode() then return end;
	
	local redColor = Color(230, 0, 0, self.alpha*255);
	local greenColor = Color(0, 230, 0, self.alpha*255);
	local whiteColor = Color(230, 230, 230, self.alpha*255);
	
	local deltaError = false;
	
	local storedCheckpoints = {};
	if self.userData.maps["m_" .. world.mapName] ~= nil then storedCheckpoints = self.userData.maps["m_" .. world.mapName].checkPoints; end
	local store = widgetGetConsoleVariable("store");
	local showSpeed = (widgetGetConsoleVariable("showSpeed") ~= 0);
	local showDistance = (widgetGetConsoleVariable("showDistance") ~= 0);
	local useTotal = (widgetGetConsoleVariable("useTotal") ~= 0);
	local showDelta = (widgetGetConsoleVariable("showDelta") ~= 0);
	local hideDuringRun = (widgetGetConsoleVariable("hideDuringRun") ~= 0);
	local beep = (widgetGetConsoleVariable("beep") ~= 0);
	local strictMessages = (widgetGetConsoleVariable("strictMessages") ~= 0);
	
	if store ~= 0 then
		widgetSetConsoleVariable("store","0");
		
		self.userData.maps["m_" .. world.mapName] = { checkPoints = self.checkPoints }
		saveUserData(self.userData);
		self.userData = loadUserData();
	end	
	
	local player = getPlayer()
	if not player then return end;
    local speed = math.ceil(player.speed)
	local raceTime = player.raceTimeCurrent;
	local currentCheckpointTime = {
		rel = raceTime - self.lastCheckpointTime; 
		abs = raceTime;
		}
		
	local currentCheckpointDistance = {
	rel = player.stats.distanceTravelled - self.startDistance - self.lastCheckpointDistance;
	abs = player.stats.distanceTravelled - self.startDistance;
}
	


	-- Reached new Checkpoint?
	if string.len(message.text) > 0 then
		if (message.text == "Checkpoint " .. self.currentCheckpoint+1) or (not strictMessages) then
			if (message.text ~= self.lastMessage) then
				
				if beep then playSound("internal/misc/chat"); end
				local newCheckpoint = {
					speed = speed;
					cTime = raceTime;
					distance = player.stats.distanceTravelled - self.startDistance;
					}
				table.insert(self.checkPoints, newCheckpoint);
				self.lastCheckpointTime = raceTime;
				self.lastCheckpointDistance = newCheckpoint.distance;
				self.currentCheckpoint = self.currentCheckpoint + 1;
			end
		end
	
	end
	
	self.lastMessage = message.text;
	
	-- Add last Checkpoint when finished
	if not player.raceActive then
		self.newRace = true;
		if player.raceTimePrevious ~= 0 and self.finishSwitch == true then
		  self.finishSwitch = false;
		  local newCheckpoint = {
				speed = speed;
				cTime = player.raceTimePrevious;
				distance = player.stats.distanceTravelled - self.startDistance;
				}
			table.insert(self.checkPoints, newCheckpoint);
		end
		self.startDistance= player.stats.distanceTravelled;
	elseif self.newRace == true then
		self.finishSwitch = true;
		self.newRace = false;
		self.checkPoints = { };
		self.currentCheckpoint = 0;
		self.lastCheckpointTime = 0;
		self.lastCheckpointDistance = 0;
	end
	
	
    -- Actual Drawing
    if not shouldShowHUD() then return end;
	if hideDuringRun and player.raceActive then return end;
	
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
	
	frameWidth = colTimeWidth;
	if showDelta then 
			frameWidth=frameWidth+colTimeDeltaWidth;
		end
	if showSpeed then 
		frameWidth=frameWidth+colSpeedWidth;
		if showDelta then 
			frameWidth=frameWidth+colSpeedDeltaWidth;
		end
	end
	if showDistance then 
		frameWidth=frameWidth+colDistanceWidth; 
		if showDelta then 
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
	
	local newSpeed = speed;
	local newTime = currentCheckpointTime.abs;
	local newDistance = currentCheckpointDistance.abs;
	
	local oldSpeed = 0; 
	local oldTime = 0;
	local oldDistance = 0;
	
	local deltaSpeed = 0;
	local deltaTime = 0;
	local deltaDistance = 0;
	
	local tmpText = "";
	
	if storedCheckpoints[self.currentCheckpoint+1] ~= nil then
		oldSpeed = storedCheckpoints[self.currentCheckpoint+1].speed;
		oldTime = storedCheckpoints[self.currentCheckpoint+1].cTime;
		oldDistance = storedCheckpoints[self.currentCheckpoint+1].distance;
	else
		deltaError = true;
	end
	
	if useTotal == false then
		newTime = currentCheckpointTime.abs - self.lastCheckpointTime;
		newDistance = currentCheckpointDistance.abs - self.lastCheckpointDistance;
		
		if self.currentCheckpoint > 0 and storedCheckpoints[self.currentCheckpoint] ~= nil then
		oldTime = oldTime - storedCheckpoints[self.currentCheckpoint].cTime;
		oldDistance = oldDistance - storedCheckpoints[self.currentCheckpoint].distance;
		end
	end
	
	deltaTime = newTime - oldTime;
	deltaDistance = newDistance - oldDistance;
	deltaSpeed = newSpeed - oldSpeed;
	
	if player.raceActive == false then
		nvgText(0, (0)*fontSize, "---"); 
		if showDelta then
			xOffset = xOffset + colTimeDeltaWidth;
			nvgText(xOffset, (0)*fontSize, "(---)");  
		end
		xOffset = xOffset + colSpeedWidth;
		
		if showSpeed then 
			nvgText(xOffset, (0)*fontSize, "---"); 
			if showDelta then
				xOffset = xOffset + colSpeedDeltaWidth;
				nvgText(xOffset, (0)*fontSize, "(---)");  
			end
			xOffset = xOffset + colDistanceWidth; 
		end
		
		if showDistance then 
			nvgText(xOffset, (0)*fontSize, "---"); 
			if showDelta then
				xOffset = xOffset + colDistanceDeltaWidth;
				nvgText(xOffset, (0)*fontSize, "(---)");  
			end
			
			xOffset = xOffset + col3width; 
		end
	else
		nvgText(0, (0)*fontSize, FormatTimeToDecimalTime(newTime)); 
		if showDelta then
			xOffset = xOffset + colTimeDeltaWidth;
			
			if deltaError then 
				tmpText ="(---)"
			else
				tmpText ="(" .. Checkpoints:FormatTimeDelta(deltaTime) .. ")";
			end
			
			nvgText(xOffset, (0)*fontSize, tmpText);  
		end
		
		xOffset = xOffset + colSpeedWidth;
		
		if showSpeed then 
			nvgText(xOffset, (0)*fontSize, newSpeed .. "ups");
			if showDelta then
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
		
		if showDistance then 
			nvgText(xOffset, (0)*fontSize, newDistance .. "u"); 
			
			if showDelta then
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
	
	if storedCheckpoints[i] ~= nil then
		oldSpeed = storedCheckpoints[i].speed;
		oldTime = storedCheckpoints[i].cTime;
		oldDistance = storedCheckpoints[i].distance;
	else
		deltaError = true;
	end

	local timeColor = whiteColor;
	local distColor = whiteColor;
	local speedColor = whiteColor;
	
	if useTotal == false and i > 1 then
		newTime = check.cTime - self.checkPoints[i-1].cTime;
		newDistance = check.distance - self.checkPoints[i-1].distance;
		if storedCheckpoints[i-1] ~= nil then
			oldTime = oldTime - storedCheckpoints[i-1].cTime;
			oldDistance = oldDistance - storedCheckpoints[i-1].distance;
		end
	end
	

	deltaTime = newTime - oldTime;
	if deltaTime > 0 then timeColor = redColor else timeColor = greenColor; end
	deltaDistance = newDistance - oldDistance;
	if deltaDistance > 0 then distColor = redColor else distColor = greenColor; end
	deltaSpeed = newSpeed - oldSpeed;
	if deltaSpeed < 0 then speedColor = redColor else speedColor = greenColor; end

	
		nvgFillColor(whiteColor);
		nvgText(0, (#self.checkPoints-i+1)*fontSize, i .. ": " .. FormatTimeToDecimalTime(newTime)); 
		
		if showDelta then
			nvgFillColor(timeColor);
			xOffset = xOffset + colTimeDeltaWidth;
			if deltaError then 
				nvgFillColor(whiteColor);
				tmpText ="(---)"
			else
				tmpText ="(" .. Checkpoints:FormatTimeDelta(deltaTime) .. ")";
			end
			nvgText(xOffset, (#self.checkPoints-i+1)*fontSize, tmpText);  
		end
		
		xOffset = xOffset + colSpeedWidth;
		
		if showSpeed then 
			nvgFillColor(whiteColor);
			nvgText(xOffset, (#self.checkPoints-i+1)*fontSize, newSpeed .. "ups"); 
			
			if showDelta then
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
				nvgText(xOffset, (#self.checkPoints-i+1)*fontSize, tmpText);  
			end
			
			xOffset = xOffset + colDistanceWidth; 
		end
		
		if showDistance then 
			nvgFillColor(whiteColor);
			nvgText(xOffset, (#self.checkPoints-i+1)*fontSize, newDistance .. "u"); 
			
			if showDelta then
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
				nvgText(xOffset, (#self.checkPoints-i+1)*fontSize, tmpText);  
			end
			
			xOffset = xOffset + col3width;
		end

	deltaError = false;
	xOffset= 0;
	end

end
