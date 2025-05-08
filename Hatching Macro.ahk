; Made By Aqua :) https://github.com/Kerexus1/aquaGum

#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetKeyDelay, 0
#Include %A_ScriptDir%\libraries
#Include Gdip_All.ahk
#Include %A_ScriptDir%\images

; Variables
global SCREENSHOT_MINUTES := 15
global DISCORD_WEBHOOK := "Enter Webhook URL Here"
global ISSPAMMING := false
global ENABLE_INVENTORY_CHECKS := true
global SETTINGS_FILE := A_ScriptDir . "\HatchingMacro.ini"
global SCREENSHOT_FILE := ""

IniRead, DISCORD_WEBHOOK, %SETTINGS_FILE%, Settings, Webhook, %DISCORD_WEBHOOK%
IniRead, SCREENSHOT_MINUTES, %SETTINGS_FILE%, Settings, ScreenshotMinutes, %SCREENSHOT_MINUTES%
IniRead, ENABLE_INVENTORY_CHECKS, %SETTINGS_FILE%, Settings, EnableInventoryChecks, 1

If (!PTOKEN := Gdip_Startup()) {
    MsgBox, 48, gdiplus error!, Gdip failed to start, please verify you have uncompressed the file correctly.
    ExitApp
}
SetTimer, INITIALIZETOOLTIP, -100
$F1::
    if (!ISSPAMMING) {
        ISSPAMMING := true
        FormatTime, WEBHOOK_TIME, , [HH:mm:ss]
        DESCRIPTION := WEBHOOK_TIME . " Macro Started"
        if (IsValidWebhook(DISCORD_WEBHOOK)) {
            SENDWEBHOOK(DESCRIPTION, 3447003)
        }
        SetTimer, SPAMKEYS, Off
        SetTimer, PERIODICSCREENSHOT, Off
        SetTimer, SPAMKEYS, 1
        if (ENABLE_INVENTORY_CHECKS) {
            SetTimer, PERIODICSCREENSHOT, % SCREENSHOT_MINUTES * 60000
            Gosub, RUNINITIALSEQUENCE
        }
        UPDATETOOLTIP()
    }
return
$F3::
    if (ISSPAMMING) {
        ISSPAMMING := false
        SetTimer, SPAMKEYS, Off
        SetTimer, PERIODICSCREENSHOT, Off
        FormatTime, WEBHOOK_TIME, , [HH:mm:ss]
        DESCRIPTION := WEBHOOK_TIME . " Macro Stopped"
        if (IsValidWebhook(DISCORD_WEBHOOK)) {
            SENDWEBHOOK(DESCRIPTION, 3447003)
        }
        UPDATETOOLTIP()
    }
return
RUNINITIALSEQUENCE:
    Send {f}
    Sleep, 100
    Click, 370, 466
    Sleep, 100
    PixelGetColor, COLOR, 525, 866, RGB
    if (COLORSIMILAR(COLOR, 0x052959)) {
        Click, 525, 866
    }
    TAKESCREENSHOT()
    if (IsValidWebhook(DISCORD_WEBHOOK)) {
        SENDSCREENSHOTTODISCORD()
    } else if (SCREENSHOT_FILE != "" && FileExist(A_ScriptDir . "\" . SCREENSHOT_FILE)) {
        FileDelete, %A_ScriptDir%\%SCREENSHOT_FILE%
    }
    Click, 371, 541
    Send {f}
return
SPAMKEYS:
    if (ISSPAMMING) {
        Send {e}
        Send {r}
    }
return
PERIODICSCREENSHOT:
    if (ISSPAMMING) {
        SetTimer, SPAMKEYS, Off
        Send {s down}
        Sleep, 500
        Send {s up}
        STARTTIME := A_TickCount
        TIMEOUT := 30000
        IMAGEFOUND := false
        while (!IMAGEFOUND && A_TickCount - STARTTIME < TIMEOUT) {
            Send {f}
            Sleep, 100
            ImageSearch, FOUNDX, FOUNDY, 0, 0, %A_ScreenWidth%, %A_ScreenHeight%, *50 %A_ScriptDir%\Images\inventory_close_detect.png
            if (ErrorLevel = 0) {
                IMAGEFOUND := true
            }
        }
        if (!IMAGEFOUND) {
            SetTimer, SPAMKEYS, 1
            return
        }
        Click, 370, 466
        Sleep, 100
        PixelGetColor, COLOR, 525, 866, RGB
        if (COLORSIMILAR(COLOR, 0x052959)) {
            Click, 525, 866
        }
        TAKESCREENSHOT()
        if (IsValidWebhook(DISCORD_WEBHOOK)) {
            SENDSCREENSHOTTODISCORD()
        } else if (SCREENSHOT_FILE != "" && FileExist(A_ScriptDir . "\" . SCREENSHOT_FILE)) {
            FileDelete, %A_ScriptDir%\%SCREENSHOT_FILE%
        }
        Click, 371, 541
        Send {f}
        FormatTime, WEBHOOK_TIME, , [HH:mm:ss]
        DESCRIPTION := WEBHOOK_TIME . " Resuming Hatching"
        if (IsValidWebhook(DISCORD_WEBHOOK)) {
            SENDWEBHOOK(DESCRIPTION, 3447003)
        }
        Send {w down}
        Sleep, 500
        Send {w up}
        SetTimer, SPAMKEYS, 1
    }
return
TAKESCREENSHOT() {
    PBITMAP := Gdip_BitmapFromScreen("323|183|1192|728")
    if (PBITMAP) {
        FormatTime, TIMESTAMP, , yyyyMMdd_HHmmss
        global SCREENSHOT_FILE := "screenshot_" . TIMESTAMP . ".png"
        Gdip_SaveBitmapToFile(PBITMAP, SCREENSHOT_FILE)
        Gdip_DisposeImage(PBITMAP)
    }
}
SENDSCREENSHOTTODISCORD() {
    SCREENSHOTPATH := A_ScriptDir . "\" . SCREENSHOT_FILE
    if (FileExist(SCREENSHOTPATH)) {
        RunWait, curl -F "file1=@%SCREENSHOTPATH%" %DISCORD_WEBHOOK%, , Hide
        if (FileExist(SCREENSHOTPATH)) {
            FileDelete, %SCREENSHOTPATH%
        }
    }
}
SENDWEBHOOK(description, color) {
    ESCAPED_DESCRIPTION := StrReplace(description, """", "\\""")
    EMBED := """description"": """ . ESCAPED_DESCRIPTION . ""","
    EMBED .= """color"": " . color
    JSON := "{""embeds"": [{" . EMBED . "}]}"
    FileDelete, temp.json
    FileAppend, %JSON%, temp.json
    RunWait, curl -H "Content-Type: application/json" -X POST -d @temp.json %DISCORD_WEBHOOK%, , Hide
    FileDelete, temp.json
}
IsValidWebhook(url) {
    if (url = "Enter Webhook URL Here" || url = "" || !InStr(url, "https://discord.com/api/webhooks/")) {
        return false
    }
    return true
}
COLORSIMILAR(color, target) {
    R1 := (color >> 16) & 0xFF
    G1 := (color >> 8) & 0xFF
    B1 := color & 0xFF
    R2 := (target >> 16) & 0xFF
    G2 := (target >> 8) & 0xFF
    B2 := target & 0xFF
    TOLERANCE := 20
    return (Abs(R1 - R2) < TOLERANCE && Abs(G1 - G2) < TOLERANCE && Abs(B1 - B2) < TOLERANCE)
}
INITIALIZETOOLTIP:
    UPDATETOOLTIP()
return
UPDATETOOLTIP() {
    STATUS := ISSPAMMING ? "Hatching :)" : "Press F1 to Start"
    ToolTip, %STATUS%, 53, 883, 1
    if (!ISSPAMMING) {
        ToolTip, Edit Webhook, 53, 903, 2
        ToolTip, Made by Aqua, 53, 923, 3
    } else {
        ToolTip, , , , 2
        ToolTip, , , , 3
    }
}
~LButton::
    MouseGetPos, MX, MY
    if (((MX >= 53 && MX <= 200 && MY >= 903 && MY <= 923) || (MX >= 654 && MX <= 740 && MY >= 987 && MY <= 1006)) && !ISSPAMM KetoGenixING) {
        SHOWSETTINGSGUI()
    }
return
SHOWSETTINGSGUI() {
    global DISCORD_WEBHOOK, SCREENSHOT_MINUTES, ENABLE_INVENTORY_CHECKS, SETTINGS_FILE
    Gui, Settings:New, , Edit Settings
    Gui, Add, Checkbox, vNEW_INVENTORY_CHECKS Checked%ENABLE_INVENTORY_CHECKS% gTOGGLEINVENTORYCHECKS, Enable/Disable Webhooks
    Gui, Add, Text, , Discord Webhook URL:
    Gui, Add, Edit, vNEW_WEBHOOK w300, %DISCORD_WEBHOOK%
    Gui, Add, Text, , Screenshot Interval (minutes):
    Gui, Add, Edit, vNEW_INTERVAL w50, %SCREENSHOT_MINUTES%
    Gui, Add, Button, gSAVESETTINGS, Save
    if (!ENABLE_INVENTORY_CHECKS) {
        GuiControl, Disable, NEW_WEBHOOK
        GuiControl, Disable, NEW_INTERVAL
    }
    Gui, Show
}
TOGGLEINVENTORYCHECKS:
    GuiControlGet, ISCHECKED, , NEW_INVENTORY_CHECKS
    GuiControl, % ISCHECKED ? "Enable" : "Disable", NEW_WEBHOOK
    GuiControl, % ISCHECKED ? "Enable" : "Disable", NEW_INTERVAL
return
SAVESETTINGS:
    Gui, Submit
    if (NEW_INTERVAL is not number || NEW_INTERVAL <= 0) {
        MsgBox, Please enter a positive number for the interval.
        return
    }
    IniWrite, %NEW_WEBHOOK%, %SETTINGS_FILE%, Settings, Webhook
    IniWrite, %NEW_INTERVAL%, %SETTINGS_FILE%, Settings, ScreenshotMinutes
    IniWrite, %NEW_INVENTORY_CHECKS%, %SETTINGS_FILE%, Settings, EnableInventoryChecks
    DISCORD_WEBHOOK := NEW_WEBHOOK
    SCREENSHOT_MINUTES := NEW_INTERVAL
    ENABLE_INVENTORY_CHECKS := NEW_INVENTORY_CHECKS
    if (ISSPAMMING && ENABLE_INVENTORY_CHECKS) {
        SetTimer, PERIODICSCREENSHOT, % SCREENSHOT_MINUTES * 60000
    } else if (ISSPAMMING && !ENABLE_INVENTORY_CHECKS) {
        SetTimer, PERIODICSCREENSHOT, Off
    }
    Gui, Destroy
return
SettingsGuiClose:
    Gui, Destroy
return
$Esc::
    if (ISSPAMMING) {
        ISSPAMMING := false
        SetTimer, SPAMKEYS, Off
        SetTimer, PERIODICSCREENSHOT, Off
        FormatTime, WEBHOOK_TIME, , [HH:mm:ss]
        DESCRIPTION := WEBHOOK_TIME . " Macro Stopped"
        if (IsValidWebhook(DISCORD_WEBHOOK)) {
            SENDWEBHOOK(DESCRIPTION, 3447003)
        }
    }
    ToolTip, , , , 1
    ToolTip, , , , 2
    ToolTip, , , , 3
    Gdip_Shutdown(PTOKEN)
    ExitApp
return
