// internal
#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "query_helpers.as"
#include "secession_helpers.as"
// --------------------------------------------


// --------------------------------------------
class CharacterLifecycleHandler : Tracker {
	protected Cabal@ m_metagame;

	protected int m_playerCharacterId;
    protected float m_localPlayerCheckTimer;
    protected float LOCAL_PLAYER_CHECK_TIME = 5.0;

	// ----------------------------------------------------
	CharacterLifecycleHandler(Cabal@ metagame) {
		@m_metagame = @metagame;

        // enable character kill tracking for cabal game mode (off by default)
        string trackCharDeath = "<command class='set_metagame_event' name='character_die' enabled='1' />";
        m_metagame.getComms().send(trackCharDeath);
	}

	//////////////////////////////
	// ALL CHARACTER LIFECYCLES //
	//////////////////////////////
    protected void handleCharacterDieEvent(const XmlElement@ event) {
		// TagName					string (character_die)
		// character_id				int (character who dropped the item)

		// TagName					string (character)
		// id						int (character's id)
		// name						string (First Last)
		// position					string (xxx.xxx yy.yyy zzz.zzz)
		// block					string (AA BB)
		// dead						int (0 / 1)
		// wounded					int (0 / 1)
		// faction_id				int (0 .. num factions -1)
		// xp						real
		// rp						int
		// leader					int (0 / 1)
		// player_id				int (-1 (not a player), 0 (a player))

        _log("*** CABAL: handleCharacterDieEvent fired!", 1);
		// don't process if not properly started
		//if (!hasStarted()) return;

		int charId = event.getIntAttribute("character_id");
		// const XmlElement@ deadCharInfo = getCharacterInfo(m_metagame, charId);
		const XmlElement@ deadCharInfo = event.getFirstElementByTagName("character");

		// make sure they're dead (sanity)
		if (deadCharInfo.getIntAttribute("dead") != 1) {
			_log("*** CABAL: character is not dead. Ignoring", 1);
			return;
		}

        // _log("*** CABAL: store details of dead character " + charId, 1);
		charId = deadCharInfo.getIntAttribute("id");
		string charName = deadCharInfo.getStringAttribute("name");
        string charPos = deadCharInfo.getStringAttribute("position");
		Vector3 v3charPos = stringToVector3(charPos);

		string charBlock = deadCharInfo.getStringAttribute("block");
		int charFactionId = deadCharInfo.getIntAttribute("faction_id");

		float charXP = deadCharInfo.getFloatAttribute("xp");
		int charRP = deadCharInfo.getIntAttribute("rp");
		int charLeader = deadCharInfo.getIntAttribute("leader");
		_log("*** CABAL: Character " + charId + " (" + charName + "), with " + charXP + " XP, has died.", 1);

		// _log("*** CABAL: store player character's info", 1);
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, 0); // this may not work in all cases. Coop: player IDs?
		int playerCharId = playerInfo.getIntAttribute("character_id");
		const XmlElement@ playerCharInfo = getCharacterInfo(m_metagame, playerCharId);
		string playerPos = playerCharInfo.getStringAttribute("position");
        _log("*** CABAL: Player Character id: " + m_playerCharacterId + " is at: " + playerPos);
		Vector3 v3playerPos = stringToVector3(playerPos);


		// create a new Vector3 as (enemyX, playerY +2, playerZ)
		//float retX = v3charPos.get_opIndex(0);
		float retX = v3charPos.get_opIndex(0);
        float retY = v3playerPos.get_opIndex(1) + 2.0;
        float retZ = v3playerPos.get_opIndex(2);
        Vector3 dropPos = Vector3(retX, retY, retZ);

		// based on these details, set a probability for a weapon/power-up/etc. to spawn
		// between the invisible walls the the player character is locked within (enemyX, playerY+2, playerZ)

        _log("*** CABAL: dropping an item at " + dropPos.toString(),1);
        string creator = "<command class='create_instance' faction_id='0' position='" + dropPos.toString() + "' instance_class='carry_item' instance_key='commstech_radio_1.carry_item' />";
		// ^ hard coded to drop a commstech_radio_1.carry_item for now. randomise...
        m_metagame.getComms().send(creator);
		_log("*** CABAL: item placed at " + dropPos.toString(),1);

		// ensure all dropped items have a short TTL e.g 5 seconds
        // ensure only rare weapons are dropped
	}

	/////////////////////////////////
	// PLAYER CHARACTER LIFECYCLES //
	/////////////////////////////////
    protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		_log("*** CABAL: CharacterLifecycleHandler::handlePlayerSpawnEvent", 1);

		// how can this be improved to support 2-player co-op play?
		// currently falls apart if a second player were to spawn.

		const XmlElement@ element = event.getFirstElementByTagName("player");
		string name = element.getStringAttribute("name");
		_log("*** CABAL: player " + name + " spawned.", 1);
		if (m_playerCharacterId < 0) {
			m_playerCharacterId = element.getIntAttribute("character_id");
		}
		_log("*** CABAL: player character id is: " + m_playerCharacterId, 1);
	}

	// ----------------------------------------------------
	protected void handlePlayerDieEvent(const XmlElement@ event) {
		_log("*** CABAL: CharacterLifecycleHandler::handlePlayerDieEvent", 1);

		// decrement lives left

		// tidy up assets

		// reset stuffs as required

		// end game if 0 lives left

	}

	// ----------------------------------------------------
	protected void ensureValidLocalPlayer(float time) {
		if (m_playerCharacterId < 0) {
			m_localPlayerCheckTimer -= time;
			_log("*** CABAL: m_local_PlayerCheckTimer: " + m_localPlayerCheckTimer,1);
			if (m_localPlayerCheckTimer < 0.0) {
				_log("*** CABAL: tracked player character id " + m_playerCharacterId, 1);
				const XmlElement@ player = m_metagame.queryLocalPlayer();
				if (player !is null) {
					//setupCharacterForTracking
				} else {
					_log("WARNING, local player query failed", -1);
				}
				m_localPlayerCheckTimer = LOCAL_PLAYER_CHECK_TIME;
			}
		}
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

    // ----------------------------------------------------
    void update(float time) {
        ensureValidLocalPlayer(time);

		// Every so often we may want to clear the battlefield
		// _log("*** CABAL: removing dead characters from play", 1);
    }
}
