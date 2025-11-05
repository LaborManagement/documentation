-- ============================================================================
-- ONBOARDING PHASE 10: FIX SEED USER PASSWORDS
-- ============================================================================
-- Purpose: Ensure bootstrap users have deterministic bcrypt passwords (cost 12).
-- Dependencies: Users must exist from 07_create_seed_users.sql.
-- ============================================================================

SET search_path TO auth;
\set ON_ERROR_STOP on

BEGIN;

UPDATE auth.users
SET password = '$2a$12$slYQmyNdGzin7olVN3p5Be0DlH.PKZbv5H8KnzzVgXXbVxzy990qm',  -- Business!2025
    updated_at = NOW()
WHERE username = 'business.admin';

UPDATE auth.users
SET password = '$2a$12$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E50Dmk0m.',  -- TechBoot!2025
    updated_at = NOW()
WHERE username = 'tech.bootstrap';

COMMIT;

-- Verification
SELECT username, password 
FROM auth.users 
WHERE username IN ('business.admin', 'tech.bootstrap')
ORDER BY username;
