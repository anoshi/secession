#include "tracker.as"
#include "gamemode.as"
//#include "helpers.as"
//#include "query_helpers.as"

#include "log.as"

class QuickieStory : Tracker {
	protected SecessionQuickie@ m_metagame;

	// --------------------------------------------
	QuickieStory(SecessionQuickie@ metagame) {
		@m_metagame = @metagame;
		commanderBriefing();
	}

    // --------------------//
	// COMMANDER BRIEFINGS //
	// --------------------//
	protected void commanderBriefing() {
	// borrowed from scripts/invasion/map_rotator_invasion.as

		// commander jumps on the airwaves and tells the player about what's happening
		// first we pull some info about the player character's location and the level's state in general

		string baseName = "one of the bases";
		{
			const XmlElement@ base = getStartingBase(m_metagame, 0);
			if (base !is null) {
				baseName = base.getStringAttribute("name");
			}
		}

		dictionary a = {
			//{"%map_name", stage.m_mapInfo.m_name},
			{"%base_name", baseName}
			//{"%number_of_bases", formatUInt(stage.m_factions[0].m_ownedBases.size())}
		};

		// commander says something
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 2.0, 0, "map start with 1 base, part 1", a));
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 4.0, 0, "map start with 1 base, part 2", a));
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "map start with 1 base, part 3", a));

		/*
		// capture map?
		if (stage.isCapture()) {
			m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 6.0, 0, "map start with 1 base, capture", a));

		} else if (stage.isKoth()) {
			// koth map?
			a["%target_base_name"] = stage.m_kothTargetBase;
			m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 6.0, 0, "map start with 1 base, koth", a));
		}

		// side objectives?
		if (stage.hasSideObjectives()) {
			m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "side objectives", a));
		}

		// intel objectives
		if (stage.hasIntelManager()) {
			m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "intel objectives", a));
		}

		// loot / cargo trucks?
		if (stage.hasLootObjective()) {
			m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "loot objective", a));
		}

		// radio tower / truck?
		if (stage.hasRadioObjective()) {
			m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "radio tower or truck objective", a));
		}

		// aa?
		if (hasAaObjective()) {
			m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 5.0, 0, "aa objective", a));
		}
		*/
		m_metagame.getTaskSequencer().add(AnnounceTask(m_metagame, 0.0, 0, "map start, ending", a));

		// finally enable "in game commander" radio, battle and event reports
		m_metagame.getTaskSequencer().add(CallFloat(CALL_FLOAT(this.setCommanderAiReports), 1.0));
	}

	void setCommanderAiReports(float percentage) {
		string command =
			"<command\n" +
			"  class='commander_ai'" +
			"  faction='0'" +
			"  commander_radio_reports='" + percentage + "'>" +
			"</command>\n";
		m_metagame.getComms().send(command);
	}
}
