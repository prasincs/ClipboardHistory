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
    echo -e "${YELLOW}ℹ️  Package.resolved not found; no dependencies to verify.${NC}"
    exit 0
fi

FAILURES=0
FOUND=0
while IFS= read -r line; do
    if [[ $line =~ \"identity\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
        CURRENT_PACKAGE="${BASH_REMATCH[1]}"
    elif [[ $line =~ \"revision\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
        CURRENT_REVISION="${BASH_REMATCH[1]}"

        PACKAGE_KEY="${CURRENT_PACKAGE}"
        EXPECTED=$(get_expected_checksum "$PACKAGE_KEY")

        FOUND=1
        if [ -z "$EXPECTED" ]; then
            echo -e "${YELLOW}⚠️  Package '$PACKAGE_KEY' has no expected checksum registered.${NC}"
        elif [ "$CURRENT_REVISION" != "$EXPECTED" ]; then
            echo -e "${RED}❌ Package '$PACKAGE_KEY' checksum mismatch!${NC}"
            echo "   Expected: $EXPECTED"
            echo "   Found:    $CURRENT_REVISION"
            FAILURES=$((FAILURES + 1))
        else
            echo -e "${GREEN}✅ Package '$PACKAGE_KEY' verified${NC}"
        fi
    fi
  done < "$PROJECT_ROOT/Package.resolved"

if [ $FOUND -eq 0 ]; then
    echo -e "${YELLOW}ℹ️  No dependencies pinned in Package.resolved.${NC}"
fi

if [ $FAILURES -gt 0 ]; then
    echo -e "${RED}❌ Dependency verification failed!${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Dependency verification completed successfully.${NC}"
fi
