#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/secession/scripts"
#include "my_gamemode.as"

// --------------------------------------------
void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	UserSettings settings;
	settings.fromXmlElement(inputSettings);
	_setupLog(inputSettings);
	settings.print();
	//array<string> overlays = {
    //            "media/packages/secession"
    //    };
    //    settings.m_overlayPaths = overlays;

	MyGameMode metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
