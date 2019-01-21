private ["_mission","_pole","_position","_name","_grp","_grps","_startPos","_search","_wp","_units"];

// Get mission number, important we do this early
_mission = count wai_mission_data -1;

//select plotpole to spawn mission
_pole = call BD_selectPoleIN;
if ((isNil "_pole")||(isNull _pole)) exitWith {
	wai_mission_markers = wai_mission_markers - [("MainHero" + str(_mission))];
	wai_mission_data set [_mission, -1];
	BD_active = false;
	h_missionsrunning = h_missionsrunning - 1;
	diag_log "[BD/WAI] Attack - good pole is not found";
};
_position = getPos _pole;
_name = _pole call BD_poleOwnerName;//name of owner
diag_log format["[BD/WAI] Attack - defend %1 @ %2",_name,_position];
BD_allPlots = BD_allPlots - [_pole];

// Spawn crates
[[
	[[3,[4,crate_tools_sniper],[3,crate_items_gems],[3,ai_wep_machine],0],crates_small,[0,0,_position select 2]]
],_position,_mission] call wai_spawnCrate;

//spawn position
_search = [_position,1000,1750,10,0,2000,0];
_startPos = _search call BIS_fnc_findSafePos;
_startPos set [2,0];
while {[_startPos,1200] call isNearPlayer} do {_startPos = _search call BIS_fnc_findSafePos;};

//Attackers
_grps = [];

//Troops
_grp = [_startPos,6,"Medium",[0,"AT"],4,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
_grps = _grps + [_grp];
_grp = [_startPos,6,"Medium",[0,"AT"],4,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
_grps = _grps + [_grp];
_grp = [_startPos,4,"Medium",       2,6,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
_grps = _grps + [_grp];
_grp = [_startPos,4,"Medium",       1,4,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
_grps = _grps + [_grp];

//Vehicle
_grp = [_position,_startPos,50,4,armed_vehicle call BIS_fnc_selectRandom,"Extreme","Bandit","Bandit",_mission] call vehicle_patrol;
_grps = _grps + [_grp];
_grp = [_position,_startPos,50,4,armed_vehicle call BIS_fnc_selectRandom,"Extreme","Bandit","Bandit",_mission] call vehicle_patrol;

//join
{(units _x) joinSilent _grp;} forEach _grps;
_grp selectLeader ((units _grp) select 0);
_grp allowFleeing 0;
(units _grp) allowGetIn true;
diag_log format["[BD/WAI] Attack %1 units",count (units _grp)];

//move
for "_x" from 1 to 4 do
{
	_wp = _grp addWaypoint [[(_position select 0),(_position select 1),0],DZE_PlotPole select 1];
	_wp setWaypointType "SAD";
	_wp setWaypointCompletionRadius 200;
};
_wp = _grp addWaypoint [[(_position select 0),(_position select 1),0],100];
_wp setWaypointType "CYCLE";
_wp setWaypointCompletionRadius 200;


[
	_mission, // Mission number
	_position, // Position of mission
	"Medium", // Difficulty
	"Attacked Base", // Name of Mission
	"MainHero", // Mission Type: MainHero or MainBandit
	true, // show mission marker?
	false, // make minefields available for this mission
	["kill"], // Completion type: ["crate"], ["kill"], or ["assassinate", _unitGroup],
	[
		format["Bandits are going to attacking %1's base!",_name], // mission announcement
		"Survivors have defended the base. Reward is near plotpole.", // mission success
		"Bandits have left the base." // mission fail
	]
] call mission_winorfail;

/*
//units try to get in static weapons
sleep 300;
_units = units _grp;
{
	_static = _x;
	{
		if ((alive _x) && (vehicle _x == _x)) exitWith {
			_x assignAsGunner _static;
			[_x] orderGetIn true;
			diag_log format["[BD/WAI] %1 tries to gets in %2",name _x, typeOf _static];
			_static addEventHandler ["GetIn",{
				private ["_veh"];
				_veh = _this select 0;
				if (!isPlayer (_this select 2)) exitWith {
					[_veh,typeOf _veh] call load_ammo2;
				};
			}];
			_units = _units - [_x];
		};
	} forEach _units;
} forEach (_position nearEntities [BD_static, DZE_PlotPole select 0]);
*/

//allow next mission
sleep ((wai_mission_timeout select 1)*60);
BD_active = false;
