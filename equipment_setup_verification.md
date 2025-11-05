# 🎥 Equipment Setup & Demo Environment Preparation

## **📋 Complete Equipment Verification Checklist**

### **Essential Hardware**
```
✅ MacBook Pro M3 Max (or equivalent M-series)
✅ External monitor (for dual-screen recording setup)
✅ USB-C hub/docking station (if needed)
✅ Quality microphone (Blue Yeti, Audio-Technica AT2020, or equivalent)
✅ Audio interface (Focusrite Scarlett Solo or equivalent - optional)
✅ Ring light or softbox lighting setup
✅ Tripod for camera/smartphone (if recording yourself)
✅ Clean desk space with professional appearance
✅ Backup power source (charged MacBook sufficient)
```

### **Recording Software Setup**
```
✅ Screen Recording: 
   - ScreenFlow 11 (recommended) OR
   - OBS Studio (free alternative) OR
   - QuickTime Player (basic)

✅ Audio Recording:
   - Audacity (free) OR
   - GarageBand (macOS built-in) OR  
   - Adobe Audition (professional)

✅ Video Editing:
   - DaVinci Resolve (free professional) OR
   - Final Cut Pro (macOS) OR
   - Adobe Premiere Pro

✅ System Utilities:
   - Stats (system monitoring overlay)
   - Cursorcerer (cursor highlighting)
   - KeyCastr (keystroke visualization)
```

### **Development Environment Setup**
```
✅ Terminal: iTerm2 with Oh My Zsh
✅ Text Editor: VS Code with optimized theme
✅ Browser: Chrome with clean profiles for demos
✅ File Manager: Organized folder structure
✅ Development Tools: Xcode Command Line Tools installed
```

## **🖥️ Demo Environment Configuration**

### **Step 1: Clean System Preparation**

**Terminal Setup:**
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install essential development tools
brew install git
brew install node
brew install python

# Install screen recording utilities
brew install stats
brew install keycastr

# Verify installations
brew list --versions
```

**VS Code Configuration:**
```json
{
  "editor.fontSize": 16,
  "editor.fontFamily": "SF Mono, Monaco, 'Cascadia Code', 'Roboto Mono', monospace",
  "editor.lineHeight": 1.6,
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.wordWrap": "on",
  "editor.minimap.enabled": false,
  "editor.gotoLocation.multipleReferences": "goto",
  "editor.formatOnSave": true,
  "editor.renderWhitespace": "boundary",
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": true,
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.shell.osxLocation": "/bin/zsh"
}
```

### **Step 2: Local AI Setup Verification**

**Ollama Installation Test:**
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Verify installation
ollama --version

# Test model download (Dolphin-7B for demo)
ollama pull dolphin-2.6-mistral-7b
ollama list

# Test model performance
time ollama run dolphin-2.6-mistral-7b "Write a simple React component"
```

**Continue.dev Extension Setup:**
```bash
# Install VS Code extension
code --install-extension continue.continue

# Verify extension activation
# Check VS Code extensions panel
```

### **Step 3: Recording Environment Optimization**

**Screen Recording Settings:**
```bash
# ScreenFlow recommended settings:
Resolution: 1920x1080
Frame Rate: 60fps
Audio: 48kHz, 16-bit
Format: ProRes 422 (editing) / H.264 (delivery)
Bitrate: 8-12 Mbps

# OBS Studio settings:
Base Resolution: 1920x1080
Output Resolution: 1920x1080  
Frame Rate: 60fps
Encoder: x264 (CPU) or Apple VT H264 (Metal)
CRF: 18-23 (quality)
```

**Audio Setup Test:**
```bash
# Test microphone levels
# Target: -12dB to -6dB peak levels
# Background noise: < -40dB

# Verify audio interface (if used)
# Test both internal mic and external mic
```

## **🔧 Demo Script Preparation**

### **Terminal Environment Setup**

**Custom ZSH Prompt:**
```bash
# Add to ~/.zshrc
PROMPT='%B%F{magenta}local-ai-demo%f%b %1~ % %# '
RPROMPT='%T %B%F{yellow}%m%f%b'

# Enable syntax highlighting
brew install zsh-syntax-highlighting
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Add useful aliases
alias ll='ls -la'
alias gs='git status'
alias gl='git log --oneline -10'
```

**Performance Monitoring:**
```bash
# Add to ~/.zshrc for real-time metrics
function prompt_right() {
    local cpu=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    local gpu=$(system_profiler SPDisplaysDataType | grep "Chipset Model" -A 1 | tail -1 | awk '{print $4}')
    local battery=$(pmset -g batt | grep -E '[0-9]+%' | cut -d';' -f1 | sed 's/.*\([0-9]\+\)%.*/\1/')
    echo "CPU:${cpu%.*}% GPU:${battery}%"
}
```

### **VS Code Workspace Preparation**

**Demo Project Structure:**
```
📁 demo-project/
  📁 README.md
  📁 package.json
  📁 tsconfig.json
  📁 src/
    📁 components/
      📄 DataVisualization.tsx
      📄 Dashboard.tsx
    📁 utils/
      📄 calculations.ts
      📄 helpers.ts
    📁 styles/
      📄 components.css
  📁 public/
    📄 index.html
```

**Pre-written Code Snippets:**
```typescript
// Create sophisticated data visualization component
import React, { useState, useEffect } from 'react';
import * as d3 from 'd3';

interface DataPoint {
  timestamp: Date;
  value: number;
  category: string;
}

interface VisualizationProps {
  data: DataPoint[];
  width?: number;
  height?: number;
}

const DataVisualization: React.FC<VisualizationProps> = ({ 
  data, 
  width = 800, 
  height = 400 
}) => {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  
  const filteredData = selectedCategory === 'all' 
    ? data 
    : data.filter(d => d.category === selectedCategory);
  
  useEffect(() => {
    // D3.js integration for real-time updates
    const svg = d3.select('#chart')
      .attr('width', width)
      .attr('height', height);
    
    // Rendering logic here
  }, [filteredData, width, height]);
  
  return (
    <div className="visualization-container">
      <h2>Real-time Data Visualization</h2>
      <select 
        value={selectedCategory}
        onChange={(e) => setSelectedCategory(e.target.value)}
      >
        <option value="all">All Categories</option>
        <option value="sales">Sales</option>
        <option value="users">Users</option>
      </select>
      <svg id="chart"></svg>
    </div>
  );
};

export default DataVisualization;
```

## **⚡ Performance Verification Tests**

### **Hardware Performance Benchmark**

**System Resources Check:**
```bash
# CPU performance test
sysctl -n machdep.cpu.brand_string

# Memory verification  
system_profiler SPHardwareDataType | grep Memory

# GPU verification
system_profiler SPDisplaysDataType | grep "Chipset Model"

# Storage performance
diskutil info / | grep "Total Size"

# Battery health
system_profiler SPPowerDataType | grep "Cycle Count"
```

**Model Loading Speed Test:**
```bash
# Test Dolphin-7B loading
time ollama run dolphin-2.6-mistral-7b "Hello, world"

# Expected: < 15 seconds loading time
# Target: < 5 seconds response time for simple queries
```

### **Recording Quality Verification**

**Audio Quality Test:**
```bash
# Record 30-second test clip
# Test for:
# - Clear speech without clipping
# - Minimal background noise
# - Consistent volume levels
# - No audio dropouts
```

**Video Quality Test:**
```bash
# Record 60-second screen test
# Check for:
# - Smooth 60fps performance
# - Clear text readability
# - Proper color accuracy
# - No frame drops during typing
```

## **📊 Demo Environment Metrics**

### **Target Performance Benchmarks**
```
🎯 MacBook Pro M3 Max:
  - Model loading: < 10 seconds
  - Simple queries: < 5 seconds
  - Complex code generation: 25-35 seconds
  - Screen recording: 60fps constant
  - Audio quality: -12dB to -6dB peaks

🎯 MacBook Pro M2 Pro:
  - Model loading: < 15 seconds
  - Simple queries: < 8 seconds  
  - Complex code generation: 35-50 seconds
  - Screen recording: 60fps constant
  - Audio quality: -12dB to -6dB peaks

🎯 MacBook Pro M1:
  - Model loading: < 20 seconds
  - Simple queries: < 12 seconds
  - Complex code generation: 60-90 seconds
  - Screen recording: 60fps constant (may need optimization)
  - Audio quality: -12dB to -6dB peaks
```

### **Pre-Recording Checklist**
```
✅ Hardware Tests:
  [ ] MacBook performance verified
  [ ] External monitor connected and calibrated
  [ ] Microphone levels tested and optimized
  [ ] Camera (if recording yourself) positioned
  [ ] Lighting setup arranged

✅ Software Tests:
  [ ] Screen recording software configured
  [ ] Audio recording levels optimized
  [ ] VS Code theme and extensions ready
  [ ] Terminal environment customized
  [ ] Demo project files prepared

✅ AI Environment Tests:
  [ ] Ollama installation verified
  [ ] Dolphin model downloaded and tested
  [ ] Continue.dev extension working
  [ ] Response times within target ranges
  [ ] Performance monitoring tools active

✅ Backup Plans:
  [ ] Alternative recording software ready
  [ ] Backup microphone available
  [ ] Demo video recording plan B prepared
  [ ] Troubleshooting guide accessible
```

## **🎬 Recording Day Checklist**

### **Morning Setup (30 minutes)**
```
⏰ Equipment Check:
  [ ] MacBook charged and connected to power
  [ ] External monitor calibrated and positioned
  [ ] Microphone connected and levels tested
  [ ] Lighting adjusted for optimal visibility
  [ ] Recording software launched and configured

⏰ Environment Setup:
  [ ] Desktop cleaned and organized
  [ ] Browser tabs prepared (GitHub, pricing pages)
  [ ] Terminal window arranged with custom prompt
  [ ] VS Code workspace ready with demo project
  [ ] Performance monitoring overlay activated

⏰ AI Environment Test:
  [ ] Ollama running in background
  [ ] Dolphin model pre-loaded
  [ ] Continue.dev extension active in VS Code
  [ ] Test query response time within target range
  [ ] All integrations working smoothly
```

### **Recording Session (2-3 hours)**
```
⏰ Session 1 - 3-Minute Demo (30 minutes):
  [ ] Multiple takes of 3-minute demo
  [ ] Test different pacing and emphasis
  [ ] Capture various demo scenarios
  [ ] Backup footage and B-roll

⏰ Session 2 - 5-Minute Extended Demo (45 minutes):
  [ ] Extended demo with deeper technical details
  [ ] Hardware optimization showcase
  [ ] Team deployment demonstration
  [ ] Enterprise features walkthrough

⏰ Session 3 - 30-Second Teaser (15 minutes):
  [ ] Quick overview for social media
  [ ] Hook-focused version
  [ ] Multiple angles and styles

⏰ Session 4 - Additional Content (30 minutes):
  [ ] Q&A preparation clips
  [ ] Performance comparison footage
  [ ] Setup process documentation
  [ ] Error handling examples
```

### **Quality Assurance**
```
✅ Technical Review:
  [ ] Audio levels consistent across all clips
  [ ] Video quality meets platform requirements
  [ ] Response times visible and impressive
  [ ] Code generation quality demonstrates value
  [ ] Performance metrics displayed clearly

✅ Content Review:
  [ ] Key messages delivered effectively
  [ ] Call-to-action clear and compelling
  [ ] Technical details accurate and helpful
  [ ] Demo flow logical and engaging
  [ ] Backup footage available if needed
```

## **🚨 Troubleshooting Guide**

### **Common Issues & Solutions**

**Audio Problems:**
```
Issue: Microphone levels too low/high
Solution: 
  - Adjust input gain on interface/microphone
  - Check system preferences → Sound → Input
  - Use gain staging: -12dB to -6dB peak levels

Issue: Background noise picked up
Solution:
  - Move to quieter environment
  - Use noise gate in recording software
  - Position microphone closer to speaker
  - Enable noise reduction in post-production
```

**Video Problems:**
```
Issue: Frame drops during recording
Solution:
  - Close unnecessary applications
  - Reduce recording resolution if needed
  - Check available storage space
  - Restart recording software

Issue: Text hard to read during screen recording
Solution:
  - Increase font sizes in terminal/VS Code
  - Use high contrast themes
  - Zoom in on specific areas when needed
  - Add text callouts and overlays
```

**AI Performance Issues:**
```
Issue: Model responses too slow for demo
Solution:
  - Use smaller model (Dolphin-7B vs Dolphin-34B)
  - Pre-load model before recording
  - Prepare responses and use for backup
  - Adjust demo script to account for timing

Issue: AI integration not working smoothly
Solution:
  - Restart Continue.dev extension
  - Check VS Code settings and configuration
  - Verify Ollama service is running
  - Test with different model or prompt
```

## **📱 Platform-Specific Requirements**

### **HackerNews/Reddit**
```
Requirements:
  - Max file size: 100MB
  - Supported formats: MP4, WebM
  - Resolution: 1280x720 minimum
  - Duration: Under 3 minutes recommended

Optimization:
  - Compress using HandBrake or similar
  - Target bitrate: 2-4 Mbps
  - Use H.264 codec for compatibility
  - Include subtitles for accessibility
```

### **YouTube**
```
Requirements:
  - Resolution: 1920x1080 minimum
  - Frame rate: 60fps preferred
  - Max file size: 256GB (but keep smaller)
  - Duration: No specific limit

Optimization:
  - Upload in highest quality available
  - Use descriptive title and tags
  - Include chapters/timestamps
  - Create custom thumbnail
```

### **Social Media**
```
Twitter/LinkedIn:
  - Duration: 30-60 seconds
  - Resolution: 1280x720
  - File size: Under 50MB
  - Format: MP4, H.264

Instagram:
  - Duration: 60 seconds max
  - Square format: 1080x1080
  - Vertical format: 1080x1920
  - Story format: 1080x1920
```

**Equipment setup complete! Ready to start recording! 🎬**