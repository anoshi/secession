// internal
#include "comms.as"
#include "metagame.as"
#include "resource.as"

// --------------------------------------------------------
array<const XmlElement@>@ getVehiclesNearPosition(const Metagame@ metagame, const Vector3@ position, int factionId) {
	array<const XmlElement@> vehicles;

	XmlElement@ query = XmlElement(
		makeQuery(metagame, array<dictionary> = {
			dictionary = { {"TagName", "data"}, {"class", "vehicles"}, {"faction_id", factionId},
						   {"position", position.toString()} } }));

	const XmlElement@ doc = metagame.getComms().query(query);
	vehicles = doc.getElementsByTagName("vehicle");

	return vehicles;
}
// --------------------------------------------------------

// BEGIN SECESSION HELPERS
// BC Hot Potato Position Tracker
string hpPosition;
void setHotPotPosi(string pos) {
	hpPosition = pos;
	_log("Hot Potato now at: " + hpPosition, 1);
}
string getHotPotPosi() {
	return hpPosition;
}

// END SECESSION HELPERS
// --------------------------------------------