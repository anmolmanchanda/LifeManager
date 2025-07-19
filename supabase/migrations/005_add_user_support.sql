-- Add User Support Migration
-- This migration adds user_id columns to support multi-tenant architecture

-- Enable Row Level Security and add user_id columns to all major tables

-- Add user_id to core PARA tables
ALTER TABLE projects ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE areas ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE resources ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE blobs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add user_id to content tables
ALTER TABLE journal_entries ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE therapy_sessions ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE financial_entries ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE knowledge_entries ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE recipes ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE diets ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE inventories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE shows ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE youtube_entries ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE grocery_lists ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add user_id to relationship and metadata tables
ALTER TABLE categories ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE tags ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE prompt_logs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Add user_id to new v2.0 tables if they exist
ALTER TABLE task_dependencies ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- Create indexes for user_id columns for performance
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_areas_user_id ON areas(user_id);
CREATE INDEX IF NOT EXISTS idx_resources_user_id ON resources(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_blobs_user_id ON blobs(user_id);
CREATE INDEX IF NOT EXISTS idx_journal_entries_user_id ON journal_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_therapy_sessions_user_id ON therapy_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_entries_user_id ON financial_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_knowledge_entries_user_id ON knowledge_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_recipes_user_id ON recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_diets_user_id ON diets(user_id);
CREATE INDEX IF NOT EXISTS idx_inventories_user_id ON inventories(user_id);
CREATE INDEX IF NOT EXISTS idx_shows_user_id ON shows(user_id);
CREATE INDEX IF NOT EXISTS idx_youtube_entries_user_id ON youtube_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_grocery_lists_user_id ON grocery_lists(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_user_id ON tags(user_id);
CREATE INDEX IF NOT EXISTS idx_prompt_logs_user_id ON prompt_logs(user_id);

-- Enable Row Level Security on all tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE blobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE therapy_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE diets ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventories ENABLE ROW LEVEL SECURITY;
ALTER TABLE shows ENABLE ROW LEVEL SECURITY;
ALTER TABLE youtube_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE grocery_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompt_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for user data isolation
-- Projects policies
CREATE POLICY "Users can only access their own projects" ON projects
    FOR ALL USING (auth.uid() = user_id);

-- Areas policies
CREATE POLICY "Users can only access their own areas" ON areas
    FOR ALL USING (auth.uid() = user_id);

-- Resources policies
CREATE POLICY "Users can only access their own resources" ON resources
    FOR ALL USING (auth.uid() = user_id);

-- Tasks policies
CREATE POLICY "Users can only access their own tasks" ON tasks
    FOR ALL USING (auth.uid() = user_id);

-- Blobs policies
CREATE POLICY "Users can only access their own blobs" ON blobs
    FOR ALL USING (auth.uid() = user_id);

-- Journal entries policies
CREATE POLICY "Users can only access their own journal entries" ON journal_entries
    FOR ALL USING (auth.uid() = user_id);

-- Therapy sessions policies
CREATE POLICY "Users can only access their own therapy sessions" ON therapy_sessions
    FOR ALL USING (auth.uid() = user_id);

-- Financial entries policies
CREATE POLICY "Users can only access their own financial entries" ON financial_entries
    FOR ALL USING (auth.uid() = user_id);

-- Knowledge entries policies
CREATE POLICY "Users can only access their own knowledge entries" ON knowledge_entries
    FOR ALL USING (auth.uid() = user_id);

-- Recipes policies
CREATE POLICY "Users can only access their own recipes" ON recipes
    FOR ALL USING (auth.uid() = user_id);

-- Diets policies
CREATE POLICY "Users can only access their own diets" ON diets
    FOR ALL USING (auth.uid() = user_id);

-- Inventories policies
CREATE POLICY "Users can only access their own inventories" ON inventories
    FOR ALL USING (auth.uid() = user_id);

-- Shows policies
CREATE POLICY "Users can only access their own shows" ON shows
    FOR ALL USING (auth.uid() = user_id);

-- YouTube entries policies
CREATE POLICY "Users can only access their own youtube entries" ON youtube_entries
    FOR ALL USING (auth.uid() = user_id);

-- Grocery lists policies
CREATE POLICY "Users can only access their own grocery lists" ON grocery_lists
    FOR ALL USING (auth.uid() = user_id);

-- Categories policies
CREATE POLICY "Users can only access their own categories" ON categories
    FOR ALL USING (auth.uid() = user_id);

-- Tags policies
CREATE POLICY "Users can only access their own tags" ON tags
    FOR ALL USING (auth.uid() = user_id);

-- Prompt logs policies
CREATE POLICY "Users can only access their own prompt logs" ON prompt_logs
    FOR ALL USING (auth.uid() = user_id);

-- Create a development user for testing
-- This ensures we have a consistent user_id for development
INSERT INTO auth.users (id, email, encrypted_password, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'dev@lifemanager.local',
    crypt('dev_password', gen_salt('bf')),
    NOW(),
    NOW()
) ON CONFLICT (id) DO NOTHING;

-- Update existing data to use the development user
-- This ensures backward compatibility with existing data
UPDATE projects SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE areas SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE resources SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE tasks SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE blobs SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE journal_entries SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE therapy_sessions SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE financial_entries SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE knowledge_entries SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE recipes SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE diets SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE inventories SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE shows SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE youtube_entries SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE grocery_lists SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE categories SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE tags SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;
UPDATE prompt_logs SET user_id = '00000000-0000-0000-0000-000000000001'::uuid WHERE user_id IS NULL;