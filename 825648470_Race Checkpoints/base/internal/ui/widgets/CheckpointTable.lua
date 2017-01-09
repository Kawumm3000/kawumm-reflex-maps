-- CheckpointTable by Kawumm

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
	
	if (user.hideDuringRun and self.player.raceActive) or not shouldShowHUD() or not isRaceMode() then return end;
	
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
    nvgRoundedRect(-colTimeWidth-20, -frameHeight/2, frameWidth+40, (#Checkpoints.checkpoints+1)*frameHeight*1.15, 5);
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
	
	local newSpeed = Checkpoints.currentSpeed;
	local newTime = Checkpoints.currentSector.timeTot;
	local newDistance = Checkpoints.currentSector.distanceTot;
	
	local oldSpeed = 0; 
	local oldTime = 0;
	local oldDistance = 0;
	
	local deltaSpeed = 0;
	local deltaTime = 0;
	local deltaDistance = 0;
	
	local tmpText = "";
	
	if Checkpoints.storedCheckpoints[Checkpoints.lastCheckpointNo+1] ~= nil then
		oldSpeed = Checkpoints.storedCheckpoints[Checkpoints.lastCheckpointNo+1].speed;
		oldTime = Checkpoints.storedCheckpoints[Checkpoints.lastCheckpointNo+1].cTime;
		oldDistance = Checkpoints.storedCheckpoints[Checkpoints.lastCheckpointNo+1].distance;
	else
		deltaError = true;
	end
	
	if user.useTotal == false then
		newTime = Checkpoints.currentSector.timeRel;
		newDistance = Checkpoints.currentSector.distanceRel;
		
		if Checkpoints.lastCheckpointNo > 0 and Checkpoints.storedCheckpoints[Checkpoints.lastCheckpointNo] ~= nil then
		oldTime = oldTime - Checkpoints.storedCheckpoints[Checkpoints.lastCheckpointNo].cTime;
		oldDistance = oldDistance - Checkpoints.storedCheckpoints[Checkpoints.lastCheckpointNo].distance;
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
		
	if Checkpoints.player.raceActive == false or Checkpoints.raceState == C_RACE_STATE_PRERUN then
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
				tmpText ="(" .. Checkpoints:FormatTimeDelta(deltaTime) .. ")";
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
	
	for i, check in ipairs(Checkpoints.checkpoints) do
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
		
		if Checkpoints.storedCheckpoints[i] ~= nil then
			oldSpeed = Checkpoints.storedCheckpoints[i].speed;
			oldTime = Checkpoints.storedCheckpoints[i].cTime;
			oldDistance = Checkpoints.storedCheckpoints[i].distance;
		else
			deltaError = true;
		end

		local timeColor = whiteColor;
		local distColor = whiteColor;
		local speedColor = whiteColor;
		
		-- yOffset = #Checkpoints.checkpoints-i+1; (old ordering)
		yOffset=i;
		
		if user.useTotal == false and i > 1 then
			newTime = check.cTime - Checkpoints.checkpoints[i-1].cTime;
			newDistance = check.distance - Checkpoints.checkpoints[i-1].distance;
			if Checkpoints.storedCheckpoints[i-1] ~= nil then
				oldTime = oldTime - Checkpoints.storedCheckpoints[i-1].cTime;
				oldDistance = oldDistance - Checkpoints.storedCheckpoints[i-1].distance;
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
					tmpText ="(" .. Checkpoints:FormatTimeDelta(deltaTime) .. ")";
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
Checkpoints:registerWidget("CheckpointTable");
