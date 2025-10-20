import Foundation
import Contacts

/// Contacts tool - provides access to system contacts
public class ContactsTool: MCPToolProtocol {
    public let name = "searchContacts"
    public let description = "Search contacts by name, phone number, or email address. Returns contacts as JSON-LD formatted data."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [
                "query": [
                    "type": "string",
                    "description": "Search query (name, phone number, or email)"
                ],
                "limit": [
                    "type": "number",
                    "description": "Maximum number of contacts to return. Defaults to 10."
                ]
            ],
            "required": ["query"]
        ]
    }
    
    private let contactStore = CNContactStore()
    
    public init() {}
    
    public func execute(arguments: [String: Any]) async throws -> String {
        guard let query = arguments["query"] as? String else {
            throw MCPToolError.missingArgument("query")
        }
        
        let limit = arguments["limit"] as? Int ?? 10
        
        // Check permission
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard authStatus == .authorized else {
            throw MCPToolError.permissionDenied("Contacts access not authorized. Please grant access through System Settings.")
        }
        
        // Search contacts
        let contacts = try await searchContacts(query: query, limit: limit)
        
        // Convert to JSON-LD
        let jsonLDContacts = contacts.map { contact in
            convertContactToJSONLD(contact)
        }
        
        return formatJSONLDArray(jsonLDContacts)
    }
    
    private func searchContacts(query: String, limit: Int) async throws -> [CNContact] {
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactImageDataKey as CNKeyDescriptor,
            CNContactUrlAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor
        ]
        
        var contacts: [CNContact] = []
        
        // Search by name
        let predicate = CNContact.predicateForContacts(matchingName: query)
        contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        
        // If no results, try searching by phone/email
        if contacts.isEmpty {
            let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
            
            try contactStore.enumerateContacts(with: fetchRequest) { contact, stop in
                // Check phone numbers
                for phoneNumber in contact.phoneNumbers {
                    if phoneNumber.value.stringValue.contains(query) {
                        contacts.append(contact)
                        if contacts.count >= limit {
                            stop.pointee = true
                        }
                        return
                    }
                }
                
                // Check emails
                for email in contact.emailAddresses {
                    if email.value.lowercased().contains(query.lowercased()) {
                        contacts.append(contact)
                        if contacts.count >= limit {
                            stop.pointee = true
                        }
                        return
                    }
                }
            }
        }
        
        return Array(contacts.prefix(limit))
    }
    
    private func convertContactToJSONLD(_ contact: CNContact) -> [String: Any] {
        let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        
        let email = contact.emailAddresses.first?.value as String?
        let phone = contact.phoneNumbers.first?.value.stringValue
        let url = contact.urlAddresses.first?.value as String?
        
        // Get postal address if available
        var address: JSONLD.PostalAddress?
        if let postalAddress = contact.postalAddresses.first?.value {
            address = JSONLD.PostalAddress(
                streetAddress: postalAddress.street,
                addressLocality: postalAddress.city,
                addressRegion: postalAddress.state,
                postalCode: postalAddress.postalCode,
                addressCountry: postalAddress.country
            )
        }
        
        var props: [String: Any] = [
            "name": fullName.isEmpty ? "Unknown" : fullName
        ]
        
        if !contact.givenName.isEmpty {
            props["givenName"] = contact.givenName
        }
        if !contact.familyName.isEmpty {
            props["familyName"] = contact.familyName
        }
        if let email = email {
            props["email"] = email
        }
        if let phone = phone {
            props["telephone"] = phone
        }
        if let url = url {
            props["url"] = url
        }
        if let address = address {
            props["address"] = address.toJSONLD()
        }
        
        return JSONLD.object(type: "Person", properties: props)
    }
}

/// Get current user contact info
public class MeContactTool: MCPToolProtocol {
    public let name = "getMe"
    public let description = "Get information about the current user (me card)."
    
    public var inputSchema: [String: Any] {
        return [
            "type": "object",
            "properties": [:]
        ]
    }
    
    private let contactStore = CNContactStore()
    
    public init() {}
    
    public func execute(arguments: [String: Any]) async throws -> String {
        let authStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard authStatus == .authorized else {
            throw MCPToolError.permissionDenied("Contacts access not authorized.")
        }
        
        guard let meContact = try? contactStore.unifiedMeContactWithKeys(toFetch: [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]) else {
            throw MCPToolError.executionFailed("Could not retrieve 'me' contact")
        }
        
        let person = JSONLD.Person(
            name: "\(meContact.givenName) \(meContact.familyName)",
            givenName: meContact.givenName,
            familyName: meContact.familyName,
            email: meContact.emailAddresses.first?.value as String?,
            telephone: meContact.phoneNumbers.first?.value.stringValue
        )
        
        return formatJSONLD(person.toJSONLD())
    }
}

