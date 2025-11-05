-- ============================================================================
-- ONBOARDING PHASE 08: ASSIGN BOOTSTRAP USERS TO ROLES
-- ============================================================================
-- Purpose: Assign the bootstrap users created in phase 07 to their respective roles.
--
-- User-Role Assignments:
--   business.admin → BASIC_USER + BUSINESS_ADMIN
--   tech.bootstrap → BASIC_USER + TECHNICAL_BOOTSTRAP
--
-- Dependencies: Roles (01_create_roles.sql) and users (07_create_seed_users.sql) must exist first.
-- ============================================================================

SET search_path TO auth;
\set ON_ERROR_STOP on

BEGIN;

-- ============================================================================
-- BACKUP EXISTING DATA (with date suffix: 251201)
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_roles_251201 (LIKE user_roles INCLUDING ALL);
DELETE FROM user_roles_251201;
INSERT INTO user_roles_251201 SELECT * FROM user_roles 
WHERE user_id IN (SELECT id FROM users WHERE username IN ('business.admin', 'tech.bootstrap'));

-- Clear existing assignments for bootstrap users
DELETE FROM user_roles
WHERE user_id IN (
  SELECT id FROM users WHERE username IN ('business.admin', 'tech.bootstrap')
);

-- ============================================================================
-- ASSIGN BOOTSTRAP USERS TO THEIR ROLES
-- ============================================================================

-- business.admin assignments
INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW()
FROM users u
JOIN roles r ON r.name = 'BASIC_USER'
WHERE u.username = 'business.admin';

INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW()
FROM users u
JOIN roles r ON r.name = 'BUSINESS_ADMIN'
WHERE u.username = 'business.admin';

-- tech.bootstrap assignments
INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW()
FROM users u
JOIN roles r ON r.name = 'BASIC_USER'
WHERE u.username = 'tech.bootstrap';

INSERT INTO user_roles (user_id, role_id, assigned_at)
SELECT u.id, r.id, NOW()
FROM users u
JOIN roles r ON r.name = 'TECHNICAL_BOOTSTRAP'
WHERE u.username = 'tech.bootstrap';

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
  v_total_assignments INTEGER;
  v_business_admin_roles INTEGER;
  v_tech_bootstrap_roles INTEGER;
  v_role_misses INTEGER;
BEGIN
  -- Total assignments (2 users × 2 roles = 4)
  SELECT COUNT(*) INTO v_total_assignments
  FROM user_roles
  WHERE user_id IN (
    SELECT id FROM users WHERE username IN ('business.admin', 'tech.bootstrap')
  );

  IF v_total_assignments <> 4 THEN
    RAISE EXCEPTION 'Expected 4 user-role assignments (2 users × 2 roles), found %', v_total_assignments;
  END IF;

  -- business.admin should have exactly 2 roles
  SELECT COUNT(*) INTO v_business_admin_roles
  FROM user_roles ur
  JOIN users u ON ur.user_id = u.id
  WHERE u.username = 'business.admin';

  IF v_business_admin_roles <> 2 THEN
    RAISE EXCEPTION 'business.admin should have 2 roles, found %', v_business_admin_roles;
  END IF;

  -- tech.bootstrap should have exactly 2 roles
  SELECT COUNT(*) INTO v_tech_bootstrap_roles
  FROM user_roles ur
  JOIN users u ON ur.user_id = u.id
  WHERE u.username = 'tech.bootstrap';

  IF v_tech_bootstrap_roles <> 2 THEN
    RAISE EXCEPTION 'tech.bootstrap should have 2 roles, found %', v_tech_bootstrap_roles;
  END IF;

  -- Verify no role references point to missing roles
  SELECT COUNT(*) INTO v_role_misses
  FROM user_roles ur
  WHERE ur.user_id IN (
    SELECT id FROM users WHERE username IN ('business.admin', 'tech.bootstrap')
  )
  AND ur.role_id NOT IN (SELECT id FROM roles WHERE is_active = true);

  IF v_role_misses > 0 THEN
    RAISE EXCEPTION 'Detected % assignments referencing missing or inactive roles', v_role_misses;
  END IF;

  RAISE NOTICE '';
  RAISE NOTICE '✓ Bootstrap user-role assignments completed';
  RAISE NOTICE '  - business.admin: BASIC_USER + BUSINESS_ADMIN';
  RAISE NOTICE '  - tech.bootstrap: BASIC_USER + TECHNICAL_BOOTSTRAP';
  RAISE NOTICE '  - Total assignments: %', v_total_assignments;
END $$;

-- Display all bootstrap user-role assignments
SELECT 
  u.username AS user,
  r.name AS role,
  r.description,
  ur.assigned_at,
  r.is_active
FROM user_roles ur
JOIN users u ON ur.user_id = u.id
JOIN roles r ON ur.role_id = r.id
WHERE u.username IN ('business.admin', 'tech.bootstrap')
ORDER BY u.username, r.name;

COMMIT;

-- ============================================================================
-- POST-SCRIPT SUMMARY
-- ============================================================================
-- Bootstrap User-Role Assignments: 4 total (2 users × 2 roles)
-- 
-- Capabilities summary:
--   business.admin → BASIC_USER (authorization.api.access, service.catalog.read)
--                    BUSINESS_ADMIN (user.account.*, rbac.role.read, rbac.role.assign)
--   tech.bootstrap → BASIC_USER + TECHNICAL_BOOTSTRAP (full RBAC/UI/System configuration)
--
-- Next Step: Run 09_create_page_actions.sql to wire UI actions to capabilities and endpoints.
-- ============================================================================
