--[[----------------------------------------------------------------------------

ZenphotoPluginInfoProvider.lua
Export service provider description for Lightroom Zenphoto uploader
------------------------------------------------------------------------------]]
require 'ZenphotoDialogSections'
--require "LRLib_SelfUpdate"
local startD = {}
local endD = {}
local startDone = {}
local endDone = {}

startD.startDialog = function(startDone)
  ZenphotoDialogSections.startDialog(startDone)
end


endD.endDialog = function(endD,endDone)
  ZenphotoDialogSections.endDialog(endD,endDone)
end

return {
startDialog = ZenphotoDialogSections.startDialog,
sectionsForTopOfDialog = ZenphotoDialogSections.sectionsForTopOfDialog,
startDialog = startD.startDialog,
	endDialog =  endD.endDialog,
}
