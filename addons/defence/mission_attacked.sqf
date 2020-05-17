private ["_mission","_pole","_position","_name","_grp","_grps","_startPos","_search","_wp","_units","_abrt","_veh1","_veh2","_load"];

// Get mission number, important we do this early
_mission = count wai_mission_data -1;

//select plotpole to spawn mission
_pole = call BD_selectPoleIN;
_abrt = {
	wai_mission_markers = wai_mission_markers - [("MainHero" + str(_mission))];
	wai_mission_data set [_mission, -1];
	BD_active = false;
	h_missionsrunning = h_missionsrunning - 1;
	WAI_MarkerReady = true;
	diag_log "[BD/WAI] Attack - good pole is not found";
};
if (isNil "_pole") exitWith {call _abrt;};
if (isNull _pole) exitWith {call _abrt;};
_position = getPos _pole;
_name = _pole call BD_poleOwnerName;//name of owner
diag_log format["[BD/WAI] Attack - defend %1 @ %2",_name,_position];
BD_allPlots = BD_allPlots - [_pole];

// Spawn crates
[[
	[[[2,ai_wep_special_good + ai_wep_special_rare],0,[1,crate_items_gems],[2,ai_wep_sniper+ai_wep_machine],0],crates_small,[0,0,(_position select 2) + 0.5]]
],_position,_mission] call wai_spawnCrate;

//spawn position
_search = [_position,950,1200,3,0,2000,0];
_startPos = _search call BIS_fnc_findSafePos;
_startPos set [2,0];
while {[_startPos,1000] call isNearPlayer} do {_startPos = _search call BIS_fnc_findSafePos;};

//Attackers
_grps = [];

//Vehicle
_grp = [_position,_startPos,100,4,armed_vehicle call BIS_fnc_selectRandom,"Extreme","Bandit","Bandit",_mission] call vehicle_patrol;
_veh1 = vehicle leader _grp;
_grps = _grps + [_grp];
_grp = [_position,_startPos,100,4,cargo_trucks call BIS_fnc_selectRandom,"Extreme","Bandit","Bandit",_mission] call vehicle_patrol;
_veh2 = vehicle leader _grp;
_grps = _grps + [_grp];

_load = {
	private ["_i","_veh","_grp","_cnt"];
	_veh = _this select 0;
	_grp = _this select 1;
	_cnt = _veh emptyPositions "cargo";
	_i = 0;
	{
		if (vehicle _x == _x) then {
			_x assignAsCargo _veh;
			_x moveInCargo [_veh,_i];
			_i = _i + 1;
		};
		if (_i >= _cnt) exitWith {};
	} forEach (units _grp);
	_veh removeAllEventHandlers "GetOut";
};

//Troops
_grp = [_startPos,_veh1 emptyPositions "cargo","Hard",[0,"AT"],3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
[_veh1,_grp] call _load;
_grps = _grps + [_grp];
_grp = [_startPos,_veh2 emptyPositions "cargo","Hard","Random",3,"Random","Bandit","Random","Bandit",_mission] call spawn_group;
[_veh2,_grp] call _load;
_grps = _grps + [_grp];

{
	//move
	for "_i" from 1 to 4 do
	{
		_wp = _x addWaypoint [[(_position select 0),(_position select 1),0],DZE_PlotPole select 1];
		_wp setWaypointType "SAD";
		_wp setWaypointSpeed "FULL";
		_wp setWaypointCompletionRadius 200;
	};
	_wp = _x addWaypoint [[(_position select 0),(_position select 1),0],100];
	_wp setWaypointType "CYCLE";
	_wp setWaypointCompletionRadius 200;
} forEach _grps;

//join
_grp = _grps select 0;
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
	_wp setWaypointSpeed "FULL";
	_wp setWaypointCompletionRadius 200;
};
_wp = _grp addWaypoint [[(_position select 0),(_position select 1),0],100];
_wp setWaypointType "CYCLE";
_wp setWaypointCompletionRadius 200;


[
	_mission, // Mission number
	_position, // Position of mission
	"Medium", // Difficulty
	"Defend Player Base", // Name of Mission
	"MainHero", // Mission Type: MainHero or MainBandit
	true, // show mission marker?
	false, // make minefields available for this mission
	["crate"], // Completion type: ["crate"], ["kill"], or ["assassinate", _unitGroup],
	[
		format["Bandits are going to attack %1's base!",_name], // mission announcement
		"Survivors have defended the base. Reward is near plotpole.", // mission success
		"Bandits have left the base." // mission fail
	]
] call mission_winorfail;

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
					_veh call load_ammo2;
					_veh removeAllEventHandlers "HandleDamage";
					_veh setVariable ["CharacterID","0",true];
				};
			}];
			_units = _units - [_x];
		};
	} forEach _units;
} forEach (_position nearEntities [BD_static, DZE_PlotPole select 1]);
{_x doMove _position;} forEach _units;

//allow next mission
sleep ((wai_mission_timeout select 1)*60);
BD_active = false;
