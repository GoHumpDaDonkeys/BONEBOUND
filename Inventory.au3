#include-once
Global $BB_GoldLoot[0][2]
Func BB_TownActive()
    Return BB_Alive() And Map_GetMapID()=57 And Map_GetInstanceInfo("IsOutpost")
EndFunc
Func BB_FindCarried($id)
    For $bag=1 To 4
        For $slot=1 To Item_GetBagInfo($bag,"Slots")
            Local $p=Item_GetItemBySlot($bag,$slot)
            If $p<>0 And Item_ItemID($p)=$id Then Return $p
        Next
    Next
    Return 0
EndFunc
Func BB_GearSignature($p)
    Return Item_GetItemInfoByPtr($p,"ModelID") & "|" & Item_GetItemInfoByPtr($p,"ItemType") & "|" & Item_GetItemInfoByPtr($p,"Rarity") & "|" & Item_GetModStruct($p)
EndFunc
Func BB_TrackGold($id)
    Local $p=BB_FindCarried($id)
    If $p=0 Then Return
    Local $rarity=Item_GetItemInfoByPtr($p,"Rarity")
    If $rarity<>2624 And $rarity<>2623 And $rarity<>2626 And $rarity<>2627 Then Return
    For $i=0 To UBound($BB_GoldLoot)-1
        If $BB_GoldLoot[$i][0]=$id Then Return
    Next
    Local $n=UBound($BB_GoldLoot)
    ReDim $BB_GoldLoot[$n+1][2]
    $BB_GoldLoot[$n][0]=$id
    $BB_GoldLoot[$n][1]=BB_GearSignature($p)
EndFunc
Func BB_GoldEligible($p,$signature)
    Return BB_SaleEligible($p,$signature,False)
EndFunc
Func BB_SaleEligible($p,$signature,$manual=False)
    If $p=0 Then Return False
    Local $model=Item_GetItemInfoByPtr($p,"ModelID"), $rarity=Item_GetItemInfoByPtr($p,"Rarity")
    ; Explicit material protection applies to both automatic and manual cleanup.
    If $model=921 Or $model=929 Then Return False
    If $manual Then
        If $rarity<>2621 And $rarity<>2626 And $rarity<>2624 Then Return False
    Else
        If $rarity<>2624 Then Return False
    EndIf
    If BB_HasVigor($p) Then Return False
    If BB_IsArmor($p) And Item_GetItemInfoByPtr($p,"IsIdentified") And Not BB_ArmorModsReady($p) Then Return False
    If Item_GetItemInfoByPtr($p,"Quantity")<>1 Then Return False
    If Item_GetItemInfoByPtr($p,"Equipped")<>0 Or Item_GetItemInfoByPtr($p,"Customized")<>0 Then Return False
    Switch Item_GetItemInfoByPtr($p,"ItemType")
        Case 0,2,4,5,7,12,13,15,16,19,22,24,26,27,32,35,36
            Return BB_GearSignature($p)=$signature
    EndSwitch
    Return False
EndFunc
Func BB_EmptyStorageSlot()
    Local $slot[2]=[0,0]
    For $bag=8 To 21
        If Item_GetBagPtr($bag)=0 Or Item_GetBagInfo($bag,"ID")=0 Then ContinueLoop
        For $s=1 To Item_GetBagInfo($bag,"Slots")
            If Item_GetItemBySlot($bag,$s)<>0 Then ContinueLoop
            $slot[0]=$bag
            $slot[1]=$s
            Return $slot
        Next
    Next
    Return $slot
EndFunc
Func BB_StoreItem($id,$amount)
    If Not BB_TownActive() Then Return False
    Local $p=BB_FindCarried($id)
    If $p=0 Then Return False
    Local $model=Item_GetItemInfoByPtr($p,"ModelID"), $before=Item_GetItemInfoByPtr($p,"Quantity")
    If $amount<=0 Or $amount>$before Then Return False
    Local $slot=BB_EmptyStorageSlot()
    If $slot[0]=0 Then
        BB_Halt("Storage Full")
        Return False
    EndIf
    BB_Log("Storing Items")
    Item_MoveItem_($id,$slot[0],$slot[1],$amount)
    Local $clock=TimerInit()
    While BB_TownActive() And TimerDiff($clock)<5000
        Local $dest=Item_GetItemBySlot($slot[0],$slot[1]), $source=BB_FindCarried($id), $remaining=0
        If $source<>0 Then $remaining=Item_GetItemInfoByPtr($source,"Quantity")
        If $dest<>0 And $remaining=$before-$amount Then
            If Item_GetItemInfoByPtr($dest,"ModelID")=$model And Item_GetItemInfoByPtr($dest,"Quantity")=$amount Then
                If $amount<$before Or Item_ItemID($dest)=$id Then Return True
            EndIf
        EndIf
        Sleep(50)
    WEnd
    If $BB_Run Then BB_Halt("Storage Transfer Failed")
    Return False
EndFunc
Func BB_FindMerchant()
    BB_Log("Finding Merchant")
    Local $clock=TimerInit()
    While BB_TownActive() And TimerDiff($clock)<10000
        For $id=1 To Agent_GetMaxAgents()-1
            If Agent_GetAgentPtr($id)=0 Or Not Agent_GetAgentInfo($id,"IsNPC") Then ContinueLoop
            Local $name=Agent_GetAgentInfo($id,"Name")
            ; Bergen's merchant is Luka. Never select the nearest arbitrary NPC.
            If StringRegExp($name,"(?i)(^|[^a-z])Luka([^a-z]|$)") Then Return $id
        Next
        Sleep(100)
    WEnd
    BB_Halt("Merchant Not Found")
    Return 0
EndFunc
Func BB_OpenMerchant()
    Local $merchant=BB_FindMerchant()
    If $merchant=0 Then Return 0
    BB_Log("Visiting Merchant")
    Agent_GoNPC($merchant)
    Local $clock=TimerInit(), $retry=TimerInit()
    While BB_TownActive() And TimerDiff($clock)<25000
        If Agent_GetAgentPtr($merchant)=0 Then ExitLoop
        If Agent_GetDistance($merchant)<300 And Merchant_GetMerchantItemsSize()>0 Then Return $merchant
        If TimerDiff($retry)>2000 Then
            Agent_GoNPC($merchant)
            $retry=TimerInit()
        EndIf
        Sleep(50)
    WEnd
    If $BB_Run Then BB_Halt("Merchant Unavailable")
    Return 0
EndFunc
Func BB_IdentifyGold($id)
    Local $p=BB_FindCarried($id)
    If $p=0 Then Return False
    If Item_GetItemInfoByPtr($p,"IsIdentified") Then Return True
    ; White gear has no hidden properties to identify.
    If Item_GetItemInfoByPtr($p,"Rarity")=2621 Then Return True
    If Not BB_HasIDKit() Then
        BB_Halt("Need ID Kit")
        Return False
    EndIf
    BB_Log("Identifying Items")
    If Not Item_IdentifyItem($id) Then
        BB_Halt("Identification Failed")
        Return False
    EndIf
    Local $clock=TimerInit()
    While BB_TownActive() And TimerDiff($clock)<5000
        $p=BB_FindCarried($id)
        If $p=0 Then ExitLoop
        If Item_GetItemInfoByPtr($p,"IsIdentified") Then Return True
        Sleep(50)
    WEnd
    If $BB_Run Then BB_Halt("Identification Failed")
    Return False
EndFunc
Func BB_SellGold($id,$merchant,$signature,$manual=False)
    If Not BB_TownActive() Then Return False
    Local $p=BB_FindCarried($id)
    If Not BB_SaleEligible($p,$signature,$manual) Then Return False
    If Item_GetItemInfoByPtr($p,"Rarity")<>2621 And Not Item_GetItemInfoByPtr($p,"IsIdentified") Then Return False
    If Agent_GetAgentPtr($merchant)=0 Or Agent_GetDistance($merchant)>=300 Then
        BB_Halt("Merchant Out Of Range")
        Return False
    EndIf
    Local $wallet=Item_GetInventoryInfo("GoldCharacter"), $value=Item_GetItemInfoByPtr($p,"Value")
    If $value<=0 Or $wallet+$value>100000 Then
        BB_Halt("Gold Limit")
        Return False
    EndIf
    BB_Log("Selling Items")
    Merchant_SellItem($id,1,False)
    Local $clock=TimerInit()
    While BB_TownActive() And TimerDiff($clock)<5000
        If BB_FindCarried($id)=0 And Item_GetInventoryInfo("GoldCharacter")=$wallet+$value Then Return True
        Sleep(50)
    WEnd
    If $BB_Run Then BB_Halt("Sale Not Confirmed")
    Return False
EndFunc
Func BB_InventoryCleanup()
    If Not BB_TownActive() Then Return False
    ; Snapshot the selected mode for this visit so mid-visit UI changes apply next time.
    Local $sell=$BB_IdentifySell<>0, $needStorage=False, $merchant=0
    For $bag=1 To 4
        For $slot=1 To Item_GetBagInfo($bag,"Slots")
            If Not BB_TownActive() Then Return False
            Local $p=Item_GetItemBySlot($bag,$slot)
            If $p=0 Then ContinueLoop
            Local $model=Item_GetItemInfoByPtr($p,"ModelID")
            If $model<>921 And $model<>929 Then ContinueLoop
            Local $id=Item_ItemID($p)
            While $p<>0 And Item_GetItemInfoByPtr($p,"Quantity")>=250
                If Not $needStorage Then
                    If Not BB_OpenStorageSafe() Then
                        If $BB_Run Then BB_Halt("Storage Unavailable")
                        Return False
                    EndIf
                    $needStorage=True
                EndIf
                If Not BB_StoreItem($id,250) Then Return False
                $p=BB_FindCarried($id)
            WEnd
        Next
    Next
    For $i=0 To UBound($BB_GoldLoot)-1
        If Not BB_TownActive() Then Return False
        Local $id=$BB_GoldLoot[$i][0], $p=BB_FindCarried($id)
        If $id=0 Or Not BB_TrackedEligible($p,$BB_GoldLoot[$i][1]) Then ContinueLoop
        Local $rarity=Item_GetItemInfoByPtr($p,"Rarity"), $keep=BB_HasVigor($p)
        ; Extra pickup rarities do not grant permission to identify or sell them.
        If $rarity<>2624 And Not $keep Then ContinueLoop
        If $sell And $rarity=2624 And Not $keep Then
            If Not BB_IdentifyGold($id) Then Return False
            $p=BB_FindCarried($id)
            If $p=0 Then Return False
            $BB_GoldLoot[$i][1]=BB_GearSignature($p)
            If BB_IsArmor($p) And Not BB_ArmorModsReady($p) Then
                BB_Halt("Rune Check Failed")
                Return False
            EndIf
            $keep=BB_HasVigor($p)
        EndIf
        If $keep Or Not $sell Then
            If Not $needStorage Then
                If Not BB_OpenStorageSafe() Then
                    If $BB_Run Then BB_Halt("Storage Unavailable")
                    Return False
                EndIf
                $needStorage=True
            EndIf
            If $keep Then BB_Log("Saving Vigor Armor")
            If Not BB_StoreItem($id,1) Then Return False
            $merchant=0
        Else
            If $merchant=0 Then $merchant=BB_OpenMerchant()
            If $merchant=0 Then Return False
            $needStorage=False
            If Not BB_SellGold($id,$merchant,$BB_GoldLoot[$i][1]) Then Return False
        EndIf
        $BB_GoldLoot[$i][0]=0
    Next
    Return BB_TownActive()
EndFunc


Func BB_HasIDKit()
    For $bag=1 To 4
        For $slot=1 To Item_GetBagInfo($bag,"Slots")
            Local $p=Item_GetItemBySlot($bag,$slot)
            If $p=0 Then ContinueLoop
            Switch Item_GetItemInfoByPtr($p,"ModelID")
                Case 38620
                    Return True
                Case 2989,5899
                    If Item_GetItemInfoByPtr($p,"Value")>0 Then Return True
            EndSwitch
        Next
    Next
    Return False
EndFunc
Func BB_IsArmor($p)
    Switch Item_GetItemInfoByPtr($p,"ItemType")
        Case 0,4,7,13,16,19
            Return True
    EndSwitch
    Return False
EndFunc
Func BB_ModRecords($p)
    Return StringRegExpReplace(StringUpper(String(Item_GetModStruct($p))),"^0X","")
EndFunc
Func BB_ArmorModsReady($p)
    Local $mods=BB_ModRecords($p)
    Return StringLen($mods)>0 And Mod(StringLen($mods),8)=0 And StringRegExp($mods,"^[0-9A-F]+$")
EndFunc
Func BB_VigorRecord($mods)
    $mods=StringRegExpReplace(StringUpper(String($mods)),"^0X","")
    For $offset=1 To StringLen($mods) Step 8
        Switch StringMid($mods,$offset,8)
            Case $GC_S_RUNE_GENERAL_MINOR_VIGOR,$GC_S_RUNE_GENERAL_MAJOR_VIGOR,$GC_S_RUNE_GENERAL_SUPERIOR_VIGOR
                Return True
        EndSwitch
    Next
    Return False
EndFunc
Func BB_HasVigor($p)
    If $p=0 Or Not Item_GetItemInfoByPtr($p,"IsIdentified") Then Return False
    Return BB_VigorRecord(Item_GetModStruct($p))
EndFunc
Func BB_TrackedEligible($p,$signature)
    If $p=0 Then Return False
    If Item_GetItemInfoByPtr($p,"Quantity")<>1 Or Item_GetItemInfoByPtr($p,"Equipped") Or Item_GetItemInfoByPtr($p,"Customized") Then Return False
    Local $rarity=Item_GetItemInfoByPtr($p,"Rarity")
    If $rarity<>2623 And $rarity<>2626 And $rarity<>2624 And $rarity<>2627 Then Return False
    Switch Item_GetItemInfoByPtr($p,"ItemType")
        Case 0,2,4,5,7,12,13,15,16,19,22,24,26,27,32,35,36
            Return BB_GearSignature($p)=$signature
    EndSwitch
    Return False
EndFunc
