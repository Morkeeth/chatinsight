import Foundation

/// JSON-LD Context and Schema.org support
public struct JSONLD {
    /// Schema.org context
    public static let schemaOrgContext = "https://schema.org"
    
    /// Create a JSON-LD object with Schema.org context
    public static func object(type: String, properties: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [
            "@context": schemaOrgContext,
            "@type": type
        ]
        result.merge(properties) { (_, new) in new }
        return result
    }
}

// MARK: - Schema.org Types

public extension JSONLD {
    /// Person type (Schema.org/Person)
    struct Person {
        public let name: String
        public let givenName: String?
        public let familyName: String?
        public let email: String?
        public let telephone: String?
        public let url: String?
        public let image: String?
        
        public init(
            name: String,
            givenName: String? = nil,
            familyName: String? = nil,
            email: String? = nil,
            telephone: String? = nil,
            url: String? = nil,
            image: String? = nil
        ) {
            self.name = name
            self.givenName = givenName
            self.familyName = familyName
            self.email = email
            self.telephone = telephone
            self.url = url
            self.image = image
        }
        
        public func toJSONLD() -> [String: Any] {
            var props: [String: Any] = ["name": name]
            if let givenName = givenName { props["givenName"] = givenName }
            if let familyName = familyName { props["familyName"] = familyName }
            if let email = email { props["email"] = email }
            if let telephone = telephone { props["telephone"] = telephone }
            if let url = url { props["url"] = url }
            if let image = image { props["image"] = image }
            return JSONLD.object(type: "Person", properties: props)
        }
    }
    
    /// Message type (Schema.org/Message)
    struct Message {
        public let dateCreated: String
        public let text: String?
        public let sender: Person?
        public let recipient: Person?
        public let messageAttachment: [String]?
        
        public init(
            dateCreated: String,
            text: String? = nil,
            sender: Person? = nil,
            recipient: Person? = nil,
            messageAttachment: [String]? = nil
        ) {
            self.dateCreated = dateCreated
            self.text = text
            self.sender = sender
            self.recipient = recipient
            self.messageAttachment = messageAttachment
        }
        
        public func toJSONLD() -> [String: Any] {
            var props: [String: Any] = ["dateCreated": dateCreated]
            if let text = text { props["text"] = text }
            if let sender = sender { props["sender"] = sender.toJSONLD() }
            if let recipient = recipient { props["recipient"] = recipient.toJSONLD() }
            if let attachments = messageAttachment { props["messageAttachment"] = attachments }
            return JSONLD.object(type: "Message", properties: props)
        }
    }
    
    /// Event type (Schema.org/Event)
    struct Event {
        public let name: String
        public let startDate: String
        public let endDate: String?
        public let location: String?
        public let description: String?
        public let eventStatus: String?
        
        public init(
            name: String,
            startDate: String,
            endDate: String? = nil,
            location: String? = nil,
            description: String? = nil,
            eventStatus: String? = nil
        ) {
            self.name = name
            self.startDate = startDate
            self.endDate = endDate
            self.location = location
            self.description = description
            self.eventStatus = eventStatus
        }
        
        public func toJSONLD() -> [String: Any] {
            var props: [String: Any] = [
                "name": name,
                "startDate": startDate
            ]
            if let endDate = endDate { props["endDate"] = endDate }
            if let location = location { props["location"] = location }
            if let description = description { props["description"] = description }
            if let eventStatus = eventStatus { props["eventStatus"] = eventStatus }
            return JSONLD.object(type: "Event", properties: props)
        }
    }
    
    /// PostalAddress type (Schema.org/PostalAddress)
    struct PostalAddress {
        public let streetAddress: String?
        public let addressLocality: String?
        public let addressRegion: String?
        public let postalCode: String?
        public let addressCountry: String?
        
        public init(
            streetAddress: String? = nil,
            addressLocality: String? = nil,
            addressRegion: String? = nil,
            postalCode: String? = nil,
            addressCountry: String? = nil
        ) {
            self.streetAddress = streetAddress
            self.addressLocality = addressLocality
            self.addressRegion = addressRegion
            self.postalCode = postalCode
            self.addressCountry = addressCountry
        }
        
        public func toJSONLD() -> [String: Any] {
            var props: [String: Any] = [:]
            if let streetAddress = streetAddress { props["streetAddress"] = streetAddress }
            if let addressLocality = addressLocality { props["addressLocality"] = addressLocality }
            if let addressRegion = addressRegion { props["addressRegion"] = addressRegion }
            if let postalCode = postalCode { props["postalCode"] = postalCode }
            if let addressCountry = addressCountry { props["addressCountry"] = addressCountry }
            return JSONLD.object(type: "PostalAddress", properties: props)
        }
    }
    
    /// Place type (Schema.org/Place)
    struct Place {
        public let name: String?
        public let address: PostalAddress?
        public let geo: [String: Any]?
        
        public init(
            name: String? = nil,
            address: PostalAddress? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil
        ) {
            self.name = name
            self.address = address
            if let lat = latitude, let lon = longitude {
                self.geo = [
                    "@type": "GeoCoordinates",
                    "latitude": lat,
                    "longitude": lon
                ]
            } else {
                self.geo = nil
            }
        }
        
        public func toJSONLD() -> [String: Any] {
            var props: [String: Any] = [:]
            if let name = name { props["name"] = name }
            if let address = address { props["address"] = address.toJSONLD() }
            if let geo = geo { props["geo"] = geo }
            return JSONLD.object(type: "Place", properties: props)
        }
    }
}

