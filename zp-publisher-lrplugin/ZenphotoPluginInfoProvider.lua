--[[----------------------------------------------------------------------------

ZenphotoServiceProvider.lua
Export service provider description for Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]

local LrLogger = import 'LrLogger'
local log = LrLogger( 'ZenphotoLog' )
-- Zenphoto plugin
require 'ZenphotoDialogSections'
--require "LRLib_SelfUpdate"
local endD = {}
local endDone = {}

--startD.startDialog = function(startDone)
  --LRLib_SelfUpdate.startDialog(startDone)
  --ExportToEmailPlugin.startDialog(startDone)
--end


endD.endDialog = function(endD,endDone)
  ZenphotoDialogSections.endDialog(endD,endDone)
  --LRLib_SelfUpdate.endDialog(endD,endDone)
end

return {
startDialog = ZenphotoDialogSections.startDialog,
	sectionsForTopOfDialog = ZenphotoDialogSections.sectionsForTopOfDialog,
	
--sectionsForBottomOfDialog = LRLib_SelfUpdate.PluginInfoSection,
--sectionsForTopOfDialog = ExportToEmailPlugin.sectionsForTopOfDialog,
	--startDialog = startD.startDialog, --ExportToEmailPlugin.startDialog,
	endDialog =  endD.endDialog, --ExportToEmailPlugin.endDialog,
}	
