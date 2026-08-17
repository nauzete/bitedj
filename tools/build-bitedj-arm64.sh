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
    build-essential cmake ninja-build pkg-config git ccache dpkg-dev libgtest-dev \
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
    -DCMAKE_CXX_FLAGS=-Wno-error=stringop-overflow \
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

# Build a native Debian package so apt can resolve the shared-library
# dependencies automatically. CPack in the upstream tree still uses the
# Mixxx package name and install paths, so the package is assembled from the
# verified build output with BiteDJ-specific paths and metadata.
DEB_ROOT="${BUILD_DIR}/deb-root"
DEB_VERSION="1.0.0"
rm -rf "${DEB_ROOT}"
DESTDIR="${DEB_ROOT}" cmake --install "${BUILD_DIR}" --prefix /usr --strip --config Release --component Runtime
mkdir -p "${DEB_ROOT}/usr/bin" "${DEB_ROOT}/usr/share/bitedj" "${DEB_ROOT}/DEBIAN"
if [[ -f "${DEB_ROOT}/usr/bin/mixxx" ]]; then
    mv "${DEB_ROOT}/usr/bin/mixxx" "${DEB_ROOT}/usr/bin/bitedj"
fi
if [[ -d "${DEB_ROOT}/usr/share/mixxx" ]]; then
    cp -a "${DEB_ROOT}/usr/share/mixxx/." "${DEB_ROOT}/usr/share/bitedj/"
    rm -rf "${DEB_ROOT}/usr/share/mixxx"
fi
if [[ -f "${DEB_ROOT}/usr/share/applications/org.mixxx.Mixxx.desktop" ]]; then
    mv "${DEB_ROOT}/usr/share/applications/org.mixxx.Mixxx.desktop" \
       "${DEB_ROOT}/usr/share/applications/us.deckshark.BiteDJ.desktop"
    sed -i 's/org\.mixxx\.Mixxx/us.deckshark.BiteDJ/g; s/Exec=mixxx/Exec=bitedj/g; s/Mixxx/BiteDJ/g' \
       "${DEB_ROOT}/usr/share/applications/us.deckshark.BiteDJ.desktop"
fi
rm -rf "${DEB_ROOT}/usr/share/mixxx" "${DEB_ROOT}/usr/share/doc/mixxx"
cat > "${DEB_ROOT}/DEBIAN/control" <<EOF
Package: bitedj
Version: ${DEB_VERSION}
Section: sound
Priority: optional
Architecture: arm64
Maintainer: Deckshark <support@deckshark.us>
Homepage: https://github.com/TeamDeckshark/bitedj
Depends: fonts-open-sans, fonts-ubuntu, libqt6sql6-sqlite, qt6-qpa-plugins, libqt6core5compat6
Description: BiteDJ digital DJ application
 Independent touchscreen-oriented DJ software based on Mixxx.
EOF
dpkg-deb --root-owner-group --build "${DEB_ROOT}" "${OUT_DIR}/bitedj_${DEB_VERSION}_arm64.deb" >/dev/null

echo
echo "Ejecutable: ${OUT_DIR}/bitedj-arm64/bin/bitedj"
echo "Paquete:    ${OUT_DIR}/bitedj-ubuntu-24.04-arm64.tar.gz"
echo "Debian:     ${OUT_DIR}/bitedj_${DEB_VERSION}_arm64.deb"
file "${OUT_DIR}/bitedj-arm64/bin/bitedj"
