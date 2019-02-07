// internal
#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "announce_task.as"
#include "query_helpers.as"
#include "secession_helpers.as"
// --------------------------------------------


// --------------------------------------------
class CallHandler : Tracker {
	//protected Metagame@ m_metagame;
	protected GameModeInvasion@ m_metagame;
	//protected dictionary m_trackedMaps;
	//protected Vector3 m_position;
	//protected string m_managerName;
	//protected int m_factionId;

	protected string BNNFILE = "bnn_status.xml"; // BNN mission dictionary and state information
	protected bool hpActive = false; // only one Hot Potato allowed at a time
	protected int hpHolder; // id of character holding the hot potato
	protected int numToTele = 0; // number of RA units removed during teleport 1 call, and to be delivered via teleport 2 call
	//protected string hpHolderPosi; // location of the target when receiving the hot potato
	protected bool empActive = false; // only one EMP allowed at a time
	protected array<int> empVeh; // array of vehicle ids affected by emp
	protected array<int> ppVeh; // array of vehicle ids spotted by pathping
	protected array<int> termTurrets; // array of turrets to be controlled by terminal interaction
	protected array<string> activeTimers; // stores the names of active timers
	/*
	protected array<Timers@> m_timers; // to support multiple concurrent calls' countdown timers
	// requires Timers class - see prison_break_objective.as for an example
	*/

	// ----------------------------------------------------
	CallHandler(GameModeInvasion@ metagame) {
	//CallHandler(Metagame@ metagame) {}
		@m_metagame = @metagame;
	}

	protected void handleItemDropEvent(const XmlElement@ event) {
		// BC Hot Potato item tracker
		// we only need to know if the hot potato is dropped on the ground. Otherwise, it's still held by the target
		if ((event.getStringAttribute("item_key") == "hot_potato.projectile") && (event.getStringAttribute("target_container_type_id") == "0")) {
			string hpPosi = event.getStringAttribute("position");
			_log("Hot Potato has been dropped on the ground at " + hpPosi, 1);
			setHotPotPosi(hpPosi); // see secession_helpers.as
		}
	}

	protected void handleCallEvent(const XmlElement@ event) {
	/* REMEMBER: Only calls that have notify_metagame="1" declared are sent here
	Calls that don't require script-side support will use '<command>' blocks in the call itself. */

	// variablise call attributes
		// since v1.70, calls now have phases ('queue', 'acknowledge', 'launch', 'end')
		string phase = event.getStringAttribute("phase");
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

	///////////////////////////////////
	// BNN Mission Dictionary populator
	///////////////////////////////////
	// Need to randomise the values of each dict map instead of hard-coded stuff, but this is mk.1 and working
		dictionary bnn_dict = {
			{"%activity", "call_handler the thing"},
			{"%character_name", "char name"},
			{"%company_name", "Bob Pizza"},
			{"%location_pickup", "round the corner"},
			{"%location_drop", "rah bish binnie"},
			{"%location", "secret loc"},
			{"%vicinity", "k-mart carpark"},
			{"%reward_amount", "heaps!"},
			{"%reward_type", "Pants"},
			{"%rule_engage", "Kill em all!"},
			{"%rule_loot", "don't touch!"}
		};

	////////////////////////
	//   Common   Calls   //
	////////////////////////
		if (sCall == "bnn_mission.call") {
			if (phase == "launch") {
				//sendFactionMessageKey(m_metagame, 0, "BNN mission", dictionary = {}, 1.0);
				//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "BNN mission", bnn_dict));
				notify(m_metagame, "BNN mission", bnn_dict);

				XmlElement root("bnn_missions");

				XmlElement mission("current_mission");
				mission.setStringAttribute("current", "balls");
				mission.setStringAttribute("company", "random company");
				mission.setIntAttribute("timer", rand(0, 99));
				mission.setIntAttribute("location_pickup_x", rand(0, 1024));
				mission.setIntAttribute("location_pickup_y", rand(0, 1024));
				mission.setIntAttribute("location_drop_x", rand(0, 1024));
				mission.setIntAttribute("location_drop_y", rand(0, 1024));
				mission.setIntAttribute("location_x", rand(0, 1024));
				mission.setIntAttribute("location_y", rand(0, 1024));

				root.appendChild(mission);

			//XmlElement@ updateBNNStatus(XmlElement@ root) {
				XmlElement command("command");
				command.setStringAttribute("class", "save_data");
				command.setStringAttribute("filename", BNNFILE);
				command.setStringAttribute("location", "app_data");
				command.appendChild(root);
			//}

				m_metagame.getComms().send(command);

				_log("BNN mission file updated", 1);

				XmlElement@ query = XmlElement(
				makeQuery(m_metagame, array<dictionary> = {
					dictionary = { {"TagName", "data"}, {"class", "saved_data"}, {"filename", BNNFILE}, {"location", "app_data"} } }));
				const XmlElement@ doc = m_metagame.getComms().query(query);

				const array<string>@ missions = loadStringsFromFile(m_metagame, BNNFILE, "current_mission", "timer");
				for (uint i = 0; i < missions.length(); ++i) {
					_log("mission timers, mission " + i + ": " + missions[i], 1);
				}
			}
		}
		else if (sCall == "bnn_advert.call") {
			notify(m_metagame, "BNN advert", bnn_dict);
		}
		else if (sCall == "terminal.call") {
			_log("Terminal call block processing...", 1);
			// improve to detect hostile active turrets (enemy soldier 'turret') as well as offline turrets
			if (phase == "queue") {
				const XmlElement@ qResult = getGenericObjectInfo(m_metagame, "character", iChar);
					string termPos = qResult.getStringAttribute("position");
				_log("locating turrets near: " + termPos, 1);
				Vector3 v3termPos = stringToVector3(termPos);
				array<const XmlElement@> foundTurrets = getVehiclesNearPosition(m_metagame, v3termPos, 0, 10.00f);
				for (uint i = 0; i < foundTurrets.size(); ++i) {
					const XmlElement@ info = foundTurrets[i];
					int id = info.getIntAttribute("id");
					_log("vehicle id: " + id, 1);
					const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
					string vehPosi = vehInfo.getStringAttribute("position");
					Vector3 v3VehPosi = stringToVector3(vehPosi);
					string sKey = vehInfo.getStringAttribute("key");
					if (startsWith(sKey, "veh_empl_turret")) {
						_log("found a turret at: " + vehPosi + ". (Re)Activating...", 1);
						termTurrets.push_back(id);
					} else {
						foundTurrets.erase(i);
						i--;
					}
				}
			} else if (phase == "launch") {
				for (uint i = 0; i < termTurrets.size(); ++i) {
					uint turretID = termTurrets[i];
					const XmlElement@ turretInfo = getVehicleInfo(m_metagame, turretID);
					string turretPosi = turretInfo.getStringAttribute("position");
					// remove turret vehicle/mesh from location
					string remComm = "<command class='remove_vehicle' id='" + turretID + "'></command>";
					m_metagame.getComms().send(remComm);
					// place static turret char at location
					string spawnComm = "<command class='create_instance' instance_class='character' faction_id='0' position='" + turretPosi + "' instance_key='empl_turret' /></command>";
					m_metagame.getComms().send(spawnComm);
				}
			} else if (phase == "end") {
				if (termTurrets.size() >= 1) {
					termTurrets.resize(0);
				}
			}
		}
		//else if (sCall == "bombing_run.call") {
		//	_log("Bombing run from " + charPosi + " to " + sPosi + " queued", 1);
		// subtract caller pos from target pos to get vector that is dist and dir from target to player.
		//}
	////////////////////////
	//  BlastCorp  Calls  //
	////////////////////////
		// The BC Hot Potato drops a very heavy, timed explosive in the backpack of a nearby enemy. If not detected
		// in time, the recipient (and those in the blast radius) is blown apart rather vigorously
		else if (sCall == "bc_hot_potato_1.call") {
			if (hpActive && phase == "queue") {
				string potatoComm = "<command class='chat' faction_id='0' text='Wait for next available, over' priority='1'></command>";
				m_metagame.getComms().send(potatoComm);
				_log("a hot potato is already in play", 1);
			} else if (phase == "launch") {
				_log("BC hot potato requested at: " + sPosi, 1);
				hpActive = true;
				array<const XmlElement@> targetChars;
				for (uint i = 0; i < m_metagame.getFactions().size(); ++i) {
					array<const XmlElement@> tempTargetChars = getCharactersNearPosition(m_metagame, v3Posi, i, 10.00f);
					merge(targetChars, tempTargetChars);
				}
				_log(targetChars.size() + " potential characters to receive hot potato", 1);
				if (targetChars.size() > 0) {
					uint i = rand(0, targetChars.size() - 1);
					const XmlElement@ mrPotato = targetChars[i];
					hpHolder = mrPotato.getIntAttribute("id");
					_log("character id: " + hpHolder + " chosen to receive hot potato.", 1);
					string potatoComm = "<command class='update_inventory' character_id='" + hpHolder + "' container_type_class='backpack'>" + "<item class='grenade' key='hot_potato.projectile' />" + "</command>";
					m_metagame.getComms().send(potatoComm);
					//aka: addItemInBackpack(m_metagame, id, const Resource@ r);
					//const XmlElement@ qResult = getGenericObjectInfo(m_metagame, "character", hpHolder);
					//hpHolderPosi = qResult.getStringAttribute("position");
					_log("BC Hot Potato placed in backpack of character: " + hpHolder, 1);
					setHotPotPosi("init");
					activeTimers.push_back("hot potato");
				}
			} else if (phase == "end") {
				string hpPosition = getHotPotPosi();
				if (hpPosition == "init") {
					// hot potato wasn't dropped onto ground; may have been thrown. check if resource still exists
					//const XmlElement@ isActive = getResource(m_metagame, "hot_potato.projectile", "grenade");
					//if (isActive !is null) {
					_log("Character id: " + hpHolder + " still has the hot potato. Good bye!", 1);
					const XmlElement@ qResult = getGenericObjectInfo(m_metagame, "character", hpHolder);
					hpPosition = qResult.getStringAttribute("position");
					//}
				}
				string boomComm = "<command class='create_instance' position='" + hpPosition + "' instance_class='grenade' instance_key='hot_pot_boom.projectile' activated='1'></command>";
				m_metagame.getComms().send(boomComm);
				// remove the hot potato item from play - not yet implemented
				// reset the hot potato countdown timer
				hpActive = false;
			}
		}
	////////////////////////
	//  LifeCraft  Calls  //
	////////////////////////
		// The Conversion call has a chance to convert enemy troops (AI only) in the area to fight for LifeCraft
		else if (sCall == "lc_conversion_1.call") {
			if (phase == "launch") {
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
			} else if (phase == "end") {
				_log("finished conversion attempt", 1);
			}
		}
		// The LC Forcefield places a red translucent dome over the area for a period. Characters can move
		// through the field, but projectiles that hit the dome ricochet or explode
		else if (sCall == "lc_force_field_1.call") {
			if (phase == "launch") {
				_log("establishing lc forcefield at: " + sPosi, 1);
			}
		}
		// The Repair Bomb operates similarly to the LC Heal bomb, repairing damage to all vehicles in the area of effect
		// Currently works far too well; it doesn't stop 'repairing' a vehicle that is 100% health... Script a solution
		else if (sCall == "lc_repair_bomb_1.call") {
			if (phase == "launch") {
				_log("launching repair bombs near: " + sPosi, 1);
				array<const XmlElement@> repVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 0, 35.00f);
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
				}
			}
		}
	////////////////////////
	//  ReflexArq  Calls  //
	////////////////////////
		// The nanobot cloud blinds and confuses enemy troops (AI only) in the area for a duration
		else if (sCall == "ra_nanobot_cloud_1.call") {
			if (phase == "launch") {
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
			} else if (phase == "end") {
				_log("RA Nanobot Cloud ended", 1);
			}
		}
		// The sprint call temporarily boosts the speed and willingness to charge attributes of friendly units near the caller
		else if (sCall == "ra_sprint_1.call") {
			if (phase == "queue") {
				string markComm = "<command class='set_marker' faction_id='0' id='4041' enabled='1' atlas_index='0' text='RANDOM TEXT YEEOW' position='" + sPosi + "' color='#ff0000' range='10.0'></command>";
				m_metagame.getComms().send(markComm);
			} else if (phase == "launch") {
				_log("ra sprint operating", 1);
				sendFactionMessageKey(m_metagame, 0, "ra_sprint", dictionary = {}, 1.0);
				_log("now running getCharactersNearPosition", 1);
				array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 0, 25.00f);
				_log(hitChars.size() + " characters boosted by Sprint", 1);
				for (uint i = 0; i < hitChars.size(); ++i) {
					const XmlElement@ info = hitChars[i];
					int id = info.getIntAttribute("id");
					_log("character id:" + id, 1);
					const XmlElement@ charInfo = getCharacterInfo(m_metagame, id);
					string sprintcomm = "<command class='soldier_ai' id='" + id + "'><parameter class='willingness_to_charge' value='1.0' /></command>";
					m_metagame.getComms().send(sprintcomm);
				}
			} else if (phase == "end") {
				// remove the marker
				string markComm = "<command class='set_marker' faction_id='0' id='4041' enabled='0'></command>";
				m_metagame.getComms().send(markComm);
				_log("finished running RA Sprint", 1);
			}

		}
		// The teleport (out) call relocates friendly characters in the targeted area off the field, ready to be teleported back in with teleport 2. * Warning: May not transfer all equipment in the process *
		else if (sCall == "ra_teleport_1.call") {
			if (numToTele >= 9 && phase == "queue") {
				string teleComm = "<command class='chat' faction_id='0' text='Teleporter at maximum capacity. Dispatch units before calling again. Out.' priority='1'></command>";
				m_metagame.getComms().send(teleComm);
				_log("teleport targets already at maximum", 1);
			} else if (phase == "acknowledge") {
				_log("ra teleport requested", 1);
			} else if (phase == "launch") {
				// count, id, and remove friendlies at target location
				array<const XmlElement@> teleChars = getCharactersNearPosition(m_metagame, v3Posi, 0, 10.00f);
				for (uint i = 0; i < teleChars.size(); ++i) {
					if (numToTele < 10) {
						//const XmlElement@ teleChar = getCharacterInfo(m_metagame, teleChars[i]);
						const XmlElement@ info = teleChars[i];
						int id = info.getIntAttribute("id");
						//string charClass = info.getStringAttribute("soldier_group_name");
						//const XmlElement@ qResult = getGenericObjectInfo(m_metagame, "character", id);
						const XmlElement@ qResult = getCharacterInfo(m_metagame, id);
						killCharacter(m_metagame, id);
						_log("character " + id + " retrieved for teleport", 1);
						// write the number of chars and their class/types to an array
						numToTele += 1;
					}
				}
			} else if (phase == "end") {
				// if I use an array to store these guys ... _log(teleChars.size() + " characters prepped for teleport", 1);
			}
		}
		// The teleport (in) call spawns friendly characters (who have already been teleported out/off the battlefield) at the target location
		else if (sCall == "ra_teleport_2.call") {
			if (numToTele == 0) {
				string teleComm = "<command class='chat' faction_id='0' text='No units waiting in teleporter. Port units in before calling again, over.' priority='1'></command>";
				m_metagame.getComms().send(teleComm);
				_log("No units queued to teleport", 1);
			} else {
				if (phase == "acknowledge") {
					_log(numToTele + " characters queued for teleport to " + sPosi, 1);
				}
				if (phase == "launch") {
					for (int i = 0; i < numToTele; ++i) {
						// for each unit removed in teleport 1 call, spawn very close to target location of teleport 2 call
						string teleInComm = "<command class='create_instance' instance_class='character' faction_id='0' position='" + sPosi + "'/></command>"; // instance_key='" + charType + "'
						m_metagame.getComms().send(teleInComm);
					}
				}
				if (phase == "end" && numToTele > 0) {
					// job done, reset teleporter count.
					numToTele = 0;
				}
			}
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
		// The probe emits a regular but infrequent visual 'blip' that enemies may notice and, after doing so, destroy the device.
		else if (sCall == "ss_probe_1.call") {
			_log("SS probe not implemented, yet", 1);
		}
		// The x-ray call advises the contents of crates as well as armoured and hidden devices in the game. It allows SS troops to make
		// a judgement call as to whether or not they should attempt to reach the location in the first place.
		else if (sCall == "ss_x-ray_1.call") {
			if (phase == "launch") {
				array<const XmlElement@> xrayItem = getVehiclesNearPosition(m_metagame, v3Posi, 1, 15.00f);
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
			} else if (phase == "end") {
				_log("ss x-ray completed");
			}
		}
	////////////////////////
	//   WyreTek  Calls   //
	////////////////////////
		// The EMP is verly likely to stop movement of all enemy vehicles caught in the blast area.
		else if (sCall == "wt_emp_1.call") {
			_log("WT requested EMP at: " + event.getStringAttribute("target_position"), 1);
			if (empActive && phase == "queue") {
				string empComm = "<command class='chat' faction_id='0' text='Wait for next available, over' priority='1'></command>";
				m_metagame.getComms().send(empComm);
				_log("EMP already in effect", 1);
			} else if (phase == "launch") {
				empActive = true;
				array<const XmlElement@> hitVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 1, 30.00f);
				for (uint i = 0; i < hitVehicles.size(); ++i) {
					const XmlElement@ info = hitVehicles[i];
					int id = info.getIntAttribute("id");
					_log("vehicle id: " + id, 1);
					const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
					int vType = vehInfo.getIntAttribute("type_id");
					Vector3 v3VehPosi = stringToVector3(vehInfo.getStringAttribute("position"));
					string sName = vehInfo.getStringAttribute("name");
					string sKey = vehInfo.getStringAttribute("key");
					if ( startsWith(sKey, "special_c") ) {
						_log("vehicle type " + vType + " (" + sKey + ") is not affected by EMP.", 1);
						hitVehicles.erase(i);
						i--;
						continue;
					}
					if (rand(0, 99) <= 90) {
						_log(sName + " failed save roll (<90). Applying effect", 1);
						empVeh.push_back(id);
						string command = "<command class='update_vehicle' id='" + id + "' forward='0 0 0' locked='1'></command>";
						m_metagame.getComms().send(command);
					} else { _log(sName + " passed save roll (>90). Not affected by EMP", 1 ); }
				}
				_log("finished applying EMP effect", 1);
			} else if (phase == "end") {
				if (empVeh.size() >= 1) {
					for (uint j = 0; j < empVeh.size(); ++j) {
						uint id = empVeh[j];
						// add logic to remove destroyed vehicles from the empVeh array
						string unlockComm = "<command class='update_vehicle' id='" + id + "' locked='0'></command>";
						m_metagame.getComms().send(unlockComm);
						_log("unlocking vehicle " + id, 1);
					}
					empVeh.resize(0);
				}
				empActive = false;
			}
		}
		// Pathping scans powered equipment (tanks, radio jammers, etc.) in use by the enemy and shows each item on the map.
		else if (sCall == "wt_pathping_1.call") {
			if (phase == "launch") {
				array<const XmlElement@> seenVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 1, 500.00f);
				for (uint i = 0; i < seenVehicles.size(); ++i) {
					const XmlElement@ info = seenVehicles[i];
					int id = info.getIntAttribute("id");
					_log("vehicle id: " + id, 1);
					const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
					int vType = vehInfo.getIntAttribute("type_id");
					string sName = vehInfo.getStringAttribute("name");
					string sType = vehInfo.getStringAttribute("type_id");
					string sKey = vehInfo.getStringAttribute("key");
					int oID = vehInfo.getIntAttribute("owner_id");
					if ( vType == 51 || vType == 64 || vType == 65 ) {
						_log("vehicle type " + sType + " (" + sKey + ") is not a target worth seeing.", 1);
						seenVehicles.erase(i);
						i--;
						continue;
					} else {
						_log("showing vehicle " + id + " (" + sName + ") on map", 1);
						//string seeComm = "<command class='set_spotting' faction_id='" + oID + "' vehicle_id='" + id + "'></command>";
						string seeComm = "<command class='set_spotting' faction_id='0' vehicle_id='" + id + "'></command>";
						m_metagame.getComms().send(seeComm);
						ppVeh.push_back(id);
					}
				}
			} else if (phase == "end") {
				if (ppVeh.size() >= 1) {
					for (uint j = 0; j < ppVeh.size(); ++j) {
						uint id = ppVeh[j];
						// add logic to remove destroyed vehicles from the ppVeh array
						string unseeComm = "<command class='set_spotting' faction_id='0' vehicle_id='" + id + "' enabled='0'></command>";
						m_metagame.getComms().send(unseeComm);
						_log("removing vehicle " + id + " from map view.", 1);
					}
					ppVeh.resize(0);
				}
			}
		}
		// The Propaganda call has a chance to convert enemy troops (AI only) in the area to fight for WyreTek
		else if (sCall == "wt_propaganda_1.call") {
			if (phase == "launch") {
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
						string spawnCommand = "<command class='create_instance' instance_class='character' faction_id='0' position='" + charPosi + "' instance_key='civilian' /></command>";
						m_metagame.getComms().send(spawnCommand);
					} else {
						_log("Character " + id + " passed save roll (>=60). Not affected by Propaganda", 1 );
					}
				}
			} else if (phase == "end") {
				_log("finished distributing propaganda", 1);
			}
		}
	}
	// --------------------------------------------
	/*
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
