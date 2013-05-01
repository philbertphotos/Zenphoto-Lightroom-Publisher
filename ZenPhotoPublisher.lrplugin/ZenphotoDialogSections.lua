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

require 'ZenphotoUser'

--============================================================================--

ZenphotoDialogSections = {}

function updateLogLevelStatus( propertyTable )
	--log:trace ("Calling updateLogLevelStatus( propertyTable )")
	if propertyTable.logLevel == 'none' then
		log:disable( )
		propertyTable.logSynopsis = "Log File - none"
	elseif propertyTable.logLevel == 'errors' then
	
		log:enable( { ['error'] = 'logfile' ; ['warn'] = 'logfile' ;['fatal'] = 'logfile'} )
		propertyTable.logSynopsis = "Log File - Errors Only"
		
	elseif propertyTable.logLevel == 'trace' then
		log:enable( { ['error'] = 'logfile' ; ['trace'] = 'logfile' ; ['info'] = 'logfile' } )
		propertyTable.logSynopsis = "Log File - Trace"
		
		elseif propertyTable.logLevel == 'debug' then
		log:enable( {['trace'] = 'logfile' ; ['debug'] = 'logfile' ; ['fatal'] = 'logfile' ; ['warn'] = 'logfile' ; ['info'] = 'logfile' } )
		propertyTable.logSynopsis = "Log File - Debug"
	end
end


function ZenphotoDialogSections.startDialog( propertyTable )
	log:info('ZenphotoDialogSections.startDialog')
	-- initialize the log level
	if propertyTable.logLevel == nil then
		if prefs.logLevel ~= nil and prefs.logLevel ~= "" then
			propertyTable.logLevel = prefs.logLevel
		else
			propertyTable.logLevel = 'none'
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
	prefs.logLevel = propertyTable.logLevel
	log:trace("Calling ZenphotoDialogSections.endDialog")
	-- save the log level into the preferences
end

function ZenphotoDialogSections.sectionsForTopOfDialog( f, propertyTable )
	log:trace("Calling ZenphotoDialogSections.sectionsForTopOfDialog")
	-- Initializations

	if propertyTable.logLevel == nil then
		propertyTable.logLevel = 'none'
	end
	if propertyTable.logSynopsis == nil then
		propertyTable.logSynopsis = ''
	end
	
	local activeCatalog = LrApplication.activeCatalog()
    local info = require 'Info.lua'
    local versionString = '(' .. (info.VERSION.major or '0') .. '.' .. (info.VERSION.minor or '0')  .. '.' .. (info.VERSION.revision or '0') .. '.' .. (info.VERSION.build or '0') .. ')'
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
				title = 'Welcome to ZenPhoto Publisher for Lightroom 3 and 4 \n' .."Version: ".. versionString,
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
					height_in_lines = 1,
					width = 300,
					title = 'Gives you the ablity to sync your ZenPhoto gallery with lightroom \n Please use the Issue Tracker link below for any problems you run into.',
				},
					f:static_text { 
					title = 'Issue Tracker', 
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
{
      title = "Helper Tools",
	  tooltip =  bind { key = 'logLevel', object = propertyTable },		  
f:group_box {
title = "Logging Level:", 
fill_horizontal = 0,
spacing = f:control_spacing(),
						f:row {
						fill_horizontal = 0,
								f:popup_menu {
					fill_horizontal = 1,
					--width = 120,
					items = {
						{ title = "Log File - None", value = 'none' },
						{ title = "Log File - Errors", value = 'errors' },
						{ title = "Log File - Tracing", value = 'trace' },
						{ title = "Log File - Debug", value = 'debug' },
					},
					value = bind { key = 'logLevel', object = propertyTable }
				},

				f:push_button {
						fill_horizontal = 1,
						title = 'Clear Log',
						action = function()
logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "zenphotopublisher.log")
if LrFileUtils.exists( logPath ) then
local success, reason = LrFileUtils.delete( logPath )
if not success then
log:error("Error deleting existing logfile!" .. reason)
end
log:trace("Log cleared by user")
end
						end,
					},				
--[[					f:push_button {
						fill_horizontal = 1,
						title = 'Submit log',
						action = function()
						log:info("Send Log")
   local success, body, headers = LrFunctionContext.pcallWithContext("Send Log",
    function()
     return LrHttp.post("http://www.glamworkshops.com/misc/process.php",
"name=joe&email=bb@bb.com&comments=hey man look me here&spam=4&submit=send")
    end
   )
   if not success then
   log:error("Send Log: ", headers.error)

   end
   assert(body, "no body returned")
   assert(headers, "no headers returned")
log:info("Send Log: ", table_show(headers))
log:info("Send Log body: ", table_show(body))
  end,
					},--]]
				},

						f:static_text {
					title = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "zenphotopublisher.log"), 
				},	
			},

      },
	
	}
end	

