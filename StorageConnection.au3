#include-once
; Project-local correction; supplied library files stay unchanged.
; Reference: GWCA/Source/UIMgr.cpp SendUIMessage pattern (-0x1A).
Global $g_b_AddPattern=True,$g_b_Scanner=True
Global $BB_UIMessageTarget=0,$BB_UIMessageValidated=False
Func BB_AddStoragePattern()
    Scanner_AddPattern("BB_UIMessageSafe","E8????????5DC38945085DE9",-0x1A,"Func")
EndFunc
Func BB_UIEntryValid($address,$start,$end,$first,$second,$third)
    Return $start>0 And $end>$start And $address>=$start And $address+3<=$end And $first=0x55 And $second=0x8B And $third=0xEC
EndFunc
Func BB_ValidateUIEntry($address)
    Local $start=0,$end=0
    If Not Scanner_GetSection($GC_I_SECTION_TEXT,$start,$end) Then Return False
    If $address<$start Or $address+3>$end Then Return False
    Return BB_UIEntryValid($address,$start,$end,Memory_Read($address,"byte"),Memory_Read($address+1,"byte"),Memory_Read($address+2,"byte"))
EndFunc
Func BB_ReplaceUILabel($value)
    ; This library's Memory_SetValue appends; assembly reads the first binding.
    Local $found=False
    For $n=1 To $g_amx2_Labels[0][0]
        If $g_amx2_Labels[$n][0]="UIMessage" Then
            $g_amx2_Labels[$n][1]=Ptr($value)
            $found=True
        EndIf
    Next
    Return $found
EndFunc
Func BB_ResolveStorageConnection()
    Local $original=Memory_GetValue("UIMessage"),$alternate=Scanner_GetScanResult("BB_UIMessageSafe",$g_ap_ScanResults,"Func")
    $BB_UIMessageTarget=0
    $BB_UIMessageValidated=False
    ; Scanner variants differ by one byte; only an exact validated prologue wins.
    Local $candidates[6]=[$original,$original+1,$original-1,$alternate,$alternate+1,$alternate-1]
    For $n=0 To 5
        If BB_ValidateUIEntry($candidates[$n]) Then
            $BB_UIMessageTarget=$candidates[$n]
            ExitLoop
        EndIf
    Next
    If $BB_UIMessageTarget<>0 Then
        $BB_UIMessageValidated=BB_ReplaceUILabel($BB_UIMessageTarget)
        If Not $BB_UIMessageValidated Or Memory_GetValue("UIMessage")<>$BB_UIMessageTarget Then
            $BB_UIMessageValidated=False
            $BB_UIMessageTarget=0
        EndIf
    EndIf
    BB_Log("STORAGE UI SCAN: library=" & Ptr($original) & " | alternate=" & Ptr($alternate) & " | validated=" & Ptr($BB_UIMessageTarget) & " | active label=" & Ptr(Memory_GetValue("UIMessage")))
EndFunc
Func BB_OpenStorageSafe()
    If Not BB_TownActive() Then Return False
    If Not $BB_UIMessageValidated Or Memory_GetValue("UIMessage")<>$BB_UIMessageTarget Or Not BB_ValidateUIEntry($BB_UIMessageTarget) Then
        BB_Log("STORAGE BLOCKED: UI function entry not validated; no storage command sent")
        If $BB_Run Then BB_Halt("Storage connection invalid - no command sent; review Activity")
        Return False
    EndIf
    Local $slot=$g_p_QueueBase+256*$g_i_QueueCounter
    If Memory_Read($slot,"ptr")<>0 Then
        BB_Log("STORAGE BLOCKED: command queue slot occupied; no command sent")
        Return False
    EndIf
    BB_Log("STORAGE OPEN REQUEST: validated UI=" & Ptr($BB_UIMessageTarget))
    Ui_Xunlai()
    Local $clock=TimerInit()
    While BB_TownActive()
        If Memory_Read($slot,"ptr")=0 Then
            Sleep(300)
            Return BB_TownActive()
        EndIf
        If TimerDiff($clock)>2500 Then ExitLoop
        Sleep(50)
    WEnd
    BB_Log("Storage open command not acknowledged; item transfer blocked")
    Return False
EndFunc
