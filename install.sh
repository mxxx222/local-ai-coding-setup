#!/bin/bash

# Local AI Coding Setup - Main Installation Script
# Universal setup script that detects hardware and installs appropriate components

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# Display banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "    ╔══════════════════════════════════════╗"
    echo "    ║      Local AI Coding Setup           ║"
    echo "    ║                                      ║"
    echo "    ║  🚀 Private • 🔒 Secure • 🏃 Fast   ║"
    echo "    ║                                      ║"
    echo "    ║  Setup local AI models for coding   ║"
    echo "    ║  with VS Code integration           ║"
    echo "    ╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local has_errors=false
    
    # Check for required commands
    local required_commands=("curl" "git" "python3")
    for cmd in "${required_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_success "✓ $cmd is available"
        else
            print_error "✗ $cmd is missing"
            has_errors=true
        fi
    done
    
    # Check disk space (minimum 20GB)
    local available_space
    if [[ "$OSTYPE" == "darwin"* ]]; then
        available_space=$(df -h . | tail -1 | awk '{print $4}' | sed 's/G//')
    else
        available_space=$(df -h . | tail -1 | awk '{print $4}' | sed 's/G//')
    fi
    
    if (( $(echo "$available_space > 20" | bc -l) 2>/dev/null || [[ $available_space -ge 20 ]] )); then
        print_success "✓ Sufficient disk space: ${available_space}GB"
    else
        print_warning "⚠ Low disk space: ${available_space}GB (recommended: 20GB+)"
    fi
    
    # Check internet connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "✓ Internet connectivity confirmed"
    else
        print_error "✗ No internet connection detected"
        has_errors=true
    fi
    
    if $has_errors; then
        print_error "Prerequisites check failed. Please install missing requirements."
        exit 1
    fi
}

# Run hardware detection
run_hardware_detection() {
    print_header "Hardware Detection"
    
    if [[ -f "scripts/hardware_detection.sh" ]]; then
        chmod +x scripts/hardware_detection.sh
        ./scripts/hardware_detection.sh
    else
        print_warning "Hardware detection script not found. Continuing with generic setup."
    fi
}

# Interactive setup selection
setup_selection() {
    print_header "Setup Configuration"
    
    echo "Choose your setup type:"
    echo "1) Automatic (Recommended) - Hardware detection + optimized setup"
    echo "2) Manual - Choose specific platforms"
    echo "3) Ollama only - Fastest setup, good performance"
    echo "4) Full stack - All platforms (takes longest)"
    echo "5) Custom - Select individual components"
    echo ""
    
    read -p "Enter your choice (1-5): " choice
    
    case $choice in
        1)
            print_status "Running automatic setup..."
            run_hardware_detection
            ;;
        2)
            print_status "Manual setup selected..."
            manual_setup
            ;;
        3)
            print_status "Ollama-only setup..."
            ollama_only_setup
            ;;
        4)
            print_status "Full stack setup..."
            full_stack_setup
            ;;
        5)
            print_status "Custom setup..."
            custom_setup
            ;;
        *)
            print_warning "Invalid choice. Running automatic setup."
            run_hardware_detection
            ;;
    esac
}

# Manual setup selection
manual_setup() {
    echo ""
    echo "Select platforms to install:"
    echo "1) Ollama (Recommended - Easy setup, good performance)"
    echo "2) LM Studio (GUI-based, good for experimentation)"
    echo "3) llama.cpp (Maximum performance, advanced users)"
    echo ""
    
    read -p "Enter platform numbers (e.g., '1 2' or '1 3'): " platforms
    
    for platform in $platforms; do
        case $platform in
            1)
                install_ollama
                ;;
            2)
                configure_lm_studio
                ;;
            3)
                install_llama_cpp
                ;;
            *)
                print_warning "Invalid platform: $platform"
                ;;
        esac
    done
}

# Ollama-only setup
ollama_only_setup() {
    print_status "Setting up Ollama only..."
    install_ollama
}

# Full stack setup
full_stack_setup() {
    print_status "Setting up full stack..."
    install_ollama
    configure_lm_studio
    install_llama_cpp
}

# Custom setup
custom_setup() {
    echo ""
    echo "Custom installation options:"
    echo "1) Install and configure Ollama"
    echo "2) Download code-focused models"
    echo "3) Configure VS Code extensions"
    echo "4) Set up health monitoring"
    echo "5) Run system health check"
    echo ""
    
    read -p "Enter option numbers to install (e.g., '1 2 3'): " options
    
    for option in $options; do
        case $option in
            1)
                install_ollama
                ;;
            2)
                download_models
                ;;
            3)
                setup_vscode
                ;;
            4)
                setup_monitoring
                ;;
            5)
                run_health_check
                ;;
            *)
                print_warning "Invalid option: $option"
                ;;
        esac
    done
}

# Install Ollama
install_ollama() {
    print_status "Installing Ollama..."
    
    if [[ -f "scripts/install_ollama.sh" ]]; then
        chmod +x scripts/install_ollama.sh
        ./scripts/install_ollama.sh
    else
        print_error "Ollama installation script not found"
        return 1
    fi
}

# Configure LM Studio
configure_lm_studio() {
    print_status "Configuring LM Studio..."
    
    if [[ -f "scripts/configure_lm_studio.sh" ]]; then
        chmod +x scripts/configure_lm_studio.sh
        ./scripts/configure_lm_studio.sh
    else
        print_warning "LM Studio configuration script not found"
    fi
}

# Install llama.cpp
install_llama_cpp() {
    print_status "Installing llama.cpp..."
    
    if [[ -f "scripts/install_llama_cpp.sh" ]]; then
        chmod +x scripts/install_llama_cpp.sh
        ./scripts/install_llama_cpp.sh
    else
        print_error "llama.cpp installation script not found"
        return 1
    fi
}

# Download models
download_models() {
    print_status "Downloading recommended models..."
    
    # This would typically be handled by individual platform scripts
    print_info "Models will be downloaded during platform setup"
}

# Setup VS Code
setup_vscode() {
    print_status "Setting up VS Code configuration..."
    
    if [[ -f "configs/continue_config.json" ]]; then
        mkdir -p ~/.continue
        cp configs/continue_config.json ~/.continue/config.json
        print_success "Continue.dev configuration applied"
    fi
    
    if [[ -f "configs/vscode_settings.json" ]]; then
        mkdir -p ~/.vscode
        cp configs/vscode_settings.json ~/.vscode/settings.json
        print_success "VS Code settings applied"
    fi
    
    print_info "Installing VS Code extensions..."
    if command -v code >/dev/null 2>&1; then
        code --install-extension continue.continue
        print_success "Continue.dev extension installed"
    else
        print_warning "VS Code not found. Please install extensions manually."
    fi
}

# Setup monitoring
setup_monitoring() {
    print_status "Setting up health monitoring..."
    
    if [[ -f "scripts/health_check.py" ]]; then
        chmod +x scripts/health_check.py
        print_success "Health check script configured"
    fi
}

# Run health check
run_health_check() {
    print_status "Running system health check..."
    
    if [[ -f "scripts/health_check.py" ]]; then
        python3 scripts/health_check.py
    else
        print_error "Health check script not found"
    fi
}

# Final setup verification
verify_setup() {
    print_header "Setup Verification"
    
    # Check if Ollama is running
    if pgrep -f ollama >/dev/null; then
        print_success "✓ Ollama is running"
    else
        print_warning "⚠ Ollama is not running (start with: ~/.ollama/start.sh)"
    fi
    
    # Check VS Code configuration
    if [[ -f "~/.continue/config.json" ]]; then
        print_success "✓ VS Code Continue.dev configured"
    else
        print_warning "⚠ VS Code not configured (run setup_vscode)"
    fi
    
    # Check model availability
    if command -v ollama >/dev/null 2>&1; then
        local model_count=$(ollama list 2>/dev/null | wc -l || echo "0")
        if [[ $model_count -gt 1 ]]; then
            print_success "✓ Models are available ($((model_count-1)) models)"
        else
            print_warning "⚠ No models downloaded yet"
        fi
    fi
}

# Show completion summary
show_completion_summary() {
    print_header "Setup Complete!"
    
    echo ""
    echo -e "${GREEN}🎉 Local AI Coding Setup Complete!${NC}"
    echo ""
    echo "📋 What's been installed:"
    echo "   • Ollama with code-focused AI models"
    echo "   • VS Code integration (Continue.dev)"
    echo "   • Health monitoring and diagnostics"
    echo "   • Platform management scripts"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Start coding in VS Code"
    echo "   2. Select your preferred model in Continue settings"
    echo "   3. Try the examples in docs/quick_start.md"
    echo ""
    echo "📚 Documentation:"
    echo "   • Quick Start: docs/quick_start.md"
    echo "   • Troubleshooting: docs/troubleshooting.md"
    echo "   • Full Guide: README.md"
    echo ""
    echo "🛠️  Management Commands:"
    echo "   • Health Check: python3 scripts/health_check.py"
    echo "   • System Monitor: ./monitor_[tier].sh"
    echo "   • Ollama Control: ~/.ollama/start.sh | stop.sh | status.sh"
    echo ""
    echo "💡 Pro Tips:"
    echo "   • Run health checks regularly"
    echo "   • Monitor system resources during heavy usage"
    echo "   • Try different models for different tasks"
    echo "   • Keep configurations backed up"
    echo ""
    echo -e "${PURPLE}Happy coding with AI! 🤖💻${NC}"
}

# Main installation flow
main() {
    show_banner
    check_prerequisites
    
    echo ""
    read -p "Press Enter to continue with setup..."
    
    setup_selection
    
    verify_setup
    run_health_check
    show_completion_summary
    
    echo ""
    read -p "Press Enter to exit..."
}

# Handle script interruption
trap 'print_warning "\nSetup interrupted by user"; exit 1' INT

# Run main function
main "$@"