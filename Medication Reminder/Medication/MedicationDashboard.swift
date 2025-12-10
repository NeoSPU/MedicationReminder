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
    
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    
    // For delete confirmation
    @State private var showDeleteConfirm = false
    @State private var showDeleteSelectedConfirm = false
    @State private var medicationToDelete: Medication?
    @State private var error: Error?
    @State private var isEditing = false
    
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
                        Text(NSLocalizedString("empty_title", comment: "Empty state title"))
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(NSLocalizedString("empty_subtitle", comment: "Empty state subtitle"))
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
                                    medicationToDelete = medication
                                    showDeleteConfirm = true
                                } label: {
                                    Label(NSLocalizedString("delete", comment: "Delete"), systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    // quick share: plain summary
                                    share(medication)
                                } label: {
                                    Label(NSLocalizedString("share", comment: "Share"), systemImage: "square.and.arrow.up")
                                }
                                .tint(.green)
                            }
                            .contextMenu {
                                Button(NSLocalizedString("share", comment: "Share"), systemImage: "square.and.arrow.up") { share(medication) }
                                Button(role: .destructive) {
                                    medicationToDelete = medication
                                    showDeleteConfirm = true
                                } label: {
                                    Label(NSLocalizedString("delete", comment: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                    .environment(\.editMode, .constant(isEditing ? .active : .inactive))
                    .toolbar {
                        // Left button
                        ToolbarItem(placement: .navigationBarLeading) {
                            if isEditing {
                                Button(NSLocalizedString("cancel", comment: "Cancel")) {
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
                                .accessibilityLabel(Text(NSLocalizedString("share", comment: "Share")))
                                .accessibilityHint(Text(NSLocalizedString("share_selected_hint", comment: "Share selected items")))
                                Button {
                                    showDeleteSelectedConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .disabled(selectedIDs.isEmpty)
                                .accessibilityLabel(Text(NSLocalizedString("delete", comment: "Delete")))
                                .accessibilityHint(Text(NSLocalizedString("delete_selected_hint", comment: "Delete selected items")))
                            } else if !medications.isEmpty && !medications.isEmpty {
                                NavigationLink {
                                    EditMedicationView(medication: nil)
                                } label: {
                                    Label(NSLocalizedString("add_medication", comment: "Add Medication"), systemImage: "plus")
                                        .font(.title3)
                                }
                                .accessibilityLabel(Text(NSLocalizedString("add_medication", comment: "Add Medication")))
                                .accessibilityHint(Text(NSLocalizedString("add_medication_hint", comment: "Add a new medication")))
                                Button("Edit") {
                                    withAnimation { isEditing = true }
                                }
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 8) }
            .confirmationDialog(String(format: NSLocalizedString("delete_count_title", comment: "Delete count title"), selectedIDs.count) + "\n" + NSLocalizedString("irreversible", comment: "Irreversible warning"), isPresented: $showDeleteSelectedConfirm, titleVisibility: .visible) {
                Button(role: .destructive) {
                    deleteSelected()
                    medicationToDelete = nil
                } label: {
                    Text(NSLocalizedString("delete", comment: "Delete"))
                }
                Button(role: .cancel) {
                    medicationToDelete = nil
                } label: {
                    Text(NSLocalizedString("cancel", comment: "Cancel"))
                }
            }
            .confirmationDialog(NSLocalizedString("delete_one_title", comment: "Delete one title") + "\n" + NSLocalizedString("irreversible", comment: "Irreversible warning"), isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button(role: .destructive) {
                    delete(medicationToDelete)
                    medicationToDelete = nil
                } label: {
                    Text(NSLocalizedString("delete", comment: "Delete"))
                }
                Button(role: .cancel) {
                    medicationToDelete = nil
                } label: {
                    Text(NSLocalizedString("cancel", comment: "Cancel"))
                }
            }
        }
        .alert(NSLocalizedString("error_title", comment: "Error"), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button(NSLocalizedString("ok", comment: "OK"), role: .cancel) { error = nil }
        } message: {
            Text(friendlyErrorMessage(for: error))
        }
        .navigationTitle(NSLocalizedString("medications_title", comment: "Medications"))
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
        let headerName = String(format: NSLocalizedString("share_name", comment: ""), med.name)
        let headerDosage = String(format: NSLocalizedString("share_dosage", comment: ""), med.dosage)
        let headerTime = String(format: NSLocalizedString("share_time", comment: ""), formatter.string(from: med.time))
        let reminder = med.isReminderSet ? NSLocalizedString("share_reminder_on", comment: "") : NSLocalizedString("share_reminder_off", comment: "")
        var parts: [String] = []
        parts.append(NSLocalizedString("share_header", comment: ""))
        parts.append(NSLocalizedString("share_separator", comment: ""))
        parts.append(headerName)
        parts.append(headerDosage)
        parts.append(headerTime)
        parts.append(reminder)
        let text = parts.joined(separator: "\n")
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let pop = av.popoverPresentationController {
            pop.sourceView = UIApplication.shared.topMostController?.view
            pop.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY - 50, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
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
        
        lines.append(NSLocalizedString("share_header", comment: ""))
        lines.append(NSLocalizedString("share_separator", comment: ""))
        lines.append(String.localizedStringWithFormat(NSLocalizedString("share_total_items", comment: ""), selectedMedications.count) + "\n")
        
        for med in selectedMedications {
            lines.append(String(format: NSLocalizedString("share_name", comment: ""), med.name))
            lines.append(String(format: NSLocalizedString("share_dosage", comment: ""), med.dosage))
            lines.append(String(format: NSLocalizedString("share_time", comment: ""), formatter.string(from: med.time)))
            lines.append(med.isReminderSet ? NSLocalizedString("share_reminder_on", comment: "") : NSLocalizedString("share_reminder_off", comment: ""))
            lines.append("") // spacing between items
        }
        
        let text = lines.joined(separator: "\n")
        
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let pop = av.popoverPresentationController {
            pop.sourceView = UIApplication.shared.topMostController?.view
            pop.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY - 50, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        UIApplication.shared.topMostController?.present(av, animated: true)
    }
    
    private func friendlyErrorMessage(for error: Error?) -> String {
        guard let error = error as NSError? else { return NSLocalizedString("unknown_error", comment: "Unknown error") }
        // Map by domain/code if desired; fallback to generic
        switch (error.domain, error.code) {
        default:
            return NSLocalizedString("generic_error_message", comment: "Something went wrong. Please try again." )
        }
    }
}

