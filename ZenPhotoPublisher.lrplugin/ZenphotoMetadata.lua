--[[-----------------------------+-----------------------------------------------

ZenphotoMetadata.lua
Zenphoto metadata management
Copyright (c) 2013, Joseph Philbert (https://github.com/philbertphotos/Zenphoto-Lightroom-Publisher)
------------------------------------------------------------------------------]]
return {

  metadataFieldsForPhotos = {

		{
			id = 'zenphotopublishedinfo',
		},
		
		{
			id = 'uploaded',
			title = "Uploaded",
			dataType = 'enum',
			searchable = true,
			browsable = true,
			--updateFromEarlierSchemaVersion = true,
			version = 1,
			values = {
				{
					value = 'true',
					title = "True",
				},
				{
					value = 'false',
					title = "False",
				},
			},
		},
		
		{
			id = 'albumurl',
			title = "Album URL",
			dataType = 'string', -- Specifies the data type for this field.
			searchable = true,
			browsable = true,
			--updateFromEarlierSchemaVersion = true,
			version = 1,
		},

	},
	
	schemaVersion = 1,

}
