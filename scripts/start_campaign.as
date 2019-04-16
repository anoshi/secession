#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/secession/scripts"
#include "secession_gamemode.as"

// --------------------------------------------
void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	UserSettings settings;
	settings.fromXmlElement(inputSettings);
	//_setupLog(inputSettings);
	_setupLog("dev_verbose"); // comment out before go-live
	settings.print();

	SecessionCampaign metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
