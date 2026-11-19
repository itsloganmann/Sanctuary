//
//  TrustedContactsListView.swift
//  Sanctuary
//
//  Manage trusted emergency contacts (mock data, offline)
//

import SwiftUI

struct TrustedContactsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var showAddContact = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sanctuaryBlack.ignoresSafeArea()
                
                if appState.trustedContacts.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(appState.trustedContacts) { contact in
                            contactRow(contact)
                                .listRowBackground(Color.cardBackground)
                        }
                        .onDelete(perform: deleteContact)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Trusted Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.safetyOrange)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddContact = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddContact) {
                AddContactView()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No trusted contacts yet")
                .font(.headlineMedium)
                .foregroundStyle(.secondary)
            Text("Add contacts who should receive alerts in an emergency.")
                .font(.bodyMedium)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    private func contactRow(_ contact: TrustedContact) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.safetyOrange.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(contact.name.prefix(1).uppercased())
                        .font(.headlineSmall)
                        .foregroundStyle(Color.safetyOrange)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.headlineSmall)
                    .foregroundStyle(.white)
                Text(contact.phone)
                    .font(.bodySmall)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            Text(contact.relation)
                .font(.labelSmall)
                .foregroundStyle(Color.safetyOrange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.safetyOrange.opacity(0.15))
                .clipShape(Capsule())
        }
        .accessibilityElement(children: .combine)
    }
    
    private func deleteContact(at offsets: IndexSet) {
        appState.trustedContacts.remove(atOffsets: offsets)
    }
}

// MARK: - Add Contact

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var name = ""
    @State private var phone = ""
    @State private var relation = "Friend"
    
    private let relations = ["Family", "Friend", "Partner", "Emergency"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Info") {
                    TextField("Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
                Section("Relationship") {
                    Picker("Type", selection: $relation) {
                        ForEach(relations, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        appState.trustedContacts.append(
                            TrustedContact(name: name, phone: phone, relation: relation, isNotified: false)
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
        }
    }
}
