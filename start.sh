#!/bin/bash
# Start the FORGE gateway
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 22 2>/dev/null

# Load AWS Bedrock credentials (written by setup.sh)
if [ -f "$HOME/.aws-bedrock-creds" ]; then
    source "$HOME/.aws-bedrock-creds"
else
    echo "⚠️  AWS credentials not found at ~/.aws-bedrock-creds"
    echo "   Run ./setup.sh again or set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION manually."
fi

echo "🦞 Starting FORGE gateway..."
openclaw gateway
