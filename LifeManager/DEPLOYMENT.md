# LifeManager SwiftUI App - Deployment Guide

## 🚀 Production-Ready SwiftUI macOS App with PARA Framework

This guide covers the complete deployment and setup of the LifeManager SwiftUI app with Supabase backend integration.

---

## 📋 Prerequisites

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+** with Swift 5.9+
- **Supabase Project** (create at [supabase.com](https://supabase.com))
- **OpenAI API Key** or **Claude API Key** for LLM services

---

## 🏗️ Architecture Overview

### **Version 1.0 Features (Current Implementation)**
- ✅ Natural language task input and parsing
- ✅ AI/LLM-powered task prioritization and scoring
- ✅ Complete PARA framework (Projects, Areas, Resources, Archives)
- ✅ Central knowledge base with full-text search
- ✅ Manual task focus flag for future focus mode
- ✅ Version history and audit trails
- ✅ Supabase authentication and real-time sync
- ✅ SwiftUI native macOS interface

### **Key Components**
- **SwiftUI Views**: Native macOS interface with sidebar navigation
- **PARA Repository Pattern**: Type-safe database operations
- **LLM Service**: OpenAI/Claude integration for content processing
- **Supabase Integration**: Authentication, real-time sync, and RLS security

---

## 🔧 Setup Instructions

### **1. Clone and Configure**

```bash
git clone https://github.com/anmolmanchanda/LifeManager.git
cd LifeManager
```

### **2. Environment Configuration**

Copy the example configuration:
```bash
cp LifeManager/LifeManager/Resources/Config.example.swift LifeManager/LifeManager/Resources/Config.swift
```

Update `Config.swift` with your actual values:
```swift
struct Config {
    static let supabaseURL = "https://your-project.supabase.co"
    static let supabaseAnonKey = "your-anon-key-here"
    static let openAIKey = "your-openai-key-here"
    // ... other settings
}
```

**Important**: Add `Config.swift` to your `.gitignore` to keep secrets safe.

### **3. Supabase Database Setup**

Run the complete database migration in your Supabase SQL Editor:

```sql
-- 1. Run the initial schema migration
-- Copy and paste the content from: supabase/migrations/001_initial_schema.sql

-- 2. Run the PARA implementation migration
-- Copy and paste the content from: supabase/migrations/002_para_implementation.sql

-- 3. Run the seed data
-- Copy and paste the content from: supabase/para_seed.sql
```

### **4. Row Level Security (RLS) Policies**

Apply these RLS policies in Supabase Dashboard > Authentication > Policies:

```sql
-- Enable RLS on all tables
ALTER TABLE blobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

-- Create policies for authenticated users only
CREATE POLICY "Users can manage their own blobs" ON blobs
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can manage their own areas" ON areas
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can manage their own projects" ON projects
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can manage their own tasks" ON tasks
    FOR ALL USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can manage their own resources" ON resources
    FOR ALL USING (auth.uid()::text = user_id::text);
```

### **5. Xcode Project Setup**

1. Open `LifeManager.xcodeproj` in Xcode
2. Add Supabase Swift Package:
   - **File** → **Add Package Dependencies**
   - URL: `https://github.com/supabase/supabase-swift`
   - Add to target: **LifeManager**

3. Add any additional dependencies as needed

### **6. Build and Run**

1. Select **LifeManager** scheme
2. Choose **My Mac** as destination
3. Press **⌘R** to build and run

---

## 🎯 Core Usage (v1.0 Features)

### **Natural Language Input**
```
"Lunch with Sarah tomorrow at noon"
→ Creates task with date/time parsing
→ AI suggests area/project assignment
→ Auto-prioritizes based on content
```

### **PARA Organization**
- **Projects**: Outcome-based work with deliverables
- **Areas**: Ongoing responsibilities to maintain
- **Resources**: Reference materials and knowledge
- **Archives**: Inactive items from all categories

### **Smart Search**
- Full-text search across all content types
- Semantic search with LLM integration
- Filter by work/personal, area, project, or status

### **Manual Focus Flag**
- Mark tasks as "focus" for priority attention
- Foundation for future v1.5 focus mode features

---

## 🛠️ Development Workflow

### **Adding New Features**
1. Check version roadmap in `PROJECT.md`
2. Only implement features for current version (v1.0)
3. Update `implementation_details.txt` with changes
4. Follow repository pattern for data operations

### **Database Changes**
1. Create new migration file: `supabase/migrations/00X_description.sql`
2. Update models in `Models/` directory
3. Update repositories if needed
4. Test with local Supabase instance

### **LLM Integration**
- Prompt templates in `prompts/templates/`
- All prompts logged to `prompt_logs` table
- Supports both OpenAI and Claude APIs
- Configurable via `Config.swift`

---

## 🧪 Testing

### **Supabase Connection Test**
```bash
# Test authentication
curl -X POST 'https://your-project.supabase.co/auth/v1/signup' \
  -H 'apikey: your-anon-key' \
  -H 'Content-Type: application/json' \
  -d '{"email": "test@example.com", "password": "password123"}'
```

### **Database Validation**
```sql
-- Check table creation
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Verify seed data
SELECT name, color FROM areas;
SELECT name FROM tags WHERE category = 'para';
```

### **App Integration Test**
1. Launch app
2. Sign in with test account
3. Add natural language input: "Review quarterly reports by Friday"
4. Verify AI processing and PARA categorization
5. Check Supabase dashboard for data persistence

---

## 🔐 Security Considerations

- **RLS Policies**: All data isolated by user authentication
- **API Keys**: Stored in `Config.swift` (gitignored)
- **Environment Variables**: Support for deployment environments
- **Audit Trails**: Complete version history for all changes

---

## 📈 Performance Optimization

- **Lazy Loading**: Content loaded on-demand
- **Caching**: Repository pattern with local caching
- **Pagination**: Large datasets paginated automatically
- **Real-time**: Supabase subscriptions for live updates

---

## 🚦 Version Discipline

**STRICTLY ENFORCE**: Only implement v1.0 features!

### **v1.0 (Current)**
- Natural language input ✅
- PARA organization ✅
- Manual focus flag ✅
- Search and history ✅

### **v1.5 (Future)**
- Semi-automated rescheduling ❌
- Manual focus mode ❌
- Recurring tasks ❌

### **v2.0 (Future)**
- Calendar sync ❌
- Automated scheduling ❌
- Collaboration ❌

---

## 📞 Support

For deployment issues:
1. Check `implementation_details.txt` for recent changes
2. Verify Supabase connection and RLS policies
3. Test LLM API connectivity
4. Review Xcode build logs for Swift compilation errors

---

**Version**: 1.0  
**Last Updated**: Current  
**Status**: Production Ready 🎉 