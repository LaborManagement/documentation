# Audit System Design

## Overview

The audit system provides comprehensive tracking of all user actions, data changes, and system events across all services in the Labor Management and Payment Reconciliation platform. It uses a centralized schema design to enable cross-service audit queries and compliance reporting.

**Migration Date:** November 3, 2025  
**Status:** ✅ Active

---

## Architecture

### Centralized Schema Approach

All services write to a single `audit` schema in the PostgreSQL database, with service identification tags to maintain separation and enable filtering.

```
┌─────────────────────────────────────────────────────────┐
│                    audit schema                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌───────────────────────────────────────────────┐    │
│  │        audit.audit_event                      │    │
│  │  - General action auditing                    │    │
│  │  - User activities, API calls                 │    │
│  │  - Tagged by service_name, source_schema      │    │
│  └───────────────────────────────────────────────┘    │
│                                                         │
│  ┌───────────────────────────────────────────────┐    │
│  │     audit.entity_audit_event                  │    │
│  │  - Entity-level change tracking               │    │
│  │  - Before/after values, hashing               │    │
│  │  - Tagged by service_name, source_schema,     │    │
│  │    source_table                               │    │
│  └───────────────────────────────────────────────┘    │
│                                                         │
└─────────────────────────────────────────────────────────┘
              ▲              ▲              ▲
              │              │              │
        ┌─────┴────┐   ┌────┴────┐   ┌────┴─────┐
        │   auth   │   │ payment │   │reconcile │
        │ service  │   │  flow   │   │  service │
        └──────────┘   └─────────┘   └──────────┘
```

---

## Tables

### audit.audit_event

**Purpose:** Track high-level user actions, API calls, and system events.

**Schema:**
```sql
CREATE TABLE audit.audit_event (
    id                BIGSERIAL PRIMARY KEY,
    occurred_at       TIMESTAMP WITH TIME ZONE NOT NULL,
    trace_id          TEXT,
    user_id           BIGINT,
    action            TEXT NOT NULL,
    entity_type       TEXT,
    entity_id         TEXT,
    entity_name       TEXT,
    description       TEXT,
    ip_address        TEXT,
    user_agent        TEXT,
    metadata          JSONB,
    api_endpoint      TEXT,
    http_method       TEXT,
    status_code       INTEGER,
    service_name      TEXT NOT NULL,
    source_schema     TEXT NOT NULL
);
```

**Indexes:**
- `idx_audit_event_occurred_at` - Time-based queries
- `idx_audit_event_user_id` - User activity tracking
- `idx_audit_event_trace_id` - Request tracing
- `idx_audit_event_action` - Action type filtering
- `idx_audit_event_service_name` - Service filtering
- `idx_audit_event_source_schema` - Schema filtering
- `idx_audit_event_entity_type` - Entity type queries
- `idx_audit_event_entity_id` - Entity instance tracking
- `idx_audit_event_api_endpoint` - Endpoint usage tracking

**Usage Examples:**
```sql
-- Find all actions by a user
SELECT * FROM audit.audit_event WHERE user_id = 123 ORDER BY occurred_at DESC;

-- Find all events for a service
SELECT * FROM audit.audit_event WHERE service_name = 'auth-service';

-- Find all API calls to a specific endpoint
SELECT * FROM audit.audit_event WHERE api_endpoint = '/api/users';

-- Cross-service activity for a trace
SELECT service_name, action, occurred_at 
FROM audit.audit_event 
WHERE trace_id = 'abc-123' 
ORDER BY occurred_at;
```

---

### audit.entity_audit_event

**Purpose:** Track detailed entity-level changes with before/after values and cryptographic hashing for tamper detection.

**Schema:**
```sql
CREATE TABLE audit.entity_audit_event (
    id                  BIGSERIAL PRIMARY KEY,
    occurred_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    audit_number        TEXT NOT NULL UNIQUE,
    record_number       TEXT NOT NULL,
    entity_type         TEXT NOT NULL,
    entity_id           TEXT,
    operation           TEXT NOT NULL,
    performed_by        TEXT,
    trace_id            TEXT,
    metadata            JSONB,
    old_values          JSONB,
    new_values          JSONB,
    change_summary      TEXT,
    client_ip           TEXT,
    user_agent          TEXT,
    prev_hash           TEXT NOT NULL,
    hash                TEXT NOT NULL UNIQUE,
    service_name        TEXT NOT NULL,
    source_schema       TEXT NOT NULL,
    source_table        TEXT NOT NULL
);
```

**Indexes:**
- `idx_entity_audit_occurred_at` - Time-based queries
- `idx_entity_audit_record_number` - Record tracking
- `idx_entity_audit_entity_type` - Entity type filtering
- `idx_entity_audit_entity_id` - Entity instance tracking
- `idx_entity_audit_operation` - Operation type filtering
- `idx_entity_audit_performed_by` - User tracking
- `idx_entity_audit_hash` - Hash verification
- `idx_entity_audit_service_name` - Service filtering
- `idx_entity_audit_source_schema` - Schema filtering
- `idx_entity_audit_source_table` - Table filtering

**Usage Examples:**
```sql
-- Find all changes to a specific entity
SELECT * FROM audit.entity_audit_event 
WHERE entity_type = 'USER' AND entity_id = '123' 
ORDER BY occurred_at;

-- Find all changes in a source table
SELECT * FROM audit.entity_audit_event 
WHERE source_schema = 'auth' AND source_table = 'users'
ORDER BY occurred_at DESC;

-- Verify audit chain integrity
SELECT audit_number, hash, prev_hash, occurred_at
FROM audit.entity_audit_event
WHERE record_number = 'REC-001'
ORDER BY occurred_at;
```

---

## Monitoring Views

### v_recent_events

**Purpose:** Quick view of recent audit events across all services.

```sql
CREATE VIEW audit.v_recent_events AS
SELECT 
    id,
    occurred_at,
    service_name,
    source_schema,
    action,
    user_id,
    entity_type,
    entity_id,
    trace_id
FROM audit.audit_event
WHERE occurred_at >= NOW() - INTERVAL '7 days'
ORDER BY occurred_at DESC
LIMIT 1000;
```

---

### v_activity_summary

**Purpose:** Daily activity summary by service.

```sql
CREATE VIEW audit.v_activity_summary AS
SELECT 
    DATE(occurred_at) as date,
    service_name,
    source_schema,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT trace_id) as unique_traces
FROM audit.audit_event
GROUP BY DATE(occurred_at), service_name, source_schema
ORDER BY date DESC, service_name;
```

---

### v_entity_changes_today

**Purpose:** Entity changes in the last 24 hours.

```sql
CREATE VIEW audit.v_entity_changes_today AS
SELECT 
    occurred_at,
    service_name,
    source_schema,
    source_table,
    entity_type,
    entity_id,
    operation,
    performed_by,
    change_summary
FROM audit.entity_audit_event
WHERE occurred_at >= NOW() - INTERVAL '24 hours'
ORDER BY occurred_at DESC;
```

---

## Service Configuration

Each service must configure the audit framework to write to the centralized schema.

### Auth Service

```yaml
shared-lib:
  entity-audit:
    enabled: true
    table-name: audit.entity_audit_event
    service-name: auth-service
    source-schema: auth
    source-table: users
  audit:
    enabled: true
    table-name: audit.audit_event
    service-name: auth-service
    source-schema: auth
```

### Payment Flow Service

```yaml
shared-lib:
  entity-audit:
    enabled: true
    table-name: audit.entity_audit_event
    service-name: payment-flow-service
    source-schema: payment_flow
    source-table: worker_payments
  audit:
    enabled: true
    table-name: audit.audit_event
    service-name: payment-flow-service
    source-schema: payment_flow
```

### Reconciliation Service

```yaml
shared-lib:
  entity-audit:
    enabled: true
    table-name: audit.entity_audit_event
    service-name: reconciliation-service
    source-schema: reconciliation
    source-table: transactions
  audit:
    enabled: true
    table-name: audit.audit_event
    service-name: reconciliation-service
    source-schema: reconciliation
```

---

## Shared Library Integration

### Components

1. **AuditProperties** - Configuration properties for general audit logging
2. **EntityAuditProperties** - Configuration properties for entity audit logging
3. **AuditEventRepository** - Persistence layer for audit events
4. **EntityAuditRepository** - Persistence layer for entity audit events
5. **AuditTrailService** - High-level service for logging audit events
6. **SharedEntityAuditListener** - JPA listener for automatic entity change tracking

### Usage in Services

#### Manual Audit Logging

```java
@Autowired
private AuditTrailService auditTrailService;

public void someBusinessMethod(User user) {
    // Business logic
    
    // Log audit event
    auditTrailService.logAction(
        user.getId(),
        "USER_UPDATE",
        "USER",
        String.valueOf(user.getId()),
        user.getUsername(),
        "Updated user profile",
        requestMetadata
    );
}
```

#### Automatic Entity Audit

```java
@Entity
@Table(name = "users", schema = "auth")
@EntityListeners(SharedEntityAuditListener.class)
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    private String username;
    private String email;
    
    // Changes to this entity are automatically audited
}
```

---

## Permissions

### Application Roles

All application roles have appropriate permissions:

```sql
-- Grant INSERT for audit logging
GRANT INSERT ON audit.audit_event TO auth_app_role;
GRANT INSERT ON audit.entity_audit_event TO auth_app_role;
GRANT INSERT ON audit.audit_event TO payment_app_role;
GRANT INSERT ON audit.entity_audit_event TO payment_app_role;
GRANT INSERT ON audit.audit_event TO reconciliation_app_role;
GRANT INSERT ON audit.entity_audit_event TO reconciliation_app_role;

-- Grant SELECT for audit queries
GRANT SELECT ON audit.audit_event TO auth_app_role;
GRANT SELECT ON audit.entity_audit_event TO auth_app_role;
GRANT SELECT ON audit.audit_event TO payment_app_role;
GRANT SELECT ON audit.entity_audit_event TO payment_app_role;
GRANT SELECT ON audit.audit_event TO reconciliation_app_role;
GRANT SELECT ON audit.entity_audit_event TO reconciliation_app_role;

-- Grant view access
GRANT SELECT ON audit.v_recent_events TO auth_app_role, payment_app_role, reconciliation_app_role;
GRANT SELECT ON audit.v_activity_summary TO auth_app_role, payment_app_role, reconciliation_app_role;
GRANT SELECT ON audit.v_entity_changes_today TO auth_app_role, payment_app_role, reconciliation_app_role;
```

---

## Query Patterns

### Cross-Service User Activity

```sql
-- Find all activity for a user across all services
SELECT 
    ae.occurred_at,
    ae.service_name,
    ae.action,
    ae.entity_type,
    ae.entity_name,
    ae.description
FROM audit.audit_event ae
WHERE ae.user_id = 123
ORDER BY ae.occurred_at DESC;
```

### Service-Specific Activity

```sql
-- Find all auth-service activity
SELECT * FROM audit.audit_event 
WHERE service_name = 'auth-service'
ORDER BY occurred_at DESC
LIMIT 100;
```

### Entity Change History

```sql
-- Find complete change history for an entity
SELECT 
    eae.occurred_at,
    eae.operation,
    eae.performed_by,
    eae.old_values,
    eae.new_values,
    eae.change_summary
FROM audit.entity_audit_event eae
WHERE eae.entity_type = 'USER' 
  AND eae.entity_id = '123'
ORDER BY eae.occurred_at;
```

### Trace-Based Request Flow

```sql
-- Follow a request across services
SELECT 
    ae.service_name,
    ae.occurred_at,
    ae.action,
    ae.api_endpoint,
    ae.status_code
FROM audit.audit_event ae
WHERE ae.trace_id = 'trace-abc-123'
ORDER BY ae.occurred_at;
```

### Compliance Reporting

```sql
-- Generate compliance report for date range
SELECT 
    DATE(ae.occurred_at) as date,
    ae.service_name,
    ae.action,
    COUNT(*) as action_count,
    COUNT(DISTINCT ae.user_id) as unique_users
FROM audit.audit_event ae
WHERE ae.occurred_at BETWEEN '2025-11-01' AND '2025-11-30'
GROUP BY DATE(ae.occurred_at), ae.service_name, ae.action
ORDER BY date DESC, action_count DESC;
```

### Audit Chain Verification

```sql
-- Verify integrity of audit chain for a record
WITH audit_chain AS (
    SELECT 
        audit_number,
        hash,
        prev_hash,
        occurred_at,
        LAG(hash) OVER (ORDER BY occurred_at) as expected_prev_hash
    FROM audit.entity_audit_event
    WHERE record_number = 'REC-001'
    ORDER BY occurred_at
)
SELECT 
    audit_number,
    occurred_at,
    CASE 
        WHEN prev_hash = expected_prev_hash THEN 'VALID'
        WHEN expected_prev_hash IS NULL THEN 'FIRST'
        ELSE 'BROKEN'
    END as chain_status
FROM audit_chain;
```

---

## Performance Considerations

### Index Strategy

- Time-based queries use `occurred_at` indexes
- User activity queries use `user_id` indexes
- Trace-based queries use `trace_id` indexes
- Service filtering uses `service_name` and `source_schema` indexes
- Entity queries use `entity_type` and `entity_id` indexes

### Partitioning (Future)

For high-volume environments, consider partitioning by time:

```sql
-- Example monthly partitioning (not yet implemented)
CREATE TABLE audit.audit_event_2025_11 
PARTITION OF audit.audit_event
FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');
```

### Archival Strategy

- Keep 90 days of audit data in hot storage
- Archive older data to cold storage or data warehouse
- Maintain audit chain integrity during archival

---

## Migration History

### Phase 1: Schema-Specific Tables (Pre-Nov 2025)

Each service had its own audit tables:
- `auth.audit_event` / `auth.entity_audit_event`
- `payment_flow.audit_event` / `payment_flow.entity_audit_event`
- `reconciliation.audit_event` / `reconciliation.entity_audit_event`

**Limitations:**
- No cross-service queries
- Duplicate table management
- Inconsistent schemas

### Phase 2: Centralized Schema (Nov 3, 2025)

Migrated to centralized `audit` schema:
- Created `audit.audit_event` and `audit.entity_audit_event`
- Migrated all historical data (65 total rows)
- Added service/schema tagging columns
- Archived old tables with `_archived_20251103` suffix

**Benefits:**
- Cross-service audit queries
- Single source of truth
- Consistent schema
- Easier compliance reporting

---

## Troubleshooting

### Issue: Audit events not appearing

**Check:**
1. Verify configuration: `shared-lib.audit.enabled=true`
2. Check table name: `shared-lib.audit.table-name=audit.audit_event`
3. Verify database permissions: `GRANT INSERT ON audit.audit_event TO {app_role}`
4. Check application logs for errors

### Issue: Entity audit not working

**Check:**
1. Verify entity has `@EntityListeners(SharedEntityAuditListener.class)`
2. Check configuration: `shared-lib.entity-audit.enabled=true`
3. Verify source table configuration
4. Check JPA transaction is active

### Issue: Hash chain broken

**Possible Causes:**
- Manual data modification
- Concurrent writes without proper locking
- Database restore from backup

**Resolution:**
- Identify break point in chain
- Investigate audit logs around that timestamp
- Contact security team if tampering suspected

---

## Best Practices

### DO:
✅ Always set trace_id for distributed request tracking  
✅ Include meaningful descriptions in audit events  
✅ Use entity audit for sensitive data changes  
✅ Log both successful and failed operations  
✅ Include user_id whenever available  
✅ Tag events with appropriate entity_type and entity_id  

### DON'T:
❌ Log sensitive data (passwords, tokens) in audit metadata  
❌ Skip audit logging for "read-only" operations  
❌ Modify audit tables directly  
❌ Delete audit records (archive instead)  
❌ Use audit tables for operational queries  

---

## Security Considerations

1. **Immutability**: Audit tables should be append-only
2. **Access Control**: Limit DELETE/UPDATE permissions on audit tables
3. **Encryption**: Consider encryption at rest for sensitive audit data
4. **Retention**: Define and enforce data retention policies
5. **Integrity**: Use hash chains for tamper detection on critical entities
6. **Compliance**: Ensure audit logs meet regulatory requirements (GDPR, HIPAA, etc.)

---

## References

- [Request Lifecycle](./request-lifecycle.md) - How audit fits into request processing
- [Data Map](./data-map.md) - Database schema relationships
- [PostgreSQL for Auth](../foundations/postgres-for-auth.md) - Database configuration

---

**Document Version:** 1.0  
**Last Updated:** November 3, 2025  
**Owner:** Platform Team  
**Status:** ✅ Production
