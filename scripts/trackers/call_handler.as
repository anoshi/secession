// internal
#include "query_helpers.as"
#include "tracker.as"
#include "log.as"

// --------------------------------------------
class CallHandler : Tracker {
	protected GameMode@ m_metagame;
	protected dictionary m_trackedMaps;
	protected Vector3 m_position;
	protected string m_managerName;
	protected int m_factionId;

	// ----------------------------------------------------
	CallHandler(GameMode@ metagame, string managerName, int factionId) {
		@m_metagame = @metagame;
		m_managerName = managerName;
		m_factionId = factionId;
	}

	// --------------------------------------------
	void init() {
	}

	// --------------------------------------------
	void start() {
	}

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
	protected void handleCallRequestEvent(const XmlElement@ event) {
		_log("handleCallRequestEvent in call_handler.as fired", 1);
		sendFactionMessageKey(m_metagame, 0, "CallHandler", dictionary = {}, 1.0);

		string key = event.getStringAttribute("call_key");
		_log("call made was for " + key, 1);

		if (key == "notify_metagame.call") {
			_log("key was definitely notify_metagame.call", 1);
			sendFactionMessageKey(m_metagame, 0, "hello world", dictionary = {}, 1.0);
			//m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 3.0, 0, "call made", bc_call_dict));
		}

		//const XmlElement@ curCall = event.getFirstElementByTagName("call_request_event");

		//dictionary call_dict = {{"TagName", "command"},{"class", "chat"},{"text", "call request event handler called!"}};
		//m_metagame.getComms().send(XmlElement(call_dict));
	
		//sendFactionMessageKey(m_metagame, 0, "handleCallRequestEvent method running", dictionary = {}, 1.0);

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

}