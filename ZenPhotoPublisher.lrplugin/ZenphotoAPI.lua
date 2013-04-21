--[[----------------------------------------------------------------------------

ZenphotoAPI.lua
Common code to initiate Zenphoto API requests

------------------------------------------------------------------------------]]
local LrDialogs 		= import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrHttp 			= import 'LrHttp'
local LrMD5 			= import 'LrMD5'
local LrPathUtils 		= import 'LrPathUtils'
local LrXml 			= import 'LrXml'
local prefs 			= import 'LrPrefs'.prefsForPlugin()

--============================================================================--

ZenphotoAPI = {}

--------------------------------------------------------------------------------

function initRequestParams()
	log:info('initRequestParams')
	local paramMap = {}

	local username = prefs.instanceTable[publishServiceID].username
	local password = prefs.instanceTable[publishServiceID].password
	local loglevel = prefs.logLevel

	table.insert( paramMap, { paramName = 'loginUsername', paramType = 'string', paramValue = username } )
	table.insert( paramMap, { paramName = 'loginPassword', paramType = 'string', paramValue = password } )
	table.insert( paramMap, { paramName = 'loglevel', paramType = 'string', paramValue = loglevel } )
	return paramMap
end


--------------------------------------------------------------------------------

function ZenphotoAPI.authorize( login, password ) 
	log:info('Authorizing with Zenphoto... Username:'..tostring(login), 'password:'..tostring(password), 'host:'..prefs.instanceTable[publishServiceID].host)

	local auth = false
	local showMsg = true
	
	local paramMap = initRequestParams()
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.login', paramMap, true )
	-- Parse response
	log:debug("authorize.xmlResponse: "..tostring(xmlResponse))
	if not xmlResponse or string.find(xmlResponse, 'html') then
		LrDialogs.message( 'Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
		log:fatal('Server could not be connected!')
		fault = true
		showMsg = false
	end
	local faltString, faultCode = ZenphotoAPI.getXMLError(xmlResponse)
	--log:fatal("faultCode")
	if faultCode == '-2' then
		LrDialogs.message( 'Zenphoto version error!', faltString, 'error' )
		log:fatal( 'Zenphoto version error!', faltString, 'error' )
		fault = true
		showMsg = false	
	end

	if faultCode == '-1' then
	log:info('Authorization failed!')
		auth = false
		showMsg = true		
	else
		log:info('Authorization successful')
		auth = true
		showMsg = false	
	end	

	return auth, showMsg
end	

--------------------------------------------------------------------------------

function ZenphotoAPI.uploadPhoto( filePath, params )
	log:info('uploadPhoto: ' .. filePath)
	log:debug('Uploading params: ' .. table_show(params))

	local err = ZenphotoAPI.uploadFile( filePath )
	
	if err then return nil, err end

	local filename = LrPathUtils.leafName( filePath )	

	local paramMap = initRequestParams()
	table.insert( paramMap, { paramName = 'filename', paramType = 'string', paramValue = filename } )
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end

	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.image.upload', paramMap, true )

	log:debug('uploadPhoto:'..xmlResponse)
	
	return ZenphotoAPI.getTableFromXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.uploadXMLPhoto( filename, params, file )
	log:info('Uploading XML photo: ' .. filename)

	local paramMap = initRequestParams()
	table.insert( paramMap, { paramName = 'filename',		paramType = 'string', paramValue = filename } )
	table.insert( paramMap, { paramName = 'file',			paramType = 'string', paramValue = file } )
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.image.uploadXML', paramMap, true )
	log:debug('uploadPhoto.paramMap: '..table_show(paramMap))
	log:debug('uploadPhotoXML:'..xmlResponse)
	
	return ZenphotoAPI.getTableFromXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.getAlbums( propertyTable, simple )	
	log:info('ZenphotoAPI.getAlbums'..table_show(propertyTable))
	
	local paramMap = initRequestParams()
	if simple then
		table.insert( paramMap, { paramName = 'simplelist', paramType = 'string', paramValue = tostring(simple) } )
	end
	
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.getList', paramMap, true )
	log:debug('getAlbums paramMap: '..table_show(paramMap))
	log:debug('getAlbums: '..xmlResponse)

	if simple == true then
		local result = ZenphotoAPI.getTableFromXML(xmlResponse, true)
		local empty = { { title = '- no sub-album -', value = ''} }
		return Utils.joinTables(empty, result)
	else
		return ZenphotoAPI.getTableFromXML(xmlResponse, false, false)	
	end
end

--------------------------------------------------------------------------------

function ZenphotoAPI.getAlbumImages(id)	
	log:info('Get images from album')

	local paramMap = initRequestParams()
	table.insert( paramMap, { paramName = 'id',	paramType = 'string', paramValue = id } )
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.getImages', paramMap, true )
	log:debug('getAlbumImages.paramMap'..table_show(paramMap))
	log:debug('getAlbumImages:'..xmlResponse)
	return ZenphotoAPI.getTableFromXML(xmlResponse, false, false)	
end

--------------------------------------------------------------------------------

function ZenphotoAPI.getImageComments(id, propertyTable)	
	log:info('ZenphotoAPI.Getimagecomments: '..table_show(getImageComments))

	local zenphotoURLroot = 'http://'..prefs.instanceTable[publishServiceID].host..'/'
local paramMap = initRequestParams()
		table.insert( paramMap, { paramName = 'id', paramType = 'string', paramValue = id.remoteId } )
 		table.insert( paramMap, { paramName = 'url', paramType = 'string', paramValue = zenphotoURLroot..id.url } ) 
		
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.get.comments', paramMap, true )
	log:debug('getImageComments.paramMap '..table_show(paramMap))
	log:debug('getImageComments:'..xmlResponse)
	return ZenphotoAPI.getTableFromXML(xmlResponse, false, false)	
end

---------------------------------------------------------------------------------
function ZenphotoAPI.addComment( propertyTable, params )
log:info('ZenphotoAPI.addComment '..table_show(params))

local paramMap = initRequestParams()
		table.insert( paramMap, { paramName = 'id', paramType = 'string', paramValue = params.Id } ) 
		table.insert( paramMap, { paramName = 'commentText', paramType = 'string', paramValue = params.commentText } ) 
		local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.add.comment', paramMap, true )
		
		log:info('addImageComments paramMap : '..table_show(paramMap))		
		log:debug('addImageComment:'..xmlResponse)
--[[function getnum(_index)
log _index
end
table.foreachi( id , getnum)--]]	
	return ZenphotoAPI.getSingleValueXML(xmlResponse)
end 

---------------------------------------------------------------------------------
function ZenphotoAPI.getImageRating( propertyTable, params )
log:info('ZenphotoAPI.getImageRating: '.. table_show(params))

local paramMap = initRequestParams()
		table.insert( paramMap, { paramName = 'id', paramType = 'string', paramValue = params.photoId } ) 
		local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.get.ratings', paramMap, true )
		
		log:debug('getRating paramMap : '..table_show(paramMap))
		log:debug('getRating:'..xmlResponse)	
	return ZenphotoAPI.getSingleValueXML(xmlResponse)
end 

--------------------------------------------------------------------------------

function ZenphotoAPI.deletePhoto(propertyTable, params)
	log:info('Delete photo from server')
	
	ZenphotoAPI.initPublishServiceID(propertyTable)

	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end

	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.image.delete', paramMap, true )
		log:debug('deletePhoto: '..table_show(paramMap))
		log:debug("deletePhoto.xmlResponse: " .. xmlResponse)
	
	return ZenphotoAPI.getSingleValueXML(xmlResponse)
end
--------------------------------------------------------------------------------

function ZenphotoAPI.deleteAlbum( propertyTable, albumId )
	log:info('Delete album from server with imageId: ' .. table_show(albumId))

	local paramMap = initRequestParams()
		log:info('deleteAlbum'..table_show(paramMap))
	table.insert( paramMap, { paramName = 'id', paramType = 'string', paramValue = albumId } )
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.delete', paramMap, true )
	log:debug('deleteAlbum: ' ..table_show(paramMap))
	log:debug("deleteAlbum.xmlResponse: " .. xmlResponse)
	return ZenphotoAPI.getSingleValueXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.createAlbum( propertyTable, params )
	log:info('Create a new album: ' .. table_show(params))
	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.create', paramMap, true )
	log:debug('createAlbum: '..table_show(paramMap))
	log:debug("createAlbum.xmlResponse: " .. xmlResponse)
	
	return ZenphotoAPI.getTableFromXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.editAlbum( propertyTable, params )
	log:info('Edit Zenphoto album: '..table_show(params))
	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.edit', paramMap, true )
	log:debug('editAlbum.API: '..table_show(paramMap))
	log:debug("editAlbum.xmlResponse: " .. xmlResponse)

	return ZenphotoAPI.getTableFromXML(xmlResponse)
end

--------------------------------------------------------------------------------


function ZenphotoAPI.initPublishServiceID( propertyTable )
log:trace( 'initPublishServiceID')
	local catalog = import 'LrApplication'.activeCatalog()
	local publishServices = catalog:getPublishServices( _PLUGIN.id )
log:trace( 'initPublishServiceID'..table_show(publishServices))
		for i, publishService in pairs ( publishServices ) do
			if ( publishService:getName() == propertyTable.LR_publish_connectionName) then
				publishServiceID = publishService.localIdentifier
			end
		end
	return publishServiceID
end

function ZenphotoAPI.getTableFromXML(xmlResponse, formatForUI, allowSingleEntry)
log:trace( 'ZenphotoAPI.getTableFromXML Main' )
	if formatForUI == nil then formatForUI = false end
	if allowSingleEntry == nil then allowSingleEntry = true end

	if not xmlResponse then
		LrDialogs.message( 'Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
		log:fatal('Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error')
		return {}
	end

	--log:debug("Debug getTableFromXML:"..xmlResponse)
	
	local responseDocument = LrXml.parseXml( xmlResponse, true )
	responseDocument = responseDocument:childAtIndex(1)

	-- show when image was not found
	if responseDocument:name() == "fault" then
	log:info ('show when image was not found')
		return nil, ZenphotoAPI.getXMLError(xmlResponse)
	end

	local xslt = [[
				<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output method="text"/>
				<xsl:template match="param">
					return {<xsl:apply-templates />
				}
				</xsl:template>
				<xsl:template match="struct">
					{
						<xsl:for-each select="member">
							<xsl:value-of select="name"/> = "<xsl:value-of select="value"/>", 
						</xsl:for-each>
					},
				</xsl:template>
				</xsl:stylesheet>
			]]
		
	local luaTableString = responseDocument:transform( xslt )

	if formatForUI then
		local clear = { id = 'value', name = 'title' }
		for key, value in pairs ( clear ) do
			luaTableString = string.gsub(luaTableString,key,value)
		end
	end

	--log:debug(luaTableString)
	
	local luaTableFunction = luaTableString and loadstring( luaTableString )
	local _, resultTable = LrFunctionContext.pcallWithEmptyEnvironment( luaTableFunction )
	
	if resultTable and #resultTable == 1 and allowSingleEntry == true then
		return decode64(resultTable[1])
	else
		return decode64(resultTable)
	end
end

function ZenphotoAPI.getListFromXML(xmlResponse)
log:trace( 'getListFromXML' )
	local responseDocument = LrXml.parseXml( xmlResponse, true )
	responseDocument = responseDocument:childAtIndex(1)

	-- show when image was not found
	if responseDocument:name() == "fault" then
		error(ZenphotoAPI.getXMLError(xmlResponse))
		log:fatal(ZenphotoAPI.getXMLError(xmlResponse))
	end

	local xslt = [[
				<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
				<xsl:output method="text"/>
				<xsl:template match="param">
					return {<xsl:apply-templates />
				}
				</xsl:template>
				<xsl:template match="data">
				<xsl:for-each select="value">
					"<xsl:value-of select="."/>", 
				</xsl:for-each>
				</xsl:template>
				</xsl:stylesheet>
			]]
		
	local luaTableString = responseDocument:transform( xslt )

	local luaTableFunction = luaTableString and loadstring( luaTableString )
	local _, resultTable = LrFunctionContext.pcallWithEmptyEnvironment( luaTableFunction )
	
	return decode64(resultTable)
end

function ZenphotoAPI.getSingleValueXML(xmlResponse)
log:trace("ZenphotoAPI.getSingleValueXML")
	local responseDocument = LrXml.parseXml( xmlResponse, true )
	responseDocument = responseDocument:childAtIndex(1)

	-- show when image was not found
	if responseDocument:name() == "fault" then
		log:debug('image was not found err'..ZenphotoAPI.getXMLError(xmlResponse))
	end

	local responseDocument = LrXml.parseXml(xmlResponse)
	local transformString = [[
		<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
			<xsl:output method="text"/>
			<xsl:template match="methodResponse/params/param">
				<xsl:value-of select="."/>
			</xsl:template>
		</xsl:stylesheet>
	]]
	local responseString = responseDocument:transform(transformString)
	return trim(responseString)
end

--------------------------------------------------------------------------------

	-- handle errors and return the error code and string

function ZenphotoAPI.getXMLError(xmlResponse)
log:trace("ZenphotoAPI.getXMLError"..xmlResponse)
	local responseDocument = LrXml.parseXml(xmlResponse)
log:trace("responseDocument")
log:debug("xmlResponse.getXMLError: " ..xmlResponse)
	local xslt = [[
				<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
					<xsl:output method="text"/>
					<xsl:template match="struct">
						return {
							<xsl:for-each select="member">
								<xsl:value-of select="name"/> = "<xsl:value-of select="value"/>", 
							</xsl:for-each>
						}
					</xsl:template>
				</xsl:stylesheet>
				]]
	local luaTableString = responseDocument:transform( xslt )
	--
	-- if no error and result was true
	--
	if luaTableString == '1' then return end

	
	local luaTableFunction = luaTableString and loadstring( luaTableString )
	local _, resultTable = LrFunctionContext.pcallWithEmptyEnvironment( luaTableFunction )
	
	if resultTable.faultCode == '-32700' then
		resultTable.faultString = 'HTML tags, like "<p>" etc., are only allowed in the description!'
	end
	log:trace("resultTable" .. resultTable.faultString, resultTable.faultCode)
	return resultTable.faultString, resultTable.faultCode
end
--------------------------------------------------------------------------------

	-- Params are list of maps with keys: paramName, paramType, paramValue

function ZenphotoAPI.sendXMLRequest( methodName, params )
	log:trace("ZenphotoAPI.sendXMLRequest")
	log:trace("ZenphotoAPI.sendXMLRequest-methodName"..table_show(methodName))
	log:trace("ZenphotoAPI.sendXMLRequest-params"..table_show(params))
		
	local params = encode64(params)
	
	local xmlBuilder = LrXml.createXmlBuilder( false )
	xmlBuilder:beginBlock( 'methodCall' )
	
	xmlBuilder:tag( 'methodName', methodName )

	xmlBuilder:beginBlock( 'params' )
	xmlBuilder:beginBlock( 'param' )
	xmlBuilder:beginBlock( 'value' )
	xmlBuilder:beginBlock( 'struct' )

	for i,nextParam in ipairs( params )  do
		xmlBuilder:beginBlock( 'member' )	
		xmlBuilder:tag( 'name', nextParam.paramName)
		xmlBuilder:beginBlock( 'value' )	
		xmlBuilder:tag( nextParam.paramType, nextParam.paramValue)
		xmlBuilder:endBlock( 'value' )	
		xmlBuilder:endBlock( 'member' )
	end

	xmlBuilder:endBlock( 'struct' )
	xmlBuilder:endBlock( 'value' )
	xmlBuilder:endBlock( 'param' )
	xmlBuilder:endBlock( 'params' )

	xmlBuilder:endBlock( 'methodCall' )
	local xmlString = xmlBuilder:serialize()
	--xmlString = string.gsub(xmlString, '&lt;','<')
	--xmlString = string.gsub(xmlString, '&gt;','>')

	--log:debug ('Sending XML String ' .. xmlString)	
	--log:debug ('CONTENT LENGTH is ' .. tostring( #xmlString ))
	--log:debug ('Request XML is ' .. xmlString)
	
	-- build headers
	local headers = {}
	table.insert( headers, { field = 'User-Agent', value = 'Adobe Photoshop Lightroom Zenphoto Publish Plugin' } )
	table.insert( headers, { field = 'Content-Type', value = 'text/xml; charset=ISO-8859-1' } )
	table.insert( headers, { field = 'Content-length', value = trim(tostring( #xmlString) ) } )
	
	zenphotoHost = prefs.instanceTable[publishServiceID].host
	zenphotoURL = 'http://'..zenphotoHost..'/'..prefs.webpath..'/xmlrpc.php'
	
	-- send request
	table.insert( headers, { field = 'Host', value = zenphotoHost} )
	local responseXML, responseHeaders = LrHttp.post( zenphotoURL, xmlString, headers, 'POST' )	
	--log:debug('headers: '..responseXML, table_show(responseHeaders))	
	local responseXML = xmlfix(responseXML,"methodRespons") 
	--log:debug("ZenphotoAPI.sendXML-RequestresponseXML: "..responseXML)
	return responseXML
end

--------------------------------------------------------------------------------

function ZenphotoAPI.uploadFile( filePath )
	log:trace('uploadFile/s')
	local zenphotoHost = prefs.instanceTable[publishServiceID].host
	local zenphotoURL = 'http://'..zenphotoHost..'/'..prefs.webpath..'/xmlrpc_upload.php'
	local  filename = LrPathUtils.leafName( filePath )	
	log:info( 'Uploading photo: ' ..filename )
	local mimeChunks = {}
	mimeChunks[ #mimeChunks + 1 ] = { name = 'photo', fileName = filename, filePath = filePath, contentType = 'application/octet-stream' }

	-- Post it and wait for confirmation.
	local result, hdrs = LrHttp.postMultipart( zenphotoURL, mimeChunks )

	if result and string.find(result, 'Permission denied') then
	log:info('uploadFile.Permission denied')
		return 'Please make sure you have sufficient writing permissions to write to "'..prefs.webpath..'"'
	end
	
--	log:info('upload-result'..table_show(result))
--	log:info('hdrs'..table_show(hdrs)
end