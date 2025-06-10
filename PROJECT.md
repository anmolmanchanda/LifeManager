# LifeManager - AI-Powered Personal Productivity System

## Project Summary and Goals

LifeManager is a native macOS productivity application designed for productivity-obsessed software engineers. The system serves as a comprehensive "life OS" that ingests, processes, and organizes all text-based information through AI-powered automation using **Supabase** as the managed backend and **Swift/SwiftUI** for the native macOS interface.

**Core Purpose**: Build a native macOS app with backend logic and AI prompt-engine that ingests, parses, categorizes, and organizes all the user's text-based information in real time. All data is structured in Supabase (PostgreSQL) for fast search, tagging, prioritization, and audit/history.

**Primary Goals**:
- Receive and process large pieces of unstructured text ("blobs") with metadata
- Automate task creation, organization, and prioritization using AI
- Provide structured, tagged, searchable digital organization system
- Maintain complete audit trail and version history
- Enable fast search, filtering, and multiple view modes
- Native macOS experience with SwiftUI interface
- Managed backend with Supabase for reliability and scalability

## Technology Stack

- **Frontend**: Swift/SwiftUI (native macOS)
- **Backend**: Supabase (managed PostgreSQL with real-time features)
- **AI Processing**: Claude/OpenAI integration
- **Database**: PostgreSQL via Supabase
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Real-time subscriptions

## Implementation Plan

### Phase 1: Core Infrastructure (v1.0)
1. **Supabase Setup & Schema Implementation**
   - Supabase project setup and configuration
   - Complete database schema with all required tables
   - Implement audit/history tracking for all records
   - Set up proper indexing and RLS policies

2. **Swift Data Layer**
   - Supabase Swift SDK integration
   - Swift data models for all tables
   - Repository pattern for data access
   - Real-time data synchronization

3. **Input Processing Engine**
   - SwiftUI natural language input interface
   - Text blob parsing and metadata extraction
   - Automatic categorization system

4. **AI Processing Pipeline**
   - LLM-driven categorization and tagging
   - Task extraction and prioritization
   - Content summarization
   - Work/personal classification

5. **Data Organization System**
   - Inbox processing workflow
   - Category assignment and management
   - Tag and project management
   - Cross-linking capabilities

6. **Search & Retrieval System**
   - Natural language search queries
   - Multi-field filtering capabilities
   - Multiple view modes (task list, calendar, timeline)
   - Work/personal filtering

7. **SwiftUI Interface**
   - Native macOS interface design
   - Multiple view modes and navigation
   - Real-time data updates
   - Responsive and intuitive UX

### Phase 2: Enhanced Features (Future)
- Advanced analytics and insights
- Pattern recognition and suggestions
- Enhanced prioritization algorithms
- Performance optimizations
- Additional data types and categories

## Database Schema (Supabase PostgreSQL)

### Core Tables

#### `blobs`
- `id` (UUID, PRIMARY KEY)
- `content` (TEXT) - Original unstructured text
- `source_type` (ENUM) - email, note, journal, recipe, diet, screenshot, inventory, show, youtube, grocery, insight, knowledge
- `context` (JSONB) - Additional structured metadata (device info, location, etc.)
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `processed` (BOOLEAN) - Whether blob has been processed
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `categories`
- `id` (UUID, PRIMARY KEY)
- `name` (VARCHAR) - Journal, Therapy, Task, Finance, Knowledge, Recipe, Diet, Inventory, Show, YouTube, Grocery
- `description` (TEXT)
- `created_at` (TIMESTAMP)

#### `tags`
- `id` (UUID, PRIMARY KEY)
- `name` (VARCHAR)
- `color` (VARCHAR) - For UI display
- `created_at` (TIMESTAMP)

#### `projects`
- `id` (UUID, PRIMARY KEY)
- `name` (VARCHAR)
- `description` (TEXT)
- `status` (ENUM: 'active', 'completed', 'archived')
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `journal_entries`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `summary` (TEXT)
- `mood` (VARCHAR)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `therapy_sessions`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `session_date` (DATE)
- `therapist` (VARCHAR)
- `summary` (TEXT)
- `insights` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `tasks`
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
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `completed_at` (TIMESTAMP)

#### `financial_entries`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `amount` (DECIMAL)
- `currency` (VARCHAR)
- `category` (ENUM: 'expense', 'income', 'investment', 'transfer')
- `description` (TEXT)
- `transaction_date` (DATE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `knowledge_entries`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `summary` (TEXT)
- `topic` (VARCHAR)
- `source_url` (VARCHAR)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `recipes`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `ingredients` (TEXT)
- `instructions` (TEXT)
- `source_url` (VARCHAR)
- `nutrition` (JSONB)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `diets`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `meals` (JSONB)
- `notes` (TEXT)
- `start_date` (DATE)
- `end_date` (DATE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `inventories`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `item_name` (VARCHAR)
- `category` (VARCHAR)
- `quantity` (INTEGER)
- `location` (VARCHAR)
- `expiration_date` (DATE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `shows`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `season` (INTEGER)
- `episode` (INTEGER)
- `status` (ENUM: 'watching', 'completed', 'on_hold', 'dropped')
- `platform` (VARCHAR)
- `notes` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `youtube_entries`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `video_id` (VARCHAR)
- `title` (VARCHAR)
- `channel` (VARCHAR)
- `playlist` (VARCHAR)
- `type` (ENUM: 'video', 'playlist', 'reaction', 'review')
- `watched_at` (TIMESTAMP)
- `notes` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `grocery_lists`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `list_title` (VARCHAR)
- `items` (JSONB)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Relationship Tables

#### `blob_categories`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `category_id` (UUID, FOREIGN KEY → categories.id)
- `confidence_score` (DECIMAL) - AI confidence in categorization
- `created_at` (TIMESTAMP)

#### `blob_tags`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `tag_id` (UUID, FOREIGN KEY → tags.id)
- `created_at` (TIMESTAMP)

#### `task_tags`
- `id` (UUID, PRIMARY KEY)
- `task_id` (UUID, FOREIGN KEY → tasks.id)
- `tag_id` (UUID, FOREIGN KEY → tags.id)
- `created_at` (TIMESTAMP)

### History/Audit Tables

#### `blob_history`
- `id` (UUID, PRIMARY KEY)
- `blob_id` (UUID, FOREIGN KEY → blobs.id)
- `field_name` (VARCHAR)
- `old_value` (TEXT)
- `new_value` (TEXT)
- `changed_by` (VARCHAR) - system or user identifier
- `changed_at` (TIMESTAMP)

#### `task_history`
- `id` (UUID, PRIMARY KEY)
- `task_id` (UUID, FOREIGN KEY → tasks.id)
- `field_name` (VARCHAR)
- `old_value` (TEXT)
- `new_value` (TEXT)
- `changed_by` (VARCHAR)
- `changed_at` (TIMESTAMP)

## Directory Structure

```
LifeManager/
├── .git/                     # Git repository
├── .cursorrules             # Cursor AI rules and preferences
├── PROJECT.md               # This file - project overview and documentation
├── implementation_details.txt # Change log and implementation notes
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
│   │   ├── Models/         # Swift data models
│   │   ├── Services/       # Supabase service layer
│   │   ├── Repositories/   # Data access layer
│   │   ├── Views/          # SwiftUI views
│   │   ├── ViewModels/     # View models (MVVM)
│   │   ├── Utils/          # Utility functions
│   │   └── Resources/      # Assets and configuration
│   └── Tests/              # Unit and integration tests
├── supabase/               # Supabase configuration
│   ├── migrations/         # Database migrations
│   ├── seed.sql           # Initial data
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
- Automatic categorization and tagging of text blobs
- Task extraction and prioritization
- Work/personal distinction
- Complete history and audit trail
- Summarization of long content
- Supabase PostgreSQL storage
- Search and retrieval with natural language queries
- Multiple view modes (task list, calendar, timeline)
- Inbox processing workflow
- Recipe, diet, inventory, show, YouTube, and grocery list management
- Native macOS SwiftUI interface

### EXCLUDED Features (Must NOT be present in v1.0):
- Voice/audio input or output
- Drag-and-drop, file, or image handling
- Direct integration with email, messages, or other apps
- Watch app or mobile device companion
- Auto-categorization from external data sources
- Attachment storage (references only if necessary)

## Current Status

- [x] Project initialization
- [x] Directory structure planned
- [x] Updated PROJECT.md documentation with Supabase approach
- [ ] Supabase project setup and schema implementation
- [ ] Swift data models and service layer
- [ ] SwiftUI interface development
- [ ] AI processing pipeline
- [ ] Testing framework

## Notes

This project serves as a comprehensive personal productivity system, with AI at its core for processing and organizing all text-based information. The system uses Supabase for managed backend services and maintains strict boundaries for v1.0 to ensure focused development and clear scope management.
