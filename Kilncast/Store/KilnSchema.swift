import Foundation
import SwiftData

/// Role: Persistence. VersionedSchema v1. Person and Touch only.
enum KilnSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Person.self, Touch.self] }
}

/// Role: Persistence. Migration plan from v1. Empty stages until a real migration exists.
enum KilnMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [KilnSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
