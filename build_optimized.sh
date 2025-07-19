#!/bin/bash

echo "🚀 Optimized Build with Advanced Flags"

# Use all available CPU cores
CORES=$(sysctl -n hw.logicalcpu)
echo "Using $CORES CPU cores for parallel compilation"

# Optimized Swift build with advanced flags
swift build \
    --configuration release \
    --jobs $CORES \
    -Xswiftc -O \
    -Xswiftc -whole-module-optimization \
    -Xswiftc -enable-batch-mode \
    -Xswiftc -index-store-path -Xswiftc .build/index-store \
    -Xswiftc -suppress-warnings \
    -Xswiftc -enable-experimental-feature -Xswiftc StrictConcurrency \
    "$@"
