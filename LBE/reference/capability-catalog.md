# Capability Catalog (Legacy)

**Navigation:** Previous: [Role Catalog](role-catalog.md) → Next: [Policy Matrix](policy-matrix.md)

The capability layer has been decommissioned in favour of direct **policy → endpoint** bindings. This page is preserved for historical reference while migration scripts and older environments are fully cleaned up.

## What Changed?

- Policies now name the permission directly; there is no intermediate `auth.capabilities` or `auth.policy_capabilities` hop in production code.
- UI visibility relies on the meta endpoints (`/api/meta/pages`, `/api/meta/endpoints`, `/api/meta/ui-access-matrix/{pageId}`) rather than capability lookups.
- See `auth-service/CAPABILITY_REMOVAL_CONTEXT.md` for the step-by-step removal plan.

## When Do I Still Think About Capabilities?

- Only when maintaining legacy environments that still contain the `capabilities` and `policy_capabilities` tables.
- When running the onboarding SQL scripts prior to the cleanup migrations—scripts `03_create_capabilities.sql` and `05_link_policies_to_capabilities.sql` are now considered **archive material**.

## Where To Look Instead

- [Policy Matrix](policy-matrix.md) – shows which policies unlock which endpoints.
- [Policy Binding Relationships](../architecture/policy-binding.md) – updated diagrams of the new flow.
- `/api/meta/user-access-matrix/{userId}` – real-time breakdown of user → role → policy → endpoint.

If you encounter a reference to capabilities during a review, assume it is technical debt to be deleted. Update the migration tracking document and favor policy-centric terminology in new work.
