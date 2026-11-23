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

    readonly property string memoryKey: "aethon.weather.lang"
    readonly property var availableLanguages: [
        { code: "auto", name: "" },
        { code: "en", name: "English" },
        { code: "es", name: "Español" },
        { code: "pt", name: "Português" },
        { code: "ru", name: "Русский" },
        { code: "fr", name: "Français" },
        { code: "de", name: "Deutsch" },
        { code: "it", name: "Italiano" }
    ]

    property string selected: "auto"
    readonly property string effective: root.selected === "auto" ? Language.currentLanguage : root.selected
    readonly property string _reactive: root.effective
    readonly property string geocodingCode: {
        var c = root.effective;
        return (c === "en" || c === "es" || c === "pt" || c === "ru" || c === "fr" || c === "de" || c === "it") ? c : "en";
    }

    readonly property var days: ({
        en: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        es: ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
        pt: ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"],
        ru: ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"],
        fr: ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
        de: ["So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"],
        it: ["Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"]
    })

    readonly property var strings: ({
        en: {
            weather_title: "WEATHER",
            weather_search_placeholder: "Type a city...",
            weather_feels_like: "Feels like:",
            weather_humidity: "Humidity:",
            weather_wind: "Wind:",
            weather_forecast: "Forecast",
            weather_no_city: "Search for a city to see the weather",
            weather_error: "Connection error. Try again.",
            weather_search_results: "Results",
            weather_loading: "Loading...",
            weather_wmo_clear: "Clear sky",
            weather_wmo_partly_cloudy: "Partly cloudy",
            weather_wmo_overcast: "Overcast",
            weather_wmo_fog: "Fog",
            weather_wmo_drizzle: "Drizzle",
            weather_wmo_rain: "Rain",
            weather_wmo_snow: "Snow",
            weather_wmo_thunderstorm: "Thunderstorm",
            weather_settings_title: "WEATHER SETTINGS",
            weather_setting_city: "Change City",
            weather_setting_unit: "Temperature Unit",
            weather_setting_unit_c: "Celsius (°C)",
                                    weather_setting_unit_f: "Fahrenheit (°F)",
                                    weather_setting_language: "Language",
                                    weather_language_auto: "Automatic (theme)",
                                    weather_back_hint: "{cancel}: Back | {details}: Settings",
                                    weather_searching: "Searching...",
                                    weather_no_results: "No results found",
                                    weather_hint_menu: "{accept}: Select | {cancel}: Back",
                                    weather_hint_search: "{accept}: Search | {down}: Results | {cancel}: Cancel",
                                    weather_hint_results: "{accept}: Select | {up}: Search | {cancel}: Cancel",
                                    weather_setting_wind: "Wind Unit",
                                    weather_setting_days: "Forecast Days",
                                    weather_setting_details: "Extra Details",
                                    weather_days: "days",
                                    weather_option_on: "On",
                                    weather_option_off: "Off",
                                    weather_rain_chance: "Rain:",
                                    weather_uv: "UV:",
                                    weather_sunrise: "Sunrise:",
                                    weather_sunset: "Sunset:",
                                    weather_retry_hint: "{accept}: Retry",
                                    weather_setting_time: "Time Format",
                                    weather_setting_air: "Air Quality",
                                    weather_air_quality: "Air quality:",
                                    weather_aqi_good: "Good",
                                    weather_aqi_moderate: "Moderate",
                                    weather_aqi_sensitive: "Unhealthy (sensitive)",
                                    weather_aqi_unhealthy: "Unhealthy",
                                    weather_aqi_very_unhealthy: "Very unhealthy",
                                    weather_aqi_hazardous: "Hazardous",
                                    weather_hint_city: "{accept}: Add | {left}{right}: Switch | {details}: Remove | {cancel}: Back"
        },
        es: {
            weather_title: "CLIMA",
            weather_search_placeholder: "Escribe una ciudad...",
            weather_feels_like: "Sensación:",
            weather_humidity: "Humedad:",
            weather_wind: "Viento:",
            weather_forecast: "Pronóstico",
            weather_no_city: "Busca una ciudad para ver el clima",
            weather_error: "Error de conexión. Reintentá.",
            weather_search_results: "Resultados",
            weather_loading: "Cargando...",
            weather_wmo_clear: "Despejado",
            weather_wmo_partly_cloudy: "Parcialmente nublado",
            weather_wmo_overcast: "Nublado",
            weather_wmo_fog: "Niebla",
            weather_wmo_drizzle: "Llovizna",
            weather_wmo_rain: "Lluvia",
            weather_wmo_snow: "Nieve",
            weather_wmo_thunderstorm: "Tormenta",
            weather_settings_title: "AJUSTES DEL CLIMA",
            weather_setting_city: "Cambiar Ciudad",
            weather_setting_unit: "Unidad de Temperatura",
            weather_setting_unit_c: "Celsius (°C)",
                                    weather_setting_unit_f: "Fahrenheit (°F)",
                                    weather_setting_language: "Idioma",
                                    weather_language_auto: "Automático (tema)",
                                    weather_back_hint: "{cancel}: Volver | {details}: Ajustes",
                                    weather_searching: "Buscando...",
                                    weather_no_results: "Sin resultados",
                                    weather_hint_menu: "{accept}: Seleccionar | {cancel}: Volver",
                                    weather_hint_search: "{accept}: Buscar | {down}: Resultados | {cancel}: Cancelar",
                                    weather_hint_results: "{accept}: Seleccionar | {up}: Buscar | {cancel}: Cancelar",
                                    weather_setting_wind: "Unidad de Viento",
                                    weather_setting_days: "Días de Pronóstico",
                                    weather_setting_details: "Detalles Extra",
                                    weather_days: "días",
                                    weather_option_on: "Activado",
                                    weather_option_off: "Desactivado",
                                    weather_rain_chance: "Lluvia:",
                                    weather_uv: "UV:",
                                    weather_sunrise: "Amanecer:",
                                    weather_sunset: "Atardecer:",
                                    weather_retry_hint: "{accept}: Reintentar",
                                    weather_setting_time: "Formato de Hora",
                                    weather_setting_air: "Calidad del Aire",
                                    weather_air_quality: "Calidad del aire:",
                                    weather_aqi_good: "Buena",
                                    weather_aqi_moderate: "Moderada",
                                    weather_aqi_sensitive: "Dañina (sensibles)",
                                    weather_aqi_unhealthy: "Dañina",
                                    weather_aqi_very_unhealthy: "Muy dañina",
                                    weather_aqi_hazardous: "Peligrosa",
                                    weather_hint_city: "{accept}: Agregar | {left}{right}: Cambiar | {details}: Quitar | {cancel}: Volver"
        },
        pt: {
            weather_title: "CLIMA",
            weather_search_placeholder: "Digite uma cidade...",
            weather_feels_like: "Sensação:",
            weather_humidity: "Umidade:",
            weather_wind: "Vento:",
            weather_forecast: "Previsão",
            weather_no_city: "Busque uma cidade para ver o clima",
            weather_error: "Erro de conexão. Tente novamente.",
            weather_search_results: "Resultados",
            weather_loading: "Carregando...",
            weather_wmo_clear: "Céu limpo",
            weather_wmo_partly_cloudy: "Parcialmente nublado",
            weather_wmo_overcast: "Nublado",
            weather_wmo_fog: "Neblina",
            weather_wmo_drizzle: "Garoa",
            weather_wmo_rain: "Chuva",
            weather_wmo_snow: "Neve",
            weather_wmo_thunderstorm: "Tempestade",
            weather_settings_title: "CONFIGURAÇÕES DO CLIMA",
            weather_setting_city: "Alterar cidade",
            weather_setting_unit: "Unidade de temperatura",
            weather_setting_unit_c: "Celsius (°C)",
                                    weather_setting_unit_f: "Fahrenheit (°F)",
                                    weather_setting_language: "Idioma",
                                    weather_language_auto: "Automático (tema)",
                                    weather_back_hint: "{cancel}: Voltar | {details}: Configurações",
                                    weather_searching: "Buscando...",
                                    weather_no_results: "Sem resultados",
                                    weather_hint_menu: "{accept}: Selecionar | {cancel}: Voltar",
                                    weather_hint_search: "{accept}: Buscar | {down}: Resultados | {cancel}: Cancelar",
                                    weather_hint_results: "{accept}: Selecionar | {up}: Buscar | {cancel}: Cancelar",
                                    weather_setting_wind: "Unidade do vento",
                                    weather_setting_days: "Dias de previsão",
                                    weather_setting_details: "Detalhes extras",
                                    weather_days: "dias",
                                    weather_option_on: "Ligado",
                                    weather_option_off: "Desligado",
                                    weather_rain_chance: "Chuva:",
                                    weather_uv: "UV:",
                                    weather_sunrise: "Nascer do sol:",
                                    weather_sunset: "Pôr do sol:",
                                    weather_retry_hint: "{accept}: Tentar novamente",
                                    weather_setting_time: "Formato de hora",
                                    weather_setting_air: "Qualidade do ar",
                                    weather_air_quality: "Qualidade do ar:",
                                    weather_aqi_good: "Boa",
                                    weather_aqi_moderate: "Moderada",
                                    weather_aqi_sensitive: "Prejudicial (sensíveis)",
                                    weather_aqi_unhealthy: "Prejudicial",
                                    weather_aqi_very_unhealthy: "Muito prejudicial",
                                    weather_aqi_hazardous: "Perigosa",
                                    weather_hint_city: "{accept}: Adicionar | {left}{right}: Alternar | {details}: Remover | {cancel}: Voltar"
        },
        ru: {
            weather_title: "ПОГОДА",
            weather_search_placeholder: "Введите город...",
            weather_feels_like: "Ощущается:",
            weather_humidity: "Влажность:",
            weather_wind: "Ветер:",
            weather_forecast: "Прогноз",
            weather_no_city: "Найдите город, чтобы увидеть погоду",
            weather_error: "Ошибка соединения. Попробуйте снова.",
            weather_search_results: "Результаты",
            weather_loading: "Загрузка...",
            weather_wmo_clear: "Ясно",
            weather_wmo_partly_cloudy: "Переменная облачность",
            weather_wmo_overcast: "Пасмурно",
            weather_wmo_fog: "Туман",
            weather_wmo_drizzle: "Морось",
            weather_wmo_rain: "Дождь",
            weather_wmo_snow: "Снег",
            weather_wmo_thunderstorm: "Гроза",
            weather_settings_title: "НАСТРОЙКИ ПОГОДЫ",
            weather_setting_city: "Сменить город",
            weather_setting_unit: "Единицы температуры",
            weather_setting_unit_c: "Цельсий (°C)",
                                    weather_setting_unit_f: "Фаренгейт (°F)",
                                    weather_setting_language: "Язык",
                                    weather_language_auto: "Авто (тема)",
                                    weather_back_hint: "{cancel}: Назад | {details}: Настройки",
                                    weather_searching: "Поиск...",
                                    weather_no_results: "Нет результатов",
                                    weather_hint_menu: "{accept}: Выбрать | {cancel}: Назад",
                                    weather_hint_search: "{accept}: Поиск | {down}: Результаты | {cancel}: Отмена",
                                    weather_hint_results: "{accept}: Выбрать | {up}: Поиск | {cancel}: Отмена",
                                    weather_setting_wind: "Единицы ветра",
                                    weather_setting_days: "Дней прогноза",
                                    weather_setting_details: "Доп. данные",
                                    weather_days: "дн.",
                                    weather_option_on: "Вкл",
                                    weather_option_off: "Выкл",
                                    weather_rain_chance: "Дождь:",
                                    weather_uv: "УФ:",
                                    weather_sunrise: "Восход:",
                                    weather_sunset: "Закат:",
                                    weather_retry_hint: "{accept}: Повторить",
                                    weather_setting_time: "Формат времени",
                                    weather_setting_air: "Качество воздуха",
                                    weather_air_quality: "Качество воздуха:",
                                    weather_aqi_good: "Хорошее",
                                    weather_aqi_moderate: "Умеренное",
                                    weather_aqi_sensitive: "Вредно (чувствит.)",
                                    weather_aqi_unhealthy: "Вредное",
                                    weather_aqi_very_unhealthy: "Очень вредное",
                                    weather_aqi_hazardous: "Опасное",
                                    weather_hint_city: "{accept}: Добавить | {left}{right}: Сменить | {details}: Удалить | {cancel}: Назад"
        },
        fr: {
            weather_title: "MÉTÉO",
            weather_search_placeholder: "Saisissez une ville...",
            weather_feels_like: "Ressenti:",
            weather_humidity: "Humidité:",
            weather_wind: "Vent:",
            weather_forecast: "Prévisions",
            weather_no_city: "Recherchez une ville pour voir la météo",
            weather_error: "Erreur de connexion. Réessayez.",
            weather_search_results: "Résultats",
            weather_loading: "Chargement...",
            weather_wmo_clear: "Ciel dégagé",
            weather_wmo_partly_cloudy: "Partiellement nuageux",
            weather_wmo_overcast: "Couvert",
            weather_wmo_fog: "Brouillard",
            weather_wmo_drizzle: "Bruine",
            weather_wmo_rain: "Pluie",
            weather_wmo_snow: "Neige",
            weather_wmo_thunderstorm: "Orage",
            weather_settings_title: "RÉGLAGES MÉTÉO",
            weather_setting_city: "Changer de ville",
            weather_setting_unit: "Unité de température",
            weather_setting_unit_c: "Celsius (°C)",
                                    weather_setting_unit_f: "Fahrenheit (°F)",
                                    weather_setting_language: "Langue",
                                    weather_language_auto: "Automatique (thème)",
                                    weather_back_hint: "{cancel}: Retour | {details}: Réglages",
                                    weather_searching: "Recherche...",
                                    weather_no_results: "Aucun résultat",
                                    weather_hint_menu: "{accept}: Choisir | {cancel}: Retour",
                                    weather_hint_search: "{accept}: Chercher | {down}: Résultats | {cancel}: Annuler",
                                    weather_hint_results: "{accept}: Choisir | {up}: Recherche | {cancel}: Annuler",
                                    weather_setting_wind: "Unité du vent",
                                    weather_setting_days: "Jours de prévision",
                                    weather_setting_details: "Détails supplémentaires",
                                    weather_days: "jours",
                                    weather_option_on: "Activé",
                                    weather_option_off: "Désactivé",
                                    weather_rain_chance: "Pluie:",
                                    weather_uv: "UV:",
                                    weather_sunrise: "Lever:",
                                    weather_sunset: "Coucher:",
                                    weather_retry_hint: "{accept}: Réessayer",
                                    weather_setting_time: "Format de l'heure",
                                    weather_setting_air: "Qualité de l'air",
                                    weather_air_quality: "Qualité de l'air:",
                                    weather_aqi_good: "Bon",
                                    weather_aqi_moderate: "Modéré",
                                    weather_aqi_sensitive: "Mauvais (sensibles)",
                                    weather_aqi_unhealthy: "Mauvais",
                                    weather_aqi_very_unhealthy: "Très mauvais",
                                    weather_aqi_hazardous: "Dangereux",
                                    weather_hint_city: "{accept}: Ajouter | {left}{right}: Changer | {details}: Retirer | {cancel}: Retour"
        },
        de: {
            weather_title: "WETTER",
            weather_search_placeholder: "Stadt eingeben...",
            weather_feels_like: "Gefühlt:",
            weather_humidity: "Feuchtigkeit:",
            weather_wind: "Wind:",
            weather_forecast: "Vorhersage",
            weather_no_city: "Suche eine Stadt, um das Wetter zu sehen",
            weather_error: "Verbindungsfehler. Versuche es erneut.",
            weather_search_results: "Ergebnisse",
            weather_loading: "Lädt...",
            weather_wmo_clear: "Klar",
            weather_wmo_partly_cloudy: "Teilweise bewölkt",
            weather_wmo_overcast: "Bedeckt",
            weather_wmo_fog: "Nebel",
            weather_wmo_drizzle: "Nieselregen",
            weather_wmo_rain: "Regen",
            weather_wmo_snow: "Schnee",
            weather_wmo_thunderstorm: "Gewitter",
            weather_settings_title: "WETTER-EINSTELLUNGEN",
            weather_setting_city: "Stadt ändern",
            weather_setting_unit: "Temperatureinheit",
            weather_setting_unit_c: "Celsius (°C)",
                                    weather_setting_unit_f: "Fahrenheit (°F)",
                                    weather_setting_language: "Sprache",
                                    weather_language_auto: "Automatisch (Thema)",
                                    weather_back_hint: "{cancel}: Zurück | {details}: Einstellungen",
                                    weather_searching: "Suche...",
                                    weather_no_results: "Keine Ergebnisse",
                                    weather_hint_menu: "{accept}: Auswählen | {cancel}: Zurück",
                                    weather_hint_search: "{accept}: Suchen | {down}: Ergebnisse | {cancel}: Abbrechen",
                                    weather_hint_results: "{accept}: Auswählen | {up}: Suche | {cancel}: Abbrechen",
                                    weather_setting_wind: "Windeinheit",
                                    weather_setting_days: "Vorhersagetage",
                                    weather_setting_details: "Zusatzdetails",
                                    weather_days: "Tage",
                                    weather_option_on: "An",
                                    weather_option_off: "Aus",
                                    weather_rain_chance: "Regen:",
                                    weather_uv: "UV:",
                                    weather_sunrise: "Sonnenaufgang:",
                                    weather_sunset: "Sonnenuntergang:",
                                    weather_retry_hint: "{accept}: Erneut versuchen",
                                    weather_setting_time: "Zeitformat",
                                    weather_setting_air: "Luftqualität",
                                    weather_air_quality: "Luftqualität:",
                                    weather_aqi_good: "Gut",
                                    weather_aqi_moderate: "Mäßig",
                                    weather_aqi_sensitive: "Ungesund (Empfindliche)",
                                    weather_aqi_unhealthy: "Ungesund",
                                    weather_aqi_very_unhealthy: "Sehr ungesund",
                                    weather_aqi_hazardous: "Gefährlich",
                                    weather_hint_city: "{accept}: Hinzufügen | {left}{right}: Wechseln | {details}: Entfernen | {cancel}: Zurück"
        },
        it: {
            weather_title: "METEO",
            weather_search_placeholder: "Digita una città...",
            weather_feels_like: "Percepita:",
            weather_humidity: "Umidità:",
            weather_wind: "Vento:",
            weather_forecast: "Previsioni",
            weather_no_city: "Cerca una città per vedere il meteo",
            weather_error: "Errore di connessione. Riprova.",
            weather_search_results: "Risultati",
            weather_loading: "Caricamento...",
            weather_wmo_clear: "Sereno",
            weather_wmo_partly_cloudy: "Parzialmente nuvoloso",
            weather_wmo_overcast: "Coperto",
            weather_wmo_fog: "Nebbia",
            weather_wmo_drizzle: "Pioviggine",
            weather_wmo_rain: "Pioggia",
            weather_wmo_snow: "Neve",
            weather_wmo_thunderstorm: "Temporale",
            weather_settings_title: "IMPOSTAZIONI METEO",
            weather_setting_city: "Cambia città",
            weather_setting_unit: "Unità di temperatura",
            weather_setting_unit_c: "Celsius (°C)",
                                    weather_setting_unit_f: "Fahrenheit (°F)",
                                    weather_setting_language: "Lingua",
                                    weather_language_auto: "Automatico (tema)",
                                    weather_back_hint: "{cancel}: Indietro | {details}: Impostazioni",
                                    weather_searching: "Ricerca...",
                                    weather_no_results: "Nessun risultato",
                                    weather_hint_menu: "{accept}: Seleziona | {cancel}: Indietro",
                                    weather_hint_search: "{accept}: Cerca | {down}: Risultati | {cancel}: Annulla",
                                    weather_hint_results: "{accept}: Seleziona | {up}: Cerca | {cancel}: Annulla",
                                    weather_setting_wind: "Unità del vento",
                                    weather_setting_days: "Giorni di previsione",
                                    weather_setting_details: "Dettagli extra",
                                    weather_days: "giorni",
                                    weather_option_on: "Attivo",
                                    weather_option_off: "Disattivo",
                                    weather_rain_chance: "Pioggia:",
                                    weather_uv: "UV:",
                                    weather_sunrise: "Alba:",
                                    weather_sunset: "Tramonto:",
                                    weather_retry_hint: "{accept}: Riprova",
                                    weather_setting_time: "Formato orario",
                                    weather_setting_air: "Qualità dell'aria",
                                    weather_air_quality: "Qualità dell'aria:",
                                    weather_aqi_good: "Buona",
                                    weather_aqi_moderate: "Moderata",
                                    weather_aqi_sensitive: "Malsana (sensibili)",
                                    weather_aqi_unhealthy: "Malsana",
                                    weather_aqi_very_unhealthy: "Molto malsana",
                                    weather_aqi_hazardous: "Pericolosa",
                                    weather_hint_city: "{accept}: Aggiungi | {left}{right}: Cambia | {details}: Rimuovi | {cancel}: Indietro"
        }
    })

    function t(key) {
        if (!key) return "";
        var _ = root._reactive;

        var dict = root.strings[root.effective];
        if (dict && dict[key] !== undefined) return dict[key];

        var en = root.strings["en"];
        if (en && en[key] !== undefined) return en[key];

        console.warn("[WeatherLanguage] Clave no encontrada:", key);
        return key;
    }

    function dayShort(dayIndex) {
        var _ = root._reactive;
        var list = root.days[root.effective] || root.days["en"];
        return list[dayIndex] || "";
    }

    function languageLabel(code) {
        if (code === "auto") return root.t("weather_language_auto");
        for (var i = 0; i < root.availableLanguages.length; i++) {
            if (root.availableLanguages[i].code === code) return root.availableLanguages[i].name;
        }
        return code;
    }

    function _indexOf(code) {
        for (var i = 0; i < root.availableLanguages.length; i++) {
            if (root.availableLanguages[i].code === code) return i;
        }
        return -1;
    }

    function setLanguage(code) {
        if (root._indexOf(code) < 0) code = "auto";
        if (code === root.selected) return;
        root.selected = code;
        root.save();
    }

    function cycle(step) {
        var n = root.availableLanguages.length;
        var i = root._indexOf(root.selected);
        if (i < 0) i = 0;
        i = (i + step + n) % n;
        root.setLanguage(root.availableLanguages[i].code);
    }

    function load() {
        if (api.memory.has(root.memoryKey)) {
            var stored = api.memory.get(root.memoryKey);
            if (typeof stored === "string" && root._indexOf(stored) >= 0) root.selected = stored;
        }
    }

    function save() {
        api.memory.set(root.memoryKey, root.selected);
    }

    Component.onCompleted: root.load()
}
