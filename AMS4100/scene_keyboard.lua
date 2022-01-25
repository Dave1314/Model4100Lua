

------------------------------------------------------------------------------
-- In "pause.lua"
------------------------------------------------------------------------------
local composer = require( "composer" )

local scene = composer.newScene()
local sceneGroup

local kb = require( "keyboard" )
local ls = require( "loadsave" )
local md = require( "myData" )
local mf = require( "myFunctions"  )

local ams = md.instrumentSettings.current

local myText, keyboardType, myNativeText, myKeyboard
local params, newValue, oldValue

local keyboardTypes = {
	Address = "native",
	["Amp 1"] = "amplitude",
	["Amp 2"] = "amplitude",
	["Amp. Step"] = "amplitude",
	Delay  = "time",
	["Dur 1"] = "time",
	["Dur 2"] = "time",
	Duration = "time",
	Frequency = "frequency",
	["Freq. Step"] = "frequency",
	["H/O Level"] = "amplitude",
	ID = "native",
	Intr = "time",
	["Local Pin"] = "unitless",
	Name = "native",
	Period = "time",
	["Post Delay"] = "time",
	["Pre Delay"] = "time",
	Protocol = "native",
	Quantity = "unitless",
	["Time Step"] = "time",
	["Uniform #"] = "unitless",
}

local function exitOverlay()
	-- reset touch focus
	display.getCurrentStage():setFocus( nil )
	mf.dprint( "Keyboard Overlay exited." )
	composer.hideOverlay( "fade", 200 )
end

---[[ 'onRelease' event listener for HomeBtn
local function onbkTouch(event)

	local t = event.target
	local p= t.parentGrp

	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true

	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

		elseif event.phase == "ended" or event.phase == "cancelled" then
			t.isFocus = nil
			exitOverlay()

		end
	end

	return true	-- indicates successful touch
end

local function updateStats()
	--Make sure it doesn't blow up with a nil value

	if newValue == "" or newValue == "-" then
		newValue = "0"
	end
	if params.id == "Freq. Step" then
		md.settings.freqSteps = 1/newValue/1e-6
	elseif params.id == "Time Step" then
		md.settings.timeSteps = newValue
	elseif params.id == "Amp. Step" then
		md.settings.ampSteps = newValue
	end
	if composer.getSceneName( "current" ) == "scene_event" then
		local e = params.e
		if params.id == "Dur 1" then
			e.Dur1 = tonumber(newValue)
		elseif params.id == "Dur 2" then
			if e.Type == "biphasic" then
				e.Dur1 = tonumber(newValue)
			else
				e.Dur2 = tonumber(newValue)
			end
		elseif params.id == "Amp 1" then
			e.Amp1 = tonumber(newValue)
		elseif params.id == "Amp 2" then
			if e.Type == "biphasic" then
				e.Amp1 = -tonumber(newValue)
			else
				e.Amp2 = tonumber(newValue)
			end
		elseif params.id == "Intr" then
			e.Intr = tonumber(newValue)
		elseif params.id == "Period" then
			local newPeriod = tonumber(newValue)
			--e.Period = math.max(newPeriod, md.settings.timeSteps)
			e.Period = newPeriod			
		elseif params.id == "Frequency" then
			mf.dprint("Frequency: " .. newValue)
			local newFrequency = tonumber(newValue)
			--e.Period = 1/math.max(newFrequency, md.settings.freqSteps)*1000000 
			e.Period = 1/newFrequency*1000000
		elseif params.id == "Delay" then
			e.Delay = tonumber(newValue)
		elseif params.id == "Quantity" then
			e.Quantity = tonumber(newValue)
		elseif params.id == "Time Step" then
			md.settings.timeSteps = newValue
			if md.settings.timeSteps < 1 then
				md.settings.timeSteps = 1
			end
		end
		md.state.updatePulse = true
	elseif composer.getSceneName( "current" ) == "scene_train" then
		if params.id == "Duration" then
			ams.Train.Dur = tonumber(newValue)
			--ams.Train.options.Stored.Dur = tonumber(newValue)
		elseif params.id == "Period" then
			ams.Train.Period = tonumber(newValue)
			--ams.Train.options.Stored.Period = tonumber(newValue)
		elseif params.id == "Frequency" then
			newValue = 1/tonumber(newValue)*1000000 
			mf.dprint("Period: " .. newValue)
			ams.Train.Period = newValue			
			--newValue = math.round( newValue )
			ams.Train.Period = newValue
		elseif params.id == "Delay" then
			ams.Train.Delay = tonumber(newValue)
		elseif params.id == "Pre Delay" then
			ams.Train.PreDelay = tonumber(newValue)
		elseif params.id == "Post Delay" then
			ams.Train.PostDelay = tonumber(newValue)
		elseif params.id == "Quantity" then
			ams.Train.Quantity = tonumber(newValue)
			--ams.Train.options.Stored.Quantity = tonumber(newValue)
		elseif params.id == "H/O Level" then
			ams.Train.Level = tonumber(newValue)
		elseif params.id == "Uniform #" then
			if newValue < 1 then newValue = 1 end
			if newValue > 20 then newValue = 20 end
			ams.EventList.Uniform = tonumber(newValue)
		end
--		md.state.updateTrain = true
	elseif composer.getSceneName( "current" ) == "scene_home" then
--		if params.id == "Time Step" then
--			md.settings.timeSteps = newValue
--		elseif params.id == "Amp. Step" then
--			md.settings.ampSteps = newValue
--		end
	elseif composer.getSceneName( "current" ) == "scene_loadSave" then
		if params.id == "ID" then
			ams.Description = newValue
		elseif params.id == "Protocol" then
			ams.Description = newValue
		elseif params.id == "Name" then
			ams.InstrumentName = newValue
		end
	elseif composer.getSceneName( "current" ) == "scene_help" then
		if params.id == "Local Pin" then
			newValue = tonumber( newValue )
			if newValue then
				if newValue >= 0 and newValue <= 99999 then
					ams.localPinNumber = newValue
				end
			end
		end
	end
end

local function processInput( id )
	--Event handler code goes here
	if id == "←" or id == "Back" then
		myText.value = string.sub(myText.value, 1, -2)

	elseif id == "OK" then
		local multiplier
		if string.find( myText.units, "µs", 1, true) then
			multiplier = 1
		elseif string.find( myText.units, "ms", 1, true) then
			multiplier = 1000
		elseif string.find( myText.units, "kHz", 1, true) then
			multiplier = 1000
		elseif string.find( myText.units, "mHz", 1, true) then
			multiplier = 0.001	
		elseif string.find( myText.units, "Hz", 1, true) then
			multiplier = 1
		elseif string.find( myText.units, "�V", 1, true) then
			multiplier = 1
		elseif string.find( myText.units, "mV", 1, true) then
			multiplier = 1000
		elseif string.find( myText.units, "�A", 1, true) then
			multiplier = 1
		elseif string.find( myText.units, "mA", 1, true) then
			multiplier = 1000
		elseif keyboardType == "unitless" then
			multiplier = 1
		else
			multiplier = 1000000
		end
		mf.dprint("myText.units: " .. myText.units)
		mf.dprint("newValue: " .. newValue)
		mf.dprint("multiplier: " .. multiplier)
		newValue = tonumber( myText.value ) * multiplier
		mf.dprint("new newValue: " .. newValue)
		updateStats()
		exitOverlay()
	elseif id == "Cancel" then
		exitOverlay()
	elseif id == "Clear" then
		myText.value = "0"
	elseif id == "±" then
		if keyboardType == "voltage" or keyboardType == "current" then
			if string.find( myText.value, "-" ) then
				myText.value = string.sub(myText.value, 2 )
			else
				myText.value = "-" .. myText.value
			end					end
		elseif id == "µs"  then
			myText.units = " µs"
		elseif id == "µV"  then
			myText.units = " µV"
		elseif id == "µA" then
			myText.units = " µA"
		elseif id == "ms"  then
			myText.units = " ms"
		elseif id == "mV"  then
			myText.units = " mV"
		elseif id == "mA" then
			myText.units = " mA"
		elseif id == "s"  then
			myText.units = " s"
		elseif id == "V" then
			myText.units = " V"
		elseif id == "A" then
			myText.units = " A"
		elseif id == "mHz" then
			myText.units = " mHz"
		elseif id == "Hz" then
			myText.units = " Hz"
		elseif id == "kHz" then
			myText.units = " kHz"
		else
			if string.len( myText.value ) < 7 then
				if id == "." then
					--Make sure only one decimal point exists
					if keyboardType ~= "quantity" then
						if not string.find( myText.value, ".", 1, true ) then
							myText.value = myText.value .. "."
						end
					end
				else
					myText.value = myText.value .. id
				end
			end
		end

		if myText.value == "" then
			myText.value = "0"
		elseif myText.value == "-" then
			myText.value = "-0"
		elseif myText.value == "0" or myText.value == "-0" then
			--Do nothing
		elseif string.sub( myText.value, 1, 2 ) == "0." then
			--Do nothing
		elseif string.sub( myText.value, 1, 3 ) == "-0." then
			--Do nothing
		elseif string.sub( myText.value, 1, 1 ) == "0" then
			myText.value = string.sub( myText.value, 2 )
		elseif string.sub( myText.value, 1, 2 ) == "-0" then
			myText.value = "-" .. string.sub( myText.value, 3 )
		end

		myText.text = myText.value .. myText.units

	end


---[[ 'onRelease' event listener for navigation buttons
	local function onKeyboardTouch(event)

		local t = event.target
		local p= t.parentGrp

		if event.phase == "began" then
			-- set touch focus
			display.getCurrentStage():setFocus( t )
			t.isFocus = true
			--t.fill.effect.ambientLightIntensity = 0.1

		elseif t.isFocus then
			if event.phase == "moved" then
				local dx = math.abs(t.x - event.x)
				local dy = math.abs(t.y - event.y)

				--Disable highlights if their finger moves off the button
				if dx > t.width/2 or dy > t.height/2 then
					display.getCurrentStage():setFocus( nil )
					t.isFocus = nil
					--t.fill.effect.ambientLightIntensity = 0
				end

			elseif event.phase == "ended" or event.phase == "cancelled" then

				local currentScene = composer.getSceneName("current")
				mf.dprint( event )
				mf.dprint( currentScene )

				-- reset touch focus
				display.getCurrentStage():setFocus( nil )
				t.isFocus = nil
				--t.fill.effect.ambientLightIntensity = 0

				processInput( t.id )
			end
		end

		return true	-- indicates successful touch
	end

	local function onKeyEvent( event )

		local phase = event.phase
		local keyName = event.keyName
		--print( currScene, event.phase, event.keyName )
		local keyNames = {
			["0"] = "0",
			["1"] = "1",
			["2"] = "2",
			["3"] = "3",
			["4"] = "4",
			["5"] = "5",
			["6"] = "6",
			["7"] = "7",
			["8"] = "8",
			["9"] = "9",
			numPad0 = "0",
			numPad1 = "1",
			numPad2 = "2",
			numPad3 = "3",
			numPad4 = "4",
			numPad5 = "5",
			numPad6 = "6",
			numPad7 = "7",
			numPad8 = "8",
			numPad9 = "9",
			enter = "OK",
			numPadEnter = "OK",
			escape = "Cancel",
			["."] = ".",
			["numPad."] = ".",
			["+"] = "±",
			["-"] = "±",
			["numPad+"] = "±",
			["numPad-"] = "±",
			deleteBack = "Back",
			deleteForward = "Back",
			space = "Clear",
			tab = "Tab",
		}
		if keyboardType == "frequency" then
			keyNames["k"] = "kHz"
			keyNames["h"] = "Hz"
			keyNames["m"] = "mHz"
		elseif keyboardType == "time" then
			keyNames["u"] = "µs"
			keyNames["m"] = "ms"
			keyNames["s"] = "s"
		elseif keyboardType == "voltage" then
			keyNames["u"] = "µV"
			keyNames["m"] = "mV"
			keyNames["v"] = "V"
		elseif keyboardType == "current" then
			keyNames["u"] = "µA"
			keyNames["m"] = "mA"
			keyNames["a"] = "A"
		end

		if phase == "up" and keyNames[keyName] then
			if keyName == "back" then
				--Let the keyEvent Handler in main process the exit request
				return false
			else
				mf.dprint( keyName .. "  " .. keyNames[keyName] )
				processInput( keyNames[keyName] )
				return true
			end
		end
		return false
	end

	local function nativeTextListener( event )

		if ( event.phase == "began" ) then
			-- user begins editing defaultField

		elseif ( event.phase == "ended" or event.phase == "submitted" ) then
			-- do something with defaultField text
			if params.id == "ID" then
				ams.Description = event.target.text
			elseif params.id == "Protocol" then
				ams.Description = event.target.text
			elseif params.id == "Name" then
				ams.InstrumentName = event.target.text
			elseif params.id == "Address" then
				--md.settings.ipaddress = event.target.text
				ams.connection.address = event.target.text
				--Break the connection and attempt to connect to the new address
				ams.connection.connected = false
				ls.saveTable(md.settings, "settings.json", system.DocumentsDirectory)
			end

			exitOverlay()
		elseif ( event.phase == "editing" ) then

			if string.len( event.text ) > 16 then
				--myNativeText.text = event.oldText
				--myNativeText.text = string.sub( event.oldText, 1, 16 )
				myNativeText.text = string.sub( event.text, 1, 16 )
			else
				myText.text = event.text
			end
		end
	end


	function scene:create( event )

		mf.dprint( "scene_game entered." )


		local labels
		local screenW = md.screenW
		local screenH = md.screenH
		local tileW = md.tileW
		local x, y
		local temp
		params = event.params
		--myText = params.textBox
		--mf.dprint( params )
		sceneGroup = self.view

		mf.dprint( "Keyboard Overlay entered." )

		--Create a large, transparent rectangle to catch tap/touch events
		local bk = display.newRect(sceneGroup, screenW/2, screenH/2, screenW, screenH)
		bk.fill = {1, 1, 1, 0}
		bk.isHitTestable = true
		bk:addEventListener( "touch", onbkTouch )

		--Create a smaller one to mask out the background
		local bk2 = display.newRect(sceneGroup, 0.5*screenW, 0.5*screenH, screenW, screenH )
		bk2.fill = {1, 1, 1, 0.5}

		--Overlay a false textBox on top of the real one to highlight it
		local options = {
			text = params.textBox.text,
			x = params.textBox.x,
			y = params.textBox.y,
			width = params.textBox.rect.width,
			height = params.textBox.rect.height,
			font = md.defaultFont,
			fontSize = md.defaultFontSize,
			align = "center",
			parent = sceneGroup,
		}
		local myRect = display.newRoundedRect( sceneGroup, options.x, options.y, options.width, options.height, 0.025*options.width )
		myRect.stroke = {type="image", filename="images/Picture1.png"}
		myRect.strokeWidth = 2
		myRect:setStrokeColor( unpack( md.defaultFontColor ))
		myRect.anchorY = 0.55

		myText = display.newText(options)
		--Start 4 spots from the end of the string so that any leading white space
		--is not included in the units tag
		local inds = string.find( params.textBox.text, " ", -4 )
		if inds then
			myText.value = string.sub( params.textBox.text, 1, inds-1 )
			myText.units = string.sub( params.textBox.text, inds )
		else
			myText.value = params.textBox.text
			myText.units = ""
		end
		myText.value = "0"
		myText.text = myText.value .. myText.units
		myText:setFillColor( unpack( md.defaultFontColor ))

		keyboardType = keyboardTypes[ params.id ]

		--Hide the text field so the native textfield is shown
		if keyboardType == "native" then
			myText.isVisible = false
		end

		if keyboardType == "amplitude" then
			if ams.Config.Mode == "intVolt" then
				keyboardType = "voltage"
			else
				keyboardType = "current"
			end
		end

		local sW, sH = display.contentWidth, display.contentHeight
		local midX = 0.35*sW - sW/40
		local midY = 0.75*sH
		local w = sH/10
		local h = w

		--Set up the keyboard.
		if keyboardType == "native" then
			myNativeText = native.newTextField( options.x, options.y,
				options.width, options.height )
			--myNativeText.isVisible = false
			myNativeText.inputType = "url"
			myNativeText.text = params.value
			myNativeText.font = native.newFont( options.font, options.fontSize )
			myNativeText.hasBackground = true
			myNativeText:setReturnKey( "done" )
			myNativeText:addEventListener( "userInput", nativeTextListener )
			native.setKeyboardFocus( myNativeText )
		else
			local options = {
				parent = sceneGroup,
				type = keyboardType,
				midX = midX,
				midY = midY,
				w = w,
				h = w,
				r = 0.2*w,
				fillColor = { 156/256, 176/256, 179/256 },
				stroke = {type="image", filename="images/Picture1.png"},
				strokeColor = { 156/256, 176/256, 179/256 },
				strokeWidth = 3,
				fontSize = 1.25*md.defaultFontSize,
				fontColor = md.defaultFontColor,
				listener = onKeyboardTouch,
			}
			myKeyboard = kb.new( options )

		end
		newValue = event.params.value
		oldValue = event.params.value
		updateStats()

		mf.dprint( "scene_keyboard created." )

	end

	function scene:show( event )
		local sceneGroup = self.view
		local phase = event.phase

		if ( phase == "will" ) then
			--mf.dprint( event.params )
			--add the key callback
			Runtime:addEventListener( "key", onKeyEvent )
		elseif ( phase == "did" ) then
		end
	end

	function scene:hide( event )
		local sceneGroup = self.view
		local phase = event.phase
		local parent = event.parent  --reference to the parent scene object
		local t = {
			id = params.id
		}

		if ( phase == "will" ) then

			-- Call the "resumeGame()" function in the parent scene
			if keyboardType == "native" then
				myNativeText:removeEventListener( "userInput", nativeTextListener )
				myNativeText:removeSelf()
				myNativeText = nil
			end
			native.setKeyboardFocus( nil )
			Runtime:removeEventListener( "key", onKeyEvent )
			local sceneName = composer.getSceneName( "current" )
			if sceneName == "scene_train" then
				md.state.updateTrain = true
			elseif sceneName == "scene_event" then
				md.state.updatePulse = true
				md.state.updateEvent = true
			elseif sceneName == "scene_configure" then
				md.state.updateConfig = true
			elseif sceneName == "scene_home" then
				md.state.updateHome = true
			end
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