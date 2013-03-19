<?php

//
//	make sure that the WEBPATH is set to parent directory for correct URL values
//
$dir = str_replace('\\', '/', realpath(dirname(__FILE__)));
define('SERVERPATH', strstr($dir, '/plugins/zp-lightroom', true));

require_once(SERVERPATH . '/zp-core/functions.php');
include_once(SERVERPATH . '/zp-core/template-functions.php');
require_once(SERVERPATH . '/zp-core/lib-auth.php');
include_once(SERVERPATH . '/plugins/zp-lightroom/IXR_Library.inc.php');

/* Create the server and map the XML-RPC method names to the relevant functions */
$server = new IXR_Server(array(
	'zenphoto.login' 			=> 'authorize',
	'zenphoto.check' 			=> 'checkConnection',
    'zenphoto.album.getList' 	=> 'getAlbumList',
    'zenphoto.album.getImages' 	=> 'getAlbumImages',
    'zenphoto.album.delete' 	=> 'deleteAlbum',
    'zenphoto.album.create' 	=> 'createAlbum',
    'zenphoto.album.edit' 		=> 'changeAlbum',
    'zenphoto.image.delete' 	=> 'deleteImage',
    'zenphoto.image.upload' 	=> 'upload',
    'zenphoto.image.uploadXML' 	=> 'uploadXML',
	));


/*******************************************************************************************************
 *
 *		MySQL Helper functions (read only!!!)
 *
 **/
	function getAlbumForAlbumID($id) {
		$row = query_single_row('SELECT folder FROM '.prefix("albums").' WHERE id='.$id.' LIMIT 1', true);

		if (!$row['folder'])
			return null;

		$album = new Album(new Gallery(), $row['folder']);
		makeAlbumCurrent($album);
		return $album;
	}

	function getImageForImageID($id) {
		$row = query_single_row('SELECT '.prefix("images").'.id, '.prefix("images").'.filename, '.prefix("albums").'.folder FROM
								'.prefix("images").' LEFT JOIN '.prefix("albums").' ON '.prefix("images").'.albumId = '.prefix("albums").'.id
								WHERE
								'.prefix("images").'.id='.$id, true);

		$album = new Album(new Gallery(),$row['folder']);
		return new _Image($album, $row['filename']);
	}

	function getAlbumsFromDB($gallery, $parentid = null) {
		if (!$parentid)
			return query_full_array('SELECT folder FROM '.prefix('albums').' WHERE parentid is null ORDER BY id', true);
		else
			return query_full_array('SELECT folder FROM '.prefix('albums').' WHERE parentid = '.$parentid.' ORDER BY id', true);
	}


/*******************************************************************************************************
 *
 *		General Helper functions
 *
 **/
	function getFolderNode($foldername) {
		return strrpos($foldername, '/') ? substr (strrchr ($foldername, "/"), 1) : $foldername;
	}
	
	/**
	 *	get all subalbums (if available)
	 **/
	 function getSubAlbums($gallery, $album) {
		$list = array();

		$albumObj = new Album($gallery, $album);

		if ($albumObj->isDynamic() || !$albumObj->getID())
			return $list;
		
	//	$subalbums = $albumObj->getAlbums(0);
		$subalbums = getAlbumsFromDB($gallery, $albumObj->getID());

		if (is_array($subalbums)) {
			foreach ($subalbums as $subalbum) {
				$list[] = $subalbum['folder'];
				$list = array_merge($list, getSubAlbums($gallery, $subalbum['folder']));
			}
		}
		return $list;
	}

	function entitysave($list) {
		$tmp = array();
		
		if (is_array($list))
			foreach ($list as $key=>$value)
				$tmp[$key] = new IXR_Base64(html_entity_decode($value));
			
		return $tmp;
	}


	function decode64($args) {
		foreach($args as $key=>$value)
			$args[$key] = base64_decode($value);

		return $args;
	}


/*******************************************************************************************************
 *
 * Functions defining the behaviour of the server 
 *
 **/

/**
 *	first authorize
 **/
 function authorize($args) {
	global $_zp_authority;

	$args = decode64($args);

	if (!preg_match('#^1.4#', ($version = getVersion())))
		return new IXR_Error(-2, 'Zenphoto version '.$version.' but v1.4.x required!');

	$_zp_authority = new Zenphoto_Authority();

	$hash = $_zp_authority->passwordHash($args['loginUsername'], $args['loginPassword']);
	$userobj = $_zp_authority->getAnAdmin(array('`user`=' => $args['loginUsername'], '`pass`=' => $hash, '`valid`=' => 1));
	if($userobj) {
		return true;
	} else {
		return new IXR_Error(-1, 'Incorrect username or password '.$args['loginUsername'].' '.$args['loginPassword']);
	}
}
 
 
/**
 *
 *
 **/
function getAlbumList($args) {

	if (is_object($login_state = authorize($args)))	return $login_state;

	$args = decode64($args);

	$gallery = new Gallery();
	$albums = getAlbumsFromDB($gallery);
	
	//
	//	gather all names of the albums, including sub-albums
	//
	$allalbums = array();

	if (is_array($albums))
		foreach ($albums as $album) {
			$allalbums[] = $album['folder'];

			foreach (getSubAlbums($gallery, $album['folder']) as $sub)
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
					 'url' => WEBPATH.'index.php?album='.urlencode($album->name).'/',
			'parentFolder' => $album->getParent()->name,
			 'description' => $album->getDesc(),
				'location' => $album->getLocation(),
				'password' => $album->getPassword(),
					'show' => $album->getShow(),
			  'commentson' => $album->getCommentsAllowed()
				));
	}
	return $list;
}


/**
 *
 *	retrieve all images from an album
 *
 **/
function getAlbumImages($args) {
	global $_zp_current_image;
	
	if (is_object($login_state = authorize($args)))	return $login_state;

	$args = decode64($args);

	if (!($album = getAlbumForAlbumID($args['id'])) || !$args['id'])
		return new IXR_Error(-1, 'No folder with database ID '.$args['id'].' found!');

	$list = array();
	while (next_image(true)) 
		$list[] = entitysave(array(
			'id' => $_zp_current_image->getID(),
			'name' => $_zp_current_image->filename,
			'url' => WEBPATH.'index.php?album='.urlencode($_zp_current_image->album->name).'&image='.urlencode($_zp_current_image->filename)
		));

	return $list;
}
 
 
/**
 *
 *	upload a new image to the server
 *
 **/
function uploadXML($args) {
	
	if (is_object($login_state = authorize($args)))	return $login_state;

	$args = decode64($args);

	if (!($album = getAlbumForAlbumID($args['id'])))
		return new IXR_Error(-1, 'No folder with database ID '.$args['id'].' found!');

			
	$filepath = getAlbumFolder().($args['parentFolder'] ? $args['parentFolder'].'/' : '').$args['folder'];
	$filename = $args['filename'];
	$filepath= utf8_decode($filepath);
	$filename = utf8_decode($filename);


	// save file
	$fp = fopen( $filepath.'/'.$filename, "wb" ); 
	fwrite( $fp, base64_decode( $args['file'] ) ); 
	fclose( $fp ); 

	$img = newImage($album, $filename);

	return entitysave(array(
		'status' => 'success',
			'id' => $img->getID(),
		  'name' => $img->filename,
		   'url' => WEBPATH.'index.php?album='.urlencode($img->album->name).'&image='.urlencode($img->filename)
		));
}


/**
 *
 *	upload a new image to the server
 *
 **/
function upload($args) {
	
	if (is_object($login_state = authorize($args)))	return $login_state;

	$args = decode64($args);

	if (!($album = getAlbumForAlbumID($args['id'])))
		return new IXR_Error(-1, 'No folder with database ID '.$args['id'].' found!');

	$filepath = getAlbumFolder().($args['parentFolder'] ? $args['parentFolder'].'/' : '').$args['folder'];
	$filename = $args['filename']; 

	$filepath= utf8_decode($filepath);
	$filename = utf8_decode($filename);

	if (!file_exists($filename))
		return new IXR_Error(-50, 'Image upload error of file: '.$filename);

	if (!file_exists($filepath))
		return new IXR_Error(-50, 'Album does not exists: '.$filepath);

	// check if the photo is part of a stack
//	$stackedfilename = $args['stackposition'] ? preg_replace('#(.jpg|.tif|.dng|.png|.gif)(.*)#i','-Stack'.$args['stackposition'].'$1',$filename) : $filename;
	$stackedfilename = $filename;

	if (!copy($filename, $filepath.'/'.$filename))
		return new IXR_Error(-50, 'Photo '.$filename.' could not be copied to album: '.$filepath);
	
	@unlink($filename);


	
	$img = newImage($album, $filename);
	
	return entitysave(array(
		'status' => 'success',
			'id' => $img->getID(),
		  'name' => $img->filename,
		   'url' => WEBPATH.'index.php?album='.urlencode($img->album->name).'&image='.urlencode($img->filename)
		));
}


/**
 *
 *
 *
 *
 **/
function deleteImage($args) {
	global $_zp_current_album, $_zp_current_image;
	
	if (is_object($login_state = authorize($args)))	return $login_state;

	$args = decode64($args);

	$img = getImageForImageID($args['id']);

	if ($img->filename)
		$img->remove();
	else
		return new IXR_Error(-1, 'Image not found on server '.$obj['filename']);
}


/**
 *
 *
 *
 *
 **/
function deleteAlbum($args) {
	
	if (is_object($login_state = authorize($args)))	return $login_state;
	
	$args = decode64($args);
	
	if (!($album = getAlbumForAlbumID($args['id'])))
		return new IXR_Error(-1, 'No folder with database ID '.$args['id'].' found!');

	$album->deleteAlbum();
}


/**
 *
 *
 *
 *
 **/
function createAlbum($args) {
	
	if (is_object($login_state = authorize($args)))	return $login_state;

	$args = decode64($args);

	$gallery = new Gallery();
	
	$folder = sanitize_path($args['folder']);
	$uploaddir = $gallery->albumdir . internalToFilesystem($folder);

	if (is_dir($uploaddir))
		return new IXR_Error(-1, 'Album with folder "'.$folder.'" does already exists!');
	else
		@mkdir_recursive($uploaddir, CHMOD_VALUE);

	@chmod($uploaddir, CHMOD_VALUE);
	
	$album = new Album( $gallery, $folder);

	if (!$album->name)
		return new IXR_Error(-1, 'Album could not be created '.$args['name']);

	$album->setTitle($args['name']);
	$album->save();
	
	return entitysave(array (
				  'id' => $album->getID(),
				 'url' => WEBPATH.'index.php?album='.urlencode($album->name).'/',
			  'folder' => getFolderNode($album->name),
		'parentFolder' => $album->getParent()->name
	));
}


/**
 *
 *
 *
 *
 **/
function changeAlbum($args) {
	global $_zp_current_album;
	
	if (is_object($login_state = authorize($args)))	return $login_state;

	$args = decode64($args);

	if (!($album = getAlbumForAlbumID($args['id'])))
		return new IXR_Error(-1, 'No folder with database ID '.$args['id'].' found!');


	//
	//	change album values
	//
	foreach($args as $key=>$value)
	global $_zp_authority;
	$_zp_authority = new Zenphoto_Authority();

	switch($key) {
			case 'name':		$album->setTitle($value); break;
			case 'description':	$album->setDesc(base64_decode($value)); break;
		    case 'location':	$album->setLocation(base64_decode($value)); break;
		    case 'password':	$album->setPassword($_zp_authority->passwordHash($value)); break;
			case 'show':		$album->setShow($value); break;
			case 'commentson':	$album->setCommentsAllowed($value); break;
		}
	$album->save();
	

	//
	//	rename action
	//
	$newfolder = $args['parentFolder'] ? $args['parentFolder'].'/'.$args['folder'] : $args['folder'];
	if ($newfolder && $album->name != $newfolder)
	{
		$result = $album->moveAlbum( $newfolder );
		switch($result) {
			case '1':	return new IXR_Error(-5, 'General change folder error!');
			case '3':	return new IXR_Error(-5, 'There already exists an album or sub-album with this name');
			case '4':	return new IXR_Error(-5, 'You canot make a sub-folder of the current folder');
		}
	}
	
	$parent = $album->getParent();
	return entitysave(array (
				  'id' => $album->getID(),
				'name' => $album->getTitle(),
				 'url' => WEBPATH.'index.php?album=' . urlencode($album->name). '/',
			 'folder'  => getFolderNode($album->name),
		'parentFolder' => ($parent ? $parent->name : null),
		 'description' => $album->getDesc(),
		    'location' => $album->getLocation(),
			'password' => $album->getPassword(),
				'show' => $album->getShow(),
		  'commentson' => $album->getCommentsAllowed()
	));
	
}

?>