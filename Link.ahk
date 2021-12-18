;-----------------------------;
;            Space            ;  内存占用 11870 编译14976
;-----------------------------;  磁盘占用 编译 1.16
#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.设定工作路径
#SingleInstance, force ; 重新加载提示
; #MenuMaskKey VK12 ; 屏蔽按键松开事件
; #Persistent ; 让脚本持续运行(即直到用户关闭或遇到 ExitApp).
SetBatchLines, -1 ; 运行速度 -1 满血运行
#KeyHistory 0 ; 键击历史记录保存 0以关闭提升性能
ListLines, Off ; 忽略后续键击,可以提升一些性能 禁用无法获得记录
#MaxHotkeysPerInterval 200 ; 与下面的一起使用限制一段时间内激活热键的个数
#HotkeyInterval 2000
; ListHotkeys
; ListVars

; A_Startup 自启动路径 拷贝当前文件进入即可开机自启动
; A_ScriptFullPath 脚本完整路径
; A_ScriptName 脚本的文件名称
; A_ScriptDir 所在目录的绝对路径.
; A_WorkingDir 脚本当前工作目录
; A_IsCompiled 是否已编译

; 定义全局参数
S_IsCurArea := 1 ; 鼠标`选区
S_IsAltTab := 1 ; alt tab 下 iljk 导航
global S_IsSpaceOn := 1
global S_IsHiddenIcon := 0 ; 默认关闭, 这会导致 toast 无标题
global S_IsTrayVolume := 1
global S_IsStandard := 0 ; 显示标准菜单
global Version := "Ver 1.3"
CoordMode, Mouse, Screen

; EdgeModel() 添加功能名对应效果
; 下面添加鼠标选取区域{功能名:SetArea(xMin[,xMax,yMin,yMax],window[,control],sleep)}  选择 window + control 自动忽略定位区域
; 越在此字典靠后位置需要判断的次数就越多, 常用功能考虑往前移
Edges := {desktop:SetArea(0.95,1,0,0.15)
         ,volume:SetArea(,,,,"0x201a0",["Windows.UI.Composition.DesktopWindowContentBridge1"
         ,"TrayClockWClass1","ToolbarWindow323"],0)
         ,taskview:SetArea(0,0.01,0.35,0.65,,,500)
         ,window:SetArea(0.35,0.65,0,0.01)
         ,window1:SetArea(0.05,0.35,0,0.01)
         ,volume:SetArea(0.87,0.925,0.955,1,,,0)}

; 菜单初始化
; Menu, Tray, Icon, 1.ico, , 1 ; 图标 冻结
; Menu, Tray, Icon, 21.ico, , 1 ; 图标 冻结
; Menu, Tray, Tip, Link ; Tray 鼠标悬浮提示
; Menu, Tray, NoStandard ; 删除所有 Tray 下的标准菜单(非自定义)
; Menu, Tray, NoMainWindow ; 删除任务菜单主窗口
; #NoTrayIcon ; Exitapp 指定, 否则退出困难

; Setting Submenu
Menu, Config, Add, Space, SpaceHotKey
Menu, Config, Add, Volume, TrayVolume
Menu, Config, Add, Hidden, HiddenIcon ; 任务栏图标
Menu, ConfigStandard, Add, Standard ,HiddenStandard, +Radio ; 标准菜单
Menu, Config, Add, Standard, :ConfigStandard

; Tray Menu
Menu, Tray, Add, %Version%,Version
Menu, Tray, Disable, %Version% ; 禁用版本
Menu, Tray, Add ; 添加分割线
Menu, Tray, Add, Help, GetHelp ; 帮助
Menu, Tray, Add, Setting, :Config ; 设置
Menu, Tray, Add, Exit, ExitApp ; 退出
Menu, Tray, Default, Setting

Init() ; 初始化方法要在热键被定义之前执行
return

; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; 编译后删除的功能
#If not A_IsCompiled
^tab::reload ; reload 编译删除
^#s::HiddenIcon()
#If

; Suspend 开启全部
ScrollLock::
#!Space::
Suspend, % ScrollLockHook() ? 0 : 1
return

; {alt} {tab} 下不松开{alt}, {i} {l} {j} {k} 或者 {wheelDown} Or {wheelUp} 导航
#If S_IsAltTab
alt & i::up
alt & k::down
alt & j::left
alt & l::right
alt & WheelDown:: right
alt & WheelUp:: left
#If

; 按住{space}加下列热键
#If S_IsSpaceOn
space::Space
space & i::up
space & j::left
space & k::down
space & l::right
space & <::Home
space & >::End
; 光标在最右边时无法正确选中单词
space & r::Send ^{left}+^{right}
; 不常用到的额外功能
space & (::Home
space & )::End
space & f::shift
space & d::Ctrl
space & ]::Send ^#{right}
space & [::Send ^#{left}
space & e::CopyGetPath() ; 获取文件路径
space & WheelUp::
SendEvent, +!{Esc}
sleep,150
return
space & WheelDown::
SendEvent, !{Esc}
sleep,150
return
; ~LButton & RButton::!left
; space & WheelDown::!left
space & Esc:: ; close
space & 4::
send !{F4}
return
#If

; TODO
; 取色器
!#c::
PickColor() 
; LoopPickColor()
return 

; 鼠标选区
#If S_IsCurArea
~WheelUp::EdgeModel(Edge(Edges))
~WheelDown::EdgeModel(Edge(Edges),2)
#If

; 常用音量调节
; #if S_IsTrayVolume and MouseIsOverWin("ahk_class Shell_TrayWnd")
; WheelUp::Send {Volume_Up}
; WheelDown::Send {Volume_Down}
; MButton::Send {Volume_Mute}
; #If



; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; 以下是功能函数
; 判断鼠标位置模式
Edge(Edges){
    ; 循环 Edges 获取区域 只返回第一个匹配的
    MouseGetPos,curX,curY,win,con
    for model,area in Edges{
        if (win=area["win"]){
            for idx,cc in area["con"]
                if (cc = con)
                    return {model:model,slp:area["slp"]}
        }else if (curX < area["x_min"]
        or curX > area["x_max"]
        or curY < area["y_min"]
        or curY > area["y_max"])
            continue
        return {model:model,slp:area["slp"]} ; 返回通过的模式
    }
}

; 按模式执行
EdgeModel(model,t=0){
    switch model["model"]{
        case "desktop": Send % t ? "^#{right}" : "^#{left}"
        case "taskview": Send % t ? "#{tab}" : "#{tab}"
        case "window": Send % t ? "!{tab}" : "!{tab}"
        case "window1": SendEvent % t ? "!{Esc}" : "+!{Esc}"
        case "volume" : Send % t ? "{Volume_Down}" : "{Volume_Up}"
    }
    sleep model["slp"]
}

; 获取路径(资源浏览器中)或者文件名(app中)
CopyGetPath(){
    ; KeyWait, LButton, D
    clipboard := ""
    send ^c
    ClipWait, 1
    if not ErrorLevel {
    clipboard := clipboard ; ctrl c 保存的是路径
    SetTimer, RemoveToolTip, -2000
    tooltip, >>  %clipboard%  << ;提示文本
    }
}

RemoveToolTip:
tooltip,
return

; 获取窗口函数
; MouseIsOverWin(WinTitle)
; {
;     MouseGetPos, , , Win, Control
;     tooltip,%Win% + %Control% ; 控件显示
;     if WinExist("ahk_class Shell_TrayWnd" . " ahk_id " . Win){
;         if (Control = "Windows.UI.Composition.DesktopWindowContentBridge1"
;         or Control = "TrayClockWClass1" or Control = "ToolbarWindow323") {
;         return "volume" ; win 11
;         }
;         return
;     }
;     return
; }

; ScrollLock 钩子函数
ScrollLockHook()
{
    if A_IsSuspended = 1
    {
        SetScrollLockState, On
        Menu, Tray, Icon, 1.ico, , 1 ; 图标 冻结
        TrayTip, , >->-> Running <-<-<, , 16
        return 1
    }
    SetScrollLockState, Off
    Menu, Tray, Icon, 2.ico, , 1 ; 图标 冻结
    TrayTip, , >->-> @~@ Is suspend <-<-<, , 16
    return 0
}

; GetPixel
PickColor()
{
    KeyWait, LButton, D
    MouseGetPos, x, y
    PixelGetColor, color, %X%, %y%, RGB
    StringRight, color, color, 6
    clipboard = #%color%
    tooltip,#%color%, 
    sleep,500
    tooltip,
}

LoopPickColor()
{
    loop {
        MouseGetPos, x, y
        PixelGetColor, color, %X%, %y%, RGB
        NewColor := SubStr(color, 3)
        ToolTip, %NewColor%, 
        CoordMode, ToolTip, Screen
        sleep,16
        if GetKeyState("LButton", "P") {
            StringRight, color, color, 6
            clipboard = #%color%
            tooltip, 
            Break
        }
        if GetKeyState("Esc", "P") {
            ToolTip, 
            Break
        }
    }
}

SetArea(xMin=0,xMax=0,yMin=0,yMax=0,win="",con="",slp=150){
    ; if not (win and con){
    ;     return
    ; }
    ; 参数不能为负数
    return {x_min:A_ScreenWidth * xMin
            ,x_max:A_ScreenWidth * xMax
            ,y_min:A_ScreenHeight * yMin
            ,y_max:A_ScreenHeight * yMax
            ,win:win,con:con,slp:slp}
}

; 初始化函数
Init(){
    Menu, Tray, Icon, 1.ico, , 1
    Menu, Tray, Tip, Link
    Menu, Tray, NoStandard
    ; 菜单检查
    if S_IsSpaceOn{
        Menu, Config, Check, Space
    }
    if S_IsTrayVolume{
        Menu, Config, Check, Volume
    }
    if S_IsStandard{
        Menu, Tray, Standard
        Menu, Tray, NoDefault ; 恢复默认菜单
        Menu, Tray, Delete, Exit
        Menu, ConfigStandard, Check, Standard
    }
    ; 设置程序初始状态
    if not GetKeyState("ScrollLock","T"){
        Suspend, On
        Menu, Tray, Icon, 2.ico, , 1
        TrayTip, , >->-> @~@ Is suspend <-<-<, , 16
    }
    Else{ 
        TrayTip, , >->-> Running <-<-<, , 16
    }
    if S_IsHiddenIcon{
        TrayTip, Link, Hidden Traybar Icon
        Menu, Tray, NoIcon
    }
}

; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; =======================================================================================================
; 复选菜单函数
; 此函数已失去效果
TrayVolume(){
    if S_IsTrayVolume{
        Menu, %A_ThisMenu%, unCheck, %A_ThisMenuItem%
        S_IsTrayVolume := 0
        return
    }
    Menu, %A_ThisMenu%, Check, %A_ThisMenuItem%
    S_IsTrayVolume := 1
}

SpaceHotKey(){
    if S_IsSpaceOn{
        Menu, %A_ThisMenu%, unCheck, %A_ThisMenuItem%
        S_IsSpaceOn := 0
        return
    }
    Menu, %A_ThisMenu%, Check, %A_ThisMenuItem%
    S_IsSpaceOn := 1
}

; 此菜单考虑删除
HiddenStandard(){
    if S_IsStandard{
        Menu, Tray, NoStandard
        Menu, Tray, Add, Exit, ExitApp
        Menu, %A_ThisMenu%, unCheck, %A_ThisMenuItem%
        S_IsStandard := 0
        return
    }
    Menu, Tray, Standard
    Menu, Tray, NoDefault ; 恢复默认菜单
    Menu, Tray, Delete, Exit
    Menu, %A_ThisMenu%, Check, %A_ThisMenuItem%
    S_IsStandard := 1
}

GetHelp(){
    ; TODO(帮助文档) 21/12/18
    TrayTip, , Win & Alt & Space to open
    return
}

HiddenIcon(){
    if S_IsHiddenIcon{
        Menu, Tray, Icon ; 不带参数会变成默认图标
        ; A_IconHidden 内置参数
        S_IsHiddenIcon := 0
        return
    }
    TrayTip, , Restart to show Icon
    Menu, Tray,NoIcon
    S_IsHiddenIcon := 1
}

ExitApp:
ExitApp ; 退出程序
return

Version:
; TODO(检查更新)
return