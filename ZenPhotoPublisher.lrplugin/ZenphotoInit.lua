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

--require("LRLib_SelfUpdate")
require("Info")
local logger = import 'LrLogger'
-- Define logger globally
log = logger( 'zenphotopublisher' ) -- the log file name.
log:enable( "logfile" )
log:info('ZenphotoInit')
--LRLib_SelfUpdate.init(pluginName,"zenphotopublisher",ZenphotoInfo.version, ZenphotoInfo.location , "org.zenphoto.lightroom.publisher")
