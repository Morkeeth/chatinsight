import Foundation
import WeatherKit
import CoreLocation

/// Weather tool - provides weather information
@available(macOS 13.0, *)
public class WeatherTool: MCPToolProtocol {
    public let name = "getWeather"
    public let description = "Get current weather conditions for a location (latitude/longitude or address)."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "latitude": [
                    "type": "number",
                    "description": "Latitude coordinate"
                ],
                "longitude": [
                    "type": "number",
                    "description": "Longitude coordinate"
                ],
                "address": [
                    "type": "string",
                    "description": "Address to get weather for (alternative to lat/lon)"
                ]
            ]
        ]
    }
    
    private let weatherService = WeatherService.shared
    
    public init() {}
    
    public func execute(arguments: [String: Any]) async throws -> String {
        // Get location either from coordinates or address
        let location: CLLocation
        
        if let lat = arguments["latitude"] as? Double,
           let lon = arguments["longitude"] as? Double {
            location = CLLocation(latitude: lat, longitude: lon)
        } else if let address = arguments["address"] as? String {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let placemark = placemarks.first,
                  let placeLocation = placemark.location else {
                throw MCPToolError.executionFailed("Could not geocode address")
            }
            location = placeLocation
        } else {
            throw MCPToolError.missingArgument("Either latitude/longitude or address is required")
        }
        
        // Fetch weather
        let weather = try await weatherService.weather(for: location)
        
        // Convert to JSON-LD-like format
        let weatherData: [String: Any] = [
            "@context": "https://schema.org",
            "@type": "WeatherForecast",
            "location": [
                "@type": "GeoCoordinates",
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ],
            "currentConditions": [
                "temperature": [
                    "value": weather.currentWeather.temperature.value,
                    "unit": "Celsius"
                ],
                "apparentTemperature": [
                    "value": weather.currentWeather.apparentTemperature.value,
                    "unit": "Celsius"
                ],
                "humidity": weather.currentWeather.humidity,
                "pressure": [
                    "value": weather.currentWeather.pressure.value,
                    "unit": "millibars"
                ],
                "windSpeed": [
                    "value": weather.currentWeather.wind.speed.value,
                    "unit": "km/h"
                ],
                "windDirection": [
                    "value": weather.currentWeather.wind.direction.value,
                    "unit": "degrees"
                ],
                "condition": weather.currentWeather.condition.description,
                "uvIndex": weather.currentWeather.uvIndex.value,
                "visibility": [
                    "value": weather.currentWeather.visibility.value,
                    "unit": "meters"
                ]
            ]
        ]
        
        return formatJSONLD(weatherData)
    }
}

