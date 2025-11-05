-- ===============================================================
-- Add Missing User Management Endpoints
-- ===============================================================
-- This script adds the missing Edit User (PUT) and Delete User (DELETE)
-- endpoints to complete the user management CRUD operations.
--
-- Execution Date: $(date)
-- Database: labormanagement
-- Schema: auth
-- ===============================================================

-- Step 1: Register the new endpoints
-- ===============================================================
INSERT INTO auth.endpoints (service, version, method, path, description, is_active, created_at, updated_at)
VALUES
    ('AUTH', 'v1', 'PUT', '/api/auth/users/{userId}', 'Update user information', true, NOW(), NOW()),
    ('AUTH', 'v1', 'DELETE', '/api/auth/users/{userId}', 'Delete user (soft delete)', true, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Get the endpoint IDs (they will be 71 and 72 if this is the first run)
DO $$
DECLARE
    put_endpoint_id INTEGER;
    delete_endpoint_id INTEGER;
BEGIN
    -- Get the PUT endpoint ID
    SELECT id INTO put_endpoint_id
    FROM auth.endpoints
    WHERE method = 'PUT' AND path = '/api/auth/users/{userId}';
    
    -- Get the DELETE endpoint ID
    SELECT id INTO delete_endpoint_id
    FROM auth.endpoints
    WHERE method = 'DELETE' AND path = '/api/auth/users/{userId}';
    
    RAISE NOTICE 'PUT endpoint ID: %', put_endpoint_id;
    RAISE NOTICE 'DELETE endpoint ID: %', delete_endpoint_id;
    
    -- Step 2: Link endpoints to USER_ACCOUNT_MANAGE_POLICY
    -- ===============================================================
    INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
    VALUES
        (put_endpoint_id, 2),    -- USER_ACCOUNT_MANAGE_POLICY
        (delete_endpoint_id, 2)  -- USER_ACCOUNT_MANAGE_POLICY
    ON CONFLICT DO NOTHING;
    
    -- Step 3: Link page actions to the new endpoints
    -- ===============================================================
    -- Link "Edit User" action to PUT endpoint
    UPDATE auth.page_actions 
    SET endpoint_id = put_endpoint_id 
    WHERE id = 4 AND label = 'Edit User';
    
    -- Link "Delete User" action to DELETE endpoint
    UPDATE auth.page_actions 
    SET endpoint_id = delete_endpoint_id 
    WHERE id = 5 AND label = 'Delete User';
    
    RAISE NOTICE 'Successfully linked page actions to endpoints';
END $$;

-- Step 4: Verify the setup
-- ===============================================================
-- Check the complete authorization chain
SELECT 
    pa.id as action_id,
    pa.label as action_label,
    c.id as capability_id,
    c.name as capability_name,
    e.id as endpoint_id,
    e.method,
    e.path,
    STRING_AGG(DISTINCT p.name, ', ') as policies
FROM auth.page_actions pa
LEFT JOIN auth.capabilities c ON pa.capability_id = c.id
LEFT JOIN auth.endpoints e ON pa.endpoint_id = e.id
LEFT JOIN auth.policy_capabilities pc ON c.id = pc.capability_id
LEFT JOIN auth.policies p ON pc.policy_id = p.id
WHERE pa.id IN (4, 5)
GROUP BY pa.id, pa.label, c.id, c.name, e.id, e.method, e.path
ORDER BY pa.id;

-- Summary
-- ===============================================================
-- ✓ Registered 2 new endpoints (PUT and DELETE for /api/auth/users/{userId})
-- ✓ Linked both endpoints to USER_ACCOUNT_MANAGE_POLICY (policy_id=2)
-- ✓ Updated page_actions to link "Edit User" and "Delete User" to the new endpoints
-- ✓ Complete CRUD operations are now available:
--   - CREATE: POST /api/auth/users (endpoint_id=3)
--   - READ:   GET /api/auth/users (endpoint_id=5)
--   - UPDATE: PUT /api/auth/users/{userId} (endpoint_id=71)
--   - DELETE: DELETE /api/auth/users/{userId} (endpoint_id=72)
-- ===============================================================
