--[[----------------------------------------------------------------------------

ZenphotoDialogSections.lua
dialog customization for Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]
PluginVersion = '2.1'

	-- Lightroom SDK
local LrApplication     = import 'LrApplication'
local LrFunctionContext	= import 'LrFunctionContext'
local LrLogger          = import 'LrLogger'
local LrView 			= import "LrView"
local LrTasks			= import "LrTasks"
local prefs 			= import 'LrPrefs'.prefsForPlugin()
local bind 				= LrView.bind

    -- Logger
local myLogger = LrLogger( 'Zenphoto' )
myLogger:enable( "logfile" )
local debug, info, warn, err = myLogger:quick( 'debug', 'info', 'warn', 'err' )


--require 'DP_API'
require 'ZenphotoUser'

--============================================================================--

ZenphotoDialogSections = {}


function ZenphotoDialogSections.startDialog( propertyTable )
	info('ZenphotoDialogSections.startDialog')

	-- Make sure we're logged in.
	ZenphotoUser.initLogin( propertyTable )
end

function ZenphotoDialogSections.sectionsForTopOfDialog( f, propertyTable )

	local activeCatalog = LrApplication.activeCatalog()
    local info = require 'Info.lua'
    local versionString = '(' .. (info.VERSION.major or '0') .. '.' .. (info.VERSION.minor or '0')  .. '.' .. (info.VERSION.revision or '0') .. ')'
	return {

		{
			title = "ZenPhoto Publisher for Lightroom 3",
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
							LrHttp.openUrlInBrowser('http://code.google.com/p/zenphoto-publisher/') 
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
							LrHttp.openUrlInBrowser('http://code.google.com/p/zenphoto-publisher/issues/list') 
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
				title = 'Welcome to ZenPhoto Publisher for Lightroom 3 ' .. versionString,
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
					title = 'Loki (Nick Jacobsen) of Lokkju', 
					text_color = import 'LrColor'( 0, 0, 1 ),
					mouse_down = function(self) 
						local LrHttp = import 'LrHttp' 
						LrHttp.openUrlInBrowser('http://www.lokkju.com/') 
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
	}
end	


