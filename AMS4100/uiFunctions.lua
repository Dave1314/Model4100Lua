-----------------------------------------------------------------------------------------
--
-- Filename: uiFunctions.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for drawing and creating the common ui elements used in different scenes.
--
-----------------------------------------------------------------------------------------

local an = require( "analytics" )
local ls = require( "loadsave")
local md = require( "myData" )
local mf = require( "myFunctions" )
local composer = require( "composer" )
local widgets = require( "widget" )

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once.
-- 
-----------------------------------------------------------------------------------------

---[[ 'onRelease' event listener for navigation buttons
local function onNavBtnTouch(event)

	local t = event.target
	local p= t.parentGrp

	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true		
		t.fill.effect.ambientLightIntensity = 0.1

	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

			--Disable highlights if their finger moves off the button
			if dx > t.width/2 or dy > t.height/2 then
				display.getCurrentStage():setFocus( nil )
				t.isFocus = nil
				t.fill.effect.ambientLightIntensity = 0
				if t.id == "speaker" and md.settings.muted == true then
					t.fill.effect.ambientLightIntensity = 0.325
				end				
			end				

		elseif event.phase == "ended" or event.phase == "cancelled" then

			local currentScene = composer.getSceneName("current")
			mf.dprint( event )
			mf.dprint( currentScene )

			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			t.fill.effect.ambientLightIntensity = 0
			local options = {
				effect = "fade",
				time = 400,
				params = {
					sampleVar = "my sample variable"
				}
			}
			--Event handler code goes here
			if t.id == "menu" then	--Show menu overlay
				native.showAlert( "AMS 4100", "Pressing this button will link to the instrument manual.", {"OK"} )
			elseif t.id == "cart" then --Show cart overlay
				native.showAlert( "AMS 4100", "Pressing this button will link to the accessories available at www.a-msystems.com.", {"OK"} )
			elseif t.id == "back" then
				composer.gotoScene( "scene_train", options )
				
			elseif t.id == "options" then --Show options overlay
				-- By some method (a pause button, for example), show the overlay
				if currentScene ~= "scene_configure" then
					composer.gotoScene( "scene_configure", options )
				end

			elseif t.id == "speaker" then
				--Toggle sound
				--If the current volume is below 0.1 assume it's been muted 
				if audio.getVolume() < 0.1 then
					audio.setVolume( 1 )
					t.fill.effect.ambientLightIntensity = 0
					t.fill.blendMode = "multiply"
					md.settings.muted = false
					mf.dprint( "Unmuted sounds." )
					mf.logEvent( "sounds unmuted" )				
				else
					audio.setVolume( 0 )					
					t.fill.effect.ambientLightIntensity = 0.325
					md.settings.muted = true
					mf.dprint( "Muted sounds." )
					mf.logEvent( "sounds muted" )
				end

				ls.saveTable(md.settings, "settings.json", system.DocumentsDirectory)	

			else
				return false
			end

		end
	end

	return true	-- indicates successful touch
end


local _ = {}

_.drawBackground = function( params )
	local p = {
		parent = params.parent,
		x = params.x or md.screenW/2,
		y = params.y or md.screenH/2,
		w = params.w or md.screenW,		
		}		
	p.h = params.h or 86/209*p.w
	
	local bkImage = display.newImageRect( p.parent, "images/amslogo.png", p.w, p.h )
	bkImage.x = p.x
	bkImage.y = p.y

	bkImage.alpha = 0.1

end

_.drawNavButtons = function( params )

	mf.dprint( "Creating navigation buttons." )

	local parent = params.parent
	--local listener = params.listener
	local listener = onNavBtnTouch

	local ids = { "back", "menu", "options", "speaker" }

	--local sW, sH = md.screenW, md.screenH
	local sW, sH = md.contentW, md.contentH
	local w, h = md.tileW, md.tileW

	local compositePaint = {
		{type="composite",
			paint1={ type="image", filename="images/leftArrow-base.png" },
			paint2={ type="image", filename="images/leftArrow.png" }},
		{type="composite",
			paint1={ type="image", filename="images/menuButton-base3.png" },
			paint2={ type="image", filename="images/menuButton-normal3.png" }},
		{type="composite",
			paint1={ type="image", filename="images/optionsButton-base5.png" },
			paint2={ type="image", filename="images/optionsButton-normal5.png" }},	
		{type="composite",
			paint1={ type="image", filename="images/speakerButton-base3.png" },
			paint2={ type="image", filename="images/speakerButton-normal3.png" }},		
	}
	
	local currentScene = composer.getSceneName("current")
	if currentScene == "scene_train" then
		ids[1] = "cart"
		compositePaint[1] = 		{type="composite",
			paint1={ type="image", filename="images/cartButton-base4.png" },
			paint2={ type="image", filename="images/cartButton-normal4.png" }}
	end

	for m = 1,#ids do
		--mf.dprint( m, compositePaint[m] )
		local newRect = display.newRect( parent, w, 0.8*m/(#ids)*sH+w, w, h )
		newRect.fill = compositePaint[m]
		newRect.fill.effect = "composite.normalMapWith1DirLight"
		newRect.fill.effect.dirLightDirection = { 0, 1, 1 }		
		newRect.fill.effect.dirLightColor = {  1, 1, 1, 1 }
		newRect.fill.effect.ambientLightIntensity = 0
		newRect.fill.blendMode = "multiply"
		newRect.id = ids[m]
		newRect:addEventListener( "touch", listener )
	end

end

_.drawRunButtons = function( params )
	mf.dprint( "Creating run buttons." )
	
	local parent = params.parent
	local listener = params.listener

	local ids = { "start", "stop", "connect", "refresh"  }
	local labels = { "Start", "Stop", "Connect", "Refresh" }
	local sW, sH = md.screenW, md.screenH
	local w, h = md.tileW, md.tileW

	local compositePaint = {
		{type="composite",
			paint1={ type="image", filename="images/default-base.png" },
			paint2={ type="image", filename="images/default-normal.png" }},
		{type="composite",
			paint1={ type="image", filename="images/default-base.png" },
			paint2={ type="image", filename="images/default-normal.png" }},
		{type="composite",
			paint1={ type="image", filename="images/default-base.png" },
			paint2={ type="image", filename="images/default-normal.png" }},
		{type="composite",
			paint1={ type="image", filename="images/default-base.png" },
			paint2={ type="image", filename="images/default-normal.png" }},	

	}
	--Game board tiles
	params = {
		mainGroup = parent,
		w = 1.5*w,
		h = w,
		r = 0.2*w,
		onTouch = listener,
		font = md.defaultFont,
		fontSize = 0.6*md.defaultFontSize,
		fontColor = md.defaultFontColor,
		x = md.screenW - w,		
	}

	for m = 1,#ids do
		--mf.dprint( m, compositePaint[m] )
		params.y =   (m/#ids)*0.8*sH+w
		params.id = ids[m]
		local newTile = tf.createTile( params )
		newTile.fill.blendMode = "normal"
		newTile.text.text = labels[m]
		newTile:addEventListener( "touch", listener )
	end

end

return _