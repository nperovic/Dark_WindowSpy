/************************************************************************
 * @description Window Spy for AHKv2 in dark mode. 
 * @file WindowSpy.ahk
 * @author @nperovic (https://github.com/nperovic/Dark_WindowSpy)
 * @date 2026/08/16
 * @version 1.2
 ***********************************************************************/

#Requires AutoHotkey v2.0
#SingleInstance
#Warn All, Off

try TraySetIcon(RegExReplace(A_AhkPath, "iS)[^\\]+\\AutoHotkey\\\K.+", "UX\inc\spy.ico"))
#NoTrayIcon

global oGui

WM_COPY        := 0x0301
WM_RBUTTONDOWN := 0x0204
WM_RBUTTONUP   := 0x0205
SM_CXMENUCHECK := 71
SM_CYMENUCHECK := 72
CHECKBOX_SIZE  := (" W" SysGet(SM_CXMENUCHECK) " H" SysGet(SM_CYMENUCHECK)) 

SetWinDelay -1
SetControlDelay -1

SetWorkingDir A_ScriptDir
CoordMode "Pixel", "Screen"
WinSpyGui 10, "Segoe UI", true

~*LShift::
~*LShift up::
~*LCtrl::
~*LCtrl up::
{
	if InStr(ThisHotkey, 'up') {
		SetTimer Update
	} else {
		suspend_timer
	}
}


WinSpyGui(fontSize := 11, font := "Segoe UI", Wrap := true)
{
	global oGui
	
	DllCall "shell32\SetCurrentProcessExplicitAppUserModelID", "str", "AutoHotkey.WindowSpy"

	oGui := Gui(" AlwaysOnTop Resize MinSize MinSizex1 OwnDialogs", "Window Spy for AHKv2")
	
	oGui.MarginX   := 10
	oGui.MarginY   := 5
	oGui.BackColor := 0x2b2b2b
	oGui.SetFont("cWhite s" fontSize, font)

	SetDarkMode(oGui)
	SetWindowColor(oGui.hwnd, 0xFFFFFFFE, 0x2b2b2b)

	oGui.AddText("0x200 h" SysGet(72), "Window Title, Class and Process").GetPos(, , &tW)
	oGui.AddText("x+m yp Right 0x200 HP W" (320 - tW - SysGet(71) + oGui.MarginX), "Follow Mouse")
	oGui.AddCheckBox("x+0 yp Right Checked vCtrl_FollowMouse HP W" SysGet(71))
		.OnEvent("Click", Checkbox_Focus)
	oGui.AddEdit("xm w320 r5 ReadOnly vCtrl_Title" (Wrap ? "" : " -Wrap"))
	
	oGui.AddText("wp", "Mouse Position")
	oGui.AddEdit("wp r4 ReadOnly vCtrl_MousePos")

	oGui.AddText("wp vCtrl_CtrlLabel", (txtFocusCtrl := "Focused Control") ":")
	oGui.AddEdit("wp r4 ReadOnly vCtrl_Ctrl")

	oGui.AddText("wp", "Active Window Postition")
	oGui.AddEdit("wp r2 ReadOnly vCtrl_Pos")

	oGui.AddText("wp", "Status Bar Text")
	oGui.AddEdit("wp r1 ReadOnly vCtrl_SBText")

	oGui.AddCheckbox("xm r1 vCtrl_IsSlow " CHECKBOX_SIZE)
		.OnEvent("Click", Checkbox_Focus)
	oGui.AddText("x+0 yp HP", "Slow TitleMatchMode")

	oGui.AddText("xm", "Visible Text")
	oGui.AddEdit("w320 r2 VScroll ReadOnly vCtrl_VisText")

	oGui.AddText(, "All Text")
	oGui.AddEdit("wp r3  VScroll ReadOnly vCtrl_AllText")

	oGui.AddText("wp r1 vCtrl_Freeze", (txtNotFrozen := "(Hold Ctrl or Shift to suspend updates)"))
; 
	oGui.OnEvent("Close", SaveLastPosition)
	oGui.OnEvent("Size", WinSpySize)

	for ctrl in ["Follow Mouse", "Slow TitleMatchMode"] 
		for event in ["Click", "DoubleClick"] 
			oGui[ctrl].OnEvent(event, ToggleCheck)

	for ctrl in oGui {
		if ctrl.Type = "Edit" {
			ctrl.Opt("-VScroll cF8F8F8 Background" oGui.BackColor)
			DllCall "HideCaret", "ptr", ctrl.hWnd
			ctrl.OnEvent("Focus", (gCtrl, *) => DllCall("HideCaret", "ptr", gCtrl.hWnd))
			; ctrl.OnMessage(WM_RBUTTONUP, Right_Click_Event) ; v2.1
			OnMessage(WM_RBUTTONUP, Right_Click_Event)
		}
		ctrl.SetFont("cF8F8F8")
		SetDarkControl ctrl, 'DarkMode_DarkTheme'
	}

	oGui.Show("Hide AutoSize")
	oGui.GetClientPos(, , &GuiWidth)
	oGui["Ctrl_FollowMouse"].GetPos(&x_ChBx_FollowMouse)
	oGui["Follow Mouse"].GetPos(&x_Text_FollowMouse)

	oGui.CtrlDistance := Map(
		"Ctrl_FollowMouse", GuiWidth - x_ChBx_FollowMouse,
		"Follow Mouse", GuiWidth - x_Text_FollowMouse
	)
	
	oGui.txtNotFrozen := txtNotFrozen       ; create properties for futur use
	oGui.txtFrozen    := "(Updates suspended)"
	oGui.txtMouseCtrl := "Control Under Mouse Position"
	oGui.txtFocusCtrl := txtFocusCtrl

	oGui.Show("AutoSize Hide")
	oGui.GetPos(, , , &w)
	oGui.Move(, , , w + 1)
	oGui.Show("Center NoActivate NA")

	SetTimer Update

	return oGui
}

ToggleCheck(GuiCtrlObj, p*)
{
	static checkBoxName := Map("Follow Mouse", "Ctrl_FollowMouse", "Slow TitleMatchMode", "Ctrl_IsSlow")

	CheckBoxCtrl := GuiCtrlObj.Gui[checkBoxName[GuiCtrlObj.Value]]
	ControlClick CheckBoxCtrl.hwnd, GuiCtrlObj.Gui
}

Checkbox_Focus(GuiCtrlObj, Info)
{
	SendMessage 0x8, , , GuiCtrlObj.hwnd
	return 0
}

; Right_Click_Event(GuiCtrl, wParam, lParam, Msg) ; v2.1
Right_Click_Event(wParam, lParam, Msg, hWnd)
{
	if !(GuiCtrl := GuiCtrlFromHwnd(hWnd)) || (GuiCtrl.Type != 'Edit')
		return

	if !(slText := EditGetSelectedText(GuiCtrl) )
		return
	
	A_Clipboard := ""

	if (GuiCtrl.Name = "Ctrl_Title") 
		A_Clipboard := StrReplace(slText, "`r`n", "`s")
	else 
		PostMessage WM_COPY, , , GuiCtrl

	if ClipWait(1) {
		SetDarkControl ToolTip("Copied: " A_Clipboard)
		SetTimer ToolTip, -1500
	}
	return 0
}

WinSpySize(GuiObj?, MinMax?, Width?, Height?)
{
	Critical "Off"

	if !GuiObj.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
	{
		return
	}

	SetTimer Update, (MinMax = 0) ? 250 : 0 ; suspend updates on minimize

	ctrlW := Width - (GuiObj.MarginX * 2) ; ctrlW := Width - horzMargin
	list  := "Title,MousePos,Ctrl,Pos,SBText,VisText,AllText,Freeze"

	Loop Parse list, ","
	{
		GuiObj["Ctrl_" A_LoopField].Move( , , ctrlW)
	}

	for CtrlName, Dist in GuiObj.CtrlDistance {
		GuiObj[CtrlName].Move(Width - Dist)
		GuiObj[CtrlName].Redraw()
	}
}

WinSpyClose(GuiObj)
{
	ExitApp
}

Update(GuiObj?)
{ ; timer, no params
	try TryUpdate(GuiObj?) ; try
}

TryUpdate(GuiObj := oGui)
{
	global oGui

	if !GuiObj.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
		return

	curWin := msWin := curCtrl := msCtrl := ''

	Ctrl_FollowMouse := GuiObj["Ctrl_FollowMouse"].Value
	CoordMode "Mouse", "Screen"
	MouseGetPos &msX, &msY, &msWin, &msCtrl, 2 ; get ClassNN and hWindow

	actWin := WinExist("A")

	if (Ctrl_FollowMouse) {
		curWin  := msWin  := msWin ?? ''
		curCtrl := msCtrl := msCtrl ?? ''
		WinExist curWin ; updating LastWindowFound?
	} else {
		curWin  := actWin
		curCtrl := ControlGetFocus() ; get focused control hwnd from active win
	}

	try curCtrlClassNN := curCtrl ? ControlGetClassNN(curCtrl) : ''

	t1 := WinGetTitle()
	t2 := WinGetClass()

	if (curWin = GuiObj.hwnd || t2 = "MultitaskingViewFrame")
	{ ; Our Gui || Alt-tab
		UpdateText "Ctrl_Freeze", GuiObj.txtFrozen
		return
	}

	UpdateText "Ctrl_Freeze", GuiObj.txtNotFrozen
	
	t3 := WinGetProcessName()
	t4 := WinGetPID()

	WinDataText := t1 "`n" ; ZZZ
		. "ahk_class " t2 "`n"
		. "ahk_exe " t3 "`n"
		. "ahk_pid " t4 "`n"
		. "ahk_id " curWin

	UpdateText "Ctrl_Title", WinDataText
	CoordMode "Mouse", "Window"
	MouseGetPos &mrX, &mrY
	CoordMode "Mouse", "Client"
	MouseGetPos &mcX, &mcY

	mClr := PixelGetColor(msX, msY, "RGB")
	mClr := SubStr(mClr, 3)

	mpText := "Screen:`t" msX ", " msY "`n"
		. "Window:`t" mrX ", " mrY "`n"
		. "Client:`t" mcX ", " mcY " (default)`n"
		. "Color :`t" mClr " (Red=" SubStr(mClr, 1, 2) " Green=" SubStr(mClr, 3, 2) " Blue=" SubStr(mClr, 5) ")"

	UpdateText "Ctrl_MousePos", mpText

	UpdateText "Ctrl_CtrlLabel", (Ctrl_FollowMouse ? GuiObj.txtMouseCtrl : GuiObj.txtFocusCtrl) ":"

	if curCtrl {
		ctrlTxt := ControlGetText(curCtrl)
		WinGetClientPos &sX, &sY, &sW, &sH, curCtrl
		ControlGetPos &cX, &cY, &cW, &cH, curCtrl

		cText := "ClassNN:`t" curCtrlClassNN "`n"
			. "Text   :`t" textMangle(ctrlTxt) "`n"
			. "Screen :`tx: " sX "`ty: " sY "`tw: " sW "`th: " sH "`n"
			. "Client :`tx: " cX "`ty: " cY "`tw: " cW "`th: " cH
	} else cText := ""

	try {
		UpdateText "Ctrl_Ctrl", cText
		wX := wY := wW := wH := ""
		WinGetPos &wX, &wY, &wW, &wH, curWin
		WinGetClientPos &wcX, &wcY, &wcW, &wcH, curWin

		wText := "Screen:`tx: " wX "`ty: " wY "`tw: " wW "`th: " wH "`n"
			. "Client:`tx: " wcX "`ty: " wcY "`tw: " wcW "`th: " wcH

		UpdateText "Ctrl_Pos", wText
		sbTxt := ""
	}

	Loop
	{
		ovi := ""
		try ovi := StatusBarGetText(A_Index)
		if (ovi = "") {
			break
		}
		sbTxt .= "(" A_Index "):`t" textMangle(ovi) "`n"
	}

	sbTxt := SubStr(sbTxt, 1, -1) ; StringTrimRight, sbTxt, sbTxt, 1
	UpdateText "Ctrl_SBText", sbTxt
	bSlow := GuiObj["Ctrl_IsSlow"].Value ; GuiControlGet, bSlow,, Ctrl_IsSlow

	if (bSlow)
	{
		DetectHiddenText False
		try ovVisText := WinGetText() ; WinGetText, ovVisText
		DetectHiddenText True
		try ovAllText := WinGetText() ; WinGetText, ovAllText
	}
	else
	{
		ovVisText := WinGetTextFast(false)
		DetectHiddenText True
		ovAllText := WinGetTextFast(true)
	}

	UpdateText "Ctrl_VisText", ovVisText
	UpdateText "Ctrl_AllText", ovAllText
}



; ===========================================================================================
; WinGetText ALWAYS uses the "slow" mode - TitleMatchMode only affects
; WinText/ExcludeText parameters. In "fast" mode, GetWindowText() is used
; to retrieve the text of each control.
; ===========================================================================================
WinGetTextFast(detect_hidden)
{
	static WINDOW_TEXT_SIZE := 32767 ; Defined in AutoHotkey source.

	try controls := WinGetControlsHwnd()
	catch
		return ''

	buf := Buffer(WINDOW_TEXT_SIZE * 2, 0)

	text := ""

	for i, hCtl in controls {
		if !detect_hidden && !DllCall("IsWindowVisible", "ptr", hCtl) {
			continue
		}
		if !DllCall("GetWindowText", "ptr", hCtl, "Ptr", buf.ptr, "int", WINDOW_TEXT_SIZE) {
			continue
		}

		text .= StrGet(buf) "`r`n" ; text .= buf "`r`n"
	}

	Loop controls.Length
	{
		hCtl := controls[A_Index]
		if !detect_hidden && !DllCall("IsWindowVisible", "ptr", hCtl) {
			continue
		}
		if !DllCall("GetWindowText", "ptr", hCtl, "Ptr", buf.ptr, "int", WINDOW_TEXT_SIZE) {
			continue
		}

		text .= StrGet(buf) "`r`n" ; text .= buf "`r`n"
	}
	return text
}

; ===========================================================================================
; Unlike using a pure GuiControl, this function causes the text of the
; controls to be updated only when the text has changed, preventing periodic
; flickering (especially on older systems).
; ===========================================================================================
UpdateText(vCtl, NewText)
{
	global oGui
	static OldText := {}

	ctl := oGui[vCtl], hCtl := Integer(ctl.hwnd)

	if (!oldText.HasProp(hCtl) Or OldText.%hCtl% != NewText)
	{
		ctl.Value := NewText
		OldText.%hCtl% := NewText
	}
}

textMangle(x)
{
	elli := true
	if (pos := InStr(x, "`n"))
	{
		x := SubStr(x, 1, pos - 1)
	}
	else if (StrLen(x) > 40)
	{
		x := SubStr(x, 1, 40)
	}
	else
	{
		selli := false
	}

	if elli
	{
		x .= " (...)"
	}
	return x
}

suspend_timer()
{
	global oGui
	SetTimer Update, 0
	UpdateText "Ctrl_Freeze", oGui.txtFrozen
}

SaveLastPosition(GuiObj, *)
{
	while WinGetMinMax(GuiObj) = -1
	{
		WinSetTransparent 0, GuiObj
		GuiObj.Restore()
	}
	GuiObj.GetPos &X, &Y, &Width, &Height
	GuiObj.Minimize
	try IniWrite Format("Pos=x{1} y{2} w{3} h{4}", X, Y, Width, Height), "WindowSpy_Settings.ini", "SavedPos"
	ExitApp
}

SetDarkControl(ctrl, style := "DarkMode_Explorer")
{
	static IsWin11 := (VerCompare(A_OSVersion, "10.0.22000") > 0)
	       
	hwnd := IsObject(ctrl) ? ctrl.hwnd : ctrl
	
	DllCall("uxtheme\SetWindowTheme", "ptr", hwnd, "ptr", StrPtr(style), "ptr", 0)
	
	if IsWin11
		DwmSetWindowAttribute hwnd, 33, InStr(WinGetClass(hwnd), 'tooltip') ? 3 : 2
}

SetDarkMode(_obj)
{
	For v in [135, 136]
		DllCall DllCall("GetProcAddress", "ptr", DllCall("GetModuleHandle", "str", "uxtheme", "ptr"), "ptr", v, "ptr"), "int", 2

	if !(attr := VerCompare(A_OSVersion, "10.0.18985") >= 0 ? 20 : VerCompare(A_OSVersion, "10.0.17763") >= 0 ? 19 : 0) 
		return false

	DwmSetWindowAttribute _obj.hwnd, attr, true
}

DwmSetWindowAttribute(hwnd?, dwAttribute?, pvAttribute := 0, cbAttribute := 4) =>
	DllCall("Dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", dwAttribute, "UInt*", &pvAttribute, "UInt", cbAttribute)


SetWindowColor(hwnd, titleText?, titleBackground?, border?) {
	static DWMWA_BORDER_COLOR := 34
	static DWMWA_CAPTION_COLOR := 35
	static DWMWA_TEXT_COLOR := 36
	static SetClrMap := Map(DWMWA_BORDER_COLOR, "border", DWMWA_CAPTION_COLOR, "titleBackground", DWMWA_TEXT_COLOR, "titleText")

	if (VerCompare(A_OSVersion, "10.0.22200") < 0) {
		return MsgBox("This is supported starting with Windows 11 Build 22000.", "OS Version Not Supported.")
	}

	for attr, var in SetClrMap {
		if (%var% ?? 0) {
			DWMSetWindowAttribute hwnd, attr, %var%
		}
	}
}
