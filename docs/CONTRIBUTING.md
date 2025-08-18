# Contributing to LifeManager

Thank you for your interest in contributing to LifeManager! This document provides guidelines and instructions for contributing to the project.

## Table of Contents
1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Process](#development-process)
4. [Code Standards](#code-standards)
5. [Testing Requirements](#testing-requirements)
6. [Pull Request Process](#pull-request-process)
7. [Architecture Guidelines](#architecture-guidelines)

## Code of Conduct

### Our Standards
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Accept responsibility for mistakes
- Prioritize the project's best interests

### Unacceptable Behavior
- Harassment or discrimination
- Personal attacks or trolling
- Publishing private information
- Unprofessional conduct

## Getting Started

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9+
- Git experience
- OpenAI API key (for testing)

### Setting Up Development Environment

1. **Fork and clone the repository**
```bash
git clone https://github.com/yourusername/LifeManager.git
cd LifeManager
git remote add upstream https://github.com/original/LifeManager.git
```

2. **Create a feature branch**
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

3. **Configure API keys**
```bash
cp config.txt.template config.txt
# Add your API keys to config.txt
```

4. **Build and test**
```bash
swift build
swift test
```

## Development Process

### 1. Check Existing Issues
- Look for existing issues before creating new ones
- Comment on issues you want to work on
- Wait for maintainer approval on major features

### 2. Follow the Architecture
- Review [ARCHITECTURE.md](./ARCHITECTURE.md) before making changes
- Maintain MVVM separation
- Follow service-oriented design patterns
- Respect the clean architecture principles

### 3. Write Clean Code
- Follow standards in [CLAUDE.md](./CLAUDE.md)
- Keep files under size limits:
  - Services: Max 500 lines
  - Views: Max 300 lines
  - Utilities: Max 200 lines
- One responsibility per class/service

## Code Standards

### Swift Style Guide

#### Naming Conventions
```swift
// Classes and protocols: PascalCase
class BrainDumpProcessor { }
protocol DataService { }

// Variables and functions: camelCase
let userName: String
func processInput() { }

// Constants: camelCase (not SCREAMING_SNAKE_CASE)
let maximumRetryCount = 3
```

#### Code Organization
```swift
class MyService: ObservableObject {
    // MARK: - Properties
    static let shared = MyService()
    @Published var state: State = .idle
    
    // MARK: - Private Properties
    private let dependency = DependencyService.shared
    
    // MARK: - Initialization
    private init() { }
    
    // MARK: - Public Methods
    func publicMethod() { }
    
    // MARK: - Private Methods
    private func helperMethod() { }
}
```

#### Error Handling
```swift
enum ServiceError: LocalizedError {
    case networkFailure
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "Network connection failed"
        case .invalidData:
            return "Received invalid data"
        }
    }
}

func performOperation() async throws -> Result {
    do {
        // Operation
    } catch {
        logger.error("Operation failed: \(error)")
        throw ServiceError.networkFailure
    }
}
```

### Commit Message Format

Use conventional commits:
```bash
feat: add calendar synchronization
fix: resolve memory leak in context window
refactor: split MainViewModel into services
docs: update API documentation
test: add unit tests for BrainDumpProcessor
chore: update dependencies
```

**NEVER include:**
- References to AI assistants
- Emojis in commit messages
- Marketing language
- Personal information

### Documentation Standards

#### Inline Documentation
```swift
/// Processes complex brain dump input and extracts structured data
/// - Parameters:
///   - input: Raw text from user input
///   - context: Current processing context
/// - Returns: Structured brain dump result
/// - Throws: ProcessingError if input cannot be parsed
func processBrainDump(
    _ input: String,
    context: ProcessingContext
) async throws -> BrainDumpResult {
    // Implementation
}
```

## Testing Requirements

### Unit Tests
Every new feature must include tests:

```swift
class BrainDumpProcessorTests: XCTestCase {
    func testComplexNoteProcessing() async throws {
        // Arrange
        let processor = BrainDumpProcessor()
        let input = "Test input"
        
        // Act
        let result = try await processor.process(input)
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertEqual(result.items.count, 1)
    }
}
```

### Test Coverage Requirements
- New features: Minimum 80% coverage
- Bug fixes: Include regression tests
- Refactoring: Maintain or improve existing coverage

### Running Tests
```bash
# All tests
swift test

# Specific test file
swift test --filter ProcessorTests

# With coverage
swift test --enable-code-coverage
```

## Pull Request Process

### Before Submitting

1. **Ensure code quality**
   - [ ] Code compiles without warnings
   - [ ] All tests pass
   - [ ] File size limits respected
   - [ ] Documentation updated

2. **Update documentation**
   - [ ] Update README.md if needed
   - [ ] Update feature_matrix.md for new features
   - [ ] Add inline documentation for public APIs

3. **Test thoroughly**
   - [ ] Manual testing completed
   - [ ] Edge cases considered
   - [ ] Performance impact assessed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactoring
- [ ] Documentation

## Changes Made
- List specific changes
- Reference issue numbers (#123)

## Testing
- Describe testing performed
- Include test coverage %

## Screenshots (if UI changes)
[Add screenshots here]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] File size limits respected
```

### Review Process

1. **Automated Checks**
   - CI/CD pipeline must pass
   - Code coverage maintained
   - No merge conflicts

2. **Code Review**
   - At least one maintainer approval required
   - Address all feedback constructively
   - Keep discussions professional

3. **Merge Strategy**
   - Squash and merge for features
   - Rebase for small fixes
   - No direct commits to main branch

## Architecture Guidelines

### Adding New Services

1. **Follow the pattern**
```swift
class NewService: ObservableObject {
    static let shared = NewService()
    
    @Published var state: State = .idle
    
    private init() { }
    
    // Service implementation
}
```

2. **Register in appropriate location**
   - Add to Services/ directory
   - Update ARCHITECTURE.md
   - Add tests in Tests/

### Refactoring Guidelines

When refactoring large files:

1. **Plan the split**
   - Identify responsibilities
   - Design service boundaries
   - Consider dependencies

2. **Create new services first**
   - Don't delete old code immediately
   - Migrate gradually
   - Maintain backward compatibility

3. **Update references**
   - Update all ViewModels
   - Fix import statements
   - Update documentation

### Database Changes

1. **Create migration**
```sql
-- supabase/migrations/xxx_description.sql
CREATE TABLE new_table (
    id UUID PRIMARY KEY,
    -- columns
);
```

2. **Update models**
```swift
// Models/NewModel.swift
struct NewModel: Codable {
    let id: UUID
    // properties
}
```

3. **Test migrations**
   - Apply in development first
   - Verify data integrity
   - Document breaking changes

## Getting Help

### Resources
- [Architecture Documentation](./ARCHITECTURE.md)
- [Development Standards](./CLAUDE.md)
- [Feature Matrix](./doc/feature_matrix.md)
- [API Documentation](./docs/api/README.md)

### Communication Channels
- GitHub Issues: Bug reports and feature requests
- GitHub Discussions: General questions and ideas
- Pull Requests: Code contributions

### Maintainer Response Time
- Issues: 24-48 hours
- Pull Requests: 48-72 hours
- Security issues: <24 hours

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to LifeManager! Your efforts help make personal organization accessible to everyone.

---

*Last updated: August 18, 2025*