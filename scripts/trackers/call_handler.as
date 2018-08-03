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
		// variablise call attributes
		string key = event.getStringAttribute("call_key");
		string posi = event.getStringAttribute("target_position");
		Vector3 v3posi = stringToVector3(event.getStringAttribute("target_position"));
		string fact = event.getStringAttribute("faction_id");
		_log("call made: " + key, 1);
		//_log("call source position: " + getPlayerPosition, 1)
		_log("call target position: " + posi, 1);
		//_log("distance from source to target: " + getPositionDistance(const Vector3@ pos1, posi), 1);
		//_log("call effect area: " + area, 1);


		if (key == "notify_metagame.call") {
			_log("key was definitely notify_metagame.call", 1);
			sendFactionMessageKey(m_metagame, 0, "hello world", dictionary = {}, 1.0);
			//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "call made", bc_call_dict));
		}
		else if (key == "ra_sprint_1.call") {
			_log("ra sprint operating", 1);
			sendFactionMessageKey(m_metagame, 0, "ra_sprint", dictionary = {}, 1.0);
			_log("now running getCharactersNearPosition", 1);
			getCharactersNearPosition(m_metagame, v3posi, 0, 25.00f);
			_log("finished running getCharactersNearPosition", 1);
		}
		else if (key == "wt_emp_1.call") {
			_log("WT activated EMP at: " + event.getStringAttribute("target_position"), 1);
			if (event.hasAttribute("character_id")) {
				_log("Attribute 'character_id' is stored in " + key, 1);
			}
			else { 
				_log("no Attribute 'character_id' in " + key, 1); 
			}
			_log("now running getVehiclesNearPosition", 1);
			getVehiclesNearPosition(m_metagame, v3posi, 0, 25.00f);
			_log("finished running getVehiclesNearPosition", 1);
			// if target is within call effect radius of call position, do something
			//if checkRange(posi, target, call_effect_radius) {
			//	_log(+ entity at target location " is within effect area of " + key, 1);
			//}
	/* bool checkRange(const Vector3@ pos1, const Vector3@ pos2, float range) {
		float length = getPositionDistance(pos1, pos2);
		return length <= range;
	} */
		}

		//else if (key == "bc_hot_potato_1.call") {
		//	_log("BC hot potato activated at: " + posi, 1);
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