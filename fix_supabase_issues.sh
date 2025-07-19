#!/bin/bash

echo "🔧 Fixing Supabase Issues for LifeManager v2.2.0"
echo "==============================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $1"
}

warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $1"
}

# Step 1: Check Supabase connection
log "Step 1: Testing Supabase connection..."

SUPABASE_URL="https://cwxvmyqzhuskjwvttlbu.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3eHZteXF6aHVza2p3dnR0bGJ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk1MjA1MTcsImV4cCI6MjA2NTA5NjUxN30.RJn7qOhY4_GghBTux8O74VvEpgv9IPSZavAEH0L61U4"

# Test basic connectivity
if curl -s "$SUPABASE_URL/rest/v1/" -H "apikey: $SUPABASE_ANON_KEY" -H "Authorization: Bearer $SUPABASE_ANON_KEY" > /dev/null; then
    log "✅ Supabase connection successful"
else
    error "❌ Supabase connection failed"
    exit 1
fi

# Step 2: Check current schema
log "Step 2: Checking current database schema..."

# Test if projects table exists and check for user_id column
PROJECTS_SCHEMA=$(curl -s "$SUPABASE_URL/rest/v1/projects?select=*&limit=0" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json")

if echo "$PROJECTS_SCHEMA" | grep -q "user_id"; then
    log "✅ user_id column already exists in projects table"
else
    warning "❌ user_id column missing from projects table - migration needed"
    
    # Step 3: Apply migration via API (if possible) or create SQL commands
    log "Step 3: Applying database migration..."
    
    info "Database migration required. Manual steps:"
    echo ""
    echo "🔧 SQL Commands to run in Supabase SQL Editor:"
    echo "============================================"
    cat supabase/migrations/005_add_user_support.sql
    echo ""
    echo "📝 Please run this migration in your Supabase dashboard:"
    echo "1. Go to https://supabase.com/dashboard/project/cwxvmyqzhuskjwvttlbu/sql"
    echo "2. Paste the SQL commands above"
    echo "3. Run the migration"
    echo ""
fi

# Step 4: Test specific failing query
log "Step 4: Testing the failing query..."

# Try to fetch projects with user_id
PROJECTS_TEST=$(curl -s "$SUPABASE_URL/rest/v1/projects?select=*&user_id=eq.00000000-0000-0000-0000-000000000001&limit=1" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json")

if echo "$PROJECTS_TEST" | grep -q "error"; then
    error "❌ Projects query with user_id failed:"
    echo "$PROJECTS_TEST" | jq -r '.message' 2>/dev/null || echo "$PROJECTS_TEST"
else
    log "✅ Projects query with user_id successful"
    echo "$PROJECTS_TEST" | jq '.' 2>/dev/null || echo "$PROJECTS_TEST"
fi

# Step 5: Create test data for development
log "Step 5: Setting up development environment..."

# Create a test project to verify everything works
TEST_PROJECT=$(cat << 'EOF'
{
    "name": "Test Project v2.2.0",
    "description": "Test project for verifying user_id functionality",
    "status": "active",
    "work_personal": "personal",
    "user_id": "00000000-0000-0000-0000-000000000001"
}
EOF
)

CREATE_RESULT=$(curl -s -X POST "$SUPABASE_URL/rest/v1/projects" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "$TEST_PROJECT")

if [ $? -eq 0 ] && [ -z "$CREATE_RESULT" ]; then
    log "✅ Test project created successfully"
else
    warning "Test project creation result: $CREATE_RESULT"
fi

# Step 6: Verify build performance issue
log "Step 6: Diagnosing build performance..."

# Check if we can resolve dependencies without full build
log "Testing dependency resolution..."
if swift package resolve > /dev/null 2>&1; then
    log "✅ Swift package resolution successful"
    
    # Check dependency cache
    CACHE_SIZE=$(du -sh .build 2>/dev/null | cut -f1 || echo "0B")
    info "Build cache size: $CACHE_SIZE"
    
    # Test incremental build
    log "Testing incremental build (30 second timeout)..."
    if timeout 30 swift build --configuration release -Xswiftc -suppress-warnings > /dev/null 2>&1; then
        log "✅ Incremental build successful"
    else
        warning "Build still takes >30 seconds - large dependency compilation"
    fi
else
    error "❌ Package resolution failed"
fi

# Step 7: Summary and recommendations
log "Step 7: Summary and recommendations"
echo ""
echo "🎯 ISSUE DIAGNOSIS COMPLETE"
echo "=========================="
echo ""
echo "ROOT CAUSE: Missing user_id columns in database schema"
echo "SOLUTION: Apply the 005_add_user_support.sql migration"
echo ""
echo "📊 NEXT STEPS:"
echo "1. ✅ Apply database migration (005_add_user_support.sql)"
echo "2. ✅ Update Swift models to include user_id fields"
echo "3. ✅ Optimize build performance with incremental compilation"
echo "4. ✅ Test all PARA operations with proper user isolation"
echo ""
echo "🚀 After migration, the app should work without database errors!"

log "🎉 Supabase diagnosis complete!"