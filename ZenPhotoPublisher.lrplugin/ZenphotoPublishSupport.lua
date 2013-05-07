--[[----------------------------------------------------------------------------

ZenphotoPublishSupport.lua
Publish-specific portions of Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]
local LrDialogs 		= import 'LrDialogs'
local LrHttp			= import 'LrHttp'
local LrStringUtils		= import 'LrStringUtils'
local LrTasks			= import 'LrTasks'
local LrErrors			= import 'LrErrors'
local LrFunctionContext	= import 'LrFunctionContext'
local LrDate			= import 'LrDate'
local prefs 			= import 'LrPrefs'.prefsForPlugin()

require 'ZenphotoAPI'
require 'ZenphotoPublishSupportExtention'

--============================================================================--

local publishServiceProvider = {}

publishServiceProvider.small_icon = 'zenphoto_small.png'
publishServiceProvider.titleForPublishedCollection = 'Album'
publishServiceProvider.titleForPublishedCollectionSet = LOC "$$$/Zenphoto/titleForPublishedCollectionSet=Parent Folder"
publishServiceProvider.titleForPublishedCollection_standalone = LOC "$$$/Zenphoto/titleForPublishedCollection/Standalone=Album"
publishServiceProvider.titleForPublishedCollectionSet_standalone = LOC "$$$/Zenphoto/titleForPublishedCollectionSet/Standalone=Parent Folder"
publishServiceProvider.titleForPublishedSmartCollection = LOC "$$$/Zenphoto/TitleForPublishedSmartCollection=Dynamic Album"
publishServiceProvider.titleForPublishedSmartCollection_standalone = LOC "$$$/Zenphoto/titleForPublishedSmartCollection/Standalone=Dynamic Album"
publishServiceProvider.disableRenamePublishedCollection = false
publishServiceProvider.disableRenamePublishedCollectionSet = true
publishServiceProvider.supportsCustomSortOrder = true
publishServiceProvider.titleForPhotoRating = LOC "$$$/Zenphoto/titleForPhotoRating=Image Rating"
publishServiceProvider.titleForGoToPublishedCollection = LOC "$$$/Zenphoto/titleForGoToPublishedCollection=Show album on ZenPhoto"
publishServiceProvider.titleForGoToPublishedPhoto = LOC "$$$/Zenphoto/titleForGoToPublishedPhoto=Show image on ZenPhoto"

function publishServiceProvider.getCollectionBehaviorInfo( publishSettings,info )
	log:trace("publishServiceProvider.getCollectionBehaviorInfo")

	return {
		defaultCollectionName = "Sync Albums/Images",
		defaultCollectionCanBeDeleted = false,
		canAddCollection = true,
		maxCollectionSetDepth = 0,
	}
	
end

-- The setting to use for the publish service name if the user doesn't set one
publishServiceProvider.publish_fallbackNameBinding = 'host'

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called whenever a new
 -- publish service is created and whenever the settings for a publish service
 -- are changed. It allows the plug-in to specify which metadata should be
 -- considered when Lightroom determines whether an existing photo should be
 -- moved to the "Modified Photos to Re-Publish" status.
 
function publishServiceProvider.metadataThatTriggersRepublish( publishSettings )
	log:trace("publishServiceProvider.metadataThatTriggersRepublish")
	return {
		default = false,
		caption = true,
		keywords = true,
		dateCreated = true,
	}
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user chooses
 -- the "Go to Published Collection" context-menu item.

function publishServiceProvider.goToPublishedCollection( publishSettings, info )
	log:trace("publishServiceProvider.goToPublishedCollectionAlbum")
if info.name == "Sync Albums/Images" then
LrDialogs.message( "You can not delete this collection" )
elseif info.remoteUrl then
		LrHttp.openUrlInBrowser( 'http://' .. prefs[prefs.instance_ID].host .."/".. info.remoteUrl )
end
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user chooses the
 -- "Go to Published Photo" context-menu item.
	 
function publishServiceProvider.goToPublishedPhoto( publishSettings, info )
	log:trace("publishServiceProvider.goToPublishedPhoto")
	--log:trace("goToPublishedPhoto.info: "..table_show(info))
	--log:trace("goToPublishedPhoto.info: "..table_show(publishSettings))
	if info.remoteUrl then
		LrHttp.openUrlInBrowser( 'http://' .. prefs[prefs.instance_ID].host .."/"..info.remoteUrl )
	end
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- creates a new published collection or edits an existing one. It can add
 -- additional controls to the dialog box for editing this collection. These controls
 -- can be used to configure behaviors specific to this collection (such as
 -- privacy or appearance on a web service).

 function publishServiceProvider.viewForCollectionSettings( f, publishSettings, info )
	log:trace("publishServiceProvider.viewForCollectionSettings")
	
	--set instance ID
	instanceID = publishSettings.instance_ID
	local id = info.collectionSettings.id
	
	-- Make sure we're logged in.
	require 'ZenphotoUser'
	ZenphotoUser.initLogin( info )
	
			-- don't let them edit the default collection
if info.isDefaultCollection or info.name == "Sync Albums/Images" then
info.collectionSettings.LR_canSaveCollection = false
log:info('Sync Albums/Images has no album ID')
else
	if not prefs[instanceID].albums[info.collectionSettings.id] then
				log:info("Creating ablum table", id)
		if id ~= nil then
		prefs[instanceID].albums[id] = {}
		--set default password value
		if not prefs[instanceID].albums[id].albumpassword then
	prefs[instanceID].albums[id].albumpassword = ''
	end
	end
	end	
end
	if prefs[instanceID].token ~= true then
 LrDialogs.message('You are not logged in...','You need to login before you can get access','info')
		log:info("You are not logged in")
		local collectionSettings = assert( info.collectionSettings )
		collectionSettings.syncEnabled = false
		LrErrors.throwCanceled()
		--LrErrors.throwUserError( 'You are not logged in...You need to login before you can get access')
else
	local bind = import 'LrView'.bind
	
	local albumlist = ZenphotoAPI.getAlbums(publishSettings, true)
	log:debug('viewForCollectionSettings.albumlist: '..table_show(albumlist))

	local pubCollection = nil
	local collectionSettings = assert( info.collectionSettings )
log:debug("view CollectionSettings", table_show(info.collectionSettings))

	if not collectionSettings.folder then
		collectionSettings.folder = ''
	end
	
	if not collectionSettings.parentFolder then
		collectionSettings.parentFolder = ''
	end

	if not collectionSettings.albumpassword then
		--collectionSettings.albumpassword = prefs[instanceID].albums[albumId].albumpassword

		--if not prefs[instanceID].albums[albumId].albumpassword then
		-- prefs[instanceID].albums[albumId].albumpassword = ''
		--end
		-- prefs[instanceID].albums[albumId].albumpassword = collectionSettings.albumpassword
		
			collectionSettings.albumpassword = ''
			else 
			log:info ('albumpassword', collectionSettings.albumpassword)
			--prefs[instanceID].albums[id].albumpassword = collectionSettings.albumpassword
	end
	
	if not collectionSettings.location then
		collectionSettings.location = ''
	end
	
	if not collectionSettings.description then
		collectionSettings.description = ''
	end
	
	collectionSettings.syncEnabled = true

	if not collectionSettings.commentson then
		collectionSettings.commentson = '1'
	end

	if not collectionSettings.show then
		collectionSettings.show = '1'
	end

	--
	--	process only if already published
	--
	if info.publishedCollection then
		pubCollection = assert( info.publishedCollection )
		remoteId = pubCollection:getRemoteId()
		log:info('pubCollection:getRemoteId', remoteId)
		if remoteId then
			collectionSettings.syncEnabled = true
			collectionSettings.missing = prefs[instanceID].albums[remoteId].missing
		end
	end
	
	if not remoteId then
		collectionSettings.missing = {}
	end
	--
	--	maintenance collection dialog
	--
	if info.isDefaultCollection then
		return 	f:group_box {
					title = "Zenphoto Album Maintenance",
					size = 'small',
					fill_horizontal = 1,

					f:push_button {
						fill_horizontal = 1,
						title = 'Sync albums',
						action = function()
									LrTasks.startAsyncTask( function()
										log:trace("Sync albums dialog")
										LrFunctionContext.callWithContext('function', function(context)
											exportServiceProvider.sync(false, info.publishService, context, publishSettings)

										end)
									end)
						end,
					},
					f:push_button {
						fill_horizontal = 1,
						title = 'Sync all images',
						action = function()
									LrTasks.startAsyncTask( function()
									log:trace("Sync all images dialog")
										LrFunctionContext.callWithContext('function', function(context)

											exportServiceProvider.sync(true, info.publishService, context, publishSettings)

										end)
									end)
						end,
					},

					}
	end
	--
	--	dialog
	--
	return 	f:row {

				f:picture {
					value = _PLUGIN:resourceId('zenphoto_album.png'),
					},
	
				f:column {
					bind_to_object = assert( collectionSettings ),

					fill_horizontal = 1,

					f:group_box {
						title = "Manage Zenphoto Album",
						size = 'small',
						fill_horizontal = 1,

						f:row {
							f:static_text {
								title = "* Parent Folder:",
								alignment = "right",
								width = 100,
								},
							f:popup_menu {
								value = bind 'parentFolder',
								items = albumlist,
								fill_horizontal = 1,
								immediate = true,
								},
								},
						f:row {
							f:static_text {
								title = "* Foldername:",
								alignment = "right",
								width = 100,
								},
								
							f:edit_field {
								fill_horizontal = 1,
								value = bind 'folder',
								},
							},
						f:row {
							f:static_text {
								title = "Description:",
								alignment = "right",
								width = 100,
								},

							f:edit_field {
								height_in_lines = 3,
								width_in_chars = 38,
								value = bind 'description',
								},
						},
						
						f:row {
							f:static_text {
								title = "Location:",
								alignment = "right",
								width = 100,
								},

							f:edit_field {
								value = bind 'location',
								width_in_chars = 38,
								},
						},
												
						--[[f:row {
							f:static_text {
								title = "Album Password:",
								alignment = "right",
								tooltip = "creates a album passoword",
								width = 100,
								},

							f:edit_field {
								value = bind 'albumpassword',
								tooltip = "creates a album passoword",
								width_in_chars = 38,
								},
						},--]]

						f:row {
							f:static_text {
								width = 100,
								},
							f:checkbox {
								title = "Album published",
								checked_value = '1',
								unchecked_value = '0',
								tooltip = "published the album on zenphoto",
								value = bind 'show',
								},
							f:checkbox {
								title = "Allow comments",
								checked_value = '1',
								unchecked_value = '0',
								tooltip = "Allow comments on the album",
								value = bind 'commentson',
								},
							--[[f:checkbox {
								title = "Allow ratings",
								checked_value = '1',
								unchecked_value = '0',
								value = bind 'ratingson',
								},--]]
						},
					},
					
					spacing = f:control_spacing(),

					f:group_box {
						fill_horizontal = 1,
						title = "Sync images from server",
						size = 'small',

						f:row {
							f:push_button {
								fill_horizontal = 0,
								title = 'Sync images',
								enabled = bind 'syncEnabled',
								action = function()
											LrTasks.startAsyncTask( function()
												LrFunctionContext.callWithContext('function', function(context)
													collectionSettings.missing = publishServiceExtention.getImages( pubCollection, remoteId, publishSettings, context)
													 prefs[instanceID].albums[info.collectionSettings.id].missing = collectionSettings.missing

												end)
											end)
											
								end,
							},
							f:push_button {
								fill_horizontal = 1,
								title = 'Show -not found-',
								enabled = bind {
									keys = { 'missing' },
									operation = function( binder, values, fromTable )
													return values.missing ~= nil and #values.missing > 0
												end,
									},
								action = function()
									LrTasks.startAsyncTask( function()
										Utils.showMissingFilesDialog(collectionSettings.missing)
									end)
								end,
							},
							f:push_button {
								fill_horizontal = 1,
								title = 'Remove -not found-',
								enabled = bind {
									keys = { 'missing' },
									operation = function( binder, values, fromTable )
													return values.missing ~= nil and #values.missing > 0
												end,
									},
								action = function()
									LrTasks.startAsyncTask( function()
										exportServiceProvider.deleteMissingPhotos( collectionSettings.missing )
										collectionSettings.missing = {}
										 prefs[instanceID].albums[info.collectionSettings.id].missing = {}
									end)
								end,
							},
						},
					},
					
					spacing = f:control_spacing(),
					
					f:row {
						margin_left = 10,
						font = "<system/small>",
						f:static_text {
							title = "*  The name of the album will be taken as foldername, when leaving the field empty",
						},
					},
				},
			}
end
end
--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- has changed the per-collection settings defined via the <code>viewForCollectionSettings</code>
 -- callback. It is your opportunity to update settings on your web service to
 -- match the new settings.

function publishServiceProvider.updateCollectionSettings( publishSettings, info )
	log:trace("updateCollectionSettings")
	if prefs[instanceID].token ~= true then
	else
	if info.collectionSettings.folder == '' then
		info.collectionSettings.folder = LrStringUtils.lower( info.name )
	end
	
--show albums table
	log:info ('show album table',table_show ( prefs[instanceID]))
	prefs[instanceID] = prefs[instanceID]
	
	LrTasks.startAsyncTask( function()

		--
		--	create new collection
		--
		if info.name then
log:trace("create new collection")
			local status, err
			if not info.publishedCollection or not info.publishedCollection:getRemoteId() then
				log:trace("album create")
				status, err = ZenphotoAPI.createAlbum( publishSettings, {
																	name = info.name,
																  folder = info.collectionSettings.folder,
															parentFolder = info.collectionSettings.parentFolder,
														})
				catalog = info.publishService.catalog
				if err then
					catalog:withWriteAccessDo( "delete collection already exists", function()
						LrDialogs.message( 'Album already exists!', 'There is an album with this name already available on the server. Please choose another name!', 'info' )
						info.publishedCollection:delete()
					end)
					return
				end
				
				remoteId = status.id
			end

			--
			--	edit a published collection
			--
			if info.publishedCollection and info.publishedCollection:getRemoteId() then
			log:trace("edit a published collection")
				remoteId = info.publishedCollection:getRemoteId()
			end
			
			status, err = ZenphotoAPI.editAlbum( publishSettings, {
																  id = remoteId,
																name = info.name,
															  folder = info.collectionSettings.folder,
														parentFolder = info.collectionSettings.parentFolder,
														 description = info.collectionSettings.description,
															location = info.collectionSettings.location,
													   albumpassword = info.collectionSettings.albumpassword,
													   --albumpassword = prefs[instanceID].albums[info.collectionSettings.id].albumpassword,
																show = info.collectionSettings.show,
														  commentson = info.collectionSettings.commentson,													  
													})
				log:info('publishServiceProvider.editAlbum: '..table_show(status))
				
			--if status.albumpassword == not nil then
		--if prefs[instanceID].remoteId == nil then
					--log:info("Creating ablum table"..remoteId)
		--table.insert (prefs,instanceID,remoteId)
	--end	

			--prefs[instanceID].remoteId.albumpassword = info.collectionSettings.albumpassword
			--prefs[instanceID][remoteId] = albumpassword
					--log:trace("album password:"..info.collectionSettings.albumpassword)
			--end
			--	update collection settings
			--
			catalog = info.publishService.catalog
			if not err then
				catalog:withWriteAccessDo( "setting remote collection values", function()
					pubCollection = assert( info.publishedCollection )
					pubCollection:setCollectionSettings(status)
					pubCollection:setRemoteId(status.id)
					pubCollection:setRemoteUrl(status.url)
				end)
			else
				LrDialogs.message( 'Change error!', err, 'info' )
				log:fatal('Change error!', err, 'info')
			end
			
		end
	end)
end
end
--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- closes the dialog for creating a new published collection or editing an existing
 -- one. It is only called if you have also provided the <code>viewForCollectionSettings</code>
 -- callback, and is your opportunity to clean up any tasks or processes you may
 -- have started while the dialog was running.

function publishServiceProvider.endDialogForCollectionSettings( publishSettings, info )
	log:trace("publishServiceProvider.endDialogForCollectionSettings (n/a)")
end
-------------------------------------------------------------------------------
--- This plug-in callback function is called when the user has renamed a
 -- published collection via the Publish Services panel user interface. This is
 -- your plug-in's opportunity to make the corresponding change on the service.

function publishServiceProvider.renamePublishedCollection( publishSettings, info )
	log:trace("publishServiceProvider.renamePublishedCollection (n/a)")	
end
--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- creates a new published collection set or edits an existing one. It can add
 -- additional controls to the dialog box for editing this collection set. These controls
 -- can be used to configure behaviors specific to this collection set (such as
 -- privacy or appearance on a web service).

function publishServiceProvider.viewForCollectionSetSettings( f, publishSettings, info )
	log:trace("publishServiceProvider.viewForCollectionSetSettings (n/a)")
end
--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- closes the dialog for creating a new published collection set or editing an existing
 -- one. It is only called if you have also provided the <code>viewForCollectionSetSettings</code>
 -- callback, and is your opportunity to clean up any tasks or processes you may
 -- have started while the dialog was running.

function publishServiceProvider.endDialogForCollectionSetSettings( publishSettings, info )
	log:trace("publishServiceProvider.endDialogForCollectionSetSettings (n/a)")
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- has changed the per-collection set settings defined via the <code>viewForCollectionSetSettings</code>
 -- callback. It is your opportunity to update settings on your web service to
 -- match the new settings.

function publishServiceProvider.updateCollectionSetSettings( publishSettings, info )
	log:trace("publishServiceProvider.updateCollectionSetSettings (n/a)")
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when new or updated
 -- photos are about to be published to the service. It allows you to specify whether
 -- the user-specified sort order should be followed as-is or reversed. The Flickr
 -- sample plug-in uses this to reverse the order on the Photostream so that photos
 -- appear in the Flickr web interface in the same sequence as they are shown in the 
 -- library grid.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
	-- @param collectionInfo
	-- @name publishServiceProvider.shouldReverseSequenceForPublishedCollection
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param publishedCollectionInfo (<a href="LrPublishedCollectionInfo.html"><code>LrPublishedCollectionInfo</code></a>) an object containing publication information for this published collection.
	-- @return (boolean) true to reverse the sequence when publishing new photos

function publishServiceProvider.shouldReverseSequenceForPublishedCollection( publishSettings, collectionInfo )
	log:trace("publishServiceProvider.shouldReverseSequenceForPublishedCollection n/a")
	return collectionInfo.isDefaultCollection
end

--------------------------------------------------------------------------------
--- This plug-in defined callback function is called when one or more photos
 -- have been removed from a published collection and need to be removed from
 -- the service. If the service you are supporting allows photos to be deleted
 -- via its API, you should do that from this function.
 -- <p>As each photo is deleted, you should call the <code>deletedCallback</code>
 -- function to inform Lightroom that the deletion was successful. This will cause
 -- Lightroom to remove the photo from the "Delete Photos to Remove" group in the
 -- Library grid.</p>

function publishServiceProvider.deletePhotosFromPublishedCollection( publishSettings, arrayOfPhotoIds, deletedCallback )
	log:trace("deletePhotosFromPublishedCollection")

	for i, photoId in ipairs( arrayOfPhotoIds ) do

		local errors = ZenphotoAPI.deletePhoto( publishSettings, {	id = photoId } )

		if errors ~= '' then
			LrDialogs.message( 'Unable to delete image with id: ' .. photoId, errors, 'critical' )
			log:fatal('Unable to delete image with id: ' .. photoId, errors, 'critical')
		end

		deletedCallback( photoId )
	end
	
end

-------------------------------------------------------------------------------
--- This plug-in defined callback function is called when the user attempts to change the name
 -- of a collection, to validate that the new name is acceptable for this service.
 -- <p>This is a blocking call. You should use it only to validate easily-verified
 -- characteristics of the name, such as illegal characters in the name. For
 -- characteristics that require validation against a server (such as duplicate
 -- names), you should accept the name here and reject the name when the server-side operation
 -- is attempted.</p>
	-- @name publishServiceProvider.validatePublishedCollectionName
	-- @class function
 	-- @param proposedName (string) The name as currently typed in the new/rename/edit
		-- collection dialog.
	-- @return (Boolean) True if the name is acceptable, false if not
	-- @return (string) If the name is not acceptable, a string that describes the reason, suitable for display.

function publishServiceProvider.validatePublishedCollectionName( proposedName )
	log:trace("publishServiceProvider.validatePublishedCollectionName")
		if string.match(proposedName, "^[%w%s%_%-%/]+$") then
		return true
	else
		return false, "Only alphanumeric characters accepted'[]0-9AaZz-_/'"
end
end
--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- has attempted to delete one or more published collections defined by your
 -- plug-in from Lightroom. It provides an opportunity for you to customize the
 -- confirmation dialog.

function publishServiceProvider.shouldDeletePublishedCollection( publishSettings, info )
	log:trace("shouldDeletePublishedCollection")
--[[for i, collection in ipairs( info.collections ) do
if collection:getName() == "Sync Albums/Images" then
return "cancel"
end
end--]]
	result = LrDialogs.confirm( 'Delete album from Lightroom and from your Zenphoto webserver', 
								'Do you really want to delete it in Lightroom and on your Zenphoto webserver? All images on your server will be removed but will stay in Lightroom',
								'Delete Album', 
								'Cancel', 
								'Remove from Lightroom' )
	
		if result == 'ok' then return 'delete'
	elseif result == 'other' then return 'ignore'
	  else return 'cancel'
	   end

end

-------------------------------------------------------------------------------
--- This plug-in callback function is called when the user has deleted a
 -- published collection via the Publish Services panel user interface. This is
 -- your plug-in's opportunity to make the corresponding change on the service.
 -- <p>If your plug-in is unable to update the remote service for any reason,
 -- you should throw a Lua error from this function; this causes Lightroom to revert the change.</p>
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.deletePublishedCollection
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param info (table) A table with these fields:
	 -- <ul>
	  -- <li><b>isDefaultCollection</b>: (Boolean) True if this is the default collection.</li>
	  -- <li><b>name</b>: (string) The new name being assigned to this collection.</li>
		-- <li><b>parents</b>: (table) An array of information about parents of this collection, in which each element contains:
			-- <ul>
				-- <li><b>localCollectionId</b>: (number) The local collection ID.</li>
				-- <li><b>name</b>: (string) Name of the collection set.</li>
				-- <li><b>remoteCollectionId</b>: (number or string) The remote collection ID assigned by the server.</li>
			-- </ul> </li>
 	  -- <li><b>publishService</b>: (<a href="LrPublishService.html"><code>LrPublishService</code></a>)
	  -- 	The publish service object.</li>
	  -- <li><b>publishedCollection</b>: (<a href="LrPublishedCollection.html"><code>LrPublishedCollection</code></a>
		-- or <a href="LrPublishedCollectionSet.html"><code>LrPublishedCollectionSet</code></a>)
	  -- 	The published collection object being renamed.</li>
	  -- <li><b>remoteId</b>: (string or number) The ID for this published collection
	  -- 	that was stored via <a href="LrExportSession.html#exportSession:recordRemoteCollectionId"><code>exportSession:recordRemoteCollectionId</code></a></li>
	  -- <li><b>remoteUrl</b>: (optional, string) The URL, if any, that was recorded for the published collection via
	  -- <a href="LrExportSession.html#exportSession:recordRemoteCollectionUrl"><code>exportSession:recordRemoteCollectionUrl</code></a>.</li>
	 -- </ul>

function publishServiceProvider.deletePublishedCollection( publishSettings, info )
	log:trace("deletePublishedCollection")

	import 'LrFunctionContext'.callWithContext( 'publishServiceProvider.deletePublishedCollection', function( context )
	
		local progressScope = LrDialogs.showModalProgressDialog {
							title = LOC( "$$$/Zenphoto/DeletingCollectionAndContents=Deleting photoset ^[^1^]", info.name ),
							functionContext = context }
	
		if info and info.photoIds then
		
			for i, photoId in ipairs( info.photoIds ) do
			
				if progressScope:isCanceled() then break end
			
				progressScope:setPortionComplete( i - 1, #info.photoIds )
				ZenphotoAPI.deletePhoto( publishSettings, photoId )
					log:trace("deletePhoto")
			
			end
		
		end
	
		if info and info.remoteId then

			ZenphotoAPI.deleteAlbum( publishSettings, info.remoteId )
			 prefs[instanceID].albums[info.remoteId].missing = nil
			log:trace("deleteAlbum")

		end
			
	end )

end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user creates
 -- a new publish service via the Publish Manager dialog. It allows your plug-in
 -- to perform additional initialization.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.didCreateNewPublishService
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param info (table) A table with these fields:
	 -- <ul>
	  -- <li><b>connectionName</b>: (string) the name of the newly-created service</li>
	  -- <li><b>publishService</b>: (<a href="LrPublishService.html"><code>LrPublishService</code></a>)
	  -- 	The publish service object.</li>
	 -- </ul>

function publishServiceProvider.didCreateNewPublishService( publishSettings, info )
	local instanceID = publishSettings.localIdentifier
	log:trace("didCreateNewPublishService", instanceID)
	
			-- creating instance table in prefs
				if prefs[instanceID] == nil then
					log:info("Creating instance table (exportServiceProvider)")
					prefs[instanceID] = {}
			log:trace("Inserting new instance")
				table.insert(prefs[instanceID],
					{
					host = propertyTable.host,
					instance_ID = instanceID,
					webpath = propertyTable.webpath,
					uploadMethod = propertyTable.uploadMethod,
					username = "yourname",
					password = "password",
					token = false,
					deepscan = propertyTable.deepscan
					}
				)	
				--adds album table
	if not prefs[instanceID].albums then
	log:info("Creating albums table")
	  --prefs[instanceID].albums = nil
		prefs[instanceID].albums = {}
	end	
	end
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user creates
 -- a new publish service via the Publish Manager dialog. It allows your plug-in
 -- to perform additional initialization.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.didUpdatePublishService
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param info (table) A table with these fields:
	 -- <ul>
	  -- <li><b>connectionName</b>: (string) the name of the newly-created service</li>
	  -- <li><b>nPublishedPhotos</b>: (number) how many photos are currently published on the service</li>
	  -- <li><b>publishService</b>: (<a href="LrPublishService.html"><code>LrPublishService</code></a>)
	  -- 	The publish service object.</li>
	  -- <li><b>changedMoreThanName</b>: (boolean) true if any setting other than the name
	  --  (description) has changed</li>
	 -- </ul>
	 
function publishServiceProvider.didUpdatePublishService( publishSettings, info )
log:trace("publishServiceProvider.didUpdatePublishService")
	log:debug("didUpdate PublishSettings: ".. table_show(publishSettings))
	log:debug("didUpdate Info: ".. table_show(info))
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- has attempted to delete the publish service from Lightroom.
 -- It provides an opportunity for you to customize the confirmation dialog.
 -- <p>Do not use this hook to actually tear down the service. Instead, use
 -- <a href="#publishServiceProvider.willDeletePublishService"><code>willDeletePublishService</code></a>
 -- for that purpose.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.shouldDeletePublishService
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param info (table) A table with these fields:
	  -- <ul>
		-- <li><b>publishService</b>: (<a href="LrPublishService.html"><code>LrPublishService</code></a>)
		-- 	The publish service object.</li>
		-- <li><b>nPhotos</b>: (number) The number of photos contained in
		-- 	published collections within this service.</li>
		-- <li><b>connectionName</b>: (string) The name assigned to this publish service connection by the user.</li>
	  -- </ul>
	-- @return (string) 'cancel', 'delete', or nil (to allow Lightroom's default
		-- dialog to be shown instead)--]]
		
function publishServiceProvider.shouldDeletePublishService( publishSettings, info )
	log:trace("publishServiceProvider.shouldDeletePublishService")
	--Lets cleanup published instance.
	--LrDialogs.message('Attempt to clean up instance')
	--return cancel
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- has confirmed the deletion of the publish service from Lightroom.
 -- It provides a final opportunity for	you to remove private data
 -- immediately before the publish service is removed from the Lightroom catalog.
 -- <p>Do not use this hook to present user interface (aside from progress,
 -- if the operation will take a long time). Instead, use 
 -- <a href="#publishServiceProvider.shouldDeletePublishService"><code>shouldDeletePublishService</code></a>
 -- for that purpose.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.willDeletePublis-hService
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param info (table) A table with these fields:
	 -- <ul>
		-- <li><b>publishService</b>: (<a href="LrPublishService.html"><code>LrPublishService</code></a>)
		-- 	The publish service object.</li>
		-- <li><b>nPhotos</b>: (number) The number of photos contained in
		-- 	published collections within this service.</li>
		-- <li><b>connectionName</b>: (string) The name assigned to this publish service connection by the user.</li>
	-- </ul> --]]

function publishServiceProvider.willDeletePublishService( publishSettings, info )
	log:trace("publishServiceProvider.willDeletePublishService", table_show(publishSettings))
	log:trace("publishServiceProvider.willDeletePublishServiceinfo", table_show(info))
		local instanceID = publishSettings.instance_ID
		log:trace("willDeletePublishServiceinfo-instanceID ", instanceID)
		
	--remove instanceID settings (general cleanup)	
	prefs[instanceID] = {}
	prefs[instanceID] = nil
	table.remove(prefs,instanceID)
	prefs[instanceID] = prefs[instanceID]
	log:trace("DeletePublishService.removed the published instance :", table_show(prefs[instanceID]))
	
	local publishService = info.publishService
	local publishedPhotos = publishService.catalog:findPhotosWithProperty( "org.zenphoto.lightroom.publisher", "photoId" )
	for _, photo in ipairs( publishedPhotos ) do
		photo:setPropertyForPlugin( _PLUGIN, "uploaded", nil )
		photo:setPropertyForPlugin( _PLUGIN, "albumurl", nil )
	end	
		log:trace("DeletePublishService.removed custom metadata")
end

function publishServiceProvider.shouldDeletePhotosFromServiceOnDeleteFromCatalog( publishSettings, nPhotos )
	log:trace("shouldDeletePhotosFromServiceOnDeleteFromCatalog (n/a)")
end

function publishServiceProvider.imposeSortOrderOnPublishedCollection( publishSettings, info, remoteIdSequence )
	log:trace("publishServiceProvider.imposeSortOrderOnPublishedCollection (n/a)")
end

-------------------------------------------------------------------------------
--- This plug-in callback function is called when the user has reparented a
 -- published collection via the Publish Services panel user interface. This is
 -- your plug-in's opportunity to make the corresponding change on the service.

function publishServiceProvider.reparentPublishedCollection( publishSettings, info )
	log:trace("publishServiceProvider.reparentPublishedCollection (n/a)")
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called (if supplied)  
 -- to retrieve comments from the remote service, for a single collection of photos 
 -- that have been published through this service. This function is called:
 
function publishServiceProvider.getCommentsFromPublishedCollection( publishSettings, arrayOfPhotoInfo, commentCallback )
	log:trace("getCommentsFromPublishedCollection"..table_show(publishSettings))
		--set instance ID
	instanceID = publishSettings.instance_ID
		-- Make sure we're logged in.
	require 'ZenphotoUser'
	ZenphotoUser.initLogin( publishSettings )
	
	for i, photoInfo in ipairs( arrayOfPhotoInfo ) do
	local comments = ZenphotoAPI.getImageComments(photoInfo)
	log:trace('getCommentsData: '..table_show(comments))

	local commentList = {}
				
		if comments and #comments > 0 then

			for _, comment in ipairs( comments ) do
			
				table.insert( commentList, {
								commentId 		= comment["commentId"],
								commentText 	= comment["commentData"],
								dateCreated 	= LrDate.timeFromPosixDate(tonumber(comment["commentDate"])),
								username 		= comment["commentUsername"],
								realname		= comment["commentRealname"],
								url 			= comment["commentUrl"],
							} )
			end			
		end	
		--log:info('commentliststart: ' ..table_show(commentList))
		commentCallback{ publishedPhoto = photoInfo, comments = commentList }		
	end	
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called whenever a
 -- published photo is selected in the Library module. Your implementation should
 -- return true if there is a viable connection to the publish service and
 -- comments can be added at this time. If this function is not implemented,
 -- the new comment section of the Comments panel in the Library is left enabled
 -- at all times for photos published by this service. If you implement this function,
 -- it allows you to disable the Comments panel temporarily if, for example,
 -- the connection to your server is down.

function publishServiceProvider.canAddCommentsToService( publishSettings )
	log:trace("canAddCommentsToService")
	return false --publishSettings.commentson
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user adds 
 -- a new comment to a published photo in the Library module's Comments panel. 
 -- Your implementation should publish the comment to the service.

function publishServiceProvider.addCommentToPublishedPhoto( publishSettings, remotePhotoId, commentText )
	log:trace("addCommentToPublishedPhoto")
		local success = ZenphotoAPI.addComment( publishSettings, {
							Id = remotePhotoId,
							commentText = commentText,
						} )
	return success

end
-----------------------------------------------------------------------------

--- (optional) This plug-in defined callback function is called (if supplied)
 -- to retrieve ratings from the remote service, for a single collection of photos 
 -- that have been published through this service. This function is called:

function publishServiceProvider.getRatingsFromPublishedCollection( publishSettings, arrayOfPhotoInfo, ratingCallback )
	log:trace("getRatingsFromPublishedCollection "..table_show(arrayOfPhotoInfo))
		for i, photoInfo in ipairs( arrayOfPhotoInfo ) do
		local rating = ZenphotoAPI.getImageRating( arrayOfPhotoInfo, { photoId = photoInfo.remoteId } )
			log:trace('getRatingsData: '..table_show(rating))
		if type( rating ) == 'string' then rating = tonumber( rating ) end

		ratingCallback{ publishedPhoto = photoInfo, rating = rating or 0 }

	end
	return true
end

function publishServiceProvider.endDialog(propertyTable, why)
	log:trace("publishServiceProvider.endDialog")	
	if why=="ok" then
		if not propertyTable.instanceKey then propertyTable.instanceKey = (import 'LrDate').currentTime() end
	end
end

--------------------------------------------------------------------------------
--publishServiceProvider.disableRenamePublishedCollection = true;
ZenphotoPublishSupport = publishServiceProvider