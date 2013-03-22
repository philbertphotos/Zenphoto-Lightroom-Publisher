--[[----------------------------------------------------------------------------

ZenphotoPublishSupportExtention.lua
some functions to extend the PublishSupport portions of Lightroom

------------------------------------------------------------------------------]]

	-- Lightroom SDK
local LrDialogs 		= import 'LrDialogs'
local LrBinding 		= import 'LrBinding'
local LrLogger          = import 'LrLogger'
local LrFunctionContext	= import 'LrFunctionContext'
local LrProgressScope	= import 'LrProgressScope'
local LrTasks			= import 'LrTasks'
local LrErrors			= import 'LrErrors'
local LrStringUtils		= import 'LrStringUtils'

local LrView	= import 'LrView'
local bind 		= LrView.bind

require 'ZenphotoAPI'

    -- Logger
local LrLogger = import 'LrLogger'
local log = LrLogger( 'ZenphotoLog' )

--============================================================================--

publishServiceExtention = {}

--------------------------------------------------------------------------------

function publishServiceExtention.getImages( publishedCollection, id, publishService, context)
	log:info('reading images from server...')
	
    local progressScope = LrDialogs.showModalProgressDialog({
      title = 'Syncing image data from server',
      caption = 'load image log:info from server for album: ' .. publishedCollection:getName(),
      cannotCancel = false,
      functionContext = context,
    })

	local publishService = publishService or publishedCollection:getService()
	local missing = {}
	

	catalog = publishedCollection.catalog
	catalog:withWriteAccessDo('empty album', function()
		publishedCollection:removeAllPhotos()
	end)

	local images, err = ZenphotoAPI.getAlbumImages(id)

	if err then
		LrDialogs.message('Database error - AlbumID '..id..' does not exist', 'You attempt to access to a non existing database entry! Please re-sync your album and try again!', 'warn')
		LrErrors.throwCanceled()
	end

	for i, image in pairs ( images ) do
		progressScope:setCaption('syncing image: ' .. tostring(image.name) .. ' (' .. i .. ' of ' .. #images .. ')' )
		progressScope:setPortionComplete( i, #images )
		
		if progressScope:isCanceled() then LrErrors.throwCanceled() end
		
		LrTasks.yield()
		
		imagename = trim(Utils.getFilenameNoExt(image.name))
		photos = catalog:findPhotos {
			searchDesc = {
					criteria = 'filename',
					operation = 'any',
					value = imagename..'.',
			},
		}

	
		local photo = nil
--		if photos and #photos > 1 then
--			photo = publishServiceExtention.selectPhoto(photos, catalog)
--		else
			photo = photos[1]
--		end

		
		
		if photo then
			catalog:withWriteAccessDo('add photo to collection', function()
				log:info("+ photo: " .. photo:getFormattedMetadata( 'fileName' ))
				publishedCollection:addPhotoByRemoteId( photo, image.id, image.url, true )
			end)
		else
			log:info("- photo: " .. imagename)
			table.insert(missing, imagename)
		end
	end

	log:info('reading images from server...done')
	LrTasks.yield()
	progressScope:done()

	return missing
end



--
--
--	Show Missing files dialog
--
--
function publishServiceExtention.selectPhoto(photos, catalog)

	local photolist = {}
	for i, photo in pairs ( photos ) do
		local entry = { { title = photo:getFormattedMetadata('fileName'), value = photo} }
--		local entry = { { title = photo:getRawMetadata('fileFormat'), value = photo:getRawMetadata('masterPhoto') } }
		photolist = Utils.joinTables(photolist, entry)
		
	end


	
	LrFunctionContext.callWithContext( 'selectPhotoDialog', function( context )
		local propertyTable = LrBinding.makePropertyTable(context)
		propertyTable.photolist = photolist
		propertyTable.selected = photos[1]:getRawMetadata('masterPhoto')
		
		local LrView = import 'LrView'
		local f = LrView.osFactory()
		local contents = f:row {
								title = "Multiple photos with same name found",
								size = 'small',
								fill_horizontal = 1,

	--						f:picture {
	--							value = _PLUGIN:resourceId('zenphoto_album.png'),
	--							},
				
							f:column {
								bind_to_object = assert( propertyTable ),
								fill_horizontal = 1,	
								f:row {
									f:static_text {
										title = "Select photo by name:",
										alignment = "right",
										width = 100,
										},
										
									f:popup_menu {
										value = bind 'selected',
										items = photolist,
										fill_horizontal = 1,
										immediate = true,
										},
								},
							},
						}
						
		local result = LrDialogs.presentModalDialog(
		{
			title = 'Missing files',
			contents = contents,
		})
		
		if result == 'ok' then
			selectedPhoto = propertyTable.selected
		end
		
	end)

	return selectedPhoto
end

function publishServiceExtention.findRoot(collection)
	local root
	
	repeat
		collection = collection:getParent()
		if collection then
			root = collection
		end
	until collection == nil

	if root then return root else return collection end
end	 


function publishServiceExtention.getDefaultCollection(collection)

	local rootCollectionSet = publishServiceExtention.findRoot(collection)

	if rootCollectionSet then
		for i, collection in pairs( rootCollectionSet:getChildCollections() ) do
			if collection:getName() == 'all other' then return collection end
		end
	end

	return {}
end

function publishServiceExtention.getAllPublishedPhotos(collection, arrayOfPublishedPhotos)

	if not arrayOfPublishedPhotos then arrayOfPublishedPhotos = {} end

	if collection:type() == 'LrPublishedCollectionSet' then
		for j, childCollection in pairs (collection:getChildCollections()) do
			publishServiceExtention.getAllPublishedPhotos(childCollection, arrayOfPublishedPhotos)
		end
	end

	if collection:type() == 'LrPublishedCollection' then
		for j, publishedPhoto in pairs (collection:getPublishedPhotos()) do
			log:debug(publishedPhoto)
			table.insert(arrayOfPublishedPhotos, publishedPhoto)
		end
	end

	return arrayOfPublishedPhotos
end


function publishServiceExtention.removeAllPhotos( collection )
	if collection:type() == 'LrPublishedCollectionSet' then
		for j, childCollection in pairs (collection:getChildCollections()) do
			publishServiceExtention.removeAllPhotos(childCollection)
		end
	end

	if collection:type() == 'LrPublishedCollection' then
		collection:removeAllPhotos()
	end
end


function publishServiceExtention.collectionNameExists( publishService, name )
	for j, childCollection in pairs (publishService:getChildCollections()) do
		if LrStringUtils.lower(childCollection:getName()) == LrStringUtils.lower(name) then
			return true
		end
	end
	return false
end
