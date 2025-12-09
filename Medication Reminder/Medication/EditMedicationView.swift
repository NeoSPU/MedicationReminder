//
//  EditMedicationView.swift
//  Medication Reminder
//
//  Created by Udacity

import SwiftUI
import SwiftData

// a view to edit medication

struct EditMedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let medication: Medication?
    
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var time: Date = Date()
    @State private var isReminderSet: Bool = false
    
    // For delete confirmation
    @State private var showDeleteConfirm = false
    
    init(medication: Medication?) {
        self.medication = medication
        // state variables will be set in onAppear to keep initializer SwiftUI-friendly
    }
    
    var body: some View {
        Form {
            Section(header: Text("Medication Info")) {
                TextField("Name (e.g. Vitamin D)", text: $name)
                    .accessibilityHint("Enter medication name")
                TextField("Dosage (e.g. 1000 IU / 100 mg)", text: $dosage)
                    .keyboardType(.default)
                    .accessibilityHint("Enter dosage and units")
            }
            
            Section(header: Text("Reminder")) {
                DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                    .accessibilityLabel("Reminder time")
                Toggle("Enable reminder", isOn: $isReminderSet)
                    .accessibilityHint("Toggle on to receive reminders")
            }
            
            if medication != nil {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete Medication", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(medication == nil ? "Add Medication" : "Edit Medication")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!isValid)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .onAppear {
            if let m = medication {
                name = m.name
                dosage = m.dosage
                time = m.time
                isReminderSet = m.isReminderSet
            } else {
                // sensible defaults
                time = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            }
        }
        .confirmationDialog("Are you sure you want to delete this medication?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteAndDismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Helpers
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func save() {
        if let existing = medication {
            existing.name = name
            existing.dosage = dosage
            existing.time = time
            existing.isReminderSet = isReminderSet
        } else {
            let newMed = Medication(name: name, dosage: dosage, time: time, isReminderSet: isReminderSet)
            modelContext.insert(newMed)
        }
        try? modelContext.save()
        dismiss()
    }
    
    private func deleteAndDismiss() {
        if let m = medication {
            modelContext.delete(m)
            try? modelContext.save()
        }
        dismiss()
    }
}

