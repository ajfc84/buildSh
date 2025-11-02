#!/bin/sh


package_deb() 
{
    PROJECT_NAME="$1"
    VERSION="$2"
    DIST="$3"
    AUTHOR_NAME="$4"
    AUTHOR_EMAIL="$5"

    if [ -z "$PROJECT_NAME" ] || [ -z "$VERSION" ] || [ -z "$DIST" ] || [ -z "$AUTHOR_NAME" ] || [ -z "$AUTHOR_EMAIL" ];
    then
        echo "Usage: package_deb <PROJECT_NAME> <VERSION> <DIST> <AUTHOR_NAME> <AUTHOR_EMAIL>" >&2
        return 1
    fi

    DIST="${SUB_PROJECT_DIR}/${DIST}"
    BIN_PATH="${DIST}/${PROJECT_NAME}"

    if [ ! -f "$BIN_PATH" ];
    then
        echo "Binary not found: $BIN_PATH" >&2
        return 1
    fi

    echo "INFO: Creating distribution archive..."

    PKG_DIR="$DIST/${PROJECT_NAME}_pkg"
    DEB_DIR="$PKG_DIR/DEBIAN"
    ARCH="$(dpkg --print-architecture 2>/dev/null || echo amd64)"

    echo "INFO: packaging $PROJECT_NAME ($VERSION) for $ARCH"

    # prepare structure
    rm -rf "$PKG_DIR"
    mkdir -p "$DEB_DIR" "$PKG_DIR/usr/local/bin" "$PKG_DIR/etc/systemd/system"

    # copy binary
    cp "$BIN_PATH" "$PKG_DIR/usr/local/bin/$PROJECT_NAME"
    chmod 755 "$PKG_DIR/usr/local/bin/$PROJECT_NAME"

    # systemd service
    cat > "$PKG_DIR/etc/systemd/system/${PROJECT_NAME}.service" <<EOF
[Unit]
Description=${PROJECT_NAME} Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/${PROJECT_NAME}
Restart=always
RestartSec=5
User=lp
Group=lp
StandardOutput=append:/var/log/${PROJECT_NAME}.log
StandardError=append:/var/log/${PROJECT_NAME}.log

[Install]
WantedBy=multi-user.target
EOF

    # control file
    cat > "$DEB_DIR/control" <<EOF
Package: ${PROJECT_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: ${AUTHOR_NAME} <${AUTHOR_EMAIL}>
Description: ${PROJECT_NAME} Service
 A lightweight service daemon for ${PROJECT_NAME}.
Depends: systemd
EOF

    # postinst
    cat > "$DEB_DIR/postinst" <<EOF
#!/bin/sh
set -e
mkdir -p /var/log
touch /var/log/${PROJECT_NAME}.log
chown lp:lp /var/log/${PROJECT_NAME}.log
chmod 664 /var/log/${PROJECT_NAME}.log
systemctl daemon-reload || true
systemctl enable ${PROJECT_NAME}.service || true
systemctl restart ${PROJECT_NAME}.service || true
exit 0
EOF

    # prerm
    cat > "$DEB_DIR/prerm" <<EOF
#!/bin/sh
set -e
systemctl stop ${PROJECT_NAME}.service || true
systemctl disable ${PROJECT_NAME}.service || true
systemctl daemon-reload || true
exit 0
EOF

    # postrm
    cat > "$DEB_DIR/postrm" <<EOF
#!/bin/sh
set -e
if [ "\$1" = "remove" ] || [ "\$1" = "purge" ]; then
    rm -f /etc/systemd/system/${PROJECT_NAME}.service
    systemctl daemon-reload || true
    rm -f /var/log/${PROJECT_NAME}.log
fi
exit 0
EOF

    chmod 755 "$DEB_DIR/postinst" "$DEB_DIR/prerm" "$DEB_DIR/postrm"

    # build .deb
    PKG_NAME="${PROJECT_NAME}_${VERSION}_${ARCH}.deb"
    echo "INFO: building package: $PKG_NAME"
    dpkg-deb --build "$PKG_DIR" "$DIST/$PKG_NAME"

    echo "INFO: package created: $DIST/$PKG_NAME"
}
