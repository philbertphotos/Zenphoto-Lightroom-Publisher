<?php
//    make sure that the WEBPATH is set to parent directory for correct URL values
define ('sysrpcversion', "4.5.0.20130526");
$dir        = str_replace( '\\', '/', realpath( dirname( __FILE__ ) ) );
define( 'SERVERPATH', str_replace( '/plugins/ZenPublisher', '', $dir ) );
require_once( SERVERPATH . '/zp-core/functions.php' );
include_once( SERVERPATH . '/zp-core/template-functions.php' );
require_once( SERVERPATH . '/zp-core/lib-auth.php' );

if (getOption('zenpublisher_phperror') == 0)
{
error_reporting( E_ERROR | E_PARSE );
ini_set( "display_errors", "0" );
}

/*******************************************************************************************************
 *
 *        RPC functions
 *
 **/
function getmethod( $str )
{
	// Create the map of RPC method names to the relevant functions 
	$bindings = ( array(
		 'zenphoto.login' => 'authorize',
		'zenphoto.check' => 'checkConnection',
		'zenphoto.album.getList' => 'getAlbumList',
		'zenphoto.album.getImages' => 'getAlbumImages',
		'zenphoto.album.delete' => 'deleteAlbum',
		'zenphoto.album.create' => 'createAlbum',
		'zenphoto.album.edit' => 'changeAlbum',
		'zenphoto.image.delete' => 'deleteImage',
		'zenphoto.image.upload' => 'imageUpload',
		'zenphoto.get.comments' => 'getImageComments',
		'zenphoto.get.thumbnail' => 'getAlbumThumbnail',
		'zenphoto.get.ratings' => 'getImageRatings',
		'zenphoto.get.version' => 'getsysVersion',
		'zenphoto.get.update' => 'updateCheck',
		'zenphoto.chk.func' => 'checkFunc',
		'zenphoto.add.comment' => 'addImageComments',
		'zenphoto.test' => 'test' 
	) );
	foreach ( $bindings as $key => $val ) {
		if ( $key == $str ) {
			return $val;
		} //$key == $str
	} //$bindings as $key => $val
}
class ZEN_Error
{
	var $code;
	var $message;
	function ZEN_Error( $code, $message )
	{
		$this->code    = $code;
		$this->message = htmlspecialchars( $message );
	}
	function getjson( )
	{
		$result = json_encode( array(
			 'faultCode' => $this->code,
			'faultString' => $this->message 
		) );
		header( 'Connection: close' );
		header( 'Content-Type: application/json; charset=UTF-8' );
		header( 'Date: ' . date( 'r' ) );
		echo trim( $result );
		return $getjson;
	}
}
function output( $result )
{
	$result = json_encode( $result );
	header( 'Connection: close' );
	header( 'Content-Type: application/json; charset=UTF-8' );
	header( 'Date: ' . date( 'r' ) );
	echo trim( $result );
	exit;
}
//read the data header 
if ( isset( $_SERVER[ 'REQUEST_METHOD' ] ) && $_SERVER[ 'REQUEST_METHOD' ] !== 'POST' ) {
	header( 'Content-Type: text/plain' );
	die( 'ZenphotoPublisher requests allowed only.' );
} //isset( $_SERVER[ 'REQUEST_METHOD' ] ) && $_SERVER[ 'REQUEST_METHOD' ] !== 'POST'
global $HTTP_RAW_POST_DATA;
if ( empty( $HTTP_RAW_POST_DATA ) ) {
	$data = file_get_contents( 'php://input' );
} //empty( $HTTP_RAW_POST_DATA )
else {
	$data =& $HTTP_RAW_POST_DATA;
}
$pieces     = explode( "=", $data );
$methodname = getmethod( $pieces[ 0 ] );
output( $methodname( $pieces[ 1 ] ) );
/*******************************************************************************************************
 *
 *        General Helper functions
 *
 **/

function addZenPubData( $id, $data )
{
	/* Adds Zenphoto published information to database. */
	$parts    = explode( "=", $data );
	$readitem = query_single_row( $sql = "SELECT id, `aux`, `data` FROM " . prefix( 'plugin_storage' ) . " WHERE `type` = 'zenphotopublisher' AND `aux` = " . db_quote( $id ) );
	
	if ( $readitem ) {
		// creating or updating key
		$arr = json_decode( $readitem[ 'data' ], true );
		
		foreach ( $arr as $key => $value ) {
			if ( $key == $parts[ 0 ] ) {
				$arr[ $key ] = $parts[ 1 ];
			} //$key == $parts[ 0 ]
		} //$arr as $key => $value
		
		if ( $readitem = null ) {
			query( "UPDATE " . prefix( 'plugin_storage' ) . " SET `data` = " . db_quote( json_encode( array(
				 $parts[ 0 ] => $parts[ 1 ] 
			) ) ) . ", `type` = 'zenphotopublisher' WHERE `aux` = " . db_quote( $id ) . " AND `type` = 'zenphotopublisher'" );
		} //$readitem = null
		else {
			$marr = array_merge( $arr, array(
				 $parts[ 0 ] => $parts[ 1 ] 
			) );
			query( "UPDATE " . prefix( 'plugin_storage' ) . " SET `data` = " . db_quote( json_encode( $marr ) ) . ", `type` = 'zenphotopublisher' WHERE `aux` = " . db_quote( $id ) . " AND `type` = 'zenphotopublisher'" );
		}
	} //$readitem
	else {
		query( "INSERT INTO " . prefix( 'plugin_storage' ) . " (`type`,`aux`,`data`) VALUES ('zenphotopublisher'," . db_quote( $id ) . ",'" . json_encode( array(
			 $parts[ 0 ] => $parts[ 1 ] 
		) ) . "')" );
	}
}

//Read Data
function readZenPubData( $id, $item )
{
	$readitem = query_single_row( $sql = "SELECT id, `aux`, `data` FROM " . prefix( 'plugin_storage' ) . " WHERE `type` = 'zenphotopublisher' AND `aux` = " . db_quote( $id ) );
	$v        = json_decode( $readitem[ 'data' ], true );
	return $v[ $item ];
}

//Delete record or remove item from array
function delZenPubData( $id, $item, $why )
{
	$readitem = query_single_row( $sql = "SELECT id, `aux`, `data` FROM " . prefix( 'plugin_storage' ) . " WHERE `type` = 'zenphotopublisher' AND `aux` = " . db_quote( $id ) );
	$arr      = $readitem[ 'data' ];
	if ( $why ) {
		query( "DELETE FROM " . prefix( 'plugin_storage' ) . " WHERE `type` = 'zenphotopublisher' AND `aux` = " . db_quote( $id ) );
	} //$why
	else {
		unset( $arr[ $item ] );
		query( "UPDATE " . prefix( 'plugin_storage' ) . " SET `data` = " . db_quote( json_encode( $arr ) ) . ", `type` = 'zenphotopublisher' WHERE `aux` = " . db_quote( $id ) . " AND `type` = 'zenphotopublisher'" );
	}
}

function getFolderNode( $foldername )
{
	return strrpos( $foldername, '/' ) ? substr( strrchr( $foldername, "/" ), 1 ) : $foldername;
}
/**
 *    get all subalbums (if available)
 **/
function getSubAlbums( $gallery, $album )
{
	$list     = array( );
	$albumObj = new Album( $gallery, $album );
	$albumID  = $albumObj->getID();
	$parentID = getItemByID( "albums", $albumID );
	if ( $albumObj->isDynamic() || !$albumID )
		return $list;
	$subalbums = $albumObj->getAlbums( null, null, null, null, true );
	$subalbums = $parentID->getAlbums( null, null, null, null, true );
	if ( is_array( $subalbums ) ) {
		foreach ( $subalbums as $subalbum ) {
			$list[ ] = $subalbum;
			$list    = array_merge( $list, getSubAlbums( $gallery, $subalbum ) );
		} //$subalbums as $subalbum
	} //is_array($subalbums)
	return $list;
}

function hasSubAlbums( $id )
{
	$albumobject = getItemByID( "albums", $id );
	$subalbums = $albumobject->getAlbums( null, null, null, null, true );
if ( empty( $subalbums ) )
	return false;
else
	return true;
}
function entitysave( $list )
{
	$tmp = array( );
	if ( is_array( $list ) )
		foreach ( $list as $key => $value )
			$tmp[ $key ] = html_entity_decode( $value );
	return $tmp;
}
function decode64( $args )
{
	$args = json_decode( base64_decode( $args ), true );
	foreach ( $args[ 0 ] as $key => $value )
		$args[ $key ] = $value;
	return $args;
}
/**
 * Returns the hash of the zenphoto password
 *
 * @param string $user
 * @param string $pass
 * @return string
 */
function passwordHash( $user, $pass, $hash_type = NULL )
{
	if ( is_null( $hash_type ) ) {
		$hash_type = getOption( 'strong_hash' );
	} //is_null($hash_type)
	switch ( $hash_type ) {
		case 1:
			$hash = sha1( $user . $pass . HASH_SEED );
			break;
		case 2:
			$hash = base64_encode( pbkdf2( $pass, $user . HASH_SEED ) );
			break;
		default:
			$hash = md5( $user . $pass . HASH_SEED );
			break;
	} //$hash_type
	if ( DEBUG_LOGIN ) {
		debugLog( "passwordHash($user, $pass, $hash_type)[{HASH_SEED}]:$hash" );
	} //DEBUG_LOGIN
	return $hash;
}
/**
 * Returns an admin object from the $pat:$criteria
 * @param array $criteria [ match => criteria ]
 * @return Zenphoto_Administrator
 */
function getAnAdmin( $criteria )
{
	$selector = array( );
	foreach ( $criteria as $match => $value ) {
		if ( is_numeric( $value ) ) {
			$selector[ ] = $match . $value;
		} //is_numeric($value)
		else {
			$selector[ ] = $match . db_quote( $value );
		}
	} //$criteria as $match => $value
	$sql   = 'SELECT * FROM ' . prefix( 'administrators' ) . ' WHERE ' . implode( ' AND ', $selector ) . ' LIMIT 1';
	$admin = query_single_row( $sql, false );
	if ( $admin ) {
		return newAdministrator( $admin[ 'user' ], $admin[ 'valid' ] );
	} //$admin
	else {
		return NULL;
	}
}
/**
 * Instantiates and returns administrator object
 * @param $name
 * @param $valid
 * @return object
 */
function newAdministrator( $name, $valid = 1 )
{
	$user = new Zenphoto_Administrator( $name, $valid );
	return $user;
}
function checkLogon( $user, $pass )
{
	global $_zp_authority;
	$userobj = getAnAdmin( array(
		 '`user`=' => $user,
		'`valid`=' => 1 
	) );
	debugLog( 'checkLogon.userobject: ' . $userobj );
	if ( $userobj ) {
		$hash = $_zp_authority->passwordHash( $user, $pass );
		if ( $hash != $userobj->getPass() ) {
			$userobj = NULL;
		} //$hash != $userobj->getPass()
	} //$userobj
	// if (DEBUG_LOGIN) {
	if ( $userobj ) {
		$rights = sprintf( '%X', $userobj->getRights() );
	} //$userobj
	else {
		$rights = false;
	}
	debugLog( sprintf( 'checkLogon(%1$s, %2$s)->%3$s', $user, $hash, $rights ) );
	// } //DEBUG_LOGIN
	debugLog( "userObject1: " . $userobj );
	return $userobj;
}
function imgtime( $str )
{
	$time = strtotime( str_replace( " ", "", ( str_replace( ":", "", $str ) ) ) );
	//return date("n/d/Y g:i:s A",$time);
	return date( "Y-m-d", $time );
}
function encode_items( $array )
{
	foreach ( $array as $key => $value ) {
		if ( is_array( $value ) ) {
			$array[ $key ] = encode_items( $value );
		} //is_array($value)
		else {
			$array[ $key ] = mb_convert_encoding( $value, 'utf-8' );
		}
	} //$array as $key => $value
	return $array;
}
function logger( $string, $loglevel )
{
	switch ( $loglevel ) {
		case 'debug':
			debugLog( 'DEBUG: ' . $string );
			break;
		case 'trace':
			//debugLog('TRACE: '.$string);
			break;
		case 'errors':
			break;
		case 'none':
			break;
		default:
			break;
	} //$loglevel
}
/*******************************************************************************************************
 *
 * Functions defining the behaviour of the server 
 *
 **/
/**
 *    authorize user
 **/
function authorize( $args )
{
	global $_zp_authority;
	$args = decode64( $args );
	//debugLog('after decode: '.var_export($args, true));
	logger( 'authorize', ( $args[ 'loglevel' ] ) );
	if ( !preg_match( '#^1.4#', ( $version = getVersion() ) ) )
		return new ZEN_Error( -2, 'Zenphoto version ' . $version . ' but v1.4.x required!' );
	$_zp_authority = new Zenphoto_Authority();
	$hash          = $_zp_authority->passwordHash( $args[ 'loginUsername' ], $args[ 'loginPassword' ] );
	debugLog( 'hashvalue: ' . $hash );
	$userobj = getAnAdmin( array(
		 '`user`=' => $args[ 'loginUsername' ],
		'`valid`=' => 1 
	) );
	if ( $userobj == '' ) {
		return new ZEN_Error( -1, 'Incorrect username or password ' . $args[ 'loginUsername' ] . ' ' . $args[ 'loginPassword' ] );
	} //$userobj == ''
	else {
		$localhash = $userobj->getPass();
		debugLog( 'hash = ' . $hash . " localhash = " . $localhash );
		if ( $hash == $localhash ) {
			return true;
		} //$userobj
		else {
			return new ZEN_Error( -1, 'Incorrect username or password ' . $args[ 'loginUsername' ] . ' ' . $args[ 'loginPassword' ] );
		}
	}
}
/**
 *
 *getalbum List
 **/
function getAlbumList( $args )
{
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'getAlbumList', ( $args[ 'loglevel' ] ) );
	$gallery   = new Gallery();
	$albums    = $gallery->getAlbums( null, null, null, null, true );
	//
	//    gather all names of the albums, including sub-albums
	//
	$allalbums = array( );
	if ( is_array( $albums ) )
		foreach ( $albums as $album ) {
			$allalbums[ ] = $album;
			foreach ( getSubAlbums( $gallery, $album ) as $sub )
				$allalbums[ ] = $sub;
		} //$albums as $album
	//
	//    create album objects and get needed values
	//
	foreach ( $allalbums as $albumfolder ) {
		$album = new Album( $gallery, $albumfolder );
		//
		//    ignore dynamic albums
		//
		if ( $album->isDynamic() || !$album->getID() )
			continue;
		if ( $args[ 'simplelist' ] )
			$list[ ] = entitysave( array(
				 'name' => $album->getTitle(),
				'id' => $album->getFolder(),
				'hasSubalbum' => hasSubAlbums( $album->getID() ),				
			) );
		else
			$list[ ] = entitysave( array(
				 'id' => $album->getID(),
				'name' => $album->getTitle(),
				'folder' => getFolderNode( $album->name ),
				'url' => WEBPATH . 'index.php?album=' . urlencode( $album->name ) . '/',
				'parentFolder' => $album->getParent()->name,
				'description' => $album->getDesc(),
				'location' => $album->getLocation(),
				'hasSubalbum' => hasSubAlbums( $album->getID() ),
				'albumpassword' => readZenPubData( $album->getID(), 'albumpassword' ),
				'show' => $album->getShow(),
				'commentson' => $album->getCommentsAllowed() 
			) );
	} //$allalbums as $albumfolder
	return $list;
}
/**
 *
 *    retrieve all images from an album
 *
 **/
function getAlbumImages( $args )
{
	global $_zp_current_image;
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'getAlbumImages', ( $args[ 'loglevel' ] ) );
	$albumobject = getItemByID( "albums", $args[ 'id' ] );
	$images      = $albumobject->getImages();
	if ( !( $albumobject || !$args[ 'id' ] ) )
		return new ZEN_Error( -1, 'No folder with database ID ' . $args[ 'id' ] . ' found!' );
	makeAlbumCurrent( $albumobject );
	$list = array( );
	while ( next_image( true ) ) {
		$meta = $_zp_current_image->getmetadata();
		if ( $meta[ 'EXIFDateTimeOriginal' ] )
			$imagedate = $meta[ 'EXIFDateTimeOriginal' ];
		else
			$imagedate = false;
		$list[ ] = entitysave( array(
			 'id' => $_zp_current_image->getID(),
			'albumid' => $_zp_current_image->getAlbum()->getID(),
			'name' => $_zp_current_image->filename,
			'shortdate' => date( "Y-m-d", ( strtotime( str_replace( " ", "", ( str_replace( ":", "", $imagedate ) ) ) ) ) ),
			'longdate' => $imagedate,
			'url' => WEBPATH . 'index.php?album=' . urlencode( $_zp_current_image->album->name ) . '&image=' . urlencode( $_zp_current_image->filename ) 
		) );
	} //next_image( true )
	//writelog((var_export($list, true)));
	return $list;
}
/**
 *
 *    retrive comments from image.
 *
 **/
function getImageComments( $args )
{
	global $_zp_current_image;
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'getImageComments', ( $args[ 'loglevel' ] ) );
	$imageobject = getItemByID( "images", $args[ 'id' ] );
	if ( $imageobject->filename )
		$comments = $imageobject->getComments();
	else
		return new ZEN_Error( -1, 'Image not found on server' );
	for ( $i = 0; $i < count( $comments ); ++$i ) {
		$x              = $i + 1;
		$commentList[ ] = entitysave( array(
			 'commentData' => $comments[ $i ][ "comment" ],
			'commentId' => $comments[ $i ][ "id" ],
			'commentDate' => strtotime( str_replace( ".000000", "", $comments[ $i ][ "date" ] ) ),
			'commentUsername' => $comments[ $i ][ "email" ],
			'commentRealname' => $comments[ $i ][ "name" ],
			'commentUrl' => $args[ "url" ] . "#zp_comment_id_" . $x 
		) );
	} //$i = 0; $i < count( $comments ); ++$i
	if ( empty( $commentList ) )
		return '';
	else
		return $commentList;
}
/**
 *
 *    add comments to image.
 *
 **/
function addImageComments( $args )
{
	global $_zp_current_album, $_zp_authority;
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'addImageComments', ( $args[ 'loglevel' ] ) );
	$imageobject = getItemByID( "images", $args[ 'id' ] );
	$userobj     = $_zp_authority->getAnAdmin( array(
		 'user=' => $args[ 'loginUsername' ],
		'valid=' => 1 
	) );
	$username    = $args[ 'loginUsername' ];
	$commentText = $args[ 'commentText' ];
	$date        = date( "Y-m-d H:m:s" );
	if ( $imageobject->filename )
		query( "INSERT INTO " . prefix( 'comments' ) . "(`ownerid`,`name`,`email`,`website`,`date`,`comment`,`type`,`IP`) VALUES ('" . $args[ 'id' ] . "','" . $username . "','" . $userobj->getEmail() . "','','" . $date . "','" . $commentText . "','images','" . $_SERVER[ 'REMOTE_ADDR' ] . "')" );
	else
		return new ZEN_Error( -1, 'Image not found on server ' . $obj[ 'filename' ] );
	return true;
}
/**
 *
 *    get ratings from image.
 *
 **/
function getImageRatings( $args )
{
	global $_zp_current_image;
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'getImageRatings', ( $args[ 'loglevel' ] ) );
	$imageobject = getItemByID( "images", $args[ 'id' ] );
	$rating      = getRating( $imageobject );
	if ( $imageobject->filename )
		return $rating;
	else
		return '0';
}
/**
 *
 *    get system version.
 *
 **/
function getsysVersion( $args )
{
	//if ( is_object( $login_state = authorize( $args ) ) )
	//return $login_state;
	//$args = decode64( $args );
	//logger( 'getversion', ( $args[ 'loglevel' ] ) );
	//	$readitems = query_full_array("SELECT id, `aux`, `data` FROM ".prefix('plugin_storage')." WHERE `type` = 'zenphotopublisher'");
	//$readitem = query_single_row($sql = "SELECT id, `aux`, `data` FROM ".prefix('plugin_storage')." WHERE `type` = 'zenphotopubliser' AND `aux` = ".db_quote(22));
	//$v = var_export( $readitem, true );
	return 'Zenphoto: ' . getversion() . ' running on PHP ' . phpversion();
}
/**
 *
 *    get album thumbnail.
 *
 **/
function getAlbumThumbnail( $args )
{
	global $_zp_current_album;
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'getAlbumThumbnail', ( $args[ 'loglevel' ] ) );
	$albumobject = getItemByID( "albums", $args[ 'id' ] );
	$albumthumb  = $albumobject->getAlbumThumbImage();
	//echo "<img src=\"".WEBPATH."/".ZENFOLDER."/i.php?a=".$albumthumb->name."&i=".$albumthumb->name."&s=75&cw=75&ch=75\"></a>\n<br />"; TODO
	return $albumthumb;
}
/**
 *
 *    upload a new image to the server
 *
 **/
function imageUpload( $args )
{
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'uploadJSON', ( $args[ 'loglevel' ] ) );
	if ( !( $album = getItemByID( "albums", $args[ 'id' ] ) ) )
		return new ZEN_Error( -1, 'No folder with database ID ' . $args[ 'id' ] . ' found!' );
	$filepath = getAlbumFolder() . ( $args[ 'parentFolder' ] ? $args[ 'parentFolder' ] . '/' : '' ) . $args[ 'folder' ];
	$filename = $args[ 'filename' ];
	$filepath = utf8_decode( $filepath );
	$filename = utf8_decode( $filename );
	// save file
	$fp       = fopen( $filepath . '/' . $filename, "wb" );
	fwrite( $fp, base64_decode( $args[ 'file' ] ) );
	fclose( $fp );
	$img = newImage( $album, $filename );
	addZenPubData( $args[ 'id' ], $img->filename . '=' . $args[ $img->filename ] );
	return entitysave( array(
		 'status' => 'success',
		'id' => $img->getID(),
		'name' => $img->filename,
		'url' => WEBPATH . 'index.php?album=' . urlencode( $img->album->name ) . '&image=' . urlencode( $img->filename ) 
	) );
}
/**
 *
 *Delete Image
 *
 **/
function deleteImage( $args )
{
	global $_zp_current_album, $_zp_current_image;
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'deleteImage', ( $args[ 'loglevel' ] ) );
	$imageobject = getItemByID( "images", $args[ 'id' ] );
	if ( $imageobject->filename ) {
		delZenPubData( $args[ 'id' ], $imageobject->filename );
		$imageobject->remove();
		
		return true;
	} //$imageobject->filename
	else {
		return new ZEN_Error( -1, 'Image not found on server ' . $obj[ 'filename' ] );
	}
}
/**
 *
 *Delete Album
 *
 **/
function deleteAlbum( $args )
{
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'deleteAlbum', ( $args[ 'loglevel' ] ) );
	$album = getItemByID( "albums", $args[ 'id' ] );
	if ( $album ) {
		$album->remove();
		delZenPubData( $args[ 'id' ], null, true );
		return true;
	} //$album
	else {
		return new ZEN_Error( -1, 'No folder with database ID ' . $args[ 'id' ] . ' found!' );
	}
}
/**
 *
 *Create Image
 *
 **/
function createAlbum( $args )
{
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'createAlbum', ( $args[ 'loglevel' ] ) );
	$gallery   = new Gallery();
	$folder    = sanitize_path( $args[ 'folder' ] );
	$uploaddir = $gallery->albumdir . internalToFilesystem( $folder );
	if ( is_dir( $uploaddir ) )
		return new ZEN_Error( -1, 'Album with folder "' . $folder . '" does already exists!' );
	else
		@mkdir_recursive( $uploaddir, CHMOD_VALUE );
	@chmod( $uploaddir, CHMOD_VALUE );
	$album = new Album( $gallery, $folder );
	if ( !$album->name )
		return new ZEN_Error( -1, 'Album could not be created ' . $args[ 'name' ] );
	$album->setTitle( $args[ 'name' ] );
	$album->save();
	return entitysave( array(
		 'id' => $album->getID(),
		'url' => WEBPATH . 'index.php?album=' . urlencode( $album->name ) . '/',
		'folder' => getFolderNode( $album->name ),
		'parentFolder' => $album->getParent() 
	) );
}
/**
 *Change Album
 **/
function changeAlbum( $args )
{
	global $_zp_current_album, $_zp_authority;
	if ( is_object( $login_state = authorize( $args ) ) )
		return $login_state;
	$args = decode64( $args );
	logger( 'changeAlbum', ( $args[ 'loglevel' ] ) );
	$albumobject = getItemByID( "albums", $args[ 'id' ] );
	if ( !( $album = $albumobject ) )
		return new ZEN_Error( -1, 'No folder with database ID ' . $args[ 'id' ] . ' found!' );
	$v = var_export( $args, true );
	debuglog( 'changeAlbum: ' . $v );
	//
	//    change album values
	//
	addZenPubData( $args[ 'id' ], 'albumpassword=' . $args[ 'albumpassword' ] );
	$_zp_authority = new Zenphoto_Authority();
	$album->setTitle( $args[ 'name' ] );
	$album->setDesc( nl2br( $args[ 'description' ] ) );
	$album->setLocation( $args[ 'location' ] );
	
	if ( ( $args[ 'albumpassword' ] ) == '' )
		$album->setPassword( '' );
	else
		$album->setPassword( $_zp_authority->passwordHash( $args[ 'albumpassword' ] ) );
	$album->setShow( $args[ 'show' ] );
	$album->setCommentsAllowed( $args[ 'commentson' ] );
	$album->save();
	//
	//    rename/move action
	//
	$newfolder = $args[ 'parentFolder' ] ? $args[ 'parentFolder' ] . '/' . $args[ 'folder' ] : $args[ 'folder' ];
	if ( $newfolder && $albumobject->name != $newfolder ) {
		logger( 'changeAlbum.rename action', ( $args[ 'loglevel' ] ) );
		$result = $albumobject->move( $newfolder );
		switch ( $result ) {
			case '1':
				return new ZEN_Error( -5, 'General change folder error!' );
			case '3':
				return new ZEN_Error( -5, 'There already exists an album or sub-album with this name' );
			case '4':
				return new ZEN_Error( -5, 'You canot make a sub-folder of the current folder' );
		} //$result
	} //$newfolder && $album->name != $newfolder
	$parent = $album->getParent();
	return entitysave( array(
		 'id' => $album->getID(),
		'name' => $album->getTitle(),
		'url' => WEBPATH . 'index.php?album=' . urlencode( $album->name ) . '/',
		'folder' => getFolderNode( $album->name ),
		'parentFolder' => ( $parent ? $parent->name : null ),
		'description' => $album->getDesc(),
		'location' => $album->getLocation(),
		//'albumpassword' => $album->getPassword(),
		'albumpassword' => readZenPubData( $album->getID(), 'albumpassword' ),
		'show' => $album->getShow(),
		'commentson' => $album->getCommentsAllowed() 
	) );
}

/**
 *
 *    Check if plugin is turned on.
 *
 **/
function checkFunc( $args )
{
$args = decode64( $args );
	debugLog( 'checkFunc' . var_export( $args, true ) );
return function_exists($args['getFunction']);
}

/**
 *
 *    test/debug system.
 *
 **/
function test( $args )
{
	//if ( is_object( $login_state = authorize( $args ) ) )
	//return $login_state;
	//$args = decode64( $args );
	//logger( 'getversion', ( $args[ 'loglevel' ] ) );
	return;
}

/**
 * Update check
 */
function updateCheck($args)
{
$args = decode64( $args );
	//logger( 'updateCheck', ( $args[ 'loglevel' ] ) );
	debugLog( 'updateCheck '.sysrpcversion);
	if (getOption('zenpublisher_update') == 1 && ($args['sysversion']  > sysrpcversion))
	return true;
return false;
}
?>
