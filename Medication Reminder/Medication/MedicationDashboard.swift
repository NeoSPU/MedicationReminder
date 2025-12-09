//
//  MedicationDashboard.swift
//  Medication Reminder
//
//  Created by Udacity
//

import SwiftUI
import SwiftData
import UIKit

struct MedicationDashboard: View {
    @Query(sort: [SortDescriptor(\Medication.name, order: .forward)]) private var medications: [Medication]
    @Environment(\.modelContext) private var modelContext
    
    @State private var isEditing = false
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                
                // Apple Health Style Big Header
                Text("Medications")
                    .font(.largeTitle.bold())
                    .padding(.horizontal)
                
                if medications.isEmpty {
                    ContentUnavailableView("No Medications",
                                           systemImage: "pills",
                                           description: Text("Add your first medication reminder"))
                } else {
                    List(selection: $selectedIDs) {
                        ForEach(medications) { medication in
                            NavigationLink {
                                EditMedicationView(medication: medication)
                            } label: {
                                MedicationRowView(medication: medication)
                            }
                        }
                    }
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                }
            }
            .toolbar {
                // Left button
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") {
                            isEditing = false
                            selectedIDs.removeAll()
                        }
                    }
                }
                
                // Right button
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button {
                            shareSelected()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(selectedIDs.isEmpty)
                        
                    } else {
                        Button("Edit") {
                            withAnimation { isEditing = true }
                        }
                    }
                }
                
                // Add button (only outside editing)
                ToolbarItem(placement: .bottomBar) {
                    if !isEditing {
                        NavigationLink {
                            EditMedicationView(medication: nil)
                        } label: {
                            Label("Add Medication", systemImage: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func delete(_ med: Medication) {
        modelContext.delete(med)
        try? modelContext.save()
    }
    
    private func deleteIndexSet(_ offsets: IndexSet) {
        for index in offsets {
            let med = medications[index]
            modelContext.delete(med)
        }
        try? modelContext.save()
    }
    
    private func share(_ med: Medication) {
        // Build a plain text summary and present UIActivityViewController via ShareSheet helper
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let text = """
            Medication: \(med.name)
            Dosage: \(med.dosage)
            Time: \(formatter.string(from: med.time))
            Reminder: \(med.isReminderSet ? "On" : "Off")
            """
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.topMostController?.present(av, animated: true)
    }
    
    private func shareSelected() {
        guard !selectedIDs.isEmpty else { return }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        // filter medications by selection
        let selectedMedications = medications.filter { selectedIDs.contains($0.persistentModelID) }
        
        // Build a multi-item export
        var lines: [String] = []
        
        lines.append("Medication Summary")
        lines.append("----------------------")
        lines.append("Total items: \(selectedMedications.count)\n")
        
        for med in selectedMedications {
            lines.append("Name: \(med.name)")
            lines.append("Dosage: \(med.dosage)")
            lines.append("Time: \(formatter.string(from: med.time))")
            lines.append("Reminder: \(med.isReminderSet ? "On" : "Off")")
            lines.append("") // spacing between items
        }
        
        let text = lines.joined(separator: "\n")
        
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.topMostController?.present(av, animated: true)
    }
}

