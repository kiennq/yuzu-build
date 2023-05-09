# SPDX-FileCopyrightText: 2019 yuzu Emulator Project
# SPDX-License-Identifier: GPL-2.0-or-later

param($BUILD_NAME)

$GITDATE = $(git show -s --date=short --format='%ad') -replace "-", ""
$GITREV = $(git show -s --format='%h')

if ("$BUILD_NAME" -eq "mainline") {
    $RELEASE_DIST = "yuzu-windows-msvc"
}
else {
    $RELEASE_DIST = "yuzu-windows-msvc-$BUILD_NAME"
}

$MSVC_BUILD_PDB = "yuzu-windows-msvc-$GITDATE-$GITREV-debugsymbols.zip" -replace " ", ""
$MSVC_SEVENZIP = "yuzu-windows-msvc-$GITDATE-$GITREV.7z" -replace " ", ""
$MSVC_SOURCE = "yuzu-windows-msvc-source-$GITDATE-$GITREV" -replace " ", ""
$MSVC_SOURCE_TAR = "$MSVC_SOURCE.tar"
$MSVC_SOURCE_TARXZ = "$MSVC_SOURCE_TAR.xz"

$env:BUILD_SYMBOLS = $MSVC_BUILD_PDB
$env:BUILD_UPDATE = $MSVC_SEVENZIP

$BUILD_DIR = ".\build\bin\Release"

# Cleanup unneeded data in submodules
git submodule foreach git clean -fxd

# Upload debugging symbols
mkdir pdb
Get-ChildItem "$BUILD_DIR\" -Recurse -Filter "*.pdb" | Copy-Item -destination .\pdb
7z a -tzip $MSVC_BUILD_PDB .\pdb\*.pdb
rm "$BUILD_DIR\*.pdb"

# Create artifact directories
mkdir $RELEASE_DIST
mkdir $MSVC_SOURCE
mkdir "artifacts"

$CURRENT_DIR = Convert-Path .

# Build a tar.xz for the source of the release
git clone --depth 1 file://$CURRENT_DIR $MSVC_SOURCE
7z a -r -ttar $MSVC_SOURCE_TAR $MSVC_SOURCE
7z a -r -txz $MSVC_SOURCE_TARXZ $MSVC_SOURCE_TAR

# Build the final release artifacts
Copy-Item $MSVC_SOURCE_TARXZ -Destination $RELEASE_DIST
Copy-Item "$BUILD_DIR\*" -Destination $RELEASE_DIST -Recurse
rm "$RELEASE_DIST\*.exe"
Get-ChildItem "$BUILD_DIR" -Recurse -Filter "yuzu*.exe" | Copy-Item -destination $RELEASE_DIST
Get-ChildItem "$BUILD_DIR" -Recurse -Filter "QtWebEngineProcess*.exe" | Copy-Item -destination $RELEASE_DIST
7z a $MSVC_SEVENZIP $RELEASE_DIST

Get-ChildItem . -Filter "*.zip" | Copy-Item -destination "artifacts"
Get-ChildItem . -Filter "*.7z" | Copy-Item -destination "artifacts"
Get-ChildItem . -Filter "*.tar.xz" | Copy-Item -destination "artifacts"
