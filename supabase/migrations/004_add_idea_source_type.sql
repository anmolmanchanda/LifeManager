-- Migration: Add 'idea' to source_type enum
-- Date: 2025-01-15
-- Description: Add 'idea' as a valid source_type value for brain dump processing

-- Add 'idea' to the source_type enum
ALTER TYPE source_type ADD VALUE 'idea';

-- Also add other missing values that are in Swift but not in DB
ALTER TYPE source_type ADD VALUE 'meeting';
ALTER TYPE source_type ADD VALUE 'research';
ALTER TYPE source_type ADD VALUE 'financial';
ALTER TYPE source_type ADD VALUE 'therapy';
ALTER TYPE source_type ADD VALUE 'media'; 