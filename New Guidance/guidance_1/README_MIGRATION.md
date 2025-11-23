# Supabase User Migration Guide

This guide explains how to migrate your existing users from the database to Supabase Auth so they can log in using the Edge Function.

## Problem

Your users exist in the `users` table but not in Supabase Auth, causing "Invalid login credentials" errors when trying to log in through the Edge Function.

## Solution

Run the Supabase Edge Function to migrate users. This runs directly in Supabase's environment.

## Prerequisites

1. **Supabase Service Role Key**: You need the service role key (not the anon key) to create auth users programmatically.
2. **Node.js Environment**: The script runs in Node.js with TypeScript support.
3. **Admin Privileges**: The service role key provides admin access to create users.

## Step-by-Step Migration

### 1. Deploy the Edge Function

The migration Edge Function is already created at `supabase/functions/migrate-users/index.ts`. Deploy it using the Supabase CLI:

```bash
supabase functions deploy migrate-users
```

### 2. Get Your Service Role Key

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/tajmifkqcttcrhmmiobe)
2. Navigate to Settings → API
3. Copy the "service_role" key (keep this secret!)

### 3. Run the Migration

Call the Edge Function with your service role key:

```bash
curl -X POST \
  https://tajmifkqcttcrhmmiobe.supabase.co/functions/v1/migrate-users \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

Or use a tool like Postman/Insomnia with:
- Method: POST
- URL: `https://tajmifkqcttcrhmmiobe.supabase.co/functions/v1/migrate-users`
- Headers:
  - `Authorization: Bearer YOUR_SERVICE_ROLE_KEY`
  - `Content-Type: application/json`

### Alternative: Using Supabase CLI

If you have Supabase CLI installed and logged in:

```bash
supabase functions invoke migrate-users \
  --method POST \
  --headers "Authorization=Bearer YOUR_SERVICE_ROLE_KEY"
```

### Alternative: Using JavaScript/Node.js

Create a simple script to call the function:

```javascript
// migrate.js
const { createClient } = require('@supabase/supabase-js')

const SUPABASE_URL = 'https://tajmifkqcttcrhmmiobe.supabase.co'
const SERVICE_ROLE_KEY = 'YOUR_SERVICE_ROLE_KEY'

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)

async function runMigration() {
  try {
    const { data, error } = await supabase.functions.invoke('migrate-users', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${SERVICE_ROLE_KEY}`
      }
    })

    if (error) {
      console.error('Migration failed:', error)
    } else {
      console.log('Migration result:', data)
    }
  } catch (err) {
    console.error('Error:', err)
  }
}

runMigration()
```

Run with:
```bash
node migrate.js
```

### 5. Verify the Migration

After running the script:

1. Check the Supabase Auth users in the dashboard
2. Test login with the AuthTestPage in your Flutter app
3. Verify user roles and metadata are correct

## What the Script Does

1. **Fetches existing users** from your `users` table
2. **Creates auth users** in Supabase Auth with:
   - The same email address
   - Default password: `TempPass123!`
   - User metadata including role, name, student_id, etc.
3. **Updates database records** with the correct auth user IDs
4. **Assigns roles** based on user metadata

## Important Notes

### Default Password
- All migrated users get the password `TempPass123!`
- **Users must change this password after first login**
- Inform users about this temporary password

### User Roles
The script preserves user roles (student, counselor, admin) in the user metadata. You can use this for authorization in your Edge Function.

### Rate Limiting
The script includes delays to avoid Supabase rate limits. For large user bases, you might need to run it in batches.

## Alternative: Manual Migration

If you prefer not to use the script, you can manually create users in the Supabase dashboard:

1. Go to Authentication → Users
2. Click "Add user"
3. Enter email and password for each user
4. Update the `users` table with the auth user ID

## Troubleshooting

### "Admin API not available"
- Ensure you're using the service role key, not the anon key
- Check that your Supabase project allows admin operations

### "User already exists"
- The script checks for existing auth users and updates the database record instead of creating duplicates

### "Rate limited"
- Add longer delays between user creation
- Run the script in smaller batches

## After Migration

Once users are migrated:

1. Test login functionality with the AuthTestPage
2. Update your login UI to handle the Edge Function responses
3. Implement password reset functionality so users can change from the default password
4. Set up proper role-based authorization in your Edge Function

## Security Considerations

- Never commit the service role key to version control
- Use environment variables for sensitive keys
- Rotate keys regularly
- Monitor for unauthorized access

## Need Help?

If you encounter issues:

1. Check the console output for specific error messages
2. Verify your service role key has admin permissions
3. Ensure your Supabase project settings allow user creation
4. Test with a single user first before migrating all users
