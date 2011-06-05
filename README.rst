Introduction
----------------------------------
This software is a ROKU front-end to the Subsonic media streaming server.  It
provides the following features:
 * Browse your entire catalog
 * Search for artists, albums, songs
 * Full catalog shuffle playback
 * Quick browse of Subsonic album lists (Random, Recent, Top Rated, etc.)

Tested on Roku firmware version 2.9.

Please provide feedback: https://github.com/inbox/new/maihde

Install this channel: http://www.randomwalking.com/project.php?project=roku_subsonic

Credits
----------------------------------
Icons from Emre Ozcelik's "Elegant Blue Web" icon set
    http://www.iconfinder.com/search/?q=iconset%3Aellegant

Known Issues
----------------------------------
1. Transcoded files play only a portion of the file; this is because when the roku
   does not receive a content-length response, it will use partial transfer requests
   and it expects a 416 response code to indicate that the partial request has 
   reached the end of the file.  Subsonic does not send a 416 response code,
   causing the roku to abort playback.  See this link for the patch information:

   http://www.activeobjects.no/subsonic/forum/viewtopic.php?p=26893#26893 

2. roGridScreen doesn't cooperate with roAudioPlayer running in the background.
   If the roAudioPlayer sends an event while the grid screen is visible, the 
   album artwork get's scaled funny; this odd GridScreen behavior is in addition
   to the typical issues with roGridScreen that prevent normal stacking behavior.

3. When returning from the search roGridScreen to the main roGridScreen, a small
   delay must manually be introduced, otherwise the main grid screen get's corrupted.

4. Music must be organized in Artist/Album/Songs directory structure.

TODO
----------------------------------
1. Changing server settings doesn't cause the main screen to reload
2. Add playback position indicator in SpringBoard
3. Add comments for functions
4. Add true playlist, similar to Subsonic webpage player, where albums/songs can be added to the playlist
5. Add support for Subsonic playlists
6. Add checking for Subsonic server API version
7. Add support to view the "getNowPlaying.view" information on the main screen
8. Get lyrics from springboard page
