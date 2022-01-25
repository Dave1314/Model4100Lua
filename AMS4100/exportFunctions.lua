-----------------------------------------------------------------------------------------
--
-- Filename: exportFunctions.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for exporting and data to Dropbox, Documents, e-mail, etc.
--
-----------------------------------------------------------------------------------------

local lfs = require( "lfs" )
local json = require("json")

local db = require( "dropboxOauthV2" )
--local ls = require( "loadsave" )
local md = require( "myData" )
local mf = require( "myFunctions" )

local platform = system.getInfo( "platformName" )

local _ = {}

function _.getPath( filename, location )
	local path
	if platform == "Mac OS X" then
		path = location .. "/" .. filename
	elseif platform == "Android" or platform == "iPhone OS" then
		path = location .. "/" .. filename
	else
		path = location .. "\\" .. filename
	end
	return path
end

function _.saveTable(t, filename, location)
	--Non-sandboxed implementation of saveTable
	local path = _.getPath( filename, location )

	local file = io.open(path, "w")
	if file then
		file:write( "AMS Model 4100 Configuration File\n" )
		local contents = json.encode(t, {indent=true})
		file:write( contents )
		io.close( file )
		return true
	else
		return false
	end
end

function _.loadTable(filename, location)
	--Non-sandboxed implementation of loadTable
	local path = _.getPath( filename, location )
	local myTable = {}
	local file = io.open( path, "r" )
	if file then
		-- read all contents of file into a string
		local contents = file:read( "*a" )
		myTable = json.decode(contents);
		io.close( file )
		return myTable
	end
	return nil
end

function _.generateFilename( settings )
	--Write out the file now
	local dateTime = os.date( "%Y%m%d-%H%M%S" )
	local filename = settings.Description .. "-"
	filename = filename .. dateTime .. ".ams4100"
	return filename

end

function _.getUserDirectory()
	if platform == "Win" then
		local userPath = os.getenv("appdata")
		local appDataStart = string.find( userPath, "AppData" )
		if( appDataStart ) then
			userPath = string.sub( userPath, 1, appDataStart-1 )
		end
		return userPath
	elseif platform == "Mac OS X" then
		local userPath = os.getenv("HOME")
		return userPath
	end
end

function _.getMyDocumentsDirectory()

	local newPath = ""
	if platform == "Win" then
		--newPath = _.getUserDirectory() .. "My Documents\\"
		newPath = _.getUserDirectory() .. "Documents\\"		
	elseif platform == "Mac OS X" then
		newPath = _.getUserDirectory() .. "/Documents/"
	end
	--Make sure the directory exists
	local cmd = lfs.chdir( newPath )
	if cmd then
		local cmd = lfs.chdir( newPath .. "AMS 4100" )
		if not cmd then
			--Didn't find an AMS 4100 folder, create one.
			lfs.chdir( newPath )
			lfs.mkdir( "AMS 4100" )
		end
		newPath = newPath .. "AMS 4100"
	end
	return newPath
end

function _.verifyDropboxAuthorization( p )
	--Check to see if dropbox has already been created.  If not attemp to do so.
	--Options passed into this function are passed directly on to getToken
	--Check for dropbox authorization
	--First see if an instance already exists
	if not _.db then
		local options = {
			appKey = md.dropbox.appKey,
			appKeySecret = md.dropbox.appKeySecret,
			tokenType = md.dropbox.tokenType,
			authCode = md.settings.dropboxAuthCode,
			accessToken = md.settings.dropboxAccessToken,
		}
		_.db = db.new( options )
	end
	--getToken checks to see if dropbox has already been authorized
	--If not it launches the authorization dialog and gets a new token
	_.db:getToken( p )

end

function _.getDropboxDirectory()

	local newPath = _.getUserDirectory()
	local sep
	if platform == "Win" then
		sep = "\\"
	elseif platform == "Mac OS X" then
		sep = "/"
	end

	if platform == "Win" or platform == "Mac OS X" then
		local dropboxPath = { "Dropbox", "Apps", "AMS 4100" }
		--Make sure the directory exists
		for m = 1, 3 do
			local cmd = lfs.chdir( newPath .. dropboxPath[m] )
			if not cmd then
				--Didn't find an AMS 4100 folder, create one.
				lfs.chdir( newPath )
				lfs.mkdir( dropboxPath[m] )
			end
			newPath = newPath .. sep ..dropboxPath[m]
		end
		return newPath
	else
		newPath = system.pathForFile( "dropboxTemp/", system.DocumentsDirectory )
		return newPath
	end
end

function _.clearDropboxTempDirectory()
	--Delete all the old files in the dropboxTemp directory
	local newPath = system.pathForFile( "dropboxTemp/", system.DocumentsDirectory )
	for filename in lfs.dir( newPath ) do
		if string.find( filename, ".ams4100" ) then
			--Read the first line of the file to verify it's a config file
			local path = _.getPath( filename, newPath )
			local file = io.open( path, "r" )
			if file then
				local contents = file:read( "*l" )
				--Strip off any control characters that might be there
				contents = contents:gsub( "%c", "" )
				if contents == "AMS Model 4100 Configuration File" then
					os.remove( path )
				end
			end
		end
	end
end

function _.loadDropboxTempDirectory()

	--The general flow for acquiring a directory listing is to get
	--an authorizaiton code first.  This authCode is used to get an
	--access token.  The access token is used in all subsequent
	--transactions and is stored in the system.Documents directory.
	--In this case the directory listing request is embedded in the
	--calback function passed to the authorization routine.  This allows
	--the directory listing ot be automatically called once the
	--authorization token has been received.
	local function getDropboxListing()

		--Get directory listing
		local function getListingResponse( response )
			-- Following line caused problem on Mac Corona Simulator
			mf.dprint("getMetaResponse Callback worked: ")
			mf.dprint( response )
			--Continuing the chain even further, the directory listing has
			--been retrieved so grab the files ending in ams4100 that are
			--under 10k.  Typical config files should be between 5-6k
			for m, entry in ipairs(response.entries) do
				mf.dprint( entry.filename )
				local function saveDownloadedFile( event )
					mf.dprint( event )
					local path = system.pathForFile( "", system.DocumentsDirectory )
					path = path .. "/dropboxTemp"
					--local filename = _.generateFilename( event )
					local filename = entry.name
					_.saveTable( event, filename, path )
				end

				if string.find( entry.name, ".ams4100" ) and entry.size < 10000 then
					local options = {
						filename = entry.name,
						folder = system.pathForFile( "", system.DocumentsDirectory ),
						listener = saveDownloadedFile,
					}
					_.db:download( options )
				end
			end
		end
		--Request the directory listing of the files currently online in
		--Dropbox/Apps/AMS 4100
		_.db:list_folder( {listener = getListingResponse} )
	end

	_.verifyDropboxAuthorization( {listener = getDropboxListing} )
end

function _.uploadDropboxFile( p )
  --Upload a file to Dropbox after a local copy has been stored.
  local function uploadFile()
    _.db:upload( p )
  end
  _.verifyDropboxAuthorization( {listener = uploadFile} )
end

function _.deleteDropboxFile( p )
  --Upload a file to Dropbox after a local copy has been stored.
  local function deleteFile()
    _.db:delete( p )
  end
  _.verifyDropboxAuthorization( {listener = deleteFile} )
end

function _.refreshDropboxTempDirectory()
	--Delete all the old files in the dropbox temp directory
	_.clearDropboxTempDirectory()
	--Now download the .ams4100 config files from online
	_.loadDropboxTempDirectory()
end

function _.removeFile( p )

  os.remove( p.folder .. "/" .. p.filename )

	if (platform == "Android" or platform == "iPhone OS") and md.state.fileview == "dropbox" then
		--We just saved a local copy, make sure we
		--upload it to the dropbox account as well
    --The actual upload is delay 0.5s to make sure the file has
    --been written.
      local options = {
        folder = system.pathForFile( "", system.DocumentsDirectory ),
        filename = p.filename
      }
      _.deleteDropboxFile( options )
	end
end

function _.dropboxExport( settings )
	local path = _.getDropboxDirectory()
	local filename = _.generateFilename( settings )
	_.saveTable( settings, filename, path )

	if platform == "Android" or platform == "iPhone OS" then
		--We just saved a local copy, make sure we
		--upload it to the dropbox account as well
    --The actual upload is delay 0.5s to make sure the file has
    --been written.
    local function delayedDropboxUpload()
      local options = {
        folder = path,
        filename = filename,
      }
      _.uploadDropboxFile( options )
    end
    timer.performWithDelay( 500, delayedDropboxUpload )
	end
end

function _.localExport( settings )
	local path = md.settings.activeDirectory
	local filename = _.generateFilename( settings )
	_.saveTable( settings, filename, path )
end

function _.internalSave( settings )
	local path = system.pathForFile( "", system.DocumentsDirectory )
	local filename = _.generateFilename( settings )
	_.saveTable( settings, filename, path )
end

function _.openNative( settings )
	--local path = system.pathForFile( "", system.DocumentsDirectory )
	--_.saveTable(settings, "AMS4100TemporarySettings.txt", path )
	--system.openURL( path .. "/AMS4100TemporarySettings.txt" )
	local path = system.pathForFile( "", system.TemporaryDirectory )
	local filename = _.generateFilename( settings ) .. ".txt"
	_.saveTable(settings, filename, path )
	
	system.openURL( path .. "/" .. filename )
end

function _.emailExport( settings )
	mf.dprint( "Exporting settings via e-mail.")

	local path = system.pathForFile( "emailTemp/", system.DocumentsDirectory )

	local filename = _.generateFilename( settings )
	_.saveTable( settings, filename, path )
	mf.dprint( path )

	if platform == "Win" then
		path = system.pathForFile( filename, system.DocumentsDirectory )
		system.openURL( '"mailto:?subject=AMS%204100&body="' .. path .. '"' )

	elseif platform == "Mac OS X" then
		--system.openURL( "mailto:nobody@mycompany.com" )
		--system.openURL( '"mailto:nobody@com.com&subject=AMS%204100&body="' .. path .. '"' )
		local urlToOpen = "mailto:?"
		urlToOpen = urlToOpen .. "subject=AMS%204100"
		urlToOpen = urlToOpen .. "&body=test"
--    urlToOpen = urlToOpen .. '&attachment="' .. path .. '"'
		mf.dprint(urlToOpen)
		system.openURL( "mailto:?subject=AMS%204100&body=test" )
	elseif platform == "Android" or platform == "iPhone OS" then
		local function sendMail()
			local options =
			{
				to = "",
				subject = "AMS 4100 Instrument Settings",
				body = "",
				attachment = {
					baseDir = system.DocumentsDirectory,
					filename = "emailTemp/" .. filename,
					type="text/text" }
			}
			mf.dprint( options )
			native.showPopup( "mail", options )
		end
		--Send the e-mail after a short delay.  Prevents a warning that the
		--attachment is only 0 bytes from displaying.
		timer.performWithDelay( 500, sendMail )
	end
end

return _