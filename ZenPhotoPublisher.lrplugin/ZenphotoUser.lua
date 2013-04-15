--[[----------------------------------------------------------------------------

ZenphotoUser.lua
Zenphoto user account management

------------------------------------------------------------------------------]]
local LrBinding 		= import 'LrBinding'
local LrDialogs 		= import 'LrDialogs'
local LrView 			= import 'LrView'
local LrFunctionContext = import 'LrFunctionContext'
local LrErrors 			= import 'LrErrors'
local prefs 			= import 'LrPrefs'.prefsForPlugin()
local bind 				= LrView.bind
local share 			= LrView.share

local util              = require 'Utils'

--============================================================================--

ZenphotoUser = {}

--------------------------------------------------------------------------------

local function storedCredentialsAreValid( propertyTable )
			local username = prefs.instanceTable[instanceID].username
			local password = prefs.instanceTable[instanceID].password	
	local serviceIsRunning = prefs.instanceTable[instanceID].serviceIsRunning
	log:debug("storedCredentialsAreValid")
	return username and password and serviceIsRunning
				

end

--------------------------------------------------------------------------------

local function notLoggedIn( propertyTable )
	prefs.instanceTable[instanceID].token = nil
	propertyTable.accountStatus = LOC "$$$/Zenphoto/AccountStatus/NotLoggedIn=Not logged in"
	propertyTable.loginButtonTitle = LOC "$$$/Zenphoto/LoginButton/NotLoggedIn=Log In"
	propertyTable.loginButtonEnabled = true
	propertyTable.validAccount = false
	propertyTable.uploadLimit = ''
	propertyTable.token = nil
log:trace("accountStatus:", propertyTable.accountStatus)
end


function ZenphotoUser.resetLogin( propertyTable )
	notLoggedIn( propertyTable )
	log:trace("ZenphotoUser.resetLogin")
end

--------------------------------------------------------------------------------

function ZenphotoUser.login( propertyTable )
	log:trace("ZenphotoUser.login")
	notLoggedIn( propertyTable )

	local username, password = ZenphotoUser.getLoginAndPassword( propertyTable )
	prefs.instanceTable[instanceID].username = username
	prefs.instanceTable[instanceID].password = password	
	
	prefs.instanceTable[instanceID].token = 'OK'
	propertyTable.token = prefs.instanceTable[instanceID].token
	
	prefs.instanceTable[instanceID].instance_ID = publishServiceID
	propertyTable.instance_ID = prefs.instanceTable[instanceID].instance_ID

end

--------------------------------------------------------------------------------

function ZenphotoUser.getLoginAndPassword( propertyTable )
	log:trace("ZenphotoUser.getLoginAndPassword")
	local login, password, message = (prefs.instanceTable[instanceID].username), (prefs.instanceTable[instanceID].password)
	
	local isAuthorized = false
	local showMessage = false
	
	while not( isAuthorized ) do
	
		local message

		if showMessage then 
			message = LOC "$$$/zenphoto/LoginDialog/Invalid=The user name or password is not valid."
			log:fatal("The user name or password is not valid")
		else
			message = nil
		end

		ZenphotoUser.showLoginDialog( message, propertyTable )
		login, password = prefs.instanceTable[instanceID].username, prefs.instanceTable[instanceID].password
		isAuthorized, showMessage = ZenphotoAPI.authorize( login, password )
	end

	return login, password

end

--------------------------------------------------------------------------------

function ZenphotoUser.initLogin( propertyTable )
log:trace("ZenphotoUser.initLogin")
	if not propertyTable.LR_publishService then return end	
	-- Observe changes to prefs and update status message accordingly.
	local function updateStatus()
		if storedCredentialsAreValid( propertyTable ) then
			local displayUserName = prefs.instanceTable[publishServiceID].username
			
		if isBlank(prefs.instanceTable[instanceID].token) then 
			propertyTable.accountStatus = LOC( "$$$/Zenphoto/AccountStatus/LoggedIn=Not Logged in")
			propertyTable.loginButtonTitle = LOC( "$$$/Zenphoto/LoginButton/LoggedIn=Log in")
			elseif prefs.instanceTable[instanceID].token == "OK" then 
			propertyTable.accountStatus = LOC( "$$$/Zenphoto/AccountStatus/LoggedIn=Logged in as ".. displayUserName )
			propertyTable.loginButtonTitle = LOC( "$$$/Zenphoto/LoginButton/LoggedIn=Switch User?")
		end
			
			propertyTable.loginButtonEnabled = true
			propertyTable.LR_canExport = true
			propertyTable.validAccount = true
		else
			notLoggedIn( propertyTable )
		end
	end

	propertyTable:addObserver( 'token', updateStatus )
	updateStatus()
end

--------------------------------------------------------------------------------

function ZenphotoUser.showLoginDialog( message, propertyTable )
log:trace("ZenphotoUser.showLoginDialog")
	LrFunctionContext.callWithContext( 'ZenphotoUser.showLoginDialog', function( context )

		local f = LrView.osFactory()
	
		local properties = LrBinding.makePropertyTable( context )
		properties.login = prefs.instanceTable[instanceID].username
		properties.password = prefs.instanceTable[instanceID].password	

		local contents = f:column {
			bind_to_object = properties,
			spacing = f:control_spacing(),
			fill = 1,
	
			f:static_text {
				title = LOC "$$$/Zenphoto/LoginDialog/Message=Please enter your user name and password:",
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
			},
	
			message and f:static_text {
				title = message,
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
				text_color = import 'LrColor'( 1, 0, 0 ),
			} or 'skipped item',
			
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/Zenphoto/LoginDialog/Key=User Name:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:edit_field { 
					fill_horizonal = 1,
					width_in_chars = 30, 
					value = bind 'login',
				},
			},
			
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/Zenphoto/LoginDialog/Password=Password:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:password_field { 
					fill_horizonal = 1,
					width_in_chars = 30, 
					value = bind 'password',
				},
			},
		}
		
		local result = LrDialogs.presentModalDialog( 
			{
				title = LOC "$$$/Zenphoto/LoginDialog/Title=Enter your User name", 
				contents = contents,
			} 
		)
		
		if result == 'ok' then
					log:info("Enter your User name")
			prefs.instanceTable[instanceID].username = properties.login
			prefs.instanceTable[instanceID].password = properties.password	
		else
		log:fatal('login error')
			LrErrors.throwCanceled()
		end
	end )
end

--------------------------------------------------------------------------------