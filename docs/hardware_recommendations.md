# Hardware Recommendations

## System Requirements

### Minimum Requirements
- **CPU**: 4-core processor (Intel i5/Ryzen 5 or equivalent)
- **RAM**: 8GB (16GB recommended)
- **Storage**: 20GB free SSD space
- **OS**: macOS 12+, Windows 10+, Ubuntu 18.04+
- **Network**: Stable internet for model downloads

### Recommended Specifications
- **CPU**: 8-core processor (Intel i7/Ryzen 7 or better)
- **RAM**: 16GB (32GB+ for large models)
- **Storage**: 50GB+ NVMe SSD
- **GPU**: Dedicated GPU with 4GB+ VRAM (optional but recommended)

## Hardware Profiles

### Apple Silicon (M1/M2/M3/M4)
**Best Performance**: Native optimization with Metal acceleration

#### Recommended Models:
- **M1/M2 (8GB RAM)**: dolphin-2.6-mistral-7b, dolphin-mixtral-8x7b
- **M2/M3 (16GB+ RAM)**: dolphin-2.9.2-qwen2.5-72b, wizardlm-2-8x22b
- **M3/M4 (24GB+ RAM)**: goliath-120b (with CPU offloading)

#### Performance Tips:
- Use Metal GPU layers (35+ recommended)
- Enable memory mapping for faster loading
- Keep system updated for best Metal support

### NVIDIA GPUs
**Highest Performance**: CUDA acceleration for maximum speed

#### GPU Memory Requirements:
- **4GB VRAM**: Small models (7B-13B parameters)
- **8GB VRAM**: Medium models (13B-34B parameters)
- **12GB+ VRAM**: Large models (34B-70B parameters)
- **24GB+ VRAM**: Very large models (70B+ parameters)

#### Recommended GPUs:
- **Entry Level**: RTX 3060 (12GB) - Good for 13B-34B models
- **Mid Range**: RTX 4070 (12GB) - Excellent for 34B-70B models
- **High End**: RTX 4080/4090 (16GB/24GB) - Best for largest models

#### Setup Requirements:
- CUDA 11.8+ installed
- cuDNN library
- Latest NVIDIA drivers

### AMD GPUs (ROCm)
**Good Performance**: Open-source acceleration

#### Supported GPUs:
- Radeon RX 6000/7000 series
- Radeon Pro W6000+ series
- Instinct MI series

#### Requirements:
- ROCm 5.4+ installed
- Linux only (Ubuntu recommended)
- Kernel 5.11+

### CPU-Only Systems
**Decent Performance**: No GPU required, works everywhere

#### RAM Requirements by Model Size:
- **7B models**: 8GB RAM minimum, 16GB recommended
- **13B models**: 16GB RAM minimum, 32GB recommended
- **34B models**: 32GB RAM minimum, 64GB+ recommended
- **70B+ models**: 64GB+ RAM, very slow without GPU

#### Performance Optimization:
- Use AVX2/AVX-512 capable CPUs
- More cores = better performance
- Fast RAM (DDR4-3200+ recommended)
- SSD storage for model loading

## Model Selection by Hardware

### Code-Focused Models

#### Lightweight (7B-13B parameters)
- **dolphin-2.6-mistral-7b**: Fast, good quality, 8GB RAM minimum
- **dolphin-mixtral-8x7b**: Excellent reasoning, 16GB RAM recommended
- **wizardlm-2-8x22b**: Creative coding, 24GB RAM recommended

#### Heavyweight (34B-70B parameters)
- **dolphin-2.9.2-qwen2.5-72b**: Best algorithms, 32GB+ RAM, GPU recommended
- **mythomax-l2-13b**: Balanced performance, 16GB RAM minimum

#### Maximum Capability (100B+ parameters)
- **goliath-120b**: Highest capability, 64GB+ RAM, powerful GPU required

### General Purpose Models
- **llama-3.1-70b-lexi-uncensored**: Versatile, 32GB+ RAM recommended
- **mythomax-l2-13b**: Good all-around, 16GB RAM minimum

## Performance Benchmarks

### Inference Speed (tokens/second)

| Hardware | 7B Model | 13B Model | 34B Model | 70B Model |
|----------|----------|-----------|-----------|-----------|
| M2 Mac (16GB) | 25-35 | 15-25 | 5-10 | 2-5 |
| RTX 3060 | 40-60 | 25-40 | 10-20 | 5-10 |
| RTX 4070 | 60-80 | 40-60 | 20-35 | 10-20 |
| CPU i7-13700K | 8-15 | 4-8 | 1-3 | 0.5-1 |

### Memory Usage (VRAM/RAM)

| Model Size | Quantization | Memory Usage | Performance |
|------------|--------------|--------------|-------------|
| 7B | Q4_K_M | 4GB | Good |
| 13B | Q4_K_M | 7GB | Good |
| 34B | Q4_K_M | 18GB | Good |
| 70B | Q4_K_M | 35GB | Good |
| 70B | Q3_K_L | 25GB | Acceptable |

## Optimization Tips

### General
- Use SSD storage for models (NVMe preferred)
- Keep 20% RAM free for system operations
- Close unnecessary applications during AI usage
- Monitor temperatures during extended use

### macOS Specific
- Disable Siri and Spotlight indexing during downloads
- Use Activity Monitor to check Metal GPU usage
- Keep macOS updated for best Metal support

### Linux Specific
- Use ZRAM for additional memory compression
- Configure CPU governor for performance
- Use huge pages for better memory management

### Windows Specific
- Disable Windows Defender real-time protection during downloads
- Use high-performance power plan
- Ensure WSL2 has sufficient resources if using Linux tools

## Scaling Up

### Multiple GPUs
- Use model parallelism for very large models
- NVIDIA NVLink for multi-GPU setups
- Load balancing across GPUs

### Network Storage
- Use fast network storage for model libraries
- NAS with 10GbE networking
- Distributed storage for team environments

### Cloud Integration (Optional)
- Use local models primarily
- Cloud fallback for peak loads
- Hybrid setups for development teams

## Cost Considerations

### Hardware Costs
- **Entry Level**: $500-800 (CPU-only capable)
- **Mid Range**: $800-1500 (GPU recommended)
- **High End**: $1500+ (Professional setups)

### Power Consumption
- **CPU-only**: 65W TDP typical
- **Mid-range GPU**: 200W total system
- **High-end GPU**: 350W+ total system

## Future-Proofing

- Choose upgradable systems
- Plan for larger models (100B+ parameters)
- Consider workstation motherboards for expansion
- Invest in quality cooling for sustained performance