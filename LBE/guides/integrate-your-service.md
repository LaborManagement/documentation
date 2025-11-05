# Integrate Your Service

Follow this guide when another service in the platform needs to trust the auth service. Think of it as adding a new ride to the theme park: you must connect power, safety checks, and admission rules before opening the gate.

## Prerequisites

- Local environment ready (`guides/local-environment.md`).
- Service you are integrating can call HTTP endpoints and validate JWTs.
- Database migrations pipeline capable of updating the `auth` schema.

## 1. Decide What The Service Needs

- List the actions your service must perform (e.g., "Reporting service needs to read employer payment summaries").
- Map each action to existing endpoints or design new ones.
- Check `reference/role-catalog.md` to see which roles should have access.

## 2. Provision Policies & Endpoints

- Use the flow in `guides/extend-access.md` to create or update policies.
- Register your endpoints in `auth.endpoints` table with method, path, and description.
- Link endpoints to appropriate policies via `auth.endpoint_policies`.
- If the service requires machine-to-machine access, create or update the corresponding service account (e.g., `reporting.service`).
- Assign roles to the service account in `auth.user_roles`.

## 3. Expose API Endpoints

- Implement your service endpoints with appropriate security annotations.
- Register the endpoint in `auth.endpoints` and link it via `auth.endpoint_policies`.
- Update API documentation so consumers know the required policy.

Example controller:

```java
@GetMapping("/reports/payment-summary")
@PreAuthorize("hasAnyAuthority('REPORTING_POLICY')")
public ResponseEntity<PaymentSummary> getPaymentSummary(@AuthenticationPrincipal UserDetails user) {
    // Implementation
}
```

## 4. Share Authorization Matrix

- Use `/api/me/authorizations` for user-facing applications.
- For backend services, expose a lightweight endpoint (e.g., `/internal/authorizations/{userId}`) that reuses the same policy lookup if they cannot call the main API.

## 5. Propagate Tenant Context

- Ensure the consuming service calls `auth.set_user_context` (directly or indirectly) before hitting RLS-controlled tables.
- For JVM services, reuse the `RLSContextFilter` pattern.
- For other languages, run the equivalent `SELECT auth.set_user_context(:userId)` after establishing the database connection.

## 6. Validate End-To-End

1. Authenticate as the role or service account you configured.
2. Call the new API endpoint.
3. Confirm the correct data appears and other roles are rejected.
4. Check audit logs for recorded actions.

## 7. Production Checklist

- Feature flag or toggle to roll out safely.
- Monitoring on new endpoints (latency + error rate).
- Alert for unexpected 403 spikes (indicates mapping issues).
- Documented rollback plan (remove endpoint-policy link or revert migration).

## Handy References

- Policy design pattern – `architecture/policy-binding.md`
- Permission patterns – `architecture/permission-patterns.md`
- RLS primer – `foundations/data-guardrails-101.md`
- Troubleshooting flow – `playbooks/troubleshoot-auth.md`
- Policy matrix – `reference/policy-matrix.md`

Integrating another service should feel deliberate, not risky. Follow the steps, lean on the examples, and you'll keep the platform cohesive.
