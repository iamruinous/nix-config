#!/bin/bash
set -euo pipefail

CERT_NAME="${1:-Nix Signing}"
CERT_DAYS="${2:-3650}"  # 10 years by default

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}==>${NC} $1"; }
error() { echo -e "${RED}==>${NC} $1"; }

# Check if certificate already exists
check_existing() {
    if /usr/bin/security find-identity -v -p codesigning 2>/dev/null | grep -q "$CERT_NAME"; then
        return 0
    fi
    return 1
}

# Create temporary directory
CERT_DIR=$(mktemp -d)
trap "rm -rf $CERT_DIR" EXIT

info "Nix Code Signing Certificate Generator"
echo ""

# Check if already exists
if check_existing; then
    success "Certificate '$CERT_NAME' already exists and is trusted!"
    echo ""
    echo "Available signing identities:"
    /usr/bin/security find-identity -v -p codesigning
    echo ""
    echo "To remove and recreate, first delete the certificate from Keychain Access."
    exit 0
fi

info "Creating self-signed code signing certificate: '$CERT_NAME'"
info "Valid for $CERT_DAYS days"
echo ""

# Generate private key
info "Generating private key..."
openssl genrsa -out "$CERT_DIR/signing.key" 2048 2>/dev/null

# Generate self-signed certificate with code signing extensions
info "Generating self-signed certificate..."
openssl req -new -x509 \
    -key "$CERT_DIR/signing.key" \
    -out "$CERT_DIR/signing.crt" \
    -days "$CERT_DAYS" \
    -subj "/CN=$CERT_NAME/O=Nix" \
    -addext "keyUsage=critical,digitalSignature" \
    -addext "extendedKeyUsage=critical,codeSigning" \
    -addext "basicConstraints=critical,CA:false" \
    2>/dev/null

# Create PKCS12 bundle for import (use legacy mode for macOS compatibility)
info "Creating PKCS12 bundle..."
openssl pkcs12 -export \
    -out "$CERT_DIR/signing.p12" \
    -inkey "$CERT_DIR/signing.key" \
    -in "$CERT_DIR/signing.crt" \
    -passout pass:temp123 \
    -legacy \
    2>/dev/null

# Import into login keychain
info "Importing certificate into login keychain..."
/usr/bin/security import "$CERT_DIR/signing.p12" \
    -k ~/Library/Keychains/login.keychain-db \
    -P "temp123" \
    -T /usr/bin/codesign \
    -T /usr/bin/security \
    -T /usr/bin/productbuild \
    -T /usr/bin/productsign

# Set partition list to allow codesign access without prompts
info "Configuring keychain access..."
/usr/bin/security set-key-partition-list \
    -S apple-tool:,apple:,codesign: \
    -s -k "" ~/Library/Keychains/login.keychain-db 2>/dev/null || \
/usr/bin/security set-key-partition-list \
    -S apple-tool:,apple:,codesign: \
    -s ~/Library/Keychains/login.keychain-db 2>/dev/null || true

# Save certificate for trust step
SAVED_CERT="$HOME/.nix-codesign-cert.crt"
cp "$CERT_DIR/signing.crt" "$SAVED_CERT"

echo ""
warn "Certificate imported but needs to be TRUSTED for code signing."
echo ""
info "To trust the certificate, run:"
echo ""
echo "  sudo security add-trusted-cert -d -r trustRoot -p codeSign -k /Library/Keychains/System.keychain '$SAVED_CERT'"
echo ""
info "Or manually in Keychain Access:"
echo "  1. Open Keychain Access"
echo "  2. Find '$CERT_NAME' in 'login' keychain under 'My Certificates'"
echo "  3. Double-click the certificate"
echo "  4. Expand 'Trust' section"
echo "  5. Set 'Code Signing' to 'Always Trust'"
echo "  6. Close and enter your password"
echo ""

# Try to add trust automatically (requires sudo) if running interactively
if [[ -t 0 ]]; then
    read -p "Would you like to trust the certificate now? (requires sudo) [y/N] " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Adding certificate to system trust store..."
        if sudo /usr/bin/security add-trusted-cert -d -r trustRoot \
            -k /Library/Keychains/System.keychain \
            -p codeSign \
            "$SAVED_CERT"; then
            success "Certificate trusted successfully!"
            rm -f "$SAVED_CERT"
        else
            error "Failed to add trust. Please trust manually in Keychain Access."
            echo "Certificate saved at: $SAVED_CERT"
            exit 1
        fi
    else
        echo "Certificate saved at: $SAVED_CERT"
        echo "Run the sudo command above when ready to trust."
    fi
else
    echo "Certificate saved at: $SAVED_CERT"
    echo "Run the sudo command above to complete setup."
fi

echo ""
# Verify the certificate is now valid
if check_existing; then
    success "Certificate '$CERT_NAME' is now ready for code signing!"
    echo ""
    echo "Available signing identities:"
    /usr/bin/security find-identity -v -p codesigning
    echo ""
    echo "You can now build codesigned packages:"
    echo "  nix build .#wezterm-codesigned --option sandbox false"
else
    warn "Certificate was imported but trust may not be configured."
    echo ""
    echo "Please trust the certificate manually in Keychain Access:"
    echo "  1. Open Keychain Access"
    echo "  2. Find '$CERT_NAME' in 'login' keychain"
    echo "  3. Double-click -> Trust -> Code Signing: 'Always Trust'"
fi
