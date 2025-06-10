-- Seed data for LifeManager

-- Insert initial categories
INSERT INTO categories (name, description) VALUES
    ('Journal', 'Personal thoughts, daily logs, reflections and diary entries'),
    ('Therapy', 'Mental health notes, therapeutic insights and therapy session records'),
    ('Task', 'Action items, to-dos, project work and task management'),
    ('Finance', 'Money-related content, transactions, budgets and financial planning'),
    ('Knowledge', 'Learning notes, research, factual information and knowledge base'),
    ('Recipe', 'Cooking recipes, meal plans and culinary information'),
    ('Diet', 'Diet plans, nutrition tracking and dietary information'),
    ('Inventory', 'Item tracking, stock management and inventory organization'),
    ('Show', 'TV shows, movies, entertainment tracking and reviews'),
    ('YouTube', 'YouTube videos, playlists and online content tracking'),
    ('Grocery', 'Shopping lists, grocery planning and food purchasing');

-- Insert some common initial tags
INSERT INTO tags (name, color) VALUES
    ('urgent', '#EF4444'),      -- Red for urgent items
    ('important', '#F97316'),   -- Orange for important items
    ('work', '#3B82F6'),        -- Blue for work-related items
    ('personal', '#10B981'),    -- Green for personal items
    ('health', '#8B5CF6'),      -- Purple for health-related items
    ('family', '#EC4899'),      -- Pink for family-related items
    ('learning', '#06B6D4'),    -- Cyan for learning/education
    ('finance', '#84CC16'),     -- Lime for financial items
    ('home', '#F59E0B'),        -- Amber for home-related items
    ('hobby', '#6366F1');       -- Indigo for hobby/leisure items

-- Insert a sample project
INSERT INTO projects (name, description, status, work_personal) VALUES
    ('Life Organization', 'General life management and organization tasks', 'active', 'personal'),
    ('Health & Wellness', 'Health tracking, fitness goals, and wellness activities', 'active', 'personal'),
    ('Learning Goals', 'Educational pursuits and skill development', 'active', 'both');

-- Note: Additional seed data can be added here as needed
-- This provides a foundational set of categories, tags, and projects for users to start with 