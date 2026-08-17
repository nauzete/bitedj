#!/usr/bin/env bash
set -Eeuo pipefail

# Build BiteDJ natively on Ubuntu 24.04 ARM64.
# The resulting binary is intentionally built dynamically against Ubuntu's
# libraries so it uses the target machine's audio and graphics stack.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-arm64"
OUT_DIR="${ROOT_DIR}/dist-arm64"

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "aarch64" ]]; then
    echo "Este script debe ejecutarse en Ubuntu 24.04 ARM64 (aarch64)." >&2
    exit 2
fi

if ! command -v apt-get >/dev/null || ! grep -qi '^VERSION_ID="24.04"' /etc/os-release; then
    echo "Se requiere Ubuntu 24.04." >&2
    exit 2
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential cmake ninja-build pkg-config git ccache \
    qt6-base-dev qt6-declarative-dev qt6-5compat-dev qt6-tools-dev qt6-tools-dev-tools libqt6svg6-dev \
    qtkeychain-qt6-dev \
    libasound2-dev libjack-jackd2-dev libpulse-dev portaudio19-dev \
    libportmidi-dev libsndio-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswresample-dev \
    libchromaprint-dev libfftw3-dev libflac-dev libid3tag0-dev libmad0-dev \
    libmp3lame-dev \
    libmodplug-dev libopus-dev libopusfile-dev libsndfile1-dev \
    libshout3-dev libtag1-dev libvorbis-dev libwavpack-dev \
    libebur128-dev librubberband-dev libsoundtouch-dev \
    libusb-1.0-0-dev libhidapi-dev liblilv-dev libserd-dev libsord-dev \
    libsratom-dev libzix-dev libprotobuf-dev protobuf-compiler \
    libsqlite3-dev libupower-glib-dev libdbus-1-dev libmsgsl-dev \
    libglu1-mesa-dev libx11-dev libxext-dev libxi-dev libxrandr-dev \
    libxrender-dev libxfixes-dev libxkbcommon-dev fonts-open-sans fonts-ubuntu

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DBUILD_TESTING=OFF \
    -DBUILD_BENCH=OFF \
    -DDOWNLOAD_MANUAL=OFF \
    -DWARNINGS_FATAL=OFF \
    -DQT6=ON \
    -DFAAD=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr

cmake --build "${BUILD_DIR}" --parallel "$(nproc)" --target mixxx

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}/bitedj-arm64/res" "${OUT_DIR}/bitedj-arm64/bin"
cp "${BUILD_DIR}/mixxx" "${OUT_DIR}/bitedj-arm64/bin/bitedj"
cp -a "${ROOT_DIR}/res/." "${OUT_DIR}/bitedj-arm64/res/"
cp "${ROOT_DIR}/LICENSE" "${ROOT_DIR}/README.md" "${OUT_DIR}/bitedj-arm64/"
chmod 0755 "${OUT_DIR}/bitedj-arm64/bin/bitedj"

tar -C "${OUT_DIR}" -czf "${OUT_DIR}/bitedj-ubuntu-24.04-arm64.tar.gz" bitedj-arm64

echo
echo "Ejecutable: ${OUT_DIR}/bitedj-arm64/bin/bitedj"
echo "Paquete:    ${OUT_DIR}/bitedj-ubuntu-24.04-arm64.tar.gz"
file "${OUT_DIR}/bitedj-arm64/bin/bitedj"
