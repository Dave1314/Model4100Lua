-------------------------------------------------
--
-- ams4100-keyboard.lua
--
-- "ams4100-keyboard" class for keyboard level functions and data
--
-------------------------------------------------

local keyboardKey = {}
local keyboardKey_mt = { __index = keyboardKey}	-- metatable

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------

local function localKeyListener( event )

	local t = event.target
	-- Dummy placeholder function if parent listener does not exist
	if t.listener then
		return t.listener( event )
	end

end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function keyboardKey.new( p )	-- constructor

	p = p or {}
	local sW = display.contentWidth
	local sH = display.contentHeight

	local newKey = {
		parent = p.parent or display.newGroup(),
		x = p.x or sW/2,
		y = p.y or sH/2,
		width = p.w or sH/10,
		height = p.h or sH/10,
		r = p.r or sH/100,
		fillColor = p.fillColor or {0.5, 0.5, 0.5, 0.5},
		stroke = p.stroke or {0.5, 0.5, 0.5, 0.5},
		strokeWidth = p.strokeWidth or sW/10,
		strokeColor = p.strokeColor or {0.5, 0.5, 0.5, 0.5},
		font = p.font or native.systemFont,
		fontSize = p.fontSize or 0,
		fontColor = p.fontColor or {0, 0, 0, 1},
		text = p.text or "Default",
		align = p.align or "center",
		listener = p.listener or nil,
		}

	newKey.background = display.newRoundedRect( newKey.parent, newKey.x, newKey.y,
		newKey.width, newKey.height, newKey.r )
	newKey.background:setFillColor( unpack( newKey.fillColor ))
	newKey.background.stroke = p.stroke
	newKey.background.strokeWidth = p.strokeWidth
	newKey.background:setStrokeColor( unpack( newKey.strokeColor ))
	newKey.background.id = newKey.text
	newKey.background:addEventListener( "touch", localKeyListener )
	newKey.background.listener = newKey.listener
	--newKey.background.stroke.effect = "filter.blur"

	newKey.height = 0
	newKey.text = display.newText( newKey )
	newKey.text:setFillColor( unpack( newKey.fontColor ))

	return setmetatable( newKey, keyboardKey_mt )
end

---------------------------------------------------------------------

function keyboardKey:destroy()

	local s = self

	s.background:removeEventListener( "touch", localKeyListener )
	s.background:removeSelf()
	s.background = nil
	s.text:removeSelf()
	s.text = nil

end

---------------------------------------------------------------------

return keyboardKey