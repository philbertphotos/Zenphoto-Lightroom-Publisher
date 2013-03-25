--[[----------------------------------------------------------------------------
Plug-in Name: Zenphoto Publisher
Version: 3.0.1
Author URI: http://www.lokkju.com
Author URI: http://www.elementalpress.com
Author: Loki
Author: L. Hagen
----------------------
Developer: Joseph Philbert 
Developer URI: http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher

------------------------------------------------------------------------------]]
local majorVersion = 3
local minorVersion = 0
local revisionVersion = 2
local dateVersion = 20130323
ZenphotoInfo = {}	
	local displayVersion = ZenphotoInfo.version
ZenphotoInfo.version = majorVersion .. minorVersion .. revisionVersion .. dateVersion 
ZenphotoInfo.versionDot = majorVersion .."." .. minorVersion .. "." .. revisionVersion .. "." .. dateVersion
ZenphotoInfo.location = "http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher"

return 
{
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,

	LrToolkitIdentifier = 'org.zenphoto.lightroom.publisher',
	LrPluginName = 'ZenPhoto Publisher',
	LrPluginInfoUrl = 'http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher',
		LrInitPlugin = "ZenphotoInit.lua",
		LrMetadataProvider = 'ZenphotoMetadata.lua',		
		LrMetadataTagsetFactory = "ZenphotoTagset.lua",

	VERSION = { major=3, minor=0, revision=2, nil, },

	LrPluginInfoProvider = 'ZenphotoPluginInfoProvider.lua',

	LrExportServiceProvider = {
		title = LOC "$$$/zenphoto/zenphoto=ZenPhoto Publisher",
		file = 'ZenphotoExportServiceProvider.lua',
	},
}

