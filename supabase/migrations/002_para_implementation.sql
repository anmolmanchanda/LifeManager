-- PARA Framework Implementation Migration
-- This migration implements the PARA (Projects, Areas, Resources, Archives) framework

-- Create areas table (Areas: Ongoing responsibilities/spheres of activity)
CREATE TABLE areas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    icon VARCHAR(50), -- Icon name for UI
    color VARCHAR(7) DEFAULT '#3B82F6', -- Color for UI
    work_personal work_personal_type DEFAULT 'personal',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create resources table (Resources: Reference materials and knowledge assets)
CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    blob_id UUID NOT NULL REFERENCES blobs(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    type VARCHAR(50) NOT NULL, -- research_paper, recipe, article, video, playlist, guide, insight, book, etc.
    authors JSONB DEFAULT '[]',
    summary TEXT,
    source_url TEXT,
    area_id UUID REFERENCES areas(id) ON DELETE SET NULL,
    project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
    tags JSONB DEFAULT '[]',
    metadata JSONB DEFAULT '{}', -- Additional structured metadata
    work_personal work_personal_type DEFAULT 'personal',
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    archived_at TIMESTAMP WITH TIME ZONE
);

-- Add area_id to existing projects table
ALTER TABLE projects ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE projects ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE projects ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

-- Add archiving capabilities to all content tables
ALTER TABLE tasks ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE tasks ADD COLUMN resource_id UUID REFERENCES resources(id) ON DELETE SET NULL;
ALTER TABLE tasks ADD COLUMN is_focus BOOLEAN DEFAULT false; -- Manual focus flag for v1.0
ALTER TABLE tasks ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE tasks ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE journal_entries ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE journal_entries ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE journal_entries ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE journal_entries ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE therapy_sessions ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE therapy_sessions ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE therapy_sessions ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE therapy_sessions ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE financial_entries ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE financial_entries ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE financial_entries ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE financial_entries ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE knowledge_entries ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE knowledge_entries ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE knowledge_entries ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE knowledge_entries ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE recipes ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE recipes ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE recipes ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE recipes ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE diets ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE diets ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE diets ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE diets ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE inventories ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE inventories ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE inventories ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE inventories ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE shows ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE shows ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE shows ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE shows ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE youtube_entries ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE youtube_entries ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE youtube_entries ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE youtube_entries ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE grocery_lists ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE grocery_lists ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE grocery_lists ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE grocery_lists ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

-- Add archiving to blobs table
ALTER TABLE blobs ADD COLUMN area_id UUID REFERENCES areas(id) ON DELETE SET NULL;
ALTER TABLE blobs ADD COLUMN project_id UUID REFERENCES projects(id) ON DELETE SET NULL;
ALTER TABLE blobs ADD COLUMN is_archived BOOLEAN DEFAULT false;
ALTER TABLE blobs ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

-- Create relationship tables for resources
CREATE TABLE resource_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    tag_id UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(resource_id, tag_id)
);

-- Create prompt_logs table for LLM pipeline auditing
CREATE TABLE prompt_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prompt_template VARCHAR(100) NOT NULL, -- Template identifier
    prompt_version VARCHAR(20) NOT NULL, -- Version for A/B testing
    input_data JSONB NOT NULL, -- Input parameters
    prompt_text TEXT NOT NULL, -- Final prompt sent to LLM
    response_text TEXT NOT NULL, -- LLM response
    model_name VARCHAR(50) NOT NULL, -- LLM model used
    tokens_used INTEGER,
    processing_time_ms INTEGER,
    confidence_score DECIMAL(3, 2),
    blob_id UUID REFERENCES blobs(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for PARA tables
CREATE INDEX idx_areas_name ON areas(name);
CREATE INDEX idx_areas_work_personal ON areas(work_personal);

CREATE INDEX idx_resources_title ON resources(title);
CREATE INDEX idx_resources_type ON resources(type);
CREATE INDEX idx_resources_area_id ON resources(area_id);
CREATE INDEX idx_resources_project_id ON resources(project_id);
CREATE INDEX idx_resources_is_archived ON resources(is_archived);
CREATE INDEX idx_resources_work_personal ON resources(work_personal);
CREATE INDEX idx_resources_content_search ON resources USING gin(to_tsvector('english', coalesce(title, '') || ' ' || coalesce(summary, '')));

CREATE INDEX idx_projects_area_id ON projects(area_id);
CREATE INDEX idx_projects_is_archived ON projects(is_archived);

-- Add indexes for new PARA relationships
CREATE INDEX idx_tasks_area_id ON tasks(area_id);
CREATE INDEX idx_tasks_resource_id ON tasks(resource_id);
CREATE INDEX idx_tasks_is_focus ON tasks(is_focus);
CREATE INDEX idx_tasks_is_archived ON tasks(is_archived);

CREATE INDEX idx_blobs_area_id ON blobs(area_id);
CREATE INDEX idx_blobs_project_id ON blobs(project_id);
CREATE INDEX idx_blobs_is_archived ON blobs(is_archived);

-- Prompt logs indexes
CREATE INDEX idx_prompt_logs_template ON prompt_logs(prompt_template);
CREATE INDEX idx_prompt_logs_version ON prompt_logs(prompt_version);
CREATE INDEX idx_prompt_logs_created_at ON prompt_logs(created_at);
CREATE INDEX idx_prompt_logs_blob_id ON prompt_logs(blob_id);

-- Apply updated_at triggers to new tables
CREATE TRIGGER update_areas_updated_at BEFORE UPDATE ON areas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_resources_updated_at BEFORE UPDATE ON resources
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create view for archives (virtual table)
CREATE VIEW archives AS
SELECT 
    'blob' as content_type,
    id,
    content as title,
    source_type,
    work_personal,
    archived_at,
    area_id,
    project_id
FROM blobs 
WHERE is_archived = true

UNION ALL

SELECT 
    'task' as content_type,
    id,
    title,
    status::text as source_type,
    work_personal,
    archived_at,
    area_id,
    project_id
FROM tasks 
WHERE is_archived = true

UNION ALL

SELECT 
    'resource' as content_type,
    id,
    title,
    type as source_type,
    work_personal,
    archived_at,
    area_id,
    project_id
FROM resources 
WHERE is_archived = true;

-- Function to archive content by setting archived_at and is_archived
CREATE OR REPLACE FUNCTION archive_content(
    table_name TEXT,
    content_id UUID
) RETURNS VOID AS $$
BEGIN
    EXECUTE format('UPDATE %I SET is_archived = true, archived_at = NOW() WHERE id = $1', table_name)
    USING content_id;
END;
$$ LANGUAGE plpgsql;

-- Function to unarchive content
CREATE OR REPLACE FUNCTION unarchive_content(
    table_name TEXT,
    content_id UUID
) RETURNS VOID AS $$
BEGIN
    EXECUTE format('UPDATE %I SET is_archived = false, archived_at = NULL WHERE id = $1', table_name)
    USING content_id;
END;
$$ LANGUAGE plpgsql; 