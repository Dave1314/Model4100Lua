-------------------------------------------------
--
-- ams4100-master.lua
--
-- "ams4100-master" class for ams 4100
-- Brings together all lower level classes for config, train,
-- event, and eventList classes
--
-------------------------------------------------

local ams = {}
local ams_mt = { __index = ams}	-- metatable
local bit = require( "plugin.bit" )
local mc = require( "myConnection" )
local mf = require( "myFunctions" )
local ms

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------
local function getKey( t, val )
	-- Find the key associated with a particular value in a table
	for k,v in pairs( t ) do
		if v == tonumber(val) then 
			return k 
		end
	end
	return nil
end

local function warning( message )
	mf.dprint( message )
end

function ams:addMessageToBuffer( params )
	local s = self
	if s.connection.connected then
		--Create a local copy of the message contents
		--There were isolated cases where subsequent calls to this function from the
		--same calling function would alter the values of the first call.
		local p = {
			message = params.message,
			listener = params.listener,
			time = params.time,
			forceSend = params.forceSend}

		if s.Revision ~= "M2,F1" and s.Revision ~= "M3,F2" then
		--if s.Revision ~= "M2,F1" then
			p.forceSend = true
			--params.forceSend = true
		end

		if p.forceSend then
			s.connection.sendBuffer[ #s.connection.sendBuffer + 1 ] = p
		elseif s.localPinNumber == s.PinNumber then			
			p.message = s.localPinNumber .. " " .. p.message
			s.connection.sendBuffer[ #s.connection.sendBuffer + 1 ] = p
		end		

	else
		--warning('No Instrument communication AMS4100 values will change, but the instrument settings are not changed'); 
	end
end

function ams:getInfo( id, field, listener, forceSend )

	local s = self
	local params = {
		message = "g m " .. id .. " " .. field,
		listener = listener,
		time = system.getTimer(),
		forceSend = forceSend,
	}
	s:addMessageToBuffer( params )

end

function ams:setInfo( id, field, value, listener )

	local s = self
	if value then  
		local params = {
			message = "s m " .. id .. " " .. field .. " " .. value,
			listener = listener,
			time = system.getTimer(),
		}
		s:addMessageToBuffer( params )
	else
		mf.dprint( "Nil value detected!" )
	end
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function ams.new( params )	-- constructor

	local p = params or {}

	local path = p.path or "ams4100-M2F1."
	ms = require( path .. "menuStructure" )
	local eventMaster = require( path .. "ams4100-event" )
	local trainMaster = require( path .. "ams4100-train" )
	local configMaster = require( path .. "ams4100-config" )
	local eventListMaster = require( path .. "ams4100-eventList" )

	local newAms= {		
		--Instrument settings
		Active = "",
		Description = "Protocol",
		InstrumentName = "AMS 4100",
		Revision = "M0,F0",
		SerialNumber = "100001",
		LibID = 1,
		UniformEventNumber = 1,
		Event = {},
		PinNumber = 1001,
		--Local settings
		connection = mc.new(),
		condition = {
			Vmon = false,
			Imon = false,
			FPGAgen = false,
			FPGArun = false,
			Enable = false,
			FrontPanelFreeRun = false,
			RelayClosed = false,
			FrontPanelChanged = false,
		},
		localPinNumber = 1001,
		running = false,
		trigger = 'none',
		allowHighVoltage = false,
		address = "127.0.0.1" or p.address,
		port = 23 or p.port,
	}

	--newAms.ms = require( path .. "menuStructure" )
	newAms.connection.parent = newAms
	local options = {
		parent = newAms,
		menuStructure = ms,
		id = 1,
	}

	newAms.Config = configMaster.new( options )
	newAms.Train = trainMaster.new( options )
	newAms.EventList = eventListMaster.new( options )
	for m = 1,20 do
		options.id = m + ms.amsMenu.event - 1
		newAms.Event[m] = eventMaster.new( options )
		newAms.Event[m].Description = m
	end
	
	newAms.time = system.getTimer()
	
	return setmetatable( newAms, ams_mt )
end

---------------------------------------------------------------------

function ams:checkEventParameters( id )

	local s = self

	local e = s.Event[id]

	local totalTime 
	e.err = false

	if e.Type == "monophasic" then
		totalTime = e.Dur1
	elseif e.Type == "biphasic" then
		totalTime = 2*e.Dur1 + e.Intr
	elseif e.Type == "asymm" then
		totalTime = e.Dur1 + e.Intr + e.Dur2
	elseif e.Type == "ramp" then
		totalTime = e.Dur1 + e.Intr + e.Dur2
	end

	if totalTime > e.Period then		
		e.err = true
	end

	return e.err	

end
---------------------------------------------------------------------
function ams:checkTrainParameters()

	local s = self

	s.Train.perError = false
	s.Train.durError = false

	local totalTime = 0
	--Check the status of the uniform event to make 
	--sure it doesn't exceed the train parameters.

	if s.Train.Type == "uniform" then
		local id = tonumber( s.EventList.Uniform )
		local e = s.Event[id]
		totalTime = e.Delay + e.Period * e.Quantity
	else
		if s.Config.Auto == "fill" then
			local id = tonumber( s.EventList.Mixed[1] )

			--totalTime = s.Event[id].Delay
			for m = 1, 20 do
				id = tonumber( s.EventList.Mixed[m] )
				if id then --Make sure the number exists
					if id > 0 then
						local e = s.Event[ id ]
						totalTime = totalTime + e.Period * e.Quantity
					end		
				end
			end			
		else
			for m = 1, 20 do
				local id = tonumber( s.EventList.Mixed[m] )
				if id then --Make sure the number exists
					if id > 0 then
						local e = s.Event[ id ]
						totalTime = totalTime + e.Delay + e.Period * e.Quantity
					end		
				end
			end
		end
	end
	local dur = tonumber( s.Train.Dur )
	local per = tonumber( s.Train.Period )
	if  dur > per then
		s.Train.perError = true
	end
	if totalTime > dur then
		s.Train.durError = true
	end
	if totalTime > per then
		s.Train.perError = true
	end

	return s.Train.perError or s.Train.durError

end
---------------------------------------------------------------------
function ams:getMenuVals()

	--Get the menu values from a connected instrument and store
	--them in the calling table
	local s = self
	--s.get.LibID()
	s:getRevision()
	s:getSerialNumber()
	s.Config:getMenuVals()
	s.Train:getMenuVals()
	s.EventList:get()
	--Scan across all the events and read out their data.  
	for m = 1, 20 do
		s.Event[m]:getMenuVals()
	end			

end

function ams:setMenuVals( newVals )

	local s = self
	newVals = newVals or { Config = {}, Train = {}, EventList = {}, Event = {} }
	for m = 1, 20 do
		newVals.Event[m] = newVals.Event[m] or s.Event[m]
		newVals.EventList[m] = newVals.EventList[m] or s.EventList[m]
	end

	--s.set.LibID()
	s.InstrumentName = newVals.InstrumentName or s.InstrumentName
	s.Description = newVals.Description or s.Description
	s.Config:setMenuVals( newVals.Config or s.Config )
	s.Train:setMenuVals( newVals.Train or s.Train )
	s.EventList:set( newVals.EventList or s.EventList )
	--Scan across all the events and set their data.  
	for m = 1, 20 do
		s.Event[m]:setMenuVals( newVals.Event[m] or s.Event[m] )
	end		

end

---------------------------------------------------------------------
function ams:getActive()

	local s = self

	-- The Active property gets the output status
	local function listener( value )
		if value then
			s.Active = value
			if value == "Generating dangerous pulses" or 
			value == "Generating pulses" then
				s.running = true
			else
				s.running = false
			end			
		else
			if not s.connection.commsInProgress then
				s.Active = "No instrument connection."
				s.running = false
			end
		end		
	end
	--Make sure the get status command is not already in the queue..
	local sendGetActive = true
	if  #s.connection.sendBuffer > 0 then		
		for m = 1, #s.connection.sendBuffer do
			if s.connection.sendBuffer[m].message == 'g a' then
				sendGetActive = false
				break
			end
		end
	end
	if sendGetActive then
		local params = {
			message = 'g a',
			listener = listener,
			time = system.getTimer(),
			forceSend = true,
		}
		s:addMessageToBuffer( params )
	end				
end

---------------------------------------------------------------------
function ams:getCondition()

	local s = self

	-- The Active property gets the output status
	local function listener( value )
		---[[
		local function toBits(num, bits)
			-- returns a table of bits
			local t={} -- will contain the bits
			local rest
			for b=bits,1,-1 do
				rest=math.fmod(num,2)
				t[b]=rest
				num=(num-rest)/2
			end
			if num==0 then 
				return t 
			else 
				return {'Not enough bits to represent this number'}
			end
		end --]]

		if value then
			local val1 = string.byte( value, 1 )
			local val2 = string.byte( value, 2 )
			s.condition.val1Bit7 = 				bit.band( val1, 0x80 ) ~= 0
			s.condition.val1Bit6 = 				bit.band( val1, 0x40 ) ~= 0
			s.condition.val1Bit5 = 				bit.band( val1, 0x20 ) ~= 0
			s.condition.Vmon = 					bit.band( val1, 0x10 ) ~= 0
			s.condition.Imon = 					bit.band( val1, 0x08 ) ~= 0
			s.condition.FPGAgen = 				bit.band( val1, 0x04 ) ~= 0
			s.condition.FPGArun = 				bit.band( val1, 0x02 ) ~= 0
			s.condition.Enable = 				bit.band( val1, 0x01 ) ~= 0

			s.condition.val2Bit7 = 				bit.band( val2, 0x80 ) ~= 0
			s.condition.val2Bit6 = 				bit.band( val2, 0x40 ) ~= 0
			s.condition.val2Bit5 = 				bit.band( val2, 0x20 ) ~= 0
			s.condition.val2Bit4 = 				bit.band( val2, 0x10 ) ~= 0
			s.condition.val2Bit3 = 				bit.band( val2, 0x08 ) ~= 0
			s.condition.FrontPanelFreeRun = 	bit.band( val2, 0x04 ) ~= 0
			s.condition.RelayClosed = 			bit.band( val2, 0x02 ) ~= 0
			s.condition.FrontPanelChanged = 	bit.band( val2, 0x01 ) ~= 0

			---[[
			if s.Revision == "M3,F2" then
				--s.condition.RelayClosed = 			bit.band( val2, 0x08 ) ~= 0
				--s.condition.ProgramRunning = 		bit.band( val2, 0x02 ) ~= 0
			end
			--]]
			mf.dprint(table.concat(toBits(val1,8)));
			mf.dprint(table.concat(toBits(val2,8)));
		end		
	end
	--Make sure the get condtion command is not already in the queue...
	if  #s.connection.sendBuffer > 0 then
		if s.connection.sendBuffer[ #s.connection.sendBuffer ].message ~= 'g c' then
			local params = {
				message = 'g c',
				listener = listener,
				time = system.getTimer(),
				forceSend = true,
			}
			s:addMessageToBuffer( params )

		end
	else
		local params = {
			message = 'g c',
			listener = listener,
			time = system.getTimer(),
			forceSend = true,
		}
		s:addMessageToBuffer( params )
	end

end

---------------------------------------------------------------------
function ams:getStatus()

	--If the serial number is blank that indicates this is the first time
	--to connect to this instrument.  If the connection is broken blank out
	--the serial number until the next connection is made.
	local s = self
	if s.connection.connected then
		if s.SerialNumber == "" then
			s:getSerialNumber()
		end
		--Revision has to be greater than M0, F0
		if s.Revision == "M0,F0" then
			s:getRevision()
		end				
		--If there are more than 5 commands in the buffer already skip this
		--status update and wait until the buffer has cleared out.
		if #s.connection.sendBuffer < 5 then
			s:getActive()
			s:getCondition()		
			if s.Revision == "M2,F1" or s.Revision == "M3,F2" then
				s:getPinNumber()		
			end
		end

	else
		s.Revision = "AMS 4100"
		s.SerialNumber = ""
	end	

end

---------------------------------------------------------------------
function ams:setDisplay( value )

	local params = {
		message = 's d ' .. ms.amsMenu[value],			
		--listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )		
end

---------------------------------------------------------------------
function ams:startComms( params )

	local s = self
	params = params or {}

	local p = {
		address = params.address or s.connection.address,
		port = params.port or s.connection.port,
	}
	s.connection:sendReceive( p )	
	s.getStatusTimer = timer.performWithDelay( 1000, function() s:getStatus() end, 0 )	

end


---------------------------------------------------------------------
function ams:getRevision()

	local s = self

	-- The Active property gets the output status
	local function listener( value )
		if value then
			s.Revision = value
		else
			s.Revision = "AMS 4100"
		end		
	end
	local params = {
		message = 'g r',
		listener = listener,
		time = system.getTimer(),
		forceSend = true,
	}
	s:addMessageToBuffer( params )		
end
---------------------------------------------------------------------
function ams:getPinNumber()

	local s = self

	-- The Active property gets the output status
	local function listener( value )
		if value then
			s.PinNumber = value
		else
			s.PinNumber = "1001"
		end		
	end
	local forceSend = true
	s:getInfo(ms.amsMenu.network, ms.network.pinNumber, listener, forceSend)

end

---------------------------------------------------------------------
function ams:getSerialNumber()

	local s = self

	-- The Active property gets the output status
	local function listener( value )
		if value then
			s.SerialNumber = value
		else
			s.SerialNumber = ""
		end		
	end
	local forceSend = true
	s:getInfo(ms.amsMenu.config, ms.config.serialNumber, listener, forceSend)	
end

---------------------------------------------------------------------

function ams:getSettings()
	--Return all the settings for this particular instance wihtout
	--the additional overhead of menu structures, message buffers, etc.
	local s = self
	local settings = {
		InstrumentName = s.InstrumentName,
		Description = s.Description,
		Revision = s.Revision,
		SerialNumber = s.SerialNumber,
		LibID = s.LibID,
		UniformEventNumber = s.UniformEventNumber,
		PinNumber = s.PinNumber,
		Config = {
			Revision = s.Config.Revions,
			Mode = s.Config.Mode,
			Output = s.Config.Output,
			Trigger = s.Config.Trigger,
			Auto = s.Config.Auto,
			Monitor = s.Config.Monitor,
			Sync1 = s.Config.Sync1,
			Sync2 = s.Config.Sync2,
			PeriodOrFreq = s.Config.PeriodOrFreq,
			DurOrCount = s.Config.DurOrCount,
		},
		Train = {
			Type = s.Train.Type,
			Delay = s.Train.Delay,
			Dur = s.Train.Dur,
			Period = s.Train.Period,
			Quantity = s.Train.Quantity,
			OffsetOrHold = s.Train.OffsetOrHold,
			Level = s.Train.Level,
		},
		Event = {},
		EventList = {
			Uniform = s.EventList.Uniform,
			Mixed = s.EventList.Mixed,
		},
		connection = {
			address = s.connection.address,
			port = s.connection.port,
		},
	}
	for m = 1, 20 do
		settings.Event[m] = {
			Amp1 = s.Event[m].Amp1,
			Amp2 = s.Event[m].Amp2,
			Delay = s.Event[m].Delay,
			Dur1 = s.Event[m].Dur1,
			Dur2 = s.Event[m].Dur2,
			Intr = s.Event[m].Intr,
			Frequency = s.Event[m].Frequency,
			Period = s.Event[m].Period,
			Quantity = s.Event[m].Quantity,
			Type = s.Event[m].Type,
		}
	end	

	return settings

end

---------------------------------------------------------------------

function ams:getTotalEventDuration()

	local s = self

	--Calculate the total period for all events in the list
	local delay = 0
	local period = 0		
	if s.Train.Type == "uniform" then
		local id = tonumber( s.EventList.Uniform )
		local e = s.Event[id]					
		period = e.Delay + e.Quantity * e.Period
		delay = e.Delay
	else
		for m = 1, 20 do
			local id = tonumber( s.EventList.Mixed[m] )
			local e = s.Event[id]
			if id > 0 then			
				--Only add the first event's delay in count and fill mode.
				if s.Config.Auto == "none" then
					period = period + e.Delay
				elseif m == 1 then
					period = period + e.Delay
					delay = e.Delay
				end				
				period = period + e.Quantity*e.Period
			end
		end
	end	
	return period, delay
end

---------------------------------------------------------------------

-- Action Methods   
function ams:Run()

	--Run - Start the output
	--
	--   Run will put the instrument in free run
	--
	--   SYNOPSIS: obj.Run()
	--
	--   EXAMPLE:    handle.Run;
	--

	local s = self

	local dangerousOutput = false
	local offset = 0

	local function sendAuthorization()							
		--If user authorized dangerousOutput, send the 'OK' 
		if s.allowHighVoltage then
			local params = {
				message = 'ok',
				--listener = listener,
				time = system.getTimer(),
			}
			s:addMessageToBuffer( params )						
		end					
	end

	-- Handler that gets notified when the alert closes
	local function onComplete( event )
		if ( event.action == "clicked" ) then
			local i = event.index
			if ( i == 1 ) then
				-- Do nothing; dialog will simply dismiss
			elseif ( i == 2 ) then							
				s.allowHighVoltage = true
				sendAuthorization()					
			end
			timer.resume( s.getStatusTimer )
		end
	end	


	local function listener( value )
		if value == "or anything else to cancel" then 
			mf.dprint( value )
			if s.allowHighVoltage then
				--Go ahead and send the authorization if they've 
				--previously allowed high voltages
				sendAuthorization()
				timer.resume( s.getStatusTimer )
			else
				--Show the pop up asking for authorization
				native.showAlert( "AMS 4100", "DANGEROUS OUTPUT\nPress OK to generate output.", 
					{"Cancel", "OK"}, onComplete )
			end		
		else 
			-- No sprecial processing was necessary, resume the status timer
			timer.resume( s.getStatusTimer )
		end			
		mf.dprint( "Output intiated." )
		s.running = true					
	end			

	--Send the run command.  If dangerous output is requested it's
	--trapped in the listener
	local params = {
		message = 's a r',
		listener = listener,
		time = system.getTimer(),
	}
	--Pause the get status timer until a response to the run command is received.
	if s.getStatusTimer then
		timer.pause( s.getStatusTimer )
	end		
	s:addMessageToBuffer( params )
end

function ams:Stop()
	--Stop - Stops the output
	--
	--   Stop will end free run
	--
	--   SYNOPSIS: obj.Stop()
	--
	--   EXAMPLE:    handle.Stop;
	--
	local s = self
	--Bump up the timeout to allow the isntrument time to respond
	local function listener( value )
		mf.dprint( "Output halted." )
		s.running = false
	end
	local params = {
		message = 's a s',
		listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )				
end


---------------------------------------------------------------------
function ams:OpenRelay()
	--OpenRelay - Opens the relay on the output of the 4100
	local s = self
	local function listener( value )
		mf.dprint( "Output relay closed." )			
	end
	local params = {
		message = 's r o',
		listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )				
	if s.revision == "M3,F2" then
		local function listener( value )
			mf.dprint( "Enable LED turned off." )			
		end
		local params = {
			message = 's m 0 5 0',
			listener = listener,
			time = system.getTimer()
		}
		s:addMessageToBuffer( params )
	end
end

function ams:CloseRelay()
	--CloseRelay - Closes the relay on the output of the 4100
	local s = self
	local function listener( value )
		mf.dprint( "Output relay closed." )			
	end
	local params = {
		message = 's r c',
		listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )	
	if s.revision == "M3,F2" then
		local function listener( value )
			mf.dprint( "Enable LED turned on." )			
		end		
		local params = {
			message = 's m 0 5 1',
			listener = listener,
			time = system.getTimer()
		}
		s:addMessageToBuffer( params )
	end	
end

---------------------------------------------------------------------
function ams:TriggerStop()
	local s = self
	--Set the 4100 to ignore all triggers and stop output
	local function listener( value )
		mf.dprint( "Trigger stop." )			
		s.trigger = "stop"
	end

	local params = {
		message = 's t n',
		listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )						
	s.trigger = "stop"
end

function ams:TriggerNone()
	local s = self
	--Set the 4100 to external/manual trigger
	local function listener( value )
		mf.dprint( "Trigger none." )			
		s.trigger = "none"
	end		
	local params = {
		message = 's t n',
		listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )
	s.trigger = "none"
end

function ams:TriggerOnce()
	local s = self
	--Set the 4100 to trigger once and return to external/manual trigger
	local function listener( value )
		mf.dprint( "Trigger once." )	
		--System defaults back to manual/external trigger after
		--a single trigger command
		s.trigger = "none"
	end

	local params = {
		message = 's t o',
		listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )				
	s.trigger = "once"	
end

function ams:TriggerFreeRun()
	--Set the 4100 to trigger continuously
	local s = self
	local function listener( value )
		mf.dprint( "Trigger running freely.")
		s.trigger = "freeRun"
	end

	local params = {
		message = 's t f',
		listener = listener,
		time = system.getTimer(),
	}
	s:addMessageToBuffer( params )		
	s.trigger = "freeRun"
end
---------------------------------------------------------------------

local function appendTable( t1, t2, offset )
	offset = offset or 0
	local index = #t1
	for m = 1, #t2 do
		t1[index+m] = t2[m] + offset
	end	
	return t1
end

local function appendCoords( c1, c2, offset )
	offset = offset or 0
	appendTable( c1.x, c2.x, offset )
	appendTable( c1.y, c2.y )
end

--Get the coordinates for all the events in a single train
function ams:getEventCoords()
	local s = self
	local eventCoords = {x = {}, y = {}}
	local firstEventDelay = 0
	local newCoords = {x = {}, y = {}}
	local offset, hold = 0, 0
	local xOffset

	if s.Train.OffsetOrHold == "hold" then
		hold = s.Train.Level
	else
		offset = s.Train.Level
	end

	--Determine what events are actually in the train and store that for later
	local eventList = {}
	if s.Train.Type == "uniform" then
		eventList[1] = tonumber( s.EventList.Uniform )
	else
		for m = 1, 20 do
			--s.EventList.Mixed[m] = nil
			if s.EventList.Mixed[m] then
				if s.EventList.Mixed[m] > 0 then
					table.insert( eventList, s.EventList.Mixed[m] )
				end			
			else
				mf.dprint("Nil event number detected.")
			end			
		end		
	end

	--Initialize the event coords
	eventCoords = { 
		x = {0},
		y = {hold+offset},
	}

	--Make sure there's at least one event in the event list
	if next( eventList ) ~= nil then

		--Now generate the event level coordinates for a single train taking 
		--into account the auto fill/count mode
		for k,id in ipairs( eventList ) do
			local e = s.Event[id]		
			local options = {
				getFull = true,
				getDelay = false,
				coords = eventCoords,
				offset = offset,
				hold = hold,
			}		
			if s.Config.Auto == "none" then				
				options.getDelay = true
			end			
			if k == 1 and s.Config.Auto ~= "none" then
				firstEventDelay = tonumber( s.Event[id].Delay )
			end
			--New coordinates are automatically inserted into the list
			e:getCoords( options )
		end

		--Make sure that the time duration of the event coords is less than the
		--train period and delay.  Trim off any excess coordinates.
		local maxTime 
		if s.Config.Auto == "none" or s.Config.Auto == "count" then
			maxTime = math.min( s.Train.Dur, s.Train.Period )
		elseif s.Config.Auto == "fill" then
			maxTime = eventCoords.x[ #eventCoords.x ]
		end		

		for m = #eventCoords.x, 1, -1 do
			if eventCoords.x[m] > maxTime then
				table.remove( eventCoords.x )
				table.remove( eventCoords.y )
			end
		end

	end
	return eventCoords, firstEventDelay
end

--Get the coordinates for the entire set of trains and train events
function ams:getCoords()
	local s = self
	local trainCoords = {x={}, y = {}}
	local eventCoords = {x = {}, y = {}}
	local firstEventDelay = 0
	local newCoords = {x = {}, y = {}}
	local offset, hold = 0, 0
	local xOffset

	if s.Train.OffsetOrHold == "hold" then
		hold = s.Train.Level
	else
		offset = s.Train.Level
	end

	--Start by adding the intial coordinates to the train
	if s.Train.Delay > 0 then
		newCoords = {
			x = {0, s.Train.Delay },
			y = {hold, hold},			
		}		
	else
		newCoords = {
			x = {0},
			y = {hold + offset},
		}		
	end
	appendCoords( trainCoords, newCoords )	

	--Get the coordinates of all the events in a single train
	eventCoords, firstEventDelay = s:getEventCoords()

	if s.Config.Auto == "none" then
		--Finallly add in the coordinates for train duration and period
		if s.Train.Dur < s.Train.Period then
			newCoords = {
				x = {s.Train.Dur, s.Train.Dur,  s.Train.Period},
				y = {offset+hold, hold, hold},
			}		
		else
			newCoords = {
				x = {s.Train.Period},
				y = {offset+hold},
			}					
		end

		appendCoords( eventCoords, newCoords )	

		--Add in the coordinates for each train
		--Artificially cap the number of trains plotted to 100
		local maxNum = math.min( 100, s.Train.Quantity )
		for m = 1, maxNum do
			xOffset = trainCoords.x[#trainCoords.x] or 0
			appendCoords( trainCoords, eventCoords, xOffset )			
		end
	elseif s.Config.Auto == "fill" then
		--Fill mode ignores train period
		newCoords = {
			x = {0, firstEventDelay},
			y = {offset+hold, offset+hold},
		}
		xOffset = trainCoords.x[#trainCoords.x] or 0
		appendCoords( trainCoords, newCoords, xOffset )			

		--Add in the coordinates for each train
		--Cap the number of trains plotted at 100
		local maxNum = math.min( 100, s.Train.Quantity )
		for m = 1, maxNum do
			xOffset = trainCoords.x[#trainCoords.x] or 0
			appendCoords( trainCoords, eventCoords, xOffset )			
		end
		newCoords = {
			x = {s.Train.Period},
			y = {offset+hold},
		}
		xOffset = s.Train.Delay
		appendCoords( trainCoords, newCoords, xOffset )	
	elseif s.Config.Auto == "count" then

		newCoords = {
			x = {0, firstEventDelay},
			y = {offset+hold, offset+hold},
		}
		xOffset = trainCoords.x[#trainCoords.x] or 0
		appendCoords( trainCoords, newCoords, xOffset )		

		xOffset = trainCoords.x[#trainCoords.x] or 0
		appendCoords( trainCoords, eventCoords, xOffset )			

		newCoords = {
			x = {s.Train.Period},
			y = {offset+hold},
		}					
		xOffset = s.Train.Delay
		appendCoords( trainCoords, newCoords, xOffset )			

	end

	--Add in one last set of coords for the end of the train
	newCoords = {
		x = {0},
		y = {hold},
	}					
	xOffset = trainCoords.x[#trainCoords.x] or 0
	appendCoords( trainCoords, newCoords, xOffset )

	--Cap the number of coordinates at 1000.  Plotting more than this 
	--reduces performance and results in a meaningless display
	if #trainCoords.x > 2000 then
		newCoords = {x = {}, y = {}}
		for m = 1, 2000 do
			newCoords.x[m] = trainCoords.x[m]
			newCoords.y[m] = trainCoords.y[m]
		end
		trainCoords = newCoords
	end

	return trainCoords		
end


return ams