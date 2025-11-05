# Recent Updates (Nov 2025)

This note captures the highlights from the latest cross-service changes so documentation readers can map code updates to operational impacts.

## Shared Audit Enhancements
- **What changed:** `shared-lib` added explicit tagging fields (`service-name`, `source-schema`, `source-table`) in `AuditProperties` and `EntityAuditProperties` while the payment-flow service enabled entity auditing on worker/payment aggregates.
- **Operational impact:** Every service must now populate those identifiers in `application.yml` to keep cross-service analytics accurate. See the refreshed configuration examples in:
  - `shared-lib/SharedLibIntegrationGuide.md`
  - `docs/reference/audit-quick-reference.md`
  - `docs/architecture/audit-design.md`
- **Follow-up:** Revisit service configs and confirm audit rows show the expected service/schema tags before promoting to higher environments.

## Authorization Matrix Endpoints
- **What changed:** `auth-service` introduced `/api/meta/user-access-matrix/{user_id}` and `/api/meta/ui-access-matrix/{page_id}` for deep-dive RBAC reviews. The onboarding SQL and RBAC mapping docs now list these endpoints.
- **Operational impact:** Admin tooling (and CLI scripts) can use the meta APIs to debug policy rollouts without scraping multiple tables.
- **Docs to consult:**
  - `docs/reference/raw/RBAC/MAPPINGS/PHASE1_ENDPOINTS_EXTRACTION.md`
  - `docs/reference/raw/RBAC/MAPPINGS/PHASE5_ENDPOINT_POLICY_MAPPINGS.md`
  - `docs/architecture/overview.md`

## Reconciliation Service PostgreSQL Alignment
- **What changed:** The service shifted from MySQL to PostgreSQL schemas and now defaults to `currentSchema=reconciliation` in `application-dev.yml`.
- **Operational impact:** Local dev and RLS smoke tests share one config path; keep any profile-specific overrides (e.g., `application-dev-rls.yml`) in sync with the primary dev file.
- **Docs to consult:** `docs/reference/raw/POSTGRES/README.md`

## Capability Layer Removal
- **What changed:** The intermediate capability hop has been removed. Policies now bind directly to endpoints and UI metadata.
- **Operational impact:** Update onboarding playbooks and team rituals to talk in terms of policies + endpoints. Capability tables/scripts remain only for legacy migrations.
- **Docs to consult:**
  - `docs/architecture/policy-binding.md`
  - `docs/architecture/request-lifecycle.md`
  - `docs/reference/policy-matrix.md`

## Validation Checklist
1. Audit dashboards show the correct `service_name` and `source_schema` for new payment-flow events.
2. The new meta endpoints return 200s after onboarding SQL migrations run.
3. Reconciliation service starts cleanly against the PostgreSQL instance with RLS enabled.

Keep this page updated as additional November changes land so reviewers have a single starting point before diving into the detailed references.
