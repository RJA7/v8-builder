VERSION=$1

sudo apt-get install -y \
    pkg-config \
    git \
    subversion \
    curl \
    wget \
    build-essential \
    python \
    xz-utils \
    zip

git config --global user.name "V8 Android Builder"
git config --global user.email "v8.android.builder@localhost"
git config --global core.autocrlf false
git config --global core.filemode false
git config --global color.ui true


cd ~
echo "=====[ Getting Depot Tools ]====="	
git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH=$(pwd)/depot_tools:$PATH
gclient


mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
fetch v8
echo "target_os = ['android']" >> .gclient
cd ~/v8/v8
./build/install-build-deps-android.sh
git checkout $VERSION
gclient sync


echo "=====[ Building V8 ]====="
python ./tools/dev/v8gen.py arm64.release -vv -- '
target_os = "android"
target_cpu = "arm64"
v8_target_cpu = "arm64"
enable_resource_allowlist_generation  = false

is_debug = false
is_component_build = false
is_official_build = true
symbol_level = 0
strip_debug_info = true
use_lld = true
use_rtti = false
use_exceptions = false

v8_monolithic = true
v8_static_library = true
use_custom_libcxx = false
use_thin_archives = true

v8_enable_pgo_generate = false
v8_enable_future = false
v8_use_external_startup_data = false
v8_enable_i18n_support = true
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
ninja -C out.gn/arm64.release -t clean
ninja -C out.gn/arm64.release v8_libplatform
ninja -C out.gn/arm64.release v8
cp ./third_party/android_ndk/sources/cxx-stl/llvm-libc++/libs/arm64-v8a/libc++_shared.so ./out.gn/arm64.release