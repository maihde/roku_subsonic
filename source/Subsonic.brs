REM ******************************************************
REM ROKU Channel supporting the Subsonic Media Server
REM Copyright (C) 2011 Michael Ihde
REM
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.
REM 
REM This program is distributed in the hope that it will be useful,
REM but WITHOUT ANY WARRANTY; without even the implied warranty of
REM MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
REM GNU General Public License for more details.
REM 
REM You should have received a copy of the GNU General Public License
REM along with this program.  If not, see <http://www.gnu.org/licenses/>.
REM
REM ******************************************************

REM ******************************************************
REM
REM ******************************************************
Sub Main()
    print "Entering Main"
    ' SetMainAppIsRunning()
    
    ' Set up the basic color scheme
    SetTheme()

    facade = CreateObject("roPosterScreen")
    facade.Show()
    facade.ShowMessage("Loading...")

    ' Don't show the main screen until we have been configured
    while isConfigured() = false
       ShowConfigurationScreen()
    end while

    ' Load the main screen data
    LoadMainScreenData()

    facade.ShowMessage("")
    
    ' Show the main screen
    while true
       item = ShowMainScreen()
       if item = invalid then
           exit while
       else if item.Type = "album" then
           items = GetAlbumSongs(item)
	   options = {playQueueStyle: "flat-episodic"
		     }
           ShowSpringBoard(items, 0, options)            
       else if item.Type = "button" then
           if item.id = "settings" then
               ShowConfigurationScreen()
           else if item.id = "shuffle" then
               items = GetRandomSongs()
               options = {fetchMore: GetRandomSongs
                          playQueueStyle: "flat-category"
                         }
               ShowSpringBoard(items, 0, options)            
           else if item.id = "index" then
               ShowIndex()
           end if
       end if
    end while

    facade.Close()

    print "Exiting Main"
end Sub

REM ******************************************************
REM
REM ******************************************************

Sub SetTheme()
    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    'theme.ThemeType = "generic-dark" ' UNUSABLE IF THE APP USES DIALOGS

    theme.BackgroundColor = "#363636"

    theme.OverhangOffsetSD_X = "72"
    theme.OverhangOffsetSD_Y = "25"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_Blue_SD43.png"
    theme.OverhangLogoSD  = "pkg:/images/subsonic_overhang_SDK_SD43.png"

    theme.OverhangOffsetHD_X = "123"
    theme.OverhangOffsetHD_Y = "48"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_Blue_HD.png"
    theme.OverhangLogoHD  = "pkg:/images/subsonic_overhang_HD.png"

    ' GridScreen Theme
    theme.GridScreenOverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_Blue_HD.png"
    theme.GridScreenOverhangHeightHD = "165"
    theme.GridScreenLogoOffsetHD_X = "123"
    theme.GridScreenLogoOffsetHD_Y = "48"
    theme.OverhangOffsetHD_Y = "48"
    theme.GridScreenLogoHD  = "pkg:/images/subsonic_overhang_HD.png"

    app.SetTheme(theme)
end Sub

REM ******************************************************
REM
REM ******************************************************
function CreateConfigurationScreen(port as Object) as Object
    screen = CreateObject("roParagraphScreen")
    screen.SetMessagePort(port)

    serverUrl = getServerUrl()
    if serverUrl = invalid then
	serverUrl = ""
    end if
    username = getUsername()
    if username = invalid then
	username = ""
    end if
    password = getPassword()
    if password = invalid then
	password = ""
    end if
    screen.AddParagraph("Current Configuration")    
    screen.AddParagraph(" Server Address: " + serverUrl)    
    screen.AddParagraph(" Username: " + username)    
    screen.AddParagraph(" Password: " + password)    

    screen.AddButton(1, "Set Server Address")
    screen.AddButton(2, "Set Username")
    screen.AddButton(3, "Set Password")
    screen.AddButton(4, "Test Connection")
    screen.AddButton(5, "Ok")
    return screen
end function

REM ******************************************************
REM
REM ******************************************************
function ShowConfigurationScreen()
    port=CreateObject("roMessagePort")
    screen = CreateConfigurationScreen(port)
    screen.Show()

    doExit = false
    while doExit = false ' Keep looping until the configuration is complete
	while true
	    msg = wait(0, port)
	    if type(msg) = "roParagraphScreenEvent" then
		if msg.isScreenClosed() then
		    doExit = true
		    exit while
		else if msg.isButtonPressed() then
		    if msg.getIndex() = 1 then
			value = GetInput("Server Address", getServerUrl(), "Enter the server address", 30)
			if value <> invalid then
			    setServerUrl(value)
			end if
			exit while
		    else if msg.getIndex() = 2 then
			value = GetInput("Username", getUsername(), "Enter the username", 30)
			if value <> invalid then
			    setUsername(value)
			end if
			exit while
		    else if msg.getIndex() = 3 then
			value = GetInput("Password", getPassword(), "Enter the password", 30)
			if value <> invalid then
			    setPassword(value)
			end if
			exit while
		    else if msg.getIndex() = 4 then
			if isConfigured() = false then
			    ShowErrorDialog("Configuration not complete")
			else
			    alive = isServerAlive()
			    if alive = true then
				ShowInformationalDialog("Connection success!")
			    else
				ShowErrorDialog("Failed to connect to server")
			    end if
			end if
		    else if msg.getIndex() = 5 then
		        doExit = true
			exit while
		    end if
		end if
	    endif
	end while

        if doExit = false then
	    newScreen = CreateConfigurationScreen(port)
	    newScreen.Show()
	    screen.Close()
	    screen = newScreen
	else
	    screen.Close()
	end if
    end while
end function

REM ******************************************************
REM
REM ******************************************************
function ShowErrorDialog(message as String) as Object
    port = CreateObject("roMessagePort")
    screen = CreateObject("roMessageDialog")
    screen.SetMessagePort(port)
    screen.SetTitle("Error")
    screen.SetText(message)
    screen.AddButton(1, "Ok")
    screen.EnableBackButton(true)
    screen.Show()
    
    while true
        msg = wait(0, port)
        if type(msg) = "roMessageDialogEvent" then
            if msg.isScreenClosed() then
                exit while
	    else if msg.isButtonPressed() then
                exit while
            end if
        end if
    end while
end function

REM ******************************************************
REM
REM ******************************************************
function ShowInformationalDialog(message as String) as Object
    port = CreateObject("roMessagePort")
    screen = CreateObject("roMessageDialog")
    screen.SetMessagePort(port)
    screen.SetTitle("Information")
    screen.SetText(message)
    screen.AddButton(1, "Ok")
    screen.EnableBackButton(true)
    screen.Show()
    
    while true
        msg = wait(0, port)
        if type(msg) = "roMessageDialogEvent" then
            if msg.isScreenClosed() then
                exit while
	    else if msg.isButtonPressed() then
                exit while
            end if
        end if
    end while
end function

REM ******************************************************
REM
REM ******************************************************
function GetInput(title as String, default as Dynamic, message as String, maxLength=20 as Integer) as Dynamic
    screen = CreateObject("roKeyboardScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetTitle(title)
    if default <> invalid then
        screen.SetText(default)
    end if
    screen.SetDisplayText(message)
    screen.SetMaxLength(maxLength)
    screen.AddButton(1, "Ok")
    screen.AddButton(2, "Cancel")
    screen.Show()

    while true
	msg = wait(0, screen.GetMessagePort())
	if type(msg) = "roKeyboardScreenEvent" then
	    if msg.isScreenClosed()
		return invalid
	    else if msg.isButtonPressed() then
		if msg.GetIndex() = 1 then
		    return screen.GetText()
		else if msg.GetIndex() = 2 then
		    return invalid
		end if
	    end if
	end if
    end while
end function

REM ******************************************************
REM
REM ******************************************************
function LoadMainScreenData()
    categoryList = [ {Id: "subsonic", Name: "Subsonic", Items: getMainMenu()},
                     {Id: "random",   Name: "Random", Items: invalid},
                     {Id: "newest",   Name: "Recently added", Items: invalid}, 
                     {Id: "highest",  Name: "Top rated", Items: invalid}, 
                     {Id: "recent",   Name: "Recently played", Items: invalid}, 
                     {Id: "frequent", Name: "Most played", Items: invalid} ]

    for i=0 to (categoryList.count() - 1) step 1
        ' Fetch items if necessary
        if categoryList[i].Items = invalid then
          categoryList[i].Items = getAlbumList(categoryList[i].Id)
        endif
    next

    m.Cache = {categoryList: categoryList}
end function

REM ******************************************************
REM
REM ******************************************************
function ShowMainScreen() as Object
    screen = CreateObject("roGridScreen")
    port=CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    screen.SetDisplayMode("scale-to-fill")
    screen.SetGridStyle("flat-square")

    categoryList = m.Cache.categoryList
    screen.SetupLists(categoryList.count())
    names = []
    for i=0 to (categoryList.count() - 1) step 1
        names.push(categoryList[i].Name)
	screen.SetContentList(i, categoryList[i].Items)
    next
    screen.SetListNames(names)
   
    screen.Show()

    item = invalid
    focusedRow = invalid
    while true
        print "Waiting for message"
        msg = wait(20000, port)
        'msg = wait(0, screen.GetMessagePort())     ' getmessageport does not work on gridscreen
        print "Got Message:";type(msg)
        if type(msg) = "roGridScreenEvent" then
            print "msg= "; msg.GetMessage() " , index= "; msg.GetIndex(); " data= "; msg.getData()
            if msg.isListItemFocused() then
                focusedRow = msg.GetIndex()
            else if msg.isListItemSelected() then
                row = msg.GetIndex()
                selection = msg.getData()
                info = msg.getInfo()
                print "list item selected row= "; row; " selection= "; selection
                item = categoryList[row].Items[selection]
                Exit while
            else if msg.isScreenClosed() then
	        print "Main screen closed"
                Exit while
            end if
	else
	    ' Reload the random list, only if random isn't focused
	    for i=0 to (categoryList.count() - 1) step 1
		if categoryList[i].Id = "random" and focusedRow <> i then
		    categoryList[i].Items = getAlbumList(categoryList[i].Id)
		    screen.SetContentList(i, categoryList[i].Items)
		end if
	    next	
        end if
    end while
		
    screen.Close()

    return item

end function

REM ***************************************************************
REM
REM ***************************************************************
function ShowPlayQueue(items as Object, nowplaying=0 as Integer, style="flat-episodic" as String)
    screen = CreateObject("roPosterScreen")
    screen.SetListStyle(style)
    port=CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    screen.SetContentList(items)
    screen.SetFocusedListItem(nowplaying)

    screen.Show()

    while true
        print "Waiting for message"
        msg = wait(0, port)
        'msg = wait(0, screen.GetMessagePort())     ' getmessageport does not work on gridscreen
        print "Got Message:";type(msg); " "; msg.getType()
        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                return msg.GetIndex()
            else if msg.isScreenClosed() then
                return -1
            end if
        end If
    end while
end function

REM ***************************************************************
REM
REM ***************************************************************
function ShowSpringBoard(items as Object, index=0 as Integer, options={} as Object, paused=false as Boolean)
    if items.count() <= 0 then
        print "No Items"
        return invalid
    end if
    port=CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")
REM    screen.SetBreadcrumbText(prevLoc,"Now Playing")
    screen.SetMessagePort(port)
    screen.SetPosterStyle("rounded-square-generic")
    screen.SetDescriptionStyle("audio")
    screen.SetContent(items[index])
    screen.SetTitle(items[index].Title)
    'screen.SetProgressIndicatorEnabled(true)
    screen.ClearButtons()
    if paused then
        screen.AddButton(1, "Play")
    else
        screen.AddButton(1, "Pause")
    end if
    screen.AddButton(2, "Show Queue")
    screen.AllowNavLeft(true)
    screen.AllowNavRight(true)
    screen.AllowUpdates(true)

    player = CreateObject("roAudioPlayer")
    player.SetMessagePort(port)
    player.SetLoop(0)
    player.SetContentList(items)
    player.SetNext(index)
    if not paused then
        player.Play()
    end if

    screen.Show()
 
    while true
        'print "Waiting for message from Springboard"
        msg = wait(20000, port)
        'print "Got Message:";type(msg)
        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed() then
                Exit while
	    else if msg.isButtonPressed() then
		screen.AllowUpdates(false)
	        if msg.getIndex() = 1 then
		    screen.ClearButtons()
		    if paused then
                        screen.AddButton(1, "Pause")
			paused = false
			player.Resume()
		    else
                        screen.AddButton(1, "Play")
			paused = true
			player.Pause()
		    end if
                    screen.AddButton(2, "Show Queue")
	        else if msg.getIndex() = 2 then
                    i = ShowPlayQueue(items, index, options.playQueueStyle)
                    if (i > 0) and (i <> index) then
                        index = i
			player.Stop()
                        player.SetNext(index)
	                screen.SetContent(items[index])
			player.Play()
                    end if
		end if
		screen.AllowUpdates(true)
	    else if msg.isRemoteKeyPressed() then
		i = msg.getIndex()
		if i = 4 then ' left
		    if (index > 0) then
		        index = index - 1
			player.Stop()
                        player.SetNext(index)
	                screen.SetContent(items[index])
			player.Play()
		    end if
		else if i = 5 then ' right
		    if (index < (items.count() - 1)) then
		        index = index + 1
			player.Stop()
                        player.SetNext(index)
	                screen.SetContent(items[index])
			player.Play()
                    else if options.DoesExist("fetchMore") then
		        items = options.fetchMore()	
                        if items.count() > 0 then
			    index = 0
			    player.Stop()
			    screen.SetContent(items[index])
			    player.SetContentList(items)
		            player.SetNext(index)
			    player.Play()
                        else
                            exit while
                        end if
		    end if
		end if
	    end if
        else if type(msg) = "roAudioPlayerEvent" then
            if msg.isListItemSelected() then
	        index = msg.GetIndex()
	        screen.SetContent(items[index])
            else if msg.isStatusMessage() then
		if msg.getmessage() = "start of play" then
		else if msg.getmessage() = "end of playlist" then
                    if options.DoesExist("fetchMore") then
		        items = options.fetchMore()	
                        if items.count() > 0 then
			    index = 0
			    player.Stop()
			    screen.SetContent(items[index])
			    player.SetContentList(items)
		            player.SetNext(index)
			    player.Play()
                        else
                            exit while
                        end if
		    end if
		end if
            end if
        end If
    end while
end function


REM ***************************************************************
REM
REM ***************************************************************
function getAlbumList(listtype as String) as object
    albumList = []

    xfer = CreateObject("roURLTransfer")
    xfer.SetURL(createSubsonicUrl("getAlbumList.view", {type: listtype}))
    xferResult = xfer.GetToString()
    xml = CreateObject("roXMLElement")
    
    if xml.Parse(xferResult)
       for each album in xml.albumList.album
           item = CreateObject("roAssociativeArray")
           item.Type = "album"
           item.ContentType = "audio"
           item.Title = album@title
           item.Artist = album@artist
           item.Id = album@id
           if album@coverArt <> invalid then
               item.SDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: album@coverArt})
               item.HDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: album@coverArt})
           endif
           albumList.push(item)
       next
    end if

    return albumList
end function

REM ***************************************************************
REM
REM ***************************************************************
function GetAlbumSongs(album as Object)
    xfer = CreateObject("roURLTransfer")
    xfer.SetURL(createSubsonicUrl("getMusicDirectory.view", {id: album.Id}))
    xferResult = xfer.GetToString()
    xml = CreateObject("roXMLElement")
   
    items = [] 
    if xml.Parse(xferResult)
        for each child in xml.directory.child
            item = CreateObject("roAssociativeArray")
            item.Title = child@title
            item.Album = child@album
            item.Artist = child@artist
            item.ShortDescriptionLine1 = child@title
            item.EpisodeNumber = child@track
            if child@contentType = "audio/mpeg" then
                item.ContentType = "audio"
                item.StreamFormat = "mp3"
            else if child@contentType = "audio/mp4" then
                item.ContentType = "audio"
                item.StreamFormat = "mp4"
            endif
            item.SDPosterUrl = album.SDPosterUrl
            item.HDPosterUrl = album.HDPosterUrl
            item.Url = createSubsonicUrl("stream.view", {id: child@id})
            items.push(item)
        next
    end if

    return items
end function

REM ***************************************************************
REM
REM ***************************************************************
function getMainMenu() as object
        buttons = [
            { Type: "button"
              id: "settings"
              Title: "Settings"
              Description: "Subsonic settings"
            }
' TODO
'            { Type: "button"
'              id: "search"
'              Title: "Search"
'              Description: "Search subsonic"
'            }
            { Type: "button"
              id: "shuffle"
              Title: "Shuffle All"
              Description: "Shuffle all songs"
            }
            { Type: "button"
              id: "index"
              Title: "All Artists"
              Description: "Browse all artists"
            }
       ]
       return buttons
end function

REM ***************************************************************
REM
REM ***************************************************************
function GetRandomSongs(count=100 as Integer) as Object
    xfer = CreateObject("roURLTransfer")
    xfer.SetURL(createSubsonicUrl("getRandomSongs.view", {size: Stri(count).Trim()}))
    xferResult = xfer.GetToString()
    print xferResult
    xml = CreateObject("roXMLElement")
    items = [] 
    if xml.Parse(xferResult)
        for each song in xml.randomSongs.song
            item = CreateObject("roAssociativeArray")
            item.Title = song@title
            item.Album = song@album
            item.Artist = song@artist
            item.ShortDescriptionLine1 = song@title
            item.EpisodeNumber = song@track
            item.SDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: song@coverArt})
            item.HDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: song@coverArt})
            item.Url = createSubsonicUrl("stream.view", {id: song@id})
            ' Only push songs with the correct content type
            if song@contentType = "audio/mpeg" then
                item.ContentType = "audio"
                item.StreamFormat = "mp3"
                items.push(item)
            else if song@contentType = "audio/mp4" then
                item.ContentType = "audio"
                item.StreamFormat = "mp4"
                items.push(item)
            end if
        next
    end if

    return items
end function

REM ***************************************************************
REM
REM ***************************************************************
function ShowIndex()
    Names = CreateObject("roArray", 0, true)
    Indexes = CreateObject("roAssociativeArray")

    xfer = CreateObject("roURLTransfer")
    xfer.SetURL(createSubsonicUrl("getIndexes.view", {}))
    xferResult = xfer.GetToString()
    xml = CreateObject("roXMLElement")

    if xml.Parse(xferResult)
       for each index in xml.indexes.index
           Artists = CreateObject("roArray", 0, true)
           for each artist in index.artist
               item = CreateObject("roAssociativeArray")
	       item.Id = artist@id
	       item.ShortDescriptionLine1 = artist@name 
               ' TODO Subsonic provides no artwork for artists, so just show a little submarine icon instead
	       Artists.push(item)
	   next
           Names.push(index@name)
           Indexes.AddReplace(index@name, Artists)
       next
    end if
    
    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.SetListDisplayMode("best-fit")

    screen.SetFocusedListItem(0)
    screen.setListNames(Names)
    curIndex = Names[0]
    screen.SetContentList(Indexes[curIndex])

    screen.Show()

    while true
        msg = wait(0, port)
        print "posterscreen get selection typemsg = "; type(msg)

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListFocused() then
                print "index selected: " + Stri(msg.GetIndex())
                curIndex = Names[msg.GetIndex()]
                screen.SetContentList(Indexes[curIndex])
                screen.SetFocusedListItem(0)
            else if msg.isListItemSelected() then
                print "list selected: " + Stri(msg.GetIndex())
                ShowArtist(Indexes[curIndex][msg.GetIndex()].Id)
            else if msg.isScreenClosed() then 
                exit while
            endif
        endif
    end while	        
end function

REM ***************************************************************
REM
REM ***************************************************************
function ShowArtist(artist_id as String)
    albumList = CreateObject("roArray", 0, true)

    xfer = CreateObject("roURLTransfer")
    xfer.SetURL(createSubsonicUrl("getMusicDirectory.view", {id: artist_id}))
    xferResult = xfer.GetToString()
    xml = CreateObject("roXMLElement")

    if xml.Parse(xferResult)
       for each child in xml.directory.child
           item = CreateObject("roAssociativeArray")
           item.Type = "child"
           item.ContentType = "audio"
           item.Title = child@title
	   item.ShortDescriptionLine1 = child@title
           item.Artist = child@artist
           item.Id = child@id
           if child@coverArt <> invalid then
               item.SDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: child@coverArt})
               item.HDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: child@coverArt})
           endif
           albumList.push(item)
       next
    end if
    
    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.SetListDisplayMode("best-fit")

    screen.SetContentList(albumList)

    screen.Show()

    while true
        msg = wait(0, port)
        print "posterscreen get selection typemsg = "; type(msg)

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                print "list selected: " + Stri(msg.GetIndex())
	        items = GetAlbumSongs(albumList[msg.GetIndex()])
	        options = {playQueueStyle: "flat-episodic"
	 		  }
	        ShowSpringBoard(items, 0, options)            
            else if msg.isScreenClosed() then 
                exit while
            end if
        endif
    end while	        
end function

REM ***************************************************************
REM
REM ***************************************************************
function isServerAlive() as Boolean
    screen = CreateObject("roOneLineDialog")
    screen.SetTitle("Checking server connection to " + getServerUrl())
    screen.ShowBusyAnimation()
    screen.Show()

    xfer = CreateObject("roURLTransfer")
    port = CreateObject("roMessagePort")
    xfer.SetPort(port)
    xfer.SetURL(createSubsonicUrl("ping.view"))
    xferResult = xfer.AsyncGetToString()
    
    sleep(3000) ' Give it some time so the users sees the busy dialog

    while true
        msg = wait(0, port)
	if type(msg) = "roUrlEvent" then
	    if msg.getInt() = 1 then
	        screen.Close()
	        if msg.getResponseCode() = 200 then
	            return true
	        else
	            return false
		end if
	    end if
	end if
    end while
end function

REM ***************************************************************
REM
REM ***************************************************************
function createSubsonicUrl(view as String, params={} as Object) as String
    ' Always override certian values
    params.u = getUsername()
    params.p = getPassword()
    params.v = getApiVersion()
    params.c = getClient()

    ' Create a QueryString
    queryString = ""
    for each p in params
        if params[p] <> invalid
            queryString = queryString + p + "=" + params[p] + "&"
	end if
    next 

    ' Create the full URL
    url = getBaseUrl() + "/" + view + "?" + queryString 
    return url
end function

REM ***************************************************************
REM
REM ***************************************************************
function getBaseUrl() as Dynamic
    serverUrl = getServerUrl()
    if serverUrl <> invalid then
        return "http://" + serverUrl + "/rest"
    else
        return invalid
    end if
end function

REM ***************************************************************
REM
REM ***************************************************************
function getApiVersion() as String
  return "1.5.0"
End function

REM ***************************************************************
REM
REM ***************************************************************
function isConfigured() as Boolean
    if getServerUrl() <> invalid and getUsername() <> invalid and getPassword() <> invalid then
        return true
    else
        return false
    end if
End function

REM ***************************************************************
REM
REM ***************************************************************
function getServerUrl() As Dynamic
    sec = CreateObject("roRegistrySection", "Settings")
    if sec.Exists("serverUrl") then
	return sec.Read("serverUrl")
    else
	return invalid
    end if
end function

REM ***************************************************************
REM
REM ***************************************************************
function setServerUrl(serverUrl As String) As Void
    sec = CreateObject("roRegistrySection", "Settings")
    sec.Write("serverUrl", serverUrl)
    sec.Flush()
end function

REM ***************************************************************
REM
REM ***************************************************************
function getUsername() as Dynamic 
    sec = CreateObject("roRegistrySection", "Settings")
    if sec.Exists("username") then
	return sec.Read("username")
    else
	return invalid
    end if
end function

REM ***************************************************************
REM
REM ***************************************************************
function setUsername(username as String) as String
    sec = CreateObject("roRegistrySection", "Settings")
    sec.Write("username", username)
    sec.Flush()
end function

REM ***************************************************************
REM
REM ***************************************************************
function getPassword() as Dynamic 
    sec = CreateObject("roRegistrySection", "Settings")
    if sec.Exists("password") then
	return sec.Read("password")
    else
	return invalid
    end if
end function

REM ***************************************************************
REM
REM ***************************************************************
function setPassword(password as String) as String
    sec = CreateObject("roRegistrySection", "Settings")
    sec.Write("password", password)
    sec.Flush()
end function

REM ***************************************************************
REM
REM ***************************************************************
function getClient() as String
  return "roku"
end function
