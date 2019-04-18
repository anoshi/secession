#include "stage_configurator_campaign.as"

// ------------------------------------------------------------------------------------------------
class SecessionStageConfigurator : StageConfiguratorCampaign {
	// ------------------------------------------------------------------------------------------------
	SecessionStageConfigurator(GameModeInvasion@ metagame, MapRotatorCampaign@ mapRotator) {
		super(metagame, mapRotator);
	}

	// ------------------------------------------------------------------------------------------------
	const array<FactionConfig@>@ getAvailableFactionConfigs() const {
		array<FactionConfig@> availableFactionConfigs;

		availableFactionConfigs.push_back(FactionConfig(-1, "bc.xml", "BlastCorp", "0.2 0.2 0.3", "bc.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "lc.xml", "LifeCraft", "1.0 0.2 0.2", "lc.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "ra.xml", "ReflexArq", "0.5 0.2 0.5", "ra.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "ss.xml", "ScopeSystems", "0.2 0.4 0.2", "ss.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "wt.xml", "WyreTek", "0.0 0.1 0.6", "wt.xml"));
		return availableFactionConfigs;
	}

	// NOTE
	// if you need to add certain resources for enemies or friendlies generally in all stages, have a look at
	// vanilla\scripts\gamemodes\invasion\stage_configurator_invasion.as and consider overriding
	// getCommonFactionResourceChanges
	// getFriendlyFactionResourceChanges
	// getCompletionVarianceCommands
}
