#!/bin/bash

# Cloud Deployment Script for Local AI Coding Setup
# Deploys to Vercel/Netlify with cloud AI services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}☁️ Cloud Deployment for Local AI Coding Setup${NC}"
echo "================================================"

# Check if Vercel CLI is installed
if ! command -v vercel >/dev/null 2>&1; then
    echo "Installing Vercel CLI..."
    npm install -g vercel
fi

# Check if Netlify CLI is installed
if ! command -v netlify >/dev/null 2>&1; then
    echo "Installing Netlify CLI..."
    npm install -g netlify-cli
fi

# Create cloud configuration
echo ""
echo "🔧 Creating cloud configuration..."

# Create vercel.json for Vercel deployment
cat > vercel.json << 'EOF'
{
  "version": 2,
  "builds": [
    {
      "src": "api/index.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/api/(.*)",
      "dest": "/api/index.js"
    },
    {
      "src": "/(.*)",
      "dest": "/frontend/$1"
    }
  ],
  "env": {
    "OPENAI_API_KEY": "@openai-api-key"
  }
}
EOF

# Create netlify.toml for Netlify deployment
cat > netlify.toml << 'EOF'
[build]
  publish = "frontend/"
  functions = "api/"

[build.environment]
  NODE_VERSION = "18"

[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200

[functions]
  directory = "api/"
EOF

# Create cloud API endpoint
mkdir -p api
cat > api/index.js << 'EOF'
const OpenAI = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

module.exports = async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { messages, model = 'gpt-4-turbo-preview', temperature = 0.7 } = req.body;

    const completion = await openai.chat.completions.create({
      model: model,
      messages: messages,
      temperature: temperature,
      max_tokens: 2048,
    });

    res.status(200).json({
      response: completion.choices[0].message.content,
      usage: completion.usage
    });
  } catch (error) {
    console.error('OpenAI API error:', error);
    res.status(500).json({
      error: 'AI service error',
      details: error.message
    });
  }
};
EOF

# Create package.json for cloud functions
cat > package.json << 'EOF'
{
  "name": "local-ai-coding-cloud",
  "version": "1.0.0",
  "description": "Cloud deployment of Local AI Coding Setup",
  "main": "api/index.js",
  "scripts": {
    "dev": "vercel dev",
    "build": "echo 'No build step required'",
    "start": "vercel dev"
  },
  "dependencies": {
    "openai": "^4.0.0"
  },
  "devDependencies": {
    "vercel": "^32.0.0"
  }
}
EOF

# Update frontend for cloud API
mkdir -p frontend
cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Local AI Coding - Cloud</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 30px;
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
        }
        .chat-container {
            margin-top: 20px;
        }
        .message {
            margin: 10px 0;
            padding: 15px;
            border-radius: 10px;
            max-width: 70%;
        }
        .user-message {
            background: rgba(255, 255, 255, 0.2);
            margin-left: auto;
            text-align: right;
        }
        .ai-message {
            background: rgba(255, 255, 255, 0.1);
        }
        textarea {
            width: 100%;
            padding: 15px;
            border: none;
            border-radius: 10px;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            font-size: 16px;
            resize: vertical;
            min-height: 60px;
        }
        textarea::placeholder {
            color: rgba(255, 255, 255, 0.7);
        }
        button {
            background: linear-gradient(45deg, #FF6B6B, #4ECDC4);
            border: none;
            color: white;
            padding: 15px 30px;
            border-radius: 10px;
            cursor: pointer;
            font-size: 16px;
            margin-top: 10px;
            transition: transform 0.2s;
        }
        button:hover {
            transform: translateY(-2px);
        }
        .status {
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
            text-align: center;
        }
        .status.online {
            background: rgba(76, 175, 80, 0.3);
        }
        .status.offline {
            background: rgba(244, 67, 54, 0.3);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 Local AI Coding - Cloud Edition</h1>
        <p>AI-powered coding assistant running in the cloud. No local setup required!</p>

        <div id="status" class="status offline">
            🔄 Connecting to AI service...
        </div>

        <div class="chat-container" id="chat-container">
            <div class="message ai-message">
                👋 Hi! I'm your cloud-based AI coding assistant. Ask me anything about programming, algorithms, debugging, or code optimization!
            </div>
        </div>

        <textarea
            id="message-input"
            placeholder="Ask me about code, algorithms, debugging, or any programming question..."
            rows="3"
        ></textarea>
        <button onclick="sendMessage()">🚀 Send Message</button>
    </div>

    <script>
        const API_BASE = window.location.origin;
        let isOnline = false;

        async function checkStatus() {
            try {
                const response = await fetch(`${API_BASE}/api/health`, {
                    method: 'GET'
                });

                if (response.ok) {
                    document.getElementById('status').className = 'status online';
                    document.getElementById('status').innerHTML = '✅ AI service online - ready to chat!';
                    isOnline = true;
                } else {
                    throw new Error('Service not responding');
                }
            } catch (error) {
                document.getElementById('status').className = 'status offline';
                document.getElementById('status').innerHTML = '❌ AI service offline - check deployment';
                isOnline = false;
            }
        }

        async function sendMessage() {
            const input = document.getElementById('message-input');
            const message = input.value.trim();

            if (!message) return;
            if (!isOnline) {
                alert('AI service is not available. Please check the deployment.');
                return;
            }

            // Add user message
            addMessage(message, 'user-message');
            input.value = '';

            // Show typing indicator
            const typingDiv = document.createElement('div');
            typingDiv.className = 'message ai-message';
            typingDiv.innerHTML = '🤔 Thinking...';
            document.getElementById('chat-container').appendChild(typingDiv);

            try {
                const response = await fetch(`${API_BASE}/api/chat`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        messages: [
                            {
                                role: 'system',
                                content: 'You are an expert coding assistant. Provide clear, accurate, and helpful responses about programming, algorithms, debugging, and software development. Include code examples when relevant.'
                            },
                            {
                                role: 'user',
                                content: message
                            }
                        ],
                        temperature: 0.7
                    })
                });

                // Remove typing indicator
                document.getElementById('chat-container').removeChild(typingDiv);

                if (response.ok) {
                    const data = await response.json();
                    addMessage(data.response, 'ai-message');
                } else {
                    const error = await response.json();
                    addMessage(`❌ Error: ${error.error}`, 'ai-message');
                }
            } catch (error) {
                // Remove typing indicator
                document.getElementById('chat-container').removeChild(typingDiv);
                addMessage(`❌ Network error: ${error.message}`, 'ai-message');
            }
        }

        function addMessage(text, className) {
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${className}`;
            messageDiv.innerHTML = text.replace(/\n/g, '<br>');
            document.getElementById('chat-container').appendChild(messageDiv);
            messageDiv.scrollIntoView({ behavior: 'smooth' });
        }

        // Enter key to send
        document.getElementById('message-input').addEventListener('keypress', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        // Check status on load
        window.onload = checkStatus;
    </script>
</body>
</html>
EOF

# Create environment file template
cat > .env.example << 'EOF'
# Cloud Deployment Environment Variables
OPENAI_API_KEY=your_openai_api_key_here

# Optional: Other AI providers
# ANTHROPIC_API_KEY=your_anthropic_key_here
# GROQ_API_KEY=your_groq_key_here
EOF

echo ""
echo -e "${GREEN}✅ Cloud configuration created!${NC}"
echo ""
echo "📦 Deployment Options:"
echo ""

# Vercel deployment
echo "🚀 Deploy to Vercel:"
echo "   vercel --prod"
echo ""

# Netlify deployment
echo "☁️ Deploy to Netlify:"
echo "   netlify deploy --prod"
echo ""

# Manual deployment
echo "🔧 Manual deployment:"
echo "   1. Set OPENAI_API_KEY in your cloud platform"
echo "   2. Deploy the 'api/' and 'frontend/' directories"
echo "   3. Configure API routes to point to your functions"
echo ""

echo "💡 Key Differences from Local Setup:"
echo "   • No local AI model downloads required"
echo "   • Always available (no startup time)"
echo "   • Scales automatically"
echo "   • Pay-per-use pricing"
echo "   • Works on any device with browser"
echo ""

echo "🎯 Result: Your AI coding assistant runs 24/7 in the cloud!"
echo "   Just open the URL - no commands needed! 🌐🤖"