#include "item_delivery_configurator_invasion.as"

// ------------------------------------------------------------------------------------------------
class MyItemDeliveryConfigurator : ItemDeliveryConfiguratorInvasion {
	// ------------------------------------------------------------------------------------------------
	MyItemDeliveryConfigurator(GameModeInvasion@ metagame) {
		super(metagame);
	}

	array<Resource@>@ getUnlockWeaponList() const {
		array<Resource@> list;
		// briefcase delivery rewards
		list.push_back(Resource("bc_impervavest.carry_item", "carry_item"));
		list.push_back(Resource("lc_heal_nade.weapon", "weapon"));
		list.push_back(Resource("ss_srx.weapon", "weapon"));
		list.push_back(Resource("ss_sgx.weapon", "weapon"));

		return list;
	}

	array<Resource@>@ getUnlockWeaponList2() const {
		array<Resource@> list;
		// laptop delivery rewards
		// include random items from secondary companies (udonis noodles et al.)
		list.push_back(Resource("mp5sd.weapon", "weapon"));
		list.push_back(Resource("scorpion-evo.weapon", "weapon"));
		list.push_back(Resource("qcw-05.weapon", "weapon"));
		list.push_back(MultiGroupResource("vest_blackops.carry_item", "carry_item", array<string> = {"default", "supply"}));
		list.push_back(Resource("apr.weapon", "weapon"));
		list.push_back(MultiGroupResource("mk23.weapon", "weapon", array<string> = {"default", "supply"}));

		return list;
	}

	array<Resource@>@ getDeliverablesList() const {
		array<Resource@> list;
		// track delivery of these items to armory, with intention of unlocking that same item

		// BlastCorp equipment
		list.push_back(Resource("bc_lr.weapon", "weapon"));
		list.push_back(Resource("bc_mg.weapon", "weapon"));
		list.push_back(Resource("bc_sr.weapon", "weapon"));
		list.push_back(Resource("bc_sg.weapon", "weapon"));
		// LifeCraft equipment
		list.push_back(Resource("lc_lr.weapon", "weapon"));
		list.push_back(Resource("lc_mg.weapon", "weapon"));
		list.push_back(Resource("lc_sr.weapon", "weapon"));
		list.push_back(Resource("lc_sg.weapon", "weapon"));
		// ReflexArq equipment
		list.push_back(Resource("ra_lr.weapon", "weapon"));
		list.push_back(Resource("ra_mg.weapon", "weapon"));
		list.push_back(Resource("ra_sr.weapon", "weapon"));
		list.push_back(Resource("ra_sg.weapon", "weapon"));
		// ScopeSystems equipment
		list.push_back(Resource("ss_lr.weapon", "weapon"));
		list.push_back(Resource("ss_mg.weapon", "weapon"));
		list.push_back(Resource("ss_sr.weapon", "weapon"));
		list.push_back(Resource("ss_sg.weapon", "weapon"));
		// WyreTek equipment
		list.push_back(Resource("wt_lr.weapon", "weapon"));
		list.push_back(Resource("wt_mg.weapon", "weapon"));
		list.push_back(Resource("wt_sr.weapon", "weapon"));
		list.push_back(Resource("wt_sg.weapon", "weapon"));

		return list;
	}

	// --------------------------------------------
	// NOTE:
	// also see vanilla\scripts\gamemodes\invasion\item_delivery_configurator_invasion.as:
	// protected void setupGift1()
	// protected void setupGift2()
	// protected void setupGift3()

}
