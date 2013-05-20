--[[----------------------------------------------------------------------------

Utils.lua
some utilities and helper functions

------------------------------------------------------------------------------]]

local LrDialogs 		= import 'LrDialogs'
local LrFunctionContext	= import 'LrFunctionContext'
local LrBinding         = import 'LrBinding'
local LrView 			= import "LrView"
local LrStringUtils		= import 'LrStringUtils'
local prefs 			= import 'LrPrefs'.prefsForPlugin()
local Info = require 'Info'

Utils = {}

	--
	--
	--	simple preg_replace (PHP style)
	--
	--
	function preg_replace(pat,with,p)
		return (string.gsub(p,pat,with))
	end


	--
	--
	--	trim string - remove leading and tailing spaces
	--
	--
	function trim (s)
		if s ~= nil then
			return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
		end
	end

	--
	--
	--	split string
	--
	--	
	--
	function split(str, pat)
	   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	   local fpat = "(.-)" .. pat
	   local last_end = 1
	   local s, e, cap = str:find(fpat, 1)
	   while s do
	      if s ~= 1 or cap ~= "" then
		 table.insert(t,cap)
	      end
	      last_end = e+1
	      s, e, cap = str:find(fpat, last_end)
	   end
	   if last_end <= #str then
	      cap = str:sub(last_end)
	      table.insert(t, cap)
	   end
	   return t
	end
	--
	--
	--	encode64 decode64 strings
	--
	--	
function decode64(value)

	if type(value) == 'table' then
		for k,v in pairs(value) do
			if type(v) == 'table' then
			--log:debug('before decode: '..table_show(value[k]))
				value[k] = decode64(v)
				--log:debug('after decode: '..table_show(value[k]))
			else
				value[k] = LrStringUtils.decodeBase64(v)
			end
		end
	else
		value = LrStringUtils.decodeBase64(value)
	end
	
	return value
end

function encode64(value)

	if type(value) == 'table' then
		for k,v in pairs(value) do
			if type(v) == 'table' then
				value[k] = encode64(v)
			else
				if k == 'paramValue' then
					value[k] = LrStringUtils.encodeBase64(v)
				end
			end
		end
	else
		value = LrStringUtils.encodeBase64(value)
	end
	
	return value
end	
	--
	--
	--	random string
	--
	--	
math.randomseed(os.time())
 pass = {}
 function generate(s, l) -- args: smallest and largest possible password lengths, inclusive
        size = math.random(s,l) -- random password length
 
        for z = 1,size do
 
                case = math.random(1,2) -- randomly choose case (caps or lower)
                a = math.random(1,#char) -- randomly choose a character from the "char" array
                if case == 1 then
                        x=string.upper(char[a]) -- uppercase if case = 1
                elseif case == 2 then
                        x=string.lower(char[a]) -- lowercase if case = 2
                end
        table.insert(pass, x) -- add new index into array.
        end
        return(table.concat(pass)) -- concatenate all indicies of the "pass" array, then print out concatenation.
end
 
 
 function getVersion()
    return string.format("%i.%i.%i.%i", Info.VERSION.major, Info.VERSION.minor, Info.VERSION.revision, Info.VERSION.build)
end
	--
	--
	--	strip string
	--
	function strip(str)
	gsub("[A-Za-z0-9-]+[ 0-9A-Za-z#$%=@!{},`~&*()'<>?.:;_|^/+\t\r\n\[\]-]*")
	--[a-zA-Z0-9\t\n ./<>?;:"'`!@#$%^&*()[]{}_+=|\\-]
	return str
	end

	function table.join(t1, t2)
--		for k,v in ipairs(t2) do table.insert(t1, v) end return t1

		for k,v in ipairs(t2) do 
			
			local already_exists = false
			for k1,v1 in ipairs(t1) do 
				if v1 == v then
					already_exists = true
				end
			end
			
			if already_exists == false then
				table.insert(t1, v) 
			end
		end 
		return t1
	end	

	
	function Utils.joinTables(t1, t2)
--		for k,v in ipairs(t2) do table.insert(t1, v) end return t1

		for k,v in ipairs(t2) do 
			
			local already_exists = false
			for k1,v1 in ipairs(t1) do 
				if v1 == v then
					already_exists = true
				end
			end
			
			if already_exists == false then
				table.insert(t1, v) 
			end
		end 
		return t1
	end	
	

	function table.findkey(t, v)
		if type(t) == "table" and v then 
			for k, val in pairs(t) do 
				if k == v then 
					return true, k, val
				end 
			end 
		end 
		return false 
	end	

	function table.findValueByKey(t, k, v)
		if type(t) == "table" and v then 
			for key, val in pairs(t) do 
				if k == key and v == value then 
					return true, k, val
				end 
			end 
		end 
		return false 
	end	

	function table.replace(t, kv, v)
	
		if type(t) == "table" and v then 
			for pos, val in pairs(t) do
				if val.id == kv then 
					table.remove(t, pos)
				end 
			end 
		end 

		table.insert(t,v)
	end	
	
	--
	--
	--	getFilenameNoExt
	--		remove the typical file extentions
	-- 
	--
	function Utils.getFilenameNoExt(value)

		-- define special chars and extentions to remove
		local clear = { '\r?\n', ';', '\t', ' ', ',', '.nef', '.NEF', '.jpg', '.JPG', '.psd', '.dng', '.DNG' }
		for i, item in pairs ( clear ) do
			value = string.gsub(value,item,' ')
		end

		-- remove multiple spaces and return
		return trim(string.gsub(value,'%s+',' '))
	end

	
	--
	--
	--	removeFileExtentions
	--		remove file extentions from a string and return a table of results
	-- 
	--
	function Utils.removeFileExtentions(value)
		return split(Utils.getFilenameNoExt(value),' ')
	end
	
    --
	--
	--	getFiledate
	--		remove file extentions from a string and return a table of results
	-- 
	--
	function Utils.getFiledate(value)
		return split(Utils.getFilenameNoExt(value),' ')
	end

	--
	--
	--	Show Missing files dialog
	--
	--
	function Utils.showMissingFilesDialog(photos)

		if not photos then return {} end
	
		table.sort(photos)
	
		local missing = ''
		for i, photo in ipairs( photos ) do
			missing = missing .. photo .. '\r\n'
		end

		local LrView = import 'LrView'
		local f = LrView.osFactory()
		local contents = f:column
		{
			f:static_text {
				title = 'The following images could not be found by their names:',
			},
			spacing = f:control_spacing(),
			f:edit_field {
				fill_horizonal = 1,
				width_in_chars = 40,
				height_in_lines = 15,
				value = missing
			},
		}
		local result = LrDialogs.presentModalDialog(
		{
			title = 'Missing files',
			contents = contents,
			otherVerb = 'Save'
		})
		
		if result == 'other' then
			local saveresult = LrDialogs.runSavePanel(
			{
				title = 'Save result to file',
				canCreateDirectories = true,
				requiredFileType = 'txt',
			})
			
			if saveresult then
				save_to_file(saveresult,missing)
			end
		end
		
	end



 -- Send Log Dialog
function Utils.sendlog() 
LrFunctionContext.callWithContext ("sendprop", function (context)
local prop = LrBinding.makePropertyTable (context) 

prop.from = 'your@email.com'
prop.body = 'Explain your problem here.'
prop.sub = 'Zenphoto problem [sendlog]'
local v = LrView.osFactory()
sendresult = LrDialogs.presentModalDialog {
      title = LOC("$$$/xxx=Send LOG"),
	  actionVerb = "Send",
      contents = v:view {
         bind_to_object = prop,
         v:static_text {
            title = LOC("$$$/xxx=Please be as detailed as possible so I can process the debug log")
         },
         v:view {
            --margin_top    = 30,
            --margin_bottom = 30,
            --place_horizontal = 0.5,
            --place = 'horizontal',
			
v:row {
width = 550,
v:static_text {
				title = LOC "$$$/Zenphoto/ToAddText=From:			",
				alignment = 'right',
				--width = 'labelWidth',
				--visible = bind 'hasNoError',
			},
			
v:edit_field {
				value = LrView.bind 'from',
				auto_completion = true,
				immediate = true,
				height_in_lines = 1,
				fill_horizontal = 1,
				validate = function(view, value)
                             -- strip all whitespace, just in case some came over with a cut-n-paste
                             value = value:gsub('%s+', '')
                             if value:match('^[%w+%.%-_]+@[%w+%.%-_]+%.%a%a+$') then
                                return true, value
                             else
                                return false, value, LOC("$$$/xxx=Enter a valid email address")
                             end
                          end,
			},
		},

		v:row {
v:static_text {
				title = LOC "$$$/Zenphoto/SubjectText=Subject:	",
				alignment = 'right',
				--width = share 'labelWidth',
				--visible = bind 'hasNoError',
			},

v:edit_field {
				value = LrView.bind 'sub',
				--enabled = bind 'subjectline',
				validate = "",
				truncation = 'middle',
				immediate = true,
				height_in_lines = 1,
				fill_horizontal = 1,
			},
		},
		
v:row {
v:static_text {
title = LOC "$$$/Zenphoto/BodyText=USE Ctrl-J to create a new-line",
},
},
v:row {
v:static_text {
				title = LOC "$$$/Zenphoto/BodyText=Body:		",
				alignment = 'right',
				--width = share 'labelWidth',
				--visible = bind 'hasNoError',
			},
v:edit_field {
				value = LrView.bind 'body',
				validate = "",
				truncation = 'middle',
				immediate = true,
				height_in_lines = 8,
				fill_horizontal = 1,
			},
			},
			v:row {
v:static_text {
				title = LOC "$$$/Zenphoto/Striped=ALL PASSWORDS AND SENSITIVE INFORMATION WILL BE STRIPPED FROM THE LOGS\n(hostnames are keep for debugging purposes)",
				alignment = 'right',
				--width = share 'labelWidth',
				--visible = bind 'hasNoError',
			},

			},
		  }
      }
   }
   str = prop.sub..':'..prop.from..':'..prop.body..':' 
    end) 
--log:info(table_show(str)) 
	 if sendresult == "ok" then
      return str
   else
      return false
   end 
end
	-- 
	-- 
	--	get_file_contents - read a file
	--	filename: file name
	--	returns
	--		content: content of the file
	--
	function get_file_contents(filename)
		local fh = assert(io.open(filename, "rb"))
		content = fh:read("*all") 
		fh:close() 
		return content 
	end


	--
	--
	--	save_to_file - save a string to a file
	--	filename: file name
	--	content: yna string to store
	--
	function save_to_file(filename,content)
		local fh = assert(io.open(filename, "wb"))
		fh:write(content) 
		fh:close()
	end

function isBlank(x)
  return not not tostring(x):find("^%s*$")
end	
	--
	--	print table dump
	--
	
--[[function table_show (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = ''
    for key, value in pairs (tt) do
      sb = sb .. (string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        sb = sb .. ( "{\n");
        sb = sb .. (table_show (value, indent + 2, done))
        sb = sb .. (string.rep (" ", indent)) -- indent it
        sb = sb .. ("}\n");
      elseif "number" == type(key) then
         sb = sb .. (string.format("\"%s\"\n", tostring(value)))
      else
         sb = sb .. (string.format("%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return(sb)
  else
    return tostring(tt .. "\n")
  end
end--]]

	--
-- table dump
--
function tdump(t)
local function dmp(t, l, k)
if type(t) == "table" then
if prefs.logLevel == 'verbose' then
log:debug('tdump:',string.format("%s%s:", string.rep(" ", l*2), tostring(k)))
end
for k, v in pairs(t) do
dmp(v, l+1, k)
end
else
if prefs.logLevel == 'verbose' then
log:debug(string.format('tdump:', "%s%s:%s", string.rep(" ", l*2), tostring(k), tostring(t)))
end
end
end

dmp(t, 1, "root")
end

-- alt version2, handles cycles, functions, booleans, etc
--  - abuse to http://richard.warburton.it
-- output almost identical to print(table.show(t)) below.
function print_r (t, name, indent)
  local tableList = {}
  function table_r (t, name, indent, full)
    local serial=string.len(full) == 0 and name
        or type(name)~="number" and '["'..tostring(name)..'"]' or '['..name..']'
    log:debug(indent,serial,' = ') 
    if type(t) == "table" then
      if tableList[t] ~= nil then log:debug('{}; -- ',tableList[t],' (self reference)\n')
      else
        tableList[t]=full..serial
        if next(t) then -- Table not empty
          log:debug('{\n')
          for key,value in pairs(t) do table_r(value,key,indent..'\t',full..serial) end 
          log:debug(indent,'};\n')
        else log:debug('{};\n') end
      end
    else log:debug(type(t)~="number" and type(t)~="boolean" and '"'..tostring(t)..'"'
                  or tostring(t),';\n') end
  end
  table_r(t,name or '__unnamed__',indent or '','')
 end
  
function table_show(t, name, indent)
   local cart     -- a container
   local autoref  -- for self references

   -- returns true if the table is empty
   local function isemptytable(t) return next(t) == nil end

   local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
         local info = debug.getinfo(o, "S")
         -- info.name is nil because o is not a calling level
         if info.what == "C" then
            return string.format("%q", so .. ", C function")
         else 
            -- the information is defined through lines
            return string.format("%q", so .. ", defined in (" ..
                info.linedefined .. "-" .. info.lastlinedefined ..
                ")" .. info.source)
         end
      elseif type(o) == "number" or type(o) == "boolean" then
         return so
      else
         return string.format("%q", so)
      end
   end

   local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

      cart = cart .. indent .. field

      if type(value) ~= "table" then
         cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
         if saved[value] then
            cart = cart .. " = {}; -- " .. saved[value] 
                        .. " (self reference)\n"
            autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
         else
            saved[value] = name
            --if tablecount(value) == 0 then
            if isemptytable(value) then
               cart = cart .. " = {};\n"
            else
               cart = cart .. " = {\n"
               for k, v in pairs(value) do
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "   ", saved, field)
               end
               cart = cart .. indent .. "};\n"
            end
         end
      end
   end

   name = name or "__unnamed__"
   if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
   end
   cart, autoref = "", ""
   addtocart(t, name, indent)
   return cart .. autoref
end

function CurrentTime()
   local F = [[%%a=%a
%%A=%A 
%%b=%b 
%%B=%B 
%%c=%c 
%%d=%d 
%%H=%H 
%%I=%I 
%%j=%j 
%%m=%m 
%%M=%M 
%%p=%p 
%%S=%S 
%%U=%U 
%%w=%w
%%W=%W
%%x=%x
%%X=%X
%%y=%y   
%%Y=%Y    
]]
   return os.date(F, os.time())
end

function table.clone(t, nometa) 
   local u = {} 
    
   if not nometa then 
     setmetatable(u, getmetatable(t)) 
   end 
    
   for i, v in pairs(t) do 
     if type(v) == "table" then 
       u[i] = table.clone(v) 
     else 
       u[i] = v 
     end 
   end 
    
   return u 
 end 
  
 function table.merge(t, u) 
   local r = table.clone(t) 
    
   for i, v in pairs(u) do 
     r[i] = v 
   end 
    
   return r 
 end 
  
 function table.keys(t) 
   local keys = {} 
   for k, v in pairs(t) do table.insert(keys, k) end 
   return keys 
 end 
  
 function table.unique(t) 
   local seen = {} 
   for i, v in ipairs(t) do 
     if not table.includes(seen, v) then table.insert(seen, v) end 
   end 
  
   return seen 
 end 
  
 function table.values(t) 
   local values = {}     
   for k, v in pairs(t) do table.insert(values, v) end   
   return values 
 end 
  
 function table.last(t) 
   return t[#t] 
 end 
  
 function table.append(t, moreValues) 
   for i, v in ipairs(moreValues) do 
     table.insert(t, v) 
   end 
    
   return t 
 end 
  
 function table.indexOf(t, value) 
   for k, v in pairs(t) do 
     if v == value then return k end 
   end 
    
   return nil 
 end 
  
 function table.includes(t, value) 
   return table.indexOf(t, value) 
 end 
  
 function table.find(t, func) 
   for k, v in pairs(t) do 
     if func(v) then return v end 
   end 
    
   return nil 
 end 
  
 function table.filter(t, func) 
   local matches = {} 
   for k, v in pairs(t) do 
     if func(v) then table.insert(matches, v) end 
   end 
    
   return matches 
 end 
  
 function table.map(t, func) 
   local mapped = {} 
   for k, v in pairs(t) do 
     table.insert(mapped, func(v)) 
   end 
    
   return mapped 
 end 
  
 function table.groupBy(t, func) 
   local grouped = {} 
   for k, v in pairs(t) do 
     local groupKey = func(v) 
     if not grouped[groupKey] then grouped[groupKey] = {} end     
     table.insert(grouped[groupKey], v) 
   end 
    
   return grouped 
 end 
  
 function table.tostring(t, indent) 
   local output = {} 
   if type(t) == "table" then 
     table.insert(output, "{\n") 
     for k, v in pairs(t) do 
       local innerIndent = (indent or " ") .. (indent or " ") 
       table.insert(output, innerIndent .. tostring(k) .. " = ") 
       table.insert(output, table.tostring(v, innerIndent)) 
     end 
      
     if indent then 
       table.insert(output, (indent or "") .. "},\n") 
     else 
       table.insert(output, "}") 
     end 
   else 
     if type(t) == "string" then t = string.format("%q", t) end -- quote strings       
     table.insert(output, tostring(t) .. ",\n") 
   end 
    
   return table.concat(output) 
 end 
 
function serialize(t)
  local serializedValues = {}
  local value, serializedValue
  for i=1,#t do
    value = t[i]
    serializedValue = type(value)=='table' and serialize(value) or value
    table.insert(serializedValues, serializedValue)
  end
  return string.format("{ %s }", table.concat(serializedValues, ', ') )
end

-- Is Str an identifier?
local function IsIdent(Str)
 return not Keywords[Str] and string.find(Str, "^[%a_][%w_]*$")
end

-- Converts a non-table to a Lua- and human-readable string:
local function ScalarToStr(Val)
 local Ret
 local Type = type(Val)
 if Type == "string" then
   Ret = StrToStr(Val)
 elseif Type == "function" or Type == "userdata" or Type == "thread" then
   -- Punt:
   Ret = "<" .. _tostring(Val) .. ">"
 else
   Ret = _tostring(Val)
 end -- if
 return Ret
end

-- Converts a table to a Lua- and human-readable string.
local function TblToStr(Tbl, Seen)
 Seen = Seen or {}
 local Ret = {}
 if not Seen[Tbl] then
   Seen[Tbl] = true
   local LastArrayKey = 0
   for Key, Val in pairs(Tbl) do
     if type(Key) == "table" then
       Key = "[" .. TblToStr(Key, Seen) .. "]"
     elseif not IsIdent(Key) then
       if type(Key) == "number" and Key == LastArrayKey + 1 then
         -- Don't mess with Key if it's an array key.
         LastArrayKey = Key
       else
         Key = "[" .. ScalarToStr(Key) .. "]"
       end
     end
     if type(Val) == "table" then
       Val = TblToStr(Val, Seen)
     else
       Val = ScalarToStr(Val)
     end
     Ret[#Ret + 1] =
       (type(Key) == "string"
         and (Key .. " = ") -- Explicit key.
         or "") -- Implicit array key.
       .. Val
   end
   Ret = "{" .. table.concat(Ret, ", ") .. "}"
 else
   Ret = "<cycle to " .. _tostring(Tbl) .. ">"
 end
 return Ret
end

--
-- Strip UTF8 BOM
--
function string.ucharrange(s, i)
	if type(s) ~= "string" or type(i) ~= "number" or i < 1 or i > s:len() then
		error("string and valid number expected", 2)
	end
	local byte = s:byte(i)
	if not byte then
		return 0
	elseif byte < 192 then
		return 1
	elseif byte < 224 then
		return 2
	elseif byte < 240 then
		return 3
	elseif byte < 248 then
		return 4
	elseif byte < 252 then
		return 5
	else
		return 6
	end
end

function string.uchars(s)
	if type(s) ~= "string" then
		error("string expected", 2)
	end
	local char_i, s_pos = 0, 1
	local function itor()
		if s_pos > s:len() then
			return nil
		end

		local char_w = string.ucharrange(s, s_pos)
		local cur_pos = s_pos
		s_pos = s_pos + char_w
		char_i = char_i + 1
		return char_i, s:sub(cur_pos, cur_pos + char_w - 1)
	end
	return itor
end

function utf8trim(s)
	--Unicode characters to table entries
	local utf8_c = {}
	for ci, char in string.uchars(s) do
		table.insert(utf8_c, char)
	end
	--Erase prespace
	local prespace = 0
	for ci=1, #utf8_c do
		if utf8_c[ci] ~= " " and utf8_c[ci] ~= "\t" then
			for i=1, ci-1 do
				prespace = prespace + 1
				table.remove(utf8_c, 1)
			end
			break
		elseif ci == #utf8_c then
			prespace = #utf8_c
			utf8_c = {}
		end
	end
	--Erase postspace
	local postspace = 0
	for ci=#utf8_c, 1, -1 do
		if utf8_c[ci] ~= " " and utf8_c[ci] ~= "\t" then
			for i=#utf8_c, ci+1, -1 do
				postspace = postspace + 1
				table.remove(utf8_c)
			end
			break
		end
	end
	--Return trimmed string
	return table.concat(utf8_c), prespace, postspace
end