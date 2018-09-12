// internal
#include "tracker.as"
#include "gamemode.as"
#include "log.as"

// --------------------------------------------


// --------------------------------------------
class BNN : Tracker {
	protected GameMode@ m_metagame;

    protected float MISSION_TIMER_MAX = 36.00; //180
    protected float MISSION_TIMER_MIN = 18.00; //90
	protected float miTimer; // mission random timer
    protected float ADVERT_TIMER_MAX = 240.00;
    protected float ADVERT_TIMER_MIN = 120.00;
	protected float adTimer; // advert random timer
	protected array<string> activeTimers = {"mission", "advert"}; // stores the names of active timers
	protected dictionary bnn_dict;

	// one of each of the following arrays' strings is chosen at random to populate BNN missions
	protected array<string> actArr = {"The thing", "The stuff", "fun fun fun"};
	protected array<string> charArr = {"Dr. Evil", "Seymour Butts", "Harry Potter"};
	protected array<string> compArr = {"Uranus Proctology", "Udonis Noodles", "Pompeii Insurance", "ZEROGEE Sick Bags"};
	// location_pickup, location_drop, and location will be anywhere in a 1024 square area.
	// vicinity will be the name of the map area nearest to location
	// reward_amount will be a uint figure between 50 and 5000 - needs serious logic rules to set a relevant value to the mission and requestor
	protected array<string> rTypeArr = {"XP", "RP", "Weapon", "Armour", "Vehicle"};
	protected array<string> rEngageArr = {"Avoid", "Eliminate", "Rout", "Distract"};
	protected array<string> rLootArr = {"Allowed", "Discouraged", "Prohibited"};

	// ----------------------------------------------------
	BNN(GameMode@ metagame) {
		@m_metagame = @metagame;

		restartTimer("mission");
		restartTimer("advert");
	}

	protected void restartTimer(string timer) {
		if (timer == "mission") {
			miTimer = rand(MISSION_TIMER_MIN, MISSION_TIMER_MAX);
			_log("BNN mission timer restarting with count: " + miTimer ,1);
		} else if (timer == "advert") {
			adTimer = rand(ADVERT_TIMER_MIN, ADVERT_TIMER_MAX);
			_log("BNN advert timer restarting with count: " + adTimer, 1);
		}
	}

	protected dictionary makeBNNDict(string type) {
		// this method creates randomly-populated dictionaries for BNN Missions and Advertisments
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
		miTimer -= time;
		adTimer -= time;
		if (miTimer <= 0.0) {
			_log("mission timer expired. BNN announcement incoming", 1);
			//dictionary miDict = makeBNNDict("mission");
			dictionary miDict = {
				{"%activity", actArr[rand(0, actArr.size() -1)] },
				{"%character_name", charArr[rand(0, charArr.size() -1)] },
				{"%company_name", compArr[rand(0, compArr.size() -1)] }, 
				{"%location_pickup", rand(0, 1024) + ", " + rand(0,1024) },
				{"%location_drop", rand(0, 1024) + ", " + rand(0,1024) },
				{"%location", rand(0, 1024) + ", " + rand(0,1024) },
				{"%vicinity", "map_area name" },
				{"%reward_amount", rand(50, 5000) },
				{"%reward_type", rTypeArr[rand(0, rTypeArr.size() -1)] }, 
				{"%rule_engage", rEngageArr[rand(0, rEngageArr.size() -1)] },
				{"%rule_loot", rLootArr[rand(0, rLootArr.size() -1)] }
			};
			newBNNAnnouncement("mission", miDict);
			restartTimer("mission");
		} 
		if (adTimer <= 0.0) {
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