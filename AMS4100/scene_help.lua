

------------------------------------------------------------------------------
-- In "pause.lua"
------------------------------------------------------------------------------
local composer = require( "composer" )

local scene = composer.newScene()
local sceneGroup

local bf = require( "bannerFunctions" )
local it = require( "instrumentTabBar" )
local ls = require("loadsave")
local md = require( "myData" )
local mf = require( "myFunctions" )
local tm = require( "topMenuBar" )
local ui = require( "uiFunctions" )
local ams = md.instrumentSettings.current

local instrumentTabGrp = display.newGroup()

local _ = {}
_.bannerText = {}

-- By some method (a "resume" button, for example), hide the overlay

local outputTypes = {
	order = {"intVolt", "intCurrent", "ext20VperV", "ext10mAperV",
		"ext1mAperV", "ext100uAperV"},
	intVolt = "Voltage",
	intCurrent = "Current",
	ext20VperV = "Ext 20V/V",
	ext10mAperV = "Ext 10mA/V",
	ext1mAperV = "Ext 1mA/V",
	ext100uAperV = "Ext 100uA/V",
}
local triggerTypes = {
	order = {"rising", "falling"},
	rising = "Rising",
	falling = "Falling",
}
local autoTypes = {
	order = {"none", "count", "fill"},
	none = "None",
	count = "Count",
	fill = "Fill",
}
local monTypes = {
	order = {"scale100mVperV", "scale1VperV", "scale10VperV", "scale20VperV",
		"scale100uAperV", "scale1mAperV", "scale10mAperV", "scale100mAperV"},
	scale100mVperV = "0.1V/V",
	scale1VperV = "1V/V",
	scale10VperV = "10V/V",
	scale20VperV = "20V/V",
	scale100uAperV = "100uA/V",
	scale1mAperV = "1mA/V",
	scale10mAperV = "10mA/V",
	scale100mAperV = "100mA/V",
}
local syncTypes = {
	order = {"trainDelay", "trainDuration", "eventDelay", "eventDuration1",
		"eventDuration2", "eventDuration3", "clockuS", "clockmS", "clockS" },
	trainDelay = "Train Del.",
	trainDuration = "Train Dur.",
	eventDelay = "Event Del.",
	eventDuration1 = "Event Dur1",
	eventDuration2 = "Event Intr",
	eventDuration3 = "Event Dur2",
	clockuS = "Clock uS",
	clockmS = "Clock mS",
	clockS = "Clock S",
}
local perTypes = {
	order = {"period", "frequency"},
	period = "Period",
	frequency = "Frequency",
}
local eventPulseTypes = {
	order = {"monophasic", "biphasic", "asymm", "ramp"},
	monophasic = "Mono",
	biphasic = "Bi",
	asymm = "Asymm",
	ramp = "Ramp",
}
local symTypes = {
	order = {"yes", "no"},
	yes = "Yes",
	no = "No",
}
local trainPulseTypes = {
	order = {"mixed", "uniform"},
	mixed = "Mixed",
	uniform =  "Uniform",
}
local hoTypes = {
	order = {"hold", "offset"},
	hold = "Hold",
	offset = "Offset",
}

local function textListener( event )

	local t = event.target

	if ( event.phase == "began" ) then
		-- user begins editing defaultField
		mf.dprint( event.text )

	elseif ( event.phase == "ended" or event.phase == "submitted" ) then
		-- do something with defaultField text
		mf.dprint( t.id )
		mf.dprint( event.target.text )
		if t.id == "IP Address" then
			--md.settings.ipaddress = t.text
			ams.connection.address = t.text
		elseif t.id == "Port" then
			--md.settings.port = t.text
			ams.connection.port = t.text
		end
		ls.saveTable(md.settings, "settings.json", system.DocumentsDirectory)
	elseif ( event.phase == "editing" ) then
		mf.dprint( event.newCharacters )
		mf.dprint( event.oldText )
		mf.dprint( event.startPosition )
		mf.dprint( event.text )
	end
end

local function onLoadDefaultSettingsTap( event )

	local function onComplete( event )
		if ( event.action == "clicked" ) then
			local i = event.index
			if ( i == 1 ) then
				-- Do nothing; dialog will simply dismiss
			elseif ( i == 2 ) then
				md.state.allowHighVoltage = true
		--Load the settings from the default file
				local savedSettings = ls.loadTable("instrumentSettings.json", 		system.ResourceDirectory)
				ams:setMenuVals( savedSettings.current )
			end

		end
	end

	native.showAlert( "AMS 4100", "Load default settings into Current config?",
		{"Cancel", "OK"}, onComplete )

	return true
end

-- listener function
local function onEveryFrame( event )

	--If the user has selected a new tab this forces the udpate to occurr
	--If not, it's pointing exactly where it was before so no harm done.
	ams = md.instrumentSettings.current

	bf.updateBanner()
	it.updateMenuBar()
	tm.updateMenuBar()

	if md.state.updateConfig then
		md.state.updateConfig = false
		--ams.updateConfig()
	end
	if md.state.appResumed then
		md.state.appResumed = false
		--maskGroup2:invalidate()
		--maskGroup3:invalidate()
		--pic:invalidate()
	end

	--Trap the case where the Event List is empty.
	if ams.LibID < 0 or ams.LibID > 20 then
		ams.LibID = 1
	end

	local e = ams.Event[ams.LibID]

	local function calcDisplayAmplitude( value )
		if ams.Config.Mode == "intCurrent" then
			return mf.calcDisplayAmps( value )
		else
			return mf.calcDisplayVolts( value )
		end
	end

	_.bannerText["Auto"].text = autoTypes[ams.Config.Auto]
	_.bannerText["Train Type"].text = trainPulseTypes[ams.Train.Type]
	_.bannerText["Uniform #"].text = ams.EventList.Uniform
	_.bannerText["Train Quantity"].text = ams.Train.Quantity
	_.bannerText["Train Delay"].text = mf.calcDisplayTime(ams.Train.Delay)
	_.bannerText["Frequency"].text = mf.calcDisplayFreq(ams.Train.Period)
	_.bannerText["Train Period"].text = mf.calcDisplayTime(ams.Train.Period)
	_.bannerText["Train Duration"].text = mf.calcDisplayTime(ams.Train.Dur)
	_.bannerText["Hold/Off"].text = hoTypes[ams.Train.OffsetOrHold]
	_.bannerText["H/O Level"].text = calcDisplayAmplitude( ams.Train.Level )

	_.bannerText["Event Type"].text = eventPulseTypes[e.Type]
	_.bannerText["Quantity"].text = e.Quantity
	_.bannerText["Delay"].text = mf.calcDisplayTime(e.Delay)
	_.bannerText["Period"].text = mf.calcDisplayTime(e.Period)
	_.bannerText["Dur 1"].text = mf.calcDisplayTime(e.Dur1)
	_.bannerText["Amp 1"].text = calcDisplayAmplitude(e.Amp1)
	_.bannerText["Dur 2"].text = mf.calcDisplayTime(e.Dur2)
	_.bannerText["Amp 2"].text = calcDisplayAmplitude(e.Amp2)
	_.bannerText["Intr"].text = mf.calcDisplayTime(e.Intr)

	_.bannerText["Trigger"].text = triggerTypes[ams.Config.Trigger]
	_.bannerText["Mode"].text = outputTypes[ams.Config.Mode]
	_.bannerText["Monitor"].text = monTypes[ams.Config.Monitor]
	_.bannerText["Sync 1"].text = syncTypes[ams.Config.Sync1]
	_.bannerText["Sync 2"].text = syncTypes[ams.Config.Sync2]
	_.bannerText["Per/Freq"].text = perTypes[ams.Config.PeriodOrFreq]


end

function scene:create( event )

	mf.dprint( "scene_configure entered." )

	local labels
	local screenW = md.screenW
	local screenH = md.screenH
	local tileW = md.tileW
	local x, y
	local params

	sceneGroup = self.view

	mf.dprint( "Confiugre Overlay entered." )
	--Background rectangle

	local sW, sH = md.screenW, md.screenH

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

	--Create the navigation buttons
	--params.listener = onNavBtnTouch
	--ui.drawNavButtons( params )

	--Create the run buttons
	params.listener = onRunBtnTouch
	--ui.drawRunButtons( params )

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

	params = {
		parent = sceneGroup,
		midX = md.gui.topMenu.midX, --0.5*sW,
		midY = md.gui.topMenu.midY, --0.1*sH,
		mWidth = md.gui.topMenu.mWidth, --sW,
		mHeight = md.gui.topMenu.mHeight, --0.1*sH,
		divLineX = md.gui.topMenu.divLineX, --0.25*sW,
	}
	tm.drawMenuBarButtons( params )

	local p = {
		parent = params.parent,
		font = params.font or md.defaultFont,
		fontSize = params.fontSize or md.defaultFontSize,
		fontColor = params.fontColor or md.defaultFontColor,
		midX = params.midX or 0.5*sW - sW/40,
		midY = 0.55*sH,
		bannerHeight = params.bannerHeight or 0.8*sH,
		stroke = params.stroke or {0, 0, 0, 0.8},
		strokeWidth = params.strokeWidth or 3,
		w = params.w or sW/8,
		h =  params.h or sH/20,
	}

	local allIDs = {
		{
			{"Mode", " "},
			{"Monitor", " "},
			{"Trigger", " "},
			{"Auto", " "},
			{"Per/Freq", " "},
			{"Sync 1", " "},
			{"Sync 2", " "},
			{"", ""},
			{"", ""},
			{"", ""},
			{"", ""},
		},
		{
			{"Train Type", " "},
			{"Uniform #", " "},
			{"Train Delay", " "},
			{"Train Duration", " "},
			{"Train Period", " "},
			{"Train Quantity", " "},
			{"Hold/Off", " "},
			{"H/O Level", " "},
			{"Frequency", " "},
			{"",""},
			{"", ""},
		},

		{
			{"Event Type", " "},
			{"Quantity", " "},
			{"Delay", " "},
			{"Period", " "},
			{"Dur 1", " ",},
			{"Amp 1", " "},
			{"Intr", " "},
			{"Dur 2", " "},
			{"Amp 2", " "},
			{"", ""},
			{"", ""},
		}
	}

	for k = 1, 3 do
		local ids = allIDs[k]
		local rows, cols = #ids, 1
		local labels = {}
		p.midX = sW/4.5 - (1.5-k)*p.w*2.1
		for m = 1, rows do
			cols = #ids[m]
			for n = 1, cols do
				if ids[m][n] ~= "" then
					local panX = p.midX - (cols/2-n+0.5)*p.w*1
					--local panY = p.midY - (rows/2-m+0.5)*p.h*1.3
					local panY = p.midY - (rows/2-m+0.5)*p.bannerHeight/11

					local options = {
						text = ids[m][n] .. ": ",
						x = panX,
						y = panY,
						width = p.w,
						height = p.h,
						font = p.font,
						fontSize = p.fontSize,
						align = "right",
						parent = p.parent,
					}
					if ids[m][n] == " " then
						local myRect = display.newRoundedRect( p.parent, panX, panY, p.w, p.h, 0.025*p.w )
						myRect.strokeWidth = 2
						myRect:setStrokeColor( unpack( p.fontColor ))
						--Adjust the height up slightly so the text is centered better
						myRect.anchorY = 0.55
						myRect.id = ids[m][n-1]

						options.align = "center"
						_.bannerText[myRect.id] = display.newText(options)
						_.bannerText[myRect.id]:setFillColor( unpack( p.fontColor ))

						_.bannerText[myRect.id].label = labels[m]
						_.bannerText[myRect.id].rect = myRect

					elseif ids[m][n] == "AMS 4100" then
						options.text = "AMS 4100"
						options.align = "center"
						local myText = display.newText(options)
						myText:setFillColor( unpack( p.fontColor ))

					else
						labels[m] = display.newText(options)
						labels[m]:setFillColor( unpack( p.fontColor ))
					end
				end
			end
		end
	end

	local options = {
		text = "Load Default Settings",
		x = 0.15*sW,
		y = 0.75*sH,
		width = 0.15*sW,
		height = 2*p.h,
		font = p.font,
		fontSize = p.fontSize,
		align = "center",
		parent = p.parent,
	}
	local myText = display.newText( options )
	myText:setFillColor( unpack( p.fontColor ))
	myText:addEventListener( "tap", onLoadDefaultSettingsTap )



	local helpText = {
		"AMS 4100 is a production of A-M Systems LLC.  For help and support contact us at www.a-msystems.com.",
		"Crystal Project by Everaldo Coelho, Entypo by Daniel Bruce, Typicons by Stephen Hutchings, and ecg2, train4, and home4 icons by Freepik, are licensed under a Creative Commons Attribution 3.0 Unported License.",}

	for m = 1, 2 do
		local panX = 0.375*sW
		local panY = 0.925*sH - (3/2-m+0.5)*p.bannerHeight/15
		local options = {
			text = helpText[m],
			x = panX,
			y = panY,
			width = 0.7*sW,
			height = 2*p.h,
			font = p.font,
			fontSize = 0.75*p.fontSize,
			align = "center",
			parent = p.parent,
		}
		local myText = display.newText( options )
		myText:setFillColor( unpack( p.fontColor ))
	end

  params = {
    midX = 0.375*sW,
    midY = 0.975*sH,
    menuWidth = 0.75*sW,
    menuHeight = 0.05*sH,
    fontSize = md.defaultFontSize,
    parent = instrumentTabGrp,
  }

	it.drawTabBarButtons( params )

	sceneGroup:insert( instrumentTabGrp )

	mf.dprint( "scene_configure created." )

end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		Runtime:addEventListener( "enterFrame", onEveryFrame )

	elseif ( phase == "did" ) then

	end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase
	local parent = event.parent  --reference to the parent scene object

	if ( phase == "will" ) then
		-- Call the "resumeGame()" function in the parent scene
		Runtime:removeEventListener( "enterFrame", onEveryFrame )
		native.setKeyboardFocus( nil )
		md.amsMaster:storeSettings()
	elseif ( phase == "did" ) then
		mf.dprint( "scene_configure removed" )
		composer.removeScene( "scene_help", false)

	end
end

function scene:destroy( event )
	local sceneGroup = self.view

end

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

return scene