-------------------------------------------------
--
-- ams4100-keyboard.lua
--
-- "ams4100-keyboard" class for keyboard level functions and data
--
-------------------------------------------------

local keyboard = {}
local keyboard_mt = { __index = keyboard}	-- metatable
local keyboardKey = require( "keyboardKey" )

local keyboards = {
	frequency = {
		{"1", "2", "3", "", "Back"},
		{"4", "5", "6", "mHz", "OK"},
		{"7", "8", "9", "Hz", "Cancel"},
		{"", "0", ".", "kHz", "Clear"},},
	time = {
		{"1", "2", "3", "", "Back"},
		{"4", "5", "6", "µs", "OK"},
		{"7", "8", "9", "ms", "Cancel"},
		{"", "0", ".", "s", "Clear"},},
	voltage = {
		{"1", "2", "3", "", "Back"},
		{"4", "5", "6", "µV", "OK"},
		{"7", "8", "9", "mV", "Cancel"},
		{"±", "0", ".", "V", "Clear"},},
	current = {
		{"1", "2", "3", "", "Back"},
		{"4", "5", "6", "µA", "OK"},
		{"7", "8", "9", "mA", "Cancel"},
		{"±", "0", ".", "A", "Clear"},},
	unitless = {
		{"1", "2", "3", "Back"},
		{"4", "5", "6", "OK"},
		{"7", "8", "9", "Cancel"},
		{"", "0", "","Clear"},},
}
-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------

local function localKeyboardListener( event )
	-- Dummy placeholder function if parent listener does not exist
end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function keyboard.new( p )	-- constructor

	p = p or {}
	local sW = display.contentWidth
	local sH = display.contentHeight

	local newKeyboard = {
		parent = p.parent or display.newGroup(),
		type = p.type or "unitless",
		midX = p.midX or sW/2,
		midY = p.midY or sH/2,
		w = p.w or sH/10,
		h = p.h or sH/10,
		x = p.x or sW/2,
		y = p.y or sH/2,
		width = p.w or sH/10,
		height = p.h or sH/10,
		r = p.r or sH/100,
		fillColor = p.fillColor or {0.5, 0.5, 0.5, 1},
		stroke = p.stroke or {0.5, 0.5, 0.5, 0.5},
		strokeWidth = p.strokeWidth or sW/100,
		strokeColor = p.strokeColor or {0.5, 0.5, 0.5, 1},
		font = p.font or native.systemFont,
		fontSize = p.fontSize or 0,
		fontColor = p.fontColor or {0, 0, 0, 1},
		text = p.text or "Default",
		align = p.align or "center",
		listener = p.listener or nil,
	}

	local rows = #keyboards[ newKeyboard.type ]
	local cols = #keyboards[ newKeyboard.type ][1]
	newKeyboard.rows = rows
	newKeyboard.cols = cols
	local w = newKeyboard.w
	local h = newKeyboard.h
	local options = {
		parent = newKeyboard.parent,
		w = newKeyboard.w,
		h = newKeyboard.h,
		r = newKeyboard.r,
		fillColor = newKeyboard.fillColor,
		stroke = newKeyboard.stroke,
		strokeWidth = newKeyboard.strokeWidth,
		strokeColor = newKeyboard.strokeColor,
		font = newKeyboard.font,
		fontSize = newKeyboard.fontSize,
		fontColor = newKeyboard.fontColor,
		listener = newKeyboard.listener,
		}

	for m = 1, rows do
		newKeyboard[m] = {}
		for n = 1, cols do
			if keyboards[newKeyboard.type][m][n] ~= "" then
				local panX = newKeyboard.midX - (cols/2-n+0.5)*w*1.1
				local panY = newKeyboard.midY - (rows/2-m+0.5)*h*1.1
				options.x = panX
				options.y = panY
				options.w = newKeyboard.w
				options.text = keyboards[newKeyboard.type][m][n]
				if n == cols then
					options.w = 2*options.w
					options.x = options.x + w
				end
				newKeyboard[m][n] = keyboardKey.new( options )
			end
		end
	end

	return setmetatable( newKeyboard, keyboard_mt )
end

---------------------------------------------------------------------

function keyboard:destroyKeys()
	local s = self

	for m = 1, s.rows do
		for n = 1, s.cols do
			if s[m][n] then
				s[m][n]:destroy()
			end
		end
	end

	s = nil
end

function keyboard:changeType( newType )

	local s = self
	s.type = newType
	s:destroyKeys()
	local newKeyboard = keyboard.new( s )

	return newKeyboard

end


return keyboard