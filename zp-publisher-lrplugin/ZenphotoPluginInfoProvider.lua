--[[----------------------------------------------------------------------------

ZenphotoServiceProvider.lua
Export service provider description for Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]

-- Zenphoto plugin
require 'ZenphotoDialogSections'

return {
	startDialog = ZenphotoDialogSections.startDialog,
	sectionsForTopOfDialog = ZenphotoDialogSections.sectionsForTopOfDialog,
}
