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

	canHide = true ; 
	canPosition = false;

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
	storedCheckpoints = {
	}, -- export
	
	_startDistance = 0,
	_strictMessages = true,
	_autoSave = false,
	_widgets = {
	},
	_lastMessage = "",
	_lastPlayer = nil,
	_lastLogIdRead = 0,
};
registerWidget("Checkpoints");

function Checkpoints:initialize()
    widgetCreateConsoleVariable("store","int","0");
	widgetCreateConsoleVariable("beep","int","0");
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

function Checkpoints:registerWidget(widget) 
	table.insert(self._widgets, widget)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Checkpoints:reset() 
		self.checkpoints = { };
		self.lastCheckpointNo = 0;
		self.lastCheckpoint.time = 0;
		self.lastCheckpoint.distance = 0;
		self._startDistance= self.player.stats.distanceTravelled;
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Checkpoints:onRaceStart() 
	for i, widget in ipairs(self._widgets) do
		if _G[widget].onRaceStart ~= nil then 
			_G[widget]:onRaceStart();
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Checkpoints:onNewCheckpoint() 
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

function Checkpoints:onFinish() 
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

function Checkpoints:drawTable()

end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function Checkpoints:draw()

	if not isRaceMode() then return end;


	if self.userData.maps["m_" .. world.mapName] ~= nil then self.storedCheckpoints = self.userData.maps["m_" .. world.mapName].checkpoints; end
	
	local store = widgetGetConsoleVariable("store");
	
	self.beep = (widgetGetConsoleVariable("beep") ~= 0);
	self._strictMessages = (widgetGetConsoleVariable("strictMessages") ~= 0);
	self._autoSave = (widgetGetConsoleVariable("autoSave") ~= 0);
	
	-- Autosave
	if self._autoSave and self.raceState == C_RACE_STATE_JUST_FINISHED then
		if self.storedCheckpoints[#self.checkpoints] == nil or self.checkpoints[#self.checkpoints].cTime < self.storedCheckpoints[#self.checkpoints].cTime then
			store = 1;
		end
	end
	
	-- Save
	if store ~= 0 then
		widgetSetConsoleVariable("store","0");
		
		self.userData.maps["m_" .. world.mapName] = { checkpoints = self.checkpoints, kaduudle = 435 }
		saveUserData(self.userData);
		self.userData = loadUserData();
	end	
	
	self.player = getPlayer()
	if not self.player then return end;
    self.currentSpeed = math.ceil(self.player.speed)
	self.currentRaceTime = self.player.raceTimeCurrent;
	
	self.currentSector.timeTot = self.currentRaceTime;
	self.currentSector.timeRel = self.currentRaceTime - self.lastCheckpoint.time; 

	self.currentSector.distanceRel = self.player.stats.distanceTravelled - self._startDistance - self.lastCheckpoint.distance;
	self.currentSector.distanceTot = self.player.stats.distanceTravelled - self._startDistance;
	
	-- Check for player switch
	if self._lastPlayer ~= self.player.name then
		Checkpoints:reset();
		self._lastPlayer = self.player.name;
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
		Checkpoints:reset();
		self.raceState = C_RACE_STATE_RUN;
		Checkpoints:onRaceStart(); 
	end
	
	-- Reached new Checkpoint?
	if string.len(message.text) > 0 and self.raceState == C_RACE_STATE_RUN then
		if (message.text == "Checkpoint " .. self.lastCheckpointNo+1) or (string.find(message.text, "^Checkpoint " .. self.lastCheckpointNo+1 .. "[^%d]")~=nil) or (not self._strictMessages) then
			if (message.text ~= self._lastMessage) then
				Checkpoints:onNewCheckpoint();
			end
		end
	
	end
	
	self._lastMessage = message.text;
	
	-- Add last Checkpoint when finished
	if self.raceState == C_RACE_STATE_JUST_FINISHED then
		Checkpoints:onFinish();
	end
	
-- Actual Drawing (this is done in a different widget now
--    if not shouldShowHUD() then return end;
--	Checkpoints:drawTable();
end
