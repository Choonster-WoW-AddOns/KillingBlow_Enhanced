-- IMPORTANT: If you make any changes to this file, make sure you back it up before installing a new version.
-- This will allow you to restore your custom configuration with ease.
-- Also back up any custom textures you add.

-------
-- The first three variables control the appearance of the texture.
-------

-- The path of the texture file you want to use relative to the main WoW directory (without the texture's file extension).
-- The default texture is "Interface\\AddOns\\KillingBlowImage\\KillingBlow"
local TEXTURE_PATH = "Interface\\AddOns\\KillingBlowImage\\KillingBlow"

-- You can add your own texture by placing a TGA image in the WoW\Interface\AddOns\KillingBlowImage directory and changing the string after TEXTURE_PATH to match its name.
-- See the "filename" argument on the following page for details on the required texture file format:
-- http://www.wowpedia.org/API_Texture_SetTexture
--
-- GIMP (www.gimp.org) is a free image editing program that can easily convert almost any image format to TGA as well as let you create your own TGA images.
-- If you want your texture to be packaged with the AddOn, just leave a comment on Curse or WoWI with the image embedded or a direct link to download the image.
-- I can convert PNG and other formats to TGA if needed.
-- Make sure that you have ownership rights of any image that you contribute.

-- The height/width of the texture. Using a height:width ratio different to that of the texture file may result in distortion.
local TEXTURE_WIDTH = 300
local TEXTURE_HEIGHT = 263

-------
-- These four variables control how the image is anchored to the screen.
-------

-- Used in image:SetPoint(TEXTURE_POINT, UIParent, ANCHOR_POINT, OFFSET_X, OFFSET_Y)
-- See http://www.wowpedia.org/API_Region_SetPoint for explanation.
local TEXTURE_POINT = "BOTTOM" -- The point of the texture that should be anchored to the nameplate.
local ANCHOR_POINT  = "TOP"	   -- The point of the nameplate the texture should be anchored to.
local OFFSET_X = 0 			   -- The x/y offset of the texture relative to the anchor point.
local OFFSET_Y = 5

-------
-- These three variables control the scaling animation that plays when the image is shown
-------

local SCALE_X = 1.5 -- The X scalar that the image should scale by
local SCALE_Y = 1.5 -- The Y scalar that the image should scale by
local SCALE_DURATION = 0.75 -- The duration of the scaling animation in seconds

-- The sound to play when you get a killing blow
local SOUND_PATH = "Sound\\creature\\GeneralBjarngrim\\HL_Bjarngrim_Slay03.ogg"

-------------------
-- END OF CONFIG --
-------------------
-- Do not change anything below here!

local PLAYER_GUID = UnitGUID("player")

local frame = CreateFrame("Frame", "KillingBlowImageFrame", UIParent)
frame:SetSize(TEXTURE_WIDTH, TEXTURE_HEIGHT)
frame:SetPoint(TEXTURE_POINT, UIParent, ANCHOR_POINT, OFFSET_X, OFFSET_Y)
frame:SetFrameStrata("HIGH")
frame:Hide()

local texture = frame:CreateTexture()
texture:SetTexture(TEXTURE_PATH)
texture:SetAllPoints()

local group = texture:CreateAnimationGroup()

local animation = group:CreateAnimation("Scale")
animation:SetScale(SCALE_X, SCALE_Y)
animation:SetDuration(SCALE_DURATION)

frame:SetScript("OnShow", function(self)
	group:Play()
	PlaySoundFile(SOUND_PATH)
end)

group:SetScript("OnFinished", function(self)
	frame:Hide()
end)

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)

function frame:PLAYER_LOGIN()
	PLAYER_GUID = UnitGUID("player")
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, sourceGUID)
	if event == "PARTY_KILL" and sourceGUID == PLAYER_GUID then
		self:Show()
	end
end

