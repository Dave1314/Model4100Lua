
local _ = {}

_.amsMenu = {
	general = 0,
	config = 1,
	--steps = 2,
	network = 3,
	--home = 6, 
	uniform = 4,
	train = 7, 
	eventlist = 8,
	event = 10,
}
_.general = { --0
	mode = 0,
	monitor = 1,
	trigger =2,
	auto = 3,
	save = 4,
	output = 5,
}
_.mode = { --0 0
	intVolt = 0,
	intCurrent = 1,
	ext20VperV = 2,
	ext10mAperV = 3,
	ext1mAperV = 4,
	ext100uAperV = 5,
}
_.monitor = { --0 1
	scale100mVperV = 0,
	scale1VperV = 1,	
	scale10VperV = 2,
	scale20VperV = 3,
	scale100uAperV = 4,
	scale1mAperV = 5,
	scale10mAperV = 6,
	scale100mAperV = 7,
}
_.trigger = { --0 2
	rising = 0,
	falling = 1,
}
_.auto = { --0 3
	none = 0,
	count = 1,
	fill = 2,
}
_.output = { --0 5
	on = 0,
	off = 1,
}
_.config = { --1
	periodOrFreq = 0,
	sync1 = 1,
	sync2 = 2,
	serialNumber = 6,
}
_.periodOrFreq = { --1 0
	period = 0,
	frequency = 1,
}
_.durOrCount = 	{ --1 
	duration = 0,
	counts = 1,
}
_.sync = { --1 1/2
	trainDelay = 0,
	trainDuration = 1,
	eventDelay = 2,
	eventDuration1 = 3,
	eventDuration2 = 4,
	eventDuration3 = 5,
	eventWidth = 6,
	clockuS = 7,
	clockmS = 8,
	--clockS = 8,
}

_.network = { --3
	address = 0,
	subnet = 1,
	gateway = 2,
	pinNumber = 3,
}

_.uniform = { -- 4 0
	eventNumber = 0,
	MAC = 1,
}

_.train = { --7
	trainType = 0,
	delay = 1,
	duration = 2,
	period = 3,
	quantity = 4,
	offsetOrHold = 5,
	level = 6,
}
_.tType = { --7 0
	uniform = 0,
	mixed = 1,
}
_.offsetOrHold =  { --7 5
	hold = 0,
	offset = 1,
}
_.eventList =	{ 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 
	23, 24, 25, 26, 27, 28, 29, 30, 31, 32 }

_.event = 	{ --9+Event Number
	eventID = 0,
	libID = 1,	
	eType = 2,
	delay = 3,
	quantity = 4,
	period = 5,
	dur1 = 6,
	amp1 = 7,
	intr = 8,
	dur2 = 9,
	amp2 = 10,
}
_.eType = 	 {
	monophasic = 0,
	biphasic = 1,
	asymm = 2,
	ramp = 3,
}


return _