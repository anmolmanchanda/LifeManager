-- Recently Deleted Tasks Migration
-- Add support for soft deletion with 24-hour recovery period

-- Add deleted_at column to tasks table
ALTER TABLE tasks ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;

-- Create index for deleted_at column
CREATE INDEX idx_tasks_deleted_at ON tasks(deleted_at);

-- Create function to automatically clean up permanently deleted tasks after 24 hours
CREATE OR REPLACE FUNCTION cleanup_permanently_deleted_tasks()
RETURNS void AS $$
BEGIN
    -- Delete tasks that have been in deleted state for more than 24 hours
    DELETE FROM tasks 
    WHERE deleted_at IS NOT NULL 
    AND deleted_at < NOW() - INTERVAL '24 hours';
    
    -- Log the cleanup action
    RAISE NOTICE 'Cleaned up permanently deleted tasks older than 24 hours';
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to run cleanup daily (this would need to be set up in Supabase dashboard)
-- Note: This is a comment because the actual scheduling would be done in Supabase dashboard
-- SELECT cron.schedule('cleanup-deleted-tasks', '0 2 * * *', 'SELECT cleanup_permanently_deleted_tasks();');

-- Function to soft delete a task (set deleted_at timestamp)
CREATE OR REPLACE FUNCTION soft_delete_task(task_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE tasks 
    SET deleted_at = NOW(), 
        updated_at = NOW()
    WHERE id = task_id;
END;
$$ LANGUAGE plpgsql;

-- Function to restore a soft deleted task
CREATE OR REPLACE FUNCTION restore_deleted_task(task_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE tasks 
    SET deleted_at = NULL, 
        updated_at = NOW()
    WHERE id = task_id;
END;
$$ LANGUAGE plpgsql;

-- Function to permanently delete a task immediately
CREATE OR REPLACE FUNCTION permanently_delete_task(task_id UUID)
RETURNS void AS $$
BEGIN
    DELETE FROM tasks WHERE id = task_id;
END;
$$ LANGUAGE plpgsql;
