# LBE Platform Documentation

Follow this path step by step—each document links directly to the next so you always know where to go.

## 🚀 Quick Start

**New to the platform?** Start here:
- **[Workspace Setup](workspace-setup/QUICK_START.md)** – Get your development environment running in 5 minutes
- **[Full Setup Guide](workspace-setup/WORKSPACE_SETUP.md)** – Detailed multi-root workspace configuration

## Guided Path

1. **Step 1 · [Architecture Overview](architecture/overview.md)**  
   Meet every component and see how authentication and authorization fit together.  
   → Next: **Step 2 · [Data Map](architecture/data-map.md)**

2. **Step 2 · [Data Map](architecture/data-map.md)**  
   Understand how tables relate (users → roles → policies → capabilities → endpoints → tenant ACL).  
   → Visual Guides:
   - **[Request Lifecycle Flowchart](architecture/request-lifecycle.md)** – How a request flows through the system
   - **[Policy Binding Relationships](architecture/policy-binding.md)** – How permissions interconnect
   - **[Common Permission Patterns](architecture/permission-patterns.md)** – Real-world setup examples
   - **[Audit Design](architecture/audit-design.md)** – Centralized audit logging and compliance tracking  
   → Next: **Step 3 · [Journey: Login To Data](guides/login-to-data.md)**

3. **Step 3 · [Journey: Login To Data](guides/login-to-data.md)**  
   Follow worker, employer, and board personas from login through JWT validation, authorization, and RLS.  
   → Next: **Step 4 · [RBAC Setup Playbook](guides/setup/rbac.md)**

4. **Step 4 · [RBAC Setup Playbook](guides/setup/rbac.md)**  
   Create roles, policies, capabilities, endpoints, and UI wiring in the correct order.  
   → Next: **Step 5 · [VPD Setup Playbook](guides/setup/vpd.md)**

5. **Step 5 · [VPD Setup Playbook](guides/setup/vpd.md)**  
   Configure row-level security, load tenant ACL, and test contrasting users.  
   → Next: **Step 6 · [Role Catalog](reference/role-catalog.md)**

6. **Step 6 · [Role Catalog](reference/role-catalog.md)**  
   Drop into the concise references (roles → capabilities → policies → VPD → operations → audit) with links into raw data.  
   → Continue through the reference loop:  
   `[Capability Catalog](reference/capability-catalog.md)` *(legacy recap)* → `[Policy Matrix](reference/policy-matrix.md)` → `[VPD Checklist](reference/vpd-checklist.md)` → `[Audit Quick Reference](reference/audit-quick-reference.md)` → `[PostgreSQL Operations](reference/postgres-operations.md)` → `[Raw Reference Index](reference/raw/README.md)`

## Optional Companions

- **Story Prelude** – `start/welcome.md`, `start/platform-tour.md`, `start/role-stories.md`
- **Concept Primers** – `foundations/access-control-101.md`, `foundations/data-guardrails-101.md`, `foundations/postgres-for-auth.md`
- **Troubleshooting** – `playbooks/troubleshoot-auth.md`
- **Bootstrap SQL** – `onboarding/setup/` (run alongside Steps 4 and 5)
- **Data Access Patterns** – `guides/data-access-patterns.md` (when choosing between JPA, jOOQ DSL, or SQL templates)

## 🛠️ Developer Tools

### GitHub Copilot Integration

Each service includes `.github/copilot-instructions.md` with embedded coding standards. These files ensure Copilot generates code following platform patterns:

- **auth-service** – RBAC, JWT validation, policy enforcement
- **payment-flow-service** – Payment processing, worker/employer management
- **reconciliation-service** – Transaction matching, settlement processing

### Multi-root Workspace Setup

For the best development experience with cross-service context:

1. **[Quick Start](workspace-setup/QUICK_START.md)** – Fast setup commands
2. **[Full Setup Guide](workspace-setup/WORKSPACE_SETUP.md)** – Detailed configuration options
3. **[Clone Script](workspace-setup/clone-all.sh)** – Automated repository cloning
4. **[Workspace Config](workspace-setup/lbe-services.code-workspace)** – VS Code multi-root workspace

**Benefits:**
- ✅ GitHub Copilot can reference documentation across all projects
- ✅ Unified search across services
- ✅ Single VS Code window for all services
- ✅ Consistent formatting and code generation

## Keeping Docs In Sync

- Update the guided path first and verify each “Next” link.
- Surface new details in the reference summaries; point to `reference/raw/` for exhaustive tables.
- When schemas or capabilities change, adjust the playbooks and matching reference sheet together.
- Capture cross-service release notes in `reference/recent-updates.md` so reviewers can see the latest commits before diving into deep references.
