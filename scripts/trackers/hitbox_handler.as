// internal
#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "announce_task.as"
#include "query_helpers.as"
#include "secession_helpers.as"
// --------------------------------------------


// --------------------------------------------
class HitboxHandler : Tracker {
	//protected Metagame@ m_metagame;
	protected GameMode@ m_metagame;

	// ----------------------------------------------------
	HitboxHandler(GameMode@ metagame) {
	//HitboxHandler(Metagame@ metagame) {}
		@m_metagame = @metagame;
		getTriggerHitboxes(m_metagame);
	}

	protected array<const XmlElement@>@ getTriggerHitboxes(const Metagame@ metagame) {
		_log("running getTriggerHitboxes", 1);
		XmlElement@ query = XmlElement(
			makeQuery(metagame, array<dictionary> = {
				dictionary = { {"TagName", "data"}, {"class", "hitboxes"} } }));

		const XmlElement@ doc = metagame.getComms().query(query);
		array<const XmlElement@> triggerList = doc.getElementsByTagName("hitbox");

		for (uint i = 0; i < triggerList.size(); ++i) {
			const XmlElement@ hitboxNode = triggerList[i];
			string id = hitboxNode.getStringAttribute("id");
			if (startsWith(id, "hitbox_trigger")) {
				_log("including " + id, 1);
			} else {
				triggerList.erase(i);
				i--;
			}
		}
		_log("* " + triggerList.size() + " trigger areas found", 1);
		return triggerList;
	}

	protected void handleHitboxEvent(const XmlElement@ event) {
	// variablise hitbox event attributes
		//string phase = event.getStringAttribute("phase");
		//string sChar = event.getStringAttribute("character_id");
		//int iChar = event.getIntAttribute("character_id");
		//string sCall = event.getStringAttribute("call_key");
		//string sPosi = event.getStringAttribute("target_position");
		//Vector3 v3Posi = stringToVector3(event.getStringAttribute("target_position"));
		//const XmlElement@ char = getCharacterInfo(m_metagame, iChar);
		//return getGenericObjectInfo(metagame, "character", characterId);

		_log("hitbox event triggered, into hitbox_handler: ", 1);
	}
	// --------------------------------------------
	/*
	// --------------------------------------------
	void init() {
	}
	// --------------------------------------------
	void start() {
	}
	*/
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
}
