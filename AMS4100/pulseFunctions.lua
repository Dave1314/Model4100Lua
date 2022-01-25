-----------------------------------------------------------------------------------------
--
-- Filename: chartFunctions.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for drawing and creating the graphs of pulses
--
-----------------------------------------------------------------------------------------

local gf = require( "graphFunctions" )

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
--
-- NOTE: Code outside of listener functions (below) will only be executed once.
--
-----------------------------------------------------------------------------------------

local pulse = {}
local pulse_mt = { __index = pulse }

local function drawOutline( p )

	local myRect
	if p.r == 0 then
		myRect = display.newRect( p.parent, p.x, p.y, p.w, p.h )
	else
		myRect = display.newRoundedRect( p.parent, p.x, p.y, p.w, p.h, p.r )
	end
	myRect.fill = p.fill
	myRect:setFillColor( unpack( p.fillColor ))
	myRect.stroke = p.stroke
	myRect:setStrokeColor( unpack( p.strokeColor ))
	myRect.strokeWidth = p.strokeWidth
	myRect.isHitTestable = p.isHitTestable
	myRect.isVisible = p.visible
	return myRect

end

local function drawText( p )

	local myText = display.newText( p )
	myText:setFillColor( unpack( p.fontColor ))
	myText.isVisible = p.visible
	return myText

end

local function drawPulse( p )

	local e = p.event
	p.coords = e:getCoords( {getFull = true} )
	local myGraph = gf.new( p )
	return myGraph

end

local function isTrue( p )
	return (p == nil) or (p == true)
end

function pulse.new( options )

	local p = options or {}
	p.options = options.options or {}
	p.outline = options.outline or {}
	p.text = options.text or {}
	p.pulse = options.pulse or {}

	local newPulse = { parent = display.newGroup() }
	newPulse.parent.x = p.x or 0
	newPulse.parent.y = p.y or 0
	if options.parent then
		options.parent:insert( newPulse.parent )
	end

	newPulse.options = {
		parent = newPulse.parent,
		id = p.id or 1,
		x = 0, --p.x or 0,
		y = 0, --p.y or 0,
		w = p.w or 0.065*display.contentWidth,
		h = p.h or 0.065*display.contentHeight,
		r = p.r or 1,
		event = options.event or {},
		getFull = options.getFull,
		getDelay = options.getDelay,
		offset = options.offset or 0,
		hold = options.hold or 0,
	}
	newPulse.options.outline = {
		--parent = newPulse.options.parent,
		parent = newPulse.parent,
		x = p.outline.x or 0,
		y = p.outline.y or 0,
		w = newPulse.options.w,
		h = newPulse.options.h,
		r = newPulse.options.r,
		fill = p.outline.fill or {0, 0, 0, 0},
		fillColor = p.outline.fillColor or {0, 0, 0, 0},
		stroke = p.outline.stroke or {0, 0, 0, 1},
		strokeColor = p.outline.strokeColor or {0.5},
		strokeWidth = p.outline.strokeWidth or 3,
		isHitTestable = isTrue( p.outline.isHitTestable ),
		visible = isTrue( p.outline.visible ),
	}
	newPulse.options.text = {
		--parent = newPulse.options.parent,
		parent = newPulse.parent,
		x = p.text.x or 0, --newPulse.options.w/4,
		y = p.text.y or 0, --newPulse.options.h/4,
		width = p.text.width or nil,
		height = p.text.height or nil,
		align = p.text.align or nil,
		text = p.text.text or "", --"test",
		font = p.text.font or native.systemFont,
		fontSize = p.text.fontSize or 0,
		fontColor = p.text.fontColor or { 0.5, 0.5, 0.5, 1 },
		visible = isTrue( p.text.visible ),
	}
	newPulse.options.pulse = {
		--parent = newPulse.options.parent,
		parent = newPulse.parent,
		event = options.event,
		id = options.id or 1,
		x = p.pulse.x or 0,
		y = p.pulse.y or 0,
		w = p.pulse.w or newPulse.options.w,
		h = p.pulse.h or newPulse.options.h,
		autoscale = true,
		ySymmetry = true,
		visible = true,
		line = {
			coords = p.pulse.coords or {0,0,1,1},
			alpha = options.alpha or 1,
			fill = options.fill or {0, 0, 0, 0},
			stroke = options.stroke or {0, 0, 0, 0.8},
			strokeWidth = options.strokeWidth or 2,
			},
		grid = {
			numX = 0,
			numY = 1,
			visible = true,
		},
		outline = {visible = false},
		label = {visible = false},
	}
	newPulse.parent.pulse = newPulse

	newPulse.outline = drawOutline( newPulse.options.outline )
	newPulse.text = drawText( newPulse.options.text )
	newPulse.pulse = drawPulse( newPulse.options.pulse )

	function newPulse:enterFrame( event )
		local s = self
		if s.options then
			local e = s.options.event
			s:update()
		end
	end

	function newPulse.parent:finalize( event )
		local s = self
		Runtime:removeEventListener( "enterFrame", s.pulse )
		s:removeEventListener( "finalize", s )
	end

	Runtime:addEventListener( "enterFrame", newPulse )
	newPulse.parent:addEventListener( "finalize" )

	return setmetatable( newPulse, pulse_mt )

end

function pulse:copy()
	local s = self
	return pulse.new( s.options )
end

function pulse:update()
	local s = self
	local e = s.options.event
	local options = {
		getFull = s.options.getFull,
		getDelay = s.options.getDelay,
		offset = s.options.offset,
		hold = s.options.hold,
	}

	--Force updating coordinates
	e.updateCoords = true

	if e.updateCoords then
		e.updateCoords = false
		s.pulse.options.line.coords = e:getCoords( options )
	end

	if s.text.text ~= e.Description then
		s.text.text = e.Description
	end

	if e.err then
		s.pulse.options.line.strokeColor = {1, 0, 0, 1}
	else
		s.pulse.options.line.strokeColor = {0, 0, 0, 1}
	end

end

function pulse:destroy()
	local s = self
	--_.pulseLineGroup:removeSelf()
end

function pulse:removeSelf()
	local s = self
	s.outline:removeSelf()
	s.outline = nil
	s.text:removeSelf()
	s.text = nil
	s.pulse:removeSelf()
	s.pulse = nil
	s.parent:removeSelf()
	s.parent = nil
	s.options = {}
	s.options = nil
	s = nil
end


return pulse
