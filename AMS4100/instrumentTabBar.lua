-----------------------------------------------------------------------------------------
--
-- Filename: topTabBar.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for drawing and creating the common ui elements used in
-- different scenes.  In particular this one handles adding and removing
-- tabs to display data from multiple instruments that may be connected.
--
-----------------------------------------------------------------------------------------
local composer = require( "composer" )
local widget = require( "widget" )
local md = require( "myData" )
local mf = require( "myFunctions" )
local ams = md.instrumentSettings.current

local _ = {}
_.tabLabels = { "123456"}
md.state.activeTab = 1

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
--
-- NOTE: Code outside of listener functions (below) will only be executed once.
--
-----------------------------------------------------------------------------------------

local function switchToNewTab( index )
	mf.dprint( "Tab bar event: " .. index  )
	mf.dprint( "Number active instruments: " .. #md.amsMaster.active  )
	--Set the current instrument to the highlighted tab
	md.state.activeTab = index

	--Reload the scene to force the changes to take effect
	local params = {
		effect = "crossFade",
		time = 0,
		params = {
			effect = "crossFade",
			time = 0,
			newInstrument = md.amsMaster.active[ index ]
		}
	}
	composer.gotoScene( "scene_transition", params )

end

-- ScrollView listener
local function scrollListener( event )

	local phase = event.phase
	local t = event.target

	if ( phase == "began" ) then print( "Scroll view was touched" )
	elseif ( phase == "moved" ) then print( "Scroll view was moved" )
		mf.dprint( t:getContentPosition() )
	elseif ( phase == "ended" ) then print( "Scroll view was released" )
	end

	-- In the event a scroll limit is reached...
	if ( event.limitReached ) then
		if ( event.direction == "up" ) then print( "Reached bottom limit" )
		elseif ( event.direction == "down" ) then print( "Reached top limit" )
		elseif ( event.direction == "left" ) then print( "Reached right limit" )
		elseif ( event.direction == "right" ) then print( "Reached left limit" )
		end
	end

	return true
end


local function instrumentTabBarEvent( event )

	local t = event.target
	if event.phase == "moved" then
		local dx = math.abs( ( event.x - event.xStart ) )
		-- If the touch on the button has moved more than 10 pixels,
		-- pass focus back to the scroll view so it can continue scrolling
		if ( dx > 10 ) then
			_.tabButtons:takeFocus( event )
		end
	elseif event.phase == "ended" then
		switchToNewTab( t.id )
	end
	return true
end

local function createButtons( params )

	--Create one button for each active instrument
	local numButtons = #md.amsMaster.active

	--local buttonWidth = params.menuWidth/(numButtons)
	local buttonWidth = 0.225*params.menuWidth
	local buttonHeight = params.menuHeight
	local listener = params.listener


	local x, y = params.midX, params.midY
	---[[

	local buttonGroup = widget.newScrollView( {
			x = x,
			y = y,
			width = params.menuWidth,
			height = params.menuHeight,
			hideBackground = true,
			verticalScrollDisabled = true,
--		scrollWidth = 600,
--		scrollHeight = 800,
			listener = scrollListener
		}
	)

	--Add a table to store references to the buttons later on
	buttonGroup.buttons = {}
	--local myRect = display.newRect( params.parent, x, y, params.menuWidth, params.menuHeight )
	--myRect:setFillColor( 156/256, 176/256, 179/256 )
	--]]

	for m = 1, numButtons do

		local labelColor
		if m == md.state.activeTab then
			labelColor = {default={0,0,0,1}, over ={0,1,1}}
		else
			labelColor = {default={0,0,0,0.4}, over ={0,1,1}}
		end

		-- Create the add and remove tab button widgets
		local myButton = widget.newButton(
			{
				parent = buttonGroup,
				id = m,
				label = "",  --Automatically gets updated in updateMenuButtons
				font = params.font,
				fontSize = params.fontSize,
				labelColor = labelColor,
				x = (m-0.5)*buttonWidth,
				y = 0.5*buttonHeight,
				shape = "roundedRect",
				width = 0.9*buttonWidth,
				height = 0.75*buttonHeight,
				cornerRadius = 2,
				--strokeColor = {default={156/256, 176/256, 179/256 }, over= {1,1,0.7,0.4}},
				strokeColor = {default={120/256, 135/256, 135/256 }, over= {1,1,0.7,0.4}},
				strokeWidth = 4,
				id = m,
				onEvent = listener,
			})

		--Make the active button stand out from the others


		--Store a reference to this buttons instrument to support tab switching
		myButton.activeInstrument = md.amsMaster.active[m]
		buttonGroup:insert( myButton )
		buttonGroup.buttons[m] = myButton
		--mf.dprint( (m-0.5)*buttonWidth )
	end
	--mf.dprint( md.state.activeTab*buttonWidth )
	mf.dprint( buttonGroup:getContentPosition() )
	local options = {
		x = (3-md.state.activeTab)*buttonWidth,
		time = 0}
	buttonGroup:scrollToPosition( options )

	return buttonGroup

end

-- Function to handle button events
local function addRemoveTabButtonEvent( event )

	local id = event.target.id

	if event.phase == "ended" then
		if id == "addTab" then
			--Add a new tab to the tab bar
			--_.tabLabels[ #_.tabLabels+1 ] = tonumber(_.tabLabels[#_.tabLabels])+1
			md.amsMaster:addActive()			
			local index = #md.amsMaster.active

			--Scan over the existing labels to find a new name for
			--this instrument
			local newName

			for m = 1, index do
				local labelGood = true
				newName = "AMS 4100 - " .. m
				for n = 1, index do
					if newName == _.tabLabels[n] then
						labelGood = false
					end
				end

				if labelGood then
					break
				end
			end
			md.amsMaster.active[ index ].InstrumentName = newName

			_.tabLabels[ index ] = md.amsMaster.active[ index ].InstrumentName
			
			--Load the default settings into the new instrument
			local ls = require("loadsave")
			if ls.doesFileExist("AMS4100TemporarySettings.ams4100", system.ResourceDirectory) then
				local newSettings = ls.loadTable("AMS4100TemporarySettings.ams4100", system.ResourceDirectory)
				md.amsMaster.active[ index ]:setMenuVals( newSettings )
			end
			
		elseif id == "removeTab" then
			--Remove the active tab
			if #_.tabLabels > 1 then
				local index = md.state.activeTab
				md.amsMaster:removeActive( index )
				if index > 1 then
					switchToNewTab( index-1 )
				else
					switchToNewTab( 1 )
				end
			end
			mf.dprint( "Active tab: " .. _.tabButtons.id )
		else
			return false

		end

		--Copy the options so they don't get clobbered in the next step
		local p = _.tabButtons.options

		--Remove all the old buttons
		for m = _.tabButtons.numChildren,1,-1 do
			_.tabButtons[m]:removeSelf()
			_.tabButtons[m] = nil
		end
		_.tabButtons:removeSelf()
		_.tabButtons = nil

		--Create new ones to replace the old ones
		_.tabButtons = createButtons( p )
		_.tabButtons.options = p
		_.tabButtons.id = _.tabButtons.numChildren
		--switchToNewTab( _.tabButtons.id )
		p.parent:insert( _.tabButtons )
		mf.dprint("Active sessions: " .. #md.amsMaster.active )

	end
end

_.updateMenuBar = function()

	for m = 1, #_.tabButtons.buttons do
		local label = _.tabButtons.buttons[m]:getLabel()

		if label ~= md.amsMaster.active[m].InstrumentName then
			local button = _.tabButtons.buttons[m]
			local buttonWidth = button.width
			local fontSize = button._view._fontSize
			local labelWidth = string.len( md.amsMaster.active[m].InstrumentName )*fontSize

			if labelWidth > buttonWidth then
				fontSize = fontSize * buttonWidth/labelWidth

			end

			_.tabButtons.buttons[m]:setLabel(md.amsMaster.active[m].InstrumentName)
			--Change the somewhat hidden size value of the actual label
			_.tabButtons.buttons[m]._view._label.size = fontSize
		end
	end

end

_.drawTabBarButtons = function( params )

	mf.dprint( "Creating top menu bar buttons." )

	local sW, sH = md.screenW, md.screenH
	local w, h = md.tileW, md.tileW

	local p = {
		parent = 		params.parent,
		font = 			params.font or md.defaultFont,
		fontSize = 		params.fontSize or md.defaultFontSize,
		fontColor = 	params.fontColor or md.defaultFontColor,
		stroke = 		params.stroke or {0, 0, 0, 0.8},
		strokeWidth = 	params.strokeWidth or 3,
		midX = 			params.midX or 0.5*sW,
		midY =  			params.midY or 0.5*sH,
		divLineX = 		params.divLineX or 0.5*sW,
		menuWidth = 	params.menuWidth or sW,
		menuHeight =  	params.menuHeight or sH,
		buttonWidth = 	params.bWidth or 0.045*sW,
		buttonHeight = params.bHeight or 0.045*sW,
	}

	--Create a white rectangle behind the bar to act as the background
	_.bg = display.newRect( p.parent, p.midX, p.midY, p.menuWidth, p.menuHeight )
	_.bg:setFillColor( 156/256, 176/256, 179/256 )

	local topEdge = p.midY-p.menuHeight/2
	local botEdge = p.midY+p.menuHeight/2
	--Top menu bar line
	local myLine = display.newLine( p.parent, 0, topEdge, p.menuWidth, topEdge )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth

	--Right edge line
	myLine = display.newLine( p.parent, p.menuWidth, topEdge, p.menuWidth, botEdge )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth

	---[[
	-- Create the add and remove tab button widgets
	_.addTabButton = widget.newButton(
		{
			x = 0.925*p.menuWidth,
			y = p.midY,
			width = 0.75*p.menuHeight,
			height = 0.75*p.menuHeight,
			defaultFile = "images/entypo-120-3662.png",
			overFile = "images/entypo-120-3662.png",
			id = "addTab",
			onEvent = addRemoveTabButtonEvent,
		})
	p.parent:insert( _.addTabButton )

	_.removeTabButton = widget.newButton(
		{
			x = 0.975*p.menuWidth,
			y = p.midY,
			width = 0.75*p.menuHeight,
			height = 0.75*p.menuHeight,
			defaultFile = "images/entypo-5-3486.png",
			overFile = "images/entypo-5-3486.png",
			id = "removeTab",
			onEvent = addRemoveTabButtonEvent,
		})
	p.parent:insert( _.removeTabButton )
	--]]
	for m = 1, #md.amsMaster.active do
		_.tabLabels[m] = md.amsMaster.active[m].InstrumentName
	end

	p.labels = _.tabLabels
	p.midX = 0.9*p.midX
	p.menuWidth = 0.9*p.menuWidth
	p.listener = instrumentTabBarEvent
	_.tabButtons = createButtons( p )
	_.tabButtons.options = p
	p.parent:insert( _.tabButtons )
end

return _