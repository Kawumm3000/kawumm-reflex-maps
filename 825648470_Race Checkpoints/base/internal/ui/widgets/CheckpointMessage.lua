--------------------------------------------------------------------------------
-- Checkpoint Message by Kawumm
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"

CheckpointMessage =
{
	alpha = 1;
	visibleTime = 0;
	color = Color(230,230,230,255);
	text = "";
};
registerWidget("CheckpointMessage");
Checkpoints:registerWidget("CheckpointMessage");
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function CheckpointMessage:draw()

    if not shouldShowHUD() then return end;
	if not isRaceMode() then return end;

	local player = getPlayer();
	if not player then return end;
	
	if self.visibleTime > 0 then
		self.visibleTime= self.visibleTime - deltaTimeRaw;
	else
		return;
	end

    local frameColor = Color(0,0,0,self.alpha*128);
    local frameWidth = 180;
    local frameHeight = 35;

    nvgBeginPath();
    --nvgRoundedRect(-frameWidth/2, -frameHeight/2, frameWidth, frameHeight, 5);
    --nvgFillColor(frameColor); 
    --nvgFill();

    local fontSize = frameHeight * 1.15;


	
    nvgFontSize(fontSize);
	nvgFontFace(FONT_TEXT2_BOLD);
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);

	nvgFontBlur(2);
	nvgFillColor(Color(0, 0, 0, self.alpha*255));
	nvgText(0, -1, self.text);
	nvgText(0, -1, self.text);
	nvgFontBlur(0);
	nvgFillColor(self.color);
	nvgText(0, -1, self.text);
end

function CheckpointMessage:onNewCheckpoint()
	local newTime = 0
	local oldTime = 0;
	
	if Checkpoints.storedCheckpoints[#Checkpoints.checkpoints] ~= nil and Checkpoints.checkpoints[#Checkpoints.checkpoints] ~=nil then
		newTime = Checkpoints.checkpoints[#Checkpoints.checkpoints].cTime;
		oldTime = Checkpoints.storedCheckpoints[#Checkpoints.checkpoints].cTime;
		self.text = Checkpoints:FormatTimeDelta(newTime-oldTime);
		if newTime-oldTime <= 0 then
			self.color = Color(0, 230, 0, self.alpha*255);
		else
			self.color = Color(230, 0, 0, self.alpha*255);
		end
	else
		self.text = "(---)";
		self.color = Color(230, 230, 230, self.alpha*255);
	end
	
	self.visibleTime=2;
end
