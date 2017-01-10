-- CheckpointTable by Kawumm
require "base/internal/ui/CheckCore"
require "base/internal/ui/reflexcore"

CheckpointTable = {canHide = true ; canPosition = true; alpha=1}

function CheckpointTable:initialize()
	self.userData = loadUserData();
	CheckSetDefaultValue(self, "userData", "table", {});
	CheckSetDefaultValue(self.userData, "showSpeed", "boolean", true);
	CheckSetDefaultValue(self.userData, "showDistance", "boolean", true);
	CheckSetDefaultValue(self.userData, "showDelta", "boolean", true);
	CheckSetDefaultValue(self.userData, "useTotal", "boolean", false);
	CheckSetDefaultValue(self.userData, "hideDuringRun", "boolean", false);
end

function CheckpointTable:draw()

	local user = self.userData;
	
	if (user.hideDuringRun and self.player.raceActive) or not shouldShowHUD() or not isRaceMode() or CheckCore.player == nil then return end;
	
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
	if user.showDelta then 
			frameWidth=frameWidth+colTimeDeltaWidth;
		end
	if user.showSpeed then 
		frameWidth=frameWidth+colSpeedWidth;
		if user.showDelta then 
			frameWidth=frameWidth+colSpeedDeltaWidth;
		end
	end
	if user.showDistance then 
		frameWidth=frameWidth+colDistanceWidth; 
		if user.showDelta then 
			frameWidth=frameWidth+colDistanceDeltaWidth;
		end
	end

    nvgBeginPath();
    nvgRoundedRect(-colTimeWidth-20, -frameHeight/2, frameWidth+40, (#CheckCore.checkpoints+1)*frameHeight*1.15, 5);
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
	
	local newSpeed = CheckCore.currentSpeed;
	local newTime = CheckCore.currentSector.timeTot;
	local newDistance = CheckCore.currentSector.distanceTot;
	
	local oldSpeed = 0; 
	local oldTime = 0;
	local oldDistance = 0;
	
	local deltaSpeed = 0;
	local deltaTime = 0;
	local deltaDistance = 0;
	
	local tmpText = "";
	
	if CheckCore.activeStored[CheckCore.lastCheckpointNo+1] ~= nil then
		oldSpeed = CheckCore.activeStored[CheckCore.lastCheckpointNo+1].speed;
		oldTime = CheckCore.activeStored[CheckCore.lastCheckpointNo+1].cTime;
		oldDistance = CheckCore.activeStored[CheckCore.lastCheckpointNo+1].distance;
	else
		deltaError = true;
	end
	
	if user.useTotal == false then
		newTime = CheckCore.currentSector.timeRel;
		newDistance = CheckCore.currentSector.distanceRel;
		
		if CheckCore.lastCheckpointNo > 0 and CheckCore.activeStored[CheckCore.lastCheckpointNo] ~= nil then
		oldTime = oldTime - CheckCore.activeStored[CheckCore.lastCheckpointNo].cTime;
		oldDistance = oldDistance - CheckCore.activeStored[CheckCore.lastCheckpointNo].distance;
		end
	end
	
	deltaTime = newTime - oldTime;
	deltaDistance = newDistance - oldDistance;
	deltaSpeed = newSpeed - oldSpeed;
		
	tmpText = CheckCore.player.name .. " vs. (" .. CheckCore.activeStoredName .. ")";
	-- tmpText = CheckCore.player.steamId .. " vs. (" .. CheckCore.activeStoredName .. ")"; Maybe change this to steamId later
	
	nvgFontBlur(2);
	nvgFillColor(blackColor);
	nvgText(frameWidth-colTimeWidth, -1*fontSize, tmpText);
	nvgText(frameWidth-colTimeWidth, -1*fontSize, tmpText);
	nvgText(frameWidth-colTimeWidth, -1*fontSize, tmpText);
	nvgFontBlur(0);	
	nvgFillColor(fontColor);
	nvgText(frameWidth-colTimeWidth, -1*fontSize, tmpText);
		
	if CheckCore.player.raceActive == false or CheckCore.raceState == C_RACE_STATE_PRERUN then
		nvgText(0, (0)*fontSize, "---"); 
		if user.showDelta then
			xOffset = xOffset + colTimeDeltaWidth;
			nvgText(xOffset, (0)*fontSize, "(---)");  
		end
		xOffset = xOffset + colSpeedWidth;
		
		if user.showSpeed then 
			nvgText(xOffset, (0)*fontSize, "---"); 
			if user.showDelta then
				xOffset = xOffset + colSpeedDeltaWidth;
				nvgText(xOffset, (0)*fontSize, "(---)");  
			end
			xOffset = xOffset + colDistanceWidth; 
		end
		
		if user.showDistance then 
			nvgText(xOffset, (0)*fontSize, "---"); 
			if user.showDelta then
				xOffset = xOffset + colDistanceDeltaWidth;
				nvgText(xOffset, (0)*fontSize, "(---)");  
			end
			
			xOffset = xOffset + col3width; 
		end
	else
		nvgText(0, (0)*fontSize, FormatTimeToDecimalTime(newTime)); 
		if user.showDelta then
			xOffset = xOffset + colTimeDeltaWidth;
			
			if deltaError then 
				tmpText ="(---)"
			else
				tmpText ="(" .. CheckCore:FormatTimeDelta(deltaTime) .. ")";
			end
			
			nvgText(xOffset, (0)*fontSize, tmpText);  
		end
		
		xOffset = xOffset + colSpeedWidth;
		
		if user.showSpeed then 
			nvgText(xOffset, (0)*fontSize, newSpeed .. "ups");
			if user.showDelta then
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
		
		if user.showDistance then 
			nvgText(xOffset, (0)*fontSize, newDistance .. "u"); 
			
			if user.showDelta then
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
	
	for i, check in ipairs(CheckCore.checkpoints) do
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
		
		if CheckCore.activeStored[i] ~= nil then
			oldSpeed = CheckCore.activeStored[i].speed;
			oldTime = CheckCore.activeStored[i].cTime;
			oldDistance = CheckCore.activeStored[i].distance;
		else
			deltaError = true;
		end

		local timeColor = whiteColor;
		local distColor = whiteColor;
		local speedColor = whiteColor;
		
		-- yOffset = #CheckCore.checkpoints-i+1; (old ordering)
		yOffset=i;
		
		if user.useTotal == false and i > 1 then
			newTime = check.cTime - CheckCore.checkpoints[i-1].cTime;
			newDistance = check.distance - CheckCore.checkpoints[i-1].distance;
			if CheckCore.activeStored[i-1] ~= nil then
				oldTime = oldTime - CheckCore.activeStored[i-1].cTime;
				oldDistance = oldDistance - CheckCore.activeStored[i-1].distance;
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
			
			if user.showDelta then
				nvgFillColor(timeColor);
				xOffset = xOffset + colTimeDeltaWidth;
				if deltaError then 
					nvgFillColor(whiteColor);
					tmpText ="(---)"
				else
					tmpText ="(" .. CheckCore:FormatTimeDelta(deltaTime) .. ")";
				end
				nvgText(xOffset, (yOffset)*fontSize, tmpText);  
			end
			
			xOffset = xOffset + colSpeedWidth;
			
			if user.showSpeed then 
				nvgFillColor(whiteColor);
				nvgText(xOffset, (yOffset)*fontSize, newSpeed .. "ups"); 
				
				if user.showDelta then
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
			
			if user.showDistance then 
				nvgFillColor(whiteColor);
				nvgText(xOffset, (yOffset)*fontSize, newDistance .. "u"); 
				
				if user.showDelta then
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

function CheckpointTable:onNewCheckpoint()
end

function CheckpointTable:onFinish()
end

function CheckpointTable:drawOptions(x, y, intensity)
	local optargs = {};
	optargs.intensity = intensity;
	 
	local user = self.userData;
	 
	user.showSpeed = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Show speeds", user.showSpeed, optargs);
	y = y + 60;
	 
	user.showDistance = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Show distances", user.showDistance, optargs);
	y = y + 60;
	 
	user.showDelta = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Show delta times", user.showDelta, optargs);
	y = y + 60;
	 
	user.useTotal = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Use total measurements", user.useTotal, optargs);
	y = y + 60;
	 
	user.hideDuringRun = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Hide during run", user.hideDuringRun, optargs);
	y = y + 60;
	 
	 
	 saveUserData(user);
end

registerWidget("CheckpointTable");
CheckCore:registerWidget("CheckpointTable");
