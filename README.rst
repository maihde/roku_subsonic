Introduction
------------
This software is a ROKU front-end to the Subsonic media streaming server.  It
provides the following features:
 * Browse your entire catalog
 * Search for artists, albums, songs
 * Full catalog shuffle playback
 * Quick browse of Subsonic album lists (Random, Recent, Top Rated, etc.)

Tested on Roku firmware version 2.9.

Please provide feedback: https://github.com/inbox/new/maihde

Install this channel: https://owner.roku.com/add/X2NAU4

Release Notes
~~~~~~~~~~~~~

1.3.0 - COMING SOON
'''''''''''''''''''''

 * Request properly scaled images from the Subsonic server to avoid slow response when
   viewing folders (artists) with a large number of albums

1.2.0 - 28th Sep 2011
'''''''''''''''''''''

 * Searches that return no results display a message instead of an empty results screen
 * Improved the functionality of "Test Connection" on settings screen
 * Auto-test the connectivity to the server on startup
 * Port 4040 is used by default unless a port is specified for the server address setting
 * Screensaver shows album art when playing music
 * Pressing the "back" button on the remote takes you to the start of the song; pressing again takes you back to the 
   previous song (i.e. CD-player functionality)
 
1.1.0 - 9th July 2011
'''''''''''''''''''''

 * Fix issue where "Play Queue" screen did not show album/artist information
 * Display progress bar while playing songs
 * Add Next/Prev buttons to the playback screen menu (remote left/right arrows retain the same behavior for skipping as in 1.0 release)
 * Remove the star-rating item from the playback screen since Subsonic doesn't provide support for that over the API
 * Added extra guidance to the server address configuration screen
 * Reduce the number of shuffled songs to fetch at one time to 20 instead of 100.  This improves response times when selecting shuffle

1.0.0 - 29th May 2011
'''''''''''''''''''''

 * First published release
 * Provided basic functionality including:
   * Ablity to browse and play albums from your music collection
   * Continuous shuffle of your entire music collection
   * Search your collection for artists, albums, and songs
   * Quick access to subsonic album lists (Random, Recent, Top Rated, etc.)

Credits
-------
Icons from Emre Ozcelik's "Elegant Blue Web" icon set
    http://www.iconfinder.com/search/?q=iconset%3Aellegant

Various bug-fixes and enhancements from Mark Leone.

Known Issues
------------
1. Transcoded files play only a portion of the file; this is because when the roku
   does not receive a content-length response, it will use partial transfer requests
   and it expects a 416 response code to indicate that the partial request has 
   reached the end of the file.  Subsonic does not send a 416 response code,
   causing the roku to abort playback.  See this link for the patch information:

   http://www.activeobjects.no/subsonic/forum/viewtopic.php?p=26893#26893 

   UPDATE - Subsonic 4.6.beta1 appears to have resolved this issue

2. roGridScreen doesn't cooperate with roAudioPlayer running in the background.
   If the roAudioPlayer sends an event while the grid screen is visible, the 
   album artwork get's scaled funny; this odd GridScreen behavior is in addition
   to the typical issues with roGridScreen that prevent normal stacking behavior.

3. When returning from the search roGridScreen to the main roGridScreen, a small
   delay must manually be introduced, otherwise the main grid screen get's corrupted.

4. Music must be organized in Artist/Album/Songs directory structure.

TODO
----

Version 1.3 - Goal Nov 30
~~~~~~~~~~~~~~~~~~~~~~~~~
#. If Subsonic API 1.6 is available, provide rating controls on springboard and use setRating API to update rating on Subsonic
#. Add support to browse and play Subsonic playlists
#. When in suffle mode, fetch more when there is only one song left such that the Next->Button always has a valid entry
#. Check if roGridScreen and roAudioPlayer are compatible in firmware 3.0
#. Check if Subsonic 4.6 and/or firmware 3.0 fixes transcoding content-length issue.  If not, provide a warning (only once)
   the first time a user attempts to play a transcoded file.

Version 1.4 - Goal Jan 31
~~~~~~~~~~~~~~~~~~~~~~~~~
#. Subsonic Jukebox Control Mode
#. Podcasts support
#. Add ability to create playlist on the fly, similar to Subsonic webpage player, where albums/songs can be added to the playlist
#. Reload the main-screen categories when re-entering it, but do so in the background so that the user-interface is snappy
#. Attempt to optimize initial startup and loading of index browser

Version 1.5
~~~~~~~~~~~
#. Add basic video support
#. Add support to view the "getNowPlaying.view" information on the main grid screen
