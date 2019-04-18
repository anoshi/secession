#include "gamemode_campaign.as"
#include "secession_stage_configurator.as"
#include "secession_item_delivery_configurator.as"
#include "secession_vehicle_delivery_configurator.as"

// --------------------------------------------
class SecessionCampaign : GameModeCampaign {
	// --------------------------------------------
	SecessionCampaign(UserSettings@ settings) {
		super(settings);
	}

	// --------------------------------------------
	protected void setupMapRotator() {
		MapRotatorCampaign mapRotatorCampaign(this);
		SecessionStageConfigurator configurator(this, mapRotatorCampaign);
		@m_mapRotator = @mapRotatorCampaign;
	}

	// --------------------------------------------
	protected void setupItemDeliveryOrganizer() {
		SecessionItemDeliveryConfigurator configurator(this);
		@m_itemDeliveryOrganizer = ItemDeliveryOrganizer(this, configurator);
	}

	// --------------------------------------------
	protected void setupVehicleDeliveryObjectives() {
		SecessionVehicleDeliveryConfigurator configurator(this);
		configurator.setup();
	}
}
