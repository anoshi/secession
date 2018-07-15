// internal
#include "log.as"
#include "helpers.as"
#include "comms.as"
#include "task_sequencer.as"
#include "map_info.as"
#include "admin_manager.as"

// generic trackers
#include "ban_manager.as"

//TODO: #include "trackers/chat_logger.as"

// --------------------------------------------
class Metagame {
	protected Comms@ m_comms;
	protected TaskSequencer@ m_taskSequencer;
	protected MapInfo m_mapInfo;

	protected array<Tracker@> m_trackers;
	protected bool m_restartRequested;

	protected AdminManager@ m_adminManager;
	protected BanManager@ m_banManager;

	protected string m_startServerCommand;

	//protected m_chatLogger;

	// --------------------------------------------
	Metagame(string startServerCommand = "") {
		
		@m_adminManager = AdminManager(this);

		m_startServerCommand = startServerCommand;

		@m_comms = Comms();

		if (isInServerMode()) {
			startServer();
			getAdminManager().loadFromFile();
		}

		/*
		// TODO:
			$this->chat_logger = new ChatLogger($this);
		}
		*/
	}

	// --------------------------------------------
	void init() {
		clearTrackers();

		@m_taskSequencer = TaskSequencer();
		resetTimer();
	}

	// --------------------------------------------
	Comms@ getComms() const {
		return m_comms;
	}

	// --------------------------------------------
	TaskSequencer@ getTaskSequencer() const {
		return m_taskSequencer;
	}

	// --------------------------------------------
	void resetTimer() {
		float dummy = now();
	}

	// --------------------------------------------
	void run() {
		const float TARGET_CYCLE_TIME = 0.5f;
		const float MINIMUM_SLEEP_TIME = 0.010f;
		float dummy = now();
		bool processed = false;
		while (true) {
			{
				float elapsedTime = now();
				update(elapsedTime);

				float sleepTime = MINIMUM_SLEEP_TIME;
				if (!processed) {
					sleepTime = TARGET_CYCLE_TIME - elapsedTime;
				}

				if (sleepTime > 0.0f) {
					sleep(sleepTime);
				}
			}

			processed = false;
			const XmlElement@ event = m_comms.receive();
			if (!event.empty() && event.getName() != "dummy_event") {
				if (m_trackers.size() > 0) {
					processed = true;
					if (event.getName() == "user_quit_event") {
						_log("user quit signal detected, stopping script", -1);
						break;
					}

					// inform all trackers about the event
					for (uint i = 0; i < m_trackers.size(); ++i) {
						Tracker@ tracker = m_trackers[i];
						tracker.handleEvent(event);
					}
				} else {
					_log("no event tracker registered, skipping message", 1);
				}
			}

			if (m_restartRequested) {
				m_restartRequested = false;
				_log("restart had been requested, calling metagame init now", -1);
				init();
			}
		}
	}

	// --------------------------------------------
	void uninit() {
		_log("uninitializing", -1);
	}

	// --------------------------------------------
	void preBeginMatch() {		
		m_taskSequencer.clear();
		clearTrackers();

		if (isInServerMode()) {
			// recreated every match begin, it's fine
			addTracker(BanManager(this));
			getAdminManager().loadFromFile();
		}

		/*
		// TODO
			if ($this->chat_logger) {
				$this->add_tracker($this->chat_logger);
			}
			*/
	}

	// --------------------------------------------
	bool isInServerMode() {
		return m_startServerCommand != "";
	}

	// --------------------------------------------
	protected void startServer() {
		if (m_startServerCommand != "") {
			getComms().send(m_startServerCommand);
		} else {
			_log("not starting server", 1);
		}
	}

	// --------------------------------------------
	void postBeginMatch() {
	}

	// --------------------------------------------
	void addTracker(Tracker@ tracker) {
		m_trackers.insertLast(tracker);
		tracker.onAdd();
		_log("tracker added, count " + m_trackers.size(), 1);
	}

	// --------------------------------------------
	protected void clearTrackers() {
		for (uint i = 0; i < m_trackers.size(); ++i) {
			Tracker@ tracker = m_trackers[i];
			tracker.onRemove();
		}
		m_trackers.resize(0);
		_log("tracker cleared, count " + m_trackers.size(), 1);
	}

	// --------------------------------------------
	protected void trackerCompleted(Tracker@ tracker) {
		// by default, nothing to do here
	}

	// --------------------------------------------
	protected void update(float time) {
		m_taskSequencer.update(time);

		// maintain trackers
		for (uint i = 0; i < m_trackers.size(); ++i) {
			Tracker@ tracker = m_trackers[i];

			// track passed time here and feed it to tracker, trackers can then
			// use if for updating timers and looking out for expiration to trigger stuff
			//

			// windows + PHP + named pipes (+ the fact that PHP thread support is less than perfect) 
			// has one issue:
			// - we need to pulse dummy events from the server to keep the script not blocking at
			//   checking if there's anything to read in the input pipe
			// - the pulses come in at max 1 second intervals, so the script won't update itself faster
			//   than that except when other events happen to come in

			if (!tracker.hasStarted()) {
				tracker.start();
			}

			if (tracker.hasStarted()) {
				tracker.update(time);
			}

			if (tracker.hasEnded()) {
				trackerCompleted(tracker);
				_log("tracker " + i + " ended, removing from list", 1);

				// cleanup
				removeTrackerByKey(i);
				i--;
			}
		}
	}

	// --------------------------------------------
	protected void removeTrackerByKey(int i) {
		Tracker@ tracker = m_trackers[i];
		m_trackers.removeAt(i);
		tracker.onRemove();
	}

	// --------------------------------------------
	void removeTracker(Tracker@ tracker) {
		int i = m_trackers.findByRef(tracker);
		if (i != -1) {
			removeTrackerByKey(i);
		}
	}

	// --------------------------------------------
	void requestRestart() {
		_log("request_restart", 1);
		m_restartRequested = true;
	}

	// --------------------------------------------
	AdminManager@ getAdminManager() const {
		return m_adminManager;
	}

	// --------------------------------------------
	string getRegion(const Vector3@ pos) const {
		return ::getRegion(pos, m_mapInfo);
	}
}

