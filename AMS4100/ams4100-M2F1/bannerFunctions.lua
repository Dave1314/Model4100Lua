-----------------------------------------------------------------------------------------
--
-- Filename: bannerFunctions.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for drawing and creating the banner used on the event and possibly train screen
--
-----------------------------------------------------------------------------------------
local composer = require( "composer" )
local widget = require( "widget" )

local md = require( "myData" )
local mf = require( "myFunctions" )
local cf = require( "chartFunctions" )
local ams = md.instrumentSettings.current

local ls = require( "loadsave" )

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once.
-- 
-----------------------------------------------------------------------------------------

local _ = {}
_.bannerText = {}

local modeTypes = {
	order = {"intVolt", "intCurrent", "ext20VperV", "ext10mAperV", "ext1mAperV", "ext100uAperV"},
	intVolt = "Voltage",
	intCurrent = "Current",
	ext20VperV = "Ext 20V/V",
	ext10mAperV = "Ext 10mA/V",
	ext1mAperV = "Ext 1mA/V",
	ext100uAperV = "Ext 100uA/V",
}
local triggerTypes = {
	order = {"rising", "falling"},
	rising = "Rising",
	falling = "Falling",
}
local autoTypes = {
	order = {"none", "count", "fill"},
	none = "None",
	count = "Count",
	fill = "Fill",
}
local monTypes = {	
	order = {"scale100mVperV", "scale1VperV", "scale10VperV", "scale20VperV",
		"scale100uAperV", "scale1mAperV", "scale10mAperV", "scale100mAperV"},
	scale100mVperV = "0.1V/V",
	scale1VperV = "1V/V",	
	scale10VperV = "10V/V",
	scale20VperV = "20V/V",
	--There was an error in the scaling of the monitor, updating the values only 
	--to avoid causing other issues
	scale100uAperV = "10uA/V",
	scale1mAperV = "100uA/V",
	scale10mAperV = "1mA/V",
	scale100mAperV = "10mA/V",	
}
local syncTypes = {
	order = {"trainDelay", "trainDuration", "eventDelay", "eventDuration1", 
		"eventDuration2", "eventDuration3", "eventWidth", "clockuS", "clockmS" },
	trainDelay = "Train Del.",
	trainDuration = "Train Dur.",
	eventDelay = "Event Del.",
	eventDuration1 = "Event Dur1",
	eventDuration2 = "Event Intr",
	eventDuration3 = "Event Dur2",
	eventWidth = "Event Width", 
	clockuS = "Clock uS",
	clockmS = "Clock mS",
}	
local perTypes = {
	order = {"period", "frequency"},
	period = "Period",
	frequency = "Frequency",
}
local eventPulseTypes = {
	order = {"monophasic", "biphasic", "asymm", "ramp"},
	monophasic = "Mono", 
	biphasic = "Bi", 
	asymm = "Asymm",
	ramp = "Ramp",
}
local symTypes = {
	order = {"yes", "no"},
	yes = "Yes", 
	no = "No",
}
local trainPulseTypes = {
	order = {"mixed", "uniform"},
	mixed = "Mixed",
	uniform =  "Uniform",
}
local hoTypes = {
	order = {"hold", "offset"},
	hold = "Hold", 
	offset = "Offset",
}
local outTypes = {
	order = {"on", "off"},
	on = "Enabled", 
	off = "Disabled",
}

local function getNext( t, value )
	local index = 0
	for i,v in ipairs( t.order ) do
		if value == v then
			index = i
		end		
	end	
	if index < #t.order then
		index = index + 1
	else
		index = 1
	end
	return t.order[index]
end

local function getUserChoice( options )

	local tableView  --Forward declaration to facilitate destruction later on
	local tableViewBackground  --Forward declaration, used to capture all other touch input
	local sW, sH = md.screenW, md.screenH
	local x, y = options.x, options.y
	local group = options.group
	local value = options.target[options.key]
	local p = _.options  --Local reference for input parameters 
	local targetHeight = (#group.order+1)*p.h
	
	local function removeTableView()
		tableView:removeSelf()
		tableView = nil				
		tableViewBackground:removeSelf()
		tableViewBackground = nil
	end	
	
	local function onRowRender( event )
		-- Get reference to the row group
		local row = event.row

		-- Cache the row "contentWidth" and "contentHeight" because 
		-- the row bounds can change as children objects are added
		local rowHeight = row.contentHeight
		local rowWidth = row.contentWidth
		local options = 
		{
			parent = row,
			text = row.params.rowText,
			x = rowWidth * 0.5,
			y = rowHeight * 0.5,
			width = rowWidth,
			font = md.defaultFont,   
			fontSize = md.defaultFontSize,
			align = "center" 
		}
		--local rowTitle = display.newText( row, "Row " .. row.index, 0, 0, nil, 14 )
		local rowTitle = display.newText( options )
		rowTitle:setFillColor( 0 )

	end

	local function onRowTouch( event )
		--if event.phase == "tap" then
		if event.phase == "tap" or event.phase == "release" then
			local index = event.target.index
			local key = group.order[index] 
			mf.dprint( group.order[index] )
			mf.dprint( group[key] )
			options.target[options.key] = key
				
			transition.to( tableView, {time = 200, height = 0, onComplete = removeTableView} )
			if _.sceneName == "scene_train" then
				md.state.updateTrain = true
				md.state.updateConfig = true
			elseif _.sceneName == "scene_event" then
				md.state.updatePulse = true
				md.state.updateEvent = true
			elseif _.sceneName == "scene_configure" then
				md.state.updateTrain = true
				md.state.updateConfig = true
			elseif _.sceneName == "scene_home" then
				md.state.updateTrain = true
				md.state.updateConfig = true
			end	
		end		
	end

	local function scrollListener()
	end	

	local function onBackgroundTap( event )
		if event.phase == "ended" then
			transition.to( tableView, {time = 200, height = 0, onComplete = removeTableView} )
		end		
	end

	tableViewBackground = display.newRect( display.contentCenterX, 
	display.contentCenterY,	display.contentWidth, display.contentHeight)
	tableViewBackground:setFillColor( 0,0,0,0 )
	tableViewBackground.isHitTestable = true
	tableViewBackground:addEventListener( "touch", onBackgroundTap )
	p.parent:insert( tableViewBackground )
	-- Create the widget
	tableView = widget.newTableView(
		{
			x = x,
			y = y,
			height = targetHeight,
			width = p.w,
			--topPadding = p.h/2,
			--bottomPadding = p.h/2,
			isBounceEnabled = false,
			onRowRender = onRowRender,
			onRowTouch = onRowTouch,
			listener = scrollListener
		}
	)
	p.parent:insert( tableView )

	for m = 1, #group.order do
		-- Insert a row into the tableView
		local index = group.order[m]
		if type(v) ~= "table" then 
			tableView:insertRow({
					isCategory = false,
					params = {
						rowIndex = index,
						rowText = group[index],
					}})
		end
	end
	tableView.height = 0
	transition.to( tableView, {time = 200, height = targetHeight} )
	return value
end

---[[ 'onRelease' event listener for navigation buttons
local function onOpenRelayTouch(event)

	local t = event.target

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
			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			ams:OpenRelay()
			mf.dprint("Open relay command sent.")
		end
	end
	return true	-- indicates successful touch
end

---[[ 'onRelease' event listener for navigation buttons
local function onCloseRelayTouch(event)

	local t = event.target

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
			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			ams:CloseRelay()
			mf.dprint("Close relay command sent.")
		end
	end
	return true	-- indicates successful touch
end

---[[ 'onRelease' event listener for navigation buttons
local function onEmergencyStopTouch(event)

	local t = event.target

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

			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			ams:TriggerStop()
			ams:OpenRelay()
			ams:Stop()
		end
	end

	return true	-- indicates successful touch
end

---[[ 'onRelease' event listener for navigation buttons
local function onMaskRectTouch(event)

	local t = event.target

	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true		

	elseif t.isFocus then
		if event.phase == "moved" then

		elseif event.phase == "ended" or event.phase == "cancelled" then

			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
		end
	end
	mf.dprint( "Mask rect event detected." )
	return true	-- indicates successful touch
end

--'onRelease' event listener for horRect1
local function onBannerRectTouch(event)

	local t = event.target
	local p = t.parentGrp
	local e = ams.Event[ams.LibID]
	
	if t.isFocus then
		mf.dprint( "onBannerRectTouch " .. t.id .. " has the focus.")
	else
		mf.dprint( "onBannerRectTouch " .. t.id .. " does not have the focus.")		
	end
	
	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true		
		t.x0 = event.x - t.x
		--return true
	elseif t.isFocus then
		if event.phase == "moved" then
			mf.dprint( "onBannerRectTouch " .. t.id .. " touch event moved. ")
		elseif event.phase == "ended" or event.phase == "cancelled" then
			mf.dprint( "onBannerRectTouch " .. t.id .. " touch event ended. ")

			local needsUpdate = false
			local updatePeriods = false
			local options = { x = t.x, y = t.y }

			if t.id == "Type" then
				if _.sceneName == "scene_train" then			
					ams.Train.Type = getNext( trainPulseTypes, ams.Train.Type )
				elseif _.sceneName == "scene_event" then
					--e.Type = getNext( eventPulseTypes, e.Type )
					options.group = eventPulseTypes
					options.target = e
					options.key = "Type"
					getUserChoice( options )					
				end
				needsUpdate = true
			elseif t.id == "Hold/Off" then
				ams.Train.OffsetOrHold = getNext( hoTypes, ams.Train.OffsetOrHold )
				needsUpdate = true
			elseif t.id == "Mode" then				
				--ams.Config.Mode = getNext( modeTypes, ams.Config.Mode )
				--needsUpdate = true
				options.group = modeTypes
				options.target = ams.Config
				options.key = "Mode"
				getUserChoice( options )				
			elseif t.id == "Output" then				
				ams.Config.Output = getNext( outTypes, ams.Config.Output )
				needsUpdate = true				
			elseif t.id == "Trigger" then
				ams.Config.Trigger = getNext( triggerTypes, ams.Config.Trigger )
				needsUpdate = true
			elseif t.id == "Auto" then				
				ams.Config.Auto = getNext( autoTypes, ams.Config.Auto )
				needsUpdate = true				
				--Store or recall the values for train duration, period and quantity
				if ams.Config.Auto == "none" then
					--Recall the stored values
					ams.Train.Quantity = ams.Train.Stored.Quantity
					ams.Train.Period = ams.Train.Stored.Period
					ams.Train.Dur = ams.Train.Stored.Dur
				elseif ams.Config.Auto == "count" then
					ams.Train.Quantity = 1 
					ams.Train.Dur = ams:getTotalEventDuration()
					ams.Train.Period = ams.Train.Dur
				elseif ams.Config.Auto == "fill" then								
					ams.Train.Stored.Quantity = ams.Train.Quantity
					ams.Train.Stored.Period = ams.Train.Period
					ams.Train.Stored.Dur = ams.Train.Dur
					ams.Train.Period = ams.Train.Dur
				end				
			elseif t.id == "Sync 1" then			
				--ams.Config.Sync1 = getNext( syncTypes, ams.Config.Sync1 )
				--needsUpdate = true
				options.group = syncTypes
				options.target = ams.Config
				options.key = "Sync1"
				getUserChoice( options )
			elseif t.id == "Sync 2" then				
				--ams.Config.Sync2 = getNext( syncTypes, ams.Config.Sync2 )
				--needsUpdate = true
				options.group = syncTypes
				options.target = ams.Config
				options.key = "Sync2"
				getUserChoice( options )				
			elseif t.id == "Per/Freq" then
				ams.Config.PeriodOrFreq = getNext( perTypes, ams.Config.PeriodOrFreq )
				needsUpdate = true
				updatePeriods = true
			elseif t.id == "Monitor" then
				--ams.Config.Monitor = getNext( monTypes, ams.Config.Monitor )
				--needsUpdate = true
				options.group = monTypes
				options.target = ams.Config
				options.key = "Monitor"
				getUserChoice( options )							
			elseif t.id == "Comms" then
				--Do nothing
			elseif t.id == "App. Rev." then
				--Do nothing
			elseif t.id == "Firmware" then
				--Do nothing
			elseif t.id == "Serial #" then
				--Do nothing				
			else
				--Must be a text box to enter a value.  Set up and display
				--the keyboard
				local options = {
					isModal = true,
					effect = "fade",
					time = 200,
					params = {
						id = t.id,
						e = e,
						value = "Value",
						textBox = _.bannerText[t.id],
					}
				}
				if t.id == "Duration" then
					options.params.value = ams.Train.Dur
				elseif t.id == "Dur 1" then
					options.params.value = e.Dur1					
				elseif t.id == "Dur 2" then
					options.params.value = e.Dur2
				elseif t.id == "Amp 1" then
					options.params.value = e.Amp1
				elseif t.id == "Amp 2" then
					options.params.value = e.Amp2
				elseif t.id == "Intr" then
					options.params.value = e.Intr
				elseif t.id == "Freq. Step" then
					options.params.value = md.settings.freqSteps
				elseif t.id == "Time Step" then
					options.params.value = md.settings.timeSteps
				elseif t.id == "Amp. Step" then
					options.params.value = md.settings.ampSteps
				elseif t.id == "Period" then
					if _.sceneName == "scene_train" then
						options.params.value = ams.Train.Period
					else
						options.params.value = e.Period
					end					
				elseif t.id == "Frequency" then
					if _.sceneName == "scene_train" then
						options.params.value = 1/(ams.Train.Period/1000000)
					else
						options.params.value = 1/(e.Period/1000000)
					end					
				elseif t.id == "Delay" then
					if _.sceneName == "scene_train" then
						options.params.value = ams.Train.Delay
					else
						options.params.value = e.Delay
					end					
				elseif t.id == "Pre Delay" then
					options.params.value = ams.Train.PreDelay
				elseif t.id == "Post Delay" then
					options.params.value = ams.Train.PostDelay					
				elseif t.id == "Quantity" then
					if _.sceneName == "scene_train" then
						options.params.value = ams.Train.Quantity
					else
						options.params.value = e.Quantity						
					end					
				elseif t.id == "Uniform #" then
					options.params.value = ams.EventList.Uniform
				elseif t.id == "H/O Level" then
					options.params.value = ams.Train.Level					
				elseif t.id == "ID" then
					options.params.value = ams.Description					
				elseif t.id ==  "Name" then
					options.params.value = ams.InstrumentName
				elseif t.id == "Protocol" then
					options.params.value = ams.Description
				elseif t.id == "Address" then
					--options.params.value = md.settings.ipaddress
					options.params.value = ams.connection.address
				end

				composer.showOverlay( "scene_keyboard", options )				
			end
			if needsUpdate then
				if _.sceneName == "scene_train" then
					md.state.updateTrain = true
					md.state.updateConfig = true
				elseif _.sceneName == "scene_event" then
					md.state.updatePulse = true
					md.state.updateEvent = true
				elseif _.sceneName == "scene_configure" then
					md.state.updateTrain = true
					md.state.updateConfig = true
				elseif _.sceneName == "scene_home" then
					md.state.updateTrain = true
					md.state.updateConfig = true
				end				
			end

			if updatePeriods then
				md.state.updatePeriods = true
			end			

			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil			
			return true
		end

		-- reset touch focus
		--display.getCurrentStage():setFocus( nil )
		--t.isFocus = nil
	end
	mf.dprint( "Returned true.")
	return true	-- indicates successful touch
end

--'onRelease' event listener for horRect1
local function onPlusMinusButtonTouch(event)

	local t = event.target
	local p = t.parentGrp
	local e = ams.Event[ams.LibID]
	mf.dprint( "plusMinusButton  " .. t.id .. " touch event detected. " .. event.phase)
	if event.phase == "began" then
		-- set touch focus
		mf.dprint( "plusMinusButton  " .. t.id .. " touch event began.")
		display.getCurrentStage():setFocus( t )
		t.isFocus = true		
		t.x0 = event.x - t.x
		return true
	elseif t.isFocus then
		if event.phase == "moved" then
		
		elseif event.phase == "ended" or event.phase == "cancelled" then
			mf.dprint( "plusMinusButton  " .. t.id .. " touch event ended.")
			local needsUpdate = false
			local updatePeriods = false
			local options = { x = t.x, y = t.y }

			if t.id == "Quantity" then
				if _.sceneName == "scene_train" then
					ams.Train.Quantity = ams.Train.Quantity + t.sign
				else
					e.Quantity = e.Quantity + t.sign 
				end		
				needsUpdate = true		
			elseif t.id == "Delay" then
				if _.sceneName == "scene_train" then
					ams.Train.Delay = ams.Train.Delay + t.sign*md.settings.timeSteps
				else
					e.Delay = e.Delay + t.sign*md.settings.timeSteps
				end				
				needsUpdate = true		
			elseif t.id == "Duration" then
				ams.Train.Dur = ams.Train.Dur + t.sign*md.settings.timeSteps		
				needsUpdate = true
			elseif t.id == "Period" then
				if ams.Config.PeriodOrFreq == "period" then
					--mf.dprint(ams.Train.Period .. " " .. ams.Train.Frequency)
					if _.sceneName == "scene_train" then
						local newPeriod = ams.Train.Period + t.sign*md.settings.timeSteps
						--if newPeriod >= md.settings.timeSteps then
						if newPeriod > 0 then
							ams.Train.Period = newPeriod
						end
						--ams.Train.Period = ams.Train.Period + t.sign*md.settings.timeSteps
					else
						local newPeriod = e.Period + t.sign*md.settings.timeSteps
						--if newPeriod >= md.settings.timeSteps then
						if newPeriod > 0 then
							e.Period = newPeriod
						end
						--e.Period = e.Period + t.sign*md.settings.timeSteps
					end				
				else
					if _.sceneName == "scene_train" then
						local newPeriod = 1/(1/ams.Train.Period + t.sign/md.settings.freqSteps)
						if 1/newPeriod > 1/md.settings.freqSteps then
							ams.Train.Period = newPeriod
						end
					else
						local newPeriod = 1/(1/e.Period + t.sign/md.settings.freqSteps)
						--if newPeriod > 0 then
						if 1/newPeriod > 1/md.settings.freqSteps then
							e.Period = newPeriod
						end
					end					
				end
				needsUpdate = true		
			elseif t.id == "Dur 1" then
				e.Dur1 = math.max(0, e.Dur1 + t.sign*md.settings.timeSteps)
				needsUpdate = true		
			elseif t.id == "Dur 2" then
				e.Dur2 = math.max(0, e.Dur2 + t.sign*md.settings.timeSteps)
				needsUpdate = true	
			elseif t.id == "Amp 1" then
				e.Amp1 = e.Amp1 + t.sign*md.settings.ampSteps
				needsUpdate = true	
			elseif t.id == "Amp 2" then
				e.Amp2 = e.Amp2 + t.sign*md.settings.ampSteps
				needsUpdate = true
			elseif t.id == "Intr" then
				e.Intr = math.max(0, e.Intr + t.sign*md.settings.timeSteps)
				needsUpdate = true					
			elseif t.id == "Frequency" then
				--This is handled by the 'Period' t.id
			elseif t.id == "Pre Delay" then
				options.params.value = ams.Train.PreDelay
			elseif t.id == "Post Delay" then
				options.params.value = ams.Train.PostDelay									
			elseif t.id == "H/O Level" then
				ams.Train.Level = ams.Train.Level + t.sign*md.settings.ampSteps
				needsUpdate = true
			end

			if needsUpdate then
				if _.sceneName == "scene_train" then
					md.state.updateTrain = true
					md.state.updateConfig = true
				elseif _.sceneName == "scene_event" then
					md.state.updatePulse = true
					md.state.updateEvent = true
					md.state.updateConfig = true
				elseif _.sceneName == "scene_configure" then
					md.state.updateTrain = true
					md.state.updateConfig = true
				elseif _.sceneName == "scene_home" then
					md.state.updateTrain = true
					md.state.updateConfig = true
				end				
			end

			if updatePeriods then
				md.state.updatePeriods = true
			end			

			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil			
			return true
		end
		-- reset touch focus
		--display.getCurrentStage():setFocus( nil )
		--t.isFocus = nil
	end
	mf.dprint( "Returned true.")
	return true	-- indicates successful touch
end

_.updateBanner = function()

	--If the user has selected a new tab this forces the udpate to occurr
	--If not, it's pointing exactly where it was before so no harm done.
	ams = md.instrumentSettings.current
	
	local timeDivisor, ampDivisor = 1, 1
	local alphaLevel = 0.7

	local e = ams.Event[ams.LibID]

	local function calcDisplayAmplitude( value )
		if ams.Config.Mode == "intCurrent" then
			return mf.calcDisplayAmps( value )
		else
			return mf.calcDisplayVolts( value )
		end
	end

	_.bannerText["Freq. Step"].text = mf.calcDisplayFreq( md.settings.freqSteps )
	_.bannerText["Time Step"].text = mf.calcDisplayTime( md.settings.timeSteps )
	_.bannerText["Amp. Step"].text = calcDisplayAmplitude( md.settings.ampSteps )
	
	if ams.condition.RelayClosed then
		_.relayClosedGrey.alpha = 0
		_.relayOpenGrey.alpha = 1
	else
		_.relayClosedGrey.alpha = 1
		_.relayOpenGrey.alpha = 0		
	end
		
	if _.sceneName == "scene_train" then

		ams:checkTrainParameters()

		_.bannerText["Auto"].text = autoTypes[ams.Config.Auto]
		_.bannerText["Type"].text = trainPulseTypes[ams.Train.Type]
		_.bannerText["Uniform #"].text = ams.EventList.Uniform		
		_.bannerText["Quantity"].text = ams.Train.Quantity		
		_.bannerText["Delay"].text = mf.calcDisplayTime(ams.Train.Delay)
		_.bannerText["Frequency"].text = mf.calcDisplayFreq(ams.Train.Period)
		_.bannerText["Period"].text = mf.calcDisplayTime(ams.Train.Period)
		_.bannerText["Duration"].text = mf.calcDisplayTime(ams.Train.Dur)
		_.bannerText["Hold/Off"].text = hoTypes[ams.Train.OffsetOrHold]
		_.bannerText["H/O Level"].text = calcDisplayAmplitude( ams.Train.Level )

		if ams.Train.Type == "uniform" then
			local id = ams.EventList.Uniform
			ams.LibID = id
			_.bannerText["Uniform #"].mask.alpha = 0
			_.bannerText["Uniform #"].mask.isHitTestable = false
		else
			local id = ams.EventList.Mixed[1]
			ams.LibID = id
			_.bannerText["Uniform #"].mask.alpha = alphaLevel
			_.bannerText["Uniform #"].mask.isHitTestable = false
		end

		--Hide the period or frequency boxes depending on instrument state
		if ams.Config.PeriodOrFreq == "period" then
			_.bannerText["Period"].alpha = 1
			_.bannerText["Period"].label.alpha = 1
			_.bannerText["Period"].rect.alpha = 1
			_.bannerText["Period"].mask.alpha = 1				
			_.bannerText["Frequency"].alpha = 0
			_.bannerText["Frequency"].label.alpha = 0
			_.bannerText["Frequency"].rect.alpha = 0
			_.bannerText["Frequency"].mask.alpha = 0
		else
			_.bannerText["Frequency"].alpha = 1
			_.bannerText["Frequency"].label.alpha = 1
			_.bannerText["Frequency"].rect.alpha = 1
			_.bannerText["Frequency"].mask.alpha = 1
			_.bannerText["Period"].alpha = 0
			_.bannerText["Period"].label.alpha = 0
			_.bannerText["Period"].rect.alpha = 0
			_.bannerText["Period"].mask.alpha = 0			
		end				

		if ams.Config.Auto == "fill" then
			if ams.Config.PeriodOrFreq == "frequency" then
				_.bannerText["Frequency"].mask.alpha = alphaLevel				
			else
				_.bannerText["Period"].mask.alpha = alphaLevel
			end			
			_.bannerText["Duration"].mask.alpha = 0
			_.bannerText["Quantity"].mask.alpha = alphaLevel
			if ams.Train.durError then
				_.bannerText["Duration"].rect:setFillColor( 1, 0, 0, 0.25 )
			else
				_.bannerText["Duration"].rect:setFillColor( 1 )
			end				
			local period, delay = ams:getTotalEventDuration()
			ams.Train.Quantity = math.floor( (ams.Train.Dur-delay)/(period-delay) )			
			ams.Train.Period = ams.Train.Dur
		elseif ams.Config.Auto == "count" then
			if ams.Config.PeriodOrFreq == "frequency" then
				_.bannerText["Frequency"].mask.alpha = alphaLevel				
			else
				_.bannerText["Period"].mask.alpha = alphaLevel
			end			
			_.bannerText["Duration"].mask.alpha = alphaLevel
			_.bannerText["Quantity"].mask.alpha = alphaLevel		
			ams.Train.Quantity = 1
			ams.Train.Dur = ams:getTotalEventDuration()
			ams.Train.Period = ams.Train.Dur			
		else
			if ams.Config.PeriodOrFreq == "frequency" then				
				_.bannerText["Frequency"].mask.alpha = 0
				--if ams.Train.freqError then
				if ams.Train.perError then
					_.bannerText["Frequency"].rect:setFillColor( 1, 0, 0, 0.25 )
				else
					_.bannerText["Frequency"].rect:setFillColor( 1 )
				end				
			else				
				_.bannerText["Period"].mask.alpha = 0
				if ams.Train.perError then
					_.bannerText["Period"].rect:setFillColor( 1, 0, 0, 0.25 )
				else
					_.bannerText["Period"].rect:setFillColor( 1 )
				end
			end			

			_.bannerText["Duration"].mask.alpha = 0			
			_.bannerText["Quantity"].mask.alpha = 0

			if ams.Train.durError then
				_.bannerText["Duration"].rect:setFillColor( 1, 0, 0, 0.25 )
			else
				_.bannerText["Duration"].rect:setFillColor( 1 )
			end					
		end

	elseif _.sceneName  == "scene_event" then	
		local perError = ams:checkEventParameters(ams.LibID)    
		_.bannerText["Type"].text = eventPulseTypes[e.Type]		
		_.bannerText["Quantity"].text = e.Quantity
		_.bannerText["Delay"].text = mf.calcDisplayTime(e.Delay)
		_.bannerText["Dur 1"].text = mf.calcDisplayTime(e.Dur1)
		_.bannerText["Intr"].text = mf.calcDisplayTime(e.Intr)
		_.bannerText["Amp 1"].text = calcDisplayAmplitude(e.Amp1)
		_.bannerText["Frequency"].text = mf.calcDisplayFreq(e.Period)
		_.bannerText["Period"].text = mf.calcDisplayTime(e.Period)

			if ams.Config.PeriodOrFreq == "frequency" then				
				_.bannerText["Frequency"].mask.alpha = 0
				--if ams.Train.freqError then
				if perError then
					_.bannerText["Frequency"].rect:setFillColor( 1, 0, 0, 0.25 )
				else
					_.bannerText["Frequency"].rect:setFillColor( 1 )
				end				
			else				
				_.bannerText["Period"].mask.alpha = 0
				if perError then
					_.bannerText["Period"].rect:setFillColor( 1, 0, 0, 0.25 )
				else
					_.bannerText["Period"].rect:setFillColor( 1 )
				end
			end	
		if e.Type == "biphasic" then 
			_.bannerText["Dur 2"].text = mf.calcDisplayTime(e.Dur1)
			_.bannerText["Amp 2"].text = calcDisplayAmplitude(-e.Amp1)	
			_.bannerText["Intr"].mask.alpha = 0
			_.bannerText["Amp 2"].mask.alpha = alphaLevel
			_.bannerText["Dur 2"].mask.alpha = alphaLevel
		elseif e.Type == "monophasic" then
			_.bannerText["Intr"].mask.alpha = alphaLevel
			_.bannerText["Amp 2"].mask.alpha = alphaLevel
			_.bannerText["Dur 2"].mask.alpha = alphaLevel			
		else
			_.bannerText["Dur 2"].text = mf.calcDisplayTime(e.Dur2)
			_.bannerText["Amp 2"].text = calcDisplayAmplitude(e.Amp2)
			_.bannerText["Intr"].mask.alpha = 0
			_.bannerText["Amp 2"].mask.alpha = 0
			_.bannerText["Dur 2"].mask.alpha = 0
		end


	elseif _.sceneName == "scene_home" then		
		local newSize
		_.bannerText["Trigger"].text = triggerTypes[ams.Config.Trigger]
		_.bannerText["Mode"].text = modeTypes[ams.Config.Mode]			
		_.bannerText["Monitor"].text = monTypes[ams.Config.Monitor]
		_.bannerText["Sync 1"].text = syncTypes[ams.Config.Sync1]
		_.bannerText["Sync 2"].text = syncTypes[ams.Config.Sync2]
		_.bannerText["Per/Freq"].text = perTypes[ams.Config.PeriodOrFreq]
		_.bannerText["Output"].text = outTypes[ams.Config.Output]		
		_.bannerText["Protocol"].text = ams.Description		
		_.bannerText["Name"].text = ams.InstrumentName

	elseif _.sceneName == "scene_help" then
	
		_.bannerText["App. Rev."].text = md.state.revision
		_.bannerText["Firmware"].text = ams.Revision
		_.bannerText["Serial #"].text = ams.SerialNumber
		_.bannerText["Local Pin"].text = ams.localPinNumber
		_.bannerText["Address"].text = ams.connection.address
		_.bannerText["Comms"].text = #ams.connection.sendBuffer	
	end		
	
	--Check to see if the length of the text is too long
	--If so decrease the font size to fit better
	--This function is essentially disabled so all text is now smaller
	for key, value in pairs(_.bannerText) do
		local newSize
		if value.text then
			local length = string.len(value.text)
			value.size = value.originalSize
			--if 0.6*length*value.size > value.rect.width then
				value.size = 0.8*value.size
			--end	
		end
	end
end

_.drawBanner = function( params )

	local sW, sH = md.screenW, md.screenH
	local p = {
		parent = params.parent,		
		font = params.font or md.defaultFont,
		fontSize = params.fontSize or md.defaultFontSize,
		fontColor = params.fontColor or md.defaultFontColor,
		midX = params.midX or 0.5*sW - sW/40,
		bannerHeight = params.bannerHeight or sH,
		stroke = params.stroke or {0, 0, 0, 0.8},
		strokeWidth = params.strokeWidth or 3,		
		w = params.w or sW/10,
	}
	
	
	p.midY =  params.midY or 2*p.fontSize
	p.h =  params.h or 1.1*p.fontSize
	
	--Store all the input options so they can be resued in the tableView
	_.options = p
	
	local myRect = display.newRect( p.parent, sW-p.w, sH/2, 2*p.w, sH )
	myRect:setFillColor( 156/256, 176/256, 179/256 )
	myRect.strokeWidth = 0

	local myLine = display.newLine( p.parent, sW-2*p.w, 0, sW-2*p.w, sH )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth

	myLine = display.newLine( p.parent, sW-2*p.w, 0.64*sH, sW, 0.64*sH )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth
	
	myLine = display.newLine( p.parent, sW-2*p.w, 0.85*sH, sW, 0.85*sH )
	myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myLine.strokeWidth = p.strokeWidth
	
	_.relayOpenColored = display.newRect( p.parent, sW-p.w/2, 0.925*sH, 0.5*p.w, 0.5*p.w)
	_.relayOpenColored.fill = {type = "image", filename = "images/relayOpenColored.png"}	
	_.relayOpenColored:addEventListener( "touch", onOpenRelayTouch )
	_.relayOpenGrey = display.newRect( p.parent, sW-p.w/2, 0.925*sH, 0.5*p.w, 0.5*p.w)
	_.relayOpenGrey.fill = {type = "image", filename = "images/relayOpenGrey.png"}	
	_.relayClosedColored = display.newRect( p.parent, sW-3*p.w/2, 0.925*sH, 0.5*p.w, 0.5*p.w)
	_.relayClosedColored.fill = {type = "image", filename = "images/relayClosedColored.png"}	
	_.relayClosedColored:addEventListener( "touch", onCloseRelayTouch )
	_.relayClosedGrey = display.newRect( p.parent, sW-3*p.w/2, 0.925*sH, 0.5*p.w, 0.5*p.w)
	_.relayClosedGrey.fill = {type = "image", filename = "images/relayClosedGrey.png"}	
	
	--[[  Emergency stop button replaced with relay open/closed indicators
	--_.eStopImage = display.newRect( p.parent, sW-p.w/2, 0.9*sH, 0.185*sH, 0.185*sH)
	_.eStopImage = display.newRect( p.parent, sW-p.w/2, 0.925*sH, 0.5*p.w, 0.5*p.w)
	_.eStopImage.fill = {type = "image", filename = "images/stop.png"}	
	_.eStopImage.id = "eStop"
	_.eStopImage:addEventListener( "touch", onEmergencyStopTouch )
	local options = {
		text = "EMERGENCY\nSTOP",
		x = sW-1.4*p.w,
		y = 0.925*sH,
		width = p.w,
		height = 0,
		font = p.font,
		fontSize = p.fontSize,
		align = "center",
		parent = p.parent,
	}

	local eStopText = display.newText( options )
	eStopText:setFillColor( unpack( p.fontColor ))
	--]]
	_.sceneName = composer.getSceneName( "current" )
	local ids
	--The entries below have the format {"Field Name", "", bool}
	--If the second entry has a space, create a text box to display the value
	--If the third entry is true, create the plus/minus boxes
	if _.sceneName == "scene_train" then
		ids = {
			{"Auto", " ", false},				
			{"Type", " ", false}, 			
			{"Uniform #", " ", false},
			{"Quantity", " ", true},			
			{"Delay", " ", true}, 
			{"Duration", " ", true},
			{"Period", " ", true}, 
			{"Hold/Off", " ", false}, 
			{"H/O Level", " ", true},
			{"Frequency", " ", false}, 
			{"Freq. Step"," ", false},
			{"Time Step", " ", false}, 
			{"Amp. Step", " ", false},
		}
	elseif _.sceneName == "scene_event" then
		ids = {
			{"Type", " ", false},
			{"Quantity", " ", true}, 
			{"Delay", " ", true}, 
			{"Period", " ", true}, 
			{"Dur 1", " ", true},
			{"Amp 1", " ", true},
			{"Intr", " ", true}, 
			{"Dur 2", " ", true}, 
			{"Amp 2", " ", true},
			{"Frequency", " ", false}, 
			{"Freq. Step"," ", false},
			{"Time Step", " ", false}, 
			{"Amp. Step", " ", false},
		}	
	elseif _.sceneName == "scene_home" then
		ids = {			
			{"Name", " ", false},
			{"Protocol", " ", false}, 
			--{"Address", " ", false},
			{"Per/Freq", " ", false},
			{"Mode", " ", false},
			{"Sync 1", " ", false}, 
			{"Sync 2", " ", false},
			{"Trigger", " ", false}, 
			{"Monitor", " ", false}, 
			{"Output", " ", false},			
			{"", "", false},										
			{"Freq. Step"," ", false},
			{"Time Step", " ", false}, 
			{"Amp. Step", " ", false},										
		}	
	elseif _.sceneName == "scene_help" then
		ids = {
			{"App. Rev.", " ", false},
			{"Firmware", " ", false}, 
			{"Serial #", " ", false},
			{"Local Pin", " ", false},
			{"Address", " ", false}, 
			{"Comms", " ", false}, 
			{"", "", false}, 
			{"", "", false}, 
			{"", "", false},			
			{"", "", false},
			{"Freq. Step"," ", false},
			{"Time Step", " ", false}, 
			{"Amp. Step", " ", false},
		}
	else
		ids = {
			{"AMS 4100", "", false}, 
			{"", "", false},
			{"", "", false}, 
			{"", "", false}, 
			{"", "", false}, 
			{"", "", false}, 
			{"", "", false},
			{"", "", false},
			{"", "", false},
			{"", "", false},
		}
	end

	local rows, cols = #ids, 1
	local labels = {}

	for m = 1, rows do
		if ids[m][1] ~= "" then
			local panX = p.midX - 0.7*p.w 		
			local panY = 1.125*p.midY - (rows/2-m+0.5)*p.bannerHeight/12
			local options = {
				text = ids[m][1] .. ": ",
				x = panX,
				y = panY,
				width = p.w,
				height = p.h,
				font = p.font,
				fontSize = p.fontSize,
				align = "right",
				parent = p.parent,
			}
			labels[m] = display.newText(options)
			labels[m]:setFillColor( unpack( p.fontColor ))			
		end
	end
	
	
	p.w = 1.15*p.w
	for m = 1, rows do
		if ids[m][2] ~= "" then
			local panX = p.midX + 0.35*p.w 		
			local panY = 1.125*p.midY - (rows/2-m+0.5)*p.bannerHeight/12

			local options = {
				text = "default",
				x = panX,
				y = panY,
				width = p.w,
				height = p.h,
				font = p.font,
				fontSize = 0.9*p.fontSize,
				align = "right",
				parent = p.parent,
			}
			if ids[m][2] == " " then
				--Decrease the width to allow room for the plus/minus button
				if ids[m][3] then
					options.width = p.w - 2.2*p.h
					--_.bannerText[myRect.id].width = myRect.width					
				end
				
				local myRect = display.newRoundedRect( p.parent, panX, panY, options.width, p.h, 0.025*p.w )
				myRect.strokeWidth = 2
				myRect:setStrokeColor( unpack( p.fontColor ))
				--Adjust the height up slightly so the text is centered better
				myRect.anchorY = 0.55  
				myRect.id = ids[m][1]
				myRect:addEventListener( "touch", onBannerRectTouch )

				options.align = "center"
				options.width = myRect.width
				options.width = nil
				options.height = nil
				_.bannerText[myRect.id] = display.newText(options)
				_.bannerText[myRect.id]:setFillColor( unpack( p.fontColor ))
				_.bannerText[myRect.id].fontSize = p.fontSize
				_.bannerText[myRect.id].originalSize = _.bannerText[myRect.id].size
				
				options.width = myRect.width
				options.height = myRect.height
				local myMask = display.newRoundedRect( p.parent, panX, panY, options.width, p.h, 0.025*p.w )
				myMask.strokeWidth = 2
				myMask:setStrokeColor( unpack( p.fontColor ))
				--Adjust the height up slightly so the text is centered better
				myMask.anchorY = 0.55  
				myMask.alpha = 0
				myMask:addEventListener( "touch", onMaskRectTouch )

				_.bannerText[myRect.id].label = labels[m]
				_.bannerText[myRect.id].rect = myRect
				_.bannerText[myRect.id].mask = myMask				
				--Create the plus/minus buttons 
				if ids[m][3] then
					--myRect.width = myRect.width - 2.2*p.h
					--_.bannerText[myRect.id].width = myRect.width
					local myRectPlus = display.newRoundedRect( p.parent, panX+2*p.h, panY, p.h, p.h, 0.025*p.w )
					myRectPlus.strokeWidth = 2
					myRectPlus:setStrokeColor( unpack( p.fontColor ))
					--Adjust the height up slightly so the text is centered better
					myRectPlus.anchorY = 0.55  
					myRectPlus.id = ids[m][1]
					myRectPlus.sign = 1
					myRectPlus:addEventListener( "touch", onPlusMinusButtonTouch )						
					local myRectMinus = display.newRoundedRect( p.parent, panX-2*p.h, panY, p.h, p.h, 0.025*p.w )
					myRectMinus.strokeWidth = 2
					myRectMinus:setStrokeColor( unpack( p.fontColor ))
					--Adjust the height up slightly so the text is centered better
					myRectMinus.anchorY = 0.55  
					myRectMinus.id = ids[m][1]
					myRectMinus.sign = -1
					myRectMinus:addEventListener( "touch", onPlusMinusButtonTouch )	
					options.align = "center"
					options.width = p.h
					options.fontSize = 1.5*options.fontSize
					options.x = panX+2*p.h
					options.y = panY-0.2*p.h
					options.text = "+"
					local newTextPlus = display.newText(options)
					newTextPlus:setFillColor( unpack( p.fontColor ))
					options.x = panX-2*p.h
					options.text = "-"
					local newTextMinus = display.newText(options)
					newTextMinus:setFillColor( unpack( p.fontColor ))
				end

			elseif ids[m][n] == "AMS 4100" then
				options.text = "AMS 4100"
				options.align = "center"
				local myText = display.newText(options)
				myText:setFillColor( unpack( p.fontColor ))

			end
		end	
	end
	if composer.getSceneName( "current" ) == "scene_train" or 
		composer.getSceneName( "current" ) == "scene_event" then
		---[[
		_.bannerText["Frequency"].rect.width = _.bannerText["Period"].rect.width 
		_.bannerText["Frequency"].y = _.bannerText["Period"].y 
		_.bannerText["Frequency"].label.y = _.bannerText["Period"].label.y 
		_.bannerText["Frequency"].rect.y = _.bannerText["Period"].rect.y 
		_.bannerText["Frequency"].mask.y = _.bannerText["Period"].mask.y 
		--]]
		if ams.Config.PeriodOrFreq == "period" then
			_.bannerText["Frequency"].alpha = 0
			_.bannerText["Frequency"].label.alpha = 0
			_.bannerText["Frequency"].rect.alpha = 0
			_.bannerText["Frequency"].mask.alpha = 0
		else
			_.bannerText["Period"].alpha = 0
			_.bannerText["Period"].label.alpha = 0
			_.bannerText["Period"].rect.alpha = 0
			_.bannerText["Period"].mask.alpha = 0			
		end
	end	
	_.updateBanner()
end

return _