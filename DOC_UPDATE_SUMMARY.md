# Documentation Update Summary - Capability Removal

**Date:** November 5, 2025  
**Context:** Following the removal of the Capability layer from the authorization system, all documentation has been updated to reflect the simplified Policy → Endpoint model.

---

## ✅ Completed Updates

### Architecture Documentation

1. **`architecture/overview.md`**
   - ✅ Updated sequence diagram to remove "Capabilities + tenant rules" → "Policies + tenant rules"
   - ✅ Changed response status descriptions from "Capability check fails" → "Policy check fails"
   - ✅ Maintained dual relationship model (Backend: User → Role → Policy → Endpoint)

2. **`architecture/permission-patterns.md`**
   - ✅ Completely rewrote Pattern 1 (Read-Only Viewer) to use direct policy-to-endpoint bindings
   - ✅ Removed all SQL creating `auth.capabilities` and `auth.policy_capabilities`
   - ✅ Updated Pattern 2 (Progressive Permissions) with policy-only approach
   - ✅ Updated Pattern 3 (Organization-Based Scoping) to remove capability references
   - ✅ Rewrote Pattern 5 from "Capability Inheritance" to "Policy Inheritance"
   - ✅ Updated troubleshooting section to remove capability checking steps
   - ✅ Changed verification queries to use `auth.endpoint_policies` instead of capability joins

3. **`architecture/request-lifecycle.md`** *(guides/request-lifecycle.md)*
   - ✅ Updated mermaid diagram: "Step 4: Match Capability" → "Step 4: Match Policy"
   - ✅ Changed "Step 2: Load User Context" from "roles → policies → capabilities" to "roles → policies"
   - ✅ Removed capability loading SQL queries
   - ✅ Updated Step 4 logic from capability matching to policy matching
   - ✅ Updated all scenario examples to use policy names instead of capability names
   - ✅ Changed decision matrix: "Missing required capability" → "Missing required policy"
   - ✅ Updated audit log examples: CAPABILITY_MISSING → POLICY_MISSING

### Guide Documentation

4. **`guides/integrate-your-service.md`**
   - ✅ Renamed "Section 2: Provision Capabilities & Policies" → "Provision Policies & Endpoints"
   - ✅ Removed capability creation steps
   - ✅ Updated to focus on endpoint registration and policy linking
   - ✅ Removed @PreAuthorize annotation examples with capability names
   - ✅ Changed rollback plan from "remove capability" to "remove endpoint-policy link"
   - ✅ Updated references from "Capability design pattern" to "Policy design pattern"

5. **`reference/capability-catalog.md`**
   - ✅ Already marked as **LEGACY** with migration notice
   - ✅ Includes references to CAPABILITY_REMOVAL_CONTEXT.md
   - ✅ Redirects readers to policy-matrix.md

---

## ⏳ Remaining Updates Needed

### High Priority

6. **`guides/extend-access.md`** ⚠️
   - ❌ Still references "Design the capability" in scenario
   - ❌ Still has SQL for `INSERT INTO auth.capability`
   - ❌ Still has SQL for `INSERT INTO auth.policy_capability`
   - ❌ Still shows `@PreAuthorize("hasAuthority('payment.ledger.download')")`
   - ❌ Still references capability naming conventions
   - **Action Required:**
     - Change scenario to policy and endpoint design
     - Replace capability SQL with endpoint registration SQL
     - Remove PreAuthorize examples or update to policy-based
     - Update references to policy-naming conventions

7. **`guides/user-management-crud-completion.md`** ⚠️
   - ❌ Line 8-9: References capabilities `user.account.update` and `user.account.delete`
   - ❌ Line 79: Table header includes "Capability" column
   - ❌ Line 89: Flow shows "User → Role → Policy → Capability ↔ Endpoint"
   - ❌ Line 96: References capability names in bullet list
   - **Action Required:**
     - Remove capability column from tables
     - Update flow diagram to "User → Role → Policy → Endpoint"
     - Change references to policy names

8. **`onboarding/setup/README.md`** ⚠️ CRITICAL
   - ❌ Line 13: Architecture shows "User → Role → Policy → Capability ↔ Endpoint"
   - ❌ Line 43: References `03_create_capabilities.sql` migration
   - ❌ Line 45: References `05_link_policies_to_capabilities.sql`
   - ❌ Line 49: References capability_id in page_actions
   - ❌ Line 63: "Capability ↔ Endpoint" authorization description
   - ❌ Line 72: Table header "Capabilities"
   - ❌ Line 92: Foreign keys for `policy_capabilities` and `capability_id`
   - ❌ Line 107: Request flow includes "Capabilities"
   - ❌ Line 114: "User Capabilities → PageActions"
   - ❌ Line 122-123: References capabilities table and policy_capabilities
   - ❌ Line 125: page_actions with capability_id
   - ❌ Line 138: SELECT counting capabilities
   - ❌ Line 151: Count result shows "Capabilities | 91"
   - ❌ Line 160-185: Verification queries using capability joins
   - **Action Required:**
     - Remove migration steps 03 and 05
     - Update all diagrams to remove capability layer
     - Remove capability table references
     - Update verification queries to use policy-endpoint joins only
     - Remove capability_id references from page_actions
     - Update foreign key documentation

9. **`user_pwd.md`** ⚠️
   - ❌ Line 29: "capability setup" in purpose column
   - ❌ Line 175: "## 📊 User Capabilities Summary" section
   - ❌ Line 177: Table header "Capabilities"
   - ❌ Line 223: "✅ 89 Capabilities Configured"
   - ❌ Line 225: "✅ 225 Policy-Capability Links"
   - **Action Required:**
     - Remove "User Capabilities Summary" section entirely
     - Update statistics to show policy counts and endpoint counts
     - Remove capability setup from purpose descriptions

### Medium Priority

10. **`reference/role-catalog.md`** (or `reference/raw/ONBOARDING_ROLES.md`)
    - ❌ Line 10: "Specific Capabilities" section
    - ❌ Line 25: References "98 capabilities"
    - ❌ Line 33: "### Granted Capabilities (55/98)"
    - ❌ Line 42: "RBAC - Capability Management (6)"
    - ❌ Line 52: "/api/admin/capabilities/*" endpoints
    - ❌ Line 69-70: References to creating capabilities and linking policies to capabilities
    - **Action Required:**
      - Remove "Granted Capabilities" sections
      - Replace with "Assigned Policies" sections
      - Update endpoint references to remove /api/admin/capabilities
      - Update role descriptions to focus on policies granted

11. **`reference/policy-matrix.md`**
    - ⏳ Need to verify it shows policy → endpoint mappings directly
    - ⏳ Should NOT show capability intermediary
    - **Action Required:**
      - Review and ensure no capability references
      - Confirm matrix shows: Policy Name | Endpoints | Description

12. **`architecture/policy-binding.md`**
    - ⏳ Need to update relationship diagrams
    - ⏳ Should show: User → Role → Policy → Endpoint
    - ⏳ Remove any capability nodes from mermaid diagrams
    - **Action Required:**
      - Update all mermaid diagrams
      - Remove capability boxes/nodes
      - Simplify relationships to 3-layer model

13. **`reference/raw/ONBOARDING_ARCHITECTURE.md`**
    - ❌ Line 10: "Capabilities | 98 atomic capabilities"
    - ❌ Line 13: "Policy-capability links | 288"
    - ❌ Line 30: DB2 references "auth.capabilities / mappings"
    - ❌ Line 56: "Required policy + capabilities"
    - ❌ Line 57: "Verify capability grants"
    - ❌ Line 66: "policy or capability mismatch"
    - ❌ Line 74: "Capability bundle" row in table
    - ❌ Line 81: "Approx. Capabilities" column header
    - ❌ Line 91: "capability lists" reference
    - ❌ Line 95-97: References to capabilities in setup steps
    - **Action Required:**
      - Mark file as ARCHIVE or LEGACY
      - Add header warning about outdated architecture
      - Or update all references to remove capability layer

---

## Migration Script Status

### Database Migrations
- ✅ `001_remove_capabilities_part_a.sql` - Created (drops FKs and junction table)
- ✅ `002_remove_capabilities_part_b.sql` - Created (drops capabilities table)
- ⏳ Not yet executed in production

### Code Changes
- ✅ Capability.java - Deleted
- ✅ PolicyCapability.java - Deleted
- ✅ CapabilityRepository.java - Deleted
- ✅ PolicyCapabilityRepository.java - Deleted
- ✅ CapabilityController.java - Deleted
- ✅ RoleService.java - Capability references removed
- ✅ ServiceCatalogService.java - Refactored to policy-based
- ✅ UIConfigService.java - Migrated to policy-based
- ✅ PolicyController.java - Capability endpoints removed
- ✅ PageActionController.java - Capability dependency removed

---

## Documentation Standards (Post-Migration)

### Terminology Changes
| Old Term | New Term |
|----------|----------|
| Capability | Policy (in authorization context) |
| User has capability X | User has policy Y (which grants access to endpoint Z) |
| Capability check | Policy check |
| capability_id | (removed) |
| policy_capabilities table | (removed) |
| User → Role → Policy → Capability → Endpoint | User → Role → Policy → Endpoint |

### SQL Pattern Changes

**OLD Pattern:**
```sql
-- Create capability
INSERT INTO auth.capabilities (name, description) VALUES (...);

-- Link to policy
INSERT INTO auth.policy_capabilities (policy_id, capability_id) 
SELECT p.id, c.id FROM auth.policies p, auth.capabilities c WHERE ...;

-- Verify
SELECT c.name FROM auth.capabilities c 
JOIN auth.policy_capabilities pc ON c.id = pc.capability_id
WHERE ...;
```

**NEW Pattern:**
```sql
-- Register endpoint
INSERT INTO auth.endpoints (method, path, label, description) VALUES (...);

-- Link to policy
INSERT INTO auth.endpoint_policies (endpoint_id, policy_id)
SELECT e.id, p.id FROM auth.endpoints e, auth.policies p WHERE ...;

-- Verify
SELECT e.method, e.path, p.name 
FROM auth.endpoints e
JOIN auth.endpoint_policies ep ON e.id = ep.endpoint_id
JOIN auth.policies p ON ep.policy_id = p.id
WHERE ...;
```

### Diagram Pattern Changes

**OLD Flow:**
```
Request → JWT → Roles → Policies → Capabilities → Endpoints → Data (RLS)
```

**NEW Flow:**
```
Request → JWT → Roles → Policies → Endpoints → Data (RLS)
```

---

## Verification Checklist

After completing remaining updates:

- [ ] Search entire docs/ folder for "capability" (case-insensitive)
- [ ] Verify no SQL references to `auth.capabilities`
- [ ] Verify no SQL references to `auth.policy_capabilities`
- [ ] Verify no Java code examples with `hasAuthority('capability.name')`
- [ ] Verify all mermaid diagrams show 3-layer model (Role → Policy → Endpoint)
- [ ] Verify all verification queries use `endpoint_policies` not `policy_capabilities`
- [ ] Update all migration step lists to remove capability creation steps
- [ ] Verify API documentation references `/api/meta/*` instead of capability endpoints

---

## Files Not Requiring Updates

The following files contain minimal or context-appropriate capability references:

- ✅ `auth-service/CAPABILITY_REMOVAL_CONTEXT.md` - Tracking document (intentionally references capabilities)
- ✅ `reference/capability-catalog.md` - Marked as LEGACY with proper redirects
- ✅ `architecture/audit-*.md` - Historical references are acceptable if clearly marked
- ✅ `reference/raw/*` - Legacy documentation archives

---

## Next Steps

1. Complete updates to high-priority files (6-9) above
2. Update medium-priority files (10-13)
3. Run global search for remaining capability references
4. Execute database migrations in staging environment
5. Verify application functionality after migrations
6. Update this summary document as final checklist

---

## Notes

- All timestamps reference "November 2025" context
- Policy-based model significantly simplifies the authorization layer
- UI now uses page_actions → endpoints directly, no capability intermediary
- Backend authorization checks user policies against endpoint_policies table
- RLS remains unchanged (still provides tenant-level data isolation)
