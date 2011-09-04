' Implements the auidoapp screensaver. This is only run when the
' audioapp application is already running.
'
' The main application writes the url of the current cover art
' to the tmp file system and the screen saver uses that cover art.

' The screensaver entry point.
Sub RunScreenSaver()
    m.filesystem = CreateObject("roFileSystem")
    m.dev = CreateObject("roDeviceInfo")
    m.art_urls = CreateObject("roArray",10,true)
    ' If the main audio app isn't running, then defer to the
    ' default screen saver for now.
    if (not IsMainAppRunning()) then
        print "Main app not running. Exiting."
        return
    end if
    ' If there is no cover art saved from the main application, then
    ' defer to the default screensaver. Remove this if you want to
    ' run the logo screensaver or something else at this point.
    if (GetSavedCoverArtUrl() = "") then
        print "No cover art available. Exiting."
        return
    end if
    DisplayScreenSaver()
End Sub

Sub DisplayScreenSaver()
    ' image "constants"
    m.border_hd    = {url:"pkg:/images/Art_Border_HD.png"              , SourceRect:{w:205,h:210} , TargetRect:{x:0,y:0,w:0,h:0}}
    m.border_sd43  = {url:"pkg:/images/Art_Border_SD43.png"            , SourceRect:{w:138,h:129} , TargetRect:{x:0,y:0,w:0,h:0}}
    m.default_hd   = {url:"pkg:/images/Logo_Overhang_Roku_SDK_HD.png"   , SourceRect:{w:296,h:60}  , TargetRect:{x:0,y:0,w:0,h:0}}
    m.default_sd43 = {url:"pkg:/images/Logo_Overhang_Roku_SDK_SD43.png" , SourceRect:{w:222,h:45}  , TargetRect:{x:0,y:0,w:0,h:0}}

    m.default_image = CreateDefaultScreensaverImage()

    canvas = CreateScreensaverCanvas("#000000")
    canvas.SetImageFunc(GetCoverArtImage)
    ' Always use bouncing for now. Smooth doesn't work quite right.
    ' For smooth to work the script needs to download the cover art to
    ' the tmp file system for setting content on the graphics canvas.
    if (Rnd(1) <> 1) then
        print "Running random bouncing logo."
        canvas.SetLocFunc(screensaverLib_RandomLocation)
        canvas.SetUpdatePeriodInMS(6000)
        canvas.SetUnderscan(.09)
    else
        print "Running smooth animation logo."
        canvas.SetLocFunc(screensaverLib_SmoothAnimation)
        canvas.SetUpdatePeriodInMS(50)
        canvas.SetUnderscan(.07)
    end if
    canvas.Go()
    
End Sub

' Return the appropriate image to display as the screen saver.
' If there is a url available then it returns a cover art image.
' If there is no cover art url available, then it returns a logo.
Function GetCoverArtImage()
    url = GetSavedCoverArtUrl()
    if (url <> "") then
        if (m.last_url <> url) then
            m.last_image = CreateCoverArtImage(url)
            m.last_url = url
        end if
        return m.last_image
    else if (m.art_urls.Count() <> 0)
        if (m.cover_timer = invalid or m.cover_timer.TotalMilliseconds() > 5000) then
            if (m.cover_timer = invalid) then m.cover_timer = CreateObject("roTimespan")
            m.cover_timer.Mark()
            m.last_image = CreateCoverArtImage(m.art_urls[Rnd(m.art_urls.Count())-1])
        end if
        return m.last_image
    else
        return m.default_image
    endif
End Function

' Creates an roAssociativeArray that is compatible with DrawBouncingImage() that
' represents the current playing cover art with a border.
' The border images determine the size of the final composite image. The cover
' art will be scaled to the target size by the roGraphicsCanvas.
Function CreateCoverArtImage(cover_art_url)
    o = CreateObject("roAssociativeArray")
    o.art = {url:cover_art_url}
    if m.dev.GetDisplayAspectRatio() = "16x9" then
        o.border = m.border_hd
        o.art_offset_width  = 6
        o.art_offset_height = 6
        o.art.targetrect = {w:188,h:188}
    else
        o.border = m.border_sd43
        o.art_offset_width  = 5
        o.art_offset_height = 4
        o.art.targetrect = {w:124,h:112}
    end if
    
    o.content_list = [o.art,o.border]
    
    o.GetHeight  = function() :return m.border.SourceRect.h :end function
    o.GetWidth   = function() :return m.border.SourceRect.w :end function

    o.Update = function(x,y)
        m.content_list[0].TargetRect.x = x + m.art_offset_width
        m.content_list[0].TargetRect.y = y + m.art_offset_height
        m.content_list[1].TargetRect.x = x 
        m.content_list[1].TargetRect.y = y 
        return m.content_list
    end function
    
    return o
End Function

' Creates an roAssociativeArray that is compatible with DrawBouncingImage() that
' represents the default screensaver image. This is used if there is no
' cover art currently available. This should only be if the app
' is on the home screen and has not played a file yet.
Function CreateDefaultScreensaverImage()
    o = CreateObject("roAssociativeArray")
    if m.dev.GetDisplayAspectRatio() = "16x9" then
        o.art = m.default_hd
    else
        o.art = m.default_sd43
    end if
    o.content_list = [o.art]

    o.GetHeight  = function() :return m.art.SourceRect.h :end function
    o.GetWidth   = function() :return m.art.SourceRect.w :end function
    o.Update = function(x,y)
        m.art.TargetRect.x = x
        m.art.TargetRect.y = y
        return m.content_list
    end function

    return o
End Function

Sub SetMainAppIsRunning(flag as string)
    WriteFileHelper("tmp:/subsonic_running_signal", flag)
End Sub

Function IsMainAppRunning()
    if ReadAsciiFile("tmp:/subsonic_running_signal") = "true" then
        return true
    else
        return false
    end if
End Function

' Called from the main application when the song changes so
' that the screensaver has the most recent cover art.
Sub SaveCoverArtForScreenSaver(url_SD43,url_HD)
    print "Saving Cover Art URL: " ; url_SD43
    WriteFileHelper("tmp:/cover_art_url_SD43",url_SD43)
    print "Saving Cover Art URL: " ; url_HD
    WriteFileHelper("tmp:/cover_art_url_HD"  ,url_HD)
End Sub

' Simple file write helper. Write to a tmp file then move to the final
' file.
Sub WriteFileHelper(fname, url)
    if (url <> invalid) then
        if (not WriteAsciiFile(fname + "~",url)) then print "WriteAsciiFile() Failed" 
        if (not MoveFile(fname + "~",fname)) then print "MoveFile() failed"
    else
        DeleteFile(fname)
    end if
End Sub

' Retrieve the saved cover art url. Returns the correct
' url depending on the aspect ratio of the device.
Function GetSavedCoverArtUrl()
    if m.dev.GetDisplayAspectRatio() = "16x9" then
        return ReadAsciiFile("tmp:/cover_art_url_HD")
    else
        return ReadAsciiFile("tmp:/cover_art_url_SD43")
    end if
End Function
