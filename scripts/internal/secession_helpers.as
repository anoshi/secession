// internal
#include "comms.as"
#include "metagame.as"
#include "resource.as"

/////////////////////////////////////////
// ----- BEGIN SECESSION HELPERS ----- //
/////////////////////////////////////////

///////////////////////////
// ----- BIG DICTS ----- //
///////////////////////////
dictionary bnn_dict = {
	{"%activity", "call_handler the thing"},
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

/*
dictionary veh_stats = {
	{'veh_speeder.vehicle', dictionary = {{'max_health', 2.4}, {'ab', 2}} },
    {'lc_jeep.vehicle', dictionary = {{'max_health', 1}, {'bb', 2}} },
	{'veh_terminal.vehicle', dictionary = {{'max_health', 23.0} {'cc', 3}} }
};
*/

////////////////////////////////
// ----- GLOBAL METHODS ----- //
////////////////////////////////
array<const XmlElement@>@ getVehiclesNearPosition(const Metagame@ metagame, const Vector3@ position, int factionId, float range = 25.00f) {
	array<const XmlElement@> allVehicles;
	array<const XmlElement@> vehNearPos;

	_log("*** SECESSION getVehiclesNearPosition running", 1);

// querying 'vehicles' doesn't support a range variable, like 'characters' does.
// Must grab all vehicles and check their proximity to event, in turn.

	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "vehicles"}, {"faction_id", factionId},
						   {"position", position.toString()} } }));

	const XmlElement@ doc = metagame.getComms().query(query);
	allVehicles = doc.getElementsByTagName("vehicle");

	for (uint i = 0; i < allVehicles.size(); ++i) {
		const XmlElement@ curVeh = allVehicles[i];
		int id = curVeh.getIntAttribute("id");
		const XmlElement@ vehInfo = getVehicleInfo(metagame, id);
		int vType = vehInfo.getIntAttribute("type_id");
		string sName = vehInfo.getStringAttribute("name");
		string sKey = vehInfo.getStringAttribute("key");
		Vector3 curVehPos = stringToVector3(vehInfo.getStringAttribute("position"));
		_log("*** SECESSION: working on vehicle: " + id + " (" + sKey + ") ", 1);
		if (checkRange(position, curVehPos, range) ) {
			// we should never need to know where the decoration vehicles are.
			if ( startsWith(sKey, "deco_") || startsWith(sKey, "dumpster") ) {
				allVehicles.erase(i);
				i--;
				_log("*** SECESSION: removed vehicle " + id + " (decoration) from list.", 1);
			} else {
				vehNearPos.insertLast(curVeh);
				_log("*** SECESSION: vehicle: " + id + " (" + sName + ") is within desired range. Adding.", 1);
			}
		}
	}

	return vehNearPos;
}

// --------------------//
// Commander Greetings //
// --------------------//
void commanderGreeting(const Metagame@ metagame) {

	array<const XmlElement@> allFactions;

	_log("*** SECESSION commanderGreeting running", 1);

	// borrowed from scripts/invasion/map_rotator_invasion.as
	// commander jumps on the airwaves and tells the player about what's happening
	// first we pull some info about the player character's location and the level's state in general
	string baseName = "one of the bases";
	string factionName = "unknown faction";
	int numFactions;

	XmlElement@ factionData = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "factions"} }
		})
	);
	const XmlElement@ factionDoc = metagame.getComms().query(factionData);
	allFactions = factionDoc.getElementsByTagName("faction");

	numFactions = allFactions.size();

	_log("*** SECESSION: " + numFactions + " factions", 1);

	//const XmlElement@ base = getStartingBase(m_metagame, 0);
	//	if (base !is null) {
	//		baseName = base.getStringAttribute("name");
	//	}

	dictionary a = {
		//{"%map_name", stage.m_mapInfo.m_name},
		{"%base_name", baseName},
		{"%faction_name", factionName}
		//{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
	};

	/*
	// commander says something
	m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 2.0, 0, "quickmatch commander greeting", a));

	/*
	// capture map?
	if (stage.isCapture()) {
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 6.0, 0, "map start with 1 base, capture", a));

	} else if (stage.isKoth()) {
		// koth map?
		a["%target_base_name"] = stage.m_kothTargetBase;
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 6.0, 0, "map start with 1 base, koth", a));
	}

	// side objectives?
	if (stage.hasSideObjectives()) {
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "side objectives", a));
	}

	// intel objectives
	if (stage.hasIntelManager()) {
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "intel objectives", a));
	}

	// loot / cargo trucks?
	if (stage.hasLootObjective()) {
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "loot objective", a));
	}

	// radio tower / truck?
	if (stage.hasRadioObjective()) {
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "radio tower or truck objective", a));
	}

	// aa?
	if (hasAaObjective()) {
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "aa objective", a));
	}

	m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 0.0, 0, "map start, ending", a));

	// finally enable "in game commander" radio, battle and event reports
	m_metagame.getTaskSequencer().add(CallFloat(CALL_FLOAT(this.setCommanderAiReports), 1.0));
	*/
}

/*
void setCommanderAiReports(float percentage) {
	string command =
		"<command\n" +
		"  class='commander_ai'" +
		"  faction='0'" +
		"  commander_radio_reports='" + percentage + "'>" +
		"</command>\n";
	m_metagame.getComms().send(command);
}
*/

///////////////////////////////
// ----- TRIGGER AREAS ----- //
///////////////////////////////
array<const XmlElement@>@ getTriggerAreas(const Metagame@ metagame) {
	_log("** GET TRIGGER AREAS", 1);
	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "hitboxes"} } }));

	const XmlElement@ doc = metagame.getComms().query(query);
	array<const XmlElement@> triggerAreas = doc.getElementsByTagName("hitbox");
	return triggerAreas;
}

// -------------------------------------------------------
void associateTriggerAreas(const Metagame@ metagame, const array<const XmlElement@>@ armoryList, string instanceType, int instanceId, array<string>@ trackedTriggerAreas) {
	array<string> addIds;
	_log("** SECESSION FEEDING associateTriggerAreasEx instanceType: " + instanceType + ", instanceId: " + instanceId, 1);
	associateTriggerAreasEx(metagame, armoryList, instanceType, instanceId, trackedTriggerAreas, addIds);
}

// -------------------------------------------------------
void associateTriggerAreasEx(const Metagame@ metagame, const array<const XmlElement@>@ armoryList, string instanceType, int instanceId, array<string>@ trackedTriggerAreas, array<string>@ addIds) {
	_log("** ASSOCIATING TRIGGER AREAS", 1);
	if (instanceId < 0) return;

	// check against already associated triggerAreas
	// and determine which need to be added or removed
	_log("** SECESSION trackedTriggerAreas contains: ", 1);
	for (uint i = 0; i < trackedTriggerAreas.size(); ++i) {
		_log("** trackedTriggerAreas " + i + ": " + trackedTriggerAreas[i], 1);
	}

	// prepare to remove all triggerAreas
	array<string> removeIds = trackedTriggerAreas;

	for (uint i = 0; i < armoryList.size(); ++i) {
		const XmlElement@ armory = armoryList[i];
		string armoryId = armory.getStringAttribute("id");

		int index = removeIds.find(armoryId);
		if (index >= 0) {
			// already tracked and still needed
			// remove from ids to remove
			removeIds.erase(index);
		} else {
			// not yet tracked, needs to be added
			addIds.push_back(armoryId);
		}
	}

	for (uint i = 0; i < removeIds.size(); ++i) {
		string id = removeIds[i];
		string command = "<command class='remove_hitbox_check' id='" + id + "' instance_type='" + instanceType + "' instance_id='" + instanceId + "' />";
		metagame.getComms().send(command);
		_log("** REMOVED instanceType: " + instanceType + ", instanceId: " + instanceId + " from trackedTriggerAreas." ,1);
		trackedTriggerAreas.erase(trackedTriggerAreas.find(id));
	}

	for (uint i = 0; i < addIds.size(); ++i) {
		string id = addIds[i];
		string command = "<command class='add_hitbox_check' id='" + id + "' instance_type='" + instanceType + "' instance_id='" + instanceId + "' />";
		metagame.getComms().send(command);
		_log("** ADDED instanceType: " + instanceType + ", instanceId: " + instanceId + " to trackedTriggerAreas." ,1);
		trackedTriggerAreas.push_back(id);
	}
}

// ----------------------------------------------------
void clearTriggerAreaAssociations(const Metagame@ metagame, string instanceType, int instanceId, array<string>@ trackedTriggerAreas) {
	if (instanceId < 0) return;

	// remove all tracked triggerAreas
	for (uint i = 0; i < trackedTriggerAreas.size(); ++i) {
		string id = trackedTriggerAreas[i];
		string command = "<command class='remove_hitbox_check' id='" + id + "' instance_type='" + instanceType + "' instance_id='" + instanceId + "' />";
		metagame.getComms().send(command);
		_log("** SECESSION query_helpers clearTriggerAreaAssociations has run", 1);
		//refreshTriggerAreas(metagame, triggerIds, instanceId);
	}

	trackedTriggerAreas.clear();
}

///////////////////////
// ----- CALLS ----- //
///////////////////////
// BC Hot Potato Position Tracker
string hpPosition; // global var lols

void setHotPotPosi(string pos) {
	hpPosition = pos;
	_log("Hot Potato now at: " + hpPosition, 1);
}

string getHotPotPosi() {
	return hpPosition;
}



///////////////////////////////////////
// ----- END SECESSION HELPERS ----- //
///////////////////////////////////////

/*
// --------------------------------------------------------
const XmlElement@ getExtraCharacterInfo(const Metagame@ metagame, int characterId) {
	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "character"}, {"id", characterId}, {"include_equipment", 1}}}));

	const XmlElement@ doc = metagame.getComms().query(query);
	return doc.getFirstElementByTagName("character"); //.getElementsByTagName("item")
}
const XmlElement@ characterInfo = getExtraCharacterInfo(m_metagame, characterId);
array<const XmlElement@>@ equipment = characterInfo.getElementsByTagName("item");

	string primary = equipment[0].getStringAttribute("key");
	string secondary = equipment[1].getStringAttribute("key");
	string throwable = equipment[2].getStringAttribute("key");
	string carry = equipment[4].getStringAttribute("key");
*/
