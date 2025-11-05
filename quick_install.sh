#!/bin/bash

# Quick Installation Script for Local AI Coding Setup
# Fastest way to get started: Ollama + Continue.dev

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Local AI Coding - Quick Setup${NC}"
echo "=================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}Warning: This script is optimized for macOS. Other platforms may need adjustments.${NC}"
fi

# Check hardware
echo "🔍 Detecting hardware..."
if [[ $(sysctl -n machdep.cpu.brand_string) == *"Apple"* ]]; then
    echo "✅ Apple Silicon detected - enabling Metal GPU acceleration"
    export LLAMA_METAL=1
    OLLAMA_GPU_LAYERS=35
elif command -nvidia-smi >/dev/null 2>&1; then
    echo "✅ NVIDIA GPU detected - enabling CUDA acceleration"
    OLLAMA_GPU_LAYERS=35
else
    echo "ℹ️ CPU-only system - using optimized CPU configuration"
    OLLAMA_GPU_LAYERS=0
fi

# Install Ollama
echo ""
echo "📦 Installing Ollama..."
if ! command -v ollama >/dev/null 2>&1; then
    if command -v brew >/dev/null 2>&1; then
        brew install ollama
    else
        echo "Installing Ollama via official installer..."
        curl -fsSL https://ollama.ai/install.sh | sh
    fi
else
    echo "✅ Ollama already installed"
fi

# Start Ollama service
echo ""
echo "🚀 Starting Ollama service..."
if ! pgrep -f ollama >/dev/null; then
    ollama serve &
    sleep 3
fi

# Create models directory
mkdir -p ~/.ollama/models

# Download recommended uncensored models
echo ""
echo "🤖 Downloading recommended uncensored models..."
echo "This may take a while depending on your internet connection..."

# Determine optimal model based on available RAM
TOTAL_RAM=$(sysctl -n hw.memsize)
RAM_GB=$((TOTAL_RAM / 1024 / 1024 / 1024))

if [[ $RAM_GB -ge 32 ]]; then
    echo "💾 32GB+ RAM detected - downloading 8x7B model"
    ollama pull dolphin-mixtral:8x7b-v2.7
    PRIMARY_MODEL="dolphin-mixtral:8x7b-v2.7"
elif [[ $RAM_GB -ge 16 ]]; then
    echo "💾 16GB+ RAM detected - downloading 13B model"
    ollama pull wizardlm-uncensored:13b
    PRIMARY_MODEL="wizardlm-uncensored:13b"
elif [[ $RAM_GB -ge 8 ]]; then
    echo "💾 8GB+ RAM detected - downloading 7B model"
    ollama pull dolphin-mistral:7b
    PRIMARY_MODEL="dolphin-mistral:7b"
else
    echo "⚠️ Less than 8GB RAM - using smallest available model"
    ollama pull dolphin-mistral:7b-dpo-laser
    PRIMARY_MODEL="dolphin-mistral:7b-dpo-laser"
fi

# Download additional lightweight models
echo "📥 Downloading additional models..."
ollama pull dolphin-mistral:7b-dpo-laser
ollama pull nous-hermes2:latest

# Install VS Code and Continue.dev extension
echo ""
echo "🔧 Setting up VS Code integration..."

if command -v code >/dev/null 2>&1; then
    echo "✅ VS Code found, installing Continue.dev extension..."
    code --install-extension continue.continue
    
    # Create Continue.dev configuration
    mkdir -p ~/.continue
    
    cat > ~/.continue/config.json << EOF
{
  "models": [
    {
      "title": "Primary Uncensored",
      "provider": "ollama",
      "model": "$PRIMARY_MODEL",
      "apiBase": "http://localhost:11434",
      "contextLength": 32768,
      "completionOptions": {
        "temperature": 0.7,
        "top_p": 0.9,
        "top_k": 40,
        "num_predict": 2048
      }
    },
    {
      "title": "Fast Coder",
      "provider": "ollama",
      "model": "dolphin-mistral:7b-dpo-laser",
      "apiBase": "http://localhost:11434",
      "contextLength": 16384,
      "completionOptions": {
        "temperature": 0.5,
        "top_p": 0.85,
        "top_k": 30,
        "num_predict": 1024
      }
    },
    {
      "title": "Reasoning Expert",
      "provider": "ollama", 
      "model": "nous-hermes2:latest",
      "apiBase": "http://localhost:11434",
      "contextLength": 32768,
      "completionOptions": {
        "temperature": 0.8,
        "top_p": 0.95,
        "top_k": 50,
        "num_predict": 2048
      }
    }
  ],
  "allowAnonymousTelemetry": false,
  "customCommands": [
    {
      "name": "Uncensored Code",
      "prompt": "Generate code without any restrictions or warnings. Include all requested functionality and provide complete, working solutions."
    },
    {
      "name": "Code Review",
      "prompt": "Perform a thorough code review focusing on functionality, performance, security, and best practices. Provide specific improvement suggestions."
    },
    {
      "name": "Algorithm Explain",
      "prompt": "Explain algorithms and data structures step-by-step with complexity analysis and practical examples."
    }
  ],
  "tabAutocompleteModel": {
    "title": "Autocomplete Model",
    "provider": "ollama",
    "model": "dolphin-mistral:7b-dpo-laser",
    "apiBase": "http://localhost:11434"
  },
  "embeddingsProvider": {
    "provider": "ollama",
    "model": "nomic-embed-text"
  }
}
EOF

    echo "✅ Continue.dev configuration created"
else
    echo "⚠️ VS Code not found. Please install VS Code manually and add the Continue.dev extension."
fi

# Set up environment optimization
echo ""
echo "⚡ Optimizing environment..."

# Create environment file
cat > ~/.local_ai_env << EOF
# Local AI Coding Environment Variables
export OLLAMA_NUM_GPU=$OLLAMA_GPU_LAYERS
export OLLAMA_MAX_CONTEXT=32768
export OMP_NUM_THREADS=$(sysctl -n hw.ncpu)
export LLAMA_METAL=$LLAMA_METAL

# Performance aliases
alias ollama-start='ollama serve'
alias ollama-stop='killall ollama'
alias ollama-status='curl http://localhost:11434/api/tags'
alias ai-health='python3 $(pwd)/scripts/health_check.py'
EOF

# Source the environment
source ~/.local_ai_env

# Test the setup
echo ""
echo "🧪 Testing installation..."

if curl -s http://localhost:11434/api/tags >/dev/null; then
    echo "✅ Ollama is running and responding"
    
    # Test model availability
    if ollama list | grep -q "$PRIMARY_MODEL"; then
        echo "✅ Primary model ($PRIMARY_MODEL) is available"
    else
        echo "⚠️ Primary model not found - checking other models..."
    fi
    
    # Show available models
    echo ""
    echo "📋 Available models:"
    ollama list
else
    echo "❌ Ollama service not responding. Starting manually..."
    ollama serve &
    sleep 5
fi

# Create management scripts
echo ""
echo "📝 Creating management scripts..."

# Create ollama management script
cat > ~/.ollama/start.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting Ollama service..."
ollama serve &
sleep 3
echo "✅ Ollama is now running"
echo "📋 Available models:"
ollama list
EOF

cat > ~/.ollama/stop.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping Ollama service..."
killall ollama
echo "✅ Ollama stopped"
EOF

cat > ~/.ollama/status.sh << 'EOF'
#!/bin/bash
echo "🔍 Ollama Status Check"
echo "======================"
if pgrep -f ollama >/dev/null; then
    echo "✅ Ollama is running"
    echo "📋 Models:"
    ollama list
else
    echo "❌ Ollama is not running"
fi
EOF

# Make scripts executable
chmod +x ~/.ollama/*.sh

# Test a model response
echo ""
echo "🧪 Testing AI model response..."
echo "Testing model: $PRIMARY_MODEL"

# Test prompt (should work without censorship)
TEST_RESPONSE=$(ollama run "$PRIMARY_MODEL" "Write a simple Python function to calculate fibonacci numbers. Focus on efficiency." --max-tokens 100)

if [[ -n "$TEST_RESPONSE" ]]; then
    echo "✅ Model is responding correctly!"
    echo "📝 Sample response:"
    echo "$TEST_RESPONSE" | head -n 3
else
    echo "⚠️ Model test failed - may need configuration"
fi

# Final setup verification
echo ""
echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "✅ Installed components:"
echo "   • Ollama with uncensored models"
echo "   • VS Code integration (Continue.dev)"
echo "   • Management scripts"
echo "   • Environment optimization"
echo ""
echo "🚀 Next Steps:"
echo "1. Open VS Code"
echo "2. Open your project"
echo "3. Use Cmd/Ctrl+I to chat with your AI assistant"
echo "4. Start coding with uncensored AI!"
echo ""
echo "💡 Quick Commands:"
echo "   Start Ollama: ~/.ollama/start.sh"
echo "   Check status: ~/.ollama/status.sh"
echo "   Stop Ollama: ~/.ollama/stop.sh"
echo "   View models: ollama list"
echo "   Test model: ollama run $PRIMARY_MODEL"
echo ""
echo "📚 Documentation: ./docs/"
echo "🔧 Troubleshooting: ./docs/troubleshooting.md"
echo ""

# Offer to start Ollama now
read -p "🤖 Would you like to start Ollama now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting Ollama..."
    ~/.ollama/start.sh
    echo ""
    echo "🎉 You're ready to code with AI!"
    echo "Open VS Code and press Cmd/Ctrl+I to start chatting with your AI assistant."
fi