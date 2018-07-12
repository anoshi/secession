// internal
#include "tracker.as"
#include "log.as"
#include "query_helpers.as"

// --------------------------------------------
class Overtime : Tracker {
	protected GameModeInvasion@ m_metagame;
	protected int m_factionId;
	protected bool m_started;
	protected float m_matchWinTimer;
	protected int m_matchWinner;
	protected float m_timer;
	protected float REFRESH_TIME = 10.0;
	protected float THRESHOLD = 80.0;

	// --------------------------------------------
	Overtime(GameModeInvasion@ metagame, int factionId) {
		@m_metagame = @metagame;
		m_factionId = factionId;
		m_started = false;
		m_matchWinTimer = 100000.0;
		m_matchWinner = -1;
		m_timer = 0.0;
	}

	// --------------------------------------------
	void start() {
		_log("starting Overtime tracker", 1);
		m_started = true;
		
		refresh();
	}

    // ----------------------------------------------------
	void update(float time) {
		// recheck every 10 seconds
		m_timer -= time;
		if (m_timer < 0.0) {
			refresh();
		}
	}

    // ----------------------------------------------------
	protected void refresh() {
		// query for game win timer 
		// if used to be higher than threshold and is now lower than threshold, decrease attacker faction capacities
		// if used to be lower than threshold and is now higher than threshold, set attacker faction capacities back to normal
	
		float lastWinTimer = m_matchWinTimer;
		int lastWinner = m_matchWinner;

		// query about bases
		const XmlElement@ general = getGeneralInfo(m_metagame);
		m_matchWinner = general.getIntAttribute("match_winner");
		m_matchWinTimer = general.getFloatAttribute("match_win_timer");
		_log("* " + m_matchWinTimer + " win timer, " + m_matchWinner + " about to win", 1);

		const array<Faction@>@ factions = m_metagame.getFactions();
		// if invalid winner, not set 
		if ((m_matchWinner < 0) ||
			// or if winner changed since last time
			(lastWinner != m_matchWinner) ||
			// or current winner is neutral
			(factions[m_matchWinner].isNeutral()) ||
			// or win time used to be below threshold, and now went back up
			(lastWinTimer <= THRESHOLD && m_matchWinTimer > THRESHOLD)) {

			// go back to default
			setLoserCapacityDefault();

			setAllDefaultMode();

		} else if (lastWinTimer > THRESHOLD && m_matchWinTimer <= THRESHOLD) {
			setLoserCapacityDown();

			setLoserOffensiveMode();
		}

		m_timer = REFRESH_TIME;
	}

	// ----------------------------------------------------
    protected void handleBaseOwnerChangeEvent(const XmlElement@ event) {
        // base_id
        // owner_id (faction)

		refresh();
    }

	// --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
		return m_started;
	}

	// --------------------------------------------
	void setLoserCapacityDown() {
		string command =
			"<command class='change_game_settings'>";
		
		for (uint i = 0; i < m_metagame.getFactions().size(); ++i) {
			Faction@ f = m_metagame.getFactions()[i];
			float multiplier = m_metagame.determineFinalFactionCapacityMultiplier(f, i);

			if (int(i) == m_matchWinner) {
				command +=
				"    <faction capacity_multiplier='" + multiplier + "' />";
			} else {
				// if capacity multiplier was 0 (neutral), it will continue to be
				float capacity = min(multiplier, 0.05);
				command +=
				"    <faction capacity_multiplier='" + capacity + "' />";
			}
		}

		command += 
			"</command>";

		m_metagame.getComms().send(command);

		// TODO: instead of using friendly id we could have this send messages to all factions
		// - would make the tracker usable in PvP too 

		if (m_factionId == m_matchWinner) {
			// player is winning
			sendFactionMessageKey(m_metagame, m_factionId, "overtime, we are winning");

		} else {
			// player is losing
			sendFactionMessageKey(m_metagame, m_factionId, "overtime, we are losing");
		}
	}

	// --------------------------------------------
	void setLoserCapacityDefault() {
		string command =
			"<command class='change_game_settings'>";
		
		for (uint i = 0; i < m_metagame.getFactions().size(); ++i) {
			Faction@ f = m_metagame.getFactions()[i];
			float multiplier = m_metagame.determineFinalFactionCapacityMultiplier(f, i);

			command +=
			"    <faction capacity_multiplier='" + multiplier + "' />";
		}

		command += 
			"</command>";

		m_metagame.getComms().send(command);
	}

	// --------------------------------------------
	void setAllDefaultMode() {
		for (uint i = 0; i < m_metagame.getFactions().size(); ++i) {
			applyDefaultMode(i);
		}
	}

	// --------------------------------------------
	void applyDefaultMode(int enemyId) {
		const array<Faction@>@ factions = m_metagame.getFactions();

		const XmlElement@ command = factions[enemyId].m_defaultCommanderAiCommand;
		m_metagame.getComms().send(command);
	}

	// --------------------------------------------
	void setLoserOffensiveMode() {
		for (uint i = 0; i < m_metagame.getFactions().size(); ++i) {
			if (int(i) != m_matchWinner) {
				applyOffensiveMode(i);
			} 
		}
	}

	// --------------------------------------------
	void applyOffensiveMode(int id) {
		string command =
			"<command class='commander_ai'" +
 			"       faction='" + id + "'" +
 			"       base_defense='0.0'" +
 			"       border_defense='0.0'>" +
        	        "</command>";
		m_metagame.getComms().send(command);
	}
}
