#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="1.0.0"
ZEN_MIN_VERSION="3.0.0"
ZEN_INSTALLER="https://raw.githubusercontent.com/Jishith-dev/Zen/main/install.sh"
FORGE_REPO="${FORGE_REPO_URL:-https://github.com/Jishith-dev/Forge.git}"

AUTO_YES=false

for arg in "$@"; do
    case "$arg" in
        -y|--yes)
            AUTO_YES=true
            ;;
        -h|--help)
            printf 'Usage: install.sh [-y|--yes]\n'
            exit 0
            ;;
        *)
            printf 'Error: unknown option: %s\n' "$arg" >&2
            exit 1
            ;;
    esac
done

log() {
    printf '[Forge] %s\n' "$*"
}

die() {
    printf '[Forge] Error: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    if [[ -n "${WORK_DIR:-}" && -d "$WORK_DIR" ]]; then
        rm -rf -- "$WORK_DIR"
    fi
}

trap cleanup EXIT

confirm() {
    if "$AUTO_YES"; then
        return 0
    fi

    local answer
    read -r -p "$1 [y/N] " answer
    [[ "$answer" == "y" || "$answer" == "Y" ]]
}

for cmd in curl git grep; do
    command -v "$cmd" >/dev/null 2>&1 ||
        die "Required command not found: $cmd"
done

# Make common user installation locations discoverable.
if [[ -n "${PREFIX:-}" && -d "$PREFIX/bin" ]]; then
    export PATH="$PREFIX/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"

get_zen_version() {
    local output
    output="$(zen --version 2>&1)" || return 1

    if [[ "$output" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        printf '%s.%s.%s\n' \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[2]}" \
            "${BASH_REMATCH[3]}"
    else
        return 1
    fi
}

version_is_supported() {
    local version="$1"
    local major minor patch

    IFS=. read -r major minor patch <<< "$version"

    # Avoid octal interpretation of leading zeroes.
    major=$((10#$major))
    minor=$((10#$minor))
    patch=$((10#$patch))

    (( major > 3 ||
       (major == 3 && minor > 0) ||
       (major == 3 && minor == 0 && patch >= 0) ))
}

ZEN_VERSION=""

if command -v zen >/dev/null 2>&1; then
    ZEN_VERSION="$(get_zen_version || true)"
fi

if [[ -z "$ZEN_VERSION" ]] ||
   ! version_is_supported "$ZEN_VERSION"; then

    if [[ -n "$ZEN_VERSION" ]]; then
        log "Zen $ZEN_VERSION is too old; Forge requires Zen $ZEN_MIN_VERSION or newer."
    else
        log "Zen is not installed or its version could not be detected."
    fi

    confirm "Install or update Zen now?" ||
        die "Zen installation cancelled."

    log "Running the official Zen installer..."

    if "$AUTO_YES"; then
        curl -fsSL "$ZEN_INSTALLER" | bash -s -- -y
    else
        curl -fsSL "$ZEN_INSTALLER" | bash
    fi

    # Refresh PATH for common installation locations.
    if [[ -n "${PREFIX:-}" && -d "$PREFIX/bin" ]]; then
        export PATH="$PREFIX/bin:$PATH"
    fi
    export PATH="$HOME/.local/bin:$PATH"

    command -v zen >/dev/null 2>&1 ||
        die "Zen installation finished, but 'zen' is not available in PATH."

    ZEN_VERSION="$(get_zen_version || true)"

    [[ -n "$ZEN_VERSION" ]] ||
        die "Could not determine the installed Zen version."

    version_is_supported "$ZEN_VERSION" ||
        die "Zen $ZEN_VERSION is unsupported. Upgrade to Zen $ZEN_MIN_VERSION or newer."
fi

log "Using Zen $ZEN_VERSION."

if [[ -n "${PREFIX:-}" && -d "$PREFIX/bin" ]]; then
    INSTALL_DIR="$PREFIX/bin"
else
    INSTALL_DIR="$HOME/.local/bin"
fi

mkdir -p "$INSTALL_DIR"

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/forge-install.XXXXXXXX")" ||
    die "Could not create a temporary directory."

log "Cloning Forge source..."

git clone --depth 1 "$FORGE_REPO" "$WORK_DIR/forge" ||
    die "Could not clone $FORGE_REPO"

cd "$WORK_DIR/forge"

log "Running Zen to build Forge..."

zen build main.zen ||
    die "The Forge build/run command failed."

[[ -f build/main ]] ||
    die "Expected executable build/main was not produced."

chmod +x build/main

# Install atomically so a failed copy does not damage the old installation.
TEMP_BINARY="$INSTALL_DIR/.forge.tmp.$$"
trap 'rm -f -- "${TEMP_BINARY:-}"; cleanup' EXIT

cp build/main "$TEMP_BINARY"
chmod +x "$TEMP_BINARY"
mv -f "$TEMP_BINARY" "$INSTALL_DIR/forge"

log "Forge v$VERSION installed to $INSTALL_DIR/forge"

# Verify the installed CLI.
if "$INSTALL_DIR/forge" --version; then
    log "Installation successful."
else
    die "Forge was copied, but its --version check failed."
fi

case ":$PATH:" in
    *":$INSTALL_DIR:"*)
        ;;
    *)
        log "Add this directory to PATH if needed:"
        log "export PATH=\"$INSTALL_DIR:\$PATH\""
        ;;
esac

log "Only the Forge executable was installed; temporary source files will be removed."
