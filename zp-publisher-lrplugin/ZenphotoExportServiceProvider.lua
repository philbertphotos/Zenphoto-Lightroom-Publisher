--[[----------------------------------------------------------------------------

ZenphotoExportServiceProvider.lua
Export service provider description for Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]

	-- Lightroom SDK
local LrBinding         = import 'LrBinding'
local LrView            = import 'LrView'
local LrApplication     = import 'LrApplication'
local LrDialogs         = import 'LrDialogs'
local LrFunctionContext	= import 'LrFunctionContext'
local LrHttp            = import 'LrHttp'
local LrColor           = import 'LrColor'
local LrDate           	= import 'LrDate'
local LrLogger          = import 'LrLogger'
local LrXml             = import 'LrXml'
local prefs 			= import 'LrPrefs'.prefsForPlugin()
local LrPathUtils		= import 'LrPathUtils'
local LrStringUtils		= import 'LrStringUtils'
local LrFileUtils		= import 'LrFileUtils'
local LrTasks			= import 'LrTasks'
local LrProgressScope	= import 'LrProgressScope'

local util              = require 'Utils'

local bind = LrView.bind
local share = LrView.share
    -- Logger
local LrLogger = import 'LrLogger'
local log = LrLogger( 'ZenphotoLog' )

--============================================================================--

	-- ZenPhoto plugin
require 'ZenphotoPublishSupport'
require 'ZenphotoPublishSupportExtention'

exportServiceProvider = {}

for name, value in pairs( ZenphotoPublishSupport ) do
	exportServiceProvider[ name ] = value
end

exportServiceProvider.supportsIncrementalPublish = 'only'
--exportServiceProvider.hideSections = { 'exportLocation', 'postProcessing', 'metadata', 'fileNaming', 'watermarking' }
exportServiceProvider.hideSections = { 'exportLocation' }
exportServiceProvider.allowFileFormats = { 'JPEG' }
exportServiceProvider.allowColorSpaces = { 'sRGB'  }
exportServiceProvider.hidePrintResolution = true
exportServiceProvider.exportPresetFields = {
		{ key = 'LR_jpeg_quality', default = 100 },	
		{ key = 'LR_size_resizeType', default = 'longEdge' },
		{ key = 'LR_size_maxHeight', default = '1024' },
		{ key = 'LR_size_maxWidth', default = '1024' },
		{ key = 'LR_outputSharpeningMedia', default = 'screen' },
		{ key = 'LR_size_doNotEnlarge', default = 'true' },
		{ key = 'username', default = "yourloginname" },
		{ key = 'password', default = "password" },
		{ key = 'host', default = "wwww.yourzenphotoserver.com" },
		{ key = 'accountStatus', default = "Please fill out the available sections and save to enable this service" },
		{ key = 'loginButtonTitle', default = "DISABLED" },
		{ key = 'uploadMethod', default = "POST" },
		{ key = 'token', default = "" },
	}
--------------------------------------------------------------------------------

function exportServiceProvider.startDialog( propertyTable )
if prefs.logLevel ~= not 'none' then
log:trace("exportServiceProvider.startDialog")
end

	if not propertyTable.LR_publishService then	return end
	local publishService = propertyTable.LR_publishService
	publishServiceID = publishService.localIdentifier
	
	prefs.instanceID = publishServiceID	
	
	instanceID = tonumber(trim(prefs.instanceID))
	
	log:info("publishServiceID:" ..publishServiceID)

	if instanceID ~= nil then
		log:trace("instanceId not nil = ",prefs.instanceID)
	else
		log:trace("instanceId is nil = ",prefs.instanceID)
	end
				--if prefs.instanceTable ~= nil then --or prefs.instanceTable.instanceID ~= true then
			-- creating instance table in prefs
				if prefs.instanceTable == nil then
					log:info("Creating instance table")
					prefs.instanceTable = {}
				end			
				
if prefs.instanceTable[instanceID] then
 log:trace("instanceId exsits")
 else
  log:trace("Inserting new instance")
				table.insert(prefs.instanceTable,instanceID,
					{
					host = propertyTable.host,
					webpath = propertyTable.webpath,
					uploadMethod = propertyTable.uploadMethod,
					username = "yourname",
					password = "password",
					token = "", 
					}
				)				
			end
			
	prefs.instanceTable.serviceIsRunning = publishService
log:info("prefs.serviceIsRunning")
	if prefs.instanceTable.serviceIsRunning then
		propertyTable.serviceIsRunning = true
		propertyTable.publishServiceID = publishServiceID
	else
		propertyTable.serviceIsRunning = false
		propertyTable.publishServiceID = nil
	end

	-- Make sure we're logged in.
	require 'ZenphotoUser'
	ZenphotoUser.initLogin( propertyTable )

	propertyTable.host = prefs.instanceTable[instanceID].host or 'www.yourwebserver.com'
	prefs.instanceTable[instanceID].host = propertyTable.host
	propertyTable:addObserver( 'host', function() 
		prefs.instanceTable[instanceID].host = propertyTable.host
		ZenphotoUser.resetLogin( propertyTable )
	end)

	propertyTable.uploadMethod = prefs.instanceTable[instanceID].uploadMethod or 'POST'
	prefs.instanceTable[instanceID].uploadMethod = propertyTable.uploadMethod
	propertyTable:addObserver( 'uploadMethod', function() 
		prefs.instanceTable[instanceID].uploadMethod = propertyTable.uploadMethod
	end)
	
	propertyTable.webpath = '/plugins/zp-lightroom/' --prefs.webpath or '/plugins/zp-lightroom/'
	prefs.webpath = '/plugins/zp-lightroom/' --propertyTable.webpath
	propertyTable:addObserver( 'webpath', function() 
		prefs.webpath = propertyTable.webpath
		ZenphotoUser.resetLogin( propertyTable )
	end)
	
	if not prefs.instanceTable[instanceID].missing then
		prefs.instanceTable[instanceID].missing = {}
	end
	
		if prefs.logLevel == 'verbose' then
		  	tdump(prefs)
		end
end


--------------------------------------------------------------------------------
function exportServiceProvider.sectionsForTopOfDialog( f, propertyTable )
	-- set global publishServiceID to identify the current prefs
	--publishServiceID = localIdentifier
	--prefs.publishServiceID = trim(publishServiceID)
if prefs.logLevel ~= not 'none' then
log:trace("exportServiceProvider.sectionsForTopOfDialog")
end
    return {
			{
			title = "Login to ZenPhoto",
			synopsis = bind 'accountStatus',
			bind_to_object = propertyTable,
			
			f:row {
				f:static_text {
					title = 'Enter ZenPhoto-URL (without \'http://\'):',
					width = 300,
				},

				f:edit_field {
					fill_horizontal = 1,
					value = bind 'host',
					immediate = true,
				},
			},

			f:row {
				f:static_text {
					fill_horizontal = 1,
					title = bind 'accountStatus',
					alignment = 'right',
				},
				f:push_button {
					width = share 'button_width',
					title = bind 'loginButtonTitle',
					enabled = bind {
						keys = { 'loginButtonEnabled', 'serviceIsRunning' }, -- bind to both keys
						operation = function( binder, values, fromTable ) 
							return values.loginButtonEnabled == true and values.serviceIsRunning == true
						end,
						},
					action = function()
						LrFunctionContext.postAsyncTaskWithContext ('LoginTask', function() 
																					ZenphotoUser.login( propertyTable )
																				 end
																   )						
					end,
				},
			},
			f:row {
				f:static_text {
					fill_horizontal = 1,
					title = 'Upload photos via ',
					alignment = 'right',
				},

				f:popup_menu {
					width = share 'button_width',
					alignment = 'center',
					items = { 
						{ title = "HTTP Multi-Post",	value = 'POST' },
						{ title = "XML data", 			value = 'XML'  },
					},
					value = bind 'uploadMethod',
					size = 'small'
				},
			},

			f:row {
				margin_top = 10,

				f:static_text {
					fill_horizontal = 1,
					height_in_lines = 9,
					width = 70,
					title = 'Once you have logged-in, close the Publishing Manager and go to the "Publish Services" menu on the left side of the Lightroom window. There you will find the "Zenphoto Publisher" with a default node called "Sync Albums/Images". Right-click on it and select "Edit album..." from the menu. \n\nA dialog will be opened. Please click now the "Sync albums" or "Sync all images" button for the initial sync with your Zenphoto server and Lightroom.\n\nFurther details and instructions can be found on http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher.',
				},
			},
			
--[[			
			f:row {
				margin_top = 20,
				f:static_text {
					fill_horizontal = 1,
					title = 'Read albumlist from server',
				},

				f:push_button {
					title = 'Sync albums',
					width = share 'button_width',
					enabled = bind {
						keys = { 'validAccount', 'serviceIsRunning' }, -- bind to both keys
						operation = function( binder, values, fromTable ) 
							return values.validAccount == values.serviceIsRunning and values.serviceIsRunning == true and values.validAccount == true -- check that values are ==
						end,
						},
					action = function()
									LrTasks.startAsyncTask( function()
											exportServiceProvider.sync(false, context)
									end)
							end,
				},
			},

			f:row {
				f:static_text {
					fill_horizontal = 1,
					title = 'Read albums and images from server (EXPERIMENTAL)',
				},

				f:push_button {
					title = 'Full sync',
					width = share 'button_width',
					enabled = bind {
						keys = { 'validAccount', 'serviceIsRunning' }, 
						operation = function( binder, values, fromTable ) 
							return values.validAccount == values.serviceIsRunning and values.serviceIsRunning == true 
						end,
						},
					action = function()
									LrTasks.startAsyncTask( function()
										exportServiceProvider.sync(true, context)
									end)
							end,
				},
			},
]]--
		},
	}
end


--------------------------------------------------------------------------------


function exportServiceProvider.sync( fullsync, publishService, context )

	local catalog = import 'LrApplication'.activeCatalog()
	local albums = ZenphotoAPI.getAlbums()
	LrFunctionContext.callWithContext('sync Albums', function(context)

		local progressScope = LrDialogs.showModalProgressDialog({
			title = 'Syncing albums',
			caption = 'loading albums info from server',
			cannotCancel = false,
			functionContext = context,
		})

		for i, collection in pairs ( publishService:getChildCollections() ) do
			
			infoSummary = collection:getCollectionInfoSummary()
			if infoSummary and not infoSummary.isDefaultCollection then
				catalog:withWriteAccessDo( "delete local lightroom collections (albums)", function()
					collection:delete()
				end)
			end
		end


			
		for i, album in pairs ( albums ) do
			log:info("add album: -" .. tostring(album.name) .. "-")

			progressScope:setCaption('reading album: ' .. tostring(album.name) .. ' (' .. i .. ' of ' .. #albums .. ')' )
			progressScope:setPortionComplete( i, #albums )
			if progressScope:isCanceled() then break end

			if not publishServiceExtention.collectionNameExists(publishService, album.name) then
				catalog:withWriteAccessDo( "create album", function()
					pubCollection = publishService:createPublishedCollection( album.name, nil, true )
					pubCollection:setCollectionSettings(album)
					pubCollection:setRemoteId( album.id )
					pubCollection:setRemoteUrl( album.url )
				end)
			else
				LrDialogs.message('Album '..album.name..' already exists', 'This album is not created in Lightroom. Albumnames must be unique.','info')
			end
		end
		progressScope:done()
		
	end)
		
	LrTasks.yield()
	
	--
	--	sync images for all collections
	--
	if fullsync then
		local missing = {}
		
		log:info('start syncing album and images')
		for i, pubCollection in pairs (publishService:getChildCollections()) do

			LrTasks.yield()
			
			remoteId = pubCollection:getRemoteId()

			if remoteId and pubCollection:getName() ~= 'Sync Albums/Images' then
				LrFunctionContext.callWithContext('sync Images', function(context)
					result = publishServiceExtention.getImages( pubCollection, remoteId, nil, context)
					prefs.instanceTable[instanceID].missing[remoteId] = result
					missing = Utils.joinTables(missing, result)
				end)
			end
		end
		log:info('finish syncing album and images')
		
		if #missing > 0 then Utils.showMissingFilesDialog(missing) end
		
	end
end



--------------------------------------------------------------------------------
--
--
--	HELPER function to delete missing images
--
--
function exportServiceProvider.deleteMissingPhotos(arrayOfPhotoNames)

	result = LrDialogs.confirm( 'Delete the "not found images" from the server', 
								'Do you really want to delete the images that were not found on your Zenphoto webserver?',
								'Delete', 
								'Cancel' 
								)
	
	if result == 'ok' then 

		LrFunctionContext.callWithContext('delete images', function(context)

			local progressScope = LrDialogs.showModalProgressDialog({
				title = 'Delete images from server',
				cannotCancel = false,
				functionContext = context,
			})

			for i, photoName in ipairs( arrayOfPhotoNames ) do

				progressScope:setCaption('delete image: ' .. tostring(photoName) .. ' (' .. i .. ' of ' .. #arrayOfPhotoNames .. ')' )
				progressScope:setPortionComplete( i, #arrayOfPhotoNames )
				if progressScope:isCanceled() then break end

				local errors = ZenphotoAPI.deletePhoto({	name = photoName,	})

				if errors ~= '' then
					LrDialogs.message( 'Unable to delete image with name: ' .. photoName, errors, 'critical' )
				end
			end
			
			progressScope:done()
		end)
			
	end

end


--------------------------------------------------------------------------------


function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
	-- Check for photos that have been uploaded already.
	local exportSession = exportContext.exportSession

	-- Make a local reference to the export parameters.
	local nPhotos = exportSession:countRenditions()

	-- Set progress title.
	local progressScope = exportContext:configureProgress{
												title = nPhotos > 1
													and LOC( "$$$/zenphoto/Upload/Progress=Uploading ^1 photos to ZenPhoto", nPhotos )
													or LOC "$$$/zenphoto/Upload/Progress/One=Uploading one photo to ZenPhoto",
										}
	local propertyTable = {}

	-- check if in Publish Service or not ("not" is the normal export)
	local pubCollection = exportContext.publishedCollection
	-- show the custom export dialog

	infoSummary = pubCollection:getCollectionInfoSummary()
	local params = infoSummary.collectionSettings

	-- Iterate through photo renditions.
	for i, rendition in exportContext:renditions{ stopIfCanceled = true } do

		local result = {}
		local errors = nil
		local photo = rendition.photo
		local photoname = photo:getFormattedMetadata('fileName')

		log:info('Getting next photo...' .. photoname)
		
		if not rendition.wasSkipped then
			
			-- render photo
			local success, pathOrMessage = rendition:waitForRender()
			-- Check for cancellation again after photo has been rendered.
			if progressScope:isCanceled() then break end
			
			--
			-- if redition was successful
			--
			if success then

				if prefs.uploadMethod == 'POST' then
					result, errors = ZenphotoAPI.uploadPhoto (pathOrMessage, params)
				else
					-- read file
					local filename  = LrPathUtils.leafName( pathOrMessage )
					local file = assert(io.open(pathOrMessage, "rb"))
					local photoBinaryData = file:read("*all")
					file:close()
					-- convert to base64
					local base64Data = LrStringUtils.encodeBase64(photoBinaryData)
					result, errors = ZenphotoAPI.uploadXMLPhoto ( filename, params, base64Data )
				end
					
				-- delete tmp-image file
				LrFileUtils.delete( pathOrMessage )

				--
				-- if image uploaded OK
				--
				if result then 
					log:info ('Image ' .. photoname .. ' uploaded successfully')
					rendition:recordPublishedPhotoId( result.id )
					rendition:recordPublishedPhotoUrl( result.url )
--write information to metadata			
log:info ('write information to custom metadata')
        photo.catalog:withWriteAccessDo( "set.metadata",
                                    function()
	photo:setPropertyForPlugin(_PLUGIN,"uploaded","true")
	photo:setPropertyForPlugin(_PLUGIN,"albumurl",result.url)
                                    end)
				else
					-- upload was not successful and returned an error
					LrDialogs.message( 'Unable to upload image ' .. photoname, errors, 'critical' )
				end
				-- Adjust progesss scope
				progressScope:setPortionComplete(i, nPhotos)
				
			end -- if success then
		end
		
	end -- for i renditions

	progressScope:done()
end

return exportServiceProvider