--[[----------------------------------------------------------------------------

ZenphotoAPI.lua
Common code to initiate Zenphoto API requests

------------------------------------------------------------------------------]]

	-- Lightroom SDK
local LrDialogs 		= import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrHttp 			= import 'LrHttp'
local LrMD5 			= import 'LrMD5'
local LrPathUtils 		= import 'LrPathUtils'
local LrXml 			= import 'LrXml'
local LrStringUtils		= import 'LrStringUtils'
local prefs 			= import 'LrPrefs'.prefsForPlugin()


local logger = import 'LrLogger'( 'ZenphotoAPI' )
logger:enable('logfile')
local debug, info, warn, err = logger:quick( 'debug', 'info', 'warn', 'err' )

--============================================================================--

ZenphotoAPI = {}

--------------------------------------------------------------------------------

function initRequestParams()
	local paramMap = {}

--	if not publishServiceID then
--		error("publishServiceID not set")
--	end
	
	local username = prefs.username
	local password = prefs.password

	table.insert( paramMap, { paramName = 'loginUsername', paramType = 'string', paramValue = username } )
	table.insert( paramMap, { paramName = 'loginPassword', paramType = 'string', paramValue = password } )
	return paramMap
end


--------------------------------------------------------------------------------

function ZenphotoAPI.authorize( login, password ) 

	info('Authorizing with Zenphoto... Username: ' .. tostring(login) .. ' width password ' .. tostring(password))

	local auth = false
	local showMsg = true
	
	local paramMap = initRequestParams()
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.login', paramMap, true )


	-- Parse response
	if not xmlResponse or string.find(xmlResponse, 'html') then
		LrDialogs.message( 'Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
		fault = true
		showMsg = false
	end

	
	local faltString, faultCode = ZenphotoAPI.getXMLError(xmlResponse);
	if faultCode == '-2' then
		LrDialogs.message( 'Zenphoto version error!', faltString, 'error' )
		fault = true
		showMsg = false	
	end

	if faultCode == '-1' then
		auth = false
		showMsg = true
	else
--		info('Authorization successful')
		auth = true
		showMsg = false	
	end	

	return auth, showMsg
end	


--------------------------------------------------------------------------------


function ZenphotoAPI.uploadPhoto( filePath, params )
	info('Uploading POST photo: ' .. filePath)

	local err = ZenphotoAPI.uploadFile( filePath )
	
	if err then return nil, err end

	local filename = LrPathUtils.leafName( filePath )	

	local paramMap = initRequestParams()
	table.insert( paramMap, { paramName = 'filename', paramType = 'string', paramValue = filename } )
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end

	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.image.upload', paramMap, true )

--	info(xmlResponse)
	
	return ZenphotoAPI.getTableFromXML(xmlResponse)
end


--------------------------------------------------------------------------------


function ZenphotoAPI.uploadXMLPhoto( filename, params, file )
	info('Uploading XML photo: ' .. filename)

	local paramMap = initRequestParams()
	table.insert( paramMap, { paramName = 'filename',		paramType = 'string', paramValue = filename } )
	table.insert( paramMap, { paramName = 'file',			paramType = 'string', paramValue = file } )
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end
	
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.image.uploadXML', paramMap, true )

--	info(xmlResponse)
	
	return ZenphotoAPI.getTableFromXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.deletePhoto(propertyTable, params)
	info('Delete photo from server')
	
	ZenphotoAPI.initPublishServiceID(propertyTable)
	
--	publishServiceID = assert( info.publishService.localIdentifier )
	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end
	info(paramMap)
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.image.delete', paramMap, true )

	info(xmlResponse)
	
	return ZenphotoAPI.getSingleValueXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.getAlbums( propertyTable, simple )	
	info('Get list of all albums')

--	if propertyTable then
--		ZenphotoAPI.initPublishServiceID(propertyTable)
--	end
		
	local paramMap = initRequestParams()
	if simple then
		table.insert( paramMap, { paramName = 'simplelist', paramType = 'string', paramValue = tostring(simple) } )
	end
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.getList', paramMap, true )
	
--	info(xmlResponse)

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
	info('Get images from album ' .. tostring(id))

	local paramMap = initRequestParams()
	table.insert( paramMap, { paramName = 'id',	paramType = 'string', paramValue = id } )
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.getImages', paramMap, true )

--	info(xmlResponse)
	
	return ZenphotoAPI.getTableFromXML(xmlResponse, false, false)	
end

--------------------------------------------------------------------------------

function ZenphotoAPI.deleteAlbum( propertyTable, albumId )
	info('Delete album from server with imageId: ' .. albumId)
	
--	ZenphotoAPI.initPublishServiceID(propertyTable)

	local paramMap = initRequestParams()
	table.insert( paramMap, { paramName = 'id', paramType = 'string', paramValue = albumId } )
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.delete', paramMap, true )

--	info(xmlResponse)
	
	return ZenphotoAPI.getSingleValueXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.createAlbum( propertyTable, params )
	info('Create a new album: ' .. params.name)

--	ZenphotoAPI.initPublishServiceID(propertyTable)

	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.create', paramMap, true )

--	info(xmlResponse)
	
	return ZenphotoAPI.getTableFromXML(xmlResponse)
end

--------------------------------------------------------------------------------

function ZenphotoAPI.editAlbum( propertyTable, params )
	info('Edit album: ')

--	ZenphotoAPI.initPublishServiceID(propertyTable)

	local paramMap = initRequestParams()
	for key,value in pairs(params) do 
		table.insert( paramMap, { paramName = key, paramType = 'string', paramValue = value } ) 
	end
	local xmlResponse = ZenphotoAPI.sendXMLRequest( 'zenphoto.album.edit', paramMap, true )

--	info(xmlResponse)

	return ZenphotoAPI.getTableFromXML(xmlResponse)
end

--------------------------------------------------------------------------------


function ZenphotoAPI.initPublishServiceID( propertyTable )

	local catalog = import 'LrApplication'.activeCatalog()
	local publishServices = catalog:getPublishServices( _PLUGIN.id )

		for i, publishService in pairs ( publishServices ) do
			if ( publishService:getName() == propertyTable.LR_publish_connectionName) then
				publishServiceID = publishService.localIdentifier
			end
		end
	
	return publishServiceID
	
end














function ZenphotoAPI.getTableFromXML(xmlResponse, formatForUI, allowSingleEntry)

	if formatForUI == nil then formatForUI = false end
	if allowSingleEntry == nil then allowSingleEntry = true end

	if not xmlResponse then
		LrDialogs.message( 'Server could not be connected!', 'Please make sure that an internet connection is established and that the web service is running.', 'error' )
		return {}
	end

--	info(xmlResponse)
	
	local responseDocument = LrXml.parseXml( xmlResponse, true )
	responseDocument = responseDocument:childAtIndex(1)

	-- show when image was not found
	if responseDocument:name() == "fault" then
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

--	info(luaTableString)
	
	local luaTableFunction = luaTableString and loadstring( luaTableString )
	local _, resultTable = LrFunctionContext.pcallWithEmptyEnvironment( luaTableFunction )
	
	if resultTable and #resultTable == 1 and allowSingleEntry == true then
		return decode64(resultTable[1])
	else
		return decode64(resultTable)
	end
end


function decode64(value)

	if type(value) == 'table' then
		for k,v in pairs(value) do
			if type(v) == 'table' then
				value[k] = decode64(v)
			else
				value[k] = LrStringUtils.decodeBase64(v)
			end
		end
	else
		value = LrStringUtils.decodeBase64(value)
	end
	
	return value
end

function encode64(value)

	if type(value) == 'table' then
		for k,v in pairs(value) do
			if type(v) == 'table' then
				value[k] = encode64(v)
			else
				if k == 'paramValue' then
					value[k] = LrStringUtils.encodeBase64(v)
				end
			end
		end
	else
		value = LrStringUtils.encodeBase64(value)
	end
	
	return value
end



function ZenphotoAPI.getListFromXML(xmlResponse)

	local responseDocument = LrXml.parseXml( xmlResponse, true )
	responseDocument = responseDocument:childAtIndex(1)

	-- show when image was not found
	if responseDocument:name() == "fault" then
		error(ZenphotoAPI.getXMLError(xmlResponse))
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

	local responseDocument = LrXml.parseXml( xmlResponse, true )
	responseDocument = responseDocument:childAtIndex(1)

	-- show when image was not found
	if responseDocument:name() == "fault" then
		debug(ZenphotoAPI.getXMLError(xmlResponse))
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

	local responseDocument = LrXml.parseXml(xmlResponse)

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
	
	return resultTable.faultString, resultTable.faultCode
end


--------------------------------------------------------------------------------

	-- Params are list of maps with keys: paramName, paramType, paramValue

function ZenphotoAPI.sendXMLRequest( methodName, params )
	
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
	xmlString = string.gsub(xmlString, '&lt;','<')
	xmlString = string.gsub(xmlString, '&gt;','>')

	--info ('Sending XML String ' .. xmlString)	
	--info ('CONTENT LENGTH is ' .. tostring( #xmlString ))
	--info ('Request XML is ' .. xmlString)
	
	-- build headers
	local headers = {}
	table.insert( headers, { field = 'User-Agent', value = 'Adobe Photoshop Lightroom Zenphoto Publish Plugin' } )
	table.insert( headers, { field = 'Content-Type', value = 'text/xml; charset=utf-8' } )
	table.insert( headers, { field = 'Content-length', value = tostring( #xmlString ) } )

	
	zenphotoHost = prefs.host
	zenphotoURL = 'http://'..zenphotoHost..'/'..prefs.webpath..'/xmlrpc.php'

	-- send request
	table.insert( headers, { field = 'Host', value = zenphotoHost} )			
	
-- info(xmlString)
	local responseXML, responseHeaders = LrHttp.post( zenphotoURL, xmlString, headers, 'POST' ) 
-- info(responseXML)
	
	return responseXML

end

--------------------------------------------------------------------------------

function ZenphotoAPI.uploadFile( filePath )

	local zenphotoHost = prefs.host
	local zenphotoURL = 'http://'..zenphotoHost..'/'..prefs.webpath..'/xmlrpc_upload.php'

	info( 'Uploading photo', zenphotoURL )

	local filename = LrPathUtils.leafName( filePath )	

	local mimeChunks = {}
--	mimeChunks[ #mimeChunks + 1 ] = { name = 'folder', value = "folder" }
	mimeChunks[ #mimeChunks + 1 ] = { name = 'photo', fileName = filename, filePath = filePath, contentType = 'application/octet-stream' }

	-- Post it and wait for confirmation.
	local result, hdrs = LrHttp.postMultipart( zenphotoURL, mimeChunks )

	if result and string.find(result, 'Permission denied') then
		return 'Please make sure you have sufficient writing permissions to write to "'..prefs.webpath..'"'
	end
	
--	info(result)
--	info(hdrs)
--	tdump(hdrs)
end

