#include "gamemode_invasion.as"
#include "map_rotator_campaign.as"
#include "stage_configurator_campaign.as"

// --------------------------------------------
class GameModeCampaign : GameModeInvasion {

	// --------------------------------------------
	GameModeCampaign(UserSettings@ settings) {
		super(settings);
	}

	// --------------------------------------------
	void init() {
		GameModeInvasion::init();

		// add local player as admin for easy testing, hacks, etc
		if (!getAdminManager().isAdmin(getUserSettings().m_username)) {
			getAdminManager().addAdmin(getUserSettings().m_username);
		}
	}

	// --------------------------------------------
	protected void setupMapRotator() {
		// StageConfigurator registers itself to map rotator, waiting to be called at a specific time
		MapRotatorCampaign mapRotatorCampaign(this);
		StageConfiguratorCampaign configurator(this, mapRotatorCampaign);
		@m_mapRotator = @mapRotatorCampaign;
	}

	// --------------------------------------------
	protected void setupPenaltyManager() {
		// skip for single player
	}

	// --------------------------------------------
	protected void setupMinibosses() {
		// skip for single player
	}

	// --------------------------------------------
	protected void setupDisableRadioAtMatchOver() {
		// skip for single player, not really needed
	}

	// --------------------------------------------
	void save() {
		// save metagame status now:
		_log("saving metagame", 1);

		XmlElement commandRoot("command");
		commandRoot.setStringAttribute("class", "save_data");

		XmlElement root("saved_metagame");

		m_mapRotator.save(root);
		m_unlockManager.save(root);
		m_specialCrateManager.save(root);
		if (m_specialCargoVehicleManager !is null) {
			m_specialCargoVehicleManager.save(root);
		}
		if (m_itemDeliveryOrganizer !is null) {
			m_itemDeliveryOrganizer.save(root);
		}
	
		// append user-settings in too
		XmlElement@ settings = m_userSettings.toXmlElement("settings");
		root.appendChild(settings);

		commandRoot.appendChild(root);

		// save through game
		getComms().send(commandRoot);
	}

	// --------------------------------------------
	void load() {
		// load metagame status now:
		_log("loading metagame", 1);

		XmlElement@ query = XmlElement(
			makeQuery(this, array<dictionary> = {
				dictionary = { {"TagName", "data"}, {"class", "saved_data"} } }));
		const XmlElement@ doc = getComms().query(query);

		if (doc !is null) {
			const XmlElement@ root = doc.getFirstChild();
			// read user-settings too, have them around separately..
			const XmlElement@ settings = root.getFirstElementByTagName("settings");
			if (settings !is null) {
				m_userSettings.fromXmlElement(settings);
				m_userSettings.m_continue = true;
			}

			m_userSettings.print();

			m_mapRotator.init();
			m_mapRotator.load(root);

			m_unlockManager.init(0);
			m_unlockManager.load(root);

			if (m_specialCrateManager !is null) {
				m_specialCrateManager.init();
				m_specialCrateManager.load(root);
			}

			if (m_specialCargoVehicleManager !is null) {
				m_specialCargoVehicleManager.init();
				m_specialCargoVehicleManager.load(root);
			}

			if (m_itemDeliveryOrganizer !is null) {
				m_itemDeliveryOrganizer.init();
				m_itemDeliveryOrganizer.load(root);
			}

			_log("loaded", 1);
		} else {
			_log("load failed");
			m_mapRotator.init();
			m_unlockManager.init(0);
			if (m_specialCrateManager !is null) {
				m_specialCrateManager.init();
			}
			if (m_specialCargoVehicleManager !is null) {
				m_specialCargoVehicleManager.init();
			}
			if (m_itemDeliveryOrganizer !is null) {
				m_itemDeliveryOrganizer.init();
			}
		}
	}
}

