# LIFE MANAGER — PROJECT OVERVIEW AND DOCUMENTATION

## Current Status: v2.0 Production Release

This document provides comprehensive project overview for LifeManager v2.0, a production-ready AI-powered personal productivity system with advanced intelligent automation capabilities.

**Current Version**: v2.0 (Intelligent Automation) - Production Ready ✅  
**Documentation Updated**: June 22, 2025

## 📚 Documentation Navigation

- **📋 [README.md](../README.md)** - Main project overview and feature matrix
- **📝 [CHANGELOG.md](../CHANGELOG.md)** - Complete version history and changes
- **🚀 [RELEASE_NOTES.md](../RELEASE_NOTES.md)** - Production deployment information
- **🔧 [CLAUDE.md](../CLAUDE.md)** - Technical documentation and development guide
- **📁 [docs/](.)** - Organized documentation structure

---

## Version 1.0 — Core LLM Productivity + Knowledge Base

- Natural language task input and parsing (e.g., "Lunch with Sarah tomorrow at noon" creates the right task with date/time/priority).
- AI/LLM-powered task prioritization, scoring, and suggested due dates.
- Core PARA structure: Projects, Areas, Resources, Archives organization for all info.
- Central knowledge base: Journals, resources, recipes, finances, shows, YouTube, inventory, grocery lists, research papers, therapy notes, etc.
- Full-text and semantic search across all content.
- Smart (manual) task bump/reschedule option (user can nudge overdue tasks, but not yet auto-rescheduled).
- Manual "focus" flag on tasks for future focus mode.
- Version history/audit for all changes.
- NO automated calendar scheduling, recurring tasks, team/collab, or real calendar sync in this version.

---

## Version 1.5 — Productivity Enhancements

- Smart (semi-automated) task rescheduling: If a task is overdue, suggest bumping or reassigning a new date/time.
- Manual "focus mode": User can mark times or blocks as "focus," and see filtered views of only focus tasks.
- Recurring tasks: User can define repeating routines (e.g., "Pay rent monthly," "Weekly review").
- Early PARA view/filter in UI (filter by Project, Area, Resource, Archive).

---

## Version 2.0 — Motion AI-Level Automation

- Automated AI-powered scheduling: Tasks are auto-assigned to calendar slots by AI, based on priorities, deadlines, duration, and calendar availability.
- Two-way sync with external calendars (Apple/Google/Outlook): Pull meetings/events, avoid conflicts, update when schedule changes.
- Automated focus time blocking: AI blocks out time for deep work around meetings and other events.
- Task dependencies: User can define dependencies (e.g., Task B cannot start until Task A is completed).
- Collaboration/Shared tasks and projects: Support for team projects, shared lists, and multi-user features.
- Automated re-scheduling: Missed/overdue tasks are auto-bumped and rescheduled intelligently.

---

**IMPORTANT:**
- Claude/Cursor:  
    - When developing or generating code/features, only build for the current version (v1.0, v1.5, or v2.0) as specified in the active branch/ticket.  
    - Do NOT implement features planned for later versions until that version is actively being built.
    - Any new tickets or features must specify their intended version and dependencies.

---

# LifeManager - AI-Powered Personal Productivity System with PARA Framework

## Recent Changes (Latest Updates)

### Authentication System Improvements (Latest)
- **Enhanced Development Bypass**: Now creates real authenticated Supabase sessions instead of mock data
- **Improved Test Account**: Updated to `dev@lifemanager.local` with automatic fallback creation
- **Password Reset Feature**: Added password reset functionality for existing accounts
- **Force Account Creation**: Added "Force Create Dev Account" button for development setup
- **Better Error Handling**: Improved authentication error messages and fallback mechanisms
- **Magic Link Processing**: Enhanced magic link callback handling with manual processing option

**Authentication Solutions for Common Issues**:
1. **Existing accounts with forgotten passwords**: Use the "Reset Password" button
2. **Magic link not working**: Use manual callback processing or Force Create Dev Account
3. **Test account invalid credentials**: Fixed to use new dev@lifemanager.local account
4. **Development bypass showing no content**: Now creates authenticated sessions for database access
5. **Email delivery issues**: Added alternative account creation methods

### Advanced Calendar System with Toggl Integration (Latest Update)
- **Smart Calendar View**: New advanced calendar with real-time Toggl time tracking integration
- **Buffer Management**: Automatic 5-minute per hour buffer enforcement to prevent overbooking
- **Auto-Bumping Logic**: Automatic rescheduling when actual time entries conflict with planned events
- **Enhanced Parking Lot**: LLM-powered importance ranking and intelligent overflow handling
- **Smart Notifications**: Progressive alert system with push notifications, SMS, and email escalation
- **Visual Cues**: Color-coded events showing actual vs planned time with "pushed by X minutes" labels

### Recently Deleted Tasks & Parking Lot Scheduling (Previous Update)
- **Recently Deleted Section**: Added 24-hour recovery system for deleted tasks in archive
- **Enhanced Scheduling Logic**: Fixed parking lot to only show tasks with both date AND time as "scheduled"
- **Database Soft Delete**: Implemented PostgreSQL soft delete with cleanup functions
- **UI Improvements**: Added countdown timers and restore/delete actions for recently deleted tasks

## Project Summary and Goals

LifeManager is a native macOS productivity application designed for productivity-obsessed software engineers, built around the **PARA methodology** (Projects, Areas, Resources, Archives). The system serves as a comprehensive "life OS" that ingests, processes, and organizes all text-based information through AI-powered automation using **Supabase** as the managed backend and **Swift/SwiftUI** for the native macOS interface.

**Core Purpose**: Build a native macOS app with backend logic and AI prompt-engine that ingests, parses, categorizes, and organizes all the user's text-based information using PARA methodology in real time. All data is structured in Supabase (PostgreSQL) for fast search, tagging, prioritization, and audit/history.

**PARA Framework Integration**:
- **Projects**: Time-bound efforts with clear outcomes (e.g., "PR Application", "Move Apartment")
- **Areas**: Ongoing responsibilities/spheres of activity (e.g., "Health", "Finances", "Learning")  
- **Resources**: Reference materials and knowledge assets (research papers, recipes, articles, videos, guides)
- **Archives**: Inactive or completed information with full archiving capabilities

**Primary Goals**:
- Receive and process large pieces of unstructured text ("blobs") with PARA categorization
- Automate task creation, organization, and prioritization using AI with PARA context
- Provide structured, tagged, searchable digital organization system using PARA methodology
- Maintain complete audit trail and version history with prompt/response logging
- Enable fast search, filtering, and multiple view modes organized by PARA structure
- Native macOS experience with SwiftUI interface
- Managed backend with Supabase for reliability and scalability

## Technology Stack

- **Frontend**: Swift/SwiftUI (native macOS)
- **Backend**: Supabase (managed PostgreSQL with real-time features)
- **AI Processing**: Claude/OpenAI integration with versioned prompt templates
- **Database**: PostgreSQL via Supabase with PARA-structured schema
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Real-time subscriptions
- **Prompt Engineering**: Versioned templates with performance tracking

## Implementation Plan

### Phase 1: Core Infrastructure with PARA Framework (v1.0)
1. **Supabase Setup & PARA Schema Implementation**
   - Supabase project setup and configuration
   - Complete database schema with PARA tables (areas, resources, archives)
   - Implement audit/history tracking for all records
   - Set up proper indexing and RLS policies

2. **Swift PARA Data Layer**
   - Supabase Swift SDK integration
   - Swift data models for all PARA tables and relationships
   - Repository pattern for PARA-aware data access
   - Real-time data synchronization with archiving support

3. **PARA Input Processing Engine**
   - SwiftUI natural language input interface
   - Text blob parsing with PARA categorization
   - Automatic area/project assignment system

4. **AI Processing Pipeline with Prompt Engineering**
   - LLM-driven PARA categorization and tagging
   - Task extraction with area/project context
   - Content summarization with versioned prompts
   - Work/personal classification
   - Prompt/response logging for optimization

5. **PARA Data Organization System**
   - Inbox processing workflow with PARA routing
   - Area and project management
   - Resource library with metadata and tagging
   - Archive system with bulk operations
   - Cross-linking capabilities between PARA categories

6. **Search & Retrieval System**
   - Natural language search queries across PARA categories
   - Multi-field filtering by area, project, archive status
   - Multiple view modes (PARA dashboard, task list, calendar, timeline)
   - Work/personal filtering within PARA structure

7. **SwiftUI Interface**
   - Native macOS interface with PARA navigation
   - Multiple view modes and PARA-based organization
   - Real-time data updates with archiving controls
   - Responsive and intuitive UX following PARA principles

### Phase 2: Enhanced PARA Features (Future)
- Advanced PARA analytics and insights
- Pattern recognition for automatic area/project suggestions
- Enhanced prioritization algorithms with PARA context
- Performance optimizations for large PARA hierarchies
- Additional resource types and automated metadata extraction

## Database Schema (Supabase PostgreSQL) - PARA Enhanced

### PARA Core Tables

#### `areas` (PARA Areas - Ongoing Responsibilities)
- `id` (UUID, PRIMARY KEY)
- `name` (VARCHAR) - Health & Fitness, Career & Professional, etc.
- `description` (TEXT)
- `icon` (VARCHAR) - For UI display
- `color` (VARCHAR) - For UI theming
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `created_at`, `updated_at` (TIMESTAMP)

#### `resources` (PARA Resources - Reference Materials)
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `type` (VARCHAR) - research_paper, recipe, article, video, playlist, guide, insight, book
- `authors` (JSONB)
- `summary` (TEXT)
- `source_url` (TEXT)
- `area_id` (UUID, FOREIGN KEY → areas.id)
- `project_id` (UUID, FOREIGN KEY → projects.id)
- `tags` (JSONB)
- `metadata` (JSONB) - Additional structured metadata
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `is_archived` (BOOLEAN)
- `created_at`, `updated_at`, `archived_at` (TIMESTAMP)

### Enhanced Core Tables with PARA Support

#### `blobs` (Central Content Store)
- `id` (UUID, PRIMARY KEY)
- `content` (TEXT) - Original unstructured text
- `source_type` (ENUM) - email, note, journal, recipe, diet, screenshot, inventory, show, youtube, grocery, insight, knowledge
- `context` (JSONB) - Additional structured metadata
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `processed` (BOOLEAN) - Whether blob has been processed
- `area_id` (UUID, FOREIGN KEY → areas.id) - **PARA Enhancement**
- `project_id` (UUID, FOREIGN KEY → projects.id) - **PARA Enhancement**
- `is_archived` (BOOLEAN) - **PARA Enhancement**
- `created_at`, `updated_at`, `archived_at` (TIMESTAMP)

#### `projects` (PARA Projects - Time-bound Efforts)
- `id` (UUID, PRIMARY KEY)
- `name` (VARCHAR)
- `description` (TEXT)
- `status` (ENUM: 'active', 'completed', 'archived')
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `area_id` (UUID, FOREIGN KEY → areas.id) - **PARA Enhancement**
- `is_archived` (BOOLEAN) - **PARA Enhancement**
- `created_at`, `updated_at`, `archived_at` (TIMESTAMP)

#### `tasks` (Enhanced with PARA Context)
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `description` (TEXT)
- `priority` (ENUM: 'urgent', 'high', 'medium', 'low')
- `status` (ENUM: 'inbox', 'todo', 'in_progress', 'completed', 'cancelled')
- `due_date` (TIMESTAMP)
- `estimated_duration` (INTEGER) - in minutes
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `project_id` (UUID, FOREIGN KEY → projects.id)
- `area_id` (UUID, FOREIGN KEY → areas.id) - **PARA Enhancement**
- `resource_id` (UUID, FOREIGN KEY → resources.id) - **PARA Enhancement**
- `is_focus` (BOOLEAN) - **Manual focus flag for v1.0**
- `is_archived` (BOOLEAN) - **PARA Enhancement**
- `created_at`, `updated_at`, `completed_at`, `archived_at` (TIMESTAMP)

### AI Processing Tables

#### `prompt_logs` (LLM Pipeline Auditing)
- `id` (UUID, PRIMARY KEY)
- `prompt_template` (VARCHAR) - Template identifier for versioning
- `prompt_version` (VARCHAR) - Version for A/B testing
- `input_data` (JSONB) - Input parameters
- `prompt_text` (TEXT) - Final prompt sent to LLM
- `response_text` (TEXT) - LLM response
- `model_name` (VARCHAR) - LLM model used
- `tokens_used` (INTEGER)
- `processing_time_ms` (INTEGER)
- `confidence_score` (DECIMAL)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `created_at` (TIMESTAMP)

### PARA Archives View
#### `archives` (Virtual View)
```sql
CREATE VIEW archives AS
SELECT 'blob' as content_type, id, content as title, source_type, work_personal, archived_at, area_id, project_id
FROM blobs WHERE is_archived = true
UNION ALL
SELECT 'task' as content_type, id, title, status::text, work_personal, archived_at, area_id, project_id  
FROM tasks WHERE is_archived = true
UNION ALL
SELECT 'resource' as content_type, id, title, type, work_personal, archived_at, area_id, project_id
FROM resources WHERE is_archived = true;
```

## PARA Framework Implementation Details

### Repository Architecture
- **AreaRepository**: Manage PARA areas with project counting and analytics
- **ResourceRepository**: Handle knowledge assets with advanced search and tagging
- **ArchiveRepository**: Cross-category archive management with bulk operations
- **PromptLogRepository**: LLM pipeline tracking with performance metrics

### Prompt Engineering System
- **Versioned Templates**: Stored in `/prompts/templates/` with version control
- **Template Categories**: 
  - `categorize_blob.txt` - PARA categorization logic
  - `extract_tasks.txt` - Task extraction with area/project context
  - `summarize_content.txt` - Content summarization for resources
- **Performance Tracking**: Token usage, processing time, confidence scores
- **A/B Testing**: Version comparison for prompt optimization

### PARA Content Protocol
```swift
protocol PARAContent {
    var id: UUID { get }
    var areaId: UUID? { get }
    var projectId: UUID? { get }
    var isArchived: Bool { get }
    var archivedAt: String? { get }
    var workPersonal: WorkPersonalType { get }
}
```

## Directory Structure

```
LifeManager/
├── .git/                     # Git repository
├── .cursorrules             # Cursor AI rules and preferences
├── PROJECT.md               # This file - project overview and documentation
├── implementation_details.txt # Change log and implementation notes
├── prompts/                 # AI prompt engineering
│   └── templates/          # Versioned prompt templates
│       ├── categorize_blob.txt
│       ├── extract_tasks.txt
│       └── summarize_content.txt
├── doc/                     # Documentation folder
│   ├── api.md              # API documentation
│   ├── database.md         # Database schema details
│   └── architecture.md     # System architecture
├── tickets/                 # Feature and bug tracking
│   ├── feature-001-supabase-setup.md
│   ├── feature-002-swift-data-models.md
│   └── feature-003-ai-processing.md
├── LifeManager/             # Xcode project
│   ├── LifeManager.xcodeproj
│   ├── LifeManager/
│   │   ├── App/            # App entry point and configuration
│   │   ├── Models/         # Swift data models (includes PARAModels.swift)
│   │   ├── Services/       # Supabase service layer
│   │   ├── Repositories/   # Data access layer (includes PARARepository.swift)
│   │   ├── Views/          # SwiftUI views
│   │   ├── ViewModels/     # View models (MVVM)
│   │   ├── Utils/          # Utility functions
│   │   └── Resources/      # Assets and configuration
│   └── Tests/              # Unit and integration tests
├── supabase/               # Supabase configuration
│   ├── migrations/         # Database migrations
│   │   ├── 001_initial_schema.sql
│   │   └── 002_para_implementation.sql
│   ├── seed.sql           # Initial data
│   ├── para_seed.sql      # PARA-specific seed data
│   └── config.toml        # Supabase configuration
├── scripts/                # Utility scripts
└── README.md               # Project readme
```

## Repository Configuration

- **Repository**: https://github.com/anmolmanchanda/LifeManager
- **Author**: manchandaanmol@icloud.com
- **Branch Strategy**: dev for all AI-generated code, main for releases

## Version 1.0 Scope - STRICTLY DEFINED (Core LLM Productivity + Knowledge Base)

### INCLUDED Features (v1.0 ONLY):
- **Natural language task input and parsing** (e.g., "Lunch with Sarah tomorrow at noon" creates the right task with date/time/priority)
- **AI/LLM-powered task prioritization, scoring, and suggested due dates**
- **Core PARA structure**: Complete Projects, Areas, Resources, Archives organization for all info
- **Central knowledge base**: Journals, resources, recipes, finances, shows, YouTube, inventory, grocery lists, research papers, therapy notes, etc.
- **Full-text and semantic search** across all content
- **Smart (manual) task bump/reschedule option** (user can nudge overdue tasks, but not yet auto-rescheduled)
- **Manual "focus" flag on tasks** for future focus mode
- **Version history/audit for all changes** with prompt logging
- **Supabase PostgreSQL storage** with PARA schema
- **Native macOS SwiftUI interface** with PARA navigation
- **Work/personal distinction** within PARA structure
- **Inbox processing workflow** with PARA routing

### EXCLUDED Features (Must NOT be present in v1.0):
- ❌ **NO automated calendar scheduling** (v2.0 feature)
- ❌ **NO recurring tasks** (v1.5 feature)
- ❌ **NO team/collaboration features** (v2.0 feature)
- ❌ **NO real calendar sync** (v2.0 feature)
- ❌ **NO automated rescheduling** (v2.0 feature)
- ❌ **NO focus mode UI/filtering** (v1.5 feature)
- ❌ **NO task dependencies** (v2.0 feature)
- ❌ Voice/audio input or output
- ❌ Drag-and-drop, file, or image handling
- ❌ Direct integration with email, messages, or other apps
- ❌ Watch app or mobile device companion
- ❌ Auto-categorization from external data sources
- ❌ Attachment storage (references only if necessary)

## Current Status

- [x] Project initialization with PARA framework
- [x] Directory structure with prompt engineering organization
- [x] Enhanced database schema with PARA tables and archiving
- [x] Swift data models with PARAContent protocol
- [x] PARA-aware repositories (Area, Resource, Archive, PromptLog)
- [x] Prompt templates for PARA categorization and task extraction
- [x] Updated PROJECT.md documentation with PARA methodology
- [ ] Supabase project setup and schema deployment
- [ ] Swift SDK integration and PARA service testing
- [ ] AI processing pipeline with prompt versioning
- [ ] SwiftUI interface with PARA navigation
- [ ] Testing framework for PARA operations

## PARA Implementation Benefits

1. **Structured Organization**: Clear distinction between projects, areas, resources, and archives
2. **Context-Aware AI**: LLM processing with PARA categorization for better accuracy
3. **Lifecycle Management**: Natural progression from active → archive with bulk operations
4. **Knowledge Base**: Comprehensive resource library with metadata and cross-linking
5. **Productivity Focus**: Area-based responsibility tracking and project completion
6. **Prompt Engineering**: Versioned templates with performance optimization
7. **Scalability**: Clean separation allows for complex organizational hierarchies

## Notes

This project serves as a comprehensive personal productivity system with the PARA methodology at its core. AI processing is enhanced with PARA context for more accurate categorization, and the prompt engineering system ensures continuous optimization of LLM interactions. The system maintains strict boundaries for v1.0 to ensure focused development while building a robust foundation for advanced PARA-based features.

All prompt templates are versioned and tracked for performance optimization, enabling A/B testing and continuous improvement of AI accuracy within the PARA framework.

# Recent Changes and Enhancements

## Recently Implemented Features

### Recently Deleted Tasks (v1.0 Enhancement)
- **Soft Deletion System**: Tasks now have a 24-hour recovery period before permanent deletion
- **Database Changes**: Added `deleted_at` column to tasks table with automatic cleanup functions
- **UI Integration**: "Recently Deleted" section added to Archives view with restore/permanent delete options
- **Auto-cleanup**: Database function to permanently delete tasks after 24 hours (manual trigger available)
- **Recovery Workflow**: Users can restore accidentally deleted tasks within the 24-hour window

### Improved Parking Lot Scheduling Logic (v1.0 Enhancement)
- **Enhanced Scheduling Detection**: Tasks are only considered "scheduled" if they have both date AND time
- **Smart Filtering**: Tasks with only dates (midnight time) are now properly categorized as "unscheduled"
- **Consistent UI**: Updated all parking lot views to use the new `isScheduled` computed property
- **Better Organization**: Clearer distinction between truly scheduled tasks vs. tasks with just due dates

### Database Schema Updates
```sql
-- New migration: 003_recently_deleted.sql
ALTER TABLE tasks ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
CREATE INDEX idx_tasks_deleted_at ON tasks(deleted_at);

-- Cleanup functions for automated maintenance
CREATE FUNCTION cleanup_permanently_deleted_tasks();
CREATE FUNCTION soft_delete_task(task_id UUID);
CREATE FUNCTION restore_deleted_task(task_id UUID);
CREATE FUNCTION permanently_delete_task(task_id UUID);
```

### Code Changes Summary
1. **Model Updates**: Enhanced `LifeTask` with `deletedAt`, `isScheduled`, `isDeleted`, and `canBePermalentlyDeleted` properties
2. **Repository Extensions**: Added soft delete, restore, and permanent delete methods to `TaskRepository`
3. **UI Components**: New `RecentlyDeletedTaskRowView` with restore/delete actions and countdown timer
4. **Filtering Logic**: Updated all task filtering to exclude deleted tasks and use proper scheduling logic
5. **Archive Integration**: Recently deleted tasks appear in Archives under dedicated section

### Implementation Details
- **Soft Delete**: Tasks marked with `deleted_at` timestamp, not immediately removed from database
- **Recovery Period**: 24-hour window for task restoration with visual countdown
- **Automatic Cleanup**: Background process to permanently delete expired tasks
- **UI Polish**: Red-tinted rows, strikethrough text, and clear action buttons for deleted tasks
- **Data Integrity**: Proper filtering ensures deleted tasks don't appear in active views

## Next Development Steps
1. Set up automated cleanup job in Supabase dashboard
2. Add bulk restore/delete operations for recently deleted items
3. Consider extending soft delete to other content types (blobs, projects)
4. Add user preferences for deletion recovery period
