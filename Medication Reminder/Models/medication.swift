//
//  medication.swift
//  Medication Reminder
//
//  Created by Udacity
//
import Foundation
import SwiftData

// Medication Model

@Model
final class Medication {
    
    @Attribute(.unique) var name: String
    var dosage: String
    var time: Date
    var isReminderSet: Bool
    
    init(name: String,
         dosage: String = "",
         time: Date = .now,
         isReminderSet: Bool = false) {
        self.name = name
        self.dosage = dosage
        self.time = time
        self.isReminderSet = isReminderSet
    }
    
}

extension Medication {
    // Example instance for previews / seeded data
    static var example: Medication {
        Medication(name: "Vitamin D", dosage: "1000 IU", time: Date().addingTimeInterval(3600), isReminderSet: true)
    }
}


