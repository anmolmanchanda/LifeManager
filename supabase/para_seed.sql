-- PARA Framework Seed Data

-- Insert default Areas (ongoing responsibilities/spheres of activity)
INSERT INTO areas (name, description, icon, color, work_personal) VALUES
    ('Health & Fitness', 'Physical and mental health, exercise, nutrition, medical care', 'heart.fill', '#10B981', 'personal'),
    ('Career & Professional', 'Job responsibilities, career development, professional skills', 'briefcase.fill', '#3B82F6', 'work'),
    ('Finances & Investments', 'Financial planning, budgeting, investments, expenses', 'dollarsign.circle.fill', '#84CC16', 'both'),
    ('Learning & Education', 'Continuous learning, courses, reading, skill development', 'book.fill', '#06B6D4', 'both'),
    ('Relationships & Family', 'Family time, friendships, social connections', 'person.2.fill', '#EC4899', 'personal'),
    ('Home & Living', 'Household management, maintenance, organization', 'house.fill', '#F59E0B', 'personal'),
    ('Hobbies & Recreation', 'Entertainment, creative pursuits, leisure activities', 'gamecontroller.fill', '#6366F1', 'personal'),
    ('Travel & Experiences', 'Travel planning, experiences, adventures', 'airplane', '#8B5CF6', 'personal'),
    ('Technology & Tools', 'Tech setup, software, productivity tools', 'desktopcomputer', '#64748B', 'both'),
    ('Personal Development', 'Self-improvement, therapy, mindfulness, goal setting', 'person.crop.circle.badge.plus', '#F97316', 'personal');

-- Update existing projects to link to areas (examples)
-- Note: In practice, these would be set based on user's actual projects
UPDATE projects SET area_id = (SELECT id FROM areas WHERE name = 'Personal Development' LIMIT 1) 
WHERE name = 'Life Organization';

UPDATE projects SET area_id = (SELECT id FROM areas WHERE name = 'Health & Fitness' LIMIT 1) 
WHERE name = 'Health & Wellness';

UPDATE projects SET area_id = (SELECT id FROM areas WHERE name = 'Learning & Education' LIMIT 1) 
WHERE name = 'Learning Goals';

-- Insert sample resources to demonstrate the PARA structure
INSERT INTO resources (blob_id, title, type, summary, source_url, area_id, work_personal) 
SELECT 
    b.id,
    'Getting Things Done - David Allen',
    'book',
    'Comprehensive productivity methodology and system for managing tasks and projects',
    'https://www.amazon.com/Getting-Things-Done-Stress-Free-Productivity/dp/0143126563',
    a.id,
    'both'
FROM blobs b, areas a 
WHERE a.name = 'Personal Development' 
AND b.source_type = 'knowledge' 
LIMIT 1;

-- Add common resource types for better organization
-- This helps users understand what kind of resources they can track
INSERT INTO categories (name, description) VALUES
    ('Research Paper', 'Academic papers, studies, and research documents'),
    ('Article', 'Blog posts, news articles, and online content'),
    ('Video', 'Educational videos, tutorials, and recorded content'),
    ('Book', 'Books, eBooks, and written publications'),
    ('Guide', 'How-to guides, manuals, and instructional content'),
    ('Template', 'Reusable templates and frameworks'),
    ('Tool', 'Software tools, apps, and digital resources'),
    ('Reference', 'Quick reference materials and cheat sheets');

-- Update existing tags with better PARA-friendly categorization
INSERT INTO tags (name, color) VALUES
    ('para-project', '#3B82F6'),     -- Blue for project-related items
    ('para-area', '#10B981'),        -- Green for area-related items  
    ('para-resource', '#F59E0B'),    -- Amber for resources
    ('para-archive', '#6B7280'),     -- Gray for archived items
    ('actionable', '#EF4444'),       -- Red for actionable items
    ('reference', '#8B5CF6'),        -- Purple for reference materials
    ('someday-maybe', '#64748B'),    -- Slate for someday/maybe items
    ('waiting-for', '#F97316'),      -- Orange for items waiting on others
    ('review', '#06B6D4'),           -- Cyan for items needing review
    ('template', '#84CC16');         -- Lime for templates and reusable items

-- Create some example prompt templates for LLM operations
-- These demonstrate how to version and track AI prompts
INSERT INTO prompt_logs (prompt_template, prompt_version, input_data, prompt_text, response_text, model_name, tokens_used, processing_time_ms, confidence_score) VALUES
    (
        'categorize_blob',
        'v1.0',
        '{"content": "Need to prepare for quarterly review meeting", "source_type": "note"}',
        'Analyze this content and categorize it according to PARA methodology. Content: "Need to prepare for quarterly review meeting". Determine if this is a Project, Area, Resource, or should be Archived. Also suggest appropriate tags.',
        '{"category": "project", "area": "Career & Professional", "tags": ["work", "meeting", "review"], "reasoning": "This is a specific time-bound task that requires preparation"}',
        'claude-3-sonnet',
        150,
        450,
        0.92
    ),
    (
        'extract_tasks',
        'v1.0',
        '{"content": "I need to book a dentist appointment, update my resume, and review the Q3 budget", "source_type": "note"}',
        'Extract actionable tasks from this content: "I need to book a dentist appointment, update my resume, and review the Q3 budget". Return as structured JSON with title, priority, area, and due date if mentioned.',
        '[{"title": "Book dentist appointment", "priority": "medium", "area": "Health & Fitness"}, {"title": "Update resume", "priority": "low", "area": "Career & Professional"}, {"title": "Review Q3 budget", "priority": "high", "area": "Finances & Investments"}]',
        'claude-3-sonnet',
        200,
        380,
        0.88
    );

-- Create example of archived content
-- This shows how the archiving system works
UPDATE tasks SET is_archived = true, archived_at = NOW() - INTERVAL '30 days'
WHERE status = 'completed' AND updated_at < NOW() - INTERVAL '60 days'
LIMIT 2; 