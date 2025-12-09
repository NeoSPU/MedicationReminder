// MedicationRowView.swift
// Medication Reminder
//
// Created by Alex Rublov on 08/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import SwiftUI
import SwiftData

struct MedicationRowView: View {
    @Bindable var medication: Medication
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "pills.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(medication.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(medication.dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(medication.time, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Toggle(isOn: $medication.isReminderSet) {
                Text("") // label hidden
            }
            .labelsHidden()
            .onChange(of: medication.isReminderSet) { oldValue, newValue in
                // Save immediately when user toggles
                try? modelContext.save()
            }
            .accessibilityLabel(medication.isReminderSet ? "Reminder enabled" : "Reminder disabled")
        }
        .padding(.vertical, 8)
    }
}

