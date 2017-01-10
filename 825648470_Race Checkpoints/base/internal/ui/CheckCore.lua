--------------------------------------------------------------------------------
-- Race Checkpoints by Kawumm
--------------------------------------------------------------------------------
C_RACE_STATE_PRERUN = 1 -- mostly used for invalid runs. display nothing, wait for start.
C_RACE_STATE_RUN = 2 -- currently running and valid.
C_RACE_STATE_JUST_FINISHED = 3 -- do finish stuff.
C_RACE_STATE_FINISHED = 4 -- after run, display checkpoint table.

require "base/internal/ui/reflexcore"

CheckCore =
{

	canHide = false; 
	canPosition = false;
	
	scrollingUsed = false;

	raceState = C_RACE_STATE_PRERUN, 
	
	currentSector = {
		timeTot = 0,
		timeRel = 0,
		
		distanceTot = 0,
		distanceRel = 0,
	},

	lastCheckpointNo = 0,

	lastCheckpoint = {
		time = 0,
		distance = 0,
	},
	
	currentSpeed = 0,
	currentRaceTime = 0,
	
	checkpoints = { 
	}, -- export
	
	activeStoredName = "NO_NAME",
	activeStored = {
	}, -- export
	allStored = {
	},

	_activeStoredIndex = 0,
	_startDistance = 0,
	_strictMessages = true,
	_autoSave = false,
	_saveToConfig = true,
	_widgets = {
	},
	_lastMessage = "",
	_lastPlayer = nil,
	_lastLogIdRead = 0,
	_lastMap = "",
};
registerWidget("CheckCore");

function CheckCore:initialize()
    widgetCreateConsoleVariable("store","int","0");
	widgetCreateConsoleVariable("next","int","0");
	widgetCreateConsoleVariable("previous","int","0");
	widgetCreateConsoleVariable("clearall","int","0");
	
	self.userData = loadUserData();
	CheckSetDefaultValue(self, "userData", "table", {});
	CheckSetDefaultValue(self.userData, "strictMessages", "boolean", true);
	CheckSetDefaultValue(self.userData, "autoSave", "boolean", true);
	CheckSetDefaultValue(self.userData, "saveToConfig", "boolean", true);
	CheckSetDefaultValue(self.userData, "active", "boolean", true);
	CheckSetDefaultValue(self.userData, "maps", "table", {});
end

function CheckCore:finalize()
	saveUserData(self.userData);
end

function CheckCore:FormatTimeDelta(msTime) 
	if msTime < 0 then 
		return "-" .. FormatTimeToDecimalTime(-msTime);
	else
		return "+" .. FormatTimeToDecimalTime(msTime);
	end
end

function CheckCore:registerWidget(widget) 
	table.insert(self._widgets, widget)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CheckCore:reset() 
		self.checkpoints = { };
		self.lastCheckpointNo = 0;
		self.lastCheckpoint.time = 0;
		self.lastCheckpoint.distance = 0;
		self._startDistance= self.player.stats.distanceTravelled;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CheckCore:flushData()
	self.userData.maps = { }
	saveUserData(self.userData);
	
	CheckCore:onMapChange()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CheckCore:onRaceStart() 
	for i, widget in ipairs(self._widgets) do
		if _G[widget].onRaceStart ~= nil then 
			_G[widget]:onRaceStart();
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CheckCore:onNewCheckpoint() 
	-- if self.beep then playSound("internal/misc/chat"); end
	local newCheckpoint = {
		speed = self.currentSpeed;
		cTime = self.currentRaceTime;
		distance = self.player.stats.distanceTravelled - self._startDistance;
		}
	table.insert(self.checkpoints, newCheckpoint);
	self.lastCheckpoint.time = self.currentRaceTime;
	self.lastCheckpoint.distance = newCheckpoint.distance;
	self.lastCheckpointNo = self.lastCheckpointNo + 1;
	
	for i, widget in ipairs(self._widgets) do
		if _G[widget].onNewCheckpoint ~= nil then 
			_G[widget]:onNewCheckpoint();
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CheckCore:onFinish() 
	local newCheckpoint = {
		speed = self.currentSpeed;
		cTime = self.player.raceTimePrevious;
		distance = self.player.stats.distanceTravelled - self._startDistance;
		}
	table.insert(self.checkpoints, newCheckpoint);
	
	for i, widget in ipairs(self._widgets) do
		if _G[widget].onFinish ~= nil then 
			_G[widget]:onFinish();
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CheckCore:onMapChange()
	self._lastMap = world.mapName
	self.allStored = { };
	self.activeStored = { };
	self.activeStoredName = "NO_NAME";
	
	self.scrollingUsed = false;
	if self.userData.maps["m_" .. world.mapName] ~= nil and self._saveToConfig then 
		self.allStored = self.userData.maps["m_" .. world.mapName];
	end
	CheckCore:onPlayerSwitch()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


function CheckCore:onPlayerSwitch()
	CheckCore:reset();
	self._lastPlayer = self.player.name;
	self.raceState = C_RACE_STATE_PRERUN;
	if self.scrollingUsed then return end;
	for key,value in pairs(self.allStored) do 
		if value.name == self.player.name then 
			self.activeStored = value.checkpoints; 
			self.activeStoredName = value.name;
			break; 
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function CheckCore:draw()

	if not isRaceMode() or not self.userData.active then return end;
	
	self.player = getPlayer()
	if not self.player then return end;

	if self._lastMap ~= world.mapName then
		CheckCore:onMapChange();
	end 
	
	local store = widgetGetConsoleVariable("store");
	
	self._strictMessages = self.userData.strictMessages
	self._autoSave = self.userData.autoSave
	self._saveToConfig = self.userData.saveToConfig;
	
	local scrollPrev = (widgetGetConsoleVariable("previous") ~= 0);
	local scrollNext = (widgetGetConsoleVariable("next") ~= 0);
	local clearAll = (widgetGetConsoleVariable("clearall") ~= 0);
	
	-- Clears all stored data
	if clearAll then
		widgetSetConsoleVariable("clearall","0");
		CheckCore:flushData();
	end
	
	-- Autosave
	if self._autoSave and self.raceState == C_RACE_STATE_JUST_FINISHED then
		local tmpStore = {}
		for key,value in pairs(self.allStored) do 
			if value.name == self.player.name then 
				tmpStore=value.checkpoints; 
				break; 
			end
		end
		
		if tmpStore[#self.checkpoints] == nil or self.checkpoints[#self.checkpoints].cTime < tmpStore[#self.checkpoints].cTime then
			store = 1;
		end
	end
	
	-- Save
	if store ~= 0 then
		widgetSetConsoleVariable("store","0");
		
		local newCheckpoints = { }
		for key,value in ipairs (self.checkpoints) do
				local newCheckpoint = {
					speed = value.speed;
					cTime = value.cTime;
					distance = value.distance;
				}
				table.insert(newCheckpoints, newCheckpoint);
		end
		
		--this needs revisiting
		
		if self.activeStoredName ==  self.player.name then
			self.activeStored = newCheckpoints;
		end 
		
		local foundSlot = false;
		for key,value in pairs(self.allStored) do 
			if value.name == self.player.name then 
				value.checkpoints=newCheckpoints; 
				foundSlot = true; 
				break; 
			end
		end
		
		if not foundSlot then 
			local newStoreSlot = {
				name=self.player.name,
				checkpoints=newCheckpoints,
			}
			table.insert(self.allStored,newStoreSlot);
			if self._activeStoredIndex==0 or not self.scrollingUsed then
				self.activeStoredName = self.player.name;
				self.activeStored = newStoreSlot.checkpoints;
				self._activeStoredIndex = #self.allStored;
			end
		end
		
		if self._saveToConfig then
			self.userData.maps["m_" .. world.mapName] = self.allStored
			saveUserData(self.userData);
		end
		--self.userData = loadUserData();
	end	
	

	
	-- Check for player switch
	if self._lastPlayer ~= self.player.name then
		CheckCore:onPlayerSwitch();
	end
	
	-- Check for active Stored scroll
	if scrollNext then
		widgetSetConsoleVariable("next","0");
		self._activeStoredIndex = math.min(self._activeStoredIndex+1, #self.allStored);
		if self.allStored[self._activeStoredIndex]~=nil then
			self.activeStored = self.allStored[self._activeStoredIndex].checkpoints
			self.activeStoredName = self.allStored[self._activeStoredIndex].name
		end
		self.scrollingUsed = true;
		
	elseif scrollPrev then
		widgetSetConsoleVariable("previous","0");
		self._activeStoredIndex = math.max(self._activeStoredIndex-1, 1);
		if self.allStored[self._activeStoredIndex]~=nil then
			self.activeStored = self.allStored[self._activeStoredIndex].checkpoints
			self.activeStoredName = self.allStored[self._activeStoredIndex].name
		end
		self.scrollingUsed = true;
	end
	
	
	
    self.currentSpeed = math.ceil(self.player.speed)
	self.currentRaceTime = self.player.raceTimeCurrent;
	
	self.currentSector.timeTot = self.currentRaceTime;
	self.currentSector.timeRel = self.currentRaceTime - self.lastCheckpoint.time; 

	self.currentSector.distanceRel = self.player.stats.distanceTravelled - self._startDistance - self.lastCheckpoint.distance;
	self.currentSector.distanceTot = self.player.stats.distanceTravelled - self._startDistance;
	

	
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
				if self._lastLogIdRead < logEntry.id then
					self._lastLogIdRead = logEntry.id;
					
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
		CheckCore:reset();
		self.raceState = C_RACE_STATE_RUN;
		CheckCore:onRaceStart(); 
	end
	
	-- Reached new Checkpoint?
	if string.len(message.text) > 0 and self.raceState == C_RACE_STATE_RUN then
		if (message.text == "Checkpoint " .. self.lastCheckpointNo+1) or (string.find(message.text, "^Checkpoint " .. self.lastCheckpointNo+1 .. "[^%d]")~=nil) or (not self._strictMessages) then
			if (message.text ~= self._lastMessage) then
				CheckCore:onNewCheckpoint();
			end
		end
	
	end
	
	self._lastMessage = message.text;
	
	-- Add last Checkpoint when finished
	if self.raceState == C_RACE_STATE_JUST_FINISHED then
		CheckCore:onFinish();
	end
	
-- Actual Drawing (this is done in a different widget now
--    if not shouldShowHUD() then return end;
--	CheckCore:drawTable();
end

function CheckCore:drawOptions(x, y, intensity)
	local optargs = {};
	optargs.intensity = intensity;
	 
	local user = self.userData;
	user.active = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Enabled", user.active, optargs);
	y = y + 60;
	
	user.autoSave = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Auto save faster runs", user.autoSave, optargs);
	y = y + 60;
	 
	user.saveToConfig = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Save runs to config file", user.saveToConfig, optargs);
	y = y + 60;
	 
	user.strictMessages = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Strict checkpoint messages", user.strictMessages, optargs);
	y = y + 60;
	 
	 
	 saveUserData(user);
end
