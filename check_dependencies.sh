#!/bin/sh

MISSING=""
FOUND=""
checkdep() {
    local exe="$1" package="$2" upstream="$3"
    if command -v "$1" >/dev/null 2>&1; then
        FOUND="${FOUND:+${FOUND} }$exe"
        return "0"
    fi
    MISSING=${MISSING:+${MISSING }$package}
    echo "missing $exe."
    echo "  It can be installed in package: $package"
    [ -n "$upstream" ] &&
        echo "  Upstream project url: $upstream"
    return 1
}

checkdep cloud-localds cloud-image-utils http://launchpad.net/cloud-utils
# checkdep genisoimage genisoimage
checkdep qemu-img qemu-utils http://qemu.org/
# checkdep qemu-system-x86_64 qemu-system-x86 http://qemu.org/
checkdep wget wget

if [ -n "$MISSING" ]; then
    echo
    [ -n "${FOUND}" ] && echo "found: ${FOUND}"
    echo "install missing deps with:"
    echo "  apt-get update && apt-get install ${MISSING}"
else
    echo "All good. (${FOUND})"
fi

# vi: ts=4 expandtab
