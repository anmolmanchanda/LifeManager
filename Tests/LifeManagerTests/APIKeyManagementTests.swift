import XCTest
@testable import LifeManager

/// Tests for API key management system
/// Verifies template-based configuration and error handling
final class APIKeyManagementTests: XCTestCase {
    
    func testConfigTemplateExists() throws {
        // Given
        let templatePath = "config.txt.template"
        
        // When
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let templateFullPath = "\(currentDirectory)/\(templatePath)"
        
        // Then
        XCTAssertTrue(fileManager.fileExists(atPath: templateFullPath), 
                     "config.txt.template should exist in project root")
    }
    
    func testConfigTemplateContainsRequiredKeys() throws {
        // Given
        let templatePath = "config.txt.template"
        
        // When
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let templateFullPath = "\(currentDirectory)/\(templatePath)"
        
        guard fileManager.fileExists(atPath: templateFullPath) else {
            XCTFail("config.txt.template not found")
            return
        }
        
        let templateContent = try String(contentsOfFile: templateFullPath)
        
        // Then
        XCTAssertTrue(templateContent.contains("OPENAI_API_KEY"), 
                     "Template should contain OPENAI_API_KEY placeholder")
        XCTAssertTrue(templateContent.contains("SUPABASE_URL"), 
                     "Template should contain SUPABASE_URL placeholder")
        XCTAssertTrue(templateContent.contains("SUPABASE_ANON_KEY"), 
                     "Template should contain SUPABASE_ANON_KEY placeholder")
    }
    
    func testLLMServiceHandlesMissingAPIKey() async throws {
        // Given
        let llmService = LLMService()
        
        // When
        let result = await llmService.processBrainDump("Test input")
        
        // Then
        // Should handle missing API key gracefully without crashing
        // The exact behavior depends on implementation, but it shouldn't crash
        XCTAssertNotNil(result, "LLMService should return a result even with missing API key")
    }
    
    func testConfigurationInstructions() throws {
        // Given
        let templatePath = "config.txt.template"
        
        // When
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let templateFullPath = "\(currentDirectory)/\(templatePath)"
        
        guard fileManager.fileExists(atPath: templateFullPath) else {
            XCTFail("config.txt.template not found")
            return
        }
        
        let templateContent = try String(contentsOfFile: templateFullPath)
        
        // Then
        XCTAssertTrue(templateContent.contains("Copy this file"), 
                     "Template should contain setup instructions")
        XCTAssertTrue(templateContent.contains("config.txt"), 
                     "Template should reference the target config file")
    }
} 