# Audit System Quick Reference

## Table Overview

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `audit.audit_event` | General action logging | user_id, action, service_name, occurred_at |
| `audit.entity_audit_event` | Entity change tracking | entity_type, entity_id, old_values, new_values, hash |

---

## Common Queries

### Find User Activity
```sql
SELECT * FROM audit.audit_event 
WHERE user_id = {user_id} 
ORDER BY occurred_at DESC;
```

### Find Service Activity
```sql
SELECT * FROM audit.audit_event 
WHERE service_name = '{service_name}' 
ORDER BY occurred_at DESC 
LIMIT 100;
```

### Find Entity Changes
```sql
SELECT * FROM audit.entity_audit_event 
WHERE entity_type = '{ENTITY_TYPE}' 
  AND entity_id = '{id}' 
ORDER BY occurred_at;
```

### Trace Request Flow
```sql
SELECT service_name, action, occurred_at 
FROM audit.audit_event 
WHERE trace_id = '{trace_id}' 
ORDER BY occurred_at;
```

### Daily Activity Summary
```sql
SELECT * FROM audit.v_activity_summary 
WHERE date = CURRENT_DATE;
```

---

## Service Tags

| Service | service_name | source_schema |
|---------|-------------|---------------|
| Auth Service | `auth-service` | `auth` |
| Payment Flow Service | `payment-flow-service` | `payment_flow` |
| Reconciliation Service | `reconciliation-service` | `reconciliation` |

---

## Configuration Template

```yaml
shared-lib:
  audit:
    enabled: true
    table-name: audit.audit_event
    service-name: {service-name}
    source-schema: {schema}
  entity-audit:
    enabled: true
    table-name: audit.entity_audit_event
    service-name: {service-name}
    source-schema: {schema}
    source-table: {primary-table}
```

- `service-name` should be the canonical microservice identifier (`auth-service`, `payment-flow-service`, `reconciliation-service`, etc.).
- Keep `source-schema`/`source-table` aligned with the schema and primary table that raised the event so downstream analytics can filter accurately.

---

## Monitoring Views

| View | Purpose |
|------|---------|
| `audit.v_recent_events` | Last 7 days of events (limit 1000) |
| `audit.v_activity_summary` | Daily stats by service |
| `audit.v_entity_changes_today` | Entity changes in last 24h |

---

## Permissions

```sql
-- Application roles have INSERT + SELECT
GRANT INSERT, SELECT ON audit.audit_event TO {app_role};
GRANT INSERT, SELECT ON audit.entity_audit_event TO {app_role};
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO {app_role};
```

---

## Indexes

### audit.audit_event (9 indexes)
- occurred_at, user_id, trace_id, action
- service_name, source_schema
- entity_type, entity_id, api_endpoint

### audit.entity_audit_event (10 indexes)
- occurred_at, record_number, entity_type, entity_id
- operation, performed_by, hash
- service_name, source_schema, source_table

---

## See Also
- [Audit Design](../architecture/audit-design.md) - Full documentation
- [Data Map](../architecture/data-map.md) - Schema relationships
