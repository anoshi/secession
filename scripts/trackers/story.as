// internal
#include "tracker.as"
#include "gamemode.as"
#include "log.as"

// --------------------------------------------


// --------------------------------------------
class Story : Tracker {
	protected GameModeInvasion@ m_metagame;

    protected float STORY_DELAY_MAX = 50.00; //180.00;
    protected float STORY_DELAY_MIN = 25.00; //90.00;
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
		_log("** SECESSION Story continues in: " + storyDelay + " seconds." ,1);
	}

	protected void tellNextStoryItem() {

		// hard-coded list for now. Become a per-faction, tracked list with current, next (and branching story arc logic)?
		string storyKey = "story_1";
		dictionary a = {
			// format: {"%text_replacement_key", textReplacementValue},
			// {"%another_key", some_array_of_text_items[rand(0, some_array_of_text_items.size() -1)]},
			// {"%mission_goal", anyMissionGoal(faction_name)}, // <-- might even work
			// {"%last_key", "bye bye"}
			{"%mission_goal", anyMissionGoal()}
		};

		// What is the player character's Id?
		const XmlElement@ player = m_metagame.queryLocalPlayer();
		int playerCharId = player.getIntAttribute("character_id");
		// what is the player character's position?
		const XmlElement@ playerInfo = getCharacterInfo(m_metagame, playerCharId);
		if (playerInfo.getIntAttribute("wounded") != 1 && playerInfo.getIntAttribute("dead") != 1) {
			_log("** SECESSION: player is alive, tell more story");
			Vector3 playerPos = stringToVector3(playerInfo.getStringAttribute("position"));
			// find nearby friendlies
			array<const XmlElement@> friendlyChars = getCharactersNearPosition(m_metagame, playerPos, 0, 10.0f);
			if (friendlyChars.size() > 0) { // pc and inanimate objects won't continue the story
				for (uint fc = 0; fc < friendlyChars.size(); ++fc) {
					if ((friendlyChars[fc].getIntAttribute("id") == playerCharId) || (friendlyChars[fc].getStringAttribute("soldier_group_name") == "empl_turret")) {
						friendlyChars.erase(fc);
					}
				}
			}
			if (friendlyChars.size() > 0) { // anyone left nearby?
				_log("** SECESSION: found " + friendlyChars.size() + " friendlies near player character!", 1);
				// have one of them say the next line of the story
				uint friendlyCharId = friendlyChars[rand(0, friendlyChars.size() -1)].getIntAttribute("id");
				const XmlElement@ friendlyCharInfo = getCharacterInfo(m_metagame, friendlyCharId);
				_log("** SECESSION: character ID " + friendlyCharId + " about to say a story item!", 1);
				sendFactionMessageKeySaidAsCharacter(m_metagame, 0, friendlyCharId, storyKey, a);
				// update the reference var to where the player is at in the story (persist beyond saves)
			}
		}
	}

	protected string anyMissionGoal() {
		array<string> missionGoals = {"fun", "NOFUN", "MANY WOW", "such adventure"};
		return missionGoals[rand(0, missionGoals.size() -1)];
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
			_log("** SECESSION story update incoming!", 1);
			tellNextStoryItem();
			queueStoryItem();
		}
	}
	// ----------------------------------------------------
}
