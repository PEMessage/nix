#!/usr/bin/env bash
# One-shot remote NixOS install with nixos-anywhere + disko.
#
# Automates, in order:
#   1. fetch_kexec   download the kexec bootstrap tarball locally, so the
#                    target machine never has to reach GitHub
#   2. make_secrets  stage the per-provider secrets under secrets/<alias>
#                    (gitignored; existing files are never overwritten)
#   3. lock_flake    `nix flake lock` so disko and friends are pinned
#   4. install       `nixos-anywhere` -- THIS WIPES THE TARGET DISK --
#
# Usage:
#   # non-interactive, password from the environment, no confirmation prompt
#   ROOT_PASS='...' script/onboard.sh -H root@1.2.3.4 -p 22 -c vps -a <servername> -y
#
#   # otherwise: ssh port 22, config vps, and a password prompt
#   script/onboard.sh -H root@1.2.3.4 -a <servername>
#
# The root password is read from $ROOT_PASS, or prompted for on a tty. It is
# deliberately NOT accepted as a command-line argument, so it never lands in
# shell history or `ps`. Every option can also be supplied as an env var.
#
# Flags:
#   -H, --target  root@IP     target host                (required)
#   -p, --ssh-port PORT       SSH port                   (default 22)
#   -c, --config  NAME        nixosConfiguration         (default vps)
#   -a, --alias   NAME        secrets/<NAME> dir         (required, e.g. <servername>)
#   -F, --force               overwrite existing secret files
#   -y, --yes                 skip the destructive-action confirmation
#   -h, --help
#
# Scratch space is the fixed dir /tmp/nixos-onboard (printed on start, reused
# across runs so the kexec tarball is not re-downloaded); the SSH key is always
# ~/.ssh/id_ed25519.pub.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

WORK=""
TARGET="${TARGET:-}"
PORT="${PORT:-22}"
CONFIG="${CONFIG:-vps}"
ALIAS="${ALIAS:-}"
RELEASE=""
ARCH="${ARCH:-x86_64-linux}"
PUBKEY="${PUBKEY:-$HOME/.ssh/id_ed25519.pub}"
ROOT_PASS="${ROOT_PASS:-}"
ASSUME_YES="${ASSUME_YES:-0}"
FORCE=0
KEXEC="${KEXEC:-}"
KEXEC_URL=""

trap 'unset ROOT_PASS SSHPASS 2>/dev/null || true' EXIT

# -- helpers ---------------------------------------------------------------

need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }
die()  { echo "error: $*" >&2; exit 1; }

runcmd() {
    echo "Running: $*"
    "$@"
}

title() {
    echo "=========================="
    echo "${FUNCNAME[1]}"
    echo "=========================="
}

usage() {
    cat <<'EOF'
One-shot remote NixOS install with nixos-anywhere + disko (WIPES THE TARGET DISK).

Usage:
  # non-interactive, password from the environment, no confirmation prompt
  ROOT_PASS='...' script/onboard.sh -H root@1.2.3.4 -p 22 -c vps -a <servername> -y

  # otherwise: ssh port 22, config vps, and a password prompt
  script/onboard.sh -H root@1.2.3.4 -a <servername>

Flags:
  -H, --target  root@IP     target host                (required)
  -p, --ssh-port PORT       SSH port                   (default 22)
  -c, --config  NAME        nixosConfiguration         (default vps)
  -a, --alias   NAME        secrets/<NAME> dir         (required, e.g. <servername>)
  -F, --force               overwrite existing secret files
  -y, --yes                 skip the destructive-action confirmation
  -h, --help

Scratch space is /tmp/nixos-onboard (printed on start; reused across runs).
The root password is read from $ROOT_PASS, or prompted for on a tty (never argv).
EOF
}

target_ip() {
    echo "${TARGET##*@}"
}

# -- steps -----------------------------------------------------------------

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -H|--target)   TARGET="${2:?--target needs a value}"; shift 2 ;;
            -p|--ssh-port) PORT="${2:?--ssh-port needs a value}"; shift 2 ;;
            -c|--config)   CONFIG="${2:?--config needs a value}"; shift 2 ;;
            -a|--alias)    ALIAS="${2:?--alias needs a value}"; shift 2 ;;
            -F|--force)    FORCE=1; shift ;;
            -y|--yes)      ASSUME_YES=1; shift ;;
            -h|--help)     usage; exit 0 ;;
            *)             die "unknown argument: $1 (try --help)" ;;
        esac
    done
}

make_workdir() {
    # Fixed name on purpose: the kexec tarball is large and is reused across
    # runs, so re-downloading it every time would be wasteful.
    WORK="/tmp/nixos-onboard"
    mkdir -p "$WORK"
    echo "work dir    : $WORK"
}

resolve() {
    title

    [ -n "$TARGET" ] || die "--target root@IP is required"
    case "$TARGET" in
        *@*) : ;;
        *)   TARGET="root@$TARGET" ;;
    esac
    [ -n "$(target_ip)" ] || die "could not parse an IP out of --target '$TARGET'"

    [ -n "$ALIAS" ] || die "--alias NAME is required (e.g. <servername>)"
    case "$ALIAS" in
        *[!A-Za-z0-9._-]*) die "--alias may only contain [A-Za-z0-9._-]" ;;
    esac
    [[ "$ALIAS" != *..* ]] || die "--alias must not contain '..'"

    # Kexec release follows the nixpkgs branch pinned in flake.nix, so the
    # bootstrap image and the installed system stay in step.
    RELEASE="$(sed -n 's/.*nixpkgs?ref=\([A-Za-z0-9._-]*\).*/\1/p' \
        "$REPO/flake.nix" | head -n1)"
    RELEASE="${RELEASE:-nixos-26.05}"

    KEXEC="${KEXEC:-$WORK/nixos-kexec-installer-$ARCH.tar.gz}"
    KEXEC_URL="https://github.com/nix-community/nixos-images/releases/download/$RELEASE/nixos-kexec-installer-noninteractive-$ARCH.tar.gz"

    echo "target      : $TARGET:$PORT"
    echo "config      : $CONFIG"
    echo "alias       : $ALIAS  (secrets/$ALIAS)"
    echo "kexec       : $RELEASE ($ARCH)"
    echo "pubkey      : $PUBKEY"
}

check_env() {
    title

    local c
    for c in nix git curl openssl tar; do runcmd need "$c"; done
    [ -f "$REPO/flake.nix" ] || die "no flake.nix under $REPO"
    [ -f "$PUBKEY" ] || die "SSH public key not found: $PUBKEY"
}

ensure_password() {
    title

    if [ -n "$ROOT_PASS" ]; then
        return 0
    fi
    [ -t 0 ] || die "ROOT_PASS is unset and stdin is not a tty"
    local confirm
    read -r -s -p "root password for $TARGET: " ROOT_PASS || true
    echo
    read -r -s -p "confirm password: " confirm || true
    echo
    [ -n "$ROOT_PASS" ] || die "password must not be empty"
    [ "$ROOT_PASS" = "$confirm" ] || die "passwords do not match"
}

fetch_kexec() {
    title

    if [ -s "$KEXEC" ] && [ "$FORCE" != 1 ]; then
        echo "kexec tarball already present, not re-downloading"
    else
        runcmd curl -fL --retry 3 --retry-delay 2 -o "$KEXEC.part" "$KEXEC_URL"
        runcmd mv "$KEXEC.part" "$KEXEC"
    fi
    runcmd ls -lh "$KEXEC"

    # Magic-byte check: a captive portal / error page otherwise sails through.
    local magic
    magic="$(head -c 2 "$KEXEC" | od -An -tx1 | tr -d ' \n')"
    [ "$magic" = "1f8b" ] || die "$KEXEC is not a gzip tarball (bad magic '$magic')"
}

# Write a secret only when the destination is absent/empty, unless --force.
place_secret() { # place_secret <mode> <dst> <value>
    local mode="$1" dst="$2" value="$3" rel="${2#"$REPO"/}"
    if [ -s "$dst" ] && [ "$FORCE" != 1 ]; then
        echo "keep   $rel"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    printf '%s\n' "$value" >"$dst"
    chmod "$mode" "$dst"
    echo "write  $rel"
}

place_file() { # place_file <mode> <src> <dst>
    local mode="$1" src="$2" dst="$3" rel="${3#"$REPO"/}"
    if [ -s "$dst" ] && [ "$FORCE" != 1 ]; then
        echo "keep   $rel"
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    cp -- "$src" "$dst"
    chmod "$mode" "$dst"
    echo "write  $rel"
}

make_secrets() {
    title

    umask 077
    local base="$REPO/secrets/$ALIAS"
    local sshdir="$base/root/.ssh"
    local secretsdir="$base/var/lib/nixos-secrets"

    # Never delete or re-create the tree: --extra-files ships whatever is under
    # secrets/<alias>, and unrelated host secrets (e.g. derper-host) may live
    # there already. Only add what is missing.
    runcmd mkdir -p "$sshdir" "$secretsdir"

    place_file 600 "$PUBKEY" "$sshdir/authorized_keys"

    local hash
    hash="$(printf '%s' "$ROOT_PASS" | openssl passwd -6 -stdin)"
    place_secret 600 "$secretsdir/root.hash" "$hash"
    place_secret 600 "$secretsdir/pem.hash" "$hash"

    # The vps config reads the DERP public IP from this file at runtime; the
    # public IP is exactly the address we are installing onto.
    place_secret 600 "$secretsdir/derper-host" "$(target_ip)"

    runcmd chmod 700 "$sshdir"
    echo "-- secrets/$ALIAS --"
    runcmd find "$base" -printf '%M %p\n'
}

lock_flake() {
    title

    runcmd git -C "$REPO" add -N .
    runcmd nix flake lock "$REPO"
    runcmd nix flake metadata "$REPO" >"$WORK/flake-metadata.txt"
    sed -n '1,5p' "$WORK/flake-metadata.txt"
}

verify_config() {
    title

    [ -d "$REPO/hosts/$CONFIG" ] || echo "warning: hosts/$CONFIG does not exist" >&2
    local names
    names="$(nix eval --json --apply builtins.attrNames \
        "$REPO#nixosConfigurations")" \
        || die "could not evaluate $REPO#nixosConfigurations"
    case "$names" in
        *"\"$CONFIG\""*) echo "found nixosConfiguration '$CONFIG'" ;;
        *) die "no nixosConfiguration '$CONFIG' in flake (have: $names)" ;;
    esac
}

confirm() {
    title

    [ "$ASSUME_YES" = 1 ] && return 0
    [ -t 0 ] || die "refusing to wipe $TARGET without confirmation; pass -y"
    echo "This will install nixosConfiguration '$CONFIG' on $TARGET:$PORT"
    echo "and WIPE the target disk via disko."
    local reply
    read -r -p "Continue? [y/N] " reply || true
    case "$reply" in
        [Yy]|[Yy][Ee][Ss]) : ;;
        *) die "aborted" ;;
    esac
}

install() {
    title

    runcmd mkdir -p "$REPO/hosts/$CONFIG"
    export SSHPASS="$ROOT_PASS"
    runcmd nix run github:nix-community/nixos-anywhere -- \
        --flake "$REPO#$CONFIG" \
        --target-host "$TARGET" \
        --ssh-port "$PORT" \
        --post-kexec-ssh-port "$PORT" \
        --env-password \
        --kexec "$KEXEC" \
        --extra-files "$REPO/secrets/$ALIAS" \
        --build-on local \
        --generate-hardware-config nixos-generate-config \
            "$REPO/hosts/$CONFIG/hardware-configuration.nix"
}

# -- main -------------------------------------------------------------------

main() {
    parse_args "$@"
    make_workdir
    resolve
    check_env
    ensure_password
    fetch_kexec
    make_secrets
    lock_flake
    verify_config
    confirm
    install
}

main "$@"
