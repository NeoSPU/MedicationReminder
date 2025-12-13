// PersistanceService.swift
// Medication Reminder
//
// Created by Alex Rublov on 08/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import SwiftData
import SwiftUI

enum PersistenceError: Error, LocalizedError {
    case medicineAlreadyExists(name: String)
    case medicineNotFound(name: String)
    
    var errorDescription: String? {
        switch self {
        case .medicineAlreadyExists(let name):
            return "Medication with name \"\(name)\" already exists."
        case .medicineNotFound(let name):
            return "Medication with name \"\(name)\" was not found."
        }
    }
}

final class PersistenceService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    //MARK: CRUD methods for Medication
    /// Creation method for Medication
    @discardableResult
    func addMedication(name: String, dosage: String, time: Date, isReminderSet: Bool) throws -> Medication {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.name == normalized }
        )
        let existing = try modelContext.fetch(descriptor)
        if existing.first != nil {
            throw PersistenceError.medicineAlreadyExists(name: normalized)
        }

        let newMedication = Medication(name: normalized, dosage: dosage, time: time, isReminderSet: isReminderSet)
        modelContext.insert(newMedication)

        do {
            try modelContext.save()
        } catch {
            print("ModelContext save error:", error)
            throw error
        }
        return newMedication
    }
    
    /// Read method for Medication
    func fetchnewMedication(named name: String) throws -> Medication {
        
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.name == normalized }
        )
        let results = try modelContext.fetch(descriptor)
        if let medication = results.first {
            return medication
        } else {
            throw PersistenceError.medicineNotFound(name: normalized)
        }
    }
    
    /// Update method for Medication
    @discardableResult
    func updateMedication(name: String) throws -> Medication {
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.name == name }
        )
        guard let medication = try modelContext.fetch(descriptor).first else {
            throw PersistenceError.medicineNotFound(name: name)
        }
        return medication
    }
    
    /// Delete method for Medication
    @discardableResult
    func deleteMedication(name: String) throws -> Bool {
        let descriptor = FetchDescriptor<Medication>(
            predicate: #Predicate { $0.name == name }
        )
        if let medication = try modelContext.fetch(descriptor).first {
            modelContext.delete(medication)
            try modelContext.save()
            return true
        } else {
            throw PersistenceError.medicineNotFound(name: name)
        }
    }

}
