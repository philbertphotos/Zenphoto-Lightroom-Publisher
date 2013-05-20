--[[----------------------------------------------------------------------------

ZenphotoDialogSections.lua
dialog customization for Lightroom Zenphoto uploader

------------------------------------------------------------------------------]]
local LrApplication     = import 'LrApplication'
local LrFunctionContext	= import 'LrFunctionContext'
local LrLogger          = import 'LrLogger'
local LrView 			= import "LrView"
local LrTasks			= import "LrTasks"
local LrPathUtils		= import 'LrPathUtils'
local LrStringUtils		= import 'LrStringUtils'
local prefs 			= import 'LrPrefs'.prefsForPlugin()
local LrFileUtils       = import 'LrFileUtils'
local LrBinding         = import 'LrBinding'
local LrDialogs         = import 'LrDialogs'
local LrErrors          = import 'LrErrors'
local LrShell           = import 'LrShell'
local LrDate            = import 'LrDate'
local LrHttp            = import 'LrHttp'
local LrMD5             = import 'LrMD5'
local LrColor           = import 'LrColor'

local PROP
 
local pluginName = nil
local pluginURLTag = nil
local pluginVersion = nil
local pluginLocation = nil

-- The namespace


require 'ZenphotoUser'
--============================================================================--

ZenphotoDialogSections = {}
ZenPhoto_SelfUpdate = {}

function updateLogLevelStatus( propertyTable )
	log:trace ("updateLogLevelStatus( propertyTable )")
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
	
	log:trace("SelfUpdate.startDialog")
   --if not  prefs then  prefs = prefs end
   if not pluginName then pluginName = name end

   propertyTable.lib_selfupdate_pluginName = pluginName
   	propertyTable.lib_selfupdate_autocheck = prefs.lib_selfupdate_autocheck

-- add observer
	propertyTable:addObserver( 'logLevel', updateLogLevelStatus )
	-- initialize dialog elements
	updateLogLevelStatus( propertyTable )
	-- Make sure we're logged in.
	ZenphotoUser.initLogin( propertyTable )
end
-------------------------------------------------------------------------------

-- Self Update

-----
----- VERSION CHECKING
-----

local function VersionIsNewerThan(old, new)

   local old_date, old_num = tostring(old):match('^(%d+)%.(%d+)$')
   local new_date, new_num = tostring(new):match('^(%d+)%.(%d+)$')

--   if not old_num or not new_num then
--   LrDialogs.message("first false")
--      return false
--  end

   if tonumber(new) > tonumber(old) then
--LrDialogs.message("greater than")
   return true
else
return false
   end

   if (tonumber(new_date) == tonumber(old_date)) and (tonumber(new_num) > tonumber(old_num)) then
   LrDialogs.message("last true")
      return true
   end
--   return false

end

local function quote(s)

   return '"' .. s .. '"'

end

-- Does a raw version check (that is, in the current task) and updates the
-- state appropriately. If 'force' is true, the check is in response to a
-- user having pressed a [Check Now] button. Otherwise, it's an auto-check
-- that we want to be light weight.

local function do_raw_check(args)
log:info("do_raw_check")
   local PROP, force = unpack(args)

   local LrVersion = LrApplication.versionString():gsub('%s+', '+')
   local LrBuild   = LrApplication.versionTable().build
   local OS = WIN_ENV and 'W' or 'M'

   local function update(key, val)
      PROP[key] = val
       prefs[key] = val
   end

   -- Contact server to find out the latest version number. The user's
   -- current version and a "random unique identifier" (created by
   -- math.random) so that I can count, out of curiosity, how many
   -- individual users are using each plugin. The "random unique identifier"
   -- is used instead of an IP address because it's both more and less constant
   -- (more, because it doesn't change as a user's dynamic IP changes, and
   -- less because it differs among different users behind the same proxy).
   
   --get Master Branch
local getgit = LrHttp.get('https://api.github.com/repos/philbertphotos/Zenphoto-Lightroom-Publisher', nil, 3)
	local getgitreply = (JSON:decode( getgit ))
	--log:info('Get Master Branch' ,table_show(getgitreply)) --only needed to see table
	
   local urlToCheck = 'https://raw.github.com/philbertphotos/Zenphoto-Lightroom-Publisher/'..getgitreply.default_branch..'/VERSION'
   log:info("url: " .. urlToCheck)

   local reply = LrHttp.get(urlToCheck, nil, 3)
log:info("urlToCheck Reply", table_show(reply))
   -- Regardless of the reply, if this is an auto-check (as opposed to a
   -- user-initiated check), we want to mark that we did a check. This
   -- stops the thing from auto-checking over and over in the face of
   -- downed connectivity or a problem with the version server.
   --log:info("server reply: " .. reply)

   if not force then
       prefs.VERSION_CHECK_TIME = LrDate.currentTime()
   end

   if not reply or reply == '' then 
      -- Something went wrong. If this was a user-initiated check, let them known
      if force then
         LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/InternalError=Internal Plugin Error"),
                           LOC("$$$/LRLib/SelfUpdate/VersionServer/NoContact=Could not contact the version-check server"),
                           "warning")
      end
      return
   end

   -- got a reply... what kind?
   local LatestVersion = reply:match('^(%d+\.%d+)%s*$')

   if not LatestVersion then

      -- We got no reply, so just leave things be unless its a forced
      -- check, in which case we report the problem

      if force then
         LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/InternalError=Internal Plugin Error"),
                           LOC("$$$/LRLib/SelfUpdate/VersionServer/BadReply=Reply from the version server not understood:") .. "\n" .. tostring(reply),
                           "warning")
      end

      return
   end

   -- We have a proper reply. We updated the check time earlier if it wasn't a forced check,
   -- but now we'll do so regardless.

   prefs.VERSION_CHECK_TIME = LrDate.currentTime()

log:info('LatestVersion: '..LatestVersion ,'PluginVersion: '..pluginVersion)
   -- We now actually check to see whether ours is old
   if VersionIsNewerThan(pluginVersion, LatestVersion) then

      -- Ours is old
	  log:info("Found a newer version on the server.")
      update('NEW_VERSION_NUMBER', LatestVersion)
      ShowUpgradeDialog(PROP)
   else
      -- Ours is not old
	  log:onfo('You have the latest version ')
      update('NEW_VERSION_NUMBER', nil)

      if force then
         LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/Version/Latest=You have the latest version "..pluginVersion), nil, "info")
      end

   end
end

-- Called to asynchronously check the version server

function async_version_check(PROP, force)
 log:info("async_version_check")

   if not PROP.doing_version_check
  --    and
  --      (force or LrDate.currentTime() - prefs().VERSION_CHECK_TIME > check_delta)
   then
      PROP.doing_version_check = true
      local old = PROP.version_checknow_title
      PROP.version_checknow_title = LOC("$$$/107=checking^.")
	  log:info("checking")
 
      LrTasks.startAsyncTask( function()
         do_raw_check( { PROP, force } )
         PROP.version_checknow_title = old
         PROP.doing_version_check = nil
      
      end)
   end
end

-----
----- SELF UPDATE
-----

-- Locate the unzip application (under LR 2.0 and above)

local raw_unzip
if LrApplication.versionString then

   if WIN_ENV then
      raw_unzip = LrPathUtils.child(LrPathUtils.child(_PLUGIN.path, "Win"), "unzip.exe")
 --log:info("raw_zip" .. raw_unzip ..".\n")
   else
      local to_try = { "/usr/bin/unzip",
                       "/sw/bin/unzip" }
      for _, path in ipairs(to_try) do
         if LrFileUtils.exists(path) then
            raw_unzip = path
            break
         end
      end
   end
end

-- Make another copy of the unzip application so that we can overwrite the original during update

local my_zip_copy
local function unzip_cmd()

   if not WIN_ENV then
      return raw_unzip
   end

   if not my_zip_copy then
   tmpzip = LrPathUtils.child(_PLUGIN.path, "unzip.exe")
      local tmp = LrPathUtils.child(_PLUGIN.path, "unzip.exe")
      LrFileUtils.delete(tmp)
      if not LrFileUtils.copy(raw_unzip, tmp) then
         LrErrors.throwUserError(LOC("$$$/LRLib/SelfUpdate/Copy=Could not LrFileUtils.copy(^1, ^2)", raw_unzip, tmp))
      end
      my_zip_copy = quote(tmp)           

         log:debug("zipCopy" .. my_zip_copy ..".\n")

   end
   return my_zip_copy
end

local function abort(PROP, message)

   PROP.status = LOC("$$$/LRLib/SelfUpdate/Aborted=Upgrade aborted.")
   PROP.okay = LOC("$$$/LRLib/SelfUpdate/Button/Dismiss=Dismiss")
   PROP.status_color = LrColor(1,0,0)

   if message then
      LrErrors.throwUserError(message)
   end
   
   return nil
   
end

-- Given a url and a simple filename, download the cotents of the url to that named file
-- in a temporary folder.
--
-- Returns the full path to the downloaded file

local function download_file(context, PROP, url, leafName)
log:info('download_file: ', leafName)
       
   local fullpath = LrPathUtils.child(LrPathUtils.getStandardFilePath('temp'), leafName)
        log:info("fullpath is [" .. fullpath .. "]\n")
   -- just in case it's already there, get rid of it
   LrFileUtils.delete(fullpath)
   
   -- Since we're doing it by chunks, we can show a progress dialog...
   
   local PS = LrDialogs.showModalProgressDialog {
      functionContext = context,
      title = LOC("$$$/LRLib/SelfUpdate/Downloading=Downloading new plugin from server^."),
   }
   -- we'll write it file from the HTTP stream
   local fd, error = io.open(fullpath, "wb")
   if not fd then
      return abort(PROP, LOC("$$$/LRLib/SelfUpdate/CannotOpenTemp=Can't create temporary file ^[^1^] for download: ^2", fullpath, error))
   end
   
 PS:setCaption(LOC("$$$/LRLib/SelfUpdate/ProgressCaption/Starting=Starting download^."))
 
       if PS:isCanceled() then
         return abort(PROP)
      end
	  
      local part_data, reply_headers = LrHttp.get("https://nodeload.github.com/philbertphotos/Zenphoto-Lightroom-Publisher/zip/4.5.0") 
 	  log:info("headers [" .. table_show(reply_headers) .. "]\n") --turn of for debuging 
 	  --log:info("part_data [" .. table_show(part_data) .. "]\n") --turn of for debuging 
 log:info("fullpath [" .. fullpath .. "]\n") --turn of for debuging

if type(reply_headers) ~= "table" then
         --Dump(reply_headers, LOC("$$$/LRLib/SelfUpdate/UnexpectedReply=Unexpected reply while attempting to download the new version"))
         return abort(PROP, LOC("$$$/LRLib/SelfUpdate/Aborting=Aborting upgrade attempt"))
      end
if reply_headers.status == 404 then
                 return abort(PROP, LOC("$$$/LRLib/SelfUpdate/Unavailable=The new version's zip file doesn't seem to be available. Aborting the upgrade attempt."))
      end	
	  
	  if reply_headers.error then
                 return abort(PROP, LOC("$$$/LRLib/SelfUpdate/Unavailable="..reply_headers.error.name.."... Aborting the upgrade attempt."))
      end	  
           -- Dump out the bytes we just got to the file
		   for _, t in ipairs(reply_headers) do
         if t.field == "Content-Length" then
length = t.value
         end
 if t.field == "Content-Disposition" then
aattach = (string.gsub(t.value,'attachment; filename=',''))
--log:info('Attachment', PROP.attach)
         end
      end
--[[PS:setPortionComplete('0', length)
      PS:setCaption(LOC("$$$/LRLib/SelfUpdate/ProgressCaption=Downloading: ^1% (^2 of ^3)",
                        string.format("%.0f", 0 * 100 / length)))

      if '0' >= length then
         done = true
      end--]]
	  
	  PROP.can_invoke = false
	  PROP.attach = attach
      PROP.status = LOC("$$$/LRLib/SelfUpdate/ProgressCaption=Downloading: ^1% (^2 of ^3)",length)
	  log:info("Downloading: ^1% (^2 of ^3)",length)
      fd:write(part_data)
   fd:close()
   PS:done()
log:info("Save File")   
   return fullpath
end

local function show_upgrade_dialog(PROP, PluginDialogPROP)
log:trace('show_upgrade_dialog')

   function download_and_install()
log:trace('download_and_install')
         log:debug("Start of automatic download-and-install....\n")

      PROP.can_invoke = false
      PROP.status = LOC("$$$/LRLib/SelfUpdate/Status/Downloading=Downloading new version now^.")
      PROP.okay = LOC("$$$/LRLib/SelfUpdate/Button/Abort=Abort")
		 log:info(pluginLocation)
		 log:info('attach prop',PROP.attach)
--get plugin filename
 --= pluginLocation .. "\\Zenphoto-Lightroom-Publisher" .. reply .. ".zip"
 --local urlversion = LrHttp.get("http://www.philbertphotos.com/versioncheck.php", nil, 3)
 --get repo branch TODO
local urlversion = 'temp.zip' -- PROP.attach
      if prefs.logLevel == 'debug' then
      log:info("Fetching [" .. pluginLocation .. ' File: ',table_show(PROP)  .. "]\n")
      end
      local pluginFilename = LrPathUtils.leafName(pluginLocation .. "/" .. urlversion )
                        log:info("plugin-Filename [" .. pluginFilename .. "]\n")
				  
      local zipfile, downloaded_length = LrFunctionContext.callWithContext("File Download",download_file, PROP, pluginLocation.. "\\" .. urlversion .. ".zip", pluginFilename)
                  log:info("Zip-Filename [" .. pluginLocation.. "\\" .. urlversion .. ".zip" .. "]\n")
				  
      if not zipfile then
         PROP.aborted = true
         return
      end

      if PROP.abort then
         PROP.aborted = true
         LrFileUtils.delete(zipfile)
         return
      end

         log:debug("Zipfile is [" .. tostring(zipfile) .. "]\n")
      if not LrFileUtils.exists(zipfile) then
         LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/InternalError=Internal Plugin Error"),
                           LOC("$$$/LRLib/SelfUpdate/NoFile=The downloaded file ^[^1^] seems to have disappeared", zipfile),
                           "critical")
         return abort(PROP)
      end

      if not LrFileUtils.isReadable(zipfile) then
         LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/InternalError=Internal Plugin Error"),
                           LOC("$$$/LRLib/SelfUpdate/NotReadable=The downloaded file ^[^1^] is not readable", zipfile),
                           "critical")
         return abort(PROP)
      end

      -- if DEBUG then
      --    DumpLog(LrFileUtils.fileAttributes(zipfile), "zip attributes")
      -- end

      PROP.status = LOC("$$$/LRLib/SelfUpdate/Installing=Installing new version^.")

      local plugin_base_dir = LrPathUtils.parent(_PLUGIN.path)..'\\ZenPhotoPublisher.lrplugin'
      local zip_base_dir = plugin_base_dir..'\\win'
      local tmplog = LrPathUtils.child(LrPathUtils.getStandardFilePath('temp'), "lr-plugin-unzip-log.txt") 
      --LrFileUtils.delete(tmplog)

         log:debug("Base dir [" .. tostring(plugin_base_dir) .. "]\n")
         log:debug("tmplog is [" .. tmplog .. "]\n")

local args = {
		 'j',-- eXtract files
		 'o ', -- assume Yes on all queries/overwrite exsiting' 
      }

      local cmd = unzip_cmd() .. ' -' .. table.concat(args, '') .. ' ' .. quote(zipfile) .. ' *.lua *.png *.exe -d ' .. quote(plugin_base_dir)
	  cmd = cmd .. " > " .. quote(tmplog)
  
   if WIN_ENV then
         cmd = quote(cmd)
      end
      -- One final check before unzipping...

      if PROP.abort then
         PROP.aborted = true
         LrFileUtils.delete(zipfile)
         return
      end

         log:debug("Command: " .. cmd .. "\n")
	local status = LrTasks.execute(cmd)
	if LrFileUtils.exists( plugin_base_dir..'\\unzip.exe' ) then
	LrFileUtils.delete( zip_base_dir..'\\unzip.exe' )
		 LrFileUtils.createDirectory(zip_base_dir)
		 LrTasks.sleep(1) --dramatic pause.
		 local response = LrFileUtils.move( plugin_base_dir..'\\unzip.exe', zip_base_dir..'\\unzip.exe' )
		 log:debug("move-unzip is [" .. tostring(response) .. "]\n")
							
		 local params = pluginName..':'..pluginVersion..':'..prefs.NEW_VERSION_NUMBER..':'..os.date('%d_%m_%y %H_%M')
	 local response = LrHttp.post("http://www.glamworkshops.com/misc/selfupdate.php",params, nil)
  log:info('selfupdate', table_show(response))
	end
	
	  if prefs.logLevel == 'debug' then
         log:debug(string.format("exit status is %d (0x%08x)\n", status, status))
		 
         local log = ""
         for line in io.lines(tmplog) do
            log = log .. line .. "\n"
         end

         if #log == 0 then
            log = LOC("$$$/LRLib/SelfUpdate/NoLog=(no log file available)")
         else
            log = LOC("$$$/LRLib/SelfUpdate/Log=Unzip log:^n" .. log)
         end

         --log:info(log)
      end

      PROP.okay = LOC("$$$/LRLib/SelfUpdate/Status/Done=Done")

      -- We're done with the zip
      LrFileUtils.delete(zipfile)
	  LrFileUtils.delete(tmpzip)

      -- Windows seems to give an exit value of 50 ("disk full") even when
      -- there's plenty of space, so until I can figure it out more, I'll just
      -- ignore this error.

      if status ~= 0 and status ~= 50 then

         PROP.status = LOC("$$$/LRLib/SelfUpdate/Status/Error=Error installing new version.")
         PROP.status_color = LrColor(1,0,0)
         PROP.okay = LOC("$$$/LRLib/SelfUpdate/Botton/Dismiss=Dismiss")

         if not prefs.loglevel == debug then
            LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/Error=Error installing new version."), nil, "critical")
         else
            LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/Error=Error installing new version."),
							  LOC("$$$/LRLib/SelfUpdate/Error/Log=The upgrade log, ^[^1^], will be shown."),
                              "critical")
         end

      else

         local note = LOC("$$$/LRLib/SelfUpdate/InstalledVersion=Plugin has been installed.")
         if PluginDialogPROP then
            PluginDialogPROP.newly_installed_note = note
         end
         PROP.status                           = note .. " " .. LOC("$$$/LRLib/SelfUpdate/Status/Reload=Please restart Lightroom.")
         PROP.status_color                     = LrColor(0.5,0,0)

         -- Reset things for when the plugin is reloaded

         prefs.NEW_VERSION_NUMBER = nil
         prefs.VERSION_CHECK_TIME = 0
      end

      -- Done with the log
      LrFileUtils.delete(tmplog)
   end

   local v = LrView.osFactory()
   local do_it_now_label = LOC("$$$/LRLib/SelfUpdate/Button/Download=Download and Install")
--log:debug('Check PROP', table_show(PROP))
   PROP.okay = LOC("$$$/LRLib/SelfUpdate/Button/Cancel=Cancel")
   PROP.can_invoke = true
   PROP.abort = false
   PROP.status = ''
   PROP.completed = false

LrDialogs.presentModalDialog {
      title = LrView.bind {
           bind_to_object = PluginDialogPROP,
           key = 'lib_selfupdate_pluginName',
      },

      cancelVerb = "< exclude >", -- this magic, unpublished setting removes the cancel button, and may not work in the future
      actionVerb = LrView.bind { bind_to_object = PROP, key = 'okay' },
      accessoryView = v:static_text {
         fill_horizontal = 1,
         text_color = LrView.bind { bind_to_object = PROP, key = 'status_color' },
         title = LrView.bind { bind_to_object = PROP, key = 'status' }
      },
      contents = v:view {
         margin_bottom = 3,        
         v:static_text {
            width = 550,
            height_in_lines = -1,
            title = LrView.bind {
                 bind_to_object = PluginDialogPROP,
                 key = 'lib_selfupdate_pluginName',
                 transform = function (value, fromTable)
                    return LOC("$$$/LRLib/SelfUpdate/Instructions/1=There is a new version of ^1 available.^nClick ^[^2^] to update this plugin to the latest version.", value, do_it_now_label)
               end
            }
         },

         v:spacer { height = 15 },

         v:static_text {
            width = 550,
            height_in_lines = -1,
            title = LOC("$$$/x46=In order for the new version to take effect, you must reload the the plugin or Lightroom.")
         },

         v:spacer { height = 15 },

         v:static_text {
            width = 550,
            text_color = LrColor(.4),
            height_in_lines = -1,
            title = LOC("$$$/x1499=Note: if the automatic upgrade fails for any reason, please perform the upgrade manually, downloading the latest version from http://www.philbertphotos.com and unzipping it in place of the current plugin.")
         },

         v:spacer { height = 15 },

         v:push_button  {
            title = do_it_now_label,
            place_horizontal = 0.5,
            enabled = LrView.bind { object = PROP, key = 'can_invoke' },
            action = function()
                        LrTasks.startAsyncTask(download_and_install, LOC("$$$/LRLib/SelfUpdate/Installing=Downloading and installing new version"))
                     end
         }
      }
   }

   PROP.abort = true -- just in case a download was running
end

function ShowUpgradeDialog(PluginDialogPROP)
log:trace('ShowUpgradeDialog')
   if not unzip_cmd() then
   log:info('Unable to locate system ^[unzip^] command')
      LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/NoUnzip=Unable to locate system ^[unzip^] command"),
                        LOC("$$$/LRLib/SelfUpdate/NoUnzip/Detail=Please type ^[which unzip^] into a Terminal window and contact the author with the result"), "critical")
   else
LrTasks.startAsyncTask( function()
show_upgrade_dialog(PROP, PluginDialogPROP)
		end)
   end
end


-----
----- INITIALISATION
-----

local check_delta = 3600  -- how often to auto-check, in seconds

-- Generate a unique ID to track unique installation counts

local function default_ruid()
   local OS = WIN_ENV and 'W' or 'M'

   math.randomseed(os.time())
   return OS .. LrMD5.digest(tostring(os.clock()) .. tostring(math.random()))
end

function ZenPhoto_SelfUpdate.init(name, URLTag, version, location)
   log:trace('ZenPhoto_SelfUpdate.init')
   pluginName = name
   pluginURLTag = URLTag
   pluginVersion = version
   pluginLocation = location

   if not  prefs.RUID then
       prefs.RUID = default_ruid()
   end

   if not  prefs.VERSION_CHECK_TIME then
       prefs.VERSION_CHECK_TIME = 0
   end

   -- Check for updates
   
   if  prefs.lib_selfupdate_autocheck then 
   log:trace('If autocheck true then...')
        LrFunctionContext.postAsyncTaskWithContext("Self update", function(context)
                                                    PROP = LrBinding.makePropertyTable(context)
                                                    PROP.lib_selfupdate_pluginName = name
                                                    do_raw_check( { PROP, false } )
                                                 end)
		else
		        LrFunctionContext.postAsyncTaskWithContext("Self update", function(context)
                                                    PROP = LrBinding.makePropertyTable(context)
                                                    PROP.lib_selfupdate_pluginName = name
                                                 end)

   end
      
end
-------------------------------------------------------------------------------

function ZenphotoDialogSections.endDialog( propertyTable )
	log:trace("ZenphotoDialogSections.endDialog")
	-- save the log level into the preferences
	prefs.logLevel = propertyTable.logLevel

	log:trace("SelfUpdate.endDialog")
     --prefs.lib_selfupdate_autocheck = propertyTable.lib_selfupdate_autocheck
	prefs.lib_selfupdate_autocheck = propertyTable.lib_selfupdate_autocheck 
end

function ZenphotoDialogSections.sectionsForTopOfDialog( f, propertyTable )
	log:trace("ZenphotoDialogSections.sectionsForTopOfDialog")
	-- Initializations

	if propertyTable.logLevel == nil then
		propertyTable.logLevel = 'none'
	end	
	
	if propertyTable.lib_selfupdate_autocheck == nil then
		propertyTable.lib_selfupdate_autocheck = true
	end
	
	if propertyTable.logSynopsis == nil then
		propertyTable.logSynopsis = ''
	end
	local bind 	= LrView.bind
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
							LrTasks.startAsyncTaskstartAsyncTask( function()
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
					

         f:checkbox {
            title = LOC "$$$/LRLib/SelfUpdate/AutoCheck=Check for updates to this plugin when Lightroom starts",
			value = bind { key = 'lib_selfupdate_autocheck', object = propertyTable }
         },
         f:row {
            fill_horizontal = 1,
            f:push_button  {
               title =  LOC "$$$/LRLib/SelfUpdate/PluginInfo/CheckNow=Check for updates now",
               place_horizontal = 0.5,
               action = function()
                           async_version_check( f, true )
                        end
            },
         },
      				--[[f:static_text { 
					title = LOC "$$$/LRLib/SelfUpdate/PluginInfo/autochk=Checking...", 
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
				},--]]
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
						log:trace("Cleared Log")
local logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "zenphotopublisher.log")
if LrFileUtils.exists( logPath ) then
local success, reason = LrFileUtils.delete( logPath )
if not success then
log:error("Error deleting existing logfile!" .. reason)
end
log:trace("Log cleared by user")
end
						end,
					},				
				f:push_button {
						fill_horizontal = 1,
						title = 'Open Log',
						action = function()
					LrTasks.startAsyncTask( function()
						log:trace("Open Log")
local logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "zenphotopublisher.log")
if LrFileUtils.exists( logPath ) then
--LrShell.revealInShell(logPath)
log:trace("Log opened by user")
   if WIN_ENV then
 LrShell.openFilesInApp( { logPath }, 'notepad.exe' ) 
else
  LrShell.openFilesInApp( { logPath }, "/Applications/TextEdit.app" ) 
end
end
end)
						end,
					},				
					f:push_button {
						fill_horizontal = 1,
						title = 'Submit log',
						action = function()
				LrTasks.startAsyncTask( function()
										log:info("Send Log")
		local logPath = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "zenphotopublisher.log")
		contents = get_file_contents(logPath)

mailsend = Utils.sendlog()
contents = get_file_contents(logPath)
s=contents:gsub("(%[\"password\"%]%s*=%s*)%b\"\"", "%1\"********\"")
m=s:gsub("(%[\"loginPassword\"%]%s*=%s*)%b\"\"", "%1\"********\"")
				 log:info("Sanitizing log")	
msg = LrStringUtils.encodeBase64(m)
					
if not mailsend == false then
  local response, body, headers = LrHttp.post("http://www.glamworkshops.com/misc/sendlog.php",mailsend..msg)
  log:info("Mail response", response)
  LrDialogs.message('Zenphoto-Publisher LOG has been sent to the developer.')  

 else 
  log:info("User Canceled")
  end 
     end)


   if not response then
   log:error("Send Log: ", headers.error)
   end
   assert(body, "no body returned")
   assert(headers, "no headers returned")
log:info("Send Log: ", table_show(headers))
log:info("Send Log body: ", table_show(body))
  end,
					},
				},

						f:static_text {
					title = LrPathUtils.child(LrPathUtils.getStandardFilePath('documents'), "zenphotopublisher.log"), 
				},	
			},

      },
	
	}
end	
