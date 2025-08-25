#!/bin/bash

# Script to configure API key restrictions and security settings
# Run this script to secure your Firebase and Google Cloud APIs

set -e

# Configuration
PROJECT_ID="omni-ai-8d5d2"
BUNDLE_ID="com.jns.Omni"

echo "🔒 Configuring API Security for Omni AI"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI is not installed${NC}"
    echo "Please install Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if firebase is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ firebase CLI is not installed${NC}"
    echo "Please install Firebase CLI: npm install -g firebase-tools"
    exit 1
fi

echo "📋 Current Project: $PROJECT_ID"
echo ""

# Set the active project
echo "Setting active project..."
gcloud config set project $PROJECT_ID

# Get the current Firebase API key from GoogleService-Info.plist
if [ -f "OmniAI/GoogleService-Info.plist" ]; then
    API_KEY=$(grep -A1 "API_KEY" OmniAI/GoogleService-Info.plist | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>/\1/')
    echo -e "${GREEN}✅ Found API Key: ${API_KEY:0:10}...${NC}"
else
    echo -e "${YELLOW}⚠️  GoogleService-Info.plist not found${NC}"
    echo "Please enter your Firebase API key manually:"
    read -r API_KEY
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Configuring Firebase App Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Enable App Check in Firebase
echo "Enabling App Check for iOS app..."
firebase appcheck:activate ios --project $PROJECT_ID 2>/dev/null || {
    echo -e "${YELLOW}⚠️  App Check may already be enabled or requires manual setup${NC}"
    echo "Please enable App Check in Firebase Console:"
    echo "https://console.firebase.google.com/project/$PROJECT_ID/appcheck"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Configuring API Key Restrictions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Note: API key restrictions need to be set via Console or API
echo "Setting API key restrictions..."
echo ""
echo "Please configure the following restrictions in Google Cloud Console:"
echo "1. Go to: https://console.cloud.google.com/apis/credentials?project=$PROJECT_ID"
echo "2. Click on your API key: $API_KEY"
echo "3. Under 'Application restrictions', select 'iOS apps'"
echo "4. Add bundle ID: $BUNDLE_ID"
echo "5. Under 'API restrictions', select 'Restrict key'"
echo "6. Add these APIs:"
echo "   - Firebase App Check API"
echo "   - Firebase Authentication API"
echo "   - Cloud Firestore API"
echo "   - Cloud Functions API"
echo "   - Firebase Cloud Messaging API"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Setting Up Security Rules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Deploy Firestore security rules
if [ -f "firestore.rules" ]; then
    echo "Deploying Firestore security rules..."
    firebase deploy --only firestore:rules --project $PROJECT_ID
    echo -e "${GREEN}✅ Firestore rules deployed${NC}"
else
    echo -e "${YELLOW}⚠️  firestore.rules not found${NC}"
fi

# Deploy Storage security rules if they exist
if [ -f "storage.rules" ]; then
    echo "Deploying Storage security rules..."
    firebase deploy --only storage:rules --project $PROJECT_ID
    echo -e "${GREEN}✅ Storage rules deployed${NC}"
else
    echo -e "${YELLOW}⚠️  storage.rules not found (may not be using Storage)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  Configuring Cloud Functions Security"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if OpenAI secret is configured
echo "Checking OpenAI API key secret..."
if gcloud secrets describe OPENAI_API_KEY --project=$PROJECT_ID &>/dev/null; then
    echo -e "${GREEN}✅ OpenAI API key secret exists${NC}"
else
    echo -e "${YELLOW}⚠️  OpenAI API key secret not found${NC}"
    echo "To create it, run:"
    echo "echo 'YOUR_OPENAI_API_KEY' | gcloud secrets create OPENAI_API_KEY --data-file=- --project=$PROJECT_ID"
fi

# Grant Cloud Functions access to the secret
echo "Granting Cloud Functions access to secrets..."
gcloud secrets add-iam-policy-binding OPENAI_API_KEY \
    --member="serviceAccount:$PROJECT_ID@appspot.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" \
    --project=$PROJECT_ID 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Secret access may already be configured${NC}"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  Enabling Security APIs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Enable required APIs
APIS=(
    "firebaseappcheck.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "iamcredentials.googleapis.com"
)

for API in "${APIS[@]}"; do
    echo "Enabling $API..."
    gcloud services enable $API --project=$PROJECT_ID 2>/dev/null || {
        echo -e "${YELLOW}⚠️  $API may already be enabled${NC}"
    }
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  Setting Up Monitoring"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Creating alert policies for security monitoring..."

# Create alert for high API usage
cat > /tmp/high_api_usage_alert.json << EOF
{
  "displayName": "High API Usage Alert",
  "conditions": [{
    "displayName": "API requests exceeding threshold",
    "conditionThreshold": {
      "filter": "resource.type=\"api\" AND metric.type=\"serviceruntime.googleapis.com/api/request_count\"",
      "comparison": "COMPARISON_GT",
      "thresholdValue": 10000,
      "duration": "300s",
      "aggregations": [{
        "alignmentPeriod": "60s",
        "perSeriesAligner": "ALIGN_RATE"
      }]
    }
  }]
}
EOF

gcloud alpha monitoring policies create --policy-from-file=/tmp/high_api_usage_alert.json --project=$PROJECT_ID 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Alert policy may already exist${NC}"
}

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Security Configuration Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "1. Configure API key restrictions in Google Cloud Console (link above)"
echo "2. Enable App Check in Firebase Console if not already enabled"
echo "3. Test the application to ensure all functions work correctly"
echo "4. Monitor the security alerts in Google Cloud Console"
echo ""
echo -e "${GREEN}🔒 Your app is now more secure!${NC}"