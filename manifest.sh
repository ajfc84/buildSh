#!/bin/sh

. "${CI_PROJECT_DIR}/buildSh/utils.sh"


create_manifest_winget()
{
    PROJECT_NAME="$1"        # ex: fx-shop-print
    VERSION="$2"             # ex: 1.0.0
    MSI_PATH="$3"            # ex: /mnt/c/FxShopPrint
    MSI_FILENAME="$4"        # ex: fx-shop-print-1.0.0.msi
    DESCRIPTION="$5"         # ex: FxShop Print Agent for POS integration

    if [ -z "$PROJECT_NAME" ] ||  [ -z "$VERSION" ] ||  [ -z "$MSI_PATH" ] ||  [ -z "$MSI_FILENAME" ];
    then
        echo "Usage: $0 <PROJECT_NAME> <VERSION> <MSI_PATH> <MSI_FILENAME> [Description]" >&2
        exit 1
    fi

    if [ -z "$VENDOR" ] || [ -z "$CI_REPOSITORY_URL" ] || [ -z "$WIN_REPO_URL_PATH" ] || [ -z "$WIN_REPO_MANIFEST_DIR" ];
    then
        echo "ERROR: $0 requires environment variables: VENDOR, CI_REPOSITORY_URL, WIN_REPO_URL_PATH, WIN_REPO_MANIFEST_DIR" >&2
        exit 1
    fi

    INSTALLER_URL="https://${CI_REPOSITORY_URL}/${WIN_REPO_URL_PATH}/${MSI_FILENAME}"    # ex: https://repo.fxshop.com/windows/fx-shop-print-1.0.0.msi

    if [ ! -f "$MSI_PATH" ];
    then
        echo "MSI not found: $MSI_PATH" >&2
        return 1
    fi

    if [ -z "$DESCRIPTION" ];
    then
        DESCRIPTION=""
    fi

    WIN_PROJECT_NAME=$(to_camel_case "${PROJECT_NAME}")
    PACKAGE_ID="${VENDOR}.${WIN_PROJECT_NAME}"

    # Normalize paths
    PACKAGE_ID_LW=$(echo "$PACKAGE_ID" | tr '[:upper:]' '[:lower:]')
    VENDOR_LW=$(echo "$VENDOR" | tr '[:upper:]' '[:lower:]')
    WIN_PROJECT_NAME_LW=$(echo "$WIN_PROJECT_NAME" | tr '[:upper:]' '[:lower:]')

    MANIFESTS_DIR="${CI_PROJECT_DIR}/fx-repo/${WIN_REPO_MANIFEST_DIR}/${VENDOR_LW}/${WIN_PROJECT_NAME_LW}/${VERSION}"
    mkdir -p "$MANIFESTS_DIR"

    echo "INFO: Creating WinGet manifests at $MANIFESTS_DIR" >&2

    echo "INFO: Calculating SHA256 for ${MSI_PATH}" >&2
    SHA256=$(sha256sum "${MSI_PATH}" | awk '{print $1}')

    # Base manifest
    cat > "${MANIFESTS_DIR}/${PACKAGE_ID_LW}.yaml" <<EOF
PackageIdentifier: $PACKAGE_ID
PackageVersion: $VERSION
PackageName: $WIN_PROJECT_NAME
Publisher: $VENDOR
License: Proprietary
ShortDescription: $DESCRIPTION
ManifestType: version
ManifestVersion: 1.6.0
EOF

    # Installer manifest
    cat > "${MANIFESTS_DIR}/${PACKAGE_ID_LW}.installer.yaml" <<EOF
PackageIdentifier: $PACKAGE_ID
PackageVersion: $VERSION
InstallerType: msi
Installers:
  - Architecture: x64
    InstallerUrl: $INSTALLER_URL
    InstallerSha256: $SHA256
ManifestType: installer
ManifestVersion: 1.6.0
EOF

    # Locale manifest (pt-PT default)
    cat > "${MANIFESTS_DIR}/${PACKAGE_ID_LW}.locale.pt-PT.yaml" <<EOF
PackageIdentifier: $PACKAGE_ID
PackageVersion: $VERSION
PackageLocale: pt-PT
Publisher: $VENDOR
PackageName: $WIN_PROJECT_NAME
ShortDescription: $DESCRIPTION
ManifestType: locale
ManifestVersion: 1.6.0
EOF

    echo "INFO: Created successfully WinGet manifests" >&2
}
