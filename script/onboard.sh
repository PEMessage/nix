#!/usr/bin/env bash
# One-shot remote NixOS install with nixos-anywhere + disko.
#
# Automates, in order:
#   1. fetch_kexec      download the kexec bootstrap tarball locally, so the
#                       target machine never has to reach GitHub
#   2. stage_host_secrets  decrypt this host's root-key-encrypted files from the
#                          secrets repo (hosts/<alias>/root/<path>, mirroring
#                          the target) into a staging dir for --extra-files
#   3. verify_secrets   prove hosts/<hosts-dir>/secret.yaml opens with that key
#   4. install          `nixos-anywhere` -- THIS WIPES THE TARGET DISK --
#
# It does not lock or stage the flake: that must be done beforehand (`nix flake
# lock`, `git add`), otherwise the eval below fails with a nix error. The only
# repo write is the regenerated hosts/<dir>/_nixos/hardware-configuration.nix.
#
# The root age key never touches disk: the operator provides it as SOPS_AGE_KEY
# (see the secrets repo README) and it is used only to unwrap the per-host key.
# Only that per-host key is shipped, to /var/lib/sops-nix/key.txt.
#
# Usage (the root key must already be exported as $SOPS_AGE_KEY — see the
# secrets repo README for how):
#   ROOT_PASS='...' script/onboard.sh \
#       -H root@1.2.3.4 -p 22 -c vm-citrine -a vm-citrine -y
#   script/onboard.sh -H root@1.2.3.4 -c vm-citrine -a vm-citrine
#
# The root *password* (the cloud image's login password) is read from
# $ROOT_PASS, or prompted for on a tty. It is deliberately NOT accepted as a
# command-line argument, so it never lands in shell history or `ps`. Every
# option can also be supplied as an env var.
#
# Flags:
#   -H, --target  root@IP     target host                (required)
#   -p, --ssh-port PORT       SSH port                   (default 22)
#   -P, --post-kexec-port PORT  port dialled after kexec (default 22)
#   -c, --config  NAME        nixosConfiguration         (required)
#   -d, --hosts-dir DIR       hosts/<DIR> holding _nixos/ (default: $CONFIG)
#   -a, --alias   NAME        per-host key name          (default: $CONFIG)
#   -F, --force               re-download the kexec tarball
#   -y, --yes                 skip the destructive-action confirmation
#   -h, --help
#
# Scratch space is /tmp/nixos-onboard (printed on start, reused across runs so
# the kexec tarball is not re-downloaded).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

WORK=""
TARGET="${TARGET:-}"
PORT="${PORT:-22}"
# Port we dial *after* the kexec switchover, overridable with -P. The prebuilt
# installer always listens on 22 inside the guest, so this is the public port
# that reaches guest:22 -- 22 on a 1:1 NAT endpoint. Override when the provider
# maps ports.
POST_KEXEC_PORT=22
CONFIG="${CONFIG:-}"
HOSTS_DIR="${HOSTS_DIR:-}"
ALIAS="${ALIAS:-}"
RELEASE=""
ARCH="${ARCH:-x86_64-linux}"
ROOT_PASS="${ROOT_PASS:-}"
ASSUME_YES="${ASSUME_YES:-0}"
FORCE=0
KEXEC="${KEXEC:-}"
KEXEC_URL=""
SECRETS_REPO="${SECRETS_REPO:-$REPO/secrets}"
HOST_ROOT=""
SECRET_FILE=""
STAGE=""
STAGE_KEY=""

trap 'unset ROOT_PASS SSHPASS 2>/dev/null || true' EXIT

# -- helpers ---------------------------------------------------------------

need() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }
die()  { echo "error: $*" >&2; exit 1; }

runcmd() {
    echo "Running: $*"
    "$@"
}

runeval() {
    echo "Running: $*"
    eval "$*"
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
  ROOT_PASS='...' script/onboard.sh -H root@1.2.3.4 -p 22 -c vm-citrine -a vm-citrine -y
  script/onboard.sh -H root@1.2.3.4 -c vm-citrine -a vm-citrine

SOPS_AGE_KEY (the root key) must be in the environment — see the secrets repo.

Flags:
  -H, --target  root@IP     target host                (required)
  -p, --ssh-port PORT       SSH port                   (default 22)
  -P, --post-kexec-port PORT  port dialled after kexec (default 22)
  -c, --config  NAME        nixosConfiguration         (required)
  -d, --hosts-dir DIR       hosts/<DIR> holding _nixos/ (default: $CONFIG)
  -a, --alias   NAME        per-host key name          (default: $CONFIG)
  -F, --force               re-download the kexec tarball
  -y, --yes                 skip the destructive-action confirmation
  -h, --help

The root password is read from $ROOT_PASS, or prompted for on a tty (never argv).

The installer itself always listens on 22; -P is the *public* port that reaches
guest:22 after the switch. Only needed when the provider maps ports (1:1 NAT: 22).
EOF
}

target_ip() {
    echo "${TARGET##*@}"
}

# -- steps -----------------------------------------------------------------

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -H|--target)    TARGET="${2:?--target needs a value}"; shift 2 ;;
            -p|--ssh-port)  PORT="${2:?--ssh-port needs a value}"; shift 2 ;;
            -P|--post-kexec-port)
                            POST_KEXEC_PORT="${2:?--post-kexec-port needs a value}"; shift 2 ;;
            -c|--config)    CONFIG="${2:?--config needs a value}"; shift 2 ;;
            -d|--hosts-dir) HOSTS_DIR="${2:?--hosts-dir needs a value}"; shift 2 ;;
            -a|--alias)     ALIAS="${2:?--alias needs a value}"; shift 2 ;;
            -F|--force)     FORCE=1; shift ;;
            -y|--yes)       ASSUME_YES=1; shift ;;
            -h|--help)      usage; exit 0 ;;
            *)              die "unknown argument: $1 (try --help)" ;;
        esac
    done
}

make_workdir() {
    title
    # Fixed name on purpose: the kexec tarball is large and reused across runs,
    # so re-downloading it every time would be wasteful.
    WORK="/tmp/nixos-onboard"
    STAGE="$WORK/extra-files"
    STAGE_KEY="$STAGE/var/lib/sops-nix/key.txt"
    runcmd mkdir -p "$WORK"
    echo "work dir    : $WORK"
}

resolve_target() {
    [ -n "$TARGET" ] || die "--target root@IP is required"
    case "$TARGET" in
        *@*) : ;;
        *)   TARGET="root@$TARGET" ;;
    esac
    [ -n "$(target_ip)" ] || die "could not parse an IP out of --target '$TARGET'"
}

resolve_names() {
    [ -n "$CONFIG" ] || die "--config NAME is required (e.g. -c vm-citrine)"
    # Both default to the config name and both become path components, so
    # validate before anything is derived from them.
    ALIAS="${ALIAS:-$CONFIG}"
    HOSTS_DIR="${HOSTS_DIR:-$CONFIG}"
    case "$ALIAS" in
        *[!A-Za-z0-9._-]*) die "--alias may only contain [A-Za-z0-9._-]" ;;
    esac
    case "$HOSTS_DIR" in
        *[!A-Za-z0-9._/-]*) die "--hosts-dir may only contain [A-Za-z0-9._/-]" ;;
    esac
    [[ "$ALIAS" != *..* ]] || die "--alias must not contain '..'"
    [[ "$HOSTS_DIR" != *..* ]] || die "--hosts-dir must not contain '..'"
}

resolve_paths() {
    SECRETS_REPO="${SECRETS_REPO%/}"
    # hosts/<alias>/root mirrors the target filesystem ("/").
    HOST_ROOT="$SECRETS_REPO/hosts/$ALIAS/root"
    SECRET_FILE="$REPO/hosts/$HOSTS_DIR/secret.yaml"
}

resolve_kexec() {
    # Kexec release follows the nixpkgs branch pinned in flake.nix, so the
    # bootstrap image and the installed system stay in step.
    RELEASE="$(sed -n 's/.*nixpkgs?ref=\([A-Za-z0-9._-]*\).*/\1/p' "$REPO/flake.nix" | sed -n '1p')"
    RELEASE="${RELEASE:-nixos-26.05}"

    KEXEC="${KEXEC:-$WORK/nixos-kexec-installer-$ARCH.tar.gz}"
    KEXEC_URL="https://github.com/nix-community/nixos-images/releases/download/$RELEASE/nixos-kexec-installer-noninteractive-$ARCH.tar.gz"
}

show_plan() {
    echo "target      : $TARGET:$PORT (post-kexec via $POST_KEXEC_PORT)"
    echo "config      : $CONFIG  (hosts/$HOSTS_DIR)"
    echo "alias       : $ALIAS  ($HOST_ROOT)"
    echo "secrets repo: $SECRETS_REPO"
    echo "kexec       : $RELEASE ($ARCH)"
}

resolve() {
    title
    resolve_target
    resolve_names
    resolve_paths
    resolve_kexec
    show_plan
}

check_env() {
    title
    local c
    for c in nix git curl openssl tar sops; do runcmd need "$c"; done
    [ -f "$REPO/flake.nix" ] || die "no flake.nix under $REPO"
    [ -d "$SECRETS_REPO" ] || die "secrets repo not found: $SECRETS_REPO (set SECRETS_REPO)"
    [ -n "${SOPS_AGE_KEY:-}" ] || \
        die "SOPS_AGE_KEY is unset; export the root key first (see the secrets repo README)"
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

stage_host_secrets() {
    title
    [ -d "$HOST_ROOT" ] || \
        die "no root-key secrets at $HOST_ROOT; add them to the secrets repo first"
    umask 077
    local count=0 enc rel
    # hosts/<host>/root mirrors the target filesystem, so we decrypt each file
    # to the same relative path and let --extra-files lay it down. sops takes the
    # root key from SOPS_AGE_KEY and the rest from each file's own metadata, so
    # no .sops.yaml is needed here.
    while IFS= read -r -d '' enc; do
        rel="${enc#"$HOST_ROOT"/}"
        runcmd mkdir -p "$(dirname "$STAGE/$rel")"
        runeval "sops --decrypt '$enc' > \"$STAGE/$rel\""
        runcmd chmod 600 "$STAGE/$rel"
        count=$((count + 1))
    done < <(find "$HOST_ROOT" -type f -print0)
    [ "$count" -gt 0 ] || die "no files under $HOST_ROOT"
    [ -s "$STAGE_KEY" ] || \
        die "no host key at $HOST_ROOT/var/lib/sops-nix/key.txt"
    echo "staged      : $count file(s) from $HOST_ROOT"
}

verify_secrets() {
    title
    [ -s "$SECRET_FILE" ] || die "no hosts/$HOSTS_DIR/secret.yaml; create and encrypt it first"
    runeval "SOPS_AGE_KEY_FILE='$STAGE_KEY' sops --decrypt '$SECRET_FILE' >/dev/null" \
        || die "hosts/$HOSTS_DIR/secret.yaml does not decrypt with the staged per-host key"
    echo "ok     ${SECRET_FILE#"$REPO"/} decrypts with the per-host key"
}

verify_config() {
    title
    [ -d "$REPO/hosts/$HOSTS_DIR" ] || \
        die "host directory hosts/$HOSTS_DIR does not exist; pass -d"
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
    runcmd mkdir -p "$REPO/hosts/$HOSTS_DIR/_nixos"
    export SSHPASS="$ROOT_PASS"
    # "$PORT" is the provider's endpoint on the *original* system; after the
    # kexec switch the prebuilt nixos-images installer always runs sshd on 22
    # inside the guest, so we dial whatever public port reaches guest:22.
    #
    # --no-substitute-on-destination: without it nix has the *target* fetch paths
    # from its own substituters (cache.nixos.org), which is glacially slow from
    # this network; with it the paths come from the local store over this link.
    runcmd nix run github:nix-community/nixos-anywhere -- \
        --flake "$REPO#$CONFIG" \
        --target-host "$TARGET" \
        --ssh-port "$PORT" \
        --post-kexec-ssh-port "$POST_KEXEC_PORT" \
        --no-substitute-on-destination \
        --env-password \
        --kexec "$KEXEC" \
        --extra-files "$STAGE" \
        --build-on local \
        --generate-hardware-config nixos-generate-config \
            "$REPO/hosts/$HOSTS_DIR/_nixos/hardware-configuration.nix"
}

# -- main -------------------------------------------------------------------

main() {
    parse_args "$@"
    make_workdir
    resolve
    check_env
    ensure_password
    fetch_kexec
    stage_host_secrets
    verify_secrets
    verify_config
    confirm
    install
}

main "$@"
