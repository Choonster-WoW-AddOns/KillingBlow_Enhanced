-- IMPORTANT: If you make any changes to this file, make sure you back it up before installing a new version.
-- This will allow you to restore your custom configuration with ease.
-- Also back up any custom textures or sounds you add.

-------
-- The first three variables control the appearance of the texture.
-------

-- The path of the texture file you want to use relative to the main WoW directory (without the texture's file extension).
-- The default texture is "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow"
local TEXTURE_PATH = "Interface\\AddOns\\KillingBlow_Enhanced\\KillingBlow"

-- You can add your own texture by placing a TGA image in the WoW\Interface\AddOns\KillingBlowImage directory and changing the string after TEXTURE_PATH to match its name.
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

-- If true, the AddOn will only activate in battlegrounds. If false, it will work everywhere.
local BG_ONLY = true

-- If true, the AddOn will print a message in your chat frame when you get a killing blow showing your current total.
-- This is reset any time you go through a loading screen (e.g. when entering or leaving a battleground or instance)
local DO_CHAT = true

-------------------
-- END OF CONFIG --
-------------------
-- Do not change anything below here!

------
-- Animations
------
local frame = CreateFrame("Frame", "KillingBlowImageFrame", UIParent)
frame:SetPoint(TEXTURE_POINT, UIParent, ANCHOR_POINT, OFFSET_X, OFFSET_Y)
frame:SetFrameStrata("HIGH")
frame:Hide()

local texture = frame:CreateTexture()
texture:SetTexture(TEXTURE_PATH)
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

local PLAYER_GUID = UnitGUID("player")
local InBattleground = false
local KillCount = 0

local function KillingBlow()
	frame:Show()
	
	if DO_CHAT then
		KillCount = KillCount + 1
		print(("|cffff0000Killing Blows Counter: %d|r"):format(KillCount))
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
	local inInstance, instanceType = IsInInstance()
	InBattleground = instanceType == "pvp"
	if BG_ONLY then
		if InBattleground then
			self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		else
			self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		end
	end
	
	KillCount = 0
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags)
	if event == "PARTY_KILL" and sourceGUID == PLAYER_GUID then
		if InBattleground and band(destGUID:sub(5, 5), 0x7) ~= 0 then return end -- If we're in a Battleground and this isn't a player, ignore it
		KillingBlow()
	end
end


