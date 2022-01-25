
local composer = require( "composer" )
local scene = composer.newScene()
local widget = require( "widget" )

local bf = require( "bannerFunctions" )
local cf = require( "chartFunctions" )
local it = require( "instrumentTabBar" )
local ls = require("loadsave")
local md = require( "myData" )
local pf = require( "pulseFunctions" )
local mf = require( "myFunctions" )
--local tf = require( "tileFunctions" )
local tm = require( "topMenuBar" )
local ui = require( "uiFunctions" )
local gf = require( "graphFunctions" )

local ams = md.instrumentSettings.current
local pulseGraph

local instrumentTabGrp = display.newGroup()

local rTime = 0

local function onRightArrowTouch( event )
	if ams.LibID < 20 then
		ams.LibID = ams.LibID + 1
	else
		ams.LibID = 1
	end
	md.state.updatePulse = true
end

local function onLeftArrowTouch( event )
	if ams.LibID > 1 then
		ams.LibID = ams.LibID -1
	else
		ams.LibID = 20
	end
	md.state.updatePulse = true
end

local function onAmpAxisTouch( event )
	local t = event.target
	local e = ams.Event[ams.LibID]
	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		t.y0 = event.y
		t.Amp1 = e.Amp1
		t.Amp2 = e.Amp2
		t.ampScale = md.state.ampScale
		t.max = 0.6*md.screenH/md.state.ampScale/4
		md.state.scalingAmplitude = true
	elseif t.isFocus then
		if event.phase == "moved" then
			local bounds = t.contentBounds
			if event.y > bounds.yMin and event.y < bounds.yMax then
				local max = math.round( event.y/t.y0*t.max/md.settings.ampSteps ) * md.settings.ampSteps
				if e.Type == "monophasic" or e.Type == "biphasic" then
					max = math.max( math.abs(e.Amp1), max )
				else
					max = math.max( math.abs(e.Amp1), math.abs(e.Amp2), max )
				end
				--max = math.round( event.y/t.y0*t.max/md.settings.ampSteps ) * md.settings.ampSteps

				md.state.ampScale =  0.6*md.screenH/max/4

				mf.dprint( md.state.ampScale .. " " .. max )
				md.state.updatePulse = true
			end

			--md.state.updatePulse = true
		elseif event.phase == "ended" or event.phase == "cancelled" then
			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			md.state.scalingAmplitude = false
		end
	end
	return true
end

local function onDelayAxisTouch( event )
	local t = event.target
	local e = ams.Event[ams.LibID]
	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		t.x0 = event.x
		t.Delay = e.Delay
	elseif t.isFocus then
		if event.phase == "moved" then
			local bounds = t.contentBounds
			if event.x > bounds.xMin and event.x < bounds.xMax then
				e.Delay = t.Delay * event.x/t.x0
				e.Delay = math.round( e.Delay/md.settings.timeSteps) * md.settings.timeSteps
				if e.Delay == 0 and event.x > t.x0 then
					e.Delay = md.settings.timeSteps
				end
			end
		elseif event.phase == "ended" or event.phase == "cancelled" then
			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
		end
	end
	return true
end

local function onTimeAxisTouch( event )
	local t = event.target
	local e = ams.Event[ams.LibID]
	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		t.x0 = event.x
		t.Period = e.Period
	elseif t.isFocus then
		if event.phase == "moved" then
			local bounds = t.contentBounds
			if event.x > bounds.xMin and event.x < bounds.xMax then
				e.Period = t.Period * t.x0/event.x
				e.Period = math.round( e.Period/md.settings.timeSteps) * md.settings.timeSteps
				if e.Type == "monophasic" then
					e.Period = math.max( e.Period, e.Dur1 )
				elseif e.Type == "biphasic" then
					e.Period = math.max( e.Period, 2*e.Dur1+e.Intr )
				else
					e.Period = math.max( e.Period, e.Dur1+e.Intr+e.Dur2 )
				end
			end

			md.state.updatePulse = true
		elseif event.phase == "ended" or event.phase == "cancelled" then
			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
		end
	end
	return true
end

local function onRectAlphaTap( event )
	
	local t = event.target
	if md.state.eventRectAlpha < 0.2 then
		md.state.eventRectAlpha = 0.3
	else
		md.state.eventRectAlpha = 0
	end	
	t.alpha = md.state.eventRectAlpha + 0.4
end

-- listener function
local function onEveryFrame( event )


	cf.updateChart()
	cf.updatePulse()
	bf.updateBanner()
	it.updateMenuBar()
	tm.updateMenuBar()

	pulseGraph.options.event = ams.Event[ams.LibID]

	local showMixedIndicator = false
	for m = 1, #ams.EventList.Mixed do
		if ams.LibID == ams.EventList.Mixed[m] then
			showMixedIndicator = true
		end
	end
	if showMixedIndicator then
		cf.mixedEventText.alpha = 1
		cf.mixedEventIndicator.alpha = 1
	else
		cf.mixedEventText.alpha = 0
		cf.mixedEventIndicator.alpha = 0
	end
	if ams.LibID == ams.EventList.Uniform then
		cf.uniformEventText.alpha = 1
		cf.uniformEventIndicator.alpha = 1
	else
		cf.uniformEventText.alpha = 0
		cf.uniformEventIndicator.alpha = 0
	end


	if md.state.updateEvent then
		md.state.updateEvent = false
		ams.Event[ams.LibID].updateCoords = true
		--ams:Stop()
		ams.Event[ams.LibID]:setMenuVals()
		--ams:Run()
		local restartOutput = false
		if ams.Train.Type == "uniform" and ams.LibID == ams.EventList.Uniform then
			restartOutput = true
		elseif ams.Train.Type == "mixed" then
			for m = 1, #ams.EventList.Mixed do
				if ams.LibID == ams.EventList.Mixed[m] then
					restartOutput = true
				end
			end
		end
		if restartOutput then
			ams:Stop()
			ams:Run()
		end

	end

	if md.state.appResumed then
		md.state.appResumed = false
		--maskGroup2:invalidate()
		--maskGroup3:invalidate()
		--pic:invalidate()
	end

end

function scene:create( event )

	mf.dprint( "scene_event entered." )
	--mf.dprint( md.events[md.eventNum] )
	local sceneGroup = self.view

	local sW, sH = md.screenW, md.screenH
	local midX = 0.39*sW
	local midY = 0.45*sH
	local myRect

	local bk = display.newRect( sceneGroup, 0.5*sW, 0.5*sH, sW, sH )
	bk.fill = {1, 1, 1}

	local params

	--A-M Systems logo
	params = {
		parent = sceneGroup,
		x = md.gui.background.x,
		y = md.gui.background.y,
		w = md.gui.background.w,
		h = md.gui.background.h,
	}
	ui.drawBackground( params )

	--Trap the case where the Event List is empty.
	if ams.LibID < 0 or ams.LibID > 20 then
		ams.LibID = 1
	end

	--Right side banner
	params = {
		parent = sceneGroup,
		midX = md.gui.banner.midX,
		midY = md.gui.banner.midY,
		bannerHeight = md.gui.banner.bannerHeight,
		w = md.gui.banner.w,
		h = md.gui.banner.h,
		font = md.defaultFont,
		fontSize = md.defaultFontSize,
	}
	bf.drawBanner( params )

	--Top menu bar
	params = {
		parent = sceneGroup,
		midX = md.gui.topMenu.midX,
		midY = md.gui.topMenu.midY,
		mWidth = md.gui.topMenu.mWidth,
		mHeight = md.gui.topMenu.mHeight,
		divLineX = md.gui.topMenu.divLineX,
	}
	tm.drawMenuBarButtons( params )

	local e = ams.Event[ams.LibID]
	--[[
	if md.settings.timeSteps > e.Period then
		md.settings.timeSteps = e.Period
	end
	--]]
	--midY = 0.2*sH
	midY = 0.87*sH
	--Full pulse event showing delay and quantity
	params = {
		parent = sceneGroup,
		x = midX,
		y = midY,
		w = 0.6*sW,
		h = 0.15*sH,
		--x = md.gui.bottomGraph.x,
		--y = md.gui.bottomGraph.y,
		--w = md.gui.bottomGraph.w,
		--h = md.gui.bottomGraph.h,
		event = ams.Event[ams.LibID],
		getFull = true,
		getDelay = true,
		offset = 0,
		hold = 0,
		text = {
			--x = -0.5*0.72*sW,
			--y = -0,
			x = 0.25*sW,
			y = -0.65*sH,
			--fontSize = 1.5*md.defaultFontSize,
			fontSize = 3*md.defaultFontSize,
			--fontColor = {0, 0, 0, 1},
			fontColor = {0, 0, 0, 0.6},
		},
		stroke = { type = "image", filename = "images/Picture5.png" },
		strokeWidth = 6,
		outline = {visible = false},
	}
	if (ams.Train.OffsetOrHold == "offset") then
		params.offset = ams.Train.Level
	elseif (ams.Train.OffsetOrHold == "hold") then
		params.hold = ams.Train.Level
	end

	pulseGraph = pf.new( params )

	--Right arrow
	params = {
		x = midX + 0.325*sW,
		y = midY,
		width = 0.045*sW,
		height = 0.045*sW,
--		defaultFile = "images/arrow-24-64.png",
--		overFile = "images/arrow-24-64.png",
		defaultFile = "images/entypo-57-3555.png",
		overFile = "images/entypo-57-3555.png",
		onRelease = onRightArrowTouch,
	}
	sceneGroup:insert( widget.newButton( params ) )

	--Left arrow
	params = {
		x = midX - 0.325*sW,
		y = midY,
		width = 0.045*sW,
		height = 0.045*sW,
		defaultFile = "images/entypo-162-3704.png",
		overFile = "images/entypo-162-3704.png",
		onRelease = onLeftArrowTouch,
	}
	sceneGroup:insert( widget.newButton( params ) )

	params = {
		parent = sceneGroup,
		x = midX,
		y = 0.2*sH,
		w = 0.6*sW,
		h = 0.075*sH,
	}
	myRect = display.newRect( sceneGroup, params.x, params.y, params.w, params.h )
	myRect.alpha = 0
	myRect.isHitTestable = true
	myRect:addEventListener( "touch", onDelayAxisTouch )

	--Draw the background gridlines and axis labels for the event being 
	--edited and then overlay the actual pulse representing it on top of that.
	midY = 0.45*sH
	params = {
		parent = sceneGroup,
		x = midX,
		y = midY,
		w = 0.6*sW,
		h = 0.6*sH,
		numX = 3,
		fontSize = 0.75*md.defaultFontSize,
	}
	cf.drawChart( params )
	cf.drawPulse( params )
	
	--Draw a small rectangle in the lower right corner to enable toggling
	--the alpha of the rectangles used to capture touches on and off.
	myRect = display.newRect(sceneGroup, 0.65*sW, 0.7*sH, 0.03*sW, 0.03*sW )
	myRect:setFillColor( 0, 0, 0, 0  )
	myRect:setStrokeColor( 0 )
	myRect.strokeWidth = 5
	myRect.alpha = md.state.eventRectAlpha + 0.4
	myRect.isHitTestable = true
	myRect:addEventListener( "tap", onRectAlphaTap )

	--Draw the squiggle and text for indicating whether this event is
	--one of the events in the Event List.
	cf.mixedEventIndicator = display.newImageRect( sceneGroup, 'images/ecg2.png', 0.04*sW, 0.04*sW)
	cf.mixedEventIndicator.x = 0.72*sW
	cf.mixedEventIndicator.y = 0.2*sH
	cf.mixedEventIndicator:setFillColor( 0 )
	cf.mixedEventIndicator.alpha = 0
	
	params = {
		parent = sceneGroup,
		text = "M",
		x = 0.74*sW,
		y = 0.18*sH,
		font = md.defaultFont,
		fontSize = md.defaultFontSize,
	}
	cf.mixedEventText = display.newText( params )
	cf.mixedEventText:setFillColor( 0 )
	cf.mixedEventText.alpha = 0

	--Draw the squiggle and text for indicating whether this event is
	--the uniform event in Uniform mode.
	cf.uniformEventIndicator = display.newImageRect( sceneGroup, 'images/ecg2.png', 0.04*sW, 0.04*sW)
	cf.uniformEventIndicator.x = 0.72*sW
	cf.uniformEventIndicator.y = 0.3*sH
	cf.uniformEventIndicator:setFillColor( 0 )
	cf.uniformEventIndicator.alpha = 0

	params = {
		parent = sceneGroup,
		text = "U",
		x = 0.74*sW,
		y = 0.28*sH,
		font = md.defaultFont,
		fontSize = md.defaultFontSize,
	}
	cf.uniformEventText = display.newText( params )
	cf.uniformEventText:setFillColor( 0 )
	cf.uniformEventText.alpha = 0

	params = {
		parent = sceneGroup,
		x = 0.045*sW,
		y = midY,
		w = 0.09*sW,
		h = 0.6*sH,
	}
	myRect = display.newRect( sceneGroup, params.x, params.y, params.w, params.h )
	myRect.alpha = 0
	--myRect.fill = {0, 0, 0.5}
	myRect.isHitTestable = true
	myRect:addEventListener( "touch", onAmpAxisTouch )

	params = {
		parent = sceneGroup,
		x = midX,
		y = midY + 0.3375*sH,
		w = 0.6*sW,
		h = 0.075*sH,
	}
	myRect = display.newRect( sceneGroup, params.x, params.y, params.w, params.h )
	myRect.alpha = 0
	myRect.isHitTestable = true
	myRect:addEventListener( "touch", onTimeAxisTouch )

  params = {
    midX = 0.375*sW,
    midY = 0.975*sH,
    menuWidth = 0.75*sW,
    menuHeight = 0.05*sH,
    fontSize = md.defaultFontSize,
    parent = instrumentTabGrp,
  }

	params.parent = instrumentTabGrp
	it.drawTabBarButtons( params )
	sceneGroup:insert( instrumentTabGrp )

	mf.dprint( "scene_event created." )

end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- assign the above function as an "enterFrame" listener
		Runtime:addEventListener( "enterFrame", onEveryFrame )
	elseif ( phase == "did" ) then
		mf.dprint( "Event Screen Entered." )
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- remove the function below as an "enterFrame" listener
		--cf.captureGraph()
		--ams.Event[ams.LibID]:setMenuVals()
		--ams:setDisplay( "event" )
		--display.save( sceneGroup.myRects, "test" )

		Runtime:removeEventListener( "enterFrame", onEveryFrame )
		--cf.destroyFullPulse()

		md.amsMaster:storeSettings()

	elseif ( phase == "did" ) then
		mf.dprint( "scene_event removed" )
		composer.removeScene( "scene_event", false)
	end
end

function scene:destroy( event )
	local sceneGroup = self.view

end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene