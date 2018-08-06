// internal
#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "query_helpers.as"

// --------------------------------------------
class CallHandler : Tracker {
	protected Metagame@ m_metagame;
	//protected dictionary m_trackedMaps;
	//protected Vector3 m_position;
	//protected string m_managerName;
	//protected int m_factionId;

	// ----------------------------------------------------
	CallHandler(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	protected void handleCallRequestEvent(const XmlElement@ event) {
	/* REMEMBER: Only calls that have notify_metagame="1" declared are sent here */
	// variablise call attributes
		string sCaller = event.getStringAttribute("character_id");
		int iCaller = event.getIntAttribute("character_id");
		string sKey = event.getStringAttribute("call_key");
		string sPosi = event.getStringAttribute("target_position");
		Vector3 v3Posi = stringToVector3(event.getStringAttribute("target_position"));
		string fact = event.getStringAttribute("faction_id");
		const XmlElement@ char = getCharacterInfo(m_metagame, iCaller);
	//return getGenericObjectInfo(metagame, "character", characterId);

		_log("call made: " + sKey, 1);
		//_log("call source position: " + getPlayerPosition, 1)
		_log("call target position: " + sPosi, 1);
		//_log("distance from source to target: " + getPositionDistance(const Vector3@ pos1, posi), 1);
		//_log("call effect area: " + area, 1);

	////////////////////////
	//   Common   Calls   //
	////////////////////////
		// Notify metage call is a placeholder call to test calls that have 'notify_metagame="1"' set
		if (sKey == "notify_metagame.call") {
			sendFactionMessageKey(m_metagame, 0, "notify call", dictionary = {}, 1.0);
			//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "notify call", bc_call_dict));
		}
	////////////////////////
	//  BlastCorp  Calls  //
	////////////////////////
		// None that requires script-side support at this time. See 'command' blocks in the calls themselves.
	////////////////////////
	//  LifeCraft  Calls  //
	////////////////////////
		// The LC Forcefield places a red translucent dome over the area for a period. Characters can move 
		// through the field, but projectiles that hit the dome ricochet or explode 
		else if (sKey == "lc_force_field_1.call") {
			_log("establishing lc forcefield at: " + sPosi, 1);	
		} 
		// The Repair Bomb operates similarly to the LC Heal bomb, repairing damage to all vehicles in the area of effect
		// Currently works far too well; it doesn't stop 'repairing' a vehicle that is 100% health... Script a solution
		else if (sKey == "lc_repair_bomb_1.call") {
			_log("launching repair bombs near: " + sPosi, 1);
			array<const XmlElement@> repVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 0, 2.000f);
			_log("vehicles to be repaired include: ", 1);
			//_log(getVehiclesNearPosition(m_metagame, v3Posi, 0, 25.00f), 1);
		}
	////////////////////////
	//  ReflexArq  Calls  //
	////////////////////////
		// The nanobot cloud blinds and confuses enemy troops (AI only) in the area for a duration
		else if (sKey == "ra_nanobot_cloud_1.call") {
			_log("nanobot cloud operating", 1);
			sendFactionMessageKey(m_metagame, 0, "ra_nanobot_cloud", dictionary = {}, 1.0);
			_log("now running getCharactersNearPosition", 1);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 1, 25.00f);
			_log(hitChars.size() + " characters affected by Nanobot Cloud", 1);
			_log("finished running getCharactersNearPosition", 1);
		} 
		// The sprint call temporarily boosts the speed and willingness to charge attributes of friendly units near the caller 
		else if (sKey == "ra_sprint_1.call") {
			_log("ra sprint operating", 1);
			sendFactionMessageKey(m_metagame, 0, "ra_sprint", dictionary = {}, 1.0);
			_log("now running getCharactersNearPosition", 1);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 0, 25.00f);
			_log(hitChars.size() + " characters boosed by Sprint", 1);
			string command = "<command class='update_character' id='" + sCaller + "' position='" + sPosi + "' ></command>";
			_log("finished running getCharactersNearPosition", 1);
		} 
		// The teleport call relocates the caller to the desired location. * Warning: May not transfer all equipment in the process *
		else if (sKey == "ra_teleport_1.call") {
			_log("ra teleport requested", 1);
			_log("relocating character " + sCaller + " to " + sPosi, 1);
			string command = "<command class='update_character' id='" + sCaller + "' position='" + sPosi + "' ></command><command class='update_camera' position='" + sPosi + "'></command>";
			m_metagame.getComms().send(command);
			_log("finished teleporting character_id " + sCaller + " to " + sPosi, 1);
		}
	////////////////////////
	// ScopeSystems Calls //
	////////////////////////
		// The x-ray call advises the contents of crates as well as armoured and hidden devices in the game. It allows SS troops to make 
		// a judgement call as to whether or not they should attempt to reach the location in the first place.
		else if (sKey == "ss_x-ray_1.call") {
			array<const XmlElement@> xrayItem = getVehiclesNearPosition(m_metagame, v3Posi, 1, 2.000f);
			for (uint i = 0; i < xrayItem.size(); ++i) {
				const XmlElement@ info = xrayItem[i];
				int id = info.getIntAttribute("id");
				_log("vehicle id: " + id, 1);
				const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
				int vType = vehInfo.getIntAttribute("type_id");
				string sName = vehInfo.getStringAttribute("name");
				string sType = vehInfo.getStringAttribute("type_id");
				string sKey = vehInfo.getStringAttribute("key");
				if ( vType == 51 || vType == 64 || vType == 65 || startsWith(sKey, "deco_") || startsWith(sKey, "dumpster") || startsWith(sKey, "special_c") ) {
					_log("vehicle type " + sType + " (" + sKey + ") not a target worth seeing.", 1);
					xrayItem.erase(i);
					i--;
				} else {
					_log("showing vehicle " + id + " (" + sName + ") on map", 1); 
					string command = "<command class='set_spotting' vehicle_id='" + id + "' />";
					m_metagame.getComms().send(command);
				}
			}
		}
		// The Probe call launches a stealth device that alerts the caller's faction when an enemy unit passes near it.
		// The probe emits a regular but infrequent visual 'blip' that enemies may notice and destroy the device.
		else if (sKey == "ss_probe.call") {
			_log("SS probe not implemented, yet", 1);
		}
	////////////////////////
	//   WyreTek  Calls   //
	////////////////////////
		// The EMP is verly likely to stop movement of all enemy vehicles caught in the blast area. 
		else if (sKey == "wt_emp_1.call") {
			_log("WT activated EMP at: " + event.getStringAttribute("target_position"), 1);
			_log("now running getVehiclesNearPosition", 1);
			array<const XmlElement@> hitVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 1, 2.000f);
			//SCRIPT:  sending: TagName=command class=make_query id=11.000 TagName=data class=vehicles faction_id=0.000 position=181.80701 17.85490 335.78699 range=25.000 
			//SCRIPT:  received: TagName=query_result query_id=11     TagName=vehicle id=0     TagName=vehicle id=8     TagName=vehicle id=9     TagName=vehicle id=14     TagName=vehicle id=16     TagName=vehicle id=19     TagName=vehicle id=20     TagName=vehicle id=22
			_log(hitVehicles.size() + " vehicles in radius of EMP detonation", 1);
			for (uint i = 0; i < hitVehicles.size(); ++i) {
				const XmlElement@ info = hitVehicles[i];
				int id = info.getIntAttribute("id");
				_log("vehicle id: " + id, 1);
				//SCRIPT:vehicle id: 0
				const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
				int vType = vehInfo.getIntAttribute("type_id");
				string sName = vehInfo.getStringAttribute("name");
				string sType = vehInfo.getStringAttribute("type_id");
				string sKey = vehInfo.getStringAttribute("key");
				//SCRIPT:  sending: TagName=command class=make_query id=12.000     TagName=data class=vehicle id=0.000 
				//SCRIPT:  received: TagName=query_result query_id=12     TagName=vehicle block=9 9 forward=0.925284 0 0.379275 health=2 holder_id=0 id=0 key=jeep_2.vehicle name=Urbal UAS owner_id=0 position=323.597 12.4804 310.537 right=0.379267 0 -0.925287 type_id=93 
				if ( vType == 51 || vType == 64 || vType == 65 || startsWith(sKey, "deco_") || startsWith(sKey, "dumpster") || startsWith(sKey, "special_c") ) {
					_log("vehicle type " + sType + " (" + sKey + ") not affected by EMP.", 1);
					hitVehicles.erase(i);
					i--;
				} else {
					_log("applying EMP effect on vehicle " + sName, 1); 
					string command = "<command class='update_vehicle' id='" + id + "' max_speed='0.0' acceleration='0' max_reverse_speed='0.0' locked='1'></command>";
					// optional: locked='1'>
					m_metagame.getComms().send(command);
				}
			}
				//now the 'hitVehicles' array stores only the vehicles the the EMP blast will affect.
				// for each vehicle: get max_speed, acceleration, max_reverse_speed
				
				// for each vehicle: set above values to 0 for EMP period (e.g. 15 seconds)

			//array<const XmlElement@> vehicleList = doc.getElementsByTagName("vehicle");
			//_log("* " + vehicleList.size() + " vehicles found with key " + vehicleKey + " in faction " + factionId, 1);

			_log("finished running getVehiclesNearPosition", 1);
			// if target is within call effect radius of call position, do something
			//if checkRange(sPosi target, call_effect_radius) {
			//	_log(entity at target location + " is within effect area of " + sKey, 1);
			//}
		}
		// Pathping scans powered equipment (tanks, radio jammers, etc.) in use by the enemy and shows each item on the map.
		else if (sKey == "wt_pathping_1.call") {
			array<const XmlElement@> seenVehicles = getVehiclesNearPosition(m_metagame, v3Posi, 1, 2.000f);
			for (uint i = 0; i < seenVehicles.size(); ++i) {
				const XmlElement@ info = seenVehicles[i];
				int id = info.getIntAttribute("id");
				_log("vehicle id: " + id, 1);
				const XmlElement@ vehInfo = getVehicleInfo(m_metagame, id);
				int vType = vehInfo.getIntAttribute("type_id");
				string sName = vehInfo.getStringAttribute("name");
				string sType = vehInfo.getStringAttribute("type_id");
				string sKey = vehInfo.getStringAttribute("key");
				if ( vType == 51 || vType == 64 || vType == 65 || startsWith(sKey, "deco_") || startsWith(sKey, "dumpster") || startsWith(sKey, "special_c") ) {
					_log("vehicle type " + sType + " (" + sKey + ") not a target worth seeing.", 1);
					seenVehicles.erase(i);
					i--;
				} else {
					_log("showing vehicle " + id + " (" + sName + ") on map", 1); 
					string command = "<command class='set_spotting' vehicle_id='" + id + "' />";
					m_metagame.getComms().send(command);
				}
			}
		}
		/* bool checkRange(const Vector3@ pos1, const Vector3@ pos2, float range) {
		float length = getPositionDistance(pos1, pos2);
		return length <= range;
		*/
	
		/*if (event.hasAttribute("character_id")) {
			_log("Attribute 'character_id' is stored in " + sKey, 1);
		} else { 
			_log("no Attribute 'character_id' in " + sKey, 1); 
		}*/
		
		//else if (sKey == "bc_hot_potato_1.call") {
		//	_log("BC hot potato activated at: " + sPosi 1);
		//	addItemInBackpack(m_metagame, int characterId, const Resource@ r);
		//}


		//dictionary call_dict = {{"TagName", "command"},{"class", "chat"},{"text", "call request event handler called!"}};
		//m_metagame.getComms().send(XmlElement(call_dict));
	
		//AnnounceTask(Metagame@ metagame, float time, int factionId, string key, dictionary@ a = dictionary(), float priority = 1.0)
		//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "call made", bc_call_dict));

		// string command = "<command class='notify' text='call handler script running' />";
		// m_metagame.getComms().send(command);

		// string command = "<command class='set_soundtrack' enabled='1' />";
		// m_metagame.getComms().send(command);

		/*
		dictionary bc_call_dict = {
			{"%map_name", stage.m_mapInfo.m_name}, 
			{"%base_name", baseName}, 
			{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
		};

		int players = getPlayerCount(m_metagame)
		m_metagame.getComms().send(players)
		*/
	}
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
	/*
	// --------------------------------------------
	void update(float time) {
	}
	*/

	// ----------------------------------------------------

}