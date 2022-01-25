--AMS4100 handle Class for A-M systems Model 4100
--%   A Lua module to interface with A-M Systems Model 4100
--%   Instrument Amplifiers.
--%
--%  This is a wrapper function to handle multiple revs of the firmware.

local md = require( "myData" )

if md.state.AMS4100Rev == "Model 2101 rev 12 Sept 12, 2015" then
	return require( "ams4100-rev12.ams4100" )
elseif md.state.AMS4100Rev == "Model 4100_151123" then
	return require( "ams4100_151123.ams4100" )
else
	return require( "ams4100-M2F1.ams4100-main" )
end

