#!/bin/sh

# Check parameters
if [ $# -ne 1 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage:
    $0 <version>"
    exit 1
fi

PACKAGE="msedit"
REPO="microsoft/edit"

# Processing again to avoid errors of remote incoming 
VERSION=$(echo $1 | sed -n 's|[^0-9]*\([^_]*\).*|\1|p')

ARCH_LIST="amd64 arm64"
AMD64_FILENAME="edit-$VERSION-x86_64-linux-gnu.tar.zst"
ARM64_FILENAME="edit-$VERSION-aarch64-linux-gnu.tar.zst"

build() {
    # Prepare
    ARCH=$1
    BASE_DIR="$PACKAGE"_"$ARCH"
    cp -r templates "$BASE_DIR"
    sed -i "s/Architecture: arch/Architecture: $ARCH/" "$BASE_DIR/DEBIAN/control"
    sed -i "s/Version: version/Version: $VERSION-1/" "$BASE_DIR/DEBIAN/control"

    # Download and move file
    curl https://api.github.com/repos/$REPO/releases/latest | jq -r '.body' > $BASE_DIR/usr/share/doc/$PACKAGE/CHANGELOG.md
    curl -sLo "$PACKAGE-$ARCH.tar.zst" "$(get_url_by_arch $ARCH)"
    tar -xf "$PACKAGE-$ARCH.tar.zst"
    mv "edit" "$BASE_DIR/usr/bin/$PACKAGE"
    chmod 755 "$BASE_DIR/usr/bin/$PACKAGE"

    # Build
    dpkg-deb -b --root-owner-group -Z xz "$BASE_DIR" output
}

get_url_by_arch() {
    DOWNLOAD_PERFIX="https://github.com/$REPO/releases/latest/download"
    case $1 in
    "amd64") echo "$DOWNLOAD_PERFIX/$AMD64_FILENAME" ;;
    "arm64") echo "$DOWNLOAD_PERFIX/$ARM64_FILENAME" ;;
    esac
}

mkdir -p output

for i in $ARCH_LIST; do
    echo "Building $i package..."
    build "$i"
done

# Create repo files
cd output
apt-ftparchive packages . > Packages
apt-ftparchive release . > Release
