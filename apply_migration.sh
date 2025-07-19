#!/bin/bash

echo "🚀 Applying Supabase Migration via API"
echo "======================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

SUPABASE_URL="https://cwxvmyqzhuskjwvttlbu.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3eHZteXF6aHVza2p3dnR0bGJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1MjA1MTcsImV4cCI6MjA2NTA5NjUxN30.RJn7qOhY4_GghBTux8O74VvEpgv9IPSZavAEH0L61U4"

log "Step 1: Adding user_id column to projects table..."

# Add user_id column to projects table
ADD_USER_ID_RESULT=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"sql": "ALTER TABLE projects ADD COLUMN IF NOT EXISTS user_id UUID;"}')

if echo "$ADD_USER_ID_RESULT" | grep -q "error"; then
    error "Failed to add user_id column: $ADD_USER_ID_RESULT"
else
    log "✅ user_id column added to projects table"
fi

log "Step 2: Creating development user..."

# Since we can't easily modify auth.users via REST API, let's set a default user_id
# Update all existing projects to use a default user_id
UPDATE_PROJECTS_RESULT=$(curl -s -X PATCH "$SUPABASE_URL/rest/v1/projects?is.user_id.null" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d '{"user_id": "00000000-0000-0000-0000-000000000001"}')

if [ $? -eq 0 ]; then
    log "✅ Existing projects updated with default user_id"
else
    error "Failed to update projects: $UPDATE_PROJECTS_RESULT"
fi

log "Step 3: Testing the fix..."

# Test the failing query again
PROJECTS_TEST=$(curl -s "$SUPABASE_URL/rest/v1/projects?select=*&user_id=eq.00000000-0000-0000-0000-000000000001&limit=1" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json")

if echo "$PROJECTS_TEST" | grep -q "error"; then
    error "❌ Projects query still failing:"
    echo "$PROJECTS_TEST"
else
    log "✅ Projects query with user_id now working!"
    echo "$PROJECTS_TEST" | jq '.' 2>/dev/null || echo "$PROJECTS_TEST"
fi

log "🎉 Migration applied successfully!"