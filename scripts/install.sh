#!/usr/bin/env bash
#
# VANTA installer for macOS and Linux.
#
#   curl -fsSL https://vanta.aethlon.xyz/install.sh | bash
#
# Override the install directory with VANTA_INSTALL_DIR, or pin a release with
# VANTA_VERSION (for example, VANTA_VERSION=v0.1.0).
set -euo pipefail

REPO="Aethlon/Vanta"
BIN="vanta"
INSTALL_DIR="${VANTA_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${VANTA_VERSION:-}"

say() {
    printf '%s\n' "$*"
}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

fetch_stdout() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    else
        die "curl or wget is required"
    fi
}

download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" -o "$2"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$2" "$1"
    else
        die "curl or wget is required"
    fi
}

case "$(uname -s)" in
    Linux*) os="linux" ;;
    Darwin*) os="macos" ;;
    *)
        die "unsupported operating system: $(uname -s). Visit https://vanta.aethlon.xyz"
        ;;
esac

case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
        die "unsupported architecture: $(uname -m). Visit https://vanta.aethlon.xyz"
        ;;
esac

if [ "$os" = "linux" ] && [ "$arch" != "x86_64" ]; then
    die "no Linux ${arch} build is published yet. Visit https://vanta.aethlon.xyz"
fi

asset="vanta-${os}-${arch}.tar.gz"

if [ -z "$VERSION" ]; then
    VERSION="$(fetch_stdout "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n 1 || true)"
fi

if [ -z "$VERSION" ]; then
    die "no published VANTA release is available yet. Visit https://vanta.aethlon.xyz"
fi

url="https://github.com/${REPO}/releases/download/${VERSION}/${asset}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

say "Downloading VANTA ${VERSION} (${os}/${arch})..."
if ! download "$url" "$tmp/$asset"; then
    die "could not download ${url}. Visit https://vanta.aethlon.xyz"
fi

# Verify the checksum when the release includes one.
if download "${url}.sha256" "$tmp/${asset}.sha256" 2>/dev/null; then
    expected="$(cut -d' ' -f1 "$tmp/${asset}.sha256")"
    if command -v sha256sum >/dev/null 2>&1; then
        actual="$(sha256sum "$tmp/$asset" | cut -d' ' -f1)"
    elif command -v shasum >/dev/null 2>&1; then
        actual="$(shasum -a 256 "$tmp/$asset" | cut -d' ' -f1)"
    else
        actual=""
        say "warning: no sha256 tool found; skipping checksum verification"
    fi
    if [ -n "$actual" ] && [ "$expected" != "$actual" ]; then
        die "checksum mismatch for ${asset}"
    fi
fi

tar -xzf "$tmp/$asset" -C "$tmp"
[ -f "$tmp/$BIN" ] || die "archive did not contain a vanta binary"

mkdir -p "$INSTALL_DIR"
install -m 0755 "$tmp/$BIN" "$INSTALL_DIR/$BIN"

say ""
say "  ##   ##   #####   ##   ##  ######  #####"
say "  ##   ##  ##   ##  ###  ##    ##    ##  ##"
say "  ##   ##  #######  ## # ##    ##    ######"
say "   ## ##   ##   ##  ##  ###    ##    ##  ##"
say "    ###    ##   ##  ##   ##    ##    ##  ##"
say ""
say "  VANTA ${VERSION} installed"
say "  deterministic code intelligence"
say ""
say "  Start:    vanta"
say "  Index:    vanta index ."
say "  Update:   vanta update"
say "  Docs:     https://vanta.aethlon.xyz/docs"
say ""
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        say ""
        say "Add it to your PATH:"
        say "  export PATH=\"$INSTALL_DIR:\$PATH\""
        say "Then restart the shell or source your profile."
        ;;
esac

"$INSTALL_DIR/$BIN" --version
