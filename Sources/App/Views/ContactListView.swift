import SwiftUI

struct ContactListView: View {
    let contacts: [Contact]
    @Binding var selectedContact: Contact?
    let searchText: String
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.name?.localizedCaseInsensitiveContains(searchText) ?? false ||
            contact.id.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(filteredContacts, selection: $selectedContact) { contact in
            ContactRow(contact: contact)
                .tag(contact)
        }
    }
}

