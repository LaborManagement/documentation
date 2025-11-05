-- ============================================================================
-- ONBOARDING PHASE 06: LINK ENDPOINTS TO POLICIES
-- ============================================================================
-- Purpose: Align registered endpoints with granular bootstrap policies.
-- Dependencies: 00_register_endpoints.sql, 04_create_policies.sql must run first.
-- Authorization Flow:
--   User → Roles → Policies → {Capabilities, Endpoints}
--   Endpoint access requires a matching policy for the caller's role(s).
--
-- Policy Mapping Overview:
--   - BASIC_USER_POLICY → authentication + metadata surfaces
--   - USER_ACCOUNT_MANAGE_POLICY → user lifecycle endpoints
--   - ROLE_* policies → split read / assignment / management endpoints
--   - CAPABILITY / POLICY / ENDPOINT / UI / ACTION policies → technical administration
-- ============================================================================

SET search_path TO auth;
\set ON_ERROR_STOP on

BEGIN;

-- Clear existing endpoint policy links
DELETE FROM endpoint_policies;

-- ============================================================================
-- HELPER FUNCTION: Safe endpoint-policy link insertion
-- ============================================================================
CREATE OR REPLACE FUNCTION safe_endpoint_policy_link(
  p_endpoint_method TEXT,
  p_endpoint_path TEXT,
  p_policy_name TEXT
)
RETURNS VOID AS $$
DECLARE
  v_endpoint_id BIGINT;
  v_policy_id BIGINT;
BEGIN
  -- Get endpoint ID with validation
  SELECT id INTO v_endpoint_id FROM endpoints 
  WHERE path = p_endpoint_path AND method = p_endpoint_method AND is_active = true;
  
  IF v_endpoint_id IS NULL THEN
    RAISE EXCEPTION 'Endpoint "% %" not found or inactive', p_endpoint_method, p_endpoint_path;
  END IF;
  
  -- Get policy ID with validation
  SELECT id INTO v_policy_id FROM policies 
  WHERE name = p_policy_name AND is_active = true;
  
  IF v_policy_id IS NULL THEN
    RAISE EXCEPTION 'Policy "%" not found or inactive', p_policy_name;
  END IF;
  
  -- Insert link
  INSERT INTO endpoint_policies (endpoint_id, policy_id)
  VALUES (v_endpoint_id, v_policy_id)
  ON CONFLICT (endpoint_id, policy_id) DO NOTHING;
  
EXCEPTION WHEN OTHERS THEN
  RAISE EXCEPTION 'Error linking endpoint "% %" to policy "%": %', 
    p_endpoint_method, p_endpoint_path, p_policy_name, SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- BASIC_USER_POLICY (Baseline access for all authenticated users)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/auth/login', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('POST', '/api/auth/logout', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/auth/ui-config', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/me/authorizations', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/meta/service-catalog', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/meta/endpoints', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/meta/pages', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('POST', '/internal/auth/introspect', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/internal/authz/endpoints/{endpointId}', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/internal/authz/users/{userId}/matrix', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('GET', '/internal/authz/endpoints/metadata', 'BASIC_USER_POLICY');
SELECT safe_endpoint_policy_link('POST', '/internal/authz/policies/evaluate', 'BASIC_USER_POLICY');

-- ============================================================================
-- USER_ACCOUNT_MANAGE_POLICY (User lifecycle operations)
-- ============================================================================
SELECT safe_endpoint_policy_link('GET', '/api/auth/users', 'USER_ACCOUNT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/auth/users/role/{role}', 'USER_ACCOUNT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/auth/users/{userId}/status', 'USER_ACCOUNT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/auth/users/{userId}/roles', 'USER_ACCOUNT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('POST', '/api/auth/users/{userId}/invalidate-tokens', 'USER_ACCOUNT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('POST', '/api/auth/users', 'USER_ACCOUNT_MANAGE_POLICY');

-- ============================================================================
-- ROLE_READ_POLICY (Role catalog visibility)
-- ============================================================================
SELECT safe_endpoint_policy_link('GET', '/api/auth/roles', 'ROLE_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/roles', 'ROLE_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/roles/with-permissions', 'ROLE_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/roles/{id}', 'ROLE_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/roles/by-name/{name}', 'ROLE_READ_POLICY');

-- ============================================================================
-- ROLE_ASSIGN_POLICY (Role assignment operations)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/admin/roles/assign', 'ROLE_ASSIGN_POLICY');
SELECT safe_endpoint_policy_link('POST', '/api/admin/roles/revoke', 'ROLE_ASSIGN_POLICY');

-- ============================================================================
-- ROLE_MANAGE_POLICY (Role creation and maintenance)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/admin/roles', 'ROLE_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/admin/roles/{id}', 'ROLE_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/roles/{id}', 'ROLE_MANAGE_POLICY');

-- ============================================================================
-- POLICY_READ_POLICY (Policy catalog visibility)
-- ============================================================================
SELECT safe_endpoint_policy_link('GET', '/api/admin/policies', 'POLICY_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/policies/{id}', 'POLICY_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/policies/{id}/capabilities', 'POLICY_READ_POLICY');

-- ============================================================================
-- POLICY_MANAGE_POLICY (Policy administration)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/admin/policies', 'POLICY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/admin/policies/{id}', 'POLICY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/policies/{id}', 'POLICY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PATCH', '/api/admin/policies/{id}/toggle-active', 'POLICY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('POST', '/api/admin/policies/{id}/capabilities', 'POLICY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/policies/{id}/capabilities/{capabilityId}', 'POLICY_MANAGE_POLICY');

-- ============================================================================
-- CAPABILITY_READ_POLICY (Capability catalog visibility)
-- ============================================================================
SELECT safe_endpoint_policy_link('GET', '/api/admin/capabilities', 'CAPABILITY_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/capabilities/{id}', 'CAPABILITY_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/meta/user-access-matrix/{user_id}', 'CAPABILITY_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/meta/ui-access-matrix/{page_id}', 'CAPABILITY_READ_POLICY');

-- ============================================================================
-- CAPABILITY_MANAGE_POLICY (Capability CRUD)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/admin/capabilities', 'CAPABILITY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/admin/capabilities/{id}', 'CAPABILITY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/capabilities/{id}', 'CAPABILITY_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PATCH', '/api/admin/capabilities/{id}/toggle-active', 'CAPABILITY_MANAGE_POLICY');

-- ============================================================================
-- ENDPOINT_READ_POLICY (Endpoint catalog visibility)
-- ============================================================================
SELECT safe_endpoint_policy_link('GET', '/api/admin/endpoints', 'ENDPOINT_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/endpoints/{id}', 'ENDPOINT_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/endpoints/{id}/policies', 'ENDPOINT_READ_POLICY');

-- ============================================================================
-- ENDPOINT_MANAGE_POLICY (Endpoint administration)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/admin/endpoints', 'ENDPOINT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/admin/endpoints/{id}', 'ENDPOINT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/endpoints/{id}', 'ENDPOINT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PATCH', '/api/admin/endpoints/{id}/toggle-active', 'ENDPOINT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('POST', '/api/admin/endpoints/{id}/policies', 'ENDPOINT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/endpoints/{id}/policies/{policyId}', 'ENDPOINT_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('POST', '/api/admin/endpoints/bulk-policy-assignment', 'ENDPOINT_MANAGE_POLICY');

-- ============================================================================
-- UI_PAGE_READ_POLICY (UI page catalog visibility)
-- ============================================================================
SELECT safe_endpoint_policy_link('GET', '/api/admin/ui-pages', 'UI_PAGE_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/ui-pages/all', 'UI_PAGE_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/ui-pages/{id}', 'UI_PAGE_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/ui-pages/{id}/children', 'UI_PAGE_READ_POLICY');

-- ============================================================================
-- UI_PAGE_MANAGE_POLICY (UI page administration)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/admin/ui-pages', 'UI_PAGE_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/admin/ui-pages/{id}', 'UI_PAGE_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/ui-pages/{id}', 'UI_PAGE_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PATCH', '/api/admin/ui-pages/{id}/toggle-active', 'UI_PAGE_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PATCH', '/api/admin/ui-pages/{id}/reorder', 'UI_PAGE_MANAGE_POLICY');

-- ============================================================================
-- UI_ACTION_READ_POLICY (Page action visibility)
-- ============================================================================
SELECT safe_endpoint_policy_link('GET', '/api/admin/page-actions', 'UI_ACTION_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/page-actions/{id}', 'UI_ACTION_READ_POLICY');
SELECT safe_endpoint_policy_link('GET', '/api/admin/page-actions/page/{pageId}', 'UI_ACTION_READ_POLICY');

-- ============================================================================
-- UI_ACTION_MANAGE_POLICY (Page action administration)
-- ============================================================================
SELECT safe_endpoint_policy_link('POST', '/api/admin/page-actions', 'UI_ACTION_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PUT', '/api/admin/page-actions/{id}', 'UI_ACTION_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('DELETE', '/api/admin/page-actions/{id}', 'UI_ACTION_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PATCH', '/api/admin/page-actions/{id}/toggle-active', 'UI_ACTION_MANAGE_POLICY');
SELECT safe_endpoint_policy_link('PATCH', '/api/admin/page-actions/{id}/reorder', 'UI_ACTION_MANAGE_POLICY');

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DO $$
DECLARE
  v_expected RECORD;
  v_actual INTEGER;
  v_total_links INTEGER;
  v_unassigned_endpoints INTEGER;
BEGIN
  -- Validate endpoint counts per policy
  FOR v_expected IN
    SELECT * FROM (
      VALUES
        ('BASIC_USER_POLICY', 12),
        ('USER_ACCOUNT_MANAGE_POLICY', 6),
        ('ROLE_READ_POLICY', 5),
        ('ROLE_ASSIGN_POLICY', 2),
        ('ROLE_MANAGE_POLICY', 3),
        ('POLICY_READ_POLICY', 3),
        ('POLICY_MANAGE_POLICY', 6),
        ('CAPABILITY_READ_POLICY', 4),
        ('CAPABILITY_MANAGE_POLICY', 4),
        ('ENDPOINT_READ_POLICY', 3),
        ('ENDPOINT_MANAGE_POLICY', 7),
        ('UI_PAGE_READ_POLICY', 4),
        ('UI_PAGE_MANAGE_POLICY', 5),
        ('UI_ACTION_READ_POLICY', 3),
        ('UI_ACTION_MANAGE_POLICY', 5)
    ) AS expected(policy_name, endpoint_count)
  LOOP
    SELECT COUNT(*) INTO v_actual
    FROM endpoint_policies ep
    JOIN policies p ON p.id = ep.policy_id
    WHERE p.name = v_expected.policy_name;

    IF v_actual <> v_expected.endpoint_count THEN
      RAISE EXCEPTION 'Policy % has % endpoints linked (expected %)',
        v_expected.policy_name, v_actual, v_expected.endpoint_count;
    END IF;
  END LOOP;

  -- Total verification
  SELECT COUNT(*) INTO v_total_links FROM endpoint_policies;
  IF v_total_links <> 72 THEN
    RAISE EXCEPTION 'Expected 72 endpoint-policy links, found %', v_total_links;
  END IF;

  -- Ensure no active endpoint is left without a policy
  SELECT COUNT(*) INTO v_unassigned_endpoints
  FROM endpoints e
  WHERE e.is_active = true
    AND NOT EXISTS (
      SELECT 1 FROM endpoint_policies ep
      WHERE ep.endpoint_id = e.id
    );

  IF v_unassigned_endpoints <> 0 THEN
    RAISE EXCEPTION 'Found % active endpoints without policies', v_unassigned_endpoints;
  END IF;

  RAISE NOTICE '✓ Endpoint-policy linking completed: % total links', v_total_links;
END $$;

-- Display assignment summary
SELECT 
  p.name as policy_name,
  COUNT(ep.endpoint_id) as endpoint_count
FROM policies p
LEFT JOIN endpoint_policies ep ON p.id = ep.policy_id
WHERE p.is_active = true
GROUP BY p.id, p.name
ORDER BY policy_name;

COMMIT;

-- ============================================================================
-- POST-SCRIPT SUMMARY
-- ============================================================================
-- Endpoint-Policy Links: 72 total across 15 bootstrap policies.
--
-- Highlights:
--   - BASIC_USER retains auth + metadata access only.
--   - BUSINESS_ADMIN derives user lifecycle + role read/assign endpoints.
--   - TECHNICAL_BOOTSTRAP inherits all admin surfaces via specialized policies.
--   - Verification enforces per-policy counts and ensures zero orphaned endpoints.
--
-- Seed execution order reminder:
--   00_register_endpoints → 01_create_roles → 03_create_capabilities
--   → 04_create_policies → 05_link_policies_to_capabilities → 06_link_endpoints_to_policies.
-- ============================================================================
