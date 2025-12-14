#!/bin/sh
set -e

# Check and extract version number
[ $# != 1 ] && echo "Usage:  $0 <latest_releases_tag>" && exit 1
VERSION=$(echo "$1" | sed -n 's|[^0-9]*\([^_]*\).*|\1|p') && test "$VERSION"

PACKAGE=msedit
REPO=microsoft/edit

ARCH_LIST="amd64 arm64"
AMD64_FILENAME="edit-$VERSION-x86_64-linux-gnu.tar.zst"
ARM64_FILENAME="edit-$VERSION-aarch64-linux-gnu.tar.zst"

prepare() {
    mkdir -p output tmp
    curl -fs https://api.github.com/repos/$REPO/releases/latest | jq -r '.body' | gzip > tmp/changelog.gz
    curl -fsLo "tmp/$PACKAGE.svg" https://github.com/microsoft/edit/raw/refs/heads/main/assets/edit.svg
    curl -fsLo "tmp/$PACKAGE.desktop" https://github.com/microsoft/edit/raw/refs/heads/main/assets/com.microsoft.edit.desktop
    sed -i "s/Icon=edit/Icon=$PACKAGE/" "tmp/$PACKAGE.desktop"
    sed -i "s/Exec=edit/Exec=$PACKAGE/" "tmp/$PACKAGE.desktop"
}

build() {
    BASE_DIR="$PACKAGE"_"$ARCH" && rm -rf "$BASE_DIR"
    install -D templates/copyright -t "$BASE_DIR/usr/share/doc/$PACKAGE"
    install -D tmp/changelog.gz -t "$BASE_DIR/usr/share/doc/$PACKAGE"
    install -D "tmp/$PACKAGE.desktop" -t "$BASE_DIR/usr/share/applications"
    install -D "tmp/$PACKAGE.svg" -t "$BASE_DIR/usr/share/icons/hicolor/scalable/apps"

    # Download and move file
    curl -fsLo "tmp/$PACKAGE-$ARCH.tar.zst" "$(get_url_by_arch "$ARCH")"
    tar -xf "tmp/$PACKAGE-$ARCH.tar.zst"
    install -D -m 755 -t "$BASE_DIR/usr/bin" edit && rm edit

    # Package deb
    mkdir -p "$BASE_DIR/DEBIAN"
    SIZE=$(du -sk "$BASE_DIR"/usr | cut -f1)
    echo "Package: $PACKAGE
Version: $VERSION-1
Architecture: $ARCH
Installed-Size: $SIZE
Maintainer: wcbing <i@wcbing.top>
Section: editors
Priority: optional
Homepage: https://github.com/$REPO
Description: A simple editor for simple needs.
" > "$BASE_DIR/DEBIAN/control"

    dpkg-deb -b --root-owner-group -Z xz "$BASE_DIR" output
}

get_url_by_arch() {
    DOWNLOAD_PREFIX="https://github.com/$REPO/releases/latest/download"
    case $1 in
    "amd64") echo "$DOWNLOAD_PREFIX/$AMD64_FILENAME" ;;
    "arm64") echo "$DOWNLOAD_PREFIX/$ARM64_FILENAME" ;;
    esac
}

prepare

for ARCH in $ARCH_LIST; do
    echo "Building $ARCH package..."
    build
done

# Create repo files
cd output && apt-ftparchive packages . > Packages && apt-ftparchive release . > Release
