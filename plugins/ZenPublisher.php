<?php
/**
 * 
This is a Lightroom 3 and 4 publishing service plugin, it gives you the ability to sync Lightroom with your Zenphoto installation.

The Lightroom publishing service that gives you the possibility to sync Lightroom with your Zenphoto installation – but in an intelligent and very easy to use way. 
 * @package plugins
 */

$plugin_is_filter = 5|CLASS_PLUGIN;

$plugin_author = "Joseph Philbert";
$plugin_version = ' .n/a';
$plugin_URL = 'http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher';
$plugin_description = gettext("This is a Lightroom 3 and 4 publishing service plugin, it gives you the ability to sync Lightroom with your Zenphoto installation.
The Lightroom publishing service that gives you the possibility to sync Lightroom with your Zenphoto installation – but in an intelligent and very easy to use way. ");

zp_register_filter('load_request', 'forceAlbum');

function forceAlbum($success) {

return $success;
}
?>