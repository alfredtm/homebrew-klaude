class Klaude < Formula
  desc "Claude Code in Docker - YOLO mode containerized AI coding assistant"
  homepage "https://github.com/alfredtm/klaude"
  version "1.0.0"
  
  # Using Google's robots.txt as a stable dummy URL since Homebrew requires one, but we embed all code in this formula
  url "https://www.google.com/robots.txt"
  sha256 "08b39f388199b56f32a048424ae0055f8ad0b86f1cd8d1de2c171bb02e880403"
  
  depends_on "docker"

  def install
    # Create the main klaude script
    (bin/"klaude").write <<~EOS
      #!/bin/bash
      
      # Colors
      G='\\033[0;32m'
      Y='\\033[1;33m'
      B='\\033[0;34m'
      R='\\033[0;31m'
      N='\\033[0m'
      
      # Check if Docker is running
      if ! docker info >/dev/null 2>&1; then
          echo -e "${R}❌ Docker is not running. Please start Docker Desktop first.${N}"
          exit 1
      fi
      
      # Check if klaude image exists locally
      IMAGE_NAME="ghcr.io/alfredtm/klaude:latest"
      LOCAL_IMAGE="klaude-image"
      
      # Try to pull the latest image from GHCR
      echo -e "${Y}📦 Pulling latest Klaude image from GitHub Container Registry...${N}"
      if docker pull "$IMAGE_NAME" 2>/dev/null; then
          echo -e "${G}✅ Successfully pulled latest image${N}"
          # Tag it locally for consistency
          docker tag "$IMAGE_NAME" "$LOCAL_IMAGE" 2>/dev/null
      else
          echo -e "${Y}⚠️  Could not pull from GHCR, checking for local image...${N}"
          if ! docker images | grep -q "$LOCAL_IMAGE"; then
              echo -e "${R}❌ No local image found. Please check your internet connection or build locally.${N}"
              echo -e "${Y}To build locally, run: docker build -t $LOCAL_IMAGE https://github.com/alfredtm/klaude.git${N}"
              exit 1
          fi
          echo -e "${B}ℹ️  Using existing local image${N}"
      fi
      
      # Determine workspace
      if [ -n "$1" ]; then
          WORKSPACE="$1"
      elif git rev-parse --show-toplevel &>/dev/null 2>&1; then
          WORKSPACE=$(git rev-parse --show-toplevel)
      else
          WORKSPACE=$(pwd)
      fi
      
      PROJECT_NAME=$(basename "$WORKSPACE")
      
      # Show what we're doing
      echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
      echo -e "${B}🚀 Klaude YOLO Mode (Containerized)${N}"
      echo -e "${Y}📁 Project:${N} $WORKSPACE"
      echo -e "${G}🔧 Container:${N} Fresh (nukeable)"
      echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${N}"
      
      # Check for previous session
      if [ -f "$WORKSPACE/.klaude-session" ]; then
          echo -e "${Y}📚 Previous session: $(cat $WORKSPACE/.klaude-session)${N}"
      fi
      
      # Mark new session
      echo "$(date '+%Y-%m-%d %H:%M')" > "$WORKSPACE/.klaude-session"
      
      echo -e "${G}Starting container...${N}"
      echo ""
      
      # Run Claude with persistent auth as non-root user for YOLO mode
      USER_ID=$(id -u)
      GROUP_ID=$(id -g)
      
      # Check for Claude auth in macOS location first, then fallback to Linux location
      CLAUDE_AUTH_DIR_MACOS="$HOME/Library/Application Support/Claude"
      CLAUDE_AUTH_DIR_LINUX="$HOME/.config/claude"
      
      if [ -d "$CLAUDE_AUTH_DIR_MACOS" ] && [ "$(ls -A "$CLAUDE_AUTH_DIR_MACOS" 2>/dev/null)" ]; then
          echo -e "${G}🔑 Found local Claude auth (macOS), mounting to container${N}"
          CLAUDE_AUTH_SOURCE="$CLAUDE_AUTH_DIR_MACOS"
          HAS_AUTH=true
      elif [ -d "$CLAUDE_AUTH_DIR_LINUX" ] && [ "$(ls -A "$CLAUDE_AUTH_DIR_LINUX" 2>/dev/null)" ]; then
          echo -e "${G}🔑 Found local Claude auth (Linux), mounting to container${N}"
          CLAUDE_AUTH_SOURCE="$CLAUDE_AUTH_DIR_LINUX"
          HAS_AUTH=true
      else
          echo -e "${Y}⚠️  No local Claude auth found, will need to login in container${N}"
          HAS_AUTH=false
      fi
      
      # Run container as root initially to set up, then drop privileges for claude
      if [ "$HAS_AUTH" = true ]; then
          docker run -it --rm \\
              --name "klaude-${PROJECT_NAME//[^a-zA-Z0-9]/-}-$$" \\
              --hostname "klaude" \\
              --privileged \\
              -v "$WORKSPACE":/workspace \\
              -v "$CLAUDE_AUTH_SOURCE":/home/claude/.config/claude \\
              -w /workspace \\
              -e PATH=/usr/local/bin:/usr/bin:/bin \\
              -e CLAUDE_CONFIG_DIR=/home/claude/.config/claude \\
              -e HOME=/home/claude \\
              -e USER=claude \\
              klaude-image \\
              bash -c \"
                  # Give claude user access to the workspace
                  chown -R claude:claude /workspace
                  
                  echo '🔑 Using host Claude authentication with persistence'
                  
                  # Set up proper environment for Claude
                  export HOME=/home/claude
                  export USER=claude
                  export CLAUDE_CONFIG_DIR=/home/claude/.config/claude
                  
                  # Ensure proper directory structure and ownership
                  mkdir -p /home/claude/.config
                  chown -R claude:claude /home/claude/.config
                  chown -R claude:claude /home/claude/.config/claude 2>/dev/null || true
                  chmod 755 /home/claude/.config/claude
                  
                  # Ensure Claude can write to config files for session persistence
                  find /home/claude/.config/claude -type f -exec chmod 644 {} \; 2>/dev/null || true
                  
                  echo '✅ Container ready! Starting Claude Code in YOLO mode...'
                  echo '    (Using --dangerously-skip-permissions safely in container)'
                  echo ''
                  
                  # Run as the existing claude user
                  exec su claude -c 'cd /workspace && claude --dangerously-skip-permissions'
              \"
      else
          docker run -it --rm \\
              --name "klaude-${PROJECT_NAME//[^a-zA-Z0-9]/-}-$$" \\
              --hostname "klaude" \\
              --privileged \\
              -v "$WORKSPACE":/workspace \\
              -w /workspace \\
              -e PATH=/usr/local/bin:/usr/bin:/bin \\
              -e CLAUDE_CONFIG_DIR=/home/claude/.config/claude \\
              klaude-image \\
              bash -c \"
                  # Give claude user access to the workspace
                  chown -R claude:claude /workspace
                  
                  echo '🔑 No auth mounted, will need to login'
                  
                  echo '✅ Container ready! Starting Claude Code in YOLO mode...'
                  echo '    (Using --dangerously-skip-permissions safely in container)'
                  echo ''
                  
                  # Run as the existing claude user
                  exec su claude -c 'cd /workspace && claude --dangerously-skip-permissions'
              \"
      fi
      
      echo -e "${G}✨ Session ended. Project intact at: $WORKSPACE${N}"
    EOS
    
    # Create helper scripts
    (bin/"klaude-update").write <<~EOS
      #!/bin/bash
      echo "🔄 Updating Klaude Docker image..."
      docker rmi klaude-image 2>/dev/null
      docker pull ghcr.io/alfredtm/klaude:latest || {
          echo "❌ Failed to pull latest image from GHCR"
          exit 1
      }
      docker tag ghcr.io/alfredtm/klaude:latest klaude-image
      echo "✅ Updated to latest Klaude image!"
    EOS
    
    (bin/"klaude-nuke").write <<~EOS
      #!/bin/bash
      echo "☢️  Nuking all Klaude containers and images..."
      docker rm -f $(docker ps -aq --filter name=klaude) 2>/dev/null
      docker rmi klaude-image 2>/dev/null
      echo "✨ All Klaude containers and images cleared!"
    EOS
    
    # Make all scripts executable
    bin.children.each { |f| f.chmod 0755 }
  end
  
  def caveats
    <<~EOS
      #{Formatter.headline("Getting Started with Klaude")}
      
      Klaude has been installed! Here's how to use it:
      
      #{Formatter.headline("Commands:")}
        klaude              - Start Klaude in current directory
        klaude [path]       - Start Klaude in specific directory
        klaude-update       - Update to latest Claude Code version
        klaude-nuke         - Remove all Klaude containers and images
      
      #{Formatter.headline("First Run:")}
      1. Make sure Docker Desktop is running
      2. Run 'klaude' in any project directory
      3. Image will be automatically pulled from GitHub Container Registry
      4. Login with your Claude Pro/Max subscription when prompted (required each session)
      
      #{Formatter.headline("Important:")}
      ⚠️  Klaude runs in YOLO mode - Claude has full access to the mounted directory!
      ⚠️  Changes are made to your ACTUAL files (not copies)
      
      Enjoy coding with Claude! 🚀
    EOS
  end
  
  test do
    assert_match "Klaude YOLO Mode", shell_output("#{bin}/klaude --help 2>&1", 1)
  end
end