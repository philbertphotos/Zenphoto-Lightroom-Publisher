--[[----------------------------------------------------------------------------

ZenphotoPublishSupport.lua
Publish-specific portions of Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]

	-- Lightroom SDK
local LrDialogs 		= import 'LrDialogs'
local LrHttp			= import 'LrHttp'
local LrStringUtils		= import 'LrStringUtils'
local LrTasks			= import 'LrTasks'
local LrErrors			= import 'LrErrors'
local LrFunctionContext	= import 'LrFunctionContext'
local prefs 			= import 'LrPrefs'.prefsForPlugin()

require 'ZenphotoAPI'
require 'ZenphotoPublishSupportExtention'

    -- Logger
local LrLogger = import 'LrLogger'
local log = LrLogger( 'ZenphotoLog' )

--============================================================================--

local publishServiceProvider = {}

publishServiceProvider.small_icon = 'zenphoto_small.png'
publishServiceProvider.publish_fallbackNameBinding = 'fullname'
publishServiceProvider.titleForPublishedCollection = 'Album'
--publishServiceProvider.titleForPublishedCollectionSet = 'Event / Division'
--publishServiceProvider.titleForPublishedCollection_standalone = LOC "$$$/Zenphoto/TitleForPublishedCollection/Standalone=Photoset"
--publishServiceProvider.titleForPublishedCollectionSet_standalone = "new album"
--publishServiceProvider.titleForPublishedSmartCollection = LOC "$$$/Zenphoto/TitleForPublishedSmartCollection=Smart Photoset"
--publishServiceProvider.titleForPublishedSmartCollection_standalone = LOC "$$$/Zenphoto/TitleForPublishedSmartCollection/Standalone=Smart Photoset"
publishServiceProvider.disableRenamePublishedCollection = false
publishServiceProvider.disableRenamePublishedCollectionSet = true
publishServiceProvider.supportsCustomSortOrder = true
publishServiceProvider.titleForPhotoRating = LOC "$$$/Zenphoto/TitleForPhotoRating=Favorite Count"
publishServiceProvider.titleForGoToPublishedCollection = LOC "$$$/Zenphoto/TitleForGoToPublishedCollection=Show album on ZenPhoto"
publishServiceProvider.titleForGoToPublishedPhoto = LOC "$$$/Zenphoto/TitleForGoToPublishedPhoto=Show image on ZenPhoto"




function publishServiceProvider.getCollectionBehaviorInfo( publishSettings )
	log:debug("getCollectionBehaviorInfo-Sync Albums/Images")
	return {
		defaultCollectionName = "Sync Albums/Images",
		defaultCollectionCanBeDeleted = false,
		canAddCollection = true,
		maxCollectionSetDepth = 0,
	}
	
end


--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called whenever a new
 -- publish service is created and whenever the settings for a publish service
 -- are changed. It allows the plug-in to specify which metadata should be
 -- considered when Lightroom determines whether an existing photo should be
 -- moved to the "Modified Photos to Re-Publish" status.
 
function publishServiceProvider.metadataThatTriggersRepublish( publishSettings )
	log:debug("publishServiceProvider.metadataThatTriggersRepublish")
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
	log:debug("publishServiceProvider.goToPublishedCollection")
	if info.remoteUrl then
--		local publishServiceID = assert( info.publishService.localIdentifier )
		LrHttp.openUrlInBrowser( 'http://' .. prefs.host .. info.remoteUrl )
	end
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user chooses the
 -- "Go to Published Photo" context-menu item.
	 
function publishServiceProvider.goToPublishedPhoto( publishSettings, info )
	log:debug("publishServiceProvider.goToPublishedPhoto")
	if info.remoteUrl then
--		local publishServiceID = assert( info.publishService.localIdentifier )
		LrHttp.openUrlInBrowser( 'http://' .. prefs.host .. info.remoteUrl )
	end
end


--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- creates a new published collection or edits an existing one. It can add
 -- additional controls to the dialog box for editing this collection. These controls
 -- can be used to configure behaviors specific to this collection (such as
 -- privacy or appearance on a web service).

 function publishServiceProvider.viewForCollectionSettings( f, publishSettings, info )
	log:debug("publishServiceProvider.viewForCollectionSettings")
--	local publishServiceID = assert( info.publishService.localIdentifier )	
	if prefs.token ~= 'OK' then
		LrDialogs.message("You are not logged in info")
		--LrErrors.throwCanceled()
		log:info("You are not logged in ERROR" , prefs.token)
		local collectionSettings = assert( info.collectionSettings )
		
		collectionSettings.syncEnabled = false
		
		
      --LrErrors.throwUserError("You are not logged in info")
	--end
else
log:info("viewForCollectionSettings -  After Else")
	local bind = import 'LrView'.bind
	
	local albumlist = ZenphotoAPI.getAlbums(publishSettings, true)
	local pubCollection = nil
	local collectionSettings = assert( info.collectionSettings )
log:info("viewForCollectionSettings / ZenphotoAPI.getAlbums")
	if not collectionSettings.folder then
		collectionSettings.folder = ''
	end
	
	if not collectionSettings.parentFolder then
		collectionSettings.parentFolder = ''
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
		if remoteId then
			collectionSettings.syncEnabled = true
			collectionSettings.missing = prefs.missing[remoteId]
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
					title = "Manage Album",
					size = 'small',
					fill_horizontal = 1,

					f:push_button {
						fill_horizontal = 1,
						title = 'Sync albums',
						action = function()
									LrTasks.startAsyncTask( function()
										LrFunctionContext.callWithContext('function', function(context)

											exportServiceProvider.sync(false, info.publishService, context)

										end)
									end)
						end,
					},
					f:push_button {
						fill_horizontal = 1,
						title = 'Sync all images',
						action = function()
									LrTasks.startAsyncTask( function()
										LrFunctionContext.callWithContext('function', function(context)

											exportServiceProvider.sync(true, info.publishService, context)

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
						title = "Manage Album",
						size = 'small',
						fill_horizontal = 1,

						f:row {
							f:static_text {
								title = "* Foldername:",
								alignment = "right",
								width = 100,
								},
								
							f:popup_menu {
								value = bind 'parentFolder',
								items = albumlist,
								fill_horizontal = 1,
								immediate = true,
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
												
						f:row {
							f:static_text {
								title = "Album Password:",
								alignment = "right",
								width = 100,
								},

							f:edit_field {
								value = bind 'password',
								width_in_chars = 38,
								},
						},

						f:row {
							f:static_text {
								width = 100,
								},
							f:checkbox {
								title = "Album published",
								checked_value = '1',
								unchecked_value = '0',
								value = bind 'show',
								},
							f:checkbox {
								title = "Allow comments",
								checked_value = '1',
								unchecked_value = '0',
								value = bind 'commentson',
								},
						},
					},
					
					spacing = f:control_spacing(),

					f:group_box {
						fill_horizontal = 1,
						title = "Sync images from server",
						size = 'small',

						f:row {
							f:push_button {
								fill_horizontal = 1,
								title = 'Sync images',
								enabled = bind 'syncEnabled',
								action = function()

											LrTasks.startAsyncTask( function()
												LrFunctionContext.callWithContext('function', function(context)

													prefs.missing[remoteId] = {}
													collectionSettings.missing = publishServiceExtention.getImages( pubCollection, remoteId, info.publishService, context)
													prefs.missing[remoteId] = collectionSettings.missing

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
										prefs.missing[remoteId] = {}
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
	log:debug("publishServiceProvider.updateCollectionSettings")
	if prefs.token ~= 'OK' then
	else
	if info.collectionSettings.folder == '' then
		info.collectionSettings.folder = LrStringUtils.lower( info.name )
	end
	
	
	LrTasks.startAsyncTask( function()

		--
		--	create new collection
		--
		if info.name then

			local status, err
			if not info.publishedCollection or not info.publishedCollection:getRemoteId() then
			
				log:debug("album create")
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
				remoteId = info.publishedCollection:getRemoteId()
			end
			
			status, err = ZenphotoAPI.editAlbum( publishSettings, {
																  id = remoteId,
																name = info.name,
															  folder = info.collectionSettings.folder,
														parentFolder = info.collectionSettings.parentFolder,
														 description = LrStringUtils.encodeBase64(info.collectionSettings.description),
															location = LrStringUtils.encodeBase64(info.collectionSettings.location),
															password = info.collectionSettings.password,
																show = info.collectionSettings.show,
														  commentson = info.collectionSettings.commentson,
													})
				
			--
			if password == not nil then
			albumpassword = info.collectionSettings.password
					log:trace("album password:"..albumpassword)
			end
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
	log:debug("publishServiceProvider.endDialogForCollectionSettings (n/a)")
end


-------------------------------------------------------------------------------
--- This plug-in callback function is called when the user has renamed a
 -- published collection via the Publish Services panel user interface. This is
 -- your plug-in's opportunity to make the corresponding change on the service.

function publishServiceProvider.renamePublishedCollection( publishSettings, info )
	log:debug("publishServiceProvider.renamePublishedCollection (n/a)")	
end


--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- creates a new published collection set or edits an existing one. It can add
 -- additional controls to the dialog box for editing this collection set. These controls
 -- can be used to configure behaviors specific to this collection set (such as
 -- privacy or appearance on a web service).

function publishServiceProvider.viewForCollectionSetSettings( f, publishSettings, info )
	log:debug("publishServiceProvider.viewForCollectionSetSettings (n/a)")
end


--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- closes the dialog for creating a new published collection set or editing an existing
 -- one. It is only called if you have also provided the <code>viewForCollectionSetSettings</code>
 -- callback, and is your opportunity to clean up any tasks or processes you may
 -- have started while the dialog was running.

function publishServiceProvider.endDialogForCollectionSetSettings( publishSettings, info )
	log:debug("publishServiceProvider.endDialogForCollectionSetSettings (n/a)")
end


--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- has changed the per-collection set settings defined via the <code>viewForCollectionSetSettings</code>
 -- callback. It is your opportunity to update settings on your web service to
 -- match the new settings.

function publishServiceProvider.updateCollectionSetSettings( publishSettings, info )
	log:debug("publishServiceProvider.updateCollectionSetSettings (n/a)")
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
	log:debug("publishServiceProvider.shouldReverseSequenceForPublishedCollection")
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
	log:debug("publishServiceProvider.deletePhotosFromPublishedCollection")

	for i, photoId in ipairs( arrayOfPhotoIds ) do

		local errors = ZenphotoAPI.deletePhoto( publishSettings, {	id = photoId } )

		if errors ~= '' then
			LrDialogs.message( 'Unable to delete image with id: ' .. photoId, errors, 'critical' )
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
	log:debug("publishServiceProvider.validatePublishedCollectionName")
	if string.find(proposedName,'/') then return false else return true end
end



--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user
 -- has attempted to delete one or more published collections defined by your
 -- plug-in from Lightroom. It provides an opportunity for you to customize the
 -- confirmation dialog.

function publishServiceProvider.shouldDeletePublishedCollection( publishSettings, info )
	log:debug("publishServiceProvider.shouldDeletePublishedCollection")

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
	log:debug("publishServiceProvider.deletePublishedCollection")

	import 'LrFunctionContext'.callWithContext( 'publishServiceProvider.deletePublishedCollection', function( context )
	
		local progressScope = LrDialogs.showModalProgressDialog {
							title = LOC( "$$$/Zenphoto/DeletingCollectionAndContents=Deleting photoset ^[^1^]", info.name ),
							functionContext = context }
	
		if info and info.photoIds then
		
			for i, photoId in ipairs( info.photoIds ) do
			
				if progressScope:isCanceled() then break end
			
				progressScope:setPortionComplete( i - 1, #info.photoIds )
				ZenphotoAPI.deletePhoto( publishSettings, photoId )
			
			end
		
		end
	
		if info and info.remoteId then

			ZenphotoAPI.deleteAlbum( publishSettings, info.remoteId )
			prefs.missing[info.remoteId] = nil

		end
			
	end )

end









function publishServiceProvider.didCreateNewPublishService( publishSettings, info )
	log:debug("publishServiceProvider.didCreateNewPublishService (n/a)")
end

function publishServiceProvider.didUpdatePublishService( publishSettings, info )
	log:debug("publishServiceProvider.didUpdatePublishService (n/a)")
end

function publishServiceProvider.shouldDeletePublishService( publishSettings, info )
	log:debug("publishServiceProvider.shouldDeletePublishService (n/a)")
end

function publishServiceProvider.willDeletePublishService( publishSettings, info )
	log:debug("publishServiceProvider.willDeletePublishService (n/a)")
	
--	publishServiceID = ZenphotoAPI.initPublishServiceID( publishSettings )
--	prefs[publishServiceID] = nil
	
end

function publishServiceProvider.shouldDeletePhotosFromServiceOnDeleteFromCatalog( publishSettings, nPhotos )
	log:debug("publishServiceProvider.shouldDeletePhotosFromServiceOnDeleteFromCatalog (n/a)")
end

function publishServiceProvider.imposeSortOrderOnPublishedCollection( publishSettings, info, remoteIdSequence )
	log:debug("publishServiceProvider.imposeSortOrderOnPublishedCollection (n/a)")
end


-------------------------------------------------------------------------------
--- This plug-in callback function is called when the user has reparented a
 -- published collection via the Publish Services panel user interface. This is
 -- your plug-in's opportunity to make the corresponding change on the service.

function publishServiceProvider.reparentPublishedCollection( publishSettings, info )
	log:debug("publishServiceProvider.reparentPublishedCollection (n/a)")
end


--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called (if supplied)  
 -- to retrieve comments from the remote service, for a single collection of photos 
 -- that have been published through this service. This function is called:

function publishServiceProvider.getCommentsFromPublishedCollection( publishSettings, arrayOfPhotoInfo, commentCallback )
	log:debug("publishServiceProvider.getCommentsFromPublishedCollection (n/a)")
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called (if supplied)
 -- to retrieve ratings from the remote service, for a single collection of photos 
 -- that have been published through this service. This function is called:

function publishServiceProvider.getRatingsFromPublishedCollection( publishSettings, arrayOfPhotoInfo, ratingCallback )
	log:debug("publishServiceProvider.getRatingsFromPublishedCollection (n/a)")
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
	log:debug("publishServiceProvider.canAddCommentsToService (n/a)")
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user adds 
 -- a new comment to a published photo in the Library module's Comments panel. 
 -- Your implementation should publish the comment to the service.

function publishServiceProvider.addCommentToPublishedPhoto( publishSettings, remotePhotoId, commentText )
	log:debug("publishServiceProvider.addCommentToPublishedPhoto (n/a)")
end

--------------------------------------------------------------------------------

ZenphotoPublishSupport = publishServiceProvider
