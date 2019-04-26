// internal
#include "gamemode.as"
//#include "user_settings_simple.as"
#include "user_settings.as"
#include "log.as"
#include "announce_task.as"
#include "query_helpers.as"

// generic trackers
#include "basic_command_handler.as"
#include "autosaver.as"
#include "looper.as"

// secession helpers
#include "secession_helpers.as"
#include "short_story.as"

// secession trackers
#include "bnn.as"
#include "quickie_call_handler.as"
#include "dummy_vehicle_handler.as"
#include "quickie_hitbox_handler.as"
// #include "story.as" // hey! play the campaign, punk :-P

// --------------------------------------------
class SecessionQuickie : GameMode {
	protected UserSettings@ m_userSettings;
	string m_gameMapPath = "";

	// --------------------------------------------
	SecessionQuickie(UserSettings@ settings) {
		super(settings.m_startServerCommand);
		@m_userSettings = @settings;
		_log("*** SECESSION : made it into SecessionQuickie constructor", 1);
	}

	// --------------------------------------------
	void init() {
		GameMode::init();

		if (m_userSettings.m_continue) {
			// loading a saved game?
			load();
			preBeginMatch();
			postBeginMatch();

		} else {
			// no, it's not a save game
			changeMap();
			sync();
			preBeginMatch();
			startMatch();
			postBeginMatch();
		}

		// add local player as admin for easy testing, hacks, etc
		if (!getAdminManager().isAdmin(getUserSettings().m_username)) {
			getAdminManager().addAdmin(getUserSettings().m_username);
		}
	}

	// --------------------------------------------
	void uninit() {
		save();
		GameMode::uninit();
	}

	// --------------------------------------------
	protected void changeMap() {
		// TODO: derive and implement
	}

	// --------------------------------------------
	protected void startMatch() {
		// TODO: derive and implement
	}

	// --------------------------------------------
	void postBeginMatch() {
		GameMode::postBeginMatch();

		updateGeneralInfo();
		save();

		addTracker(AutoSaver(this));
		addTracker(BasicCommandHandler(this));
		addTracker(Looper(this));

		// Secession handlers:
		addTracker(BNN(this));                  // Broadcast News Network Class and Methods
		addTracker(QuickieCallHandler(this));   // 'H' call menu and scripted call handler
		addTracker(QuickieHitboxHandler(this)); // Trigger area (hitbox) HitboxHandler Class and Methods
		addTracker(QuickieStory(this));         // NPC comms to player
		addTracker(DummyVehicleHandler(this));	// Performs tasks when (dummy) vehicles are destroyed

		_log("*** SECESSION: getting user settings: ", 1);
		getUserSettings();
		_log("*** SECESSION: got user settings", 1);
	}

	// --------------------------------------------
	protected void updateGeneralInfo() {
		const XmlElement@ general = getGeneralInfo(this);
		if (general !is null) {
			m_gameMapPath = general.getStringAttribute("map");
		}
	}

	// --------------------------------------------
	const UserSettings@ getUserSettings() const {
		return m_userSettings;
	}

	// --------------------------------------------
	void save() {
		_log("saving metagame", 1);

		XmlElement commandRoot("command");
		commandRoot.setStringAttribute("class", "save_data");

		XmlElement root("saved_metagame");
		XmlElement@ settings = m_userSettings.toXmlElement("settings");
		root.appendChild(settings);

		commandRoot.appendChild(root);
		getComms().send(commandRoot);
	}

	// --------------------------------------------
	void load() {
		_log("*** SECESSION: loading metagame", 1);

		XmlElement@ query = XmlElement(
			makeQuery(this, array<dictionary> = {
				dictionary = { {"TagName", "data"}, {"class", "saved_data"} } }));
		const XmlElement@ doc = getComms().query(query);

		if (doc !is null) {
			const XmlElement@ root = doc.getFirstChild();
			const XmlElement@ settings = root.getFirstElementByTagName("settings");
			if (settings !is null) {
				m_userSettings.fromXmlElement(settings);
				// set continue false now, so that complete restart (::init)
				// will properly execute start rather than load
				m_userSettings.m_continue = false;
			}

			m_userSettings.print();

			_log("loaded", 1);
		} else {
			_log("load failed");
		}
	}

	// --------------------------------------------
	protected void sync() {
		XmlElement@ query = XmlElement(makeQuery(this, array<dictionary> = {}));
		const XmlElement@ doc = getComms().query(query);
		getComms().clearQueue();
		resetTimer();
	}

	// --------------------------------------------
	const XmlElement@ queryLocalPlayer() const {
		array<const XmlElement@> players = getGenericObjectList(this, "players", "player");
		const XmlElement@ player = null;
		for (uint i = 0; i < players.size(); ++i) {
			const XmlElement@ info = players[i];

			string name = info.getStringAttribute("name");

			_log("player: " + name + ", target player is " + m_userSettings.m_username);
			if (name == m_userSettings.m_username) {
				_log("ok");
				@player = @info;
				break;
			} else {
				_log("no match");
			}
		}
		return player;
	}

	void setMapInfo(const MapInfo@ info) {
		m_mapInfo = info;
	}
}
