#include-once
Func BB_Active()
    BB_Pump()
    Return $BB_Run And Not $BB_Exit And $BB_Attached
EndFunc
Func BB_Alive()
    Return BB_Active() And Agent_GetAgentPtr(-2)<>0 And Not Agent_GetAgentInfo(-2,"IsDead")
EndFunc
Func BB_Wait($ms,$protect=False)
    Local $t=TimerInit()
    While TimerDiff($t)<$ms
        If Not BB_Alive() Then Return False
        If $protect Then BB_Protect()
        Sleep(50)
    WEnd
    Return True
EndFunc
Func BB_Effect($slot)
    Local $id=$BB_Expected[$slot-1]
    If $id=0 Then Return 0
    If $slot>=6 Then
        If Agent_GetAgentBondInfo(-2,$id,Agent_GetMyID(),"HasBond") Then Return 999999
    EndIf
    Return Agent_GetAgentEffectInfo(-2,$id,"TimeRemaining")
EndFunc
Func BB_Cast($slot)
    Local $id=$BB_Expected[$slot-1]
    If $id=0 Or Not BB_Alive() Then Return False
    If TimerDiff($BB_Session)<$BB_BusyUntil Or Agent_GetAgentInfo(-2,"IsCasting") Then Return False
    If Not Skill_GetSkillbarInfo($slot,"IsRecharged") Then Return False
    If Agent_GetAgentInfo(-2,"CurrentEnergy")<Skill_GetSkillInfo($id,"EnergyCost") Then Return False
    Skill_UseSkill($slot,-2)
    $BB_CastAt[$slot]=TimerDiff($BB_Session)
    $BB_BusyUntil=$BB_CastAt[$slot]+Skill_GetSkillInfo($id,"Activation")*1000+800
    Return True
EndFunc
Func BB_Protect()
    If Map_GetMapID()<>59 Then Return
    If BB_Effect(1)<3500 Then
        BB_Cast(1)
        Return
    EndIf
    If BB_Effect(2)<3500 Then
        BB_Cast(2)
        Return
    EndIf
    If $BB_Combat And BB_Effect(3)<1500 Then
        If BB_Cast(3) Then Return
    EndIf
    If Agent_GetAgentInfo(-2,"CurrentEnergy")<12 Then BB_Cast(4)
EndFunc
Func BB_Travel()
    $BB_Combat=False
    If Not BB_Active() Then Return False
    If Map_GetMapID()=57 And Map_GetInstanceInfo("IsOutpost") Then Return BB_WaitForMapReady(57,False)
    BB_Log("Returning to Bergen Hot Springs")
    $BB_Transition=True
    Map_TravelTo(57,Map_GetCharacterInfo("Language"),Map_GetCharacterInfo("Region"),0,False)
    Return BB_WaitForMapReady(57,False)
EndFunc
Func BB_Move($x,$y,$protect=False)
    Local $t=TimerInit(), $retry=TimerInit()
    Map_Move($x,$y,0)
    While BB_Alive()
        If Map_GetMapID()<>59 And $protect Then Return False
        If Agent_GetDistanceToXY($x,$y)<140 Then Return True
        If TimerDiff($t)>25000 Then
            BB_Log("Waypoint timed out: " & $x & ", " & $y)
            Return False
        EndIf
        If $protect Then BB_Protect()
        If TimerDiff($retry)>1600 And TimerDiff($BB_Session)>$BB_BusyUntil Then
            Map_Move($x,$y,0)
            $retry=TimerInit()
        EndIf
        Sleep(50)
    WEnd
    Return False
EndFunc
Func BB_FreeSlots()
    Local $n=0
    For $bag=1 To 4
        $n+=Item_GetBagInfo($bag,"EmptySlots")
    Next
    Return $n
EndFunc
Func BB_CountModel($model)
    Local $n=0
    For $bag=1 To 4
        For $slot=1 To Item_GetBagInfo($bag,"Slots")
            Local $id=Item_GetItemBySlot($bag,$slot)
            If $id=0 Then ContinueLoop
            If Item_GetItemInfoByItemID($id,"ModelID")=$model Then $n+=Item_GetItemInfoByItemID($id,"Quantity")
        Next
    Next
    Return $n
EndFunc
Func BB_Cycle()
    If Not BB_Travel() Then Return False
    If Not BB_InventoryCleanup() Then Return False
    If Party_GetPartyContextInfo("TotalPartySize")<>1 Then
        BB_Halt("Solo party required. Remove heroes and henchmen.")
        Return False
    EndIf
    If Agent_GetAgentInfo(-2,"MaxHP")<>55 Then
        BB_Halt("55 maximum HP required. Check runes, weapon and cesta.")
        Return False
    EndIf
    If BB_FreeSlots()<3 Then
        BB_Halt("At least 3 free inventory slots required. Clear bags and restart.")
        Return False
    EndIf
    BB_Log("Loading your original Monk / Dervish build")
    Attribute_LoadSkillTemplate($BB_Template)
    If Not BB_Wait(2000) Then Return False
    For $i=1 To 8
        If Skill_GetSkillbarInfo($i,"SkillID")<>$BB_Expected[$i-1] Then
            BB_Halt("Build did not match. Check unlocked skills and Monk / Dervish profession.")
            Return False
        EndIf
    Next
    BB_Log("Build skill slots confirmed")
    If Not BB_EnsureHardMode() Then Return False
    BB_Log("Leaving Bergen - original farming route")
    If Not BB_Move(17676,-16496) Then Return False
    If Not BB_Move(16215,-16288) Then Return False
    $BB_Transition=True
    Map_InitMapIsLoaded()
    Map_Move(15241,-14387,0)
    If Not BB_WaitForMapReady(59,True,True) Then Return False
    BB_Log("Establishing maintained enchantments")
    For $slot=8 To 6 Step -1
        Local $t=TimerInit()
        While BB_Alive() And BB_Effect($slot)<=0 And TimerDiff($t)<16000
            BB_Cast($slot)
            If Not BB_Wait(100) Then Return False
        WEnd
        If BB_Effect($slot)<=0 Then
            BB_Log("Could not establish " & $BB_Names[$slot-1])
            Return False
        EndIf
    Next
    Local $prep=TimerInit()
    While BB_Alive() And (BB_Effect(1)<4000 Or BB_Effect(2)<4000) And TimerDiff($prep)<18000
        BB_Protect()
        If Not BB_Wait(100) Then Return False
    WEnd
    If BB_Effect(1)<4000 Or BB_Effect(2)<4000 Then Return False
    BB_Log("Gathering enemies - protection active")
    If Not BB_Move(15544.56,-13850.09,True) Then Return False
    If Not BB_Move(15727,-12610,True) Then Return False
    If Not BB_Move(15645,-11748,True) Then Return False
    BB_Log("Holding the farm - Shield of Judgment")
    $BB_Combat=True
    Local $fight=TimerInit(), $clear=0, $seen=False
    While BB_Alive() And TimerDiff($fight)<150000
        Local $enemies=BB_EnemyCount()
        If $enemies>0 Then $seen=True
        BB_Protect()
        If $seen And $enemies=0 Then
            If $clear=0 Then $clear=TimerInit()
            If TimerDiff($clear)>4000 Then ExitLoop
        Else
            $clear=0
        EndIf
        Sleep(75)
    WEnd
    $BB_Combat=False
    If Not BB_Alive() Then Return False
    If Not $seen Or BB_EnemyCount()>0 Then
        BB_Log("Farm did not clear before timeout")
        Return False
    EndIf
    BB_Log("Collecting bones and selected drops")
    If Not BB_Loot() Then Return False
    $BB_Runs+=1
    If Not BB_Travel() Then Return False
    If Not BB_InventoryCleanup() Then Return False
    If $BB_Finish Then BB_Halt("Run complete. Stopped in Bergen.")
    Return True
EndFunc
Func BB_EnemyCount()
    Local $n=0
    For $id=1 To Agent_GetMaxAgents()-1
        If Agent_GetAgentPtr($id)=0 Then ContinueLoop
        If Agent_GetAgentInfo($id,"Type")<>219 Then ContinueLoop
        If Agent_GetAgentInfo($id,"Allegiance")<>3 Or Agent_GetAgentInfo($id,"IsDead") Then ContinueLoop
        If Agent_GetDistance($id)<1100 Then $n+=1
    Next
    Return $n
EndFunc
Func BB_Loot()
    Local $started=TimerInit(), $attempted=ObjCreate("Scripting.Dictionary")
    While BB_Alive() And TimerDiff($started)<45000
        BB_Protect()
        Local $best=0, $dist=2000
        For $id=1 To Agent_GetMaxAgents()-1
            If Agent_GetAgentPtr($id)=0 Then ContinueLoop
            If Agent_GetAgentInfo($id,"Type")<>0x400 Then ContinueLoop
            If $attempted.Exists(String($id)) Then ContinueLoop
            Local $owner=Agent_GetAgentInfo($id,"Owner")
            If $owner<>0 And $owner<>Agent_GetMyID() Then ContinueLoop
            If Not BB_WantLoot($id) Then ContinueLoop
            Local $d=Agent_GetDistance($id)
            If $d<$dist Then
                $best=$id
                $dist=$d
            EndIf
        Next
        If $best=0 Then Return True
        If BB_FreeSlots()<2 Then
            BB_Log("Bags nearly full - preserving collected items")
            Return True
        EndIf
        $attempted.Add(String($best),True)
        Local $model=Item_GetItemInfoByAgentID($best,"ModelID"), $rarity=Item_GetItemInfoByAgentID($best,"Rarity")
        Local $lootItem=Agent_GetAgentInfo($best,"ItemID")
        Local $before=BB_CountModel(921), $coinBefore=Item_GetInventoryInfo("GoldCharacter")
        Item_PickUpItem($best)
        Local $t=TimerInit()
        While BB_Alive() And Agent_GetAgentPtr($best)<>0 And TimerDiff($t)<9000
            BB_Protect()
            Sleep(75)
        WEnd
        If Not BB_Alive() Then Return False
        ; Confirm gains from inventory; disappearing ground agents alone are not proof.
        Local $boneGain=BB_CountModel(921)-$before, $coinGain=Item_GetInventoryInfo("GoldCharacter")-$coinBefore
        If $boneGain>0 Then $BB_Bones+=$boneGain
        If $coinGain>0 Then $BB_Coins+=$coinGain
        If $rarity=2624 Or $rarity=2623 Or $rarity=2626 Or $rarity=2627 Then
            Local $found=False
            For $bag=1 To 4
                For $slot=1 To Item_GetBagInfo($bag,"Slots")
                    Local $ptr=Item_GetItemBySlot($bag,$slot)
                    If $ptr<>0 And Item_ItemID($ptr)=$lootItem Then $found=True
                Next
            Next
            If $found Then
                If $rarity=2624 Then $BB_Golds+=1
                BB_TrackGold($lootItem)
            EndIf
        EndIf
    WEnd
    Return BB_Alive()
EndFunc
Func BB_WantLoot($id)
    Local $model=Item_GetItemInfoByAgentID($id,"ModelID"), $rarity=Item_GetItemInfoByAgentID($id,"Rarity")
    If $model=$GC_I_MODELID_LOCKPICK Then Return BB_Selected($BB_LootLockpicks)
    If BB_IsEventItem($model) Then Return BB_Selected($BB_LootEvents)
    If $model=$GC_I_MODELID_DECAYED_ORR_EMBLEM Then Return BB_Selected($BB_LootEmblems)
    If $model=921 Then Return BB_Selected($BB_LootBones)
    If $model=929 Then Return BB_Selected($BB_LootDust)
    If $model=2511 Then Return BB_Selected($BB_LootCoins) And Item_GetInventoryInfo("GoldCharacter")<99000
    If $model=146 Then
        Local $extra=Item_GetItemInfoByAgentID($id,"ExtraID")
        Return BB_Selected($BB_LootDye) And ($extra=10 Or $extra=12)
    EndIf
    Switch $rarity
        Case 2623
            Return BB_Selected($BB_LootBlues)
        Case 2626
            Return BB_Selected($BB_LootPurples)
        Case 2624
            Return BB_Selected($BB_LootGolds)
        Case 2627
            Return BB_Selected($BB_LootGreens)
    EndSwitch
    Return False
EndFunc

; Use the packet-based API instead of the client SetDifficulty function pointer.
Func BB_EnsureHardMode($timeout=8000)
    If Not BB_Alive() Then Return False
    If Map_GetMapID()<>57 Or Not Map_GetInstanceInfo("IsOutpost") Or Party_GetPartyContextPtr()=0 Then
        BB_Halt("Difficulty check stopped: Bergen outpost and a loaded party are required.")
        Return False
    EndIf
    If Party_GetPartyContextInfo("TotalPartySize")<>1 Then
        BB_Halt("Difficulty check stopped: solo party required.")
        Return False
    EndIf
    If Party_GetPartyContextInfo("IsHardMode") Then
        BB_Log("Hard Mode already active - no switch command sent")
        Return True
    EndIf
    BB_Log("Requesting Hard Mode through Game_SwitchMode(1)")
    ; This API has no success return; the live party flag is the acknowledgement.
    Game_SwitchMode(1)
    Local $clock=TimerInit()
    While TimerDiff($clock)<$timeout
        If Not BB_Alive() Then Return False
        If Map_GetMapID()<>57 Or Not Map_GetInstanceInfo("IsOutpost") Then
            BB_Halt("Map changed while confirming Hard Mode. Return to Bergen and retry.")
            Return False
        EndIf
        If Party_GetPartyContextInfo("IsHardMode") Then
            BB_Log("Hard Mode confirmed - ready to leave Bergen")
            Return True
        EndIf
        If Not BB_Wait(100) Then Return False
    WEnd
    BB_Halt("Hard Mode not confirmed. Select it manually in Bergen, then press START FARM.")
    Return False
EndFunc
