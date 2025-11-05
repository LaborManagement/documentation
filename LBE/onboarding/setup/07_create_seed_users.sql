-- ============================================================================
-- ONBOARDING PHASE 07: CREATE BOOTSTRAP SEED USERS (2 Total)
-- ============================================================================
-- Purpose: Create 2 bootstrap users for system initialization.
-- Users:
--   1. business.admin (BUSINESS_ADMIN + BASIC_USER roles): User management operations
--   2. tech.bootstrap (TECHNICAL_BOOTSTRAP + BASIC_USER roles): System configuration
--
-- NOTE: Both users are assigned BASIC_USER role to enable:
--   - Authorization API access (permission checking)
--   - Service catalog access (endpoint discovery)
--
-- Dependencies: users table and roles from 01_create_roles.sql must exist first.
-- ============================================================================

SET search_path TO auth;
\set ON_ERROR_STOP on

BEGIN;

-- ============================================================================
-- BACKUP EXISTING DATA (with date suffix: 251201)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_tenant_acl_251201 (LIKE auth.user_tenant_acl INCLUDING ALL);
DELETE FROM user_tenant_acl_251201;
INSERT INTO user_tenant_acl_251201 SELECT * FROM auth.user_tenant_acl 
WHERE user_id IN (SELECT id FROM auth.users WHERE username IN ('business.admin', 'tech.bootstrap'));

CREATE TABLE IF NOT EXISTS user_roles_251201 (LIKE user_roles INCLUDING ALL);
DELETE FROM user_roles_251201;
INSERT INTO user_roles_251201 SELECT * FROM user_roles 
WHERE user_id IN (SELECT id FROM auth.users WHERE username IN ('business.admin', 'tech.bootstrap'));

CREATE TABLE IF NOT EXISTS users_251201 (LIKE auth.users INCLUDING ALL);
DELETE FROM users_251201;
INSERT INTO users_251201 SELECT * FROM auth.users 
WHERE username IN ('business.admin', 'tech.bootstrap');

-- Clear existing seed users (fresh setup)
DELETE FROM auth.user_tenant_acl 
WHERE user_id IN (
  SELECT id FROM auth.users WHERE username IN ('business.admin', 'tech.bootstrap')
);

DELETE FROM user_roles
WHERE user_id IN (
  SELECT id FROM auth.users WHERE username IN ('business.admin', 'tech.bootstrap')
);

DELETE FROM auth.users
WHERE username IN ('business.admin', 'tech.bootstrap');

-- ============================================================================
-- INSERT 2 BOOTSTRAP SEED USERS
-- Note: full_name is REQUIRED by User entity definition
-- Password hashes: bcrypt hash (should be updated in production)
-- Roles will be assigned in 08_assign_users_to_roles.sql
-- ============================================================================

INSERT INTO auth.users (
  username,
  email,
  password,
  full_name,
  permission_version,
  role,
  is_enabled,
  is_account_non_expired,
  is_account_non_locked,
  is_credentials_non_expired,
  created_at,
  updated_at,
  last_login
) VALUES
(
  'business.admin',
  'business.admin@system.local',
  '$2a$12$slYQmyNdGzin7olVN3p5Be0DlH.PKZbv5H8KnzzVgXXbVxzy990qm',  -- encrypted password: Business!2025
  'Business Administrator',
  1,
  'ADMIN',
  true,
  true,
  true,
  true,
  NOW(),
  NOW(),
  NULL
),
(
  'tech.bootstrap',
  'tech.bootstrap@system.local',
  '$2a$12$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E50Dmk0m.',  -- encrypted password: TechBoot!2025
  'Technical Bootstrap Administrator',
  1,
  'ADMIN',
  true,
  true,
  true,
  true,
  NOW(),
  NOW(),
  NULL
)
ON CONFLICT (username) DO UPDATE SET
  email = EXCLUDED.email,
  password = EXCLUDED.password,
  full_name = EXCLUDED.full_name,
  permission_version = EXCLUDED.permission_version,
  role = EXCLUDED.role,
  is_enabled = EXCLUDED.is_enabled,
  is_account_non_expired = EXCLUDED.is_account_non_expired,
  is_account_non_locked = EXCLUDED.is_account_non_locked,
  is_credentials_non_expired = EXCLUDED.is_credentials_non_expired,
  updated_at = NOW();

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
  v_count INTEGER;
  v_missing_fullname INTEGER;
BEGIN
  -- Verify 2 seed users created
  SELECT COUNT(*) INTO v_count FROM auth.users 
  WHERE username IN ('business.admin', 'tech.bootstrap');
  
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'Expected 2 seed users, found %', v_count;
  END IF;
  
  -- Verify all users have full_name
  SELECT COUNT(*) INTO v_missing_fullname FROM auth.users
  WHERE username IN ('business.admin', 'tech.bootstrap')
  AND (full_name IS NULL OR full_name = '');
  
  IF v_missing_fullname > 0 THEN
    RAISE EXCEPTION 'Found % users with missing or empty full_name', v_missing_fullname;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE username IN ('business.admin', 'tech.bootstrap')
      AND is_enabled = false
  ) THEN
    RAISE EXCEPTION 'All seed users must be enabled';
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM auth.users 
    WHERE username IN ('business.admin', 'tech.bootstrap')
      AND role NOT IN ('ADMIN', 'USER', 'WORKER', 'BOARD', 'EMPLOYER')
  ) THEN
    RAISE EXCEPTION 'Unexpected role enum detected for seed users';
  END IF;
  
  RAISE NOTICE 'Successfully created % bootstrap seed users with valid roles and enabled status', v_count;
END $$;

-- Verify creation details
SELECT username, email, full_name, role, is_enabled, created_at FROM auth.users 
WHERE username IN ('business.admin', 'tech.bootstrap')
ORDER BY username;

-- Verify count
SELECT COUNT(*) AS total_bootstrap_seed_users FROM auth.users 
WHERE username IN ('business.admin', 'tech.bootstrap');

COMMIT;

-- ============================================================================
-- POST-SCRIPT SUMMARY
-- ============================================================================
-- Created Users: 2
--   1. business.admin (ADMIN role enum): Business-facing user management
--   2. tech.bootstrap (ADMIN role enum): Technical system configuration
--
-- User Role Assignments (to be done in 08_assign_users_to_roles.sql):
--   - business.admin → BUSINESS_ADMIN + BASIC_USER roles
--   - tech.bootstrap → TECHNICAL_BOOTSTRAP + BASIC_USER roles
--
-- Password Reference (see docs/user_pwd.md for full credential documentation):
--   - business.admin: Business!2025 (bcrypt: $2a$12$slYQmyNdGzin7olVN3p5Be0DlH.PKZbv5H8KnzzVgXXbVxzy990qm)
--   - tech.bootstrap: TechBoot!2025 (bcrypt: $2a$12$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E50Dmk0m.)
--
-- IMPORTANT: Update passwords immediately on first login in production!
--
-- Next Step: Run 08_assign_users_to_roles.sql to assign these users to roles.
-- ============================================================================
