<?php
/**
 * 
This is a Lightroom 3 and 4 publishing service plugin, it gives you the ability to sync Lightroom with your Zenphoto installation.

The Lightroom publishing service that gives you the possibility to sync Lightroom with your Zenphoto installation – but in an intelligent and very easy to use way. 
 * @package plugins
 */

//$plugin_is_filter = 5|CLASS_PLUGIN;

$plugin_author = "Joseph Philbert";
$plugin_version = '4.5.0.20130526';
$plugin_URL = 'http://philbertphotos.github.com/Zenphoto-Lightroom-Publisher';
$plugin_description = gettext("This is a Lightroom 3 and 4 publishing service plugin, it gives you the ability to sync Lightroom with your Zenphoto installation.
The Lightroom publishing service that gives you the possibility to sync Lightroom with your Zenphoto installation – but in an intelligent and very easy to use way. ");

/*
Plugin options.
*/
$option_interface = 'ZenPublisherOptions';
/**
 * Plugin option handling class
 *
 */
class ZenPublisherOptions {
  /**
* Handles custom formatting of options for Admin
*
* @param string $option the option name of the option to be processed
* @param mixed $currentValue the current value of the option (the "before" value)
*/
	function ZenPublisherOptions() {
		setOptionDefault('zenpublisher_phperror', 0);
		setOptionDefault('zenpublisher_update', 1);
	}
	

	function getOptionsSupported() {
		return array(										
 			gettext('Display PHP Error Notices') => array(
			'key' => 'zenpublisher_phperror',
			'type' => 5,
			'selections' => array(
			gettext('ON') => 1,
			gettext('OFF') => 0
			),
			'desc' => gettext('Error_reporting ( E_ERROR | E_PARSE ) turn on for debuggin only may cause the RPC to fail(off by default)')											
			), 			
			gettext('Updated PHP RPC') => array(
			'key' => 'zenpublisher_update',
			'type' => 5,
			'selections' => array(
			gettext('YES') => 1,
			gettext('NO') => 0
			),
			'desc' => gettext('Enable or Disable the updating of the RPC file')											
			),
		);
	}		
	function handleOption($option, $currentValue) {
}
}
/**
 * Update check
 */
function updateRPC( $gitbranch )
{
	//debugLog( 'updateCheck' . var_export( $args, true ) );
	$updatebase = "https://raw.github.com/philbertphotos/Zenphoto-Lightroom-Publisher/".$gitbranch."/plugins/ZenPublisher/ZenRPC.php";
	$self       = "./ZenPublisher/ZenRPC.php";
	$contents   = @file_get_contents( $updatebase );
	
	//$fp = @fopen( $self, 'w' );
     if ($fp = @fopen($self, 'w')) {
    //$info = $content; 
	if (fwrite($fp, $contents)) {
      return true;
    }
    fclose($fp);
  }
  return false;

}

function outputcomm( $result )
{
	$result = json_encode( $result );
	header( 'Connection: close' );
	header( 'Content-Type: application/json; charset=UTF-8' );
	header( 'Date: ' . date( 'r' ) );
	echo trim( $result );
	exit;
}
$task =& $HTTP_RAW_POST_DATA ;
$taskbits = explode( "=", $task );
//echo getOption('zenpublisher_update');
if (!empty ($taskbits[0]))
outputcomm($taskbits[ 0 ]( $taskbits[ 1 ].$c) );
?>


