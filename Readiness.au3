#include-once
; Map ID and a nonzero agent pointer can appear before loading has finished.
; Use BB_Active (not BB_Alive) while these pointers are being rebuilt.
Func BB_MapReady($map,$explorable,$checkBuild=False)
    If Map_GetInstanceInfo("IsLoading") Then Return False
    If Map_GetMapID()<>$map Then Return False
    If $explorable Then
        If Not Map_GetInstanceInfo("IsExplorable") Then Return False
    Else
        If Not Map_GetInstanceInfo("IsOutpost") Then Return False
    EndIf
    If Agent_GetMyID()=0 Or Agent_GetAgentPtr(-2)=0 Then Return False
    If Agent_GetAgentInfo(-2,"MaxHP")<=0 Or Agent_GetAgentInfo(-2,"MaxEnergy")<=0 Then Return False
    If Agent_GetAgentInfo(-2,"IsDead") Or Agent_GetAgentInfo(-2,"CurrentHP")<=0 Then Return False
    If $checkBuild Then
        For $slot=1 To 8
            If Skill_GetSkillbarInfo($slot,"SkillID")<>$BB_Expected[$slot-1] Then Return False
        Next
    EndIf
    Return True
EndFunc
Func BB_WaitForMapReady($map,$explorable,$checkBuild=False,$timeout=60000,$settle=1000)
    $BB_Transition=True
    BB_Log("Waiting for map " & $map & " to finish loading")
    Local $clock=TimerInit(), $stable=0, $ready=False
    While TimerDiff($clock)<$timeout And BB_Active()
        If BB_MapReady($map,$explorable,$checkBuild) Then
            If $stable=0 Then $stable=TimerInit()
            If TimerDiff($stable)>=$settle Then
                $ready=True
                ExitLoop
            EndIf
        Else
            $stable=0
        EndIf
        Sleep(50)
    WEnd
    $BB_Transition=False
    If $ready Then
        BB_Log("Map " & $map & " loaded; player" & ($checkBuild ? " and skill bar" : "") & " ready")
        Return True
    EndIf
    If $BB_Run And Not $BB_Exit And $BB_Attached Then BB_Halt("Map " & $map & " did not become ready. Stopped without a recovery travel; wait for loading, then retry.")
    Return False
EndFunc
