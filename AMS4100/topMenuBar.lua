-----------------------------------------------------------------------------------------
--
-- Filename: topMenuBar.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for drawing and creating the common ui elements used in different scenes.
--
-----------------------------------------------------------------------------------------
local composer = require( "composer" )

local an = require( "analytics" )
local ls = require( "loadsave")
local md = require( "myData" )
local mf = require( "myFunctions" )
--local tf = require( "tileFunctions" )
local ams = md.instrumentSettings.current

local _ = {}
_.buttons = {}

_.tooltip = display.newGroup()

--Structure used for determining if a  mouseover event has occurred.
local mouseData = {
	oldX = 0,
	oldY = 0,
	newX = 0,
	newY = 0,
	startTime = 0,
	endTime = 0
}

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once.
-- 
-----------------------------------------------------------------------------------------

local function exitActivityIndicator()

	local counter = 0

	local function incCounter()
		counter = counter + 1
		if #md.state.sendBuffer > 1 and counter < 50 then
			timer.performWithDelay( 100, incCounter, 1 )
		elseif counter < 250 then
			native.setActivityIndicator( false )
			local options = {
				effect = "fade",
				time = 5,
				params = {
					transition = "fast",
				}
			}
			composer.gotoScene( "scene_splash", options )
		else
			native.setActivityIndicator( false )
		end
	end

	timer.performWithDelay( 100, incCounter, 1 )
end

---[[ 'onRelease' event listener for navigation buttons
local function onMenuBarTouch(event)

	local t = event.target
	local p= t.parentGrp

	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true		
		t.alpha = 0.5
	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

			--Disable highlights if their finger moves off the button
			if dx > t.width/2 or dy > t.height/2 then
				t.alpha = 1
				display.getCurrentStage():setFocus( nil )
				t.isFocus = nil			
			end				

		elseif event.phase == "ended" or event.phase == "cancelled" then
			t.alpha = 1

			local currentScene = composer.getSceneName("current")

			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			local options = {
				effect = "fade",
				time = 400,
				params = {
					sampleVar = "my sample variable"
				}
			}
			--Event handler code goes here
			--	"home", "train", "event", "play", "go", "status", "info", "help", "config", "refresh"			
			if t.id == "save" then	--Show menu overlay
				if currentScene ~= "scene_loadSave" then
					composer.gotoScene( "scene_loadSave", options )
				end				
			elseif t.id == "home" then 
				if currentScene ~= "scene_home" then
					composer.gotoScene( "scene_home", options )
				elseif currentScene ~= "scene_help" then
					composer.gotoScene( "scene_help", options )
				end
			elseif t.id == "train" then
				if currentScene ~= "scene_train" then
					composer.gotoScene( "scene_train", options )
				end
			elseif t.id == "event" then
				if currentScene ~= "scene_event" then
					composer.gotoScene( "scene_event", options )
				end
			elseif t.id == "info" then
				if currentScene ~= "scene_info" then
					composer.gotoScene( "scene_info", options )
				end
			elseif t.id == "help" then
				if currentScene ~= "scene_help" then
					composer.gotoScene( "scene_help", options )
				end
			elseif t.id == "config" then
				if currentScene ~= "scene_configure" then
					composer.gotoScene( "scene_configure", options )
				end
			elseif t.id == "upload" then
				ams:Stop()
				ams:setMenuVals( ams )
				ams:Run()
			elseif t.id == "download" then
				ams:getMenuVals()
			elseif t.id == "triggerStop" then
				ams:TriggerStop()				
			elseif t.id == "triggerNone" then
				ams:TriggerNone()
			elseif t.id == "triggerOnce" then
				ams:TriggerOnce()
			elseif t.id == "triggerFreeRun" then
				ams:TriggerFreeRun()
			else
				return false
			end

		end
	end

	return true	-- indicates successful touch
end

local function updateConnectionStatus()
	local highlightColor = {1, 1, 0, 1}
	if ams.connection.connected then

		_.buttons["refresh"].alpha = 1
		_.buttons["download"].alpha = 1
		_.buttons["upload"].alpha = 1
		if ams.localPinNumber ~= ams.PinNumber then
			--_.statusText.text = "Bad pin: " .. ams.Active
			_.statusText.text = "BAD PIN"
		else
			_.statusText.text = ams.Active
			if not ams.condition.RelayClosed then 
				_.statusText.text = "Internal relay disengaged.  Toggle ENABLE button."
			end
			if not ams.condition.Enable then 
				_.statusText.text = "ENABLE button out."
			end
			if ams.condition.Vmon then
				_.statusText.text = "Over voltage monitor triggered."
			end
			if ams.condition.Imon then
				_.statusText.text = "Over current monitor triggered."
			end			
			--[[Attempt to autoscale the font size for overly long strings
			if string.len(_.statusText.text) > 0 then
				local newSize = md.screenW/2.5/string.len(_.statusText.text)
				newSize = math.min( 25, newSize )
				_.statusText.size = newSize
			end--]]
   
		end		
	else
		_.statusText.text = "AMS 4100"
		_.buttons["refresh"].alpha = 0.25
		_.buttons["download"].alpha = 0.25
		_.buttons["upload"].alpha = 0.25
	end	
	if ams.Active == "DANGEROUS PULSES" then
		_.buttons["status"]:setFillColor( 1, 0, 0, 1 )	
	else
		_.buttons["status"]:setFillColor( 0, 0, 0, 0.25 )	
	end	
	if not ams.connection.timeout and ams.connection.connected then
		_.buttons["refresh"]:setFillColor( unpack(highlightColor))
	else
		_.buttons["refresh"]:setFillColor( 0, 0, 0, 1 )	
	end

	if ams.connection.commsInProgress and #ams.connection.sendBuffer > 1 then 
		_.buttons["refresh"]:rotate( 3 ) 
	end	
end

local function updateTriggerStatus()
	local highlightColor = {1, 1, 0, 1}
	_.buttons["triggerStop"]:setFillColor( 0, 0, 0, 1 )
	_.buttons["triggerNone"]:setFillColor( 0, 0, 0, 1 )
	--triggerOnce highlighting gets turned off by a timer generated
	--when the highlighting gets turned on
	--_.buttons["triggerOnce"]:setFillColor( 0, 0, 0, 1 )
	_.buttons["triggerFreeRun"]:setFillColor( 0, 0, 0, 1 )

	
	if ams.trigger == "stop" then
		_.buttons["triggerStop"]:setFillColor( unpack(highlightColor))
	elseif ams.trigger == "none" then
		_.buttons["triggerNone"]:setFillColor( unpack(highlightColor))
	elseif ams.trigger == "once" then
		_.buttons["triggerOnce"]:setFillColor( unpack(highlightColor))
		--In the callback listener for triggerOnce the trigger mode is set 
		--to "none" so triggerNone will be highlighted.  The code snippet
		--below disables the highlighting on the single trigger icon.		
		timer.performWithDelay( 500, 
			function() 
				_.buttons["triggerOnce"]:setFillColor( 0, 0, 0, 1 )
			end, 1 )
	elseif ams.trigger == "freeRun" then
		_.buttons["triggerFreeRun"]:setFillColor( unpack(highlightColor))
	end	
end

local function updateSceneStatus()
	local highlightColor = {1, 1, 0, 1}
	local currScene = composer.getSceneName( "current" )
	_.buttons["home"]:setFillColor( 0, 0, 0, 1 )
	_.buttons["train"]:setFillColor( 0, 0, 0, 1 )
	_.buttons["event"]:setFillColor( 0, 0, 0, 1 )
	if currScene == "scene_home" then
		_.buttons["home"]:setFillColor( unpack(highlightColor))
	elseif currScene == "scene_help" then
		_.buttons["home"]:setFillColor( unpack(highlightColor))		
	elseif currScene == "scene_train" then
		_.buttons["train"]:setFillColor( unpack(highlightColor))
	elseif currScene == "scene_event" then
		_.buttons["event"]:setFillColor( unpack(highlightColor))
	end

end

local function updateMouseStatus()

	mouseData.newX = md.state.mouse.x
	mouseData.newY = md.state.mouse.y
	--mouseData.endTime = md.state.mouse.time
	mouseData.endTime = system.getTimer()

	if mouseData.newX == mouseData.oldX and
	mouseData.newY == mouseData.oldY then
		if mouseData.endTime - mouseData.startTime > 1000 then
			--Display a tooltip if the mouse has stayed in the same position
			--for more than 1 second.
			for k,button in pairs( _.buttons ) do
				local bounds = button.contentBounds
				local x = mouseData.newX
				local y = mouseData.newY
				if x > bounds.xMin and x < bounds.xMax then
					if y > bounds.yMin and y < bounds.yMax then
						if not _.tooltip.active then
							_.tooltip.x = button.x	
							_.tooltip.y = _.tooltip.options.y
							_.tooltip.active = true
							mf.dprint( "Activating tooltip." )
							local options = {
								x = 0,
								y = 0,
								width = _.tooltip.options.width,
								fontSize = _.tooltip.options.fontSize,
								align = "center",
								text = button.toolTip,
								parent = _.tooltip,
							}
							--Shift the tooltip to the right if it's at the 
							--left edge of the screen							
							_.tooltip.x = math.max( _.tooltip.x, options.width )
							--Shift the tooltip to the left if it's at the 
							--rfight edge of the screen							
							_.tooltip.x = math.min( _.tooltip.x, display.actualContentWidth-options.width )
							
							_.tooltip.text = display.newText( options )
							_.tooltip.text:setFillColor( 0 )

							_.tooltip.background = display.newRoundedRect( 0, 0, 
								1.6*_.tooltip.text.width, 1.2*_.tooltip.text.height, 5 )					
							_.tooltip.background:setFillColor( 1 )
							_.tooltip.background:setStrokeColor( 0 )
							_.tooltip.background.strokeWidth = 3
							_.tooltip:insert( _.tooltip.background )
							_.tooltip:insert( _.tooltip.text )
							_.tooltip.alpha = 1
						end
					end
				end					
			end

		else
			--Hide the tooltip textbox
			_.tooltip.alpha = 0
			if _.tooltip.active then
				_.tooltip.active = false
				mf.dprint( "Deactivating tooltip." )
				_.tooltip.background:removeSelf()
				_.tooltip.background = nil
				_.tooltip.text:removeSelf()
				_.tooltip.text = nil
			end
		end
	else
		mouseData.oldX = mouseData.newX
		mouseData.oldY = mouseData.newY
		mouseData.startTime = mouseData.endTime
	end	

end

_.updateMenuBar = function( params )

	--If the user has selected a new tab this forces the udpate to occurr
	--If not, it's pointing exactly where it was before so no harm done.
	ams = md.instrumentSettings.current

	updateConnectionStatus()

	updateTriggerStatus()

	updateSceneStatus()

	updateMouseStatus()

end

_.drawMenuBarButtons = function( params )

	mf.dprint( "Creating top menu bar buttons." )

	local sW, sH = md.screenW, md.screenH
	local w, h = md.tileW, md.tileW

	local p = {
		parent = params.parent,		
		font = params.font or md.defaultFont,
		fontSize = params.fontSize or md.defaultFontSize,
		fontColor = params.fontColor or md.defaultFontColor,
		stroke = params.stroke or {0, 0, 0, 0.8},
		strokeWidth = params.strokeWidth or 3,			
		midX = params.midX or 0.5*sW,
		midY =  params.midY or 0.5*sH,
		divLineX = params.divLineX or 0.5*sW,
		menuWidth = params.mWidth or sW,
		menuHeight =  params.mHeight or sH,
		buttonWidth = params.bWidth or 0.045*sW,
		buttonHeight = params.bHeight or 0.045*sW,
	}


	--local listener = params.listener
	local listener = onMenuBarTouch
	local topEdge = p.midY-p.menuHeight/2
	local botEdge = p.midY+p.menuHeight/2

	local myRect = display.newRect( p.parent, p.midX, p.midY, p.menuWidth, p.menuHeight)
	myRect:setFillColor( 156/256, 176/256, 179/256 )
	myRect.strokeWidth = 0

	--Top menu bar line
	local myLine = display.newLine( p.parent, 0, topEdge, p.menuWidth, topEdge )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth

	--Bottom menu bar line
	myLine = display.newLine( p.parent, 0, botEdge, p.menuWidth, botEdge )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth

	--Left menu bar line
	myLine = display.newLine( p.parent, 4*0.0625*p.menuWidth, botEdge, 
		4*0.0625*p.menuWidth, topEdge )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth

	--Right menu bar line
	myLine = display.newLine( p.parent, sW-p.divLineX, botEdge, sW-p.divLineX, topEdge )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth

	local buttons = { 
		{id = "upload",
			x = 0.75*0.0625,
			paint = "images/upload.png",
			toolTip = "Send settings to instrument.",
		},			
		{id = "download",
			x = 2*0.0625,
			paint = "images/download.png",
			toolTip = "Retrieve settings from instrument.",
		},
		{id = "refresh",
			x = 3.25*0.0625,
			paint = "images/refresh57.png",
			toolTip = "Connection status.",
		},					
		{id = "status",
			x = 4.5*0.0625,
			paint = "images/warning9.png",
			toolTip = "Dangerous outputs.",
		},		
		{id = "triggerOnce",
			x = 9.5*0.0625,
			paint = "images/loop-arrow-1.png",
			toolTip = "Single trigger.",
		},		
		{id = "triggerStop",
			x = 11.5*0.0625,
			paint = "images/delete-button.png",
			toolTip = "Stop all triggering.",
		},		
		{id = "triggerNone",
			x = 8.5*0.0625,
			paint = "images/bnc.png",
			toolTip = "External trigger.",
		},		
		{id = "triggerFreeRun",
			x = 10.5*0.0625,
			paint = "images/repeat.png",
			toolTip = "Free run.",
		},				
		{id = "home",
			x = 12.75*0.0625,
			paint = "images/home4.png",
			toolTip = "Home/Config Screen",
		},
		{id = "train",
			x = 14*0.0625,
			paint = "images/train4.png",
			toolTip = "Train Screen",
		},
		{id = "event",
			x = 15.25*0.0625,
			paint = "images/ecg2.png",
			toolTip = "Event Screen",
		},
	}

	for m = 1,#buttons do
		--mf.dprint( m, compositePaint[m] )
		local panX = buttons[m].x*p.menuWidth 
		local panY = p.midY -- (rows/2-m+0.5)*h*1.1		
		local x = buttons[m].x
		local y = p.midY
		local id = buttons[m].id
		local myImageRect = display.newImageRect( p.parent, buttons[m].paint, p.buttonWidth, p.buttonHeight )
		myImageRect.x = panX
		myImageRect.y = panY
		myImageRect.id = buttons[m].id
		myImageRect.toolTip = buttons[m].toolTip
		myImageRect:addEventListener( "touch", listener )
		myImageRect:setFillColor( 0, 0, 0, 1 )
		_.buttons[id] = myImageRect
	end

---[[
	local options = {
		text = "AMS 4100",
		--x = 0.575*p.menuWidth,
		x = 6.5*0.0625*p.menuWidth,		
    y = p.midY,
		width = 0.21*p.menuWidth,
    --height = p.menuHeight,
		font = p.font,
		fontSize = 0.85*p.fontSize,
		align = "center",
		parent = p.parent,
	}
	_.statusText = display.newText( options )
	--_.statusText.anchorX = 0
	_.statusText:setFillColor( unpack( p.fontColor ))	
  --[[
  local myRect = display.newRect( options.x, options.y, options.width, p.menuHeight )
  p.parent:insert( myRect )
  myRect:setFillColor( 0,0,1,0.5 )
  --]]
	--Store the tooltip options for later.  The tooltip gets created and destroyed
	--dynamically as needed.
	_.tooltip.options = {
		x = options.x,
		y = 2.5*p.midY,
		width = 2.1*p.buttonWidth,
		fontColor = p.fontColor,
		--fontSize = 0.8*p.fontSize,
		fontSize = 0.9*p.fontSize,
	}

end

return _