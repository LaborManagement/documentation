# Role Catalog

**Navigation:** Previous: [VPD Setup Playbook](../guides/setup/vpd.md) → Next: [Policy Matrix](policy-matrix.md)

Use this catalog when you need a concise snapshot of each platform role. For full historical detail, see the legacy document in `reference/raw/ONBOARDING_ROLES.md`.

| Role | Policy Count | Typical User | Highlights | Default UI Areas |
| --- | --- | --- | --- | --- |
| `PLATFORM_BOOTSTRAP` | 17 | `platform.bootstrap@lbe.local` (service) | Seeds catalog, links policies, should be disabled after use | Hidden admin setup pages |
| `ADMIN_TECH` | 12 | `admin.tech@lbe.local` | Manages users, roles, policies, endpoints, UI pages | System settings, RBAC admin, audit views |
| `ADMIN_OPS` | 8 | `admin.ops@lbe.local` | Operates day-to-day reconciliation without altering RBAC wiring | Operational dashboards, audit logs, ticket triage |
| `BOARD` | 5 | `board.member@lbe.local` | Reviews escalated employer requests and approves payouts | Board overview, approvals, reporting |
| `EMPLOYER` | 6 | `employer.demo@lbe.local` | Manages payment submissions within their organisation | Employer dashboard, request status, payment ledger |
| `WORKER` | 4 | `worker.demo@lbe.local` | Uploads documents, tracks personal payments | Worker portal, upload screens |
| `TEST_USER` | 14 | `qa.test@lbe.local` | Broad sandbox access mirroring production for QA | Mirrors ADMIN_TECH + EMPLOYER for testing |

## Reference Queries

```sql
-- List policies for a role
SELECT p.name
FROM auth.policies p
JOIN auth.role_policies rp ON rp.policy_id = p.id
JOIN auth.roles r ON r.id = rp.role_id
WHERE r.name = 'EMPLOYER'
  AND rp.is_active = true
  AND p.is_active = true
ORDER BY p.name;

-- Show endpoints unlocked by a role
SELECT e.method, e.path, p.name as policy
FROM auth.endpoints e
JOIN auth.endpoint_policies ep ON ep.endpoint_id = e.id
JOIN auth.policies p ON p.id = ep.policy_id
JOIN auth.role_policies rp ON rp.policy_id = p.id
JOIN auth.roles r ON r.id = rp.role_id
WHERE r.name = 'EMPLOYER'
  AND rp.is_active = true
ORDER BY e.path;
```

## Policy Themes

- **Worker journeys** – Upload, update, and track own payment requests.
- **Employer journeys** – Approve worker submissions, view organisation-wide data.
- **Board oversight** – Approve final payouts and view cross-organisation reports.
- **Tech administration** – Manage RBAC catalog, system settings, and audit logs.
- **Operational support** – Monitor queues, resolve exceptions, and run reports.

## When Updating Roles

1. Adjust the `auth.role_policies` mapping first.
2. Update `/api/me/authorizations` contract tests if policy assignments change.
3. Notify front-end owners when UI access changes—meta endpoints drive button visibility.

## Further Reading

- Stories and analogies – [Role Stories](../start/role-stories.md)
- How to add policies – [Extend Access Guide](../guides/extend-access.md)
- Raw role breakdown – [ONBOARDING_ROLES.md](raw/ONBOARDING_ROLES.md)
