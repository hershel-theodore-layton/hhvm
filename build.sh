#!/usr/bin/env bash
set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

usage() {
  cat <<'USAGE'
Usage:
  ./build.sh [--ubuntu-26.04]

Build HHVM Debian packages. By default, build for Ubuntu 24.04.

Options:
  --ubuntu-26.04  Build for Ubuntu 26.04.
  -h, --help      Show this help.
USAGE
}

TARGET_UBUNTU_VERSION="24.04"
DISTRO_DEFAULT="ubuntu-24.04-noble"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --ubuntu-26.04)
      TARGET_UBUNTU_VERSION="26.04"
      DISTRO_DEFAULT="ubuntu-26.04-resolute"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      echo "Unexpected positional argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ "$#" -ne 0 ]; then
  echo "Unexpected positional argument: $1" >&2
  usage >&2
  exit 2
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "build.sh must run as root in a fresh Ubuntu container." >&2
  exit 1
fi

. /etc/os-release
if [ "${ID:-}" != "ubuntu" ] || [ "${VERSION_ID:-}" != "$TARGET_UBUNTU_VERSION" ]; then
  echo "build.sh expects Ubuntu ${TARGET_UBUNTU_VERSION}; found ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi
unset VERSION

branch_version() {
  local branch y m d
  branch="$(git branch --show-current 2>/dev/null || true)"
  if [[ "$branch" =~ ^hhvm-oss-([0-9]{4})([0-9]{2})([0-9]{2})$ ]]; then
    y="${BASH_REMATCH[1]}"
    m="${BASH_REMATCH[2]}"
    d="${BASH_REMATCH[3]}"
    printf '%s.%s.%s\n' "$y" "$m" "$d"
    return
  fi

  echo "Set HHVM_VERSION or build from an hhvm-oss-YYYYMMDD branch." >&2
  exit 1
}

JOBS="${JOBS:-$(nproc)}"
OUT="${OUT:-/var/out}"
DISTRO="${DISTRO:-$DISTRO_DEFAULT}"
VERSION="${HHVM_VERSION:-$(branch_version)}"

export JOBS OUT DISTRO VERSION
export DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:-parallel=${JOBS}}"

apt_get() {
  apt-get -o Acquire::Retries=3 "$@"
}

apt_get update -y
apt_get install -y ca-certificates gnupg software-properties-common
add-apt-repository -y universe
apt_get update -y

apt_get install -y \
  curl \
  devscripts \
  equivs \
  git \
  openssh-client \
  python3

export PATH="/root/.cargo/bin:$PATH"
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
fi
rustup toolchain install nightly --profile minimal
rustup component add rustfmt --toolchain nightly
rustup default nightly

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mapfile -t SUBMODULES < <(git config --file .gitmodules --get-regexp 'submodule\..*\.path' | awk '{ print $2 }')
  if [ "${#SUBMODULES[@]}" -gt 0 ]; then
    git submodule sync --recursive -- "${SUBMODULES[@]}"
    git submodule update --init --recursive -- "${SUBMODULES[@]}"
  fi
fi

rm -rf debian
rm -f ./*-build-deps*_*_all.deb ./*-build-deps*_*_*.buildinfo ./*-build-deps*_*_*.changes
mkdir -p "$OUT"

exec ci/bin/make-debianish-package
