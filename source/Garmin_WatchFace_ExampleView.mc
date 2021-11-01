import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Position;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.SensorHistory;

var gIconsFont;
var gThemeColour; 
var gLocationLat;
var gLocationLon;
var gWeatherProvider;
var gWeatherApiKey;
var gWeatherUpdate = false;
var gecHour;
var geventTime;
var gBGColor, gFGColor, gIconColor, gHourColor, gMinColor;
const SCREEN_MULTIPLIER = (System.getDeviceSettings().screenWidth < 360) ? 1 : 2;
const BATTERY_HEAD_HEIGHT = 4 * SCREEN_MULTIPLIER;
const BATTERY_MARGIN = SCREEN_MULTIPLIER;
const WeatherProviderOpenWeatherMap = 0;
const WeatherProviderGarmin = 1;
const WeatherProviderQWeather = 2;

class Garmin_WatchFace_ExampleView extends WatchUi.WatchFace {

    var gNum = 0;
    var mRow1 = 20;
    var mRow2 = 45;
    var mRow3 = 70;
    var mRow4 = 95;
    var mRow5 = 120;
    var mRow6 = 145;
    var mRow7 = 170;
    var mRow8 = 195;
    var mRow9 = 220;
    hidden var _lastBg = null;
	hidden var _bgInterval = new Time.Duration(59 * 60); //one hour

    function initialize() {
        var location = Activity.getActivityInfo().currentLocation;
		if (location) {
			location = location.toDegrees(); // Array of Doubles.
			gLocationLat = location[0].toFloat();
			gLocationLon = location[1].toFloat();
            Storage.setValue("_gLocationLat", gLocationLat);
            Storage.setValue("_gLocationLon", gLocationLon);
            Properties.setValue("appVersion", "0.2.1");
            //System.println("latitude: "+gLocationLat+",longitude:" +gLocationLon); // latitude (38.856147)  longitude (-94.800953)
        }
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        gIconsFont = Application.loadResource(Rez.Fonts.IconsFont20px);
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Create a method to get the SensorHistoryIterator object
    function getIterator() {
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getOxygenSaturationHistory)) {
            try {
                var ret = Toybox.SensorHistory.getOxygenSaturationHistory({});
                return ret;
            }
            catch( ex ) {
                // Code to catch all execeptions
                return null;
            }
            finally {
                // Code to execute when
            }
        }
        return null;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        var width = dc.getWidth();
        var height = dc.getHeight();
        var stringWidth;
        var textCenter = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var textLeftCenter = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
        var textRightCenter = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
        //var bgColor = Graphics.COLOR_BLACK;
        //var fgColor = Graphics.COLOR_DK_BLUE;
        //var iconColor = Graphics.COLOR_GREEN;
        
        var lightGreenColor = 0x55FFAA;
        var lightRedClolr = 0xFF55AA;
        var lightOrgColor = 0xFFAA55;
        var lightBlueColor = 0xAAAAFF;

        gBGColor = Properties.getValue("BackgroundColor");
        gFGColor = Properties.getValue("ForegroundColor");
        gIconColor = Properties.getValue("IconColor");
        gHourColor = Properties.getValue("HourColor");
        gMinColor = Properties.getValue("MinColor");

        gThemeColour = Graphics.COLOR_GREEN;
        dc.setColor(gBGColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle (0, 0, width, height);

        dc.setColor(gIconColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(width/2, mRow1+20, width/2, height-50);
		
        
        //Time-------------------------------------------------------
        
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (getApp().getProperty("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        // Update the view
        dc.setColor(gHourColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2-3, mRow5, Graphics.FONT_SYSTEM_NUMBER_THAI_HOT, hours, textRightCenter);
        dc.setColor(gMinColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2-3, mRow7+10, Graphics.FONT_SYSTEM_NUMBER_HOT, clockTime.min.format("%02d"), textRightCenter);

        //HeartRate-------------------------------------------------------

		var sample;
        var activityInfo;
		var value = "";
        activityInfo = Activity.getActivityInfo();
		sample = activityInfo.currentHeartRate;
		if (sample != null) {
			value = sample.format("%d");
		} else if (ActivityMonitor has :getHeartRateHistory) {
			sample = ActivityMonitor.getHeartRateHistory(1, /* newestFirst */ true).next();
			if ((sample != null) && (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE)) {
				value = sample.heartRate.format("%d");
			}
		} 
		var timeString2 = Lang.format("$1$",[value]);
        dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT);   
        dc.drawText(width/2 + 28 , mRow1, Graphics.FONT_SYSTEM_TINY, timeString2, textLeftCenter);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
		dc.drawText(width/2 + 2, mRow1, gIconsFont, "a", textLeftCenter);

        //battery-------------------------------------------------------

        var value2 = Math.floor(System.getSystemStats().battery);
		value2 = value2.format("%d") + "%";
        dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2 + 2, height - 16, Graphics.FONT_SYSTEM_TINY, value2, textLeftCenter);
        drawBatteryMeter(dc, width/2 - 15, height - 15, 21, 15);
        
        //ActivityMonitor info-------------------------------------------------------

        var info = ActivityMonitor.getInfo();
        var mSteps = info.steps;
        var mCalories = info.calories;
        var mDistances = info.distance/100;
        var mFloorsclimbed = info.floorsClimbed;

        dc.setColor(gIconColor, Graphics.COLOR_TRANSPARENT);
		dc.drawText(width/2 + 3, mRow2, gIconsFont, "b", textLeftCenter);
        dc.drawText(width/2 + 3, mRow3, gIconsFont, "p", textLeftCenter);
        dc.drawText(width/2 + 3, mRow6, gIconsFont, "9", textLeftCenter);
        dc.drawText(width/2 + 3, mRow7, gIconsFont, "e", textLeftCenter);

        dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT);   
        dc.drawText(width/2 + 28, mRow2, Graphics.FONT_SYSTEM_TINY, mSteps, textLeftCenter);  
        dc.drawText(width/2 + 28, mRow3, Graphics.FONT_SYSTEM_TINY, mCalories, textLeftCenter);
        dc.drawText(width/2 + 28, mRow6, Graphics.FONT_SYSTEM_TINY, mDistances, textLeftCenter);
        dc.drawText(width/2 + 28, mRow7, Graphics.FONT_SYSTEM_TINY, mFloorsclimbed, textLeftCenter);

        //Date-------------------------------------------------------
        var mySettings = System.getDeviceSettings();
        if( mySettings.systemLanguage == System.LANGUAGE_CHS){
            var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            var dateString1 = Lang.format("$1$月$2$日", [today.month, today.day]);
            var dateUtils = new LunarDateUtils();
            var dateChinese = dateUtils.getLunarDate(today.year, today.month.toNumber(), today.day);

            dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width/2 - 3, mRow2, Graphics.FONT_SYSTEM_TINY, dateString1, textRightCenter);
            today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            dc.drawText(width/2 - 3, mRow3, Graphics.FONT_SYSTEM_TINY, dateChinese+","+today.day_of_week, textRightCenter);
        }else{
            var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            var dateString1 = Lang.format("$1$ $2$", [today.day, today.month]);

            dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width/2 - 3, mRow2, Graphics.FONT_SYSTEM_TINY, dateString1, textRightCenter);
            dc.drawText(width/2 - 3, mRow3, Graphics.FONT_SYSTEM_TINY, today.day_of_week, textRightCenter);
        }
        //set background service --------- weather ----------------------------------------------
        var mCelsiusChar = "°C";
        if( mySettings.systemLanguage == System.LANGUAGE_CHS){
            mCelsiusChar = "℃";
        }
        var mLn = "- - -";
        var mTemp = "--" + mCelsiusChar;
        var mHumi = null;
        var mMain = null;
        var mDesc = null;
        var mCon = null;
        var mWeatherID = null;

        if(gWeatherProvider == WeatherProviderGarmin){
            var mConditions = Weather.getCurrentConditions();
            mLn = mConditions.observationLocationName;
            mCon = mConditions.condition;
            mTemp = mConditions.temperature + mCelsiusChar;
            mHumi = mConditions.relativeHumidity + "%";
            //stringWidth = dc.getTextWidthInPixels(mTemp, Graphics.FONT_SYSTEM_TINY);
        } else {
            if (_lastBg == null){
                _lastBg = new Time.Moment(Time.now().value());
            }
            else if (_lastBg.add(_bgInterval).lessThan(new Time.Moment(Time.now().value()))){
                _lastBg = new Time.Moment(Time.now().value());
                Application.getApp().InitBackgroundEvents();
            }
            if(gWeatherUpdate){
                var _weatherData = Storage.getValue("_weather");
                if((gWeatherProvider == WeatherProviderOpenWeatherMap) && (gWeatherApiKey != null)){
                    if(_weatherData != null){
                        //gWeatherUpdate = false;
                        mLn = _weatherData["name"];
                        mTemp = (_weatherData["main"]["temp"]).toNumber() + mCelsiusChar;
                        mWeatherID = _weatherData["weather"][0]["id"];
                        mMain = _weatherData["weather"][0]["main"];
                        mDesc = _weatherData["weather"][0]["description"];
                        mLn = mLn + " | " + mMain + "," + mDesc;
                        if(mWeatherID == 800){//"Clear"
                            mCon = 0;
                        }else if(mWeatherID >= 500 and mWeatherID<= 599) {//"Rain"
                            mCon = 3;
                        }else if(mWeatherID >= 300 and mWeatherID<= 399){//"Drizzle"
                            mCon = 3;
                        }else if(mWeatherID >= 600 and mWeatherID<= 699){//"Snow"
                            mCon = 4;
                        }else if(mWeatherID >= 200 and mWeatherID<= 299){//"Thunderstorm"
                            mCon = 6;
                        }else if(mWeatherID >= 701 and mWeatherID<= 781){//"Atmosphere"
                            mCon = 8;
                        }else if(mWeatherID >= 801 and mWeatherID<= 804){//"Clouds"
                            mCon = 20;
                        }else{
                            mCon = 8;
                        }
                    }
                }else if((gWeatherProvider == WeatherProviderQWeather) && (gWeatherApiKey != null)){ 
                    if(_weatherData != null){
                        //gWeatherUpdate = false;
                        mLn = _weatherData["now"]["text"];
                        mTemp = _weatherData["now"]["temp"] + mCelsiusChar;
                        mWeatherID = _weatherData["now"]["icon"];
                        mMain = _weatherData["now"]["windDir"];
                        mDesc = _weatherData["now"]["pressure"];
                        mLn = mLn + " | " + mMain + "," + mDesc;
                        mWeatherID = mWeatherID.toNumber();
                        if(mWeatherID == 100 or mWeatherID == 150){//"Clear"
                            mCon = 0;
                        }else if(mWeatherID >= 300 and mWeatherID<= 399) {//"Rain"
                            mCon = 3;
                        }else if(mWeatherID >= 400 and mWeatherID<= 500){//"Snow"
                            mCon = 4;
                        }else if(mWeatherID >= 500 and mWeatherID<= 599){//"Atmosphere"
                            mCon = 8;
                        }else if(mWeatherID >= 101 and mWeatherID<= 154){//"Clouds"
                            mCon = 20;
                        }else{
                            mCon = 8;
                        }
                    }
                }
            }
        }
        //-------------------------------------------------------------------
        var positionInfo = Position.getInfo();
        var mAtitude = 0;

        if (positionInfo has :altitude && positionInfo.altitude != null) {
            mAtitude = positionInfo.altitude;
        }else{
            mAtitude = 0;
        }
        dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT); 
        dc.drawText(width/2 + 3 + 28, mRow5, Graphics.FONT_SYSTEM_TINY, mTemp, textLeftCenter);
        dc.drawText(width/2, mRow9, Graphics.FONT_SYSTEM_XTINY, mLn, textCenter);
        dc.drawText(width/2 + 3 + 28, mRow4, Graphics.FONT_SYSTEM_TINY, mAtitude.toNumber(), textLeftCenter);

        dc.setColor(gIconColor, Graphics.COLOR_TRANSPARENT);
        stringWidth = width/2 + 3;
        dc.drawText(width/2 + 3, mRow4, gIconsFont, "c", textLeftCenter);

        if (mCon == 20) { // Cloudy
            dc.drawText(stringWidth, mRow5, gIconsFont, "k", textLeftCenter);
        } else if (mCon == 0 or mCon == 5) { // Clear or Windy
            dc.drawText(stringWidth, mRow5, gIconsFont, "0", textLeftCenter);	
        } else if (mCon == 1 or mCon == 23 or mCon == 40 or mCon == 52) { // Partly Cloudy or Mostly Clear or fair or thin clouds
            dc.drawText(stringWidth, mRow5, gIconsFont, "3", textLeftCenter); 
        } else if (mCon == 2 or mCon == 22) { // Mostly Cloudy or Partly Clear
            dc.drawText(stringWidth, mRow5, gIconsFont, "3", textLeftCenter); 
        } else if (mCon == 3 or mCon == 14 or mCon == 15 or mCon == 11 or mCon == 13 or mCon == 24 or mCon == 25 or mCon == 26 or mCon == 27 or mCon == 45) { // Rain or Light Rain or heavy rain or showers or unkown or chance  
            dc.drawText(stringWidth, mRow5, gIconsFont, "6", textLeftCenter); 
        } else if (mCon == 4 or mCon == 10 or mCon == 16 or mCon == 17 or mCon == 34 or mCon == 43 or mCon == 46 or mCon == 48 or mCon == 51) { // Snow or Hail or light or heavy snow or ice or chance or cloudy chance or flurries or ice snow
            dc.drawText(stringWidth, mRow5, gIconsFont, "7", textLeftCenter);
        } else if (mCon == 6 or mCon == 12 or mCon == 28 or mCon == 32 or mCon == 36 or mCon == 41 or mCon == 42) { // Thunder or scattered or chance or tornado or squall or hurricane or tropical storm
            dc.drawText(stringWidth, mRow5, gIconsFont, "2", textLeftCenter); 
        } else if (mCon == 7 or mCon == 18 or mCon == 19 or mCon == 21 or mCon == 44 or mCon == 47 or mCon == 49 or mCon == 50) { // Wintry Mix (Snow and Rain) or chance or cloudy chance or freezing rain or sleet
            dc.drawText(stringWidth, mRow5, gIconsFont, "6", textLeftCenter);
        } else if (mCon == 8 or mCon == 9 or mCon == 29 or mCon == 30 or mCon == 31 or mCon == 33 or mCon == 35 or mCon == 37 or mCon == 38 or mCon == 39) { // Fog or Hazy or Mist or Dust or Drizzle or Smoke or Sand or sandstorm or ash or haze
            dc.drawText(stringWidth, mRow5, gIconsFont, "5", textLeftCenter); 
        } else {
            dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT); 
            dc.drawText(stringWidth, mRow5, gIconsFont, "n", textLeftCenter); 
        }
        //dc.drawText(width/2 - 3 - 25, mRow7, Graphics.FONT_SYSTEM_TINY, mHumi+"%", textRightCenter);

        //phoneConnected------------------------------------------------------
        
        //var mySettings = System.getDeviceSettings();
        if(mySettings.phoneConnected){
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
        }else{
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        }
        dc.drawText(width/2 - 10, mRow1, gIconsFont, "g", textRightCenter);

        //SPO2 OxygenSaturation------------------------------------------------------

        // Store the iterator info in a variable. The options are 'null' in
        // this case so the entire available history is returned with the
        // newest samples returned first.
        var pulseOxData = null;
        if (Activity.getActivityInfo() has :currentOxygenSaturation) {
        	pulseOxData = Activity.getActivityInfo().currentOxygenSaturation ;
        }
        if(pulseOxData == null){
            var sensorIter = getIterator();
            if(sensorIter != null){
                pulseOxData = sensorIter.next().data.toNumber();
            }else{
                pulseOxData = null;
            }
        }
        dc.setColor(gFGColor, Graphics.COLOR_TRANSPARENT);
        if (pulseOxData != null) {
            dc.drawText(width/2 + 3 + 28, mRow8, Graphics.FONT_SYSTEM_TINY, pulseOxData.toString() + "%", textLeftCenter);
        }else{
            dc.drawText(width/2 + 3 + 28, mRow8, Graphics.FONT_SYSTEM_TINY, "--%", textLeftCenter);
        }
        dc.setColor(gIconColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width/2 + 6, mRow8, gIconsFont, "f", textLeftCenter);
        //------------------------------------------------------

        // Call the parent onUpdate function to redraw the layout
        //View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
function DisplaySunEvent(layout)
{
    var eventTime = null;
    var location = [gLocationLat,gLocationLon];
    var time = System.getClockTime();
        
    if (gecHour == time.hour && geventTime != null && time.hour <= geventTime[0] && time.min < geventTime[1]) {
        eventTime = geventTime;
    } else {
        if (location != null && location.size() == 2)
        {
            var DOY = WatchData.GetDOY(Time.now());

		    // get sunrise
		    //
            var ne = WatchData.GetNextSunEvent(DOY, location[0], location[1], time.timeZoneOffset, time.dst, true);
            if (ne != null && (time.hour > ne[0] || (time.hour == ne[0] && time.min > ne[1]))) {
		    	// if missed sunrise, get sunset
		    	//
                ne = WatchData.GetNextSunEvent(DOY, location[0], location[1], time.timeZoneOffset, time.dst, false);
                if (ne != null && (time.hour > ne[0] || (time.hour == ne[0] && time.min > ne[1]))) {
		    		// if missed sunset, get sunrise next day
		    		//
                    DOY = WatchData.GetDOY(Time.now().add(new Toybox.Time.Duration(86400)));
                    ne = WatchData.GetNextSunEvent(DOY, location[0], location[1], time.timeZoneOffset, time.dst, true);
                }
            }
            eventTime = ne; 
            gecHour = time.hour;
            geventTime = eventTime;
        }
    }

    if (eventTime == null){
        return ["no gps", ""];
    }else{
        layout["f"][1] = 101;
        return [eventTime[0].format("%02d") + ":" + eventTime[1].format("%02d"), eventTime[2] ? "r" : "s"];
    }
}

function drawBatteryMeter(dc, x, y, width, height) {
	dc.setColor(gIconColor, Graphics.COLOR_TRANSPARENT);
	dc.setPenWidth(2);
	dc.drawRoundedRectangle(
		x - (width / 2) + 1,
		y - (height / 2) + 1,
		width - 1,
		height - 1,
		2 * SCREEN_MULTIPLIER);
	dc.fillRectangle(
		x + (width / 2) + BATTERY_MARGIN,
		y - (BATTERY_HEAD_HEIGHT / 2),
		2,
		BATTERY_HEAD_HEIGHT);

	var batteryLevel = Math.floor(System.getSystemStats().battery);		
	var fillColour;
	if (batteryLevel <= 10) {
		fillColour = Graphics.COLOR_RED;
	} else if (batteryLevel <= 20) {
		fillColour = Graphics.COLOR_YELLOW;
	} else {
		fillColour = gIconColor;
	}

	dc.setColor(fillColour, Graphics.COLOR_TRANSPARENT);
	var lineWidthPlusMargin = (2 + BATTERY_MARGIN);
	var fillWidth = width - (2 * lineWidthPlusMargin);
	dc.fillRectangle(
		x - (width / 2) + lineWidthPlusMargin,
		y - (height / 2) + lineWidthPlusMargin,
		Math.ceil(fillWidth * (batteryLevel / 100)), 
		height - (2 * lineWidthPlusMargin));
}
