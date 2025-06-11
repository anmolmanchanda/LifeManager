# LifeManager

An AI-powered personal productivity system for macOS, built with Swift/SwiftUI and Supabase.

## Overview

LifeManager is a native macOS application designed for productivity-obsessed software engineers. It serves as a comprehensive "life OS" that ingests, processes, and organizes all text-based information through AI-powered automation.

### Key Features

- **AI-Powered Organization**: Automatic categorization and tagging of all text input
- **Universal Inbox**: Single input point for all text-based information
- **Task Management**: Intelligent task extraction with priority and due date detection
- **Multi-Category Support**: Journal, Therapy, Tasks, Finance, Knowledge, Recipe, Diet, Inventory, Shows, YouTube, Grocery
- **Advanced Search**: Full-text search across all content with intelligent filtering
- **Work/Personal Separation**: Automatic classification and filtering
- **Complete Audit Trail**: Version history for all changes and edits
- **Real-time Sync**: Live data updates across the application

## Technology Stack

- **Frontend**: Swift/SwiftUI (native macOS)
- **Backend**: Supabase (managed PostgreSQL with real-time features)
- **AI Processing**: Claude/OpenAI integration
- **Database**: PostgreSQL via Supabase
- **Authentication**: Supabase Auth
- **Real-time**: Supabase Real-time subscriptions

## Project Structure

```
LifeManager/
├── PROJECT.md               # Complete project documentation
├── implementation_details.txt # Change log and implementation notes
├── .cursorrules             # Development workflow rules
├── supabase/               # Database configuration
│   ├── migrations/         # Database schema migrations
│   └── seed.sql           # Initial seed data
├── LifeManager/           # Xcode project
│   └── LifeManager/
│       ├── Models/        # Swift data models
│       ├── Services/      # Supabase service layer
│       ├── Repositories/  # Data access layer
│       ├── Views/         # SwiftUI views (to be created)
│       └── ViewModels/    # MVVM view models (to be created)
├── tickets/               # Feature tracking
└── doc/                   # Additional documentation
```

## Database Schema

The system uses 18 PostgreSQL tables organized into:

- **Core Tables** (13): blobs, categories, tags, projects, plus specialized content tables
- **Relationship Tables** (3): Many-to-many relationships for categories and tags
- **Audit Tables** (2): Complete change tracking for blobs and tasks

### Core Content Types

1. **Blobs**: Raw text input with metadata
2. **Tasks**: Action items with priority, status, and due dates
3. **Journal Entries**: Personal thoughts and daily logs
4. **Therapy Sessions**: Mental health notes and insights
5. **Financial Entries**: Money transactions and budgets
6. **Knowledge Entries**: Learning notes and research
7. **Recipes**: Cooking instructions and ingredients
8. **Diets**: Meal plans and nutrition tracking
9. **Inventory**: Item tracking and stock management
10. **Shows**: TV/movie tracking and reviews
11. **YouTube**: Video content organization
12. **Grocery Lists**: Shopping and food planning

## Current Status

### ✅ Completed
- Project setup and documentation
- Complete database schema design
- Swift data models and enums
- Supabase service layer
- Repository pattern for data access
- Blob and Task repositories

### 🔄 In Progress
- Supabase project configuration
- Swift SDK integration

### ⏳ Upcoming
- AI processing service
- SwiftUI interface
- Authentication system
- Real-time synchronization

## Development Workflow

This project follows strict development rules defined in `.cursorrules`:

1. **Always read PROJECT.md** before making changes
2. **Update implementation_details.txt** for all changes
3. **Break down tasks** before coding
4. **Production-ready code** only - no TODOs or placeholders
5. **Repository pattern** for all data access
6. **Version 1.0 scope** strictly enforced

## Version 1.0 Scope

### ✅ Included
- Manual text input via natural language interface
- Automatic AI categorization and tagging
- Task extraction and prioritization
- Work/personal classification
- Complete audit trail
- Content summarization
- Advanced search and filtering
- Multiple view modes

### ❌ Excluded
- Voice/audio input or output
- File or image handling
- External app integrations
- Mobile/watch companions
- Attachment storage

## Repository Information

- **Repository**: https://github.com/anmolmanchanda/LifeManager
- **Author**: manchandaanmol@icloud.com
- **Branch Strategy**: `dev` for development, `main` for releases
- **License**: Private project

## Getting Started

1. **Prerequisites**
   - macOS 14+
   - Xcode 15+
   - Supabase account

2. **Setup**
   - Clone the repository
   - Set up Supabase project and deploy schema
   - Configure API keys in SupabaseService.swift
   - Build and run in Xcode

3. **Documentation**
   - Read `PROJECT.md` for complete project details
   - Check `tickets/` for current development status
   - Review `implementation_details.txt` for change history

## Contributing

This is a private project following strict development guidelines. All contributions must adhere to the workflow rules defined in `.cursorrules` and maintain the repository pattern architecture.

---

*Built with ❤️ for productivity-obsessed software engineers* 