import Foundation
import SwiftData

/// Role: Persistence. Exactly one ModelContainer factory. Failure is a typed result, not try!.
enum KilnContainer {
    static func open(
        configuration: ModelConfiguration? = nil
    ) -> Result<ModelContainer, EmberStoreError> {
        let resolved: ModelConfiguration
        if let configuration {
            resolved = configuration
        } else {
            switch applicationConfiguration() {
            case .success(let created):
                resolved = created
            case .failure(let error):
                return .failure(error)
            }
        }
        do {
            let schema = Schema(versionedSchema: KilnSchemaV1.self)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: KilnMigrationPlan.self,
                configurations: [resolved]
            )
            return .success(container)
        } catch {
            return .failure(.containerFailed)
        }
    }

    static func inMemory() -> Result<ModelContainer, EmberStoreError> {
        open(configuration: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    static func applicationConfiguration() -> Result<ModelConfiguration, EmberStoreError> {
        do {
            let root = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let folder = root.appendingPathComponent("Kilncast", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            return .success(ModelConfiguration(url: folder.appendingPathComponent("kiln.store")))
        } catch {
            return .failure(.containerFailed)
        }
    }
}

/// Role: Persistence. One container at launch. Injected; never built inside a view body.
@MainActor
final class KilnLaunchStack {
    let store: EmberStore?

    init(container: ModelContainer? = nil) {
        if let container {
            store = EmberStore(modelContainer: container)
            return
        }
        switch KilnContainer.open() {
        case .success(let opened):
            store = EmberStore(modelContainer: opened)
        case .failure:
            store = nil
        }
    }

    func prepare() async {
        guard let store else { return }
        #if targetEnvironment(simulator)
        do {
            try await store.seedDemoIfNeeded(defaultsSuiteName: nil, allowDemoSeed: true)
        } catch {
            return
        }
        #endif
    }
}
