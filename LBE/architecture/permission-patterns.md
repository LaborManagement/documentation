# Common Permission Patterns

**Navigation:** Previous: [Policy Binding](policy-binding.md) → Next: [Troubleshooting Guide](../playbooks/troubleshoot-auth.md)

This guide shows real-world patterns for setting up common permission scenarios using the simplified policy-based authorization model.

## Pattern 1: Read-Only Viewer Role

### **Scenario**
Users who can view data but cannot modify anything.

### **Setup**

```sql
-- 1. Create VIEWER role
INSERT INTO auth.roles (name, description, is_active, created_at, updated_at)
VALUES ('VIEWER', 'Read-only access to dashboards and reports', true, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- 2. Create VIEWER_POLICY
INSERT INTO auth.policies (name, description, is_active, created_at, updated_at)
VALUES ('VIEWER_POLICY', 'Grants read-only access to endpoints', true, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- 3. Link role to policy
INSERT INTO auth.role_policies (role_id, policy_id, created_at)
SELECT r.id, p.id, NOW()
FROM auth.roles r, auth.policies p
WHERE r.name = 'VIEWER' AND p.name = 'VIEWER_POLICY'
ON CONFLICT (role_id, policy_id) DO NOTHING;

-- 4. Register read-only endpoints
INSERT INTO auth.endpoints (method, path, label, description, is_active, created_at, updated_at)
VALUES 
  ('GET', '/api/payments', 'List payments', 'Fetch all payments', true, NOW(), NOW()),
  ('GET', '/api/payments/:id', 'Get payment', 'Fetch single payment', true, NOW(), NOW()),
  ('GET', '/api/reports', 'List reports', 'Fetch all reports', true, NOW(), NOW()),
  ('GET', '/api/audit-logs', 'View audit logs', 'Fetch audit logs', true, NOW(), NOW())
ON CONFLICT (method, path) DO NOTHING;

-- 5. Link endpoints directly to policy
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id, created_at)
SELECT e.id, p.id, NOW()
FROM auth.endpoints e, auth.policies p
WHERE e.path IN ('/api/payments', '/api/payments/:id', '/api/reports', '/api/audit-logs')
  AND e.method = 'GET'
  AND p.name = 'VIEWER_POLICY'
ON CONFLICT (endpoint_id, policy_id) DO NOTHING;
```

### **Verification**

```sql
-- Verify VIEWER role has correct endpoint access
SELECT r.name as role, p.name as policy, e.method, e.path
FROM auth.roles r
JOIN auth.role_policies rp ON r.id = rp.role_id
JOIN auth.policies p ON rp.policy_id = p.id
JOIN auth.endpoint_policies ep ON p.id = ep.policy_id
JOIN auth.endpoints e ON ep.endpoint_id = e.id
WHERE r.name = 'VIEWER'
ORDER BY e.method, e.path;
```

### **API Usage**

```bash
# Create VIEWER role via API
curl -X POST http://localhost:8080/api/admin/roles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "VIEWER",
    "description": "Read-only access to dashboards and reports"
  }'

# Assign user to VIEWER role
curl -X POST http://localhost:8080/api/admin/users/{userId}/roles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "roleIds": [3]
  }'
```

---

## Pattern 2: Progressive Permissions (Viewer → Editor → Admin)

### **Scenario**
Users progress through role hierarchy with increasing permissions.

### **Hierarchy**
```
VIEWER (read-only)
  ↓
EDITOR (read + write)
  ↓
ADMIN (read + write + delete + manage)
```

### **Setup**

```sql
-- Create three roles
INSERT INTO auth.roles (name, description) VALUES
  ('VIEWER', 'Read-only access'),
  ('EDITOR', 'Read and write access'),
  ('ADMIN', 'Full administrative access');

-- Create three policies (one per permission level)
INSERT INTO auth.policies (name, description) VALUES
  ('VIEWER_POLICY', 'Read-only access to resources'),
  ('EDITOR_POLICY', 'Read and write access to resources'),
  ('ADMIN_POLICY', 'Full administrative access including delete');

-- Link roles to policies
INSERT INTO auth.role_policies (role_id, policy_id)
SELECT r.id, p.id
FROM auth.roles r, auth.policies p
WHERE (r.name = 'VIEWER' AND p.name = 'VIEWER_POLICY')
   OR (r.name = 'EDITOR' AND p.name = 'EDITOR_POLICY')
   OR (r.name = 'ADMIN' AND p.name = 'ADMIN_POLICY');

-- Register endpoints at each tier
INSERT INTO auth.endpoints (method, path, label) VALUES
  -- Read tier
  ('GET', '/api/resources', 'List resources'),
  ('GET', '/api/resources/:id', 'Get resource'),
  
  -- Write tier
  ('POST', '/api/resources', 'Create resource'),
  ('PUT', '/api/resources/:id', 'Update resource'),
  
  -- Admin tier
  ('DELETE', '/api/resources/:id', 'Delete resource'),
  ('GET', '/api/admin/roles', 'Manage roles'),
  ('POST', '/api/admin/policies', 'Manage policies');

-- Link endpoints to appropriate policies
-- VIEWER_POLICY: Read-only endpoints
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id
FROM auth.endpoints e, auth.policies p
WHERE e.method = 'GET' 
  AND e.path IN ('/api/resources', '/api/resources/:id')
  AND p.name = 'VIEWER_POLICY';

-- EDITOR_POLICY: All VIEWER endpoints plus write operations
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id
FROM auth.endpoints e, auth.policies p
WHERE (
  (e.method = 'GET' AND e.path IN ('/api/resources', '/api/resources/:id'))
  OR (e.method IN ('POST', 'PUT') AND e.path LIKE '/api/resources%')
) AND p.name = 'EDITOR_POLICY';

-- ADMIN_POLICY: All endpoints including delete and admin routes
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id
FROM auth.endpoints e, auth.policies p
WHERE p.name = 'ADMIN_POLICY';
```

### **Permission Matrix**

| Endpoint | Method | VIEWER | EDITOR | ADMIN |
|----------|--------|--------|--------|-------|
| /api/resources | GET | ✅ | ✅ | ✅ |
| /api/resources | POST | ❌ | ✅ | ✅ |
| /api/resources/:id | PUT | ❌ | ✅ | ✅ |
| /api/resources/:id | DELETE | ❌ | ❌ | ✅ |
| /api/admin/roles | GET | ❌ | ❌ | ✅ |
| /api/admin/policies | POST | ❌ | ❌ | ✅ |

---

## Pattern 3: Organization-Based Scoping (Multi-Tenant)

### **Scenario**
Same permission structure, but scoped to organization (via RLS).

### **Setup**

```sql
-- Create roles (same for all orgs)
INSERT INTO auth.roles (name, description) VALUES
  ('ORG_VIEWER', 'Viewer within organization'),
  ('ORG_EDITOR', 'Editor within organization'),
  ('ORG_ADMIN', 'Admin within organization');

-- Create policies for organization-level access
INSERT INTO auth.policies (name, description) VALUES
  ('ORG_READ_POLICY', 'Organization read access'),
  ('ORG_WRITE_POLICY', 'Organization write access'),
  ('ORG_ADMIN_POLICY', 'Organization admin access');

-- Assign roles to policies
INSERT INTO auth.role_policies (role_id, policy_id)
SELECT r.id, p.id
FROM auth.roles r, auth.policies p
WHERE (r.name = 'ORG_VIEWER' AND p.name = 'ORG_READ_POLICY')
   OR (r.name = 'ORG_EDITOR' AND p.name = 'ORG_WRITE_POLICY')
   OR (r.name = 'ORG_ADMIN' AND p.name = 'ORG_ADMIN_POLICY');

-- Link policies to organization-scoped endpoints
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id
FROM auth.endpoints e, auth.policies p
WHERE e.path LIKE '/api/org/%';

-- RLS: User can only see data from their organization
-- This is enforced by auth.user_tenant_acl in the WHERE clause
```

### **RLS Protection**

```sql
-- Set user context before querying
SELECT auth.set_user_context('user-123');

-- Now query only returns rows for user's org
SELECT * FROM payment_requests
WHERE organization_id = (
  SELECT organization_id FROM auth.user_tenant_acl
  WHERE user_id = current_user_id()
);
```

---

## Pattern 4: Time-Bounded Permissions

### **Scenario**
Permissions that are temporarily elevated (e.g., on-call engineer).

### **Setup**

```sql
-- Create time-bound role
INSERT INTO auth.roles (name, description, effective_from, effective_until)
VALUES 
  ('ONCALL_ENGINEER', 
   'Temporary elevated access for on-call engineer', 
   NOW(),
   NOW() + INTERVAL '1 week');

-- Create temporary policy
INSERT INTO auth.policies (name, description, effective_from, effective_until)
VALUES
  ('ONCALL_EMERGENCY_POLICY',
   'Emergency access (valid only during on-call shift)',
   NOW(),
   NOW() + INTERVAL '1 week');

-- Link and verify
SELECT NOW() < r.effective_until as is_active
FROM auth.roles r
WHERE r.name = 'ONCALL_ENGINEER';
```

---

## Pattern 5: Policy Inheritance via Shared Policies

### **Scenario**
Multiple roles sharing the same policies without duplication.

### **Diagram**

```mermaid
graph TD
    R1["EMPLOYEE"] --> P1["SHARED_BASE_POLICY"]
    R2["CONTRACTOR"] --> P1
    R3["PARTNER"] --> P1
    
    P1 --> E1["GET /api/payments"]
    P1 --> E2["GET /api/audit-logs"]
    P1 --> E3["GET /api/reports"]
    
    R1 --> P2["EMPLOYEE_EXTRA"]
    P2 --> E4["POST /api/payments"]
    
    R2 --> P3["CONTRACTOR_EXTRA"]
    P3 --> E5["POST /api/invoices"]
```

### **Setup**

```sql
-- Create shared policy for common endpoints
INSERT INTO auth.policies (name, description)
VALUES ('SHARED_BASE_POLICY', 'Common read access for all external roles');

-- Create role-specific policies
INSERT INTO auth.policies (name, description)
VALUES 
  ('EMPLOYEE_EXTRA', 'Employee-specific additions'),
  ('CONTRACTOR_EXTRA', 'Contractor-specific additions');

-- Add roles
INSERT INTO auth.roles (name) VALUES ('EMPLOYEE'), ('CONTRACTOR'), ('PARTNER');

-- All three roles get SHARED_BASE_POLICY
INSERT INTO auth.role_policies (role_id, policy_id)
SELECT r.id, p.id
FROM auth.roles r, auth.policies p
WHERE r.name IN ('EMPLOYEE', 'CONTRACTOR', 'PARTNER')
  AND p.name = 'SHARED_BASE_POLICY';

-- Add role-specific policies
INSERT INTO auth.role_policies (role_id, policy_id)
SELECT r.id, p.id
FROM auth.roles r, auth.policies p
WHERE (r.name = 'EMPLOYEE' AND p.name = 'EMPLOYEE_EXTRA')
   OR (r.name = 'CONTRACTOR' AND p.name = 'CONTRACTOR_EXTRA');

-- Link shared policy to common endpoints
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id
FROM auth.endpoints e, auth.policies p
WHERE e.method = 'GET'
  AND e.path IN ('/api/payments', '/api/audit-logs', '/api/reports')
  AND p.name = 'SHARED_BASE_POLICY';

-- Link role-specific policies to their endpoints
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id
FROM auth.endpoints e, auth.policies p
WHERE (e.path = '/api/payments' AND e.method = 'POST' AND p.name = 'EMPLOYEE_EXTRA')
   OR (e.path = '/api/invoices' AND e.method = 'POST' AND p.name = 'CONTRACTOR_EXTRA');
```

### **Result**
- EMPLOYEE gets: SHARED_BASE + EMPLOYEE_EXTRA (read all + submit payments)
- CONTRACTOR gets: SHARED_BASE + CONTRACTOR_EXTRA (read all + create invoices)
- PARTNER gets: SHARED_BASE only (read all)

---

## Troubleshooting Permission Patterns

### **"User can't access endpoint"**

1. Verify user's role → check `auth.user_roles`
2. Verify role's policy → check `auth.role_policies`
3. Verify policy's endpoints → check `auth.endpoint_policies`
4. Verify endpoint is registered → check `auth.endpoints`
5. If all match, check RLS → verify `auth.user_tenant_acl`

### **"Multiple roles give conflicting permissions"**

A user with both VIEWER and EDITOR roles will have the **union** of policies:
- User gets: (VIEWER policies) + (EDITOR policies)
- Most permissive policy wins
- Authorization succeeds if ANY of the user's policies grant access to the endpoint

### **"Performance degraded after adding many policies"**

- Cache the entire permission matrix per user after login
- Refresh every 5-10 minutes or on explicit update
- Use database indexes on `user_id`, `role_id`, `policy_id`, `endpoint_id`
- Consider materialized views for complex policy lookups

---

## Next Steps

- Apply these patterns to your specific domain
- See [RBAC Setup Playbook](../guides/setup/rbac.md) for step-by-step implementation
- Review [Troubleshooting Guide](../playbooks/troubleshoot-auth.md) if issues arise
