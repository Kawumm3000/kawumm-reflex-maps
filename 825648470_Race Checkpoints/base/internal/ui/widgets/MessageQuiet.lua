--------------------------------------------------------------------------------
-- Modified version of the original Reflex 0.47.5 "Message" widget
-- This widget works exactly to the original message widget but plays no sound at
-- "Checkpoint #" messages or hides them completely
--------------------------------------------------------------------------------

require "base/internal/ui/reflexcore"

MessageQuiet =
{
	currentMessage = "",
	isCheckpointMessage = false,
	intensity = 0
};
registerWidget("MessageQuiet");

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function MessageQuiet:initialize()
	self.userData = loadUserData();
	CheckSetDefaultValue(self, "userData", "table", {});
	CheckSetDefaultValue(self.userData, "hideMessages", "boolean", false);
	CheckSetDefaultValue(self.userData, "muteMessages", "boolean", true);
end

function MessageQuiet:draw()
	local x = 0;
	local y = 0;
	local user = self.userData;

	-- fading down?
	if string.len(self.currentMessage) > 0 and string.len(message.text) <= 0 then
		self.intensity = self.intensity - deltaTime * 3;
		self.intensity = math.max(self.intensity, 0);
	end

	-- snap to new?
	if string.len(message.text) > 0 then

		self.isCheckpointMessage = (string.find(message.text, "^Checkpoint %d")~=nil)
		-- play beep?
		if (message.text ~= self.currentMessage or self.intensity < 1) and not (self.isCheckpointMessage and user.muteMessages) then
			playSound("internal/misc/chat");
		end
	
		self.intensity = 1;
		self.currentMessage = message.text;
	end

    -- Early out if HUD shouldn't be shown.
    if not shouldShowHUD() then return end;

	-- Checkpoint messages hidden?
	if user.hideMessages and self.isCheckpointMessage then return end;
	
	-- message expired?
	if self.intensity <= 0 then return end;

	nvgFontSize(48);
    nvgFontFace("titilliumWeb-regular");
	nvgTextAlign(NVG_ALIGN_CENTER, NVG_ALIGN_MIDDLE);
	
	-- split text into multiple lines
	local text = self.currentMessage;
	function split(str, delim)
		local result,pat,lastPos = {},"(.-)" .. delim .. "()",1
		for part, pos in string.gfind(str, pat) do
			table.insert(result, part); lastPos = pos
		end
		table.insert(result, string.sub(str, lastPos))
		return result
	end
	local textLines = split(text, "\\n");
	
	-- count lines so we can center nicely
	local lines = 0;
	for k, v in pairs(textLines) do
		lines = lines + 1;

		-- substitude keybinds
		textLines[k] = string.gsub(textLines[k], "+forward", "'".. string.upper(bindReverseLookup("+forward", "game")) .. "'");
		textLines[k] = string.gsub(textLines[k], "+crouch", "'".. string.upper(bindReverseLookup("+crouch", "game")) .. "'");
		textLines[k] = string.gsub(textLines[k], "+jump", "'".. string.upper(bindReverseLookup("+jump", "game")) .. "'");
	end

	local ystride = 40;
	local iy = y - ystride * (lines/2);
	
	local alpha = 255 * self.intensity;

	for k, v in pairs(textLines) do
		nvgFontBlur(5);
		nvgFillColor(Color(64, 64, 64, alpha));
		nvgText(x, iy, v);
	
		nvgFontBlur(0);
		nvgFillColor(Color(232,232,232, alpha));
		nvgText(x, iy, v);
		
		iy = iy + ystride;
	end
end

 function MessageQuiet:drawOptions(x, y, intensity)
	 local optargs = {};
	 optargs.intensity = intensity;
	 
	 local user = self.userData;
	 
	 user.hideMessages = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Hide Checkpoint Messages", user.hideMessages, optargs);
	 y = y + 60;
	 user.muteMessages = ui2RowCheckbox(x, y, WIDGET_PROPERTIES_COL_INDENT, "Mute Checkpoint Messages", user.muteMessages, optargs);
	 y = y + 60;
	 
	 saveUserData(user);
 end