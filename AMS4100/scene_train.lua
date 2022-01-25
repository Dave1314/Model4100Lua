
local composer = require( "composer" )

local scene = composer.newScene()

local bf = require( "bannerFunctions" )
local cf = require( "chartFunctions" )
local it = require( "instrumentTabBar" )
local ls = require( "loadsave" )
local pf = require( "pulseFunctions" )
local mc = require( "myConnection" )
local md = require( "myData" )
local mf = require( "myFunctions" )
local tm = require( "topMenuBar" )
local ui = require( "uiFunctions" )
local widget = require( "widget" )

local ams = md.instrumentSettings.current

local lang = md.settings.language

local params = {}
local sceneGroup
local tempGroup = display.newGroup()
local libRects = display.newGroup()
local trainRectGrp = display.newGroup()
local trainEventGrp = display.newGroup()
local instrumentTabGrp = display.newGroup()

local function onRectGroupMaskTouch( event )
	--Trap touchs on the rectgroup mask when in uniform
	return true
end
--[[  Commented out to add in copy/paste function in Uniform mode.  Starting that with a copy of the onLibRectMixedTouch function.
		
local function onLibRectUniformTouch(event)
	
	local t = event.target
	local p = t.parent
	local p2 = p.parent
	local pulse = p.pulse
	
	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

			--Disable highlights if their finger moves off the button
			if dx > t.width/2 or dy > t.height/2 then
				display.getCurrentStage():setFocus( nil )
				t.isFocus = nil
			end

		elseif event.phase == "ended" or event.phase == "cancelled" then

			if ams.EventList.Uniform == pulse.options.id then
				local options = {
					effect = "fade",
					time = 400,
				}
					ams.LibID = pulse.options.id
					composer.gotoScene( "scene_event", options )
					return true
			else
				ams.EventList.Uniform = pulse.options.id
			end
			md.state.updateTrain = true
			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			return true
		end
	end	
end --]]


local function onLibRectUniformTouch(event)
	local t = event.target
	local p = t.parent
	local p2 = p.parent
	local pulse = p.pulse
		if event.phase == "began" then
			-- set touch focus
			display.getCurrentStage():setFocus( t )
			t.isFocus = true
			--If this is the original libRect copy it and pass the touch listener to the copy
			if t.isOriginal then

				local newPulse = p.pulse:copy()

				--p2:insert( newPulse.parent )
				tempGroup:insert( newPulse.parent )

				newPulse.parent.x = p.x
				newPulse.parent.y = p.y
				newPulse.parent.x0 = p.x
				newPulse.parent.y0 = p.y
				newPulse.outline.isOriginal = false
				newPulse.outline.isHitTestable = true

				newPulse.outline:addEventListener( "touch", onLibRectUniformTouch )
				newPulse.outline.isFocus = true
				newPulse.parent.tapped = true
				newPulse.parent.dx = event.x - p.x
				newPulse.parent.dy = event.y - p.y
				t.isFocus = false
				display.getCurrentStage():setFocus( newPulse.outline )
				return false
			else
				p.x0 = p.x
				p.y0 = p.y
				p.dx = event.x - p.x
				p.dy = event.y - p.y
				p.tapped = true
			end

		elseif t.isFocus then
			if event.phase == "moved" then
				local dx = math.abs(t.x - event.x)
				local dy = math.abs(t.y - event.y)

				p.x = event.x - p.dx
				p.y = event.y - p.dy
				local delta = (p.x-p.x0)^2 + (p.y-p.y0)^2

				--Monitor if the pulse's location changes by more than tileW
				--If it does not then this was a tap
				if delta > md.tileW then
					p.tapped = false
				end

			elseif event.phase == "ended" or event.phase == "cancelled" then

				local id = t.trainID
				mf.dprint( id )
				local trnBounds = trainRectGrp.contentBounds
				local libBounds = libRects.contentBounds
				local removePulse = false
				if p.tapped then
					if ams.EventList.Uniform ~= pulse.options.id then
							ams.EventList.Uniform = pulse.options.id
							display.getCurrentStage():setFocus( nil )
							--return true
					else							
						local options = {
							effect = "fade",
							time = 400,
						}
						ams.LibID = pulse.options.id
						composer.gotoScene( "scene_event", options )
						return true
					end
				end

				if p.x > libBounds.xMin and p.x < libBounds.xMax and
					p.y > libBounds.yMin and p.y < libBounds.yMax then

					tempGroup:insert( p )
					local delta = md.screenW
					id = 0
					for m = 1, 20 do
						local d = math.sqrt((libRects[m].x-p.x)^2 + (libRects[m].y-p.y)^2)
						if d < delta then
							delta = d
							id = m
						end
					end
					if id == 0 then
						mf.dprint("Bad id detected.")
					else
						ams.Event[id]:setMenuVals( pulse.options.event )
						pulse:removeSelf()
					end
				else
					pulse:removeSelf()
				end
				md.state.updateTrain = true
				-- reset touch focus
				display.getCurrentStage():setFocus( nil )
			end
		end
end

local function onLibRectMixedTouch(event)
	local t = event.target
	local p = t.parent
	local p2 = p.parent
	local pulse = p.pulse
		if event.phase == "began" then
			-- set touch focus
			display.getCurrentStage():setFocus( t )
			t.isFocus = true
			--If this is the original libRect copy it and pass the touch listener to the copy
			if t.isOriginal then

				local newPulse = p.pulse:copy()

				--p2:insert( newPulse.parent )
				tempGroup:insert( newPulse.parent )

				newPulse.parent.x = p.x
				newPulse.parent.y = p.y
				newPulse.parent.x0 = p.x
				newPulse.parent.y0 = p.y
				newPulse.outline.isOriginal = false
				newPulse.outline.isHitTestable = true

				newPulse.outline:addEventListener( "touch", onLibRectMixedTouch )
				newPulse.outline.isFocus = true
				newPulse.parent.tapped = true
				newPulse.parent.dx = event.x - p.x
				newPulse.parent.dy = event.y - p.y
				t.isFocus = false
				display.getCurrentStage():setFocus( newPulse.outline )
				return false
			else
				p.x0 = p.x
				p.y0 = p.y
				p.dx = event.x - p.x
				p.dy = event.y - p.y
				p.tapped = true
			end

		elseif t.isFocus then
			if event.phase == "moved" then
				local dx = math.abs(t.x - event.x)
				local dy = math.abs(t.y - event.y)

				p.x = event.x - p.dx
				p.y = event.y - p.dy
				local delta = (p.x-p.x0)^2 + (p.y-p.y0)^2

				--Monitor if the pulse's location changes by more than tileW
				--If it does not then this was a tap
				if delta > md.tileW then
					p.tapped = false
				end

			elseif event.phase == "ended" or event.phase == "cancelled" then

				local id = t.trainID
				mf.dprint( id )
				local trnBounds = trainRectGrp.contentBounds
				local libBounds = libRects.contentBounds
				local removePulse = false
				--If the event is still close to the original location open the
				--event screen to edit that event.
				--local delta = (p.x-p.x0)^2 + (p.y-p.y0)^2
				--if delta < md.tileW then
				if p.tapped then
					if ams.Train.Type == "uniform" and
						ams.EventList.Uniform ~= pulse.options.id then
							ams.EventList.Uniform = pulse.options.id
							display.getCurrentStage():setFocus( nil )
							--return true
					else							
						local options = {
							effect = "fade",
							time = 400,
						}
						ams.LibID = pulse.options.id
						composer.gotoScene( "scene_event", options )
						return true
					end
				end

				--If the user dragged the event over the train drop it in
				if p.x > trnBounds.xMin and p.x < trnBounds.xMax and
					p.y > trnBounds.yMin and p.y < trnBounds.yMax and
					trainEventGrp.numChildren < 20 and ams.Train.Type == "mixed" then

						trnBounds.yMid = (trnBounds.yMax + trnBounds.yMin)/2
						--Figure out if the new pulse is being dropped between
						--two existing ones
						local index = trainEventGrp.numChildren + 1

						if trainEventGrp.numChildren < 10 then
							for m = 1, trainEventGrp.numChildren do
								if p.x < trainEventGrp[m].x then
									index = m
									break
								end
							end
						elseif p.y < trnBounds.yMid then
							for m = 1, 10 do
								if p.x < trainEventGrp[m].x then
									index = m
									break
								end
							end
						else
							for m = 11, trainEventGrp.numChildren do
								if p.x < trainEventGrp[m].x then
									index = m
									break
								end
							end
						end

						--Trap something funky happening to the index value or p itself
						trainEventGrp:insert( index, p )
				---[[
				elseif p.x > libBounds.xMin and p.x < libBounds.xMax and
					p.y > libBounds.yMin and p.y < libBounds.yMax then
					--User dropped the lib rect over the Library in Mixed mode.  
					--Figure out where and copy the parameters to the new location.

					--Insert the pulse into tempGroup.  This prevents the pulse getting
					--reinserted into the Event List
					tempGroup:insert( p )
					delta = md.screenW
					id = 0
					for m = 1, 20 do
						local d = math.sqrt((libRects[m].x-p.x)^2 + (libRects[m].y-p.y)^2)
						if d < delta then
							delta = d
							id = m
						end
					end

					local function onComplete()
						if id ~= 0 then
							ams.Event[id]:setMenuVals( pulse.options.event )
						else
							mf.dprint("Bad ID detected.")
						end
						pulse:removeSelf()
					end
					if id == 0 then
						mf.dprint("Bad id detected.")
					else

					transition.to( p, {time=200,
							x=libRects[id].x,
							y=libRects[id].y,
							onComplete = onComplete} )
					end
				else
					pulse:removeSelf()
				end

				for m = 1, trainEventGrp.numChildren do
					transition.to( trainEventGrp[m], {time = 200,
						x = trainRectGrp[m].x, y = trainRectGrp[m].y})
				end
				--Update the event list with the current train events
				for m = 1, 20 do
					if trainEventGrp[m] then
						ams.EventList.Mixed[m] = trainEventGrp[m].pulse.options.id
					else
						ams.EventList.Mixed[m] = -1
					end
				end
				md.state.updateTrain = true
				-- reset touch focus
				display.getCurrentStage():setFocus( nil )
			end
		end
end

local function onLibRectTouch(event)
	--onLibRectMixedTouch(event)
	---[[
	if ams.Train.Type == "uniform" then
		onLibRectUniformTouch(event)
	else
		onLibRectMixedTouch(event)
	end--]]
	return true
end

-- listener function
local function onEveryFrame( event )

	bf.updateBanner()
	tm.updateMenuBar()
	it.updateMenuBar()

	for m = 20, 1, -1 do
		--Check to see if events in the event list and in the trainEventGrp match
		if ams.EventList.Mixed[m] then
			if ams.EventList.Mixed[m] > 0 then
				local id = ams.EventList.Mixed[m]
				--See if an entry already exists here
				if trainEventGrp[m] then
					if ams.EventList.Mixed[m] == trainEventGrp[m].pulse.options.id then
						--Do nothing, events match up
					else
						--If a pulse exists change it's event to the new one
						trainEventGrp[m].pulse.options.event = ams.Event[id]
					end
				else
					--Insert a new pulse in this spot
					local newPulse = libRects[id].pulse:copy()
					mf.dprint( "Inserting event: " .. id )

					trainEventGrp:insert( m, newPulse.parent )
					newPulse.parent.x = trainRectGrp[m].x
					newPulse.parent.y = trainRectGrp[m].y
					newPulse.options.id = ams.EventList.Mixed[m]
					newPulse.outline.isOriginal = false
					newPulse.outline:addEventListener( "touch", onLibRectTouch )
					newPulse.parent.x0 = trainRectGrp[m].x
					newPulse.parent.y0 = trainRectGrp[m].y
					newPulse.parent.dx = 0
					newPulse.parent.dy = 0

				end
				--I observed one case where a corrupted Event List caused an error
				--in the next block of code.  The Event List had 4 valid events followed
				--by 4 -1s, then 3 more valid event numbers.  This caused the code to
				--try and access a nonexistant trainEventGrp.  
				if trainEventGrp[m] then
					if ams.Config.Auto == "fill" and m > 1 then
						trainEventGrp[m].pulse.options.getDelay = false
					elseif ams.Config.Auto == "count" and m > 1 then
						trainEventGrp[m].pulse.options.getDelay = false
					else
						trainEventGrp[m].pulse.options.getDelay = true
					end
				end
			else
				--If a pulse exists here remove it, event list is set at -1
				if trainEventGrp[m] then
					--trainEventGrp[m].pulse:removeSelf()
					trainEventGrp[m]:removeSelf()
				end
			end
		else
			mf.dprint("Nil event number detected.")
		end

		--If we're in uniform mode blank out all the pulses
		--The uniform event pulse will get unmasked in the next code block
		if ams.Train.Type == "uniform" then
			libRects[m].pulse.pulse.options.line.alpha = 0.25
		else
			libRects[m].pulse.pulse.options.line.alpha = 1
		end

	end

	if ams.Train.Type == "uniform" then
		--libRects[ams.EventList.Uniform].alpha = 1
		libRects[ams.EventList.Uniform].pulse.pulse.options.line.alpha = 1
		trainRectGrp.mask:setFillColor( 1, 1, 1, 0.6 )
	else
		trainRectGrp.mask:setFillColor( 1, 1, 1, 0 )
	end

	if md.state.updateHome then
		md.state.updateHome = false
		ams.updateCoords = true
		ams.Config:setMenuVals()
	end
	if md.state.updateTrain then
		md.state.updateTrain = false
		ams.updateCoords = true
		ams:Stop()
		ams.Train:setMenuVals()
		ams.Config:setMenuVals()
		ams.EventList:set()
		ams:Run()
	end
	if md.state.updatePeriods then
		md.state.updatePeriods = false
		ams.Train:setPeriod( ams.Train.Period )
		for m = 1, 20 do
			ams.Event[m]:setPeriod( ams.Event[m].Period )
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

	mf.dprint( "scene_train entered." )
	--local sceneGroup = self.view
	sceneGroup = self.view
	--Draw the boxes to indicate library and event positions
	local sW, sH = md.screenW, md.screenH

	local midX = 0.365*sW
	local midY = 0.5*sH

	local bk = display.newRect( sceneGroup, 0.5*sW, 0.5*sH, sW, sH )
	bk.fill = {1, 1, 1}

	params = {
		parent = sceneGroup,
		x = md.gui.background.x,
		y = md.gui.background.y,
		w = md.gui.background.w,
		h = md.gui.background.h,
		}
	ui.drawBackground( params )

	--Create the run buttons
	params.listener = onRunBtnTouch
	--ui.drawRunButtons( params )

	--Draw the right side banner
	params = {
		parent = sceneGroup,
		midX = md.gui.banner.midX, --0.87*sW,
		midY = md.gui.banner.midY, --0.48*sH,
		bannerHeight = md.gui.banner.bannerHeight, --0.65*md.contentH,
		w = md.gui.banner.w, --0.125*sW,
		h = md.gui.banner.h, --1.6*md.defaultFontSize,
		font = md.defaultFont,
		fontSize = md.defaultFontSize,
	}
	bf.drawBanner( params )

	--Draw the top menu bar
	params = {
		parent = sceneGroup,
		midX = md.gui.topMenu.midX, --0.5*sW,
		midY = md.gui.topMenu.midY, --0.1*sH,
		mWidth = md.gui.topMenu.mWidth, --sW,
		mHeight = md.gui.topMenu.mHeight, --0.1*sH,
		divLineX = md.gui.topMenu.divLineX, --0.25*sW,
	}
	tm.drawMenuBarButtons( params )

	--Draw the 'Library' text
	--local yOffset = 0.15*sH
	local yOffset = 0.0*sH
	midY = 0.15*sH + yOffset
	local options = {
		parent = sceneGroup,
		text = "Library",
		x = midX,
		y = midY,
		fontSize = 0.065*sH,
		font = md.defaultFont,
	}
	local libText = display.newText( options )
	libText:setFillColor( 0.25 )

	--Draw the 'Event List' text
	options.text = "Event List"
	--options.y = 0.515*sH + yOffset
	options.y = libText.y + 0.325*sH
	local trnText = display.newText( options )
	trnText:setFillColor( 0.25 )

	--Draw the Library and Event List
	local rows, cols = 2, 10

	local w = sW*0.065
	local h = w

	for m = 1, rows do
		for n = 1, cols do
			local panX = midX - (cols/2-n+0.5)*1.1*w
			local panY = midY - (rows/2-m+0.5)*1.1*h + 0.16*sH
			local id = n + (m-1)*cols
			ams:checkEventParameters( id )
			params = {
				parent = libRects,
				x = panX,
				y = panY,
				w = sW*0.065,
				h = sW*0.065,
				r = sW*0.0065,
				id = n + (m-1)*cols,
				event = ams.Event[ id ],
				getFull = true,
				getDelay = true,
				grid = {visible = false},
				outline = {visible = true},
				stroke = { type = "image", filename = "images/Picture5.png" },
				strokeWidth = 5,
				text = {
					x = -sW*0.065/4,
					y = -sW*0.065/4,
					text = ams.Event[id].id,
					fontSize = md.defaultFontSize,
					visible = true,
				},
				pulse = {
					x = 0,
					y = sW*0.065/4,
					w = sW*0.065,
					h = sW*0.065/3,
					line = {alpha = 1},
				},
				label = {visible = false},
				listener = onLibRectTouch,
			}
		   local newPulse = pf.new( params )
			newPulse.outline.isOriginal = true
			newPulse.outline:addEventListener( "touch", onLibRectTouch )
			--libRects:insert( newPulse.parent )

			--Draw the outlines for the trainRectGrp
			--panY = panY + 0.325*sH
			panY = panY + 0.325*sH
			local trainRect = display.newRoundedRect( trainRectGrp,
				panX, panY, w, h, 0.1*w)
			trainRect.isOccupied = false
			trainRect.id = n + (m-1)*cols
			trainRect:setFillColor( 0.5, 0.5, 0.5, 0 )
			trainRect:setStrokeColor( 0.75 )
			trainRect.strokeWidth = 2

		end
	end

	trainRectGrp.mask = display.newRect( trainRectGrp, midX, midY+0.485*sH, 11*w, 2.25*h )
	trainRectGrp.mask:setFillColor( 1, 1, 1, 0 )
	trainRectGrp.mask:addEventListener( "touch", onRectGroupMaskTouch )
	--Insert the events from the current event list into the train
	for m = 1, 20 do
		local value = tonumber(ams.EventList.Mixed[m]) or -1
		if value > 0 then
			local id = tonumber( ams.EventList.Mixed[m] )
			local newPulse = libRects[id].pulse:copy()
			trainEventGrp:insert( newPulse.parent )

			newPulse.parent.x = trainRectGrp[m].x
			newPulse.parent.y = trainRectGrp[m].y
			newPulse.options.id = ams.EventList.Mixed[m]
			newPulse.outline.isOriginal = false
			newPulse.outline:addEventListener( "touch", onLibRectTouch )
			newPulse.parent.x0 = trainRectGrp[m].x
			newPulse.parent.y0 = trainRectGrp[m].y
			newPulse.parent.dx = 0
			newPulse.parent.dy = 0
			if m == 1 then
				--newPulse.options.getDelay = true
				newPulse.options.getDelay = true
			else
				newPulse.options.getDelay = true
			end
		end
	end

	params = {
		parent = sceneGroup,
		x = md.gui.bottomGraph.x,
		y = md.gui.bottomGraph.y,
		w = md.gui.bottomGraph.w,
		h = md.gui.bottomGraph.h,
		event = ams,
		outline = {visible = false},
		stroke = { type = "image", filename = "images/Picture5.png" },
		strokeWidth = 5,
		text = {
			x = -0.4*0.7*sW,
			y = -0.6*0.15*sH,
			fontSize = md.defaultFontSize,
		},
	}
	local trainGraph = pf.new( params )

  params = {
    midX = 0.375*sW,
    midY = 0.975*sH,
    menuWidth = 0.75*sW,
    menuHeight = 0.05*sH,
    fontSize = md.defaultFontSize,
    parent = instrumentTabGrp,
  }
	it.drawTabBarButtons( params )

	sceneGroup:insert( trainRectGrp )
	sceneGroup:insert( libRects )
	sceneGroup:insert( trainEventGrp )
	sceneGroup:insert( tempGroup )
	sceneGroup:insert( trainRectGrp.mask )
	sceneGroup:insert( instrumentTabGrp )

	mf.dprint( "scene_train created." )

end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- assign the above function as an "enterFrame" listener
		Runtime:addEventListener( "enterFrame", onEveryFrame )
	elseif ( phase == "did" ) then
		mf.dprint( "scene_train entered" )
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		--ams:setDisplay( "train" )
		--Explicitly destroy the pulses to make sure they're onEveryFrame
		--events aren't firing at bad times.
		---[[
		for m = trainRectGrp.numChildren, 1, -1 do
			trainRectGrp[m]:removeSelf()
			trainRectGrp[m] = nil
		end
		for m = tempGroup.numChildren, 1, -1 do
			tempGroup[m]:removeSelf()
			tempGroup[m] = nil
		end
		for m = trainEventGrp.numChildren, 1, -1 do
			trainEventGrp[m]:removeSelf()
			trainEventGrp[m] = nil
		end
		for m = libRects.numChildren, 1, -1 do
			libRects[m]:removeSelf()
			libRects[m] = nil
		end
		--]]

		Runtime:removeEventListener( "enterFrame", onEveryFrame )

		md.amsMaster:storeSettings()

	elseif ( phase == "did" ) then
		mf.dprint( "scene_train removed" )
		composer.removeScene( "scene_train", false)
	end
end

function scene:destroy( event )
	mf.dprint( "scene_train destroyed" )
	local sceneGroup = self.view

end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene