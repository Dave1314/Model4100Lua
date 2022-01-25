-----------------------------------------------------------------------------------------
--
-- Filename: myFunctions.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for handling general interactions such as purchases, ratings,
-- analytics, and analytics actions.
--
-----------------------------------------------------------------------------------------

local an = require( "analytics" )
local ls = require( "loadsave")
local md = require( "myData" )

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
--
-- NOTE: Code outside of listener functions (below) will only be executed once.
--
-----------------------------------------------------------------------------------------

local function print_r ( t )
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						print(indent..string.rep(" ",string.len(pos)+6).."}")
					elseif (type(val)=="string") then
						print(indent.."["..pos..'] => "'..val..'"')
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t,"  ")
		print("}")
	else
		sub_print_r(t,"  ")
	end
	print()
end

local _ = {}

_.lockIt = function( key )
	if key == "all" then
		for k,v in pairs( locked ) do
			locked[k] = true
		end
	elseif key == "push" then
		for k,v in pairs( locked ) do
			lockedState[k] = v
		end
	elseif key == "pop" then
		for k,v in pairs( lockedState ) do
			locked[k] = v
		end
	else
		locked[key] = true
	end
	--mf.dprint( locked )
end

_.unlockIt = function( key )
	if key == "all" then
		for k,v in pairs( locke ) do
			locked[k] = false
		end
	else
		locked[key] = false
	end
	--mf.dprint( locked )
end

_.isLocked = function()
	for k,v in pairs( locked ) do
		if v then return true end
	end
	return false
end

-- Debug print function.  Set debug false to disable output
_.dprint = function( data )

	local debug = md.debugPrint

	if debug then
		if type( data ) == "table" then
			print_r( data )
		else
			print( data )
		end
	end
	return

end

_.deepCopy = function(t)

	if type(t) ~= 'table' then return t end

	local mt = getmetatable(t)
	local res = {}

	for k,v in pairs(t) do
		if type(v) == 'table' then
			v = _.deepCopy(v)
		end
		res[k] = v
	end

	setmetatable(res,mt)

	return res
end

_.shallowCopy = function(t)

	if type(t) ~= 'table' then return t end

	local mt = getmetatable(t)
	local res = {}

	for k,v in pairs(t) do
		res[k] = v
	end

	setmetatable(res,mt)

	return res
end

_.logEvent = function( event )

	local params = {
		time = os.time() - md.settings.startTime,
	}

	_.dprint("Logging event: " .. event )
	_.dprint( params )
	local function logIt ()
		an.logEvent( event, params )
	end

	timer.performWithDelay( 100, logIt )

	return

end

_.rateApp = function()

	local deviceType = system.getInfo ( "platformName" )
	local deviceVersion = system.getInfo ( "platformVersion" )

	local urlPrefix = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id="
	local urlSuffix = "&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"

	if deviceType == "iPhone OS" then

		if string.find ( deviceVersion, "7.0" ) then
			system.openURL ( "itms-apps://itunes.apple.com/app/id" .. md.ids.apple )
		else
			system.openURL ( urlPrefix .. md.ids.apple .. urlSuffix )
		end

	elseif deviceType == "Android" then
		local options =
		{
			nookAppEAN = "com.jandjstudiosllc.pixum",
			androidAppPackageName = md.ids.google,
			supportedAndroidStores = { "google", "amazon", "nook" },
		}
		native.showPopup( "appStore", options )


	end
end

_.screenCap = function( event )
	local screenCap = display.captureScreen( true )
	display.remove (screenCap)
	screenCap = nil
	return true
end

--Calculate a frequency value for display on the UI with units
--The value passed in is actually the period in us so it needs
-- to be converted to frequency
_.calcDisplayFreq = function( value )

	local displayValue, units, scale
	local number = 1/(math.abs( tonumber(value) /1000000))

	if number > 999999 then
		scale = 1000000
		units = "MHz"
	elseif number > 999 then
		scale = 1000
		units = "kHz"
	else
		scale = 1
		units = "Hz"
	end
	number = number/scale
	displayValue = string.format( "%3.3f", number )
	displayValue = displayValue .. " " .. units
	--[[
	if scale > 1 then
		number = math.round( number/scale )
		displayValue = string.format( "%3.3f", number )
		displayValue = displayValue .. " " .. units
	else
		number = math.round( number )
		displayValue = string.format( "%3.0f", number )
		displayValue = displayValue .. " " .. units
	end
	--]]

	return displayValue, value/scale, units, scale
end

--Calculate a time value for display on the UI with units
_.calcDisplayTime = function( value )
	local displayValue, units, scale
	value = tonumber( value )
	if value > 999999 then
		scale = 1000000
		units = "s"
	elseif value > 999 then
		scale = 1000
		units = "ms"
	else
		scale = 1
		units = "µs"
	end
	if scale > 1 then
		displayValue = string.format( "%3.3f", value/scale )
		displayValue = displayValue .. " " .. units
	else
		displayValue = string.format( "%3.0f", value )
		displayValue = displayValue .. " " .. units
	end

	return displayValue, value/scale, units, scale
end

--Calculate a time value for display on the UI with units
_.calcDisplayAmps = function( value )
	local displayValue, units, scale
	local number = math.abs( tonumber(value) )
	if number > 999999 then
		scale = 1000000
		units = "A"
	elseif number > 999 then
		scale = 1000
		units = "mA"
	else
		scale = 1
		units = "µA"
	end
	if scale > 1 then
		displayValue = string.format( "%3.3f", value/scale )
		displayValue = displayValue .. " " .. units
	else
		displayValue = string.format( "%3.0f", value )
		displayValue = displayValue .. " " .. units
	end

	return displayValue, value/scale, units, scale
end

--Calculate a time value for display on the UI with units
_.calcDisplayVolts = function( value )
	local displayValue, units, scale
	local number = math.abs( tonumber(value) )

	if number > 999999 then
		scale = 1000000
		units = "V"
	elseif number > 999 then
		scale = 1000
		units = "mV"
	else
		scale = 1
		units = "µV"
	end
	if scale > 1 then
		displayValue = string.format( "%3.3f", value/scale )
		displayValue = displayValue .. " " .. units
	else
		displayValue = string.format( "%3.0f", value )
		displayValue = displayValue .. " " .. units
	end

	return displayValue, value/scale, units, scale
end

_.calcTime = function( t1, t2, startValue )

	--[[
	local event = ams.Event[ams.LibID]
	local timeDivisor = 1
	if event.timeUnits == "mS" then
		timeDivisor = 1000
	elseif event.timeUnits == "S" then
		timeDivisor = 1000000
	end
	--]]
	local newValue = (t2-t1)/md.state.timeScale - startValue

	--Scale the value for the appropriate timestep
	newValue = math.round( newValue/md.settings.timeSteps ) * md.settings.timeSteps + startValue
                 
	if newValue > 93600000000 then
		newValue = 93600000000
	--elseif newValue < 1 then
	--	newValue = 1
	elseif newValue < 0 then
		newValue = 0
	end

	return math.round( newValue )
end

_.calcAmplitude = function( a1, a2, startValue )

	--[[
	local event = ams.Event[ams.LibID]
	local ampDivisor = 1
	if event.ampUnits == "mV" or event.ampUnits == "mA" then
		ampDivisor = 1000
	elseif event.ampUnits == "V" then
		ampDivisor = 1000000
	end
	--]]
	local newValue = (a2-a1)/md.state.ampScale - startValue

	newValue = math.round( newValue/md.settings.ampSteps ) * md.settings.ampSteps + startValue

	if newValue > 200000000 then
		newValue = 200000000
	elseif newValue < -200000000 then
		newValue = -200000000
	end

	return math.round( newValue )
end

return _