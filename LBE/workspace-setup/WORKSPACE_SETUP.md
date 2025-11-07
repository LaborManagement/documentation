# LBE Services - Developer Workspace Setup

This guide helps you set up your local development environment with all services and documentation available in VS Code.

## Prerequisites

- Git
- VS Code
- Java 17+
- Node.js 18+ (for admin-ui)
- Docker (optional, for local PostgreSQL)

---

## Option 1: Multi-root Workspace (Recommended for Full Development)

This approach loads all services and documentation into a single VS Code workspace, enabling GitHub Copilot to reference documentation across all projects.

### Step 1: Clone the Repository

```bash
# Clone the main repository
git clone https://github.com/your-org/PaymentReconciliation.git
cd PaymentReconciliation
```

### Step 2: Open the Workspace File

```bash
# Open VS Code with the workspace configuration
code lbe-services.code-workspace
```

Or in VS Code:
- **File → Open Workspace from File...**
- Select `lbe-services.code-workspace`

### Step 3: Install Recommended Extensions

VS Code will prompt you to install recommended extensions. Click **Install All** or install them manually:

- Java Extension Pack
- Spring Boot Extension Pack
- GitHub Copilot
- GitHub Copilot Chat
- Prettier
- ESLint

### Step 4: Verify Copilot Can See Documentation

1. Open any Java file in `auth-service`
2. Type a comment like: `// Create a method to fetch users using jOOQ`
3. GitHub Copilot should suggest code following the patterns documented in `documentation/LBE/guides/data-access-patterns.md`

---

## Option 2: Individual Service Development

If you only need to work on one service, you can clone it independently. However, Copilot won't have access to the documentation references.

### For Auth Service:

```bash
git clone https://github.com/your-org/auth-service.git
cd auth-service
code .
```

### For Payment Flow Service:

```bash
git clone https://github.com/your-org/payment-flow-service.git
cd payment-flow-service
code .
```

### For Reconciliation Service:

```bash
git clone https://github.com/your-org/reconciliation-service.git
cd reconciliation-service
code .
```

**Note:** When working with individual services, the `.github/copilot-instructions.md` files have embedded guidelines, but you won't have access to the full documentation project for reference.

---

## Option 3: Multiple Repositories Setup

If services are in separate Git repositories, you can still create a multi-root workspace:

### Step 1: Create a Parent Directory

```bash
mkdir lbe-services
cd lbe-services
```

### Step 2: Clone All Repositories

```bash
git clone https://github.com/your-org/documentation.git
git clone https://github.com/your-org/auth-service.git
git clone https://github.com/your-org/payment-flow-service.git
git clone https://github.com/your-org/reconciliation-service.git
git clone https://github.com/your-org/shared-lib.git
git clone https://github.com/your-org/admin-ui.git
```

### Step 3: Create Workspace Configuration

Create `lbe-services.code-workspace` in the parent directory:

```json
{
  "folders": [
    { "name": "📚 Documentation", "path": "documentation" },
    { "name": "🔐 Auth Service", "path": "auth-service" },
    { "name": "💰 Payment Flow Service", "path": "payment-flow-service" },
    { "name": "🔄 Reconciliation Service", "path": "reconciliation-service" },
    { "name": "📦 Shared Library", "path": "shared-lib" },
    { "name": "🎨 Admin UI", "path": "admin-ui" }
  ],
  "settings": {
    "files.exclude": {
      "**/.git": true,
      "**/node_modules": true,
      "**/target": true
    }
  }
}
```

### Step 4: Open the Workspace

```bash
code lbe-services.code-workspace
```

---

## Verifying GitHub Copilot Integration

### Test 1: Data Access Pattern Recognition

In any service, create a new Java file and type:

```java
// Fetch all active users with pagination using jOOQ
```

Copilot should suggest code using `DSLContext` and the patterns from `data-access-patterns.md`.

### Test 2: Cross-Service Reference

In `payment-flow-service`, type:

```java
// Call auth service to verify user permissions
```

Copilot should suggest proper REST client patterns referencing the auth service endpoints.

### Test 3: Documentation Access

1. Open any `.github/copilot-instructions.md` file
2. Verify it contains references like: `documentation/LBE/guides/data-access-patterns.md`
3. Use **Cmd+Click** (Mac) or **Ctrl+Click** (Windows) on the path to verify the file opens

---

## Workspace Benefits

✅ **Single window** - Work across all services without switching VS Code instances  
✅ **Copilot context** - AI has access to documentation and cross-service patterns  
✅ **Unified search** - Find code across all services with Cmd+Shift+F  
✅ **Consistent settings** - Shared formatting, linting, and Java config  
✅ **Easier refactoring** - See impact of shared-lib changes across all services  

---

## Troubleshooting

### Copilot Not Seeing Documentation

1. Verify the workspace file includes the `documentation` folder
2. Check that all paths in the workspace file are relative and correct
3. Reload VS Code: **Cmd+Shift+P** → "Developer: Reload Window"

### Java Errors After Opening Workspace

1. Wait for Java Language Server to initialize (check bottom right status)
2. Run **Cmd+Shift+P** → "Java: Clean Java Language Server Workspace"
3. Restart VS Code

### Git Issues in Multi-root Workspace

Each folder maintains its own Git repository. The Git panel shows all repos. Select the specific repo from the dropdown when committing.

---

## Team Distribution

### For GitHub

1. Commit `lbe-services.code-workspace` to the root of your monorepo
2. Add setup instructions to your main README:
   ```markdown
   ## Getting Started
   
   1. Clone the repository
   2. Open `lbe-services.code-workspace` in VS Code
   3. Install recommended extensions
   ```

### For Separate Repositories

1. Create a separate "developer-setup" repository with:
   - The workspace configuration file
   - This WORKSPACE_SETUP.md guide
   - Clone script (optional)

2. Share with team:
   ```bash
   git clone https://github.com/your-org/developer-setup.git
   cd developer-setup
   ./clone-all.sh  # Script that clones all repos
   code lbe-services.code-workspace
   ```

---

## Next Steps

- Review `.github/copilot-instructions.md` in each service
- Read `documentation/LBE/README.md` for architecture overview
- Check `documentation/LBE/guides/data-access-patterns.md` for coding standards
- Follow `documentation/LBE/onboarding/` guides for service-specific setup

---

**Questions?** Contact the platform team or check the documentation project for detailed guides.
