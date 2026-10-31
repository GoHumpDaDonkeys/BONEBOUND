#include-once
Global Const $BB_Gold=0xFF80B9D8, $BB_Ivory=0xFFE1E7EF, $BB_Muted=0xFF929C9F
Func BB_CreateUI()
    Opt("GUICloseOnESC",False)
    $BB_GUI=_ImGui_GUICreate("BONEBOUND | Bergen 55HP Farmer | v" & $BB_Version,1100,840,_Max(0,Int((@DesktopWidth-1100)/2)),_Max(0,Int((@DesktopHeight-880)/2)))
    If Not $BB_GUI Then
        MsgBox(16,"Bonebound","ImGui could not create its window. Check the included runtime and DirectX installation.")
        Exit 1
    EndIf
    ; This DLL creates a hidden host when platform viewports are disabled.
    ; Make the native host visible explicitly before the first frame.
    Local $outer=WinGetPos($BB_GUI), $client=WinGetClientSize($BB_GUI)
    Local $width=1100+$outer[2]-$client[0], $height=840+$outer[3]-$client[1]
    WinMove($BB_GUI,"",_Max(0,Int((@DesktopWidth-$width)/2)),_Max(0,Int((@DesktopHeight-$height)/2)),$width,$height)
    WinSetState($BB_GUI,"",@SW_SHOW)
    WinActivate($BB_GUI)
    _ImGui_StyleColorsDark()
    _ImGui_SetStyleColor($ImGuiCol_WindowBg,0xFF181410)
    _ImGui_SetStyleColor($ImGuiCol_ChildBg,0xFF24201B)
    _ImGui_SetStyleColor($ImGuiCol_PopupBg,0xFF24201B)
    _ImGui_SetStyleColor($ImGuiCol_Text,$BB_Ivory)
    _ImGui_SetStyleColor($ImGuiCol_TextDisabled,$BB_Muted)
    _ImGui_SetStyleColor($ImGuiCol_Border,0xFF454137)
    _ImGui_SetStyleColor($ImGuiCol_FrameBg,0xFF38332B)
    _ImGui_SetStyleColor($ImGuiCol_FrameBgHovered,0xFF514A3C)
    _ImGui_SetStyleColor($ImGuiCol_Button,0xFF4A4535)
    _ImGui_SetStyleColor($ImGuiCol_ButtonHovered,0xFF6B6148)
    _ImGui_SetStyleColor($ImGuiCol_ButtonActive,0xFF8B7A53)
    _ImGui_SetStyleColor($ImGuiCol_Header,0xFF514A3C)
    _ImGui_SetStyleColor($ImGuiCol_HeaderHovered,0xFF6B6148)
    _ImGui_SetStyleColor($ImGuiCol_CheckMark,$BB_Gold)
    _ImGui_SetStyleColor($ImGuiCol_PlotHistogram,$BB_Gold)
    $BB_HeaderTexture=_ImGui_ImageFromFile(@ScriptDir & "\Assets\Header.bmp")
    $BB_LootBones=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Bones",1))
    $BB_LootGolds=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Golds",1))
    $BB_LootCoins=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Coins",1))
    $BB_LootDust=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Dust",1))
    $BB_LootDye=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Dyes",1))
    $BB_LootEmblems=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","DecayedOrrEmblems",0))
    $BB_LootEvents=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","EventItems",1))
    $BB_LootLockpicks=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Lockpicks",1))
    $BB_LootBlues=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Blues",0))
    $BB_LootPurples=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Purples",0))
    $BB_LootGreens=Number(IniRead(@ScriptDir & "/Settings.ini","Loot","Greens",0))
    $BB_IdentifySell=Number(IniRead(@ScriptDir & "/Settings.ini","Inventory","IdentifyAndSell",0))
EndFunc
Func BB_Selected($value)
    Return $value<>0
EndFunc
Func BB_Save()
    IniWrite(@ScriptDir & "/Settings.ini","Inventory","IdentifyAndSell",Int($BB_IdentifySell<>0))
    IniWrite(@ScriptDir & "/Settings.ini","Character","Name",$BB_CharacterName)
    Local $values[11]=[$BB_LootBones,$BB_LootGolds,$BB_LootCoins,$BB_LootDust,$BB_LootDye,$BB_LootEmblems,$BB_LootEvents,$BB_LootLockpicks,$BB_LootBlues,$BB_LootPurples,$BB_LootGreens], $keys[11]=["Bones","Golds","Coins","Dust","Dyes","DecayedOrrEmblems","EventItems","Lockpicks","Blues","Purples","Greens"]
    For $i=0 To 10
        IniWrite(@ScriptDir & "/Settings.ini","Loot",$keys[$i],Int($values[$i]<>0))
    Next
EndFunc
Func BB_Log($text)
    $BB_Status=BB_ShortStatus($text)
    Local $stamp=@HOUR & ":" & @MIN & ":" & @SEC & "  ", $n=UBound($BB_Logs)
    ReDim $BB_Logs[$n+1]
    $BB_Logs[$n]=$stamp & $BB_Status
    If UBound($BB_Logs)>150 Then _ArrayDelete($BB_Logs,0)
    If Not $BB_Preview Then
        Local $file=FileOpen(@ScriptDir & "/Activity.log",1)
        If $file<>-1 Then
            FileWriteLine($file,$stamp & $text)
            FileClose($file)
        EndIf
    EndIf
EndFunc
Func BB_ShortStatus($text)
    Local $rules[22][2]=[ _
        ["(?i)^Waiting for map","Loading Map"], _
        ["(?i)^Map [0-9]+ loaded","Map Ready"], _
        ["(?i)^Map [0-9]+ did not","Loading Timeout"], _
        ["(?i)^Scanning running","Finding Characters"], _
        ["(?i)^Found [0-9]+ character","Character Ready"], _
        ["(?i)^No character","No Character"], _
        ["(?i)^Connecting to","Connecting"], _
        ["(?i)^Connected\.","Connected"], _
        ["(?i)^Connection failed","Connection Failed"], _
        ["(?i)^Bonebound v","Ready"], _
        ["(?i)^Loading your original","Loading Build"], _
        ["(?i)^Build skill slots","Build Ready"], _
        ["(?i)^Hard Mode already|^Hard Mode confirmed","Hard Mode Ready"], _
        ["(?i)^Requesting Hard Mode","Setting Hard Mode"], _
        ["(?i)^Leaving Bergen","Leaving Bergen"], _
        ["(?i)^Establishing maintained","Casting Enchantments"], _
        ["(?i)^Gathering enemies","Gathering Enemies"], _
        ["(?i)^Holding the farm","Fighting"], _
        ["(?i)^Collecting bones","Collecting Loot"], _
        ["(?i)^Returning to Bergen","Returning To Bergen"], _
        ["(?i)^Bags nearly|^At least 3 free","Inventory Full"], _
        ["(?i)^Run complete","Run Complete"] _
    ]
    For $i=0 To UBound($rules)-1
        If StringRegExp($text,$rules[$i][0]) Then Return $rules[$i][1]
    Next
    Local $words=StringSplit(StringStripWS($text,3)," ",2), $short=""
    For $i=0 To _Min(3,UBound($words)-1)
        If $i>0 Then $short&=" "
        $short&=$words[$i]
    Next
    Return StringRegExpReplace($short,"[.,;:]+$","")
EndFunc
Func BB_Halt($why)
    $BB_Run=False
    $BB_Combat=False
    If $BB_Attached Then Agent_CancelAction()
    BB_Log($why)
EndFunc
Func BB_Pump()
    If $BB_Preview Then Return
    If $BB_StopRequest Then
        $BB_StopRequest=False
        BB_Halt("Stopped by user")
    EndIf
    If $BB_ScanRequest Then
        $BB_ScanRequest=False
        BB_RefreshCharacters()
    EndIf
    If $BB_AttachRequest Then
        $BB_AttachRequest=False
        If Not $BB_Run And Not $BB_Attached Then
            If $BB_CharacterName="" Then
                BB_Log("No character selected. Log in and click REFRESH.")
            Else
                $BB_UIBusy=True
                BB_Log("Connecting to " & $BB_CharacterName & "...")
                If Core_Initialize($BB_CharacterName,False) Then
                    $BB_Attached=True
                    BB_Save()
                    BB_Log("Connected. Equip your 55HP set and start in Bergen.")
                Else
                    BB_Log("Connection failed. Refresh the character list and retry.")
                EndIf
                $BB_UIBusy=False
            EndIf
        EndIf
    EndIf
    If $BB_StartRequest Then
        $BB_StartRequest=False
        If $BB_Attached And Not $BB_Run Then
            BB_Save()
            $BB_Finish=False
            $BB_Run=True
            $BB_Fails=0
            BB_Log("Starting Bergen farm")
        ElseIf Not $BB_Attached Then
            BB_Log("Attach a character first")
        EndIf
    EndIf
    If TimerDiff($BB_LastUI)<350 Then Return
    $BB_LastUI=TimerInit()
    If Not $BB_Attached Then Return
    If Not ProcessExists($g_i_GWProcessId) Then
        $BB_Attached=False
        BB_Halt("Guild Wars closed. Restart Bonebound after reopening the game.")
        Return
    EndIf
    If $BB_Transition Or Map_GetInstanceInfo("IsLoading") Then
        $BB_VitalsText="MAP TRANSITION / waiting for player data"
        $BB_HP=0
        $BB_Energy=0
        Return
    EndIf
    $BB_HP=Agent_GetAgentInfo(-2,"HPPercent")
    $BB_Energy=Agent_GetAgentInfo(-2,"EnergyPercent")
    $BB_VitalsText="HP " & Round(Agent_GetAgentInfo(-2,"CurrentHP")) & "/" & Agent_GetAgentInfo(-2,"MaxHP") & "   |   ENERGY " & Round(Agent_GetAgentInfo(-2,"CurrentEnergy")) & "   |   MAP " & Map_GetMapID()
    For $i=0 To 7
        $BB_Effects[$i]=BB_Effect($i+1)>0
    Next
EndFunc
Func BB_RefreshCharacters()
    If $BB_Attached Or $BB_Run Or $BB_Preview Then Return
    $BB_UIBusy=True
    BB_Log("Scanning running Guild Wars clients...")
    Local $names=Scanner_GetLoggedCharNames()
    BB_SetCharacters($names)
    $BB_UIBusy=False
EndFunc
Func BB_SetCharacters($names)
    Local $saved=$BB_CharacterName, $parts=StringSplit($names,"|",2), $seen="|", $selected=""
    ReDim $BB_Characters[0]
    For $i=0 To UBound($parts)-1
        Local $name=StringStripWS($parts[$i],3)
        If $name="" Or StringInStr($seen,"|" & $name & "|") Then ContinueLoop
        $seen&=$name & "|"
        Local $n=UBound($BB_Characters)
        ReDim $BB_Characters[$n+1]
        $BB_Characters[$n]=$name
        If $name=$saved Then $selected=$name
    Next
    $BB_CharacterName=""
    If UBound($BB_Characters)=0 Then
        BB_Log("No characters found. Log in, then click REFRESH.")
        Return
    EndIf
    If $selected="" Then $selected=$BB_Characters[0]
    $BB_CharacterName=$selected
    BB_Log("Found " & UBound($BB_Characters) & " character(s). Selected: " & $selected)
EndFunc
Func BB_Render()
    If $BB_Rendering Or $BB_Exit Then Return
    $BB_Rendering=True
    If Not _ImGui_PeekMsg() Then
        $BB_Exit=True
        $BB_Run=False
        $BB_Rendering=False
        Return
    EndIf
    _ImGui_BeginFrame()
    _ImGui_SetNextWindowPos(0,0,$ImGuiCond_Always)
    _ImGui_SetNextWindowSize(1100,840,$ImGuiCond_Always)
    _ImGui_Begin("Bonebound",False,BitOR($ImGuiWindowFlags_NoTitleBar,$ImGuiWindowFlags_NoResize,$ImGuiWindowFlags_NoMove,$ImGuiWindowFlags_NoCollapse))
    _ImGui_SetWindowFontScale(1.12)
    _ImGui_PushStyleVar($ImGuiStyleVar_FrameRounding,5)
    _ImGui_PushStyleVar($ImGuiStyleVar_ChildRounding,8)
    _ImGui_PushStyleVarPos($ImGuiStyleVar_FramePadding,10,7)
    If $BB_HeaderTexture Then
        _ImGui_Image($BB_HeaderTexture,1080,132)
    Else
        _ImGui_TextColored("B O N E B O U N D",$BB_Gold)
    EndIf
    _ImGui_TextDisabled("FARM LOCATION")
    _ImGui_SameLine()
    _ImGui_SetNextItemWidth(625)
    If _ImGui_BeginCombo("##farm","Bergen Hot Springs") Then
        _ImGui_Selectable("Bergen Hot Springs",True)
        _ImGui_Selectable("Gates of Kryta",False,$ImGuiSelectableFlags_Disabled)
        _ImGui_EndCombo()
    EndIf
    _ImGui_Dummy(0,5)
    _ImGui_SetNextItemWidth(320)
    Local $name=$BB_CharacterName="" ? "Select Character" : $BB_CharacterName
    If _ImGui_BeginCombo("##character",$name) Then
        For $i=0 To UBound($BB_Characters)-1
            If _ImGui_Selectable($BB_Characters[$i],$BB_CharacterName=$BB_Characters[$i]) And Not $BB_Attached And Not $BB_UIBusy And Not $BB_Preview Then $BB_CharacterName=$BB_Characters[$i]
        Next
        _ImGui_EndCombo()
    EndIf
    _ImGui_SameLine()
    If _ImGui_Button("REFRESH",96,32) And Not $BB_Attached And Not $BB_UIBusy And Not $BB_Preview Then $BB_ScanRequest=True
    _ImGui_SameLine()
    If _ImGui_Button($BB_Attached ? "CONNECTED" : "ATTACH",110,32) And Not $BB_Attached And Not $BB_UIBusy And Not $BB_Preview Then $BB_AttachRequest=True
    _ImGui_SameLine()
    If _ImGui_Button("START FARM",140,32) And Not $BB_UIBusy And Not $BB_Preview Then $BB_StartRequest=True
    _ImGui_SameLine()
    If _ImGui_Button("FINISH RUN",140,32) And $BB_Run Then $BB_Finish=True
    _ImGui_SameLine()
    If _ImGui_Button("STOP",100,32) And Not $BB_Preview Then $BB_StopRequest=True
    _ImGui_Dummy(0,8)
    _ImGui_BeginChild("Ledger",-1,95,True)
    _ImGui_TextColored("HARVEST LEDGER",$BB_Gold)
    _ImGui_Columns(6,"Stats",False)
    BB_Stat("RUNS",$BB_Runs)
    BB_Stat("FAILED",$BB_Fails)
    BB_Stat("BONES",$BB_Bones)
    BB_Stat("GOLDS",$BB_Golds)
    BB_Stat("COINS",$BB_Coins)
    BB_Stat("SESSION",Int(TimerDiff($BB_Session)/60000) & " min")
    _ImGui_Columns(1)
    _ImGui_EndChild()
    _ImGui_TextColored($BB_Status,$BB_Gold)
    If $BB_Finish And $BB_Run Then _ImGui_TextDisabled("Finishing Run")
    _ImGui_TextDisabled($BB_VitalsText)
    _ImGui_Columns(2,"Vitals",False)
    _ImGui_ProgressBar($BB_HP,-1,8,"")
    _ImGui_NextColumn()
    _ImGui_ProgressBar($BB_Energy,-1,8,"")
    _ImGui_Columns(1)
    _ImGui_Dummy(0,8)
    _ImGui_Columns(3,"Details",False)
    _ImGui_BeginChild("Build",-1,340,True)
    _ImGui_TextColored("ENCHANTMENTS & BUILD",$BB_Gold)
    _ImGui_Separator()
    For $i=0 To 7
        _ImGui_TextColored(($i+1) & "  " & $BB_Names[$i] & ($BB_Effects[$i] ? "  *" : ""),$BB_Effects[$i] ? $BB_Gold : $BB_Muted)
        _ImGui_Dummy(0,4)
    Next
    _ImGui_EndChild()
    _ImGui_NextColumn()
    _ImGui_BeginChild("Loot",-1,340,True)
    _ImGui_TextColored("COLLECT",$BB_Gold)
    _ImGui_Separator()
    _ImGui_PushStyleVarPos($ImGuiStyleVar_FramePadding,10,3)
    _ImGui_CheckboxFlags("Bones",$BB_LootBones,1)
    _ImGui_CheckboxFlags("Blue",$BB_LootBlues,1)
    _ImGui_SameLine(160)
    _ImGui_CheckboxFlags("Purple",$BB_LootPurples,1)
    _ImGui_CheckboxFlags("Gold",$BB_LootGolds,1)
    _ImGui_SameLine(160)
    _ImGui_CheckboxFlags("Green",$BB_LootGreens,1)
    _ImGui_CheckboxFlags("Gold coins",$BB_LootCoins,1)
    _ImGui_CheckboxFlags("Glittering dust",$BB_LootDust,1)
    _ImGui_CheckboxFlags("Black / white dyes",$BB_LootDye,1)
    _ImGui_CheckboxFlags("Decayed Orr Emblems",$BB_LootEmblems,1)
    _ImGui_CheckboxFlags("Lockpicks",$BB_LootLockpicks,1)
    _ImGui_CheckboxFlags("Event Items",$BB_LootEvents,1)
    If _ImGui_IsItemHovered() Then _ImGui_SetTooltip("Festival drops: treat bags, eggs, bunnies, holiday sweets, drinks, tokens and party items.")
    _ImGui_PopStyleVar()
    _ImGui_Dummy(0,8)
    _ImGui_Separator()
    _ImGui_PushStyleVarPos($ImGuiStyleVar_FramePadding,10,3)
    _ImGui_CheckboxFlags("Identify & Sell Golds",$BB_IdentifySell,1)
    _ImGui_PopStyleVar()
    _ImGui_TextDisabled($BB_IdentifySell ? "Golds: Identify & Sell" : "Golds: Store Unidentified")
    _ImGui_EndChild()
    _ImGui_NextColumn()
    _ImGui_BeginChild("Activity",-1,340,True)
    _ImGui_TextColored("ACTIVITY",$BB_Gold)
    _ImGui_Separator()
    For $i=UBound($BB_Logs)-1 To 0 Step -1
        _ImGui_TextWrapped($BB_Logs[$i])
    Next
    _ImGui_EndChild()
    _ImGui_Columns(1)
    _ImGui_Dummy(0,8)
    _ImGui_Separator()
    _ImGui_TextDisabled("BONEBOUND v" & $BB_Version)
    _ImGui_PopStyleVar(3)
    _ImGui_End()
    _ImGui_EndFrame(0xFF181410)
    $BB_Rendering=False
EndFunc
Func BB_Stat($label,$value)
    _ImGui_TextDisabled($label)
    _ImGui_SetWindowFontScale(1.55)
    _ImGui_TextColored(String($value),$BB_Ivory)
    _ImGui_SetWindowFontScale(1.12)
    _ImGui_NextColumn()
EndFunc
