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

	_log("* SECESSION getVehiclesNearPosition running", 1);

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
		_log("working on vehicle: " + id + " (" + sKey + ") ", 1);
		if (checkRange(position, curVehPos, range) ) {
			// we should never need to know where the decoration vehicles are.
			if ( startsWith(sKey, "deco_") || startsWith(sKey, "dumpster") ) {
				allVehicles.erase(i);
				i--;
				_log("removed vehicle " + id + " (decoration) from list.", 1);
			} else {
				vehNearPos.insertLast(curVeh);
				_log("vehicle: " + id + " (" + sName + ") is within desired range. Adding.", 1);
			}
		}
	}

	return vehNearPos;
}

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
const XmlElement@ getExtCharacterInfo(const Metagame@ metagame, int characterId) {
	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "character"}, {"id", characterId}, {"include_equipment", 1}}}));

	const XmlElement@ doc = metagame.getComms().query(query);
	return doc.getFirstElementByTagName("character"); //.getElementsByTagName("item")
}
const XmlElement@ characterInfo = getExtCharacterInfo(m_metagame, characterId);
array<const XmlElement@>@ equipment = characterInfo.getElementsByTagName("item");

	string primary = equipment[0].getStringAttribute("key");
	string secondary = equipment[1].getStringAttribute("key");
	string throwable = equipment[2].getStringAttribute("key");
	string carry = equipment[4].getStringAttribute("key");
*/