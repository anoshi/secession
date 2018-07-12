// --------------------------------------------
class VehicleHintConfig {
	string m_vehicleKey;
	string m_intelText; 
	string m_destroyedText; 
	int m_factionId;
	// mode = "region" or "base"
	string m_mode;
	bool m_makeSpotted;

	VehicleHintConfig(string vehicleKey, string intelText, string destroyedText, int factionId, string mode = "region", bool makeSpotted = false) {
		m_vehicleKey = vehicleKey;
		m_intelText = intelText;
		m_destroyedText = destroyedText;
		m_factionId = factionId;
		m_mode = mode; 
		m_makeSpotted = makeSpotted;
	}
}
