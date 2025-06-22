# Focus & Timeline Views - UI Wireframes & Component Specifications

## Overview

This document provides detailed UI specifications for the Focus View and Timeline View implementations, designed to deliver a next-generation PARA-driven productivity experience with intelligent automation integration.

---

## 🟦 FOCUS VIEW - UI Specifications

### Core Design Principles
- **Effortless Daily Focus**: Make it trivial to see and act on what matters today
- **AI Transparency**: Every recommendation includes clear reasoning
- **One-Touch Actions**: Minimize cognitive overhead with smart defaults
- **Contextual Awareness**: Adapt to user's current energy and mood state

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ Focus View Header                                               │
├─────────────────────────────────────────────────────────────────┤
│ ┌─ Today's Energy Status ─┐  ┌─ Smart Filters ─────────────┐   │
│ │ 😊 Positive | ⚡ High    │  │ 🔥 🎯 ⚡ 🚀 📋 [+Custom] │   │
│ │ AI: Good day for complex │  │                            │   │
│ │     tasks                │  │                            │   │
│ └─────────────────────────┘  └─────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────┤
│ Today's Focus List                                              │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ ✓ [High] Fix critical bug in auth service          [2h]    │ │
│ │   🧠 "Due today, matches your morning focus block"         │ │
│ │   📁 LifeManager v1.0 | 🔧 Work | ⚡ High Energy          │ │
│ │                                                     ⭐ AI   │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ ○ [Medium] Review Q4 goals and adjust timelines    [1h]    │ │
│ │   🧠 "You typically do planning tasks at 2pm"              │ │
│ │   📁 Career Development | 💼 Work | 🔋 Medium Energy       │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ ○ [Low] Organize kitchen pantry                     [45m]  │ │
│ │   🧠 "Good for low-energy afternoon"                       │ │
│ │   📁 Home Organization | 🏠 Personal | 🪫 Low Energy       │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ ┌─ AI Recommendations ──────────┐ ┌─ Quick Actions ──────────┐  │
│ │ 💡 "Consider batching your    │ │ ✓ Complete Selected      │  │
│ │     admin tasks this         │ │ 📅 Defer to Tomorrow     │  │
│ │     afternoon"               │ │ ⬆️ Increase Priority     │  │
│ │                              │ │ 🗓️ Reschedule           │  │
│ │ 🎯 "You're 2 tasks away      │ │                          │  │
│ │     from your daily goal"    │ │                          │  │
│ └──────────────────────────────┘ └──────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│ Celebration Banner (when visible)                              │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ 🎉 Streak Achievement: 7 days of completing focus tasks!   │ │
│ │                                               [Dismiss]    │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Component Specifications

#### 1. FocusViewHeader
```swift
struct FocusViewHeader: View {
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    // Components:
    // - Date selector with "Today" emphasis
    // - Settings/preferences access
    // - View mode toggle (Focus/Timeline/etc.)
}
```

#### 2. EnergyStatusCard
```swift
struct EnergyStatusCard: View {
    let moodAssessment: DailyMoodAssessment
    
    // Shows:
    // - Mood emoji and energy level
    // - AI insight about optimal task types
    // - Tap to see detailed breakdown
    // - Subtle background color based on mood
}
```

#### 3. SmartFilterBar
```swift
struct SmartFilterBar: View {
    @Binding var activeFilters: Set<FocusFilter>
    let availableFilters: [FocusFilter]
    
    // Features:
    // - Horizontal scrollable filter chips
    // - Predefined filters with emoji icons
    // - Custom filter creation (+ button)
    // - Active filter count indicators
}
```

#### 4. FocusItemRow
```swift
struct FocusItemRow: View {
    @Binding var item: FocusItem
    @State private var isExpanded = false
    
    // Layout:
    // - Completion checkbox/status icon
    // - Priority indicator (color + text)
    // - Title with duration badge
    // - AI reasoning (expandable)
    // - Context tags (project, energy, etc.)
    // - Actions menu (3-dot)
}
```

#### 5. AIRecommendationCard
```swift
struct AIRecommendationCard: View {
    let recommendation: AIRecommendation
    @State private var isDismissed = false
    
    // Design:
    // - Subtle background with AI badge
    // - Recommendation text with confidence indicator
    // - Action buttons if actionable
    // - Dismiss/feedback options
}
```

#### 6. BatchActionBar
```swift
struct BatchActionBar: View {
    @Binding var selectedItems: Set<UUID>
    let availableActions: [BatchAction]
    
    // Shows when items selected:
    // - Selection count
    // - Quick action buttons
    // - Confirmation dialogs for destructive actions
}
```

### Interaction Patterns

#### Focus Item Interactions
- **Tap**: Toggle completion status
- **Long Press**: Multi-select mode
- **Swipe Right**: Quick complete
- **Swipe Left**: Defer to tomorrow
- **Double Tap**: Quick reschedule

#### AI Recommendation Interactions  
- **Tap**: Expand details and actions
- **👍/👎**: Provide feedback to improve AI
- **"Apply"**: Execute recommendation automatically
- **"Dismiss"**: Hide recommendation

#### Smart Filter Interactions
- **Tap Filter**: Apply filter (single selection)
- **Multi-tap**: Combine filters (AND logic)
- **Long Press**: Edit custom filter
- **Shake to Clear**: Reset all filters

---

## 🟧 TIMELINE VIEW - UI Specifications

### Core Design Principles
- **Goal-Centric Navigation**: Everything organized around achieving goals
- **Visual Progress Clarity**: Instant understanding of where you stand
- **Ripple Effect Visibility**: See how changes impact other goals
- **Time Travel**: Easy navigation through past, present, and future

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ Timeline View Header                                            │
├─────────────────────────────────────────────────────────────────┤
│ ┌─ Goal Selector ─────────┐ ┌─ View Controls ────────────────┐  │
│ │ 🎯 LifeManager v1.0 ▼   │ │ Timeline  Gantt  Calendar  📊  │  │
│ │ 📊 75% Complete         │ │ 6M Range  Show: Active ✓       │  │
│ └─────────────────────────┘ └─────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────┤
│ Progress Summary Bar                                            │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ ████████████████░░░░ 75% │ 3/4 Goals On Track │ 2 At Risk │ │
│ │ Next: Launch Beta (Mar 15) │ Behind: Marketing (2 weeks)   │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ Timeline Content Area                                           │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ ┌─ Jan ────┐ ┌─ Feb ────┐ ┌─ Mar ────┐ ┌─ Apr ────┐        │ │
│ │ │           │ │          │ │          │ │          │        │ │
│ │ │ ● Started │ │ 🏁 MVP   │ │ 🚀 Beta  │ │ 🎯 v1.0  │        │ │
│ │ │ ───────●──┼─●────────● │ ●─────────● │ ●────────          │ │
│ │ │   Setup   │ │ Core     │ │ Polish   │ │ Launch   │        │ │
│ │ │           │ │ Features │ │ Testing  │ │          │        │ │
│ │ └───────────┘ └──────────┘ └──────────┘ └──────────┘        │ │
│ │                                                             │ │
│ │ ⚠️ Ripple Alert: Marketing delay affects Beta launch       │ │
│ │    Suggested: Move Beta to Mar 22 or reduce scope          │ │
│ └─────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────┤
│ ┌─ AI Insights ─────────────┐ ┌─ Recent Activity ─────────────┐ │
│ │ 📈 "Velocity increased    │ │ ✓ API endpoint completed      │ │
│ │     15% this month"       │ │ 📝 Added testing milestone    │ │
│ │                           │ │ ⚠️ Design review delayed      │ │
│ │ 🎯 "You typically finish  │ │ 🎉 Database migration done    │ │
│ │     projects 1 week       │ │                               │ │
│ │     after target"         │ │ [View All Activity →]         │ │
│ └───────────────────────────┘ └───────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Component Specifications

#### 1. TimelineViewHeader
```swift
struct TimelineViewHeader: View {
    @Binding var selectedGoal: Goal?
    @Binding var viewConfig: TimelineViewConfig
    
    // Components:
    // - Goal dropdown with search
    // - View mode tabs (Timeline/Gantt/Calendar/Stats)
    // - Time range selector
    // - Filter/sort options
}
```

#### 2. GoalSelector
```swift
struct GoalSelector: View {
    @Binding var selectedGoal: Goal?
    let allGoals: [Goal]
    @State private var showingGoalPicker = false
    
    // Features:
    // - Current goal with progress indicator
    // - Dropdown with goal search
    // - Goal creation shortcut
    // - Recent goals quick access
}
```

#### 3. ProgressSummaryBar
```swift
struct ProgressSummaryBar: View {
    let progressSummary: ProgressSummary
    let risksAndOpportunities: [TimelineInsight]
    
    // Shows:
    // - Overall progress bar with percentage
    // - Goals on track vs at risk counts
    // - Next milestone with date
    // - Key risk or opportunity highlight
}
```

#### 4. TimelineCanvas
```swift
struct TimelineCanvas: View {
    let goal: Goal
    let milestones: [Milestone]
    let events: [TimelineEvent]
    @Binding var selectedTimeRange: TimeRange
    
    // Displays:
    // - Time axis (months/quarters)
    // - Milestone markers with status
    // - Progress lines connecting milestones
    // - Event annotations
    // - Zoom and pan interactions
}
```

#### 5. RippleEffectAlert
```swift
struct RippleEffectAlert: View {
    let rippleEffect: RippleEffect
    @State private var showingActions = false
    
    // Design:
    // - Warning/info styling based on severity
    // - Clear description of impact
    // - Suggested actions with estimates
    // - Dismiss or apply actions
}
```

#### 6. MilestoneCard
```swift
struct MilestoneCard: View {
    @Binding var milestone: Milestone
    @State private var showingDetails = false
    
    // Layout:
    // - Status icon with progress indicator
    // - Name and target date
    // - Task completion ratio
    // - Dependency indicators
    // - Quick actions menu
}
```

#### 7. GoalInsightPanel
```swift
struct GoalInsightPanel: View {
    let insights: [TimelineInsight]
    @State private var selectedInsight: TimelineInsight?
    
    // Features:
    // - Rotating insight cards
    // - Confidence indicators
    // - Actionable insights with buttons
    // - Historical pattern references
}
```

### Navigation Patterns

#### Goal Switching
- **Dropdown Selection**: Quick access to all goals
- **Keyboard Shortcut**: Cmd+G for goal switcher
- **Search**: Type to filter goals by name/description
- **Recents**: Show recently viewed goals at top

#### Time Navigation
- **Scroll**: Horizontal scroll through timeline
- **Zoom**: Pinch/scroll to zoom time scale
- **Jump**: Quick buttons for "Today", "This Month", "This Quarter"
- **Scrubbing**: Drag time indicator for precise navigation

#### View Modes
- **Timeline**: Horizontal timeline with milestones
- **Gantt**: Traditional Gantt chart view
- **Calendar**: Calendar grid with milestone dates
- **Stats**: Analytics and progress dashboard

---

## 🔗 Integration Points

### Connection to Existing Views
- **Main Navigation**: Tab bar integration
- **Sidebar Links**: Direct access from Projects/Areas
- **Search Integration**: Global search includes focus items
- **MindMap Links**: Visual connections to timeline

### AI Service Integration
- **Mood Analysis**: ContextMemoryService processes brain dumps
- **Priority Intelligence**: PriorityIntelligenceEngine scores items  
- **Smart Rescheduling**: IntelligentReschedulingService handles deferrals
- **Notifications**: ProactiveNotificationEngine sends reminders

### Data Flow
```
Brain Dump → AI Processing → Focus/Timeline Items
      ↓
User Actions → State Updates → AI Learning
      ↓  
Progress Tracking → Insights → Recommendations
```

---

## 🎨 Visual Design System

### Color Palette
- **Primary Blue**: #007AFF (system blue)
- **Success Green**: #34C759 
- **Warning Orange**: #FF9500
- **Danger Red**: #FF3B30
- **AI Purple**: #AF52DE
- **Neutral Grays**: System grays for backgrounds

### Typography
- **Headers**: SF Pro Display, Bold
- **Body**: SF Pro Text, Regular/Medium
- **Captions**: SF Pro Text, Regular (smaller)
- **Code/Data**: SF Mono

### Iconography
- **SF Symbols**: Primary icon system
- **Custom AI Icons**: Brain, bolt, star for AI features
- **Emoji**: Used sparingly for personality and mood

### Spacing & Layout
- **Grid**: 8pt base grid system
- **Margins**: 16pt standard margin
- **Cards**: 12pt corner radius
- **Shadows**: Subtle shadows for depth

---

## 📱 Responsive Considerations

### macOS Desktop
- **Full Layout**: All panels visible simultaneously
- **Keyboard Shortcuts**: Full shortcut support
- **Multi-Window**: Support for multiple timeline windows
- **Drag & Drop**: Between Focus and Timeline views

### Compact Layouts
- **Sidebar Collapse**: Hide/show secondary panels
- **Tab Navigation**: Switch between Focus/Timeline
- **Simplified Filters**: Essential filters only
- **Touch Interactions**: Larger touch targets

---

## ⚡ Performance Requirements

### Rendering Performance
- **60fps Scrolling**: Smooth timeline navigation
- **Lazy Loading**: Load timeline data on demand
- **Caching**: Cache computed insights and layouts
- **Animation Budget**: <16ms per frame

### Data Loading
- **Progressive Loading**: Show skeleton UI while loading
- **Background Refresh**: Update data without blocking UI
- **Offline Capability**: Cache for offline viewing
- **Real-time Updates**: Live updates for shared goals

---

## 🧪 Testing Strategy

### UI Testing Priorities
1. **Focus Item Interactions**: Complete, defer, reschedule
2. **Filter Application**: Various filter combinations
3. **Timeline Navigation**: Zoom, scroll, time jumping
4. **Goal Switching**: Performance with many goals
5. **Ripple Effect Display**: Complex dependency chains
6. **AI Recommendation Flow**: From suggestion to action

### Accessibility
- **VoiceOver**: Full screen reader support
- **High Contrast**: Support for accessibility display modes
- **Large Text**: Dynamic type support
- **Keyboard Navigation**: Full keyboard accessibility
- **Reduced Motion**: Respect motion preferences

This comprehensive UI specification provides the foundation for implementing world-class Focus and Timeline views that deliver on the vision of effortless, intelligent productivity management.