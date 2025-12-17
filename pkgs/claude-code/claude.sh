#!/usr/bin/env bash
set -euo pipefail

# Paths substituted by Nix
PATCHELF="@patchelf@"
DYNAMIC_LINKER="@dynamicLinker@"
JQ="@jq@"
CURL="@curl@"
NOTIFY="@notify@"

# Runtime paths
CLAUDE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/claude"
BINARY="$CLAUDE_DIR/claude"
VERSION_FILE="$CLAUDE_DIR/version"
UPDATE_LOG="$CLAUDE_DIR/update.log"
GCS_BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

# Detect platform
case "$(uname -m)" in
    x86_64|amd64) PLATFORM="linux-x64" ;;
    aarch64|arm64) PLATFORM="linux-arm64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

log() {
    echo "[$(date -Iseconds)] $*" >> "$UPDATE_LOG"
}

get_latest_version() {
    "$CURL" -fsSL --connect-timeout 5 "$GCS_BUCKET/latest" 2>/dev/null
}

get_manifest() {
    local version=$1
    "$CURL" -fsSL --connect-timeout 10 "$GCS_BUCKET/$version/manifest.json" 2>/dev/null
}

verify_checksum() {
    local file=$1
    local expected=$2
    local actual
    actual=$(sha256sum "$file" | cut -d' ' -f1)
    [[ "$actual" == "$expected" ]]
}

patch_binary() {
    local file=$1
    "$PATCHELF" --set-interpreter "$DYNAMIC_LINKER" "$file"
}

download_and_install() {
    local version=$1
    local quiet=${2:-false}
    local tmp
    tmp=$(mktemp)
    trap "rm -f '$tmp'" EXIT

    $quiet || echo "Downloading Claude Code $version..."

    if ! "$CURL" -fsSL "$GCS_BUCKET/$version/$PLATFORM/claude" -o "$tmp" 2>/dev/null; then
        log "ERROR: Download failed for $version"
        return 1
    fi

    # Verify checksum
    local manifest expected
    manifest=$(get_manifest "$version")
    if [[ -z "$manifest" ]]; then
        log "ERROR: Failed to fetch manifest for $version"
        return 1
    fi

    expected=$(echo "$manifest" | "$JQ" -r ".platforms[\"$PLATFORM\"].checksum")
    if ! verify_checksum "$tmp" "$expected"; then
        log "ERROR: Checksum mismatch for $version"
        return 1
    fi

    # Patch for NixOS
    $quiet || echo "Patching binary..."
    if ! patch_binary "$tmp"; then
        log "ERROR: patchelf failed for $version"
        return 1
    fi

    chmod +x "$tmp"
    mkdir -p "$CLAUDE_DIR"
    mv "$tmp" "$BINARY"
    echo "$version" > "$VERSION_FILE"
    trap - EXIT

    log "Installed $version"
    $quiet || echo "Installed Claude Code $version"
    return 0
}

repair_binary() {
    log "Attempting to repair binary..."
    if patch_binary "$BINARY" 2>/dev/null; then
        log "Repair successful"
        return 0
    fi

    # Patchelf failed, re-download
    local version
    version=$(cat "$VERSION_FILE" 2>/dev/null || get_latest_version)
    log "Re-downloading $version after repair failure"
    download_and_install "$version" true
}

notify_update() {
    local old_version=$1
    local new_version=$2

    # Try to send desktop notification
    if [[ -n "$NOTIFY" ]] && command -v "$NOTIFY" &>/dev/null; then
        "$NOTIFY" -a "Claude Code" -u low \
            "Updated: $old_version → $new_version" \
            "Restart Claude Code to use the new version.\nhttps://github.com/anthropics/claude-code/releases" \
            2>/dev/null || true
    fi
}

check_for_updates() {
    local current latest
    current=$(cat "$VERSION_FILE" 2>/dev/null || echo "")

    latest=$(get_latest_version)
    if [[ -z "$latest" ]]; then
        log "Failed to check for updates"
        return 1
    fi

    if [[ "$latest" != "$current" ]]; then
        log "Update available: $current -> $latest"
        if download_and_install "$latest" true; then
            notify_update "$current" "$latest"
        fi
    fi
}

background_update_check() {
    (check_for_updates) &>/dev/null &
    disown
}

# Ensure log directory exists
mkdir -p "$CLAUDE_DIR"

# Main logic
if [[ ! -x "$BINARY" ]]; then
    version=$(get_latest_version)
    if [[ -z "$version" ]]; then
        echo "Error: Cannot fetch version (network issue?)" >&2
        exit 1
    fi
    download_and_install "$version"
fi

# Try to run, repair if needed
if ! "$BINARY" --version &>/dev/null 2>&1; then
    repair_binary
fi

# Check for updates in background
background_update_check

# Run claude
exec "$BINARY" "$@"
