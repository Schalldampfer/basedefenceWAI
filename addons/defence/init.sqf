/*
Description:
	WAI addon "Defend your base"
	An mission will spawn on a player's base.
	A reward crate will be next to the plotpole.
Requirements:
	WAI 2.2.6
	spawn_group must return _unitGroup
	
Install:
	1. Put these files in dayz_server\addons\defence\
	2. add ' execVM "\z\addons\dayz_server\addons\defence\init.sqf"; ' at the end of dayz_server\init\server_functions.sqf
Author:
	Schalldampfer
*/

/*config*/
BD_players = 1;//least number of players to run mission
BD_static = ["StaticMGWeapon","StaticGrenadeLauncher","StaticSEARCHLight"]; //weapons AIs will get in

/*run*/
if (!isServer) exitWith {diag_log "wtf";};

[] spawn { // monitor
	private ["_missionwait","_plot","_mission"];
	waitUntil{!isNil "WAI_MarkerReady"};
	waitUntil{WAI_MarkerReady};
	_missionwait = (random((wai_mission_timer select 1) - (wai_mission_timer select 0)) + (wai_mission_timer select 0)) * 60;
	wai_h_starttime = diag_tickTime - _missionwait;
	BD_active = false;
	BD_allPlots = (entities "Plastic_Pole_EP1_DZ");
	while {true} do {
		if (!BD_active) then {
			//update plotpoles
			BD_activeUIDs = []; //list of playerUIDs in server
			{
				BD_activeUIDs set [count BD_activeUIDs, getPlayerUID _x];
			} forEach playableUnits;
			BD_activePlots = []; //list of plotpoles for active players
			{
				_plot = _x;
				if ((_plot getVariable ["ownerPUID","1"]) in BD_activeUIDs || {(_x select 0) in BD_activeUIDs} count (_plot getVariable ["plotfriends", []]) > 0) then {
					BD_activePlots set [count BD_activePlots, _plot];
				};
			} forEach BD_allPlots;
			
			//run mission
			if ((count BD_activePlots > 0) && (h_missionsrunning < wai_hero_limit) && (diag_tickTime - wai_h_starttime > _missionwait)) then {
				if (WAI_MarkerReady && ({alive _x} count playableUnits >= BD_players) && (diag_fps > wai_server_fps)) then {
					WAI_MarkerReady	= false;
					h_missionsrunning = h_missionsrunning + 1;
					wai_h_starttime = diag_tickTime;
					wai_mission_markers set [(count wai_mission_markers), ("MainHero" + str(count wai_mission_data))];
					wai_mission_data = wai_mission_data + [[0,[],[],[],[],[],[]]];
					BD_active = true;
					diag_log format["[BD/WAI] ActivePlots:%1 ActiveUIDs:%2",count BD_activePlots,count BD_activeUIDs];
					_mission = ["mission_occupied","mission_attacked"] call BIS_fnc_selectRandom;
					if ({[getPos _x,1200] call isNearPlayer} count BD_activePlots < 1) then {
						_mission = "mission_occupied";
					};
					execVM format ["\z\addons\dayz_server\addons\defence\%1.sqf",_mission];
				};
			};
			
		};
		
		if (random 1 > 0.8) then {diag_log format["[BD/WAI] status WAI_MarkerReady:%1 DTime:%2 MissionSlot:%3 BD_active:%4",WAI_MarkerReady,diag_tickTime - wai_h_starttime,wai_hero_limit - h_missionsrunning,BD_active];};
		
		//wait
		sleep 60;
	};
};

load_ammo2 = compile preprocessFileLineNumbers "\z\addons\dayz_server\addons\defence\load_ammo.sqf";

//Plotpole that no player is close to
BD_selectPoleOut = {
	private ["_pole"];
	_pole = objNull;
	if (count BD_activePlots > 0) then {
		_pole = BD_activePlots call BIS_fnc_selectRandom;
		while {({(_pole distance _x) < 1200} count playableUnits) > 0 || _pole call wai_isNearMission} do {_pole = BD_activePlots call BIS_fnc_selectRandom;};
	};
	_pole
};

//Plotpole that any player is close to
BD_selectPoleIn = {
	private ["_pole"];
	_pole = objNull;
	if (count BD_activePlots > 0) then {
		_pole = BD_activePlots call BIS_fnc_selectRandom;
		while {({(_pole distance _x) < 200} count playableUnits) < 1 || _pole call wai_isNearMission} do {_pole = BD_activePlots call BIS_fnc_selectRandom;};
	};
	_pole
};

BD_poleOwner = {
	private ["_pole","_uid","_player"];
	_pole = _this;
	_player = objNull;
	_uid = _pole getVariable ["ownerPUID","0"];
	{
		if ((alive _x) && (getPlayerUID _x == _uid)) then {
			_player = _x;
		};
	} forEach playableUnits;
	_player
};

BD_poleOwnerName = {
	private ["_player","_name"];
	_player = _this call BD_poleOwner;
	if (isNull _player) then {
		_name = "someone";
	} else {
		_name = name _player;
	};
	_name
};

wai_isNearMission = {
	private ["_validspot","_position"];
	_position = _this;
	_validspot = false;
	
	{
		if (getMarkerColor _x != "" && (_position distance (getMarkerPos _x) < wai_avoid_missions)) exitWith {
			_validspot = true;
		};
	} count wai_mission_markers;
	_validspot;
};
