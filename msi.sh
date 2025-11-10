#!/bin/sh

. "${CI_PROJECT_DIR}/buildSh/utils.sh"
. "${CI_PROJECT_DIR}/buildSh/version_sanitize.sh"

find_latest_signtool() {
    WIN_KITS_BIN_ROOT="$1"

    if [ -d "$WIN_KITS_BIN_ROOT" ]; then
        LATEST=$(ls -1 "$WIN_KITS_BIN_ROOT" 2>/dev/null | sort -V | tail -n1)
        if [ -n "$LATEST" ] && [ -x "$WIN_KITS_BIN_ROOT/$LATEST/x64/signtool.exe" ]; then
            echo "$WIN_KITS_BIN_ROOT/$LATEST/x64/signtool.exe"
            return 0
        fi
    fi
    return 1
}

## POSIX build script for generating and optionally signing an MSI installer
## Requirements (installed on the Windows host):
##   - WiX Toolset (candle.exe, light.exe)
##   - Windows SDK (signtool.exe)
package_msi() {
    PROJECT_NAME="$1"
    VERSION="$2"

    if [ -z "$PROJECT_NAME" ] || [ -z "$VERSION" ]; then
        echo "Usage: package_msi <PROJECT_NAME> <VERSION>" >&2
        exit 1
    fi

    if [ -z "$UPGRADE_CODE" ] || [ -z "$WIX_BIN" ] || [ -z "$WIN_KITS_BIN_ROOT" ]; then
        echo "ERROR: package_msi requires environment variables: UPGRADE_CODE, WIX_BIN, WIN_KITS_BIN_ROOT" >&2
        exit 1
    fi

    VERSION=$(sanitize_version "${VERSION}")
    DISPLAY_NAME=$(to_camel_case "${PROJECT_NAME}")
    DIST_WIN="/mnt/c/${DISPLAY_NAME}"
    BIN_PATH="${DIST_WIN}/${PROJECT_NAME}.exe"

    MANUFACTURER="FxSoftTech"
    DESCRIPTION="Thermal print agent for FxShop POS system"
    TIMESTAMP_URL="${TIMESTAMP_URL:-http://timestamp.digicert.com}"

    echo "==> Packaging MSI ${DISPLAY_NAME} ${VERSION}"

    if [ ! -f "$BIN_PATH" ]; then
        echo "ERROR: binary not found at $BIN_PATH" >&2
        exit 1
    fi

    if [ ! -x "$WIX_BIN/candle.exe" ] || [ ! -x "$WIX_BIN/light.exe" ]; then
        echo "ERROR: WiX Toolset not found at: $WIX_BIN" >&2
        echo "Install on Windows host with: winget install WiXToolset.WiXToolset" >&2
        exit 1
    fi

    if [ -z "$PFX_FILE" ] || [ -z "$PFX_PASS" ]; then
        echo "WARNING: PFX_FILE/PFX_PASS not set — package will be unsigned."
        SIGN_MODE="none"
    else
        SIGNTOOL=$(find_latest_signtool "${WIN_KITS_BIN_ROOT}" || true)
        if [ ! -x "$SIGNTOOL" ]; then
            echo "ERROR: signtool.exe not found. Install Windows SDK on host." >&2
            exit 1
        fi
        SIGN_MODE="pfx"
    fi

    MSI_FILE="${DIST_WIN}/${PROJECT_NAME}_${VERSION}.msi"
    WXS_FILE="${DIST_WIN}/${PROJECT_NAME}.wxs"
    WIXOBJ_FILE="${DIST_WIN}/${PROJECT_NAME}.wixobj"

    # translate paths for WiX and signtool
    BIN_PATH_WIN="$(wslpath -w "$BIN_PATH")"
    MSI_FILE_WIN="$(wslpath -w "$MSI_FILE")"
    WIXOBJ_FILE_WIN="$(wslpath -w "$WIXOBJ_FILE")"
    WXS_FILE_WIN="$(wslpath -w "$WXS_FILE")"

    GUID_COMPONENT_MAIN=$(uuidgen_safe)
    GUID_COMPONENT_SHORTCUT=$(uuidgen_safe)

    echo "==> Generating WiX XML..."
    cat > "$WXS_FILE" <<EOF
<?xml version="1.0"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi"
     xmlns:util="http://schemas.microsoft.com/wix/UtilExtension">
  <Product Id="*" Name="${DISPLAY_NAME}" Language="1033" Version="${VERSION}"
           Manufacturer="${MANUFACTURER}" UpgradeCode="${UPGRADE_CODE}">
    <Package InstallerVersion="500" Compressed="yes" InstallScope="perMachine" />
    <Media Id="1" Cabinet="product.cab" EmbedCab="yes" />
    <MajorUpgrade DowngradeErrorMessage="A newer version is already installed." />

    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFilesFolder">
        <Directory Id="INSTALLFOLDER" Name="${DISPLAY_NAME}">
          <!-- Main executable and service definition -->
          <Component Id="MainExecutable" Guid="${GUID_COMPONENT_MAIN}">
            <File Id="MainExe" Source="${BIN_PATH_WIN}" KeyPath="yes" />

            <!-- Register the Windows service -->
            <ServiceInstall
                Id="${DISPLAY_NAME}ServiceInstall"
                Name="${PROJECT_NAME}"
                DisplayName="Fx Shop Print Agent"
                Description="Thermal print agent for FxShop POS system"
                Start="auto"
                Type="ownProcess"
                Vital="yes"
                ErrorControl="normal" />

            <!-- Control service during install/uninstall -->
            <ServiceControl
                Id="${DISPLAY_NAME}ServiceControl"
                Name="${PROJECT_NAME}"
                Start="install"
                Stop="both"
                Remove="uninstall"
                Wait="yes" />

            <!-- Optional registry key (no KeyPath to avoid CNDL0042) -->
            <RegistryValue
                Root="HKLM"
                Key="Software\\${MANUFACTURER}\\${DISPLAY_NAME}"
                Name="InstallPath"
                Type="string"
                Value="[INSTALLFOLDER]" />
          </Component>

          <!-- Optional Start Menu shortcut -->
          <Directory Id="ProgramMenuFolder">
            <Directory Id="${DISPLAY_NAME}ProgramMenu" Name="${DISPLAY_NAME}">
              <Component Id="StartMenuShortcut" Guid="${GUID_COMPONENT_SHORTCUT}">
                <Shortcut
                    Id="${DISPLAY_NAME}Shortcut"
                    Name="${DISPLAY_NAME}"
                    Description="${DESCRIPTION}"
                    Target="[INSTALLFOLDER]${PROJECT_NAME}.exe"
                    WorkingDirectory="INSTALLFOLDER" />
                <RemoveFolder Id="Remove${DISPLAY_NAME}Menu" On="uninstall" />
                <RegistryValue Root="HKCU"
                               Key="Software\\${MANUFACTURER}\\${DISPLAY_NAME}"
                               Name="installed"
                               Type="integer"
                               Value="1"
                               KeyPath="yes" />
              </Component>
            </Directory>
          </Directory>
        </Directory>
      </Directory>
    </Directory>

    <Feature Id="MainFeature" Title="${DISPLAY_NAME}" Level="1">
      <ComponentRef Id="MainExecutable" />
      <ComponentRef Id="StartMenuShortcut" />
    </Feature>
  </Product>
</Wix>
EOF

    echo "==> Running WiX compiler..."
    "$WIX_BIN/candle.exe" "$WXS_FILE_WIN" -out "$WIXOBJ_FILE_WIN"
    "$WIX_BIN/light.exe" -ext WixUIExtension -ext WixUtilExtension \
        -out "$MSI_FILE_WIN" "$WIXOBJ_FILE_WIN"

    echo "==> MSI created: $MSI_FILE"

    if [ "$SIGN_MODE" = "pfx" ]; then
        echo "==> Signing MSI..."
        "$SIGNTOOL" sign \
            /fd SHA256 \
            /td SHA256 \
            /tr "$TIMESTAMP_URL" \
            /f "$PFX_FILE" \
            /p "$PFX_PASS" \
            "$MSI_FILE_WIN"
        echo "==> Signature complete."
    else
        echo "==> (No signature applied.)"
    fi
}
