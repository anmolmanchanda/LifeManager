# LifeManager - AI-Powered Personal Productivity System with PARA Framework

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

## Version 1.0 Scope - STRICTLY DEFINED

### INCLUDED Features:
- Manual text input only (natural language bar, text fields)
- **PARA Framework**: Complete Projects, Areas, Resources, Archives organization
- Automatic categorization and tagging with PARA context
- Task extraction and prioritization with area/project assignment
- Work/personal distinction within PARA structure
- Complete history and audit trail with prompt logging
- Summarization of long content for resource library
- Supabase PostgreSQL storage with PARA schema
- Search and retrieval with PARA-aware filtering
- Multiple view modes (PARA dashboard, task list, calendar, timeline)
- Inbox processing workflow with PARA routing
- Resource library management with metadata and archiving
- Native macOS SwiftUI interface with PARA navigation

### EXCLUDED Features (Must NOT be present in v1.0):
- Voice/audio input or output
- Drag-and-drop, file, or image handling
- Direct integration with email, messages, or other apps
- Watch app or mobile device companion
- Auto-categorization from external data sources
- Attachment storage (references only if necessary)

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
