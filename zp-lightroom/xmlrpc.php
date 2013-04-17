<?php

//
//	make sure that the WEBPATH is set to parent directory for correct URL values
//4.0.1
$dir = str_replace('\\', '/', realpath(dirname(__FILE__)));
define('SERVERPATH', str_replace('/plugins/zp-lightroom','',$dir));

require_once(SERVERPATH . '/zp-core/functions.php');
include_once(SERVERPATH . '/zp-core/template-functions.php');
require_once(SERVERPATH . '/zp-core/lib-auth.php');
include_once(SERVERPATH . '/plugins/zp-lightroom/IXR_Library.inc.php');

/* Create the server and map the XML-RPC method names to the relevant functions */
$server = new IXR_Server(array(
    'zenphoto.login' => 'authorize',
    'zenphoto.check' => 'checkConnection',
    'zenphoto.album.getList' => 'getAlbumList',
    'zenphoto.album.getImages' => 'getAlbumImages',
    'zenphoto.album.delete' => 'deleteAlbum',
    'zenphoto.album.create' => 'createAlbum',
    'zenphoto.album.edit' => 'changeAlbum',
    'zenphoto.image.delete' => 'deleteImage',
    'zenphoto.image.upload' => 'upload',
    'zenphoto.image.uploadXML' => 'uploadXML',
    'zenphoto.get.comments' => 'getImageComments',
    'zenphoto.get.ratings' => 'getImageRatings',
    'zenphoto.add.comment' => 'addImageComments'
));

/*******************************************************************************************************
 *
 *		General Helper functions
 *
 **/
function getFolderNode($foldername)
{
    return strrpos($foldername, '/') ? substr(strrchr($foldername, "/"), 1) : $foldername;
}
/**
 *	get all subalbums (if available)
 **/
function getSubAlbums($gallery, $album)
{
    $list = array();
    
    $albumObj = new Album($gallery, $album);
    $albumID  = $albumObj->getID();
    $parentID = getItemByID("albums", $albumID);
    
    if ($albumObj->isDynamic() || !$albumID)
        return $list;
    $subalbums = $albumObj->getAlbums();
    $subalbums = $parentID->getAlbums();
    
    if (is_array($subalbums)) {
        foreach ($subalbums as $subalbum) {
            $list[] = $subalbum;
            $list   = array_merge($list, getSubAlbums($gallery, $subalbum));
        }
    }
    return $list;
}

function entitysave($list)
{
    $tmp = array();
    
    if (is_array($list))
        foreach ($list as $key => $value)
            $tmp[$key] = new IXR_Base64(html_entity_decode($value, ENT_NOQUOTES, 'ISO8859-1'));
            //$tmp[$key] = new IXR_Base64(html_entity_decode($value));
    
    return $tmp;
}


function decode64($args)
{
    foreach ($args as $key => $value)
        $args[$key] = base64_decode($value);
    
    return $args;
}
/**
 * Returns the hash of the zenphoto password
 *
 * @param string $user
 * @param string $pass
 * @return string
 */
function passwordHash($user, $pass, $hash_type = NULL)
{
    if (is_null($hash_type)) {
        $hash_type = getOption('strong_hash');
    }
    switch ($hash_type) {
        case 1:
            $hash = sha1($user . $pass . HASH_SEED);
            break;
        case 2:
            $hash = base64_encode(pbkdf2($pass, $user . HASH_SEED));
            break;
        default:
            $hash = md5($user . $pass . HASH_SEED);
            break;
    }
    if (DEBUG_LOGIN) {
        debugLog("passwordHash($user, $pass, $hash_type)[{HASH_SEED}]:$hash");
    }
    return $hash;
}

/**
 * Returns an admin object from the $pat:$criteria
 * @param array $criteria [ match => criteria ]
 * @return Zenphoto_Administrator
 */
function getAnAdmin($criteria)
{
    $selector = array();
    foreach ($criteria as $match => $value) {
        if (is_numeric($value)) {
            $selector[] = $match . $value;
        } else {
            $selector[] = $match . db_quote($value);
        }
    }
    $sql   = 'SELECT * FROM ' . prefix('administrators') . ' WHERE ' . implode(' AND ', $selector) . ' LIMIT 1';
    $admin = query_single_row($sql, false);
    if ($admin) {
        return newAdministrator($admin['user'], $admin['valid']);
    } else {
        return NULL;
    }
}

/**
 * Instantiates and returns administrator object
 * @param $name
 * @param $valid
 * @return object
 */
function newAdministrator($name, $valid = 1)
{
    $user = new Zenphoto_Administrator($name, $valid);
    return $user;
}

function checkLogon($user, $pass)
{
    $userobj = getAnAdmin(array(
        '`user`=' => $user,
        '`valid`=' => 1
    ));
    if ($userobj) {
        $hash = passwordHash($user, $pass, $userobj->get('passhash'));
        if ($hash != $userobj->getPass()) {
            $userobj = NULL;
        }
    }
    
    if (DEBUG_LOGIN) {
        if ($userobj) {
            $rights = sprintf('%X', $userobj->getRights());
        } else {
            $rights = false;
        }
        debugLog(sprintf('checkLogon(%1$s, %2$s)->%3$s', $user, $hash, $rights));
    }
    //return $userobj;
    debugLog("userObject1: " . $userobj);
}

function encode_items($array)
{
    foreach($array as $key => $value)
    {
        if(is_array($value))
        {
            $array[$key] = encode_items($value);
        }
        else
        {
            $array[$key] = mb_convert_encoding($value, 'ISO-8859-1');
        }
    }

    return $array;
}

function logger($string, $loglevel) {

 switch ($loglevel) {
        case 'debug':
            debugLog('DEBUG: '.$string);
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
    }
}
/*******************************************************************************************************
 *
 * Functions defining the behaviour of the server 
 *
 **/

/**
 *	authorize user
 **/
function authorize($args)
{
    global $_zp_authority;
    
    $args = decode64($args);
    if (!preg_match('#^1.4#', ($version = getVersion())))
        return new IXR_Error(-2, 'Zenphoto version ' . $version . ' but v1.4.x required!');
    
    $_zp_authority = new Zenphoto_Authority();
    
    $hash    = $_zp_authority->passwordHash($args['loginUsername'], $args['loginPassword']);
    $userobj = getAnAdmin(array(
        '`user`=' => $args['loginUsername'],
        '`valid`=' => 1
    ));
    /**

	debugLog("login hash: ".$hash);
    debugLog("userObject: ".$userobj);
    
    $hashcheck = getAnAdmin(array('`user`=' => $args['loginUsername'], '`valid`=' => 1));
    debugLog("check hash: ".$userobj->get('passhash'));
    $hash_type = getOption('strong_hash');
    debugLog("Hashtype: " .$hash_type); 
    debugLog("Hashcheck: " .$hashcheck);
    **/
    
    if ($userobj) {
        return true;
    } else {
        return new IXR_Error(-1, 'Incorrect username or password ' . $args['loginUsername'] . ' ' . $args['loginPassword']);
    }
}

/**
 *
 *getalbum List
 **/
function getAlbumList($args)
{
    //logger('getAlbumList',($args['debugLog']));
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args = decode64($args);
    
    $gallery   = new Gallery();
    $albums    = $gallery->getAlbums();
    //
    //	gather all names of the albums, including sub-albums
    //
    $allalbums = array();
    
    if (is_array($albums))
        foreach ($albums as $album) {
            $allalbums[] = $album;
            
            foreach (getSubAlbums($gallery, $album) as $sub)
                $allalbums[] = $sub;
        }
    
    //
    //	create album objects and get needed values
    //
    foreach ($allalbums as $albumfolder) {
        $album = new Album($gallery, $albumfolder);
        
        //
        //	ignore dynamic albums
        //
        if ($album->isDynamic() || !$album->getID())
            continue;
        
        if ($args['simplelist'])
            $list[] = entitysave(array(
                'name' => $album->getTitle(),
                'id' => $album->getFolder()
            ));
        else
            $list[] = entitysave(array(
                'id' => $album->getID(),
                'name' => $album->getTitle(),
                'folder' => getFolderNode($album->name),
                'url' => WEBPATH . 'index.php?album=' . urlencode($album->name) . '/',
                'parentFolder' => $album->getParent()->name,
                'description' => $album->getDesc(),
                'location' => $album->getLocation(),
                //'password' => $album->getPassword(),
                'show' => $album->getShow(),
                'commentson' => $album->getCommentsAllowed()
            ));
    }
	debuglog(var_export($list, true));
    return $list;
}


/**
 *
 *	retrieve all images from an album
 *
 **/
 	function getAlbumForAlbumID($id) {
//$row = query_single_row('SELECT folder FROM '.prefix("albums").' WHERE id='.$id.' LIMIT 1', true);
$row = getItemByID("albums",($id));

if (!$row['folder'])
return null;

$album = new Album(new Gallery(), $row['folder']);
makeAlbumCurrent($album);
return $album;
}

function getAlbumImages($args)
{
    global $_zp_current_image;
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args = decode64($args);
    
	//$albumobject = getItemByID("albums", $args['Id']);
	//debugLog('getAlbumImages: '. $albumobject);
    if (!($album = getAlbumForAlbumID($args['id'])) || !$args['id'])
    //if (!($album = getItemByID("albums",($args['id']))) || !$args['id'])
    //if (!($albumobject || !$args['id']))
        return new IXR_Error(-1, 'No folder with database ID ' . $args['id'] . ' found!');
    
    $list = array();
    while (next_image(true))
        $list[] = entitysave(array(
            'id' => $_zp_current_image->getID(),
            'name' => $_zp_current_image->filename,
            'url' => WEBPATH . 'index.php?album=' . urlencode($_zp_current_image->album->name) . '&image=' . urlencode($_zp_current_image->filename)
        ));
    
    return $list;
}

/**
 *
 *	retrive comments from image.
 *
 **/
function getImageComments($args)
{
    global $_zp_current_image;
    //$v = var_export($args, true);
    //debuglog ('getImageComments');	
    //debuglog ($v);
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args        = decode64($args);
    $imageobject = getItemByID("images", $args['Id']);
    if ($imageobject->filename)
        $comments = $imageobject->getComments();
    else
        return new IXR_Error(-1, 'Image not found on server ' . $obj['filename']);
    
    for ($i = 0; $i < count($comments); ++$i) {
        $x             = $i + 1;
        $commentList[] = entitysave(array(
            'commentData' => $comments[$i]["comment"],
            'commentId' => $comments[$i]["id"],
            'commentDate' => strtotime(str_replace(".000000", "", $comments[$i]["date"])),
            'commentUsername' => $comments[$i]["email"],
            'commentRealname' => $comments[$i]["name"],
            'commentUrl' => $args["url"] . "#zp_comment_id_" . $x
            
        ));
    }
    return $commentList;
}
/**
 *
 *	add comments to image.
 *
 **/
function addImageComments($args)
{
    global $_zp_current_image;
    
    $v = var_export($args, true);
    debuglog('addImageComments');
    debuglog($v);
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args        = decode64($args);
    $imageobject = getItemByID("images", $args['Id']);
    $username    = $args['loginUsername'];
    $commentText = $args['commentText'];
    if ($imageobject->filename)
        $postcomment = $imageobject->addComment($username, 'jj@jj.com', '', $commentText, '', '', '', '', '', '');
    //debugLog('addcomment bool: ' . $postcomment);
    //object addComment( string $name, string $email, string $website, string $comment, string $code, string $code_ok, string $ip, bool $private, bool $anon  )
    
    else
        return new IXR_Error(-1, 'Image not found on server ' . $obj['filename']);
    
    return $postcomment;
}
/**
 *
 *	get ratings from image.
 *
 **/
function getImageRatings($args)
{
    global $_zp_current_image;
    
    $v = var_export($args, true);
    debuglog('getImageRatings');
    debuglog($v);
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    $args        = decode64($args);
    $imageobject = getItemByID("images", $args['Id']);
    
    if (!$imageobject)
        $rating = getRating($imageobject);
    else
        return new IXR_Error(-1, 'Image not found on server ' . $obj['filename']);
    
    return $rating;
}
/**
 *
 *	upload a new image to the server
 *
 **/
function uploadXML($args)
{
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args = decode64($args);
    
    if (!($album = getItemByID("images", $args['Id'])))
        return new IXR_Error(-1, 'No folder with database ID ' . $args['id'] . ' found!');
    
    
    $filepath = getAlbumFolder() . ($args['parentFolder'] ? $args['parentFolder'] . '/' : '') . $args['folder'];
    $filename = $args['filename'];
    $filepath = utf8_decode($filepath);
    $filename = utf8_decode($filename);
    
    
    // save file
    $fp = fopen($filepath . '/' . $filename, "wb");
    fwrite($fp, base64_decode($args['file']));
    fclose($fp);
    
    $img = newImage($album, $filename);
    
    return entitysave(array(
        'status' => 'success',
        'id' => $img->getID(),
        'name' => $img->filename,
        'url' => WEBPATH . 'index.php?album=' . urlencode($img->album->name) . '&image=' . urlencode($img->filename)
    ));
}


/**
 *
 *	upload a new image to the server
 *
 **/
function upload($args)
{
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args = decode64($args);
    
    //if (!($album = getAlbumForAlbumID($args['id'])))
    if (!($album = getItemByID("albums", $args['Id'])))
        return new IXR_Error(-1, 'No folder with database ID ' . $args['id'] . ' found!');
    
    $filepath = getAlbumFolder() . ($args['parentFolder'] ? $args['parentFolder'] . '/' : '') . $args['folder'];
    $filename = $args['filename'];
    
    $filepath = utf8_decode($filepath);
    $filename = utf8_decode($filename);
    
    if (!file_exists($filename))
        return new IXR_Error(-50, 'Image upload error of file: ' . $filename);
    
    if (!file_exists($filepath))
        return new IXR_Error(-50, 'Album does not exists: ' . $filepath);
    
    // check if the photo is part of a stack
    //	$stackedfilename = $args['stackposition'] ? preg_replace('#(.jpg|.tif|.dng|.png|.gif)(.*)#i','-Stack'.$args['stackposition'].'$1',$filename) : $filename;
    $stackedfilename = $filename;
    
    if (!copy($filename, $filepath . '/' . $filename))
        return new IXR_Error(-50, 'Photo ' . $filename . ' could not be copied to album: ' . $filepath);
    
    @unlink($filename);
    
    
    
    $img = newImage($album, $filename);
    
    return entitysave(array(
        'status' => 'success',
        'id' => $img->getID(),
        'name' => $img->filename,
        'url' => WEBPATH . 'index.php?album=' . urlencode($img->album->name) . '&image=' . urlencode($img->filename)
    ));
}


/**
 *
 *Delete Image
 *
 **/
function deleteImage($args)
{
    global $_zp_current_album, $_zp_current_image;
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    $args        = decode64($args);
    $imageobject = getItemByID("images", $args['Id']);
    if ($imageobject->filename)
        $imageobject->remove();
    else
        return new IXR_Error(-1, 'Image not found on server ' . $obj['filename']);
}

/**
 *
 *Delete Album
 *
 **/
function deleteAlbum($args)
{
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args  = decode64($args);
    $album = getItemByID("albums", $args['Id']);
    if ($album)
        $album->remove();
    else
        return new IXR_Error(-1, 'No folder with database ID ' . $args['id'] . ' found!');
    
    
}


/**
 *
 *Create Image
 *
 **/
function createAlbum($args)
{
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args = decode64($args);
    
    $gallery = new Gallery();
    
    $folder    = sanitize_path($args['folder']);
    $uploaddir = $gallery->albumdir . internalToFilesystem($folder);
    
    if (is_dir($uploaddir))
        return new IXR_Error(-1, 'Album with folder "' . $folder . '" does already exists!');
    else
        @mkdir_recursive($uploaddir, CHMOD_VALUE);
    
    @chmod($uploaddir, CHMOD_VALUE);
    
    $album = new Album($gallery, $folder);
    
    if (!$album->name)
        return new IXR_Error(-1, 'Album could not be created ' . $args['name']);
    
    $album->setTitle($args['name']);
    $album->save();
    
    return entitysave(array(
        'id' => $album->getID(),
        'url' => WEBPATH . 'index.php?album=' . urlencode($album->name) . '/',
        'folder' => getFolderNode($album->name),
        'parentFolder' => $album->getParent()
    ));
}


/**
 *Change Album
 **/
function changeAlbum($args)
{
    debuglog('fuction-changeAlbum');
    global $_zp_current_album, $_zp_authority;
    
    if (is_object($login_state = authorize($args)))
        return $login_state;
    
    $args        = decode64($args);
    $albumobject = getItemByID("albums", $args['id']);
    if (!($album = $albumobject))
        return new IXR_Error(-1, 'No folder with database ID ' . $args['id'] . ' found!');
    //$v = var_export($args, true);
    //debuglog ($v);
    //
    //	change album values
    //
    $_zp_authority = new Zenphoto_Authority();
    
    $album->setTitle($args['name']);
    $album->setDesc(nl2br($args['description']));
    $album->setLocation($args['location']);
    //$album->setPassword($_zp_authority->passwordHash($args['password']));
    $album->setShow($args['show']);
    $album->setCommentsAllowed($args['commentson']);
    
    //$v = var_export($key, true);
    debuglog('changealbum-key');
    //debuglog ($v);
    $album->save();
    //
    //	rename action
    //
    $newfolder = $args['parentFolder'] ? $args['parentFolder'] . '/' . $args['folder'] : $args['folder'];
    if ($newfolder && $album->name != $newfolder) {
        $result = $album->moveAlbum($newfolder);
        switch ($result) {
            case '1':
                return new IXR_Error(-5, 'General change folder error!');
            case '3':
                return new IXR_Error(-5, 'There already exists an album or sub-album with this name');
            case '4':
                return new IXR_Error(-5, 'You canot make a sub-folder of the current folder');
        }
    }
    
    $parent = $album->getParent();
    return entitysave(array(
        'id' => $album->getID(),
        'name' => $album->getTitle(),
        'url' => WEBPATH . 'index.php?album=' . urlencode($album->name) . '/',
        'folder' => getFolderNode($album->name),
        'parentFolder' => ($parent ? $parent->name : null),
        'description' => $album->getDesc(),
        'location' => $album->getLocation(),
        //'password' => $album->getPassword(),
        'show' => $album->getShow(),
        'commentson' => $album->getCommentsAllowed()
        //'ratingsson' => $album->getRatingAllowed()
    ));
}
?>
