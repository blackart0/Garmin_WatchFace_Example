import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Background;
import Toybox.System;

(:background)
class Garmin_WatchFace_ExampleApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        Storage.setValue("_weather", null);
        gWeatherUpdate = false;
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {

    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {

    }

    // Return the initial view of your application here
    function getInitialView() as Array<Views or InputDelegates>? {
        //System.println("App getInitialView: provider = "+gWeatherProvider+", ApiKey = "+gWeatherApiKey);
        InitBackgroundEvents();
        return [ new Garmin_WatchFace_ExampleView() ] as Array<Views or InputDelegates>;
    }

    // New app settings have been received so trigger a UI update
    function onSettingsChanged() as Void {
        gWeatherUpdate = false;
        InitBackgroundEvents();
        WatchUi.requestUpdate();
    }

    function onBackgroundData(data) {
        if (data != null){
            Storage.setValue("_weather", data);
            gWeatherUpdate = true;
            //System.println("_weather:" + data);
        }
    }

    function InitBackgroundEvents(){
        //System.println("InitBackgroundEvents start");
        gWeatherProvider = Properties.getValue("weather-provider");
        gWeatherApiKey = Properties.getValue("WeatherApiKey");
        if((gWeatherProvider == WeatherProviderGarmin) || (gWeatherApiKey == null)){
            //System.println("InitBackgroundEvents return");
            return;
        }
    	var FIVE_MINUTES = new Toybox.Time.Duration(5 * 60);
		var lastTime = Background.getLastTemporalEventTime();
        var nextTime;
		if (lastTime != null) {
            nextTime = lastTime.add(FIVE_MINUTES);
            Background.registerForTemporalEvent(nextTime);
		} else {
            nextTime  =Time.now();
            Background.registerForTemporalEvent(nextTime);
		}
        /*
        var info = Gregorian.utcInfo(nextTime.add(new Toybox.Time.Duration(8 * 60 * 60)), Time.FORMAT_SHORT);
        var sOut = Lang.format("$1$-$2$-$3$ $4$:$5$:$6$", [info.year.format("%04u"), info.month.format("%02u"), 
			info.day.format("%02u"),info.hour.format("%02u"), info.min.format("%02u"),info.sec.format("%02u") ]);
        System.println("registerForTemporalEvent nextTime- "+sOut);
        */
    }
    
    function getServiceDelegate(){
        return [new BackgroundServiceDelegate()];
    }
}

(:background)
function getApp() as Garmin_WatchFace_ExampleApp {
    return Application.getApp() as Garmin_WatchFace_ExampleApp;
}