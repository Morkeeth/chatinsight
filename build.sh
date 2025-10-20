#!/bin/bash

# ChatInsights Build Script
# Builds both the main app and CLI server

set -e

echo "🔨 Building ChatInsights MCP Server..."
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build configuration
CONFIGURATION="${1:-release}"
BUILD_DIR=".build"

echo "${BLUE}Configuration: ${CONFIGURATION}${NC}"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
swift package clean
echo ""

# Resolve dependencies
echo "📦 Resolving dependencies..."
swift package resolve
echo ""

# Build the main app
echo "🏗️  Building ChatInsights app..."
swift build --product ChatInsights --configuration $CONFIGURATION
echo "${GREEN}✓ ChatInsights app built successfully${NC}"
echo ""

# Build the CLI server
echo "🏗️  Building chatinsights-server CLI..."
swift build --product chatinsights-server --configuration $CONFIGURATION
echo "${GREEN}✓ CLI server built successfully${NC}"
echo ""

# Show build artifacts
echo "📍 Build artifacts location:"
if [ "$CONFIGURATION" == "release" ]; then
    echo "   App: ${BUILD_DIR}/release/ChatInsights"
    echo "   CLI: ${BUILD_DIR}/release/chatinsights-server"
else
    echo "   App: ${BUILD_DIR}/debug/ChatInsights"
    echo "   CLI: ${BUILD_DIR}/debug/chatinsights-server"
fi
echo ""

# Create distributable package (optional)
if [ "$CONFIGURATION" == "release" ]; then
    echo "📦 Creating distributable package..."
    DIST_DIR="dist"
    mkdir -p "$DIST_DIR"
    
    # Copy CLI to dist
    cp "${BUILD_DIR}/release/chatinsights-server" "$DIST_DIR/"
    chmod +x "$DIST_DIR/chatinsights-server"
    
    echo "${GREEN}✓ Distribution package created in ${DIST_DIR}/${NC}"
    echo ""
fi

echo "${GREEN}✅ Build complete!${NC}"
echo ""
echo "To run:"
echo "  • App:    swift run ChatInsights"
echo "  • CLI:    swift run chatinsights-server"
echo ""
echo "To test MCP server:"
echo "  • npx @modelcontextprotocol/inspector ${BUILD_DIR}/${CONFIGURATION}/chatinsights-server"
echo ""
