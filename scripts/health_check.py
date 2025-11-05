#!/usr/bin/env python3
"""
System Health Check for Local AI Coding Setup
Monitors Ollama, llama.cpp, and system resources
"""

import os
import sys
import json
import time
import subprocess
from datetime import datetime
import socket

# Optional imports with graceful fallbacks
try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

try:
    import urllib3
    urllib3.disable_warnings()
    HAS_URLLIB3 = True
except ImportError:
    HAS_URLLIB3 = False

class HealthChecker:
    def __init__(self):
        self.results = {
            "timestamp": datetime.now().isoformat(),
            "checks": {},
            "system_info": {},
            "recommendations": []
        }
        
        # Colors for terminal output
        self.colors = {
            'red': '\033[0;31m',
            'green': '\033[0;32m',
            'yellow': '\033[1;33m',
            'blue': '\033[0;34m',
            'purple': '\033[0;35m',
            'cyan': '\033[0;36m',
            'reset': '\033[0m'
        }
    
    def print_colored(self, message, color='reset'):
        print(f"{self.colors[color]}{message}{self.colors['reset']}")
    
    def print_header(self, title):
        self.print_colored(f"\n{'='*50}", 'cyan')
        self.print_colored(f"  {title}", 'purple')
        self.print_colored(f"{'='*50}\n", 'cyan')
    
    def print_status(self, component, status, message):
        if status == 'OK':
            self.print_colored(f"  ✅ {component}: {message}", 'green')
        elif status == 'WARNING':
            self.print_colored(f"  ⚠️  {component}: {message}", 'yellow')
        elif status == 'ERROR':
            self.print_colored(f"  ❌ {component}: {message}", 'red')
        else:
            self.print_colored(f"  ℹ️  {component}: {message}", 'blue')
    
    def check_system_info(self):
        """Check basic system information"""
        self.print_header("System Information")
        
        if not HAS_PSUTIL:
            self.print_status("Dependencies", "WARNING", "psutil not available - limited system info")
            # Fallback to basic system info
            try:
                import platform
                cpu_cores = os.cpu_count() or "Unknown"
                self.print_status("CPU", "INFO", f"Detected cores: {cpu_cores}")
                self.print_status("Platform", "INFO", f"{platform.system()} {platform.release()}")
                self.results["checks"]["system_info"] = "WARNING"
                return
            except:
                self.print_status("System Info", "ERROR", "No system information available")
                self.results["checks"]["system_info"] = "ERROR"
                return
        
        try:
            # CPU information
            cpu_count = psutil.cpu_count(logical=False)  # physical cores
            cpu_count_logical = psutil.cpu_count(logical=True)  # logical cores
            cpu_freq = psutil.cpu_freq()
            
            # Memory information
            memory = psutil.virtual_memory()
            memory_gb = memory.total / (1024**3)
            
            # Disk information
            disk = psutil.disk_usage('/')
            disk_gb = disk.total / (1024**3)
            disk_free_gb = disk.free / (1024**3)
            
            # Load average (Unix-like systems)
            try:
                load_avg = os.getloadavg()
            except AttributeError:
                load_avg = None
            
            self.print_status("CPU", "INFO", f"{cpu_count} cores ({cpu_count_logical} logical)")
            if cpu_freq:
                self.print_status("CPU Frequency", "INFO", f"{cpu_freq.current:.0f} MHz")
            
            self.print_status("Memory", "INFO", f"{memory_gb:.1f} GB total, {memory.percent:.1f}% used")
            self.print_status("Disk", "INFO", f"{disk_gb:.1f} GB total, {disk_free_gb:.1f} GB free")
            
            if load_avg:
                self.print_status("Load Average", "INFO", f"{load_avg[0]:.2f}, {load_avg[1]:.2f}, {load_avg[2]:.2f}")
            
            # Store in results
            self.results["system_info"] = {
                "cpu_cores": cpu_count,
                "cpu_cores_logical": cpu_count_logical,
                "cpu_frequency": cpu_freq.current if cpu_freq else None,
                "memory_total_gb": round(memory_gb, 1),
                "memory_used_percent": memory.percent,
                "disk_total_gb": round(disk_gb, 1),
                "disk_free_gb": round(disk_free_gb, 1),
                "load_average": load_avg
            }
            
            self.results["checks"]["system_info"] = "OK"
            
        except Exception as e:
            self.print_status("System Info", "ERROR", f"Failed to get system info: {e}")
            self.results["checks"]["system_info"] = "ERROR"
    
    def check_ollama_service(self):
        """Check if Ollama service is running"""
        self.print_header("Ollama Service Check")
        
        try:
            # Check if process is running
            ollama_running = False
            for proc in psutil.process_iter(['pid', 'name']):
                if 'ollama' in proc.info['name'].lower():
                    ollama_running = True
                    self.print_status("Ollama Process", "OK", f"Running (PID: {proc.info['pid']})")
                    break
            
            if not ollama_running:
                self.print_status("Ollama Process", "WARNING", "Not running")
                self.results["checks"]["ollama_process"] = "WARNING"
            
            # Check API endpoint
            try:
                response = requests.get("http://localhost:11434/api/health", timeout=5)
                if response.status_code == 200:
                    self.print_status("Ollama API", "OK", "Responding on port 11434")
                    self.results["checks"]["ollama_api"] = "OK"
                else:
                    self.print_status("Ollama API", "WARNING", f"Unexpected status: {response.status_code}")
                    self.results["checks"]["ollama_api"] = "WARNING"
            except requests.exceptions.ConnectionError:
                self.print_status("Ollama API", "ERROR", "Not responding on port 11434")
                self.results["checks"]["ollama_api"] = "ERROR"
            except requests.exceptions.Timeout:
                self.print_status("Ollama API", "WARNING", "Timeout - service may be slow")
                self.results["checks"]["ollama_api"] = "WARNING"
            
            # Check models
            try:
                response = requests.get("http://localhost:11434/api/tags", timeout=5)
                if response.status_code == 200:
                    models_data = response.json()
                    model_count = len(models_data.get('models', []))
                    if model_count > 0:
                        self.print_status("Models", "OK", f"{model_count} model(s) available")
                        for model in models_data['models']:
                            size_gb = model.get('size', 0) / (1024**3)
                            self.print_status(f"  - {model['name']}", "INFO", f"{size_gb:.1f} GB")
                    else:
                        self.print_status("Models", "WARNING", "No models downloaded")
                    self.results["checks"]["ollama_models"] = "OK"
                else:
                    self.print_status("Models", "WARNING", f"API returned: {response.status_code}")
                    self.results["checks"]["ollama_models"] = "WARNING"
            except Exception as e:
                self.print_status("Models", "ERROR", f"Failed to check models: {e}")
                self.results["checks"]["ollama_models"] = "ERROR"
                
        except Exception as e:
            self.print_status("Ollama Service", "ERROR", f"Check failed: {e}")
            self.results["checks"]["ollama_service"] = "ERROR"
    
    def check_llama_cpp(self):
        """Check if llama.cpp server is running"""
        self.print_header("llama.cpp Check")
        
        try:
            # Check if server process is running
            llama_running = False
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                try:
                    cmdline = proc.info['cmdline']
                    if cmdline and 'server' in ' '.join(cmdline):
                        llama_running = True
                        self.print_status("llama.cpp Server", "OK", f"Running (PID: {proc.info['pid']})")
                        break
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            if not llama_running:
                self.print_status("llama.cpp Server", "WARNING", "Not running")
                self.results["checks"]["llama_cpp_server"] = "WARNING"
            
            # Check server endpoint
            try:
                response = requests.get("http://localhost:8080/health", timeout=5)
                if response.status_code == 200:
                    self.print_status("llama.cpp API", "OK", "Responding on port 8080")
                    self.results["checks"]["llama_cpp_api"] = "OK"
                else:
                    self.print_status("llama.cpp API", "WARNING", f"Unexpected status: {response.status_code}")
                    self.results["checks"]["llama_cpp_api"] = "WARNING"
            except requests.exceptions.ConnectionError:
                self.print_status("llama.cpp API", "WARNING", "Not responding on port 8080")
                self.results["checks"]["llama_cpp_api"] = "WARNING"
            except requests.exceptions.Timeout:
                self.print_status("llama.cpp API", "WARNING", "Timeout")
                self.results["checks"]["llama_cpp_api"] = "WARNING"
            
            # Check for models
            model_path = os.path.expanduser("~/llama_models")
            if os.path.exists(model_path):
                models = [f for f in os.listdir(model_path) if f.endswith('.gguf')]
                if models:
                    self.print_status("llama.cpp Models", "OK", f"{len(models)} model(s) found")
                    for model in models[:3]:  # Show first 3
                        model_size = os.path.getsize(os.path.join(model_path, model)) / (1024**3)
                        self.print_status(f"  - {model}", "INFO", f"{model_size:.1f} GB")
                    if len(models) > 3:
                        self.print_status(f"  ... and {len(models)-3} more", "INFO", "")
                else:
                    self.print_status("llama.cpp Models", "WARNING", "No GGUF models found")
                self.results["checks"]["llama_cpp_models"] = "OK"
            else:
                self.print_status("llama.cpp Models", "WARNING", "Models directory not found")
                self.results["checks"]["llama_cpp_models"] = "WARNING"
                
        except Exception as e:
            self.print_status("llama.cpp Check", "ERROR", f"Check failed: {e}")
            self.results["checks"]["llama_cpp"] = "ERROR"
    
    def check_vscode_integration(self):
        """Check VS Code integration"""
        self.print_header("VS Code Integration Check")
        
        try:
            # Check Continue.dev config
            continue_config = os.path.expanduser("~/.continue/config.json")
            if os.path.exists(continue_config):
                with open(continue_config, 'r') as f:
                    config_data = json.load(f)
                    model_count = len(config_data.get('models', []))
                    self.print_status("Continue.dev Config", "OK", f"{model_count} model(s) configured")
                    self.results["checks"]["continue_config"] = "OK"
            else:
                self.print_status("Continue.dev Config", "WARNING", "Config file not found")
                self.results["checks"]["continue_config"] = "WARNING"
            
            # Check VS Code extensions
            try:
                result = subprocess.run(['code', '--list-extensions'], 
                                      capture_output=True, text=True, timeout=10)
                if 'continue.continue' in result.stdout:
                    self.print_status("Continue.dev Extension", "OK", "Installed")
                    self.results["checks"]["continue_extension"] = "OK"
                else:
                    self.print_status("Continue.dev Extension", "WARNING", "Not installed")
                    self.results["checks"]["continue_extension"] = "WARNING"
            except (subprocess.TimeoutExpired, subprocess.SubprocessError, FileNotFoundError):
                self.print_status("VS Code", "WARNING", "Not found or not accessible")
                self.results["checks"]["vscode"] = "WARNING"
                
        except Exception as e:
            self.print_status("VS Code Integration", "ERROR", f"Check failed: {e}")
            self.results["checks"]["vscode_integration"] = "ERROR"
    
    def check_network_connectivity(self):
        """Check network connectivity"""
        self.print_header("Network Connectivity")
        
        try:
            # Test internet connectivity
            try:
                response = requests.get("https://www.google.com", timeout=5)
                self.print_status("Internet", "OK", "Connected")
                self.results["checks"]["internet"] = "OK"
            except requests.exceptions.ConnectionError:
                self.print_status("Internet", "WARNING", "No connection")
                self.results["checks"]["internet"] = "WARNING"
            
            # Test local ports
            ports_to_check = [
                (11434, "Ollama"),
                (8080, "llama.cpp"),
                (1234, "LM Studio (optional)")
            ]
            
            for port, name in ports_to_check:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(1)
                result = sock.connect_ex(('localhost', port))
                if result == 0:
                    self.print_status(f"{name} Port", "OK", f"Port {port} open")
                else:
                    self.print_status(f"{name} Port", "INFO", f"Port {port} closed")
                sock.close()
            
        except Exception as e:
            self.print_status("Network Check", "ERROR", f"Check failed: {e}")
            self.results["checks"]["network"] = "ERROR"
    
    def check_performance_metrics(self):
        """Check performance and resource usage"""
        self.print_header("Performance Metrics")
        
        try:
            # CPU usage
            cpu_percent = psutil.cpu_percent(interval=1)
            if cpu_percent < 50:
                self.print_status("CPU Usage", "OK", f"{cpu_percent:.1f}%")
                self.results["checks"]["cpu_usage"] = "OK"
            elif cpu_percent < 80:
                self.print_status("CPU Usage", "WARNING", f"{cpu_percent:.1f}% (moderate load)")
                self.results["checks"]["cpu_usage"] = "WARNING"
            else:
                self.print_status("CPU Usage", "ERROR", f"{cpu_percent:.1f}% (high load)")
                self.results["checks"]["cpu_usage"] = "ERROR"
            
            # Memory usage
            memory = psutil.virtual_memory()
            if memory.percent < 70:
                self.print_status("Memory Usage", "OK", f"{memory.percent:.1f}% used")
                self.results["checks"]["memory_usage"] = "OK"
            elif memory.percent < 85:
                self.print_status("Memory Usage", "WARNING", f"{memory.percent:.1f}% used (getting high)")
                self.results["checks"]["memory_usage"] = "WARNING"
            else:
                self.print_status("Memory Usage", "ERROR", f"{memory.percent:.1f}% used (critical)")
                self.results["checks"]["memory_usage"] = "ERROR"
            
            # Disk usage
            disk = psutil.disk_usage('/')
            disk_percent = (disk.used / disk.total) * 100
            if disk_percent < 80:
                self.print_status("Disk Usage", "OK", f"{disk_percent:.1f}% used")
                self.results["checks"]["disk_usage"] = "OK"
            elif disk_percent < 90:
                self.print_status("Disk Usage", "WARNING", f"{disk_percent:.1f}% used (getting full)")
                self.results["checks"]["disk_usage"] = "WARNING"
            else:
                self.print_status("Disk Usage", "ERROR", f"{disk_percent:.1f}% used (critical)")
                self.results["checks"]["disk_usage"] = "ERROR"
            
            # Process information for AI services
            ai_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent']):
                try:
                    if any(term in proc.info['name'].lower() for term in ['ollama', 'llama', 'server']):
                        ai_processes.append(proc.info)
                except (psutil.NoSuchProcess, psutil.AccessDenied):
                    continue
            
            if ai_processes:
                self.print_status("AI Processes", "OK", f"{len(ai_processes)} found")
                for proc in ai_processes[:3]:  # Show first 3
                    self.print_status(f"  {proc['name']}", "INFO", 
                                    f"PID: {proc['pid']}, CPU: {proc['cpu_percent']:.1f}%, "
                                    f"Memory: {proc['memory_percent']:.1f}%")
            else:
                self.print_status("AI Processes", "WARNING", "No AI processes detected")
                self.results["checks"]["ai_processes"] = "WARNING"
                
        except Exception as e:
            self.print_status("Performance Check", "ERROR", f"Check failed: {e}")
            self.results["checks"]["performance"] = "ERROR"
    
    def generate_recommendations(self):
        """Generate recommendations based on health check results"""
        self.print_header("Recommendations")
        
        recommendations = []
        
        # Check for common issues and suggest fixes
        if self.results["checks"].get("ollama_process") == "WARNING":
            recommendations.append("Start Ollama: ~/.ollama/start.sh")
        
        if self.results["checks"].get("ollama_api") == "ERROR":
            recommendations.append("Check if Ollama service is running: ~/.ollama/status.sh")
        
        if self.results["checks"].get("ollama_models") == "WARNING":
            recommendations.append("Download models: ollama pull dolphin-mistral:7b-dpo-laser")
        
        if self.results["checks"].get("continue_extension") == "WARNING":
            recommendations.append("Install Continue.dev: code --install-extension continue.continue")
        
        if self.results["checks"].get("cpu_usage") == "ERROR":
            recommendations.append("High CPU usage - close unnecessary applications")
        
        if self.results["checks"].get("memory_usage") == "ERROR":
            recommendations.append("High memory usage - restart applications or add more RAM")
        
        if self.results["checks"].get("disk_usage") == "ERROR":
            recommendations.append("Low disk space - free up space or move models to external drive")
        
        # Performance recommendations
        memory_gb = self.results["system_info"].get("memory_total_gb", 0)
        if memory_gb >= 16:
            recommendations.append("Consider downloading larger models (13B+) for better coding assistance")
        elif memory_gb >= 8:
            recommendations.append("Medium models (7B-13B) should provide good performance")
        else:
            recommendations.append("Limited memory - stick to small models (3B-7B)")
        
        # System optimization recommendations
        if sys.platform == "darwin":
            recommendations.append("For Apple Silicon: Ensure Metal acceleration is enabled (LLAMA_METAL=1)")
        elif sys.platform.startswith("linux"):
            recommendations.append("Consider installing CUDA drivers for NVIDIA GPU acceleration")
        
        # Print recommendations
        if recommendations:
            for i, rec in enumerate(recommendations, 1):
                self.print_colored(f"  {i}. {rec}", 'blue')
        else:
            self.print_colored("  ✅ No issues detected - system is healthy!", 'green')
        
        self.results["recommendations"] = recommendations
    
    def save_results(self, filename="health_check_results.json"):
        """Save health check results to file"""
        try:
            with open(filename, 'w') as f:
                json.dump(self.results, f, indent=2)
            self.print_colored(f"\n📊 Results saved to: {filename}", 'cyan')
        except Exception as e:
            self.print_colored(f"\n❌ Failed to save results: {e}", 'red')
    
    def run_full_check(self):
        """Run complete health check"""
        self.print_colored("🚀 Local AI Coding Setup - System Health Check", 'purple')
        self.print_colored("="*50, 'purple')
        
        # Run all checks
        self.check_system_info()
        self.check_ollama_service()
        self.check_llama_cpp()
        self.check_vscode_integration()
        self.check_network_connectivity()
        self.check_performance_metrics()
        self.generate_recommendations()
        
        # Summary
        self.print_header("Summary")
        total_checks = len(self.results["checks"])
        ok_count = sum(1 for status in self.results["checks"].values() if status == "OK")
        warning_count = sum(1 for status in self.results["checks"].values() if status == "WARNING")
        error_count = sum(1 for status in self.results["checks"].values() if status == "ERROR")
        
        self.print_colored(f"Total Checks: {total_checks}", 'blue')
        self.print_colored(f"✅ Passed: {ok_count}", 'green')
        self.print_colored(f"⚠️  Warnings: {warning_count}", 'yellow')
        self.print_colored(f"❌ Errors: {error_count}", 'red')
        
        # Overall status
        if error_count == 0:
            status_msg = "System is healthy! 🎉"
            status_color = 'green'
        elif error_count < warning_count:
            status_msg = "System has some issues but is functional ⚠️"
            status_color = 'yellow'
        else:
            status_msg = "System has significant issues that need attention ❌"
            status_color = 'red'
        
        self.print_colored(f"\nOverall Status: {status_msg}", status_color)
        
        return self.results

def main():
    checker = HealthChecker()
    results = checker.run_full_check()
    
    # Ask if user wants to save results
    print("\n" + "="*50)
    save_choice = input("Save detailed results to file? (y/n): ").strip().lower()
    if save_choice in ['y', 'yes']:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"health_check_{timestamp}.json"
        checker.save_results(filename)
    
    # Exit with appropriate code
    error_count = sum(1 for status in results["checks"].values() if status == "ERROR")
    sys.exit(0 if error_count == 0 else 1)

if __name__ == "__main__":
    main()