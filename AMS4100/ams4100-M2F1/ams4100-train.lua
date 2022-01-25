-------------------------------------------------
--
-- ams4100-ms.train.lua
--
-- "ams4100-train" class for train level functions and data
--
-------------------------------------------------

local train= {	get = {}, set = {} }
local train_mt = { __index = train}	-- metatable
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
	--if value > 100 then value = 100 end	
	return value
end

local function timeCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 0 then value = 0 end
	if value > 93600000000 then value = 93600000000 end	
	return value
end

local function freqCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 0 then value = 0 end
	if value > 1000000 then value = 1000000 end	
	return value
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function train.new( p )	-- constructor

	p = p or {}

	local newtrain= {
		-- Train type   
		-- EXAMPLE: handle.TrainType =1;  or  handle.TrainType = tType.simple; 
		Type = p.Type or "mixed",      
		-- Train Delay in us	
		-- Valid values are: 0 to 9,360,000,000    
		-- EXAMPLE: handle.TrainDelay =5000;   (5ms)  
		Delay = p.Delay or 5000,        
		-- Pre Train Onset Delay in us	
		-- This parameter is NOT included in repeated trains
		-- Valid values are: 0 to 9,360,000,000    
		-- EXAMPLE: handle.TrainDelay =5000;   (5ms)  
		PreDelay = p.PreDelay or 5000,        		
		-- Post Train Onset Delay in us	
		-- This parameter is included in repeated trains
		-- Valid values are: 0 to 9,360,000,000    
		-- EXAMPLE: handle.TrainDelay =5000;   (5ms)  
		PostDelay = p.PostDelay or 5000,        		
		-- Train Duration in us	
		-- Valid values are: 0 to 9,360,000,000    
		-- EXAMPLE: handle.TrainDur=5000; (5ms) 
		Dur = p.Dur or 50000,      	
		-- Train Period in us	
		-- Valid values are: 0 to 9,360,000,000    
		-- EXAMPLE: handle.TrainPeriod =5000;  (5ms)
		Period = p.Period or 50000,     
		-- Train Quantity    
		-- Valid values are: 0 to 100    
		-- EXAMPLE: handle.TrainQuantity =11;		
		Quantity = p.Quantity or 1,  		
		-- EXAMPLE: handle.OffsetOrHold =1;  
		OffsetOrHold = "hold",
		-- Train Level in uV	
		-- Valid values are: 0 to 200,000,000    
		-- EXAMPLE: handle.TainLevel =5000;  (5mV)		
		Level = p.Level or 1000,     
		-- Train Frequency in HZ	
		-- Valid values are: 1,000,000/2  to 1,000,000/9,360,000,000 Hz    
		-- EXAMPLE: handle.TrainFrequency =67; (Hz)
		--Frequency = p.Frequency or 1000,	
		-- Flag used to indicate an error in the train parameters
		perError = false,
		durError = false,		
		-- Units used for indicating time on graphs and textfields
		timeUnits = p.timeUnits or "ms",
		-- Units used for indicating amplitude on graphs and textfields
		ampUnits = p.ampUnits or "mV",
		-- Flag used to indicate an error in the train parameters
		Stored = {}
	}
	newtrain.Stored = {
		Period = newtrain.Period,
		Dur = newtrain.Dur,
		Quantity = newtrain.Quantity,
	}			
	
	--Store the options if a copy of this train needs to be created
	newtrain.parent = p.parent
	ms = p.menuStructure
	newtrain.options = p

	return setmetatable( newtrain, train_mt )
end

---------------------------------------------------------------------

function train:getType()
	-- The TrainType property 
	--
	-- Valid values are:
	-- 0 =  simple
	-- 1 =  uniform
	-- 2 =  mixed
	--   EXAMPLE: handle.TrainType =1;  
	--   EXAMPLE: handle.TrainType = tType.simple; 
	--
	local s = self
	local function listener( value )
		if value then
			s.Type = getKey( ms.tType, value )
		end
	end	
	s.parent:getInfo(ms.amsMenu.train, ms.train.trainType, listener)

end

function train:setType( value )
	local s = self
	local function listener( value )
		if value then
			s.Type = getKey( ms.tType, value )			
		end
	end		
	s.Type = value
	s.parent:setInfo(ms.amsMenu.train, ms.train.trainType, ms.tType[value], listener)
end

---------------------------------------------------------------------
function train:getDelay(obj)
	-- The TrainDelay property 
	--
	-- Valid values are:
	-- 0  to 9,360,000,000 us
	--   EXAMPLE: handle.TrainDelay =5000 (5ms);  
	--
	local s = self
	local function listener( value )
		if value then
			s.Delay = delayCheck(value)
		end	
	end	
	s.parent:getInfo(ms.amsMenu.train,ms.train.delay, listener)

end

function train:setDelay(value)
	local s = self
	value = delayCheck( value )

	local function listener( value )
		if value then
			s.Delay = delayCheck(value)
		end	
	end			

	s.Delay = value;
	s.parent:setInfo(ms.amsMenu.train, ms.train.delay, value, listener);

end

---------------------------------------------------------------------
function train:getDur()
	--TrainDur- train duration in us
	-- The TrainDurproperty 
	--
	-- Valid values are:
	-- 2  to 9,360,000,000 us
	--   EXAMPLE: handle.TrainDur=5000 (5ms);  
	--
	local s = self
	local function listener( value )
		if value then 
			s.Dur = timeCheck(value)
		end	
	end	
	s.parent:getInfo(ms.amsMenu.train,ms.train.duration, listener);

end

function train:setDur(value)
	local s = self
	value = timeCheck( value )

	local function listener( value )
		if value then 
			s.Dur = timeCheck(value)
		end	
	end		
	s.Dur = value;
	s.parent:setInfo(ms.amsMenu.train, ms.train.duration, value, listener);

end

---------------------------------------------------------------------
function train:getPeriod()
	-- The TrainPeriod property 
	--
	-- Valid values are:
	-- 2  to 9,360,000,000 us
	--   EXAMPLE: handle.TrainPeriod =5000 (5ms);  
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
	s.parent:getInfo(ms.amsMenu.train, ms.train.period, listener)
end

function train:setPeriod( value )

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
	local freq = 1000000/value
	s.Period = value					
	s.Frequency=freq
	
	s.parent:setInfo(ms.amsMenu.train, ms.train.period, value, listener)

end
--[[-------------------------------------------------------------------
--This section was commented out to break the strict ties between period 
--and frequency between the instrument and the app
function train:getPeriod()
	-- The TrainPeriod property 
	--
	-- Valid values are:
	-- 2  to 9,360,000,000 us
	--   EXAMPLE: handle.TrainPeriod =5000 (5ms);  
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
	s.parent:getInfo(ms.amsMenu.train, ms.train.period, listener)

end

function train:setPeriod( value )

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
	local freq = math.round(1000000/value)
	s.Period = value					
	s.Frequency=freq
	
	if ams.Config.PeriodOrFreq == "frequency" then
		s.parent:setInfo(ms.amsMenu.train, ms.train.period, freq, listener)
	else
		s.parent:setInfo(ms.amsMenu.train, ms.train.period, value, listener)
	end

end
--]]
---------------------------------------------------------------------
function train:getQuantity()
	-- The TrainQuantity property 
	--
	-- Valid values are:
	-- 1  to 100
	--   EXAMPLE: handle.TrainQuantity =22 ;  
	--
	local s = self
	local function listener( value )
		if value then 
			s.Quantity = quantityCheck(value)
		end
	end	
	s.parent:getInfo(ms.amsMenu.train,ms.train.quantity, listener)

end

function train:setQuantity(value)
	local s = self
	value = quantityCheck( value )

	local function listener( value )
		if value then 
			s.Quantity = quantityCheck(value)
		end
	end			
	s.Quantity=value;
	s.parent:setInfo(ms.amsMenu.train, ms.train.quantity, value, listener);

end

---------------------------------------------------------------------
function train:getLevel()
	-- The TainLevel property 
	--
	-- Valid values are:
	-- 0  to 200000000
	--   EXAMPLE: handle.TainLevel =10000;  (this is 10mV)  
	--
	local s = self
	local function listener( value )
		if value then
			if s.parent.Config.Mode == "current" then
				s.Level=ampsCheck(value)
			else
				s.Level=voltsCheck(value)
			end		
		end
	end	
	s.parent:getInfo(ms.amsMenu.train,ms.train.level, listener)

end

function train:setLevel(value)

	local s = self
	if s.parent.Config.Mode == "current" then
		value=ampsCheck(value)
	else
		value=voltsCheck(value)
	end		

	local function listener( value )
		if value then
			if s.parent.Config.Mode == "current" then
				s.Level=ampsCheck(value)
			else
				s.Level=voltsCheck(value)
			end	
		end
	end			
	s.Level=value;
	s.parent:setInfo(ms.amsMenu.train, ms.train.level, value, listener);

end

---------------------------------------------------------------------
function train:getOffsetOrHold()
	-- The OffsetOrHold property 
	--
	-- Valid values are:
	-- 0 = duration
	-- 1 = counts
	--   EXAMPLE: handle.OffsetOrHold =1;  
	--   EXAMPLE: handle.OffsetOrHold = OffsetOrHold.duration; 
	--
	local s = self
	local function listener( value )
		if value then
			s.OffsetOrHold = getKey( ms.offsetOrHold, value )
		end
	end
	s.parent:getInfo(ms.amsMenu.train, ms.train.offsetOrHold, listener)

end

function train:setOffsetOrHold( value )
	local s = self
	local function listener( value )
		if value then
			s.OffsetOrHold = getKey( ms.offsetOrHold, value )
		end
	end	
	s.DurOrCount = value
	s.parent:setInfo(ms.amsMenu.train, ms.train.offsetOrHold, ms.offsetOrHold[value], listener)
end

--[[-------------------------------------------------------------------
function train:getFrequency()
	-- The TrainFrequency property 
	--
	-- Valid values are:
	-- 1,000,000/2  to 1,000,000/9,360,000,000 Hz
	--   EXAMPLE: handle.TrainPeriod =67; (Hz)  
	-- 
	local s = self
	local function listener( value )

	end	
	return s.Frequency;
end

function train:setFrequency(value)

	local s = self
	--local period = math.round(1000000/value);
	--if math.max(period) >9360000000 or math.min(period)<0 then
	--	warning('TrainFrequency must be floats from 1.0684e-04 to 500,000');
	--else
	--	sFrequency=value;
	--	sPeriod=period;
	--	setInfo(ms.amsMenu.train, ms.train.period, period);
	--end		
end  

--]]-------------------------------------------------------------------
function train:getMenuVals()
	local s = self
	s:getType()
	s:getDelay()
	s:getDur()
	s:getPeriod()
	s:getQuantity()
	s:getLevel()
	s:getOffsetOrHold()
	--s:getFrequency()
end

function train:setMenuVals( newVals )
	local s = self
	newVals = newVals or {}
	if s.parent.getStatusTimer then
		timer.pause( s.parent.getStatusTimer )
	end
	s:setType( newVals.Type or s.Type )
	s:setDelay( newVals.Delay or s.Delay )
	s:setDur( newVals.Dur or s.Dur )
	s:setPeriod( newVals.Period or s.Period )
	s:setQuantity( newVals.Quantity or s.Quantity )
	s:setLevel( newVals.Level or s.Level )
	s:setOffsetOrHold( s.OffsetOrHold )
	if s.parent.getStatusTimer then
		timer.resume( s.parent.getStatusTimer )
	end
	--s:setFrequency( newVals.Frequency or s.Frequency )
end
---------------------------------------------------------------------
return train