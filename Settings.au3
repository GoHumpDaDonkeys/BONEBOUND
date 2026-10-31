#include-once
Global Const $BB_Version = "0.4.0", $BB_Template = "Owol0IO8TCVr4UPYvGkUCAAgoPkH"
Global $BB_Exit=False, $BB_Run=False, $BB_Attached=False, $BB_Finish=False
Global $BB_Runs=0, $BB_Fails=0, $BB_Bones=0, $BB_Golds=0, $BB_Coins=0
Global $BB_Session=TimerInit(), $BB_LastUI=TimerInit(), $BB_BusyUntil=0, $BB_Combat=False
Global $BB_Expected[8]=[245,1516,262,297,0,256,250,242]
Global $BB_Names[8]=["Protective Spirit","Mystic Regeneration","Shield of Judgment","Blessed Signet","Empty slot (original build)","Blessed Aura","Essence Bond","Balthazar's Spirit"]
Global $BB_CastAt[9], $BB_Status="Awaiting character"
Global $BB_GUI
Global $BB_LootBones, $BB_LootGolds, $BB_LootCoins, $BB_LootDust, $BB_LootDye, $BB_LootEmblems, $BB_LootEvents, $BB_LootLockpicks, $BB_LootBlues, $BB_LootPurples, $BB_LootGreens
$g_b_AutoUpdate=False

Global $BB_Characters[0], $BB_CharacterName=IniRead(@ScriptDir & "/Settings.ini","Character","Name","")
Global $BB_Rendering=False, $BB_Preview=False, $BB_HeaderTexture=0
Global $BB_AttachRequest=False, $BB_StartRequest=False, $BB_StopRequest=False, $BB_ScanRequest=False
Global $BB_VitalsText="55HP MONK / NOT CONNECTED", $BB_Effects[8], $BB_HP=0, $BB_Energy=0
Global $BB_Logs[0], $BB_UIBusy=False

Global $BB_Transition=False

Global $BB_IdentifySell=0

