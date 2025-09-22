#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Display database tables and data in a readable format."
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --tables, -t   Show only table structure"
    echo "  --data, -d     Show only table data"
    echo "  --conversations Show only conversations table"
    echo "  --messages     Show only messages table"
    echo "  --counts       Show only row counts"
    echo
    echo "Examples:"
    echo "  $0                    # Show all tables and data"
    echo "  $0 --tables           # Show only table structure"
    echo "  $0 --data             # Show only table data"
    echo "  $0 --conversations    # Show only conversations"
    echo "  $0 --messages         # Show only messages"
    echo "  $0 --counts           # Show only row counts"
}

# Default values
SHOW_TABLES=true
SHOW_DATA=true
SHOW_CONVERSATIONS=true
SHOW_MESSAGES=true
SHOW_COUNTS=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --tables|-t)
            SHOW_TABLES=true
            SHOW_DATA=false
            SHOW_CONVERSATIONS=false
            SHOW_MESSAGES=false
            SHOW_COUNTS=false
            shift
            ;;
        --data|-d)
            SHOW_TABLES=false
            SHOW_DATA=true
            SHOW_CONVERSATIONS=false
            SHOW_MESSAGES=false
            SHOW_COUNTS=false
            shift
            ;;
        --conversations)
            SHOW_TABLES=false
            SHOW_DATA=false
            SHOW_CONVERSATIONS=true
            SHOW_MESSAGES=false
            SHOW_COUNTS=false
            shift
            ;;
        --messages)
            SHOW_TABLES=false
            SHOW_DATA=false
            SHOW_CONVERSATIONS=false
            SHOW_MESSAGES=true
            SHOW_COUNTS=false
            shift
            ;;
        --counts)
            SHOW_TABLES=false
            SHOW_DATA=false
            SHOW_CONVERSATIONS=false
            SHOW_MESSAGES=false
            SHOW_COUNTS=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            echo "Use '$0 --help' for usage information" >&2
            exit 1
            ;;
    esac
done

# Database connection parameters
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-messaging_service}
DB_USER=${DB_USER:-messaging_user}
DB_PASSWORD=${DB_PASSWORD:-messaging_password}

echo -e "${BLUE}📊 Messaging Service Database Inspector${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Function to execute SQL and format output
execute_sql() {
    local sql="$1"
    local title="$2"
    local color="$3"
    
    echo -e "${color}${title}${NC}"
    echo -e "${color}$(printf '=%.0s' {1..${#title}})${NC}"
    
    if command -v psql >/dev/null 2>&1; then
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$sql" 2>/dev/null || {
            echo -e "${RED}❌ Failed to connect to database${NC}"
            echo -e "${YELLOW}💡 Make sure the database is running:${NC}"
            echo -e "   ${CYAN}docker-compose up -d postgres${NC}"
            echo -e "   ${CYAN}or start your local PostgreSQL service${NC}"
            return 1
        }
    else
        echo -e "${RED}❌ psql not found. Please install PostgreSQL client tools.${NC}"
        echo -e "${YELLOW}💡 Install with:${NC}"
        echo -e "   ${CYAN}brew install postgresql${NC} (macOS)"
        echo -e "   ${CYAN}sudo apt-get install postgresql-client${NC} (Ubuntu/Debian)"
        return 1
    fi
    echo
}

# Check if database is accessible
echo -e "${YELLOW}🔍 Checking database connection...${NC}"
if ! execute_sql "SELECT 1;" "Connection Test" "$GREEN" >/dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to database${NC}"
    echo -e "${YELLOW}💡 Make sure the database is running:${NC}"
    echo -e "   ${CYAN}docker-compose up -d postgres${NC}"
    echo -e "   ${CYAN}or start your local PostgreSQL service${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Database connection successful${NC}"
echo

# Show table structure
if [ "$SHOW_TABLES" = true ]; then
    execute_sql "
        SELECT 
            table_name,
            column_name,
            data_type,
            is_nullable,
            column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name IN ('conversations', 'messages')
        ORDER BY table_name, ordinal_position;
    " "📋 Table Structure" "$PURPLE"
fi

# Show row counts
if [ "$SHOW_COUNTS" = true ]; then
    execute_sql "
        SELECT 
            'conversations' as table_name,
            COUNT(*) as row_count
        FROM conversations
        UNION ALL
        SELECT 
            'messages' as table_name,
            COUNT(*) as row_count
        FROM messages;
    " "📊 Row Counts" "$CYAN"
fi

# Show conversations data
if [ "$SHOW_CONVERSATIONS" = true ]; then
    execute_sql "
        SELECT 
            id,
            participant_from,
            participant_to,
            created_at,
            updated_at
        FROM conversations 
        ORDER BY created_at DESC;
    " "💬 Conversations" "$GREEN"
fi

# Show messages data
if [ "$SHOW_MESSAGES" = true ]; then
    execute_sql "
        SELECT 
            m.id,
            m.conversation_id,
            m.from_address,
            m.to_address,
            m.message_type,
            LEFT(m.body, 50) || CASE WHEN LENGTH(m.body) > 50 THEN '...' ELSE '' END as body_preview,
            m.messaging_provider_id,
            m.xillio_id,
            m.timestamp,
            m.direction,
            m.created_at
        FROM messages m
        ORDER BY m.timestamp DESC
        LIMIT 20;
    " "📨 Recent Messages (Last 20)" "$BLUE"
fi

# Show summary statistics
if [ "$SHOW_DATA" = true ]; then
    execute_sql "
        SELECT 
            'Total Conversations' as metric,
            COUNT(*)::text as value
        FROM conversations
        UNION ALL
        SELECT 
            'Total Messages' as metric,
            COUNT(*)::text as value
        FROM messages
        UNION ALL
        SELECT 
            'SMS Messages' as metric,
            COUNT(*)::text as value
        FROM messages WHERE message_type = 'sms'
        UNION ALL
        SELECT 
            'MMS Messages' as metric,
            COUNT(*)::text as value
        FROM messages WHERE message_type = 'mms'
        UNION ALL
        SELECT 
            'Email Messages' as metric,
            COUNT(*)::text as value
        FROM messages WHERE message_type = 'email'
        UNION ALL
        SELECT 
            'Inbound Messages' as metric,
            COUNT(*)::text as value
        FROM messages WHERE direction = 'inbound'
        UNION ALL
        SELECT 
            'Outbound Messages' as metric,
            COUNT(*)::text as value
        FROM messages WHERE direction = 'outbound';
    " "📈 Summary Statistics" "$YELLOW"
fi

echo -e "${GREEN}✅ Database inspection complete${NC}"
echo -e "${BLUE}💡 Use '$0 --help' for more options${NC}"
