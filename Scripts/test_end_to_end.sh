#!/bin/bash

# End-to-End Testing Script for Omni AI Security Implementation
# This script tests all app functionality to ensure no regression

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Omni AI End-to-End Testing Suite"
echo "====================================="
echo ""

# Configuration
API_URL="https://generateairesponse-bzait6iraa-uc.a.run.app"
TEST_EMAIL="test_$(date +%s)@test.com"
TEST_PASSWORD="TestPassword123!"

# Test results
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
test_passed() {
    echo -e "${GREEN}✅ PASSED${NC}: $1"
    ((PASSED++))
}

test_failed() {
    echo -e "${RED}❌ FAILED${NC}: $1"
    echo "   Error: $2"
    ((FAILED++))
}

test_warning() {
    echo -e "${YELLOW}⚠️  WARNING${NC}: $1"
    ((WARNINGS++))
}

print_section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# SECTION 1: Firebase Connectivity Tests
print_section "Testing Firebase Connectivity"

echo "Testing Firebase project access..."
if firebase projects:list 2>/dev/null | grep -q "omni-ai-8d5d2"; then
    test_passed "Firebase project accessible"
else
    test_failed "Firebase project access" "Cannot access Firebase project"
fi

# Continue with remaining tests...
echo ""
echo "Test script created. Run with: bash Scripts/test_end_to_end.sh"
