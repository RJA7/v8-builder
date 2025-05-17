#!/bin/bash
set -e

VERSION=$1  # e.g., 135.0.7049.79

# ✅ Install required host tools
sudo apt-get update
sudo apt-get install -y \
    pkg-config git subversion curl wget \
    build-essential python3 python3-pip \
    xz-utils zip ninja-build

# ✅ Git config for gclient
git config --global user.name "V8 Android Builder"
git config --global user.email "v8.android.builder@localhost"
git config --global core.autocrlf false
git config --global core.filemode false
git config --global color.ui true

# ✅ Clone depot_tools
cd ~
echo "=====[ Getting Depot Tools ]====="
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PWD/depot_tools:$PATH"
export DEPOT_TOOLS_WIN_TOOLCHAIN=0
export GYP_GENERATORS=ninja

# ✅ Create workspace and fetch V8
mkdir -p v8_source && cd v8_source
fetch v8
echo "target_os = ['android']" >> .gclient
cd v8

# ✅ Checkout specific version
git checkout "$VERSION"
gclient sync --with_branch_heads --no-history --force --reset

# ✅ Set up build output dir
mkdir -p out.gn/arm64.release

# ✅ Final GN args for minimal static Android build
gn gen out.gn/arm64.release --args='
target_os = "android"
target_cpu = "arm64"
v8_target_cpu = "arm64"

v8_enable_i18n_support = true

# ✅ Official and PGO flags (IMPORTANT FIX)
is_debug = false
is_component_build = false
is_official_build = false  # ⚠️ Must be false to prevent PGO
v8_enable_pgo = false      # Prevent any pgo-related GN logic
v8_enable_pgo_generate = false
v8_enable_pgo_use = false
enable_resource_allowlist_generation = false

# ✅ Optimization & stripping
symbol_level = 0
strip_debug_info = true
use_lld = true
use_rtti = false
use_exceptions = false
use_thin_archives = true

# ✅ Static build mode
v8_monolithic = true
v8_static_library = true
use_custom_libcxx = false

# ✅ Disable all unneeded features
v8_enable_future = false
v8_use_external_startup_data = false
v8_enable_webassembly = false
v8_enable_gdbjit = false
v8_enable_disassembler = false
v8_enable_v8_checks = false
v8_enable_debugging_features = false
v8_enable_test_features = false
v8_enable_object_print = false
v8_enable_verify_heap = false
v8_enable_handle_zapping = false
v8_enable_third_party_heap = false
v8_enable_conservative_stack_scanning = false
v8_enable_shared_ro_heap = false
v8_deprecation_warnings = false
v8_enable_inspector = false
'

# ✅ Clean + build
ninja -C out.gn/arm64.release -t clean
ninja -C out.gn/arm64.release v8_monolith

# ✅ Optional: copy output to structured directory
mkdir -p ~/v8_output/lib
mkdir -p ~/v8_output/include

cp out.gn/arm64.release/obj/libv8_monolith.a ~/v8_output/lib/
cp -r include/* ~/v8_output/include/

echo "✅ V8 build complete!"
