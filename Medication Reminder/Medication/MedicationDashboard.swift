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
    @State private var query = ""
    @State private var sortOrder: SortDescriptor<Medication> = SortDescriptor(\Medication.name)
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddSheet = false
    @State private var selectionMode = false
    @State private var selectedIDs: Set<String> = []
    @State private var error: Error?

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            MedicationListView(query: query, sortOrder: sortOrder)
                .searchable(text: $query)
                .toolbar {sortOptions}
        }
    }
    
    // MARK: - Views
    
    @ToolbarContentBuilder
    var sortOptions: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu("Sort", systemImage: "arrow.up.arrow.down") {
                Picker("Sort", selection: $sortOrder) {
                    Text("Name (A–Z)")
                        .tag(SortDescriptor<Medication>(\.name, order: .forward))
                    Text("Name (Z–A)")
                        .tag(SortDescriptor<Medication>(\.name, order: .reverse))
                }
            }
            .pickerStyle(.inline)
        }
    }
}


// MARK: - CategoriesListView with #Predicate and @Query

private struct MedicationListView: View {
    let query: String
    let sortOrder: SortDescriptor<Medication>
    
    @Environment(\.modelContext) private var modelContext
    @Query private var medications: [Medication]
    @State private var error: Error?
    @State private var showingAddSheet = false
    @State private var selectionMode = false
    @State private var selectedIDs: Set<String> = []

    init(query: String, sortOrder: SortDescriptor<Medication>) {
        self.query = query
        self.sortOrder = sortOrder
        
        // Build a #Predicate based on the current query. If empty, match all.
        let predicate: Predicate<Medication>
        if query.isEmpty {
            predicate = #Predicate<Medication> { _ in true }
        } else {
            let q = query
            predicate = #Predicate<Medication> { medication in
                medication.name.localizedStandardContains(q)
            }
        }
        
        // Initialize the @Query wrapper with filter and sort so filtering/sorting happen in the store.
        self._medications = Query(filter: predicate, sort: [sortOrder])
    }
    
    var body: some View {
        content
            .navigationTitle("Medications")
            .toolbar {
                if medications.isEmpty {
                    NavigationLink(value: EditMedicationView.Mode.add) {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: EditMedicationView.Mode.self) { mode in
                EditMedicationView(mode: mode)
            }
            .alert(error: $error)
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var content: some View {
        if medications.isEmpty {
            empty
        } else {
            list(for: medications)
                .listStyle(.insetGrouped)
        }
    }
    
    private var empty: some View {
        List {
            VStack(spacing: 16) {
                Image(systemName: "pills.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.tint)
                Text("No medication reminders yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Tap + to add a medication and set reminders. Keeping a regular routine helps maintain medication adherence.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                NavigationLink(value: EditMedicationView.Mode.add) {
                    Label("Add Medication", systemImage: "plus")
                        .frame(minWidth: 160)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
            .listRowBackground(Color.clear)
        }
    }
    
    private var noResults: some View {
        VStack(spacing: 16) {
            Image(systemName: "pills.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(.tint)
            Text("Couldn't find \"\(query)\"")
            Text("Tap + to add a medication and set reminders. Keeping a regular routine helps maintain medication adherence.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            NavigationLink(value: EditMedicationView.Mode.add) {
                Label("Add Medication", systemImage: "plus")
                    .frame(minWidth: 160)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .center)
        .listRowBackground(Color.clear)
    }
    
    private func list(for medications: [Medication]) -> some View {

        ScrollView(.vertical) {
            if medications.isEmpty {
                noResults
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(medications) { med in
                        NavigationLink(value: med) {
                            MedicationRowView(medication: med)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(name: med.name)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                // quick share: plain summary
                                share(med)
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(.green)
                        }
                    }
                    .onDelete(perform: deleteIndexSet)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    selectionMode.toggle()
                    if !selectionMode { selectedIDs.removeAll() }
                } label: {
                    Image(systemName: selectionMode ? "checkmark.circle.fill" : "checkmark.circle")
                }
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    // MARK: - Data
    
    private func delete(name: String) {
        Task {
            do {
                try PersistenceService(modelContext: modelContext).deleteMedication(name: name)
            } catch {
                await MainActor.run { self.error = error }
            }
        }
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
    
    private func deleteIndexSet(_ offsets: IndexSet) {
            for index in offsets {
                let med = medications[index]
                modelContext.delete(med)
            }
            try? modelContext.save()
        }
}
