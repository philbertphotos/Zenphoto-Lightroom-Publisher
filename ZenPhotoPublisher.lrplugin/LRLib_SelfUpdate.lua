--[[----------------------------------------------------------------------------

Copyright (c) 2009, Joseph Philbert (http://www.philbertphotos.com)

All rights reserved.

See included file LICENSE.txt for details.

Special Thanks goes to Tim Armes and Jeffrey Friedl
------------------------------------------------------------------------------]]

--
-- Self updating 
--

LrFunctionContext = import 'LrFunctionContext'
LrApplication     = import 'LrApplication'
LrPathUtils       = import 'LrPathUtils'
LrFileUtils       = import 'LrFileUtils'
LrBinding         = import 'LrBinding'
LrDialogs         = import 'LrDialogs'
LrErrors          = import 'LrErrors'
LrLogger          = import 'LrLogger'
LrColor           = import 'LrColor'
LrPrefs           = import 'LrPrefs'
LrShell           = import 'LrShell'
LrTasks           = import 'LrTasks'
LrDate            = import 'LrDate'
LrHttp            = import 'LrHttp'
LrView            = import 'LrView'
LrFtp             = import 'LrFtp'
LrMD5             = import 'LrMD5'

local PROP
local PREFS
 
local pluginName = nil
local pluginURLTag = nil
local pluginVersion = nil
local pluginLocation = nil

-- The namespace

LRLib_SelfUpdate = {}

-- For debug

local LrLogger = import 'LrLogger'
local log = LrLogger( 'ExportToEmailLog' )

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
   local PROP, force = unpack(args)

   local LrVersion = LrApplication.versionString():gsub('%s+', '+')
   local LrBuild   = LrApplication.versionTable().build
   local OS = WIN_ENV and 'W' or 'M'

   local function update(key, val)
      PROP[key] = val
      PREFS[key] = val
   end

   -- Contact server to find out the latest version number. The user's
   -- current version and a "random unique identifier" (created by
   -- math.random) so that I can count, out of curiosity, how many
   -- individual users are using each plugin. The "random unique identifier"
   -- is used instead of an IP address because it's both more and less constant
   -- (more, because it doesn't change as a user's dynamic IP changes, and
   -- less because it differs among different users behind the same proxy).

   local urlToCheck = "http://www.philbertphotos.com/versioncheck.php".. "?plugin=" .. pluginURLTag .. "-" .."&current=" ..pluginVersion .."&ruid="..PREFS.RUID.. "&LR=".."&build="
   log:info("url: " .. urlToCheck)

   local reply = LrHttp.get(urlToCheck, nil, 3)

   -- Regardless of the reply, if this is an auto-check (as opposed to a
   -- user-initiated check), we want to mark that we did a check. This
   -- stops the thing from auto-checking over and over in the face of
   -- downed connectivity or a problem with the version server.
   log:info("server reply: " .. reply)

--LrDialogs.message(reply)
--LrDialogs.message(urlToCheck)
   if not force then
      PREFS.VERSION_CHECK_TIME = LrDate.currentTime()
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

   PREFS.VERSION_CHECK_TIME = LrDate.currentTime()

--LrDialogs.message(LatestVersion .. ' and ' ..pluginVersion)
   -- We now actually check to see whether ours is old
   if VersionIsNewerThan(pluginVersion, LatestVersion) then

      -- Ours is old
      update('NEW_VERSION_NUMBER', LatestVersion)
      ShowUpgradeDialog(PROP)

   else

      -- Ours is not old
      update('NEW_VERSION_NUMBER', nil)

      if force then
         LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/Version/Latest=You have the latest version"), nil, "info")
      end

   end
end

-- Called to asynchronously check the version server

function async_version_check(PROP, force)

   if not PROP.doing_version_check
  --    and
  --      (force or LrDate.currentTime() - PREFS().VERSION_CHECK_TIME > check_delta)
   then
      PROP.doing_version_check = true
      local old = PROP.version_checknow_title
      PROP.version_checknow_title = LOC("$$$/107=checking^.")

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
      raw_unzip = LrPathUtils.child(LrPathUtils.child(_PLUGIN.path, "Win"), "7z.exe")
	        if DEBUG then
         log:info("raw_zip" .. raw_unzip ..".\n")
      end
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
   tmpzip = LrPathUtils.child(_PLUGIN.path, "7z.exe")
      local tmp = LrPathUtils.child(_PLUGIN.path, "7z.exe")
      LrFileUtils.delete(tmp)
      if not LrFileUtils.copy(raw_unzip, tmp) then
         LrErrors.throwUserError(LOC("$$$/LRLib/SelfUpdate/Copy=Could not LrFileUtils.copy(^1, ^2)", raw_unzip, tmp))
      end
      my_zip_copy = quote(tmp)           
	  if DEBUG then
         log:info("zipCopy" .. my_zip_copy ..".\n")
      end
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

   local function grok_range(replyheaders)
   
      for _, t in ipairs(replyheaders) do
         --
         -- Looking for something like:
         --   field = "Content-Range"
         --   value = "bytes 500-999/3570800"
         --
         if t.field == "Content-Range" then
            local A, B, C = t.value:match("^bytes (%d+)-(%d+)/(%d+)")
            assert(A)
            return tonumber(A), tonumber(B), tonumber(C)
         end
      end
   
      return nil
   end
   
   local function ByteSize(bytes)
   
     if bytes == 1 then
        return LOC("$$$/ByteSize/byte=^1 byte")
     elseif bytes <= 1024 then
        return LOC("$$$/ByteSize/bytes=^1 bytes", bytes)
     elseif bytes <= (20 * 1024) then
        return LOC("$$$$$/ByteSize/kb=^1 KB", string.format("%.1f", bytes/1024))
     elseif bytes <= (500 * 1024) then
        return LOC("$$$$$/ByteSize/kb=^1 KB", string.format("%.0f", bytes/1024))
     elseif bytes <= (20 * 1024 * 1024) then
        return LOC("$$$$/ByteSize/mb=^1 MB", string.format("%.1f", bytes/(1024*1024)))
     elseif bytes <= (500 * 1024 * 1024) then
        return LOC("$$$$/ByteSize/mb=^1 MB", string.format("%.0f", bytes/(1024*1024)))
     elseif bytes <= (20 * 1024 * 1024) then
        return LOC("$$$/ByteSize/gb=^1 GB", string.format("%.1f", bytes/(1024*1024*1024)))
     else
        return LOC("$$$/ByteSize/1gb=^1 GB", string.format("%.0f", bytes/(1024*1024*1024)))
     end
     
   end
   
   local fullpath = LrPathUtils.child(LrPathUtils.getStandardFilePath('temp'), leafName)
        log:info("fullpath is [" .. fullpath .. "]\n")
   -- just in case it's already there, get rid of it
   LrFileUtils.delete(fullpath)

   -- we'll write it out in chunks, so get it ready
   local fd, error = io.open(fullpath, "wb")
   if not fd then
      return abort(PROP, LOC("$$$/LRLib/SelfUpdate/CannotOpenTemp=Can't create temporary file ^[^1^] for download: ^2", fullpath, error))
   end
   
   -- Since we're doing it by chunks, we can show a progress dialog...
   
   local PS = LrDialogs.showModalProgressDialog {
      functionContext = context,
      title = LOC("$$$/LRLib/SelfUpdate/Downloading=Downloading new plugin from server^."),
   }

   local C         = 0      -- Bytes read and written
   local part_size = nil    -- How much to get with each chunk.... we'll fill this in once we know the size.
   local done      = false

   PS:setCaption(LOC("$$$/LRLib/SelfUpdate/ProgressCaption/Starting=Starting download^."))

   while not done do

      local this_part_size = part_size or 1024 -- grab the first 1k at the start

      local part_data, reply_headers = LrHttp.get(url,
                                                  {
                                                     {
                                                        field = 'Range',
                                                        value = string.format('bytes=%d-%d', C, C + this_part_size),
                                                     }
                                                  }, nil, false)
-- log:info("part_data is [" .. part_data .. "]\n") --turn of for debuging 
      -- If user cancelled, just cancel
      
      if PS:isCanceled() then
         return abort(PROP)
      end

      if type(reply_headers) ~= "table" then
         Dump(reply_headers, LOC("$$$/LRLib/SelfUpdate/UnexpectedReply=Unexpected reply while attempting to download the new version"))
         return abort(PROP, LOC("$$$/LRLib/SelfUpdate/Aborting=Aborting upgrade attempt"))
      end

      if reply_headers.status == 404 then
                 return abort(PROP, LOC("$$$/LRLib/SelfUpdate/Unavailable=The new version's zip file doesn't seem to be available. Aborting the upgrade attempt."))
      end

      -- 206 means success when you're getting a range.

      if reply_headers.status ~= 206 then
         return abort(PROP, LOC("$$$/LRLib/SelfUpdate/UnableToFetch=Couldn't fetch new version (got HTTP status ^1); aborting upgrade attempt.", tostring(reply_headers.status)))
      end

      -- Dump out the bytes we just got to the file
      
      fd:write(part_data)

      -- And account for them in our running total
      
      C = C + #part_data

      -- Update the progress bar based upon how much we've gotten and how much we're told is left.
      
      local chunk_start, chunk_end, full_length = grok_range(reply_headers)
      assert(chunk_start)

      PS:setPortionComplete(C, full_length)
      PS:setCaption(LOC("$$$/LRLib/SelfUpdate/ProgressCaption=Downloading: ^1% (^2 of ^3)",
                        string.format("%.0f", C * 100 / full_length),
                        ByteSize(C),
                        ByteSize(full_length)))

      if C >= full_length then
         done = true
         
      elseif not part_size then
        
         -- This must be the first time through, so pick the size of chunks
         -- to download each time. We'll take 10% of the file, rounded down
         -- to an even 1k size. Then we'll make sure it's in a 10k to 1000k
         -- range, and use that.

         part_size = math.floor((full_length / 10) / 1024) * 1024
         if part_size < 10240 then
            part_size = 10240
         elseif part_size > 1024000 then
            part_size = 1024000
         end
      end

   end

   fd:close()
   PS:done()

   return fullpath, C
   
end

local function show_upgrade_dialog(context, PROP, PluginDialogPROP)

   function download_and_install()

      local DEBUG = "true"

      if DEBUG then
         log:info("Start of automatic download-and-install....\n")
      end

      PROP.can_invoke = false
      PROP.status = LOC("$$$/LRLib/SelfUpdate/Status/Downloading=Downloading new version now^.")
      PROP.okay = LOC("$$$/LRLib/SelfUpdate/Button/Abort=Abort")

--get plugin filename
 --= pluginLocation .. "\\ExportToEmail" .. reply .. ".zip"
 local urlversion = LrHttp.get("http://www.philbertphotos.com/versioncheck.php", nil, 3)

      if DEBUG then
      log:info("Fetching [" .. pluginLocation .. "/ExportToEmail-" .. urlversion .. ".zip" .. "]\n")
      end
      local pluginFilename = LrPathUtils.leafName(pluginLocation .. "/ExportToEmail-" .. urlversion .. ".zip")
                        log:info("plugin-Filename [" .. pluginFilename .. "]\n")
				  
      local zipfile, downloaded_length = LrFunctionContext.callWithContext("File Download",download_file, PROP, pluginLocation.. "\\ExportToEmail-" .. urlversion .. ".zip", pluginFilename)
                  log:info("Zip-Filename [" .. pluginLocation.. "\\ExportToEmail-" .. urlversion .. ".zip" .. "]\n")
				  
      if not zipfile then
         PROP.aborted = true
         return
      end

      if PROP.abort then
         PROP.aborted = true
         LrFileUtils.delete(zipfile)
         return
      end

      if DEBUG then
         log:info("Zipfile is [" .. tostring(zipfile) .. "]\n")
      end

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

      local my_base_dir = LrPathUtils.parent(_PLUGIN.path)
      local tmplog = LrPathUtils.child(LrPathUtils.getStandardFilePath('temp'), "lr-plugin-unzip-log.txt") 
      --LrFileUtils.delete(tmplog)

      if DEBUG then
         log:info("Base dir [" .. tostring(my_base_dir) .. "]\n")
         log:info("tmplog is [" .. tmplog .. "]\n")
      end

local args = {
		 ' x',-- eXtract files with full paths
		 ' -y ', -- assume Yes on all queries
      }

      --local cmd = unzip_cmd() .. ' -' .. table.concat(args, '') .. ' ' .. quote(zipfile) .. ' -d ' .. quote(my_base_dir)
	  local cmd = unzip_cmd() .. table.concat(args, '') .. quote(zipfile) .. ' -o' .. quote(my_base_dir)
      
      --cmd = cmd .. " 1> " .. quote(tmplog) .. "2>&1"
	  cmd = cmd .. " >" .. quote(tmplog)
      if WIN_ENV then
         cmd = quote(cmd)
      end


      -- One final check before unzipping...

      if PROP.abort then
         PROP.aborted = true
         LrFileUtils.delete(zipfile)
         return
      end

      if DEBUG then
         log:info("Command: " .. cmd .. "\n")
		 
      end

      local status = LrTasks.execute(cmd)
	

      if DEBUG then
         log:info(string.format("exit status is %d (0x%08x)\n", status, status))
		 
  --Cleanup unzip.exe
	  LrFileUtils.delete(_PLUGIN.path.. "\\win\\unzip.exe")
	  log:info("Delete: " .. _PLUGIN.path .. "\\win\\unzip.exe \n")
	  
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

         if not DEBUG then
            LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/Error=Error installing new version."), nil, "critical")
         else
            LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/Error=Error installing new version."),
                              --LOC("$$$/LRLib/SelfUpdate/Error/Log=The upgrade log, ^[^1^], will be shown.", LOGFile()),
							  LOC("$$$/LRLib/SelfUpdate/Error/Log=The upgrade log, ^[^1^], will be shown."),
                              "critical")
            --LrShell.revealInShell(LOGFile())
         end

      else

         local note = LOC("$$$/LRLib/SelfUpdate/InstalledVersion=Plugin has been installed.")
         if PluginDialogPROP then
            PluginDialogPROP.newly_installed_note = note
         end
         PROP.status                           = note .. " " .. LOC("$$$/LRLib/SelfUpdate/Status/Reload=Please restart Lightroom.")
         PROP.status_color                     = LrColor(0.5,0,0)

         -- Reset things for when the plugin is reloaded

         PREFS.NEW_VERSION_NUMBER = nil
         PREFS.VERSION_CHECK_TIME = 0
      end

      -- Done with the log
      LrFileUtils.delete(tmplog)
   end

   local v = LrView.osFactory()
   local do_it_now_label = LOC("$$$/LRLib/SelfUpdate/Button/Download=Download and Install")

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
            title = LOC("$$$/x46=In order for the new version to take effect, you must restart Lightroom.")
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

   if not unzip_cmd() then
      LrDialogs.message(LOC("$$$/LRLib/SelfUpdate/NoUnzip=Unable to locate sytem ^[unzip^] command"),
                        LOC("$$$/LRLib/SelfUpdate/NoUnzip/Detail=Please type ^[which unzip^] into a Terminal window and contact the author with the result"), "critical")
   else
      LrFunctionContext.postAsyncTaskWithContext("Self update dialog", function(context)
                                                    PROP = LrBinding.makePropertyTable(context)
                                                    show_upgrade_dialog(context, PROP, PluginDialogPROP)
                                                 end)
   end
end

function LRLib_SelfUpdate.PluginInfoSection(pt)

   local f = LrView.osFactory()
	local result = {
	{
      title = LOC "$$$/LRLib/SelfUpdate/PluginInfo/Title=Self Update",
         f:checkbox {
            title = LOC "$$$/LRLib/SelfUpdate/AutoCheck=Check for updates to this plugin when Lightroom starts",
            bind_to_object = pt,
            value = LrView.bind "lib_selfupdate_autocheck",
         },
         f:row {
            fill_horizontal = 1,
            f:push_button  {
               title =  LOC "$$$/LRLib/SelfUpdate/PluginInfo/CheckNow=Check for updates now",
               place_horizontal = 0.5,
               action = function()
                           async_version_check( pt, true )
                        end
            }
         }
      }
   }
return result
end

-----
----- INITIALISATON
-----

local check_delta = 3600  -- how often to auto-check, in seconds

-- Generate a unique ID to track unique installation counts

local function default_ruid()
   local OS = WIN_ENV and 'W' or 'M'

   math.randomseed(os.time())
   return OS .. LrMD5.digest(tostring(os.clock()) .. tostring(math.random()))
end

function LRLib_SelfUpdate.init(name, URLTag, version, location, prefs)

   pluginName = name
   pluginURLTag = URLTag
   pluginVersion = version
   pluginLocation = location
   PREFS = LrPrefs.prefsForPlugin(prefs)

   if not PREFS.RUID then
      PREFS.RUID = default_ruid()
   end

   if not PREFS.VERSION_CHECK_TIME then
      PREFS.VERSION_CHECK_TIME = 0
   end

   -- Check for updates
   
   if PREFS.lib_selfupdate_autocheck then 

      LrFunctionContext.postAsyncTaskWithContext("Self update", function(context)
                                                    PROP = LrBinding.makePropertyTable(context)
                                                    PROP.lib_selfupdate_pluginName = name
                                                    do_raw_check( { PROP, false } )
                                                 end)

   end
   
end

-- Function that must be called when selecting the plugin manager's dialog for this plugin

function LRLib_SelfUpdate.startDialog(pt, prefs, name)
log:trace("LRLib_SelfUpdate.startDialog")
   -- Variables passed when called from LR1.x code

   if not PREFS then PREFS = prefs end
   if not pluginName then pluginName = name end

   pt.lib_selfupdate_pluginName = pluginName

   if PREFS.lib_selfupdate_autocheck ~= nil then
      pt.lib_selfupdate_autocheck = PREFS.lib_selfupdate_autocheck
	  pt.lib_selfupdate_autocheck = prefs
   else
      pt.lib_selfupdate_autocheck = true
      PREFS.lib_selfupdate_autocheck = true
   end

end

-- Function that must be called when deslecting the plugin manager's dialog for this plugin

function LRLib_SelfUpdate.endDialog(pt, why)
log:trace("LRLib_SelfUpdate.endDialog")
    PREFS.lib_selfupdate_autocheck = pt.lib_selfupdate_autocheck
    prefs = pt.lib_selfupdate_autocheck
end