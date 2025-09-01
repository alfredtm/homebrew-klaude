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
      
      # Check for 1Password CLI and fetch credentials
      OP_AVAILABLE=false
      GH_TOKEN=""
      KUBECONFIG_CONTENT=""
      
      # Allow disabling 1Password integration
      if [ "$KLAUDE_NO_1PASSWORD" = "true" ]; then
          echo -e "${Y}⚠️  1Password integration disabled (KLAUDE_NO_1PASSWORD=true)${N}"
      else
          if command -v op &>/dev/null; then
              # Check if signed in to 1Password
              if op account list &>/dev/null 2>&1; then
                  echo -e "${B}🔐 Checking for 1Password items tagged 'klaude'...${N}"
                  
                  # Get all items with 'klaude' tag
                  OP_ITEMS=$(op item list --tags klaude --format json 2>/dev/null || echo "[]")
                  
                  if [ "$OP_ITEMS" != "[]" ] && [ -n "$OP_ITEMS" ]; then
                      # Try to get GitHub token (look for item with 'github' in title/name)
                      for item_id in $(echo "$OP_ITEMS" | jq -r '.[] | select(.title | ascii_downcase | contains("github")) | .id' 2>/dev/null); do
                          GH_TOKEN=$(op item get "$item_id" --fields label=token,label=pat,label=personal_access_token --format json 2>/dev/null | jq -r '.[] | .value' 2>/dev/null | head -1)
                          if [ -n "$GH_TOKEN" ]; then
                              echo -e "${G}  ✓ Found GitHub token${N}"
                              break
                          fi
                      done
                      
                      # If no GitHub token found in fields, try to get it from password field
                      if [ -z "$GH_TOKEN" ]; then
                          for item_id in $(echo "$OP_ITEMS" | jq -r '.[] | select(.title | ascii_downcase | contains("github")) | .id' 2>/dev/null); do
                              GH_TOKEN=$(op item get "$item_id" --fields password --format json 2>/dev/null | jq -r '.value' 2>/dev/null)
                              if [ -n "$GH_TOKEN" ]; then
                                  echo -e "${G}  ✓ Found GitHub token${N}"
                                  break
                              fi
                          done
                      fi
                      
                      # Try to get kubectl config (look for document with 'kube' in name)
                      for item_id in $(echo "$OP_ITEMS" | jq -r '.[] | select(.title | ascii_downcase | contains("kube")) | .id' 2>/dev/null); do
                          KUBECONFIG_CONTENT=$(op document get "$item_id" 2>/dev/null)
                          if [ -n "$KUBECONFIG_CONTENT" ]; then
                              echo -e "${G}  ✓ Found kubectl config${N}"
                              break
                          fi
                      done
                      
                      if [ -n "$GH_TOKEN" ] || [ -n "$KUBECONFIG_CONTENT" ]; then
                          OP_AVAILABLE=true
                      else
                          echo -e "${Y}ℹ️  No GitHub token or kubectl config found in items tagged 'klaude'${N}"
                      fi
                  else
                      echo -e "${Y}ℹ️  No 1Password items tagged with 'klaude' found${N}"
                      echo -e "${Y}    Tag your GitHub token and/or kubeconfig items with 'klaude' to use them${N}"
                  fi
              else
                  echo -e "${Y}ℹ️  1Password CLI found but not signed in (run 'op signin' first)${N}"
              fi
          fi
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
      
      # Use persistent auth directory for Klaude (separate from host Claude)
      KLAUDE_AUTH_DIR="$HOME/.config/klaude-auth"
      mkdir -p "$KLAUDE_AUTH_DIR"
      
      if [ -f "$KLAUDE_AUTH_DIR/.credentials.json" ]; then
          echo -e "${G}🔑 Found saved Klaude authentication${N}"
          HAS_AUTH=true
      else
          echo -e "${Y}🔑 No saved auth found - will need to login once${N}"
          HAS_AUTH=false
      fi
      
      # Prepare environment variables and temp files for credentials
      DOCKER_ENV_ARGS=""
      DOCKER_VOLUME_ARGS=""
      TEMP_KUBECONFIG=""
      
      if [ "$OP_AVAILABLE" = "true" ]; then
          # Add GitHub token as environment variable
          if [ -n "$GH_TOKEN" ]; then
              DOCKER_ENV_ARGS="$DOCKER_ENV_ARGS -e GITHUB_TOKEN=$GH_TOKEN -e GH_TOKEN=$GH_TOKEN"
          fi
          
          # Create temporary kubeconfig file
          if [ -n "$KUBECONFIG_CONTENT" ]; then
              TEMP_KUBECONFIG=$(mktemp -t klaude-kubeconfig.XXXXXX)
              echo "$KUBECONFIG_CONTENT" > "$TEMP_KUBECONFIG"
              DOCKER_VOLUME_ARGS="$DOCKER_VOLUME_ARGS -v $TEMP_KUBECONFIG:/home/claude/.kube/config:ro"
              # Ensure cleanup on exit
              trap "rm -f '$TEMP_KUBECONFIG' 2>/dev/null" EXIT INT TERM
          fi
      fi
      
      # Run container with persistent Klaude auth directory
      docker run -it --rm \\
              --name "klaude-${PROJECT_NAME//[^a-zA-Z0-9]/-}-$$" \\
              --hostname "klaude" \\
              --privileged \\
              -v "$WORKSPACE":/workspace \\
              -v "$KLAUDE_AUTH_DIR":/home/claude/.config/claude \\
              $DOCKER_VOLUME_ARGS \\
              -w /workspace \\
              -e PATH=/usr/local/bin:/usr/bin:/bin \\
              -e CLAUDE_CONFIG_DIR=/home/claude/.config/claude \\
              -e HOME=/home/claude \\
              -e USER=claude \\
              $DOCKER_ENV_ARGS \\
              klaude-image \\
              bash -c \"
                  # Skip workspace chown since we use --dangerously-skip-permissions
                  echo '📁 Workspace: /workspace (using --dangerously-skip-permissions)'
                  
                  if [ -f /home/claude/.config/claude/.credentials.json ]; then
                      echo '🔑 Using saved Klaude authentication'
                  else
                      echo '🔑 First run - you will need to login once'
                  fi
                  
                  # Set up proper environment for Claude
                  export HOME=/home/claude
                  export USER=claude
                  export CLAUDE_CONFIG_DIR=/home/claude/.config/claude
                  
                  # Ensure proper directory structure and ownership
                  mkdir -p /home/claude/.config
                  mkdir -p /home/claude/.kube
                  chown -R claude:claude /home/claude/.config
                  chown -R claude:claude /home/claude/.config/claude 2>/dev/null || true
                  chmod 755 /home/claude/.config/claude
                  
                  # Set up kubectl config if mounted
                  if [ -f /home/claude/.kube/config ]; then
                      chown claude:claude /home/claude/.kube
                      chmod 600 /home/claude/.kube/config 2>/dev/null || true
                      echo '☸️  Kubectl configured from 1Password'
                  fi
                  
                  # Show if GitHub token is available
                  if [ -n \"\$GITHUB_TOKEN\" ]; then
                      echo '🔑 GitHub token available from 1Password'
                  fi
                  
                  # Ensure Claude can write to config files for session persistence
                  find /home/claude/.config/claude -type f -exec chmod 644 {} \; 2>/dev/null || true
                  
                  echo '✅ Container ready! Starting Claude Code in YOLO mode...'
                  echo '    (Authentication will persist after first login)'
                  echo ''
                  
                  # Run as the existing claude user
                  exec su claude -c 'cd /workspace && claude --dangerously-skip-permissions'
              \"
      
      # Clean up temp file if it exists (backup cleanup)
      [ -n "$TEMP_KUBECONFIG" ] && rm -f "$TEMP_KUBECONFIG" 2>/dev/null
      
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
      4. Login with your Claude Pro/Max subscription when prompted (first run only)
      
      #{Formatter.headline("1Password Integration (Optional):")}
      Tag your 1Password items with 'klaude':
        • GitHub Personal Access Token (with 'github' in the title)
        • Kubectl config document (with 'kube' in the title)
      
      Then run: op signin (if not already signed in)
      Klaude will automatically detect and use these credentials!
      
      To disable: KLAUDE_NO_1PASSWORD=true klaude
      
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