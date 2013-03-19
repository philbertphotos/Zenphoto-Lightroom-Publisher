Zenphoto Lightroom Publisher
============================
Developed by Joseph Philbert based on Nick Jacobson (lokkju) changes originally developed by Lars Hagen (desgphoto)

A Lightroom 3 and 4 publishing service tool. The service gives you the possibility to sync Lightroom with your Zenphoto installation.

Today I like to introduce a updated plug-in for Lightroom 3 and 4 and uses the Lightroom publishing service that gives you the possibility to sync Lightroom with your Zenphoto installation – but in an intelligent and very easy to use way.

The new publishing service feature of Lightroom gives you the possibility to monitor and manage exported images on different web services. Whenever you make changes on published photos (e.g. change the image settings or some of the metadata in Lightroom), these photos will be monitored and marked, automatically. You can now republish all these photos with a single click.

Furthermore, whenever you add or remove photos from your published collections, they will be added or removed to your web server the next time you press the Lightroom "Publish" button. Please read the Lightroom documentation.

_**How does the service work?**_
After you have installed the service via the Lightroom "Plug-in Manager", you have to enter the host of your Zenphoto installation. In the next step press the login button and enter your username and the password. You must be a Zenphoto administrator to be able to login. All other Zenphoto accounts are not allowed to access the web service.

After you successfully logged-in you can sync with your already uploaded images. When pressing the "Sync Album" or the "Sync Photos" ?button, all Zenphoto albums will be read and created as collections as part of the "Lightroom 2 Zenphoto" service. Therefore the plug-in will connect to the web server and will gather information of your already uploaded albums and images (e.g. the album name, the filename and the URL).

This information is used to to find the images within your current active catalog. If an image was found, it will be assigned to the corresponding collection of the "Lightroom 2 Zenphoto" service.

Finally, you will get an infobox showing you the images which were not found in your current catalog but are available in your Zenphoto installation.

Once you have synced with your Zenphoto installation you can assign any image you like to an album (or – in Lightroom terminology – collection). When you now change any metadata of published images, these images will be automatically marked to be republished the next time you push the "Publish" button.

Please see the Lightroom 3 documentation for details on how it works.

**Installation**

The installation is very simple. The download comes as a ZIP-file which contains two directories:
ZenphotoPublisher.lrplugin? – is the Lightroom plug-in which must be installed from the Lightroom Plugin Manager
zp-lightroom - the web service which makes the interaction between Lightroom an Zenphoto possible. Please copy this directory as it is into the "PLUGIN" path of your Zenphoto installation. All communication between Lightroom and Zenphoto is done via XML-calls?:

IXR_Library.inc.php? – 3rd party PHP class to handle XML client/server communication (this class is also used e.g. by WordPress)
xmlprc.php – contains functions to access the Zenphoto-API, e.g. to read data and make any changes. The service will not write to the database via SQL. Any changes are made via Zenphoto-API calls. So it should be save in any way! Nevertheless, there are some SQL-statements used to get images and albums based on their stored database ID. Unfortunately, Zenphoto offers only the possibility to get this ID, e.g. via "getAlbumID", but offers no function to get an album or image by its ID :-(
xmlrpc_upload.php – receives multipart POST messages and stores the image. The received images will be temporarily saved in the ‘zp-lightroom’ directory. So please make sure that sufficient write permissions are available.

**Configuration?**
lr_publishing

Go to the Publish Service section of Lightroom and select the “Zenphoto Publisher”
Enter a name for the service (any string is possible)
Enter the URL of your Zenphoto server (without “http”)
Optional: if you have decided to change the default path of the web service you can enter a new path (without a trailing slash)
Press “Save” to create a new service
Open the Publish Service again and login (enter admin username and password)
lr_login
When the username and the password but also the given Zenphoto-URL and the path to the web service are correct you will see that you are logged-in.
The buttons “Sync Albums” and “Full Sync” are now enabled.
    “Sync Albums”? – will read information for all albums from your server and will create corresponding albums (in Lightroom terminology: collections) in Lightroom
    “Full Sync”? – will do the same as “Sync albums” but will also read information for all images from Zenphoto and assign them to Lightroom when the images are in your current catalog. (ATTENTION: Windows user please see Bugs and Limitation section below)?
Please close the Publishing Manager now
You should now be ready to work!

When you have created your service the first time you will need to make an initial sync with your Zenphoto web server. You can do this first sync via the buttons “Sync Albums” and “Full Sync” as explained above or via the special "Maintenance" ?collection.

This collection is created automatically, when you have started the service and cannot be removed. In fact it only exists for Windows users which might have problems with the syncing method explained in point (8).

Please note: all Lightroom collections will be removed when you press "Sync albums" or "Full sync" and the service will be initialized again. All unpublished images will be lost and have to be assigned to the albums again. But "Sync albums" or "Full sync" ?will not make any changes on the server side.

???Depending on your catalog size and the amount of images on your server the sync-procedure can take a while?. A progress bar will show you the status of your sync.

Once you have synced Lightroom and Zenphoto you will see a list of all you albums already published in Zenphoto and the albums will contain the images (under the assumption that the images on Zenphoto are available in your current active catalog, too). Now you are able to:
lz_publishinglist lr_menu??
    create, rename, delete or modify albums
    assign images to your albums
    remove images from your albums

The album creation and edit functionalities are very similar. A dialog as shown below pops-up and allows you to enter some general data as used to in Zenphoto.
lz_edit?
Provided functions
    two-way sync with all albums and images already installed on your Zenphoto installation
    create albums
    delete albums
    rename albums – change the album name, the album folder and start a manual sync of the album
    handle Zenphoto sub-albums (including rename and move, see: Limitations below)
    upload images
    delete images

Requirements
    Lightroom 3 and up (previous versions will not work)
    Zenphoto 1.4 and up

F.A.Q.

I get “Server could not be connected” but my settings are correct

This happens when your server settings are incorrect. Please make sure that ZenPhoto-URL only contains the server name and the webservice directory does contain the complete webpath. 
For example: when you have installed Zenphoto under ‘www.yoursystem.com/‘ then usually the zp-lightroom folder is then located under ‘www.yoursystem.com/plugins/zp-lightroom‘. The correct settings are now:

    ZenPhoto-URL: ‘www.yoursystem.com‘
    webservice directory: ‘/plugins/zp-lightroom‘

I have logged-in but cannot publish any photos
Please make sure that the zp-lightroom directory has write permissions. This is necessary for temporary files. If you cannot or wont make it writable then change the upload method to ‘XML data‘.

If you now have still problems then check the owner and the permissions of the photos that you want publish. In other words: you must be the owner of a photo that you want publish to the server. This problem can happen when you want “overwrite” an already existing photo on the server which has a different owner or not sufficient permissions.

I get the message ‘Unable to upload photo …’
See the point above. If you still have problems, then please try to change the “Upload method” to “XML data”.

My filenames contain an apostrophe and I cannot publish any photos

Please change the “Upload method” to “XML data”. Until now I couldn’t find any way to cast an apostrophe for the Multipart-POST, but “XML data” is working.
Changelog
*Bugs & Limitations*
Due to a bug in Lightroom, the Zenphoto sub-albums are not yet fully supported
Lightroom crashed sometimes when using the Sync buttons from inside the Publishing Manager. This seems to happen under Vista only, and is already announced as a bug to Adobe. I never have experienced catalog damages – but nevertheless: use it on your own risk. If you afraid problems then make use of the sync buttons from withing the “Maintenance” collection. This works in any case!
ATTENTION: do never ever make an album part of itself or of an containing sub-album. Usually, there should be fired an exception by Zenphoto, but it doesn’t happen… :-(
