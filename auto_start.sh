#!/bin/bash

# Automated Startup Script for Local AI Coding Setup
# Automatically starts Ollama service and checks system health

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Local AI Coding - Auto Start${NC}"
echo "=================================="

# Check if Ollama is already running
if pgrep -f ollama >/dev/null; then
    echo -e "${GREEN}✅ Ollama is already running${NC}"

    # Check if API is responding
    if curl -s http://localhost:11434/api/tags >/dev/null; then
        echo -e "${GREEN}✅ Ollama API is responding${NC}"

        # Show available models
        echo ""
        echo "📋 Available models:"
        ollama list
        echo ""
        echo -e "${GREEN}🎉 Ready to code with AI!${NC}"
        echo "Open VS Code and press Cmd/Ctrl+I to start chatting with your AI assistant."
        exit 0
    else
        echo -e "${YELLOW}⚠️ Ollama process found but API not responding. Restarting...${NC}"
        killall ollama
        sleep 2
    fi
fi

# Load environment variables if they exist
if [[ -f ~/.local_ai_env ]]; then
    echo "⚡ Loading optimized environment..."
    source ~/.local_ai_env
fi

# Start Ollama service
echo ""
echo "🚀 Starting Ollama service..."
ollama serve &
OLLAMA_PID=$!

# Wait for service to start
echo "⏳ Waiting for Ollama to initialize..."
sleep 5

# Check if service started successfully
if ! kill -0 $OLLAMA_PID 2>/dev/null; then
    echo -e "${RED}❌ Failed to start Ollama service${NC}"
    exit 1
fi

# Verify API is responding
MAX_ATTEMPTS=10
ATTEMPT=1

while [[ $ATTEMPT -le $MAX_ATTEMPTS ]]; do
    echo "🔍 Checking API connectivity (attempt $ATTEMPT/$MAX_ATTEMPTS)..."

    if curl -s http://localhost:11434/api/tags >/dev/null; then
        echo -e "${GREEN}✅ Ollama API is responding${NC}"
        break
    fi

    if [[ $ATTEMPT -eq $MAX_ATTEMPTS ]]; then
        echo -e "${RED}❌ Ollama API not responding after $MAX_ATTEMPTS attempts${NC}"
        echo "Try running: ~/.ollama/start.sh"
        exit 1
    fi

    sleep 3
    ((ATTEMPT++))
done

# Show available models
echo ""
echo "📋 Available models:"
ollama list

# Test primary model if available
PRIMARY_MODEL=$(ollama list | grep -E "(dolphin-mixtral|wizardlm-uncensored|dolphin-mistral)" | head -1 | awk '{print $1}')

if [[ -n "$PRIMARY_MODEL" ]]; then
    echo ""
    echo "🧪 Testing AI model response..."
    TEST_RESPONSE=$(timeout 10 ollama run "$PRIMARY_MODEL" "Hello! Are you ready to help with coding?" --max-tokens 50 2>/dev/null || echo "")

    if [[ -n "$TEST_RESPONSE" ]]; then
        echo -e "${GREEN}✅ AI model is responding correctly!${NC}"
    else
        echo -e "${YELLOW}⚠️ Model test timed out - may be loading${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Local AI Coding Setup is ready!${NC}"
echo ""
echo "🚀 Next steps:"
echo "1. Open VS Code"
echo "2. Open your project"
echo "3. Press Cmd/Ctrl+I to chat with your AI assistant"
echo ""
echo "💡 Quick commands:"
echo "   Check status: ~/.ollama/status.sh"
echo "   Stop service: ~/.ollama/stop.sh"
echo "   View models: ollama list"
echo ""
echo "Happy coding with AI! 🤖💻"