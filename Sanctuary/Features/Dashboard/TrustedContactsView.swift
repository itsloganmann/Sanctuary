import SwiftUI

struct TrustedContactsView: View {
    init() {
        print("TrustedContactsView INIT")
    }
    @Environment(DependencyContainer.self) private var dependencies
    @State private var contacts: [TrustedContact] = []
    @State private var isLoading = false
    @State private var showAddContact = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Text("DEBUG: TrustedContactsView loaded")
                .foregroundColor(.red)
            ZStack {
                if isLoading {
                    ProgressView("Loading contacts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contacts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No trusted contacts yet.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Add a trusted contact to receive alerts in an emergency.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(contacts) { contact in
                            VStack(alignment: .leading) {
                                Text(contact.displayName)
                                    .font(.headline)
                                Text(contact.phoneNumber ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: deleteContact)
                    }
                }
            }
            .navigationTitle("Trusted Contacts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddContact = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddTrustedContactView(onAdd: { _ in
                    loadContacts()
                })
            }
            .onAppear(perform: loadContacts)
            .alert(isPresented: .constant(errorMessage != nil), content: {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK"), action: { errorMessage = nil }))
            })
        }
    }
    
    func loadContacts() {
        isLoading = true
    print("loadContacts() called")
    Task {
            guard let userId = dependencies.authManager.currentUser?.id else {
                errorMessage = "Not authenticated. Please log in."
                isLoading = false
                return
            }
            print("Current user ID: \(userId.uuidString)")
            do {
                contacts = try await dependencies.profileRepository.getTrustedContacts(for: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func deleteContact(at offsets: IndexSet) {
        let toDelete = offsets.map { contacts[$0] }
        Task {
            for contact in toDelete {
                do {
                    guard let userId = dependencies.authManager.currentUser?.id else {
                        errorMessage = "Not authenticated. Please log in."
                        return
                    }
                    try await dependencies.profileRepository.removeTrustedContact(for: userId, contactId: contact.id)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            loadContacts()
        }
    }
}

struct AddTrustedContactView: View {
    @Environment(DependencyContainer.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onAdd: (TrustedContact) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Info")) {
                    TextField("Name", text: $displayName)
                        .disabled(isLoading)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .disabled(isLoading)
                }
                if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
            .overlay(
                Task {
                    print("loadContacts() called")
                    print("authManager.currentUser: \(String(describing: dependencies.authManager.currentUser))")
                    guard let userId = dependencies.authManager.currentUser?.id else {
                        errorMessage = "Not authenticated. Please log in."
                        isLoading = false
                        return
                    }
                    print("Current user ID: \(userId.uuidString)")
                    do {
                        contacts = try await dependencies.profileRepository.getTrustedContacts(for: userId)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
                    .disabled(displayName.isEmpty || phoneNumber.isEmpty || isLoading)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isLoading)
                }
            }
        }
    }
    
    func addContact() {
        isLoading = true
        errorMessage = nil
        Task {
            guard let userId = dependencies.authManager.currentUser?.id else {
                errorMessage = "Not authenticated. Please log in."
                isLoading = false
                return
            }
            do {
                let newProfile = try await dependencies.profileRepository.addTrustedContact(for: userId, displayName: displayName, phoneNumber: phoneNumber)
                let trustedContact = TrustedContact(
                    id: newProfile.id,
                    displayName: newProfile.displayName,
                    phoneNumber: newProfile.phoneNumber,
                    relationType: .emergency // Default or fetch actual relationType if available
                )
                onAdd(trustedContact)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
