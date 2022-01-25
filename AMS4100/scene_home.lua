
local composer = require( "composer" )

local scene = composer.newScene()

local bf = require( "bannerFunctions" )
local cf = require( "chartFunctions" )
local ef = require( "exportFunctions" )
local fv = require( "fileView" )
local it = require( "instrumentTabBar" )
local ls = require( "loadsave" )
local pf = require( "pulseFunctions" )
local mc = require( "myConnection" )
local md = require( "myData" )
local mf = require( "myFunctions" )
local tm = require( "topMenuBar" )
local ui = require( "uiFunctions" )
local lfs = require( "lfs" )
local json = require("json")

local amsMaster = require( "ams4100" )
local ams = md.instrumentSettings

local lang = md.settings.language

local params = {}
local sceneGroup
local exportGrp = display.newGroup()
local saveButtonsGroup = display.newGroup()
local saveRectGrp = display.newGroup()
local currentRectGrp = display.newGroup()
local instrumentTabGrp = display.newGroup()
local tempGroup = display.newGroup()
local platform = system.getInfo( "platformName" )

--Create a holding place for the copies of saved settings
local newSettings = { current = {} }
newSettings.current = amsMaster.new()
newSettings.current.needsCommit = false

local function checkBounds( p, b )

	if p.x > b.xMin and p.x < b.xMax	and p.y > b.yMin and p.y < b.yMax then
		return true
	else
		return false
	end

end

local function checkExport( event, settings )
	--If the copy of currentRect has been dropped over one of the export buttons
	--export it to the appropriate location.
	for m = 1, exportGrp.numChildren do
		local bounds = exportGrp[m].contentBounds
		if checkBounds( event, bounds ) then
			mf.dprint( 'Current rect dropped over ' .. exportGrp[m].id )
			if exportGrp[m].id == "dropbox" then
				ef.dropboxExport( settings )
			elseif exportGrp[m].id == "localExport" then
				ef.localExport( settings )
			elseif exportGrp[m].id == "openNative" then
				ef.openNative( settings )
			elseif exportGrp[m].id == "email" then
				ef.emailExport( settings )
			else
				ef.internalSave( settings )
			end
		end
	end
end

local function onKeyEvent( event )

	local phase = event.phase
	local keyName = event.keyName

	local x, y = saveRectGrp.fileView:getContentPosition()
	local view = saveRectGrp.fileView:getView()
	local scrollHeight = view._scrollHeight
	local height = saveRectGrp.fileView.height
	local bounds = saveRectGrp.fileView.contentBounds
	local minHeight = 0.095*md.screenH

	if "up" == keyName and phase == "up"  then
		saveRectGrp.fileView:scrollToPosition({x=0, y=y+minHeight, time=100})
	elseif "down" == keyName and phase == "up"  then
		saveRectGrp.fileView:scrollToPosition({x=0, y=y-minHeight, time=100})
	end

	--x, y = saveRectGrp.fileView:getContentPosition()
	if y > 0 then
		saveRectGrp.fileView:scrollTo("top", {})
	elseif -y+height > scrollHeight then
		saveRectGrp.fileView:scrollTo("bottom", {})		
	end

	return true
end

---[[ 'onRelease' event listener for HomeBtn
local function onSaveRectTouch(event)

	local t = event.target
	local p = t.parent
	local p2 = p.parent
	local pulse = p.pulse

	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		--If this is the original libRect copy it and pass the touch listener to the copy
		if t.isOriginal then
			local newPulse = pulse:copy()

			tempGroup:insert( newPulse.parent )

			newPulse.parent.x = p.x
			newPulse.parent.y = event.y
			newPulse.parent.x0 = p.x
			newPulse.parent.y0 = event.y --p.y
			newPulse.outline.isOriginal = false
			newPulse.outline.isHitTestable = true
			newPulse.outline:setFillColor( 1, 1, 1, 0.75 )
			newPulse.outline:addEventListener( "touch", onSaveRectTouch )
			newPulse.outline.isFocus = true
			newPulse.parent.dx = event.x - p.x
			newPulse.parent.dy = 0
			t.isFocus = false
			display.getCurrentStage():setFocus( newPulse.outline )
		else
			p.dx = event.x - p.x
			p.dy = event.y - p.y
		end
	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

			p.x = event.x - p.dx
			p.y = event.y - p.dy

		elseif event.phase == "ended" or event.phase == "cancelled" then

			local id = pulse.options.id
			local bounds = currentRectGrp.contentBounds
			local saveBounds = saveRectGrp.contentBounds
			local exportBounds = exportGrp.contentBounds
			local settings = pulse.options.event:getSettings()

			mf.dprint( "Processing save slot " .. id )

			--If the user dragged the event over the train drop it in
			if checkBounds( event, bounds ) then
				--If another saved config has been added to this group
				--destroy the first one so the new one is the only one
				transition.to(p, {time = 200,
						x = currentRectGrp[1].x,
						y = currentRectGrp[1].y})
				local isConnected = md.state.connected
				md.state.connected = false
				newSettings.current:setMenuVals( settings )
				newSettings.current.needsCommit = true
				pulse.options.saveID = 9  --Hard code this ID so pulse gets destroyed
				md.state.connected = isConnected
				--Check to see if they're trying to export these settings
			else
				--Saved rects and current rect export function are the same.
				--Use a single function to check if the rect has been dropped
				--over one of the export options.
				checkExport( event, settings )
				pulse:removeSelf()
			end
			-- reset touch
			t.isFocus = false
			display.getCurrentStage():setFocus( nil )
		end
	end
	return true	-- indicates successful touch
end

---[[ 'onRelease' event listener for HomeBtn
local function onFileRectTouch(event)

	local t = event.target
	local p = t.parent
	local filename = p.pulse.options.event.filename


	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		--If this is the original libRect copy it and pass the touch listener to the copy
	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

			p.x = event.x - p.dx
			p.y = event.y - p.dy

		elseif event.phase == "ended" or event.phase == "cancelled" then

			if filename == ".." then
				lfs.chdir(md.settings.activeDirectory)
				lfs.chdir("..")
				md.settings.activeDirectory = lfs.currentdir()
			else
				lfs.chdir(md.settings.activeDirectory)
				lfs.chdir(filename)
				md.settings.activeDirectory = lfs.currentdir()
			end
			-- reset touch
			t.isFocus = false
			display.getCurrentStage():setFocus( nil )
		end
	end
	return true	-- indicates successful touch
end

local function onFileViewRectTouch(event)

	local t = event.target
	local p = t.parent

	if p.pulse.options.event.isDir then
		onFileRectTouch( event )
	else
		onSaveRectTouch( event )
	end
	return true
end

---[[ 'onRelease' event listener for HomeBtn
local function onCurrentRectTouch(event)

	local t = event.target
	local p = t.parent
	local p2 = p.parent
	local pulse = p.pulse

	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		--If this is the original libRect copy it and pass the touch listener to the copy
		if t.isOriginal then
			local newPulse = pulse:copy()

			tempGroup:insert( newPulse.parent )

			newPulse.parent.x = p.x
			newPulse.parent.y = p.y
			newPulse.parent.x0 = p.x
			newPulse.parent.y0 = p.y
			newPulse.outline.isOriginal = false
			newPulse.outline.isHitTestable = true
			newPulse.outline:setFillColor( 1, 1, 1, 0.75 )
			newPulse.outline:addEventListener( "touch", onCurrentRectTouch )
			newPulse.outline.isFocus = true
			newPulse.parent.dx = event.x - p.x
			newPulse.parent.dy = event.y - p.y
			t.isFocus = false
			display.getCurrentStage():setFocus( newPulse.outline )
		else
			p.x0 = p.x
			p.y0 = p.y
			p.dx = event.x - p.x
			p.dy = event.y - p.y
		end
		--return true
	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

			p.x = event.x - p.dx
			p.y = event.y - p.dy

		elseif event.phase == "ended" or event.phase == "cancelled" then

			--Get a clean copy of the settings without the extra overhead
			local settings = pulse.options.event:getSettings()
			local bounds = saveRectGrp.contentBounds

			--If the user dragged the event over the fileview display drop it in
			if checkBounds( p, bounds ) then
				--Current rect was dropped over the savedRectGrp bounds.
				--Save the settings in the appropriate spot.
				if md.state.fileview == "dropbox" then
					ef.dropboxExport( settings )
				elseif md.state.fileview == "localExport" then
					ef.localExport( settings )
				else
					ef.internalSave( settings )
				end
			else

				--Saved rects and current rect export function are the same.
				--Use a single function to check if the rect has been dropped
				--over one of the export options.
				checkExport( event, settings )

			end
			--Clean up the old pulse and regenerate the fileView
			pulse:removeSelf()

			-- reset touch focus
			t.isFocus = false
			display.getCurrentStage():setFocus( nil )
		end
	end
	return true	-- indicates successful touch
end

local function uploadSettings( updateInstrument )

	--Commit the changes to the saved list.
	--Temporarily disable comms while saving the new config
	--local isConnected = ams.current.connection.connected
	--md.state.connected = false

	--if updateInstrument then
	--	ams.current.connection.connected = isConnected
	--end

	if newSettings.current.needsCommit then
		--Save the instrument name so it can be restored
		local name = ams.current.InstrumentName
		newSettings.current.needsCommit = false
		ams.current:Stop()
		ams.current:setMenuVals( newSettings.current )
		ams.current.InstrumentName = name
		ams.current:Run()
	end
	--ams.current.connection.connected = isConnected
	--Clear out the copies overlaid on top of the saved
	--and current pulse blocks.
	for m = tempGroup.numChildren, 1, -1 do
		tempGroup[m]:removeSelf()
		tempGroup[m] = nil
	end

	--md.state.connected = isConnected
end

local function onUploadCommitTouch( event )

	local t = event.target
	local p = t.parent

	if ( event.phase == "began" ) then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true

	elseif ( t.isFocus ) then
		if ( event.phase == "moved" ) then

		elseif ( event.phase == "ended" or event.phase == "cancelled" ) then

			uploadSettings( true )
			-- reset touch focus
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
		end
	end
	return true
end

local function onScrollBarTouch( event )

	local t = event.target
	local p = t.parent

	local view = saveRectGrp.fileView:getView()
	local minHeight = saveRectGrp.scrollBar.height
	local scrollHeight = view._scrollHeight
	local height = saveRectGrp.fileView.height
	local bounds = saveRectGrp.fileView.contentBounds

	if ( event.phase == "began" ) then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true				
		--print( "Begin" .. "\t" .. event.y-bounds.yMin )
		t.startX = t.x
		t.startY = t.y
	elseif ( t.isFocus ) then
		if ( event.phase == "moved" ) then
			--Only enable scrolling if the scrollHeight is greater than the height
			if scrollHeight > height then
				
				local dy = event.y-t.startY
				local newY = -(event.y-bounds.yMin)/(height) * (scrollHeight-height+minHeight)
				saveRectGrp.fileView:scrollToPosition({x=0, y=newY, time=0})
				local x,y = saveRectGrp.fileView:getContentPosition()
				
--		saveRectGrp.scrollBar.y = -(height-minHeight)*y/(scrollHeight-height) + bounds.yMin
				
--				local newY = -(event.y-bounds.yMin)/(height) * (scrollHeight-height+minHeight)
--				saveRectGrp.fileView:scrollToPosition({x=0, y=newY, time=0})
--				local x,y = saveRectGrp.fileView:getContentPosition()

				--print( height .. "\t" .. scrollHeight .. "\t" .. dy .. "\t" .. newY)
			end
		elseif ( event.phase == "ended" or event.phase == "cancelled" ) then
			-- reset touch focus
			---[[
			local x, y = saveRectGrp.fileView:getContentPosition()
			if y > 0 then
				saveRectGrp.fileView:scrollTo("top", {})
			elseif -y+height > scrollHeight then
				saveRectGrp.fileView:scrollTo("bottom", {})		
			end--]]
			--print( y .. "\t" .. height .. "\t" .. scrollHeight)
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
		end
	end
	return true
end

---[[ 'onRelease' event listener for navigation buttons
local function onExportBarTouch(event)

	local t = event.target
	local p= t.parentGrp

	if event.phase == "began" then
		-- set touch focus
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		t.alpha = 0.5
	elseif t.isFocus then
		if event.phase == "moved" then
			local dx = math.abs(t.x - event.x)
			local dy = math.abs(t.y - event.y)

			--Disable highlights if their finger moves off the button
			if dx > t.width/2 or dy > t.height/2 then
				t.alpha = 1
				display.getCurrentStage():setFocus( nil )
				t.isFocus = nil
			end

		elseif event.phase == "ended" or event.phase == "cancelled" then

			t.alpha = 1
			if t.id == "internalSave" or t.id == "dropbox" or t.id == "localExport" then
				--Move the underline to indicate which file location is the active one.
				for m = 1, exportGrp.numChildren do
					--exportGrp[m]:setFillColor( 0 )
					exportGrp[m].underline.alpha = 0
				end
				t.underline.alpha = 1
				md.state.fileview = t.id
				if t.id == "dropbox" then
					if platform == "Android" or platform == "iPhone OS" then
						ef.refreshDropboxTempDirectory()
					end
				end

			end
			--Reset the scrollview to the top
			saveRectGrp.fileView:scrollToPosition({x=0, y=0, time=0})
			display.getCurrentStage():setFocus( nil )
			t.isFocus = nil
			return true	-- indicates successful touch
		end
	end
end

-- timer listener function to scan the active save file directory
-- and regenerate the fileview if the contents have chnaged
local function onFileCheckInterval()

	local activeDirectory
	if md.state.fileview == "internalSave" then
		activeDirectory = system.pathForFile( "", system.DocumentsDirectory )
	elseif md.state.fileview == "localExport" then
		activeDirectory = md.settings.activeDirectory
	elseif md.state.fileview == "dropbox" then
		activeDirectory = ef.getDropboxDirectory()
	elseif md.state.fileview == "" then

	end

	local regenerateView = false
	local newListing = {}
	local oldListing = saveRectGrp.fileView.oldListing

	for file in lfs.dir( activeDirectory ) do
		table.insert( newListing, file )
	end

	if #newListing ~= #oldListing then
		regenerateView = true
	else
		for m = 1, #newListing do
			if newListing[m] ~= oldListing[m] then
				regenerateView = true
				break;
			end
		end
	end

	if regenerateView then
		saveRectGrp.fileView.oldListing = newListing
		saveRectGrp.fileView:regenerateView( activeDirectory )	
	end
end

-- listener function
local function onEveryFrame( event )

	bf.updateBanner()		--Update right side banner
	it.updateMenuBar()	--Update bottom instrument tab bar
	tm.updateMenuBar()	--Update top menu bar
	--em.updateMenuBar()

	if sceneGroup.trnText.text ~= ams.current.InstrumentName .. ":" then
		sceneGroup.trnText.text = ams.current.InstrumentName .. ":"
	end

	local activeDirectory
	if md.state.fileview == "internalSave" then
		activeDirectory = system.pathForFile( "", system.DocumentsDirectory )
	elseif md.state.fileview == "localExport" then
		activeDirectory = md.settings.activeDirectory
	elseif md.state.fileview == "dropbox" then
		activeDirectory = ef.getDropboxDirectory()
	elseif md.state.fileview == "" then

	end
	if saveRectGrp.directoryText.text ~= activeDirectory then
		saveRectGrp.directoryText.text = activeDirectory
	end

	--Updating the periods first seems to prevent the instrument
	--from going into an 'Event period to low' error condition.
	if md.state.updatePeriods then
		md.state.updatePeriods = false
		ams.current.Train:setPeriod( ams.current.Train.Period )
		for m = 1, 20 do
			ams.current.Event[m]:setPeriod( ams.current.Event[m].Period )
		end
	end
	if md.state.updateHome then
		md.state.updateHome = false
		ams.current.updateCoords = true
		ams.current.Config:setMenuVals()
	end
	if md.state.updateTrain then
		md.state.updateTrain = false
		ams.current.updateCoords = true
		ams.current:Stop()
		ams.current.Train:setMenuVals()
		ams.current.Config:setMenuVals()
		ams.current.EventList:set()
		ams.current:Run()
	end

	local x, y = saveRectGrp.fileView:getContentPosition()
	local view = saveRectGrp.fileView:getView()
	local scrollHeight = view._scrollHeight
	local height = saveRectGrp.fileView.height
	local bounds = saveRectGrp.fileView.contentBounds
	local minHeight = 0.095*md.screenH

	if scrollHeight > height then
		saveRectGrp.scrollBar.y = -(height-minHeight)*y/(scrollHeight-height) + bounds.yMin
	else 
		saveRectGrp.scrollBar.y = bounds.yMin
	end

	if saveRectGrp.scrollBar.y < bounds.yMin then
		saveRectGrp.scrollBar.y = bounds.yMin
	elseif saveRectGrp.scrollBar.y+saveRectGrp.scrollBar.height > bounds.yMax then
		saveRectGrp.scrollBar.y = bounds.yMax - saveRectGrp.scrollBar.height
	end

	if md.state.appResumed then
		md.state.appResumed = false
	end

end

function scene:create( event )

	mf.dprint( "scene_loadSave entered." )
	sceneGroup = self.view
	--Draw the boxes to indicate library and event positions
	local sW, sH = md.screenW, md.screenH
	local w, h
	local midX = 0.365*sW
	local midY = 0.5*sH

	local bk = display.newRect( sceneGroup, 0.5*sW, 0.5*sH, sW, sH )
	bk.fill = {1, 1, 1}

	params = {
		parent = sceneGroup,
		x = midX,
		y = midY,
		w = 1.8*midX,
		h = nil,
	}
	ui.drawBackground( params )

	params = {
		parent = sceneGroup,
		midX = md.gui.banner.midX, --0.87*sW,
		midY = md.gui.banner.midY, --0.48*sH,
		bannerHeight = md.gui.banner.bannerHeight, --0.65*md.contentH,
		w = md.gui.banner.w, --0.125*sW,
		h = md.gui.banner.h, --1.6*md.defaultFontSize,
		font = md.defaultFont,
		fontSize = md.defaultFontSize,
	}
	bf.drawBanner( params )

	local yOffset = 0.0*sH
	midY = 0.15*sH + yOffset
	local options = {
		parent = sceneGroup,
		text = "Stored:",
		x = midX,
		y = midY,
		fontSize = 0.065*sH,
		font = md.defaultFont,
	}
	local libText = display.newText( options )
	libText:setFillColor( 0.25, 0.25, 0.25, 0 )


	--Prep the id's and other settings for the export options
	local buttonsMaster = {
		{id = "internalSave",
			paint = "images/entypo-23-3505.png",
			toolTip = "Store settings in internal storage.",
			--exportFunction = emailExport,
		},
		{id = "localExport",
			paint = "images/entypo-12-3493.png",
			toolTip = "Store settings in Documents.",
			--exportFunction = localExport,
		},
		{id = "dropbox",
			--paint = "images/entypo-88-3593.png",
			paint = "images/dropbox-windows.png",
			toolTip = "Store settings in Dropbox.",
			--exportFunction = dropboxExport,
		},
		{id = "email",
			paint = "images/entypo-80-3585.png",
			toolTip = "Send settings via e-mail.",
			--exportFunction = emailExport,
		},
		{id = "openNative",
			paint = "images/entypo-2-3480.png",
			toolTip = "Store settings in Finder.",
			--exportFunction = openNative,
		},
	}

	--Set up the layout for which buttons to display on the left side
	--for each platform.
	local buttons = {}
	if platform == "Win" then
		buttons[1] = buttonsMaster[1]
		buttons[2] = buttonsMaster[2]
		buttons[3] = buttonsMaster[3]
	elseif platform == "Mac OS X" then
		buttons[1] = buttonsMaster[1]
		buttons[2] = buttonsMaster[2]
		buttons[3] = buttonsMaster[3]
	elseif platform == "iPhone OS" then
		buttons[1] = buttonsMaster[1]
		buttons[2] = buttonsMaster[3]
	elseif platform == "Android" then
		buttons[1] = buttonsMaster[1]
		buttons[2] = buttonsMaster[3]
	else
		buttons[1] = buttonsMaster[1]
		buttons[2] = buttonsMaster[2]
		buttons[3] = buttonsMaster[3]
	end

	w = 0.05*sH
	h = w
	midX = 0.1*sW

	for m = 1, #buttons do
		local x =  2*w*(m-#buttons/2) + midX
		local y = midY
		local id = buttons[m].id
		local myImageRect = display.newImageRect( exportGrp, buttons[m].paint, w, h )
		myImageRect.x = x
		myImageRect.y = y
		myImageRect.id = buttons[m].id
		myImageRect.toolTip = buttons[m].toolTip
		myImageRect:addEventListener( "touch", onExportBarTouch )
		local underlineRect = display.newRoundedRect( sceneGroup, x, y+0.7*h, w, h/5, 0.05*w)
		underlineRect:setFillColor( 0.2 )
		underlineRect.alpha = 0
		--myImageRect:setFillColor( 0, 0, 0, 1 )
		exportGrp[id] = myImageRect
		exportGrp[id].underline = underlineRect
	end
	md.state.fileview = "internalSave"
	exportGrp.internalSave.underline.alpha = 1

	--Now set up the layout for buttons displayed on the right hand side
	buttons = {}
	if platform == "Win" then
		buttons[1] = buttonsMaster[5]
	elseif platform == "Mac OS X" then
		buttons[1] = buttonsMaster[5]
	elseif platform == "iPhone OS" then
		buttons[1] = buttonsMaster[4]
	elseif platform == "Android" then
		buttons[1] = buttonsMaster[4]
	else
		buttons[1] = buttonsMaster[4]
		buttons[2] = buttonsMaster[5]
	end

	midX = 0.6*sW

	for m = 1, #buttons do
		local x =  2*w*(m-#buttons/2) + midX
		local y = midY
		local id = buttons[m].id
		local myImageRect = display.newImageRect( exportGrp, buttons[m].paint, w, h )
		myImageRect.x = x
		myImageRect.y = y
		myImageRect.id = buttons[m].id
		myImageRect.toolTip = buttons[m].toolTip
		myImageRect:addEventListener( "touch", onExportBarTouch )
		myImageRect:setFillColor( 0, 0, 0, 1 )
		exportGrp[id] = myImageRect
		--Create a dummy placeholder for the underline on the email and txt views
		--Makes it easier to have all export function in one group and maintain
		--underline on the "tabs" for file export.
		exportGrp[id].underline = {alpha = 0}
	end

	--Create the label for displaying the instrument name
	midX = 0.365*sW
	options.text = ams.current.InstrumentName .. ":"
	options.y = midY + 0.325*sH
	sceneGroup.trnText = display.newText( options )
	sceneGroup.trnText:setFillColor( 0.25 )

	--midY = 0.45*sH + yOffset
	midY = midY + 0.26*sH
	local rows, cols = 4, 2
	w = sW*0.325
	h = sH*0.095

	local panX, panY

	options = {
		scrollview = {
			parent = saveRectGrp,
			x = midX,
			y = 0.525*sH,
			width = 0.725*sW,
			height = 0.6*sH,
			hideScrollView = false,
		},
		directory = system.pathForFile( "", system.DocumentsDirectory ),
		--listener = onSaveRectTouch,
		listener = onFileViewRectTouch,
	}
	saveRectGrp.fileView = fv.new( options )
	saveRectGrp.fileView:scanDirectory()
	saveRectGrp.fileView:generateView()
	md.state.fileview = "internalSave"

	--Create the visible portion of the scrollbar
	local o = {
		parent = saveRectGrp,
		x = saveRectGrp.fileView.x + saveRectGrp.width/2 - 0.01*sW,
		y = saveRectGrp.fileView.y,
		w = 0.01*sW,
		--h = 0.6*sH,
		h = 0.095*sH,
		r = 0.1*w,
	}
	saveRectGrp.scrollBar = display.newRoundedRect(o.parent, o.x, o.y, o.w, o.h, o.r)
	saveRectGrp.scrollBar.anchorY = 0
	saveRectGrp.scrollBar.strokeWidth = 0
	saveRectGrp.scrollBar:setFillColor(156/256, 176/256, 179/256)
	saveRectGrp.scrollBar:setStrokeColor(156/256, 176/256, 179/256)

	--Now create a transparent mask over the top to catch touch events
	o.h = 0.6*sH
	saveRectGrp.scrollBarMask = display.newRoundedRect(o.parent, o.x, o.y, o.w, o.h, o.r)
	saveRectGrp.scrollBarMask.strokeWidth = 0
	saveRectGrp.scrollBarMask:setFillColor(0.8)
	saveRectGrp.scrollBarMask.alpha = 0.5
	saveRectGrp.scrollBarMask.isHitTestable = true
	saveRectGrp.scrollBarMask:addEventListener("touch", onScrollBarTouch)

	options = {
		parent = saveRectGrp,
		text = options.directory,
		x = 0.3*sW,
		y = 0.21*sH,
		w = sW,
		fontSize = 0.6*md.defaultFontSize,
		font = md.defaultFont,
		align = "left",
	}
	saveRectGrp.directoryText = display.newText( options )
	saveRectGrp.directoryText:setFillColor( 0.25, 0.25, 0.25, 1 )

	--Draw the outlines for the currentRectGrp
	--panX = midX - (2/2-2+0.5)*1.1*w
	panX = midX - -0.55*w
	--panY = midY - 0.5*1.1*h + 0.365*sH
	--panY = midY - 0.5*1.1*h + 0.5*sH
	panY = 0.89*sH
	libText.x = midX - (2/2-1+0.5)*1.1*w
	sceneGroup.trnText.x = midX - (2/2-1+0.5)*1.1*w
	sceneGroup.trnText.y = panY

	options = {
		parent = currentRectGrp,
		id = "Current",
		x = panX,
		y = panY,
		w = w,
		h = h,
		event = ams.current,
		text = {
			y = -h/4,
			width = 0.8*w,
			align = "left",
			text = ams.current.Description,
			fontSize = md.defaultFontSize,
		},
		pulse = {y = h/4, h = h/2},
	}
	local trainGraph = pf.new( options )
	trainGraph.outline.isOriginal = true
	trainGraph.outline.isHitTestable = true
	trainGraph.outline:addEventListener( "touch", onCurrentRectTouch )

	--Moved the top menu bar to the end so tooltips appear on top
	--of everything else
	params = {
		parent = sceneGroup,
		midX = md.gui.topMenu.midX, --0.5*sW,
		midY = md.gui.topMenu.midY, --0.1*sH,
		mWidth = md.gui.topMenu.mWidth, --sW,
		mHeight = md.gui.topMenu.mHeight, --0.1*sH,
		divLineX = md.gui.topMenu.divLineX, --0.25*sW,
	}
	tm.drawMenuBarButtons( params )

	--Draw a dummy rectangle over the upload button to capture that event
	--This allows committing a saved config to the current instrument settings
	--before uploading it.
	local myRect = display.newRect( sceneGroup, 0.075*sH, 0.05*sH, 0.1*sH, 0.1*sH )
	myRect:setFillColor( 1, 0, 0, 0 )
	myRect.isHitTestable = true
	myRect:addEventListener( "touch", onUploadCommitTouch )

	--Draw the instrument tab bar across the bottom of the screen
	params = {
		midX = 0.375*sW,
		midY = 0.975*sH,
		menuWidth = 0.75*sW,
		menuHeight = 0.05*sH,
		fontSize = md.defaultFontSize,
		parent = instrumentTabGrp,
	}
	it.drawTabBarButtons( params )

	sceneGroup:insert( exportGrp )
	sceneGroup:insert( currentRectGrp )
	sceneGroup:insert( saveRectGrp )
	sceneGroup:insert( saveButtonsGroup )
	sceneGroup:insert( tempGroup )
	sceneGroup:insert( instrumentTabGrp )

	saveRectGrp.fileView.timer = timer.performWithDelay( 500, onFileCheckInterval, -1 )
	mf.dprint( "scene_home created." )

end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- assign the above function as an "enterFrame" listener
		Runtime:addEventListener( "enterFrame", onEveryFrame )
		Runtime:addEventListener( "key", onKeyEvent )
	elseif ( phase == "did" ) then
		mf.dprint( "scene_loadSave entered" )

	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		Runtime:removeEventListener( "enterFrame", onEveryFrame )
		Runtime:removeEventListener( "key", onKeyEvent )

		timer.cancel( saveRectGrp.fileView.timer )
		uploadSettings()

		ls.saveTable( md.instrumentSettings, "instrumentSettings.json",
			system.DocumentsDirectory)
		--ams.setMenuVals()

	elseif ( phase == "did" ) then
		mf.dprint( "scene_home removed" )
		composer.removeScene( "scene_home", false)
	end
end

function scene:destroy( event )
	mf.dprint( "scene_home destroyed" )
	local sceneGroup = self.view

end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene