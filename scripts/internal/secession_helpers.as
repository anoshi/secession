// internal
#include "comms.as"
#include "metagame.as"
#include "resource.as"

// --------------------------------------------------------
// BEGIN SECESSION HELPERS
// --------------------------------------------------------
array<const XmlElement@>@ getVehiclesNearPosition(const Metagame@ metagame, const Vector3@ position, int factionId, float range = 25.00f) {
	array<const XmlElement@> allVehicles;
	array<const XmlElement@> vehNearPos;

	_log("* getVehiclesNearPosition running", 1);

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

// BC Hot Potato Position Tracker
string hpPosition;
void setHotPotPosi(string pos) {
	hpPosition = pos;
	_log("Hot Potato now at: " + hpPosition, 1);
}

string getHotPotPosi() {
	return hpPosition;
}

// --------------------------------------------
// END SECESSION HELPERS
// --------------------------------------------