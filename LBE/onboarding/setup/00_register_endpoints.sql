-- ============================================================================
-- ONBOARDING PHASE 00: REGISTER ALL ENDPOINTS
-- ============================================================================
-- Purpose: Pre-register all API endpoints before creating roles, policies, or users.
-- This script MUST run first so downstream scripts can enforce FK relationships.
-- ============================================================================

SET search_path TO auth;
\set ON_ERROR_STOP on

BEGIN;

-- ============================================================================
-- BACKUP EXISTING DATA (with date suffix: 251201)
-- ============================================================================
CREATE TABLE IF NOT EXISTS endpoint_policies_251201 (LIKE endpoint_policies INCLUDING ALL);
DELETE FROM endpoint_policies_251201;
INSERT INTO endpoint_policies_251201 SELECT * FROM endpoint_policies;

CREATE TABLE IF NOT EXISTS endpoints_251201 (LIKE endpoints INCLUDING ALL);
DELETE FROM endpoints_251201;
INSERT INTO endpoints_251201 SELECT * FROM endpoints;

-- Clear existing endpoints and dependent data
DELETE FROM endpoint_policies WHERE endpoint_id IN (SELECT id FROM endpoints);
DELETE FROM endpoints;
ALTER SEQUENCE endpoints_id_seq RESTART WITH 1;

-- ============================================================================
-- AUTH ENDPOINTS (/api/auth/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('auth', 'v1', 'POST', '/api/auth/login', 'User login with credentials', 'FORM', true, NOW(), NOW()),
('auth', 'v1', 'POST', '/api/auth/logout', 'User logout', 'FORM', true, NOW(), NOW()),
('auth', 'v1', 'POST', '/api/auth/users', 'Create new user account', 'FORM', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/auth/ui-config', 'Get UI configuration for logged-in user', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/auth/users', 'Get all users', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/auth/users/role/{role}', 'Get users by role', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'PUT', '/api/auth/users/{userId}/status', 'Enable/disable user account', 'FORM', true, NOW(), NOW()),
('auth', 'v1', 'PUT', '/api/auth/users/{userId}/roles', 'Update user roles', 'FORM', true, NOW(), NOW()),
('auth', 'v1', 'POST', '/api/auth/users/{userId}/invalidate-tokens', 'Invalidate all user tokens', 'FORM', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/auth/roles', 'Get all available roles', 'LIST', true, NOW(), NOW());

-- ============================================================================
-- ADMIN: ROLE MANAGEMENT ENDPOINTS (/api/admin/roles/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('admin', 'v1', 'GET', '/api/admin/roles', 'List all roles', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/roles/with-permissions', 'Get roles with permission counts', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/roles/{id}', 'Get role by ID', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/roles/by-name/{name}', 'Get role by name', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/roles', 'Create new role', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PUT', '/api/admin/roles/{id}', 'Update role', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/roles/{id}', 'Delete role', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/roles/assign', 'Assign role to user', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/roles/revoke', 'Revoke role from user', 'FORM', true, NOW(), NOW());

-- ============================================================================
-- ADMIN: POLICY MANAGEMENT ENDPOINTS (/api/admin/policies/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('admin', 'v1', 'GET', '/api/admin/policies', 'List all policies', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/policies/{id}', 'Get policy by ID', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/policies', 'Create new policy', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PUT', '/api/admin/policies/{id}', 'Update policy', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/policies/{id}', 'Delete policy', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PATCH', '/api/admin/policies/{id}/toggle-active', 'Toggle policy active status', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/policies/{id}/capabilities', 'Get capabilities for policy', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/policies/{id}/capabilities', 'Add capability to policy', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/policies/{id}/capabilities/{capabilityId}', 'Remove capability from policy', 'FORM', true, NOW(), NOW());

-- ============================================================================
-- ADMIN: CAPABILITY MANAGEMENT ENDPOINTS (/api/admin/capabilities/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('admin', 'v1', 'GET', '/api/admin/capabilities', 'List all capabilities', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/capabilities/{id}', 'Get capability by ID', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/capabilities', 'Create new capability', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PUT', '/api/admin/capabilities/{id}', 'Update capability', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/capabilities/{id}', 'Delete capability', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PATCH', '/api/admin/capabilities/{id}/toggle-active', 'Toggle capability active status', 'FORM', true, NOW(), NOW());

-- ============================================================================
-- ADMIN: ENDPOINT MANAGEMENT ENDPOINTS (/api/admin/endpoints/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('admin', 'v1', 'GET', '/api/admin/endpoints', 'List all endpoints', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/endpoints/{id}', 'Get endpoint by ID', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/endpoints', 'Create new endpoint', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PUT', '/api/admin/endpoints/{id}', 'Update endpoint', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/endpoints/{id}', 'Delete endpoint', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PATCH', '/api/admin/endpoints/{id}/toggle-active', 'Toggle endpoint active status', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/endpoints/{id}/policies', 'Get policies for endpoint', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/endpoints/{id}/policies', 'Link policy to endpoint', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/endpoints/{id}/policies/{policyId}', 'Unlink policy from endpoint', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/endpoints/bulk-policy-assignment', 'Bulk assign policies to endpoints', 'FORM', true, NOW(), NOW());

-- ============================================================================
-- ADMIN: UI PAGE MANAGEMENT ENDPOINTS (/api/admin/ui-pages/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('admin', 'v1', 'GET', '/api/admin/ui-pages', 'List UI pages', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/ui-pages/all', 'Get all UI pages hierarchical', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/ui-pages/{id}', 'Get UI page by ID', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/ui-pages', 'Create new UI page', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PUT', '/api/admin/ui-pages/{id}', 'Update UI page', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/ui-pages/{id}', 'Delete UI page', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PATCH', '/api/admin/ui-pages/{id}/toggle-active', 'Toggle UI page active status', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PATCH', '/api/admin/ui-pages/{id}/reorder', 'Reorder UI pages', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/ui-pages/{id}/children', 'Get child pages', 'LIST', true, NOW(), NOW());

-- ============================================================================
-- ADMIN: PAGE ACTION MANAGEMENT ENDPOINTS (/api/admin/page-actions/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('admin', 'v1', 'GET', '/api/admin/page-actions', 'List page actions', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/page-actions/{id}', 'Get page action by ID', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'GET', '/api/admin/page-actions/page/{pageId}', 'Get actions for page', 'LIST', true, NOW(), NOW()),
('admin', 'v1', 'POST', '/api/admin/page-actions', 'Create new page action', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PUT', '/api/admin/page-actions/{id}', 'Update page action', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'DELETE', '/api/admin/page-actions/{id}', 'Delete page action', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PATCH', '/api/admin/page-actions/{id}/toggle-active', 'Toggle page action active status', 'FORM', true, NOW(), NOW()),
('admin', 'v1', 'PATCH', '/api/admin/page-actions/{id}/reorder', 'Reorder page actions', 'FORM', true, NOW(), NOW());

-- ============================================================================
-- AUTHORIZATION/METADATA ENDPOINTS (/api/me/*, /api/meta/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('auth', 'v1', 'GET', '/api/me/authorizations', 'Get current user authorizations', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/meta/service-catalog', 'Get service catalog', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/meta/endpoints', 'Get endpoints metadata', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/meta/pages', 'Get UI pages metadata', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/meta/user-access-matrix/{user_id}', 'Get RBAC matrix for a user', 'LIST', true, NOW(), NOW()),
('auth', 'v1', 'GET', '/api/meta/ui-access-matrix/{page_id}', 'Get UI access matrix for a page', 'LIST', true, NOW(), NOW());

-- ============================================================================
-- INTERNAL ENDPOINTS (/internal/auth/*, /internal/authz/*)
-- ============================================================================
INSERT INTO endpoints (service, version, method, path, description, ui_type, is_active, created_at, updated_at) VALUES
('internal', 'v1', 'POST', '/internal/auth/introspect', 'Internal: Token introspection', 'FORM', true, NOW(), NOW()),
('internal', 'v1', 'GET', '/internal/authz/endpoints/{endpointId}', 'Internal: Get endpoint policies', 'LIST', true, NOW(), NOW()),
('internal', 'v1', 'GET', '/internal/authz/users/{userId}/matrix', 'Internal: Get user authorization matrix', 'LIST', true, NOW(), NOW()),
('internal', 'v1', 'GET', '/internal/authz/endpoints/metadata', 'Internal: Get endpoints metadata', 'LIST', true, NOW(), NOW()),
('internal', 'v1', 'POST', '/internal/authz/policies/evaluate', 'Internal: Evaluate policies', 'FORM', true, NOW(), NOW());

-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT 
  service,
  version,
  method,
  path,
  description,
  ui_type,
  is_active,
  created_at
FROM endpoints
ORDER BY service, path
LIMIT 100;

-- Count by service
SELECT 
  service,
  COUNT(*) as endpoint_count
FROM endpoints
WHERE is_active = true
GROUP BY service
ORDER BY service;

COMMIT;

-- ============================================================================
-- POST-SCRIPT SUMMARY
-- ============================================================================
-- Expected Endpoints Created: ~65 total
-- 
-- Distribution by Service:
--   - auth: 15 endpoints (login, logout, users, roles, authorizations, metadata)
--   - admin: 42 endpoints (roles, policies, capabilities, endpoints, ui-pages, page-actions)
--   - internal: 5 endpoints (token introspection, policy evaluation, authorization matrix)
--
-- All endpoints are marked as is_active=true and ready for policy assignment.
--
-- Next Step: Run 01_create_roles.sql to create the bootstrap roles.
-- ============================================================================
