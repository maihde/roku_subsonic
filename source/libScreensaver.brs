REM ******************************************************
REM vim: et: sw=4
REM
REM ROKU Channel supporting the Subsonic Media Server
REM
REM Copyright (C) 2011 Michael Ihde
REM Copyright (C) 2011 Mark Leone
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

' Creates ScreensaverCanvas object. A ScreensaverCanvas helps create simple
' image animations using the roImageCanvas component. Technically this
' is more generic than just a screensaver canvas, but I didn't want to imply
' it would be useful for much else so I didn't give it a more generic name.
'
' You must provide the following via either the CreateScreensaverCanvas() function
' or via the appropriate SetXXX function on the ScreensaverCanvas object.
'
'   image_func: A function that returns the image to render. This function is called for
'               every iteration. An image is something that implements the following:
'            GetHeight()  - The height of the image in pixels.
'            GetWidth()   - The width of the image in pixels.
'            Update()     - Called when the image will be updated on the screen.
'                           The new location for the image is provided as parameters.
'                           Returns a content list that is compatible with roGraphicsScreen.
'   location_func: A function with a signature identical to screensaverLib_RandomLocation.
'                  This function is called every loc_update_period milliseconds.
'   underscan: The amount (as a percentage) to reduce the size of the canvas in order
'              to avoid partially drawn images on the edges. Default is 0.
'   update_period: How often to update the image in milliseconds. Default is 6 seconds.
'                  Every update_period milliseconds, Update() is called on the provided
'                  image and the screen is updated.
'   loc_update_period: How often a new location is generated using the location_func. This
'                      may be different from update_period if you want the image to update
'                      more frequently then it moves. A bouncing clock with a moving second
'                      hand is a good example of when this might be the case.
'
Function CreateScreensaverCanvas(background_color = invalid, prt=invalid, loc_func=invalid, image_func=invalid)
    o = CreateObject("roAssociativeArray")
    o.canvas = CreateObject("roImageCanvas")
    if (background_color <> invalid) then o.canvas.SetBackgroundColor(background_color)
    
    o.Show                = function() : m.canvas.Show() : end function
    o.Update              = screensaverCanvas_Update
    o.Go                  = screensaverCanvas_Go
    o.SetUnderscan        = screensaverCanvas_SetUnderscan
    ' Store the function pointers into an array so that when they are called they
    ' can access global m members if they want to. There is no benefit in giving them
    ' access to members of this object.
    o.func_array             = CreateObject("roArray",2,false)
    o.SetImageFunc           = function(image_func)         : m.func_array[0]  = image_func             : end function
    o.SetLocFunc             = function(loc_func)           : m.func_array[1]  = loc_func               : end function
    o.SetUpdatePeriodInMS    = function(update_period)      : m.update_period  = update_period          : end function
    o.SetLocUpdatePeriodInMS = function(loc_update_period)  : m.loc_update_period  = loc_update_period  : end function

    o.func_array[0]  = image_func
    o.func_array[1]  = loc_func
    o.prt            = prt
    o.loc            = invalid
    o.underscan      = 0
    ' Default is 6 seconds
    o.update_period     = 6000
    ' Default of 0, which really means at the same time as the update_period
    o.loc_update_period = 0
    ' Period for changing screensaver mode when Random mode selected
    o.mode_update_period = 60000
    
    ' Create a message port if one wasn't provided.
    if (o.prt=invalid) then o.prt = CreateObject("roMessagePort")
    o.canvas.SetMessagePort(o.prt)

    ' Setup the default screen
    canvas_size = o.canvas.GetCanvasRect()
    o.raw_scr = {width:canvas_size.w,height:canvas_size.h}
    o.scr = o.raw_scr
    o.mode = invalid
    return o
End Function

' Shows the underlying screen and updates the screen at the given
' update rate.  Doesn't return until the screen has been closed.
Sub screensaverCanvas_Go() 
    loc_timer   =  CreateObject("roTimespan")
    update_timer =  CreateObject("roTimespan")
    mode_timer =  CreateObject("roTimespan")
    loc_timer.Mark()
    update_timer.Mark()
    mode_timer.Mark()
    m.canvas.Show()
    first_time=true

    while(true)
        msg = wait(20,m.prt)
        if (msg = invalid) then
            ' First time. Update no matter what.
            if first_time then
                m.Update(true)
                first_time = false
            else
                newLoc = false
                if (update_timer.TotalMilliseconds() > m.update_period) then
                    if (loc_timer.TotalMilliseconds() > m.loc_update_period) then 
                        newloc = true
                        loc_timer.Mark()
                    end if
                    if (getScreensaverMode() = "Random" and mode_timer.TotalMilliseconds() > m.mode_update_period) then 
                        setNewMode(m)
                        newLoc = true
                        mode_timer.Mark()
                    end if
                    update_timer.Mark()
                    m.Update(newloc)
                end if
            end if
         else
             if (type(msg) = "roImageCanvas") then
                 if (msg.isScreenClosed()) then return
             end if
         end if
     end while
End Sub

Sub setNewMode(canvas as Object)
    'ensure new mode is not same as old one
    mode = canvas.mode
    while mode = canvas.mode
        mode = Rnd(3)
    end while
    canvas.mode = mode
    canvas_size = canvas.canvas.GetCanvasRect()
    canvas.raw_scr = {width:canvas_size.w,height:canvas_size.h}
    canvas.scr = canvas.raw_scr
    if (mode = 1) then
        print "Running bouncing animation mode."
        canvas.SetLocFunc(screensaverLib_RandomLocation)
        canvas.SetUpdatePeriodInMS(6000)
        canvas.SetUnderscan(.09)
    else if (mode = 2) then
        print "Running smooth animation mode."
        canvas.SetLocFunc(screensaverLib_SmoothAnimation)
        canvas.SetUpdatePeriodInMS(50)
        canvas.SetUnderscan(.07)
    else if (mode = 3) then
        print "Running Corners animation mode."
        canvas.SetLocFunc(screensaverLib_CornerLocations)
        canvas.SetUpdatePeriodInMS(6000)
        canvas.SetUnderscan(.09)
    end if
end Sub

' Equivalent to a single iteration of Go(). This is useful if the caller
' wants to control the main UI loop. Everytime this method is called the screen is
' updated. Neither the update_period or loc_update_period have any bearing
' when using this function directly. Both are completely up to the client.
Function screensaverCanvas_Update(generateNewLoc = true)    
    image = m.func_array[0]()
    if (generateNewLoc = true) then
        m.loc = m.func_array[1](m.scr,image.GetWidth(),image.GetHeight(),m.loc)
    end if
    m.canvas.SetContentList(image.Update(m.loc.x,m.loc.y))
End Function

' Set the desired underscan.
' Internally this adjusts the m.scr value to represent the desired screen.
Sub screensaverCanvas_SetUnderscan(underscan)
    m.underscan = underscan
    m.scr = screensaverLib_CalcUnderscan(m.scr.width,m.scr.height,underscan)
End Sub

' Calculates the new canvas size given the size of the screen and an
' underscan percentage. Returns an roAssociativeArray with the following
' members:
'     x (Integer)      - The new starting x location (instead of 0)
'     y (Integer)      - The new starting y location (instead of 0)
'     width (Integer)  - The new width
'     height (Integer) - The new height
Function screensaverLib_CalcUnderscan(screen_width,screen_height,underscan)
    scr = CreateObject("roAssociativeArray")
    width_reduction = Int((screen_width*underscan)/2)
    height_reduction = Int((screen_height*underscan)/2)
    scr.x      = width_reduction
    scr.width  = screen_width - (width_reduction*2)
    scr.y      = height_reduction
    scr.height = screen_height - (height_reduction*2)
    return scr
End Function

' A random location generator.
' Given a screen (like that returned from screensaverLib_CalcUnderscan) and
' an image size this function returns an roAssociativeArray with x and y members
' that represent the points on the screen where the image should be
' drawn.
'
' The loc is passed is as it's part of the standard function signature
' invoked by the Update method. loc is the current loc or invalid
' if this is the first invocation. This function doesn't need it, but
' others do. loc is an roAssociativeArray. The key members are x and y.
' It can be used to store function specific state beyond x and y if
' necessary.
Function screensaverLib_RandomLocation(scr, image_width, image_height, loc)
    if (loc = invalid) then loc = {x:scr.x,y:scr.y}
    width_range = scr.width-image_width
    height_range = scr.height-image_height
    loc.x = Rnd(scr.width-image_width) + scr.x
    loc.y = Rnd(scr.height-image_height) + scr.y
    return loc
End Function

' Similar to screensaverLib_RandomLocations except that it repeatedly
' generates locations in the four corners of the screen.
'
' Uses loc to store the last corner generated.
Function screensaverLib_CornerLocations(scr, image_width, image_height, loc)
    ' Ensure a different corner is chosen
    if (loc = invalid) then
        loc = {x:scr.x,y:scr.y,corner:invalid}
    end if
    corner = loc.corner
    while corner = loc.corner
        corner = Rnd(4)
    end while
    loc.corner = corner
    
    if (loc.corner = 1) then
        'TOP RIGHT
        loc.x = scr.width + scr.x - image_width
        loc.y = scr.y
    else if (loc.corner = 2) then
        'BOTTOM RIGHT
        loc.x = scr.width  + scr.x - image_width
        loc.y = scr.height + scr.y - image_height
    else if (loc.corner = 3) then
        'BOTTOM LEFT
        loc.x = scr.x
        loc.y = scr.height + scr.y - image_height
    else if (loc.corner = 4) then
        'TOP LEFT
        loc.x = scr.x
        loc.y = scr.y
    end if
    return loc
End Function

' Similar to screensaverLib_RandomLocation except that it attempts
' to generate locations that would create smooth animation where the
' image travels across the screen. When it hits the perimeter it starts
' traveling in the opposite direction. 
'
' Uses loc to store the current velocity in addition to the last location.
Function screensaverLib_SmoothAnimation(scr, image_width, image_height, loc)
    ' Pick a random start location
    if (loc = invalid or loc.velocity_x = invalid or loc.velocity_y = invalid) then
        loc = screensaverLib_RandomLocation(scr,image_width,image_height,invalid)
        loc.velocity_x=1
        loc.velocity_y=1
    end if

    ' Check for outer edge collision
    if (loc.x <= scr.x or loc.x + image_width >= scr.width)
        loc.velocity_x = -(loc.velocity_x)
    end if
        
    if (loc.y <= scr.y or loc.y + image_height >= scr.height)
        loc.velocity_y = -(loc.velocity_y)
    end if

    ' Update the location
    loc.x = loc.x + loc.velocity_x
    loc.y = loc.y + loc.velocity_y
    return loc
End Function

' For testing. Always returns the top left. 
Function screensaverLib_UpperLeft(scr, image_width, image_height, loc)
    return {x:scr.x, y:scr.y}
End Function
