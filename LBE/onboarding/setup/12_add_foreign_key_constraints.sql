-- ===============================================================
-- Add Foreign Key Constraints for Referential Integrity
-- ===============================================================
-- This script adds all missing foreign key constraints to ensure
-- referential integrity across the auth schema.
--
-- Execution Date: 2025-11-03
-- Database: labormanagement
-- Schema: auth
-- ===============================================================

-- IMPORTANT: Run this only after all data is loaded and validated
-- Foreign keys will prevent orphaned records and enforce data consistency

SET search_path TO auth;

-- ===============================================================
-- 1. user_roles junction table
-- ===============================================================
ALTER TABLE auth.user_roles
    DROP CONSTRAINT IF EXISTS fk_user_roles_user,
    DROP CONSTRAINT IF EXISTS fk_user_roles_role;

ALTER TABLE auth.user_roles
    ADD CONSTRAINT fk_user_roles_user 
        FOREIGN KEY (user_id) 
        REFERENCES auth.users(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ADD CONSTRAINT fk_user_roles_role 
        FOREIGN KEY (role_id) 
        REFERENCES auth.roles(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE;

-- ===============================================================
-- 2. policy_capabilities junction table
-- ===============================================================
ALTER TABLE auth.policy_capabilities
    DROP CONSTRAINT IF EXISTS fk_policy_capabilities_policy,
    DROP CONSTRAINT IF EXISTS fk_policy_capabilities_capability;

ALTER TABLE auth.policy_capabilities
    ADD CONSTRAINT fk_policy_capabilities_policy 
        FOREIGN KEY (policy_id) 
        REFERENCES auth.policies(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ADD CONSTRAINT fk_policy_capabilities_capability 
        FOREIGN KEY (capability_id) 
        REFERENCES auth.capabilities(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE;

-- ===============================================================
-- 3. endpoint_policies junction table
-- ===============================================================
ALTER TABLE auth.endpoint_policies
    DROP CONSTRAINT IF EXISTS fk_endpoint_policies_endpoint,
    DROP CONSTRAINT IF EXISTS fk_endpoint_policies_policy;

ALTER TABLE auth.endpoint_policies
    ADD CONSTRAINT fk_endpoint_policies_endpoint 
        FOREIGN KEY (endpoint_id) 
        REFERENCES auth.endpoints(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ADD CONSTRAINT fk_endpoint_policies_policy 
        FOREIGN KEY (policy_id) 
        REFERENCES auth.policies(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE;

-- ===============================================================
-- 4. page_actions table
-- ===============================================================
ALTER TABLE auth.page_actions
    DROP CONSTRAINT IF EXISTS fk_page_actions_page,
    DROP CONSTRAINT IF EXISTS fk_page_actions_capability,
    DROP CONSTRAINT IF EXISTS fk_page_actions_endpoint;

ALTER TABLE auth.page_actions
    ADD CONSTRAINT fk_page_actions_page 
        FOREIGN KEY (page_id) 
        REFERENCES auth.ui_pages(id) 
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    ADD CONSTRAINT fk_page_actions_capability 
        FOREIGN KEY (capability_id) 
        REFERENCES auth.capabilities(id) 
        ON DELETE RESTRICT  -- Don't allow deleting capability if used in page actions
        ON UPDATE CASCADE,
    ADD CONSTRAINT fk_page_actions_endpoint 
        FOREIGN KEY (endpoint_id) 
        REFERENCES auth.endpoints(id) 
        ON DELETE SET NULL  -- Allow endpoint deletion, set to NULL in page actions
        ON UPDATE CASCADE;

-- ===============================================================
-- 5. ui_pages table (self-referential for hierarchy)
-- ===============================================================
ALTER TABLE auth.ui_pages
    DROP CONSTRAINT IF EXISTS fk_ui_pages_parent;

ALTER TABLE auth.ui_pages
    ADD CONSTRAINT fk_ui_pages_parent 
        FOREIGN KEY (parent_id) 
        REFERENCES auth.ui_pages(id) 
        ON DELETE SET NULL  -- If parent deleted, children become top-level
        ON UPDATE CASCADE;

-- ===============================================================
-- 6. user_tenant_acl table (already exists, verify)
-- ===============================================================
-- This constraint already exists from initial setup
-- Just verify it's correctly configured
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_schema = 'auth'
        AND table_name = 'user_tenant_acl'
        AND constraint_name = 'fk_acl_user'
    ) THEN
        ALTER TABLE auth.user_tenant_acl
            ADD CONSTRAINT fk_acl_user 
                FOREIGN KEY (user_id) 
                REFERENCES auth.users(id) 
                ON DELETE CASCADE
                ON UPDATE CASCADE;
    END IF;
END $$;

-- ===============================================================
-- 7. revoked_tokens table (if user_id exists)
-- ===============================================================
-- Check if revoked_tokens has user_id column
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'auth'
        AND table_name = 'revoked_tokens'
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE auth.revoked_tokens
            DROP CONSTRAINT IF EXISTS fk_revoked_tokens_user;
        
        ALTER TABLE auth.revoked_tokens
            ADD CONSTRAINT fk_revoked_tokens_user 
                FOREIGN KEY (user_id) 
                REFERENCES auth.users(id) 
                ON DELETE CASCADE
                ON UPDATE CASCADE;
    END IF;
END $$;

-- ===============================================================
-- Verification
-- ===============================================================
SELECT 
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table,
    ccu.column_name AS foreign_column,
    rc.delete_rule,
    rc.update_rule
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
JOIN information_schema.referential_constraints rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'auth'
ORDER BY tc.table_name, tc.constraint_name;

-- Summary
SELECT 
    COUNT(*) as total_foreign_keys,
    COUNT(DISTINCT tc.table_name) as tables_with_fks
FROM information_schema.table_constraints tc
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'auth';

-- ===============================================================
-- Expected Results:
-- ===============================================================
-- user_roles: 2 FKs (user_id → users, role_id → roles)
-- policy_capabilities: 2 FKs (policy_id → policies, capability_id → capabilities)
-- endpoint_policies: 2 FKs (endpoint_id → endpoints, policy_id → policies)
-- page_actions: 3 FKs (page_id → ui_pages, capability_id → capabilities, endpoint_id → endpoints)
-- ui_pages: 1 FK (parent_id → ui_pages)
-- user_tenant_acl: 1 FK (user_id → users)
-- Total: 11 foreign keys across 6 tables
-- ===============================================================

-- ===============================================================
-- Notes on DELETE/UPDATE Rules:
-- ===============================================================
-- CASCADE: When parent is deleted/updated, child records are automatically deleted/updated
-- RESTRICT: Prevents parent deletion if child records exist (must delete children first)
-- SET NULL: When parent is deleted, child foreign key is set to NULL
-- NO ACTION: Similar to RESTRICT but checks at end of transaction
--
-- Choices made:
-- - Junction tables: CASCADE (if parent is deleted, links should be deleted)
-- - page_actions.capability_id: RESTRICT (don't delete capabilities in use)
-- - page_actions.endpoint_id: SET NULL (allow endpoint deletion, UI can handle null)
-- - ui_pages.parent_id: SET NULL (deleted parent means top-level page)
-- ===============================================================
