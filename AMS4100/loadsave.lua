local _ = {}
local json = require("json")

local DefaultLocation = system.DocumentsDirectory
local RealDefaultLocation = DefaultLocation
local ValidLocations = {
	[system.DocumentsDirectory] = true,
	[system.CachesDirectory] = true,
	[system.TemporaryDirectory] = true,
	[system.ResourceDirectory ] = true,
}

local function parseCSVLine (line,sep)
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos)
				if (c == '"') then txt = txt..'"' end
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end
		end
	end
	return res
end

function _.saveTable(t, filename, location)
	if location and (not ValidLocations[location]) then
		error("Attempted to save a table to an invalid location", 2)
	elseif not location then
		location = DefaultLocation
	end

	local path = system.pathForFile( filename, location)
	local file = io.open(path, "w")
	if file then
		local contents = json.encode(t, {indent=true})
		file:write( contents )
		io.close( file )
		return true
	else
		return false
	end
end

function _.loadCSV(filename, location)
	if location and (not ValidLocations[location]) then
		error("Attempted to load a table from an invalid location", 2)
	elseif not location then
		location = DefaultLocation
	end
	local path = system.pathForFile( filename, location)
	local contents = ""
	local myTable = {}
	local file = io.open( path, "r" )
	if file then
		-- read all contents of file into a string
		for line in file:lines() do
			table.insert( myTable, parseCSVLine( line ) )
		end
		io.close( file )
		return myTable
	end
	return nil
end


function _.loadTable(filename, location)
	if location and (not ValidLocations[location]) then
		error("Attempted to load a table from an invalid location", 2)
	elseif not location then
		location = DefaultLocation
	end
	local path = system.pathForFile( filename, location)
	local contents = ""
	local myTable = {}
	local file = io.open( path, "r" )
	if file then
		-- read all contents of file into a string
		local contents = file:read( "*a" )
		myTable = json.decode(contents);
		io.close( file )
		return myTable
	end
	return nil
end

function _.changeDefault(location)
	if location and (not location) then
		error("Attempted to change the default location to an invalid location", 2)
	elseif not location then
		location = RealDefaultLocation
	end
	DefaultLocation = location
	return true
end

function _.doesFileExist( fname, path )

	local results = false

	local filePath = system.pathForFile( fname, path )

	--filePath will be 'nil' if file doesn't exist and the path is 'system.ResourceDirectory'
	if ( filePath ) then
		filePath = io.open( filePath, "r" )
	end

	if ( filePath ) then
		--clean up file handles
		filePath:close()
		results = true
	else

	end

	return results
end

function _.copyFile( srcName, srcPath, dstName, dstPath, overwrite )

	local results = false

	local srcPathExist = _.doesFileExist( srcName, srcPath )

	if ( srcPathExist == false ) then
		return nil	-- nil = source file not found
	end

	--check to see if destination file already exists
	if not ( overwrite ) then
		if ( fileLib.doesFileExist( dstName, dstPath ) ) then
			return 1	-- 1 = file already exists (don't overwrite)
		end
	end

	--copy the source file to the destination file
	local rfilePath = system.pathForFile( srcName, srcPath )
	local wfilePath = system.pathForFile( dstName, dstPath )

	local rfh = io.open( rfilePath, "rb" )
	local wfh = io.open( wfilePath, "wb" )

	if not ( wfh ) then

		return false
	else
		--read the file from 'system.ResourceDirectory' and write to the destination directory
		local data = rfh:read( "*a" )
		if not ( data ) then

			return false
		else
			if not ( wfh:write( data ) ) then

				return false
			end
		end
	end

	results = 2	-- 2 = file copied successfully!

	--clean up file handles
	rfh:close()
	wfh:close()

	return results
end

return _