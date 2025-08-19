-- Migration: Advanced Brain Dump Tables for Complex Note Processing
-- Fixed version: Uses auth.users and handles tasks table reference
-- Created: August 2025

-- First check if tasks table exists, if not create a basic one
CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

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

-- 4. Goals Table with Progress Tracking
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

-- 5. Schedules and Routines Table
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

-- 6. Contacts and Relationships Table
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

-- 7. Complex Notes Processing Table (without vector if extension not available)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        CREATE TABLE IF NOT EXISTS processed_notes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            original_text TEXT NOT NULL,
            processed_at TIMESTAMP DEFAULT NOW(),
            items_extracted INTEGER,
            processing_model VARCHAR(50),
            confidence_score FLOAT,
            categories_found TEXT[],
            entities_extracted JSONB,
            relationships JSONB,
            embeddings vector(1536),
            metadata JSONB,
            created_at TIMESTAMP DEFAULT NOW()
        );
        
        -- Create index only if vector extension exists
        CREATE INDEX IF NOT EXISTS idx_processed_notes_embeddings 
        ON processed_notes USING ivfflat (embeddings vector_cosine_ops);
    ELSE
        CREATE TABLE IF NOT EXISTS processed_notes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
            original_text TEXT NOT NULL,
            processed_at TIMESTAMP DEFAULT NOW(),
            items_extracted INTEGER,
            processing_model VARCHAR(50),
            confidence_score FLOAT,
            categories_found TEXT[],
            entities_extracted JSONB,
            relationships JSONB,
            embeddings_json JSONB, -- Store as JSONB if vector not available
            metadata JSONB,
            created_at TIMESTAMP DEFAULT NOW()
        );
    END IF;
END
$$;

-- 8. Appointments and Events Table
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

-- 9. Document and Reference Storage
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

-- 10. Time Tracking Enhancement
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
    linked_task_id UUID REFERENCES tasks(id), -- Now tasks table exists
    linked_schedule_id UUID REFERENCES schedules(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_health_logs_user_date ON health_logs(user_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_medication_tracking_active ON medication_tracking(user_id, active);
CREATE INDEX IF NOT EXISTS idx_personal_rules_active ON personal_rules(user_id, active);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(user_id, status);
CREATE INDEX IF NOT EXISTS idx_schedules_active ON schedules(user_id, active);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(user_id, scheduled_date);

-- Enable Row Level Security
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

-- RLS Policies (using IF NOT EXISTS to avoid duplicates)
DO $$
BEGIN
    -- Tasks policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tasks' AND policyname = 'Users can manage own tasks') THEN
        CREATE POLICY "Users can manage own tasks" ON tasks FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Health logs policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'health_logs' AND policyname = 'Users can manage own health logs') THEN
        CREATE POLICY "Users can manage own health logs" ON health_logs FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Medication tracking policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'medication_tracking' AND policyname = 'Users can manage own medication tracking') THEN
        CREATE POLICY "Users can manage own medication tracking" ON medication_tracking FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Personal rules policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'personal_rules' AND policyname = 'Users can manage own personal rules') THEN
        CREATE POLICY "Users can manage own personal rules" ON personal_rules FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Goals policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'goals' AND policyname = 'Users can manage own goals') THEN
        CREATE POLICY "Users can manage own goals" ON goals FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Schedules policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'schedules' AND policyname = 'Users can manage own schedules') THEN
        CREATE POLICY "Users can manage own schedules" ON schedules FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Contacts policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'contacts' AND policyname = 'Users can manage own contacts') THEN
        CREATE POLICY "Users can manage own contacts" ON contacts FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Processed notes policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'processed_notes' AND policyname = 'Users can manage own processed notes') THEN
        CREATE POLICY "Users can manage own processed notes" ON processed_notes FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Appointments policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'appointments' AND policyname = 'Users can manage own appointments') THEN
        CREATE POLICY "Users can manage own appointments" ON appointments FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Documents policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'documents' AND policyname = 'Users can manage own documents') THEN
        CREATE POLICY "Users can manage own documents" ON documents FOR ALL USING (auth.uid() = user_id);
    END IF;
    
    -- Time blocks policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'time_blocks' AND policyname = 'Users can manage own time blocks') THEN
        CREATE POLICY "Users can manage own time blocks" ON time_blocks FOR ALL USING (auth.uid() = user_id);
    END IF;
END
$$;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Brain dump tables created successfully!';
    RAISE NOTICE 'Tables created: tasks, health_logs, medication_tracking, personal_rules, goals, schedules, contacts, processed_notes, appointments, documents, time_blocks';
END
$$;