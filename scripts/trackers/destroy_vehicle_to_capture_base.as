// internal
#include "tracker.as"
#include "log.as"
#include "query_helpers.as"

// --------------------------------------------
class DestroyVehicleToCaptureBase : Tracker {
	protected Metagame@ m_metagame;
	protected string m_vehicleKey;
	protected int m_capturerFaction;

	// ----------------------------------------------------
	DestroyVehicleToCaptureBase(Metagame@ metagame, string vehicleKey, int capturerFaction) {
		@m_metagame = @metagame;
		m_vehicleKey = vehicleKey;
		m_capturerFaction = capturerFaction;
	}

	// ----------------------------------------------------
	bool hasStarted() const {
		return true;
	}

	// ----------------------------------------------------
	bool hasEnded() const {
		return false;
	}

	// ----------------------------------------------------
	protected void handleVehicleDestroyEvent(const XmlElement@ event) {
		// vehicle_id
		_log("handleVehicleDestroyEvent in destroy_vehicle_to_capture_base.as fired", 1);
		string key = event.getStringAttribute("vehicle_key");
		if (key == m_vehicleKey) {
			_log("DestroyVehicleToCaptureBase, vehicle being destroyed, key " + key, 1);

			int baseId = -1;
			Vector3 position = stringToVector3(event.getStringAttribute("position"));
			float distance = -1.0;
			const XmlElement@ baseInfo = getClosestBase(m_metagame, position, distance);
			if (baseInfo !is null) {
				baseId = baseInfo.getIntAttribute("id");
			} else {
				_log("DestroyVehicleToCaptureBase, ERROR, closest base not found for position " + position.toString(), -1);
			}

			if (baseId >= 0) {
				// capture the base
				int owner = m_capturerFaction;
				// capture the associated base now
				string command = "<command class='update_base'" +
					"	base_id='" + baseId + "' " +
					"	owner_id='" + owner + "' />";
				m_metagame.getComms().send(command);

			} else {
				_log("DestroyVehicleToCaptureBase, ERROR, couldn't resolve base id for the vehicle", -1);
			}
		}
	}
}
