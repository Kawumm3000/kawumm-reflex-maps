--------------------------------------------------------------------------------
-- Leaderboard helpers
--------------------------------------------------------------------------------
function QueryFriendsLeaderboard(mapName, mode)
	local mySteamId = steamId;

	-- query leaderboard
	local friendSteamIds = { ["0"] = mySteamId };
	local friendCount = 1;
	for k, friend in pairs(steamFriends) do

		-- steam friends include blocked people, requested people, and just people you've seen in game. So be sure to only include friends here
		if friend.m_steamId == mySteamId or friend.relationship == "Friend" then
			friendCount = friendCount + 1;
			friendSteamIds[friendCount] = friend.steamId;
		end
	end

	-- perform query, redunant queries will be ignored, so it's okay to do this over and over
	leaderboardsRequestUsers(mapName, mode, friendSteamIds);

	-- look up leaderboard (this will take a few seconds to actually come back)
	return leaderboards[mapName .. "." .. mode];
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function QuerySelfLeaderboard(mapName, mode)
	-- query leaderboard
	local steamIds = { ["0"] = steamId }; -- me

	-- perform query, redunant queries will be ignored, so it's okay to do this over and over
	leaderboardsRequestUsers(mapName, mode, steamIds);

	-- look up leaderboard (this will take a few seconds to actually come back)
	return leaderboards[mapName .. "." .. mode];
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function QueryGlobalLeaderboard(mapName, mode, optionalGlobalType)
	-- perform query, redunant queries will be ignored, so it's okay to do this over and over
	leaderboardsRequestGlobal(mapName, mode, optionalGlobalType);

	-- look up leaderboard (this will take a few seconds to actually come back)
	return leaderboards[mapName .. "." .. mode];
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ExtractFriendsLeaderboardEntries(leaderboard)
	local entryCount = 0;
	local entries = {};

	-- pull out valid entries
	if leaderboard ~= nil then
		for steamId, entry in pairs(leaderboard.friendsEntries) do
			if entry.timeMillis > 0 then
				entryCount = entryCount + 1;
				entries[entryCount] = {};
				entries[entryCount].steamId = steamId;
				entries[entryCount].timeMillis = entry.timeMillis;
				entries[entryCount].old = entry.mapHash ~= leaderboard.mapHash;
				entries[entryCount].topSpeed = entry.topSpeed
			end
		end
	end

	local function SortEntry(a, b)
--		if a.old ~= b.old then
--			local ao = a.old and 1 or 0;
--			local bo = b.old and 1 or 0;
--			return ao < bo;
--		end
		return a.timeMillis < b.timeMillis;
	end

	table.sort(entries, SortEntry);
	
	return entries, entryCount;
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function ExtractGlobalLeaderboardEntries(leaderboard)
	local entryCount = 0;
	local entries = {};

	-- pull out valid entries
	if leaderboard ~= nil then
		for steamId, entry in pairs(leaderboard.globalEntries) do
			if entry.timeMillis > 0 then
				entryCount = entryCount + 1;
				entries[entryCount] = {};
				entries[entryCount].steamId = steamId;
				entries[entryCount].timeMillis = entry.timeMillis;
				entries[entryCount].old = entry.mapHash ~= leaderboard.mapHash;
				entries[entryCount].globalRank = entry.globalRank;
				entries[entryCount].topSpeed = entry.topSpeed;
			end
		end
	end

	local function SortEntry(a, b)
--		if a.old ~= b.old then
--			local ao = a.old and 1 or 0;
--			local bo = b.old and 1 or 0;
--			return ao < bo;
--		end
		return a.timeMillis < b.timeMillis;
	end

	table.sort(entries, SortEntry);
	
	return entries, entryCount;
end

function FormatTimeToDecimalShort(time) 
	local ms = time % 1000;
	time = math.floor(time / 1000);
	local seconds = time % 60;
	time = math.floor(time / 60);
	local minutes = time % 60;
	--time = math.floor(time / 60);
	--local hours = time;
	
	-- "Decimal time": http://en.wikipedia.org/wiki/Decimal_time
	-- MM:SS.sss
	if minutes>0 then
	return string.format("%d:%d.%03d", minutes, seconds, ms);
	else 
	return string.format("%d.%03d", seconds, ms);
	end
end