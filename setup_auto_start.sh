#!/bin/bash

# Setup Auto-Start Script for Local AI Coding Setup
# Adds auto-start functionality to shell profiles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Auto-Start for Local AI Coding${NC}"
echo "==============================================="

# Determine shell profile
SHELL_PROFILE=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_PROFILE="$HOME/.bashrc"
else
    echo -e "${YELLOW}⚠️ Unsupported shell: $SHELL${NC}"
    echo "Please manually add the auto-start function to your shell profile."
    exit 1
fi

echo "📝 Detected shell profile: $SHELL_PROFILE"

# Create auto-start function
AUTO_START_FUNCTION="
# Local AI Coding Auto-Start Function
ai-start() {
    local script_dir=\"\$(cd \"\$(dirname \"\${BASH_SOURCE[0]:-\$0}\")\" && pwd)\"
    if [[ -f \"\$script_dir/auto_start.sh\" ]]; then
        \"\$script_dir/auto_start.sh\"
    else
        echo \"❌ auto_start.sh not found in \$script_dir\"
        return 1
    fi
}

# Auto-start AI on shell login (optional - comment out if not wanted)
# ai-start
"

# Check if function already exists
if grep -q "ai-start()" "$SHELL_PROFILE" 2>/dev/null; then
    echo -e "${YELLOW}⚠️ ai-start function already exists in $SHELL_PROFILE${NC}"
    read -p "Overwrite existing function? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping function update."
    else
        # Remove existing function
        sed -i.bak '/# Local AI Coding Auto-Start Function/,/^}/d' "$SHELL_PROFILE"
        echo "$AUTO_START_FUNCTION" >> "$SHELL_PROFILE"
        echo -e "${GREEN}✅ Function updated${NC}"
    fi
else
    echo "$AUTO_START_FUNCTION" >> "$SHELL_PROFILE"
    echo -e "${GREEN}✅ Auto-start function added to $SHELL_PROFILE${NC}"
fi

# Create desktop shortcut (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    echo "🖥️ Creating desktop shortcut..."

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SHORTCUT_PATH="$HOME/Desktop/AI_Start.command"

    cat > "$SHORTCUT_PATH" << EOF
#!/bin/bash
cd "$SCRIPT_DIR"
./auto_start.sh
EOF

    chmod +x "$SHORTCUT_PATH"
    echo -e "${GREEN}✅ Desktop shortcut created: $SHORTCUT_PATH${NC}"
fi

# Create launch agent for macOS (optional auto-start on login)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ""
    read -p "🤖 Create macOS Launch Agent for auto-start on login? (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
        mkdir -p "$LAUNCH_AGENT_DIR"

        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/com.local-ai-coding.autostart.plist"

        cat > "$LAUNCH_AGENT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local-ai-coding.autostart</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/auto_start.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/local-ai-coding.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/local-ai-coding-error.log</string>
</dict>
</plist>
EOF

        # Load the launch agent
        launchctl load "$LAUNCH_AGENT_PLIST"
        echo -e "${GREEN}✅ Launch Agent created and loaded${NC}"
        echo "AI will now start automatically on login"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Auto-start setup complete!${NC}"
echo ""
echo "🚀 Usage options:"
echo "1. Terminal: Run 'ai-start' in any terminal"
echo "2. Desktop: Double-click 'AI_Start.command' on desktop"
if [[ "$OSTYPE" == "darwin"* ]] && [[ -f "$LAUNCH_AGENT_PLIST" ]]; then
    echo "3. Auto: AI starts automatically on login"
fi
echo ""
echo "💡 Test it now:"
echo "   ai-start"
echo ""
echo "Happy coding with automated AI! 🤖⚡"