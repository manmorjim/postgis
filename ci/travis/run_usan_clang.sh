#!/usr/bin/env bash
set -e

# Enable undefined behaviour sanitizer using traps
CFLAGS_USAN="-g3 -O0 -mtune=generic -fno-omit-frame-pointer -fsanitize=undefined,implicit-conversion -fsanitize-undefined-trap-on-error -fno-sanitize-recover=implicit-conversion"
LDFLAGS_STD="-Wl,-Bsymbolic-functions -Wl,-z,relro -fsanitize=undefined,implicit-conversion -fsanitize-undefined-trap-on-error -fno-sanitize-recover=implicit-conversion"

# Sanitizer options to continue avoid stopping the runs on leaks (expected on postgres binaries)
export ASAN_OPTIONS=halt_on_error=false,leak_check_at_exit=false,exitcode=0
export MSAN_OPTIONS=halt_on_error=false,leak_check_at_exit=false,exitcode=0

#Run postgres preloading sanitizer libs
LD_PRELOAD=/usr/lib/clang/8/lib/linux/libclang_rt.asan-x86_64.so /usr/local/pgsql/bin/pg_ctl -c -l /tmp/logfile start


# Build with Clang and usan flags
./autogen.sh
./configure --enable-debug CC=clang CFLAGS="${CFLAGS_USAN}" LDFLAGS="${LDFLAGS_STD}"
bash ./ci/travis/logbt -- make -j check RUNTESTFLAGS=--verbose
