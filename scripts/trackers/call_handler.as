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
		if (sKey == "notify_metagame.call") {
			sendFactionMessageKey(m_metagame, 0, "notify call", dictionary = {}, 1.0);
			//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "notify call", bc_call_dict));
		}
	////////////////////////
	//  BlastCorp  Calls  //
	////////////////////////

	////////////////////////
	//  LifeCraft  Calls  //
	////////////////////////
		else if (sKey == "lc_force_field_1.call") {
			_log("establishing lc forcefield at: " + sPosi, 1);
			// place some sort of red translucent dome over the area 
			// projectiles that hit the dome and ricochet or explode 
		} else if (sKey == "lc_repair_bomb_1.call") {
			_log("launching repair bombs near: " + sPosi, 1);
			_log("vehicles to be repaired include: ", 1);
			//_log(getVehiclesNearPosition(m_metagame, v3Posi, 0, 25.00f), 1);
		}
	////////////////////////
	//  ReflexArq  Calls  //
	////////////////////////
		else if (sKey == "ra_nanobot_cloud_1.call") {
			_log("nanobot cloud operating", 1);
			sendFactionMessageKey(m_metagame, 0, "ra_nanobot_cloud", dictionary = {}, 1.0);
			_log("now running getCharactersNearPosition", 1);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 1, 25.00f);
			_log(hitChars.size() + " characters affected by Nanobot Cloud", 1);
			_log("finished running getCharactersNearPosition", 1);
		} else if (sKey == "ra_sprint_1.call") {
			_log("ra sprint operating", 1);
			sendFactionMessageKey(m_metagame, 0, "ra_sprint", dictionary = {}, 1.0);
			_log("now running getCharactersNearPosition", 1);
			array<const XmlElement@> hitChars = getCharactersNearPosition(m_metagame, v3Posi, 0, 25.00f);
			_log(hitChars.size() + " characters boosed by Sprint", 1);
			_log("finished running getCharactersNearPosition", 1);
		} else if (sKey == "ra_teleport_1.call") {
			_log("ra teleport requested", 1);
			_log("relocating character " + sCaller + " to " + sPosi, 1);
			//<command class="update_character" id="sCaller" position="v3Posi" /></command>
			_log("finished teleporting character_id " + sCaller, 1);
		}
	////////////////////////
	// ScopeSystems Calls //
	////////////////////////

	////////////////////////
	//   WyreTek  Calls   //
	////////////////////////
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
				string sId = info.getStringAttribute("id");
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
					string command = "<command class='update_vehicle' id='" + sId + "' max_speed='0.0' acceleration='0' max_reverse_speed='0.0' locked='1'></command>";
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