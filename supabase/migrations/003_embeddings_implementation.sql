-- Embeddings Implementation Migration
-- Adds vector embeddings support for semantic PARA matching

-- Enable vector extension for PostgreSQL
CREATE EXTENSION IF NOT EXISTS vector;

-- Create embeddings cache table for OpenAI embeddings
CREATE TABLE embeddings_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cache_key TEXT NOT NULL UNIQUE,
    embedding vector(1536), -- OpenAI text-embedding-3-small dimensions
    text TEXT NOT NULL,
    model_name VARCHAR(50) DEFAULT 'text-embedding-3-small',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add embedding columns to PARA tables
ALTER TABLE projects ADD COLUMN embedding vector(1536);
ALTER TABLE areas ADD COLUMN embedding vector(1536);
ALTER TABLE resources ADD COLUMN embedding vector(1536);
ALTER TABLE blobs ADD COLUMN embedding vector(1536);

-- Create indexes for vector similarity search
CREATE INDEX idx_embeddings_cache_embedding ON embeddings_cache USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX idx_projects_embedding ON projects USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX idx_areas_embedding ON areas USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX idx_resources_embedding ON resources USING ivfflat (embedding vector_cosine_ops);
CREATE INDEX idx_blobs_embedding ON blobs USING ivfflat (embedding vector_cosine_ops);

-- Create function to calculate cosine similarity
CREATE OR REPLACE FUNCTION cosine_similarity(a vector, b vector)
RETURNS float AS $$
BEGIN
    RETURN 1 - (a <=> b);
END;
$$ LANGUAGE plpgsql;

-- Create function to find similar PARA items
CREATE OR REPLACE FUNCTION find_similar_para_items(
    query_embedding vector(1536),
    similarity_threshold float DEFAULT 0.7,
    result_limit int DEFAULT 10
)
RETURNS TABLE (
    item_type text,
    item_id uuid,
    title text,
    similarity float
) AS $$
BEGIN
    RETURN QUERY
    (
        SELECT 'project'::text, p.id, p.name, cosine_similarity(query_embedding, p.embedding)
        FROM projects p
        WHERE p.embedding IS NOT NULL
        AND cosine_similarity(query_embedding, p.embedding) >= similarity_threshold
    )
    UNION ALL
    (
        SELECT 'area'::text, a.id, a.name, cosine_similarity(query_embedding, a.embedding)
        FROM areas a
        WHERE a.embedding IS NOT NULL
        AND cosine_similarity(query_embedding, a.embedding) >= similarity_threshold
    )
    UNION ALL
    (
        SELECT 'resource'::text, r.id, r.title, cosine_similarity(query_embedding, r.embedding)
        FROM resources r
        WHERE r.embedding IS NOT NULL
        AND cosine_similarity(query_embedding, r.embedding) >= similarity_threshold
    )
    ORDER BY similarity DESC
    LIMIT result_limit;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update embeddings_cache updated_at
CREATE OR REPLACE FUNCTION update_embeddings_cache_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_embeddings_cache_updated_at
    BEFORE UPDATE ON embeddings_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_embeddings_cache_updated_at();

-- Create indexes for cache performance
CREATE INDEX idx_embeddings_cache_key ON embeddings_cache(cache_key);
CREATE INDEX idx_embeddings_cache_created_at ON embeddings_cache(created_at);
CREATE INDEX idx_embeddings_cache_model ON embeddings_cache(model_name);

-- Add comments for documentation
COMMENT ON TABLE embeddings_cache IS 'Cache for OpenAI embeddings to reduce API calls and improve performance';
COMMENT ON COLUMN embeddings_cache.embedding IS 'Vector embedding from OpenAI text-embedding-3-small (1536 dimensions)';
COMMENT ON COLUMN projects.embedding IS 'Semantic embedding for project name and description';
COMMENT ON COLUMN areas.embedding IS 'Semantic embedding for area name and description';
COMMENT ON COLUMN resources.embedding IS 'Semantic embedding for resource title and summary';
COMMENT ON COLUMN blobs.embedding IS 'Semantic embedding for blob content'; 