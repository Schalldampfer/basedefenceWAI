private ["_mission","_pole","_position","_name","_grp","_static","_abrt"];

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
	[[[3,ai_wep_machine],[3,crate_tools_sniper],10,[3,ai_wep_sniper],2],crates_small,[0,0,_position select 2]]
],_position,_mission] call wai_spawnCrate;

//Troops
       [[(_position select 0)+10,(_position select 1)+10,0],4,"Medium",[0,"AT"],3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
       [[(_position select 0)+10,(_position select 1)-10,0],4,"Medium",[0,"AA"],3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
       [[(_position select 0)-10,(_position select 1)+10,0],7,"Medium","Random",4,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
_grp = [[(_position select 0)-10,(_position select 1)-10,0],7,"Medium",       0,3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;

//get units in static weapons
{
	_static = _x;
	{
		if (vehicle _x == _x) exitWith {
			_x moveInGunner _static;
			diag_log format["[BD/WAI] %1 gets in %2",name _x, typeOf _static];
			[_static,typeOf _static] call load_ammo2;
		};
	} forEach (units _grp);
} forEach (_position nearEntities [BD_static, DZE_PlotPole select 0]);

[
	_mission, // Mission number
	_position, // Position of mission
	"Medium", // Difficulty
	"Occupied Player Base", // Name of Mission
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
