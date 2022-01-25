--Google key.  Paste below when it's created.
--local googleKey = ""


--calculate the aspect ratio of the device
local aspectRatio = display.pixelHeight / display.pixelWidth
application = {
   content = {
      width = aspectRatio > 1.5 and 800 or math.ceil( 1200 / aspectRatio ),
      height = aspectRatio < 1.5 and 1200 or math.ceil( 800 * aspectRatio ),
      --width = aspectRatio > 1.5 and 320 or math.ceil( 480 / aspectRatio ),
      --height = aspectRatio < 1.5 and 480 or math.ceil( 320 * aspectRatio ),
      --scale = "zoomEven",
      fps = 60,

      imageSuffix = {
		["@2x"] = 1.5,
		["@4x"] = 3.0, 
      },
   },
   
	license =
	{
		google =
		{
	--		key = googleKey,
	--		policy = "serverManaged",
		},
	},
	
	notification = 
	{
		iphone = {
			types = {
				"badge", "sound", "alert"
			}
		}
	}   
}