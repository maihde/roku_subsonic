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
1. Add comments for functions
2. Add true playlist, similar to Subsonic webpage player, where albums/songs can be added to the playlist
3. Add support for Subsonic playlists
4. Add checking for Subsonic server API version
5. Add support to view the "getNowPlaying.view" information on the main screen
6. Access lyrics from springboard page
7. Error checking when server is down
8. Add screensaver with album art (see sdk/examples/audioapp)
9. Reload the main-screen when entering it, primarlily so that Recently Played is kept up-to-date
10. Track version so we can notify users when the version get's updated
11. Provide warning the first time a transcoded file is loading, telling the user about issue #1
