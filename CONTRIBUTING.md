# Contributing to Clipboard History

Thank you for your interest in contributing to Clipboard History! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/ClipboardHistory.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Install git hooks: `make install-hooks`
5. Make your changes
6. Run tests: `make test`
7. Run linter: `make lint`
8. Commit your changes: `git commit -am 'Add some feature'`
9. Push to the branch: `git push origin feature/your-feature-name`
10. Submit a pull request

## Development Setup

### Prerequisites

- macOS 13.0 or later
- Xcode 14.0 or later
- Swift 5.9 or later

### Building

```bash
make build       # Debug build
make release     # Release build with app bundle
```

### Running Tests

```bash
make test
```

### Other Commands

```bash
make clean       # Clean build artifacts
make run         # Build and run debug version
make lint        # Run SwiftLint
make format      # Format code with swift-format
make dmg         # Create DMG for distribution
make help        # Show all available commands
```

## Code Style

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Write tests for new features

## Pull Request Process

1. Ensure all tests pass
2. Update the README.md with details of changes if needed
3. Update the tests to cover your changes
4. Make sure your code follows the existing style
5. Write a clear PR description explaining your changes

## Reporting Issues

- Use the GitHub issue tracker
- Check if the issue already exists
- Provide detailed steps to reproduce
- Include system information (macOS version, etc.)
- Attach screenshots if relevant

## Feature Requests

- Open an issue with the "enhancement" label
- Describe the feature and its use case
- Discuss before implementing major changes

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Assume good intentions

## Questions?

Feel free to open an issue for any questions about contributing!