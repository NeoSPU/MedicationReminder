// Utiles.swift
// Medication Reminder
//
// Created by Alex Rublov on 08/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import SwiftUI

extension View {
  func alert(error: Binding<Error?>) -> some View {
    self.alert(isPresented: Binding<Bool>(
      get: { error.wrappedValue != nil },
      set: { if !$0 { error.wrappedValue = nil } }
    )) {
      Alert(
        title: Text("Error"),
        message: Text(error.wrappedValue?.localizedDescription ?? "An unknown error occurred."),
        dismissButton: .default(Text("Dismiss"))
      )
    }
  }
}
