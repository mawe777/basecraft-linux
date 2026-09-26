#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Marco Welter <mawe@tamaly.de>

set -euo pipefail

install -Dm644 \
    "$RECIPE_DIR/files/basecraft-release" \
    "$PKGDIR/etc/basecraft-release"

install -Dm644 \
    "$RECIPE_DIR/COPYING" \
    "$PKGDIR/usr/share/licenses/basecraft-release/COPYING"
