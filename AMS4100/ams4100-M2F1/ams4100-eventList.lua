-------------------------------------------------
--
-- ams4100-eventList.lua
--
-- "ams4100-eventList" class for eventList level functions and data
--
-------------------------------------------------

local eventList = {}
local eventList_mt = { __index = eventList}	-- metatable
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

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function eventList.new( options )	-- constructor
		
	local newEventList= { Uniform = 1, Mixed = {} }
	for m = 1, 20 do
		newEventList.Mixed[m] = -1
	end
	newEventList.parent = options.parent
	ms = options.menuStructure
	
	return setmetatable( newEventList, eventList_mt )
end

---------------------------------------------------------------------
function eventList:getUniform()
	-- The TrainQuantity property 
	--
	-- Valid values are:
	-- 1  to 20
	--   EXAMPLE: handle.TrainQuantity =12 ;  
	--
	local s = self
	local function listener( value )
		if value then 
			value = tonumber( value )
			if value < 1 then value = 1 end
			if value > 20 then value = 20 end
			s.Uniform = value
		end
	end	
	s.parent:getInfo(ms.amsMenu.uniform, ms.uniform.eventNumber, listener)

end

function eventList:setUniform( list )
	local s = self
	list = list or {}

	local function listener( value )
		if value then 
			value = tonumber( value )
			if value < 1 then value = 1 end
			if value > 20 then value = 20 end
			s.Uniform = value
		end
	end			
	s.Uniform = list.Uniform or s.Uniform
	s.parent:setInfo(ms.amsMenu.uniform, ms.uniform.eventNumber, s.Uniform, listener);

end
---------------------------------------------------------------------

function eventList:getMixed()
	
	local s = self
	
	local function getEventList(id)
		-- The EventList property 
		--
		-- Valid values are:
		--   0 to 20 
		--   EXAMPLE: handle.EventList(3) =1;  
		--   EXAMPLE: handle.EventList=                            
		--            [1 2 3 4 5 6 7 8 9 0 11 12 13 14 15 16 17 18 19 20];
		--
		local function listener( value )
		--	if value then
		--		s.Mixed[id] = tonumber( value )
		--	end		
			value = tonumber( value )
			if value then 
				s.Mixed[id] = value
			else
				s.Mixed[id] = -1
			end
			
		end	
		s.parent:getInfo(ms.amsMenu.eventlist, ms.eventList[id], listener)

	end
	
	for m = 1, 20 do
		getEventList(m)
	end
end

function eventList:setMixed( list )
	
	local s = self
	list = list or { Uniform = 1, Mixed = {}}
	
	local function setEventList(id, value)
		local function listener( value )
			if value then
				s.Mixed[id] = tonumber( value )
			end		
		end		
		s.Mixed[id] = value
		s.parent:setInfo(ms.amsMenu.eventlist, ms.eventList[id], value, listener)
	end
	
	for m = 1, 20 do
		setEventList( m, list.Mixed[m] or s.Mixed[m] )
	end
end
---------------------------------------------------------------------

function eventList:get( list )
	local s = self
	s:getUniform()
	s:getMixed()
end

function eventList:set( list )
	local s = self
	if s.parent.getStatusTimer then
		timer.pause( s.parent.getStatusTimer )
	end	
	s:setUniform( list )
	s:setMixed( list )
	if s.parent.getStatusTimer then
		timer.resume( s.parent.getStatusTimer )
	end	
end

return eventList