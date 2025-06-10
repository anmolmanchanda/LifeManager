import Foundation

// Test our core models compilation
struct QuickTest {
    static func testModels() {
        print("🧪 Testing LifeManager Core Models...")
        
        // Test SourceType enum
        let sourceType = SourceType.note
        print("✅ SourceType: \(sourceType.displayName)")
        
        // Test WorkPersonalType enum
        let workType = WorkPersonalType.personal
        print("✅ WorkPersonalType: \(workType.displayName)")
        
        // Test TaskPriority enum
        let priority = TaskPriority.high
        print("✅ TaskPriority: \(priority.displayName) (sort: \(priority.sortOrder))")
        
        // Test Blob creation
        let blob = Blob(
            content: "Test natural language input: Meet with team tomorrow at 2pm",
            sourceType: .note,
            workPersonal: .work
        )
        print("✅ Blob created: \(blob.content)")
        print("   ID: \(blob.id)")
        print("   Source: \(blob.sourceType.displayName)")
        print("   Type: \(blob.workPersonal.displayName)")
        
        // Test Project creation
        let project = Project(
            name: "Q4 Planning",
            description: "Quarterly planning for next quarter",
            workPersonal: .work
        )
        print("✅ Project created: \(project.name)")
        print("   Status: \(project.status.displayName)")
        
        print("🎉 All core models working correctly!")
    }
}

// Run the test
QuickTest.testModels() 