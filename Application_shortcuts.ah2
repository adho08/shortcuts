#Requires AutoHotkey 2.0+    ; Needs v2
#SingleInstance Force        ; Run only one instance

global Windows := Array()

global DesktopHwnds := Array()
Desktop := WinGetList("ahk_exe explorer.exe")
Desktop_id := ""

; --------- Opening/Quiting Applications ---------

class WinClass {

    hwnd := 0
    application := "ahk_exe "
    actualW := 0
    actualH := 0
    borderW := 0
    borderH := 0
    x := 0
    y := 0
    w := 0
    h := 0
    state := 'n'
    prevX := 0
    prevY := 0
    prevW := 0
    prevH := 0
    prevState := 'n'
    lastActivatedIndex := 0
    desktopHwnd := 0

    ; defining: hwnd, actualW, actualH, x, y, w, h, borderW, borderH
    __New(hwnd) {
        this.hwnd := hwnd

        WinGetClientPos(, , &actualW, &actualH, this.hwnd)
        this.actualW := actualW
        this.actualH := actualH

        this.UpdatePos()

        this.borderW := this.w - this.actualW
        this.borderH := this.h- this.actualH

        this.application := WinGetProcessName(this.hwnd)
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

        ; Save the previous position
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
        appWindows := Array()

        ; Create an array of windows with the same application and desktop
        for win in Windows {
            if win.application = this.application and DllCall("VirtualDesktopAccessor.dll\IsWindowOnCurrentVirtualDesktop", "Ptr", win.hwnd) {
                appWindows.Push(win.hwnd)
            }
        }

        if this.lastActivatedIndex > appWindows.Length {
            this.lastActivatedIndex := appWindows.Length
        }

        ; Activate the next window in the cycle
        if appWindows.Length > 0 {
            this.lastActivatedIndex := Mod((this.lastActivatedIndex), appWindows.Length) + 1
            WinActivate appWindows[this.lastActivatedIndex]
        }
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

            WinMove -this.borderW/2, -this.borderH/2, A_ScreenWidth + this.borderW, A_ScreenHeight + this.borderH, this.hwnd

            this.state := 'm'
        } else {
            WinMove this.prevX, this.prevY, this.prevW, this.prevH, this.hwnd
            this.UpdatePos(this.prevState)
        }
    }

    PrintData() { ; debugging
        MsgBox "x: " this.x ", y: " this.y " width: " this.w ", height: " this.h ", State: " this.state ", hwnd: " this.hwnd ", desktop hwnd: " this.desktopHwnd ", application: " this.application
    }
}

; --------- Opening/Quiting Applications ---------

CheckWindows() { ; Checks if every window is registered

    ; If any window is closed, remove it from the list automatically
    for window in Windows {
        if WinExist("ahk_id " window.hwnd) = 0 {
            Windows.RemoveAt A_Index
            window := "" ; losing the reference to object
        }
    }

    hwnds := WinGetList()
    for hwnd in hwnds {
        winInfo := WinGetStyle(hwnd)
        win := GetWindowObj(hwnd)
        if Type(win) = "Integer" and winInfo & 0x10000000 { ; If the window is not registered and visible
            win := WinClass(hwnd)
            Windows.Push(win)
        }
    }
}

; SetTimer CheckWindows, 1000

^<^>!C:: OpenApplication "ahk_exe chrome.exe", "C:\Program Files (x86)\Chromium\chrome-win\chrome.exe"
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
        Run path, , , &pid ; Start Application
        WinWait "ahk_pid " pid, , 1
        hwnd := WinGetID(application)
        win := WinClass(hwnd)
        win.Maximize()
        Windows.Push(win)
        WinRestore hwnd
    } else {
        win := GetWindowObj(hwnd)
        if Type(win) != "Integer" {
            win.Activate()
        }
    }
}

^Q:: ; Quiting the Window
{
    hwnd := WinGetID("A") ; Get the active window's HWND

    win := GetWindowObj(hwnd)
    WinClose hwnd

    for window in Windows {
        if window.hwnd = hwnd {
            Windows.RemoveAt A_Index
            window := "" ; losing the reference to object
            MsgBox hwnd " " Windows[A_Index].hwnd
            break
        }
    }
}

; --------- Window Manager ---------

GetWindowObj(hwnd) {

    for w in Windows {
        if w.hwnd = hwnd {
            return w
        }
    }
    return 0
}

^Left:: { ; Ctrl + Left moves window to the left half
    hwnd := WinExist("A")
    win := GetWindowObj(hwnd)
    if Type(win) != "Integer" {
        win.Move("Left")
    }
}
^Right:: { ; Ctrl + Right moves window to the right half
    hwnd := WinExist("A")
    win := GetWindowObj(hwnd)
    if Type(win) != "Integer" {
        win.Move("Right") 
    }
}

^M:: { ; Ctrl + M maximizes the window
    hwnd := WinExist("A")
    win := GetWindowObj(hwnd)
    if Type(win) != "Integer" {
        win.Maximize()
    }
}

^+Y:: {
    hwnd := WinExist("A")
    win := GetWindowObj(hwnd)
    if win != "Integer" {
        win.PrintData()
    }
}

^+N:: {
    CheckWindows()
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
