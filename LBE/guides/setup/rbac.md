# RBAC Setup Playbook

**Navigation:** Previous: [Journey: Login To Data](../login-to-data.md) → Next: [VPD Setup Playbook](vpd.md)

Follow this sequence whenever you onboard a new tenant or extend permissions. Treat it like wiring a building’s security system—each step unlocks the next one.

## Overview Of The Flow

```mermaid
flowchart TD
    A[Plan roles] --> B[Create policies]
    B --> C[Register endpoints]
    B --> D[Map UI pages & actions]
    C --> E[Bind endpoint to policy]
    D --> F[Surface in authorization matrix]
    E --> G[Assign policy to roles]
    G --> H[Assign roles to users]
    H --> I[Verify behaviour]
```

## 1. Plan Roles & Personas

- Confirm which personas exist (e.g., Worker, Employer, Board, Service Accounts).
- Decide whether new roles are needed or existing ones can be reused.
- Reference: `../../reference/role-catalog.md`.

## 2. Create Or Update Policies

Policies define the access boundary and tie protected operations to the roles that can exercise them.

**Via SQL:**
```sql
-- Insert a policy if it doesn't exist
INSERT INTO auth.policies (name, description)
VALUES ('EMPLOYER_POLICY', 'Employer actions for payment reconciliation')
ON CONFLICT (name) DO NOTHING;
```

**Via API (UI):**
```http
POST /api/admin/policies
Content-Type: application/json

{
  "name": "EMPLOYER_POLICY",
  "description": "Employer actions for payment reconciliation"
}
```

Link the policy to roles:

**Via SQL:**
```sql
INSERT INTO auth.role_policies (role_id, policy_id, assigned_at, is_active)
SELECT r.id, p.id, CURRENT_TIMESTAMP, true
FROM auth.roles r, auth.policies p
WHERE r.name IN ('EMPLOYER', 'TEST_USER')
  AND p.name = 'EMPLOYER_POLICY'
ON CONFLICT (role_id, policy_id) DO NOTHING;
```

**Via API (UI):**
```http
POST /api/admin/policies/{policyId}/roles
Content-Type: application/json

{
  "roleIds": [2, 3]
}
```
(where `roleIds` correspond to EMPLOYER and TEST_USER roles)

## 3. Register Endpoints

**Via SQL:**
```sql
INSERT INTO auth.endpoints (method, path, label)
VALUES ('GET', '/api/employer/payment-ledger', 'Download employer payment ledger')
ON CONFLICT (method, path) DO NOTHING;
```

**Via API (UI):**
```http
POST /api/admin/endpoints
Content-Type: application/json

{
  "method": "GET",
  "path": "/api/employer/payment-ledger",
  "label": "Download employer payment ledger"
}
```

Bind the endpoint to the policy:

**Via SQL:**
```sql
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id
FROM auth.endpoints e, auth.policies p
WHERE e.method = 'GET'
  AND e.path = '/api/employer/payment-ledger'
  AND p.name = 'EMPLOYER_POLICY'
ON CONFLICT (endpoint_id, policy_id) DO NOTHING;
```

**Via API (UI):**
```http
POST /api/admin/endpoints/{endpointId}/policies
Content-Type: application/json

{
  "policyIds": [5]
}
```
(where `endpointId` is the GET /api/employer/payment-ledger endpoint ID and `policyIds` contains EMPLOYER_POLICY ID)

## 4. Wire UI Pages & Actions

### Understanding page_actions Table
The `page_actions` table serves a **dual purpose**:
1. **Permission Check**: Links to `policy_id` to determine if the user can see the action
2. **API Binding**: Links to `endpoint_id` to specify which endpoint to call

**Schema:**
```sql
CREATE TABLE auth.page_actions (
    id BIGSERIAL PRIMARY KEY,
    page_id INTEGER REFERENCES auth.ui_pages(id),
    label VARCHAR(64) NOT NULL,
    policy_id BIGINT REFERENCES auth.policies(id),
    endpoint_id BIGINT REFERENCES auth.endpoints(id),
    -- other fields...
);
```

### Frontend Authorization Flow
```
User loads page
  ↓
Call: GET /api/meta/endpoints?page_id={id}
  ↓
Backend returns page_actions WHERE:
  - user has the required policy through their active roles
  - endpoint_id is not null
  ↓
Frontend renders buttons/actions with API endpoints
```

**Via SQL:**
```sql
-- Create page action with both policy and endpoint
INSERT INTO auth.page_actions (page_id, label, policy_id, endpoint_id)
SELECT 
    p.id,
    'Download Ledger',
    pol.id,
    e.id
FROM auth.ui_pages p
JOIN auth.policies pol ON pol.name = 'EMPLOYER_POLICY'
JOIN auth.endpoints e ON e.method = 'GET'
  AND e.path = '/api/employer/payment-ledger'
WHERE p.page_id = 'EMPLOYER_DASHBOARD'
ON CONFLICT DO NOTHING;
```

**Via API (UI):**
```http
-- Create page action
POST /api/admin/page-actions
Content-Type: application/json

{
  "pageId": 5,
  "label": "Download Ledger",
  "policyId": 7,
  "endpointId": 45
}
```

### Verify Page Actions Linkage
```sql
-- Check complete authorization chain for a page
SELECT 
    pa.id,
    pa.label,
    pol.name as policy,
    e.method,
    e.path,
    STRING_AGG(DISTINCT p.name, ', ') as endpoint_policies
FROM auth.page_actions pa
JOIN auth.policies pol ON pa.policy_id = pol.id
JOIN auth.endpoints e ON pa.endpoint_id = e.id
JOIN auth.endpoint_policies ep ON e.id = ep.endpoint_id
JOIN auth.policies p ON ep.policy_id = p.id
WHERE pa.page_id = 2  -- User Management page
GROUP BY pa.id, pa.label, pol.name, e.method, e.path
ORDER BY pa.id;
```

**Important:** Front-end code should:
1. Call `/api/meta/endpoints?page_id={id}` to get available actions
2. Only render buttons/actions returned in the response
3. Use the `endpoint` field to make API calls when clicked

## 5. Assign Roles To Users

**Via SQL:**
```sql
INSERT INTO auth.user_roles (user_id, role_id)
SELECT u.id, r.id
FROM auth.users u, auth.roles r
WHERE u.username = 'employer.demo'
  AND r.name = 'EMPLOYER'
ON CONFLICT (user_id, role_id) DO NOTHING;
```

**Via API (UI):**
```http
POST /api/admin/users/{userId}/roles
Content-Type: application/json

{
  "roleIds": [2]
}
```
(where `userId` is the ID of employer.demo user and `roleIds` contains EMPLOYER role ID)

If creating service accounts, ensure credentials are stored securely and tokens carry the correct audience.

## 6. Verify The Setup

### Backend Verification
1. **Test endpoint authorization** with both allowed and disallowed users (expect 200 vs 403):
```bash
# Allowed user
curl -H "Authorization: Bearer $ADMIN_TOKEN" 
  http://localhost:8080/api/auth/users

# Disallowed user
curl -H "Authorization: Bearer $BASIC_TOKEN" 
  http://localhost:8080/api/auth/users
```

2. **Check policy resolution**:
```sql
-- What policies does this user have?
SELECT DISTINCT p.name
FROM auth.user_roles ur
JOIN auth.roles r ON ur.role_id = r.id
JOIN auth.role_policies rp ON r.id = rp.role_id
JOIN auth.policies p ON rp.policy_id = p.id
WHERE ur.user_id = 123
  AND rp.is_active = true
  AND p.is_active = true;
```

3. **Verify endpoint-policy links**:
```sql
-- What policies protect this endpoint?
SELECT p.name, p.type, p.description
FROM auth.endpoints e
JOIN auth.endpoint_policies ep ON e.id = ep.endpoint_id
JOIN auth.policies p ON ep.policy_id = p.id
WHERE e.method = 'PUT' AND e.path = '/api/auth/users/{userId}';
```

### Frontend Verification
1. **Test page action visibility**:
```http
GET /api/meta/endpoints?page_id=2
Authorization: Bearer $USER_TOKEN
```

2. **Verify response contains actions**:
```json
{
  "actions": [
    {
      "id": 2,
      "label": "Create User",
      "policy": "USER_ADMIN_POLICY",
      "endpoint": {
        "method": "POST",
        "path": "/api/auth/users"
      }
    }
  ]
}
```

3. **Check audit logs** for recorded access decisions:
```sql
SELECT * FROM audit.access_log 
WHERE user_id = 123 
ORDER BY timestamp DESC 
LIMIT 10;
```

## Troubleshooting Tips

- **Policy missing for user** – Confirm `auth.role_policies` contains the assignment and `is_active = true`
- **Endpoint still returns 403** – Verify `auth.endpoint_policies` references the expected policy and that policy is attached to the caller’s role
- **Button visible but API fails** – Ensure `page_actions.policy_id` aligns with the endpoint’s guarding policy
- **Page action not showing** – Check both `policy_id` and `endpoint_id` fields in `page_actions`, and confirm the policy is active
- **UI shows wrong actions** – Clear frontend cache and confirm `/api/meta/endpoints` reflects the latest page action definitions

## Next Steps

Once RBAC is wired, continue to [VPD Setup Playbook](vpd.md) to configure tenant-level data guardrails.
