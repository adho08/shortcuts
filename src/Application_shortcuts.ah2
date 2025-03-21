#Requires AutoHotkey 2.0+    ; Needs v2
#SingleInstance Force        ; Run only one instance
try { ; By try there is no error Msgbox if user doesn't allow admin access
    if !A_IsAdmin {
        Run "*RunAs " A_ScriptFullPath
    }
}

reziseChange := 50
moveChange := 50

global AllWindows := Array() ; Array of all windows
global WM_GETMINMAXINFO := 0x0024

; --------- Opening/Quiting Applications ---------

class WinClass {

    ; defining: hwnd, actualW, actualH, x, y, w, h, borderW, borderH
    __New(hwnd) {
        this.hwnd := hwnd
        this.state := 'n'

        this.Update()
	this.SafeData()

        this.borderX := this.w - this.actualW
        this.borderY := this.h - this.actualH

        try {
            this.pid := WinGetPID(hwnd)
        }

        this.application := ""

        ; Some windows are hosted by ApplicationFrameHost.exe (E.g. Calculator, OneNote for Windows 10, etc.)

        try {
            this.application := "ahk_exe " WinGetProcessName(this.hwnd)
        }

        try {
            this.path := WinGetProcessPath(this.hwnd)
        }

        this.dockedL := false
        this.dockedR := false
        this.dockedU := false
        this.dockedD := false

        ; Keeping the values for coordinates of window in variables to avoid repeated and easy-changable code
        this.left := -this.borderX/2
        this.right := A_ScreenWidth + this.borderX
        this.top := -this.borderY/2 + 1
        this.bottom := A_ScreenHeight + this.borderY + 1
        this.middleX := this.left + A_ScreenWidth/2
        this.middleY := this.top + A_ScreenHeight/2

        ; Keeping the values for width and height of window in variables to avoid repeated and easy-changable code
        this.screenwidth := A_ScreenWidth + this.borderX
        this.screenheight := A_ScreenHeight + this.borderY
        this.halfscreenwidth := A_ScreenWidth/2 + this.borderX
        this.halfscreenheight := A_ScreenHeight/2 + this.borderY

        ; ----------- generated -----------

        MINMAXINFO := Buffer(40, 0)
        SendMessage WM_GETMINMAXINFO,, MINMAXINFO.Ptr,,"ahk_id " this.hwnd ; WM_GETMINMAXINFO := 0x24
        this.minW := NumGet(MINMAXINFO, 24, "Int") ;ptMinTrackSize
        this.minH := NumGet(MINMAXINFO, 28, "Int")
    }

    Update(prevState := this.state) {
        WinGetPos(&x, &y, &w, &h, this.hwnd)
        ; Update the position
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        
        this.prevState := prevState

        WinGetClientPos(&actualX, &actualY, &actualW, &actualH, this.hwnd)
        this.actualX := actualX
        this.actualY := actualY
        this.actualW := actualW
        this.actualH := actualH

        ; Check the state of the window
        
    }

    MoveTo(horizontal := "", vertical := "") { ; Move window to left, right, top or bottom half. Additionally it can be moved to either of the 4 corners.

        this.dockedL := false
        this.dockedR := false
        this.dockedU := false
        this.dockedD := false

	this.SafeData()

        if vertical = "" {
            if horizontal = "Left" {
                WinMove this.left, this.top, this.halfscreenwidth, this.screenheight, this.hwnd ; Move to left half
                this.dockedL := true
		this.state := 'l'
            } else if horizontal = "Right" {
                WinMove this.middleX, this.top, this.halfscreenwidth, this.screenheight, this.hwnd ; Move to right half
                this.dockedR := true
		this.state := 'r'
            }
        } else if horizontal = "" {
            if vertical = "Up" {
                WinMove this.left, this.top, this.screenwidth, this.halfscreenheight, this.hwnd ; Move to top half
                this.dockedU := true
		this.state := 'u'
            } else if vertical = "Down" {
                WinMove this.left, this.middleY, this.screenwidth, this.halfscreenheight, this.hwnd ; Move to bottom half
                this.dockedD := true
		this.state := 'd'
            }
        } else {
            if horizontal = "Left" {
                if vertical = "Up" { 
                    WinMove this.left, this.top, this.halfscreenwidth, this.halfscreenheight, this.hwnd ; top-left corner
                    this.dockedL := true
                    this.dockedU := true
		    this.state := 'lu'
                } else if vertical = "Down" {
                    WinMove this.left, this.middleY, this.halfscreenwidth, this.halfscreenheight, this.hwnd ; bottom-left corner
                    this.dockedL := true
                    this.dockedD := true
		    this.state := 'ld'
                }
            } else if horizontal = "Right" {
                if vertical = "Up" {
                    WinMove this.middleX, this.top, this.halfscreenwidth, this.halfscreenheight, this.hwnd ; top-right corner
                    this.dockedR := true
                    this.dockedU := true
		    this.state := 'ru'
                } else if vertical = "Down" {
                    WinMove this.middleX, this.middleY, this.halfscreenwidth, this.halfscreenheight, this.hwnd ; bottom-right corner
                    this.dockedR := true
                    this.dockedD := true
		    this.state := 'rd'
                }
            }
        }

        ; Update the position
        this.Update()
    }

    Activate() {
        WinActivate this.hwnd
    }

    Quit() {
    }

    Maximize() {


        if this.state != 'm' {
            try { ; Some windows cannot be moved or resized by this command

		this.SafeData()

                WinMove -this.borderX/2, -this.borderY/2, A_ScreenWidth + this.borderX, A_ScreenHeight + this.borderY, this.hwnd
                this.state := 'm'

                ; If docked in every side was to be true, resizing would not be possible anymore
                this.dockedL := false
                this.dockedR := false
                this.dockedU := false
                this.dockedD := false
            }
        } else {
            WinMove this.prevX, this.prevY, this.prevW, this.prevH, this.hwnd
            this.state := 'n'
        }
        this.Update(this.prevState)
    }

    Resize(changeW := 0, changeH := 0) {

        if (this.actualW + changeW < this.minW) { ; If the next width is less than the minimum width
            changeW := 0
        }
        if (this.actualH + changeH < this.minH) { ; If the next height is less than the minimum height
            changeH := 0
        }

        ; Define the changes in the window size in each direction
        changeL := - changeW/2 
        changeR := changeW
        changeU := - changeH/2
        changeD := changeH

        if this.dockedL or (this.actualX + changeL) <= 0 { ; if the left side of the window is out of the screen
            changeL := 0
            if this.dockedL {
                changeR := changeH/2
            } else {
                changeR := changeH
            }
            this.x := - this.borderX/2 ; resize to border of left side
            changeR := changeW/2
            this.dockedL := true
        }
        if this.dockedR or (this.actualX + this.actualW + changeR) >= A_ScreenWidth { ; if the right side of the window is out of the screen
            changeR := 0
            this.w := A_ScreenWidth + this.borderX / 2 - this.x - changeL ; resize to border of right side
            this.dockedR := true
        }
        if this.dockedU or (this.actualY + changeU) <= 0 { ; if the upper side of the window is out of the screen
            changeU := 0
            this.y := - this.borderY/2 ; resize to border of upper side
            if this.dockedU {
                changeD := changeH/2
            } else {
                changeD := changeH
            }
            this.dockedU := true
        }
        if this.dockedD or (this.actualY + this.actualH + changeD) >= A_ScreenHeight { ; if the lower side of the window is out of the screen
            changeD := 0
            this.h := A_ScreenHeight + this.borderY / 2 - this.y - changeU ; resize to border of lower side
            this.dockedD := true
        }

        if this.dockedL and this.dockedR {
            this.dockedL := false
            this.dockedR := false
        }
        if this.dockedU and this.dockedD {
            this.dockedU := false
            this.dockedD := false
        }       

	this.SafeData()

        WinMove this.x + changeL, this.y + changeU, this.w + changeR, this.h + changeD, this.hwnd

        this.Update()
    }

    Move(changeX := 0, changeY := 0) {

        if this.actualX + changeX < 0 { ; If the window outside the left side of the screen
            changeX := 0
            this.x := -this.borderX/2
            this.dockedL := true
        }
        if this.actualX + this.actualW + changeX > A_ScreenWidth { ; If the window is outside the right side of the screen
            changeX := 0
            this.x := A_ScreenWidth + this.borderX/2 - this.w
            this.dockedR := true
        }
        if this.actualY + changeY < 0 { ; If the window is outside the top side of the screen
            changeY := 0
            this.y := -this.borderY/2
            this.dockedU := true
        }
        if this.actualY + this.actualH + changeY > A_ScreenHeight { ; If the window is outside the bottom side of the screen
            changeY := 0
            this.y := A_ScreenHeight + this.borderY/2 - this.h
            this.dockedD := true
        }

	this.SafeData()

        WinMove this.x + changeX, this.y + changeY, this.w, this.h, this.hwnd

        this.Update()
    }

    PrintData() { ; debugging

        this.Update()

        str := "x: " this.x ", y: " this.y " width: " this.w ", height: " this.h ", r: " this.x + this.w ", b: " this.y + this.h
        str .= "`nminW: " this.minW ", minH: " this.minH
        str .= "`nhwnd: " this.hwnd ", application: " this.application 
	str .= "`nprevX: " this.prevX ", prevY: " this.prevY ", prevW: " this.prevW ", prevH: " this.prevH
        str .= "`nborderX: " this.borderX ", borderY: " this.borderY ", actualW: " this.actualW ", actualH: " this.actualH 
        str .= "`ndockedL: " this.dockedL ", dockedR: " this.dockedR ", dockedU: " this.dockedU ", dockedD: " this.dockedD
        str .= "`nstate: " this.state

        MsgBox str
    }

    SafeData() {
    	
	; Save previous data
        this.prevX := this.x
        this.prevY := this.y
        this.prevW := this.w
        this.prevH := this.h

    }

}

; --------- Opening/Quiting Applications ---------

CheckAllWindows() { ; Checks if every window is registered

    ; If any window is closed, remove it from the list automatically
    for window in AllWindows {
        if WinExist("ahk_id " window.hwnd) = 0 {
            AllWindows.RemoveAt A_Index
            window := "" ; losing the reference to object
        }
    }

    ; Get hwnd of all windows in an array
    hwnds := WinGetList()

    ; Loop through all windows
    for hwnd in hwnds {
        winInfo := WinGetStyle(hwnd)
        win := GetWindowObj(hwnd)
        if !(win is Winclass) and winInfo & 0x10000000 { ; If the window is not registered and visible

            ; Make a new WinClass object for the window
            win := WinClass(hwnd)
            ; Add the window to the list
            AllWindows.Push(win)
        } else if win is Winclass{
            win.Update()
        }
    }
}

SetTimer CheckAllWindows, 250

; Ctrl + Alt Gr + <Letter>
^<^>!C:: OpenApp "Chromium", "ahk_exe chrome.exe"
^<^>!G:: OpenApp "GitHub Desktop"
^<^>!M:: OpenApp "OUTLOOK"
^<^>!V:: OpenApp "Visual Studio Code", "ahk_exe Code.exe"
^<^>!W:: OpenApp "WhatsApp"
^<^>!N:: OpenApp "OneNote"
^<^>!S:: OpenApp "Spotify"
^<^>!T:: OpenApp "Terminal", "ahk_exe WindowsTerminal.exe"
^<^>!E:: OpenApp "File Explorer", "ahk_exe explorer.exe"

OpenApp(appName, processName := "") { ; https:/www.autohotkey.com/boards/viewtopic.php?p=438517#p438517

    if !WinExist("ahk_exe " appName ".exe") and !WinExist(processName) {
        for app in ComObject('Shell.Application').NameSpace('shell:AppsFolder').Items {
            if app.Name = appName {
                RunWait('explorer shell:appsFolder\' app.Path)
            }
        }
    } else {
        if !(processName = "") {
            CycleAllWindows(processName)
        } else {
            CycleAllWindows("ahk_exe " appName ".exe")
        }
    }
}

OpenApplication(application) {

    hwnd := WinExist(application)

    if hwnd = 0 {
        Run application
    } else {
        CycleAllWindows(application)
    }
}

^Q:: ; Quiting the window
{
    try {
        WinKill "A"
    }
}

; --------- Window Manager ---------

GetWindowObj(hwnd) {

    for win in AllWindows {
        if win.hwnd = hwnd {
            return win
        }
    }
    return 0
}

global successive := 1
global lastActivatedApp := ""

CycleAllWindows(application) {

    global successive, lastActivatedApp

    appWindows := Array()

        ; Create an array of windows with the same application and desktop
        for win in AllWindows {
            if StrCompare(win.application, application) = 0 and DllCall("..\bin\VirtualDesktopAccessor.dll\IsWindowOnCurrentVirtualDesktop", "Ptr", win.hwnd) {
                appWindows.Push(win)
            }
        }

        ; Activate the next window in the cycle
        ; If the same application is activated as before, move to the next window in the list
        if StrCompare(application, lastActivatedApp) = 0 {
            successive := Mod(successive, appWindows.Length) + 1
        } else {
        ; If a different application is activated, start from the first window
            successive := 1
        }
        appWindows[successive].Activate()

        lastActivatedApp := application
}

^ö:: { ; Ctrl + ö moves window to the left half or to either corner on left side
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        switch win.state {
            case 'u': win.MoveTo("Left", "Up")
            case 'd': win.MoveTo("Left", "Down")
            default: win.MoveTo("Left", ) 
        }
    }
}
^$:: { ; Ctrl + $ moves window to the right half or to either corner on right side
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        switch win.state {
            case 'u': win.MoveTo("Right", "Up")
            case 'd': win.MoveTo("Right", "Down")
            default: win.MoveTo("Right", ) 
        }
    }
}

^ü:: { ; Ctrl + ü moves window to the top half or to either corner on upper side
hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        switch win.state {
            case 'l': win.MoveTo("Left", "Up")
            case 'r': win.MoveTo("Right", "Up")
            default: win.MoveTo(, "Up") 
        }
    }
}

^ä:: { ; Ctrl + ä moves window to the bottom half or to either corner on lower side
hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        switch win.state {
            case 'l': win.MoveTo("Left", "Down")
            case 'r': win.MoveTo("Right", "Down")
            default: win.MoveTo(, "Down") 
        }
    }
}

!ö:: { ; Alt + ö makes the window smaller in x
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Resize(-reziseChange, )
    }
}

!$:: { ; Alt + $ makes the window bigger in x
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Resize(reziseChange, )
    }
}

!ü:: { ; Alt + ü makes the window bigger in y
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Resize(, reziseChange)
    }
}

!ä:: { ; Alt + ä makes the window smaller in y
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Resize(, -reziseChange)
    }
}

+!ö:: { ; Shift + Alt + ö moves the window in -x direction
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Move(-moveChange, )
        win.dockedR := false
    }
}

+!$:: { ; Shift + Alt + $ moves the window in +x direction
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Move(moveChange, )
        win.dockedL := false
    }
}

+!ü:: { ; Shift + Alt + ü moves the window in -y direction
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Move(, -moveChange)
        win.dockedD := false
    }
}

+!ä:: { ; Shift + Alt + a moves the window in +y direction
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Move(, moveChange)
        win.dockedU := false
    }
}

^M:: { ; Ctrl + M maximizes the window
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.Maximize()
    }
}

^N:: {
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        RunWait win.path
    }
}

^+Y:: {
    hwnd := WinExist("A")
    win := GetWindowObj(hwnd)
    if win is WinClass {
        win.PrintData()
    }
}

^+N:: {
   MonitorGetWorkArea(1, &Left, &Top, &Right, &Bottom)
   WinMove Left, Top, , , "A"
}

RunCMDCommand(command) {
    ; Create hidden CMD process
    cmdHidden := ComObject("WScript.Shell")
    
    ; Execute command and capture output
    exec := cmdHidden.Exec(A_ComSpec " /c " command)
    
    ; Wait for command to complete
    while !exec.Status
        Sleep(100)
    
    ; Get output and return it
    return exec.StdOut.ReadAll()
}

; --------- Made by Ai (Copilot, Blackbox, ChatGPT, Claude) ---------

GetUWPProcessIDViaCOM(windowHwnd) {
    ; Create COM object for Windows Shell
    shell := ComObject("Shell.Application")
    
    ; Get Windows view
    windows := shell.Windows
    
    ; Initialize variables for process info
    procID := 0
    
    try {
        for window in windows {
            ; Try to match the window handle
            if (window.HWND = windowHwnd) {
                ; Get the associated process
                procID := window.ProcessID
                break
            }
        }
    } catch Error as e {
        ; Handle any COM errors
        MsgBox "Error: " e.Message
        return 0
    }
    
    return procID
}

GetMinMaxInfo() { ; https:/www.autohotkey.com/boards/viewtopic.php?t=36412
    Global WM_GETMINMAXINFO
    Static MINMAXINFO := Buffer(40, 0)
    NumPut(0, MINMAXINFO, 24, "Int")
    NumPut(0, MINMAXINFO, 28, "Int")
    NumPut(0, MINMAXINFO, 32, "Int")
    NumPut(0, MINMAXINFO, 36, "Int")
    
    SendMessage(WM_GETMINMAXINFO, 0, MINMAXINFO.Ptr, "A")
    
    return {
        min_x: NumGet(MINMAXINFO, 24, "Int"), 
        min_y: NumGet(MINMAXINFO, 28, "Int"),
        max_x: NumGet(MINMAXINFO, 32, "Int"),
        max_y: NumGet(MINMAXINFO, 36, "Int")
    }
}

; --------- Utility Functions ---------
