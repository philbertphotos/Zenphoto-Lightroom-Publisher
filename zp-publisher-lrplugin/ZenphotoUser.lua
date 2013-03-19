--[[-----------------------------+-----------------------------------------------

ZenphotoUser.lua
Zenphoto user account management

------------------------------------------------------------------------------]]

	-- Lightroom SDK
local LrBinding 		= import 'LrBinding'
local LrDialogs 		= import 'LrDialogs'
local LrView 			= import 'LrView'
local LrFunctionContext = import 'LrFunctionContext'
local LrErrors 			= import 'LrErrors'
local prefs 			= import 'LrPrefs'.prefsForPlugin()
local bind 				= LrView.bind
local share 			= LrView.share

    -- Logger
local LrLogger = import 'LrLogger'
local log = LrLogger( 'ZenphotoLog' )

--============================================================================--

ZenphotoUser = {}

--------------------------------------------------------------------------------

local function storedCredentialsAreValid( propertyTable )
	local username = prefs.username
	local password = prefs.password
	local serviceIsRunning = prefs.serviceIsRunning
	log:debug("check credentials: ",tostring(username) and tostring(password) and tostring(serviceIsRunning))
	return username and password and serviceIsRunning
				

end

--------------------------------------------------------------------------------

local function notLoggedIn( propertyTable )
--	prefs.username = nil
--	prefs.password = nil
	prefs.token = nil
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

	prefs.username = username
	prefs.password = password
	prefs.token = 'OK'

	propertyTable.token = prefs.token

end

--------------------------------------------------------------------------------

function ZenphotoUser.getLoginAndPassword( propertyTable )
if prefs.logLevel ~= not 'none' then
log:trace("'ZenphotoUser.getLoginAndPassword'")
end
	local login, password, message = prefs.username, prefs.password
	
	local isAuthorized = false
	local showMessage = false
	
	while not( isAuthorized ) do
	
		local message

		if showMessage then 
			message = LOC "$$$/zenphoto/LoginDialog/Invalid=The user name or password is not valid."
			log:debug ("The user name or password is not valid")
		else
			message = nil
		end

		ZenphotoUser.showLoginDialog( message, propertyTable )
		login, password = prefs.username, prefs.password
		isAuthorized, showMessage = ZenphotoAPI.authorize( login, password )
	end

	return login, password

end

--------------------------------------------------------------------------------

function ZenphotoUser.initLogin( propertyTable )
if prefs.logLevel ~= not 'none' then
log:trace("ZenphotoUser.initLogin")
end
--local pubServices = LrPublishService.publishService.localIdentifier
	local tableID = prefs.publishServiceID
	log:trace("tableID: "..tableID)
				prefs.instanceTable = {}
				log:info("Inserting login instance")
				--prefs.instanceTable = {}
				table.insert(prefs.instanceTable,tableID,{
					username = prefs.username,
					password = prefs.password				
					}
				)					
	--checkuser = prefs.instanceTable[instanceId].webpath
--log:trace("checkuser:" ..checkuser)

	if not propertyTable.LR_publishService then return end
	-- Observe changes to prefs and update status message accordingly.
	local function updateStatus()
		if storedCredentialsAreValid( propertyTable ) then
			local displayUserName = prefs.username
			propertyTable.accountStatus = LOC( "$$$/Zenphoto/AccountStatus/LoggedIn=Logged in as ^1", displayUserName )
			propertyTable.loginButtonTitle = LOC "$$$/Zenphoto/LoginButton/LoggedIn=Switch User?"
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
		properties.login = prefs.username
		properties.password = prefs.password


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
			prefs.username = properties.login
			prefs.password = properties.password
		else
			LrErrors.throwCanceled()
		end
	end )
end

--------------------------------------------------------------------------------
