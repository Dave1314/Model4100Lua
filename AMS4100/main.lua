

--require("lib.Helper")
local md = require( "myData" )
local mf = require( "myFunctions" )

local ls = require("loadsave")
local composer = require( "composer" )
local analytics = require "analytics"
local socket = require( "socket" )
local lfs = require( "lfs" )

---[=[ Debugging functions.  Comment this block out for final build

local platform = system.getInfo( "environment" )

if platform == "simulator" then
	require('mobdebug').start()
end

md.debugPrint = false
--local perf = require( "PerformanceWatch" )
--perf.new()

--[[
local screenCapRect = display.newRect( 0, 0, 250, 250)
screenCapRect.alpha = 0
screenCapRect.isHitTestable = true
screenCapRect:addEventListener( "tap", mf.screenCap )
--]]
--]=]

md.amsMaster = require( "ams4100-master" ).new()
local ams = md.instrumentSettings

md.instrumentSettings.current = md.amsMaster.active[1]
md.instrumentSettings.current.InstrumentName =
	md.instrumentSettings.current.InstrumentName .. " - 1"
md.instrumentSettings.current.Description =
	md.instrumentSettings.current.Description .. " - Current"

local function onKeyEvent( event )

	local phase = event.phase
	local keyName = event.keyName

	if "back" == keyName and phase == "up"  then
		local prevScene = composer.getSceneName( "previous" )
		composer.gotoScene( prevScene )
		--native.requestExit()
		return false  --SEE NOTE BELOW

	end
end

local function onMouseEvent( event )
	--Capture the state of the mouse on a mouse event so it can be
	--used to determine if a help text event should be initiated.
	md.state.mouse.name = event.name
	md.state.mouse.x = event.x
	md.state.mouse.y = event.y
	md.state.mouse.time = event.time
	md.state.mouse.primaryButtonDown = event.isPrimaryButtonDown
	md.state.mouse.secondaryButtonDown = event.isSecondaryButtonDown
	md.state.mouse.middleButtonDown = event.isMiddleButtonDown

	--Return false so this doesn't interfere with other event handlers
	return false
end

local function onResize( event )

	if 1 then
		mf.dprint( "Resize event detected." )
		mf.dprint( event )
	end

	md.contentW = md.screenW
	md.contentH = md.screenH

	--If it gets too skinny shrink the height
	if md.contentH/md.contentW > 2/3 then
		md.contentH = 2*md.contentW/3
	end

	md.tileW = 0.95*md.contentW/6
	md.defaultFontSize = 0.0175*md.contentW
	local currentScene = composer.getSceneName( "current" )
	--composer.gotoScene( currentScene )

end

local function onAccelerate( event )
	if md.settings.highlights then
		md.state.x = -event.xGravity or 0
		md.state.y = -event.yGravity or 1
		md.state.z = 0.6 --math.abs(event.zGravity) or 1
	else
		md.state.x = 0
		md.state.y = 1
		md.state.z = 0.6
	end
end

local function onSystemEvent( event )
	if event.type == "applicationStart" then

		-- this block executed when application launches (after main.lua)

	elseif event.type == "applicationExit" then

		-- this block executed just prior to the app quitting
		-- OS closes least recently used app, user explicitly quits, etc.
		mf.dprint( "onSystemEvent applicationExit event detected." )
		
		--md.amsMaster:setTriggerNoneAll()
		--smd.amsMaster:setRelayClosedAll()
		md.amsMaster:storeSettings()

	elseif event.type == "applicationSuspend" then

		-- this block executed when app goes into “suspend” state
		-- e.g. user receives phone call, presses home button, etc.
		md.amsMaster:storeSettings()

	elseif event.type == "applicationResume" then

		-- this block executed when app resumes from “suspend” state
		-- e.g. user goes back into app (while it is still running in bg)
		md.state.appResumed = true
		md.state.allowHighVoltage = false
	end
end

function string:split( inSplitPattern, outResults )

	if not outResults then
		outResults = { }
	end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	while theSplitStart do
		table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
	end
	table.insert( outResults, string.sub( self, theStart ) )
	return outResults
end

local function main()

	mf.dprint( "main entered." )
	display.setStatusBar( display.HiddenStatusBar )
	math.randomseed( os.time() )

	if system.getInfo( "gpuSupportsHighPrecisionFragmentShaders" ) then
		mf.dprint( "High precision shader supported"  )
	else
		mf.dprint( "High precision shader NOT supported"  )
	end

	--Make sure the dropboxTemp and emailTemp directories exist
  local path = system.pathForFile( "", system.DocumentsDirectory )
  lfs.chdir( path )
  if not lfs.chdir( path .. "/dropboxTemp") then
    lfs.mkdir( "dropboxTemp" )
  end
  if not lfs.chdir( path .. "/emailTemp") then
    lfs.mkdir( "emailTemp" )
  end
	mf.dprint( "Initializing settings file." )
	
	local ef = require("exportFunctions")
	--Check to see if a settings file exists, if so load it and restore the settings
	if ls.doesFileExist("settings.json", system.DocumentsDirectory) then
		local settings = ls.loadTable("settings.json", system.DocumentsDirectory)
		for k,v in pairs(settings) do
			md.settings[k] = v
		end
		if md.settings.activeDirectory == "" then
			md.settings.activeDirectory = ef.getMyDocumentsDirectory()			
		end
	else
		--If not create a new one from scratch
		md.settings.activeDirectory = ef.getMyDocumentsDirectory()
		ls.saveTable(md.settings, "settings.json", system.DocumentsDirectory)
	end


	--Check to see if an instrument settings file exists,
	--if so load it and restore the settings

	md.amsMaster:loadSettings()

	----------------------------------------------------------------------------------------

	md.screenW = display.contentWidth
	md.screenH = display.contentHeight

	md.defaultFont = "OpenSans-Regular.ttf"
	--md.defaultFont = "Inconsolata.otf"
	md.contentW = md.screenW
	md.contentH = md.screenH

	--If it gets too skinny shrink the height
	if md.contentH/md.contentW > 2/3 then
		md.contentH = 2*md.contentW/3
	end

	md.tileW = 0.95*md.contentW/6
	md.panX = 0.1*md.screenW
	md.panY = 0.3*md.screenH
	md.defaultFontSize = 0.0175*md.contentW
	md.defaultFontColor = {0, 0, 0, 0.75}

--Positioning data for common UI elements across the scenes
md.gui = {
	background = {
		x = 0.365*md.screenW,
		y = 0.5*md.screenH,
		w = 0.65*md.screenW,
		h = nil,
	},
	topMenu = {
		midX = 0.5*md.screenW,
		midY = 0.05*md.screenH,
		mWidth = md.screenW,
		mHeight = 0.1*md.screenH,
		divLineX = 0.25*md.screenW,
	},
	banner = {
		midX = 0.87*md.screenW,
		midY = 0.43*md.screenH,
		bannerHeight = 0.65*md.contentH,
		w = 0.125*md.screenW,
		h = 1.6*md.defaultFontSize,
	},
	bottomGraph = {
		x = 0.375*md.screenW,
		y = 0.87*md.screenH,
		w = 0.7*md.screenW,
		h = 0.15*md.screenH,
		},
}

	-- Enable auto-recycle on scene change
	--composer.recycleOnSceneChange = true
	mf.dprint( md.settings )

	--Start comms with all active sessions that have been loaded
	for m = 1, #md.amsMaster.active do
		md.amsMaster.active[m]:startComms()
	end

	--Get the status of the device every second
	mf.dprint( "Config completed, starting now." )
	--composer.gotoScene( "scene_info" )
	--composer.gotoScene( "scene_help" )
	--composer.gotoScene( "scene_train" )
	--composer.gotoScene( "scene_event" )
	--composer.gotoScene( "scene_home" )
	--composer.gotoScene( "scene_configure" )
	composer.gotoScene( "scene_splash" )
	--composer.gotoScene( "scene_loadSave" )
end

Runtime:addEventListener( "system", onSystemEvent )

--add the key callback
Runtime:addEventListener( "key", onKeyEvent )

-- Add the mouse event listener.
Runtime:addEventListener( "mouse", onMouseEvent )

Runtime:addEventListener( "resize", onResize )

mf.dprint( "Entering main." )

main()