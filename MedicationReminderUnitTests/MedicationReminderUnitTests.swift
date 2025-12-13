// MedicationReminderUnitTests.swift
// Medication Reminder
//
// Created by Alex Rublov on 11/12/2025.
// Copyright © 2025 Alex Rublov. All rights reserved.
//
// ========================================================

import XCTest
import SwiftData
@testable import Medication_Reminder

@MainActor
final class PersistenceServiceTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var service: PersistenceService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Medication.self, configurations: config)
        context = container.mainContext
        service = PersistenceService(modelContext: context)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
        service = nil
        try super.tearDownWithError()
    }

    private func randomSuffix() -> String { String(UUID().uuidString.prefix(8)).lowercased() }

    func testAddMedicationSucceeds() throws {
        let unique = "Med_" + randomSuffix()
        let time = Date()
        let created = try service.addMedication(name: unique, dosage: "10mg", time: time, isReminderSet: true)
        XCTAssertEqual(created.name, unique)
        XCTAssertEqual(created.dosage, "10mg")
        XCTAssertEqual(created.time.timeIntervalSince1970, time.timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(created.isReminderSet, true)

        let descriptor = FetchDescriptor<Medication>(predicate: #Predicate { $0.name == unique })
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.first?.name, unique)
    }

    func testAddMedicationDuplicateThrows() throws {
        let base = "DupMed_" + randomSuffix()
        _ = try service.addMedication(name: base, dosage: "5mg", time: Date(), isReminderSet: false)
        do {
            _ = try service.addMedication(name: "  " + base + "  ", dosage: "5mg", time: Date(), isReminderSet: false)
            XCTFail("Expected medicineAlreadyExists to be thrown")
        } catch let error as PersistenceError {
            switch error {
            case .medicineAlreadyExists(let name):
                XCTAssertEqual(name, base)
            default:
                XCTFail("Unexpected PersistenceError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchMedicationNotFoundThrows() throws {
        let name = "NonExisting_" + randomSuffix()
        do {
            _ = try service.fetchnewMedication(named: name)
            XCTFail("Expected medicineNotFound to be thrown")
        } catch let error as PersistenceError {
            switch error {
            case .medicineNotFound(let missing):
                XCTAssertEqual(missing, name)
            default:
                XCTFail("Unexpected PersistenceError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateMedicationReturnsExisting() throws {
        let name = "UpdateMed_" + randomSuffix()
        _ = try service.addMedication(name: name, dosage: "1 pill", time: Date(), isReminderSet: false)
        let updated = try service.updateMedication(name: name)
        XCTAssertEqual(updated.name, name)

        let fetched = try service.fetchnewMedication(named: name)
        XCTAssertEqual(fetched.name, name)
        // Since SwiftData can return same instance in same context, object identity may match
        // We assert by equality of names; deeper identity checks can be brittle across frameworks
    }

    func testDeleteMedicationSucceeds() throws {
        let name = "DeleteMed_" + randomSuffix()
        _ = try service.addMedication(name: name, dosage: "20mg", time: Date(), isReminderSet: false)
        let deleted = try service.deleteMedication(name: name)
        XCTAssertTrue(deleted)
        do {
            _ = try service.fetchnewMedication(named: name)
            XCTFail("Expected medicineNotFound after deletion")
        } catch let error as PersistenceError {
            switch error {
            case .medicineNotFound(let missing):
                XCTAssertEqual(missing, name)
            default:
                XCTFail("Unexpected PersistenceError: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

