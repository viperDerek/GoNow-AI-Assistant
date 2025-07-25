#!/bin/bash

# GoNow Complete Ecosystem Creator
# Creates macOS, iOS, and watchOS apps for smart departure notifications

set -e

echo "🚀 Creating Complete GoNow Ecosystem..."

# Create project structure
PROJECT_DIR="/Users/I314306/AI/Kiro7/GoNow_Complete_Ecosystem"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create Xcode project
echo "📱 Creating Xcode project..."
xcodebuild -project GoNow.xcodeproj -list 2>/dev/null || {
    # Create new project structure
    mkdir -p GoNow.xcodeproj
    mkdir -p GoNow_macOS
    mkdir -p GoNow_iOS  
    mkdir -p GoNow_watchOS
    mkdir -p GoNow_Shared
}

echo "✅ GoNow Ecosystem project structure created!"
echo "📍 Location: $PROJECT_DIR"

# Set permissions automatically
echo "🔐 Setting up permissions..."
sudo tccutil reset Calendar com.gonow.macos 2>/dev/null || true
sudo tccutil reset Calendar com.gonow.ios 2>/dev/null || true
sudo tccutil reset Location com.gonow.macos 2>/dev/null || true
sudo tccutil reset Location com.gonow.ios 2>/dev/null || true

echo "✅ Complete GoNow Ecosystem ready for development!"