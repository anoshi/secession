// internal
#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "announce_task.as"
#include "query_helpers.as"
#include "secession_helpers.as"
// --------------------------------------------


// --------------------------------------------
class HitboxHandler : Tracker {
	//protected Metagame@ m_metagame;
	protected GameModeInvasion@ m_metagame;
	protected array<const XmlElement@> m_triggerAreas;
	protected array<string> m_trackedTriggerAreas;

	protected int m_playerCharacterId;
	protected float m_localPlayerCheckTimer;
	protected float LOCAL_PLAYER_CHECK_TIME = 5.0;

	// ----------------------------------------------------
	HitboxHandler(GameModeInvasion@ metagame) {
	//HitboxHandler(Metagame@ metagame) {}
		@m_metagame = @metagame;
		determineTriggerAreasList();
	}

	// -------------------------------------------------------
	protected void handleHitboxEvent(const XmlElement@ event) {
		_log("** SECESSION hitbox event triggered. Running in hitbox_handler.as", 1);
		// variablise returned handleHitboxEvent event attributes:
		string sHId = event.getStringAttribute("hitbox_id");
		string sIType = event.getStringAttribute("instance_type");
		int iIId = event.getIntAttribute("instance_id");
		string sPos = ""; // stores the xyz coords of the hitbox
		Vector3 v3Pos; // stores same as Vector3

		// is it a trigger area hitbox? If not, this is not the handler you are looking for...
		if (!startsWith(sHId, "hitbox_trigger_")) {
			return;
		}

		// get details about the hitbox that has been entered
		const array<const XmlElement@> list = getTriggerAreasList();
		for (uint i = 0; i < list.size(); ++i) {
			_log("** SECESSION looping through triggerAreasList. Looking for " + sHId, 1);
			const XmlElement@ thisArea = list[i];
			if (thisArea.getStringAttribute("id") == sHId) {
				_log("** SECESSION trigger area found! " + sHId + " has position: " + thisArea.getStringAttribute("position"), 1);
				sPos = thisArea.getStringAttribute("position");
				Vector3 v3Pos = stringToVector3(sPos);
			}
		}

		if (sIType == "character" && iIId == m_playerCharacterId) {
		// this event concerns our master player, who is being tracked for hitbox collisions via setupCharacterForTracking(int id);
			_log("** player within trigger area: " + sHId, 1);
			if (startsWith(sHId, "hitbox_trigger_jumppad")) {
				_log("hitbox is a jump pad. Spawning jump platform at location", 1);
				string spawnComm = "<command class='create_instance' position='" + sPos + "' instance_class='vehicle' instance_key='platform.vehicle' /></command>";
				m_metagame.getComms().send(spawnComm);
			}
			else if (startsWith(sHId, "hitbox_trigger_repairbay")) {
				_log("hitbox is a repair bay. Starting repairs", 1);
				array<const XmlElement@> repVehicle = getVehiclesNearPosition(m_metagame, v3Pos, 0, 7.00f);
			} // note terminal, mounted weapon, fires healing stream at vehicle.
			else if (startsWith(sHId, "hitbox_trigger_trap")) {
				_log("hitbox is a trap. Running deterrent routines...", 1);
				// Player has entered an area that is tracked by an enemy device.
				// Add a particle effect like a flashing red light on the detecting device

				// Spawn some baddies || commander alert to enemy faction ||  some other dastardly act.
			}
			// when we're done handling the event, we may want to clear hitbox checking
			// (I don't think we want to clear these until the end of each map)
			//clearTriggerAreaAssociations(m_metagame, "character", m_playerCharacterId, m_trackedTriggerAreas);
		}
	}

	// -------------------------------------------------------
	protected void determineTriggerAreasList() {
		array<const XmlElement@> list;
		_log("** SECESSION hitbox_handler: determineTriggerAreasList", 1);

    	list = getTriggerAreas(m_metagame);
			// go through the list and only leave the ones in we're interested in, 'hitbox_trigger_*'
			for (uint i = 0; i < list.size(); ++i) {
				const XmlElement@ triggerAreaNode = list[i];
				string id = triggerAreaNode.getStringAttribute("id");
				bool ruleOut = false;
				if (id.findFirst("hitbox_trigger_") < 0) {
					ruleOut = true;

				if (ruleOut) {
					_log("** SECESSION hitbox_handler determineTriggerAreasList: ruling out " + id, 1);
					list.erase(i);
					i--;
				} else {
					_log("** SECESSION hitbox_handler determineTriggerAreasList: including " + id, 1);
				}
			}
			_log("* " + list.size() + " trigger areas found");
		}

		m_triggerAreas = list;
		markTriggerAreas(); // show the centre point of each trigger area with a mark and also on map
	}

	// -------------------------------------------------------
	protected const array<const XmlElement@>@ getTriggerAreasList() const {
		return m_triggerAreas;
	}

	// -------------------------------------------------------
	protected array<const XmlElement@>@ getTriggerAreas(const Metagame@ metagame) {
		_log("running getTriggerAreas in hitbox_handler.as", 1);
		XmlElement@ query = XmlElement(
			makeQuery(metagame, array<dictionary> = {
				dictionary = { {"TagName", "data"}, {"class", "hitboxes"} } }));

		const XmlElement@ doc = metagame.getComms().query(query);
		array<const XmlElement@> triggerList = doc.getElementsByTagName("hitbox");

		for (uint i = 0; i < triggerList.size(); ++i) {
			const XmlElement@ hitboxNode = triggerList[i];
			string id = hitboxNode.getStringAttribute("id");
			if (startsWith(id, "hitbox_trigger")) {
				_log("including " + id, 1);
			} else {
				triggerList.erase(i);
				i--;
			}
		}
		_log("* " + triggerList.size() + " trigger areas found", 1);
		return triggerList;
	}

	// ----------------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		_log("** SECESSION hitboxHandler::handlePlayerSpawnEvent", 1);

		const XmlElement@ element = event.getFirstElementByTagName("player");
		string name = element.getStringAttribute("name");
		_log("player spawned: " + name + ", target username is " + m_metagame.getUserSettings().m_username, 1);
		if (name == m_metagame.getUserSettings().m_username) {
			_log("player is local", 1);
			setupCharacterForTracking(element.getIntAttribute("character_id"));
		}
	}

	// ----------------------------------------------------
	protected void setupCharacterForTracking(int id) {
		clearTriggerAreaAssociations(m_metagame, "character", m_playerCharacterId, m_trackedTriggerAreas);
		m_playerCharacterId = id;

		_log("setting up tracking for character " + id, 1);

		const array<const XmlElement@> list = getTriggerAreasList();
		if (list !is null) {
			associateTriggerAreas(m_metagame, list, "character", m_playerCharacterId, m_trackedTriggerAreas);
		}
	}

	// ----------------------------------------------------
	protected void ensureValidLocalPlayer(float time) {
		if (m_playerCharacterId < 0) {
			m_localPlayerCheckTimer -= time;
			if (m_localPlayerCheckTimer < 0.0) {
				_log("tracked player character id " + m_playerCharacterId, 1);
				const XmlElement@ player = m_metagame.queryLocalPlayer();
				if (player !is null) {
					setupCharacterForTracking(player.getIntAttribute("character_id"));
				} else {
					_log("WARNING, local player query failed", -1);
				}
				m_localPlayerCheckTimer = LOCAL_PLAYER_CHECK_TIME;
			}
		}
	}

		// --------------------------------------------
	protected void markTriggerAreas() {
		const array<const XmlElement@> list = getTriggerAreasList();
		if (list is null) return;

		//bool showAtScreenEdge = showTriggerAreas(); // method doesn't exist, example only

		// only show trigger area markers for debug purposes at this time
		// debug:
        bool showAtScreenEdge = true;

		int offset = 2050;
		for (uint i = 0; i < list.size(); ++i) {
			const XmlElement@ triggerAreaNode = list[i];
			string id = triggerAreaNode.getStringAttribute("id");
			string text = "a trigger area";
			int atlasIndex = 1;
			float size = 1.0;
			string color = "#E0E0E0";
			string position = triggerAreaNode.getStringAttribute("position");

			string command = "<command class='set_marker' id='" + offset + "' faction_id='0' atlas_index='" + atlasIndex +
				"' text='" + text + "' position='" + position + "' color='" + color + "' size='" + size + "' show_at_screen_edge='" + (showAtScreenEdge?1:0) + "' />";
			m_metagame.getComms().send(command);

			offset++;
		}
	}

	// --------------------------------------------------------
	protected void unmarkTriggerAreas() {
		const array<const XmlElement@> list = getTriggerAreasList();
		if (list !is null) return;

		int offset = 2050;
		for (uint i = 0; i < list.size(); ++i) {
			string command = "<command class='set_marker' id='" + offset + "' enabled='0' />";
			m_metagame.getComms().send(command);
			offset++;
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
		ensureValidLocalPlayer(time);
	}
	// ----------------------------------------------------
}
