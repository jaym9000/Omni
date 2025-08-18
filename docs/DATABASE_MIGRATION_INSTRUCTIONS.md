# 🔧 Database Migration Instructions

## Fix for Email Sign-Up Error

You're seeing the error "new row violates row-level security policy for table 'users'" because the Supabase database is missing columns and policies needed for the guest user feature.

## How to Apply the Fix

### Step 1: Open Supabase Dashboard
1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project (rchropdkyqpfyjwgdudv)
3. Navigate to **SQL Editor** in the left sidebar

### Step 2: Run the Migration
1. Click **New Query** button
2. Copy the entire contents of `supabase_migration_fix.sql`
3. Paste it into the SQL editor
4. Click **Run** button (or press Cmd+Enter)

### Step 3: Verify the Migration
You should see a success message saying:
```
Migration completed successfully!
Users table now supports guest users and has proper RLS policies.
Email sign-up should now work without RLS violations.
```

### What This Migration Does

1. **Adds Missing Columns** to the users table:
   - `is_guest` - Tracks if user is a guest
   - `guest_conversation_count` - Tracks guest conversations
   - `max_guest_conversations` - Sets limit (default 3)
   - `notifications_enabled` - User preference
   - `daily_reminder_time` - For reminder notifications

2. **Fixes RLS Policies** to allow:
   - New users to create their profile during sign-up
   - Anonymous users to create guest profiles
   - Proper upsert operations to avoid conflicts

3. **Creates Helper Functions**:
   - `upsert_user_profile()` - Safely creates or updates user profiles
   - `get_user_by_auth_id()` - Retrieves user by auth ID

4. **Adds Performance Indexes** for faster queries

## Testing After Migration

1. **Test Email Sign-Up**:
   - Try creating a new account with email
   - Should work without RLS errors

2. **Test Guest Sign-In**:
   - Click "Try Omni Free"
   - Should allow 3 conversations per day

3. **Test Apple Sign-In**:
   - Should continue working as before

## Troubleshooting

If you still see errors after running the migration:

1. **Check if columns were added**:
   ```sql
   SELECT column_name 
   FROM information_schema.columns 
   WHERE table_name = 'users';
   ```

2. **Check RLS policies**:
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename = 'users';
   ```

3. **Try a manual insert test**:
   ```sql
   -- This should work after migration
   INSERT INTO users (
       auth_user_id,
       email,
       display_name,
       is_guest
   ) VALUES (
       auth.uid(),
       'test@example.com',
       'Test User',
       false
   );
   ```

## Important Notes

- This migration is safe to run multiple times (idempotent)
- It uses `IF NOT EXISTS` and `IF EXISTS` clauses
- No data will be lost
- The migration preserves all existing users and data

## Need Help?

If you encounter any issues:
1. Check the Supabase logs: Dashboard > Logs > Recent Logs
2. Verify your Supabase URL and anon key in the app match the dashboard
3. Ensure RLS is enabled on all tables (it should be after migration)