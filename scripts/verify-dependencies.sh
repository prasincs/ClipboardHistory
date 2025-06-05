#!/bin/bash
set -eo pipefail

# Dependency verification script
# This script verifies that dependencies match expected checksums
# to prevent supply chain attacks

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Expected dependency checksums (update these when legitimately updating dependencies)
get_expected_checksum() {
    case "$1" in
        "HotKey") echo "a3cf605d7a96f6ff50e04fcb6dea6e2613cfcbe4" ;;
        *) echo "" ;;
    esac
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "🔍 Verifying dependency integrity..."

# Check if Package.resolved exists
if [ ! -f "$PROJECT_ROOT/Package.resolved" ]; then
    echo -e "${RED}❌ Package.resolved not found!${NC}"
    echo "Run 'swift package resolve' to generate it."
    exit 1
fi

# Parse Package.resolved and verify checksums
FAILURES=0
while IFS= read -r line; do
    if [[ $line =~ \"identity\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
        CURRENT_PACKAGE="${BASH_REMATCH[1]}"
    elif [[ $line =~ \"revision\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
        CURRENT_REVISION="${BASH_REMATCH[1]}"
        
        # Convert package name to our expected format
        PACKAGE_KEY=""
        case "$CURRENT_PACKAGE" in
            "hotkey") PACKAGE_KEY="HotKey" ;;
        esac
        
        if [ -n "$PACKAGE_KEY" ]; then
            EXPECTED=$(get_expected_checksum "$PACKAGE_KEY")
            if [ -z "$EXPECTED" ]; then
                echo -e "${YELLOW}⚠️  Package '$PACKAGE_KEY' not in verification list${NC}"
            elif [ "$CURRENT_REVISION" != "$EXPECTED" ]; then
                echo -e "${RED}❌ Package '$PACKAGE_KEY' checksum mismatch!${NC}"
                echo "   Expected: $EXPECTED"
                echo "   Found:    $CURRENT_REVISION"
                FAILURES=$((FAILURES + 1))
            else
                echo -e "${GREEN}✅ Package '$PACKAGE_KEY' verified${NC}"
            fi
        fi
    fi
done < "$PROJECT_ROOT/Package.resolved"

if [ $FAILURES -gt 0 ]; then
    echo -e "${RED}❌ Dependency verification failed!${NC}"
    echo "This could indicate:"
    echo "  - An unauthorized dependency update"
    echo "  - A compromised dependency"
    echo "  - A supply chain attack"
    echo ""
    echo "If this is a legitimate update, update the checksums in this script."
    exit 1
else
    echo -e "${GREEN}✅ All dependencies verified successfully${NC}"
fi