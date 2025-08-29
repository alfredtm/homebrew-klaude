# Homebrew Klaude Tap

🍺 Official Homebrew tap for [Klaude](https://github.com/alfredtm/klaude) - Claude Code in Docker YOLO mode.

## Installation

```bash
brew tap alfredtm/klaude
brew install klaude
```

## What is Klaude?

Klaude is a containerized AI coding assistant that runs Claude Code in Docker with full access to your project files. Perfect for when you want Claude to have complete control over your codebase without worrying about system dependencies.

## Commands

- `klaude` - Start Klaude in current directory
- `klaude [path]` - Start Klaude in specific directory  
- `klaude-update` - Update to latest Claude Code version
- `klaude-nuke` - Remove all Klaude data and containers
- `klaude-auth-reset` - Clear saved authentication

## Requirements

- Docker Desktop must be running
- Claude Pro/Max subscription for authentication

## ⚠️ Important

Klaude runs in YOLO mode - Claude has **full access** to the mounted directory! Changes are made to your **ACTUAL files** (not copies).

## Links

- 🐙 [Main Repository](https://github.com/alfredtm/klaude)
- 📖 [Documentation](https://alfredtm.github.io/homebrew-klaude/)
- 🚀 [Docker Images](https://github.com/alfredtm/klaude/pkgs/container/klaude)

---

*Enjoy coding with Claude!* 🚀