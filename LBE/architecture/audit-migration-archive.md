# Audit Migration Archive

## Migration Completed: November 3, 2025

The centralized audit schema migration has been successfully completed and the audit_migration folder has been archived.

---

## What Was Migrated

### Database Changes
- ✅ Created `audit` schema with 2 tables:
  - `audit.audit_event` (15 rows migrated)
  - `audit.entity_audit_event` (50 rows migrated)
- ✅ Created 16 performance indexes
- ✅ Created 3 monitoring views
- ✅ Granted permissions to all app roles
- ✅ Archived old schema-specific tables with `_archived_20251103` suffix

### Code Changes
- ✅ Updated shared-lib audit repositories to write to centralized schema
- ✅ Added service metadata fields (service_name, source_schema, source_table)
- ✅ Updated all application.yml profile files (dev, test, staging, prod)
- ✅ Maintained backward compatibility

---

## Archive Location

The original migration scripts were moved from `docs/audit_migration/` and the important information has been consolidated into:

### Primary Documentation
- **[Audit Design](../architecture/audit-design.md)** - Complete audit system documentation
- **[Audit Quick Reference](../reference/audit-quick-reference.md)** - Quick reference for queries and configuration
- **[Table Names Reference](../reference/TABLE_NAMES_REFERENCE.md)** - Includes audit tables

### Migration SQL Scripts (if needed for other environments)

**Note:** The migration has already been applied to development. For staging/production:

1. **Create Audit Schema:**
```sql
-- See architecture/audit-design.md for full schema DDL
-- Or restore from git history: docs/audit_migration/01_create_audit_schema.sql
```

2. **Migrate Data:**
```sql
-- Pattern for each service:
INSERT INTO audit.audit_event 
  (occurred_at, trace_id, user_id, action, entity_type, entity_id, 
   entity_name, description, ip_address, user_agent, metadata, 
   api_endpoint, http_method, status_code, service_name, source_schema)
SELECT 
  occurred_at, trace_id, user_id, action, entity_type, entity_id,
  entity_name, description, ip_address, user_agent, metadata,
  api_endpoint, http_method, status_code,
  'service-name',  -- Set appropriate service name
  'source_schema'  -- Set appropriate schema
FROM source_schema.audit_event;
```

3. **Archive Old Tables (after 7 days):**
```sql
ALTER TABLE auth.audit_event RENAME TO audit_event_archived_YYYYMMDD;
ALTER TABLE auth.entity_audit_event RENAME TO entity_audit_event_archived_YYYYMMDD;
-- Repeat for other schemas
```

4. **Drop Archived Tables (after 30 days):**
```sql
DROP TABLE IF EXISTS auth.audit_event_archived_YYYYMMDD CASCADE;
DROP TABLE IF EXISTS auth.entity_audit_event_archived_YYYYMMDD CASCADE;
-- Repeat for other schemas
```

---

## Configuration Reference

All services must use this configuration pattern:

```yaml
shared-lib:
  audit:
    enabled: true
    table-name: audit.audit_event
    service-name: {service-name}     # e.g., auth-service
    source-schema: {schema}          # e.g., auth
  entity-audit:
    enabled: true
    table-name: audit.entity_audit_event
    service-name: {service-name}
    source-schema: {schema}
    source-table: {primary-table}    # e.g., users
```

---

## Rollback (Emergency Only)

If critical issues are discovered:

1. **Stop all services**
2. **Restore archived tables:**
```sql
ALTER TABLE auth.audit_event_archived_20251103 RENAME TO audit_event;
ALTER TABLE auth.entity_audit_event_archived_20251103 RENAME TO entity_audit_event;
-- Repeat for payment_flow, reconciliation
```

3. **Revert configuration** in all application.yml files:
```yaml
shared-lib:
  audit:
    table-name: audit_event  # Back to schema-specific
  entity-audit:
    table-name: entity_audit_event  # Back to schema-specific
```

4. **Redeploy services** with old configuration
5. **Optional:** Drop audit schema: `DROP SCHEMA audit CASCADE;`

---

## Verification Queries

### Check Audit Data
```sql
-- Event counts by service
SELECT service_name, source_schema, COUNT(*) 
FROM audit.audit_event 
GROUP BY service_name, source_schema;

-- Entity changes by service
SELECT service_name, source_schema, COUNT(*) 
FROM audit.entity_audit_event 
GROUP BY service_name, source_schema;
```

### Check Recent Activity
```sql
SELECT * FROM audit.v_recent_events LIMIT 10;
SELECT * FROM audit.v_activity_summary WHERE date >= CURRENT_DATE - 7;
```

---

## Timeline

| Date | Action | Status |
|------|--------|--------|
| Nov 3, 2025 | Dev migration executed | ✅ Complete |
| Nov 4-10, 2025 | Dev monitoring period | ⏳ In Progress |
| Nov 5-6, 2025 | Staging migration (planned) | 🔜 Upcoming |
| Nov 7, 2025 | Production migration (planned) | 🔜 Upcoming |
| Nov 14, 2025 | Archive old tables (planned) | 📅 Scheduled |
| Dec 14, 2025 | Drop archived tables (planned) | 📅 Scheduled |

---

## Contact

For questions about the audit system:
- See [Audit Design Documentation](../architecture/audit-design.md)
- Check [Audit Quick Reference](../reference/audit-quick-reference.md)
- Review shared-lib audit framework code

---

**Archive Date:** November 3, 2025  
**Migration Status:** ✅ Successfully Completed in Dev  
**Next Steps:** Monitor for 7 days, then proceed with staging/production
