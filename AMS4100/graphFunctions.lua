-------------------------------------------------
--
-- ams4100-graph.lua
--
-- "ams4100-graph" class for graph level functions and data
--
-------------------------------------------------
local graph = {}
local graph_mt = { __index = graph}	-- metatable

local mathMax = math.max
local mathMin = math.min
local stringFormat = string.format

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------
local function getKey( t, val )
	-- Find the key associated with a particular value in a table
	for k,v in pairs( t ) do
		if v == tonumber(val) then
			return k
		end
	end
	return nil
end

local function onMouseEvent( event )
	local mf = require( "myFunctions" )

	mf.dprint( { x = event.x, y = event.y } )

end


local function drawOutline( p )

	local myRect
	if p.r == 0 then
		myRect = display.newRect( p.parent, p.x, p.y,
			p.w-p.strokeWidth, p.h-p.strokeWidth )
	else
		myRect = display.newRoundedRect( p.parent, p.x, p.y,
			p.w-p.strokeWidth, p.h-p.strokeWidth, p.r )
	end
	myRect.fill = p.fill
	myRect:setFillColor( unpack( p.fillColor ))
	myRect.stroke = p.stroke
	myRect:setStrokeColor( unpack( p.strokeColor ))
	myRect.strokeWidth = p.strokeWidth
	myRect.isVisible = p.visible

	return myRect
end

local function drawGridLines( p )

	local myGroup = display.newGroup()
	p.parent:insert( myGroup )
	myGroup.x = p.x
	myGroup.y = p.y
	for m = 1, p.numX do
		local x = ((p.numX+1)/2 - m) * p.w/(p.numX+1)
		local yMin, yMax = p.h/2, -p.h/2
		local myLine = display.newLine( myGroup, x, yMin, x, yMax )
		myLine.stroke = p.stroke
		myLine:setStrokeColor( unpack( p.strokeColor ))
		myLine.strokeWidth = p.strokeWidth
		myLine.isVisible = p.visible
	end
	for m = 1, p.numY do
		local xMin, xMax = p.w/2, -p.w/2
		local y = ((p.numY+1)/2 - m) * p.h/(p.numY+1)
		local myLine = display.newLine( myGroup, xMin, y, xMax, y )
		myLine.stroke = p.stroke
		myLine:setStrokeColor( unpack( p.strokeColor ))
		myLine.strokeWidth = p.strokeWidth
		myLine.isVisible = p.visible
	end
	return myGroup
end

local function drawAxisLabels( p )

	if p.autoscale then
		p.xMax = mathMax( unpack( p.coords.x ))
		p.xMin = mathMin( unpack( p.coords.x ))
		p.yMax = mathMax( unpack( p.coords.y ))
		p.yMin = mathMin( unpack( p.coords.y ))
	end

	local myLabels = display.newGroup()
	p.parent:insert( myLabels )

	local xLabels = display.newGroup()
	myLabels:insert( xLabels )

	for m = 1, p.numX+2 do
		local xText = (p.xMax-p.xMin)*(m-1)/(p.numX+1) + p.xMin
		xText = xText/p.xScale
		xText = stringFormat( p.xFormat, xText ) .. " " .. p.xUnits
		local options = {
			parent = xLabels,
			text = xText ,
			x = -((p.numX+3)/2 - m) * p.w/(p.numX+1),
			y = 0,
			font = p.font,
			fontSize = p.fontSize,
		}
		local myText = display.newText( options )
		myText:setFillColor( unpack( p.fontColor ))
		myText.isVisible = p.visible

	end
	xLabels.x = p.xOffset
	xLabels.y = p.yOffset + p.h/2 + 0.75*xLabels.height

	local yLabels = display.newGroup()
	myLabels:insert( yLabels )

	for m = 1, p.numY+2 do
		local yText = (p.yMax-p.yMin)*(m-1)/(p.numY+1) + p.yMin
		yText = yText/p.yScale
		yText = stringFormat( p.yFormat, yText ) .. " " .. p.yUnits
		local options = {
			parent = yLabels,
			text = yText,
			x = 0,
			y = ((p.numY+3)/2 - m) * p.h/(p.numY+1),
			font = p.font,
			fontSize = p.fontSize,
		}
		local myText = display.newText( options )
		myText:setFillColor( unpack( p.fontColor ))
		myText.isVisible = p.visible
	end
	yLabels.x = p.xOffset - p.w/2 - 0.6*yLabels.width
	yLabels.y = p.yOffset

	return myLabels

end

local function drawLine( p )

	local xCoords = p.coords.x
	local yCoords = p.coords.y

	if p.autoscale then
		--Limit the number of points that have to get plotted.
		p.xMax = xCoords[1]
		p.xMin = xCoords[1]
		p.yMax = yCoords[1]
		p.yMin = yCoords[1]
		for m = 2, #p.coords.x do
			if xCoords[m] > p.xMax then p.xMax = xCoords[m] end
			if xCoords[m] < p.xMin then p.xMin = xCoords[m] end
			if yCoords[m] > p.yMax then p.yMax = yCoords[m] end
			if yCoords[m] < p.yMin then p.yMin = yCoords[m] end
		end
	end

	if p.ySymmetry then
		p.yMax = mathMax( math.abs(p.yMax), math.abs(p.yMin) )
		p.yMin = -p.yMax
	end

	if p.yMin == 0 and p.yMax == 0 then
		p.yScale = 1
	else
		p.yScale = -p.h/(p.yMax-p.yMin)
	end

	if p.xMin == 0 and p.xMax == 0 then
		p.xScale = 1
	else
		p.xScale = p.w/(p.xMax-p.xMin)
	end

	local xOffset = (p.xMax+p.xMin)*p.xScale/2
	local yOffset = (p.yMax+p.yMin)*p.yScale/2

--Build the table of local coordinates
--Also eliminate any duplicate points in the list
	local coords = {
		xCoords[1]*p.xScale - xOffset,
		yCoords[1]*p.yScale - yOffset,}
	local index = 3
	for m = 2, #xCoords do
		local newX = xCoords[m]*p.xScale - xOffset
		local newY = yCoords[m]*p.yScale - yOffset
		if newX ~= coords[#coords-1] or newY ~= coords[#coords] then
			coords[index] = newX
			coords[index+1] = newY
			index = index + 2
		end
	end

	--Store the original settings to determine if the line needs updating
	--later on down the road
	for m = 1, #p.coords.x do
		p.original.coords.x[m] = p.coords.x[m]
		p.original.coords.y[m] = p.coords.y[m]
	end
	p.original.alpha = p.alpha


	local myContainer = display.newContainer( p.parent, p.w, p.h )
--local myContainer = display.newGroup()
	p.parent:insert( myContainer )
	myContainer.x = p.x
	myContainer.y = p.y

	--Plotting more than 500 coordinates gets really slow.  The unpack function also
	--overloads with more than 1000 points.

	local myLine
	--myLine = display.newLine( myContainer, coords[1], coords[2], coords[3], coords[4] )
	---[[
	if #coords >= 4 then
		myLine = display.newLine( myContainer, coords[1], coords[2], coords[3], coords[4] )
	else
		myLine = display.newLine( myContainer, 0, 0, 0, 0 )
	end
	--]]
	for m = 5, #coords, 2 do
		myLine:append( coords[m], coords[m+1] )
	end

	myLine.alpha = p.alpha
	myLine.stroke = p.stroke
	myLine:setStrokeColor( unpack( p.strokeColor ))
	myLine.strokeWidth = p.strokeWidth
	myLine.isVisible = p.visible
	myLine.options = p

	return myContainer
end

local function isTrue( p )
	return (p == nil) or (p == true)
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function graph.new( options )	-- constructor

	local p = options or {}
	p.options = {}
	p.grid = options.grid or {}
	p.label = options.label or {}
	p.outline = options.outline or {}
	p.line = options.line or {}

	local newGraph = { parent = display.newGroup() }
	newGraph.parent.x = p.x or display.contentWidth/2
	newGraph.parent.y = p.y or display.contentWidth/2
	if options.parent then
		options.parent:insert( newGraph.parent )
	end

	newGraph.options = {
		parent = newGraph.parent,
		x = 0, --p.x or display.contentWidth/2,
		y = 0, --p.y or display.contentHeight/2,
		w = p.w or display.contentWidth/2,
		h = p.h or display.contentHeight/2,
		r = p.r or 0,
		coords = p.coords or {
			x = { -1, 1 },
			y = { -1, 1 },
		},
		xMin = p.xMin or -2,
		xMax = p.xMax or 2,
		xScale = p.xScale or 1,
		yMin = p.yMin or -2,
		yMax = p.yMax or 2,
		yScale = p.yScale or 1,
		listener = p.listener or nil,
		autoscale = isTrue( p.autoscale ),
		ySymmetry = isTrue( p.ySymmetry ),
		visible = isTrue( p.visible )
	}
	newGraph.options.grid = {
		parent = newGraph.options.parent,
		x = newGraph.options.x,
		y = newGraph.options.y,
		w = newGraph.options.w,
		h = newGraph.options.h,
		stroke = p.grid.stroke or {},
		strokeColor = p.grid.strokeColor or {0, 0, 0, 0.2},
		strokeWidth = p.grid.strokeWidth or 2,
		numX = p.grid.numX or 3,
		numY = p.grid.numY or 3,
		visible = isTrue( p.grid.visible ),
		ySymmetry = isTrue( p.grid.ySymmetry ),
	}
	newGraph.options.label = {
		parent = newGraph.options.parent,
		xOffset = newGraph.options.x,
		yOffset = newGraph.options.y,
		w = newGraph.options.w,
		h = newGraph.options.h,
		numX = p.grid.numX or 3,
		numY = p.grid.numY or 3,
		font = p.label.font or native.systemFont,
		fontSize = p.label.fontSize or 0,
		fontColor = p.label.color or { 0.5, 0.5, 0.5, 1 },
		xMin = newGraph.options.xMin,
		xMax = newGraph.options.xMax,
		xScale = newGraph.options.xScale,
		yMin = newGraph.options.yMin,
		yMax = newGraph.options.yMax,
		yScale = newGraph.options.yScale,
		xUnits = p.label.xUnits or "",
		xFormat = p.label.xFormat or "%3.2f",
		yUnits = p.label.yUnits or "",
		yFormat = p.label.yFormat or "%3.2f",
		visible = isTrue( p.label.visible ),
	}
	newGraph.options.outline = {
		parent = newGraph.options.parent,
		x = newGraph.options.x,
		y = newGraph.options.y,
		w = newGraph.options.w,
		h = newGraph.options.h,
		r = newGraph.options.r,
		fill = p.outline.fill or {0, 0, 0, 0},
		fillColor = p.outline.fillColor or {0, 0, 0, 0},
		stroke = p.outline.stroke or {0, 0, 0, 1},
		strokeColor = p.outline.strokeColor or {0, 0, 0, 1},
		strokeWidth = p.outline.strokeWidth or 3,
		visible = isTrue( p.outline.visible ),
	}
	newGraph.options.line = {
		parent = newGraph.options.parent,
		x = newGraph.options.x,
		y = newGraph.options.y,
		w = newGraph.options.w,
		h = newGraph.options.h,
		xMin = newGraph.options.xMin,
		xMax = newGraph.options.xMax,
		xScale = newGraph.options.xScale,
		yMin = newGraph.options.yMin,
		yMax = newGraph.options.yMax,
		yScale = newGraph.options.yScale,
		autoscale = newGraph.options.autoscale,
		ySymmetry = newGraph.options.ySymmetry,
		coords = newGraph.options.coords,
		alpha = options.line.alpha or 1,
		fill = options.line.fill or {0, 0, 0, 0},
		fillColor = options.line.fillColor or {1, 1, 1, 1},
		stroke = options.line.stroke or {0, 0, 0, 1},
		strokeColor = options.line.strokeColor or {0, 0, 0, 1},
		strokeWidth = options.line.strokeWidth or 3,
		visible = isTrue( options.line.visible ),
	}

	--Copy the original coordinates into the options to detect
	--if the line needs to be redrawn
	newGraph.options.line.original = {
		alpha = newGraph.options.line.alpha,
		stroke = newGraph.options.line.stroke,
		strokeWidth = newGraph.options.line.strokeWidth,
		strokeColor = newGraph.options.line.strokeColor,
		coords = {x = {}, y = {}}}

	newGraph.parent.graph = newGraph
	newGraph.outline = drawOutline( newGraph.options.outline )
	newGraph.grid = drawGridLines( newGraph.options.grid )
	newGraph.labels = drawAxisLabels( newGraph.options.label )
	newGraph.line = drawLine( newGraph.options.line )

	function newGraph:enterFrame( event )
		local s = self
		if s.options.line.visible then s:updateLine() end
		if s.options.label.visible then s:updateAxisLabels() end
	end

	function newGraph.parent:finalize( event )
		local s = self
		Runtime:removeEventListener( "enterFrame", s.graph )
		s:removeEventListener( "finalize", s )
	end

	Runtime:addEventListener( "enterFrame", newGraph )
	newGraph.parent:addEventListener( "finalize" )

	return setmetatable( newGraph, graph_mt )
end

---------------------------------------------------------------------

function graph:destroyLine()
	local s = self
	if s.line then
		s.line:removeSelf()
		s.line = nil
	end
end

function graph:destroyGridLines()
	local s = self
	if s.grid then
		s.grid:removeSelf()
		s.grid = nil
	end
end

function graph:destroyOutline()
	local s = self
	if s.outline then
		s.outline:removeSelf()
		s.outline = nil
	end
end

function graph:destroyLabels()
	local s = self
	if s.labels then
		s.labels:removeSelf()
		s.labels = nil
	end
end

function graph:removeSelf()
	local s = self
	if s then
		Runtime:removeEventListener( "enterFrame", s )
		s:destroyOutline()
		s:destroyGridLines()
		s:destroyLabels()
		s:destroyLine()
		s.parent:removeSelf()
		s.parent = nil
		s = nil
	end
end

function graph:updateLine()
	local s = self

	local needsUpdate = false

	if s.options.line.original.alpha ~= s.options.line.alpha then
		needsUpdate = true
	end

	if #s.options.line.original.coords.x ~= #s.options.line.coords.x then
		needsUpdate = true
	else
		local endM = math.max( #s.options.line.original.coords.x, #s.options.line.coords.x)
		for m = 1, endM do
			if s.options.line.coords.x[m] ~= s.options.line.original.coords.x[m] or
			s.options.line.coords.y[m] ~= s.options.line.original.coords.y[m] then
				needsUpdate = true
				break
			end
		end
	end
	--]]
	--needsUpdate = true
	if needsUpdate then
		s:destroyLine()
		s.line = drawLine( s.options.line )
	end
end

function graph:updateAxisLabels()
	local s = self
	s:destroyLabels()
	s.labels = drawAxisLabels( s.options.label )
end

return graph