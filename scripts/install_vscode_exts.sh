#!/bin/bash

# VS Code Extensions Installation Script
# Installs recommended extensions for AI-powered coding

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if VS Code is installed
check_vscode() {
    print_status "Checking VS Code installation..."

    if command -v code >/dev/null 2>&1; then
        print_success "VS Code is installed"
        return 0
    else
        print_error "VS Code is not installed or not in PATH"
        print_status "Please install VS Code from: https://code.visualstudio.com/"
        return 1
    fi
}

# Install extension with error handling
install_extension() {
    local extension_id="$1"
    local extension_name="$2"

    print_status "Installing $extension_name..."

    if code --install-extension "$extension_id" --force >/dev/null 2>&1; then
        print_success "✓ $extension_name installed"
    else
        print_warning "⚠ Failed to install $extension_name"
    fi
}

# Core AI extensions
install_ai_extensions() {
    print_status "Installing AI and coding extensions..."

    # Continue.dev - Main AI coding assistant
    install_extension "continue.continue" "Continue.dev"

    # GitHub Copilot (optional alternative)
    # install_extension "github.copilot" "GitHub Copilot"

    # Tabnine (optional alternative)
    # install_extension "tabnine.tabnine-vscode" "Tabnine AI"
}

# Language support extensions
install_language_extensions() {
    print_status "Installing language support extensions..."

    # Python
    install_extension "ms-python.python" "Python"
    install_extension "ms-python.black-formatter" "Black Formatter"
    install_extension "ms-python.flake8" "Flake8"

    # JavaScript/TypeScript
    install_extension "ms-vscode.vscode-typescript-next" "TypeScript Importer"

    # Go
    install_extension "golang.go" "Go"

    # Rust
    install_extension "rust-lang.rust-analyzer" "Rust Analyzer"

    # Java
    install_extension "redhat.java" "Java Language Support"

    # C/C++
    install_extension "ms-vscode.cpptools" "C/C++"
}

# Development tools
install_dev_tools() {
    print_status "Installing development tools..."

    # Git integration
    install_extension "eamodio.gitlens" "GitLens"
    install_extension "ms-vscode.vscode-git-graph" "Git Graph"

    # Docker
    install_extension "ms-azuretools.vscode-docker" "Docker"

    # Remote development
    install_extension "ms-vscode-remote.remote-ssh" "Remote SSH"
    install_extension "ms-vscode-remote.remote-containers" "Dev Containers"

    # Testing
    install_extension "hbenl.vscode-test-explorer" "Test Explorer"
    install_extension "ms-vscode.test-adapter-converter" "Test Adapter Converter"
}

# Productivity extensions
install_productivity_extensions() {
    print_status "Installing productivity extensions..."

    # Code formatting and linting
    install_extension "esbenp.prettier-vscode" "Prettier"
    install_extension "ms-vscode.vscode-json" "JSON Tools"

    # Themes and icons
    install_extension "pkief.material-icon-theme" "Material Icon Theme"
    install_extension "dracula-theme.theme-dracula" "Dracula Official"

    # Utilities
    install_extension "ms-vscode.vscode-terminal-here" "Terminal Here"
    install_extension "alefragnani.bookmarks" "Bookmarks"
    install_extension "gruntfuggly.todo-tree" "Todo Tree"
}

# Configure VS Code settings
configure_vscode() {
    print_status "Configuring VS Code settings..."

    local settings_dir="$HOME/.vscode"
    local settings_file="$settings_dir/settings.json"

    # Create settings directory if it doesn't exist
    mkdir -p "$settings_dir"

    # Check if settings file exists, create backup if it does
    if [[ -f "$settings_file" ]]; then
        cp "$settings_file" "${settings_file}.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Backed up existing settings"
    fi

    # Apply our recommended settings
    if [[ -f "configs/vscode_settings.json" ]]; then
        cp "configs/vscode_settings.json" "$settings_file"
        print_success "VS Code settings applied"
    else
        print_warning "VS Code settings config not found"
    fi
}

# Main installation function
main() {
    echo -e "${BLUE}VS Code Extensions Installation${NC}"
    echo "================================"

    if ! check_vscode; then
        exit 1
    fi

    echo ""
    read -p "This will install recommended VS Code extensions. Continue? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled"
        exit 0
    fi

    install_ai_extensions
    echo ""
    install_language_extensions
    echo ""
    install_dev_tools
    echo ""
    install_productivity_extensions
    echo ""
    configure_vscode

    echo ""
    print_success "VS Code extensions installation complete!"
    echo ""
    echo "Next steps:"
    echo "1. Restart VS Code to activate extensions"
    echo "2. Configure Continue.dev with your preferred models"
    echo "3. Check extension settings for customization"
    echo ""
    echo "Installed extensions can be managed via:"
    echo "VS Code → Extensions (Ctrl+Shift+X) → Installed"
}

# Run main function
main "$@"