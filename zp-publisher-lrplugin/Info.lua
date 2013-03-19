--[[----------------------------------------------------------------------------

Plug-in Name: Zenphoto Publisher
Version: 2.1.201207072318
Author URI: http://www.lokkju.com / http://www.lokiphoto.com
Author URI: http://www.elementalpress.com / http://www.elementalshoots.com
Author: Loki
Author: L. Hagen

------------------------------------------------------------------------------]]

return 
{
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 3.0,

	LrToolkitIdentifier = 'zenphoto.publisherZ',
	LrPluginName = 'ZenPhoto Publisher',
	LrPluginInfoUrl = 'http://code.google.com/p/zenphoto-publisher/',

	VERSION = { major=2, minor=1, revision=201207072318, nil, },

	LrPluginInfoProvider = 'ZenphotoPluginInfoProvider.lua',

	LrExportServiceProvider = {
		title = LOC "$$$/zenphoto/zenphoto=ZenPhoto Publisher",
		file = 'ZenphotoExportServiceProvider.lua',
	},
}

