--[[----------------------------------------------------------------------------

Utils.lua
some utilities and helper functions

------------------------------------------------------------------------------]]

local LrDialogs 		= import 'LrDialogs'

local logger = import 'LrLogger'( 'ZenphotoUser' )
logger:enable('print')
local debug, info, warn, err = logger:quick( 'debug', 'info', 'warn', 'err' )

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


	
	-- 
	-- 
	--	get_file_contents - read a file
	--	filename: file name
	--	returns
	--		content: content of the file
	--
	function get_file_contents(filename)
		local fh = assert(io.open(filename, "rb"))
		content = fh:read("*a") 
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

	
	
	--
	--	table dump
	--
	function tdump(t)
	  local function dmp(t, l, k)
		if type(t) == "table" then
		  debug(string.format("%s%s:", string.rep(" ", l*2), tostring(k)))
		  for k, v in pairs(t) do
			dmp(v, l+1, k)
		  end
		else
		  debug(string.format("%s%s:%s", string.rep(" ", l*2), tostring(k), tostring(t)))
		end
	  end
	  
	  dmp(t, 1, "root")
	end
	
	

	function table_keys(t)
	  local ks = {}
	  for k in pairs(t) do ks[#ks+1] = k end
	  return ks
	end
	
	
	

	function pairsByKeys (t, f) 
		local a = {} 
		for n in pairs(t) do 
			table.insert(a, n) 
		end 
		table.sort(a, f) 
		local i = 0      -- iterator variable 
		local iter = function ()   -- iterator function 
			i = i + 1 
			if a[i] == nil then 
					return nil 
			else 
					return a[i], t[a[i]] 
			end 
		end 
		return iter 
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