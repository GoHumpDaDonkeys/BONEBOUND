#RequireAdmin
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_requestedExecutionLevel=requireAdministrator
#include "Runtime/Library.au3"
#include "Runtime/ImGui/ImGui.au3"
#include "Settings.au3"
#include "Interface.au3"
#include "Readiness.au3"
#include "EventItems.au3"
#include "Inventory.au3"
#include "StorageConnection.au3"
#include "Farmer.au3"
For $i=1 To $CmdLine[0]
    If $CmdLine[$i]="/preview" Then $BB_Preview=True
Next
BB_CreateUI()
OnAutoItExitRegister("BB_Cleanup")
AdlibRegister("BB_Render",30)
BB_Render()
If Not $BB_Preview Then BB_RefreshCharacters()
BB_Log("Bonebound v" & $BB_Version & " ready")
While Not $BB_Exit
    BB_Pump()
    If $BB_Run And Not $BB_Preview Then
        If Not BB_Cycle() And $BB_Run Then
            $BB_Fails+=1
            BB_Log("Run failed. Returning to Bergen.")
            If $BB_Fails>=3 Then
                BB_Halt("Three failures this session. Review Activity.log before retrying.")
            Else
                BB_Travel()
            EndIf
        EndIf
    EndIf
    Sleep(30)
WEnd
Exit

Func BB_Cleanup()
    AdlibUnRegister("BB_Render")
    If Not $BB_Preview Then BB_Save()
EndFunc
; Compatibility callbacks used by the bundled GWAu3 library.
Func StartBot()
    Return
EndFunc
Func _Exit()
    $BB_Exit=True
    $BB_Run=False
EndFunc
Func Out($text)
    BB_Log($text)
EndFunc

; No optional API plugins enabled.
Func Extend_AddPattern()
    BB_AddStoragePattern()
EndFunc

; No optional API plugins enabled.
Func Extend_Scanner()
    BB_ResolveStorageConnection()
EndFunc

; No optional API plugins enabled.
Func Extend_InitializeResult()
    Return
EndFunc

; No optional API plugins enabled.
Func Extend_Assembler()
    Return
EndFunc

; No optional API plugins enabled.
Func Extend_Write()
    Return
EndFunc

; No optional API plugins enabled.
Func Extend_AssemblerWriteDetour()
    Return
EndFunc

; No optional API plugins enabled.
Func Extend_AssemblerData()
    Return
EndFunc
