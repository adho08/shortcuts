#Requires AutoHotkey 2.0+    ; Needs v2
#SingleInstance Force        ; Run only one instance

global AllWindows := Array() ; Array of all windows
global WM_GETMINMAXINFO := 0x0024

; --------- Opening/Quiting Applications ---------

class WinClass {

    ; defining: hwnd, actualW, actualH, x, y, w, h, borderW, borderH
    __New(hwnd) {
        this.hwnd := hwnd
        this.state := 'n'

        WinGetClientPos(, , &actualW, &actualH, this.hwnd)
        this.actualW := actualW
        this.actualH := actualH

        WinGetPos(&x, &y, &w, &h, this.hwnd)
        this.x := x
        this.y := y
        this.w := w
        this.h := h

        this.borderW := this.w - this.actualW
        this.borderH := this.h - this.actualH

        this.pid := WinGetPID(hwnd)

        this.application := ""
        try { ; Some windows are hosted by ApplicationFrameHost.exe (E.g. Calculator, OneNote for Windows 10, etc.)
            this.application := "ahk_exe " WinGetProcessName(this.hwnd)
        }

        try {
            this.path := WinGetProcessPath(this.hwnd)
        }
    }

    Update(prevState := this.state) {
        ; Save previous data
        this.prevX := this.x
        this.prevY := this.y
        this.prevW := this.w
        this.prevH := this.h
        this.prevState := prevState

        WinGetPos(&x, &y, &w, &h, this.hwnd)
        ; Update the position
        this.x := x
        this.y := y
        this.w := w
        this.h := h
    }

    MoveTo(side) { ; Move window to left or right side

        if side = "Left" {
            WinMove -this.borderW//2, -this.borderH//2, A_ScreenWidth//2 + this.borderW, A_ScreenHeight + this.borderH, this.hwnd ; Move to left side
            this.state := 'l'
        } else if side = "Right" {
            WinMove A_ScreenWidth // 2 - this.borderW//2, -this.borderH//2, A_ScreenWidth//2 + this.borderW, A_ScreenHeight + this.borderH, this.hwnd ; Move to right side
            this.state := 'r'
        }
        ; Update the position
        this.Update()
    }

    Activate() {
        WinActivate this.hwnd
    }

    Quit() {
    }

    Maximize() { ; Maximize the window

        if this.state != 'm' {
            try { ; Some windows cannot be moved or resized by this command
                WinMove -this.borderW/2, -this.borderH/2, A_ScreenWidth + this.borderW, A_ScreenHeight + this.borderH, this.hwnd
                this.state := 'm'
            }
        } else {
            WinMove this.prevX, this.prevY, this.prevW, this.prevH, this.hwnd
        }
        this.Update(this.prevState)
    }

    Resize(changeW := 0, changeH := 0) {
        ; change indicates if the window is being made smaller or bigger
        ; change = negative for smaller, change = positive for bigger, absolute value of sb indicates the change in size
        minW := SysGet(28) ; Get the minimum width of the window (SM_CXMIN)
        minH := SysGet(29) ; Get the minimum height of the window (SM_CYMIN)
        maxW := SysGet(61) ; Get the maximum width of the window (SM_CXMAX)
        maxH := SysGet(62) ; Get the maximum height of the window (SM_CYMAX)

        if (this.w + changeW < minW) { ; If the next reduction is less than the minimum width, window will not be resized
            changeW := 0
        }
        if (this.h + changeH < minH) { ; If the next reduction is less than the minimum height, window will not be resized
            changeH := 0
        }

        changeL := - changeW/2 ; change in the left side
        changeR := changeW ; change in the right side
        changeU := - changeH/2 ; change in the upper side
        changeD := changeH ; change in the lower/down side

        if this.x + changeL < 0 { ; if the left side of the window is out of the screen
            changeL := 0
            changeR := changeW/2
        }
        if this.x + this.w + changeR > A_ScreenWidth { ; if the right side of the window is out of the screen
            changeR := 0
        }
        if this.y + changeU < 0 { ; if the upper side of the window is out of the screen
            changeU := 0
            changeD := changeH/2
        }
        if this.y + this.h + changeD > A_ScreenHeight { ; if the lower side of the window is out of the screen
            changeD := 0
        }

        WinMove this.x + changeL, this.y + changeU, this.w + changeR, this.h + changeD, this.hwnd
        this.Update()
    }

    MakeBigger() {

    }

    Drive() {

    }

    PrintData() { ; debugging
        MsgBox "x: " this.x ", y: " this.y " width: " this.w ", height: " this.h ", State: " this.state ", hwnd: " this.hwnd ", application: " this.application ", PID: " this.pid
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
        if Type(win) = "Integer" and winInfo & 0x10000000 { ; If the window is not registered and visible

            ; Make a new WinClass object for the window
            win := WinClass(hwnd)
            ; Add the window to the list
            AllWindows.Push(win)
        } else {
            win.Update()
        }
    }
}

SetTimer CheckAllWindows, 250

^<^>!C:: OpenApp "Chromium", "ahk_exe chrome.exe"
^<^>!G:: OpenApp "GitHub Desktop"
^<^>!M:: OpenApp "OUTLOOK"
^<^>!E:: OpenApp "explorer"
^<^>!V:: OpenApp "Visual Studio Code", "ahk_exe Code.exe"
^<^>!W:: OpenApp "WhatsApp"
^<^>!N:: OpenApp "OneNote"
^<^>!S:: OpenApp "Spotify"
; ^<^>!T:: OpenApp "command line"

OpenApp(appName, processName := "") { ; https://www.autohotkey.com/boards/viewtopic.php?p=438517#p438517

    if !WinExist("ahk_exe " appName ".exe") and !WinExist(processName) {
        for app in ComObject('Shell.Application').NameSpace('shell:AppsFolder').Items {
            (app.Name = appName) && RunWait('explorer shell:appsFolder\' app.Path)
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

^Left:: { ; Ctrl + Left moves window to the left half
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.MoveTo("Left")
    }
}
^Right:: { ; Ctrl + Right moves window to the right half
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.MoveTo("Right") 
    }
}

^,:: { ; Ctrl + , makes the window smaller in x
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.Resize(-10, )
    }
}

^.:: { ; Ctrl + . makes the window bigger in x
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.Resize(10, )
    }
}

^¨:: { ; Ctrl + ¨ makes the window bigger in y
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.Resize(, 10)
    }
}

^-:: { ; Ctrl + - makes the window smaller in y
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.Resize(, -10)
    }
}

^ö:: { ; Ctrl + ö makes the window bigger in y
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.Move()
    }
}

^M:: { ; Ctrl + M maximizes the window
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.Maximize()
    }
}

^N:: {
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        RunWait win.path
    }
}

^+Y:: {
    hwnd := WinExist("A")
    win := GetWindowObj(hwnd)
    try {
        win.PrintData()
    }
}

^+N:: {
    MyGui := Gui(, "Process List")
    LV := MyGui.Add("ListView", "x2 y0 w400 h500", ["Name"])
    for app in ComObject('Shell.Application').NameSpace('shell:AppsFolder').Items
		LV.Add("", app.Name)
    MyGui.Show()
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

GetMinMaxInfo() { ; https://www.autohotkey.com/boards/viewtopic.php?t=36412
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

