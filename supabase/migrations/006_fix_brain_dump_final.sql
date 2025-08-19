-- Final fix for brain dump tables - handles existing tasks table properly
-- August 2025

-- First, let's add user_id to tasks table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'tasks' AND column_name = 'user_id') THEN
        ALTER TABLE tasks ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        
        -- Update existing tasks to have the current user's ID if needed
        UPDATE tasks SET user_id = auth.uid() WHERE user_id IS NULL;
    END IF;
END
$$;

-- Now create the remaining tables (skip tasks since it exists)

-- 1. Health Logs Table
CREATE TABLE IF NOT EXISTS health_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    condition_name VARCHAR(255),
    symptoms TEXT[],
    severity INTEGER CHECK (severity >= 1 AND severity <= 10),
    medications TEXT[],
    dosage_info JSONB,
    body_parts TEXT[],
    triggers TEXT[],
    notes TEXT,
    appointment_id UUID,
    logged_at TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Medication Tracking Table
CREATE TABLE IF NOT EXISTS medication_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    medication_name VARCHAR(255) NOT NULL,
    dosage VARCHAR(100),
    frequency VARCHAR(100),
    time_of_day TIME[],
    start_date DATE,
    end_date DATE,
    prescribed_by VARCHAR(255),
    purpose TEXT,
    side_effects TEXT[],
    notes TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Personal Rules Table
CREATE TABLE IF NOT EXISTS personal_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    rule_text TEXT NOT NULL,
    rule_type VARCHAR(50),
    category VARCHAR(100),
    start_date DATE,
    end_date DATE,
    time_constraints JSONB,
    conditions JSONB,
    priority INTEGER DEFAULT 5,
    enforcement_level VARCHAR(20),
    violations_count INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Goals Table
CREATE TABLE IF NOT EXISTS goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    target_date DATE,
    start_date DATE DEFAULT CURRENT_DATE,
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    milestones JSONB,
    metrics JSONB,
    dependencies UUID[],
    parent_goal_id UUID REFERENCES goals(id),
    status VARCHAR(20) DEFAULT 'active',
    priority INTEGER DEFAULT 5,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. Schedules Table
CREATE TABLE IF NOT EXISTS schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    schedule_type VARCHAR(50),
    time_blocks JSONB,
    recurrence_pattern VARCHAR(100),
    active_days INTEGER[],
    exceptions JSONB,
    duration_minutes INTEGER,
    category VARCHAR(100),
    linked_goal_id UUID REFERENCES goals(id),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 6. Contacts Table
CREATE TABLE IF NOT EXISTS contacts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255),
    notes TEXT,
    tags TEXT[],
    last_contact DATE,
    reminder_frequency VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 7. Processed Notes Table with caching
CREATE TABLE IF NOT EXISTS processed_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    original_text TEXT NOT NULL,
    original_hash VARCHAR(64), -- For cache matching
    processed_at TIMESTAMP DEFAULT NOW(),
    items_extracted INTEGER,
    processing_model VARCHAR(50), -- 'gpt-5', 'o3', 'o4-mini-high'
    confidence_score FLOAT,
    categories_found TEXT[],
    entities_extracted JSONB,
    relationships JSONB,
    embeddings_json JSONB, -- Store as JSONB for now
    metadata JSONB,
    cache_expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '30 days',
    created_at TIMESTAMP DEFAULT NOW()
);

-- 8. Appointments Table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    appointment_type VARCHAR(100),
    provider_name VARCHAR(255),
    location TEXT,
    scheduled_date DATE,
    scheduled_time TIME,
    duration_minutes INTEGER,
    preparation_notes TEXT,
    questions_to_ask TEXT[],
    documents_needed TEXT[],
    follow_up_required BOOLEAN DEFAULT false,
    related_health_log_id UUID REFERENCES health_logs(id),
    status VARCHAR(20) DEFAULT 'scheduled',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 9. Documents Table
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    document_type VARCHAR(100),
    content TEXT,
    file_url TEXT,
    tags TEXT[],
    related_appointment_id UUID REFERENCES appointments(id),
    related_health_log_id UUID REFERENCES health_logs(id),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 10. Time Blocks Table
CREATE TABLE IF NOT EXISTS time_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    block_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    activity VARCHAR(255),
    category VARCHAR(100),
    planned BOOLEAN DEFAULT false,
    productivity_score INTEGER CHECK (productivity_score >= 1 AND productivity_score <= 10),
    notes TEXT,
    linked_task_id UUID REFERENCES tasks(id),
    linked_schedule_id UUID REFERENCES schedules(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- 11. Cache Table for AI Processing
CREATE TABLE IF NOT EXISTS ai_processing_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    input_hash VARCHAR(64) NOT NULL,
    input_preview TEXT, -- First 200 chars for debugging
    model_used VARCHAR(50),
    processing_result JSONB,
    tokens_used INTEGER,
    cost_usd DECIMAL(10, 6),
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT NOW() + INTERVAL '30 days',
    UNIQUE(user_id, input_hash)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_health_logs_user_date ON health_logs(user_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_medication_tracking_active ON medication_tracking(user_id, active);
CREATE INDEX IF NOT EXISTS idx_personal_rules_active ON personal_rules(user_id, active);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(user_id, status);
CREATE INDEX IF NOT EXISTS idx_schedules_active ON schedules(user_id, active);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(user_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_processed_notes_hash ON processed_notes(user_id, original_hash);
CREATE INDEX IF NOT EXISTS idx_cache_hash ON ai_processing_cache(user_id, input_hash);
CREATE INDEX IF NOT EXISTS idx_cache_expires ON ai_processing_cache(expires_at);

-- Enable RLS on all tables
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE medication_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE personal_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE processed_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE time_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_processing_cache ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (checking if user_id column exists first)
DO $$
BEGIN
    -- Only create policy if user_id column exists in tasks
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'tasks' AND column_name = 'user_id') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tasks' AND policyname = 'Users can manage own tasks') THEN
            CREATE POLICY "Users can manage own tasks" ON tasks FOR ALL USING (auth.uid() = user_id);
        END IF;
    END IF;
END
$$;

-- Create policies for other tables (these definitely have user_id)
CREATE POLICY IF NOT EXISTS "Users can manage own health logs" ON health_logs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own medication tracking" ON medication_tracking FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own personal rules" ON personal_rules FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own goals" ON goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own schedules" ON schedules FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own contacts" ON contacts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own processed notes" ON processed_notes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own appointments" ON appointments FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own documents" ON documents FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own time blocks" ON time_blocks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY IF NOT EXISTS "Users can manage own cache" ON ai_processing_cache FOR ALL USING (auth.uid() = user_id);

-- Success
DO $$
BEGIN
    RAISE NOTICE 'Brain dump tables created successfully with caching support!';
END
$$;