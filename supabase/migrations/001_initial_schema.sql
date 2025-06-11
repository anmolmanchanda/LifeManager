-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom enum types
CREATE TYPE work_personal_type AS ENUM ('work', 'personal', 'both');
CREATE TYPE task_priority_type AS ENUM ('urgent', 'high', 'medium', 'low');
CREATE TYPE task_status_type AS ENUM ('inbox', 'todo', 'in_progress', 'completed', 'cancelled');
CREATE TYPE project_status_type AS ENUM ('active', 'completed', 'archived');
CREATE TYPE financial_category_type AS ENUM ('expense', 'income', 'investment', 'transfer');
CREATE TYPE show_status_type AS ENUM ('watching', 'completed', 'on_hold', 'dropped');
CREATE TYPE youtube_type AS ENUM ('video', 'playlist', 'reaction', 'review');
CREATE TYPE source_type AS ENUM ('email', 'note', 'journal', 'recipe', 'diet', 'screenshot', 'inventory', 'show', 'youtube', 'grocery', 'insight', 'knowledge');

-- Core Tables

-- blobs: Core text storage with metadata
CREATE TABLE blobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    source_type source_type NOT NULL,
    context JSONB DEFAULT '{}',
    work_personal work_personal_type DEFAULT 'personal',
    processed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- categories: Fixed category definitions
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- tags: Dynamic tag management
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    color VARCHAR(7) DEFAULT '#3B82F6', -- Default blue color
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- projects: Project organization
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    status project_status_type DEFAULT 'active',
    work_personal work_personal_type DEFAULT 'personal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- journal_entries: Journal-specific data
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    summary TEXT,
    mood VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- therapy_sessions: Therapy session data
CREATE TABLE therapy_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    session_date DATE,
    therapist VARCHAR(100),
    summary TEXT,
    insights TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- tasks: Task and to-do management
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID REFERENCES blobs(id) ON DELETE SET NULL,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    priority task_priority_type DEFAULT 'medium',
    status task_status_type DEFAULT 'inbox',
    due_date TIMESTAMP WITH TIME ZONE,
    estimated_duration INTEGER, -- in minutes
    work_personal work_personal_type DEFAULT 'personal',
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- financial_entries: Financial transaction data
CREATE TABLE financial_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    category financial_category_type NOT NULL,
    description TEXT,
    transaction_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- knowledge_entries: Knowledge base items
CREATE TABLE knowledge_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    summary TEXT,
    topic VARCHAR(100),
    source_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- recipes: Recipe data
CREATE TABLE recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    ingredients TEXT,
    instructions TEXT,
    source_url TEXT,
    nutrition JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- diets: Diet plan data
CREATE TABLE diets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    meals JSONB DEFAULT '{}',
    notes TEXT,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- inventories: Inventory management
CREATE TABLE inventories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    item_name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    quantity INTEGER DEFAULT 1,
    location VARCHAR(100),
    expiration_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- shows: TV show and movie tracking
CREATE TABLE shows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    season INTEGER,
    episode INTEGER,
    status show_status_type DEFAULT 'watching',
    platform VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- youtube_entries: YouTube content tracking
CREATE TABLE youtube_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    video_id VARCHAR(100),
    title VARCHAR(300) NOT NULL,
    channel VARCHAR(200),
    playlist VARCHAR(300),
    type youtube_type DEFAULT 'video',
    watched_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- grocery_lists: Grocery list management
CREATE TABLE grocery_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    list_title VARCHAR(300) NOT NULL,
    items JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Relationship Tables

-- blob_categories: Many-to-many blob-category relationships
CREATE TABLE blob_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    confidence_score DECIMAL(3, 2) DEFAULT 0.5, -- 0.00 to 1.00
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blob_id, category_id)
);

-- blob_tags: Many-to-many blob-tag relationships
CREATE TABLE blob_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blob_id, tag_id)
);

-- task_tags: Many-to-many task-tag relationships
CREATE TABLE task_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(task_id, tag_id)
);

-- History/Audit Tables

-- blob_history: Complete change tracking for blobs
CREATE TABLE blob_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by VARCHAR(100) DEFAULT 'system',
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- task_history: Complete change tracking for tasks
CREATE TABLE task_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    field_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by VARCHAR(100) DEFAULT 'system',
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance

-- Blob content search
CREATE INDEX idx_blobs_content ON blobs USING gin(to_tsvector('english', content));
CREATE INDEX idx_blobs_source_type ON blobs(source_type);
CREATE INDEX idx_blobs_work_personal ON blobs(work_personal);
CREATE INDEX idx_blobs_processed ON blobs(processed);
CREATE INDEX idx_blobs_created_at ON blobs(created_at);

-- Task indexes
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_priority ON tasks(priority);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_work_personal ON tasks(work_personal);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);

-- Category and tag indexes
CREATE INDEX idx_blob_categories_blob_id ON blob_categories(blob_id);
CREATE INDEX idx_blob_categories_category_id ON blob_categories(category_id);
CREATE INDEX idx_blob_tags_blob_id ON blob_tags(blob_id);
CREATE INDEX idx_blob_tags_tag_id ON blob_tags(tag_id);
CREATE INDEX idx_task_tags_task_id ON task_tags(task_id);
CREATE INDEX idx_task_tags_tag_id ON task_tags(tag_id);

-- History indexes
CREATE INDEX idx_blob_history_blob_id ON blob_history(blob_id);
CREATE INDEX idx_task_history_task_id ON task_history(task_id);
CREATE INDEX idx_blob_history_changed_at ON blob_history(changed_at);
CREATE INDEX idx_task_history_changed_at ON task_history(changed_at);

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers
CREATE TRIGGER update_blobs_updated_at BEFORE UPDATE ON blobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_journal_entries_updated_at BEFORE UPDATE ON journal_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_therapy_sessions_updated_at BEFORE UPDATE ON therapy_sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_financial_entries_updated_at BEFORE UPDATE ON financial_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_knowledge_entries_updated_at BEFORE UPDATE ON knowledge_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recipes_updated_at BEFORE UPDATE ON recipes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_diets_updated_at BEFORE UPDATE ON diets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inventories_updated_at BEFORE UPDATE ON inventories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_shows_updated_at BEFORE UPDATE ON shows
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_youtube_entries_updated_at BEFORE UPDATE ON youtube_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grocery_lists_updated_at BEFORE UPDATE ON grocery_lists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 