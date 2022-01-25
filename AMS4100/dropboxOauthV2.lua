-------------------------------------------------
--
-- dropboxOauthV2.lua
--
-- Authenticate and provides access to Dropbox using oauth2
--
-- # Heading1
--
-------------------------------------------------

local json = require( "json" )
--local lfs = require( "lfs" )
local mime = require( "mime" )
local network = require( "network" )
local mf = require( "myFunctions" )

local dropbox = {}
local dropbox_mt = { __index = dropbox}	-- metatable

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------

-- The following sample code contacts Google's encrypted search over SSL
-- and mf.dprints the response (in this case, the HTML source of the home page)
-- to the Corona terminal.

local function responseToTable( str, delimiters )

  local obj = {}

  while str:find(delimiters[1]) ~= nil do
    if #delimiters > 1 then
      local key_index = 1
      local val_index = str:find(delimiters[1])
      local key = str:sub(key_index, val_index - 1)

      str = str:sub((val_index + delimiters[1]:len()))

      local end_index
      local value

      if str:find(delimiters[2]) == nil then
      end_index = str:len()
      value = str
    else
    end_index = str:find(delimiters[2])
    value = str:sub(1, (end_index - 1))
    str = str:sub((end_index + delimiters[2]:len()), str:len())
  end
  obj[key] = value
  --mf.dprint(key .. ":" .. value)		-- **debug
else

  local val_index = str:find(delimiters[1])
  str = str:sub((val_index + delimiters[1]:len()))
  local end_index
  local value

  if str:find(delimiters[1]) == nil then
  end_index = str:len()
  value = str
else
end_index = str:find(delimiters[1])
value = str:sub(1, (end_index - 1))
str = str:sub(end_index, str:len())
end
obj[#obj + 1] = value
end
end
return obj
end

-- Deletes a token from file.
local function deleteToken( tokenType )

  local path = system.pathForFile( tokenType, system.DocumentsDirectory )
  os.remove( path )

end

-- Loads a token from file.
local function loadToken( tokenType )
  local saveData = ""
  local path = system.pathForFile( tokenType, system.DocumentsDirectory )
  local file = io.open( path, "r" )
  if file then
    saveData = file:read( "*a" )
    io.close( file )
  end
  file = nil
  return saveData
end

-- Saves a token to file.
local function storeToken( tokenType, data )
  local path = system.pathForFile( tokenType, system.DocumentsDirectory )
  local file = io.open( path, "w" )
  file:write( data )
  io.close( file )
  file = nil
end

-- Wrapper function to process callbacks from Dropbox
local function dropboxListener( event, listener )
  if ( event.isError ) then
    mf.dprint( "Network error!")		
  else
    mf.dprint( "dropboxListener response: " )		
    --Decode the response and send it to the listener function if provided
    if listener then
      --Catch a config file being downloaded by checking the first line
      --Basically just need to strip out the header line
      if string.find( event.response, "AMS Model 4100 Configuration File" ) then
        local startPos = string.find( event.response, "{" )
        event.response = string.sub(event.response, startPos )
      end        
      local decodedFile, pos, msg = json.decode( event.response )
      if not decodedFile then
        mf.dprint( "Decode failed at "..tostring(pos)..": "..tostring(msg) )
      end      
      listener( decodedFile )
    end		
  end
  mf.dprint( event.response )
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------
function dropbox.new( p )	-- constructor

  p = p or {}

  local newDropbox= {

    appKey = 			p.appKey 			or "key",
    appKeySecret = 	p.appKeySecret 	or "secret",
    authCode = 			p.authCode 			or "authorization code",
    accessToken = 		p.accessToken 		or "",
    tokenType = 		p.tokenType 		or "",
    uid = 				p.uid 				or "",
    accountID = 		p.accountID 		or "",
    tokenFileName =	p.tokenFileName 	or "dropboxV2accessToken",
  }

  --Store the options if a copy of this config needs to be created
  newDropbox.options = p

  return setmetatable( newDropbox, dropbox_mt )
end

---------------------------------------------------------------------
--authorize launches a webview that allows the user to ok the app
--having access to their dropbox account
function dropbox:authorize( p )

  local s = self
  p = p or {}

  s.appKey = p.appKey or s.appKey
  s.appKeySecret = p.appKeySecret or s.appKeySecret
  s.authCode = p.authCode or s.AuthCode

  local URI = "https://www.dropbox.com"

  local url = "https://www.dropbox.com/oauth2/authorize?client_id=" 
  .. s.appKey .."&response_type=token&redirect_uri=" .. URI

  local platform = system.getInfo( "environment" )
  local platformName = system.getInfo( "platformName" )

  if platform == "simulator" and platformName == "Win" then
    url = "https://www.dropbox.com/oauth2/authorize?client_id=" 
    .. s.appKey .."&response_type=code"
    system.openURL( url )
  else
    local webView
    local function webListener( event )
      if event.url then
        mf.dprint( "You are visiting: " .. event.url )

        local response = responseToTable( event.url, { "=", "&"} )
        mf.dprint(response)

        local access_token = response["https://www.dropbox.com/#access_token"]
        if access_token then
          webView:removeSelf()
          webView = nil
          s.accessToken = access_token
          storeToken( s.tokenFileName, access_token )
          if platform == "Android" then
            native:setKeyboardFocus()
          end
          --Optional callback to process another command after the 
          --token is received
          if p.listener then
            p.listener()
          end          
        end				
      end

      if event.type then
        mf.dprint( "The event.type is " .. event.type ) -- mf.dprint the type of request
      end

      if event.errorCode then
        native.showAlert( "Error!", event.errorMessage, { "OK" } )
      end

      mf.dprint( event )
    end

    local sW = display.contentWidth
    local sH = display.contentHeight
    webView = native.newWebView( sW/2, sH/2, sW, sH )
    webView:request( url )

    webView:addEventListener( "urlRequest", webListener )
  end
end

---------------------------------------------------------------------
--[[
requestToken(app key, app secret, authorization code)
requests the oath2 token, using fa.request().
returns the token, or nil on a failure.
--]]
function dropbox:requestToken(p)

  local s = self
  p = p or {}

  local listener = p.listener
  s.appKey = p.appKey or s.appKey
  s.appKeySecret = p.appKeySecret or s.appKeySecret
  s.authCode = p.authCode or s.authCode

  --Combine our app's key and secret'
  local authorization = (mime.b64(s.appKey..":"..s.appKeySecret))

  local url = "https://api.dropboxapi.com/oauth2/token"
  local method = "POST"

  local body = "grant_type=authorization_code&code=".. s.authCode	
  local params = {
    headers = {
      ["Authorization"] = "Basic " .. authorization,
      ["Content-Type"] = "application/x-www-form-urlencoded"},
    body = body,
  }

  local function localListener( event )
    dropboxListener( event, listener )
  end

  --Request a token	
  return network.request( url, method, localListener, params )

end
---------------------------------------------------------------------
--[[
revokeToken(app key, app secret, authorization code)
requests the oath2 token, using fa.request().
returns the token, or nil on a failure.
--]]
function dropbox:revokeToken(p)

  local s = self
  p = p or {}

  local listener = p.listener
  s.appKey = p.appKey or s.appKey
  s.appKeySecret = p.appKeySecret or s.appKeySecret
  s.authCode = p.authCode or s.AuthCode

  local url = "https://api.dropboxapi.com/2/auth/token/revoke"
  local body = json.encode()
  local method = "POST"

  local params = {
    headers = {
      ["Authorization"] = "Bearer " .. s.accessToken,
      ["Content-Type"] = "application/json"},
    body = body,
  }

  local function localListener( event )
    deleteToken( s.tokenFileName )
    dropboxListener( event, listener )
  end

  --Request a token	
  return network.request( url, method, localListener, params )

end
---------------------------------------------------------------------

--This function determines if an access token already exists or if
--a new one needs to be generated.  If it needs to be generated the
--authorization is called first then requestToken is called.
function dropbox:getToken( p )

  local s = self

  p = p or {}

  s.appKey = p.appKey or s.appKey
  s.appKeySecret = p.appKeySecret or s.appKeySecret
  s.authCode = p.authCode or s.AuthCode

  local accessToken = loadToken( s.tokenFileName )

  if accessToken == "" then
    s:authorize( p )
  else
    s.accessToken = accessToken
    if p.listener then
      p.listener()
    end    
  end

  return accessToken

end
---------------------------------------------------------------------
--[[ Sends a file to Dropbox.
function dropbox:upload( p )

  local s = self
  p = p or {}

  local listener = p.listener
  local folder = p.folder or ""
  local filename = p.filename or ""
  local path = folder .. "/" .. filename

  filename = "test.ams4100"
  
  local dropboxAPIArg = json.encode({
      path = path,
      mode = "add",
      autorename = true,
      mute = false,
    })

  local url = "https://content.dropboxapi.com/2/files/upload"
  local method = "POST"	
  local params = {
    headers = {
      ["Authorization"] = "Bearer " .. s.accessToken,
      ["Content-Type"] = "application/octet-stream",
      ["Dropbox-API-Arg"] = dropboxAPIArg,
    },
    body = {
      --filename = filename,
      --baseDirectory = folder,
    },
  }

  local function localListener( event )
    dropboxListener( event, listener )
  end

  return network.request( url, method, localListener, params )

end --]]

---------------------------------------------------------------------
-- Sends a file to Dropbox.
function dropbox:upload( p )

	local s = self
	p = p or {}

	local listener = p.listener
	local folder = p.folder or ""
	local filename = p.filename or ""
	local path = folder .. filename

	local dropboxAPIArg = json.encode({
			path = "/" .. filename,
			mode = "add",
			autorename = true,
			mute = false,
		})

	local url = "https://content.dropboxapi.com/2/files/upload"
	local method = "POST"	
	local params = {
		headers = {
			["Authorization"] = "Bearer " .. s.accessToken,
			["Content-Type"] = "application/octet-stream",
			["Dropbox-API-Arg"] = dropboxAPIArg,
		},    
		body = {
			filename = filename,
			baseDirectory = folder,
		},
	}

	local function localListener( event )
    if ( event.isError ) then
      mf.dprint( "Network error" )
    else
      if event.phase == "began" then
        mf.dprint( "Upload started." )
      elseif event.phase == "progress" then
        mf.dprint( "Uploading....  Bytes transferred: " .. event.bytesTransferred )
      elseif event.phase == "ended" then
        mf.dprint( "Upload finished" )
        mf.dprint( "Event Status: " .. event.status )
        mf.dprint( "Event Response: " .. event.response )
        dropboxListener( event, listener )
      end      
    end
	end
  
  return network.upload( url, method, localListener, params, "dropboxTemp/" .. filename, system.DocumentsDirectory )

end
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Sends a file to Dropbox.
function dropbox:delete( p )

	local s = self
	p = p or {}

	local listener = p.listener
	local folder = p.folder or ""
	local filename = p.filename or ""
	local path = folder .. filename

	local body = json.encode({
			path = "/" .. filename,
		})

	local url = "https://api.dropboxapi.com/2/files/delete"
	local method = "POST"	
	local params = {
		headers = {
			["Authorization"] = "Bearer " .. s.accessToken,
			["Content-Type"] = "application/json",			
		},    
    body = body,
	}

	local function localListener( event )
    if ( event.isError ) then
      mf.dprint( "Network error" )
    else
      if event.phase == "began" then
        mf.dprint( "Upload started." )
      elseif event.phase == "progress" then
        mf.dprint( "Uploading....  Bytes transferred: " .. event.bytesTransferred )
      elseif event.phase == "ended" then
        mf.dprint( "Upload finished" )
        mf.dprint( "Event Status: " .. event.status )
        mf.dprint( "Event Response: " .. event.response )
        dropboxListener( event, listener )
      end      
    end
	end
  
  return network.request( url, method, localListener, params )

end
---------------------------------------------------------------------
function dropbox:list_folder( p )

  local s = self
  p = p or {}

  local folder = p.folder or ""

  local listener = p.listener

  local url = "https://api.dropboxapi.com/2/files/list_folder"
  local method = "POST"	
  local body = json.encode( {path = ""} )
  local params = {
    headers = {
      ["Authorization"] = "Bearer " .. s.accessToken,
      ["Content-Type"] = "application/json",
    },
    body = body,
  }

  local function localListener( event )
    dropboxListener( event, listener )
  end

  return network.request( url, method, localListener, params )
end
---------------------------------------------------------------------
function dropbox:download( p )

  local s = self
  p = p or {}

  local listener = p.listener
  local folder = p.folder or ""
  local filename = p.filename or ""
  local path = folder .. filename

  local url = "https://content.dropboxapi.com/2/files/download"
  local method = "GET"	

  local dropboxAPIArg = json.encode({
      path = "/" .. filename,
    })

  local params = {
    headers = {
      ["Authorization"] = "Bearer " .. s.accessToken,
      ["Dropbox-API-Arg"] = dropboxAPIArg,			
    },
  }

  local function localListener( event )
    dropboxListener( event, listener )
  end

  --Request a token	
  return network.request( url, method, localListener, params )
end
---------------------------------------------------------------------
---------------------------------------------------------------------
return dropbox