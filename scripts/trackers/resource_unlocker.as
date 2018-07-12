// internal
#include "query_helpers.as"

// generic trackers
#include "resource.as"

// ----------------------------------------------------
interface UnlockListener {
	void itemUnlocked(const Resource@ resource);
}

// --------------------------------------------
class MultiGroupResource : Resource {
	array<string> m_groups;

	// --------------------------------------------
	MultiGroupResource(string key, string type, array<string>@ groups) {
		super(key, type);
		m_groups = groups; // copy
	}
}

// ----------------------------------------------------
void addInDictionary(dictionary@ dict, string group, const Resource@ resource) {
	array<const Resource@>@ list;
	if (dict.exists(group)) {
		dict.get(group, @list);
	} else {
		@list = array<const Resource@>();
		dict.set(group, @list);
	}
	list.insertLast(resource);
}

// ----------------------------------------------------
void changeFactionResources(Metagame@ metagame, int factionId, const array<const Resource@>@ resources, bool add) {
	// reorder resources so that we have them listed per group
	dictionary dict;

	for (uint i = 0; i < resources.size(); ++i) {
		const Resource@ resource = resources[i];

		const MultiGroupResource@ mgResource = cast<const MultiGroupResource>(resource);
		if (mgResource !is null) {
			for (uint j = 0; j < mgResource.m_groups.size(); ++j) {
				string group = mgResource.m_groups[j];
				addInDictionary(dict, group, resource);
			}
		} else {
			addInDictionary(dict, "default", resource);
		}
	}

	for (uint i = 0; i < dict.getKeys().size(); ++i) {
		string group = dict.getKeys()[i];

		array<const Resource@>@ list;
		dict.get(group, @list);

		if (list.size() > 0) {
			XmlElement command("command");
			command.setStringAttribute("class", "faction_resources");
			command.setStringAttribute("soldier_group_name", group);
			command.setIntAttribute("faction_id", factionId);
			for (uint j = 0; j < list.size(); ++j) {
				const Resource@ resource = list[j];
				addFactionResourceElements(command, resource.m_type, array<string> = {resource.m_key}, add);
			}
			metagame.getComms().send(command);
		}
	}
}

// ----------------------------------------------------
class ResourceUnlocker {
	protected Metagame@ m_metagame;
	protected int m_factionId;
	protected dictionary m_unlockList;
	protected string m_customStatTag;
	protected UnlockListener@ m_listener;

	// ----------------------------------------------------
	ResourceUnlocker(Metagame@ metagame, int factionId, const dictionary@ unlockList, UnlockListener@ listener, string customStatTag = "") {
		@m_metagame = @metagame;
		m_factionId = factionId;
		m_unlockList = unlockList; // copy
		m_customStatTag = customStatTag;
		@m_listener = listener;
	}

	// ----------------------------------------------------
	void handleItemDeliveryCompleted(const Resource@ item, int characterId = -1) {
		_log("handle_item_delivery_completed", 1);

		// link delivered item to a resource unlock:
		const Resource@ unlock = getUnlock(item);

		if (unlock !is null) {
			_log("* item delivery completed, picking unlock for " + item.m_key + " (" + item.m_type + "): " + unlock.m_key + " (" + unlock.m_type + ")", 1);
			// enable a resource for the faction
			changeFactionResources(m_metagame, m_factionId, array<const Resource@> = {unlock}, true);

			// query for unlock name
			string name = getResourceName(m_metagame, unlock.m_key, unlock.m_type);
			if (name != "") {
				// comment about it?
				//$text = "objective completed, " . $this->item_name . " unlocked";
				dictionary a = {
					{"%resource_name", name}
				};
				sendFactionMessageKey(m_metagame, m_factionId, "resource added in stock", a);
			}

			// unlocks are lost over time, but they must carry over map changes
			// announce to metagame that we've unlocked something now, it'll handle that part
			m_listener.itemUnlocked(unlock);

			if (characterId >= 0 && m_customStatTag != "") {
				string c = "<command class='add_custom_stat' character_id='" + characterId + "' tag='" + m_customStatTag + "' />";
				m_metagame.getComms().send(c);
			}

		} else {
			_log("* failed to find an unlock", 1);

			// comment about it?
			//$text = "objective completed, " . $this->item_name . " unlocked";

			// if all unlocks have been used:
			// - don't care for now?
		}
	}

	// ----------------------------------------------------
	protected void ruleOutOwnedItems(array<Resource@>@ masterList, string type, string typePlural) {
		array<const XmlElement@> own = getFactionDeliverables(m_metagame, m_factionId, type, typePlural);
		if (own.size() == 0) return;

		// go through the list and match with master list, removing those already there, from the master list
		for (uint i = 0; i < own.size(); ++i) {
			const XmlElement@ node = own[i];
			string key = node.getStringAttribute("key");
			// check if we have this key
			int eraseIndex = -1;
			for (uint j = 0; j < masterList.size(); ++j) {
				Resource@ item = masterList[j];
				if (key != item.m_key) {
					// no match, continue searching
				} else {
					// matches, rule it out
					eraseIndex = j;
					break;
				}
			}
			if (eraseIndex >= 0) {
				masterList.erase(eraseIndex);
			}
		}
	}

	// ----------------------------------------------------
	protected Resource@ pickRewardItem(const array<Resource@>@ inputMasterList) const {
		// remove already owned items from input list
		array<Resource@> masterList = inputMasterList;

		ruleOutOwnedItems(masterList, "weapon", "weapons");
		ruleOutOwnedItems(masterList, "carry_item", "carry_items");
		//rule_out_owned_items($master_list, "grenade", "grenades");
		//rule_out_owned_items($master_list, "call", "calls");
		//rule_out_owned_items($master_list, "vehicle", "vehicles");

		// any item randomly from the list?

		if (masterList.size() > 0) {
			_log("possible reward items " + masterList.size(), 1);
			int itemIndex = rand(0, masterList.size() - 1);
			Resource@ item = masterList[itemIndex];
			return item;
		}

		return null;
	}

	// ----------------------------------------------------
	protected const Resource@ getUnlock(const Resource@ item) const {
		_log("get_unlock", 1);
		const Resource@ result = null;
		if (m_unlockList.exists(item.m_key)) {
			// unlock list is an associative container of
			// "delivery target item key" -> "container potential reward resourcerefs"
			array<Resource@>@ list;
			m_unlockList.get(item.m_key, @list);
			@result = pickRewardItem(list);
		} else {
			_log("key " + item.m_key + " doesn't exist in unlock_list", 1);
		}
		return result;
	}
}
