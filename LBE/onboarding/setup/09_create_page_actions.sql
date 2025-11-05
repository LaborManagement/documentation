-- ============================================================================
-- ONBOARDING PHASE 09: CREATE PAGE ACTIONS
-- ============================================================================
-- Purpose: Map UI navigation actions to capabilities so RBAC rules flow to the UI.
-- Dependencies: 02_create_ui_pages.sql, 03_create_capabilities.sql.
-- ============================================================================

SET search_path TO auth;
\set ON_ERROR_STOP on

BEGIN;

-- =========================================================================
-- BACKUP EXISTING DATA (with date suffix: 251201)
-- =========================================================================
CREATE TABLE IF NOT EXISTS page_actions_251201 (LIKE page_actions INCLUDING ALL);
DELETE FROM page_actions_251201;
INSERT INTO page_actions_251201 SELECT * FROM page_actions;

-- Reset page actions
DELETE FROM page_actions;
ALTER SEQUENCE page_actions_id_seq RESTART WITH 1;

-- Helper macro implemented via repeated pattern
-- Each section joins capability catalog by capability name.

-- Dashboard
WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'dashboard'),
     cap  AS (SELECT id FROM capabilities WHERE name = 'service.catalog.read')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT 'View Dashboard', 'read', page.id, cap.id, 1, true, NOW(), NOW(), 'home', 'default'
FROM page, cap;

-- Reusable insert helper using VALUES
WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'user-mgmt')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'Create User',  'create', 'user.account.create',  'plus',   'success'),
    (2, 'View Users',   'read',   'user.account.read',    'eye',    'default'),
    (3, 'Edit User',    'update', 'user.account.update',  'edit',   'info'),
    (4, 'Delete User',  'delete', 'user.account.delete',  'trash',  'danger'),
    (5, 'Toggle Status','toggle', 'user.status.toggle',   'power',  'warning')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'role-mgmt')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'View Roles',   'read',   'rbac.role.read',   'eye',        'default'),
    (2, 'Create Roles', 'create', 'rbac.role.create', 'plus',       'success'),
    (3, 'Edit Roles',   'update', 'rbac.role.update', 'edit',       'info'),
    (4, 'Delete Roles', 'delete', 'rbac.role.delete', 'trash',      'danger'),
    (5, 'Assign Roles', 'assign', 'rbac.role.assign', 'user-plus',  'warning'),
    (6, 'Revoke Roles', 'revoke', 'rbac.role.revoke', 'user-minus', 'warning')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'policy-mgmt')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'View Policies',   'read',   'rbac.policy.read',             'eye',    'default'),
    (2, 'Create Policy',   'create', 'rbac.policy.create',           'plus',   'success'),
    (3, 'Edit Policy',     'update', 'rbac.policy.update',           'edit',   'info'),
    (4, 'Delete Policy',   'delete', 'rbac.policy.delete',           'trash',  'danger'),
    (5, 'Toggle Policy',   'toggle', 'rbac.policy.toggle',           'power',  'warning'),
    (6, 'Link Capability', 'link',   'rbac.policy.link-capability',  'link',   'info'),
    (7, 'Unlink Capability','unlink','rbac.policy.unlink-capability','unlink', 'info')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'capability-mgmt')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'View Capabilities', 'read',   'rbac.capability.read',        'eye',   'default'),
    (2, 'Create Capability', 'create', 'rbac.capability.create',      'plus',  'success'),
    (3, 'Edit Capability',   'update', 'rbac.capability.update',      'edit',  'info'),
    (4, 'Delete Capability', 'delete', 'rbac.capability.delete',      'trash', 'danger'),
    (5, 'Toggle Capability', 'toggle', 'rbac.capability.toggle',      'power', 'warning'),
    (6, 'View Matrix',       'read',   'rbac.capability.read-matrix', 'table', 'info')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'endpoint-mgmt')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'View Endpoints',  'read',   'rbac.endpoint.read',        'eye',   'default'),
    (2, 'Create Endpoint', 'create', 'rbac.endpoint.create',      'plus',  'success'),
    (3, 'Edit Endpoint',   'update', 'rbac.endpoint.update',      'edit',  'info'),
    (4, 'Delete Endpoint', 'delete', 'rbac.endpoint.delete',      'trash', 'danger'),
    (5, 'Toggle Endpoint', 'toggle', 'rbac.endpoint.toggle',      'power', 'warning'),
    (6, 'Link Policy',     'link',   'rbac.endpoint.link-policy', 'link',  'info'),
    (7, 'Unlink Policy',   'unlink', 'rbac.endpoint.unlink-policy','unlink','info')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'ui-pages')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'View Pages',       'read',   'ui.page.read',             'eye',   'default'),
    (2, 'Create Page',      'create', 'ui.page.create',           'plus',  'success'),
    (3, 'Edit Page',        'update', 'ui.page.update',           'edit',  'info'),
    (4, 'Delete Page',      'delete', 'ui.page.delete',           'trash', 'danger'),
    (5, 'Toggle Page',      'toggle', 'ui.page.toggle',           'power', 'warning'),
    (6, 'Reorder Pages',    'reorder','ui.page.reorder',          'sort',  'info'),
    (7, 'View Children',    'read',   'ui.page.read-children',    'tree',  'info'),
    (8, 'Manage Hierarchy', 'manage', 'ui.page.manage-hierarchy', 'layers','info')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'ui-actions')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'View Actions',    'read',   'ui.action.read',        'eye',   'default'),
    (2, 'Create Action',   'create', 'ui.action.create',      'plus',  'success'),
    (3, 'Edit Action',     'update', 'ui.action.update',      'edit',  'info'),
    (4, 'Delete Action',   'delete', 'ui.action.delete',      'trash', 'danger'),
    (5, 'Toggle Action',   'toggle', 'ui.action.toggle',      'power', 'warning'),
    (6, 'Reorder Actions', 'reorder','ui.action.reorder',     'sort',  'info'),
    (7, 'Actions by Page', 'read',   'ui.action.read-by-page','list',  'info')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

WITH page AS (SELECT id FROM ui_pages WHERE page_id = 'system-ops')
INSERT INTO page_actions (label, action, page_id, capability_id, display_order, is_active, created_at, updated_at, icon, variant)
SELECT defs.label, defs.action, page.id, cap.id, defs.display_order, true, NOW(), NOW(), defs.icon, defs.variant
FROM page
JOIN (
  VALUES
    (1, 'View Audit Logs',   'read',   'system.audit.read',            'file-text', 'default'),
    (2, 'Filter Audit Logs', 'filter', 'system.audit.filter',          'filter',    'info'),
    (3, 'Export Audit Logs', 'export', 'system.audit.export',          'download',  'success'),
    (4, 'View Settings',     'read',   'system.settings.read',         'settings',  'default'),
    (5, 'Update Settings',   'update', 'system.settings.update',       'settings',  'warning'),
    (6, 'Ingestion Status',  'read',   'system.ingestion.read-status', 'activity',  'info'),
    (7, 'Trigger MT940',     'trigger','system.ingestion.trigger-mt940','play',     'success'),
    (8, 'Trigger VAN',       'trigger','system.ingestion.trigger-van', 'play',      'success')
) AS defs(display_order, label, action, capability_name, icon, variant)
JOIN LATERAL (SELECT id FROM capabilities WHERE name = defs.capability_name) cap ON true;

-- =========================================================================
-- VERIFICATION
-- =========================================================================
DO $$
DECLARE
  v_total INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_total FROM page_actions;
  IF v_total <> 55 THEN
    RAISE EXCEPTION 'Expected 55 page actions, found %', v_total;
  END IF;
  RAISE NOTICE 'Successfully created % page actions.', v_total;
END $$;

SELECT pa.id, pa.label, up.page_id AS page, c.name AS capability
FROM page_actions pa
JOIN ui_pages up ON up.id = pa.page_id
JOIN capabilities c ON c.id = pa.capability_id
ORDER BY up.page_id, pa.display_order;

COMMIT;

-- =========================================================================
-- POST-SCRIPT SUMMARY
-- =========================================================================
-- Page actions now enforce capability checks across dashboard, administration,
-- UI configuration, and system operations.
-- =========================================================================
