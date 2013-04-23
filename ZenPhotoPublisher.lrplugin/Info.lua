--[[----------------------------------------------------------------------------
Plug-in Name: Zenphoto Publisher
Version: 4.0.1
Author URI: http://www.lokkju.com
Author URI: http://www.elementalpress.com
Author: Loki
Author: L. Hagen
----------------------
Developer: Joseph Philbert
Developer URI: http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher

------------------------------------------------------------------------------]]

local majorVersion = 4
local minorVersion = 0
local revisionVersion = 1
local dateVersion = 20130423
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
	LrPluginInfoProvider = 'ZenphotoPluginInfoProvider.lua',

	LrExportServiceProvider = {
		title = LOC "$$$/zenphoto/zenphoto=ZenPhoto Publisher",
		file = 'ZenphotoExportServiceProvider.lua',
	},
	VERSION = { major=4, minor=0, revision=1, build=20130423, nil, },
}
