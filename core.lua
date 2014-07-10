-- IMPORTANT: If you make any changes to this file, make sure you back it up before installing a new version.
-- This will allow you to restore your custom configuration with ease.
-- Also back up any custom textures or sounds you add.

-------
-- The first three variables control the appearance of the texture.
-------

-- The path of the texture file you want to use for characters of each faction relative to the main WoW directory (without the texture's file extension).
-- The default texture is "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow_Enhanced\\KillingBlow_Alliance" for Alliance
-- and "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow_Enhanced\\KillingBlow_Horde" for Horde.
-- The AddOn also includes another texture: "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow_Enhanced\\KillingBlow_HordeAlliance"
local ALLIANCE_TEXTURE_PATH = "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow_Alliance"
local HORDE_TEXTURE_PATH = "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow_Horde"

-- You can add your own texture by placing a TGA image in the WoW\Interface\AddOns\KillingBlowImage directory and changing the string after
-- ALLIANCE_TEXTURE_PATH or HORDE_TEXTURE_PATH to match its name.
-- See the "filename" argument on the following page for details on the required texture file format:
-- http://www.wowpedia.org/API_Texture_SetTexture
--
-- GIMP (www.gimp.org) is a free image editing program that can easily convert almost any image format to TGA as well as let you create your own TGA images.
-- If you want your texture to be packaged with the AddOn, just leave a comment on Curse or WoWI with the image embedded or a direct link to download the image.
-- I can convert PNG and other formats to TGA if needed.
-- Make sure that you have ownership rights of any image that you contribute.

-- The height/width of the texture. Using a height:width ratio different to that of the texture file may result in distortion.
local TEXTURE_WIDTH = 200
local TEXTURE_HEIGHT = 200

-------
-- These four variables control how the image is anchored to the screen.
-------

-- Used in image:SetPoint(TEXTURE_POINT, UIParent, ANCHOR_POINT, OFFSET_X, OFFSET_Y)
-- See http://www.wowpedia.org/API_Region_SetPoint for explanation.
local TEXTURE_POINT = "CENTER" -- The point of the texture that should be anchored to the screen.
local ANCHOR_POINT  = "CENTER" -- The point of the screen the texture should be anchored to.
local OFFSET_X = 0 			   -- The x/y offset of the texture relative to the anchor point.
local OFFSET_Y = 5

-------
-- These four variables control the animation that plays when the image is shown
-------

local SCALE_X = 1.5 -- The X scalar that the image should scale by
local SCALE_Y = 1.5 -- The Y scalar that the image should scale by
local SCALE_DURATION = 0.75 -- The duration of the scaling animation in seconds

local DELAY_DURATION = 0.75 -- The amount of time between the end of the scaling animation and the image hiding

-------
-- Other options
-------

-- The sound to play when you get a killing blow
local SOUND_PATH = "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow.mp3"

-- The channel to play the sound through. This can be "Master", "SFX", "Music" or "Ambience"
local SOUND_CHANNEL = "Master"

-- If true, the AddOn will only activate in battlegrounds and arenas. If false, it will work everywhere.
local PVP_ONLY = true

-- If true, the AddOn will print a message in your chat frame when you get a killing blow showing your current total.
-- This is reset any time you go through a loading screen (e.g. when entering or leaving a battleground or instance)
local DO_CHAT = true

-------------------
-- END OF CONFIG --
-------------------
-- Do not change anything below here!

-- List globals here for mikk's FindGlobals script
-- GLOBALS: PlaySoundFile, UnitGUID, IsInInstance, GetTime, UnitFactionGroup

------
-- Animations
------
local frame = CreateFrame("Frame", "KillingBlow_EnhancedFrame", UIParent)
frame:SetPoint(TEXTURE_POINT, UIParent, ANCHOR_POINT, OFFSET_X, OFFSET_Y)
frame:SetFrameStrata("HIGH")
frame:Hide()

local texture = frame:CreateTexture()
texture:SetAllPoints()

local group = texture:CreateAnimationGroup()

group:SetScript("OnPlay", function(self)
	frame:SetSize(TEXTURE_WIDTH, TEXTURE_HEIGHT) -- Set the frame to the configured size before scaling animation starts
end)

local scale = group:CreateAnimation("Scale")
scale:SetScale(SCALE_X, SCALE_Y)
scale:SetDuration(SCALE_DURATION)

local delay = group:CreateAnimation("Animation")
delay:SetDuration(DELAY_DURATION)

delay:SetScript("OnPlay", function(self)
	frame:SetSize(TEXTURE_WIDTH * SCALE_X, TEXTURE_HEIGHT * SCALE_Y) -- Set the frame to the scaled size after the scaling animation ends
end)

group:SetScript("OnFinished", function(self)
	frame:Hide()
end)

frame:SetScript("OnShow", function(self)
	group:Play()
	PlaySoundFile(SOUND_PATH, SOUND_CHANNEL)
end)


------
-- Events
------
local band = bit.band
local print, tonumber = print, tonumber

local FILTER_MINE = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_REACTION_FRIENDLY, COMBATLOG_OBJECT_CONTROL_PLAYER) -- Matches any "unit" under the player's control
local GUID_TYPE_MASK = 0x7
local GUID_TYPE_PLAYER = 0x0

local PLAYER_GUID = UnitGUID("player")
local InPVP = false
local KillCount = 0
local RecentKills = setmetatable({}, { __mode = "kv" }) -- [GUID] = killTime (from GetTime())
local FirstLoad = true

local function KillingBlow()
	frame:Show()
	
	if DO_CHAT then
		KillCount = KillCount + 1
		print(("|cffCC0033Killing Blows Counter: %d|r"):format(KillCount))
	end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function frame:PLAYER_LOGIN()
	PLAYER_GUID = UnitGUID("player")
end

function frame:PLAYER_ENTERING_WORLD()
	if FirstLoad then
		FirstLoad = false
		texture:SetTexture(UnitFactionGroup("player") == "Alliance" and ALLIANCE_TEXTURE_PATH or HORDE_TEXTURE_PATH)
	end
	
	local inInstance, instanceType = IsInInstance()
	InPVP = instanceType == "pvp" or instanceType == "arena"
	if PVP_ONLY then
		if InPVP then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
	
	KillCount = 0
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	if
		not destGUID or destGUID == "" or -- If there isn't a valid destination GUID
		(sourceGUID ~= PLAYER_GUID and band(sourceFlags, FILTER_MINE) ~= FILTER_MINE) or -- Or the source unit isn't the player or something controlled by the player (the latter check was suggested by Caellian)
		(InPVP and band(tonumber(destGUID:sub(5, 5), 16), GUID_TYPE_MASK) ~= GUID_TYPE_PLAYER) -- Or we're in a Battleground/Arena and the destination unit isn't a player
	then return end -- Return now
	
	local _, overkill
	if event == "SWING_DAMAGE" then
		_, overkill = ...
	elseif event:find("_DAMAGE", 1, true) and not event:find("_DURABILITY_DAMAGE", 1, true) then
		_, _, _, _, overkill = ...
	end
	
	local now, previousKill = GetTime(), RecentKills[destGUID]
	
	-- Caellian has noted that PARTY_KILL doesn't always fire correctly and suggested checking the overkill argument
	-- (which will be 0 [or maybe -1] for non-killing blows) to mitigate against this.
	--
	-- Because most kills will trigger PARTY_KILL and an overkill _DAMAGE, we need to keep a record of recent kill times
	-- and only record kills of the same unit when they're at least 1 second apart.
	if (event == "PARTY_KILL" or (overkill and overkill > 0)) and (not previousKill or now - previousKill > 1.0) then
		KillingBlow()
		RecentKills[destGUID] = now
	end
end
