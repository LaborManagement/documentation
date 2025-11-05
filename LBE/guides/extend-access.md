# Extend Access Guide

Use this step-by-step recipe when you need to add or adjust permissions. It mirrors what happens in production while remaining safe for experimentation.

## Scenario

You want employers to download a payment ledger. The same flow applies for any new endpoint permission.

## Overview Of Steps

1. Design the endpoint and determine required policy.
2. Update the catalogue (database).
3. Wire the backend endpoint.
4. Reveal or hide UI actions.
5. Verify with contrasting tests.

## 1. Design The Endpoint & Policy

- Write the plain-language job story: "Employers can download their own payment ledger."
- Define the endpoint: `GET /api/employer/payment-ledger`
- Decide which policy protects it (EMPLOYER_POLICY)
- Decide which roles receive access (EMPLOYER, TEST_USER for QA)

## 2. Update The Catalogue

> All tables live in the `auth` schema. Run these changes through migrations or manual SQL in a non-production environment first.

```sql
-- 1. Register the endpoint
INSERT INTO auth.endpoints (method, path, label, description, service, is_active, created_at, updated_at)
VALUES ('GET', '/api/employer/payment-ledger', 'Download employer payment ledger', 
        'Download payment ledger CSV for owned employer records', 'EMPLOYER', true, NOW(), NOW())
ON CONFLICT (method, path) DO NOTHING;

-- 2. Link endpoint to policy
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id, created_at)
SELECT e.id, p.id, NOW()
FROM auth.endpoints e, auth.policies p
WHERE e.method = 'GET'
  AND e.path = '/api/employer/payment-ledger'
  AND p.name = 'EMPLOYER_POLICY'
ON CONFLICT (endpoint_id, policy_id) DO NOTHING;

-- 3. Verify the policy is linked to correct roles
SELECT r.name AS role, p.name AS policy, e.method, e.path
FROM auth.roles r
JOIN auth.role_policies rp ON r.id = rp.role_id
JOIN auth.policies p ON rp.policy_id = p.id
JOIN auth.endpoint_policies ep ON p.id = ep.policy_id
JOIN auth.endpoints e ON ep.endpoint_id = e.id
WHERE e.path = '/api/employer/payment-ledger';
```

## 3. Implement The Endpoint

In the Spring controller, implement and guard the method:

```java
@GetMapping("/payment-ledger")
@PreAuthorize("hasAnyAuthority('EMPLOYER_POLICY')")  // Policy-based authorization
public ResponseEntity<Resource> downloadLedger(@AuthenticationPrincipal UserDetails user) {
    // Implementation here
    return ResponseEntity.ok()
        .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=ledger.csv")
        .body(resource);
}
```

## 4. Update The UI

- Create a page action that links to the endpoint:

```sql
-- Add action to employer dashboard page
INSERT INTO auth.page_actions (page_id, label, action, endpoint_id, icon, variant, created_at, updated_at)
SELECT 
    p.id,
    'Download Ledger',
    'DOWNLOAD',
    e.id,
    'download',
    'primary',
    NOW(),
    NOW()
FROM auth.ui_pages p, auth.endpoints e
WHERE p.page_id = 'employer-dashboard'
  AND e.method = 'GET'
  AND e.path = '/api/employer/payment-ledger'
ON CONFLICT (page_id, endpoint_id) DO NOTHING;
```

- Frontend fetches available actions via `/api/meta/endpoints?page_id=employer-dashboard`
- Show the "Download Ledger" button only when the endpoint appears in the response
- Button automatically hidden for users without EMPLOYER_POLICY

## 5. Verify Behaviour

Use two seed users:

```bash
# Employer should succeed
curl -H "Authorization: Bearer <employer-token>" \
  http://localhost:8080/api/employer/payment-ledger

# Worker should fail with 403
curl -H "Authorization: Bearer <worker-token>" \
  http://localhost:8080/api/employer/payment-ledger
```

Check the database session set the context correctly:

```sql
SET ROLE app_payment_flow;
SELECT auth.set_user_context('employer.user');
SELECT COUNT(*) FROM payment_flow.payment_ledger;
```

Expect to see only employer-owned rows.

## Ready Reference

- Policy-driven authorization – `architecture/policy-binding.md`
- Seed users and policy map – `reference/role-catalog.md`, `reference/policy-matrix.md`
- Troubleshooting failures – `playbooks/troubleshoot-auth.md`
- Permission patterns – `architecture/permission-patterns.md`

Repeat this loop for any new permission. Change the names, keep the structure.
