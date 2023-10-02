/************************************************************************
 * @description Window Spy for AHKv2 in dark mode. [https://github.com/nperovic/Dark_WindowSpy]
 * @file WindowSpy.ahk
 * @author nperovic
 * @date 2023/10/02
 * @version 1.0.0
 ***********************************************************************/
#Requires AutoHotkey v2
#SingleInstance Ignore
#NoTrayIcon

SetWorkingDir(A_ScriptDir)
CoordMode("Pixel", "Screen")
SetWinDelay(-1)
SetControlDelay(-1)

WinSpyGui(9, "Segoe UI", false)

~*Shift::
~*Ctrl:: suspend_timer()
~*Ctrl up::
~*Shift up:: SetTimer(Update)

WinSpyGui(fontSize := 11, font := "Segoe UI", Wrap := true)
{
	global oGui
	static WM_RBUTTONDOWN := 0x0204
	     , WM_RBUTTONUP   := 0x0205

	try TraySetIcon "inc\spy.ico"
	DllCall("shell32\SetCurrentProcessExplicitAppUserModelID", "ptr", StrPtr("AutoHotkey.WindowSpy"))

	oGui           := Gui("AlwaysOnTop Resize MinSize DPIScale", "Window Spy for AHKv2")
	oGui.BackColor := "1F1F1F"

	oGui.SetFont("cF8F8F8 S" fontSize, font)
	oGui.OnEvent("Close", WinSpyClose)
	oGui.OnEvent("Size", WinSpySize)
	OnMessage(WM_RBUTTONUP, Right_Click_Event)

	oGui.Add("Text", , "Window Title, Class and Process:")
	oGui.Add("Checkbox", "yp Right -Wrap -0x4000 vCtrl_FollowMouse").Value := 1
	oGui.Add("Text", "xp+45 yp", "Follow Mouse").OnEvent("Click", ToggleCheck)
	oGui.Add("Edit", "xm w320 r5 ReadOnly vCtrl_Title" (Wrap ? "" : " -Wrap"))
	oGui.Add("Text", , "Mouse Position")
	oGui.Add("Edit", "w320 r4 ReadOnly vCtrl_MousePos")
	oGui.Add("Text", "w320 vCtrl_CtrlLabel", (txtFocusCtrl := "Focused Control") ":")
	oGui.Add("Edit", "w320 r4 ReadOnly vCtrl_Ctrl")
	oGui.Add("Text", , "Active Window Postition:")
	oGui.Add("Edit", "w320 r2 ReadOnly vCtrl_Pos")
	oGui.Add("Text", , "Status Bar Text:")
	oGui.Add("Edit", "w320 r2 ReadOnly vCtrl_SBText")
	oGui.Add("Checkbox", "x-12 Right vCtrl_IsSlow")
	oGui.Add("Text", "xp+48 yp", "Slow TitleMatchMode").OnEvent("Click", ToggleCheck)
	oGui.Add("Text", "xm", "Visible Text:")
	oGui.Add("Edit", "w320 r2 ReadOnly vCtrl_VisText")
	oGui.Add("Text", , "All Text:")
	oGui.Add("Edit", "w320 r2 ReadOnly vCtrl_AllText")
	oGui.Add("Text", "w320 r1 vCtrl_Freeze", (txtNotFrozen := "(Hold Ctrl or Shift to suspend updates)"))

	for ctrl in oGui
	{
		if ctrl Is Gui.Edit
			ctrl.Opt("cF8F8F8 Background" oGui.BackColor)
		ctrl.Opt("cF8F8F8")
		ctrl.SetFont("cF8F8F8")
		SetDarkMode(ctrl)
	}

	SetDarkTitle(oGui)
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

	oGui.GetClientPos(, , &Width, &Height)
	WinSpySize(oGui, 0, Width, Height)
	oGui.Show("NoActivate AutoSize")

	SetTimer(Update, 250)
	return oGui
}

ToggleCheck(GuiCtrlObj, p*)
{
	static checkBoxName := Map("Follow Mouse", "Ctrl_FollowMouse", "Slow TitleMatchMode", "Ctrl_IsSlow")

	CheckBoxCtrl       := GuiCtrlObj.Gui[checkBoxName[GuiCtrlObj.Value]]
	CheckBoxCtrl.Value := !CheckBoxCtrl.Value
}

Right_Click_Event(wParam, lParam, msg, hwnd)
{
	static WM_RBUTTONDOWN := 0x0204
	     , WM_RBUTTONUP   := 0x0205

	if !(GuiCtrlFromHwnd(hwnd) Is Gui.Edit
		&& msg = WM_RBUTTONUP)
		return 0

	A_Clipboard := ""
	ControlSend("^{Ins}", hwnd)
	if ClipWait(1)
	{
		ToolTip("Copied: " A_Clipboard)
		SetTimer(ToolTip, -1000)
	}
	return 0
}

WinSpySize(GuiObj?, MinMax?, Width?, Height?)
{

	Critical("Off")
	Sleep(-1)

	if !GuiObj.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
		return

	SetTimer(Update, (MinMax = 0) ? 250 : 0) ; suspend updates on minimize

	ctrlW := Width - (GuiObj.MarginX * 2) ; ctrlW := Width - horzMargin
	list  := "Title,MousePos,Ctrl,Pos,SBText,VisText,AllText,Freeze"

	Loop Parse list, ","
		GuiObj["Ctrl_" A_LoopField].Move(, , ctrlW)

	for CtrlName, Dist in GuiObj.CtrlDistance
	{
		GuiObj[CtrlName].Move(Width - Dist)
		GuiObj[CtrlName].Redraw()
	}
}

WinSpyClose(GuiObj) => ExitApp()

Update(GuiObj?)
{ ; timer, no params
	try TryUpdate(GuiObj?) ; try
}

TryUpdate(GuiObj?)
{
	global oGui
	GuiObj := GuiObj ?? oGui

	if !GuiObj.HasProp("txtNotFrozen") ; WinSpyGui() not done yet, return until it is
		return

	Ctrl_FollowMouse := GuiObj["Ctrl_FollowMouse"].Value
	CoordMode("Mouse", "Screen")
	MouseGetPos(&msX, &msY, &msWin, &msCtrl, 2) ; get ClassNN and hWindow
	actWin := WinExist("A")

	if (Ctrl_FollowMouse)
	{
		curWin := msWin, curCtrl := msCtrl
		WinExist("ahk_id " curWin) ; updating LastWindowFound?
	}
	else
	{
		curWin  := actWin
		curCtrl := ControlGetFocus() ; get focused control hwnd from active win
	}
	    curCtrlClassNN := ""
	try curCtrlClassNN := ControlGetClassNN(curCtrl)

	t1 := WinGetTitle(), t2 := WinGetClass()
	if (curWin = GuiObj.hwnd || t2 = "MultitaskingViewFrame")
	{ ; Our Gui || Alt-tab
		UpdateText("Ctrl_Freeze", GuiObj.txtFrozen)
		return
	}

	UpdateText("Ctrl_Freeze", GuiObj.txtNotFrozen)
	t3 := WinGetProcessName(), t4 := WinGetPID()

	WinDataText := t1 "`n" ; ZZZ
		. "ahk_class " t2 "`n"
		. "ahk_exe " t3 "`n"
		. "ahk_pid " t4 "`n"
		. "ahk_id " curWin

	UpdateText("Ctrl_Title", WinDataText)
	CoordMode("Mouse", "Window")
	MouseGetPos(&mrX, &mrY)
	CoordMode("Mouse", "Client")
	MouseGetPos(&mcX, &mcY)
	mClr := PixelGetColor(msX, msY, "RGB")
	mClr := SubStr(mClr, 3)

	mpText := "Screen:`t" msX ", " msY "`n"
		. "Window:`t" mrX ", " mrY "`n"
		. "Client:`t" mcX ", " mcY " (default)`n"
		. "Color :`t" mClr " (Red=" SubStr(mClr, 1, 2) " Green=" SubStr(mClr, 3, 2) " Blue=" SubStr(mClr, 5) ")"

	UpdateText("Ctrl_MousePos", mpText)

	UpdateText("Ctrl_CtrlLabel", (Ctrl_FollowMouse ? GuiObj.txtMouseCtrl : GuiObj.txtFocusCtrl) ":")

	if (curCtrl)
	{
		ctrlTxt := ControlGetText(curCtrl)
		WinGetClientPos(&sX, &sY, &sW, &sH, curCtrl)
		ControlGetPos(&cX, &cY, &cW, &cH, curCtrl)

		cText := "ClassNN:`t" curCtrlClassNN "`n"
			. "Text   :`t" textMangle(ctrlTxt) "`n"
			. "Screen :`tx: " sX "`ty: " sY "`tw: " sW "`th: " sH "`n"
			. "Client :`tx: " cX "`ty: " cY "`tw: " cW "`th: " cH
	}
	else
		cText := ""

	UpdateText("Ctrl_Ctrl", cText)
	wX := "", wY := "", wW := "", wH := ""
	WinGetPos(&wX, &wY, &wW, &wH, "ahk_id " curWin)
	WinGetClientPos(&wcX, &wcY, &wcW, &wcH, "ahk_id " curWin)

	wText := "Screen:`tx: " wX "`ty: " wY "`tw: " wW "`th: " wH "`n"
		. "Client:`tx: " wcX "`ty: " wcY "`tw: " wcW "`th: " wcH

	UpdateText("Ctrl_Pos", wText)
	sbTxt := ""

	Loop
	{
		ovi := ""
		try ovi := StatusBarGetText(A_Index)
		if (ovi = "")
			break
		sbTxt .= "(" A_Index "):`t" textMangle(ovi) "`n"
	}

	sbTxt := SubStr(sbTxt, 1, -1) ; StringTrimRight, sbTxt, sbTxt, 1
	UpdateText("Ctrl_SBText", sbTxt)
	bSlow := GuiObj["Ctrl_IsSlow"].Value ; GuiControlGet, bSlow,, Ctrl_IsSlow

	if (bSlow)
	{
		DetectHiddenText False
		ovVisText := WinGetText() ; WinGetText, ovVisText
		DetectHiddenText True
		ovAllText := WinGetText() ; WinGetText, ovAllText
	}
	else
	{
		ovVisText := WinGetTextFast(false)
		ovAllText := WinGetTextFast(true)
	}

	UpdateText("Ctrl_VisText", ovVisText)
	UpdateText("Ctrl_AllText", ovAllText)
}

; =========================================================================================== 
; WinGetText ALWAYS uses the "slow" mode - TitleMatchMode only affects
; WinText/ExcludeText parameters. In "fast" mode, GetWindowText() is used
; to retrieve the text of each control.
; =========================================================================================== 
WinGetTextFast(detect_hidden)
{
	controls := WinGetControlsHwnd()

	static WINDOW_TEXT_SIZE := 32767 ; Defined in AutoHotkey source.

	buf := Buffer(WINDOW_TEXT_SIZE * 2, 0)

	text := ""

	Loop controls.Length
	{
		hCtl := controls[A_Index]
		if !detect_hidden && !DllCall("IsWindowVisible", "ptr", hCtl)
			continue
		if !DllCall("GetWindowText", "ptr", hCtl, "Ptr", buf.ptr, "int", WINDOW_TEXT_SIZE)
			continue

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
	       ctl     := oGui[vCtl], hCtl := Integer(ctl.hwnd)

	if (!oldText.HasProp(hCtl) Or OldText.%hCtl% != NewText)
	{
		ctl.Value      := NewText
		OldText.%hCtl% := NewText
	}
}

textMangle(x)
{
	elli := false
	if (pos := InStr(x, "`n"))
		x := SubStr(x, 1, pos - 1), elli := true
	else if (StrLen(x) > 40)
		x := SubStr(x, 1, 40), elli := true
	if elli
		x .= " (...)"
	return x
}

suspend_timer()
{
	global oGui
	SetTimer(Update, 0)
	UpdateText("Ctrl_Freeze", oGui.txtFrozen)
	oGui["Ctrl_FollowMouse"].Value := 0
}

SetDarkMode(_obj) => (
	DllCall("uxtheme\SetWindowTheme", "ptr", _obj.hwnd, "ptr", StrPtr("DarkMode_Explorer"), "ptr", 0) ? true : false
)

SetDarkTitle(_obj)
{
	if VerCompare(A_OSVersion, "10.0.17763") >= 0
	{
		attr := 19

		if VerCompare(A_OSVersion, "10.0.18985") >=  0
			attr := 20
		
		if DllCall("dwmapi\DwmSetWindowAttribute", "ptr", _obj.hwnd, "int", attr, "int*", true, "int", 4)
			return true
	}
	return false
}
