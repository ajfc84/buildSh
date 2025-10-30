#!/bin/sh


package_deb() 
{
    NAME="$1"
    VERSION="$2"
    BIN_PATH="$3"
    BUILD_DIR="$4"
    AUTHOR_NAME="$5"
    AUTHOR_EMAIL="$6"

    if [ -z "$NAME" ] || [ -z "$VERSION" ] || [ -z "$BIN_PATH" ] || [ -z "$BUILD_DIR" ] || [ -z "$AUTHOR_NAME" ] || [ -z "$AUTHOR_EMAIL" ]; then
        echo "Usage: package_deb <name> <version> <bin_path> <build_dir> <author_name> <author_email>" >&2
        return 1
    fi

    if [ ! -f "$BIN_PATH" ]; then
        echo "Binary not found: $BIN_PATH" >&2
        return 1
    fi

    PKG_DIR="$BUILD_DIR/${NAME}_pkg"
    DEB_DIR="$PKG_DIR/DEBIAN"
    ARCH="$(dpkg --print-architecture 2>/dev/null || echo amd64)"

    echo "INFO: packaging $NAME ($VERSION) for $ARCH"

    # prepare structure
    rm -rf "$PKG_DIR"
    mkdir -p "$DEB_DIR" "$PKG_DIR/usr/local/bin" "$PKG_DIR/etc/systemd/system"

    # copy binary
    cp "$BIN_PATH" "$PKG_DIR/usr/local/bin/$NAME"
    chmod 755 "$PKG_DIR/usr/local/bin/$NAME"

    # systemd service
    cat > "$PKG_DIR/etc/systemd/system/${NAME}.service" <<EOF
[Unit]
Description=${NAME} Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/${NAME}
Restart=always
RestartSec=5
User=lp
Group=lp
StandardOutput=append:/var/log/${NAME}.log
StandardError=append:/var/log/${NAME}.log

[Install]
WantedBy=multi-user.target
EOF

    # control file
    cat > "$DEB_DIR/control" <<EOF
Package: ${NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: ${AUTHOR_NAME} <${AUTHOR_EMAIL}>
Description: ${NAME} Service
 A lightweight service daemon for ${NAME}.
Depends: systemd
EOF

    # postinst
    cat > "$DEB_DIR/postinst" <<EOF
#!/bin/sh
set -e
mkdir -p /var/log
touch /var/log/${NAME}.log
chown lp:lp /var/log/${NAME}.log
chmod 664 /var/log/${NAME}.log
systemctl daemon-reload || true
systemctl enable ${NAME}.service || true
systemctl restart ${NAME}.service || true
exit 0
EOF

    # prerm
    cat > "$DEB_DIR/prerm" <<EOF
#!/bin/sh
set -e
systemctl stop ${NAME}.service || true
systemctl disable ${NAME}.service || true
systemctl daemon-reload || true
exit 0
EOF

    # postrm
    cat > "$DEB_DIR/postrm" <<EOF
#!/bin/sh
set -e
if [ "\$1" = "remove" ] || [ "\$1" = "purge" ]; then
    rm -f /etc/systemd/system/${NAME}.service
    systemctl daemon-reload || true
    rm -f /var/log/${NAME}.log
fi
exit 0
EOF

    chmod 755 "$DEB_DIR/postinst" "$DEB_DIR/prerm" "$DEB_DIR/postrm"

    # build .deb
    PKG_NAME="${NAME}_${VERSION}_${ARCH}.deb"
    echo "INFO: building package: $PKG_NAME"
    dpkg-deb --build "$PKG_DIR" "$BUILD_DIR/$PKG_NAME"

    echo "INFO: package created: $BUILD_DIR/$PKG_NAME"
}
