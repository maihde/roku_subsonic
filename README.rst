Introduction
------------
This software is a ROKU front-end to the Subsonic media streaming server.  It
provides the following features:
 * Browse your entire catalog
 * Search for artists, albums, songs
 * Full catalog shuffle playback
 * Quick browse of Subsonic album lists (Random, Recent, Top Rated, etc.)

Tested on Roku firmware version: 2.9 and 3.0

Please provide feedback: https://github.com/inbox/new/maihde

Install this channel: https://owner.roku.com/add/SUBSONIC

Release Notes
~~~~~~~~~~~~~

1.10.0 - 14th Mar 2015
'''''''''''''''''''''
 * Fix bug that would cause hang on first startup
 * Added introduction screen
 * Added demo mode

1.9.0 - 26th Feb 2015
'''''''''''''''''''''
 * Add support for Podcasts

1.8.0 - 14th Jan 2015
'''''''''''''''''''''
 * Change Artist image to fill poster screen
 * Add default Album and Song images
 * Provide support for Artist->Song file organization (as opposed to Artist->Album->Song)
 * Add "Play All" and "Shuffle All" for Artist Screen
   
1.7.0 - 4th Mar 2011
'''''''''''''''''''''
 * No code changes from 1.6.0, republished to take advantage of new ability to publish channels
   to non-US Roku players.

1.6.0 - 10th Jan 2011
'''''''''''''''''''''
 * Fix bug that prevents the channel from working if a wrong username/password has been entered
 * Fix bug where the back button does not work on the track-playback screen or the "Show Queue" screen

1.5.0 - 9th Jan 2011
''''''''''''''''''''
 * Fix bug that prevent leaving the Configuration Screen when an invalid server parameters are entered
 * Fix memory leak that could occur if the main screen is left running continuously
 * Fix bug that prevented the main screen background updaters from working correctly in all instances
 * Add support to show the "Now Playing" list
 * Show artist in description area of main screen

1.4.0 - 7th Jan 2011
''''''''''''''''''''
 * Add support for playback of playlists (both as-is and shuffled)
   - You can press the play button to bypass the springboard
 * Show album ratings on main screen
 * Pressing up on search results returns back to main screen
 * Improve speed by building URLs with cached values instead of reading the registry
 * Deal with loss of server connection while program is running
 * Reload main screen (in background) so that lists stay up to date
 
1.3.0 - 19th Nov 2011
'''''''''''''''''''''
 * Request properly scaled images from the Subsonic server to avoid slow response when
   viewing folders (artists) with a large number of albums
 * Change browse icon to prepare for 1.4.0 support for "Now Playing" icon
 * Fix bug when setting username/password

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

Known Issues
------------
1. With Subsonic 4.5 and earlier, transcoded files play only a portion of the file.
   Subsonic 4.6 resolves this issue. See this link for a patch 
   of 4.4 and 4.5:

   http://www.activeobjects.no/subsonic/forum/viewtopic.php?p=26893#26893

2. roGridScreen doesn't cooperate with roAudioPlayer running in the background.
   If the roAudioPlayer sends an event while the grid screen is visible, the 
   album artwork get's scaled funny; this odd GridScreen behavior is in addition
   to the typical issues with roGridScreen that prevent normal stacking behavior.

3. When returning from the search roGridScreen to the main roGridScreen, a small
   delay must manually be introduced, otherwise the main grid screen get's corrupted.

4. Music must be organized in "Artist/Album/Songs" and/or "Artist/Songs" directory structure.

5. On roku firmware version 3.0, button clicks will cause gaps in audio playback.
   Turn Sound-Effects to "Off" if this is bothersome.

TODO
----
See https://github.com/maihde/roku_subsonic/issues
