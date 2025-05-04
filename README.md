# Untitled Folder

A macOS application for intelligently renaming untitled files and folders based on their content and metadata.

## Project Structure

The project is organized into 7 main phases:

1. `phase1/` - Core File Processing
   - FileScanner
   - FilenameAnalyzer

2. `phase2/` - Renaming & Safety
   - RenameExecutor
   - Dry-Run Mode

3. `phase3/` - LLM / Model Integration
   - LLMIntegration
   - LocalModelFallback

4. `phase4/` - User Interface
   - CLI Component
   - macOS App (SwiftUI)

5. `phase5/` - Subscription & Billing
   - SubscriptionManager
   - Server-Side Billing API

6. `phase6/` - Distribution & Marketing
   - Apple App Store Packaging
   - Website & Landing Page

7. `phase7/` - Logging, Analytics & CI/CD
   - LoggingAnalytics
   - CI/CD Pipeline

## Getting Started

1. Clone the repository
2. Follow the setup instructions in each phase's README.md
3. Run the test suite: `swift test`

## Requirements

- macOS 13+
- Swift 5.7+
- Python 3.10+
- Xcode 14+

## License

MIT License 