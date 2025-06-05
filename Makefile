.PHONY: build test clean run release lint install-hooks security verify-deps

# Default target
all: build

# Build the project
build:
	swift build

# Build for release
release:
	swift build -c release
	./build.sh

# Run tests
test:
	swift test

# Clean build artifacts
clean:
	rm -rf .build
	rm -rf ClipboardHistory.app
	rm -f ClipboardHistory.dmg
	rm -f ClipboardHistory.zip

# Run the app (debug build)
run: build
	./.build/debug/ClipboardHistory

# Lint the code
lint:
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
	else \
		echo "SwiftLint not installed. Install with: brew install swiftlint"; \
	fi

# Format code
format:
	@if command -v swift-format >/dev/null 2>&1; then \
		swift-format -i -r Sources/ Tests/; \
	else \
		echo "swift-format not installed. Install with: brew install swift-format"; \
	fi

# Install git hooks
install-hooks:
	@echo "#!/bin/sh" > .git/hooks/pre-commit
	@echo "make security" >> .git/hooks/pre-commit
	@echo "make lint" >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "Git hooks installed (includes security checks)"

# Verify dependencies
verify-deps:
	@chmod +x scripts/verify-dependencies.sh
	@scripts/verify-dependencies.sh

# Run security checks
security: verify-deps
	@echo "Running security checks..."
	@if command -v gitleaks >/dev/null 2>&1; then \
		gitleaks detect --config .gitleaks.toml --source . -v; \
	else \
		echo "⚠️  Gitleaks not installed. Install with: brew install gitleaks"; \
	fi
	@echo "✅ Security checks completed"

# Create a DMG for distribution
dmg: release
	@mkdir -p dist
	@cp -R ClipboardHistory.app dist/
	@hdiutil create -volname "Clipboard History" -srcfolder dist -ov -format UDZO ClipboardHistory.dmg
	@rm -rf dist
	@echo "Created ClipboardHistory.dmg"

# Help target
help:
	@echo "Available targets:"
	@echo "  make build         - Build the project (debug)"
	@echo "  make release       - Build for release and create app bundle"
	@echo "  make test          - Run tests"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make run           - Build and run (debug)"
	@echo "  make lint          - Run SwiftLint"
	@echo "  make format        - Format code with swift-format"
	@echo "  make security      - Run security checks (deps + secrets)"
	@echo "  make verify-deps   - Verify dependency checksums"
	@echo "  make install-hooks - Install git pre-commit hooks"
	@echo "  make dmg           - Create DMG for distribution"
	@echo "  make help          - Show this help message"