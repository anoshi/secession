// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "announce_task.as"

// invasion
#include "map_rotator_invasion.as"

// --------------------------------------------
class CallHandler : Tracker {
	protected Metagame@ m_metagame;
	protected array<Stage@> m_stages;
	protected int m_currentStageIndex;
	protected int m_nextStageIndex;
	protected array<int> m_stagesCompleted;

	// --------------------------------------------
	CallHandler(Metagame@ metagame) {
		@m_metagame = @metagame;
	}
	
	// ----------------------------------------------------
	protected void handleCallRequestEvent(const XmlElement@ event) {
		// player_id
		// player_name
		// message
		// global

		Stage@ stage = m_stages[m_currentStageIndex];

				// assuming 0th faction is us
				// get starting base
				string baseName = "one of the bases";
				{
					const XmlElement@ base = getStartingBase(m_metagame, 0);
					if (base !is null) {
						baseName = base.getStringAttribute("name");
					}
				}

		dictionary bc_call_dict = {
					{"%map_name", stage.m_mapInfo.m_name}, 
					{"%base_name", baseName}, 
					{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
				};
		//AnnounceTask(Metagame@ metagame, float time, int factionId, string key, dictionary@ a = dictionary(), float priority = 1.0)
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "call made", bc_call_dict));

		/*
		int players = getPlayerCount(m_metagame)
		m_metagame.getComms().send(players)
		_log("reached call handler script");
		string command = "<command class='notify' text='call handler script running' />";
		m_metagame.getComms().send(command);
		*/
	}

	// ----------------------------------------------------
	protected void spawnInstanceNearPlayer(int senderId, string key, string type, int factionId = 0) {
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		if (playerInfo !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				Vector3 pos = stringToVector3(characterInfo.getStringAttribute("position"));
				pos.m_values[0] += 5.0;
				string c = "<command class='create_instance' instance_class='" + type + "' instance_key='" + key + "' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
				m_metagame.getComms().send(c);
			}
		}
	}

	// ----------------------------------------------------
	protected void destroyAllEnemyVehicles(string key) {
		for (uint f = 1; f < 3; ++f) {
			array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, key);
			
			for (uint i = 0; i < vehicles.size(); ++i) {
				const XmlElement@ vehicle = vehicles[i];
				int id = vehicle.getIntAttribute("id");
				destroyVehicle(m_metagame, id);
			}
		}
	}
}