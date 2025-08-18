# Enterprise Repository Structure

## Current Issues
- Monolithic ViewModels (3000+ lines)
- Monolithic Views (3000+ lines)  
- Mixed concerns in single files
- No clear module boundaries
- Missing test structure
- No deployment automation

## Proposed Enterprise Structure

```
LifeManager/
├── .github/
│   ├── workflows/
│   │   ├── ci-pr.yml              # PR validation
│   │   ├── cd-main.yml            # Production deployment
│   │   ├── security.yml           # Security scanning
│   │   └── release.yml            # Release automation
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── CODEOWNERS
│
├── Sources/
│   ├── LifeManagerCore/           # Core business logic
│   │   ├── Models/
│   │   │   ├── PARA/
│   │   │   ├── Calendar/
│   │   │   ├── Context/
│   │   │   └── User/
│   │   ├── Protocols/
│   │   └── Extensions/
│   │
│   ├── LifeManagerData/           # Data layer
│   │   ├── Repositories/
│   │   │   ├── PARARepository.swift
│   │   │   ├── UserRepository.swift
│   │   │   └── CalendarRepository.swift
│   │   ├── Database/
│   │   │   ├── SupabaseClient.swift
│   │   │   └── Migrations/
│   │   └── Cache/
│   │       └── CacheManager.swift
│   │
│   ├── LifeManagerServices/       # Service layer
│   │   ├── AI/
│   │   │   ├── LLM/
│   │   │   │   ├── LLMProtocol.swift
│   │   │   │   ├── OpenAIService.swift
│   │   │   │   └── ClaudeService.swift
│   │   │   ├── Embeddings/
│   │   │   └── BrainDump/
│   │   ├── Context/
│   │   │   ├── ActivityPatternService.swift
│   │   │   ├── ContextWindowManager.swift
│   │   │   └── SummaryGenerationService.swift
│   │   ├── Calendar/
│   │   │   ├── CalendarService.swift
│   │   │   └── SchedulingEngine.swift
│   │   ├── Integration/
│   │   │   ├── TogglService.swift
│   │   │   └── AppleCalendarService.swift
│   │   └── Notification/
│   │       └── NotificationService.swift
│   │
│   ├── LifeManagerUI/             # UI layer
│   │   ├── App/
│   │   │   ├── LifeManagerApp.swift
│   │   │   └── AppDelegate.swift
│   │   ├── Scenes/
│   │   │   ├── Main/
│   │   │   │   ├── MainCoordinator.swift
│   │   │   │   ├── MainViewModel.swift (< 300 lines)
│   │   │   │   └── MainView.swift (< 300 lines)
│   │   │   ├── BrainDump/
│   │   │   │   ├── BrainDumpViewModel.swift
│   │   │   │   ├── BrainDumpView.swift
│   │   │   │   └── Components/
│   │   │   │       ├── InputArea.swift
│   │   │   │       └── ProcessingIndicator.swift
│   │   │   ├── PARA/
│   │   │   │   ├── Projects/
│   │   │   │   ├── Areas/
│   │   │   │   ├── Resources/
│   │   │   │   └── Archive/
│   │   │   ├── Calendar/
│   │   │   │   ├── CalendarViewModel.swift
│   │   │   │   ├── CalendarView.swift
│   │   │   │   └── Components/
│   │   │   └── Settings/
│   │   │       ├── SettingsViewModel.swift
│   │   │       └── SettingsView.swift
│   │   ├── Shared/
│   │   │   ├── Components/
│   │   │   ├── Modifiers/
│   │   │   └── Styles/
│   │   └── Resources/
│   │       ├── Assets.xcassets
│   │       └── Localizable.strings
│   │
│   └── LifeManagerLib/            # Shared utilities
│       ├── Logger/
│       ├── Networking/
│       ├── Security/
│       └── Utilities/
│
├── Tests/
│   ├── LifeManagerCoreTests/
│   │   ├── Models/
│   │   └── Mocks/
│   ├── LifeManagerDataTests/
│   │   ├── Repositories/
│   │   └── Database/
│   ├── LifeManagerServicesTests/
│   │   ├── AI/
│   │   ├── Context/
│   │   └── Calendar/
│   ├── LifeManagerUITests/
│   │   └── Scenes/
│   ├── IntegrationTests/
│   └── E2ETests/
│
├── Scripts/
│   ├── setup.sh
│   ├── build.sh
│   ├── test.sh
│   ├── deploy.sh
│   └── create_app_bundle.sh
│
├── Configuration/
│   ├── Development/
│   ├── Staging/
│   └── Production/
│
├── Documentation/
│   ├── API/
│   ├── Architecture/
│   ├── Deployment/
│   └── UserGuide/
│
├── Infrastructure/
│   ├── Terraform/           # Infrastructure as Code
│   ├── Docker/
│   └── Kubernetes/
│
├── .swiftlint.yml
├── .gitignore
├── Package.swift
├── README.md
├── ARCHITECTURE.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── LICENSE
└── Makefile
```

## Implementation Plan

### Phase 1: Core Refactoring (Week 1)
1. Extract ViewModels into focused modules
2. Break down ContentView into components
3. Create proper service boundaries

### Phase 2: Testing (Week 2)
1. Add unit tests for all services
2. Add integration tests
3. Add UI tests

### Phase 3: CI/CD (Week 3)
1. Implement new workflows
2. Add deployment automation
3. Setup monitoring

### Phase 4: Documentation (Week 4)
1. API documentation
2. Architecture diagrams
3. Deployment guides

## Benefits
- **Maintainability**: Clear separation of concerns
- **Testability**: Easy to mock and test each layer
- **Scalability**: Can add features without affecting others
- **Team Collaboration**: Clear ownership boundaries
- **CI/CD**: Automated quality gates
- **Security**: Proper secret management
- **Performance**: Module-level optimization