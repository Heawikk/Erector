Class SHHud extends OLHud
dependson(SHOptions)
config(tool);

Enum Menu
{
	Normal,
	Show,
	Collision,
	Cheats,
	SavePositionSelect,
	SaveOrLoad,
	Funny,
	PlayerModel,
	Credits,
	Teleporter,
	Logging,
	PlayerScale,
	SHDebug,
	LC,
	AdminChk, 
	PrisonChk,
	SewersChk,
	MWChk,
	CourtyardChk,
	FWChk,
	RevisitChk,
	LabChk,
	WorldSettings,
};

Enum EOffset
{
	O_None,
	O_Center,
	O_Full
};

Struct ButtonStruct
{
	var String Name;
	var string ConsoleCommand;
	var vector2d Start_Points;
	var vector2d End_Point;
	var vector2D Location;
	var vector2D Offset;
	var vector2D ScaledOffset;
	var vector2D ClipStart;
	var vector2D ClipEnd;
	var vector2D AbsoluteLocation;
	var bool template;
	var int Row;
	Var int Column;
};

Struct InputBox
{
	var String ID;
	var String Contents;
	var vector2d Start_Points;
	var vector2d End_Point;
};


Struct RGBA
{
	var Byte Red;
	var Byte Green;
	var Byte Blue;
	var Byte Alpha;
};

Struct ControllerSelection
{
	var int Row;
	var int Column;
};

Struct Saved_Menu
{
	var ControllerSelection SavedSelection;
	var Menu Menu;
};

Struct SHDebugBool
{
	var name Option;
	var bool Bool;
};

var config bool bShouldPauseWithoutFocus;
var config string Cursor;
var config float CursorScale, CursorOutline;
var config RGBA BackgroundColor, DefaultTextColor, ButtonColor, ButtonHoveredColor, CommandLineColor, CommandLineTextColor, CursorColor, CursorOutlineColor;

var bool Show_Menu, Pressed, AlreadyCommited;
var string Command, DebugPreviousMove, PlayerDebug;
var array<ButtonStruct> Buttons;
var ButtonStruct Previous_Button;
var Menu CurrentMenu, PreviousMenu;
var Vector2D TeleporterOffset;
var float BaseX, BaseY, DeltaTimeHUD;
var ControllerSelection SelectedButton;
var LocalPlayer Player;
var Array<Saved_Menu> PreviousMenus;
var Array<SHDebugBool> SHDebugBools;
var SHOptions CachedOptions;

var SHPlayerController Controller;
var SHGame CurrentGame;
var SHHero SpeedPawn;

`FunctVar

Function String LocalizedString(String Tag, Optional String Catagory="Text")
{
	Return Localize(Catagory, Tag, "SpeedrunHelper");
}

function DrawHUD() //Called every frame
{
	local SHOptions.SHVariable Variable;

	Super.DrawHUD(); //Run Parent Function First
	PlayerDebug="";

	Controller = SHPlayerController(PlayerOwner); //Cast to SHPlayerController using 'PlayerOwner'
	CurrentGame = SHGame(WorldInfo.Game);
	SpeedPawn = SHHero(Controller.Pawn);
	Buttons.Remove(0, Buttons.Length);

	BaseX=GetCorrectSizeX();

	UpdateActorDebug();

	ScreenTextDraw("ERECTOR\nAlpha 1.0", vect2D(1,1), MakeRGBA(60,179,113,180));

	foreach CurrentGame.SHOptions.SavedVariables(Variable)
	{
		if (Variable.Bool)
		{
			Variable.Modifier.onDrawHUD(Self);
		}
	}

	ScreenTextDraw(PlayerDebug, vect2d(0,25), MakeRGBA(255,255,255));

	if (Controller.Collision_Type_Override!=Normal && OLHero(Controller.Pawn).CylinderComponent.CollisionRadius==30)
	{
		Controller.SetPlayerCollisionType(Controller.Collision_Type_Override);
	}
	if (Show_Menu)
	{
		Save_Position_Interface();
	}
}

Event UpdateActorDebug()
{
	local string PlayerDebug;

	if (Controller.bIsModDebugEnabled)
	{
		PlayerDebug=PlayerDebug $ "\n\nCanvas Debug: \nCurrent AspectRatio: " $ GetAspectRatio() $ "\nWidth: " $ Canvas.SizeX $ "\nHeight: " $ Canvas.SizeY;
		PlayerDebug=PlayerDebug $ "\n\nMenu Debug: \nCurrently Selected Row: " $ SelectedButton.Row $ "\nCurrently Selected Column: " $ SelectedButton.Column;
		PlayerDebug=PlayerDebug $ "\nPrevious Controller Interaction: " $ DebugPreviousMove;
		if (Controller.bIsOL2StaminaSimulatorEnabled)
		{
			PlayerDebug=PlayerDebug $ "\n\nStamina Debug: " $ "\nCurrent Stamina: " $ SpeedPawn.RunStamina $ "\nStamina Percent: " $ SpeedPawn.StaminaPercent $ "\nOut of Stamina: " $ SpeedPawn.bOutofStamina;
			PlayerDebug=PlayerDebug $ "\nCurrent Stamina State: " $ SpeedPawn.CurrentStaminaState $ "\nReady to sprint: " $ SpeedPawn.bReadytosprint;
		}

		if (Controller.bIsOL2BandageSimulatorEnabled)
		{
			PlayerDebug=PlayerDebug $ "\n\nBandageDebug: " $ "\nbNeedsBandage: " $ SpeedPawn.bNeedsBandage $ "\nIsBandaging: " $ SpeedPawn.bIsBandaging $ "\nWearing Bandage: " $ SpeedPawn.bHasBandage;
			PlayerDebug=PlayerDebug $ "\nSpeedPercent: " $ SpeedPawn.SpeedPercent;
		}
	}

	ScreenTextDraw(PlayerDebug, vect2d(0,25), MakeRGBA(255,255,255));
}

Exec Function GoBack()
{
	if (!SHPlayerInput(Playerowner.PlayerInput).UsedGamepadLastTick()) {return;}
	if (CurrentMenu==Normal)
	{
		SHPlayerController(PlayerOwner).OpenConsoleMenu(0);
	}
	else
	{
		SetMenu(PreviousMenus[PreviousMenus.length - 1].Menu);
	}
}

Event Ghost_mode()
{
	local SHPlayerInput PlayerInput;

}

Event Save_Position_Interface()
{
	local SHPlayerInput PlayerInput;
	local Vector2D StartClip, EndClip;
	local SHPlayerController Controller;

	Controller = SHPlayerController(PlayerOwner);
	PlayerInput = SHPlayerInput(PlayerOwner.PlayerInput);
	Canvas.Font = Font'SH_Font.Calibri';

	DrawScaledBox( Vect2D( ( BaseX / 2) - 325, 150), Vect2D(700, 450),  BackgroundColor, StartClip, EndClip);

	EndClip = EndClip - Scale2DVector(vect2D(0, 15)); //Add Padding

	DrawScaledBox( Vect2D( ( BaseX / 2) - 325, 150), Vect2D( 700, 10),  CommandLineColor,,);

	ScreenTextDraw(Command, vect2D( ( BaseX / 2) - 325, 150 ), CommandLineTextColor);

	Switch(CurrentMenu)
	{
		case Normal:
		AddLocalizedButton("DebugFunctions", "SetMenu Show", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("PlayerFunctions", "SetMenu Cheats",, true);
		AddLocalizedButton("WorldFunctions", "SetMenu WorldSettings",, true);
		AddLocalizedButton("Entertainment", "SetMenu Funny",, true);
		AddLocalizedButton("ShowCredits", "SetMenu Credits",, true );
		break;

		case SavePositionSelect:
		DrawLocalizedText("SavePositionSelect", Vect2D( ( BaseX / 2), 300),,,, O_Center);
		AddButton(Vectortostring(Controller.Saved_Positions[1].Location), "Check_Position 1 | SetMenu SaveOrLoad", vect2d(15, 25),, true, StartClip, EndClip);
		AddButton(Vectortostring(Controller.Saved_Positions[2].Location), "Check_Position 2 | SetMenu SaveOrLoad", vect2d(1, 35),true, true);
		AddButton(Vectortostring(Controller.Saved_Positions[3].Location), "Check_Position 3 | SetMenu SaveOrLoad", vect2d(10, 35),true, true);
		AddButton(Vectortostring(Controller.Saved_Positions[4].Location), "Check_Position 4 | SetMenu SaveOrLoad", vect2d(5, 45),true, true);
		AddLocalizedButton("BackText", "SetMenu Cheats", , true);
		break;

		case SaveOrLoad:
		ScreenTextDraw("Location: " $ Controller.Saved_Positions[Controller.Selected_Save].Location $ "\nRotation: " $ Function.Vect2DtoString( Controller.Saved_Positions[Controller.Selected_Save].Rotation ), vect2D(750, 350 ),,,, O_Center );
		AddLocalizedButton("Save", "Save_Position " $ Controller.Selected_Save, vect2d(15, 25),,, StartClip, EndClip);
		AddLocalizedButton("Load", "Load_Position " $ Controller.Selected_Save,, true);
		AddLocalizedButton("BackText", "SetMenu SavePositionSelect" , , true);
		break;

		case Show:
		AddLocalizedButton("ChangeFPS", "ChangeFPS ", vect2d(15, 25),,, StartClip, EndClip, true);
		AddLocalizedButton("ShowFPS", "Stat FPS", , true);
		AddLocalizedButton("LevelInformation", "Stat Levels", , true);
		AddLocalizedButton("ActorDebugInfo", "ToggleSHOption ActorDebugView", , true);
		AddLocalizedButton("Collision", "Show Collision", , true);
		AddLocalizedButton("Volumes", "Show Volumes", , true);
		AddLocalizedButton("Fog", "Show Fog", , true);
		AddLocalizedButton("LevelColoration", "Show Levelcoloration", , true); 
		AddLocalizedButton("PostProcessing", "Show PostProcess", , true);
		AddLocalizedButton("ShowGrain", "ToogleGrain", , true);
		AddLocalizedButton("BackText", "SetMenu Normal", , true);
		break;

		case WorldSettings:
		AddLocalizedButton("CheckpointLoader", "SetMenu LC", vect2d(15, 25),,, StartClip, EndClip);
		AddLocalizedButtonDisplay("UnlockAllDoorsCheat", Controller.bShouldUnlockAllDoors, "UnlockDoorsToggle",, true );
		AddLocalizedButton("Skip_Start_Intro", "SkipStart", , true);
		AddLocalizedButton("Skip_Torture", "SkipTorture", , true);
		AddLocalizedButton("Reload", "Reload", , true);
		AddLocalizedButton("BackText", "SetMenu Normal", , true);
		break;

		case Collision:

		AddLocalizedButton("CollisionNormal", "SetPlayerCollisionType CT_Normal | SetMenu Cheats", vect2d(15, 25),,, StartClip, EndClip );
		AddLocalizedButton("CollisionVaulting", "SetPlayerCollisionType CT_Vault | SetMenu Cheats", , true );
		AddLocalizedButton("CollisionDoor", "SetPlayerCollisionType CT_Door | SetMenu Cheats", , true );
		AddLocalizedButton("CollisionShimmy", "SetPlayerCollisionType CT_Shimmy | SetMenu Cheats", , true );
		AddLocalizedButton("BackText", "SetMenu Cheats", , true);
		break;

		case Cheats:

		AddLocalizedButton("ShowPositionSaver", "SetMenu SavePositionSelect", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("ShowTeleporter", "SetMenu Teleporter",, true);
		AddLocalizedButton("KillAllCheat", "KillAllEnemys",, true);
		AddLocalizedButtonDisplay("FreecamCheat", !Controller.UsingFirstPersonCamera(), "ToogleFreeCam",, true);
		AddLocalizedButtonDisplay("FreeBhopsFunny", DisplaySHOption("FreeBHops"), "ToggleSHOption FreeBHops", , true);
		AddLocalizedButton("TeleportToFreecamCheat", "Teleporttofreecam",, true );
		AddLocalizedButtonDisplay("PlayerColliderSizeCheat", SHPlayerController(PlayerOwner).Collision_Type_Override, "SetMenu Collision",, true );
		AddLocalizedButtonDisplay("GodmodeCheat", DisplaySHOption("GodMode"), "ToggleSHOption GodMode",, true );
		AddLocalizedButtonDisplay("ToggleDeathBoundsCheat", Controller.bDisableKillBound, "ToogleKillBound",, true );
		AddLocalizedButton("UnlimitedBatteries", "UnlimitedBatteries",, true );
		AddButton("Player Scaler", "SetMenu PlayerScale",, true);
		AddLocalizedButton("PlayerModel", "SetMenu PlayerModel",, true);
		AddLocalizedButton("BackText", "SetMenu Normal", , true);
		break;

		Case Funny:
		AddLocalizedButtonDisplay("EveryoneFatherMartinFunny", Controller.bShouldMartinReplaceEnemyModels, "MartinifyToggle",vect2d(15, 25),,, StartClip, EndClip );
		AddLocalizedButtonDisplay("EveryoneWieldFatherMartin", Controller.bShouldWieldFatherMartin, "ToogleWieldFatherMartin",,true);
		AddLocalizedButtonDisplay("WernickeSkipFunny", DisplaySHOption("WernickeSkip"), "ToggleSHOption WernickeSkip", , true);
		AddLocalizedButtonDisplay("OL2BandageFunny", DisplaySHOption("OL2BandageSim"), "ToggleSHOption OL2BandageSim", , true);
		AddLocalizedButtonDisplay("OL2StaminaFunny", Controller.bIsOL2StaminaSimulatorEnabled, "SimulateOL2Stamina", , true);
		AddLocalizedButtonDisplay("SeizureFunny", Controller.SpeedPawn.bShouldSeizure,"ToggleSeizure",,True);
		AddLocalizedButton("BackText", "SetMenu Normal", , true);
		Break;

		Case LC:
		AddLocalizedButton("AdminBlock", "SetMenu AdminChk", vect2d(15, 25),,, StartClip, EndClip);
		AddLocalizedButton("Prison", "SetMenu PrisonChk",, true );
		AddLocalizedButton("Sewers", "SetMenu SewersChk",, true );
		AddLocalizedButton("MaleWard", "SetMenu MWChk",, true );
		AddLocalizedButton("Courtyard", "SetMenu CourtyardChk",, true );
		AddLocalizedButton("FemaleWard", "SetMenu FWChk",, true );
		AddLocalizedButton("BackToAdmin", "SetMenu RevisitChk",, true );
		AddLocalizedButton("Lab", "SetMenu LabChk",, true );
		AddLocalizedButton("BackText", "SetMenu WorldSettings", , true);
		break;

		Case PlayerModel:
		AddButton("Miles", "UpdatePlayerModel PM_Miles",vect2d(15, 125),,, StartClip, EndClip );
		AddButton("Miles No Fingers", "UpdatePlayerModel PM_MilesNoFingers",, true);
		AddButton("WaylonIT", "UpdatePlayerModel PM_WaylonIT",, true);
		AddButton("Waylon Prisoner", "UpdatePlayerModel PM_WaylonPrisoner",, true);
		AddLocalizedButton("NoOverridePM", "UpdatePlayerModel PM_NoOverride",, true);
		AddLocalizedButton("BackText", "SetMenu Cheats",, true);
		break;

		Case Credits:
		DrawLocalizedText("Credits", vect2D(0, 10 ),,, true,,,StartClip);
		AddLocalizedButton("BackText", "SetMenu Normal",vect2d(15, 205),,, StartClip, EndClip );
		break;

		Case Teleporter:
		ScreenTextDraw("Offset: " $ TeleporterOffset.X $ ", " $ TeleporterOffset.Y, vect2D(250, 50 ),,,, O_Center, O_Center, StartClip );
		AddLocalizedButton("Forward", "AddTeleportOffset 25 0", vect2d(15, 25),false, false, StartClip, EndClip);
		AddLocalizedButton("Left", "AddTeleportOffset 0 -25", vect2d(5, 50),false, false, StartClip, EndClip);
		AddLocalizedButton("Right", "AddTeleportOffset 0 25", vect2d(50, 50),false, false, StartClip, EndClip);
		AddLocalizedButton("Back", "AddTeleportOffset -25 0", vect2d(15, 75),false, false, StartClip, EndClip);
		AddLocalizedButton("Teleport", "Teleport_In_Direction " $ TeleporterOffset.X $ " " $ TeleporterOffset.Y, vect2d(5, 200),true, true, StartClip, EndClip);
		AddLocalizedButton("BackText", "SetMenu Cheats",vect2d(425, 425), true,, StartClip, EndClip );
		break;

		Case PlayerScale:
		AddButton("Up (x2)", "ScalePlayer " $ Controller.Pawn.Mesh.Scale + 1, vect2d(15, 25),true, false, StartClip, EndClip);
		AddButton("Up (x1.5)", "ScalePlayer " $ Controller.Pawn.Mesh.Scale + 0.5, vect2d(15, 25),true, false, StartClip, EndClip);
		AddButton("Up (x1.2)", "ScalePlayer " $ Controller.Pawn.Mesh.Scale + 0.2, vect2d(15, 25),true, false, StartClip, EndClip);
		AddButton("Down (x1.2)", "ScalePlayer " $ Controller.Pawn.Mesh.Scale - 0.2, vect2d(15, 25),true, false, StartClip, EndClip);
		AddButton("Down (x1.5)", "ScalePlayer " $ Controller.Pawn.Mesh.Scale - 0.5, vect2d(15, 25),true, false, StartClip, EndClip);
		AddButton("Down (x2)", "ScalePlayer " $ Controller.Pawn.Mesh.Scale - 1, vect2d(15, 25),true, false, StartClip, EndClip);
		AddLocalizedButton("BackText", "SetMenu Cheats", , true);
		break;

		Case AdminChk:
		AddLocalizedButton("StartGame", "LoadCheckpoint StartGame", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("AdminGates", "LoadCheckpoint Admin_Gates",, true );
		AddLocalizedButton("AdminGarden", "LoadCheckpoint Admin_Garden",, true );
		AddLocalizedButton("AdminExplosion", "LoadCheckpoint Admin_Explosion",, true );
		AddLocalizedButton("AdminMezzanine", "LoadCheckpoint Admin_Mezzanine",, true );
		AddLocalizedButton("AdminMainHall", "LoadCheckpoint Admin_MainHall",, true );
		AddLocalizedButton("AdminWheelChair", "LoadCheckpoint Admin_WheelChair",, true );
		AddLocalizedButton("AdminSecurityRoom", "LoadCheckpoint Admin_SecurityRoom",, true );
		AddLocalizedButton("AdminBasement", "LoadCheckpoint Admin_Basement",, true );
		AddLocalizedButton("AdminElectricity", "LoadCheckpoint Admin_Electricity",, true );
		AddLocalizedButton("AdminPostBasement", "LoadCheckpoint Admin_PostBasement",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;

		Case PrisonChk:
		AddLocalizedButton("Prison_Start", "LoadCheckpoint Prison_Start", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("Prison_IsolationCells01_Mid", "LoadCheckpoint Prison_IsolationCells01_Mid",, true );
		AddLocalizedButton("Prison_ToPrisonFloor", "LoadCheckpoint Prison_ToPrisonFloor",, true );
		AddLocalizedButton("Prison_PrisonFloor_3rdFloor", "LoadCheckpoint Prison_PrisonFloor_3rdFloor",, true );
		AddLocalizedButton("Prison_PrisonFloor_SecurityRoom1", "LoadCheckpoint Prison_PrisonFloor_SecurityRoom1",, true );
		AddLocalizedButton("Prison_PrisonFloor02_IsolationCells01", "LoadCheckpoint Prison_PrisonFloor02_IsolationCells01",, true );
		AddLocalizedButton("Prison_Showers_2ndFloor", "LoadCheckpoint Prison_Showers_2ndFloor",, true );
		AddLocalizedButton("Prison_PrisonFloor02_PostShowers", "LoadCheckpoint Prison_PrisonFloor02_PostShowers",, true );
		AddLocalizedButton("Prison_PrisonFloor02_SecurityRoom2", "LoadCheckpoint Prison_PrisonFloor02_SecurityRoom2",, true );
		AddLocalizedButton("Prison_IsolationCells02_Soldier", "LoadCheckpoint Prison_IsolationCells02_Soldier",, true );
		AddLocalizedButton("Prison_IsolationCells02_PostSoldier", "LoadCheckpoint Prison_IsolationCells02_PostSoldier",, true );
		AddLocalizedButton("Prison_OldCells_PreStruggle", "LoadCheckpoint Prison_OldCells_PreStruggle",, true );
		AddLocalizedButton("Prison_OldCells_PreStruggle2", "LoadCheckpoint Prison_OldCells_PreStruggle2",, true );
		AddLocalizedButton("Prison_Showers_Exit", "LoadCheckpoint Prison_Showers_Exit",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;

		Case SewersChk:
		AddLocalizedButton("Sewer_start", "LoadCheckpoint Sewer_start", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("Sewer_FlushWater", "LoadCheckpoint Sewer_FlushWater",, true );
		AddLocalizedButton("Sewer_WaterFlushed", "LoadCheckpoint Sewer_WaterFlushed",, true );
		AddLocalizedButton("Sewer_Ladder", "LoadCheckpoint Sewer_Ladder",, true );
		AddLocalizedButton("Sewer_ToCitern", "LoadCheckpoint Sewer_ToCitern",, true );
		AddLocalizedButton("Sewer_Citern1", "LoadCheckpoint Sewer_Citern1",, true );
		AddLocalizedButton("Sewer_Citern2", "LoadCheckpoint Sewer_Citern2",, true );
		AddLocalizedButton("Sewer_PostCitern", "LoadCheckpoint Sewer_PostCitern",, true );
		AddLocalizedButton("Sewer_ToMaleWard", "LoadCheckpoint Sewer_ToMaleWard",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;

		Case MWChk:
		AddLocalizedButton("Male_Start1", "LoadCheckpoint Male_Start", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("Male_Chase1", "LoadCheckpoint Male_Chase",, true );
		AddLocalizedButton("Male_ChasePause1", "LoadCheckpoint Male_ChasePause",, true );
		AddLocalizedButton("Male_Torture1", "LoadCheckpoint Male_Torture",, true );
		AddLocalizedButton("Male_TortureDone1", "LoadCheckpoint Male_TortureDone",, true );
		AddLocalizedButton("Male_Surgeon1", "LoadCheckpoint Male_surgeon",, true );
		AddLocalizedButton("Male_GetTheKey1", "LoadCheckpoint Male_GetTheKey",, true );
		AddLocalizedButton("Male_GetTheKey2", "LoadCheckpoint Male_GetTheKey2",, true );
		AddLocalizedButton("Male_Elevator1", "LoadCheckpoint Male_Elevator",, true );
		AddLocalizedButton("Male_ElevatorDone1", "LoadCheckpoint Male_ElevatorDone",, true );
		AddLocalizedButton("Male_Priest1", "LoadCheckpoint Male_Priest",, true );
		AddLocalizedButton("Male_Cafeteria1", "LoadCheckpoint Male_Cafeteria",, true );
		AddLocalizedButton("Male_SprinklerOff1", "LoadCheckpoint Male_SprinklerOff",, true );
		AddLocalizedButton("Male_SprinklerOn1", "LoadCheckpoint Male_SprinklerOn",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;

		Case CourtyardChk:
		AddLocalizedButton("Courtyard_Start", "LoadCheckpoint Courtyard_Start", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("Courtyard_Corridor", "LoadCheckpoint Courtyard_Corridor",, true );
		AddLocalizedButton("Courtyard_Chapel", "LoadCheckpoint Courtyard_Chapel",, true );
		AddLocalizedButton("Courtyard_Soldier1", "LoadCheckpoint Courtyard_Soldier1",, true );
		AddLocalizedButton("Courtyard_Soldier2", "LoadCheckpoint Courtyard_Soldier2",, true );
		AddLocalizedButton("Courtyard_FemaleWard", "LoadCheckpoint Courtyard_FemaleWard",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;

		Case FWChk:
		AddLocalizedButton("Female_Start", "LoadCheckpoint Female_Start", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("Female_Mainchute", "LoadCheckpoint Female_Mainchute",, true );
		AddLocalizedButton("Female_2ndFloor", "LoadCheckpoint Female_2ndFloor",, true );
		AddLocalizedButton("Female_2ndFloorChute", "LoadCheckpoint Female_2ndFloorChute",, true );
		AddLocalizedButton("Female_ChuteActivated", "LoadCheckpoint Female_ChuteActivated",, true );
		AddLocalizedButton("Female_Keypickedup", "LoadCheckpoint Female_Keypickedup",, true );
		AddLocalizedButton("Female_3rdFloor", "LoadCheckpoint Female_3rdFloor",, true );
		AddLocalizedButton("Female_3rdFloorHole", "LoadCheckpoint Female_3rdFloorHole",, true );
		AddLocalizedButton("Female_3rdFloorPostHole", "LoadCheckpoint Female_3rdFloorPostHole",, true );
		AddLocalizedButton("Female_Tobigjump", "LoadCheckpoint Female_Tobigjump",, true );
		AddLocalizedButton("Female_LostCam", "LoadCheckpoint Female_LostCam",, true );
		AddLocalizedButton("Female_FoundCam", "LoadCheckpoint Female_FoundCam",, true );
		AddLocalizedButton("Female_Chasedone", "LoadCheckpoint Female_Chasedone",, true );
		AddLocalizedButton("Female_Exit", "LoadCheckpoint Female_Exit",, true );
		AddLocalizedButton("Female_Jump", "LoadCheckpoint Female_Jump",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;

		Case RevisitChk:
		AddLocalizedButton("Revisit_Soldier1", "LoadCheckpoint Revisit_Soldier1", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("Revisit_Mezzanine", "LoadCheckpoint Revisit_Mezzanine",, true );
		AddLocalizedButton("Revisit_ToRH", "LoadCheckpoint Revisit_ToRH",, true );
		AddLocalizedButton("Revisit_RH", "LoadCheckpoint Revisit_RH",, true );
		AddLocalizedButton("Revisit_FoundKey", "LoadCheckpoint Revisit_FoundKey",, true );
		AddLocalizedButton("Revisit_To3rdfloor", "LoadCheckpoint Revisit_To3rdfloor",, true );
		AddLocalizedButton("Revisit_3rdFloor", "LoadCheckpoint Revisit_3rdFloor",, true );
		AddLocalizedButton("Revisit_RoomCrack", "LoadCheckpoint Revisit_RoomCrack",, true );
		AddLocalizedButton("Revisit_ToChapel", "LoadCheckpoint Revisit_ToChapel",, true );
		AddLocalizedButton("Revisit_PriestDead", "LoadCheckpoint Revisit_PriestDead",, true );
		AddLocalizedButton("Revisit_Soldier3", "LoadCheckpoint Revisit_Soldier3",, true );
		AddLocalizedButton("Revisit_ToLab", "LoadCheckpoint Revisit_ToLab",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;

		Case LabChk:
		AddLocalizedButton("Lab_Start", "LoadCheckpoint Lab_Start", vect2d(15, 25),, true, StartClip, EndClip);
		AddLocalizedButton("Lab_PremierAirLock", "LoadCheckpoint Lab_PremierAirLock",, true );
		AddLocalizedButton("Lab_SwarmIntro", "LoadCheckpoint Lab_SwarmIntro",, true );
		AddLocalizedButton("Lab_SwarmIntro2", "LoadCheckpoint Lab_SwarmIntro2",, true );
		AddLocalizedButton("Lab_Soldierdead", "LoadCheckpoint Lab_Soldierdead",, true );
		AddLocalizedButton("Lab_SpeachDone", "LoadCheckpoint Lab_SpeachDone",, true );
		AddLocalizedButton("Lab_SwarmCafeteria", "LoadCheckpoint Lab_SwarmCafeteria",, true );
		AddLocalizedButton("Lab_EBlock", "LoadCheckpoint Lab_EBlock",, true );
		AddLocalizedButton("Lab_ToBilly", "LoadCheckpoint Lab_ToBilly",, true );
		AddLocalizedButton("Lab_BigRoom", "LoadCheckpoint Lab_BigRoom",, true );
		AddLocalizedButton("Lab_BigRoomDone", "LoadCheckpoint Lab_BigRoomDone",, true );
		AddLocalizedButton("Lab_BigTower", "LoadCheckpoint Lab_BigTower",, true );
		AddLocalizedButton("Lab_BigTowerStairs", "LoadCheckpoint Lab_BigTowerStairs",, true );
		AddLocalizedButton("Lab_BigTowerMid", "LoadCheckpoint Lab_BigTowerMid",, true );
		AddLocalizedButton("Lab_BigTowerDone", "LoadCheckpoint Lab_BigTowerDone",, true );
		AddLocalizedButton("BackText", "SetMenu LC", , true);
		break;


		
	}
	DrawMouse();
}

Exec Function bool ToggleSHOption(coerce Name Option, optional Int Toggle=INDEX_NONE, optional bool bShouldExecute=true)
{
	Return SHPlayerController(PlayerOwner).CachedOptions.ToggleSHOption(Option, Toggle, bShouldExecute);
}

Exec Function bool DisplaySHOption(coerce Name Option)
{
	Return SHPlayerController(PlayerOwner).CachedOptions.GetSHBool(Option);
}

Exec Function SetSHDebugOption(Name Option, Int Bool)
{
	local Int Index;
	local SHDebugBool SavedBool;

	FindBool:
	Index = SHDebugBools.find('Option', Option);
	if (Index==Index_None) 
	{
		SavedBool.Option=Option;
		SHDebugBools.AddItem(SavedBool);
		goto FindBool;
	}

	if (Bool<=Index_None)
	{
		SHDebugBools[Index].Bool=!SHDebugBools[Index].Bool;
	}
	else
	{
		SHDebugBools[Index].Bool=Bool(Bool);
	}
}

Function Bool GetSHDebugOption(Name Option)
{
	local Int Index;

	Index = SHDebugBools.find('Option', Option);
	if (Index==Index_None) 
	{
		return false;
	}
	else
	{
		return SHDebugBools[Index].bool;
	}
}

Event Tick(Float DeltaTime)
{
	DeltaTimeHUD=DeltaTime;
	Super.Tick(DeltaTime);
}

Exec Function OLLog(String Log)
{
	local Sequence GameSeq;

	local name Name;
	local OLCheckpoint SavedCheckpoint;
	local SequenceObject SavedSequence;
	Local array<SequenceObject> SavedSequences;
	local bool bool;
	local int Index;

	GameSeq = WorldInfo.GetGameSequence();

	Switch(Log)
	{
		Case "Objectives":
			foreach SHPlayerController(PlayerOwner).CompletedObjectives(Name)
			{
				`log("ID: " $ Name);
				++Index;
			}
		break;

		Case "Checkpoints":
			`log("Beginning to print checkpoints (Not in order)");
			`log("------------------------------");
			Foreach AllActors(Class'OLGame.OLCheckpoint', SavedCheckpoint)
			{
				if (SavedCheckpoint == none) {break;}
				`log("Name: " $ SavedCheckpoint.CheckpointName);
				`log( "Chapter: " $ Localize("Locations", String(SavedCheckpoint.Tag), "OLGame") );
				`log("Location: " $ SavedCheckpoint.Location);
				bool=false;
				GameSeq.FindSeqObjectsByClass(class'OLSeqAct_Checkpoint', true, SavedSequences);
				foreach SavedSequences(SavedSequence)
				{
					if (SavedSequence.Class == Class'OLSeqAct_Checkpoint') 
					{
						if (OLSeqAct_Checkpoint(SavedSequence).CheckpointName == SavedCheckpoint.CheckpointName) {bool=true;}
					}
				}
				`log("Is triggered by Kismet: " $ bool);
				`log("------------------------------");
				++Index;
			}
		break;
	}
}

Exec Function MoveSelection( int Right, int Up)
{	
	local ButtonStruct Button;
	local Int StoredColumn;

	if ( !SHPlayerInput(Playerowner.PlayerInput).UsedGamepadLastTick() ) {return;}

	Button = FindButton(Buttons, SelectedButton.Row + Right, SelectedButton.Column);
	If (Button.Row==-1)
	{	
		if (Right>0 && SelectedButton.Row>1) //left
		{
			SelectedButton.Row = 1;
			DebugPreviousMove="Moved left and wrapped back to Row 1";
			goto Button2;
		}
		else if (Right>0 && SelectedButton.Row<=1)
		{
			SelectedButton.Row=Buttons[Buttons.length - 1].row;
			SelectedButton.Column=Buttons[Buttons.length - 1].column;
			DebugPreviousMove="Moved left, and wrapped to column " $ SelectedButton.Column;
			goto Button2;
		}
		else if (Right<0) //right
		{
			Button = FindButton(Buttons, Buttons[Buttons.Length - 1].Row, SelectedButton.Column);
			if (Button.Row!=-1)
			{
				SelectedButton.Row = Button.Row;
				DebugPreviousMove="Moved Right, and wrapped to row " $ Button.Row;
				goto Button2;
			}
			else
			{
				Button = FindButton(Buttons, SelectedButton.Row + 1, 1);
				if (Button.Row!=-1)
				{
					StoredColumn=1;
					While (Button.Row!=-1)
					{
						Button = FindButton(Buttons,  SelectedButton.Row + 1, StoredColumn + 1);
						if (Button.Row!=-1)
						{
							StoredColumn = Button.Column;
						}
					}
					SelectedButton.Row=SelectedButton.Row + 1;
					SelectedButton.Column=StoredColumn;
					DebugPreviousMove="Moved Right, and wrapped to column " $ StoredColumn;
					goto Button2;
				}
			}
		}
	}
	else
	{
		SelectedButton.Row = SelectedButton.Row + Right;
		if (Right>0) {DebugPreviousMove="Right";} else if (Right<0) {DebugPreviousMove="Left";}
		goto Button2;
	}

	Button2:
	Button = FindButton(Buttons, SelectedButton.Row, SelectedButton.Column + Up);
	If (Button.Row==-1)
	{
		if (Up<0) //Going up
		{
			if (SelectedButton.Row==1)
			{
				Button = FindButton(Buttons,  Buttons[Buttons.Length - 1].Row, Buttons[Buttons.Length - 1].Column);
				SelectedButton.Row=Button.Row;
				SelectedButton.Column=Button.Column;
				DebugPreviousMove="Moved Up, and wrapped forward to the last button at Column " $ Button.Column $ " and at row " $ Button.Row;
			}
			else
			{
				Button = FindButton(Buttons,  SelectedButton.Row - 1, 1);
				StoredColumn=1;
				While (Button.Row!=-1)
				{
					Button = FindButton(Buttons,  SelectedButton.Row - 1, StoredColumn + 1);
					if (Button.Row!=-1)
					{
						StoredColumn = Button.Column;
					}
				}
				SelectedButton.Row=SelectedButton.Row - 1;
				SelectedButton.Column=StoredColumn;
				DebugPreviousMove="Moved Up, and wrapped back to the button at Column " $ StoredColumn $ " and at row " $ SelectedButton.Row;
			}
		}
		else if (Up>0) //Going down
		{
			Button = FindButton(Buttons,  Buttons[Buttons.Length - 1].Row, Buttons[Buttons.Length - 1].Column);
			if (SelectedButton.Row==Button.Row)
			{
				Button = FindButton(Buttons,  1, 1);
				SelectedButton.Row=Button.Row;
				SelectedButton.Column=Button.Column;
			}
			else
			{
				SelectedButton.Row=SelectedButton.Row + 1;
				SelectedButton.Column=1;
			}
		}
	}
	else
	{
		SelectedButton.Column = SelectedButton.Column + Up;
	}
}

Exec Function AddTeleportOffset(float X, Float Y)
{
	TeleporterOffset.X = TeleporterOffset.X + X;
	TeleporterOffset.Y = TeleporterOffset.Y + Y;
}

Exec Function SelectButton()
{
	local ButtonStruct Button;
	if ( !SHPlayerInput(Playerowner.PlayerInput).UsedGamepadLastTick() ) {return;}
	Button = FindButton(Buttons, SelectedButton.Row, SelectedButton.Column);

	if (Button.Template)
	{
		Command=Button.ConsoleCommand;
		return;
	}
	PlayerOwner.ConsoleCommand(Button.ConsoleCommand);
	return;
}

Function String VariableDisplay(String String, coerce String Var)
{
	Return String $ ": " $ Var;
}

Function String LocalizedVariableDisplay(String ID, coerce String Var, Optional bool Button)
{
	if (Button) {Return VariableDisplay(LocalizedString(ID, "Buttons"), Var);}
	Return VariableDisplay(LocalizedString(ID), var);
}

Function AddLocalizedButtonDisplay(String ID, coerce string var, String ConsoleCommand, optional vector2D Location, optional bool AutoDown=False, optional bool Extend=False, optional vector2D Bound_Start, optional vector2D Bound_End, optional bool template)
{
	AddButton(LocalizedVariableDisplay(ID, Var, True), ConsoleCommand, Location, AutoDown, Extend, Bound_Start, Bound_End, template);
}

Function DrawMouse()
{
	local SHPlayerInput PlayerInput;
	local Vector2D scale;

	if ( SHPlayerInput(PlayerOwner.PlayerInput).UsingGamepad() ) { Return; }

	PlayerInput = SHPlayerInput(PlayerOwner.PlayerInput);
	if (!PlayerInput.bLeftClick)
	{
		ScreenTextDraw(Cursor, Vect2d(PlayerInput.MousePosition.X,PlayerInput.MousePosition.Y), CursorOutlineColor,vect2d(CursorScale * CursorOutline,CursorScale * CursorOutline), false, O_Center, O_Center);
		ScreenTextDraw(Cursor, Vect2d(PlayerInput.MousePosition.X,PlayerInput.MousePosition.Y), CursorColor,vect2d(CursorScale,CursorScale), false, O_Center, O_Center);
	}
	else
	{
		ScreenTextDraw(Cursor, Vect2d(PlayerInput.MousePosition.X,PlayerInput.MousePosition.Y), CursorColor,vect2d(CursorScale * CursorOutline,CursorScale * CursorOutline), false, O_Center, O_Center);
		ScreenTextDraw(Cursor, Vect2d(PlayerInput.MousePosition.X,PlayerInput.MousePosition.Y), CursorOutlineColor,vect2d(CursorScale,CursorScale), false, O_Center, O_Center);
	}
}

Function WorldTextDraw( string Text, vector location, Float Max_View_Distance, float scale, optional vector offset ) //Simple function for drawing text in 3D space
{
	Local Vector DrawLocation; //Location to Draw Text
	Local Vector CameraLocation; //Location of Player Camera
	Local Vector2D AdditionLocation;
	Local Rotator CameraDir; //Direction the camera is facing
	Local Float Distance; //Distance between Camera and text
	Local Vector2D TextSize;
	Local Vector2D ScaledOffset2D;
	Local Array<String> StringArray;
	local FontRenderInfo FontRenderInfo;

	PlayerOwner.GetPlayerViewPoint( CameraLocation, CameraDir );
	distance =  ScalebyCam( VSize(CameraLocation - Location) ); //Get the distance between the camera and the location of the text being placed, then scale it by the camera's FOV. 
	DrawLocation = Canvas.Project(Location); //Project the 3D location into 2D space.
	ScaledOffset2D.X = Offset.X;
	ScaledOffset2D.Y = Offset.Y;
	ScaledOffset2D = Scale2dVector(ScaledOffset2D);
	Offset.X = ScaledOffset2D.X;
	Offset.Y = ScaledOffset2D.Y;
	if ( vector(CameraDir) dot (location - CameraLocation) > 0.0 && distance < Max_View_Distance )
	{
		Scale = Scale / Distance; //Scale By distance. 
		StringArray = SplitString(Text, "\n", false);
		foreach StringArray(Text)
		{
			FontRenderInfo.bClipText = True;
			Canvas.SetPos(DrawLocation.X + ( Offset.X * Scale ), ( (DrawLocation.Y + AdditionLocation.Y) + ( Offset.Y * Scale ) ), DrawLocation.Z ); //Set the Position of text using the Draw Location and an optional Offset. 
		
			canvas.strlen(Text, TextSize.X, TextSize.Y);
			canvas.SetDrawColor(BackgroundColor.Red, BackgroundColor.Green, BackgroundColor.Blue, BackgroundColor.Alpha);
			Canvas.DrawRect( (TextSize.X * scale) / 1280.0f * Canvas.SizeX, (TextSize.Y * scale) / 1280.0f * Canvas.SizeX);
		
			canvas.SetDrawColor(DefaultTextColor.Red, DefaultTextColor.Green, DefaultTextColor.Blue, DefaultTextColor.Alpha);
			Canvas.SetPos( DrawLocation.X + ( Offset.X * Scale ), ( (DrawLocation.Y + AdditionLocation.Y) + ( Offset.Y * Scale ) ), DrawLocation.Z ); //Set the Position of text using the Draw Location and an optional Offset. 
			Canvas.DrawText(Text, false, Scale / 1280.0f * Canvas.SizeX, Scale / 1280.0f * Canvas.SizeX, FontRenderInfo ); //Draw the text
			AdditionLocation.Y = AdditionLocation.Y + ( (TextSize.Y * scale) / 1280.0f * Canvas.SizeX );
			// / 720.0f * Canvas.SizeY
		}
	}
}

Function ScreenTextDraw(String Text, Vector2D Location, optional RGBA Color=DefaultTextColor, optional Vector2D Scale=Vect2D(1,1), optional bool Scale_Location=True, optional EOffset OffsetX, optional EOffset OffsetY, optional vector2D Bound_Start)
{
	local vector2D ScaleCalc;
	local vector2D TextSize;
	local vector2D PreviousOrigin, PreviousClip;

	PreviousOrigin = vect2d(Canvas.OrgX, Canvas.OrgY);

	Canvas.SetOrigin(Bound_Start.X, Bound_Start.Y);


	ScaleCalc=Scale2dVector( Vect2D( 0.70 * Scale.X ,  0.70 * Scale.Y));

	canvas.TextSize(Text, TextSize.X, TextSize.Y, ScaleCalc.X, ScaleCalc.Y);
	
	if (Scale_Location)
	{
		Location=Scale2dVector(Location);
	}
	Switch(OffsetX)
	{
		Case O_Center:
		Location.X=Location.X - (TextSize.X / 2);
		Break;

		Case O_Full:
		Location.X=Location.X - TextSize.X;
		break;
	}
	Switch (OffsetY)
	{
		Case O_Center:
		Location.Y = Location.Y - (TextSize.Y / 2);
		break;

		Case O_Full:
		Location.Y=Location.Y - TextSize.Y;
		break;
	}
	Canvas.SetPos(Location.X,Location.Y);
	canvas.SetDrawColor(Color.Red,Color.Green,Color.Blue,Color.Alpha);
	Canvas.DrawText(Text, false, ScaleCalc.X, ScaleCalc.Y);
	Canvas.SetOrigin(PreviousOrigin.X, PreviousOrigin.Y);
}

Function DrawLocalizedText(String ID, Vector2D Location, optional RGBA Color=DefaultTextColor, optional Vector2D Scale=Vect2D(1,1), optional bool Scale_Location=True, optional EOffset OffsetX, optional EOffset OffsetY, optional vector2D Bound_Start)
{
	ScreenTextDraw(LocalizedString(ID),Location,Color,Scale,Scale_Location,OffsetX, OffsetY, Bound_Start);
}

Function Float ScalebyCam(Float Float) //Function to scale a float by the players current FOV. 
{
	Local Float Scale;
	Scale = ( PlayerOwner.GetFOVAngle() / 100 );

	Return Float * Scale;
}

Function RGBA MakeRGBA(byte R, byte G, byte B, optional byte A=255)
{
	local RGBA RGBShit;

	RGBShit.Red=R;
	RGBShit.Green=G;
	RGBShit.Blue=B;
	RGBShit.Alpha=A;

	Return RGBShit;
}
Function Bool ContainsName(Array<Name> Array, Name find) //Check if Array contains Name Variable. 
{
	Switch(Array.Find(find) )
	{
		case -1: Return False;

		Default: Return true;
	}
}

Function Bool ContainsString(Array<String> Array, String find)
{
	Switch(Array.Find(find))
	{
		case -1:
			Return False;
		break;

		Default:
			Return true;
		Break;
	}
}

function click()
{
	local SHPlayerInput PlayerInput;
	local ButtonStruct buttonvar;
	local IntPoint MousePosition;

	PlayerInput = SHPlayerInput(PlayerOwner.PlayerInput);

	MousePosition = PlayerInput.MousePosition;

	if (SHPlayerInput(Playerowner.PlayerInput).UsingGamepad()) {return;}

	foreach Buttons(buttonvar)
	{
		if ( MouseInbetween(buttonvar.AbsoluteLocation, buttonvar.AbsoluteLocation + buttonvar.ScaledOffset ) )
		{
			if (ButtonVar.Template)
			{
				Command=buttonvar.ConsoleCommand;
				return;
			}
			PlayerOwner.ConsoleCommand(buttonvar.ConsoleCommand);
			return;
		}
	}
	return;
}

Function Commit()
{
	PlayerOwner.ConsoleCommand(Command);
	Command="";
}

Function AddButton(String Name, String ConsoleCommand, optional vector2D Location, optional bool AutoDown=False, optional bool Extend=False, optional vector2D Bound_Start, optional vector2D Bound_End, optional bool template)
{
	local vector2D Begin_PointCalc, End_PointCalc, Offset, Center_Vector, TextSize, AbsoluteLocation, PreviousOrigin;
	local RGBA Color, TextColor;
	local ButtonStruct ButtonBase, PreviousButton, FirstButtonInRow, ButtonInColumn;
	local int Row, Column;

	PreviousOrigin = vect2d(Canvas.OrgX, Canvas.OrgY); // Set previous origin for later

	Canvas.SetOrigin(Bound_Start.X, Bound_Start.Y);

	//Default Color Values
	Color=ButtonColor;
	TextColor=ButtonHoveredColor;

	Canvas.TextSize(Name, TextSize.X, TextSize.Y);
	offset=vect2D( 15 + (TextSize.X / 1.5), 5 + (TextSize.Y / 1.5) );

	if (Buttons.Length==0) //Set Defaults
	{
	   Row=1;
	   Column=1;
	   Location.X = Location.X;
	   Location.Y = Location.Y;
	}
	else
	{
		PreviousButton=Buttons[ (Buttons.Length - 1 ) ]; //Fuck you unreal 3 and you not having a proper array length. it counts from 0, NOT FUCKING 1. Bitch
		Row=PreviousButton.Row;
		Column=PreviousButton.Column+1;
		FirstButtonInRow=FindButton(Buttons, Row, 1);
		if (FirstButtonInRow.Row!=-1)
		{
			Bound_Start = FirstButtonInRow.ClipStart;
			Bound_End = FirstButtonInRow.ClipEnd;
			if (AutoDown)
			{
				Location.X = PreviousButton.Location.X;
				Location.Y = (PreviousButton.Location.Y + PreviousButton.Offset.Y) + 10;
				if( !InRange( Scale2dVector(Location).Y + Bound_Start.Y + Offset.Y, Bound_Start.Y, Bound_Start.Y + Bound_End.Y) )
				{
					Location.X = (FirstButtonInRow.Location.X + FirstButtonInRow.Offset.X) + 10;
					Location.Y = FirstButtonInRow.Location.Y;
					++ Row;
					Column=1;
				}
				else if (Column>1)
				{
					ButtonInColumn=FindButton(Buttons, (Row - 1), Column);
					if (ButtonInColumn.Row!=-1)
					{
						Location.X = (ButtonInColumn.Location.X + ButtonInColumn.Offset.X) + 10;
					}
				}
			}
		}
	}

	AbsoluteLocation = Scale2dvector(Location) + Bound_Start;

	If ( ( MouseInbetween(AbsoluteLocation, AbsoluteLocation + Scale2DVector(Offset ) ) && !SHPlayerInput(PlayerOwner.PlayerInput).UsingGamepad() ) || SelectedButton.Row==Row && SelectedButton.Column==Column && (PlayerOwner.PlayerInput.bUsingGamepad || GetSHDebugOption('SimulateController'))) //Use your eyes :Kappap:
	{
		Color=ButtonHoveredColor;
		TextColor=ButtonColor;
	}

	//Draw the button box
	DrawScaledBox(Location, offset, Color, Begin_PointCalc, End_PointCalc, Bound_Start);

	Begin_PointCalc = Begin_PointCalc - Bound_Start;
	End_PointCalc = End_PointCalc - Bound_Start;

	//Get the center of the button
	Center_Vector=vect2D( ( Begin_PointCalc.X + (Begin_PointCalc.X + End_PointCalc.X) ) / 2, ( Begin_PointCalc.Y + ( Begin_PointCalc.Y + End_PointCalc.Y ) ) / 2);

	//Draw Button Text Centered.
	ScreenTextDraw(Name, Center_Vector,  TextColor,, false, O_Center, O_Center, Bound_Start);

	Begin_PointCalc = Begin_PointCalc + Bound_Start; //Add the bound offset to get absolute value
	End_PointCalc = End_PointCalc + Bound_Start;

	//Add the button info to the array
	ButtonBase.Name=Name;
	ButtonBase.ConsoleCommand=ConsoleCommand;
	ButtonBase.Start_Points=Begin_PointCalc;
	ButtonBase.End_Point=vect2d( (Begin_PointCalc.X + End_PointCalc.X), (Begin_PointCalc.Y + End_PointCalc.Y ) ); //Do math and add the calcs together to get the absolute end point.
	ButtonBase.Template=template; //Does button require user input after pressing
	ButtonBase.Location=Location;
	ButtonBase.Offset=Offset;
	ButtonBase.ClipStart=Bound_Start;
	ButtonBase.ClipEnd=Bound_End;
	ButtonBase.Row=Row;
	ButtonBase.Column=Column;
	ButtonBase.AbsoluteLocation=AbsoluteLocation;
	ButtonBase.ScaledOffset=Scale2dVector(Offset);

	Buttons.AddItem(ButtonBase);

	Canvas.SetOrigin(PreviousOrigin.X, PreviousOrigin.Y); //Set the origin back to the previous offset
}

Function AddLocalizedButton(String ID, String ConsoleCommand, optional vector2D Location, optional bool AutoDown=False, optional bool Extend=False, optional vector2D Bound_Start, optional vector2D Bound_End, optional bool template)
{
	AddButton(LocalizedString(ID, "Buttons"), ConsoleCommand, Location, AutoDown, Extend, Bound_Start, Bound_End, template);
}

function bool InRange(float Target, Float RangeMin, Float RangeMax)
{
	Return Target>RangeMin && Target<RangeMax;
}

Exec Function SetMenu(Menu Menu)
{
	local Saved_Menu Saved_Menu;
	if (PreviousMenus.length - 1<0)
	{
		Saved_Menu.Menu=CurrentMenu;
		Saved_Menu.SavedSelection=SelectedButton;
		PreviousMenus.AddItem(Saved_Menu);
		SelectedButton=Default.SelectedButton;
	}
	else if (PreviousMenus[PreviousMenus.length - 1].Menu == Menu)
	{
		Saved_Menu=PreviousMenus[PreviousMenus.find('Menu', Menu)];
		SelectedButton=Saved_Menu.SavedSelection;
		PreviousMenus.RemoveItem(Saved_Menu);
	}
	else
	{
		Saved_Menu.Menu=CurrentMenu;
		Saved_Menu.SavedSelection=SelectedButton;
		PreviousMenus.AddItem(Saved_Menu);
		SelectedButton=Default.SelectedButton;
	}
	CurrentMenu=Menu;
}

Function IntPoint GetMousePosition()
{
	local SHPlayerInput PlayerInput;

	PlayerInput = SHPlayerInput(PlayerOwner.PlayerInput);

	return PlayerInput.MousePosition;
}

Function Bool Mouseinbetween(Vector2D Vector1, Vector2D Vector2)
{
	local intpoint MousePosition;

	MousePosition=GetMousePosition();
	
	Return InRange(MousePosition.X, Vector1.X, Vector2.X) && InRange(MousePosition.Y, Vector1.Y, Vector2.Y );
}

Function DrawScaledBox(Vector2D Begin_Point, Vector2D End_Point, optional RGBA Color=MakeRGBA(255,255,255,255), optional out Vector2D Begin_Point_Calculated, optional out Vector2D End_Point_Calculated, optional vector2D Bound_Start  )
{
	local vector2D PreviousOrigin;

	PreviousOrigin = vect2d(Canvas.OrgX, Canvas.OrgY);

	Canvas.SetOrigin(Bound_Start.X, Bound_Start.Y);

	Begin_Point_Calculated = Scale2DVector(Begin_Point);

	End_Point_Calculated = Scale2DVector(End_Point);

	Canvas.SetPos( Begin_Point_Calculated.X, Begin_Point_Calculated.Y);
	canvas.SetDrawColor(Color.Red,Color.Green,Color.Blue,Color.Alpha);
	Canvas.DrawRect( End_Point_Calculated.X, End_Point_Calculated.Y);

	Begin_Point_Calculated = Scale2DVector(Begin_Point) + Bound_Start;

	End_Point_Calculated = Scale2DVector(End_Point) + Bound_Start;

	Canvas.SetOrigin(PreviousOrigin.X, PreviousOrigin.Y);
}

Function Vector2D Scale2DVector(Vector2D Vector)
{
	local Float AspectRatio;

	AspectRatio = GetAspectRatio();

	if (AspectRatio>=1.7) //16:9
	{
		Vector.X=Vector.X / 1280.0f * Canvas.SizeX;
		Vector.Y=Vector.Y / 1280.0f * Canvas.SizeX;
	}
	else if (AspectRatio>=1.3) //4:3
	{
		Vector.X=Vector.X / 1024.0f * Canvas.SizeX;
		Vector.Y=Vector.Y / 1024.0f * Canvas.SizeX;
	}

	Return Vector;
}

Function Float GetCorrectSizeX()
{
	local Float AspectRatio;

	AspectRatio = GetAspectRatio();

	if (AspectRatio>=1.7) //16:9
	{
		Return 1280.0f;
	}
	else if (AspectRatio>=1.3) //4:3
	{
		Return 1024.0f;
	}

}

Function Float GetAspectRatio()
{
	local vector2D ViewportSize;

	if (Player==None)
	{
		Player = LocalPlayer(PlayerOwner.Player);
	}
	Player.ViewportClient.GetViewportSize(ViewportSize);
	Return ViewportSize.X / ViewportSize.Y;
}

Function ButtonStruct FindButton(Array<ButtonStruct> Array, Int Row, Int Column)
{
	local ButtonStruct Button;

	foreach array(Button)
	{
		if (Button.Row==Row)
		{
			if (Button.Column==Column)
			{
				Return Button;
			}
		}
	}
	Button.Row=-1;
	Return Button;
}

exec function HideMenu()
{
	PlayerOwner.ConsoleCommand("OpenConsoleMenu 0");
	super.HideMenu();
}

Function Bool Vector2DInRange(Vector2D Target, Vector2D Vector1, Vector2D Vector2)
{
	Return InRange(Target.X, Vector1.X, Vector2.X) && InRange(Target.Y, Vector1.Y, Vector2.Y );
}

Function String Vectortostring(Vector Target)
{
	local string String;

	string=Target.X $ ", " $ Target.Y $ ", " $ Target.Z;

	Return string;
}

Function String CamViewtoString(CamView View)
{
	Return View.Pitch $ ", " $ View.Yaw $ ", " $ View.Roll;
}

Function Vector2d GetAdjustedTextSize(String Text, EOffset Offset)
{
	Local Vector2D SavedPos;
	Local Vector2D Location;
	Local Vector2D TextSize;
	Local Vector2D AdjustedTextSize;
	Canvas.TextSize(Text, TextSize.X, TextSize.Y);
	Switch(Offset)
	{
		Case O_Center:
		Location=Vect2D(Location.X - (TextSize.X / 2), Location.Y - (TextSize.Y / 2) );
		Break;

		Case O_Full:
		Location=Vect2D(Location.X - TextSize.X, Location.Y - TextSize.Y);
		break;
	}
	SavedPos=Vect2d(Canvas.CurX,Canvas.CurY);
	Canvas.SetPos(Location.X,Location.Y);
	Canvas.TextSize(Text,AdjustedTextSize.X, AdjustedTextSize.Y);
	Canvas.SetPos(SavedPos.X,SavedPos.Y);
	Return Scale2dVector(AdjustedTextSize);
}


//This function pauses the game when the window loses focus.
event OnLostFocusPause(bool bEnable)
{
	bLostFocus = bEnable; //Still set bLostFocus in case a function relys on it. 
	/*Check if the caller is asking to pause the game and if 'bShouldPauseWithoutFocus' is not true, if so return the function to avoid pausing. 
	It should not return the function if the game is asking to unpause, even if somehow 'bShouldPauseWithoutFocus' is suddenly not true while it's paused.*/
	if (bEnable && !bShouldPauseWithoutFocus) {Return;}
	Super.OnLostFocusPause(bEnable); //Call parent event
}

DefaultProperties
{
	`FunctObj

	SelectedButton=(Row=1, Column=1)
	bShouldDrawMouse=true;
	PreviousMenus=Normal
}