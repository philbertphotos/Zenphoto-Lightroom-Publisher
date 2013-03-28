--[[----------------------------------------------------------------------------

ZenphotoDialogSections.lua
dialog customization for Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]
PluginVersion = '3.0.1'

	-- Lightroom SDK
local LrApplication     = import 'LrApplication'
local LrFunctionContext	= import 'LrFunctionContext'
local LrLogger          = import 'LrLogger'
local LrView 			= import "LrView"
local LrTasks			= import "LrTasks"
local prefs 			= import 'LrPrefs'.prefsForPlugin()
local bind 				= LrView.bind

    -- Logger
local log = LrLogger( 'ZenphotoLog' )

require 'ZenphotoUser'

--============================================================================--

ZenphotoDialogSections = {}

function updateLogLevelStatus( propertyTable )
	--log:trace ("Calling updateLogLevelStatus( propertyTable )")
	if propertyTable.logLevel == 'none' then
		log:disable( )
		propertyTable.logSynopsis = "No Log File"
	elseif propertyTable.logLevel == 'errors' then
		log:enable( { ['error'] = 'logfile' ; ['fatal'] = 'logfile'} )
		propertyTable.logSynopsis = "Log File - Errors Only"
	elseif propertyTable.logLevel == 'trace' then
		log:enable( { ['error'] = 'logfile' ; ['debug'] = 'logfile' ; ['fatal'] = 'logfile' ; ['warn'] = 'logfile' ; ['info'] = 'logfile' } )
		propertyTable.logSynopsis = "Log File - Trace"
		elseif propertyTable.logLevel == 'verbose' then
		log:enable( 'logfile' )
		propertyTable.logSynopsis = "Log File - Verbose"
	end
end


function ZenphotoDialogSections.startDialog( propertyTable )
log:info('-------------------------------------')
log:info('START LOG TIMESTAMP')
log:info('-------------------------------------')
	
if prefs.logLevel ~= not 'none' then
	log:info('ZenphotoDialogSections.startDialog')
	end
	-- initialize the log level
	if propertyTable.logLevel == nil then
		if prefs.logLevel ~= nil and prefs.logLevel ~= "" then
			propertyTable.logLevel = prefs.logLevel
		else
			propertyTable.logLevel = 'trace'
		end
	end
	
-- add observer
	propertyTable:addObserver( 'logLevel', updateLogLevelStatus )
	-- initialize dialog elements
	updateLogLevelStatus( propertyTable )
	-- Make sure we're logged in.
	ZenphotoUser.initLogin( propertyTable )
end

-------------------------------------------------------------------------------

function ZenphotoDialogSections.endDialog( propertyTable )
	if prefs.logLevel ~= not 'none' then
	log:trace("Calling ZenphotoDialogSections.endDialog")
	end
	-- save the log level into the preferences
	prefs.logLevel = propertyTable.logLevel

end

function ZenphotoDialogSections.sectionsForTopOfDialog( f, propertyTable )
	if prefs.logLevel ~= not 'none' then
	log:trace("Calling ZenphotoDialogSections.sectionsForTopOfDialog")
end
	-- Initializations

	if propertyTable.logLevel == nil then
		propertyTable.logLevel = 'trace'
	end
	if propertyTable.logSynopsis == nil then
		propertyTable.logSynopsis = ''
	end
	
	local activeCatalog = LrApplication.activeCatalog()
    local info = require 'Info.lua'
    local versionString = '(' .. (info.VERSION.major or '0') .. '.' .. (info.VERSION.minor or '0')  .. '.' .. (info.VERSION.revision or '0') .. ')'
	return {

		{
			title = "ZenPhoto Publisher for Lightroom 3 and 4",
			f:row {
				f:column {
					f:picture {
						fill_horizontal = 1,
						value = _PLUGIN:resourceId('zenphoto_logo.png'),
					},
				},
				f:spacer {},
				f:column {
					f:static_text { 
						alignment = 'right',
						fill_horizontal = 1,
						title = 'Plugin Home Page', 
						size = 'small',
						text_color = import 'LrColor'( 0, 0, 1 ),
						mouse_down = function(self) 
							local LrHttp = import 'LrHttp' 
							LrHttp.openUrlInBrowser('http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher/') 
						end,
						[ WIN_ENV and 'adjustCursor' or 'adjust_cursor' ] = function(self)
							self.text_color = import 'LrColor'( 1, 0, 0 )
							LrTasks.startAsyncTask( function()
								LrTasks.sleep(0.5)
								self.text_color = import 'LrColor'( 0, 0, 1 )
							end)
						end,
					},
					f:static_text { 
						alignment = 'right',
						fill_horizontal = 1,
						title = 'Issue Tracker', 
						size = 'small',
						text_color = import 'LrColor'( 0, 0, 1 ),
						mouse_down = function(self) 
							local LrHttp = import 'LrHttp' 
							LrHttp.openUrlInBrowser('https://github.com/philbertphotos/Zenphoto-Lightroom-Publisher/issues?state=open') 
						end,
						[ WIN_ENV and 'adjustCursor' or 'adjust_cursor' ] = function(self)
							self.text_color = import 'LrColor'( 1, 0, 0 )
							LrTasks.startAsyncTask( function()
								LrTasks.sleep(0.5)
								self.text_color = import 'LrColor'( 0, 0, 1 )
							end)
						end,
					},					
				},
			},
			f:static_text {
				fill_horizontal = 1,
				font = "<system/small/bold>",
				title = 'Welcome to ZenPhoto Publisher for Lightroom 3 and 4 ' .. versionString,
			},
			f:column {
			spacing = 0,
			f:row {
				margin_horizontal = 0,
				fill_horizontal = 1,
				f:static_text {
					width = 125,
					title = 'Currently Maintained By:'
				},
				f:static_text { 
					title = 'Joseph Philbert', 
					text_color = import 'LrColor'( 0, 0, 1 ),
					mouse_down = function(self) 
						local LrHttp = import 'LrHttp' 
						LrHttp.openUrlInBrowser('http://www.fb.com/philbertphotography') 
					end,
					[ WIN_ENV and 'adjustCursor' or 'adjust_cursor' ] = function(self)
						self.text_color = import 'LrColor'( 1, 0, 0 )
						LrTasks.startAsyncTask( function()
							LrTasks.sleep(0.5)
							self.text_color = import 'LrColor'( 0, 0, 1 )
						end)
					end,
				},									
			},
			f:row {
				margin_horizontal = 0,
				fill_horizontal = 1,
				f:static_text {
					width = 125,
					title = 'Originally Written By:'
				},
				f:static_text { 
					title = 'Lars Hagen of Elemental Shoots', 
					text_color = import 'LrColor'( 0, 0, 1 ),
					mouse_down = function(self) 
						local LrHttp = import 'LrHttp' 
						LrHttp.openUrlInBrowser('http://www.elementalshoots.com/blog/scripts/lightroom-2-zenphoto-publishing-service/') 
					end,
					[ WIN_ENV and 'adjustCursor' or 'adjust_cursor' ] = function(self)
						self.text_color = import 'LrColor'( 1, 0, 0 )
						LrTasks.startAsyncTask( function()
							LrTasks.sleep(0.5)
							self.text_color = import 'LrColor'( 0, 0, 1 )
						end)
					end,
				},									
			},
			},
				f:static_text {
					fill_horizontal = 1,
					height_in_lines = 2,
					width = 300,
					title = 'This publishing service allows you to sync your ZenPhoto gallery installed somewhere in the web with your Lightroom catalog. Please go to the publishing section, add this service and configure it as explained.',
				},
				f:static_text {
					fill_horizontal = 1,
					height_in_lines = 2,
					width = 300,
					title = 'Please use the Issue Tracker link above for any problems you run into.',
				},		
},
{
      title = "Debug Settings",
	  tooltip =  bind { key = 'logLevel', object = propertyTable },		  
f:group_box {
title = "Logging Level:", 
fill_horizontal = 0,
spacing = f:control_spacing(),
f:popup_menu {
					fill_horizontal = 1,
					width = 120,
					items = {
						{ title = "No Log File", value = 'none' },
						{ title = "Log File - Errors", value = 'errors' },
						{ title = "Log File - Tracing", value = 'trace' },
						{ title = "Log File - Debug", value = 'verbose' },
					},
					value = bind { key = 'logLevel', object = propertyTable }
				}		
			}	
      }
	
	}
end	