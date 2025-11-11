#!/bin/bash

# LBE Services - Clone All Repositories Script
# This script helps developers quickly clone all service repositories

set -e  # Exit on error

echo "🚀 LBE Services - Repository Setup"
echo "===================================="
echo ""

# Configuration - Update these URLs with your actual repository locations
GITHUB_ORG="LaborManagement"  # Change this to your GitHub organization or username
BASE_URL="https://github.com/${GITHUB_ORG}"

# Repositories to clone
REPOS=(
    "documentation"
    "auth-service"
    "payment-flow-service"
    "reconciliation-service"
    "shared-lib"
    "admin-ui"
)

# Create parent directory
WORKSPACE_DIR="lbe-services"
echo "📁 Creating workspace directory: ${WORKSPACE_DIR}"
mkdir -p "${WORKSPACE_DIR}"
cd "${WORKSPACE_DIR}"

# Clone each repository
echo ""
echo "📥 Cloning repositories..."
echo ""

for repo in "${REPOS[@]}"; do
    if [ -d "${repo}" ]; then
        echo "⏭️  Skipping ${repo} (already exists)"
    else
        echo "📦 Cloning ${repo}..."
        git clone "${BASE_URL}/${repo}.git" || {
            echo "⚠️  Failed to clone ${repo}. Continuing..."
        }
    fi
done

echo ""
echo "✅ Repository cloning complete!"
echo ""

# Create workspace configuration if it doesn't exist
WORKSPACE_FILE="lbe-services.code-workspace"
if [ ! -f "${WORKSPACE_FILE}" ]; then
    echo "📝 Creating VS Code workspace configuration..."
    cat > "${WORKSPACE_FILE}" << 'EOF'
{
  "folders": [
    {
      "name": "📚 Documentation",
      "path": "documentation"
    },
    {
      "name": "🔐 Auth Service",
      "path": "auth-service"
    },
    {
      "name": "💰 Payment Flow Service",
      "path": "payment-flow-service"
    },
    {
      "name": "🔄 Reconciliation Service",
      "path": "reconciliation-service"
    },
    {
      "name": "📦 Shared Library",
      "path": "shared-lib"
    },
    {
      "name": "🎨 Admin UI",
      "path": "admin-ui"
    }
  ],
  "settings": {
    "files.exclude": {
      "**/.git": true,
      "**/node_modules": true,
      "**/target": true,
      "**/.DS_Store": true
    },
    "search.exclude": {
      "**/node_modules": true,
      "**/target": true,
      "**/.git": true
    },
    "java.configuration.updateBuildConfiguration": "automatic",
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
      "source.organizeImports": "explicit"
    }
  },
  "extensions": {
    "recommendations": [
      "vscjava.vscode-java-pack",
      "vmware.vscode-spring-boot",
      "GitHub.copilot",
      "GitHub.copilot-chat",
      "esbenp.prettier-vscode",
      "dbaeumer.vscode-eslint"
    ]
  }
}
EOF
    echo "✅ Workspace configuration created!"
else
    echo "⏭️  Workspace configuration already exists"
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Open VS Code workspace:"
echo "   cd ${WORKSPACE_DIR}"
echo "   code ${WORKSPACE_FILE}"
echo ""
echo "2. Install recommended extensions when prompted"
echo ""
echo "3. Verify GitHub Copilot can see documentation by:"
echo "   - Opening any Java file in auth-service"
echo "   - Typing: // Fetch users using jOOQ"
echo "   - Copilot should follow patterns from documentation/LBE/guides/"
echo ""
echo "📚 See WORKSPACE_SETUP.md for detailed instructions"
echo ""
