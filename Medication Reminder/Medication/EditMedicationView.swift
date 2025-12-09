//
//  EditMedicationView.swift
//  Medication Reminder
//
//  Created by Udacity

import SwiftUI
import SwiftData

// a view to edit medication

struct EditMedicationView: View {
    
    enum Mode: Hashable {
        case add
        case edit(Medication)
    }
    
    var mode: Mode
    
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            title = "Add Medication"
            _name = .init(initialValue: "")
            _dosage = .init(initialValue: "")
        case .edit(let medication):
            title = "Edit \(medication.name)"
            _name = .init(initialValue: medication.name)
            _dosage = .init(initialValue: medication.dosage)
            _time = .init(initialValue: medication.time)
            _isReminderSet = .init(initialValue: medication.isReminderSet)
        }
    }
    
    private let title: String
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var time: Date = Date()
    @State private var isReminderSet: Bool = false
    
    // For delete confirmation
    @State private var showDeleteConfirm = false
    
    @State private var error: Error?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var persistenceService: PersistenceService { PersistenceService(modelContext: modelContext) }
    
    // MARK: - Body

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
            
            if case .edit(let medication) = mode {
                Button(
                    role: .destructive,
                    action: {
                        delete(name: name)
                    },
                    label: {
                        Text("Delete Category")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                )
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .alert(error: $error)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save(name: name)
                }
                .disabled(!isValid)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this medication?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                   Button("Delete", role: .destructive) {
                       delete(name: name)
                   }
                   Button("Cancel", role: .cancel) {}
               }
    }
    
    // MARK: - Helpers
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dosage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Data
    
    private func delete(name: String) {
        Task {
            do {
                try PersistenceService(modelContext: modelContext).deleteMedication(name: name)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run { self.error = error }
            }
        }
    }
    
    private func save(name: String) {
        Task {
            do {
                switch mode {
                case .add:
                    try PersistenceService(modelContext: modelContext).addMedication(name: name, dosage: dosage, time: time, isReminderSet: isReminderSet)
                case .edit(_):
                    try PersistenceService(modelContext: modelContext).updateMedication(name: name)
                }
                await MainActor.run { dismiss() }
            } catch {
                print("EditMedicationView save error:", error)
                await MainActor.run { self.error = error }
            }
        }
    }
    
}

