#!/bin/bash

# =============================================================================
# Valhalla Test Fixture Generator
# =============================================================================
# This script generates test fixtures (routing tiles) for the valhalla-mobile
# project using OpenStreetMap data from Andorra.
#
# Prerequisites:
#   - Docker installed and running
#   - Internet connection to download OSM data
#
# Usage:
#   ./scripts/create_fixtures.sh
# =============================================================================

set -euo pipefail

# Configuration
OSM_URL="https://download.geofabrik.de/europe/andorra-latest.osm.pbf"
OSM_FILE="andorra-latest.osm.pbf"
VALHALLA_IMAGE="ghcr.io/valhalla/valhalla:latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Use a project-local build directory instead of /tmp to avoid Docker volume mounting issues on macOS
WORK_DIR="$PROJECT_ROOT/build/fixtures"

# Output directories
IOS_SOURCE_SUPPORT_DIR="$PROJECT_ROOT/apple/Sources/Valhalla/SupportData"
IOS_TEST_DATA="$PROJECT_ROOT/apple/Tests/ValhallaTests/TestData"
ANDROID_TEST_DATA="$PROJECT_ROOT/android/valhalla/src/androidTest/assets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cleanup() {
    log_info "Cleaning up build directory: $WORK_DIR"
    rm -rf "$WORK_DIR"
}

# Only cleanup on error; keep directory on success for debugging if needed
trap 'if [ $? -ne 0 ]; then cleanup; fi' EXIT

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi

    log_info "Prerequisites check passed."
}

# Download OSM data
download_osm_data() {
    log_info "Downloading Andorra OSM data from Geofabrik..."
    curl -L --progress-bar -o "$WORK_DIR/$OSM_FILE" "$OSM_URL"
    log_info "Download complete: $WORK_DIR/$OSM_FILE"
}

# Pull the latest Valhalla Docker image
pull_valhalla_image() {
    log_info "Pulling latest Valhalla Docker image..."
    docker pull "$VALHALLA_IMAGE"
    log_info "Docker image pulled successfully."
}

# Build Valhalla tiles
# Setup working directory
setup_work_dir() {
    log_info "Setting up working directory..."
    rm -rf "$WORK_DIR"
    mkdir -p "$WORK_DIR"
    mkdir -p "$WORK_DIR/valhalla_tiles"
    log_info "Working directory ready: $WORK_DIR"
}

build_tiles() {
    log_info "Building Valhalla tiles..."

    # Generate Valhalla config (redirect on host side, not inside container)
    log_info "Generating Valhalla configuration..."
    docker run --rm \
        -v "$WORK_DIR:/data" \
        "$VALHALLA_IMAGE" \
        valhalla_build_config \
        --mjolnir-tile-dir /data/valhalla_tiles \
        --mjolnir-timezone /data/valhalla_tiles/timezones.sqlite \
        --mjolnir-admin /data/valhalla_tiles/admins.sqlite \
        > "$WORK_DIR/valhalla.json"

    log_info "Configuration generated."

    # Verify config was created
    if [ ! -f "$WORK_DIR/valhalla.json" ]; then
        log_error "Failed to generate valhalla.json"
        exit 1
    fi

    # Build the tiles
    log_info "Building tiles from OSM data (this may take a few minutes)..."
    docker run --rm \
        -v "$WORK_DIR:/data" \
        "$VALHALLA_IMAGE" \
        valhalla_build_tiles \
        -c /data/valhalla.json \
        /data/$OSM_FILE

    log_info "Tiles built successfully."
}

# Create tar archive of tiles
create_tar_archive() {
    log_info "Creating tar archive of tiles..."

    # Create tar archive (without compression for faster access)
    cd "$WORK_DIR/valhalla_tiles"
    tar -cf "$WORK_DIR/valhalla_tiles.tar" .
    cd - > /dev/null

    log_info "Tar archive created: $WORK_DIR/valhalla_tiles.tar"
}

# Copy fixtures to iOS test directory
copy_to_ios() {
    log_info "Copying fixtures to iOS test directory..."

    # Copy the valhalla.json to config.json
    cp "$WORK_DIR/valhalla.json" "$IOS_SOURCE_SUPPORT_DIR/default.json"

    # Remove old fixtures
    rm -rf "$IOS_TEST_DATA/valhalla_tiles"
    rm -f "$IOS_TEST_DATA/valhalla_tiles.tar"

    # Copy new fixtures
    cp -r "$WORK_DIR/valhalla_tiles" "$IOS_TEST_DATA/"
    cp "$WORK_DIR/valhalla_tiles.tar" "$IOS_TEST_DATA/"

    log_info "iOS fixtures updated at: $IOS_TEST_DATA"
}

# Copy fixtures to Android test directory
copy_to_android() {
    log_info "Copying fixtures to Android test directory..."

    # Remove old fixtures
    rm -rf "$ANDROID_TEST_DATA/valhalla_tiles"
    rm -f "$ANDROID_TEST_DATA/valhalla_tiles.tar"

    # Copy new fixtures
    cp -r "$WORK_DIR/valhalla_tiles" "$ANDROID_TEST_DATA/"
    cp "$WORK_DIR/valhalla_tiles.tar" "$ANDROID_TEST_DATA/"

    # Copy the valhalla.json to config.json
    cp "$WORK_DIR/valhalla.json" "$ANDROID_TEST_DATA/config.json"

    log_info "Android fixtures updated at: $ANDROID_TEST_DATA"
}

# Print summary of Andorra coordinates for test updates
print_test_coordinates() {
    log_warn ""
    log_warn "=========================================="
    log_warn "IMPORTANT: Test Coordinates Need Updating"
    log_warn "=========================================="
    log_warn ""
    log_warn "The fixtures now use Andorra data. You may need to update test coordinates."
    log_warn ""
    log_warn "Sample coordinates within Andorra for testing:"
    log_warn "  - Andorra la Vella (capital): lat=42.5063, lon=1.5218"
    log_warn "  - Escaldes-Engordany: lat=42.5086, lon=1.5394"
    log_warn "  - Encamp: lat=42.5349, lon=1.5803"
    log_warn "  - La Massana: lat=42.5450, lon=1.5148"
    log_warn "  - Sant Julià de Lòria: lat=42.4631, lon=1.4913"
    log_warn ""
    log_warn "Example route (Andorra la Vella to Escaldes-Engordany):"
    log_warn "  Start: lat=42.5063, lon=1.5218"
    log_warn "  End:   lat=42.5086, lon=1.5394"
    log_warn ""
}

# Main execution
main() {
    log_info "=========================================="
    log_info "Valhalla Test Fixture Generator"
    log_info "=========================================="
    log_info "Working directory: $WORK_DIR"
    log_info ""

    check_prerequisites
    pull_valhalla_image
    setup_work_dir
    download_osm_data
    build_tiles
    create_tar_archive
    copy_to_ios
    copy_to_android
    print_test_coordinates

    log_info ""
    log_info "=========================================="
    log_info "Fixture generation complete!"
    log_info "=========================================="
    log_info ""
    log_info "Generated files:"
    log_info "  iOS:     $IOS_TEST_DATA/valhalla_tiles/"
    log_info "           $IOS_TEST_DATA/valhalla_tiles.tar"
    log_info "  Android: $ANDROID_TEST_DATA/valhalla_tiles/"
    log_info "           $ANDROID_TEST_DATA/valhalla_tiles.tar"
    log_info "           $ANDROID_TEST_DATA/config.json"

    # Clean up build directory on success
    cleanup
}

main "$@"
