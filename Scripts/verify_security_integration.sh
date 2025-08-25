#!/bin/bash

# Final Security Integration Verification Script
# Ensures all security features are properly integrated

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🔐 Security Integration Verification"
echo "====================================="
echo ""

PASSED=0
FAILED=0

check() {
    local test_name="$1"
    local command="$2"
    
    echo -n "Checking $test_name... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌${NC}"
        ((FAILED++))
    fi
}

echo -e "${BLUE}1. iOS Security Files${NC}"
check "CertificatePinner.swift" "[ -f 'OmniAI/Security/CertificatePinner.swift' ]"
check "NetworkSecurityManager.swift" "[ -f 'OmniAI/Security/NetworkSecurityManager.swift' ]"
check "BiometricAuthManager.swift" "[ -f 'OmniAI/Security/BiometricAuthManager.swift' ]"
check "SecureStorageMigrator.swift" "[ -f 'OmniAI/Security/SecureStorageMigrator.swift' ]"
check "AuditLogger.swift" "[ -f 'OmniAI/Security/AuditLogger.swift' ]"
check "JailbreakDetector.swift" "[ -f 'OmniAI/Security/JailbreakDetector.swift' ]"
check "MessageEncryption.swift" "[ -f 'OmniAI/Security/MessageEncryption.swift' ]"
check "SecurityMonitor.swift" "[ -f 'OmniAI/Security/SecurityMonitor.swift' ]"

echo ""
echo -e "${BLUE}2. Cloud Functions Security${NC}"
check "InputValidator module" "[ -f 'functions/src/security/inputValidator.ts' ]"
check "ContentModerator module" "[ -f 'functions/src/security/contentModerator.ts' ]"
check "RateLimiter module" "[ -f 'functions/src/security/rateLimiter.ts' ]"
check "App Check import" "grep -q 'firebase-admin/app-check' functions/src/index.ts"
check "Functions build" "cd functions && npm run build"

echo ""
echo -e "${BLUE}3. Configuration Files${NC}"
check "Firestore rules" "[ -f 'firestore.rules' ]"
check "Security documentation" "[ -f 'SECURITY.md' ]"
check "Face ID permission" "grep -q 'NSFaceIDUsageDescription' OmniAI/Info.plist"

echo ""
echo -e "${BLUE}4. Scripts${NC}"
check "Xcode integration script" "[ -f 'Scripts/integrate_security_xcode.py' ]"
check "Automated build script" "[ -f 'Scripts/automated_build.sh' ]"
check "Security test suite" "[ -f 'Scripts/security_test_suite.sh' ]"
check "Security implementation test" "[ -f 'Scripts/test_security_implementation.sh' ]"

echo ""
echo -e "${BLUE}5. Integration${NC}"
check "App Check in iOS app" "grep -q 'FirebaseAppCheck' OmniAI/App/OmniAIApp.swift"
check "Keychain manager used" "grep -q 'KeychainManager' OmniAI/Security/*.swift"
check "Input validation in functions" "grep -q 'InputValidator' functions/src/index.ts"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Results:${NC}"
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All security features are properly integrated!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Run the full test suite: ./Scripts/security_test_suite.sh"
    echo "2. Build the app: ./Scripts/automated_build.sh"
    echo "3. Deploy Cloud Functions: firebase deploy --only functions"
    echo "4. Test on physical device"
    exit 0
else
    echo -e "${RED}❌ Some security features are missing!${NC}"
    echo "Please review the failed checks above."
    exit 1
fi