#!/usr/bin/env python3

"""
Model Downloader Script
Downloads recommended AI models for local coding assistance
"""

import os
import sys
import subprocess
import json
import argparse
from pathlib import Path
from typing import List, Dict, Any

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

def print_status(message: str):
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {message}")

def print_success(message: str):
    print(f"{Colors.GREEN}[SUCCESS]{Colors.NC} {message}")

def print_warning(message: str):
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {message}")

def print_error(message: str):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {message}")

def run_command(cmd: List[str], capture_output: bool = False) -> subprocess.CompletedProcess:
    """Run a command and return the result"""
    try:
        result = subprocess.run(cmd, capture_output=capture_output, text=True, check=True)
        return result
    except subprocess.CalledProcessError as e:
        print_error(f"Command failed: {' '.join(cmd)}")
        print_error(f"Error: {e}")
        if e.stdout:
            print(f"stdout: {e.stdout}")
        if e.stderr:
            print(f"stderr: {e.stderr}")
        raise

def check_ollama() -> bool:
    """Check if Ollama is installed and running"""
    try:
        result = run_command(["ollama", "--version"], capture_output=True)
        print_success(f"Ollama is installed: {result.stdout.strip()}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print_error("Ollama is not installed or not in PATH")
        print_status("Please run ./scripts/install_ollama.sh first")
        return False

def get_system_info() -> Dict[str, Any]:
    """Get basic system information to recommend models"""
    info = {
        "cpu_cores": 0,
        "memory_gb": 0,
        "has_gpu": False,
        "platform": sys.platform
    }

    try:
        # Get CPU cores
        if sys.platform == "darwin":  # macOS
            result = run_command(["sysctl", "-n", "hw.ncpu"], capture_output=True)
            info["cpu_cores"] = int(result.stdout.strip())
        else:  # Linux/Windows
            result = run_command(["nproc"], capture_output=True)
            info["cpu_cores"] = int(result.stdout.strip())
    except:
        info["cpu_cores"] = 4  # fallback

    try:
        # Get memory (rough estimate)
        if sys.platform == "darwin":
            result = run_command(["sysctl", "-n", "hw.memsize"], capture_output=True)
            mem_bytes = int(result.stdout.strip())
            info["memory_gb"] = mem_bytes // (1024**3)
        else:
            with open("/proc/meminfo", "r") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        mem_kb = int(line.split()[1])
                        info["memory_gb"] = mem_kb // (1024**2)
                        break
    except:
        info["memory_gb"] = 8  # fallback

    # Check for GPU (basic check)
    try:
        if sys.platform == "darwin":
            # Check for Apple Silicon
            result = run_command(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True)
            if "Apple" in result.stdout:
                info["has_gpu"] = True
        else:
            # Check for NVIDIA GPU
            run_command(["nvidia-smi"], capture_output=True)
            info["has_gpu"] = True
    except:
        pass

    return info

def get_model_recommendations(system_info: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Get model recommendations based on system specs"""

    models = [
        {
            "name": "dolphin-2.6-mistral-7b",
            "size": "4GB",
            "description": "Fast, lightweight coding assistant",
            "min_memory": 8,
            "recommended": True,
            "category": "lightweight"
        },
        {
            "name": "dolphin-mixtral-8x7b",
            "size": "15GB",
            "description": "Excellent reasoning and code understanding",
            "min_memory": 16,
            "recommended": system_info["memory_gb"] >= 16,
            "category": "balanced"
        },
        {
            "name": "wizardlm-2-8x22b",
            "size": "14GB",
            "description": "Creative coding and problem solving",
            "min_memory": 16,
            "recommended": system_info["memory_gb"] >= 16,
            "category": "creative"
        },
        {
            "name": "dolphin-2.9.2-qwen2.5-72b",
            "size": "45GB",
            "description": "Advanced algorithms and complex reasoning",
            "min_memory": 32,
            "recommended": system_info["memory_gb"] >= 32,
            "category": "advanced"
        },
        {
            "name": "mythomax-l2-13b",
            "size": "8GB",
            "description": "Balanced general purpose model",
            "min_memory": 16,
            "recommended": system_info["memory_gb"] >= 16,
            "category": "general"
        }
    ]

    # Filter models based on available memory
    available_memory = system_info["memory_gb"]
    recommended_models = [m for m in models if m["min_memory"] <= available_memory]

    return recommended_models

def download_model(model_name: str):
    """Download a specific model using Ollama"""
    print_status(f"Downloading model: {model_name}")
    print_status("This may take several minutes depending on model size and internet speed...")

    try:
        run_command(["ollama", "pull", model_name])
        print_success(f"Successfully downloaded {model_name}")
    except subprocess.CalledProcessError:
        print_error(f"Failed to download {model_name}")
        return False
    return True

def list_installed_models():
    """List currently installed Ollama models"""
    try:
        result = run_command(["ollama", "list"], capture_output=True)
        lines = result.stdout.strip().split('\n')
        if len(lines) > 1:  # More than just header
            print_status("Currently installed models:")
            for line in lines[1:]:  # Skip header
                print(f"  {line}")
        else:
            print_status("No models currently installed")
    except subprocess.CalledProcessError:
        print_error("Failed to list installed models")

def main():
    parser = argparse.ArgumentParser(description="Download AI models for local coding")
    parser.add_argument("--list", action="store_true", help="List currently installed models")
    parser.add_argument("--all", action="store_true", help="Download all recommended models")
    parser.add_argument("--model", help="Download a specific model")
    parser.add_argument("--category", choices=["lightweight", "balanced", "creative", "advanced", "general"],
                       help="Download models from specific category")

    args = parser.parse_args()

    print(f"{Colors.CYAN}AI Model Downloader{Colors.NC}")
    print("=" * 30)

    if not check_ollama():
        sys.exit(1)

    if args.list:
        list_installed_models()
        return

    # Get system information
    system_info = get_system_info()
    print_status(f"System detected: {system_info['cpu_cores']} cores, {system_info['memory_gb']}GB RAM")

    if args.model:
        # Download specific model
        download_model(args.model)
    elif args.all:
        # Download all recommended models
        recommendations = get_model_recommendations(system_info)
        print_status(f"Downloading {len(recommendations)} recommended models...")

        for model in recommendations:
            download_model(model["name"])
            print()  # Add spacing
    elif args.category:
        # Download models from category
        recommendations = get_model_recommendations(system_info)
        category_models = [m for m in recommendations if m["category"] == args.category]

        if not category_models:
            print_warning(f"No {args.category} models available for your system")
            return

        print_status(f"Downloading {len(category_models)} {args.category} models...")

        for model in category_models:
            download_model(model["name"])
            print()
    else:
        # Interactive mode - show recommendations
        recommendations = get_model_recommendations(system_info)

        print_status("Recommended models for your system:")
        print()

        for i, model in enumerate(recommendations, 1):
            status = "[RECOMMENDED]" if model["recommended"] else "[AVAILABLE]"
            print(f"{i}. {model['name']} ({model['size']})")
            print(f"   {model['description']}")
            print(f"   Minimum RAM: {model['min_memory']}GB {status}")
            print()

        if not recommendations:
            print_warning("No models available for your system specifications")
            print_status("Consider upgrading RAM or using CPU-only models")
            return

        try:
            choice = input("Enter model numbers to download (comma-separated) or 'all': ").strip()

            if choice.lower() == 'all':
                models_to_download = recommendations
            else:
                indices = [int(x.strip()) - 1 for x in choice.split(',') if x.strip().isdigit()]
                models_to_download = [recommendations[i] for i in indices if 0 <= i < len(recommendations)]

            if not models_to_download:
                print_warning("No valid models selected")
                return

            print()
            for model in models_to_download:
                download_model(model["name"])
                print()

        except (ValueError, KeyboardInterrupt):
            print_warning("Invalid input or cancelled")
            return

    print_success("Model download process complete!")
    print_status("You can now use these models in VS Code with Continue.dev")

if __name__ == "__main__":
    main()