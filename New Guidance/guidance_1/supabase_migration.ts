/**
 * Supabase User Migration Script
 *
 * This TypeScript script migrates existing users from your database to Supabase Auth.
 * Run this in the Supabase Edge Functions environment or as a Node.js script with admin privileges.
 *
 * Prerequisites:
 * - Supabase admin key (service_role key)
 * - Access to your database
 * - Node.js environment with @supabase/supabase-js
 */

import { createClient, SupabaseClient } from '@supabase/supabase-js'

// Configuration - Replace with your actual values
const SUPABASE_URL = 'https://tajmifkqcttcrhmmiobe.supabase.co'
const SUPABASE_SERVICE_ROLE_KEY = 'your-service-role-key-here' // Replace with actual service role key
const DATABASE_URL = 'your-database-connection-string' // If needed for direct DB access

// Initialize Supabase admin client
const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})

interface UserRecord {
  id: number
  email: string
  username: string
  first_name: string
  last_name: string
  role: string
  student_id?: string
  grade_level?: string
  section?: string
}

async function migrateUsersToAuth() {
  console.log('Starting user migration to Supabase Auth...')

  try {
    // Fetch all existing users from your database
    const { data: users, error: fetchError } = await supabaseAdmin
      .from('users')
      .select('id, email, username, first_name, last_name, role, student_id, grade_level, section')
      .not('email', 'is', null)
      .neq('email', '')

    if (fetchError) {
      throw new Error(`Failed to fetch users: ${fetchError.message}`)
    }

    if (!users || users.length === 0) {
      console.log('No users found to migrate.')
      return
    }

    console.log(`Found ${users.length} users to migrate.`)

    let successCount = 0
    let errorCount = 0

    for (const user of users as UserRecord[]) {
      try {
        console.log(`Processing user: ${user.email} (${user.role})`)

        // Check if user already exists in auth
        const { data: existingAuthUser } = await supabaseAdmin.auth.admin.listUsers({
          filter: `email.eq.${user.email}`
        })

        if (existingAuthUser && existingAuthUser.users.length > 0) {
          console.log(`User ${user.email} already exists in auth. Updating database record...`)

          // Update the database record with the existing auth user ID
          await supabaseAdmin
            .from('users')
            .update({ id: existingAuthUser.users[0].id })
            .eq('email', user.email)

          successCount++
          continue
        }

        // Create new auth user
        const defaultPassword = 'TempPass123!' // Users should change this after first login

        const { data: authUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
          email: user.email,
          password: defaultPassword,
          email_confirm: true, // Auto-confirm email
          user_metadata: {
            username: user.username,
            first_name: user.first_name,
            last_name: user.last_name,
            role: user.role,
            student_id: user.student_id,
            grade_level: user.grade_level,
            section: user.section,
          }
        })

        if (createError) {
          throw createError
        }

        if (authUser.user) {
          // Update the database record with the new auth user ID
          const { error: updateError } = await supabaseAdmin
            .from('users')
            .update({ id: authUser.user.id })
            .eq('email', user.email)

          if (updateError) {
            console.error(`Failed to update database record for ${user.email}:`, updateError)
          } else {
            console.log(`Successfully migrated user: ${user.email}`)
            successCount++
          }
        }

        // Add a small delay to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 100))

      } catch (error) {
        console.error(`Error migrating user ${user.email}:`, error)
        errorCount++
      }
    }

    console.log(`\nMigration completed!`)
    console.log(`Successfully migrated: ${successCount} users`)
    console.log(`Errors: ${errorCount} users`)

    if (successCount > 0) {
      console.log('\n⚠️  IMPORTANT: Users have been created with default password "TempPass123!"')
      console.log('Please inform users to change their passwords after first login.')
    }

  } catch (error) {
    console.error('Migration failed:', error)
    throw error
  }
}

// Function to assign roles based on user metadata
async function assignUserRoles() {
  console.log('Assigning roles to migrated users...')

  try {
    // Get all auth users
    const { data: authUsers, error: listError } = await supabaseAdmin.auth.admin.listUsers()

    if (listError) {
      throw listError
    }

    for (const authUser of authUsers.users) {
      const role = authUser.user_metadata?.role

      if (role) {
        // You can add role-based logic here
        // For example, create entries in a user_roles table or set custom claims

        console.log(`User ${authUser.email} has role: ${role}`)

        // Example: Update user metadata with role confirmation
        await supabaseAdmin.auth.admin.updateUserById(authUser.id, {
          user_metadata: {
            ...authUser.user_metadata,
            role_assigned: true
          }
        })
      }
    }

    console.log('Role assignment completed.')

  } catch (error) {
    console.error('Role assignment failed:', error)
  }
}

// Main execution
async function main() {
  try {
    await migrateUsersToAuth()
    await assignUserRoles()
    console.log('\n🎉 Migration process completed successfully!')
  } catch (error) {
    console.error('Migration process failed:', error)
    process.exit(1)
  }
}

// Export for use as module or run directly
if (require.main === module) {
  main()
}

export { migrateUsersToAuth, assignUserRoles }
