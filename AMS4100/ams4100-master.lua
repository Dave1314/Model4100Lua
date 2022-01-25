-------------------------------------------------
--
-- ams4100-master.lua
--
-- "ams4100-master" class for ams 4100
-- Brings together all lower level classes for config, train,
-- event, and eventList classes
--
-------------------------------------------------
local ls = require("loadsave")

local master = {}
local master_mt = { __index = master}	-- metatable

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

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function master.new( params )	-- constructor

	local p = params or {}
		
	local path = p.path or "ams4100-M2F1."
	local ams = require( path .. "ams4100-main" )
	--"ams4100-M2F1.ams4100-main" )
	local newMaster= {
		--Instrument settings
		active = {},
		stored = {},
	}
	
	--Always start with at least one active profile
	newMaster.active[1] = ams.new()
	
	--Create eight profiles to represent saved slots.
	for m = 1, 8 do 
		--newMaster.stored[m] = ams.new()
	end
	
	return setmetatable( newMaster, master_mt )
end

---------------------------------------------------------------------

function master:loadSettings()
--Load the stored settings and create instances for each 
--restored block of settings

	local s = self
	
	local savedSettings
	if ls.doesFileExist("instrumentSettings.json", system.DocumentsDirectory) then
		savedSettings = ls.loadTable("instrumentSettings.json", 	system.DocumentsDirectory)
		--The original save file stored a single block in .current.  Check there first,
		--if it doesn't exist assume this is the newer version of the settings file  
		--which stored the settings for multiple instruments in .active[m].
		if savedSettings.current then
			s.active[1]:setMenuVals( savedSettings.current )
			--Check to see if the IP address is availble in the original settings file		
			--Check to see if a settings file exists, if so load it and restore the settings
			if ls.doesFileExist("settings.json", system.DocumentsDirectory) then
				local settings = ls.loadTable("settings.json", system.DocumentsDirectory)
				if settings.ipaddress then
					s.active[1].connection.address = settings.ipaddress
				end		
			end
		else			
			for m = 1, #savedSettings.active do
				if m > 1 then
					s:addActive()
				end				
				s.active[m]:setMenuVals( savedSettings.active[m] )
				s.active[m].connection.address = savedSettings.active[m].connection.address
				s.active[m].connection.port = savedSettings.active[m].connection.port
			end
		end
		
		--Similarily the saved files were originally in a table called saved.  
		--With the new app version it was changed to stored.
		--Adding dropbox and local file export negated the need to limit
		--storing files internally in instrumentSettings.  Instead export them 
		--to the sandboxed storage area so they can be read on the Home scene.
		if savedSettings.saved then
			for m = 1, #savedSettings.saved do
				--s.stored[m]:setMenuVals( savedSettings.saved[m] )
				local ef = require( "exportFunctions" )
				ef.internalSave( savedSettings.saved[m] )
			end			
		elseif savedSettings.stored then
			for m = 1, #savedSettings.stored do
				--s.stored[m]:setMenuVals( savedSettings.stored[m] )
				local ef = require( "exportFunctions" )
				ef.internalSave( savedSettings.stored[m] )
			end
		else
			--Do nothing, there were no saved or stored files detected.
		end	
	else
		--No settings file existed so this must be the first time the app has launched
		--Load the default instrument settings.
		if ls.doesFileExist("AMS4100TemporarySettings.ams4100", system.ResourceDirectory) then
			local newSettings = ls.loadTable("AMS4100TemporarySettings.ams4100", system.ResourceDirectory)
			s.active[ 1 ]:setMenuVals( newSettings )
		end
	end
end

function master:setTriggerNoneAll()
	--Send the stop signal to all connected instruments
	local s = self
		mf.dprint("setTriggerNoneAll called")
	
	for i, v in ipairs( s.active ) do
		v:TriggerNone()
		v.client:send( "s t n\r\n" )
	end
end

function master:setRelayClosedAll()
	--Send the stop signal to all connected instruments
	local s = self
	
	for i, v in ipairs( s.active ) do
		v:CloseRelay()
	end
end

function master:storeSettings()
--Extract the settings from all instances and save them
--ignoring extraneous data like the message buffers

	local s = self
	--Create the table for holding the settings before saving them
	local settings = {
		date = os.date( "%Y%m%d-%H%M%S" ),
		version = require("myData").state.revision,
		build = system.getInfo( "build" ),
		platformName = system.getInfo( "platformName" ),
		active = {},
		stored = {},
		}
	
	for i, v in ipairs( s.active ) do
		settings.active[i] = v:getSettings()
	end
	
	--Stored settings are now saved indiviually, don't write them out 
	--as part of the larger instrumentSettings file anymore
	--[[
	for i, v in ipairs( s.stored ) do
		settings.stored[i] = v:getSettings()
	end	
	--]]	
	ls.saveTable( settings, "instrumentSettings.json", system.DocumentsDirectory)	

end

---------------------------------------------------------------------

function master:addActive()
--Create a new active instance of an instrument representation	

	local s = self
	local path = "ams4100-M2F1."
	local ams = require( path .. "ams4100-main" )
	
	s.active[ #s.active+1 ] = ams.new()
	s.active[ #s.active ]:startComms()
end

function master:removeActive( index )
--Remove an active instance of an instrument representation

	local s = self
	index = index or #s.active
	if #s.active > 1 then 
		table.remove( s.active, index )
	end	

end


---------------------------------------------------------------------

function master:addStored()
--Create a new active instance of an instrument representation	

	local s = self
	local path = "ams4100-M2F1."
	local ams = require( path .. "ams4100-main" )
	
	s.stored[ #s.stored+1 ] = ams.new()
	
end

function master:removeStored( index )
--Remove an active instance of an instrument representation

	local s = self
	index = index or #s.active
	if #s.stored > 0 then 
		table.remove( s.stored, index )
	end	

end

---------------------------------------------------------------------

function master:copyActive()
	
end

function master:setCurrent()
	
end



return master