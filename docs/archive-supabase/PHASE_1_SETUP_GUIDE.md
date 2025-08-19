# Phase 1 Setup Guide - Supabase Backend Integration

## ✅ Completed Automatically
- Fixed ChatView.swift compilation issues
- Created service files (ChatService.swift, OfflineManager.swift, SupabaseManager.swift)
- Updated all data models to use UUID and be Supabase-compatible
- Prepared SQL schema with RLS policies
- Updated AuthenticationManager for Supabase (commented out until files added)

## 🔧 Manual Steps Required

### 1. Add Service Files to Xcode Project
**Files to add:**
- `OmniAI/Services/ChatService.swift`
- `OmniAI/Services/OfflineManager.swift` 
- `OmniAI/Services/SupabaseManager.swift`

**Steps:**
1. Open `OmniAI.xcodeproj` in Xcode
2. Right-click on the "Services" folder in Xcode navigator
3. Select "Add Files to 'OmniAI'"
4. Navigate to the Services folder and select the three files above
5. Ensure "Add to target: OmniAI" is checked
6. Click "Add"

### 2. Run Supabase Database Setup
**Steps:**
1. Go to your Supabase dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `supabase_setup.sql`
4. Click "Run" to execute the SQL

**What this creates:**
- `users` table with profile data
- `chat_sessions` table for conversation metadata
- `chat_messages` table for storing all messages (real-time enabled)
- `mood_entries` table for mood tracking
- `journal_entries` table for journal data
- RLS policies ensuring users only see their own data
- Performance indexes

### 3. Enable Real-time for Chat Messages
**Steps:**
1. In Supabase dashboard, go to Database > Replication
2. Find the `chat_messages` table
3. Toggle on "Real-time" for this table
4. This enables live chat message sync across devices

### 4. Re-enable Service Integration (After Step 1)
Once the service files are added to Xcode:

**Edit `OmniAI/App/OmniAIApp.swift`:**
```swift
// Uncomment these lines:
@StateObject private var chatService = ChatService()
@StateObject private var offlineManager = OfflineManager()

// And these:
.environmentObject(chatService)
.environmentObject(offlineManager)

// And this:
.onAppear {
    offlineManager.startMonitoring()
}
```

**Edit `OmniAI/Services/AuthenticationManager.swift`:**
```swift
// Uncomment this line:
private let supabase = SupabaseManager.shared.client

// And uncomment the Supabase integration code in each function
```

## 🧪 Testing Steps

### 1. Build and Run
```bash
xcodebuild -project OmniAI.xcodeproj -scheme OmniAI build
```

### 2. Test Features
- **Authentication**: Sign up/sign in should work with Supabase
- **Chat**: Messages should persist between app launches
- **Mood Tracking**: Mood entries should save to database
- **Journal**: Journal entries should persist
- **Real-time**: Open chat on two devices, messages should sync instantly

### 3. Verify Database
In Supabase dashboard, check that data appears in the tables:
- New users in `users` table
- Chat messages in `chat_messages` table
- Mood entries in `mood_entries` table

## 🚀 What This Achieves

**Current State**: Chat works with mock responses stored locally
**After Phase 1**: Chat works with mock responses stored in Supabase with real-time sync

**Ready for Phase 2**: 
- Database infrastructure ready for OpenAI responses
- Real-time messaging system in place
- User authentication and data isolation working
- Offline mode with sync queuing ready

The app will continue to work exactly as before, but now with persistent cloud storage and multi-device sync. This prepares us for Phase 2 where we'll replace the mock responses with actual OpenAI API calls.

## 🔍 Troubleshooting

**Build errors about missing imports:**
- Ensure all three service files are added to the Xcode project target

**Database connection errors:**
- Check that the SQL schema was run successfully in Supabase
- Verify the Supabase URL and API key in SupabaseManager.swift

**Real-time not working:**
- Ensure real-time is enabled for chat_messages table in Supabase dashboard
- Check that RLS policies are correctly applied