#!/usr/bin/env python3

"""
AI Model Benchmarking Script
Tests performance of installed AI models for coding tasks
"""

import os
import sys
import time
import json
import subprocess
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

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

def run_command(cmd: List[str], capture_output: bool = False, timeout: int = 30) -> subprocess.CompletedProcess:
    """Run a command with timeout"""
    try:
        result = subprocess.run(cmd, capture_output=capture_output, text=True,
                              timeout=timeout, check=True)
        return result
    except subprocess.TimeoutExpired:
        print_error(f"Command timed out after {timeout}s: {' '.join(cmd)}")
        raise
    except subprocess.CalledProcessError as e:
        print_error(f"Command failed: {' '.join(cmd)}")
        raise

def check_ollama() -> bool:
    """Check if Ollama is running"""
    try:
        run_command(["ollama", "list"], capture_output=True, timeout=10)
        return True
    except:
        print_error("Ollama is not running or not accessible")
        print_status("Please start Ollama: ollama serve")
        return False

def get_installed_models() -> List[str]:
    """Get list of installed Ollama models"""
    try:
        result = run_command(["ollama", "list"], capture_output=True)
        lines = result.stdout.strip().split('\n')
        models = []
        for line in lines[1:]:  # Skip header
            if line.strip():
                parts = line.split()
                if parts:
                    models.append(parts[0])
        return models
    except:
        return []

def benchmark_model(model_name: str, test_prompt: str, max_tokens: int = 100) -> Dict[str, Any]:
    """Benchmark a single model with a test prompt"""
    print_status(f"Benchmarking {model_name}...")

    start_time = time.time()

    try:
        # Run inference
        cmd = ["ollama", "run", model_name, test_prompt]
        result = run_command(cmd, capture_output=True, timeout=120)

        end_time = time.time()
        response_time = end_time - start_time

        response = result.stdout.strip()

        # Estimate tokens (rough approximation)
        response_tokens = len(response.split()) * 1.3  # Rough token estimate
        tokens_per_second = response_tokens / response_time if response_time > 0 else 0

        return {
            "model": model_name,
            "success": True,
            "response_time": round(response_time, 2),
            "tokens_generated": round(response_tokens),
            "tokens_per_second": round(tokens_per_second, 2),
            "response_length": len(response),
            "error": None
        }

    except subprocess.TimeoutExpired:
        return {
            "model": model_name,
            "success": False,
            "response_time": 120.0,
            "tokens_generated": 0,
            "tokens_per_second": 0,
            "response_length": 0,
            "error": "timeout"
        }
    except Exception as e:
        return {
            "model": model_name,
            "success": False,
            "response_time": time.time() - start_time,
            "tokens_generated": 0,
            "tokens_per_second": 0,
            "response_length": 0,
            "error": str(e)
        }

def get_test_prompts() -> List[str]:
    """Get a list of test prompts for benchmarking"""
    return [
        "Write a Python function to calculate fibonacci numbers recursively.",
        "Explain the difference between stack and heap memory in programming.",
        "Write a SQL query to find the top 5 customers by total order value.",
        "What are the main principles of object-oriented programming?",
        "Debug this JavaScript code: function sum(a, b) { return a + b; } console.log(sum(5));"
    ]

def run_comprehensive_benchmark(models: List[str], output_file: Optional[str] = None) -> Dict[str, Any]:
    """Run comprehensive benchmark on multiple models"""
    if not models:
        print_error("No models to benchmark")
        return {}

    test_prompts = get_test_prompts()
    results = {}

    print_status(f"Running comprehensive benchmark on {len(models)} models...")
    print_status(f"Using {len(test_prompts)} test prompts")

    for model in models:
        print(f"\n{Colors.CYAN}Testing {model}{Colors.NC}")
        print("-" * 50)

        model_results = []
        for i, prompt in enumerate(test_prompts, 1):
            print_status(f"Test {i}/{len(test_prompts)}: {prompt[:50]}...")
            result = benchmark_model(model, prompt)
            model_results.append(result)

            if result["success"]:
                print_success(
                    f"{model} responded in {result['response_time']:.2f}s "
                    f"({result['tokens_per_second']:.2f} tok/s)"
                )
            else:
                print_error(f"Failed: {result['error']}")

        # Calculate averages
        successful_tests = [r for r in model_results if r["success"]]
        if successful_tests:
            avg_response_time = sum(r["response_time"] for r in successful_tests) / len(successful_tests)
            avg_tokens_per_sec = sum(r["tokens_per_second"] for r in successful_tests) / len(successful_tests)
            success_rate = len(successful_tests) / len(test_prompts) * 100
        else:
            avg_response_time = 0
            avg_tokens_per_sec = 0
            success_rate = 0

        results[model] = {
            "individual_tests": model_results,
            "summary": {
                "average_response_time": round(avg_response_time, 2),
                "average_tokens_per_second": round(avg_tokens_per_sec, 2),
                "success_rate": round(success_rate, 1),
                "total_tests": len(test_prompts),
                "successful_tests": len(successful_tests)
            }
        }

    # Save results if requested
    if output_file:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{output_file}_{timestamp}.json" if not output_file.endswith('.json') else output_file

        with open(filename, 'w') as f:
            json.dump({
                "timestamp": timestamp,
                "system_info": get_system_info(),
                "results": results
            }, f, indent=2)

        print_success(f"Results saved to {filename}")

    return results

def get_system_info() -> Dict[str, Any]:
    """Get basic system information"""
    info = {
        "platform": sys.platform,
        "python_version": sys.version,
        "timestamp": datetime.now().isoformat()
    }

    try:
        if sys.platform == "darwin":
            # macOS
            result = run_command(["sysctl", "-n", "hw.ncpu"], capture_output=True)
            info["cpu_cores"] = int(result.stdout.strip())

            result = run_command(["sysctl", "-n", "hw.memsize"], capture_output=True)
            info["memory_bytes"] = int(result.stdout.strip())
        else:
            # Linux
            result = run_command(["nproc"], capture_output=True)
            info["cpu_cores"] = int(result.stdout.strip())

            with open("/proc/meminfo", "r") as f:
                for line in f:
                    if line.startswith("MemTotal:"):
                        info["memory_kb"] = int(line.split()[1])
                        break
    except:
        pass

    return info

def print_results_summary(results: Dict[str, Any]):
    """Print a summary of benchmark results"""
    if not results:
        return

    print(f"\n{Colors.CYAN}Benchmark Results Summary{Colors.NC}")
    print("=" * 60)

    # Sort by tokens per second
    sorted_models = sorted(results.items(),
                          key=lambda x: x[1]["summary"]["average_tokens_per_second"],
                          reverse=True)

    print(f"{'Model':<30} {'Avg Response (s)':<15} {'Tokens/sec':<12} {'Success %':<10}")
    print("-" * 70)

    for model, data in sorted_models:
        summary = data["summary"]
        print(
            f"{model:<30} "
            f"{summary['average_response_time']:<15.2f} "
            f"{summary['average_tokens_per_second']:<12.1f} "
            f"{summary['success_rate']:<10.1f}"
        )

    print("\n" + Colors.GREEN + "Legend:" + Colors.NC)
    print("• Higher tokens/sec = faster inference")
    print("• Lower response time = better responsiveness")
    print("• Higher success rate = more reliable")

def main():
    parser = argparse.ArgumentParser(description="Benchmark AI models for coding tasks")
    parser.add_argument("--models", nargs="*", help="Specific models to benchmark")
    parser.add_argument("--all", action="store_true", help="Benchmark all installed models")
    parser.add_argument("--output", help="Save results to JSON file")
    parser.add_argument("--quick", action="store_true", help="Quick benchmark with single test")

    args = parser.parse_args()

    print(f"{Colors.CYAN}AI Model Benchmark Suite{Colors.NC}")
    print("=" * 40)

    if not check_ollama():
        sys.exit(1)

    # Get models to benchmark
    if args.models:
        models = args.models
    elif args.all:
        models = get_installed_models()
        if not models:
            print_error("No models installed")
            print_status("Install models first: python3 scripts/model_downloader.py")
            sys.exit(1)
    else:
        installed = get_installed_models()
        if not installed:
            print_error("No models installed")
            sys.exit(1)

        print_status("Installed models:")
        for i, model in enumerate(installed, 1):
            print(f"  {i}. {model}")

        try:
            choice = input("\nEnter model numbers to benchmark (comma-separated) or 'all': ").strip()

            if choice.lower() == 'all':
                models = installed
            else:
                indices = [int(x.strip()) - 1 for x in choice.split(',') if x.strip().isdigit()]
                models = [installed[i] for i in indices if 0 <= i < len(installed)]

            if not models:
                print_error("No valid models selected")
                sys.exit(1)

        except (ValueError, KeyboardInterrupt):
            print_error("Invalid input")
            sys.exit(1)

    # Run benchmark
    if args.quick:
        # Quick benchmark with single test
        test_prompt = "Write a simple hello world function in Python."
        print_status("Running quick benchmark...")

        for model in models:
            result = benchmark_model(model, test_prompt, max_tokens=50)
            if result["success"]:
                print_success(
                    f"{model}: {result['response_time']:.2f}s / "
                    f"{result['tokens_per_second']:.2f} tok/s"
                )
            else:
                print_error(f"{model}: Failed ({result['error']})")
    else:
        # Full benchmark
        results = run_comprehensive_benchmark(models, args.output)
        print_results_summary(results)

if __name__ == "__main__":
    main()