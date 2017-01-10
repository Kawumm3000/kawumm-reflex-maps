--------------------------------------------------------------------------------
-- Checkpoint Delta Time by Kawumm
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"
require "base/internal/ui/CheckCore"

CheckpointDelta =
{
	alpha = 1;
	visibleTime = 0;
	color = Color(230,230,230,255);
	text = "";
};

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function CheckpointDelta:draw()
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

function CheckpointDelta:onNewCheckpoint()
	local newTime = 0
	local oldTime = 0;
	
	if CheckCore.activeStored[#CheckCore.checkpoints] ~= nil and CheckCore.checkpoints[#CheckCore.checkpoints] ~=nil then
		newTime = CheckCore.checkpoints[#CheckCore.checkpoints].cTime;
		oldTime = CheckCore.activeStored[#CheckCore.checkpoints].cTime;
		self.text = CheckCore:FormatTimeDelta(newTime-oldTime);
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

registerWidget("CheckpointDelta");
CheckCore:registerWidget("CheckpointDelta");