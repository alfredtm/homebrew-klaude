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
      
      # Create persistent auth directory with proper permissions
      CLAUDE_AUTH_DIR="$HOME/.klaude-claude-auth"
      mkdir -p "$CLAUDE_AUTH_DIR"
      # Ensure the directory exists and has correct permissions for the user
      chmod 777 "$CLAUDE_AUTH_DIR" 2>/dev/null || true
      
      echo -e "${G}Starting container...${N}"
      echo ""
      
      # Run Claude with persistent auth as non-root user for YOLO mode
      USER_ID=$(id -u)
      GROUP_ID=$(id -g)
      
      # Run container as root initially to set up, then drop privileges for claude
      docker run -it --rm \\
          --name "klaude-${PROJECT_NAME//[^a-zA-Z0-9]/-}-$$" \\
          --hostname "klaude" \\
          --privileged \\
          -v "$WORKSPACE":/workspace \\
          -v "$CLAUDE_AUTH_DIR":/home/claude/.claude \\
          -w /workspace \\
          -e PATH=/usr/local/bin:/usr/bin:/bin \\
          klaude-image \\
          bash -c \"
              # The container already has a 'claude' user (UID 1000, GID 1000)
              # We need to adjust permissions for the mounted directories
              
              # Ensure the mount point exists and check for auth data
              mkdir -p /home/claude/.claude
              if [ -d /home/claude/.claude ] && [ "\$(ls -A /home/claude/.claude 2>/dev/null)" ]; then
                  echo '🔑 Found existing auth data'
              else
                  echo '🔑 No existing auth found, will need to login'
              fi
              
              # Fix permissions for the mounted auth directory
              # Use 777 to ensure both host and container can read/write
              chmod -R 777 /home/claude/.claude 2>/dev/null || true
              chown -R claude:claude /home/claude/.claude
              
              # Also ensure .config exists for any other configs
              mkdir -p /home/claude/.config
              chown claude:claude /home/claude/.config
              
              # Give claude user access to the workspace
              chown -R claude:claude /workspace
              
              echo '📝 Note: On first run, Claude will open a browser for login'
              echo '   Your auth will be saved for future sessions'
              echo ''
              echo '✅ Container ready! Starting Claude Code in YOLO mode...'
              echo '    (Using --dangerously-skip-permissions safely in container)'
              echo ''
              
              # Run as the existing claude user with proper HOME set
              exec su claude -c 'HOME=/home/claude && cd /workspace && claude --dangerously-skip-permissions'
          \"
      
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
      rm -rf ~/.klaude-claude-auth
      echo "✨ All Klaude data cleared!"
    EOS
    
    (bin/"klaude-auth-reset").write <<~EOS
      #!/bin/bash
      echo "🔑 Resetting Klaude authentication..."
      rm -rf ~/.klaude-claude-auth
      echo "✅ Auth cleared. Next run will require login."
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
        klaude-nuke         - Remove all Klaude data and containers
        klaude-auth-reset   - Clear saved authentication
      
      #{Formatter.headline("First Run:")}
      1. Make sure Docker Desktop is running
      2. Run 'klaude' in any project directory
      3. Image will be automatically pulled from GitHub Container Registry
      4. Login with your Claude Pro/Max subscription when prompted
      
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