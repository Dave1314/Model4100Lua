-------------------------------------------------
--
-- ams4100-ms.config.lua
--
-- "ams4100-config" class for train level functions and data
--
-------------------------------------------------

local config = {	get = {}, set = {} }
local config_mt = { __index = config}	-- metatable

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
	--Check to make sure the amp values are in the appropriate range
	value = tonumber( value )
	if value < -100000 then value = -100000 end
	if value > 100000 then value = 100000 end				
	return value
end

local function voltsCheck( value )
	--Check to make sure the voltage values are in the appropriate range
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
	if value < 3 then value = 3 end
	if value > 93600000000 then value = 93600000000 end	
	return value
end

local function quantityCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 1 then value = 1 end
	if value > 100 then value = 100 end	
	return value
end

local function timeCheck( value )
	--Check to make sure the time values are in the appropriate range
	value = tonumber( value )
	if value < 0 then value = 0 end
	if value > 93600000000 then value = 93600000000 end	
	return value
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function config.new( p )	-- constructor

	p = p or {}

	local newconfig= {

		Revision = "AMS 4100",
		-- Mode type       
		-- EXAMPLE: handle.Mode =3;  
		Mode = "intVolt",    
		-- Output type       
		-- EXAMPLE: handle.Output =0;  
		Output = "on",           		
		-- Trigger type      
		-- EXAMPLE: handle.Trigger =1; 
		Trigger = "rising",         
		-- Variable Auto complete 	
		-- EXAMPLE: handle.Auto =1; 
		Auto = "none",              
		-- BNC Monitor output scale   
		-- EXAMPLE: handle.Monitor =1; 
		Monitor = "scale1VperV",     
		-- BNC Sync1 source      
		-- EXAMPLE: handle.Sync1 =1; 
		Sync1= "trainDuration",              
		-- BNC Sync2 source      
		-- EXAMPLE: handle.Sync2 =1;  
		Sync2 = "trainDuration",        
		-- Frequecy input style    
		-- EXAMPLE: handle.PeriodOrFreq =1; 
		PeriodOrFreq = "period",
		-- Duration input style 
		-- EXAMPLE: handle.DurOrCount =1; 
		DurOrCount = "",        
		-- Set train level as offset or hold       
		-- loads the config data if it exists in the config list when in train type mixed.
		configID = "1",  
	}
	--Store the options if a copy of this config needs to be created
	newconfig.parent = p.parent
	ms = p.menuStructure
	newconfig.options = p

	return setmetatable( newconfig, config_mt )
end

---------------------------------------------------------------------
function config:getMode()
	-- The Output property sets the output type
	--
	-- Valid values are:
	-- 0 = Int Volt
	-- 1 = Int Current
	-- 2 = Ext 20V/V
	-- 3 = Ext 10 ma/V
	-- 4 = Ext 1 ma/V
	-- 5 = Ext 100 uA/V
	--   EXAMPLE: handle.Output =3;  
	--   EXAMPLE: handle.Output = output.intVolt;  
	local s = self
	local function listener( value )
		if value then
			s.Mode = getKey( ms.mode, value )
		end			
	end
	
	s.parent:getInfo(ms.amsMenu.general, ms.general.mode, listener)	
end

function config:setMode( value )
	local s = self
	local function listener( value )
		if value then
			s.Mode = getKey( ms.mode, value )
		end			
	end
	s.Mode = value
	s.parent:setInfo(ms.amsMenu.general, ms.general.mode, ms.mode[value], listener)
end
---------------------------------------------------------------------
function config:getOutput()
	-- The Output property 
	--
	-- Valid values are:
	-- 0 = On
	-- 1 = Off
	--   EXAMPLE: handle.On =1;  
	--   EXAMPLE: handle.Off =trigger.rising; 
	--   
	local s = self
	local function listener( value )
		if value then
			s.Output = getKey( ms.output, value )	
		end	
	end
	s.parent:getInfo(ms.amsMenu.general, ms.general.output, listener);  

end

function config:setOutput( value )
	local s = self
	local function listener( value )
		if value then
			s.Output = getKey( ms.output, value )	
		end	
	end
	s.Output = value
	s.parent:setInfo(ms.amsMenu.general,ms.general.output, ms.output[value], listener)
end

---------------------------------------------------------------------
function config:getTrigger()
	-- The Trigger property 
	--
	-- Valid values are:
	-- 0 = Rising
	-- 1 = Falling
	--   EXAMPLE: handle.Trigger =1;  
	--   EXAMPLE: handle.Trigger =trigger.rising; 
	--   
	local s = self
	local function listener( value )
		if value then
			s.Trigger = getKey( ms.trigger, value )	
		end	
	end
	s.parent:getInfo(ms.amsMenu.general, ms.general.trigger, listener);  

end

function config:setTrigger( value )
	local s = self
	local function listener( value )
		if value then
			s.Trigger = getKey( ms.trigger, value )	
		end	
	end
	s.Trigger = value
	s.parent:setInfo(ms.amsMenu.general,ms.general.trigger, ms.trigger[value], listener)
end

---------------------------------------------------------------------
function config:getAuto()
	-- The Auto property 
	--
	-- Valid values are:
	-- 0 = None
	-- 1 = Fixed
	-- 2 = Square
	--   EXAMPLE: handle.Auto =1;  
	--   EXAMPLE: handle.Auto =auto.fixed;  
	--
	local s = self
	local function listener( value )
		if value then 
			s.Auto = getKey( ms.auto, value )
		end	
	end
	s.parent:getInfo(ms.amsMenu.general, ms.general.auto, listener);

end

function config:setAuto( value )
	local s = self
	local function listener( value )
		if value then 
			s.Auto = getKey( ms.auto, value )
		end	
	end
	s.Auto = value
	s.parent:setInfo(ms.amsMenu.general, ms.general.auto, ms.auto[value], listener)
end

---------------------------------------------------------------------
function config:getMonitor()
	-- The Monitor property 
	--
	-- Valid values are:
	-- 0 = 1V/V
	-- 1 = 10V/V
	-- 2 = 20V/V
	-- 3 = 1V/mA
	-- 4 = 10V/mA
	-- 5 = 100V/mA
	--   EXAMPLE: handle.Monitor =1;  
	--   EXAMPLE: handle.Monitor = monitor.scale1VperV; 
	--
	local s = self
	local function listener( value )
		if value then
			s.Monitor = getKey( ms.monitor, value )
		end
	end
	s.parent:getInfo(ms.amsMenu.general, ms.general.monitor, listener)

end

function config:setMonitor( value )
	local s = self
	local function listener( value )
		if value then
			s.Monitor = getKey( ms.monitor, value )
		end
	end	
	s.Monitor = value
	s.parent:setInfo(ms.amsMenu.general, ms.general.monitor, ms.monitor[value], listener )
end
---------------------------------------------------------------------
function config:getSync1()
	-- The Sync1 property 
	--
	-- Valid values are:
	-- 0 = trainDelay
	-- 1 = TrainDur
	-- 2 = eventPeriod
	-- 3 = eventDuration1
	-- 4 = eventDuration2
	-- 5 = EventDur3
	--   EXAMPLE: handle.Sync1 =1;  
	--   EXAMPLE: handle.Sync1 =sync.eventPeriod; 
	--
	local s = self
	local function listener( value )
		if value then
			s.Sync1 = getKey( ms.sync, value )
		end
	end
	s.parent:getInfo(ms.amsMenu.config, ms.config.sync1, listener)

end

function config:setSync1(value)
	local s = self
	local function listener( value )
		if value then
			s.Sync1 = getKey( ms.sync, value )
		end
	end	
	s.Sync1 = value
	s.parent:setInfo(ms.amsMenu.config, ms.config.sync1,ms.sync[value], listener)
end

---------------------------------------------------------------------
function config:getSync2()
	-- The Sync2 property 
	--
	-- Valid values are:
	-- 0 = trainDelay
	-- 1 = TrainDur
	-- 2 = eventPeriod
	-- 3 = eventDuration1
	-- 4 = eventDuration2
	-- 5 = EventDur3
	--   EXAMPLE: handle.Sync2 =1;  
	--   EXAMPLE: handle.Sync2 =sync.eventPeriod; 
	--
	local s = self
	local function listener( value )
		if value then
			s.Sync2 = getKey( ms.sync, value )
		end
	end	
	s.parent:getInfo(ms.amsMenu.config, ms.config.sync2, listener)

end

function config:setSync2(value)
	local s = self
	local function listener( value )
		if value then
			s.Sync2 = getKey( ms.sync, value )
		end
	end		
	s.Sync2 = value
	s.parent:setInfo(ms.amsMenu.config, ms.config.sync2, ms.sync[value], listener)
end
---------------------------------------------------------------------
function config:getPeriodOrFreq()
	-- The PeriodOrFreq property 
	--
	-- Valid values are:
	-- 0 = Period
	-- 1 = Frequency
	--   EXAMPLE: handle.PeriodOrFreq =1;  
	--   EXAMPLE: handle.PeriodOrFreq = periodOrFreq.frequency; 
	--
	local s = self
	local function listener( value )
		if value then
			local periodOrFreq = getKey( ms.periodOrFreq, value )
			if (periodOrFreq == "frequency") then
				s.PeriodOrFreq = periodOrFreq
				s.setPeriodOrFreq("period")
			end
		end
	end
	s.parent:getInfo(ms.amsMenu.config, ms.config.periodOrFreq, listener)
end

function config:setPeriodOrFreq(value)
	local s = self
	local function listener( value )
		if value then
			--s.PeriodOrFreq = getKey( ms.periodOrFreq, value )
		end
	end	
	--s.parent:setInfo(ms.amsMenu.config, ms.config.periodOrFreq, ms.periodOrFreq[value], listener);
	s.parent:setInfo(ms.amsMenu.config, ms.config.periodOrFreq, ms.periodOrFreq["period"], listener);
end
--[[-------------------------------------------------------------------
--This section was commented out to break the strict ties between period 
--and frequency between the instrument and the app
function config:getPeriodOrFreq()
	-- The PeriodOrFreq property 
	--
	-- Valid values are:
	-- 0 = Period
	-- 1 = Frequency
	--   EXAMPLE: handle.PeriodOrFreq =1;  
	--   EXAMPLE: handle.PeriodOrFreq = periodOrFreq.frequency; 
	--
	local s = self
	local function listener( value )
		if value then
			s.PeriodOrFreq = getKey( ms.periodOrFreq, value )
		end
	end
	s.parent:getInfo(ms.amsMenu.config, ms.config.periodOrFreq, listener)

end

function config:setPeriodOrFreq(value)
	local s = self
	local function listener( value )
		if value then
			s.PeriodOrFreq = getKey( ms.periodOrFreq, value )
		end
	end	
	s.PeriodOrFreq = value
	s.parent:setInfo(ms.amsMenu.config, ms.config.periodOrFreq, ms.periodOrFreq[value], listener);
end
--]]

---------------------------------------------------------------------


function config:getMenuVals()
	local s = self
	--config:getRevision()
	s:getMode()	
	s:getTrigger()
	s:getAuto()
	s:getMonitor()
	s:getSync1()
	s:getSync2()
	s:getOutput()
	s:getPeriodOrFreq()	
end

function config:setMenuVals( newVals )
	local s = self
	newVals = newVals or {}
	if s.parent.getStatusTimer then
		timer.pause( s.parent.getStatusTimer )
	end	
	s:setMode( newVals.Mode or s.Mode )
	s:setTrigger( newVals.Trigger or s.Trigger )
	s:setAuto( newVals.Auto or s.Auto )
	s:setMonitor( newVals.Monitor or s.Monitor )
	s:setSync1( newVals.Sync1 or s.Sync1 )
	s:setSync2( newVals.Sync2 or s.Sync2 )
	s:setOutput( newVals.Output or s.Output )
	s:setPeriodOrFreq( newVals.PeriodOrFreq or s.PeriodOrFreq )	
	if s.parent.getStatusTimer then
		timer.resume( s.parent.getStatusTimer )
	end	
end

return config