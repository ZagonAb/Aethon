// Aethon
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma Singleton
import QtQuick 2.15

QtObject {
    id: root

    readonly property string memoryKey: "aethon.weather"

    property string state: "idle"
    property string errorMessage: ""

    property string searchState: "idle"
    property var searchResults: []
    property int _searchSeq: 0
    property var currentLocation: null

    property string tempUnit: "celsius"
    property string windUnit: "kmh"
    property int forecastDays: 5
    property bool showDetails: false
    property bool showAirQuality: false
    property string timeFormat: "24h"

    property var savedLocations: []
    property int activeIndex: -1
    readonly property int maxSavedLocations: 5

    readonly property var windUnits: ["kmh", "mph", "ms", "kn"]
    readonly property var forecastDaysOptions: [3, 5, 7]
    readonly property string windUnitText: windUnit === "mph" ? "mph"
    : windUnit === "ms" ? "m/s"
    : windUnit === "kn" ? "kn" : "km/h"

    property int _fetchSeq: 0
    property int _airSeq: 0

    property real currentTemp: 0
    property real apparentTemp: 0
    property int humidity: 0
    property real windSpeed: 0
    property int weatherCode: 0
    property bool isDay: true
    property var dailyForecast: []

    property int todayRainChance: -1
    property real todayUv: -1
    property string sunrise: ""
    property string sunset: ""

    property int aqi: -1
    property real pm25: -1

    function save() {
        var obj = {
            unit: root.tempUnit,
            windUnit: root.windUnit,
            forecastDays: root.forecastDays,
                timeFormat: root.timeFormat,
                showDetails: root.showDetails,
                showAirQuality: root.showAirQuality,
                locations: root.savedLocations,
                activeIndex: root.activeIndex
        };
        if (root.currentLocation) obj.location = root.currentLocation;
        api.memory.set(root.memoryKey, obj);
    }

    function saveLocation() { root.save(); }

    function _validLoc(l) {
        return l && l.lat !== undefined && l.lon !== undefined && l.name;
    }

    function loadSettings() {
        if (!api.memory.has(root.memoryKey)) return;
        var data = api.memory.get(root.memoryKey);
        if (!data) return;

        root.tempUnit = (data.unit === "fahrenheit") ? "fahrenheit" : "celsius";

        if (root.windUnits.indexOf(data.windUnit) >= 0) root.windUnit = data.windUnit;
        else root.windUnit = (root.tempUnit === "fahrenheit") ? "mph" : "kmh";

        if (root.forecastDaysOptions.indexOf(data.forecastDays) >= 0) root.forecastDays = data.forecastDays;
        root.timeFormat = (data.timeFormat === "12h") ? "12h" : "24h";
        root.showDetails = (data.showDetails === true);
        root.showAirQuality = (data.showAirQuality === true);

        var list = [];
        if (data.locations && data.locations.length !== undefined) {
            for (var i = 0; i < data.locations.length && list.length < root.maxSavedLocations; i++) {
                if (root._validLoc(data.locations[i])) list.push(data.locations[i]);
            }
        } else if (root._validLoc(data.location)) {
            list.push(data.location);
        }
        root.savedLocations = list;

        var idx = (typeof data.activeIndex === "number" && data.activeIndex >= 0 && data.activeIndex < list.length)
        ? data.activeIndex : (list.length > 0 ? 0 : -1);
        root.activeIndex = idx;
        root.currentLocation = idx >= 0 ? list[idx] : null;
    }

    function loadSavedLocation() {
        if (root.currentLocation) {
            root.fetchWeather(root.currentLocation.lat, root.currentLocation.lon);
            return true;
        }
        return false;
    }

    Component.onCompleted: root.loadSettings()

    function _sameCity(a, b) {
        return Math.abs(a.lat - b.lat) < 0.01 && Math.abs(a.lon - b.lon) < 0.01;
    }

    function switchLocation(index) {
        if (index < 0 || index >= root.savedLocations.length || index === root.activeIndex) return;
        root.activeIndex = index;
        root.currentLocation = root.savedLocations[index];
        root.save();
        root._refetch();
    }

    function cycleLocation(step) {
        var n = root.savedLocations.length;
        if (n < 2) return;
        root.switchLocation((root.activeIndex + step + n) % n);
    }

    function removeActiveLocation() {
        if (root.activeIndex < 0) return;
        var list = root.savedLocations.slice();
        list.splice(root.activeIndex, 1);
        root.savedLocations = list;

        if (list.length === 0) {
            root.activeIndex = -1;
            root.currentLocation = null;
            root._fetchSeq++;
            root._airSeq++;
            root.state = "idle";
        } else {
            root.activeIndex = Math.min(root.activeIndex, list.length - 1);
            root.currentLocation = list[root.activeIndex];
            root._refetch();
        }
        root.save();
    }

    function _refetch() {
        if (root.currentLocation) {
            root.fetchWeather(root.currentLocation.lat, root.currentLocation.lon);
        }
    }

    function _cycle(list, current, step) {
        var i = list.indexOf(current);
        if (i < 0) i = 0;
        return list[(i + step + list.length) % list.length];
    }

    function setUnit(newUnit) {
        if (root.tempUnit === newUnit) return;
        root.tempUnit = newUnit;
        root.save();
        root._refetch();
    }

    function setWindUnit(u) {
        if (root.windUnits.indexOf(u) < 0 || root.windUnit === u) return;
        root.windUnit = u;
        root.save();
        root._refetch();
    }
    function cycleWindUnit(step) { root.setWindUnit(root._cycle(root.windUnits, root.windUnit, step)); }

    function setForecastDays(n) {
        if (root.forecastDaysOptions.indexOf(n) < 0 || root.forecastDays === n) return;
        root.forecastDays = n;
        root.save();
        root._refetch();
    }
    function cycleForecastDays(step) { root.setForecastDays(root._cycle(root.forecastDaysOptions, root.forecastDays, step)); }

    function setShowDetails(v) {
        if (root.showDetails === v) return;
        root.showDetails = v;
        root.save();
    }

    function setTimeFormat(f) {
        var nf = (f === "12h") ? "12h" : "24h";
        if (root.timeFormat === nf) return;
        root.timeFormat = nf;
        root.save();
    }

    function setShowAirQuality(v) {
        if (root.showAirQuality === v) return;
        root.showAirQuality = v;
        root.save();
        if (v && root.currentLocation && root.state === "success") {
            root.fetchAirQuality(root.currentLocation.lat, root.currentLocation.lon);
        }
    }

    function formatTime(t) {
        if (!t) return "";
        if (root.timeFormat !== "12h") return t;
        var p = String(t).split(":");
        var h = parseInt(p[0]);
        if (isNaN(h)) return t;
        var suffix = h >= 12 ? "PM" : "AM";
        var h12 = h % 12;
        if (h12 === 0) h12 = 12;
        return h12 + ":" + (p[1] || "00") + " " + suffix;
    }

    function aqiLevel(v) {
        if (v === undefined || v < 0) return -1;
        if (v <= 50) return 0;
        if (v <= 100) return 1;
        if (v <= 150) return 2;
        if (v <= 200) return 3;
        if (v <= 300) return 4;
        return 5;
    }
    function aqiKey(v) {
        var keys = ["weather_aqi_good", "weather_aqi_moderate", "weather_aqi_sensitive",
        "weather_aqi_unhealthy", "weather_aqi_very_unhealthy", "weather_aqi_hazardous"];
        var l = root.aqiLevel(v);
        return l >= 0 ? keys[l] : "";
    }
    function aqiColor(v) {
        var colors = ["#4caf50", "#e6c229", "#ff9800", "#f44336", "#9c27b0", "#7e2a4d"];
        var l = root.aqiLevel(v);
        return l >= 0 ? colors[l] : "transparent";
    }

    function resetSearch() {
        root._searchSeq++;
        root.searchResults = [];
        root.searchState = "idle";
    }

    function searchCity(query) {
        var q = (query || "").trim();
        if (q === "") {
            root.resetSearch();
            return;
        }

        var seq = ++root._searchSeq;
        root.searchState = "searching";
        root.searchResults = [];

        var lang = WeatherLanguage.geocodingCode;
        var url = "https://geocoding-api.open-meteo.com/v1/search?name="
        + encodeURIComponent(q)
        + "&count=5&language=" + lang + "&format=json";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (seq !== root._searchSeq) return;

            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data && data.results && data.results.length > 0) {
                        var results = [];
                        for (var i = 0; i < data.results.length; i++) {
                            var r = data.results[i];
                            results.push({
                                name: r.name,
                                country: r.country || "",
                                admin1: r.admin1 || "",
                                lat: r.latitude,
                                lon: r.longitude
                            });
                        }
                        root.searchResults = results;
                        root.searchState = "results";
                    } else {
                        root.searchState = "empty";
                    }
                } catch (e) {
                    root.searchState = "error";
                }
            } else {
                root.searchState = "error";
            }
        };
        xhr.send();
    }

    function selectLocation(index) {
        if (index < 0 || index >= root.searchResults.length) return;

        var loc = root.searchResults[index];
        var entry = { name: loc.name, country: loc.country, admin1: loc.admin1, lat: loc.lat, lon: loc.lon };

        var list = root.savedLocations.slice();
        var found = -1;
        for (var i = 0; i < list.length; i++) {
            if (root._sameCity(list[i], entry)) { found = i; break; }
        }
        if (found >= 0) {
            root.activeIndex = found;
        } else {
            list.unshift(entry);
            if (list.length > root.maxSavedLocations) list.pop();
            root.savedLocations = list;
            root.activeIndex = 0;
        }
        root.currentLocation = root.savedLocations[root.activeIndex];

        root.save();
        root.resetSearch();
        root._refetch();
    }

    function fetchWeather(lat, lon) {
        var seq = ++root._fetchSeq;
        root.aqi = -1;
        root.pm25 = -1;
        root.state = "fetching";
        root.errorMessage = "";

        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat
        + "&longitude=" + lon
        + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,uv_index_max,sunrise,sunset"
        + "&forecast_days=" + root.forecastDays
        + "&timezone=auto"
        + "&wind_speed_unit=" + root.windUnit
        + (root.tempUnit === "fahrenheit" ? "&temperature_unit=fahrenheit" : "");

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (seq !== root._fetchSeq) return;

            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data && data.current) {
                        root.currentTemp = data.current.temperature_2m;
                        root.apparentTemp = data.current.apparent_temperature;
                        root.humidity = data.current.relative_humidity_2m;
                        root.windSpeed = data.current.wind_speed_10m;
                        root.weatherCode = data.current.weather_code;
                        root.isDay = (data.current.is_day === 1);

                        var d = data.daily;
                        var forecast = [];
                        if (d && d.time) {
                            var days = Math.min(root.forecastDays, d.time.length);
                            for (var i = 0; i < days; i++) {
                                forecast.push({
                                    date: d.time[i],
                                    code: d.weather_code[i],
                                    max: d.temperature_2m_max[i],
                                    min: d.temperature_2m_min[i]
                                });
                            }
                        }
                        root.dailyForecast = forecast;

                        var rain = (d && d.precipitation_probability_max) ? d.precipitation_probability_max[0] : null;
                        var uv = (d && d.uv_index_max) ? d.uv_index_max[0] : null;
                        var sr = (d && d.sunrise) ? d.sunrise[0] : null;
                        var ss = (d && d.sunset) ? d.sunset[0] : null;
                        root.todayRainChance = (rain === null || rain === undefined) ? -1 : Math.round(rain);
                        root.todayUv = (uv === null || uv === undefined) ? -1 : uv;
                        root.sunrise = sr ? String(sr).substring(11, 16) : "";
                        root.sunset = ss ? String(ss).substring(11, 16) : "";

                        root.state = "success";
                        if (root.showAirQuality) root.fetchAirQuality(lat, lon);
                    } else {
                        root.state = "error";
                        root.errorMessage = "no_data";
                    }
                } catch (e) {
                    root.state = "error";
                    root.errorMessage = "parse";
                }
            } else {
                root.state = "error";
                root.errorMessage = "network";
            }
        };
        xhr.send();
    }

    function fetchAirQuality(lat, lon) {
        var seq = ++root._airSeq;
        var url = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + lat
        + "&longitude=" + lon
        + "&current=us_aqi,pm2_5&timezone=auto";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (seq !== root._airSeq) return;

            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    var c = data ? data.current : null;
                    root.aqi = (c && c.us_aqi !== null && c.us_aqi !== undefined) ? Math.round(c.us_aqi) : -1;
                    root.pm25 = (c && c.pm2_5 !== null && c.pm2_5 !== undefined) ? c.pm2_5 : -1;
                } catch (e) {
                    root.aqi = -1;
                    root.pm25 = -1;
                }
            } else {
                root.aqi = -1;
                root.pm25 = -1;
            }
        };
        xhr.send();
    }

    function getWeatherIconName(code, isDay) {
        if (code === 0) return "weather-sunny";
        if (code === 1 || code === 2) return "weather-partly-cloudy";
        if (code === 3) return "weather-cloudy";
        if (code === 45 || code === 48) return "weather-cloudy";
        if (code >= 51 && code <= 57) return "weather-drizzle";
        if (code >= 61 && code <= 67) return "weather-rain";
        if (code >= 71 && code <= 77) return "weather-cloudy";
        if (code >= 80 && code <= 82) return "weather-rain";
        if (code >= 85 && code <= 86) return "weather-cloudy";
        if (code >= 95) return "weather-rain";

        return "weather-cloudy";
    }

    function getWmoTranslationKey(code) {
        if (code === 0) return "weather_wmo_clear";
        if (code === 1 || code === 2) return "weather_wmo_partly_cloudy";
        if (code === 3) return "weather_wmo_overcast";
        if (code === 45 || code === 48) return "weather_wmo_fog";
        if (code >= 51 && code <= 57) return "weather_wmo_drizzle";
        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return "weather_wmo_rain";
        if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return "weather_wmo_snow";
        if (code >= 95) return "weather_wmo_thunderstorm";
        return "weather_wmo_overcast";
    }
}
