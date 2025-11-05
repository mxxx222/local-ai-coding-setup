#!/bin/bash

# Local AI Coding Setup - LM Studio Configuration Script
# Automated setup for LM Studio with code-focused models

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

# Detect available memory
check_system_requirements() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        TOTAL_MEM_GB=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')
    else
        TOTAL_MEM_GB=$(free -g | grep '^Mem:' | awk '{print $2}')
    fi
    
    print_status "Total System Memory: ${TOTAL_MEM_GB}GB"
    
    # Check for GPU
    GPU_DETECTED=false
    if command -v nvidia-smi >/dev/null 2>&1; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
        if [[ -n "$GPU_INFO" ]]; then
            GPU_DETECTED=true
            print_success "NVIDIA GPU detected: $GPU_INFO"
        fi
    elif [[ $(uname -m) == "arm64" ]] || [[ $(sysctl -n machdep.cpu.brand_string 2>/dev/null | grep -q "Apple") -eq 0 ]]; then
        GPU_DETECTED=true
        print_success "Apple Silicon GPU (Metal) detected"
    fi
    
    # Set recommended quantization based on system
    if [[ $TOTAL_MEM_GB -ge 32 ]]; then
        QUANTIZATION="Q5_K_M"
        print_success "High-end system - Recommended: Q5_K_M quantization"
    elif [[ $TOTAL_MEM_GB -ge 16 ]]; then
        QUANTIZATION="Q4_K_M"
        print_success "Mid-range system - Recommended: Q4_K_M quantization"
    else
        QUANTIZATION="Q4_K_M"
        print_warning "Lower-end system - Recommended: Q4_K_M quantization"
    fi
}

# Create LM Studio configuration directory
setup_config_directory() {
    CONFIG_DIR="$HOME/.lm-studio"
    mkdir -p "$CONFIG_DIR"
    print_status "Created configuration directory: $CONFIG_DIR"
}

# Create model recommendations based on hardware
generate_model_recommendations() {
    print_status "Generating model recommendations..."
    
    cat > "$CONFIG_DIR/model_recommendations.json" <<EOF
{
  "system_info": {
    "total_memory_gb": $TOTAL_MEM_GB,
    "gpu_detected": $GPU_DETECTED,
    "recommended_quantization": "$QUANTIZATION"
  },
  "model_recommendations": {
    "high_end": {
      "32GB+ RAM, High-end GPU": {
        "codellama": {
          "name": "CodeLlama 34B Instruct",
          "huggingface": "codellama/CodeLlama-34b-Instruct-hf",
          "gguf": "TheBloke/CodeLlama-34B-Instruct-GGUF",
          "quantization": "Q5_K_M",
          "file_size": "~20GB",
          "context_length": 16384,
          "specialties": ["Complex programming", "Multi-language", "Large codebase"]
        },
        "deepseek_coder": {
          "name": "DeepSeek Coder 33B Instruct",
          "huggingface": "deepseek-ai/deepseek-coder-33b-instruct",
          "gguf": "TheBloke/deepseek-coder-33B-instruct-GGUF",
          "quantization": "Q4_K_M",
          "file_size": "~19GB",
          "context_length": 16384,
          "specialties": ["Code completion", "Debugging", "Architecture"]
        }
      }
    },
    "mid_range": {
      "16GB RAM, Dedicated GPU": {
        "codellama": {
          "name": "CodeLlama 13B Instruct",
          "huggingface": "codellama/CodeLlama-13b-Instruct-hf",
          "gguf": "TheBloke/CodeLlama-13B-Instruct-GGUF",
          "quantization": "Q4_K_M",
          "file_size": "~7.8GB",
          "context_length": 8192,
          "specialties": ["General coding", "Multiple languages", "Balanced performance"]
        },
        "deepseek_coder": {
          "name": "DeepSeek Coder 6.7B Instruct",
          "huggingface": "deepseek-ai/deepseek-coder-6.7b-instruct",
          "gguf": "TheBloke/deepseek-coder-6.7B-instruct-GGUF",
          "quantization": "Q4_K_M",
          "file_size": "~4.1GB",
          "context_length": 16384,
          "specialties": ["Code generation", "Debugging", "Fast responses"]
        },
        "starcoder": {
          "name": "StarCoder 7B",
          "huggingface": "bigcode/starcoder2-7b",
          "gguf": "TheBloke/StarCoder-7B-GGUF",
          "quantization": "Q4_K_M",
          "file_size": "~4.2GB",
          "context_length": 8192,
          "specialties": ["Code chat", "Multi-language", "Conversational"]
        }
      }
    },
    "low_end": {
      "8GB RAM, Integrated GPU": {
        "codellama": {
          "name": "CodeLlama 7B Instruct",
          "huggingface": "codellama/CodeLlama-7b-Instruct-hf",
          "gguf": "TheBloke/CodeLlama-7B-Instruct-GGUF",
          "quantization": "Q4_K_M",
          "file_size": "~4.1GB",
          "context_length": 8192,
          "specialties": ["Basic coding", "Lightweight", "Fast startup"]
        },
        "deepseek_coder": {
          "name": "DeepSeek Coder 1.3B",
          "huggingface": "deepseek-ai/deepseek-coder-1.3b-instruct",
          "gguf": "TheBloke/deepseek-coder-1.3B-instruct-GGUF",
          "quantization": "Q4_K_M",
          "file_size": "~0.8GB",
          "context_length": 16384,
          "specialties": ["Very fast", "Lightweight tasks", "Resource efficient"]
        }
      }
    }
  },
  "model_urls": {
    "TheBloke": {
      "base_url": "https://huggingface.co/TheBloke",
      "models": {
        "CodeLlama-7B-Instruct-GGUF": "https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF",
        "CodeLlama-13B-Instruct-GGUF": "https://huggingface.co/TheBloke/CodeLlama-13B-Instruct-GGUF",
        "CodeLlama-34B-Instruct-GGUF": "https://huggingface.co/TheBloke/CodeLlama-34B-Instruct-GGUF",
        "deepseek-coder-6.7B-instruct-GGUF": "https://huggingface.co/TheBloke/deepseek-coder-6.7B-instruct-GGUF",
        "deepseek-coder-1.3B-instruct-GGUF": "https://huggingface.co/TheBloke/deepseek-coder-1.3B-instruct-GGUF",
        "StarCoder-7B-GGUF": "https://huggingface.co/TheBloke/StarCoder-7B-GGUF"
      }
    }
  }
}
EOF

    print_success "Model recommendations generated"
}

# Create LM Studio configuration templates
create_configuration_templates() {
    print_status "Creating LM Studio configuration templates..."
    
    # Server configuration template
    cat > "$CONFIG_DIR/server_config_template.json" <<EOF
{
  "server_settings": {
    "host": "127.0.0.1",
    "port": 1234,
    "cors_enabled": true,
    "api_key": "",
    "max_request_size": 10485760,
    "timeout": 30000,
    "keep_alive": true,
    "compression": "gzip"
  },
  "model_settings": {
    "default_model": "codellama:7b-instruct",
    "context_length": 4096,
    "batch_size": 512,
    "gpu_layers": -1,
    "threads": 0,
    "seed": -1
  },
  "generation_parameters": {
    "temperature": 0.1,
    "top_p": 0.9,
    "top_k": 40,
    "repeat_penalty": 1.1,
    "presence_penalty": 0.0,
    "frequency_penalty": 0.0,
    "mirostat": 0,
    "mirostat_tau": 5.0,
    "mirostat_eta": 0.1,
    "stop": ["</code>", "```", "\\n\\n\\n"],
    "max_tokens": 2048
  }
}
EOF

    print_success "Configuration templates created"
}

# Create VS Code integration template
create_vscode_integration() {
    print_status "Creating VS Code integration template..."
    
    cat > "$CONFIG_DIR/vscode_integration.json" <<EOF
{
  "recommendations": {
    "extensions": [
      "continue.continue",
      "ms-vscode.vscode-json",
      "redhat.vscode-yaml",
      "ms-python.python",
      "ms-vscode.vscode-typescript-next",
      "esbenp.prettier-vscode"
    ]
  },
  "continue_config": {
    "models": [
      {
        "title": "LM Studio Local",
        "provider": "lmstudio",
        "model": "local-model",
        "apiBase": "http://localhost:1234/v1"
      }
    ],
    "tabAutocompleteOptions": {
      "disable": false,
      "maxSuffixPercentage": 0.0,
      "multilineCompletions": "auto"
    },
    "customCommands": [
      {
        "name": "Explain Code",
        "prompt": "Explain this code in detail, focusing on how it works and what it does: {{{ selection }}}"
      },
      {
        "name": "Optimize Code",
        "prompt": "Optimize this code for better performance, readability, and best practices: {{{ selection }}}"
      },
      {
        "name": "Debug Help",
        "prompt": "Help debug this code. Identify potential issues and suggest fixes: {{{ selection }}}"
      },
      {
        "name": "Write Tests",
        "prompt": "Write comprehensive unit tests for this code: {{{ selection }}}"
      },
      {
        "name": "Code Review",
        "prompt": "Perform a thorough code review focusing on: 1) Best practices, 2) Security issues, 3) Performance, 4) Maintainability: {{{ selection }}}"
      }
    ]
  }
}
EOF

    print_success "VS Code integration template created"
}

# Main function
main() {
    print_status "LM Studio Configuration Setup"
    print_status "=============================="
    
    check_system_requirements
    setup_config_directory
    generate_model_recommendations
    create_configuration_templates
    create_vscode_integration
    
    print_success "LM Studio configuration completed!"
    print_status "==================================="
    print_status "Next steps:"
    print_status "1. Download and install LM Studio from https://lmstudio.ai"
    print_status "2. Use the model recommendations to download appropriate models"
    print_status "3. Start the Local Server in LM Studio"
    print_status "4. Configure VS Code with Continue.dev extension"
}

# Run main function
main "$@"