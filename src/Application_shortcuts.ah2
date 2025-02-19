#Requires AutoHotkey 2.0+    ; Needs v2
#SingleInstance Force        ; Run only one instance

global AllWindows := Array() ; Array of all windows

; --------- Opening/Quiting Applications ---------

class WinClass {

    ; defining: hwnd, actualW, actualH, x, y, w, h, borderW, borderH
    __New(hwnd) {
        this.hwnd := hwnd
        this.state := 'n'

        WinGetClientPos(, , &actualW, &actualH, this.hwnd)
        this.actualW := actualW
        this.actualH := actualH

        this.UpdatePos()

        this.borderW := this.w - this.actualW
        this.borderH := this.h - this.actualH

        this.pid := WinGetPID(hwnd)
        this.application := "ahk_exe " WinGetProcessName(this.hwnd)

        ; If the window is a UWP app, get the child hwnd
        if WinGetProcessName(hwnd) = "ApplicationFrameHost.exe" {
            this.application := "UWP"
        }
            
        this.path := WinGetProcessPath(this.hwnd)
    }

    UpdatePos(prevState := this.state) {
        WinGetPos(&x, &y, &w, &h, this.hwnd)
        this.x := x
        this.y := y
        this.w := w
        this.h := h
        this.state := prevState ; if prevState is empty, set it to state
    }

    Move(side) { ; Move window to left or right side

        ; Save previous data
        this.prevX := this.x
        this.prevY := this.y
        this.prevW := this.w
        this.prevH := this.h
        this.prevState := this.state

        if side = "Left" {
            WinMove -this.borderW//2, -this.borderH//2, A_ScreenWidth//2 + this.borderW, A_ScreenHeight + this.borderH, this.hwnd ; Move to left side
            this.state := 'l'
        } else if side = "Right" {
            WinMove A_ScreenWidth // 2 - this.borderW//2, -this.borderH//2, A_ScreenWidth//2 + this.borderW, A_ScreenHeight + this.borderH, this.hwnd ; Move to right side
            this.state := 'r'
        }
        ; Update the position
        this.UpdatePos()
    }

    Activate() {
        WinActivate this.hwnd
    }

    Quit() {
    }

    Maximize() { ; Maximize the window

        if this.state != 'm' {
            this.prevX := this.x
            this.prevY := this.y
            this.prevW := this.w
            this.prevH := this.h
            this.prevState := this.state
            try { ; Some windows cannot be moved or resized by this command
                WinMove -this.borderW/2, -this.borderH/2, A_ScreenWidth + this.borderW, A_ScreenHeight + this.borderH, this.hwnd
                this.state := 'm'
            }
        } else {
            WinMove this.prevX, this.prevY, this.prevW, this.prevH, this.hwnd
            this.UpdatePos(this.prevState)
        }
    }

    PrintData() { ; debugging
        MsgBox "x: " this.x ", y: " this.y " width: " this.w ", height: " this.h ", State: " this.state ", hwnd: " this.hwnd ", application: " this.application
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

    hwnds := WinGetList()
    for hwnd in hwnds {
        winInfo := WinGetStyle(hwnd)
        win := GetWindowObj(hwnd)
        if Type(win) = "Integer" and winInfo & 0x10000000 { ; If the window is not registered and visible
            win := WinClass(hwnd)
            AllWindows.Push(win)
        }
    }
}

SetTimer CheckAllWindows, 250

^<^>!C:: OpenApplication "ahk_exe chrome.exe", "C:\Program Files (x86)\Chromium\chrome-win\chrome.exe"
^<^>!G:: OpenApplication "ahk_exe GitHubDesktop.exe", "C:\Users\adhos\AppData\Local\GitHubDesktop\GitHubDesktop.exe"
^<^>!O:: OpenApplication "ahk_exe opera.exe", "C:\Users\adhos\AppData\Local\Programs\Opera\opera.exe"
^<^>!M:: OpenApplication "ahk_exe OUTLOOK.exe", "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.exe"
^<^>!E:: OpenApplication "ahk_exe explorer.exe", "C:\Windows\explorer.exe"
^<^>!V:: OpenApplication "ahk_exe Code.exe", "C:\Users\adhos\AppData\Local\Programs\Microsoft VS Code\Code.exe"
^<^>!W:: OpenApplication "ahk_exe WhatsApp.exe", "C:\Program Files\WindowsApps\5319275A.WhatsAppDesktop_2.2504.2.0_x64__cv1g1gvanyjgm\WhatsApp.exe"
^<^>!N:: OpenApplication "ahk_exe onenoteim.exe", "C:\Program Files\WindowsApps\Microsoft.Office.OneNote_16001.14326.22094.0_x64__8wekyb3d8bbwe\onenoteim.exe"
^<^>!S:: OpenApplication "ahk_exe Spotify.exe", "C:\Program Files\WindowsApps\SpotifyAB.SpotifyMusic_1.256.502.0_x64__zpdnekdrzrea0\Spotify.exe"
^<^>!T:: OpenApplication "ahk_exe cmd.exe", "C:\Windows\System32\cmd.exe"

OpenApplication(application, path) {

    hwnd := WinExist(application)

    if hwnd = 0 {
        CreateWindow(path)
    } else {
        CycleAllWindows(application)
    }
}

CreateWindow(path) {
    Run path, , 'Min' ; Start Application
}

^Q:: ; Quiting the window
{
    WinClose "A"
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
            if StrCompare(win.application, application) = 0 and DllCall("bin\VirtualDesktopAccessor.dll\IsWindowOnCurrentVirtualDesktop", "Ptr", win.hwnd) {
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
        win.Move("Left")
    }
}
^Right:: { ; Ctrl + Right moves window to the right half
    hwnd := WinGetID("A")
    win := GetWindowObj(hwnd)
    try {
        win.Move("Right") 
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
    CreateWindow(win.path)
}

^+Y:: {
    hwnd := WinExist("A")
    win := GetWindowObj(hwnd)
    try {
        win.PrintData()
    }
}

; --------- Made by Ai (Copilot, Blackbox, ChatGPT, Claude) ---------

GetPackageFullNameForUWP(hwnd) {
    ; Get window process ID
    winProcessId := 0
    DllCall("GetWindowThreadProcessId", "Ptr", hwnd, "UInt*", &winProcessId)
    
    ; Open process with PROCESS_QUERY_LIMITED_INFORMATION access rights
    hProcess := DllCall("OpenProcess", "UInt", 0x1000, "Int", 0, "UInt", winProcessId, "Ptr")
    
    if (!hProcess) {
        MsgBox("Failed to open process. Error: " A_LastError)
        return "Error: Could not open process"
    }
    
    ; Get the package full name
    length := 0
    result := DllCall("GetPackageFullName", "Ptr", hProcess, "UInt*", &length, "Ptr", 0)
    
    if (result = 15700) { ; APPMODEL_ERROR_NO_PACKAGE
        MsgBox("The process is not a UWP application.")
        DllCall("CloseHandle", "Ptr", hProcess)
        return "Error: The process is not a UWP application"
    }
    
    if (result != 0) {
        MsgBox("GetPackageFullName failed. Error: " result)
        DllCall("CloseHandle", "Ptr", hProcess)
        return "Error: GetPackageFullName failed"
    }
    
    if (length > 0) {
        packageName := Buffer(length * 2)
        result := DllCall("GetPackageFullName", "Ptr", hProcess, "UInt*", &length, "Ptr", packageName)
        
        DllCall("CloseHandle", "Ptr", hProcess)
        
        if (result == 0) {
            returnVal := StrGet(packageName)
            MsgBox("Retrieved Package Full Name: '" returnVal "'")
            return returnVal
        } else {
            return "Error in second call: " result
        }
    } else {
        DllCall("CloseHandle", "Ptr", hProcess)
        return "Error: No Package Full Name available"
    }
}

^+$:: ; Removing Taskbar (copied from internet: https://www.autohotkey.com/boards/viewtopic.php?t=113325)
{ 
    static ABM_SETSTATE := 0xA, ABS_AUTOHIDE := 0x1, ABS_ALWAYSONTOP := 0x2
    static hide := 0
    hide := not hide
    APPBARDATA := Buffer(size := 2*A_PtrSize + 2*4 + 16 + A_PtrSize, 0)
    NumPut("UInt", size, APPBARDATA), NumPut("Ptr", WinExist("ahk_class Shell_TrayWnd"), APPBARDATA, A_PtrSize)
    NumPut("UInt", hide ? ABS_AUTOHIDE : ABS_ALWAYSONTOP, APPBARDATA, size - A_PtrSize)
    DllCall("Shell32\SHAppBarMessage", "UInt", ABM_SETSTATE, "Ptr", APPBARDATA)
}
