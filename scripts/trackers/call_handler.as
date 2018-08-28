// internal
#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "query_helpers.as"
// --------------------------------------------


// --------------------------------------------
class CallHandler : Tracker {
	protected Metagame@ m_metagame;
	//protected dictionary m_trackedMaps;
	//protected Vector3 m_position;
	//protected string m_managerName;
	//protected int m_factionId;

	protected float hpTimer = 15.0; // hot potato detonates after 15 seconds
	protected int hpHolder; // id of character holding the hot potato
	protected float empTimer = 10.0; // emp lasts for 10 seconds
	protected array<int> empVeh; // array of vehicle ids affected by emp
	protected array<string> activeTimers; // stores the names of active timers
	/*
	protected array<Timers@> m_timers; // to support multiple concurrent calls' countdown timers
	// requires Timers class - see prison_break_objective.as for an example
	*/

	// ----------------------------------------------------
	CallHandler(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	protected void handleCallRequestEvent(const XmlElement@ event) {
	/* REMEMBER: Only calls that have notify_metagame="1" declared are sent here
	Calls that don't require script-side support will use '<command>' blocks in the call itself. */

	// variablise call attributes
		string sChar = event.getStringAttribute("character_id");
		int iChar = event.getIntAttribute("character_id");
		string sCall = event.getStringAttribute("call_key");
		string sPosi = event.getStringAttribute("target_position");
		Vector3 v3Posi = stringToVector3(event.getStringAttribute("target_position"));
		const XmlElement@ char = getCharacterInfo(m_metagame, iChar);
		//return getGenericObjectInfo(metagame, "character", characterId);

		_log("call made: " + sCall, 1);
		//_log("call source position: " + getPlayerPosition, 1)
		_log("call target position: " + sPosi, 1);
		//_log("distance from source to target: " + getPositionDistance(const Vector3@ pos1, posi), 1);
		//_log("call effect area: " + area, 1);

	////////////////////////
	//   Common   Calls   //
	////////////////////////
		// Notify metagame call is a placeholder call to test calls that have 'notify_metagame="1"' set
		if (sCall == "notify_metagame.call") {
			sendFactionMessageKey(m_metagame, 0, "notify call", dictionary = {}, 1.0);
		}
		else if (sCall == "bnn_mission.call") {
			sendFactionMessageKey(m_metagame, 0, "BNN mission", dictionary = {}, 1.0);
		}
		else if (sCall == "bnn_advert.call") {
			sendFactionMessageKey(m_metagame, 0, "BNN advert", dictionary = {}, 1.0);
		}
	////////////////////////
	//  BlastCorp  Calls  //
	////////////////////////
		// The BC Hot Potato drops a very heavy, timed explosive in the backpack of a nearby enemy. If not detected 
		// in time, the recipient (and those in the blast radius) is blown apart rather vigorously
		else if (sCall == "bc_hot_potato_1.call") {
			_log("BC hot potato reqested at: " + sPosi, 1);
			array<const XmlElement@> targetChars = getCharactersNearPosition(m_metagame, v3Posi, 0, 10.00f);
			_log(targetChars.size() + " potential characters to receive hot potato", 1);
			if (targetChars.size() > 0) {
				uint i = rand(0, targetChars.size() - 1);
				const XmlElement@ mrPotato = targetChars[i];
				hpHolder = mrPotato.getIntAttribute("id");
				_log("character id: " + hpHolder + " chosen to receive hot potato.", 1);
				string potatoComm = "<command class='update_inventory' character_id='" + hpHolder + "' container_type_class='backpack'>" + "<item class='grenade' key='hot_potato.projectile' />" + "</command>";
				m_metagame.getComms().send(potatoComm);
				//aka: addItemInBackpack(m_metagame, id, const Resource@ r);
				activeTimers.push_back("hot potato");
			}
			_log("finished placing the BC Hot Potato", 1);
		}
		//dictionary call_dict = {{"TagName", "command"},{"class", "chat"},{"text", "call request event handler called!"}};
		//m_metagame.getComms().send(XmlElement(call_dict));
		//AnnounceTask(Metagame@ metagame, float time, int factionId, string key, dictionary@ a = dictionary(), float priority = 1.0)
		//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "call made", bc_call_dict));
		/*
		dictionary bc_call_dict = {
			{"%map_name", stage.m_mapInfo.m_name}, 
			{"%base_name", baseName}, 
			{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
		};
		*/
	////////////////////////
	//  LifeCraft  Calls  //
	////////////////////////
		// The Conversion call has a chance to convert enemy troops (AI only) in the area to fight for LifeCraft
		else if (sCall == "lc_conversion_1.call") {
			_log("LC troops attempting to convert nearby enemies", 1);
			sendFactionMessageKey(m_metagame, 0, "lc_conversion", dictionary = {}, 1.0);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 1, 50.00f);
			_log(hitChars.size() + " characters available to convert", 1);
			for (uint i = 0; i < hitChars.size(); ++i) {
				const XmlElement@ info = hitChars[i];
				int id = info.getIntAttribute("id");
				if (rand(0, 99) < 60) {
					const XmlElement@ qResult = getGenericObjectInfo(m_metagame, "character", id);
					string charPosi = qResult.getStringAttribute("position");
					//string charClass = info.getStringAttribute("soldier_group_name");
					_log("Character " + id + " at position " + charPosi + " failed save roll (<60). Applying effect", 1);
					killCharacter(m_metagame, id);
					// or, we can make it a multiplayer job only. Kills enemy player and changes their faction to LC
					//string convertCommand = "<command class='update_player' id='" + id + "' faction_id='0' >/></command>";
					//m_metagame.getComms().send(convertCommand);
					string spawnCommand = "<command class='create_instance' instance_class='character' faction_id='0' position='" + charPosi + "' instance_key='civilian' /></command>";
					m_metagame.getComms().send(spawnCommand);
				} else {
					_log("Character " + id + " passed save roll (>=60). Not converted", 1 ); 
				}
			}
			_log("finished conversion attempt", 1);
		} 
		// The LC Forcefield places a red translucent dome over the area for a period. Characters can move 
		// through the field, but projectiles that hit the dome ricochet or explode 
		else if (sCall == "lc_force_field_1.call") {
			_log("establishing lc forcefield at: " + sPosi, 1);	
		} 
		// The Repair Bomb operates similarly to the LC Heal bomb, repairing damage to all vehicles in the area of effect
		// Currently works far too well; it doesn't stop 'repairing' a vehicle that is 100% health... Script a solution
		else if (sCall == "lc_repair_bomb_1.call") {
			_log("launching repair bombs near: " + sPosi, 1);
			array<const XmlElement@> repVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 0);
			for (uint i = 0; i < repVehicles.size(); ++i) {
				const XmlElement@ info = repVehicles[i];
				int id = info.getIntAttribute("id");
				_log("vehicle id: " + id, 1);
				const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
				int vType = vehInfo.getIntAttribute("type_id");
				Vector3 v3VehPosi = stringToVector3(vehInfo.getStringAttribute("position"));
				string sName = vehInfo.getStringAttribute("name");
				string sType = vehInfo.getStringAttribute("type_id");
				string sKey = vehInfo.getStringAttribute("key");
				if (checkRange(v3Posi, v3VehPosi, 25.00f) ) {
					if ( vType == 51 || vType == 64 || vType == 65 || startsWith(sKey, "deco_") || startsWith(sKey, "dumpster") || startsWith(sKey, "special_c") ) {
						_log("vehicle type " + sType + " (" + sKey + ") not affected by Repair Bomb.", 1);
						repVehicles.erase(i);
						i--;
					} else {
						if (rand(0, 99) <= 90) {
						_log(sName + " being repaired by Repair Bomb", 1); 
						string command = "<command class='update_vehicle' id='" + id + "' health='0.0'></command>";
						m_metagame.getComms().send(command);
						} else {
							_log(sName + " passed save roll (>90). Not affected by EMP", 1 ); 
						}
					}
				}
			}
			_log("vehicles to be repaired include: ", 1);
			//health=2 holder_id=0 id=0 key=jeep_2.vehicle name=Urbal UAS owner_id=0 position=323.597 12.4804 310.537 right=0.379267 0 -0.925287 type_id=93
		}
	////////////////////////
	//  ReflexArq  Calls  //
	////////////////////////
		// The nanobot cloud blinds and confuses enemy troops (AI only) in the area for a duration
		else if (sCall == "ra_nanobot_cloud_1.call") {
			_log("nanobot cloud operating", 1);
			sendFactionMessageKey(m_metagame, 0, "ra_nanobot_cloud", dictionary = {}, 1.0);
			const XmlElement@ fInfo = getFactionInfo(m_metagame, 1);
			//_log("fInfo contains: " + fInfo, 1);
			_log("now running getCharactersNearPosition", 1);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 1, 25.00f);
			_log(hitChars.size() + " characters affected by Nanobot Cloud", 1);
			for (uint i = 0; i < hitChars.size(); ++i) {
				const XmlElement@ info = hitChars[i];
				int id = info.getIntAttribute("id");
				_log("character id:" + id, 1);
				const XmlElement@ charInfo = getCharacterInfo(m_metagame, id);
				string qComm = "<command class='make_query' id='nanobot_query'><data class='character' id='" + id + "' /></command>";
				m_metagame.getComms().send(qComm);
				string command = "<command class='soldier_ai' id='" + id + "'><parameter class='accuracy_offset' value='-1.0' /><parameter class='leader_sight_range' value='5.0'/><parameter class='team_member_sight_range' value='5.0'/></command>";
				m_metagame.getComms().send(command);
			}
			_log("finished establishing RA Nanobot Cloud", 1);
		} 
		// The sprint call temporarily boosts the speed and willingness to charge attributes of friendly units near the caller 
		else if (sCall == "ra_sprint_1.call") {
			_log("ra sprint operating", 1);
			sendFactionMessageKey(m_metagame, 0, "ra_sprint", dictionary = {}, 1.0);
			string markComm = "<command class='set_marker' faction_id='0' id='4041' enabled='1' atlas_index='0' text='RANDOM TEXT YEEOW' position='" + sPosi + "' color='#ff0000' range='10.0'></command>";
			m_metagame.getComms().send(markComm);			
			_log("now running getCharactersNearPosition", 1);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 0, 25.00f);
			_log(hitChars.size() + " characters boosed by Sprint", 1);
			for (uint i = 0; i < hitChars.size(); ++i) {
				const XmlElement@ info = hitChars[i];
				int id = info.getIntAttribute("id");
				_log("character id:" + id, 1);
				const XmlElement@ charInfo = getCharacterInfo(m_metagame, id);
				string sprintcomm = "<command class='soldier_ai' id='" + id + "'><parameter class='willingness_to_charge' value='1.0' /></command>";
				m_metagame.getComms().send(sprintcomm);
			}
			_log("finished running RA Sprint", 1);
		} 
		// The teleport call relocates the caller to the desired location. * Warning: May not transfer all equipment in the process *
		else if (sCall == "ra_teleport_1.call") {
			_log("ra teleport requested", 1);
			_log("relocating character " + sChar + " to " + sPosi, 1);
			string command = "<command class='update_character' id='" + sChar + "' position='" + sPosi + "' faction='0'></command>";
			m_metagame.getComms().send(command);
			_log("finished teleporting character_id " + sChar + " to " + sPosi, 1);
			//const XmlElement@ teleChar = getCharacterInfo(m_metagame, iChar);
			string qComm = "<command class='make_query'><data class='character' id='" + iChar + "' /></command>";
			m_metagame.getComms().send(qComm);
		}
	////////////////////////
	// ScopeSystems Calls //
	////////////////////////
		// The armour-piercing rounds call was intended to grant armour-piercing qualities (kill_probability="[123].01")
		// to projectiles fired by SS sniper rifles for a period. This does not appear to be possible, so the call drops 
		// a crate containing a SS-specific sniper rifle (that fires AP rounds) at the location requested by the caller

		// The explosive rounds call was intended to grant explosive qualities to projectiles fired by SS shotguns and sniper 
		// rifles for a period. This does not appear to be possible, so the call drops a crate containing a SS-specific shotgun
		// (that fires explosive rounds) at the location requested by the caller.
		
		// The Probe call launches a stealth device that alerts the caller's faction when an enemy unit passes near it.
		// The probe emits a regular but infrequent visual 'blip' that enemies may notice and destroy the device.
		else if (sCall == "ss_probe_1.call") {
			_log("SS probe not implemented, yet", 1);
		}
		// The x-ray call advises the contents of crates as well as armoured and hidden devices in the game. It allows SS troops to make 
		// a judgement call as to whether or not they should attempt to reach the location in the first place.
		else if (sCall == "ss_x-ray_1.call") {
			array<const XmlElement@> xrayItem = getVehiclesNearPosition(m_metagame, v3Posi, 1);
			for (uint i = 0; i < xrayItem.size(); ++i) {
				const XmlElement@ info = xrayItem[i];
				int id = info.getIntAttribute("id");
				const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
				string sKey = vehInfo.getStringAttribute("key");
				// if some sort of crate
				if (startsWith(sKey, 'special_cr') || endsWith(sKey, '_crate.vehicle')) {
					// confirm it's near the call target position
					Vector3 v3VehPosi = stringToVector3(vehInfo.getStringAttribute("position"));
					if (checkRange(v3Posi, v3VehPosi, 10.00f) ) {
					// get detailed info
					string sName = vehInfo.getStringAttribute("name");
					string sType = vehInfo.getStringAttribute("type_id");
					// advise (likely) contents of 'vehicle'
					_log("x-ray of " + sKey + " in progress...", 1);

					} else {
						_log("Vehicle " + sKey + " is outside the range of this call", 1);
					}
				} else {
					_log("x-ray call doesn't work on " + sKey + " vehicles", 1);
					xrayItem.erase(i);
					i--;
				}
			}
		}
	////////////////////////
	//   WyreTek  Calls   //
	////////////////////////
		// The EMP is verly likely to stop movement of all enemy vehicles caught in the blast area. 
		else if (sCall == "wt_emp_1.call") {
			_log("WT activated EMP at: " + event.getStringAttribute("target_position"), 1);
			array<const XmlElement@> hitVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 1);
			for (uint i = 0; i < hitVehicles.size(); ++i) {
				const XmlElement@ info = hitVehicles[i];
				int id = info.getIntAttribute("id");
				_log("vehicle id: " + id, 1);
				const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
				int vType = vehInfo.getIntAttribute("type_id");
				Vector3 v3VehPosi = stringToVector3(vehInfo.getStringAttribute("position"));
				string sName = vehInfo.getStringAttribute("name");
				string sType = vehInfo.getStringAttribute("type_id");
				string sKey = vehInfo.getStringAttribute("key");
				if ( vType == 51 || vType == 64 || vType == 65 || startsWith(sKey, "deco_") || startsWith(sKey, "dumpster") || startsWith(sKey, "special_c") ) {
					_log("vehicle type " + sType + " (" + sKey + ") not affected by EMP.", 1);
					hitVehicles.erase(i);
					i--;
					continue;
				}
				if (checkRange(v3Posi, v3VehPosi, 25.00f) ) {
					if (rand(0, 99) <= 90) {
						_log(sName + " is within 25.00f of EMP blast and failed save roll (<90). Applying effect", 1); 
						string command = "<command class='update_vehicle' id='" + id + "' forward='0 0 0' locked='1'></command>";
						m_metagame.getComms().send(command);
						empVeh.push_back(id); // add the vehicle to empVeh array, ready to unlock when EMP effect has faded 
					} else { _log(sName + " passed save roll (>90). Not affected by EMP", 1 ); }
				} else { _log("vehicle is out of range of EMP", 1); }
			}
			activeTimers.push_back("emp");
			_log("finished running getVehiclesNearPosition", 1);
		}
		// Pathping scans powered equipment (tanks, radio jammers, etc.) in use by the enemy and shows each item on the map.
		else if (sCall == "wt_pathping_1.call") {
			array<const XmlElement@> seenVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 1);
			for (uint i = 0; i < seenVehicles.size(); ++i) {
				const XmlElement@ info = seenVehicles[i];
				int id = info.getIntAttribute("id");
				_log("vehicle id: " + id, 1);
				const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
				int vType = vehInfo.getIntAttribute("type_id");
				string sName = vehInfo.getStringAttribute("name");
				string sType = vehInfo.getStringAttribute("type_id");
				string sKey = vehInfo.getStringAttribute("key");
				if ( vType == 51 || vType == 64 || vType == 65 || startsWith(sKey, "deco_") || startsWith(sKey, "dumpster")) {
					_log("vehicle type " + sType + " (" + sKey + ") is not a target worth seeing.", 1);
					seenVehicles.erase(i);
					i--;
					continue;
				} else {
					_log("showing vehicle " + id + " (" + sName + ") on map", 1); 
					string command = "<command class='set_spotting' vehicle_id='" + id + "'></command>";
					m_metagame.getComms().send(command);
				}
			}
		}
		// The Propaganda call has a chance to convert enemy troops (AI only) in the area to fight for WyreTek
		else if (sCall == "wt_propaganda_1.call") {
			_log("WT propaganda is filling the airwaves", 1);
			string propCommand = "<command class='notify' key='wt_propaganda'></command>";
			m_metagame.getComms().send(propCommand);
			sendFactionMessageKey(m_metagame, 0, "wt_propaganda", dictionary = {}, 1.0);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 1, 50.00f);
			_log(hitChars.size() + " characters within range of propaganda", 1);
			for (uint i = 0; i < hitChars.size(); ++i) {
				const XmlElement@ info = hitChars[i];
				int id = info.getIntAttribute("id");
				if (rand(0, 99) < 60) {
					const XmlElement@ qResult = getGenericObjectInfo(m_metagame, "character", id);
					string charPosi = qResult.getStringAttribute("position");
					//string charClass = info.getStringAttribute("soldier_group_name");
					_log("Character " + id + " at position " + charPosi + " failed save roll (<60). Applying effect", 1);
					killCharacter(m_metagame, id);
					//string convertCommand = "<command class='update_character' id='" + id + "' faction_id='0' >/></command>";
					//m_metagame.getComms().send(convertCommand);
					string spawnCommand = "<command class='create_instance' instance_class='character' faction_id='0' position='" + charPosi + "' instance_key='civilian' /></command>";
					m_metagame.getComms().send(spawnCommand);
				} else {
					_log("Character " + id + " passed save roll (>=60). Not affected by Propaganda", 1 ); 
				}
			}
			_log("finished distributing propaganda", 1);
		} 
	}
	// --------------------------------------------
	/*
	bool isTimerActive(string timerName) {
		_log("Looking for '" + timerName + "'", 1);
		uint found = 0;
		for (uint i = 0; i < activeTimers.size(); ++i) {
			if (timerName == activeTimers[i]) {
				found = 1;
				break;
			}
		} 
		return found > 0;
	}

	// --------------------------------------------
	void init() {
	}

	// --------------------------------------------
	void start() {
	}
	*/
	// --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
	// --------------------------------------------
	void update(float time) {
		if (activeTimers.size() == 0) return;

		for (uint i = 0; i < activeTimers.size(); ++i) {
			if (activeTimers[i] == "hot potato") {
				hpTimer -= time;
				_log("hot potato timer is " + hpTimer, 1);
				if (hpTimer <= 0) {
					activeTimers.erase(i);
					i--;
					const XmlElement@ qResult = getGenericObjectInfo(m_metagame, "character", hpHolder);
					string charPosi = qResult.getStringAttribute("position");
					string boomComm = "<command class='create_instance' position='" + charPosi + "' instance_class='grenade' instance_key='hot_pot_boom.projectile' activated='1'></command>";
					m_metagame.getComms().send(boomComm);
				} 
			} else if (activeTimers[i] == "emp") {
				empTimer -= time;
				_log("emp timer is " + empTimer, 1);
				if (empTimer <= 0) {
					activeTimers.erase(i);
					i--;
					if (empVeh.size() >= 1) { 	
						for (uint j = 0; j < empVeh.size(); ++j) {
							uint id = empVeh[j];
							string unlockComm = "<command class='update_vehicle' id='" + id + "' locked='0'></command>";
							m_metagame.getComms().send(unlockComm);
							_log("unlocking vehicle " + id, 1);
						}
					}
				}
			}
		}
	}
	

	// ----------------------------------------------------

}


		/*
		vehicle type_id reference (until the order and count of vehicles in all_vehicles.xml changes... :-|):
		0: Jeep
		1: APC
		4: Rubber Boat
		51: gas tank
		60: mortar ammo
		61 - 65: special_crate1 through special_crate5
		66 - 70: special_cargo vehicles
		71 - 80: special_crate_wood1 through special_crate_wood10
		117: LifeCraft jeep
		*/