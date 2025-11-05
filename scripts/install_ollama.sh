#!/bin/bash

# Ollama Installation Script
# Installs and configures Ollama with uncensored AI models

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

# Check system requirements
check_system() {
    print_status "Checking system requirements..."
    
    # Check OS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "This script is optimized for macOS. Other platforms may need adjustments."
    fi
    
    # Check if Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Check available disk space (minimum 20GB)
    AVAILABLE_SPACE=$(df -h . | tail -1 | awk '{print $4}' | sed 's/G//')
    if (( $(echo "$AVAILABLE_SPACE > 20" | bc -l) 2>/dev/null || [[ $AVAILABLE_SPACE -ge 20 ]] )); then
        print_success "Sufficient disk space: ${AVAILABLE_SPACE}GB"
    else
        print_error "Insufficient disk space: ${AVAILABLE_SPACE}GB (requires 20GB+)"
        exit 1
    fi
    
    # Check internet connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "Internet connectivity confirmed"
    else
        print_error "No internet connection detected"
        exit 1
    fi
}

# Install Ollama
install_ollama() {
    print_status "Installing Ollama..."
    
    if command -v ollama >/dev/null 2>&1; then
        print_success "Ollama already installed"
        return 0
    fi
    
    # Install via Homebrew
    brew install ollama
    
    print_success "Ollama installed successfully"
}

# Configure Ollama
configure_ollama() {
    print_status "Configuring Ollama..."
    
    # Create Ollama directory structure
    mkdir -p ~/.ollama/models
    
    # Set up environment variables for optimal performance
    print_status "Setting up environment variables..."
    
    # Detect hardware and set optimal GPU layers
    if [[ $(sysctl -n machdep.cpu.brand_string) == *"Apple"* ]]; then
        export LLAMA_METAL=1
        export OLLAMA_NUM_GPU=35
        print_success "Apple Silicon detected - Metal GPU acceleration enabled"
    elif command -v nvidia-smi >/dev/null 2>&1; then
        export OLLAMA_NUM_GPU=35
        print_success "NVIDIA GPU detected - CUDA acceleration enabled"
    else
        export OLLAMA_NUM_GPU=0
        print_warning "CPU-only system detected"
    fi
    
    # Set optimal thread count
    export OMP_NUM_THREADS=$(sysctl -n hw.ncpu)
    export OLLAMA_MAX_CONTEXT=32768
    
    # Create environment file
    cat > ~/.ollama_env << EOF
# Ollama Environment Configuration
export OLLAMA_NUM_GPU=$OLLAMA_NUM_GPU
export OLLAMA_MAX_CONTEXT=32768
export OMP_NUM_THREADS=$OMP_NUM_THREADS
export LLAMA_METAL=$LLAMA_METAL

# Performance optimizations
export OLLAMA_ORIGINS=*
export OLLAMA_HOST=127.0.0.1:11434
EOF
    
    print_success "Environment configuration created"
}

# Download recommended models
download_models() {
    print_status "Downloading recommended uncensored models..."
    
    # Ensure Ollama is running
    if ! pgrep -f ollama >/dev/null; then
        print_status "Starting Ollama service..."
        ollama serve &
        sleep 3
    fi
    
    # Check available RAM and select appropriate models
    TOTAL_RAM=$(sysctl -n hw.memsize)
    RAM_GB=$((TOTAL_RAM / 1024 / 1024 / 1024))
    
    print_status "System RAM: ${RAM_GB}GB"
    
    # Define model tiers based on RAM
    if [[ $RAM_GB -ge 64 ]]; then
        print_status "64GB+ RAM - Downloading high-end models"
        MODELS=(
            "dolphin-2.9.2-qwen2.5:72b"
            "wizardlm-2-8x22b:uncensored" 
            "dolphin-mixtral:8x7b-v2.7"
            "dolphin-mistral:7b-dpo-laser"
            "nous-hermes2:solar-10.7b"
        )
    elif [[ $RAM_GB -ge 32 ]]; then
        print_status "32GB+ RAM - Downloading premium models"
        MODELS=(
            "dolphin-mixtral:8x7b-v2.7"
            "wizardlm-uncensored:13b"
            "dolphin-mistral:7b-dpo-laser"
            "nous-hermes2:solar-10.7b"
            "llama-3.1-70b-lexi-uncensored"
        )
    elif [[ $RAM_GB -ge 16 ]]; then
        print_status "16GB+ RAM - Downloading balanced models"
        MODELS=(
            "wizardlm-uncensored:13b"
            "dolphin-mistral:7b-dpo-laser"
            "nous-hermes2:solar-10.7b"
            "dolphin-2.6-mistral-7b"
        )
    elif [[ $RAM_GB -ge 8 ]]; then
        print_status "8GB+ RAM - downloading lightweight models"
        MODELS=(
            "dolphin-mistral:7b-dpo-laser"
            "dolphin-2.6-mistral-7b"
            "nous-hermes2:solar-10.7b"
        )
    else
        print_warning "Less than 8GB RAM - using minimal setup"
        MODELS=(
            "dolphin-mistral:7b-dpo-laser"
        )
    fi
    
    # Download models
    for model in "${MODELS[@]}"; do
        print_status "Downloading $model..."
        if ollama pull "$model"; then
            print_success "✓ $model downloaded successfully"
        else
            print_warning "⚠ Failed to download $model (may not exist or network issue)"
        fi
    done
    
    # Test model availability
    print_status "Available models:"
    ollama list | grep -E "(NAME|ollama)" || ollama list
}

# Create management scripts
create_management_scripts() {
    print_status "Creating management scripts..."
    
    # Start script
    cat > ~/.ollama/start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Ollama service..."
export OLLAMA_NUM_GPU=35
export LLAMA_METAL=1
export OMP_NUM_THREADS=$(sysctl -n hw.ncpu)
export OLLAMA_MAX_CONTEXT=32768

ollama serve &
sleep 3

echo "✅ Ollama is now running"
echo "📋 Available models:"
ollama list
echo ""
echo "🔧 Service URL: http://localhost:11434"
echo "📖 API docs: http://localhost:11434/docs"
EOF

    # Stop script
    cat > ~/.ollama/stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping Ollama service..."
pkill -f ollama || killall ollama
echo "✅ Ollama stopped"
EOF

    # Status script
    cat > ~/.ollama/status.sh << 'EOF'
#!/bin/bash
echo "🔍 Ollama Status Check"
echo "======================"

if pgrep -f ollama >/dev/null; then
    echo "✅ Ollama is running"
    echo ""
    echo "📋 Available models:"
    ollama list
    echo ""
    echo "🔧 Service endpoints:"
    echo "  - Main API: http://localhost:11434"
    echo "  - Health: http://localhost:11434/api/health"
    echo "  - Models: http://localhost:11434/api/tags"
else
    echo "❌ Ollama is not running"
fi
EOF

    # Model management script
    cat > ~/.ollama/models.sh << 'EOF'
#!/bin/bash
echo "🤖 Ollama Model Management"
echo "=========================="
echo ""
echo "1) List installed models"
echo "2) Download a model"
echo "3) Remove a model"
echo "4) Test a model"
echo "5) Get model info"
echo ""

read -p "Select option (1-5): " choice

case $choice in
    1)
        echo "📋 Installed models:"
        ollama list
        ;;
    2)
        read -p "Enter model name: " model
        echo "Downloading $model..."
        ollama pull "$model"
        ;;
    3)
        read -p "Enter model name to remove: " model
        echo "Removing $model..."
        ollama rm "$model"
        ;;
    4)
        echo "📋 Available models:"
        ollama list
        echo ""
        read -p "Enter model name to test: " model
        echo "Testing $model (Ctrl+C to stop)..."
        ollama run "$model"
        ;;
    5)
        read -p "Enter model name: " model
        echo "Getting info for $model..."
        ollama show "$model"
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF

    # Health check script
    cat > ~/.ollama/health.sh << 'EOF'
#!/bin/bash
echo "🏥 Ollama Health Check"
echo "======================"

# Check if Ollama is running
if pgrep -f ollama >/dev/null; then
    echo "✅ Service Status: Running"
else
    echo "❌ Service Status: Not Running"
    exit 1
fi

# Check API endpoint
if curl -s http://localhost:11434/api/health >/dev/null; then
    echo "✅ API Endpoint: Responding"
else
    echo "❌ API Endpoint: Not Responding"
    exit 1
fi

# Check models
MODEL_COUNT=$(ollama list 2>/dev/null | wc -l || echo "0")
if [[ $MODEL_COUNT -gt 1 ]]; then
    echo "✅ Models: $((MODEL_COUNT-1)) installed"
else
    echo "❌ Models: None installed"
fi

# System resource check
echo ""
echo "📊 System Resources:"
echo "  CPU: $(sysctl -n hw.ncpu) cores"
echo "  Memory: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))GB"
echo "  Storage: $(df -h . | tail -1 | awk '{print $4}') available"
EOF

    # Make all scripts executable
    chmod +x ~/.ollama/*.sh
    
    print_success "Management scripts created"
    print_info "Scripts location: ~/.ollama/"
}

# Test installation
test_installation() {
    print_status "Testing installation..."
    
    # Check if Ollama is running
    if ! curl -s http://localhost:11434/api/health >/dev/null; then
        print_warning "Ollama service not responding, starting it..."
        ~/.ollama/start.sh
        sleep 3
    fi
    
    # Test with a simple prompt
    print_status "Testing model with a coding prompt..."
    
    # Try to run a test prompt with the smallest available model
    TEST_MODEL="dolphin-mistral:7b-dpo-laser"
    
    if ollama list | grep -q "$TEST_MODEL"; then
        print_status "Testing with $TEST_MODEL..."
        
        # Create a simple test prompt
        TEST_PROMPT="Write a Python function to calculate the factorial of a number recursively."
        
        # Run the model (timeout after 30 seconds)
        timeout 30s ollama run "$TEST_MODEL" "$TEST_PROMPT" --max-tokens 50 > /tmp/ollama_test.log 2>&1
        
        if [[ -f /tmp/ollama_test.log ]] && [[ -s /tmp/ollama_test.log ]]; then
            print_success "✅ Model test successful!"
            print_info "Sample response:"
            head -3 /tmp/ollama_test.log
        else
            print_warning "⚠ Model test inconclusive"
        fi
    else
        print_warning "⚠ No models available for testing"
    fi
}

# Create startup configuration
create_startup_config() {
    print_status "Creating startup configuration..."
    
    # Create a plist for macOS auto-start (optional)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        read -p "Enable Ollama auto-start on system boot? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Create launchd plist
            mkdir -p ~/Library/LaunchAgents
            cat > ~/Library/LaunchAgents/com.ollama.service.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.service</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_NUM_GPU</key>
        <string>$OLLAMA_NUM_GPU</string>
        <key>LLAMA_METAL</key>
        <string>$LLAMA_METAL</string>
    </dict>
</dict>
</plist>
EOF
            print_success "Auto-start configuration created"
        fi
    fi
}

# Main installation function
main() {
    echo -e "${PURPLE}🚀 Ollama Installation & Configuration${NC}"
    echo "======================================"
    echo ""
    
    check_system
    install_ollama
    configure_ollama
    download_models
    create_management_scripts
    test_installation
    create_startup_config
    
    echo ""
    echo -e "${GREEN}🎉 Ollama Installation Complete!${NC}"
    echo ""
    echo "✅ What's been set up:"
    echo "   • Ollama service with uncensored models"
    echo "   • GPU acceleration (Metal/CUDA)"
    echo "   • Management scripts"
    echo "   • Environment optimization"
    echo ""
    echo "🚀 Quick Commands:"
    echo "   Start: ~/.ollama/start.sh"
    echo "   Stop: ~/.ollama/stop.sh"
    echo "   Status: ~/.ollama/status.sh"
    echo "   Health: ~/.ollama/health.sh"
    echo "   Models: ~/.ollama/models.sh"
    echo ""
    echo "📖 Next Steps:"
    echo "1. Run ~/.ollama/start.sh to start the service"
    echo "2. Test a model: ollama run dolphin-mistral:7b-dpo-laser"
    echo "3. Configure VS Code with Continue.dev"
    echo ""
    echo -e "${BLUE}Happy coding with AI! 🤖💻${NC}"
}

# Run main function
main "$@"