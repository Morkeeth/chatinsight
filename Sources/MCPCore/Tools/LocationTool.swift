import Foundation
import CoreLocation

/// Location tool - provides current location
public class LocationTool: NSObject, MCPToolProtocol {
    public let name = "getCurrentLocation"
    public let description = "Get the current location (latitude, longitude, and address)."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [:]
        ]
    }
    
    private let locationManager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    
    public override init() {
        super.init()
        locationManager.delegate = self
    }
    
    public func execute(arguments: [String: Any]) async throws -> String {
        // Request authorization
        let authStatus = locationManager.authorizationStatus
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else {
            throw MCPToolError.permissionDenied("Location access denied. Please grant access through System Settings.")
        }
        
        // Get location
        let location = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CLLocation, Error>) in
            self.continuation = continuation
            locationManager.requestLocation()
        }
        
        // Reverse geocode
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        let place = placemarks.first
        
        // Create JSON-LD Place
        let address = JSONLD.PostalAddress(
            streetAddress: place?.thoroughfare,
            addressLocality: place?.locality,
            addressRegion: place?.administrativeArea,
            postalCode: place?.postalCode,
            addressCountry: place?.country
        )
        
        let jsonLDPlace = JSONLD.Place(
            name: place?.name,
            address: address,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        return formatJSONLD(jsonLDPlace.toJSONLD())
    }
}

extension LocationTool: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            continuation?.resume(returning: location)
            continuation = nil
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

/// Geocoding tool - convert address to coordinates
public class GeocodeTool: MCPToolProtocol {
    public let name = "geocodeAddress"
    public let description = "Convert an address string to geographic coordinates (latitude and longitude)."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "address": [
                    "type": "string",
                    "description": "Address to geocode (e.g., '1 Apple Park Way, Cupertino, CA')"
                ]
            ],
            "required": ["address"]
        ]
    }
    
    public init() {}
    
    public func execute(arguments: [String: Any]) async throws -> String {
        guard let address = arguments["address"] as? String else {
            throw MCPToolError.missingArgument("address")
        }
        
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(address)
        
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw MCPToolError.executionFailed("Could not geocode address")
        }
        
        let postalAddress = JSONLD.PostalAddress(
            streetAddress: placemark.thoroughfare,
            addressLocality: placemark.locality,
            addressRegion: placemark.administrativeArea,
            postalCode: placemark.postalCode,
            addressCountry: placemark.country
        )
        
        let place = JSONLD.Place(
            name: placemark.name,
            address: postalAddress,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        return formatJSONLD(place.toJSONLD())
    }
}

