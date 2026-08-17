//
//  PersistenceController.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init() {
        container = NSPersistentContainer(name: "UserContainer")
        if let description = container.persistentStoreDescriptions.first {
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        loadStores()

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private func loadStores() {
        container.loadPersistentStores { [weak self] _, error in
            guard let error, let self else { return }
            print("Core Data store reset after load failure: \(error.localizedDescription)")
            self.destroyExistingStore()
            self.container.loadPersistentStores { _, retryError in
                if let retryError {
                    print("Core Data failed to load: \(retryError.localizedDescription)")
                }
            }
        }
    }

    private func destroyExistingStore() {
        guard let url = container.persistentStoreDescriptions.first?.url else { return }
        let coordinator = container.persistentStoreCoordinator
        if coordinator.persistentStore(for: url) != nil {
            try? coordinator.destroyPersistentStore(at: url, type: .sqlite)
        }
        for suffix in ["", "-wal", "-shm"] {
            let fileURL = URL(fileURLWithPath: url.path + suffix)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
}
