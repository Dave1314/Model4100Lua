-----------------------------------------------------------------------------------------
--
-- myData.lua
--
-- Repository for all global variables used in AMS 4100
--
-----------------------------------------------------------------------------------------

local _ = {}

_.ids = {}

_.sounds = {}
_.soundFiles = {}

_.screenW = 0
_.screenH = 0
_.contentW = 0
_.contentH = 0
_.panX = 0
_.panY = 0
_.tileW = 0

_.dropbox = {
	accountID = 		"dbid:AADoKLARs012kfDHykjZ5gZV6-K-83-63Sc",
	appKey = 			"t1micgrp7480qzu",
	appKeySecret = 	"tt4p7l2xod4q4w3",
	--authCode = 			"",
	--accessToken = 		"",
	root = 				"dropbox",
	tokenType = 		"bearer",
	--uid = 				"499566868",
}

--Actual settings are defined in main.lua after screen size is determined.
_.gui = {}

--Initialize the data variables for global settings
--These values are stored from one session to the next
_.settings = {
	language = "en",
	muted = false,
	startTime = os.time(),
	freqSteps = 10000,
	ampSteps = 10000,
	timeSteps = 10,
	activeDirectory = "",  --Initialized in main.lua
}

--Initialize the data variables for global settings
--These values are NOT stored from one session to the next
_.state = {
	allowHighVoltage = false,
	AMS4100Rev = "ams4100-Test",
	ampScale = 100,
	ampOffset = 0,
	appResumed = false,
	eventRectAlpha = 0,	
	homeGroup = "internalSave",
	mouse = {
		name = "mouse",
		x = 0,
		y = 0,
		time = 0,
		primaryButton = false,
		secondaryButton = false,
		middleButton = false
		},
	revision = "1.2.3",

	timeScale = 1,
	trigger = "none",
	updateConfig = false,
	updateGraph = false,
	timeout = false,
	--The following state variables were removed when the connection
	--changed from a single, global instance to individual instances
	--for each instrument connected.
	--connected = false,
	--commsInProgress = false,	
	--receiveBuffer = {},	--Message queue for data received from the instrument
	--receiveTimeout = 0.0,--Sets the timeout for command received from the instrument
	--running = false,
	--sendBuffer = {},		--Message queue for commands to be sent to the instrument
	--sendTimeout = 0.015,	--Sets the timeout for command sent to the instrument	
}

-- Store the settings of the connected instrument and saved configs
_.instrumentSettings = {
	Current = {},
	Saved = {},
}

return  _