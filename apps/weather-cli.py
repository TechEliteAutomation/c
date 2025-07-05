#!/usr/bin/env python3
#
# weather-cli: A comprehensive command-line weather dashboard.
# NOTE: This version uses only the free-tier OpenWeatherMap APIs.
#

import argparse
import configparser
import json
import os
import sys
import time
from collections import Counter
from datetime import datetime

import requests

# --- Configuration & Constants ---
CACHE_DIR = os.path.join(os.path.expanduser("~"), ".cache")
CACHE_FILE = os.path.join(CACHE_DIR, "weather-cli.json")
CACHE_DURATION_SECONDS = 900  # 15 minutes


# --- Color & Formatting Helpers ---
class Colors:
    RED = "\033[91m"
    ORANGE = "\033[93m"
    YELLOW = "\033[33m"
    GREEN = "\033[92m"
    BLUE = "\033[94m"
    PURPLE = "\033[95m"
    CYAN = "\033[96m"
    RESET = "\033[0m"
    BOLD = "\033[1m"


def get_temp_color(temp, units):
    if units == "imperial":
        if temp >= 90:
            return Colors.RED
        if temp >= 75:
            return Colors.ORANGE
        if temp <= 40:
            return Colors.BLUE
    else:
        if temp >= 32:
            return Colors.RED
        if temp >= 24:
            return Colors.ORANGE
        if temp <= 5:
            return Colors.BLUE
    return Colors.RESET


def get_aqi_info(aqi_index):
    aqi_map = {
        1: (Colors.GREEN, "Good"),
        2: (Colors.YELLOW, "Fair"),
        3: (Colors.ORANGE, "Moderate"),
        4: (Colors.RED, "Poor"),
        5: (Colors.PURPLE, "Very Poor"),
    }
    return aqi_map.get(aqi_index, (Colors.RESET, "Unknown"))


WEATHER_ICONS = {
    "01d": "🌞",
    "01n": "🌙",
    "02d": "🌤️",
    "02n": "🌤️",
    "03d": "☁️",
    "03n": "☁️",
    "04d": "🌥️",
    "04n": "🌥️",
    "09d": "🌧️",
    "09n": "🌧️",
    "10d": "🌦️",
    "10n": "🌦️",
    "11d": "🌩️",
    "11n": "🌩️",
    "13d": "❄️",
    "13n": "❄️",
    "50d": "🌫️",
    "50n": "🌫️",
}


def get_wind_direction_arrow(degrees):
    arrows = [
        "↓",
        "↙",
        "↙",
        "↙",
        "←",
        "↖",
        "↖",
        "↖",
        "↑",
        "↗",
        "↗",
        "↗",
        "→",
        "↘",
        "↘",
        "↘",
    ]
    index = int(((degrees + 11) % 360) / 22)
    return arrows[index]


# --- Clothing Suggestion Logic ---
def get_clothing_suggestions(current_weather, units):
    """Generates GENERAL clothing suggestions based on weather conditions."""
    feels_like = current_weather["main"]["feels_like"]
    description = current_weather["weather"][0]["description"].lower()
    feels_like_f = (feels_like * 9 / 5) + 32 if units == "metric" else feels_like

    suggestions = {
        "Top": "T-Shirt",
        "Bottom": "Shorts",
        "Outerwear": "None",
        "Footwear": "Sandals",
        "Accessory": "Sunglasses",
    }

    if 65 <= feels_like_f < 75:
        suggestions.update({"Bottom": "Jeans / Trousers", "Footwear": "Sneakers"})
    elif 55 <= feels_like_f < 65:
        suggestions.update(
            {
                "Top": "Long-sleeve Shirt",
                "Bottom": "Jeans",
                "Footwear": "Sneakers",
            }
        )
    elif 45 <= feels_like_f < 55:
        suggestions.update(
            {
                "Top": "Sweater",
                "Bottom": "Jeans",
                "Outerwear": "Light Jacket",
                "Footwear": "Shoes / Boots",
            }
        )
    elif 32 <= feels_like_f < 45:
        suggestions.update(
            {
                "Top": "Sweater / Fleece",
                "Bottom": "Trousers",
                "Outerwear": "Warm Jacket",
                "Footwear": "Boots",
                "Accessory": "Beanie",
            }
        )
    elif feels_like_f < 32:
        suggestions.update(
            {
                "Top": "Thermal Layer",
                "Bottom": "Insulated Trousers",
                "Outerwear": "Heavy Winter Coat",
                "Footwear": "Insulated Boots",
                "Accessory": "Beanie & Gloves",
            }
        )

    if "rain" in description or "drizzle" in description:
        if suggestions["Outerwear"] == "None":
            suggestions["Outerwear"] = "Waterproof Jacket"
        if "Boots" not in suggestions["Footwear"]:
            suggestions["Footwear"] = "Waterproof Shoes"
        suggestions["Accessory"] = "Umbrella"
    elif "snow" in description:
        suggestions["Outerwear"] = "Waterproof Winter Coat"
        suggestions["Footwear"] = "Waterproof Boots"

    return suggestions


# --- Caching, API, and Data Processing ---
def load_cache():
    if not os.path.exists(CACHE_FILE):
        return {}
    try:
        with open(CACHE_FILE, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {}


def save_cache(data):
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(CACHE_FILE, "w") as f:
        json.dump(data, f)


def read_config():
    config_path = os.path.join(
        os.path.expanduser("~"), ".config", "weather", "config.ini"
    )
    if not os.path.exists(config_path):
        print(f"Error: Config file not found at {config_path}", file=sys.stderr)
        sys.exit(1)
    parser = configparser.ConfigParser()
    parser.read(config_path)
    try:
        return {
            "api_key": parser.get("openweathermap", "api_key"),
            "latitude": parser.get("openweathermap", "latitude"),
            "longitude": parser.get("openweathermap", "longitude"),
            "units": parser.get("openweathermap", "units", fallback="metric"),
        }
    except (configparser.NoSectionError, configparser.NoOptionError) as e:
        print(f"Error: Missing config in {config_path}: {e}", file=sys.stderr)
        sys.exit(1)


def get_api_data(endpoint, config, cache):
    """Generic function to fetch data, using cache if valid."""
    cache_key = endpoint.split("/")[0]

    is_cache_valid = (
        cache_key in cache
        and time.time() - cache.get(cache_key, {}).get("timestamp", 0)
        < CACHE_DURATION_SECONDS
    )
    if is_cache_valid:
        return cache[cache_key]["data"]

    print(f"Fetching new '{cache_key}' data from API...", file=sys.stderr)
    base_url = "https://api.openweathermap.org/data/2.5/"
    url = (
        f"{base_url}{endpoint}?"
        f"lat={config['latitude']}&lon={config['longitude']}"
        f"&appid={config['api_key']}&units={config['units']}"
    )
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        data = response.json()
        cache[cache_key] = {"timestamp": time.time(), "data": data}
        return data
    except requests.exceptions.RequestException as e:
        print(f"Error retrieving '{cache_key}' data: {e}", file=sys.stderr)
        return cache.get(cache_key, {}).get("data")


# --- Display Functions ---
def display_current_weather(data, units):
    if not data:
        return
    location = data.get("name", "Unknown Location")
    icon = WEATHER_ICONS.get(data["weather"][0]["icon"], "❓")
    description = data["weather"][0]["description"].capitalize()
    temp, feels_like = data["main"]["temp"], data["main"]["feels_like"]
    humidity = data["main"]["humidity"]
    wind_speed = data["wind"]["speed"]
    wind_arrow = get_wind_direction_arrow(data["wind"].get("deg", 0))

    temp_color = get_temp_color(temp, units)
    temp_unit = "°F" if units == "imperial" else "°C"
    speed_unit = "mph" if units == "imperial" else "m/s"

    print(f"{Colors.BOLD}Weather for {location}{Colors.RESET}")
    print(
        f" {icon} {description} | {temp_color}{temp:.1f}{temp_unit}"
        f"{Colors.RESET} (Feels like: {feels_like:.1f}{temp_unit})"
    )
    print(f" Wind: {wind_arrow} {wind_speed:.1f} {speed_unit} | Humidity: {humidity}%")


def display_aqi(data):
    if not data or "list" not in data:
        return
    aqi_index = data["list"][0]["main"]["aqi"]
    color, desc = get_aqi_info(aqi_index)
    print(f" Air Quality: {color}{desc}{Colors.RESET}")


def display_clothing_suggestions(suggestions):
    print(f"\n{Colors.BOLD}Clothing Suggestion:{Colors.RESET}")
    filtered = {k: v for k, v in suggestions.items() if v != "None"}
    items = list(filtered.items())
    half = (len(items) + 1) // 2
    for i in range(half):
        part1 = f" {Colors.CYAN}{items[i][0]}:{Colors.RESET} {items[i][1]:<25}"
        part2 = ""
        if i + half < len(items):
            part2 = (
                f"{Colors.CYAN}{items[i + half][0]}:{Colors.RESET} {items[i + half][1]}"
            )
        print(part1 + part2)


# You can copy/paste this into your editor, replacing the existing function.
def display_daily_forecast(data, units):
    if not data or "list" not in data:
        return

    daily_data = {}
    for entry in data["list"]:
        day = datetime.fromtimestamp(entry["dt"]).strftime("%Y-%m-%d")
        if day not in daily_data:
            daily_data[day] = {"temps": [], "icons": []}
        daily_data[day]["temps"].append(entry["main"]["temp"])
        daily_data[day]["icons"].append(entry["weather"][0]["icon"])

    print(f"\n{Colors.BOLD}5-Day Forecast:{Colors.RESET}")
    temp_unit = "°F" if units == "imperial" else "°C"

    for day, values in list(daily_data.items())[1:6]:
        day_name = datetime.strptime(day, "%Y-%m-%d").strftime("%a")
        low, high = min(values["temps"]), max(values["temps"])
        icon = WEATHER_ICONS.get(Counter(values["icons"]).most_common(1)[0][0], "❓")
        low_color, high_color = get_temp_color(low, units), get_temp_color(high, units)
        # This section is corrected to be under 88 characters per line.
        low_str = f"Low: {low_color}{low:.0f}{temp_unit}{Colors.RESET}"
        high_str = f"High: {high_color}{high:.0f}{temp_unit}{Colors.RESET}"
        print(f" {day_name}: {icon}  {low_str} | {high_str}")


# --- Main Execution ---
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="A command-line weather dashboard using free OWM APIs."
    )
    # No arguments are needed for this version.
    args = parser.parse_args()

    config = read_config()
    cache = load_cache()

    current_weather = get_api_data("weather", config, cache)
    forecast_data = get_api_data("forecast", config, cache)
    aqi_data = get_api_data("air_pollution", config, cache)

    save_cache(cache)

    if not current_weather:
        print("Could not retrieve current weather data. Exiting.", file=sys.stderr)
        sys.exit(1)

    display_current_weather(current_weather, config["units"])
    display_aqi(aqi_data)

    suggestions = get_clothing_suggestions(current_weather, config["units"])
    display_clothing_suggestions(suggestions)

    display_daily_forecast(forecast_data, config["units"])
