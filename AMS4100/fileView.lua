
--
-- Filename: fileViewer.lua
--
-- Copyright: A-M Systems
--
-- Author: JRM
--
-- Description:
-- Functions for reading and displaying config files for the AMS 4100
-- Supports files stored direclty on devices such as phones and tablets
-- and in other locations like Dropbox or the Documents folder on Windows
--
-----------------------------------------------------------------------------------------

local fileView = {}
local fileView_mt = { __index = fileView } --metatable

-----------------------------------------------------------------------------------------
local composer = require( "composer" )
local lfs = require( "lfs" )
local json = require("json")
local widget = require( "widget" )

local ef = require( "exportFunctions" )
local md = require( "myData" )
local mf = require( "myFunctions" )
local ls = require( "loadsave" )

--local tf = require( "tileFunctions" )
local ams = md.instrumentSettings.current
local platform = system.getInfo( "platformName" )

-------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------

local function removeButtonEvent( event )
	local t = event.target

	if event.phase == "ended" then
		local id = event.target.id
		local p = t.parent
		local s = p.parent.parent.parent

		local options = {
			folder = t.parent.pulse.options.event.folder,
			filename = t.parent.pulse.options.event.filename,
		}

		ef.removeFile( options )

		--Traverse up the chain to regenerate the view after
		--deleting the file.
		t.parent:removeSelf()

		s:regenerateView()

	else
		return false
	end
end

local function attrdir (path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            print ("\t "..f)
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                attrdir (f)
            else
                for name, value in pairs(attr) do
                    print (name, value)
                end
            end
        end
    end
end

local function scrollListener(event)

end

-------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------

function fileView.new( p )

	local widget = require( "widget" )

	p = p or {}

	local params = {
		scrollview = {
			x = 		p.scrollview.x or 0,
			y = 		p.scrollview.y or 0,
			width = 	p.scrollview.width or display.contentWidth,
			height = p.scrollview.height or display.contentHeight,
			--scrollWidth = p.scrollview.width or display.contentWidth,
			--scrollHeight = p.scrollview.height or display.contentHeight,
			hideBackground = true,
			hideScrollBar = true,
			--backgroundColor = {0.8, 0.8, 0.8},
			horizontalScrollDisabled = true,
			verticalScrollDisabled = false,
			listener = scrollListener,			
		},
		directory = p.directory or system.DocumentsDirectory,
		listener = p.listener,
	}

	local newFileView = widget.newScrollView( params.scrollview )
	newFileView.oldListing = {".",".."}

	local x = params.scrollview.x
	local y = params.scrollview.y
	local w = params.scrollview.width
	local h = params.scrollview.height
	local r = 0.01*w
	local myRect = display.newRoundedRect( x, y, w, h, r )
	myRect:setFillColor( 1,1,1,0 )
	myRect:setStrokeColor( 0.2 )
	myRect.strokeWidth = 3

	--Store a copy of the parameters in case they're needed later
	newFileView.params = params

	--Insert the fileView into the parent group if it exists
	if p.scrollview.parent then
		p.scrollview.parent:insert( newFileView )
		p.scrollview.parent:insert( myRect )
	end

	-- Create a new amsMaster block for holding the stored settings
	local amsMaster = require( "ams4100-master" )
	newFileView.ams = amsMaster.new()

	-- The following is a trick to allow newFileView to inherit
	-- functions from fileView even though the metatable is
	-- already used by the widgets library
	newFileView.generateView = fileView.generateView
	newFileView.scanDirectory = fileView.scanDirectory
	newFileView.regenerateView = fileView.regenerateView
	return newFileView

end

function fileView:generateView()

	local pf = require( "pulseFunctions" )
	local s = self
	local events = s.ams.stored

	local parent = s
	local w = 0.325*display.contentWidth
	local h = 0.095*display.contentHeight
	local midX = 0.48*s.width
	local midY = 0.6*h
	local panX = 0
	local panY = 0

	s:setScrollHeight( 0 )

	local rows = math.ceil(#events/2)
	local cols = 2
	for m = 1, rows do
		for n = 1, cols do
			--local libRect = display.newGroup()
			panX = midX - (cols/2-n+0.5)*1.1*w
			--panY = midY - (rows/2-m+0.5)*1.1*h
			panY = midY + (m-1)*1.1*h
			local id = n + (m-1)*cols
			--Make sure this event actually exists
			if id <= #events then
				local options = {
					--parent = parent,
					id = id,
					x = panX,
					y = panY,
					w = w,
					h = h,
					event = events[id],
					text = {
						y = -h/4,
						width = 0.8*w,
						align = "left",
						text = events[id].Description,
						fontSize = md.defaultFontSize,
					},
					pulse = {y = h/4, h = h/2},
				}
				local pulse = pf.new( options )
				pulse.outline.isOriginal = true
				pulse.outline.isHitTestable = true
				pulse.outline:addEventListener( "touch", s.params.listener )
				s:insert( pulse.parent )

				if events[id].isDir then
					--Do nothing
				else
					--Add an X icon so pulses can be deleted
					local removeButton = widget.newButton(
						{
							x = 0.47*w,
							y = -0.3*h,
							width = 0.3*h,
							height = 0.3*h,
							defaultFile = "images/entypo-5-3486.png",
							overFile = "images/entypo-5-3486.png",
							id = id,
							onEvent = removeButtonEvent,
						})
					--Insert the group into the scrollview itself
					pulse.parent:insert( removeButton )
				end
			end
		end
	end
	--Disable scrolling if all the panels fit into the scrollview window
	local view = s:getView()

	if #events < 11 then
		s:setIsLocked( true )
		s:scrollToPosition( {y=0} )
	else
		s:setIsLocked( false )
	end

end

function fileView:scanDirectory( directory )

	local s = self
	directory = s.params.directory or directory

	local cmd = lfs.chdir(directory)
	--Make sure the directory actually exists
	if cmd then
		--Directory exists so remove all the existing stored settings
		for m = #s.ams.stored, 1, -1 do
			s.ams:removeStored( m )
		end

		local count = 0
		if md.state.fileview == "localExport" then
			if lfs.chdir(directory) then
				print("Changing to: " .. directory)
			end
			print("My Documents")
			for filename in lfs.dir( "C:\\Users\\Joshua\\Documents" ) do
				print(filename)
			end
			print(directory)
			for filename in lfs.dir( directory ) do
				print(filename)
			end
			
			for filename in lfs.dir( directory ) do
				if (filename == ".") then
					--Do nothing, reference to current directory
				elseif (filename == "..") then
					mf.dprint( filename .. " is a directory" )
					count = count + 1
					--Create a dummy save block to represent the directory
					s.ams:addStored()
					local id = #s.ams.stored
					s.ams.stored[id].folder = directory
					s.ams.stored[id].filename = filename
					s.ams.stored[id].isDir = true
					s.ams.stored[id].Description = filename				
				else
					local fileAttributes, fileError = lfs.attributes(filename)

					if fileAttributes then
						if string.find(fileAttributes.mode, "directory") then
							mf.dprint( filename .. " is a directory" )
							count = count + 1
							--Create a dummy save block to represent the directory
							s.ams:addStored()
							local id = #s.ams.stored
							s.ams.stored[id].folder = directory
							s.ams.stored[id].filename = filename
							s.ams.stored[id].isDir = true
							s.ams.stored[id].Description = filename
						end
					end
				end
			end
		end

		--Then scan over all the files looking for AMS 4100 config files
		for filename in lfs.dir( directory ) do

			mf.dprint( "Found file: " .. filename .. ", Count = " .. count )
			--Check if the file has the right extension
			if string.find( filename, ".ams4100") then
				mf.dprint( "Checking contents of file: " .. filename )
				count = count+1
				--If it does read the first line to see if it matches
				--local path = directory .. "\\" .. file
				local path = ef.getPath( filename, directory )
				mf.dprint( path )
				--local contents = ""
				local myTable = {}
				local file = io.open( path, "r" )
				if file then
					-- read all contents of file into a string
					local contents = file:read( "*l" )
					--Macs apparently don't strip a \r from the line being read
					--Make sure it's explicity excluded
					contents = contents:gsub( "%c", "" )
					if contents == "AMS Model 4100 Configuration File" then
						mf.dprint( "Importing file: " .. filename )
						contents = file:read( "*a" )
						myTable = json.decode(contents);
						io.close( file )
						s.ams:addStored()
						local id = #s.ams.stored
						s.ams.stored[id]:setMenuVals( myTable )
						s.ams.stored[id].path = path
						s.ams.stored[id].folder = directory
						s.ams.stored[id].filename = filename
						s.ams.stored[id].isDir = false
					end
				end
			end
		end
		mf.dprint( count )
	end
end

function fileView:regenerateView( path)

	local s = self
	local group = s._collectorGroup
	if path then
		s.params.directory = path
	end

	for m = group.numChildren, 1, -1 do
		group[m]:removeSelf()
	end
	s:scanDirectory()
	s:generateView()

end


return fileView