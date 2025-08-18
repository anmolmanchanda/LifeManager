-- Migration: Advanced Brain Dump Tables for Complex Note Processing
-- Created: August 2025
-- Purpose: Support comprehensive parsing of complex notes including health, schedules, goals, and rules

-- 1. Health Logs Table
CREATE TABLE IF NOT EXISTS health_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
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
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
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
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    rule_text TEXT NOT NULL,
    rule_type VARCHAR(50), -- 'restriction', 'habit', 'boundary', 'commitment'
    category VARCHAR(100),
    start_date DATE,
    end_date DATE,
    time_constraints JSONB, -- {"days": ["Mon", "Fri"], "hours": "8-17"}
    conditions JSONB, -- {"if": "condition", "then": "action"}
    priority INTEGER DEFAULT 5,
    enforcement_level VARCHAR(20), -- 'strict', 'flexible', 'optional'
    violations_count INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 4. Goals Table with Progress Tracking
CREATE TABLE IF NOT EXISTS goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100), -- 'career', 'health', 'financial', 'personal', 'education'
    target_date DATE,
    start_date DATE DEFAULT CURRENT_DATE,
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    milestones JSONB, -- [{"title": "milestone", "date": "2025-09-01", "completed": false}]
    metrics JSONB, -- {"target": 100, "current": 45, "unit": "hours"}
    dependencies UUID[], -- Array of other goal IDs
    parent_goal_id UUID REFERENCES goals(id),
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'paused', 'completed', 'abandoned'
    priority INTEGER DEFAULT 5,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 5. Schedules and Routines Table
CREATE TABLE IF NOT EXISTS schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    schedule_type VARCHAR(50), -- 'daily', 'weekly', 'monthly', 'custom'
    time_blocks JSONB, -- [{"start": "09:00", "end": "10:00", "activity": "French study"}]
    recurrence_pattern VARCHAR(100), -- 'every day', 'weekdays', 'weekends', 'MWF'
    active_days INTEGER[], -- [1,2,3,4,5] for Mon-Fri
    exceptions JSONB, -- {"dates": ["2025-09-01"], "reason": "holiday"}
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
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    relationship VARCHAR(100), -- 'family', 'friend', 'doctor', 'colleague'
    phone VARCHAR(50),
    email VARCHAR(255),
    notes TEXT,
    tags TEXT[],
    last_contact DATE,
    reminder_frequency VARCHAR(50), -- 'weekly', 'monthly', 'quarterly'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 7. Complex Notes Processing Table
CREATE TABLE IF NOT EXISTS processed_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    original_text TEXT NOT NULL,
    processed_at TIMESTAMP DEFAULT NOW(),
    items_extracted INTEGER,
    processing_model VARCHAR(50), -- 'gpt-4', 'o1', 'o3-mini'
    confidence_score FLOAT,
    categories_found TEXT[],
    entities_extracted JSONB, -- Named entities, dates, numbers
    relationships JSONB, -- Links between extracted items
    embeddings vector(1536), -- OpenAI embeddings
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- 8. Appointments and Events Table (enhanced)
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    appointment_type VARCHAR(100), -- 'medical', 'personal', 'work', 'social'
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
    status VARCHAR(20) DEFAULT 'scheduled', -- 'scheduled', 'completed', 'cancelled', 'rescheduled'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 9. Document and Reference Storage
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255),
    document_type VARCHAR(100), -- 'medical_report', 'prescription', 'test_result', 'reference'
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
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    block_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    activity VARCHAR(255),
    category VARCHAR(100),
    planned BOOLEAN DEFAULT false, -- Was this planned or actual
    productivity_score INTEGER CHECK (productivity_score >= 1 AND productivity_score <= 10),
    notes TEXT,
    linked_task_id UUID REFERENCES tasks(id),
    linked_schedule_id UUID REFERENCES schedules(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_health_logs_user_date ON health_logs(user_id, logged_at DESC);
CREATE INDEX idx_medication_tracking_active ON medication_tracking(user_id, active);
CREATE INDEX idx_personal_rules_active ON personal_rules(user_id, active);
CREATE INDEX idx_goals_status ON goals(user_id, status);
CREATE INDEX idx_schedules_active ON schedules(user_id, active);
CREATE INDEX idx_appointments_date ON appointments(user_id, scheduled_date);
CREATE INDEX idx_processed_notes_embeddings ON processed_notes USING ivfflat (embeddings vector_cosine_ops);

-- Enable Row Level Security
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

-- RLS Policies (users can only see their own data)
CREATE POLICY "Users can view own health logs" ON health_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own health logs" ON health_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own health logs" ON health_logs FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own health logs" ON health_logs FOR DELETE USING (auth.uid() = user_id);

-- Repeat similar policies for all tables
CREATE POLICY "Users can manage own medication tracking" ON medication_tracking FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own personal rules" ON personal_rules FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own goals" ON goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own schedules" ON schedules FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own contacts" ON contacts FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own processed notes" ON processed_notes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own appointments" ON appointments FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own documents" ON documents FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own time blocks" ON time_blocks FOR ALL USING (auth.uid() = user_id);