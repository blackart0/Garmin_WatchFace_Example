import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Background;
import Toybox.System;
import Toybox.Communications;
// The Service Delegate is the main entry point for background processes
// our onTemporalEvent() method will get run each time our periodic event
// is triggered by the system.
(:background)
class BackgroundServiceDelegate extends System.ServiceDelegate {

	function initialize() {
		System.ServiceDelegate.initialize();
	}

	function onTemporalEvent() {
		var options = {
			:method => Communications.HTTP_REQUEST_METHOD_GET,
			:headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
			:responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
		};
		if(Properties.getValue("weather-provider") == 0){ //openWeatherMap
			Communications.makeWebRequest(
				"https://api.openweathermap.org/data/2.5/weather",
				{
					"lat" => Storage.getValue("_gLocationLat"),//"39.1375",
					"lon" => Storage.getValue("_gLocationLon"),//"116.9997",
					"appid" => Properties.getValue("WeatherApiKey"),
					"lang" => "zh_cn",
					"units" => "metric" // Celcius.
				},
				options,
				method(:responseCallbackWeather)
			);
		} else if(Properties.getValue("weather-provider") == 2){ //2,qWeather
			Communications.makeWebRequest(
				"https://devapi.qweather.com/v7/weather/now",
				{
					"location" => Storage.getValue("_gLocationLon")+","+Storage.getValue("_gLocationLat"),//"39.1375",
					"key" => Properties.getValue("WeatherApiKey"),
					"gzip" => "n" 
				},
				options,
				method(:responseCallbackWeather)
			);
		}else{
			return;
		}
		/*
		var info = Gregorian.utcInfo(Time.now().add(new Toybox.Time.Duration(8 * 60 * 60)), Time.FORMAT_SHORT);
        var sOut = Lang.format("$1$-$2$-$3$ $4$:$5$:$6$", [info.year.format("%04u"), info.month.format("%02u"), 
			info.day.format("%02u"),info.hour.format("%02u"), info.min.format("%02u"),info.sec.format("%02u") ]);
		System.println("makeWebRequest  openWeatherMap - " + sOut);
		*/
    }
	
	function responseCallbackWeather(responseCode, data) {
		var result;
		if (responseCode == 200){
				result = data;
			}else{
				//result.put("isErr", true);
				result = {"httpError" => responseCode};
			}
			Background.exit(result);
	}
}
