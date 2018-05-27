#include "stage_configurator_campaign.as"

// ------------------------------------------------------------------------------------------------
class MyStageConfigurator : StageConfiguratorCampaign {
	// ------------------------------------------------------------------------------------------------
	MyStageConfigurator(GameModeInvasion@ metagame, MapRotatorCampaign@ mapRotator) {
		super(metagame, mapRotator);
	}

	// ------------------------------------------------------------------------------------------------
	const array<FactionConfig@>@ getAvailableFactionConfigs() const {
		array<FactionConfig@> availableFactionConfigs;

		// --------------------------------
		// TODO: define 3 faction configs here
		// - "green.xml" faction specification filename
		// - "Greenbelts" faction name, usually same as the one in the file
		// - "0.1 0.5 0" color used for faction in the world view
		// - "green_boss.xml" faction specification filename used in the final missions; 
		//   can be same as the regular faction filename
		// --------------------------------

		availableFactionConfigs.push_back(FactionConfig(-1, "ra.xml", "ReflexArq", "0 0.6 0.4", "ra_boss.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "bc.xml", "BlastCorp", "0.2 0.2 0.3", "bc_boss.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "wt.xml", "WyreTek", "0.0 0.1 0.5", "wt_boss.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "ss.xml", "ScopeSystems", "0.3 0.8 0.3", "ss_boss.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "lc.xml", "LifeCraft", "1.0 0.7 0.7", "lc_boss.xml"));
		return availableFactionConfigs;
	}

	// NOTE
	// if you need to add certain resources for enemies or friendlies generally in all stages, have a look at
	// vanilla\scripts\gamemodes\invasion\stage_configurator_invasion.as and consider overriding
	// getCommonFactionResourceChanges
	// getFriendlyFactionResourceChanges
	// getCompletionVarianceCommands
}
