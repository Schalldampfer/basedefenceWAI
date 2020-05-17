private["_vehicle","_type","_inGear","_turretCount","_ammo"];

_vehicle = _this;
_type = typeOf _vehicle;

//Refill _DZE vehicle's turret
_turretCount = count (configFile >> "CfgVehicles" >> _type >> "turrets");
for "_i" from 0 to (_turretCount) do {
	{
		_ammoArray = getArray (configFile >> "cfgWeapons" >> _x >> "magazines");
		if (count _ammoArray > 0) then {
			_ammo = _ammoArray select 0;
			if !(_ammo in (_vehicle magazinesTurret [_i])) then {
				_vehicle addMagazineTurret [_ammo,[_i]];
				//diag_log format["[WAI] Load %1 %2(%4) with %3",_type,_x,_ammo,_i];
			};
		};
		//diag_log format["[WAI] Load %1 %2 %3/%4",_x,_ammoArray,_i,_turretCount];
	} forEach (_vehicle weaponsTurret [_i]);
	//diag_log format["[WAI] has %1 %2/%3",(_vehicle weaponsTurret [_i]),_i,_turretCount];
};

