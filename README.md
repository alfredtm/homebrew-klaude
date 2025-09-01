# Homebrew Klaude Tap

🍺 Official Homebrew tap for [Klaude](https://github.com/alfredtm/klaude) - Claude Code in Docker YOLO mode.

## Installation

```bash
brew tap alfredtm/klaude
brew install klaude
```

## What is Klaude?

Klaude runs Claude Code in Docker with full access to your project files. Safe containerized environment with persistent authentication.

## Quick Start

1. Make sure Docker Desktop is running
2. Run `klaude` in any project directory
3. Login with your Claude Pro/Max subscription (first run only)
4. Code with Claude using `--dangerously-skip-permissions` in safe container!

## Commands

- `klaude` - Start Klaude in current directory
- `klaude [path]` - Start Klaude in specific directory  
- `klaude-update` - Update to latest version
- `klaude-nuke` - Remove all containers and images

## Features

✅ **Persistent Authentication** - Login once, use forever  
✅ **Safe Isolation** - Your host system stays protected  
✅ **Auto Updates** - Always pulls latest Claude Code  
✅ **Easy Cleanup** - Disposable containers
✅ **1Password Integration** - Auto-inject GitHub tokens & kubectl configs

## 1Password Integration (Optional)

Auto-inject credentials into Klaude container:

1. Tag your 1Password items with `klaude`:
   - GitHub token (include "github" in title)
   - Kubectl config document (include "kube" in title)
2. Sign in: `op signin`
3. Run `klaude` - credentials auto-injected!

Disable with: `KLAUDE_NO_1PASSWORD=true klaude`

## ⚠️ Important

Klaude runs with `--dangerously-skip-permissions` - Claude has **full access** to the mounted directory! Changes are made to your **ACTUAL files** (not copies).

## Links

- 🐙 [Main Repository](https://github.com/alfredtm/klaude)
- 🚀 [Docker Images](https://github.com/alfredtm/klaude/pkgs/container/klaude)

---

*Enjoy coding with Claude!* 🚀