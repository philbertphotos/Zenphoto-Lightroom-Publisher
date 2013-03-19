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

return 
{
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,

	LrToolkitIdentifier = 'zenphoto.lightroom.publisher',
	LrPluginName = 'ZenPhoto Publisher',
	LrPluginInfoUrl = 'http://code.google.com/p/zenphoto-publisher/',

	VERSION = { major=3, minor=0, revision=1, nil, },

	LrPluginInfoProvider = 'ZenphotoPluginInfoProvider.lua',

	LrExportServiceProvider = {
		title = LOC "$$$/zenphoto/zenphoto=ZenPhoto Publisher",
		file = 'ZenphotoExportServiceProvider.lua',
	},
}

