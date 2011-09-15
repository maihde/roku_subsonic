REM ******************************************************
REM vim: et: sw=4
REM
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
    m.screensaverModes = createObject("roList")
    m.screensaverModes.addTail("Smooth Animation")
    m.screensaverModes.addTail("Bouncing Animation")
    m.screensaverModes.addTail("Corners")
    m.screensaverModes.addTail("Random")
    
    SetMainAppIsRunning("true")
    
    ' Set up the basic color scheme
    SetTheme()

    facade = CreateObject("roPosterScreen")
    facade.Show()
    facade.ShowMessage("")

    ' Don't show the main screen until we have been configured
    while isConfigured() = false
       ShowConfigurationScreen()
    end while

    ' Verify the server connection
    TestServerConnection()

    facade.ShowMessage("Loading...")
    ' Load the main screen data
    LoadMainScreenData()

    facade.ShowMessage("")
    
    REM un-comment for screensaver dev testing. Screensaver will run immediately and endlessly with test image, and app will not run
    'SaveCoverArtForScreenSaver("file://pkg:/images/subsonic.png", "file://pkg:/images/subsonic.png")
    'RunScreenSaver()
    
    ' Show the main screen
    while true
       item = ShowMainScreen()
       if item = invalid then
           exit while
       else if item.Type = "album" then
           PlayAlbum(item)
       else if item.Type = "button" then
           if item.id = "settings" then
               ShowConfigurationScreen()
                ' Load the main screen data
                LoadMainScreenData()
           else if item.id = "shuffle" then
               PlayRandom()
           else if item.id = "index" then
               ShowIndex()
           else if item.id = "search" then
               selected_item = DoSearch()
               if selected_item <> invalid then
                   if selected_item.Type = "artist" then
                       ShowArtist(selected_item)
                   else if selected_item.Type = "album" then
                       PlayAlbum(selected_item)
                   else if selected_item.Type = "song" then
                       PlaySong(selected_item)
                   end if
               end if
           end if
       end if
    end while
    
    facade.Close()
    print "Exiting Main"
    SetMainAppIsRunning("false")
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
    screensaverMode = getScreensaverMode()
     if screensaverMode = invalid then
        screensaverMode = ""
    end if
    screen.AddParagraph("Current Configuration")    
    screen.AddParagraph(" Server Address: " + serverUrl)    
    screen.AddParagraph(" Username: " + username)    
    screen.AddParagraph(" Password: " + password)    
    screen.AddParagraph(" Screensaver Mode: " + screensaverMode)

    screen.AddButton(1, "Set Server Address")
    screen.AddButton(2, "Set Username")
    screen.AddButton(3, "Set Password")
    screen.AddButton(6, "Change Screensaver Mode")
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
            screensaverModeChanged = false
            msg = wait(0, port)
            if type(msg) = "roParagraphScreenEvent" then
                if msg.isScreenClosed() then
                    doExit = true
                    exit while
                else if msg.isButtonPressed() then
                    if msg.getIndex() = 1 then
                        value = GetInput("Server Address", getServerUrl(), "Enter the server address and port (i.e. 'server:4040')", 30)
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
                            TestServerConnection(false, false)
                        end if
                        exit while
                    else if msg.getIndex() = 5 then
                        doExit = true
                        exit while
                    else if msg.getIndex() = 6 then
                        screensaverModeChanged = true
                        value = getNextScreensaverMode()
                        if value <> invalid then
                            setScreensaverMode(value)
                        end if
                        exit while
                    end if
                end if
            endif
        end while

        if doExit = false then
            newScreen = CreateConfigurationScreen(port)
            'highlight next button, except if screensaver mode button was pressed, highlight it again
            if msg.getIndex() = 6 then
                newScreen.setDefaultMenuItem(3)
            else if msg.getIndex() = 4 then
                newScreen.setDefaultMenuItem(5)
            else
                newScreen.setDefaultMenuItem(msg.getIndex())
            end if
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

    ' the playback management object
    player = {
        audioPlayer: invalid
        items: invalid
        timer: invalid
        paused: true
        progress: 0
        index: 0

        Init: function(port as Object, items as Object, index=0 as Integer) 
            m.index = index
            m.items = items
            m.audioPlayer = CreateObject("roAudioPlayer")
            m.audioPlayer.SetMessagePort(port)
            m.audioPlayer.SetLoop(0)
            m.audioPlayer.SetContentList(m.items)
            m.audioPlayer.SetNext(m.index)
            m.timer = CreateObject("roTimespan")
            m.progress = 0
        end function

        SetContentList : function(items as Object, index=0 as Integer)
            m.f_Stop()
            m.index = index
            m.items = items
            m.audioPlayer.SetContentList(items)
        end function

        Play: function()
            m.progress = 0
            m.timer.Mark()
            m.audioPlayer.Play()
            m.paused = false
        end function

        Pause: function()
            m.timer.Mark()
            m.audioPlayer.Pause()
            m.paused = true
        end function

        Resume: function()
            m.timer.Mark()
            m.audioPlayer.Resume()
            m.paused = false
        end function
        
        f_Stop: function()
            m.timer.Mark()
            m.audioPlayer.Stop()
            m.paused = true
        end function

        ResetProgress: function()
            m.progress = 0
            m.timer.Mark()
        end function

        GetProgress: function() as Integer
            if not m.paused then
                m.progress = m.progress + m.timer.TotalSeconds()
                m.timer.Mark()
            end if
            return m.progress
        end function
         
        GetCurrent: function() as Dynamic
            return m.items.getEntry(m.index)
        end function

        GetNext: function() as Dynamic
            return m.items.getEntry(m.index + 1)
        end function

        GetPrev: function() as Dynamic
            return m.items.getEntry(m.index - 1)
        end function

        GotoNext: function() as Boolean
            return m.f_Goto(m.index + 1)
        end function

        GotoPrev: function() as Boolean
            return m.f_Goto(m.index - 1)
        end function

        f_Goto: function(index as Integer) as Boolean
            if index >= 0 and index < m.items.Count() then
                print "Setting index "; index
                m.index = index
                m.f_Stop()
                m.audioPlayer.SetNext(m.index)
                m.progress = 0
                m.timer.Mark()
                m.audioPlayer.Play()
                m.paused = false
                return true
            else
                return false
            end if
        end function

        SetContents: function(contents as Object)
            m.audioPlayer.SetContents(contents)
        end function
    }

    player.Init(port, items, index)

    ' the display screen
    screen = CreateObject("roSpringboardScreen")
    screen.AllowUpdates(false)
REM    screen.SetBreadcrumbText(prevLoc,"Now Playing")
    screen.SetMessagePort(port)
    REM explictly setting style = 'rounded-square-generic' prevents the progress bar from displaying
    REM with firmware 2.9
    REM screen.SetPosterStyle("rounded-square-generic")
    screen.SetContent(player.items[index])
    screen.SetDescriptionStyle("audio")
    screen.SetTitle(player.items[index].Title)
    screen.SetStaticRatingEnabled(false)
    screen.ClearButtons()
    if paused then
        screen.AddButton(1, "Play")
    else
        screen.AddButton(1, "Pause")
    end if
    if player.GetPrev() <> invalid then
        screen.AddButton(2, "Prev - " + player.GetPrev().Title)
    end if
    if player.GetNext() <> invalid then
        screen.AddButton(3, "Next - " + player.GetNext().Title)
    end if
    screen.AddButton(4, "Show Queue")
    screen.AllowNavLeft(true)
    screen.AllowNavRight(true)
    
    if player.GetCurrent().length <> invalid then 
        screen.SetProgressIndicatorEnabled(true)
        screen.SetProgressIndicator(player.progress, player.GetCurrent().length)
    else
        screen.SetProgressIndicatorEnabled(false)
    end if

    if not paused then
        player.Play()
    end if
   
    screen.AllowUpdates(true)
    screen.Show()

    while true
        'print "Waiting for message from Springboard"
        msg = wait(1000, port)
        
        ' Update the progress indicator
        if player.GetCurrent() <> invalid then
            if player.GetCurrent().length <> invalid then
                progress = player.GetProgress()
                screen.SetProgressIndicatorEnabled(true)
                screen.SetProgressIndicator(progress, player.GetCurrent().length)
            else
                screen.SetProgressIndicatorEnabled(false)
            end if
        end if

        'print "Got Message:";type(msg)
        if type(msg) = "roSpringboardScreenEvent" then
            if msg.isScreenClosed() then
                Exit while
            else if msg.isButtonPressed() then
                ' Handle the event
                print "Button pressed"; msg.getIndex()
                if msg.getIndex() = 1 then
                    if player.paused then
                        player.Resume()
                    else
                        player.Pause()
                    end if
                else if msg.getIndex() = 2 then
                    player.GotoPrev()
                    screen.SetContent(player.GetCurrent())
                else if msg.getIndex() = 3 then
                    player.GotoNext()
                    screen.SetContent(player.GetCurrent())
                else if msg.getIndex() = 4 then
                    i = ShowPlayQueue(items, index, options.playQueueStyle)
                    if (i >= 0) and (i <> player.index) then
                        player.f_Goto(i)
                        screen.SetContent(player.GetCurrent())
                    end if
                end if
            else if msg.isRemoteKeyPressed() then
                i = msg.getIndex()
                if i = 4 then ' left
                    if player.timer.TotalSeconds() >= 2 then
                        player.f_Goto(player.index)
                    else if player.GotoPrev() then
                        screen.SetContent(player.GetCurrent())
                    end if
                else if i = 5 then ' right
                    if player.GotoNext() = true
                        screen.SetContent(player.GetCurrent())
                    else if options.DoesExist("fetchMore") then
                        items = options.fetchMore()     
                        if items.count() > 0 then
                            player.SetContentList(items)
                            player.Play()
                            screen.SetContent(player.GetCurrent())
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
                player.index = index
                player.ResetProgress()
            else if msg.isStatusMessage() then
                if msg.getmessage() = "end of playlist" then
                    if options.DoesExist("fetchMore") then
                        items = options.fetchMore()     
                        if items.count() > 0 then
                            player.SetContentList(items)
                            player.Play()
                            screen.SetContent(player.GetCurrent())
                        else
                            exit while
                        end if
                    else 
                        exit while
                    end if
                else if msg.getMessage() = "start of play"
                    setScreenSaverCoverArtUrl(player.items[player.index])
                    player.timer.Mark()
                end if
            end if
        end If

        ' Update the buttons
        if msg <> invalid then
            screen.AllowUpdates(false)
            updateButtons = false
            screen.ClearButtons()
            if player.paused then
                screen.AddButton(1, "Play")
            else
                screen.AddButton(1, "Pause")
            end if
            if player.GetPrev() <> invalid then
                screen.AddButton(2, "Prev - " + player.GetPrev().Title)
            end if
            if player.GetNext() <> invalid then
                screen.AddButton(3, "Next - " + player.GetNext().Title)
            end if
            screen.AddButton(4, "Show Queue")
            screen.AllowUpdates(true)
        end if
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
           item = CreateAlbumItemFromXml(album)
           if item <> invalid then
               albumList.push(item)
           end if
       next
    end if

    return albumList
end function

REM ***************************************************************
REM
REM ***************************************************************
function PlaySong(song as Object)
    songs = [ song ]
    ShowSpringBoard(songs, 0, {playQueueStyle: "flat-episodic"})
end function

REM ***************************************************************
REM
REM ***************************************************************
function PlayAlbum(album as Object)
    songs = GetAlbumSongs(album)
    ShowSpringBoard(songs, 0, {playQueueStyle: "flat-episodic"})
end function

REM ***************************************************************
REM
REM ***************************************************************
function PlayRandom()
    screen = CreateObject("roOneLineDialog")
    screen.SetTitle("Retrieving...")
    screen.ShowBusyAnimation()
    screen.Show()

    items = GetRandomSongs()
    options = {fetchMore: GetRandomSongs
              playQueueStyle: "flat-category"
             }
    ShowSpringBoard(items, 0, options)            
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
            item = CreateSongItemFromXml(child)
            if item <> invalid then
                items.push(item)
            end if
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
              id: "index"
              Title: "All Music"
              Description: "Browse all music"
              SDPosterUrl: "pkg:/images/buttons/index.png"
              HDPosterUrl: "pkg:/images/buttons/index.png"
            }
            { Type: "button"
              id: "search"
              Title: "Search"
              Description: "Search subsonic"
              SDPosterUrl: "pkg:/images/buttons/search.png"
              HDPosterUrl: "pkg:/images/buttons/search.png"
            }
            { Type: "button"
              id: "shuffle"
              Title: "Shuffle All"
              Description: "Shuffle all songs"
              SDPosterUrl: "pkg:/images/buttons/shuffle.png"
              HDPosterUrl: "pkg:/images/buttons/shuffle.png"
            }
            { Type: "button"
              id: "settings"
              Title: "Settings"
              Description: "Subsonic settings"
              SDPosterUrl: "pkg:/images/buttons/settings.png"
              HDPosterUrl: "pkg:/images/buttons/settings.png"
            }
       ]
       return buttons
end function

REM ***************************************************************
REM
REM ***************************************************************
function GetRandomSongs(count=20 as Integer) as Object
    xfer = CreateObject("roURLTransfer")
    xfer.SetURL(createSubsonicUrl("getRandomSongs.view", {size: Stri(count).Trim()}))
    xferResult = xfer.GetToString()
    print xferResult
    xml = CreateObject("roXMLElement")
    items = [] 
    if xml.Parse(xferResult)
        for each song in xml.randomSongs.song
            item = CreateSongItemFromXml(song)
            if item <> invalid then
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

    xferResult = UrlTransferWithBusyDialog(createSubsonicUrl("getIndexes.view", {}))
    xml = CreateObject("roXMLElement")

    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.SetListDisplayMode("best-fit")

    screen.Show()

    screen.ShowMessage("Loading...")

    if xml.Parse(xferResult.data)
       for each index in xml.indexes.index
           Artists = CreateObject("roArray", 0, true)
           for each artist in index.artist
               item = CreateArtistItemFromXml(artist)
               if item <> invalid then
                   Artists.push(item)
               end if
           next
           Names.push(index@name)
           Indexes.AddReplace(index@name, Artists)
       next
    end if
    
    screen.ClearMessage()

    screen.SetFocusedListItem(0)
    screen.setListNames(Names)
    curIndex = Names[0]
    screen.SetContentList(Indexes[curIndex])


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
                selIndex = Indexes[curIndex]
                ShowArtist(selIndex[msg.GetIndex()])
            else if msg.isScreenClosed() then 
                exit while
            endif
        endif
    end while           
end function


REM ***************************************************************
REM
REM ***************************************************************
function ShowArtist(artist as Object)
    albumList = CreateObject("roArray", 0, true)

    xfer = CreateObject("roURLTransfer")
    xfer.SetURL(artist.Url)
    xferResult = xfer.GetToString()
    xml = CreateObject("roXMLElement")

    if xml.Parse(xferResult)
       for each child in xml.directory.child
           item = CreateAlbumItemFromXml(child)
           if item <> invalid then
               albumList.push(item)
           end if
       next
    end if
    
    port = CreateObject("roMessagePort")
    screen = CreateObject("roPosterScreen")
    screen.SetMessagePort(port)
    screen.SetListStyle("flat-category")
    screen.SetListDisplayMode("best-fit")
    screen.SetBreadcrumbText(artist.Title, "")
    screen.SetBreadcrumbEnabled(true)
    screen.SetContentList(albumList)

    screen.Show()

    while true
        msg = wait(0, port)
        print "posterscreen get selection typemsg = "; type(msg)

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                print "list selected: " + Stri(msg.GetIndex())
                PlayAlbum(albumList[msg.GetIndex()])
            else if msg.isScreenClosed() then 
                exit while
            end if
        endif
    end while           
end function

REM ***************************************************************
REM
REM @returns the select item, or invalid if no selection was made
REM ***************************************************************
function DoSearch() as Dynamic
    search_selection = invalid ' the item the user selected

    history = CreateObject("roSearchHistory")

    port = CreateObject("roMessagePort")
    search_screen = CreateObject("roSearchScreen")
    search_screen.SetMessagePort(port)
    search_screen.SetSearchTermHeaderText("Recent Searches")
    search_screen.SetSearchButtonText("search")
    search_screen.SetClearButtonText("clear history")
    search_screen.SetSearchTerms(history.GetAsArray())
    
    search_screen.Show() 

    searchterm = invalid
    while true
        msg = wait(0, port)
        print "recv "; type(msg)
        if type(msg) = "roSearchScreenEvent" then
            if msg.isScreenClosed() then 
                exit while
            else if msg.isCleared() then 
                history.Clear()
            else if msg.isPartialResult() then 
                filteredList = CreateObject("roArray", 0, true)
                print "partial result "; msg.GetMessage()
                if Len(msg.GetMessage()) = 0 then
                    search_screen.SetSearchTerms(history.GetAsArray())
                else
                    for each t in history.GetAsArray()
                        if StartsWith(t, msg.GetMessage()) then
                            filteredList.Push(t)
                        end if
                    next
                    search_screen.SetSearchTerms(filteredList)
                end if
            else if msg.isFullResult() then 
                print "full result "; msg.GetMessage()
                searchterm = msg.GetMessage()
                history.Push(searchterm)
                exit while
            end if
        endif
    end while           
        
    search_facade = CreateObject("roPosterScreen")
    search_facade.Show()

    search_screen.Close() 
 
    if searchterm <> invalid then
        ' Execute the search
        xferResult = UrlTransferWithBusyDialog(createSubsonicUrl("search2.view", {query: searchterm}))
        search_facade.ShowMessage("Loading...")

        results = {artists: CreateObject("roArray", 0, true)
                   albums: CreateObject("roArray", 0, true)
                   songs: CreateObject("roArray", 0, true)
                  }

        xml = CreateObject("roXMLElement")
        if xml.Parse(xferResult.data)
           for each artist in xml.searchResult2.artist
               item = CreateArtistItemFromXml(artist)
               if item <> invalid then
                   results.artists.push(item)
               end if
           next
           for each album in xml.searchResult2.album
               item = CreateAlbumItemFromXml(album)
               if item <> invalid then
                   results.albums.push(item)
               end if
           next
           for each song in xml.searchResult2.song
                item = CreateSongItemFromXml(song)
                if item <> invalid then
                    results.songs.push(item)
                end if
           next
        end if

        if results.artists.Count() > 0 or results.albums.Count() > 0 or results.songs.Count() > 0 then

            results_screen = CreateObject("roGridScreen")
            results_screen.SetBreadcrumbText("Search results for '" + searchterm + "'", "")
            results_screen.SetBreadcrumbEnabled(true)
            results_screen.SetMessagePort(port)
            results_screen.SetDisplayMode("scale-to-fill")
            results_screen.SetGridStyle("flat-square")
            results_screen.SetupLists(3)
            results_screen.SetContentList(0, results.artists)
            results_screen.SetContentList(1, results.albums)
            results_screen.SetContentList(2, results.songs)
            results_screen.SetListNames(["Artists", "Albums", "Songs"])

            results_screen.Show()

            while true
                msg = wait(0, port)

                print "rcvd "; type(msg)
                if type(msg) = "roGridScreenEvent" then
                    if msg.isScreenClosed() then 
                        exit while
                    else if msg.isListItemSelected() then
                        row = msg.GetIndex()
                        selection = msg.getData()
                        if row = 0 then
                            search_selection = results.artists[selection]
                        else if row = 1
                            search_selection = results.albums[selection]
                        else if row = 2
                            search_selection = results.songs[selection]
                        end if
                        Exit while
                    end if
                endif
            end while

            search_facade.ShowMessage("")
            results_screen.Close()
            ' A pause is necessary here, otherwise the results grid screen
            ' messes up the redraw of the main grid screen
            sleep(500)

            return search_selection
        else
            ShowInformationalDialog("No results for: " + searchterm)
        end if ' result.count() > 0
    end if ' searchterm <> invalid
    
    search_facade.Close()
    return search_selection

end function

REM ***************************************************************
REM
REM ***************************************************************
function StartsWith(text As String, substring As String) as Boolean
    if instr(1, text, substring) = 1 then
        return true
    else
        return false
    end if
end function

REM ***************************************************************
REM
REM ***************************************************************
function URLTransferWithBusyDialog(url as String, title="Retrieving..." as String) as Object
    result = CreateObject("roAssociativeArray")
    result.data = invalid
    result.code = 0

    screen = CreateObject("roOneLineDialog")
    screen.SetTitle(title)
    screen.ShowBusyAnimation()
    screen.Show()

    xfer = CreateObject("roURLTransfer")
    port = CreateObject("roMessagePort")
    xfer.SetPort(port)
    xfer.SetURL(url)
    valid = xfer.AsyncGetToString()
                
    if valid = false then
        return result
    end if
    
    sleep(2000) ' Always show the dialog for at least 2 seconds

    while true
        msg = wait(0, port)
        if type(msg) = "roUrlEvent" then
            if msg.getInt() = 1 then
                screen.Close()
                result.data = msg.getString()
                result.code = msg.getResponseCode()
                return result
            end if
        end if
    end while

end function

REM ***************************************************************
REM
REM ***************************************************************
function TestServerConnection(quiet_success=true as Boolean, quiet_failure=false as Boolean) as Boolean
    alive = false
    error = invalid

    url = createSubsonicUrl("ping.view")
    xferResult = UrlTransferWithBusyDialog(url, "Connecting")
    if xferResult.code = 200 then
        print xferResult.data
        xml = CreateObject("roXMLElement")
        ' Run the gauntlet...only succeed if all tests pass
        if xml.Parse(xferResult.data)
            if xml.GetName() = "subsonic-response" then
               if xml.GetAttributes().Lookup("status") = "ok" then
                   alive = true
               else if xml.error <> invalid then
                   if xml.GetAttributes().Lookup("version") <> invalid  then
                        sVersion = xml.GetAttributes().Lookup("version")
                        cVersion = getApiVersion()
                        error = getVersionErrMsg(cVersion, sVersion)
                        if error <> "OK" then
                            alive = false
                            versionErr = true
                        end if
                   end if
                   if versionErr <> true then
                        error = xml.error.GetAttributes().Lookup("message")
                   end if
               end if
            end if 
        end if
    end if

    if alive = true and quiet_success = false then
        ShowInformationalDialog("Connection success!")
    else if alive = false and quiet_failure = false then
        msg = "Failed to connect to server."
        if error <> invalid then
            msg = msg + " '" + error + "'"
        end if 
        ShowErrorDialog(msg)
    end if

    return false
end function

REM ***************************************************************
REM
REM ***************************************************************
function getVersionErrMsg(cVersion as String, sVersion as String) as String
    cvParts = cVersion.Tokenize(".")
    cMajor = cvParts[0]
    cMinor = cvParts[1]
    svParts = sVersion.Tokenize(".")
    sMajor = svParts[0]
    sMinor = svParts[1]
    compatible = true
    if cMajor <> sMajor then
        compatible = false
    else if Val(sMinor) < val(cMinor) then
        compatible = false
    end if
    if compatible = true then
        return "OK"
    else 
        return "Server API version " + cMajor + "." + cMinor + ".x" +  " or later required"
    end if
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
        pathIndex = 0
        if left(serverUrl, 7) <> "http://" and left(serverUrl, 8) <> "https://" then
            serverUrl = "http://" + serverUrl
            pathIndex = 8
        else 
            if left(serverUrl, 8) = "https://" then
                pathIndex = 9
            else
                pathIndex = 8
            end if
        end if
        if instr(pathIndex, serverUrl, ":") = 0  and left(serverUrl, 8) <> "https://" then
            if instr(pathIndex, serverUrl, "/") = 0 then
                serverUrl = serverUrl + ":4040"
            else
                pathIndex = instr(pathIndex, serverUrl, "/")
                serverUrl = mid(serverUrl, 1, pathIndex - 1) + ":4040" + mid(serverUrl, pathIndex)
            end if
        end if
        return serverUrl + "/rest"
    else
        return invalid
    end if
end function

REM ***************************************************************
REM
REM ***************************************************************
function getApiVersion() as String
  return "1.4.0"
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
function getScreensaverMode() as Dynamic 
    sec = CreateObject("roRegistrySection", "Settings")
    if sec.Exists("screensaverMode") then
        return sec.Read("screensaverMode")
    else
        return getDefaultScreensaverMode()
    end if
end function

REM ***************************************************************
REM
REM ***************************************************************
function getNextScreensaverMode() as Dynamic 
    m.screensaverModes.Reset()
    currentMode = getScreensaverMode()
    while  m.screenSaverModes.IsNext()
        item = m.screenSaverModes.Next()
        if item = currentMode then
            if m.screensaverModes.IsNext()
                return m.screensaverModes.Next()
            else
                return m.screensaverModes.GetHead()
            end if
        end if
    end while
    return invalid
end function

REM ***************************************************************
REM
REM ***************************************************************
function getDefaultScreensaverMode() as String 
    return m.screensaverModes.GetHead() 'Smooth
end function

REM ***************************************************************
REM
REM ***************************************************************
function setScreensaverMode(mode as String) as String
    sec = CreateObject("roRegistrySection", "Settings")
    sec.Write("screensaverMode", mode)
    sec.Flush()
end function

REM ***************************************************************
REM
REM ***************************************************************
function getClient() as String
  return "roku"
end function

REM ***************************************************************
REM
REM ***************************************************************
function CreateArtistItemFromXml(artist as Object) as Dynamic
    item = CreateObject("roAssociativeArray")
    item.Type = "artist"
    item.Id = artist@id
    item.Title = artist@name
    item.ShortDescriptionLine1 = artist@name 
    item.Url = createSubsonicUrl("getMusicDirectory.view", {id: artist@id})
    item.SDPosterUrl = "pkg:/images/buttons/artist.png"
    item.HDPosterUrl = "pkg:/images/buttons/artist.png"
    return item
end function

REM ***************************************************************
REM
REM ***************************************************************
function CreateAlbumItemFromXml(album as Object) as Dynamic
    if album@isDir = "false" then
        return invalid
    end if

    item = CreateObject("roAssociativeArray")
    item.Id = album@id
    item.Type = "album"
    item.Title = album@title
    item.Artist = album@artist
    item.ShortDescriptionLine1 = album@title
    item.ShortDescriptionLine2 = album@artist
    item.Url = createSubsonicUrl("getMusicDirectory.view", {id: album@id})
    if album@coverArt <> invalid then
        item.SDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: album@coverArt})
        item.HDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: album@coverArt})
    endif
    return item
end function

REM ***************************************************************
REM
REM ***************************************************************
function CreateSongItemFromXml(song as Object) as Dynamic
    if song@isDir = "true" then
        return invalid
    end if

    item = CreateObject("roAssociativeArray")
    item.Id = song@id
    item.Type = "song"
    item.ContentType = "audio"
    item.Title = song@title
    item.Artist = song@artist
    item.Album = song@album
    if song@duration <> invalid then
        item.Length = strtoi(song@duration)
    else
        print "Missing duration "; song@title
        item.Length = invalid 
    end if
    item.ShortDescriptionLine1 = song@title
    item.ShortDescriptionLine2 = song@album + " - " + song@artist

    item.ContentType = "audio"
    item.StreamFormat = invalid

    ' According to the Component Reference, roAudioPlayer only supports
    ' WMA or MP3
    if song@contentType = "audio/mpeg" then
        item.StreamFormat = "mp3"
    else if song@transcodedContentType = "audio/mpeg"
        item.StreamFormat = "mp3"
    end if

    if item.StreamFormat <> invalid then
        item.Url = createSubsonicUrl("stream.view", {id: song@id})
    end if

    if song@coverArt <> invalid then
       item.SDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: song@coverArt})
       item.HDPosterUrl = createSubsonicUrl("getCoverArt.view", {id: song@coverArt})
    endif

    return item
end function

REM ***************************************************************
REM
REM ***************************************************************
function setScreenSaverCoverArtUrl(item as dynamic) 
    if item.HDPosterUrl <> invalid and item.SDPosterUrl <> invalid then
        SaveCoverArtForScreenSaver(item.HDPosterUrl, item.SDPosterUrl)
    else 
        SaveCoverArtForScreenSaver("", "")
        'use default image if current item has no cover art
    end if
end function
