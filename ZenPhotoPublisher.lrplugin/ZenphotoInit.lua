--[[----------------------------------------------------------------------------

ZenphotoInit.lua
Initializes service provider description for Lightroom Zenphoto plugin

--------------------------------------------------------------------------------

Joseph Philbert
Copyright 2013 Daniel Lienert und Michael Knoll
see http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher/ for further information
All Rights Reserved.

This script is part of the yag project. The yag project is
free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

The GNU General Public License can be found at
http://www.gnu.org/copyleft/gpl.html.

This script is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

This copyright notice MUST APPEAR in all copies of the script!

------------------------------------------------------------------------------]]
local prefs 		= import 'LrPrefs'.prefsForPlugin()
local LrFileUtils 	= import 'LrFileUtils'
local LrPathUtils 	= import 'LrPathUtils'
require 'Utils'
require 'ZenphotoAPI'
require 'Info'
require 'ZenphotoDialogSections'

local logger = import 'LrLogger'
-- Define logger globally
log = logger( 'zenphotopublisher' ) -- the log file name.
log:enable( "logfile" )

local logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "zenphotopublisher.log")
if LrFileUtils.exists( logPath ) then
local success, reason = LrFileUtils.delete( logPath )
if not success then
log:error("Error deleting existing logfile!" .. reason)
end
end

log:info("LR/Zenphoto loading.")
log:info("Version " .. getVersion() .. " in Lightroom " .. import 'LrApplication'.versionString() .. " running on " .. import 'LrSystemInfo'.summaryString())

log:info('ZenphotoInit')
ZenPhoto_SelfUpdate.init(PluginName,"zenphotopublisher",ZenphotoInfo.version, "https://nodeload.github.com/philbertphotos/Zenphoto-Lightroom-Publisher/zip/4.5.0",'org.zenphoto.lightroom.publisher')