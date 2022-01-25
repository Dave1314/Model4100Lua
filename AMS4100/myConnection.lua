-----------------------------------------------------------------------------------------
--
-- Filename: myConnected.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for handling functions specific to supporting the TCP/IP
-- protocol for communicating with the instrument.
--
-----------------------------------------------------------------------------------------

local mf = require( "myFunctions" )
local socket = require( "socket" )

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
--
-- NOTE: Code outside of listener functions (below) will only be executed once.
--
-----------------------------------------------------------------------------------------

local connection = {}
local connection_mt = { __index = connection } --metatable

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

local function dprint( stuff )
	local localDebug = false
	if localDebug then
		mf.dprint( stuff )
	end
end

function connection.new( p )	-- constructor

	p = p or {}

	local newConnection= {
		address = p.address or "127.0.0.1",
		port = p.port or 23,
		sendBuffer = {},
--		receiveBuffer = {},
		sendTimeout = 15,
		connected = false,
		commsInProgress = false,
		client = socket.tcp(),
		numSendTries = 0,
		numReceiveTries = 0,
		elapsedTime = system.getTimer(),
		timeout = false,
	}
	return setmetatable( newConnection, connection_mt )
end

---------------------------------------------------------------------


function connection:sendReceive( params )

	local s = self
	local data, status, partial

	--[[
	if md.state.appResumed then
		--If the app just restarted from being suspended break the connection
		--and clear the send buffer
		dprint( "Restarting network connection." )
		md.state.appResumed = false
		md.state.connected = false
		md.state.commsInProgress = false
		md.state.sendBuffer = {}
		_.client:close()
		_.client = socket.tcp()
	end
	--]]

	--If no comms are in progress try sending the top message in the buffer
	if s.connected then

		if s.commsInProgress then
			--Comms are in progress so try reading data out of the buffer
			s.client:settimeout( 0 )
			data, status, partial = s.client:receive("*l")
			s.timeout = false
			while data do
				--Resend the command, the instrument didn't understand it
				dprint( "Raw response: " .. data )
				if data == "?" then
					s.commsInProgress = false
				elseif data == "Bad Pin" then
					--Remove this command from the queue and process the next one
					table.remove( s.sendBuffer, 1)
					s.numSendTries = 0
					s.numReceiveTries = 0
					s.commsInProgress = false
				elseif data == "*" then
				--Pop the top message off the queue and indicate end of comms
					local valueText = s.sendBuffer[1].value
					if s.sendBuffer[1].value == nil then
						valueText = "NA"
					end

					dprint( "Connection: " .. s.address )
					local address, port = s.client:getsockname()
					dprint( "Address: " .. address .. " Port: " .. port )
					local bytesReceived, bytesSent, age = s.client:getstats()
					dprint( "Received: " .. bytesReceived .. " Sent: " .. bytesSent .. " Age: " .. age )
					dprint( "Message:  " .. s.sendBuffer[1].message)
					if s.sendBuffer[1].response then
						dprint( "Response: " .. s.sendBuffer[1].response)
					end
					if s.sendBuffer[1].value then
					dprint( "Value:    " .. s.sendBuffer[1].value)
					end
					dprint()

					--Make sure a response was received
					if s.sendBuffer[1].response then
						--Verify the response matches the command that was sent
						if s.sendBuffer[1].message == s.sendBuffer[1].response then
							--Send the value to the listener function if it exists
							if s.sendBuffer[1].listener then
								if s.sendBuffer[1].value then
									if string.find( s.sendBuffer[1].message, "g a") or
										string.find( s.sendBuffer[1].message, "g c") or
										string.find( s.sendBuffer[1].message, "g r") or
										string.find( s.sendBuffer[1].message, "s a r") then
											s.sendBuffer[1].listener( s.sendBuffer[1].value )
									else
										local value = tonumber( s.sendBuffer[1].value )
										if value then
											s.sendBuffer[1].listener( value )
										else
											dprint( "Nil value received.")
										end
									end
								else
									s.sendBuffer[1].listener()
								end
							end
							--Remove this command from the queue and process the next one
							table.remove( s.sendBuffer, 1)
							s.numSendTries = 0
							s.numReceiveTries = 0
							s.commsInProgress = false
						end
					end

				--Process the returned message and stuff it in the right ams4100 slot
				elseif data == s.sendBuffer[1].message then
					--Store the response from the instrument
					s.sendBuffer[1].response = data
				else
					s.sendBuffer[1].value = data
				end
				data, status, partial = s.client:receive("*l")
				--If there are no more commands we're expecting to receive data for
				--break out of the loop.
				if not s.sendBuffer[1] then
					break
				end
			end

			if status == "closed" then
				s.connected = false
				s.timeout = false
				dprint( "Connection closed." )
				s.client:close()
				s.client = socket.tcp()
			elseif status == "timeout" then

				if s.numReceiveTries > 0 then
					dprint( "Connection timed out." .. " " .. s.numSendTries .. " "
						.. s.numReceiveTries )
					dprint( data )
					dprint( status )
					dprint( partial )
					--Indicate that we've had many successive timeouts so
					--the top bar indicator turns black.
					if s.numReceiveTries > 20 then
						s.timeout = true
					end
				end
				--Try 5 times to receive the response.  If nothing then try sending it again.
				s.numReceiveTries = s.numReceiveTries + 1
				--Changing menus can take a second or two.  Set this high so we have a 2
				--second window to try and ride through it.
				if s.numReceiveTries > 200 then
					s.numReceiveTries = 0
					s.numSendTries = s.numSendTries + 1
					--md.state.commsInProgress = false
					s.connected = false
					s.timeout = false
					s.client:close()
					s.client = socket.tcp()
				end
			else
				s.timeout = false
				dprint( "No data available." )
			end
		end

		--If we successsfully received a block of data try sending the next one
		if not s.commsInProgress then
			if #s.sendBuffer > 0 then
				--if _.numSendTries < 7 then
				if s.numSendTries < 5 then
					s.commsInProgress = true
					s:clearReceiveBuffer()
					s.client:settimeout( 0 )

					---[[
					local index = 1
					local message = ""
					local length = string.len( message )
					--The number of messages sent can easily be increased by changing the
					--threshold below.  Right now it is set at 1 so only a single message
					--is transmitted on each cycle.  The 4100 can't handle more than that
					--right now.
					while string.len( message ) < 1 do

						message = message .. s.sendBuffer[index].message .. "\r\n"
						index = index + 1
						if not s.sendBuffer[index] then
							break
						end
					end
						data, status, partial = s.client:send( message )
						dprint( "Message sent: " .. message )

					--]]
				else  --Give up on sending this message, assume connection lost?
					--Tried to send 5 times and receive ~30.  Give up and reconnect.
					s.connected = false
					s.client:close()
					s.client = socket.tcp()

				end
			else
				--Nothing in the buffer

			end
		end
		s.elapsedTime = system.getTimer()
		timer.performWithDelay( 15, function() s:sendReceive( params ) end, 1 )
	else
		params = {
			address = s.address,
			port = s.port,
			}
		s:connect( params )
		timer.performWithDelay( 2000, function() s:sendReceive( params ) end, 1 )
	end
end

function connection:connect( params )

	local s = self
	local p = params or {}

	local connected, data, err = false, "", "Invalid address."
	s.address = p.address or s.address
	s.port = p.port or s.port

	local startTime = system.getTimer()

	--Check to make sure the address is valid
	local address = s.address:split( "%." )
	local validAddress = true
  
	for m = 1, 4 do
		local addressSegment = tonumber( address[m] )
		if addressSegment then
			if addressSegment >= 0 and addressSegment <= 255 then
				--Do nothing, this is a valid address segment
			else
				--This is not a valid address segment
				validAddress = false
			end
		else
			--Address segment did not exist, this is not a valid segment
			validAddress = false
		end
	end

	if validAddress then
		s.client:settimeout( 0.100 )
		data, err = s.client:connect( s.address, s.port )
		if data == 1 then
			s.connected = true
		else
			s.connected = false
		end
		--local connected, err = false, "Disabled."
		local endTime = system.getTimer()
		local deltaT = endTime - startTime
		dprint( "Client created, attempting to connect. Elapsed time: " .. deltaT )
	else

	end

	if s.connected then
		dprint( "Connected to instrument: "  .. s.address )
		s.connected = true
		s.commsInProgress = false
		s.numSendTries = 0
		s.numReceiveTries = 0
		s.client:settimeout( 0 )
		s.client:setoption( "tcp-nodelay", true )
		--Try sending a couple carriage return/line feeds to clear the remote buffer
		s.client:send( "\r\n\r\n" )
		s.parent:getSerialNumber()
		s.parent:getRevision()
	else
		s.connected = false
		dprint( "No connection available: " .. err )
		dprint( err )
		s.client:close()
		s.client = socket.tcp()
	end

end

function connection:clearReceiveBuffer()
	local s = self
	if s.connected then
		local data, status, partial = s.client:receive("*l")
		local message
		while data do
			message = data or partial
			if message then
				dprint( message )
			end
			data, status, partial = s.client:receive("*l")
		end
	end
end

function connection:reconnect()
	local s = self
	if s.connected then
		s.connected = false
		dprint( "Reconnecting to instrument." )
		s.client:close()
		s.client = socket.tcp()
		s:clearReceiveBuffer()
	end
end

return connection