--[[----------------------------------------------------------------------------

ZenphotoAPI.lua
Common code to initiate Zenphoto API requests

------------------------------------------------------------------------------]]
local LrDialogs 		= import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrHttp 			= import 'LrHttp'
local LrMD5 			= import 'LrMD5'
local LrPathUtils 		= import 'LrPathUtils'
local LrTasks			= import 'LrTasks'
local prefs 			= import 'LrPrefs'.prefsForPlugin()
JSON = (assert(loadfile(LrPathUtils.child(_PLUGIN.path, "ZenphotoJSON.lua"))))()
--============================================================================--
ZenphotoAPI = {}

--------------------------------------------------------------------------------

function initRequestParams()
	log:trace('initRequestParams')
	local paramMap = {}

	local username = prefs[instanceID].username
	local password = prefs[instanceID].password
	local loglevel = prefs.logLevel
	
	table.insert( paramMap, { loginUsername = username,
							  loginPassword = password,
							  loglevel = loglevel,
                              checkver = getVersion()
							} )
ZenphotoAPI.getUpdate( getVersion() )
	return paramMap
end


--------------------------------------------------------------------------------

function ZenphotoAPI.authorize( login, password ) 
	log:trace('ZenphotoAPI.authorize')
	log:info('Authorizing '..tostring(login).. ' on host:'.. prefs[instanceID].host)

	local auth = false
	local showMsg = true
	
	local paramMap = initRequestParams()
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.login', paramMap, 20 )
	-- Parse response
	log:debug("authorize.jsonResponse: "..tostring(jsonResponse))
	if not jsonResponse or string.find(jsonResponse, 'html') then
		LrDialogs.message( 'Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
		log:fatal('Server could not be connected!')
		fault = true
		showMsg = false
	end

log:info('jsonResponse', table_show(jsonResponse))

	local result = (JSON:decode( jsonResponse ))
	
	log:info('jsonresult', table_show(result))
	
if result == true then
	log:info('Authorization successful')
		auth = true
		showMsg = false	
	else

	if result.code == '-2' then
		LrDialogs.message( 'Zenphoto version error!', result.message, 'error' )
		log:fatal( 'Zenphoto version error!', result.message, 'error' )
		fault = true
		showMsg = false	
	elseif result.code == '-1' then
	log:info('Authorization failed!')
		auth = false
		showMsg = true
    elseif jsonResponse == '' then
	LrDialogs.message( 'Zenphoto plugin not installed!','error' )
	log:info('Zenphoto plugin not installed!')
		fault = true
		auth = false
		showMsg = true			
	end	
end
	return auth, showMsg
end	

--------------------------------------------------------------------------------

function ZenphotoAPI.uploadImage( filename, params, file )
	log:trace('ZenphotoAPI.uploadImage')
	log:info('Uploading JSON file: ', filename)

	local paramMap = initRequestParams()
		paramMap[1]['filename'] = filename
		paramMap[1]['file'] = file
				
	for key,value in pairs(params) do 
		paramMap[1][key] = value		
	end
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.image.upload', paramMap, 0 )
	log:debug('uploadPhoto.paramMap: '..table_show(paramMap):gsub("(%[\"file\"%]%s*=%s*)%b\"\"", "%1\"********truncated - file data********\""))
	log:debug('uploadPhotoJSON:'..jsonResponse)
	
	return ZenphotoAPI.getTableFromJSON(jsonResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.getAlbums( propertyTable, simple )	
	log:trace('ZenphotoAPI.getAlbums')
	
	local paramMap = initRequestParams()
	if simple then
		--table.insert( paramMap, { simplelist = tostring(simple) } )
			paramMap[1]['simplelist'] = simple
			else 
			paramMap[1]['simplelist'] = false
	end
	
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.album.getList', paramMap, 10 )
	log:debug('getAlbums paramMap: '..table_show(paramMap))
	log:debug('getAlbums: ', jsonResponse)

	if simple == true then
		local result = ZenphotoAPI.getTableFromJSON(jsonResponse, true)
		log:debug('getAlbums result: '..table_show(result))
		local empty = { { title = '- no sub-album -', value = ''} }
		return Utils.joinTables(empty, result)
	else
		return ZenphotoAPI.getTableFromJSON(jsonResponse, false, false)
	end
end

--------------------------------------------------------------------------------

function ZenphotoAPI.getAlbumImages(id)	
	log:trace('ZenphotoAPI.getAlbumImages')

	local paramMap = initRequestParams()
	paramMap[1]['id'] = id
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.album.getImages', paramMap, 10 )
	log:debug('getAlbumImages.paramMap'..table_show(paramMap))
	log:debug('getAlbumImages:'..jsonResponse)
	return ZenphotoAPI.getTableFromJSON(jsonResponse, false, false)	
end

--------------------------------------------------------------------------------

function ZenphotoAPI.getImageComments(id, propertyTable)	
	log:info('ZenphotoAPI.Getimagecomments')

	local zenphotoURLroot = 'http://'.. prefs[instanceID].host..'/'
local paramMap = initRequestParams()
paramMap[1]['id'] = id.remoteId
paramMap[1]['url'] = zenphotoURLroot..id.url
		
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.get.comments', paramMap, 10 )
	log:debug('getImageComments.paramMap '..table_show(paramMap))
	log:debug('getImageComments:'..jsonResponse)
	return ZenphotoAPI.getTableFromJSON(jsonResponse, false, false)	
end
---------------------------------------------------------------------------------
function ZenphotoAPI.getAlbumthumbnail(id, propertyTable)	
	log:info('ZenphotoAPI.getAlbumthumbnail: '..table_show(getImageComments))

	local zenphotoURLroot = 'http://'.. prefs[instanceID].host..'/'
local paramMap = initRequestParams()
paramMap[1]['id'] = id.remoteId

	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.get.thumbnail', paramMap, 10 )
	log:debug('getImageComments.paramMap '..table_show(paramMap))
	log:debug('getImageComments:'..jsonResponse)
	return ZenphotoAPI.getTableFromJSON(jsonResponse, false, false)	
end
---------------------------------------------------------------------------------

function ZenphotoAPI.addComment( propertyTable, params )
log:trace('ZenphotoAPI.addComment')

local paramMap = initRequestParams()
		paramMap[1]['id'] = params.Id
		paramMap[1]['commentText'] = params.commentText
		
		local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.add.comment', paramMap, 10 )
		
		log:debug('addImageComments paramMap : '..table_show(paramMap))		
		log:debug('addImageComment:'..jsonResponse)

	return ZenphotoAPI.getSingleValueJSON(jsonResponse)
end 

---------------------------------------------------------------------------------
function ZenphotoAPI.getImageRating( propertyTable, params )
log:trace('ZenphotoAPI.getImageRating')

local paramMap = initRequestParams()
		paramMap[1]['id'] = params.photoId
		local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.get.ratings', paramMap, 10 )
		
		log:debug('getRating paramMap : '..table_show(paramMap))
		log:debug('getRating:'..jsonResponse)	
			
		local result = (JSON:decode( jsonResponse ))
	
	log:info('getImageRating.jsonresult', table_show(result))	
	return ZenphotoAPI.getSingleValueJSON(jsonResponse)
end 

---------------------------------------------------------------------------------
function ZenphotoAPI.getVersion()
log:trace('ZenphotoAPI.getVersion')

--local paramMap = initRequestParams()
	local paramMap = {}
		local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.get.version', paramMap, 10 )
		
		log:debug('getVersion paramMap : '..table_show(paramMap))
		log:debug('getVersion:'..jsonResponse)	
	return ZenphotoAPI.getSingleValueJSON(jsonResponse)
end

---------------------------------------------------------------------------------
function ZenphotoAPI.chkFunction(param)
log:trace('ZenphotoAPI.chkFunction')

--local paramMap = initRequestParams()
	local paramMap = {}
		table.insert( paramMap, { getFunction = param } )
		local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.chk.func', paramMap, 10 )
		
		log:debug('chkFunction paramMap : '..table_show(paramMap))
		log:debug('chkFunction:'..jsonResponse)	
		--log:debug('chkFunction:'..ZenphotoAPI.getSingleValueJSON(jsonResponse))	
	return ZenphotoAPI.getSingleValueJSON(jsonResponse)
end 

---------------------------------------------------------------------------------
function ZenphotoAPI.getUpdate( version ) 
log:trace('ZenphotoAPI.getUpdate', version)

	local paramMap = {}
	table.insert( paramMap, { sysversion = version } )
		local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.get.update', paramMap, 10 )
		
		log:debug('getUpdate paramMap : '..table_show(paramMap))
		log:debug('getUpdate:'..jsonResponse)
if (jsonResponse == true) then
	local zenphotopluginURL = 'http://'..prefs[instanceID].host..'/plugins/ZenPublisher.php'
	local responseRPC, responseHeaders = LrHttp.post( zenphotopluginURL, 'updateRPC='..prefs.getgitreply, nil, 'POST' )
log:debug('responseHeaders',table_show(responseHeaders))
	log:debug('responseRPC',responseRPC)
	
	if responseHeaders and (responseHeaders.status==500 or responseHeaders.status==401 or responseHeaders.status==400)then
	LrDialogs.message( 'ERROR '..responseHeaders.status..' Server could not be reached!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
	log:debug('ZenphotoAPI.getUpdate - Host Error: '..responseHeaders.status)
	return false;
	end	
end		
	
	return responseRPC
end 

--------------------------------------------------------------------------------

function ZenphotoAPI.deletePhoto(propertyTable, params)
	log:trace('ZenphotoAPI.deletePhoto')

	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
		paramMap[1][key] = value		
	end

	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.image.delete', paramMap, 10 )
		log:debug('deletePhoto: '..table_show(paramMap))
		log:debug("deletePhoto.jsonResponse: " .. jsonResponse)
		
		errors = string.find(jsonResponse, "MySQL Error:")
		if  errors then
			log:fatal('Unable to delete image with id: ' .. paramMap[1].id, jsonResponse, ' critical')
			return "MySQL ERROR: image ID not found or removed."
		end
	return ZenphotoAPI.getSingleValueJSON(jsonResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.deleteAlbum( propertyTable, albumId )
	log:trace('ZenphotoAPI.deleteAlbum')
	log:info('Delete album from server with imageId: ' .. table_show(albumId))

	local paramMap = initRequestParams()
		log:info('deleteAlbum'..table_show(paramMap))
		paramMap[1]['id'] = albumId 	
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.album.delete', paramMap, 10 )
	log:debug('deleteAlbum: ' ..table_show(paramMap))
	log:debug("deleteAlbum.jsonResponse: " .. jsonResponse)
	return ZenphotoAPI.getSingleValueJSON(jsonResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.createAlbum( propertyTable, params )
	log:trace('ZenphotoAPI.createAlbum')
	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
	paramMap[1][key] = value
	end
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.album.create', paramMap, 10 )
	log:debug('createAlbum: '..table_show(paramMap))
	log:debug("createAlbum.jsonResponse: " .. jsonResponse)
	
	return ZenphotoAPI.getTableFromJSON(jsonResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.editAlbum( propertyTable, params )
	log:trace('ZenphotoAPI.editAlbum')
	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
	paramMap[1][key] = value
	end
	
	local jsonResponse = ZenphotoAPI.sendJSONRequest( 'zenphoto.album.edit', paramMap, 10 )
	log:debug('editAlbum.API: '..table_show(paramMap))
	log:debug("editAlbum.jsonResponse: " .. jsonResponse)

	return ZenphotoAPI.getTableFromJSON(jsonResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.initinstanceID( propertyTable )
log:trace( 'ZenphotoAPI.initinstanceID')
	local catalog = import 'LrApplication'.activeCatalog()
	local publishServices = catalog:getPublishServices( _PLUGIN.id )
log:trace( 'initinstanceID'..table_show(publishServices))
		for i, publishService in pairs ( publishServices ) do
			if ( publishService:getName() == propertyTable.LR_publish_connectionName) then
				instanceID = publishService.localIdentifier
			end
		end
	return instanceID
end

function ZenphotoAPI.getTableFromJSON(jsonResponse, formatForUI, allowSingleEntry)
log:trace( 'ZenphotoAPI.getTableFromJSON Main' )

	if formatForUI == nil then formatForUI = false end
	if allowSingleEntry == nil then allowSingleEntry = true end

	if not jsonResponse then
		LrDialogs.message( 'Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
		log:fatal('Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error')
		return ''
	end
		
	local luaTableString = jsonResponse

	if formatForUI then
		local clear = { id = 'value', name = 'title' }
		for key, value in pairs ( clear ) do
			luaTableString = string.gsub(luaTableString,key,value)
		end
	end

	log:debug('luaTableString',table_show(luaTableString))
	resultTable = JSON:decode( luaTableString)
		--[[
	local luaTableFunction = luaTableString and loadstring( luaTableString )
	local _, resultTable = LrFunctionContext.pcallWithEmptyEnvironment( luaTableFunction )

	 --]]
	if resultTable and #resultTable == 1 and allowSingleEntry == true then
		return resultTable[1]
	else
		return resultTable
	end

end

function ZenphotoAPI.getSingleValueJSON(jsonResponse)
log:trace("ZenphotoAPI.getSingleValueJSON")
	return JSON:decode( jsonResponse )
end

--------------------------------------------------------------------------------

	-- handle errors and return the error code and string

function ZenphotoAPI.getJSONError(jsonResponse)
log:trace("ZenphotoAPI.getJSONError")

end
--------------------------------------------------------------------------------

	-- Params are list of maps with keys: paramName, paramType, paramValue
function ZenphotoAPI.sendJSONRequest( methodName, params, timeout)
	log:trace('ZenphotoAPI.sendJSONRequest')
    
	log:debug('ZenphotoAPI.sendJSONRequest-json: '..table_show(params):gsub("(%[\"file\"%]%s*=%s*)%b\"\"", "%1\"********truncated - file data********\""))
	local params = JSON:encode(params)
	params = methodName..'='..encode64(params)
	
local headers = {}
	table.insert( headers, { field = 'User-Agent', value = 'Lightroom Zenphoto Publisher Plugin/('..getVersion()..')' } )
	table.insert( headers, { field = 'Content-Type', value = 'application/x-www-form-urlencoded' } )
	table.insert( headers, { field = 'Content-length', value = trim(tostring( #params) ) } )
	--table.insert( headers, { field = 'Host', value = prefs[instanceID].host} )

	zenphotoURL = 'http://'..prefs[instanceID].host..'/plugins/ZenPublisher/ZenRPC.php'
		log:debug('ZenphotoAPI.sendJSONRequest- url: '..zenphotoURL)
	-- send request
	local responseJSON, responseHeaders = LrHttp.post( zenphotoURL, params, headers, 'POST', timeout )	
	if responseHeaders and (responseHeaders.status==500 or responseHeaders.status==401 or responseHeaders.status==400)then
	LrDialogs.message( 'ERROR '..responseHeaders.status..' Server could not be reached!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
	log:debug('ZenphotoAPI.sendJSONRequest- Host Error: '..responseHeaders.status)
	return ''
	end
	log:debug('sendJSONRequest.headers:', table_show(responseHeaders))
	log:debug('sendJSONRequest.response:', table_show(responseJSON))
	log:debug('paramssent:', table_show(params))
	
	return trim(responseJSON)
end
--------------------------------------------------------------------------------
 --checks headers of a http request for failure/errors, if any are found an error with 
 --error_message is thrown, error_message is written to log and log_message (if any) is written to
 --the log too
 function on_error(headers, error_message, log_message)
	if headers and (headers.error or not (headers.status==200 or headers.status==201)) then

		if headers.status then
			error_message = error_message.." (Code: "..headers.status..")"
		else
			error_message = error_message.." (Error: "..tostring(headers.error)..")"
		end
		
		logger:debug(error_message)
		
		if log_message then
			logger:debug(log_message)
		end
		LrErrors.throwUserError(error_message)
	end	
 end
