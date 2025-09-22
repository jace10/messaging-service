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
    echo "Clear database tables and reset data."
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --confirm, -y Skip confirmation prompt"
    echo "  --messages     Clear only messages table"
    echo "  --conversations Clear only conversations table"
    echo "  --all          Clear all tables (default)"
    echo "  --reset        Clear all tables and reset sequences"
    echo
    echo "Examples:"
    echo "  $0                    # Clear all tables with confirmation"
    echo "  $0 --confirm          # Clear all tables without confirmation"
    echo "  $0 --messages         # Clear only messages table"
    echo "  $0 --conversations    # Clear only conversations table"
    echo "  $0 --reset            # Clear all and reset auto-increment sequences"
    echo
    echo "⚠️  WARNING: This will permanently delete data!"
    echo "   Make sure you have backups if needed."
}

# Default values
CLEAR_MESSAGES=true
CLEAR_CONVERSATIONS=true
RESET_SEQUENCES=false
SKIP_CONFIRMATION=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --confirm|-y)
            SKIP_CONFIRMATION=true
            shift
            ;;
        --messages)
            CLEAR_MESSAGES=true
            CLEAR_CONVERSATIONS=false
            RESET_SEQUENCES=false
            shift
            ;;
        --conversations)
            CLEAR_MESSAGES=false
            CLEAR_CONVERSATIONS=true
            RESET_SEQUENCES=false
            shift
            ;;
        --all)
            CLEAR_MESSAGES=true
            CLEAR_CONVERSATIONS=true
            RESET_SEQUENCES=false
            shift
            ;;
        --reset)
            CLEAR_MESSAGES=true
            CLEAR_CONVERSATIONS=true
            RESET_SEQUENCES=true
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

echo -e "${RED}🗑️  Messaging Service Database Cleaner${NC}"
echo -e "${RED}=====================================${NC}"
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

# Show current data counts before clearing
echo -e "${YELLOW}📊 Current Data Counts:${NC}"
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
" "Pre-Clear Counts" "$CYAN"

# Confirmation prompt
if [ "$SKIP_CONFIRMATION" = false ]; then
    echo -e "${RED}⚠️  WARNING: This will permanently delete data!${NC}"
    echo
    
    if [ "$CLEAR_MESSAGES" = true ] && [ "$CLEAR_CONVERSATIONS" = true ]; then
        echo -e "${YELLOW}You are about to clear ALL tables (conversations and messages)${NC}"
    elif [ "$CLEAR_MESSAGES" = true ]; then
        echo -e "${YELLOW}You are about to clear the MESSAGES table only${NC}"
    elif [ "$CLEAR_CONVERSATIONS" = true ]; then
        echo -e "${YELLOW}You are about to clear the CONVERSATIONS table only${NC}"
    fi
    
    if [ "$RESET_SEQUENCES" = true ]; then
        echo -e "${YELLOW}Sequences will also be reset to start from 1${NC}"
    fi
    
    echo
    read -p "Are you sure you want to continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${GREEN}✅ Operation cancelled${NC}"
        exit 0
    fi
fi

# Clear tables
echo -e "${RED}🗑️  Clearing database...${NC}"

if [ "$CLEAR_MESSAGES" = true ]; then
    execute_sql "DELETE FROM messages;" "Clearing Messages Table" "$RED"
fi

if [ "$CLEAR_CONVERSATIONS" = true ]; then
    execute_sql "DELETE FROM conversations;" "Clearing Conversations Table" "$RED"
fi

# Reset sequences if requested
if [ "$RESET_SEQUENCES" = true ]; then
    execute_sql "
        ALTER SEQUENCE conversations_id_seq RESTART WITH 1;
        ALTER SEQUENCE messages_id_seq RESTART WITH 1;
    " "Resetting Sequences" "$PURPLE"
fi

# Show final counts
echo -e "${GREEN}📊 Final Data Counts:${NC}"
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
" "Post-Clear Counts" "$GREEN"

echo -e "${GREEN}✅ Database clearing complete${NC}"
echo -e "${BLUE}💡 Use '$0 --help' for more options${NC}"
