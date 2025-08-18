-- Task Dependencies Table
-- Priority 4: Task Dependency Management
-- Comprehensive task dependency system with intelligent scheduling consideration

CREATE TABLE IF NOT EXISTS task_dependencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dependent_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    depends_on_task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    dependency_type VARCHAR(50) NOT NULL DEFAULT 'finish_to_start',
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure no duplicate dependencies
    UNIQUE(dependent_task_id, depends_on_task_id),
    
    -- Prevent self-dependencies
    CHECK(dependent_task_id != depends_on_task_id)
);

-- Add indexes for performance
CREATE INDEX idx_task_dependencies_dependent ON task_dependencies(dependent_task_id);
CREATE INDEX idx_task_dependencies_depends_on ON task_dependencies(depends_on_task_id);
CREATE INDEX idx_task_dependencies_completed ON task_dependencies(is_completed);

-- Add RLS policies
ALTER TABLE task_dependencies ENABLE ROW LEVEL SECURITY;

-- Policy for reading dependencies (users can see dependencies for their tasks)
CREATE POLICY "Users can view task dependencies for their tasks" ON task_dependencies
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM tasks 
            WHERE tasks.id = task_dependencies.dependent_task_id 
            AND tasks.user_id = auth.uid()
        )
        OR
        EXISTS (
            SELECT 1 FROM tasks 
            WHERE tasks.id = task_dependencies.depends_on_task_id 
            AND tasks.user_id = auth.uid()
        )
    );

-- Policy for creating dependencies (users can create dependencies for their tasks)
CREATE POLICY "Users can create task dependencies for their tasks" ON task_dependencies
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM tasks 
            WHERE tasks.id = dependent_task_id 
            AND tasks.user_id = auth.uid()
        )
        AND
        EXISTS (
            SELECT 1 FROM tasks 
            WHERE tasks.id = depends_on_task_id 
            AND tasks.user_id = auth.uid()
        )
    );

-- Policy for updating dependencies (users can update dependencies for their tasks)
CREATE POLICY "Users can update task dependencies for their tasks" ON task_dependencies
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM tasks 
            WHERE tasks.id = task_dependencies.dependent_task_id 
            AND tasks.user_id = auth.uid()
        )
    );

-- Policy for deleting dependencies (users can delete dependencies for their tasks)
CREATE POLICY "Users can delete task dependencies for their tasks" ON task_dependencies
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM tasks 
            WHERE tasks.id = task_dependencies.dependent_task_id 
            AND tasks.user_id = auth.uid()
        )
    );

-- Function to automatically update is_completed when depends_on task is completed
CREATE OR REPLACE FUNCTION update_dependency_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- When a task is marked as completed, update all dependencies
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE task_dependencies
        SET is_completed = TRUE,
            updated_at = NOW()
        WHERE depends_on_task_id = NEW.id;
    END IF;
    
    -- When a task is uncompleted, update dependencies
    IF NEW.status != 'completed' AND OLD.status = 'completed' THEN
        UPDATE task_dependencies
        SET is_completed = FALSE,
            updated_at = NOW()
        WHERE depends_on_task_id = NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic dependency completion updates
CREATE TRIGGER update_dependency_completion_trigger
    AFTER UPDATE OF status ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_dependency_completion();

-- Function to check for circular dependencies
CREATE OR REPLACE FUNCTION check_circular_dependency(
    p_dependent_task_id UUID,
    p_depends_on_task_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    has_cycle BOOLEAN;
BEGIN
    -- Use recursive CTE to check for cycles
    WITH RECURSIVE dependency_chain AS (
        -- Start with the proposed dependency
        SELECT depends_on_task_id, dependent_task_id
        FROM (VALUES (p_depends_on_task_id, p_dependent_task_id)) AS proposed(depends_on_task_id, dependent_task_id)
        
        UNION
        
        -- Follow existing dependencies
        SELECT td.depends_on_task_id, td.dependent_task_id
        FROM task_dependencies td
        INNER JOIN dependency_chain dc ON td.dependent_task_id = dc.depends_on_task_id
    )
    SELECT EXISTS (
        SELECT 1 
        FROM dependency_chain 
        WHERE depends_on_task_id = p_dependent_task_id
    ) INTO has_cycle;
    
    RETURN has_cycle;
END;
$$ LANGUAGE plpgsql;

-- Trigger to prevent circular dependencies
CREATE OR REPLACE FUNCTION prevent_circular_dependencies()
RETURNS TRIGGER AS $$
BEGIN
    IF check_circular_dependency(NEW.dependent_task_id, NEW.depends_on_task_id) THEN
        RAISE EXCEPTION 'Circular dependency detected';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prevent_circular_dependencies_trigger
    BEFORE INSERT OR UPDATE ON task_dependencies
    FOR EACH ROW
    EXECUTE FUNCTION prevent_circular_dependencies();

-- Add updated_at trigger
CREATE TRIGGER update_task_dependencies_updated_at
    BEFORE UPDATE ON task_dependencies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();