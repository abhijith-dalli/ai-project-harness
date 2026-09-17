#!/bin/bash
# serve-dashboard.sh — Start a local HTTP server for the AI Project Harness dashboard
#
# Usage:
#   ./scripts/serve-dashboard.sh              # Auto-detect and serve
#   ./scripts/serve-dashboard.sh /path/to/project  # Serve a specific project
#
# The dashboard will be available at http://localhost:8080/.harness/dashboard/

set -e

PORT="${PORT:-8080}"

# Determine the project directory
if [ -n "$1" ]; then
  PROJECT_DIR="$1"
else
  PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
fi

HARNESS_DIR="$PROJECT_DIR/.harness"

if [ ! -d "$HARNESS_DIR/dashboard" ]; then
  echo "Error: No .harness/dashboard/ found at $HARNESS_DIR"
  echo ""
  echo "Make sure the harness is installed in your project:"
  echo "  ./scripts/install.sh $PROJECT_DIR"
  exit 1
fi

echo "AI Project Harness Dashboard"
echo "============================"
echo ""
echo "Project:  $PROJECT_DIR"
echo "Harness:  $HARNESS_DIR"
echo "URL:      http://localhost:$PORT/.harness/dashboard/"
echo ""
echo "Press Ctrl+C to stop."
echo ""

# Try python3 first, then python, then npx
if command -v python3 &>/dev/null; then
  cd "$PROJECT_DIR"
  python3 -m http.server "$PORT"
elif command -v python &>/dev/null; then
  cd "$PROJECT_DIR"
  python -m SimpleHTTPServer "$PORT"
elif command -v npx &>/dev/null; then
  cd "$PROJECT_DIR"
  npx serve -l "$PORT" .harness/dashboard
else
  echo "Error: No HTTP server found."
  echo "Install Python or Node.js, or run manually:"
  echo "  cd $PROJECT_DIR && python3 -m http.server $PORT"
  exit 1
fi
