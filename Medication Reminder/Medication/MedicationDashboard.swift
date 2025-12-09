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
    
    // For delete confirmation
    @State private var showDeleteConfirm = false
    @State private var showDeleteSelectedConfirm = false
    @State private var medicationToDelete: Medication?
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if medications.isEmpty {
                    // Empty state full-screen section
                    VStack(spacing: 16) {
                        Image(systemName: "pills.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 88, height: 88)
                            .foregroundStyle(.tint)
                        Text("No medication reminders yet")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Tap + to add a medication and set reminders. Keeping a regular routine helps maintain medication adherence.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        NavigationLink(destination: EditMedicationView(medication: nil)) {
                                       AddMedButton()
                                   }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
                    .listRowBackground(Color.clear)
                } else {
                    List(selection: $selectedIDs) {
                        ForEach(medications) { medication in
                            NavigationLink {
                                EditMedicationView(medication: medication)
                            } label: {
                                MedicationRowView(medication: medication)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    DispatchQueue.main.async {
                                        medicationToDelete = medication
                                        
                                        showDeleteConfirm = true
                                    }
                                    
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    // quick share: plain summary
                                    share(medication)
                                } label: {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .tint(.green)
                            }
                            .contextMenu {
                                Button("Edit", systemImage: "pencil") { isEditing = true }
                                Button("Share", systemImage: "square.and.arrow.up") { share(medication) }
                                Button(role: .destructive) {
                                    DispatchQueue.main.async {
                                        medicationToDelete = medication
                                        showDeleteConfirm = true
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button {
                            shareSelected()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .disabled(selectedIDs.isEmpty)
                        Button {
                            showDeleteSelectedConfirm = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .disabled(selectedIDs.isEmpty)
                        
                    } else if !medications.isEmpty {
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
            .confirmationDialog("Are you sure you want to delete selected medications?", isPresented: $showDeleteSelectedConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteSelected()
                    medicationToDelete = nil
                    showDeleteConfirm = false
                }
                Button("Cancel", role: .cancel) {
                    medicationToDelete = nil
                    showDeleteConfirm = false
                }
            }
            .confirmationDialog("Are you sure you want to delete this medication?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    delete(medicationToDelete)
                    medicationToDelete = nil
                    showDeleteConfirm = false
                }
                Button("Cancel", role: .cancel) {
                    medicationToDelete = nil
                    showDeleteConfirm = false
                }
            }
        }
        .alert(error: $error)
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Actions
    
    private func delete(_ med: Medication?) {
        if let medication = med {
            modelContext.delete(medication)
            do {
                try modelContext.save()
            } catch {
                self.error = error
            }
        }
    }
    
    private func deleteSelected() {
        guard !selectedIDs.isEmpty else { return }
        // Determine medications matching the selected persistent IDs
        let medsToDelete = medications.filter { selectedIDs.contains($0.persistentModelID) }
        for med in medsToDelete {
            modelContext.delete(med)
        }
        try? modelContext.save()
        // Clear selection and exit edit mode
        selectedIDs.removeAll()
        withAnimation { isEditing = false }
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

