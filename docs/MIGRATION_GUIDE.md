# MainViewModel Migration Guide

## Overview
This guide explains how to migrate from the monolithic `MainViewModel` (3,125 lines) to the new refactored architecture using specialized ViewModels.

## Architecture Changes

### Before (Monolithic)
```
MainViewModel (3,125 lines)
├── Authentication
├── Navigation
├── Brain Dump Processing
├── PARA Management
├── Sync Operations
├── Settings
└── All State Management
```

### After (Modular)
```
MainViewModelRefactored (400 lines)
├── MainCoordinator (186 lines) - Navigation & Scenes
├── BrainDumpViewModel (334 lines) - Brain Dump Processing
├── PARAManagementViewModel (350 lines) - PARA Operations
├── SyncViewModel (400 lines) - Data Synchronization
└── SettingsViewModel (450 lines) - App Settings
```

## Migration Steps

### Step 1: Update View Dependencies

#### Before:
```swift
struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        // Access everything through viewModel
        Text(viewModel.inboxInput)
        // ...
    }
}
```

#### After:
```swift
struct ContentView: View {
    @StateObject private var viewModel = MainViewModelRefactored()
    
    var body: some View {
        // Access through specialized ViewModels
        Text(viewModel.brainDumpVM.inputText)
        // ...
    }
}
```

### Step 2: Update Property Access

| Old Path | New Path | Description |
|----------|----------|-------------|
| `vm.inboxInput` | `vm.brainDumpVM.inputText` | Brain dump input text |
| `vm.isProcessingInbox` | `vm.brainDumpVM.isProcessing` | Processing state |
| `vm.projects` | `vm.paraVM.projects` | PARA projects |
| `vm.areas` | `vm.paraVM.areas` | PARA areas |
| `vm.selectedTab` | `vm.coordinator.selectedTab` | Navigation tab |
| `vm.showingSettings` | `vm.coordinator.showingSettings` | Settings visibility |
| `vm.autoSyncEnabled` | `vm.syncVM.autoSyncEnabled` | Sync settings |
| `vm.appTheme` | `vm.settingsVM.appTheme` | App theme |

### Step 3: Update Method Calls

#### Authentication
```swift
// Before
await viewModel.signIn(email: email, password: password)

// After
await viewModel.signIn(email: email, password: password) // Same interface
```

#### Brain Dump Processing
```swift
// Before
viewModel.processInboxInput()

// After
await viewModel.brainDumpVM.processBrainDump()
```

#### PARA Operations
```swift
// Before
await viewModel.createProject(project)

// After
await viewModel.paraVM.createProject(project)
```

#### Navigation
```swift
// Before
viewModel.selectedView = .projects

// After
viewModel.coordinator.navigate(to: .projects)
```

### Step 4: Update Bindings

#### Text Field Bindings
```swift
// Before
TextField("Input", text: $viewModel.inboxInput)

// After
TextField("Input", text: $viewModel.brainDumpVM.inputText)
```

#### Toggle Bindings
```swift
// Before
Toggle("Auto Sync", isOn: $viewModel.autoSyncEnabled)

// After
Toggle("Auto Sync", isOn: $viewModel.syncVM.autoSyncEnabled)
```

### Step 5: Update Observable Chains

```swift
// Before
viewModel.$projects
    .sink { projects in
        // Handle projects update
    }

// After
viewModel.paraVM.$projects
    .sink { projects in
        // Handle projects update
    }
```

## Common Patterns

### 1. Accessing Child ViewModels
```swift
// Access pattern
viewModel.brainDumpVM   // Brain dump operations
viewModel.paraVM         // PARA management
viewModel.syncVM         // Sync operations
viewModel.settingsVM     // Settings
viewModel.coordinator    // Navigation
```

### 2. Cross-ViewModel Communication
The refactored MainViewModel handles coordination between child ViewModels:

```swift
// Automatic coordination example
// When brain dump completes, PARA data refreshes automatically
// This is handled internally by MainViewModelRefactored
```

### 3. Error Handling
```swift
// Errors are now handled by the coordinator
viewModel.coordinator.showAlert(.error("Something went wrong"))
```

## Benefits of Migration

1. **Better Performance**: Each ViewModel updates independently
2. **Easier Testing**: Test individual ViewModels in isolation
3. **Clearer Responsibilities**: Each ViewModel has a single purpose
4. **Improved Maintainability**: Smaller, focused files
5. **Parallel Development**: Teams can work on different ViewModels

## Gradual Migration Strategy

If you need to migrate gradually:

1. **Phase 1**: Create new ViewModels alongside old MainViewModel
2. **Phase 2**: Start using new ViewModels in new features
3. **Phase 3**: Gradually move existing features to new ViewModels
4. **Phase 4**: Deprecate old MainViewModel
5. **Phase 5**: Remove old MainViewModel

## Testing During Migration

Run these tests after migration:

```bash
# Unit tests for new ViewModels
swift test --filter MainCoordinatorTests
swift test --filter BrainDumpViewModelTests
swift test --filter PARAManagementViewModelTests
swift test --filter SyncViewModelTests
swift test --filter SettingsViewModelTests

# Integration tests
swift test --filter MainViewModelRefactoredTests
```

## Troubleshooting

### Issue: State not updating
**Solution**: Ensure you're observing the correct child ViewModel

### Issue: Binding errors
**Solution**: Update all @Binding paths to reference child ViewModels

### Issue: Navigation not working
**Solution**: Use coordinator methods instead of direct state manipulation

### Issue: Settings not applying
**Solution**: Check that settings changes trigger through settingsVM

## Code Review Checklist

- [ ] All views updated to use MainViewModelRefactored
- [ ] All property paths updated to child ViewModels
- [ ] All method calls routed to appropriate ViewModels
- [ ] All bindings updated
- [ ] All observable chains updated
- [ ] Tests updated and passing
- [ ] No references to old MainViewModel remain

## Next Steps

After migration:

1. Delete old MainViewModel.swift
2. Rename MainViewModelRefactored to MainViewModel
3. Update documentation
4. Run full test suite
5. Performance testing

---

For questions or issues during migration, refer to the individual ViewModel documentation or create an issue in the repository.