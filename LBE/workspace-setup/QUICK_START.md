# Quick Start - Multi-root Workspace Setup

## For Monorepo (Current Setup)

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd PaymentReconciliation

# 2. Open the workspace from documentation folder
code documentation/LBE/workspace-setup/lbe-services.code-workspace

# 3. Install recommended extensions (when prompted)
```

## For Separate Repositories

```bash
# 1. Clone documentation first to get setup tools
git clone <documentation-repo>
cd documentation/LBE/workspace-setup

# 2. Run the setup script
./clone-all.sh

# 3. Open the workspace
code lbe-services.code-workspace

# Or manually:
mkdir lbe-services && cd lbe-services
git clone <documentation-repo>
git clone <auth-service-repo>
git clone <payment-flow-service-repo>
git clone <reconciliation-service-repo>
git clone <shared-lib-repo>
git clone <admin-ui-repo>

# Download workspace config
cd documentation/LBE/workspace-setup
code lbe-services.code-workspace
```
git clone <admin-ui-repo>

# 2. Download workspace configuration
curl -O https://raw.githubusercontent.com/your-org/developer-setup/main/lbe-services.code-workspace

# 3. Open workspace
code lbe-services.code-workspace
```

## Verify Copilot Integration

In any service Java file, type:
```java
// Fetch active users with pagination using jOOQ DSL
```

Copilot should generate code following `documentation/LBE/guides/data-access-patterns.md`.

## Files Created

- ✅ `lbe-services.code-workspace` - Multi-root workspace configuration
- ✅ `WORKSPACE_SETUP.md` - Detailed setup guide
- ✅ `clone-all.sh` - Automated repository cloning script
- ✅ `auth-service/.github/copilot-instructions.md` - Copilot rules
- ✅ `payment-flow-service/.github/copilot-instructions.md` - Copilot rules
- ✅ `reconciliation-service/.github/copilot-instructions.md` - Copilot rules

## Documentation Structure

```
documentation/
├── LBE/
│   ├── guides/
│   │   ├── data-access-patterns.md ← JPA vs jOOQ vs SQL templates
│   │   ├── request-lifecycle.md    ← How requests flow
│   │   └── ...
│   ├── architecture/
│   │   ├── overview.md             ← System architecture
│   │   └── ...
│   └── foundations/
│       ├── access-control-101.md   ← RBAC explained
│       └── ...
```

All copilot-instructions.md files reference and embed these guidelines.
