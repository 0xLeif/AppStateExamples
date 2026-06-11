# syntax=docker/dockerfile:1
# Multi-stage production Dockerfile for appstate-vapor-example
# Following Vapor's official deployment template conventions.
#
# NOTE: AppState's Cache uses libswiftObservation (introduced in Swift 5.9 /
# Xcode 15).  On some swift:6.1-jammy images the static-stdlib linker cannot
# locate libswiftObservation.a when building with --static-swift-stdlib.
# If you hit a link error mentioning "swiftObservation" or
# "_$s22swiftObservation..." symbols, either:
#   • Use a swift:6.1-jammy-slim runtime image (dynamic linking, no --static-swift-stdlib), or
#   • Pin to a nightly toolchain snapshot where the static archive is present.
# The Dockerfile below is correct per Vapor conventions and links statically;
# adjust the build flags if your toolchain does not include the static archive.

# -------------------------------------------------------------------------
# Build stage
# -------------------------------------------------------------------------
FROM swift:6.1-jammy AS build

WORKDIR /build

# Copy the package manifest files first so Docker can cache the dependency
# resolution layer independently of source changes.
COPY Package.swift Package.resolved ./

# Resolve dependencies (cached unless manifests change).
RUN swift package resolve --skip-update 2>&1 | tail -10

# Copy the full source tree.
COPY Sources ./Sources
COPY Tests ./Tests

# Compile a release binary with the Swift stdlib statically linked so the
# run-stage image needs no Swift runtime installation.
RUN swift build \
    --configuration release \
    --static-swift-stdlib \
    -Xswiftc -O \
    2>&1

# Stage the binary and any bundled resources into /staging so the copy into
# the run image is a single layer.
RUN mkdir -p /staging/bin && \
    cp "$(swift build --configuration release --show-bin-path)/vapor-example" /staging/bin/

# Copy any resource bundles that SwiftPM may have generated alongside the binary.
RUN find "$(swift build --configuration release --show-bin-path)" \
        -name "*.resources" -maxdepth 1 \
        -exec cp -R {} /staging/bin/ \; 2>/dev/null || true

# -------------------------------------------------------------------------
# Run stage — minimal Ubuntu image (no Swift toolchain needed with static stdlib)
# -------------------------------------------------------------------------
FROM ubuntu:jammy AS run

# Install the minimum set of shared libraries that a Swift binary may still
# need at runtime (libstdc++, icu, tls, zlib) even when statically linked.
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libstdc++6 \
        libicu70 \
        libssl3 \
        zlib1g \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user/group for the server process.
RUN groupadd --gid 1000 vapor && \
    useradd --uid 1000 --gid vapor --shell /bin/bash --create-home vapor

WORKDIR /app

# Copy the staged binary (and any resource bundles) from the build stage.
COPY --from=build --chown=vapor:vapor /staging/bin/ ./

USER vapor

EXPOSE 8080

ENTRYPOINT ["./vapor-example"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
