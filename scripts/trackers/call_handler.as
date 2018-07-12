// internal
#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "query_helpers.as"

// --------------------------------------------
class CallHandler : Tracker {
	protected Metagame@ m_metagame;
	//protected GameModeInvasion@ m_metagame;
	protected int m_factionId;

	// --------------------------------------------
	CallHandler(Metagame@ metagame, int factionId) {
		@m_metagame = @metagame;
		m_factionId = factionId;
	}
	
	// ----------------------------------------------------
	bool hasStarted() const {
		return true;
	}

	// ----------------------------------------------------
	bool hasEnded() const {
		return false;
	}

	// ----------------------------------------------------
	protected void handleCallRequestEvent(const XmlElement@ event) {


		_log("test log line", 1);
		dictionary call_dict = {{"TagName", "command"},{"class", "chat"},{"text", "call request event handler called!"}};
		m_metagame.getComms().send(XmlElement(call_dict));
	
		sendFactionMessageKey(m_metagame, 0, "handleCallRequestEvent method running", dictionary = {}, 1.0);

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

		sendFactionMessageKey(m_metagame, 0, "hello world");

		string key = event.getStringAttribute("call_key");
		if (key == "notify_metagame.call") {
			sendFactionMessageKey(m_metagame, 0, "hello world", bc_call_dict, 1.0);
			//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "call made", bc_call_dict));
		}

		int players = getPlayerCount(m_metagame)
		m_metagame.getComms().send(players)
		*/
	}

}