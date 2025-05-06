#Requires AutoHotkey 2.0+    ; Needs v2
#SingleInstance Force        ; Run only one instance
try { ; By try there is no error Msgbox if user doesn't allow admin access
    if !A_IsAdmin {
        Run "*RunAs " A_ScriptFullPath
    }
}

global AllWindows := Array() ; Array of all windows

; --------- Opening/Quiting Applications ---------

class WinClass {

    ; defining: hwnd, actualW, actualH, x, y, w, h, borderW, borderH
    __New(hwnd) {
        this.hwnd := hwnd

        try {
            this.pid := WinGetPID(hwnd)
        }

        this.application := ""

        try {
            this.application := "ahk_exe " WinGetProcessName(this.hwnd)
        }

        try {
            this.path := WinGetProcessPath(this.hwnd)
	}
	}

    Activate() {
        WinActivate this.hwnd
    }

    Quit() {
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
	    try {
		winInfo := WinGetStyle(hwnd)
	    }
	win := GetWindowObj(hwnd)
        if !(win is Winclass) { ; If the window is not registered

            ; Make a new WinClass object for the window
            win := WinClass(hwnd)
            ; Add the window to the list
            AllWindows.Push(win)
        }
    }
}

SetTimer CheckAllWindows, 250

; Ctrl + Alt Gr + <Letter>
^<^>!G:: OpenApp "GitHub Desktop"
^<^>!M:: OpenApp "OUTLOOK"
^<^>!V:: OpenApp "Visual Studio Code", "ahk_exe Code.exe"
^<^>!W:: OpenApp "WhatsApp"
^<^>!N:: OpenApp "OneNote"
^<^>!S:: OpenApp "Spotify"
^<^>!T:: OpenApp "Terminal", "ahk_exe WindowsTerminal.exe"
^<^>!F:: OpenApp "Firefox", "ahk_exe firefox.exe"

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
