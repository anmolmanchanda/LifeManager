# Advanced Calendar System Documentation

## Overview

LifeManager's Advanced Calendar System is a sophisticated scheduling and time management solution that combines AI-powered task management, real-time Toggl integration, and intelligent buffer management. This system represents the core productivity engine of LifeManager v1.75+.

## Key Features

### 1. Buffer Management System
**Purpose**: Prevents overbooking and maintains realistic scheduling
**Implementation**: 5-minute buffer per hour rule with intelligent enforcement

#### How It Works
- **Automatic Buffer Calculation**: 5 minutes of buffer time for every hour of scheduled work
- **Buffer Enforcement**: Prevents scheduling tasks that would violate buffer requirements
- **Visual Indicators**: Shows buffer time in calendar views with distinct styling
- **Overflow Handling**: Automatically moves tasks to parking lot when buffers are violated

#### Technical Implementation
```swift
// BufferCalculator.swift
class BufferCalculator {
    static func calculateRequiredBuffer(for duration: TimeInterval) -> TimeInterval {
        let hours = duration / 3600
        return hours * 300 // 5 minutes per hour in seconds
    }
    
    static func validateScheduling(
        events: [CalendarEvent], 
        newEvent: CalendarEvent
    ) -> BufferValidationResult {
        // Buffer validation logic
    }
}
```

### 2. Auto-Bumping and Cascade Rescheduling
**Purpose**: Automatically reschedules conflicting tasks when actual time differs from planned time
**Trigger**: Real-time Toggl data showing longer-than-expected task duration

#### Auto-Bumping Logic
1. **Conflict Detection**: Compares planned vs actual time from Toggl
2. **Impact Analysis**: Identifies all downstream tasks affected by overrun
3. **Intelligent Rescheduling**: Moves affected tasks to next available slots
4. **Cascade Prevention**: Ensures rescheduling doesn't create new conflicts

#### Implementation
```swift
// AutoBumpingEngine.swift
class AutoBumpingEngine {
    func handleTimeOverrun(
        originalEvent: CalendarEvent,
        actualDuration: TimeInterval
    ) async {
        let overrun = actualDuration - originalEvent.duration
        let affectedEvents = findDownstreamEvents(after: originalEvent.endDate)
        
        for event in affectedEvents {
            await rescheduleEvent(event, delayBy: overrun)
        }
    }
}
```

### 3. LLM-Powered Parking Lot
**Purpose**: Intelligent task prioritization and overflow management using AI
**Features**: Importance scoring, context-aware recommendations, smart scheduling suggestions

#### Parking Lot Intelligence
- **Importance Analysis**: LLM evaluates task importance based on content, deadlines, and context
- **Priority Scoring**: Numerical scoring system (1-10) for task prioritization
- **Smart Recommendations**: AI suggests optimal scheduling times based on task characteristics
- **Context Awareness**: Considers work/personal classification, project relationships, and user patterns

#### LLM Integration
```swift
// ParkingLotEngine.swift
class ParkingLotEngine {
    func analyzeTaskImportance(_ task: LifeTask) async -> ImportanceAnalysis {
        let prompt = """
        Analyze the importance and urgency of this task:
        Title: \(task.title)
        Description: \(task.description ?? "")
        Due Date: \(task.dueDate?.formatted() ?? "None")
        Project: \(task.projectName ?? "None")
        
        Provide importance score (1-10) and scheduling recommendation.
        """
        
        return await llmService.analyzeImportance(prompt: prompt)
    }
}
```

### 4. Real-Time Toggl Integration
**Purpose**: Synchronize planned schedule with actual time tracking
**Features**: Live time tracking, automatic conflict detection, schedule adjustment

#### Toggl API Integration
- **Rate Limiting**: 3-second delays between requests to respect API limits
- **Intelligent Caching**: Reduces API calls through smart caching strategies
- **Real-Time Sync**: Continuous synchronization between planned and actual time
- **Conflict Resolution**: Automatic detection and resolution of time conflicts

#### API Optimization
```swift
// TogglService.swift
class TogglService {
    private let requestQueue = DispatchQueue(label: "toggl-requests")
    private var lastRequestTime: Date?
    private let minimumRequestInterval: TimeInterval = 3.0
    
    func fetchTimeEntries(startDate: Date, endDate: Date) async throws -> [TogglTimeEntry] {
        // Rate limiting implementation
        await enforceRateLimit()
        
        // API call with caching
        return try await performAPICall(startDate: startDate, endDate: endDate)
    }
}
```

### 5. Smart Notifications System
**Purpose**: Progressive alert system to keep users informed of schedule changes
**Levels**: Push notifications, SMS alerts, email notifications

#### Notification Hierarchy
1. **Push Notifications**: Immediate alerts for urgent schedule changes
2. **SMS Alerts**: Secondary notifications for critical conflicts
3. **Email Notifications**: Detailed summaries and backup notifications
4. **In-App Alerts**: Real-time UI updates and decision prompts

#### Implementation
```swift
// NotificationService.swift
class NotificationService {
    func sendScheduleAlert(
        type: AlertType,
        message: String,
        urgency: UrgencyLevel
    ) async {
        switch urgency {
        case .critical:
            await sendPushNotification(message)
            await sendSMSAlert(message)
            await sendEmailNotification(message)
        case .high:
            await sendPushNotification(message)
            await sendEmailNotification(message)
        case .normal:
            await sendPushNotification(message)
        }
    }
}
```

### 6. Visual Cues and UI Enhancements
**Purpose**: Provide clear visual feedback about schedule status and conflicts
**Features**: Color coding, duration bars, conflict indicators, hover states

#### Visual Elements
- **Color-Coded Events**: Different colors for planned, actual, and conflicted time
- **Duration Bars**: Visual representation of task duration in month view
- **Conflict Indicators**: Red highlighting for schedule conflicts
- **Buffer Visualization**: Distinct styling for buffer time periods
- **Hover States**: Interactive feedback for better user experience

#### UI Components
```swift
// CalendarEventView.swift
struct CalendarEventView: View {
    let event: CalendarEvent
    
    var eventColor: Color {
        switch event.status {
        case .planned: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .overrun: return .red
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(eventColor)
            .overlay(
                Text(event.title)
                    .font(.caption)
                    .foregroundColor(.white)
            )
    }
}
```

## Calendar Views

### 1. Day View
**Purpose**: Detailed hourly schedule with drag-and-drop task scheduling
**Features**: Hour-by-hour breakdown, task scheduling, buffer visualization

#### Features
- **Hourly Time Slots**: 24-hour view with customizable time intervals
- **Drag & Drop Scheduling**: Direct task scheduling from parking lot
- **Buffer Time Display**: Visual representation of required buffer periods
- **Real-Time Updates**: Live synchronization with Toggl time entries

### 2. Week View
**Purpose**: Weekly overview with multi-day task management
**Features**: 7-day layout, cross-day task visualization, weekly planning

#### Features
- **7-Day Layout**: Full week view with day-by-day breakdown
- **Cross-Day Tasks**: Support for multi-day events and projects
- **Weekly Buffer Analysis**: Week-level buffer management and optimization
- **Batch Operations**: Multi-day scheduling and rescheduling

### 3. Month View
**Purpose**: High-level monthly planning with project duration visualization
**Features**: Monthly overview, project tracking, long-term planning

#### Features
- **Monthly Calendar Grid**: Traditional calendar layout with enhanced features
- **Project Duration Bars**: Visual representation of project timelines
- **Top 3 Projects**: Highlights longest projects per day for focus
- **Monthly Analytics**: Buffer usage, productivity metrics, goal tracking

## Drag & Drop System

### Implementation
**Purpose**: Intuitive task scheduling through drag-and-drop interface
**Components**: Drag preview, drop zones, state management

#### Drag & Drop Flow
1. **Drag Initiation**: User starts dragging task from parking lot
2. **Visual Feedback**: Custom drag preview with task information
3. **Drop Zone Highlighting**: Valid drop zones highlighted during drag
4. **Drop Validation**: Ensures dropped task fits within buffer constraints
5. **Schedule Update**: Updates calendar and database with new schedule

#### Technical Implementation
```swift
// DragDropCoordinator.swift
class DragDropCoordinator: ObservableObject {
    @Published var draggedTask: LifeTask?
    @Published var isDragging = false
    @Published var dragPosition = CGPoint.zero
    
    func startDragging(_ task: LifeTask) {
        draggedTask = task
        isDragging = true
        // Haptic feedback
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
    }
    
    func handleDrop(at date: Date) async {
        guard let task = draggedTask else { return }
        await scheduleTask(task, at: date)
        resetDragState()
    }
}
```

## Context Menu System

### Calendar Events Context Menu
**Purpose**: Quick actions for scheduled events
**Actions**: Edit, reschedule, delete, mark complete, add buffer

#### Available Actions
- **Edit Event**: Modify event details and duration
- **Reschedule**: Move event to different time slot
- **Add Buffer**: Manually add buffer time around event
- **Mark Complete**: Mark event as completed
- **Delete Event**: Remove event from calendar
- **View in Toggl**: Open corresponding Toggl time entry

### Parking Lot Tasks Context Menu
**Purpose**: Task management actions for unscheduled tasks
**Actions**: Schedule, edit, prioritize, archive, delete

#### Available Actions
- **Quick Schedule**: AI-suggested optimal scheduling times
- **Edit Task**: Modify task details and properties
- **Set Priority**: Manual priority adjustment
- **Archive Task**: Move task to archive
- **Delete Task**: Remove task permanently
- **Duplicate Task**: Create copy of task

## Performance Optimizations

### 1. API Rate Limiting
**Toggl API**: 3-second delays between requests
**Caching Strategy**: Intelligent caching to minimize API calls
**Batch Operations**: Group multiple operations to reduce request count

### 2. UI Performance
**Lazy Loading**: Load calendar data on-demand
**Efficient Updates**: Minimize SwiftUI view updates
**Background Processing**: Heavy operations performed off main thread

### 3. Memory Management
**Weak References**: Prevent retain cycles in closures
**Data Cleanup**: Regular cleanup of cached data
**Efficient Data Structures**: Optimized data structures for large datasets

## Configuration and Setup

### Toggl API Configuration
```swift
// TogglService.swift configuration
private let apiToken = "your-toggl-api-token"
private let workspaceId = "your-workspace-id"
private let baseURL = "https://api.track.toggl.com/api/v9"
```

### LLM Service Configuration
```swift
// LLMService.swift configuration
private let openAIKey = "your-openai-api-key"
private let model = "gpt-4"
private let maxTokens = 1000
```

### Notification Configuration
```swift
// NotificationService.swift configuration
private let pushNotificationEnabled = true
private let smsAlertsEnabled = false // Requires SMS service setup
private let emailNotificationsEnabled = true
```

## Troubleshooting

### Common Issues

#### 1. Toggl API Rate Limiting
**Symptoms**: 429 errors, failed API requests
**Solution**: Verify 3-second delays are implemented, check API token validity

#### 2. Calendar Not Updating
**Symptoms**: Events not appearing, stale data
**Solution**: Check real-time subscriptions, verify database connections

#### 3. Drag & Drop Not Working
**Symptoms**: Tasks not scheduling, drop zones not responding
**Solution**: Verify gesture coordination, check drop validation logic

#### 4. Context Menus Not Appearing
**Symptoms**: Right-click not showing menus
**Solution**: Check gesture conflicts, verify context menu implementation

### Debug Logging
```swift
// Enable debug logging
LifeLogger.calendar(.debug, "Calendar event loaded: \(event.title)")
LifeLogger.dragDrop(.info, "Drag operation started for task: \(task.title)")
LifeLogger.toggl(.warning, "API rate limit approaching")
```

## Future Enhancements

### Planned Features (v2.0)
- **Multi-Calendar Support**: Integration with Apple Calendar, Google Calendar
- **Team Scheduling**: Shared calendars and collaborative scheduling
- **Advanced Analytics**: Detailed productivity insights and reporting
- **Custom Buffer Rules**: User-configurable buffer management
- **Voice Integration**: Siri shortcuts for calendar operations

### Experimental Features
- **AI Schedule Optimization**: Machine learning-based schedule optimization
- **Predictive Scheduling**: AI predictions for optimal task scheduling
- **Biometric Integration**: Heart rate and stress level integration
- **AR Calendar View**: Augmented reality calendar visualization

This advanced calendar system represents the cutting edge of personal productivity software, combining AI intelligence with practical time management to create a truly intelligent scheduling assistant. 