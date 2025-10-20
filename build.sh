#!/bin/bash

# ChatInsights Build Script
set -e

echo "🚀 Building ChatInsights..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed"
    exit 1
fi

# Check Swift version
echo "📦 Swift version:"
swift --version

# Clean previous builds
echo "🧹 Cleaning previous builds..."
swift package clean

# Resolve dependencies
echo "📥 Resolving dependencies..."
swift package resolve

# Build the project
echo "🔨 Building..."
swift build -c release

echo "✅ Build complete!"
echo ""
echo "To run the app:"
echo "  swift run"
echo ""
echo "To install to /Applications:"
echo "  make install"

