#!/bin/bash
set -euo pipefail

cd "$SRCDIR"

./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
    --docdir="/usr/share/doc/${PKGNAME}-${PKGVER}"

make -j"$JOBS"

make DESTDIR="$PKGDIR" install

install -vd "$PKGDIR/usr/bin"

install -vm755 \
    joe/util/stringify \
    joe/util/termidx \
    joe/util/uniproc \
    "$PKGDIR/usr/bin/"
