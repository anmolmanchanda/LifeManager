#!/bin/bash

echo "========================================="
echo "  Apply Enhanced Brain Dump Migration"
echo "========================================="
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Step 1: Check Migration File${NC}"
echo "----------------------------------------"

if [ -f "supabase/migrations/005_advanced_brain_dump_tables.sql" ]; then
    echo -e "${GREEN}✅${NC} Migration file found"
    echo ""
    echo "This migration will create 10 new tables:"
    echo "  1. health_logs - Medical conditions and symptoms"
    echo "  2. medication_tracking - Medication schedules"
    echo "  3. personal_rules - Rules and restrictions"
    echo "  4. goals - Goals with progress tracking"
    echo "  5. schedules - Daily/weekly routines"
    echo "  6. contacts - Relationships and contacts"
    echo "  7. processed_notes - Processing history"
    echo "  8. appointments - Medical and personal appointments"
    echo "  9. documents - Reference documents"
    echo " 10. time_blocks - Time tracking enhancement"
else
    echo -e "${RED}❌${NC} Migration file not found"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Apply Migration${NC}"
echo "----------------------------------------"
echo ""
echo "To apply this migration to your Supabase database:"
echo ""
echo "Option 1: Using Supabase CLI (recommended)"
echo -e "${YELLOW}supabase db push${NC}"
echo ""
echo "Option 2: Direct PostgreSQL connection"
echo -e "${YELLOW}psql -h db.<project-ref>.supabase.co -p 5432 -d postgres -U postgres < supabase/migrations/005_advanced_brain_dump_tables.sql${NC}"
echo ""
echo "Option 3: Supabase Dashboard"
echo "  1. Go to https://app.supabase.com/project/<your-project>/sql"
echo "  2. Copy the contents of 005_advanced_brain_dump_tables.sql"
echo "  3. Paste and run in the SQL editor"
echo ""

echo -e "${BLUE}Step 3: Verify Migration${NC}"
echo "----------------------------------------"
echo ""
echo "After applying the migration, verify with:"
echo ""
echo "SELECT table_name FROM information_schema.tables"
echo "WHERE table_schema = 'public'"
echo "AND table_name IN ("
echo "  'health_logs', 'medication_tracking', 'personal_rules',"
echo "  'goals', 'schedules', 'contacts', 'processed_notes',"
echo "  'appointments', 'documents', 'time_blocks'"
echo ");"
echo ""
echo "You should see all 10 tables listed."
echo ""

echo -e "${BLUE}Step 4: Configure O1 API Access${NC}"
echo "----------------------------------------"
echo ""
echo "Add to your config.txt file:"
echo "OPENAI_API_KEY=<your-api-key>"
echo ""
echo "Note: O1 models require:"
echo "  • Valid OpenAI API key"
echo "  • Access to o1-preview or o1 model"
echo "  • Sufficient API credits"
echo ""

echo "========================================="
echo -e "${GREEN}  Migration Ready to Apply!${NC}"
echo "========================================="