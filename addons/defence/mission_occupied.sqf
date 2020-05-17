private ["_mission","_pole","_position","_name","_grp","_static","_abrt","_messages","_statics"];

// Get mission number, important we do this early
_mission = count wai_mission_data -1;

//select plotpole to spawn mission
_pole = call BD_selectPoleOut;
_abrt = {
	wai_mission_markers = wai_mission_markers - [("MainHero" + str(_mission))];
	wai_mission_data set [_mission, -1];
	BD_active = false;
	h_missionsrunning = h_missionsrunning - 1;
	WAI_MarkerReady = true;
	diag_log "[BD/WAI] Occupation - good pole is not found";
};
if (isNil "_pole") exitWith {call _abrt;};
if (isNull _pole) exitWith {call _abrt;};
_position = getPos _pole;
_name = _pole call BD_poleOwnerName;//name of owner
diag_log format["[BD/WAI] Occupation - defend %1 @ %2",_name,_position];
BD_allPlots = +BD_initPlots - [_pole];

// Spawn crates
[[
	[[[1,ai_wep_special_rare],[2,crate_tools_sniper],[1,crate_items_gems],[1,ai_wep_sniper+ai_wep_machine],1],crates_small,[0,0,(_position select 2) + 0.5]]
],_position,_mission] call wai_spawnCrate;

//Troops
[[(_position select 0)+25,(_position select 1)+25,0],5,"Medium",["Random","AT"],3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
[[(_position select 0)+25,(_position select 1)-25,0],5,"Medium",["Random","AA"],3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;

//get units in static weapons
_statics = _position nearEntities [BD_static, DZE_PlotPole select 1];
_grp = [_position,6 + (count _statics),"Medium","Random",3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
if (count _statics > 0) then {
	{
		_static = _x;
		{
			if (vehicle _x == _x && {!(_x in ["FakeWeapon","CarHorn","SportCarHorn"])} count (weapons _static) > 0) exitWith {
				_x moveInGunner _static;
				diag_log format["[BD/WAI] %1 gets in %2",name _x, typeOf _static];
				_static call load_ammo2;
				_static removeAllEventHandlers "HandleDamage";
			};
		} forEach (units _grp);
	} forEach _statics;
	if ({_x isKindOf "StaticMortar"} count _statics > 0) then {_grp spawn WAI_arty_fire};
};

//Spawn Vehicle
[cargo_trucks,[_position,1,150,5,1,2000,0] call BIS_fnc_findSafePos,_mission] call custom_publish;

//Open Doors
{
	_x animate ["Open_hinge", 1];
	_x animate ["Open_latch", 1];
	_x animate ["Open_door",1];
	_x animate ["DoorR", 1];
	_x animate ["DoorL", 1];
} forEach nearestObjects [_position, ["Land_DZE_WoodDoor_Base","CinderWallDoor_DZ_Base","Land_DZE_WoodDoorLocked_Base","CinderWallDoorLocked_DZ_Base","WoodenGate_Base"], DZE_PlotPole select 1];

//Message
RemoteMessage = ["dynamic_text",["Take it back!","Bandits have occupied your base!"],["0.40","#FFFFFF","0.60","#ffff66",0,-.35,10,0.5]];
(owner (_pole call BD_poleOwner)) publicVariableClient "RemoteMessage";

[
	_mission, // Mission number
	_position, // Position of mission
	"Medium", // Difficulty
	format["Occupied %1's Base",_name], // Name of Mission
	"MainHero", // Mission Type: MainHero or MainBandit
	true, // show mission marker?
	false, // make minefields available for this mission
	["crate"], // Completion type: ["crate"], ["kill"], or ["assassinate", _unitGroup],
	[
		format["Bandits have occupied %1's base! Take it back!",_name], // mission announcement
		"Survivors have recaptured the base. Reward is near plotpole.", // mission success
		"Bandits have left the base." // mission fail
	]
] call mission_winorfail;

//allow next mission
sleep ((wai_mission_timeout select 1)*60);
BD_active = false;
