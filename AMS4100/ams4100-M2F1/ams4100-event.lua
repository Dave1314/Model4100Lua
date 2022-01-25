-------------------------------------------------
--
-- ams4100-event.lua
--
-- "ams4100-event" class for event level functions and data
--
-------------------------------------------------

local event= {}
local event_mt = { __index = event}	-- metatable

local ms

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------
local function warning( stringData )
	--print( stringData )
	--Show popup dialog box with warning message.
end

local function getKey( t, val )
	-- Find the key associated with a particular value in a table
	for k,v in pairs( t ) do
		if v == tonumber(val) then 
			return k 
		end
	end
	return nil
end

local function ampsCheck( value )
	--Check to make sure the current values are in the appropriate range
	value = tonumber( value )
	if value < -100000 then value = -100000 end
	if value > 100000 then value = 100000 end				
	return value
end

local function voltsCheck( value )
	--Check to make sure the votlage values are in the appropriate range
	value = tonumber( value )
	if value < -200000000 then value = -200000000 end
	if value > 200000000 then value = 200000000 end				
	return value
end

local function delayCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 0 then value = 0 end
	if value > 93600000000 then value = 93600000000 end	
	return value
end

local function periodCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 1 then value = 1 end
	if value > 93600000000 then value = 93600000000 end	
	return value
end

local function quantityCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 1 then value = 1 end
	if value > 99999 then value = 99999 end	
	return value
end

local function timeCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 0 then value = 0 end
	if value > 93600000000 then value = 93600000000 end	
	return value
end

local function insertMonoCoords( s, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local lastX
	lastX = coords.x[#coords.x]
	table.insert( coords.x, lastX )
	table.insert( coords.y, s.Amp1 + offset )		
	if s.Dur1 <= s.Period then
		table.insert( coords.x, lastX+s.Dur1 )
		table.insert( coords.x, lastX+s.Dur1 )
		table.insert( coords.y, s.Amp1 + offset )
		table.insert( coords.y, offset + hold )
	else
		table.insert( coords.x, lastX+s.Period )
		table.insert( coords.y, s.Amp1 + offset )			
	end
	table.insert( coords.x, lastX+s.Period )
	table.insert( coords.y, offset + hold )

end

local function insertAsymmCoords( s, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local lastX
	lastX = coords.x[#coords.x]
	table.insert( coords.x, lastX )
	table.insert( coords.y, s.Amp1 + offset )
	
	if s.Dur1 <= s.Period then
		table.insert( coords.x, lastX+s.Dur1 )
		table.insert( coords.x, lastX+s.Dur1 )
		table.insert( coords.y, s.Amp1 + offset )
		table.insert( coords.y, offset + hold )
	end
	
	if s.Dur1 + s.Intr <= s.Period then
		table.insert( coords.x, lastX+s.Dur1+s.Intr )
		table.insert( coords.x, lastX+s.Dur1+s.Intr )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, s.Amp2 + offset )
	end
	
	if s.Dur1 + s.Intr + s.Dur2 <= s.Period then
		table.insert( coords.x, lastX+s.Dur1+s.Intr+s.Dur2 )
		table.insert( coords.x, lastX+s.Dur1+s.Intr+s.Dur2 )				
		table.insert( coords.y, s.Amp2 + offset )
		table.insert( coords.y, offset + hold )
	else
		table.insert( coords.x, lastX+s.Period )
		table.insert( coords.y, s.Amp2 + offset )
	end
	
	table.insert( coords.x, lastX+s.Period )
	table.insert( coords.y, offset + hold )
end

local function insertBiCoords( s, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local lastX
	lastX = coords.x[#coords.x]
	table.insert( coords.x, lastX )
	table.insert( coords.y, s.Amp1 + offset )
	
	if s.Dur1 <= s.Period then
		table.insert( coords.x, lastX+s.Dur1 )
		table.insert( coords.x, lastX+s.Dur1 )
		table.insert( coords.y, s.Amp1 + offset )
		table.insert( coords.y, offset + hold )
	else
		table.insert( coords.x, lastX+s.Period )
		table.insert( coords.y, s.Amp1 + offset )		
	end
	
	if s.Dur1 + s.Intr <= s.Period then
		table.insert( coords.x, lastX+s.Dur1+s.Intr )
		table.insert( coords.x, lastX+s.Dur1+s.Intr )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, -s.Amp1 + offset )
	else
		table.insert( coords.x, lastX+s.Period )
		table.insert( coords.y, offset + hold )
	end
	
	if s.Dur1 + s.Intr + s.Dur1 <= s.Period then
		table.insert( coords.x, lastX+s.Dur1+s.Intr+s.Dur1 )
		table.insert( coords.x, lastX+s.Dur1+s.Intr+s.Dur1 )				
		table.insert( coords.y, -s.Amp1 + offset )
		table.insert( coords.y, offset + hold )
	else
		table.insert( coords.x, lastX+s.Period )
		table.insert( coords.y, -s.Amp1 + offset )
	end
	
	table.insert( coords.x, lastX+s.Period )
	table.insert( coords.y, offset + hold )
end

local function insertRampCoords( s, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local lastX
	lastX = coords.x[#coords.x]

	if s.Dur1 <= s.Period then
		table.insert( coords.x, lastX+s.Dur1 )
		table.insert( coords.y, s.Amp1 + offset )
	end
	
	if s.Dur1 + s.Intr <= s.Period then
		table.insert( coords.x, lastX+s.Dur1+s.Intr )
		table.insert( coords.y, s.Amp2 + offset )
	end

	if s.Dur1 + s.Intr + s.Dur2 <= s.Period then
		table.insert( coords.x, lastX+s.Dur1+s.Intr+s.Dur2 )
		table.insert( coords.y, offset + hold )
	else
		table.insert( coords.y, offset + hold )
		table.insert( coords.x, lastX+s.Period )
	end
	
	table.insert( coords.x, lastX+s.Period )
	table.insert( coords.y, offset + hold )

end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function event.new( p, mt )	-- constructor

	p = p or {}
	
	if mt then
		setmetatable( event, mt )
	end

	local newEvent= {
		-- Event Amplitude1 for the current LibID in uV	
		-- Valid values are: 0 to 200,000,000    
		-- EXAMPLE: handle.EventAmp1 =5000;  (5mV)
		Amp1 = p.Amp1 or 1000000,    
		-- Event Amplitude2 for the current LibID in uV	
		--Valid values are: 0 to 200,000,000    
		-- EXAMPLE: handle.EventAmp2 =5000;  (5mV)
		Amp2 = p.Amp2 or 1000000,    
		-- Event Delay for the current LibID in us	
		--Valid values are: 0 to 9,360,000,000   
		--EXAMPLE: handle.EventDelay =5000;   (5ms)
		Delay = p.Delay or 1000,     
		-- Event Duration1 for the current LibID  in us	
		--Valid values are: 0 to 9,360,000,000   
		--EXAMPLE: handle.EventDuration1 =5000;   (5ms)
		Dur1= p.Dur1 or 1000,      	
		-- Event Duration2 for the current LibID in us	
		--Valid values are: 0 to 9,360,000,000    
		--EXAMPLE: handle.EventDuration2 =5000;   (5ms)
		Dur2 = p.Dur2 or 1000,     	
		-- Event Duration3 for the current LibID in us	
		-- Valid values are: 0 to 9,360,000,000    
		-- EXAMPLE: handle.EventDur3 =5000;   (5ms)
		Intr = p.Intr or 1000,    	
		-- Event Frequency for the current LibID in HZ	
		-- Valid values are: 1,000,000/2  to 1,000,000/9,360,000,000 Hz    
		-- EXAMPLE: handle.EventFrequency =67; (Hz)	
		Frequency = p.Frequency or 100,	
		-- Event Period for the current LibID in us	
		-- Valid values are: 0 to 9,360,000,000    
		-- EXAMPLE: handle.EventPeriod =5000;   (5ms)
		Period = p.Period or 10000,   
		-- Event Quantity for the current LibID    
		-- Valid values are: 0 to 100    
		-- EXAMPLE: handle.EventQuantity = 12;
		Quantity = p.Quantity or 1,  	
		-- Event Symmetry for the current LibID     
		-- Valid values are: 0 to 100   
		-- EXAMPLE: handle.EventSym =1; or handle.EventSym = symmetry.no;
		--Sym = "yes",    
		-- The type of event for the current LibID .   
		-- EXAMPLE: handle.EventType =1;  or   handle.EventType = eType.biphasic;
		Type = p.Type or "biphasic",
		-- Units used for indicating time on graphs and textfields
		timeUnits = p.timeUnits or "ms",
		-- Units used for indicating amplitude on graphs and textfields
		ampUnits = p.ampUnits or "mV",
		-- Flag used to indicate an error in the event parameters
		err = p.err or false,	
		-- Event ID in the library
		-- Valid values are from 1 to 20
		id = p.id or 1,
	}
	--Store the options if a copy of this event needs to be created
	newEvent.parent = p.parent
	ms = p.menuStructure
	newEvent.options = p

	return setmetatable( newEvent, event_mt )
end

---------------------------------------------------------------------

function event:getType()

	local s = self

	-- The EventType property 
	--
	-- Valid values are:
	--   0 = monophasic 
	--   1 = biphasic 
	--   2 = ramp 
	--   EXAMPLE: handle.EventType =1;  
	--   EXAMPLE: handle.EventType = eType.biphasic; 
	--
	local function listener( value )
		if value then
			s.Type = getKey( ms.eType, value)
		end
	end	
	s.parent:getInfo( s.id, ms.event.eType, listener)
end

function event:setType( value ) 

	local s = self

	local function listener( value )
		if value then
			s.Type = getKey( ms.eType, value)
		end
	end		
	s.Type = value
	s.parent:setInfo( s.id, ms.event.eType, ms.eType[value], listener)
end

---------------------------------------------------------------------
function event:getDelay()

	local s = self
	-- The EventDelay property 
	--
	-- Valid values are:
	-- 0  to 9,360,000,000 us
	--   EXAMPLE: handle.EventDelay =5000 (5ms);  
	--
	local function listener( value )
		if value then
			s.Delay = delayCheck(value)
		end
	end	
	s.parent:getInfo(s.id, ms.event.delay, listener)

end

function event:setDelay( value )

	local s = self

	value = delayCheck( value )

	local function listener( value )
		if value then
			s.Delay = delayCheck(value)
		end
	end			
	s.Delay = value;
	s.parent:setInfo(s.id, ms.event.delay, value, listener);

end

---------------------------------------------------------------------
function event:getDur1()

	-- The EventDuration1 property 
	--
	-- Valid values are:
	-- 1  to 9,360,000,000 us
	--   EXAMPLE: handle.EventDuration1 =5000 (5ms);  
	--

	local s = self

	local function listener( value )
		if value then
			s.Dur1 = timeCheck(value)
			if s.Type == "biphasic" then
				s.Dur2 = s.Dur1
			end			
		end	
	end	
	s.parent:getInfo( s.id, ms.event.dur1, listener)

end

function event:setDur1( value )

	local s = self

	value = timeCheck( value )

	local function listener( value )
		if value then
			s.Dur1 = timeCheck(value)
			if s.Type == "biphasic" then
				s.Dur2 = s.Dur1
			end
		end	
	end			
	s.Dur1 = value;
	if s.Type == "biphasic" then
		s.Dur2 = s.Dur1
	end
	s.parent:setInfo( s.id, ms.event.dur1, value, listener);

end

---------------------------------------------------------------------
function event:getDur2()
	-- The EventDuration2 property 
	--
	-- Valid values are:
	-- 0  to 9,360,000,000 us
	--   EXAMPLE: handle.EventDuration2 =5000 (5ms);  
	--
	local s = self

	local function listener( value )
		if value then
			s.Dur2 = timeCheck(value)
			if s.Type == "biphasic" then
				s.Dur2 = s.Dur1
			end		
		end
	end
	s.parent:getInfo( s.id, ms.event.dur2, listener )

end


function event:setDur2( value )

	local s = self

	value = timeCheck( value )

	local function listener( value )
		if value then
			s.Dur2 = timeCheck(value)
			if s.Type == "biphasic" then
				s.Dur2 = s.Dur1
			end
		end
	end			

	s.Dur2 = timeCheck( value )	
	if s.Type == "biphasic" then
		s.Dur2 = s.Dur1
	end

	s.parent:setInfo( s.id, ms.event.dur2, value, listener);

end

---------------------------------------------------------------------
function event:getIntr()
	-- The EventDuration2 property 
	--
	-- Valid values are:
	-- 1  to 9,360,000,000 us
	--   EXAMPLE: handle.EventDur3 =5000 (5ms);  
	--
	local s = self
	local function listener( value )
		if value then
			s.Intr = timeCheck(value)
		end
	end	
	s.parent:getInfo( s.id, ms.event.intr, listener)

end

function event:setIntr(value)

	local s = self
	value = timeCheck( value )

	local function listener( value )
		if value then
			s.Intr = timeCheck(value)
		end
	end		
	s.Intr=value;
	s.parent:setInfo( s.id, ms.event.intr, value, listener);

end

---------------------------------------------------------------------
function event:getPeriod()
	-- The EventPeriod property 
	--
	-- Valid values are:
	-- 2  to 9,360,000,000 us
	--   EXAMPLE: handle.EventPeriod =5000 (5ms);  
	--
	local s = self
	local md = require( "myData" )
	local ams = md.instrumentSettings.current
	
	local function listener( value )
		if value then
			s.Period = periodCheck(value)
			s.Frequency = 1000000/s.Period
		end		
	end	
	s.parent:getInfo( s.id, ms.event.period, listener)

end

function event:setPeriod( value )

	local s = self
	local md = require( "myData" )
	local ams = md.instrumentSettings.current
	
	value = periodCheck( value )

	local function listener( value )
		if value then
			s.Period = periodCheck(value)
			s.Frequency = 1000000/s.Period
		end		
	end		
	local freq=1000000/value
	s.Period=value
	s.Frequency=freq

	s.parent:setInfo( s.id, ms.event.period, value, listener)

end

--[[-------------------------------------------------------------------
--This section was commented out to break the strict ties between period 
--and frequency between the instrument and the app
function event:getPeriod()
	-- The EventPeriod property 
	--
	-- Valid values are:
	-- 2  to 9,360,000,000 us
	--   EXAMPLE: handle.EventPeriod =5000 (5ms);  
	--
	local s = self
	local md = require( "myData" )
	local ams = md.instrumentSettings.current
	
	local function listener( value )
		if value then
			if ams.Config.PeriodOrFreq == "frequency" then
				s.Period = periodCheck(1/value*1e6)
				s.Frequency = math.round(1000000/s.Period)				
			else
				s.Period = periodCheck(value)
				s.Frequency = math.round(1000000/s.Period)
			end
		end		
	end	
	s.parent:getInfo( s.id, ms.event.period, listener)

end

function event:setPeriod( value )

	local s = self
	local md = require( "myData" )
	local ams = md.instrumentSettings.current
	
	value = periodCheck( value )

	local function listener( value )
		if value then
			if ams.Config.PeriodOrFreq == "frequency" then
				s.Period = periodCheck(1/value*1e6)
				s.Frequency = math.round(1000000/s.Period)				
			else
				s.Period = periodCheck(value)
				s.Frequency = math.round(1000000/s.Period)
			end
		end		
	end		
	local freq=math.round(1000000/value);
	s.Period=value;
	s.Frequency=freq;

	if ams.Config.PeriodOrFreq == "frequency" then
		s.parent:setInfo( s.id, ms.event.period, freq, listener)
	else
		s.parent:setInfo( s.id, ms.event.period, value, listener)
	end
end
--]]
---------------------------------------------------------------------
function event:getQuantity()
	-- The EventQuantity property 
	--
	-- Valid values are:
	-- 1  to 100
	--   EXAMPLE: handle.EventQuantity =22 ;  
	--
	local s = self
	local function listener( value )
		if value then
			s.Quantity = quantityCheck(value)
		end	
	end	
	s.parent:getInfo( s.id, ms.event.quantity, listener)

end

function event:setQuantity( value )

	local s = self
	value = quantityCheck( value )

	local function listener( value )
		if value then
			s.Quantity = quantityCheck(value)
		end	
	end			
	s.Quantity=value
	s.parent:setInfo( s.id, ms.event.quantity, value, listener )
end

---------------------------------------------------------------------
function event:getFrequency()
	-- The EventFrequency property 
	--
	-- Valid values are:
	-- 1,000,000/2  to 1,000,000/9,360,000,000 Hz
	--   EXAMPLE: handle.EventFrequency =67; (Hz)  
	--
	local s = self
	local function listener( value )

	end
end

function event:setFrequency( value )

	--local period=math.round(1000000/value);
	--if math.max(period) >9360000000 or math.min(period)<0 then
	--warning('EventFrequency must be a float from 1.0684e-04 to 500,000');
	--else
	--s.Frequency=value;
	--s.Period=period;
	--setInfo(s.id, event.period, period);
	--end		
end  

---------------------------------------------------------------------
function event:getAmp1()
	-- The EventAmp1 property 
	--
	-- Valid values are:
	-- 0  to 200000000
	--   EXAMPLE: handle.EventAmp1 =10000;  (this is 10mV)  
	--
	local s = self
	local function listener( value )
		if value then
			if s.parent.Config.Mode == "current" then
				s.Amp1=ampsCheck(value)
			else
				s.Amp1=voltsCheck(value)
			end
			
			if s.Type == "biphasic" then
				s.Amp2 = -s.Amp1
			end
		end
	end	
	s.parent:getInfo( s.id, ms.event.amp1, listener )

end

function event:setAmp1(value)

	local s = self

	if s.parent.Config.Mode == "current" then
		s.Amp1=ampsCheck(value)
	else
		s.Amp1=voltsCheck(value)
	end
			
	local function listener( value )
		if value then
			if s.parent.Config.Mode == "current" then
				s.Amp1=ampsCheck(value)
			else
				s.Amp1=voltsCheck(value)
			end
			if s.Type == "biphasic" then
				s.Amp2 = -s.Amp1
			end
		end
	end			
	s.Amp1=value;
	if s.Type == "biphasic" then
		s.Amp2 = -s.Amp1
	end
	s.parent:setInfo( s.id, ms.event.amp1, value, listener);

end

---------------------------------------------------------------------
function event:getAmp2()
	-- The EventAmplitude property 
	--
	-- Valid values are:
	-- 0  to 200000000
	--   EXAMPLE: handle.EventAmplitude =10000;  (this is 10mV)  
	--
	local s = self
	local function listener( value )
		if value then
			if s.Type == "biphasic" then
				s.Amp2 = -s.Amp1
			else
				if s.parent.Config.Mode == "current" then
					s.Amp2=ampsCheck(value)
				else
					s.Amp2=voltsCheck(value)
				end				
			end			
		end
	end	
	s.parent:getInfo(s.id, ms.event.amp2, listener)

end

function event:setAmp2( value )

	local s = self
	if s.parent.Config.Mode == "current" then
		value=ampsCheck(value)
	else
		value=voltsCheck(value)
	end		

	local function listener( value )
		if value then			
			if s.Type == "biphasic" then
				s.Amp2 = -s.Amp1
			else
				if s.parent.Config.Mode == "current" then
					s.Amp2=ampsCheck(value)
				else
					s.Amp2=voltsCheck(value)
				end
			end
		end
	end			

	if s.Type == "biphasic" then
		s.Amp2 = -s.Amp1
	else
		s.Amp2 = value
	end

	s.parent:setInfo(s.id, ms.event.amp2, value, listener);

end

---------------------------------------------------------------------
function event:getMenuVals()
	--Get all the values for a single event
	local s = self
	s:getType()
	s:getDelay()
	s:getDur1()
	s:getDur2()
	s:getAmp1()
	s:getAmp2()
	s:getIntr()
	s:getPeriod()
	s:getQuantity()
end

function event:setMenuVals( newVals ) 
	--Set all the values for a single event
	local s = self
	newVals = newVals or {}
	if s.parent.getStatusTimer then
		timer.pause( s.parent.getStatusTimer )
	end
	
	s:setType( newVals.Type or s.Type )
	s:setDelay( newVals.Delay or s.Delay )
	s:setDur1( newVals.Dur1 or s.Dur1 )
	s:setDur2( newVals.Dur2 or s.Dur2 )
	s:setAmp1( newVals.Amp1 or s.Amp1 )
	s:setAmp2( newVals.Amp2 or s.Amp2 )
	s:setIntr( newVals.Intr or s.Intr )
	s:setPeriod( newVals.Period or s.Period )
	s:setQuantity( newVals.Quantity or s.Quantity )
	if s.parent.getStatusTimer then
		timer.resume( s.parent.getStatusTimer )
	end

	
end
---------------------------------------------------------------------

function event:getCoords( options )
	-- Return the coordinates for ths event
	-- Coordinates can either be full including quantity and delay
	-- or partial without the delay and only a single instance.
	
	--print( "offset: " .. options.offset )
	--print("hold: " .. options.hold )
	
	local s = self
	options = options or {}	
	local	getFull = options.getFull
	local getDelay = options.getDelay
	local offset = options.offset or 0
	local hold = options.hold or 0
	local	coords = options.coords or { x = {0}, y = {offset + hold} }
	local maxNum = 1

	if getDelay then
		local xOffset = coords.x[#coords.x] or 0
		coords.x[ #coords.x+1 ] = s.Delay + xOffset		
		coords.y[ #coords.y+1 ] = offset + hold		
	end
	
	if getFull then
		maxNum = s.Quantity
		local xOffset = coords.x[#coords.x] or 0
		--coords.x[ #coords.x+1 ] = s.Delay + xOffset
		coords.x[ #coords.x+1 ] = xOffset
		coords.y[ #coords.y+1 ] = offset + hold		
	end
	
	--Cap the number of events at 100.  Anything more is redundant.
	maxNum = math.min( maxNum, 100 )

	for m = 1, maxNum do
		if s.Type == "monophasic" then
			insertMonoCoords( s, coords, offset, hold )
		elseif s.Type == "biphasic" then
			insertBiCoords( s, coords, offset, hold )
		elseif s.Type == "asymm" then
			insertAsymmCoords( s, coords, offset, hold )
		elseif s.Type == "ramp" then
			insertRampCoords( s, coords, offset, hold )
		end
	end

	return coords
end


return event