// internal
#include "tracker.as"
#include "gamemode.as"
#include "log.as"

// --------------------------------------------


// --------------------------------------------
class BNN : Tracker {
	protected GameMode@ m_metagame;

    protected float MISSION_TIMER_MAX = 80.00; //180
    protected float MISSION_TIMER_MIN = 45.00; //90
	protected float m_timer; // mission random timer
    protected float ADVERT_TIMER_MAX = 40.00; //240
    protected float ADVERT_TIMER_MIN = 20.00; //120
	protected float a_timer; // advert random timer
	protected array<string> activeTimers = {"mission", "advert"}; // stores the names of active timers
	protected dictionary bnn_dict;
	// ----------------------------------------------------
	BNN(GameMode@ metagame) {
		@m_metagame = @metagame;

		restartTimer("mission");
		restartTimer("advert");
	}

	protected void restartTimer(string timer) {
		if (timer == "mission") {
			m_timer = rand(MISSION_TIMER_MIN, MISSION_TIMER_MAX);
			_log("BNN mission timer restarting with count: " + m_timer ,1);
		} else if (timer == "advert") {
			a_timer = rand(ADVERT_TIMER_MIN, ADVERT_TIMER_MAX);
			_log("BNN advert timer restarting with count: " + a_timer, 1);
		}
	}

	protected dictionary makeBNNDict(string type) {
		// this method creates randomly-populated dictionaries for BNN Missions (0) and Adverts (1)
		if (type == "mission") {
			dictionary bnn_dict = {
				{"%activity", "the thing"},
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
		} 
		else if (type == "advert") {
			dictionary bnn_dict = {
				{"%company_name", "Bob Pizza"}
			};
		}
		return bnn_dict;
	}

	protected void newBNNAnnouncement(string type, dictionary a) {
		_log("making a thing now!", 1);
		notify(m_metagame, "BNN " + type, a);
	}

    protected string getBNNMissionType() {
        return "mission";
    }

    protected string getBNNAdvert() {
        return "advert";
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
		m_timer -= time;
		a_timer -= time;
		if (m_timer <= 0.0) {
			_log("mission timer expired. BNN announcement incoming", 1);
			//dictionary miDict = makeBNNDict("mission");
			dictionary miDict = {
				{"%activity", "the thing"},
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
			newBNNAnnouncement("mission", miDict);
			restartTimer("mission");
		} 
		if (a_timer <= 0.0) {
			_log("advert timer expired. BNN announcement incoming", 1);
			dictionary adDict = makeBNNDict("advert");
			newBNNAnnouncement("advert", adDict);
			restartTimer("advert");
		}
	}
	// ----------------------------------------------------
}


/*
// -------------------------------------------------------
void notify(const Metagame@ metagame, string key, dictionary@ replacements = dictionary(), string dict = "") {
	_log(" * notification message: " + key, 1);
	string command =
		"<command class='notify' dict='" + dict + "' key='" + key + "'>";

	command += handleReplacements(replacements);
	command += "</command>";

	metagame.getComms().send(command);
}
*/