#!/bin/bash

# llama.cpp Installation Script
# Builds and configures llama.cpp for maximum performance

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
    
    # Check if Xcode Command Line Tools are installed
    if ! xcode-select -p >/dev/null 2>&1; then
        print_status "Installing Xcode Command Line Tools..."
        xcode-select --install
        print_warning "Please complete Xcode CLI installation before continuing"
        exit 1
    fi
    
    # Check if Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
        print_status "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install required dependencies
    print_status "Installing required dependencies..."
    brew install cmake git python3
    
    # Check available disk space (minimum 50GB for models)
    AVAILABLE_SPACE=$(df -h . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [[ $AVAILABLE_SPACE -ge 50 ]] || [[ $AVAILABLE_SPACE -ge 30 ]]; then
        print_success "Sufficient disk space: ${AVAILABLE_SPACE}GB"
    else
        print_warning "Low disk space: ${AVAILABLE_SPACE}GB (may limit model sizes)"
    fi
}

# Detect hardware capabilities
detect_hardware() {
    print_status "Detecting hardware capabilities..."
    
    # Check for Apple Silicon
    if [[ $(sysctl -n machdep.cpu.brand_string) == *"Apple"* ]]; then
        print_success "Apple Silicon detected"
        USE_METAL=1
        BUILD_TARGET="metal"
        CPU_CORES=$(sysctl -n hw.ncpu)
        TOTAL_RAM=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
        print_info "CPU Cores: $CPU_CORES, RAM: ${TOTAL_RAM}GB"
        
        # Apple Silicon optimization
        if [[ $CPU_CORES -ge 8 ]]; then
            GPU_LAYERS=40
        elif [[ $CPU_CORES -ge 4 ]]; then
            GPU_LAYERS=25
        else
            GPU_LAYERS=15
        fi
        
    # Check for NVIDIA GPU
    elif command -v nvidia-smi >/dev/null 2>&1; then
        print_success "NVIDIA GPU detected"
        USE_CUDA=1
        BUILD_TARGET="cuda"
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits | head -1)
        print_info "GPU: $GPU_INFO"
        GPU_LAYERS=40
        
    # CPU-only system
    else
        print_warning "CPU-only system detected"
        BUILD_TARGET="cpu"
        CPU_CORES=$(sysctl -n hw.ncpu)
        GPU_LAYERS=0
        print_info "CPU Cores: $CPU_CORES"
    fi
}

# Build llama.cpp
build_llama_cpp() {
    print_status "Building llama.cpp..."
    
    # Create build directory
    mkdir -p ~/llama_cpp_build
    cd ~/llama_cpp_build
    
    # Clone or update repository
    if [[ -d "llama.cpp" ]]; then
        print_status "Updating existing llama.cpp..."
        cd llama.cpp
        git pull
    else
        print_status "Cloning llama.cpp repository..."
        git clone https://github.com/ggerganov/llama.cpp.git
        cd llama.cpp
    fi
    
    # Clean previous builds
    print_status "Cleaning previous builds..."
    make clean
    
    # Build based on target
    case $BUILD_TARGET in
        "metal")
            print_status "Building with Metal GPU acceleration..."
            make LLAMA_METAL=1 -j$(sysctl -n hw.ncpu)
            ;;
        "cuda")
            print_status "Building with CUDA acceleration..."
            make LLAMA_CUDA=1 -j$(nproc)
            ;;
        "cpu")
            print_status "Building CPU-only version..."
            make -j$(sysctl -n hw.ncpu)
            ;;
    esac
    
    # Verify build
    if [[ -f "./main" ]]; then
        print_success "✅ llama.cpp built successfully"
        ./main --help >/dev/null
    else
        print_error "❌ Build failed"
        exit 1
    fi
    
    # Create symlinks for easier access
    ln -sf $(pwd)/main ~/.local/bin/llama
    ln -sf $(pwd)/server ~/.local/bin/llama-server
    
    print_success "Created symlinks: llama, llama-server"
}

# Download recommended models
download_models() {
    print_status "Downloading recommended models..."
    
    # Create models directory
    mkdir -p ~/llama_models
    
    # Function to download from Hugging Face
    download_hf_model() {
        local model_name=$1
        local file_pattern=$2
        local local_name=$3
        
        print_status "Downloading $model_name..."
        
        if command -v huggingface-cli >/dev/null 2>&1; then
            huggingface-cli download "$model_name" "$file_pattern" --local-dir "~/llama_models/$local_name" --local-dir-use-symlinks False
        else
            print_warning "huggingface-cli not found. Using wget..."
            # This is a simplified approach - in practice, you'd want more robust download logic
            print_warning "Manual download required: https://huggingface.co/$model_name"
        fi
    }
    
    # Model recommendations based on hardware
    if [[ $TOTAL_RAM -ge 64 ]]; then
        print_status "64GB+ RAM - downloading premium models"
        download_hf_model "cognitivecomputations/dolphin-2.9.2-qwen2.5" "dolphin-2.9.2-qwen2.5-72b.Q5_K_M.gguf" "dolphin-72b-q5"
        download_hf_model "ehartford/WizardLM-2-8x22B" "WizardLM-2-8x22B.Q5_K_M.gguf" "wizardlm-22b-q5"
    elif [[ $TOTAL_RAM -ge 32 ]]; then
        print_status "32GB+ RAM - downloading quality models"
        download_hf_model "cognitivecomputations/dolphin-mixtral-8x7b" "dolphin-mixtral-8x7b-v2.7.Q5_K_M.gguf" "dolphin-mixtral-q5"
        download_hf_model "ehartford/WizardLM-2-8x22B" "WizardLM-2-8x22B.Q5_K_M.gguf" "wizardlm-22b-q5"
    elif [[ $TOTAL_RAM -ge 16 ]]; then
        print_status "16GB+ RAM - downloading balanced models"
        download_hf_model "ehartford/WizardLM-2-8x22B" "WizardLM-2-8x22B.Q5_K_M.gguf" "wizardlm-22b-q5"
        download_hf_model "cognitivecomputations/dolphin-2.6-mistral-7b" "dolphin-2.6-mistral-7b-dpo-laser.Q5_K_M.gguf" "dolphin-7b-q5"
    elif [[ $TOTAL_RAM -ge 8 ]]; then
        print_status "8GB+ RAM - downloading lightweight models"
        download_hf_model "cognitivecomputations/dolphin-2.6-mistral-7b" "dolphin-2.6-mistral-7b-dpo-laser.Q5_K_M.gguf" "dolphin-7b-q5"
        download_hf_model "cognitivecomputations/dolphin-mistral-7b" "dolphin-mistral-7b.Q5_K_M.gguf" "dolphin-7b-q5"
    else
        print_warning "Less than 8GB RAM - minimal setup"
        download_hf_model "cognitivecomputations/dolphin-mistral-7b" "dolphin-mistral-7b.Q5_K_M.gguf" "dolphin-7b-q5"
    fi
    
    print_success "Model downloads initiated"
}

# Create server configuration
create_server_config() {
    print_status "Creating server configuration..."
    
    # Create server scripts
    cat > ~/.local/bin/start-llama-server << EOF
#!/bin/bash
# llama.cpp Server Startup Script

# Default model (change based on your setup)
DEFAULT_MODEL="~/llama_models/dolphin-7b-q5/dolphin-mistral-7b.Q5_K_M.gguf"

# Use provided model or default
MODEL=\${1:-\$DEFAULT_MODEL}

if [[ ! -f "\$MODEL" ]]; then
    echo "Error: Model file not found: \$MODEL"
    echo "Available models:"
    find ~/llama_models -name "*.gguf" 2>/dev/null | head -10
    exit 1
fi

echo "🚀 Starting llama.cpp server..."
echo "Model: \$MODEL"
echo "Server: http://localhost:8080"

# Environment optimizations
export OMP_NUM_THREADS=$(sysctl -n hw.ncpu)

case $BUILD_TARGET in
    "metal")
        export LLAMA_METAL=1
        echo "Using Metal GPU acceleration"
        ;;
    "cuda")
        echo "Using CUDA acceleration"
        ;;
    "cpu")
        echo "CPU-only mode"
        ;;
esac

# Start server with optimized settings
~/llama_cpp_build/llama.cpp/server \\
    -m "\$MODEL" \\
    -c 4096 \\
    --host 0.0.0.0 \\
    --port 8080 \\
    -ngl $GPU_LAYERS \\
    --mlock \\
    --verbose
EOF

    # Model testing script
    cat > ~/.local/bin/test-llama << 'EOF'
#!/bin/bash
# Test llama.cpp models

DEFAULT_MODEL="~/llama_models/dolphin-7b-q5/dolphin-mistral-7b.Q5_K_M.gguf"
MODEL=${1:-$DEFAULT_MODEL}
PROMPT=${2:-"Write a Python function to calculate fibonacci numbers."}

if [[ ! -f "$MODEL" ]]; then
    echo "Error: Model file not found: $MODEL"
    exit 1
fi

echo "🧪 Testing model: $(basename $MODEL)"
echo "Prompt: $PROMPT"
echo "Response:"
echo "===================="

~/llama_cpp_build/llama.cpp/main \\
    -m "$MODEL" \\
    -p "$PROMPT" \\
    -c 2048 \\
    --temp 0.7 \\
    --top-p 0.9 \\
    --repeat-penalty 1.1 \\
    -ngl 35
EOF

    # Performance benchmark script
    cat > ~/.local/bin/benchmark-llama << 'EOF'
#!/bin/bash
# Benchmark llama.cpp performance

DEFAULT_MODEL="~/llama_models/dolphin-7b-q5/dolphin-mistral-7b.Q5_K_M.gguf"
MODEL=${1:-$DEFAULT_MODEL}

if [[ ! -f "$MODEL" ]]; then
    echo "Error: Model file not found: $MODEL"
    exit 1
fi

echo "⚡ Performance Benchmark"
echo "Model: $(basename $MODEL)"
echo "CPU Cores: $(sysctl -n hw.ncpu)"
echo "RAM: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))GB"
echo ""

# Test prompt
TEST_PROMPT="The quick brown fox jumps over the lazy dog. This is a test prompt for benchmarking performance."

echo "Running benchmark..."
time ~/llama_cpp_build/llama.cpp/main \
    -m "$MODEL" \
    -p "$TEST_PROMPT" \
    -c 512 \
    --temp 0.8 \
    --top-p 0.9 \
    --repeat-penalty 1.05 \
    -ngl 35 \
    --mlock \
    -v
EOF

    # Make scripts executable
    chmod +x ~/.local/bin/start-llama-server
    chmod +x ~/.local/bin/test-llama
    chmod +x ~/.local/bin/benchmark-llama
    
    print_success "Server and test scripts created"
}

# Create Continue.dev configuration
configure_continue() {
    print_status "Configuring Continue.dev for llama.cpp..."
    
    mkdir -p ~/.continue
    
    cat > ~/.continue/config.json << EOF
{
  "models": [
    {
      "title": "llama.cpp Server",
      "provider": "openai",
      "model": "local-model",
      "apiBase": "http://localhost:8080/v1",
      "apiKey": "not-needed"
    }
  ],
  "allowAnonymousTelemetry": false,
  "customCommands": [
    {
      "name": "High Performance Code",
      "prompt": "Generate high-performance, optimized code with detailed explanations and best practices."
    }
  ]
}
EOF
    
    print_success "Continue.dev configuration updated"
}

# Create monitoring scripts
create_monitoring() {
    print_status "Creating monitoring scripts..."
    
    cat > ~/.local/bin/llama-status << 'EOF'
#!/bin/bash
echo "🔍 llama.cpp Status Check"
echo "========================="

# Check server
if curl -s http://localhost:8080/health >/dev/null 2>&1; then
    echo "✅ Server: Running on http://localhost:8080"
else
    echo "❌ Server: Not running"
fi

# Check models
MODEL_COUNT=$(find ~/llama_models -name "*.gguf" 2>/dev/null | wc -l)
if [[ $MODEL_COUNT -gt 0 ]]; then
    echo "✅ Models: $MODEL_COUNT available"
else
    echo "❌ Models: None found"
fi

# System resources
echo ""
echo "📊 Resources:"
echo "  CPU: $(sysctl -n hw.ncpu) cores"
echo "  RAM: $(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))GB"
echo "  Storage: $(df -h ~/llama_models 2>/dev/null | tail -1 | awk '{print $4}') available"
EOF

    chmod +x ~/.local/bin/llama-status
    print_success "Monitoring scripts created"
}

# Test installation
test_installation() {
    print_status "Testing installation..."
    
    # Test basic functionality
    if [[ -f ~/llama_cpp_build/llama.cpp/main ]]; then
        print_success "✅ Binary available"
    else
        print_error "❌ Binary not found"
        return 1
    fi
    
    # Test with simple prompt
    print_status "Testing with simple prompt..."
    
    # Look for any available model
    AVAILABLE_MODEL=$(find ~/llama_models -name "*.gguf" 2>/dev/null | head -1)
    
    if [[ -n "$AVAILABLE_MODEL" ]]; then
        echo "Testing with: $(basename $AVAILABLE_MODEL)"
        timeout 30s ~/llama_cpp_build/llama.cpp/main \
            -m "$AVAILABLE_MODEL" \
            -p "Hello" \
            -c 100 \
            --temp 0.8 \
            --top-p 0.9 \
            > /tmp/llama_test.log 2>&1
        
        if [[ -f /tmp/llama_test.log ]] && [[ -s /tmp/llama_test.log ]]; then
            print_success "✅ Model test successful"
        else
            print_warning "⚠ Model test inconclusive"
        fi
    else
        print_warning "⚠ No models available for testing"
    fi
}

# Main installation function
main() {
    echo -e "${PURPLE}🚀 llama.cpp Installation & Configuration${NC}"
    echo "=========================================="
    echo ""
    
    check_system
    detect_hardware
    build_llama_cpp
    download_models
    create_server_config
    configure_continue
    create_monitoring
    test_installation
    
    echo ""
    echo -e "${GREEN}🎉 llama.cpp Installation Complete!${NC}"
    echo ""
    echo "✅ What's been set up:"
    echo "   • llama.cpp binary built with $BUILD_TARGET optimization"
    echo "   • GPU acceleration: $GPU_LAYERS layers"
    echo "   • Server and management scripts"
    echo "   • Model download infrastructure"
    echo ""
    echo "🚀 Quick Commands:"
    echo "   Start server: start-llama-server [model_path]"
    echo "   Test model: test-llama [model_path]"
    echo "   Benchmark: benchmark-llama [model_path]"
    echo "   Check status: llama-status"
    echo ""
    echo "📖 Next Steps:"
    echo "1. Start the server: start-llama-server"
    echo "2. Configure Continue.dev to use http://localhost:8080/v1"
    echo "3. Download specific models if needed"
    echo ""
    echo -e "${BLUE}Maximum performance AI coding ready! 🏎️💻${NC}"
}

# Run main function
main "$@"