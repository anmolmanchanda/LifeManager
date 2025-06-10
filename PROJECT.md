# LifeManager - AI-Powered Personal Productivity System

## Project Summary and Goals

LifeManager is a native macOS productivity application designed for productivity-obsessed software engineers. The system serves as a comprehensive "life OS" that ingests, processes, and organizes all text-based information through AI-powered automation.

**Core Purpose**: Build the backend logic, workflow, and prompt-engine for a MacOS app that ingests, parses, categorizes, and organizes all the user's text-based information in real time. All data must be structured for fast search, tagging, prioritization, and audit/history.

**Primary Goals**:
- Receive and process large pieces of unstructured text ("blobs") with metadata
- Automate task creation, organization, and prioritization
- Provide structured, tagged, searchable digital organization system
- Maintain complete audit trail and version history
- Enable fast search, filtering, and multiple view modes

## Implementation Plan

### Phase 1: Core Infrastructure (v1.0)
1. **Database Setup & Schema Implementation**
   - PostgreSQL database with all required tables
   - Implement audit/history tracking for all records
   - Set up proper indexing for search performance

2. **Input Processing Engine**
   - Natural language input interface
   - Text blob parsing and metadata extraction
   - Automatic categorization system

3. **AI Processing Pipeline**
   - LLM-driven categorization and tagging
   - Task extraction and prioritization
   - Content summarization
   - Work/personal classification

4. **Data Organization System**
   - Inbox processing workflow
   - Category assignment (Journal, Therapy, Task, Finance, Knowledge)
   - Tag and project management
   - Cross-linking capabilities

5. **Search & Retrieval System**
   - Natural language search queries
   - Multi-field filtering capabilities
   - Multiple view modes (task list, calendar, timeline)
   - Work/personal filtering

6. **History & Audit Trail**
   - Version control for all changes
   - Complete edit history tracking
   - Rollback capabilities

### Phase 2: Enhanced Features (Future)
- Advanced analytics and insights
- Pattern recognition and suggestions
- Enhanced prioritization algorithms
- Performance optimizations

## Database Schema

### Core Tables

#### `blobs`
- `id` (PRIMARY KEY, UUID)
- `content` (TEXT) - Original unstructured text
- `source_type` (VARCHAR) - email, note, journal, etc.
- `context` (TEXT) - Additional context or metadata
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `processed` (BOOLEAN) - Whether blob has been processed
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `categories`
- `id` (PRIMARY KEY, UUID)
- `name` (VARCHAR) - Journal, Therapy, Task, Finance, Knowledge
- `description` (TEXT)
- `created_at` (TIMESTAMP)

#### `tags`
- `id` (PRIMARY KEY, UUID)
- `name` (VARCHAR)
- `color` (VARCHAR) - For UI display
- `created_at` (TIMESTAMP)

#### `projects`
- `id` (PRIMARY KEY, UUID)
- `name` (VARCHAR)
- `description` (TEXT)
- `status` (ENUM: 'active', 'completed', 'archived')
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `journal_entries`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `summary` (TEXT)
- `mood` (VARCHAR)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `therapy_notes`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `session_date` (DATE)
- `therapist` (VARCHAR)
- `summary` (TEXT)
- `insights` (TEXT)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `tasks`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `description` (TEXT)
- `priority` (ENUM: 'urgent', 'high', 'medium', 'low')
- `status` (ENUM: 'inbox', 'todo', 'in_progress', 'completed', 'cancelled')
- `due_date` (TIMESTAMP)
- `estimated_duration` (INTEGER) - in minutes
- `work_personal` (ENUM: 'work', 'personal', 'both')
- `project_id` (FOREIGN KEY → projects.id)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)
- `completed_at` (TIMESTAMP)

#### `financial_entries`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `amount` (DECIMAL)
- `currency` (VARCHAR)
- `category` (VARCHAR) - expense, income, investment, etc.
- `description` (TEXT)
- `transaction_date` (DATE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

#### `knowledge_entries`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `title` (VARCHAR)
- `summary` (TEXT)
- `topic` (VARCHAR)
- `source_url` (VARCHAR)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

### Relationship Tables

#### `blob_categories`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `category_id` (FOREIGN KEY → categories.id)
- `confidence_score` (DECIMAL) - AI confidence in categorization
- `created_at` (TIMESTAMP)

#### `blob_tags`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `tag_id` (FOREIGN KEY → tags.id)
- `created_at` (TIMESTAMP)

#### `task_tags`
- `id` (PRIMARY KEY, UUID)
- `task_id` (FOREIGN KEY → tasks.id)
- `tag_id` (FOREIGN KEY → tags.id)
- `created_at` (TIMESTAMP)

### History/Audit Tables

#### `blob_history`
- `id` (PRIMARY KEY, UUID)
- `blob_id` (FOREIGN KEY → blobs.id)
- `field_name` (VARCHAR)
- `old_value` (TEXT)
- `new_value` (TEXT)
- `changed_by` (VARCHAR) - system or user identifier
- `changed_at` (TIMESTAMP)

#### `task_history`
- `id` (PRIMARY KEY, UUID)
- `task_id` (FOREIGN KEY → tasks.id)
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
│   ├── api.md              # API documentation (future)
│   ├── database.md         # Database schema details (future)
│   └── architecture.md     # System architecture (future)
├── tickets/                 # Feature and bug tracking
│   ├── feature-001-input-processing.md
│   └── feature-002-ai-categorization.md
├── src/                     # Source code (to be created)
│   ├── backend/            # Backend API and logic
│   ├── database/           # Database migrations and setup
│   ├── ai/                 # AI processing pipeline
│   └── tests/              # Test files
├── config/                  # Configuration files (to be created)
├── scripts/                 # Utility scripts (to be created)
└── README.md               # Basic project readme (to be created)
```

## Version 1.0 Scope - STRICTLY DEFINED

### INCLUDED Features:
- Manual text input only (natural language bar, text fields)
- Automatic categorization and tagging of text blobs
- Task extraction and prioritization
- Work/personal distinction
- Complete history and audit trail
- Summarization of long content
- PostgreSQL database storage
- Search and retrieval with natural language queries
- Multiple view modes (task list, calendar, timeline)
- Inbox processing workflow

### EXCLUDED Features (Must NOT be present in v1.0):
- Voice/audio input or output
- Drag-and-drop, file, or image handling
- Direct integration with email, messages, or other apps
- Watch app or mobile device companion
- Auto-categorization from external data sources
- Attachment storage (references only if necessary)

## Current Status

- [x] Project initialization
- [x] Directory structure created
- [x] Initial PROJECT.md documentation
- [ ] Database schema implementation
- [ ] Backend API development
- [ ] AI processing pipeline
- [ ] Frontend interface
- [ ] Testing framework

## Notes

This project serves as a comprehensive personal productivity system, with AI at its core for processing and organizing all text-based information. The system maintains strict boundaries for v1.0 to ensure focused development and clear scope management.
