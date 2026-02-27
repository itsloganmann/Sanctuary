//
//  AgreementListView.swift
//  Sanctuary
//
//  View existing consent agreements
//

import SwiftUI

struct AgreementListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.sanctuaryBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignTokens.spacingMedium) {
                        ForEach(appState.agreements) { agreement in
                            agreementCard(agreement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Agreements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.safetyOrange)
                }
            }
        }
    }
    
    private func agreementCard(_ agreement: MockAgreement) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.spacingSmall) {
            HStack {
                Circle()
                    .fill(Color.pink.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(agreement.partnerName.prefix(1))
                            .font(.headlineSmall)
                            .foregroundStyle(.pink)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agreement with \(agreement.partnerName)")
                        .font(.headlineSmall)
                        .foregroundStyle(.white)
                    Text("\(agreement.boundaryCount) boundaries set")
                        .font(.bodySmall)
                        .foregroundStyle(Color.textSecondary)
                }
                
                Spacer()
                
                Text(agreement.status)
                    .font(.labelSmall)
                    .foregroundStyle(agreement.status == "Active" ? Color.statusSafe : Color.statusWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (agreement.status == "Active" ? Color.statusSafe : Color.statusWarning).opacity(0.15)
                    )
                    .clipShape(Capsule())
            }
            
            HStack {
                Image(systemName: "calendar")
                    .font(.labelSmall)
                    .foregroundStyle(Color.textTertiary)
                Text(agreement.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.labelSmall)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(DesignTokens.spacingMedium)
        .sanctuaryCard()
        .accessibilityElement(children: .combine)
    }
}
