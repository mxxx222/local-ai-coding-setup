# 🔧 Immediate Equipment Verification Checklist

## **⚡ Quick Setup Verification (15 minutes)**

### **Step 1: MacBook Hardware Verification**

**Run this command to check your specs:**
```bash
system_profiler SPHardwareDataType
```

**Expected output analysis:**
```
If you see:**
- "MacBook Pro" with M1/M2/M3 = **Premium demo target**
- 16GB RAM = Standard tier (Dolphin-8x7B recommended)
- 32GB+ RAM = Premium tier (Dolphin-34B or 72B recommended)
- 8GB RAM = Basic tier (Dolphin-7B recommended)
```

**GPU Verification:**
```bash
system_profiler SPDisplaysDataType | grep "Chipset Model"
```

**Expected for optimal demo:**
- "Apple M3" = **Excellent** (40+ GPU cores)
- "Apple M2" = **Good** (25+ GPU cores)  
- "Apple M1" = **Adequate** (8+ GPU cores)

### **Step 2: Recording Software Check**

**Test your screen recording capabilities:**

**Option A - QuickTime (Built-in)**
```bash
# Test QuickTime availability
which quicktimeplayer
# Should return: /System/Library/Frameworks/QuickTime.framework/Versions/Current/QuickTimePlayer

# Test screen recording
open -a "Screenshot" # Alternative to test screenshot capability
```

**Option B - OBS Studio (Recommended)**
```bash
# Check if installed
which obs
# If not installed, get it from: https://obsproject.com
```

**Option C - ScreenFlow (Professional)**
```bash
# Check if ScreenFlow is installed
ls /Applications/ScreenFlow*
# If not installed, download from: https://www.telestream.net/screenflow/
```

### **Step 3: Audio Setup Test**

**Test current microphone:**
```bash
# Check audio input devices
system_profiler SPAudioDataType | grep -A 10 "Inputs"

# Quick recording test
# Open QuickTime Player > File > New Audio Recording
# Record 30 seconds of speech
# Play back and check:
# - Clear speech without clipping
# - Minimal background noise
# - Consistent volume levels
```

**Audio level target:**
- **Green zone**: -12dB to -6dB peak levels (optimal)
- **Red zone**: Above -6dB (risking distortion)
- **Too low**: Below -12dB (hard to hear)

### **Step 4: Development Environment Prep**

**Terminal Setup:**
```bash
# Check if iTerm2 is available
which iterm
# If not: brew install --cask iterm2

# Check ZSH shell
echo $SHELL
# Should show: /bin/zsh or /usr/bin/zsh

# Test Oh My Zsh (for enhanced terminal)
ls ~/.oh-my-zsh
# If missing: sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

**VS Code Setup:**
```bash
# Check VS Code installation
which code
# Should return path to VS Code

# Verify Continue.dev extension
code --list-extensions | grep continue
# Should show: continue.continue
```

### **Step 5: Ollama Installation Test**

**Install and test Ollama:**
```bash
# Install Ollama (if not already installed)
curl -fsSL https://ollama.ai/install.sh | sh

# Verify installation
ollama --version

# Test model download (Dolphin-7B for demo)
ollama pull dolphin-2.6-mistral-7b

# Test model performance
time ollama run dolphin-2.6-mistral-7b "Write a simple hello world function in Python"
```

**Performance benchmarks for demo:**
- **Loading time**: < 15 seconds (good), < 10 seconds (excellent)
- **Response time**: < 30 seconds (acceptable), < 15 seconds (great)

### **Step 6: Clean Desktop Preparation**

**Quick desktop cleanup:**
```bash
# Organize desktop files
mkdir ~/Desktop/demo-materials
mv ~/Desktop/*.pdf ~/Desktop/demo-materials/ 2>/dev/null || true
mv ~/Desktop/*.png ~/Desktop/demo-materials/ 2>/dev/null || true
mv ~/Desktop/*.docx ~/Desktop/demo-materials/ 2>/dev/null || true

# Hide unnecessary files
defaults write com.apple.finder ShowHiddenFiles -bool YES

# Set clean desktop as background
# System Preferences > Desktop & Screen Saver > Solid Colors
```

### **Step 7: Browser Setup**

**Clean browser profile for demo:**
```bash
# Create clean Chrome profile
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --user-data-dir="~/Desktop/demo-chrome-profile" --new-window

# Navigate to and bookmark:
# - GitHub repository: https://github.com/mxxx222/local-ai-coding-setup
# - Pricing comparison pages for demo
```

## **🎯 Demo-Ready Checklist**

### **Critical Success Factors**
```
✅ Hardware Verification:
  [ ] MacBook model and RAM confirmed
  [ ] GPU cores and performance verified
  [ ] Storage space adequate (>50GB free)

✅ Recording Setup:
  [ ] Screen recording software tested
  [ ] Audio levels optimized (-12dB to -6dB)
  [ ] Recording quality meets platform requirements

✅ Development Environment:
  [ ] Terminal customized and ready
  [ ] VS Code with Continue.dev working
  [ ] Demo project structure prepared

✅ AI Environment:
  [ ] Ollama installed and running
  [ ] Demo model downloaded and tested
  [ ] Response times within acceptable range

✅ Presentation Setup:
  [ ] Clean desktop environment
  [ ] Browser with demo materials ready
  [ ] Performance monitoring tools active
```

## **⚠️ Common Issues & Quick Fixes**

### **Audio Problems**
```
Issue: Built-in mic too quiet/quiet background noise
Quick Fix:
  1. Use headphones with built-in mic (AirPods work well)
  2. Record in quieter environment
  3. Position closer to microphone

Issue: Audio clipping/distortion
Quick Fix:
  1. Lower system volume during recording
  2. Check microphone input levels in System Preferences
  3. Use built-in noise reduction in recording software
```

### **Performance Issues**
```
Issue: AI responses too slow for demo
Quick Fix:
  1. Use smaller model (Dolphin-7B vs Dolphin-34B)
  2. Pre-load model before recording starts
  3. Have backup responses ready

Issue: Screen recording lag
Quick Fix:
  1. Close unnecessary applications
  2. Restart MacBook for fresh start
  3. Reduce recording resolution if needed (1280x720 vs 1920x1080)
```

### **Software Issues**
```
Issue: VS Code extension not working
Quick Fix:
  1. Restart VS Code completely
  2. Reinstall Continue.dev extension
  3. Check Ollama service status: ollama serve

Issue: Terminal customization not loading
Quick Fix:
  1. Restart terminal application
  2. Reload shell: source ~/.zshrc
  3. Check for syntax errors in config files
```

## **📱 Final Pre-Recording Test**

### **30-Second Test Recording**
```
1. Open screen recording software
2. Record terminal with hardware check:
   $ system_profiler SPHardwareDataType | grep "Memory"
   $ ollama list
   $ code --version
3. Record 15 seconds of VS Code usage
4. Test AI query: "Create a simple React component"
5. Stop recording and verify quality

✅ Success Criteria:
- Video: Smooth 60fps, clear text
- Audio: Clear speech, no background noise  
- AI: Response within 30 seconds
- Overall: Professional presentation quality
```

## **🚀 Ready for Recording When...**

### **All Green Lights**
```
🎯 Performance: AI responses under 45 seconds
🎯 Recording: 60fps smooth, clear audio
🎯 Environment: Clean, organized, professional
🎯 Backup: Alternative plans ready if needed
```

### **Execute Recording Session**
```
⏰ Session 1: 3-minute demo (practice run)
⏰ Session 2: 3-minute demo (final take)  
⏰ Session 3: 5-minute extended demo
⏰ Session 4: 30-second teaser clips

🎬 Record all sessions back-to-back for consistency
🎬 Take breaks between major segments to maintain energy
🎬 Have water and notes nearby for longer sessions
```

**Your verification checklist is ready! Start with Step 1 (hardware check) and work through systematically. Most setups should be demo-ready within 15-30 minutes. 🎬**