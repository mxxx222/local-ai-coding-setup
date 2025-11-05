#!/bin/bash

# Hardware Detection Script
# Detects system capabilities and recommends optimal AI model configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# System Information Detection
detect_system_info() {
    print_header "System Information"
    
    # Operating System
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
        VERSION=$(sw_vers -productVersion)
        BUILD=$(sw_vers -buildVersion)
        print_info "Operating System: $OS $VERSION (Build $BUILD)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        VERSION=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
        print_info "Operating System: $OS $VERSION"
    else
        OS="Unknown"
        print_warning "Unknown operating system: $OSTYPE"
    fi
    
    # Architecture
    ARCH=$(uname -m)
    print_info "Architecture: $ARCH"
    
    # Hostname
    HOSTNAME=$(hostname)
    print_info "Hostname: $HOSTNAME"
}

# CPU Detection
detect_cpu() {
    print_header "CPU Information"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        CPU_BRAND=$(sysctl -n machdep.cpu.brand_string)
        CPU_CORES=$(sysctl -n hw.ncpu)
        CPU_PHYSICAL=$(sysctl -n hw.physicalcpu)
        CPU_LOGICAL=$(sysctl -n hw.logicalcpu)
        CPU_FREQ=$(sysctl -n hw.cpufrequency | awk '{print $1/1000000000 " GHz"}')
        
        print_info "CPU: $CPU_BRAND"
        print_info "Physical cores: $CPU_PHYSICAL"
        print_info "Logical cores: $CPU_LOGICAL"
        print_info "Frequency: $CPU_FREQ"
        
        # Detect Apple Silicon
        if [[ $CPU_BRAND == *"Apple"* ]]; then
            if [[ $CPU_BRAND == *"M1"* ]]; then
                CHIP="Apple M1"
                IS_APPLE_SILICON=1
            elif [[ $CPU_BRAND == *"M2"* ]]; then
                CHIP="Apple M2"
                IS_APPLE_SILICON=1
            elif [[ $CPU_BRAND == *"M3"* ]]; then
                CHIP="Apple M3"
                IS_APPLE_SILICON=1
            else
                CHIP="Apple Silicon (Unknown)"
                IS_APPLE_SILICON=1
            fi
            print_success "Detected: $CHIP"
        else
            IS_APPLE_SILICON=0
        fi
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        CPU_INFO=$(lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | xargs || echo "Unknown")
        CPU_CORES=$(nproc)
        CPU_FREQ=$(lscpu 2>/dev/null | grep "CPU max MHz" | cut -d: -f2 | xargs || echo "Unknown")
        
        print_info "CPU: $CPU_INFO"
        print_info "Cores: $CPU_CORES"
        print_info "Frequency: $CPU_FREQ"
        IS_APPLE_SILICON=0
    fi
}

# Memory Detection
detect_memory() {
    print_header "Memory Information"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        TOTAL_RAM=$(sysctl -n hw.memsize)
        TOTAL_GB=$((TOTAL_RAM / 1024 / 1024 / 1024))
        
        # Get memory pressure info if available
        MEMORY_PRESSURE=$(memory_pressure 2>/dev/null | grep "System-wide memory free percentage:" | cut -d: -f2 | xargs || echo "N/A")
        
        print_info "Total RAM: ${TOTAL_GB}GB"
        print_info "System-wide memory free: $MEMORY_PRESSURE"
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        TOTAL_RAM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        TOTAL_GB=$((TOTAL_RAM / 1024 / 1024))
        
        FREE_RAM=$(grep MemFree /proc/meminfo | awk '{print $2}')
        AVAILABLE_RAM=$((FREE_RAM / 1024 / 1024))
        
        print_info "Total RAM: ${TOTAL_GB}GB"
        print_info "Available RAM: ${AVAILABLE_RAM}GB"
    fi
}

# GPU Detection
detect_gpu() {
    print_header "GPU Information"
    
    # Check for Apple Silicon GPU
    if [[ $IS_APPLE_SILICON -eq 1 ]]; then
        # Try to get GPU info for Apple Silicon
        GPU_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs || echo "Apple Silicon GPU")
        GPU_MEMORY=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "VRAM" | head -1 | cut -d: -f2 | xargs || echo "Unified Memory")
        
        print_success "GPU: $GPU_INFO"
        print_info "Memory: $GPU_MEMORY"
        GPU_TYPE="apple_silicon"
        HAS_GPU=1
        
    # Check for NVIDIA GPU
    elif command -v nvidia-smi >/dev/null 2>&1; then
        GPU_INFO=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits | head -1)
        GPU_NAME=$(echo $GPU_INFO | cut -d, -f1)
        GPU_MEMORY=$(echo $GPU_INFO | cut -d, -f2)
        
        print_success "GPU: $GPU_NAME"
        print_info "Memory: ${GPU_MEMORY}MB"
        GPU_TYPE="nvidia"
        HAS_GPU=1
        
    # Check for AMD GPU (macOS)
    elif [[ "$OSTYPE" == "darwin"* ]] && system_profiler SPDisplaysDataType 2>/dev/null | grep -q "AMD"; then
        GPU_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs)
        print_warning "GPU: $GPU_INFO (Metal support may vary)"
        GPU_TYPE="amd_macos"
        HAS_GPU=1
        
    # Check for Intel GPU (macOS)
    elif [[ "$OSTYPE" == "darwin"* ]] && system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Intel"; then
        GPU_INFO=$(system_profiler SPDisplaysDataType 2>/dev/null | grep "Chipset Model" | head -1 | cut -d: -f2 | xargs)
        print_warning "GPU: $GPU_INFO (Limited AI acceleration)"
        GPU_TYPE="intel"
        HAS_GPU=1
    else
        print_info "No dedicated GPU detected (CPU-only mode)"
        GPU_TYPE="cpu"
        HAS_GPU=0
    fi
}

# Storage Detection
detect_storage() {
    print_header "Storage Information"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Get main disk info
        DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
        DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')
        DISK_TYPE=$(diskutil info / | grep "File System Personality" | cut -d: -f2 | xargs || echo "Unknown")
        
        print_info "Main Disk: $DISK_TOTAL total, $DISK_FREE free"
        print_info "File System: $DISK_TYPE"
        
        # Check for SSD
        DISK_MEDIA=$(diskutil info / | grep "Media" | head -1 | cut -d: -f2 | xargs)
        if [[ $DISK_MEDIA == *"SSD"* ]]; then
            print_success "Storage type: SSD (Excellent for AI workloads)"
            STORAGE_TYPE="ssd"
        elif [[ $DISK_MEDIA == *"HDD"* ]]; then
            print_warning "Storage type: HDD (May impact model loading speed)"
            STORAGE_TYPE="hdd"
        else
            print_info "Storage type: Unknown ($DISK_MEDIA)"
            STORAGE_TYPE="unknown"
        fi
        
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        DISK_TOTAL=$(df -h / | tail -1 | awk '{print $2}')
        DISK_FREE=$(df -h / | tail -1 | awk '{print $4}')
        
        print_info "Main Disk: $DISK_TOTAL total, $DISK_FREE free"
        
        # Try to detect SSD
        if [[ -f /sys/block/$(lsblk -o name | grep -E '^nvme|^sd[a-z]$' | head -1)/queue/rotational ]]; then
            ROTATIONAL=$(cat /sys/block/$(lsblk -o name | grep -E '^nvme|^sd[a-z]$' | head -1)/queue/rotational 2>/dev/null || echo "1")
            if [[ $ROTATIONAL == "0" ]]; then
                print_success "Storage type: SSD detected"
                STORAGE_TYPE="ssd"
            else
                print_warning "Storage type: HDD detected"
                STORAGE_TYPE="hdd"
            fi
        fi
    fi
}

# Network Detection
detect_network() {
    print_header "Network Information"
    
    # Check internet connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "Internet: Connected"
        INTERNET_STATUS="connected"
        
        # Check connection speed (basic test)
        print_info "Testing connection speed..."
        SPEED_TEST=$(curl -s --max-time 5 https://speed.hetzner.de/100MB.bin 2>/dev/null | wc -c || echo "0")
        if [[ $SPEED_TEST -gt 0 ]]; then
            SPEED_MB=$((SPEED_TEST / 1024 / 1024))
            if [[ $SPEED_MB -gt 50 ]]; then
                print_success "Connection speed: ${SPEED_MB}MB/s (Excellent for downloads)"
            elif [[ $SPEED_MB -gt 10 ]]; then
                print_info "Connection speed: ${SPEED_MB}MB/s (Good for downloads)"
            else
                print_warning "Connection speed: ${SPEED_MB}MB/s (Slow downloads)"
            fi
        fi
        
    else
        print_error "Internet: No connection"
        INTERNET_STATUS="disconnected"
    fi
    
    # Check local network adapter
    if [[ "$OSTYPE" == "darwin"* ]]; then
        NETWORK_ADAPTER=$(networksetup -listallhardwareports 2>/dev/null | grep -E "(Hardware Port|Device)" | head -2 | awk -F': ' '{print $2}' | tr '\n' ' ' | sed 's/ $//')
        print_info "Network adapter: $NETWORK_ADAPTER"
    fi
}

# Software Environment Detection
detect_software() {
    print_header "Software Environment"
    
    # Check for essential tools
    TOOLS=("curl" "git" "python3" "brew" "wget")
    for tool in "${TOOLS[@]}"; do
        if command -v $tool >/dev/null 2>&1; then
            VERSION=$($tool --version 2>/dev/null | head -1 || echo "Available")
            print_success "$tool: $VERSION"
        else
            print_warning "$tool: Not installed"
        fi
    done
    
    # Check for development tools
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if xcode-select -p >/dev/null 2>&1; then
            XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
            print_success "Xcode CLI Tools: $XCODE_VERSION"
        else
            print_warning "Xcode CLI Tools: Not installed"
        fi
    fi
    
    # Check for AI/ML frameworks
    AI_TOOLS=("ollama" "huggingface-cli")
    for tool in "${AI_TOOLS[@]}"; do
        if command -v $tool >/dev/null 2>&1; then
            VERSION=$($tool --version 2>/dev/null || echo "Available")
            print_success "$tool: $VERSION"
        else
            print_info "$tool: Not installed"
        fi
    done
}

# Generate Hardware Profile
generate_hardware_profile() {
    print_header "Hardware Profile Analysis"
    
    # Determine hardware tier
    if [[ $IS_APPLE_SILICON -eq 1 ]] && [[ $TOTAL_GB -ge 16 ]]; then
        TIER="Premium"
        RECOMMENDED_SETUP="ollama + dolphin-mixtral:8x7b-v2.7"
        GPU_LAYERS=35
        MAX_MODEL_SIZE="13B"
        
    elif [[ $IS_APPLE_SILICON -eq 1 ]] && [[ $TOTAL_GB -ge 8 ]]; then
        TIER="Good"
        RECOMMENDED_SETUP="ollama + dolphin-mistral:7b-dpo-laser"
        GPU_LAYERS=25
        MAX_MODEL_SIZE="7B"
        
    elif command -v nvidia-smi >/dev/null 2>&1 && [[ $TOTAL_GB -ge 16 ]]; then
        TIER="Premium"
        RECOMMENDED_SETUP="ollama + wizardlm-uncensored:13b"
        GPU_LAYERS=35
        MAX_MODEL_SIZE="13B"
        
    elif [[ $TOTAL_GB -ge 32 ]]; then
        TIER="High-End"
        RECOMMENDED_SETUP="llama.cpp + dolphin-mixtral:8x7b"
        GPU_LAYERS=40
        MAX_MODEL_SIZE="13B"
        
    elif [[ $TOTAL_GB -ge 16 ]]; then
        TIER="Standard"
        RECOMMENDED_SETUP="ollama + wizardlm-uncensored:13b"
        GPU_LAYERS=20
        MAX_MODEL_SIZE="13B"
        
    elif [[ $TOTAL_GB -ge 8 ]]; then
        TIER="Basic"
        RECOMMENDED_SETUP="ollama + dolphin-mistral:7b"
        GPU_LAYERS=10
        MAX_MODEL_SIZE="7B"
        
    else
        TIER="Minimal"
        RECOMMENDED_SETUP="ollama + small model"
        GPU_LAYERS=0
        MAX_MODEL_SIZE="3B"
    fi
    
    print_info "Hardware Tier: $TIER"
    print_info "Recommended Setup: $RECOMMENDED_SETUP"
    print_info "Max Recommended Model: $MAX_MODEL_SIZE"
    print_info "Optimal GPU Layers: $GPU_LAYERS"
}

# Generate Performance Expectations
generate_performance_expectations() {
    print_header "Performance Expectations"
    
    case $TIER in
        "Premium")
            print_success "Expected Performance: Excellent (2-5s response time)"
            print_info "Suitable for: All AI coding tasks, large models"
            print_info "Memory Usage: 16-24GB VRAM equivalent"
            ;;
        "High-End")
            print_success "Expected Performance: Very Good (3-8s response time)"
            print_info "Suitable for: Most AI coding tasks, medium-large models"
            print_info "Memory Usage: 8-16GB VRAM equivalent"
            ;;
        "Good"|"Standard")
            print_info "Expected Performance: Good (5-15s response time)"
            print_info "Suitable for: Standard coding tasks, medium models"
            print_info "Memory Usage: 4-8GB VRAM equivalent"
            ;;
        "Basic")
            print_warning "Expected Performance: Fair (10-30s response time)"
            print_info "Suitable for: Light coding tasks, small models"
            print_info "Memory Usage: 2-4GB VRAM equivalent"
            ;;
        "Minimal")
            print_warning "Expected Performance: Limited (20-60s response time)"
            print_info "Suitable for: Basic coding assistance, tiny models"
            print_info "Memory Usage: 1-2GB VRAM equivalent"
            ;;
    esac
}

# Generate Optimization Recommendations
generate_optimizations() {
    print_header "Optimization Recommendations"
    
    if [[ $IS_APPLE_SILICON -eq 1 ]]; then
        print_success "Apple Silicon Optimizations:"
        echo "  • Enable Metal GPU acceleration (LLAMA_METAL=1)"
        echo "  • Use 35+ GPU layers for optimal performance"
        echo "  • Enable unified memory optimizations"
        echo "  • Consider llama.cpp for maximum control"
        
    elif [[ $GPU_TYPE == "nvidia" ]]; then
        print_success "NVIDIA GPU Optimizations:"
        echo "  • Enable CUDA acceleration (LLAMA_CUDA=1)"
        echo "  • Use 40+ GPU layers if VRAM allows"
        echo "  • Enable mixed precision (FP16)"
        echo "  • Monitor VRAM usage during inference"
        
    else
        print_info "CPU-Only Optimizations:"
        echo "  • Increase CPU threads (OMP_NUM_THREADS=$CPU_CORES)"
        echo "  • Use quantization (Q4_K_M recommended)"
        echo "  • Enable memory locking to prevent swapping"
        echo "  • Consider smaller context windows"
    fi
    
    # Storage recommendations
    if [[ $STORAGE_TYPE == "ssd" ]]; then
        echo ""
        print_success "Storage Optimizations:"
        echo "  • Fast model loading and switching"
        echo "  • Enable model caching"
        echo "  • Store multiple models for different tasks"
        
    elif [[ $STORAGE_TYPE == "hdd" ]]; then
        echo ""
        print_warning "Storage Limitations:"
        echo "  • Slower model loading times"
        echo "  • Limit active models to 1-2"
        echo "  • Use smaller quantization levels"
    fi
}

# Generate configuration file
generate_config() {
    print_header "Generating Configuration File"
    
    CONFIG_FILE="hardware_profile_$(date +%Y%m%d_%H%M%S).json"
    
    cat > "$CONFIG_FILE" << EOF
{
  "system_info": {
    "os": "$OS",
    "arch": "$ARCH",
    "hostname": "$HOSTNAME"
  },
  "cpu": {
    "brand": "$CPU_BRAND",
    "cores": $CPU_CORES,
    "frequency": "$CPU_FREQ",
    "apple_silicon": $IS_APPLE_SILICON
  },
  "memory": {
    "total_gb": $TOTAL_GB,
    "available_gb": ${AVAILABLE_RAM:-$TOTAL_GB}
  },
  "gpu": {
    "type": "$GPU_TYPE",
    "has_gpu": $HAS_GPU,
    "info": "${GPU_INFO:-None}"
  },
  "storage": {
    "type": "$STORAGE_TYPE",
    "total": "$DISK_TOTAL",
    "free": "$DISK_FREE"
  },
  "network": {
    "status": "$INTERNET_STATUS"
  },
  "profile": {
    "tier": "$TIER",
    "recommended_setup": "$RECOMMENDED_SETUP",
    "max_model_size": "$MAX_MODEL_SIZE",
    "gpu_layers": $GPU_LAYERS,
    "performance_rating": "$PERFORMANCE_RATING"
  },
  "detection_timestamp": "$(date -Iseconds)",
  "optimizations": {
    "apple_silicon_optimizations": $([[ $IS_APPLE_SILICON -eq 1 ]] && echo "true" || echo "false"),
    "nvidia_optimizations": $([[ $GPU_TYPE == "nvidia" ]] && echo "true" || echo "false"),
    "metal_acceleration": $([[ $IS_APPLE_SILICON -eq 1 ]] && echo "true" || echo "false"),
    "cuda_acceleration": $([[ $GPU_TYPE == "nvidia" ]] && echo "true" || echo "false")
  }
}
EOF
    
    print_success "Configuration saved to: $CONFIG_FILE"
}

# Main hardware detection function
main() {
    echo -e "${PURPLE}🔍 Local AI Hardware Detection${NC}"
    echo "=================================="
    echo ""
    
    # Initialize global variables
    IS_APPLE_SILICON=0
    HAS_GPU=0
    STORAGE_TYPE="unknown"
    INTERNET_STATUS="unknown"
    TIER="Unknown"
    
    # Run all detection functions
    detect_system_info
    detect_cpu
    detect_memory
    detect_gpu
    detect_storage
    detect_network
    detect_software
    generate_hardware_profile
    generate_performance_expectations
    generate_optimizations
    generate_config
    
    echo ""
    echo -e "${GREEN}🎯 Hardware Detection Complete!${NC}"
    echo ""
    echo "📋 Summary:"
    echo "   • System: $OS on $ARCH"
    echo "   • CPU: $CPU_CORES cores ($CPU_BRAND)"
    echo "   • Memory: ${TOTAL_GB}GB RAM"
    echo "   • GPU: ${GPU_TYPE:-CPU-only}"
    echo "   • Tier: $TIER"
    echo "   • Recommended: $RECOMMENDED_SETUP"
    echo ""
    echo "📖 Next Steps:"
    echo "1. Review the configuration file: hardware_profile_*.json"
    echo "2. Run the appropriate installation script"
    echo "3. Follow the optimization recommendations"
    echo ""
    echo -e "${BLUE}Ready for optimal AI coding setup! 🚀${NC}"
}

# Run main function
main "$@"