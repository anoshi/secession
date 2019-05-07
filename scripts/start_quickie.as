// paths containing angel script files
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/secession/scripts"
// secession quickmatch gamemode and script refs
//#include "secession_quickie.as"
#include "gamemode_cabal.as"

void main(dictionary@ inputData) {
	XmlElement inputSettings(inputData);

	UserSettings settings;
	settings.fromXmlElement(inputSettings);
	//_setupLog(inputSettings);
	_setupLog("dev_verbose"); // comment out before go-live
	_log("*** SECESSION: start_quickie.as running...",1);
	settings.print();

	//SecessionQuickie metagame(settings);
	Cabal metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

	_log("ending execution");
}
