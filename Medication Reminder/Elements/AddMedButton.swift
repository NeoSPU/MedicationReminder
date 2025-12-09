// NewMedButton.swift
// Medication Reminder
//
// Created by Alex Rublov on 09/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import SwiftUI

struct AddMedButton: View {
    var body: some View {
        Label("Add Medication", systemImage: "plus")
            .frame(minWidth: 160)
            .buttonStyle(.borderedProminent)
    }
}
