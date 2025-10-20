.PHONY: build clean run install

# Build configuration
SCHEME = ChatInsights
CONFIGURATION = Debug
BUILD_DIR = .build

build:
	swift build

release:
	swift build -c release

clean:
	swift package clean
	rm -rf $(BUILD_DIR)
	rm -rf DerivedData

run: build
	swift run

install: release
	cp -r $(BUILD_DIR)/release/ChatInsights.app /Applications/

test:
	swift test

xcode:
	swift package generate-xcodeproj
	open ChatInsights.xcodeproj

format:
	swift-format format -i -r Sources/

help:
	@echo "ChatInsights Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build    - Build debug version"
	@echo "  release  - Build release version"
	@echo "  clean    - Clean build artifacts"
	@echo "  run      - Build and run the app"
	@echo "  install  - Install to /Applications"
	@echo "  xcode    - Generate and open Xcode project"
	@echo "  help     - Show this message"

