-------------------------------------------------
--
-- dropdownListBox.lua
--
-- Create a drop down list box from a group of display objects.
--
-------------------------------------------------

local dropdown = {}
local dropdown_mt = { __index = dropdown}	-- metatable

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------

-- Deletes a token from file.
local function deleteToken( tokenType )

	local path = system.pathForFile( tokenType, system.DocumentsDirectory )
	os.remove( path )

end


---------------------------------------------------------------------
-- PUBLIC FUNCTIONS
---------------------------------------------------------------------
function dropdown.new( p )	-- constructor

	local options = {}
	p = p or {}
	
	options = {
		parent = p.parent 	or display.newGroup(),
		width = 	p.width 		or display.contentWidth,
		height = p.height 	or display.contentHeight,
		x = 		p.x 			or display.contentCenterX,
		y = 		p.y 			or display.contentCenterY,
		group =	p.group 		or display.newGroup(),
	}
	if options.group.numChildren > 0 then
		options.width = p.width or options.group[1].contentWidth
		options.height = p.height or options.group[1].contentHeight
	end
	
	options.original = {
		x = 		options.x,
		y = 		options.y,
		width = 	options.width,
		height = options.height,
	}
	
	local newDropdown= display.newContainer( options.parent, options.width, options.height )
	newDropdown.x = p.x or display.contentCenterX
	newDropdown.y = p.y or display.contentCenterY
	
	newDropdown.anchorY = 0
	
	--Create a background element to help highlight container size
	newDropdown.bg = display.newRect( 0, 0, display.contentWidth, display.contentHeight )
	newDropdown.bg:setFillColor( 0, 0.1 )
	newDropdown:insert( newDropdown.bg )
	
	--Insert the group into the container
	newDropdown:insert( options.group )
	newDropdown.group = options.group
	
	--Store the options if a copy of this config needs to be created
	newDropdown.options = options
	
	--Map the private class functions to externally visible functions
	--This mapping prevents all the functions getting duplicated each 
	--time a new box is created without the need to override the 
	--metatable of the container.
	newDropdown.getContentBounds = dropdown.getContentBounds
	newDropdown.show = dropdown.show
	newDropdown.hide = dropdown.hide
	
	return newDropdown
end

---------------------------------------------------------------------

function dropdown:listener( p )
	local s = self
	s.options.listener()
end

function dropdown:show( p )
	
	local s = self
	p = p or {}
	local g = s.group
	local o = s.options.original
	
	local options = {
		time = p.time or 100,
		x = p.x or s.x,
		--y = p.y or s.y + (p.height or s.group.contentHeight)/2,
		y = s.y, -- + s.group.contentHeight/(s.group.numChildren-1),
		width = p.width or s.group.contentWidth,
		height = p.height or s.group.contentHeight,
	}
	transition.to( s, options )	
	---[[
	options = {
		time = options.time,
		y = -options.height/2 + s.group[1].contentHeight/2, 
		onComplete = function()
			print( s.y, s.height, 
				s.group.y, s.group.contentHeight, 
				s.group[1].y, s.group[1].contentHeight )		
			end}
	transition.to( s.group, options )	
	--]]

end

function dropdown:hide()
	local s = self
	local o = s.options.original
	
	local options = {
		time = 100,
		x = o.x,
		y = o.y,
		width = o.width,
		height = o.height,
	}
	transition.to( s, options )
	---[[
	options = {
		time = options.time,
		y = 0,
		onComplete = function()
			print( s.y, s.height, s.group.y, s.group.contentHeight,
				s.group[1].y, s.group[1].contentHeight)		
			end}
	transition.to( s.group, options )		
	--]]
	
end

---------------------------------------------------------------------

function dropdown:getContentBounds()
	local s = self
	local bounds = {
		xMin = s.x - s.width/2,
		xMax = s.x + s.width/2,
		yMin = s.y - s.height/2,
		yMax = s.y + s.height/2,
	}
	return bounds
end

return dropdown