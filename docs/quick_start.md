# Quick Start Guide - Local AI Coding Setup

🚀 **Get up and running with your local AI coding assistant in 10 minutes!**

## Prerequisites

- **macOS** (optimized for macOS, works on other platforms with minor adjustments)
- **8GB+ RAM** (16GB recommended for better performance)
- **20GB+ free disk space**
- **Internet connection** for initial downloads

## Quick Installation (Recommended)

### Option 1: Complete Automated Setup

```bash
# Make scripts executable
chmod +x install.sh quick_install.sh

# Run the quick installer (Ollama + Continue.dev)
./quick_install.sh
```

This will:
- ✅ Install Ollama with uncensored models
- ✅ Configure VS Code with Continue.dev
- ✅ Optimize for your hardware
- ✅ Test the installation
- ✅ Create management scripts

### Option 2: Manual Step-by-Step

If you prefer manual control:

```bash
# 1. Detect your hardware
chmod +x scripts/hardware_detection.sh
./scripts/hardware_detection.sh

# 2. Install Ollama
chmod +x scripts/install_ollama.sh
./scripts/install_ollama.sh

# 3. Install VS Code integration
chmod +x scripts/install_vscode_exts.sh
./scripts/install_vscode_exts.sh

# 4. Run health check
python3 scripts/health_check.py
```

## What Gets Installed

### Core Components
- **Ollama**: AI model runtime with GPU acceleration
- **Continue.dev**: VS Code extension for AI coding assistance
- **Management Scripts**: Easy control over your AI setup

### Recommended Models (Auto-selected based on your hardware)
- **Premium** (32GB+ RAM): Dolphin 2.9.2 72B, WizardLM 2 22B
- **Standard** (16GB+ RAM): WizardLM Uncensored 13B
- **Basic** (8GB+ RAM): Dolphin Mistral 7B
- **Minimal** (<8GB RAM): Small quantized models

## After Installation

### 1. Start Coding
```bash
# In VS Code:
# - Open your project
# - Press Cmd/Ctrl+I to open AI chat
# - Start asking questions or request code!
```

### 2. Test Your Setup
```bash
# Run system health check
python3 scripts/health_check.py

# Or use management scripts
~/.ollama/start.sh    # Start Ollama
~/.ollama/status.sh   # Check status
```

### 3. Model Management
```bash
# Check available models
ollama list

# Test a specific model
ollama run dolphin-mistral:7b-dpo-laser "Write a Python function to calculate fibonacci numbers"

# Download additional models
ollama pull dolphin-mixtral:8x7b-v2.7
```

## VS Code Configuration

### Continue.dev Setup
Your `~/.continue/config.json` is automatically configured with:

- **Multiple models** optimized for different tasks
- **Custom commands** for common coding workflows
- **Tab completion** with fast models
- **Privacy-focused** (no telemetry)

### Keyboard Shortcuts
- `Cmd/Ctrl + I`: Open AI chat panel
- `Cmd/Ctrl + K`: Quick AI actions
- `Tab`: AI-powered code completion
- `Cmd/Ctrl + /`: AI context menu

## Usage Examples

### Code Generation
```
Q: "Create a Python function to sort a list of dictionaries by multiple keys"
A: [AI generates complete, working code with explanations]
```

### Code Review
```
Q: "Review this code for performance and security issues"
A: [AI provides detailed analysis with specific improvements]
```

### Algorithm Explanation
```
Q: "Explain how this quicksort implementation works step by step"
A: [AI breaks down the algorithm with complexity analysis]
```

### Problem Solving
```
Q: "I need to process large CSV files efficiently in Python"
A: [AI suggests pandas optimization, memory management, and code examples]
```

## Troubleshooting

### Common Issues

**❌ "Ollama not running"**
```bash
# Start Ollama service
~/.ollama/start.sh
# Or manually:
ollama serve &
```

**❌ "No models available"**
```bash
# Download recommended models
ollama pull dolphin-mistral:7b-dpo-laser
ollama pull wizardlm-uncensored:13b
```

**❌ "Continue.dev not working"**
```bash
# Reinstall VS Code extension
code --install-extension continue.continue

# Reset configuration
rm ~/.continue/config.json
./scripts/install_vscode_exts.sh
```

**❌ "Slow performance"**
```bash
# Check hardware optimization
./scripts/hardware_detection.sh

# For Apple Silicon:
export LLAMA_METAL=1
export OLLAMA_NUM_GPU=35

# For NVIDIA GPUs:
export OLLAMA_NUM_GPU=35
```

### System Health Check
```bash
# Run comprehensive health check
python3 scripts/health_check.py

# This will check:
# ✅ Ollama service status
# ✅ API responsiveness  
# ✅ Model availability
# ✅ VS Code integration
# ✅ System resources
# ✅ Network connectivity
```

### Getting Help

1. **Check logs**: `~/.ollama/status.sh`
2. **View models**: `ollama list`
3. **Test manually**: `ollama run dolphin-mistral:7b "Hello"`
4. **Full diagnostic**: `python3 scripts/health_check.py`

## Performance Tips

### For Apple Silicon (M1/M2/M3)
- ✅ Metal GPU acceleration is automatically enabled
- ✅ Unified memory provides excellent performance
- ✅ Use 25-35 GPU layers for optimal speed

### For NVIDIA GPUs
- ✅ CUDA acceleration boosts performance significantly
- ✅ Monitor VRAM usage for larger models
- ✅ Consider mixed precision for memory efficiency

### For CPU-only Systems
- ✅ Use smaller, quantized models (Q4_K_M)
- ✅ Increase thread count: `export OMP_NUM_THREADS=8`
- ✅ Focus on lightweight models (3B-7B parameters)

## Security & Privacy

### What's Private
- ✅ All processing happens locally on your machine
- ✅ No data sent to external servers
- ✅ No telemetry or usage tracking
- ✅ Models run completely offline after download

### What's Configured
- ✅ Anonymous telemetry disabled in Continue.dev
- ✅ Local API endpoints only (127.0.0.1)
- ✅ No external API keys required
- ✅ Secure local communication

## Next Steps

1. **Explore examples**: Check the `examples/` folder for AI coding workflows
2. **Customize**: Edit `~/.continue/config.json` to add your preferred models
3. **Optimize**: Run `./scripts/hardware_detection.sh` for performance tuning
4. **Monitor**: Use `python3 scripts/health_check.py` regularly to maintain optimal performance

## Support

- **Documentation**: See `docs/` folder for detailed guides
- **Troubleshooting**: `docs/troubleshooting.md` for common issues
- **Hardware Guide**: `docs/hardware_recommendations.md` for optimization
- **Model Guide**: `docs/model_guide.md` for model selection

---

**🎉 You're now ready to code with AI that actually understands your needs without restrictions!**

**Happy coding! 🚀💻🤖**