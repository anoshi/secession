// internal
#include "tracker.as"
#include "gamemode.as"
#include "log.as"

// --------------------------------------------


// --------------------------------------------
class Story : Tracker {
	protected GameModeInvasion@ m_metagame;

    protected float STORY_DELAY_MAX = 10.00; //180.00;
    protected float STORY_DELAY_MIN = 5.00; //90.00;
	protected float storyDelay; // randomise time between story delivery
	protected dictionary story_dict;
	protected int m_playerCharacterId;

	// ----------------------------------------------------
	Story(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
		queueStoryItem(); // start the countdown to next story item reveal
	}

	protected void queueStoryItem() {
		storyDelay = rand(STORY_DELAY_MIN, STORY_DELAY_MAX);
		_log("*** SECESSION Story continues in: " + storyDelay + " seconds." ,1);
	}

	protected void tellNextStoryItem() {

		string storyKey = "story_1";
		dictionary a = {};

		// What is the player character's Id?
		const XmlElement@ player = m_metagame.queryLocalPlayer();
		int playerCharId = player.getIntAttribute("character_id");
		// what is the player character's position?
		const XmlElement@ playerInfo = getCharacterInfo(m_metagame, playerCharId);
		Vector3 playerPos = stringToVector3(playerInfo.getStringAttribute("position"));
		// find nearby friendlies
		array<const XmlElement@> friendlyChars = getCharactersNearPosition(m_metagame, playerPos, 0, 10.0f);
		// have one of them say the next line of the story
		_log("*** SECESSION: found " + friendlyChars.size() + " friendlies near player character!", 1);
		uint friendlyCharId = friendlyChars[rand(0, friendlyChars.size() -1)].getIntAttribute("id");
		const XmlElement@ friendlyCharInfo = getCharacterInfo(m_metagame, friendlyCharId);
		_log("*** SECESSION: character ID " + friendlyCharId + " about to say a story item!", 1);
		sendFactionMessageKeySaidAsCharacter(m_metagame, 0, friendlyCharId, storyKey, a);
		// update the reference var to where the player is at in the story (persist beyond saves)
	}

	// /////////////////////// //
	// Get player character ID //
	// /////////////////////// //
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
		_log("** SECESSION Story::handlePlayerSpawnEvent", 1);

		const XmlElement@ element = event.getFirstElementByTagName("player");
		string name = element.getStringAttribute("name");
		if (name == m_metagame.getUserSettings().m_username) {
			m_playerCharacterId = element.getIntAttribute("character_id");
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

	// --------------------------------------------
	void update(float time) {
		storyDelay -= time;
		if (storyDelay <= 0.0) {
			_log("*** SECESSION story update incoming!", 1);
			tellNextStoryItem();
			queueStoryItem();
		}
	}
	// ----------------------------------------------------
}
