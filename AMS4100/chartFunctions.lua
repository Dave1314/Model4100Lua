-----------------------------------------------------------------------------------------
--
-- Filename: chartFunctions.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for drawing and creating the chart used on the event and possibly train screen
--
-----------------------------------------------------------------------------------------

local gf = require( "graphFunctions" )
local md = require( "myData" )
local mf = require( "myFunctions" )
--local tf = require( "tileFunctions" )
local ams = md.instrumentSettings.current


-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
--
-- NOTE: Code outside of listener functions (below) will only be executed once.
--
-----------------------------------------------------------------------------------------

local _ = {}

local function calcTime( t1, t2, startValue )

	return mf.calcTime( t1, t2, startValue )

end

local function calcAmplitude( a1, a2, startValue )

	return mf.calcAmplitude( a1, a2, startValue )

end

_.destroyPulse = function()
	_.myRects:removeSelf()
	_.myRects = nil
end

_.drawOutline = function( params )
	local p = {
		parent = params.parent,
		x = params.x or 0,
		y = params.y or 0,
		w = params.w or params.parent.width,
		h = params.h or params.parent.height,
		fill = params.fill or {0, 0, 0, 0},
		stroke = params.stroke or {0, 0, 0, 1},
		strokeWidth = params.strokeWidth or 3,
	}

	local myRect = display.newRect( p.parent, p.x, p.y, p.w, p.h )
	myRect:setFillColor( p.fill[1], p.fill[2], p.fill[3], p.fill[4] )
	myRect:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
	myRect.strokeWidth = p.strokeWidth
	return myRect
end

_.drawGridlines = function( params )

	local p = {
		parent = params.parent,
		x = params.x or 0,
		y = params.y or 0,
		w = params.w or params.parent.width,
		h = params.h or params.parent.height,
		fill = params.fill or {0, 0, 0, 0},
		stroke = params.stroke or {0, 0, 0, 0.1},
		strokeWidth = params.strokeWidth or 3,
		numX = params.numX or 3,	--Number of gridlines to draw in the x direction
		numY = params.numY or 3,  --Number of gridlines to draw in the y direction
	}

	local myGroup = display.newGroup()
	p.parent:insert( myGroup )
	myGroup.x = p.x
	myGroup.y = p.y
	for m = 1, p.numX do
		local x = ((p.numX+1)/2 - m) * p.w/(p.numX+1)
		local yMin, yMax = p.h/2, -p.h/2
		local myLine = display.newLine( myGroup, x, yMin, x, yMax )
		myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
		myLine.strokeWidth = p.strokeWidth
	end
	for m = 1, p.numY do
		local xMin, xMax = p.w/2, -p.w/2
		local y = ((p.numY+1)/2 - m) * p.h/(p.numY+1)
		local myLine = display.newLine( myGroup, xMin, y, xMax, y )
		myLine:setStrokeColor( p.stroke[1], p.stroke[2], p.stroke[3], p.stroke[4] )
		myLine.strokeWidth = p.strokeWidth
	end
	return myGroup
end

_.drawAxisLabels = function( params )
	local p = {
		parent = params.parent,
		xOffset = params.x or 0,
		yOffset = params.y or 0,
		w = params.w or params.parent.width,
		h = params.h or params.parent.height,
		numX = params.numX or 3,	--Number of gridlines to draw in the x direction
		numY = params.numY or 3,  --Number of gridlines to draw in the y direction
		font = params.font or md.defaultFont,
		fontSize = params.fontSize or md.defaultFontSize,
		fontColor = params.fontColor or {0, 0, 0, 1},
	}

	_.xLabels = display.newGroup()
	p.parent:insert( _.xLabels )
	for m = 1, p.numX+2 do
		local options = {
			parent = _.xLabels,
			text = "",
			x = -((p.numX+3)/2 - m) * p.w/(p.numX+1),
			y = 0,
			font = p.font,
			fontSize = p.fontSize,
		}
		local myText = display.newText( options )
		myText:setFillColor( p.fontColor[1], p.fontColor[2], p.fontColor[3], p.fontColor[4] )
	end
	_.xLabels.x = p.xOffset
	_.xLabels.y = p.yOffset + p.h/2 + 0.75*_.xLabels.height

	_.yLabels = display.newGroup()
	p.parent:insert( _.yLabels )
	for m = 1, p.numY+2 do
		local options = {
			parent = _.yLabels,
			text = "",
			x = -25,
			y = -((p.numY+3)/2 - m) * p.h/(p.numY+1),
			font = p.font,
			fontSize = p.fontSize,
		}
		local myText = display.newText( options )
		myText:setFillColor( p.fontColor[1], p.fontColor[2], p.fontColor[3], p.fontColor[4] )
	end
	_.yLabels.x = p.xOffset - p.w/2 - 5*_.yLabels.width
	_.yLabels.y = p.yOffset

end

_.drawChart = function( params )

	local p = {
		parent = params.parent or display.newGroup(),
		x = params.x or 0,
		y = params.y or 0,
		w = params.w or md.screenW,
		h = params.h or md.screenH,
		fill = params.fill or {0, 0, 0, 0},
		stroke = params.stroke or {0, 0, 0, 0.1},
		strokeWidth = params.strokeWidth or 3,
		font = params.font or md.defaultFont,
		fontSize = params.fontSize or md.defaultFontSize,
		fontColor = params.fontColor or md.defaultFontColor,
		text = "",
		numX = params.numX or 3,	--Number of gridlines to draw in the x direction
		numY = params.numY or 3,  --Number of gridlines to draw in the y direction
	}

	local e = ams.LibID

	--Create the outline around the pulse shape
	_.myContainer = display.newContainer( p.parent, p.w, p.h )
	_.myContainer.x = p.x
	_.myContainer.y = p.y

	--The outline and grid lines get inserted directly into the container
	params.parent = p.parent
	params.x = p.x
	params.y = p.y
	_.drawOutline (params )
	_.drawGridlines( params )

	--Axis labels and the rest go into the parent group
	params.parent = p.parent
	params.x = _.myContainer.x
	params.y = _.myContainer.y
	params.w = _.myContainer.width
	params.h = _.myContainer.height
	_.drawAxisLabels( params )

end
--[[
local function insertMonoCoords( id, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local e = ams.Event[id]
	local lastX
	for m = 1, e.Quantity do
		lastX = coords.x[#coords.x]
		table.insert( coords.x, lastX )
		table.insert( coords.x, lastX+e.Dur1 )
		table.insert( coords.x, lastX+e.Dur1 )
		table.insert( coords.x, lastX+e.Period )

		table.insert( coords.y, -e.Amp1 + offset )
		table.insert( coords.y, -e.Amp1 + offset )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, offset + hold )
	end
end

local function insertAsymmCoords( id, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local e = ams.Event[id]
	local lastX
	for m = 1, e.Quantity do
		lastX = coords.x[#coords.x]
		table.insert( coords.x, lastX )
		table.insert( coords.x, lastX+e.Dur1 )
		table.insert( coords.x, lastX+e.Dur1 )
		table.insert( coords.x, lastX+e.Dur1+e.Intr )
		table.insert( coords.x, lastX+e.Dur1+e.Intr )
		table.insert( coords.x, lastX+e.Dur1+e.Intr+e.Dur2 )
		table.insert( coords.x, lastX+e.Dur1+e.Intr+e.Dur2 )
		table.insert( coords.x, lastX+e.Period )

		table.insert( coords.y, -e.Amp1 + offset )
		table.insert( coords.y, -e.Amp1 + offset )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, -e.Amp2 + offset )
		table.insert( coords.y, -e.Amp2 + offset )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, offset + hold )
	end
end

local function insertBiCoords( id, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local e = ams.Event[id]
	local lastX
	for m = 1, e.Quantity do
		lastX = coords.x[#coords.x]
		table.insert( coords.x, lastX )
		table.insert( coords.x, lastX+e.Dur1 )
		table.insert( coords.x, lastX+e.Dur1 )
		table.insert( coords.x, lastX+e.Dur1+e.Intr )
		table.insert( coords.x, lastX+e.Dur1+e.Intr )
		table.insert( coords.x, lastX+e.Dur1+e.Intr+e.Dur1 )
		table.insert( coords.x, lastX+e.Dur1+e.Intr+e.Dur1 )
		table.insert( coords.x, lastX+e.Period )

		table.insert( coords.y, -e.Amp1 + offset )
		table.insert( coords.y, -e.Amp1 + offset )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, e.Amp1 + offset )
		table.insert( coords.y, e.Amp1 + offset )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, offset + hold )
	end
end

local function insertRampCoords( id, coords, offset, hold )
	offset = offset or 0
	hold = hold or 0
	local e = ams.Event[id]
	local lastX
	for m = 1, e.Quantity do
		lastX = coords.x[#coords.x]

		table.insert( coords.x, lastX+e.Dur1 )
		table.insert( coords.x, lastX+e.Dur1+e.Intr )
		table.insert( coords.x, lastX+e.Dur1+e.Intr+e.Dur2 )
		table.insert( coords.x, lastX+e.Period )

		table.insert( coords.y, -e.Amp1 + offset )
		table.insert( coords.y, -e.Amp2 + offset )
		table.insert( coords.y, offset + hold )
		table.insert( coords.y, offset + hold )
	end
end
--]]
local function updateRects()
		local mr = _.myRects
		local e = ams.Event[ams.LibID]
				
		if e.Type == "monophasic" then
			--Update the locations and width/height for all intermediate points
			for m = 2, 10, 4 do
				mr[m].x = (mr[m-1].x + mr[m+1].x)/2
				mr[m].width = mr[m+1].x - mr[m-1].x - mr[1].width
			end
			for m = 4, 8, 4 do
				mr[m].y = (mr[m-1].y + mr[m+1].y)/2
				mr[m].height = math.abs(mr[m+1].y - mr[m-1].y) - mr[1].width
			end

			--Finally update the amplitudes and durations for this event.
			--e.Delay = calcTime( mr[1].x, mr[3].x )
			e.Dur1 =  calcTime( mr[5].x, mr[7].x, e.Dur1 )
			e.Amp1 =  calcAmplitude( mr[6].y, mr[1].y, e.Amp1 )

		elseif e.Type == "biphasic" then
			--Update the width and height of the bounding rectangles
			for m = 2, 18, 4 do
				mr[m].x = (mr[m-1].x + mr[m+1].x)/2
				mr[m].width = mr[m+1].x - mr[m-1].x - mr[1].width
			end
			for m = 4, 16, 4 do
				mr[m].y = (mr[m-1].y + mr[m+1].y)/2
				mr[m].height = math.abs(mr[m+1].y - mr[m-1].y) - mr[1].width
			end

			--Finally update the amplitudes and durations for this event.
			--e.Delay = calcTime( mr[1].x, mr[3].x )
				e.Dur1 =  calcTime( mr[5].x, mr[7].x, e.Dur1 )
				e.Intr =  calcTime( mr[9].x, mr[11].x, e.Intr )
				--e.Dur2 =  calcTime( mr[13].x, mr[15].x )
				--e.Amp1 =  calcAmplitude( mr[6].y, _.myContainer.y )
				e.Amp1 =  calcAmplitude( mr[6].y, mr[1].y, e.Amp1 )
				--e.Amp2 =  calcAmplitude( mr[14].y, _.myContainer.y )
				
		elseif e.Type == "asymm" then
			--Update the width and height of the bounding rectangles
			for m = 2, 18, 4 do
				mr[m].x = (mr[m-1].x + mr[m+1].x)/2
				mr[m].width = mr[m+1].x - mr[m-1].x - mr[1].width
			end
			for m = 4, 16, 4 do
				mr[m].y = (mr[m-1].y + mr[m+1].y)/2
				mr[m].height = math.abs(mr[m+1].y - mr[m-1].y) - mr[1].width
			end

			--Finally update the amplitudes and durations for this event.
			--e.Delay = calcTime( mr[1].x, mr[3].x )
				e.Dur1 =  calcTime( mr[5].x, mr[7].x, e.Dur1 )
				e.Intr =  calcTime( mr[9].x, mr[11].x, e.Intr )
				e.Dur2 =  calcTime( mr[13].x, mr[15].x, e.Dur2 )
				e.Amp1 =  calcAmplitude( mr[6].y, mr[1].y, e.Amp1 )
				e.Amp2 =  calcAmplitude( mr[14].y, mr[1].y, e.Amp2 )
		elseif e.Type == "ramp" then
			--Update the width and height of all bounding rectangles
			for m = 2, 10, 2 do
				mr[m].x = (mr[m-1].x + mr[m+1].x)/2
				mr[m].width = math.max(mr[m+1].x - mr[m-1].x - mr[1].width, mr[1].width)
				mr[m].y = (mr[m-1].y + mr[m+1].y)/2
				mr[m].height = math.max(math.abs(mr[m+1].y - mr[m-1].y) - mr[1].width, mr[1].width)
			end
			--Finally update the amplitudes and durations for this event.
			--e.Delay = calcTime( mr[1].x, mr[3].x )
			e.Dur1 =  calcTime( mr[3].x, mr[5].x, e.Dur1 )
			e.Intr =  calcTime( mr[5].x, mr[7].x, e.Intr )
			e.Dur2 =  calcTime( mr[7].x, mr[9].x, e.Dur2 )
			e.Amp1 =  calcAmplitude( mr[5].y, mr[1].y, e.Amp1 )
			e.Amp2 =  calcAmplitude( mr[7].y, mr[1].y, e.Amp2 )
		end
	end

_.drawPulse = function( params )

	ams = md.instrumentSettings.current
	local e = ams.Event[ams.LibID]

	local p = {
		parent = params.parent or display.newGroup(),
		x = params.x or 0,
		y = params.y or 0,
		w = params.w or display.contentWidth,
		h = params.h or display.contentHeight,
		fill = params.fill or {0, 0, 0, 0},
		--Set the stroke alpha to greater than 0 to display hit rectangles
		stroke = params.stroke or {0, 0, 0, 0.1},
		strokeWidth = params.strokeWidth or 3,
		pulseType = params.pulseType or e.Type,
	}

	_.myRects = display.newContainer( p.w, p.h )
	_.myRects.x = p.x
	_.myRects.y = p.y
	p.parent:insert( _.myRects )

	--Update the x, y, width, and height of all the rectangles used for touch events.


	--'onRelease' event listener for horRect1
	local function listener(event)

		local t = event.target
		local p= t.parent
		local mr = _.myRects
		local e = ams.Event[ams.LibID]

		if event.phase == "began" then
			mf.dprint( "chartRect" .. t.id .. " touch event detected.")

			--Store the initial positions of all rects, needed for ramp translation
			for m = 1, mr.numChildren do
				mr[m].x0 = mr[m].x
				mr[m].y0 = mr[m].y
			end
			-- set touch focus
			display.getCurrentStage():setFocus( t )
			t.isFocus = true
			-- Reinsert the target so it's at the top of the touch priority list
			t.x0 = t.x
			t.y0 = t.y + _.myRects.y
			t.dx = event.x - t.x
			t.dy = event.y - t.y
		elseif t.isFocus then
			if event.phase == "moved" then
				local margin = 5
				local bounds = _.myRects.contentBounds
				t.x = event.x - t.dx
				t.y = event.y - t.dy

				if e.Type == "monophasic" then --Pulse type 0 is monnophasic
					--Establish the boundaries for range of motion
					if t.id == 1 or t.id == 2 or t.id == 3 or t.id == 4 or t.id == 5
					or t.id == 10 or t.id == 11 then
						bounds.xMin = t.x0
						bounds.xMax = t.x0
					elseif t.id == 3 then
						bounds.xMin = mr[2].x
						bounds.xMax = mr[6].x
					elseif t.id == 4 then
						bounds.xMax = mr[6].x
					elseif t.id == 5 then
						bounds.xMax = mr[6].x
					elseif t.id == 7 then
						bounds.xMin = mr[6].x
						bounds.xMax = mr[11].x
					elseif t.id == 8 then
						bounds.xMin = mr[6].x
						bounds.xMax = mr[11].x
					elseif t.id == 9 then
						bounds.xMin = mr[6].x
						bounds.xMax = mr[11].x
					end
					if t.id == 1 or t.id == 2 or t.id == 3 or t.id == 9 or t.id == 10 or t.id == 11 then
						bounds.yMin = t.y0
						bounds.yMax = t.y0
					end
					--Adjust the bounds to get local coords inside the container
					bounds.xMin = bounds.xMin
					bounds.xMax = bounds.xMax
					bounds.yMin = bounds.yMin - _.myRects.y
					bounds.yMax = bounds.yMax - _.myRects.y
					--Update the event coordinates based on the new boundaries
					if t.x < bounds.xMin then
						t.x = bounds.xMin
					elseif t.x > bounds.xMax then
						t.x = bounds.xMax
					end
					if t.y < bounds.yMin then
						t.y = bounds.yMin
					elseif t.y > bounds.yMax then
						t.y = bounds.yMax
					end
					--Move the all the neighboring points
					if t.id == 1 then  --Edge case, handle it specially
						mr[2].y = t.y
						mr[3].y = t.y
					elseif t.id == 11 then	--Edge case, handle it specially
						mr[9].y = t.y
						mr[10].y = t.y
					elseif (t.id-1)%4 == 0 then	--ids are 1, 5 and 9
						mr[t.id-2].x = t.x
						mr[t.id-1].x = t.x
						mr[t.id+1].y = t.y
						mr[t.id+2].y = t.y
					elseif (t.id-2)%4 == 0 then --ids are 2, 6 and 10
						mr[t.id-1].y = t.y
						mr[t.id+1].y = t.y
					elseif (t.id-3)%4 == 0 then	--ids are 3 and 7
						mr[t.id-2].y = t.y
						mr[t.id-1].y = t.y
						mr[t.id+1].x = t.x
						mr[t.id+2].x = t.x
					elseif t.id % 4 == 0 then	--ids are 4 and 8
						mr[t.id-1].x = t.x
						mr[t.id+1].x = t.x
					end

				elseif e.Type == "biphasic" or e.Type == "asymm" then --Pulse type 2 is biphasic
					--Establish the boundaries for range of motion
					mf.dprint( "Processing Biphasic pulse." )
					if t.id == 1 or t.id == 2 or t.id == 3 or t.id == 4 or t.id == 5
					or t.id == 10 or t.id == 18 or t.id == 19 then
						bounds.xMin = t.x0
						bounds.xMax = t.x0
					elseif t.id == 3 or t.id == 4 or t.id == 5 then
						bounds.xMin = mr[2].x
						bounds.xMax = mr[6].x
					elseif t.id == 7 or t.id == 8 or t.id == 9 then
						bounds.xMin = mr[6].x
						bounds.xMax = mr[10].x
					elseif t.id == 11 or t.id == 12 or t.id == 13 then
						bounds.xMin = mr[10].x
						bounds.xMax = mr[14].x
					elseif t.id == 15 or t.id == 16 or t.id == 17 then
						bounds.xMin = mr[14].x
						bounds.xMax = mr[18].x
					end
					if t.id == 1 or t.id == 2 or t.id == 3 or t.id == 9 or t.id == 10
					or t.id == 11 or t.id == 17 or t.id == 18 or t.id == 19 then
						bounds.yMin = t.y0
						bounds.yMax = t.y0
					end

					--Adjust the bounds to get local coords inside the container
					bounds.xMin = bounds.xMin
					bounds.xMax = bounds.xMax
					bounds.yMin = bounds.yMin - _.myRects.y
					bounds.yMax = bounds.yMax - _.myRects.y
					--Update the event coordinates based on the new boundaries
					if t.x < bounds.xMin then
						t.x = bounds.xMin
					elseif t.x > bounds.xMax then
						t.x = bounds.xMax
					end
					if t.y < bounds.yMin then
						t.y = bounds.yMin
					elseif t.y > bounds.yMax then
						t.y = bounds.yMax
					end

					--Move the all the neighboring points
					if t.id == 1 then  --Edge case, handle it specially
						mr[2].y = t.y
						mr[3].y = t.y
					elseif t.id == 19 then	--Edge case, handle it specially
						mr[17].y = t.y
						mr[18].y = t.y
					elseif (t.id-1)%4 == 0 then	--ids are 1, 5, 9, 13, and 17
						mr[t.id-2].x = t.x
						mr[t.id-1].x = t.x
						mr[t.id+1].y = t.y
						mr[t.id+2].y = t.y
					elseif (t.id-2)%4 == 0 then --ids are 2, 6, 10, 14, and 18
						mr[t.id-1].y = t.y
						mr[t.id+1].y = t.y
						--mr[t.id+2].y = t.y
					elseif (t.id-3)%4 == 0 then	--ids are 3, 7, 11, and 15
						mr[t.id-2].y = t.y
						mr[t.id-1].y = t.y
						mr[t.id+1].x = t.x
						mr[t.id+2].x = t.x
					elseif t.id % 4 == 0 then	--ids are 4, 8, 12, and 16
						mr[t.id-1].x = t.x
						mr[t.id+1].x = t.x
					end
					if e.Type == "biphasic" then
						if t.id == 5 or t.id == 6 or t.id == 7 then
							mr[13].y =  - mr[5].y
							mr[14].y =  - mr[5].y
							mr[15].y =  - mr[5].y
						elseif t.id == 13 or t.id == 14 or t.id ==15 then
							mr[5].y = - mr[13].y
							mr[6].y = - mr[13].y
							mr[7].y = - mr[13].y
						end
						if t.id == 7 or t.id == 8 or t.id == 9 then
							mr[11].x = mr[10].x + (mr[10].x - mr[7].x)
							mr[13].x = mr[10].x + (mr[10].x - mr[7].x)
							mr[12].x = mr[10].x + (mr[10].x - mr[7].x)
						elseif t.id == 11 or t.id == 12 or t.id == 13 then
							mr[7].x = mr[10].x - (mr[11].x - mr[10].x)
							mr[8].x = mr[10].x - (mr[11].x - mr[10].x)
							mr[9].x = mr[10].x - (mr[11].x - mr[10].x)
						end
						if t.id == 15 or t.id == 16 or t.id == 17 then
							local center = (mr[15].x + mr[1].x)/2
							local offset = mr[10].x - mr[7].x
							mr[7].x = center - offset
							mr[8].x = center - offset
							mr[9].x = center - offset
							mr[10].x = center
							mr[11].x = center + offset
							mr[12].x = center + offset
							mr[13].x = center + offset
						end

					end

				elseif e.Type == "ramp" then  --Pulse type 3 is ramp
					--Establish the boundaries for range of motion
					if t.id == 1 or t.id == 2 or t.id == 3 or t.id == 4 or t.id == 10 or t.id == 11 then
						bounds.xMin = t.x0
						bounds.xMax = t.x0
					elseif t.id == 3 then
						bounds.xMin = mr[2].x
						bounds.xMax = mr[5].x
					elseif t.id == 4 then
						bounds.xMin = mr[4].x0 - mr[3].x0 + mr[1].x0
						bounds.xMax = mr[7].x0 - mr[5].x0 + mr[4].x0
					elseif t.id == 5 then
						bounds.xMin = mr[3].x
						bounds.xMax = mr[7].x
					elseif t.id == 6 then
						bounds.xMin = mr[6].x0 - mr[5].x0 + mr[3].x0
						bounds.xMax = mr[9].x0 - mr[7].x0 + mr[6].x0
					elseif t.id == 7 then
						bounds.xMin = mr[5].x
						bounds.xMax = mr[9].x
					elseif t.id == 8 then
						bounds.xMin = mr[8].x0 - mr[7].x0 + mr[5].x0
						bounds.xMax = mr[11].x0 - mr[9].x0 + mr[8].x0
					elseif t.id == 9 then
						bounds.xMin = mr[7].x
						bounds.xMax = mr[11].x
					end

					if t.id == 1 or t.id == 2 or t.id == 3 or t.id == 4 or t.id == 6
					or t.id == 8 or t.id == 9 or t.id == 10 or t.id == 11 then
						bounds.yMin = t.y0
						bounds.yMax = t.y0
					end

					--Adjust the bounds to get local coords inside the container
					bounds.xMin = bounds.xMin
					bounds.xMax = bounds.xMax
					bounds.yMin = bounds.yMin - _.myRects.y
					bounds.yMax = bounds.yMax - _.myRects.y
					--Update the event coordinates based on the new boundaries
					if t.x < bounds.xMin then
						t.x = bounds.xMin
					elseif t.x > bounds.xMax then
						t.x = bounds.xMax
					end
					if t.y < bounds.yMin then
						t.y = bounds.yMin
					elseif t.y > bounds.yMax then
						t.y = bounds.yMax
					end
					--Move the all the neighboring points
					if t.id == 1 then  --Edge case, handle it specially
						mr[2].y = t.y
						mr[3].y = t.y
					elseif t.id == 2 then
						mr[1].y = t.y
						mr[3].y = t.y
					elseif t.id == 3 then
						mr[1].y = t.y
						mr[2].y = t.y
					elseif t.id == 4 then
						mr[3].x = mr[3].x0 + t.x-t.x0
						mr[5].x = mr[5].x0 + t.x-t.x0
					elseif t.id == 6 then
						mr[5].x = mr[5].x0 + t.x-t.x0
						mr[7].x = mr[7].x0 + t.x-t.x0
					elseif t.id == 8 then
						mr[7].x = mr[7].x0 + t.x-t.x0
						mr[9].x = mr[9].x0 + t.x-t.x0
					elseif t.id == 9 then
						mr[10].y = t.y
						mr[11].y = t.y
					elseif t.id == 10 then
						mr[9].y = t.y
						mr[11].y = t.y
					elseif t.id == 11 then	--Edge case, handle it specially
						mr[9].y = t.y
						mr[10].y = t.y
					end
				end
				updateRects()
			elseif event.phase == "ended" or event.phase == "cancelled" then

				-- reset touch focus
				display.getCurrentStage():setFocus( nil )
				t.isFocus = nil
				md.state.updatePulse = true
				md.state.updateEvent = true

			end
		end
		return true	-- indicates successful touch
	end

	local coords
	local delay = 0

	if p.pulseType == "monophasic" then
		coords = {
			x = { 0,
				delay/2,
				delay,
				delay,
				delay,
				delay + e.Dur1/2,
				delay + e.Dur1,
				delay + e.Dur1,
				delay + e.Dur1,
				(delay + e.Dur1 + e.Period)/2,
				delay + e.Period},
			y = { 0,
				0,
				0,
				-e.Amp1/2,
				-e.Amp1,
				-e.Amp1,
				-e.Amp1,
				-e.Amp1/2,
				0,
				0,
				0,},
		}
	elseif p.pulseType == "biphasic" then
		coords = {
			x = { 0,
				delay/2,
				delay,
				delay,
				delay,
				delay + e.Dur1/2,
				delay + e.Dur1,
				delay + e.Dur1,
				delay + e.Dur1,
				delay + e.Dur1 + e.Intr/2,
				delay + e.Dur1 + e.Intr,
				delay + e.Dur1 + e.Intr,
				delay + e.Dur1 + e.Intr,
				delay + e.Dur1 + e.Intr + e.Dur1/2,
				delay + e.Dur1 + e.Intr + e.Dur1,
				delay + e.Dur1 + e.Intr + e.Dur1,
				delay + e.Dur1 + e.Intr + e.Dur1,
				(delay + e.Dur1 + e.Intr + e.Dur1 + e.Period)/2,
				delay + e.Period},
			y = { 0,
				0,
				0,
				-e.Amp1/2,
				-e.Amp1,
				-e.Amp1,
				-e.Amp1,
				-e.Amp1/2,
				0,
				0,
				0,
				e.Amp1/2,
				e.Amp1,
				e.Amp1,
				e.Amp1,
				e.Amp1/2,
				0,
				0,
				0,},
		}
		elseif p.pulseType == "asymm" then
		coords = {
			x = { 0,
				delay/2,
				delay,
				delay,
				delay,
				delay + e.Dur1/2,
				delay + e.Dur1,
				delay + e.Dur1,
				delay + e.Dur1,
				delay + e.Dur1 + e.Intr/2,
				delay + e.Dur1 + e.Intr,
				delay + e.Dur1 + e.Intr,
				delay + e.Dur1 + e.Intr,
				delay + e.Dur1 + e.Intr + e.Dur2/2,
				delay + e.Dur1 + e.Intr + e.Dur2,
				delay + e.Dur1 + e.Intr + e.Dur2,
				delay + e.Dur1 + e.Intr + e.Dur2,
				(delay + e.Dur1 + e.Intr + e.Dur2 + e.Period)/2,
				delay + e.Period},
			y = { 0,
				0,
				0,
				-e.Amp1/2,
				-e.Amp1,
				-e.Amp1,
				-e.Amp1,
				-e.Amp1/2,
				0,
				0,
				0,
				-e.Amp2/2,
				-e.Amp2,
				-e.Amp2,
				-e.Amp2,
				-e.Amp2/2,
				0,
				0,
				0,},
		}
	elseif p.pulseType == "ramp" then
		coords = {
			x = { 0,
				delay/2,
				delay,
				delay + e.Dur1/2,
				delay + e.Dur1,
				delay + e.Dur1 + e.Intr/2,
				delay + e.Dur1 + e.Intr,
				delay + e.Dur1 + e.Intr + e.Dur2/2,
				delay + e.Dur1 + e.Intr + e.Dur2,
				(delay + e.Dur1 + e.Intr + e.Dur2 + e.Period)/2,
				delay + e.Period},
			y = { 0,
				0,
				0,
				-e.Amp1/2,
				-e.Amp1,
				0,
				-e.Amp2,
				-e.Amp2/2,
				0,
				0,
				0,},
		}
	end
	--[[  Changed 4/10/2018 to make the amplitude steps drive the max value
	local max
	if e.Type == "monophasic" or e.Type == "biphasic" then
		max = math.max( math.abs(e.Amp1),md.settings.ampSteps )
	else
		max = math.max( math.abs(e.Amp1), math.abs(e.Amp2), md.settings.ampSteps )
	end
	if md.state.scalingAmplitude then
		--Do nothing here for now
	else
		if max  > 0.95*_.myContainer.height/md.state.ampScale/2 then
			md.state.ampScale = _.myContainer.height/max/4
		elseif max  < 0.05*_.myContainer.height/md.state.ampScale/2 then
			md.state.ampScale = _.myContainer.height/math.max(max, 1)/4
		end
	end
	--]]

	local max
	if e.Type == "monophasic" or e.Type == "biphasic" then
		max = math.abs(e.Amp1)
	else
		max = math.max( math.abs(e.Amp1), math.abs(e.Amp2) )
	end
	
	if md.state.scalingAmplitude then
		--Do nothing here for now
	else
		if max  > 0.95*_.myContainer.height/md.state.ampScale/2 then
			md.state.ampScale = _.myContainer.height/max/4
		elseif max  < 0.05*_.myContainer.height/md.state.ampScale/2 then
			md.state.ampScale = _.myContainer.height/math.max(max, 1)/4
		end
	end
	--Changed 4/1/2018 so that the period is always the max value
	--md.state.timeScale = _.myContainer.width/math.max( e.Period, md.settings.timeSteps )
	md.state.timeScale = _.myContainer.width/e.Period

	for m = 1, #coords.x do
		coords.x[m] = coords.x[m] * md.state.timeScale - _.myContainer.width/2
		coords.y[m] = coords.y[m] * md.state.ampScale
	end

	--Create the bounding box rectangles for dragging the line around
	for m = 1, #coords.x do
		local x = coords.x[m] --+ _.myContainer.x
		local y = coords.y[m] --+ _.myContainer.y
		local myRect = display.newRect( _.myRects, x, y, md.tileW/4, md.tileW/4 )
		myRect:setFillColor( 0, 0, 0, 0 )
		--Set alpha to greater than 0 to display bounding rectangles
		myRect:setStrokeColor( 0 )				
		myRect.strokeWidth = 2
		myRect.alpha = md.state.eventRectAlpha
		myRect.isHitTestable = true		
		myRect.id = m
		myRect:addEventListener( "touch", listener )
	end
	updateRects()

	--Create a dummy chart line.  This gets destroyed on the first enterFrame event.
	_.pulseLine = display.newLine( _.myRects, 0, 0, 0, 0)

end

_.updateChart = function()

	--Update the values of the x axis labels
	local n =  _.xLabels.numChildren
	for m = 1, n do
		--local newValue = md.state.timeScale*(m-1)/(n-1)
		local newValue = ams.Event[ams.LibID].Period*(m-1)/(n-1)
		_.xLabels[m].text = mf.calcDisplayTime( newValue )
	end
	--Update the values of the y axis labels
	n =  _.yLabels.numChildren
	for m = 1, n do
		--local newValue = 2*((n+1)/2 - m) / md.state.ampScale/(n-1)
		local newValue = ((n+1)/2 - m)*_.myContainer.height/ md.state.ampScale/(n-1)
		if ams.Config.Mode == "intCurrent" then
			_.yLabels[m].text = mf.calcDisplayAmps( newValue )
		else
			_.yLabels[m].text = mf.calcDisplayVolts( newValue )
		end
	end

	---[[ Update the alpha on all the rects if it's changed
	local mr = _.myRects
	if mr[1].alpha ~= md.state.eventRectAlpha then
		for m = 1, mr.numChildren do
			mr[m].alpha = md.state.eventRectAlpha
		end			
	end --]]
	
end

_.captureGraph = function()

	local bounds = _.myContainer.contentBounds
	local pic = display.captureBounds( bounds, true )
	local options = {
		filename = "event1.png",
		baseDir = system.DocumentsDirectory,
		backgroundColor = {1},
	}
	display.save( pic, options )
	pic:removeSelf()
	pic = nil

end

---[[
_.updatePulse = function()

	--If the user has selected a new tab this forces the udpate to occurr
	--If not, it's pointing exactly where it was before so no harm done.
	ams = md.instrumentSettings.current

	if md.state.updatePulse then
		md.state.updatePulse = false
		local params = {
			parent = _.myContainer.parent,
			x = _.myContainer.x,
			y = _.myContainer.y,
			w = _.myContainer.width,
			h = _.myContainer.height,
		}
		_.destroyPulse()
		_.drawPulse( params )
		if md.state.running then
			timer.performWithDelay( 100, ams.updateEvent )
		end
	end

	--Remove the old chart line
	if _.pulseLine then
		_.pulseLine:removeSelf()
		_.pulseLine = nil
	end

		--newLine appears to have issues with repeated points that have the same coordinates.
		--Run through the list and remove any dupes
		local coords = { x = {}, y = {} }
		for m = 1, _.myRects.numChildren do
			coords.x[m] = _.myRects[m].x
			coords.y[m] = _.myRects[m].y
		end

	local id = 1
	while id <= #coords.x do
		if coords.x[id] == coords.x[id+1] and coords.y[id] == coords.y[id+1] then
			table.remove( coords.x, id+1 )
			table.remove( coords.y, id+1 )
		else
			id = id+1
		end
	end

	local lineCoords = {}
	for m = 1, #coords.x-1 do
		local midX = (coords.x[m]+coords.x[m]+1)/2
		local midY = (coords.y[m]+coords.y[m]+1)/2
		table.insert( lineCoords, coords.x[m] )
		table.insert( lineCoords, coords.y[m] )
		table.insert( lineCoords, midX )
		table.insert( lineCoords, midY )

	end

	table.insert( lineCoords, coords.x[#coords.x] )
	table.insert( lineCoords, coords.y[#coords.x] )

	--Make sure there are at least 4 numbers left so a valid line can
	--be created.  --Addresses issue reported by end user.
	if #lineCoords >= 4 then
		_.pulseLine = display.newLine( _.myRects, unpack(lineCoords) )
	end

	_.pulseLine:setStrokeColor( 0, 0, 0, 0.7 )
	_.pulseLine.strokeWidth = 5
	_.pulseLine.stroke = { type = "image", filename = "images/Picture4.png" }

end

return _
