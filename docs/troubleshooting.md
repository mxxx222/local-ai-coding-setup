# Troubleshooting Guide

## Common Issues and Solutions

### Ollama Installation Issues

#### "Ollama command not found"
**Problem**: Ollama is not installed or not in PATH.
**Solution**:
1. Check if Ollama is installed: `ollama --version`
2. If not installed, run: `./scripts/install_ollama.sh`
3. Add Ollama to PATH if needed (usually automatic)

#### "Failed to start Ollama service"
**Problem**: Ollama service won't start.
**Solution**:
1. Check system resources: `python3 scripts/health_check.py`
2. Kill existing processes: `pkill -f ollama`
3. Restart Ollama: `ollama serve`
4. Check logs: `ollama logs`

### Model Download Issues

#### "Model download stuck or slow"
**Problem**: Model downloads are slow or hanging.
**Solution**:
1. Check internet connection
2. Use a different mirror if available
3. Download smaller models first
4. Monitor with: `ollama ps`

#### "Out of disk space during model download"
**Problem**: Insufficient storage for models.
**Solution**:
1. Check available space: `df -h`
2. Clean up old models: `ollama list` then `ollama rm <model>`
3. Free up space or use external storage

### VS Code Integration Issues

#### "Continue.dev extension not working"
**Problem**: VS Code extension fails to connect.
**Solution**:
1. Verify config: `cat ~/.continue/config.json`
2. Restart VS Code
3. Check Ollama is running: `ollama ps`
4. Reinstall extension: `code --uninstall-extension continue.continue && code --install-extension continue.continue`

#### "No models available in Continue"
**Problem**: Models not showing in VS Code.
**Solution**:
1. Pull models: `ollama pull dolphin-mixtral-8x7b`
2. Restart Continue extension
3. Check config points to correct Ollama endpoint

### Performance Issues

#### "AI responses are slow"
**Problem**: Inference is slow.
**Solution**:
1. Check hardware usage: `python3 scripts/health_check.py`
2. Use smaller models for faster responses
3. Adjust context length in config
4. Consider GPU acceleration if available

#### "High memory usage"
**Problem**: System memory is exhausted.
**Solution**:
1. Monitor usage: `python3 scripts/health_check.py`
2. Reduce model size or context length
3. Close unused applications
4. Consider CPU-only models

### Hardware-Specific Issues

#### Apple Silicon (M1/M2/M3)
- Ensure Metal acceleration is enabled
- Check for macOS updates
- Verify model compatibility

#### NVIDIA GPU Issues
- Install CUDA drivers
- Check GPU memory: `nvidia-smi`
- Update GPU drivers

#### CPU-only Systems
- Use quantized models (Q4_K_M)
- Reduce context length
- Consider smaller models

### Network Issues

#### "Cannot connect to Ollama API"
**Problem**: Network connectivity issues.
**Solution**:
1. Check Ollama is running: `ollama ps`
2. Verify port 11434 is open: `netstat -tlnp | grep 11434`
3. Check firewall settings
4. Restart Ollama service

### Configuration Issues

#### "Config file syntax error"
**Problem**: JSON syntax errors in config files.
**Solution**:
1. Validate JSON: `python3 -m json.tool configs/continue_config.json`
2. Check for missing commas or brackets
3. Use online JSON validator

### Advanced Troubleshooting

#### Enable Debug Logging
```bash
# For Ollama
export OLLAMA_DEBUG=1
ollama serve

# For Continue.dev
# Add to VS Code settings:
{
  "continue.debug": true
}
```

#### System Health Check
Run comprehensive diagnostics:
```bash
python3 scripts/health_check.py --verbose
```

#### Reset Configuration
If all else fails, reset to defaults:
```bash
# Backup current config
cp ~/.continue/config.json ~/.continue/config.json.backup

# Reset to default
cp configs/continue_config.json ~/.continue/config.json
```

## Getting Help

1. Check the [README.md](README.md) for basic setup
2. Review [hardware_recommendations.md](hardware_recommendations.md)
3. Run health checks regularly
4. Check Ollama documentation: https://github.com/jmorganca/ollama
5. Continue.dev docs: https://docs.continue.dev/

## Prevention Tips

- Run health checks weekly
- Keep system updated
- Monitor disk space regularly
- Backup configurations
- Test with small models first