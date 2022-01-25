
local composer = require( "composer" )
local scene = composer.newScene()

local md = require( "myData" )
local mf = require( "myFunctions" )
local bk
local logo
local w = display.contentWidth
local h = display.contentHeight

function scene:create( event )
	local sceneGroup = self.view

	--Background rectangle
	bk = display.newRect(sceneGroup, w/2, h/2, w, h )
	bk:setFillColor( 1, 1, 1 )

	local logoWidth = 0.4*w
	local logoHeight = 86/209*logoWidth
	logo = display.newRect( sceneGroup, w/2, h/2, logoWidth, logoHeight )
	logo.fill = {type = "image", filename = "images/amslogo.png" }

end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	local function moveOn()
		composer.gotoScene( "scene_train", {effect = "fade", time = "250"} )
	end

	if ( phase == "will" ) then
	elseif ( phase == "did" ) then
		timer.performWithDelay( 1500, moveOn )
	end

end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
	elseif ( phase == "did" ) then
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