#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Marco Welter <mawe@tamaly.de>

set -euo pipefail

install -Dm755 \
    "$RECIPE_DIR/files/bcraft" \
    "$PKGDIR/usr/bin/bcraft"

install -Dm644 \
    "$RECIPE_DIR/files/bcraft.1" \
    "$PKGDIR/usr/share/man/man1/bcraft.1"

install -Dm644 \
    "$RECIPE_DIR/files/bcraft.de.1" \
    "$PKGDIR/usr/share/man/de/man1/bcraft.1"

install -Dm644 \
    "$RECIPE_DIR/files/bcraft-recipe.5" \
    "$PKGDIR/usr/share/man/man5/bcraft-recipe.5"

install -Dm644 \
    "$RECIPE_DIR/files/bcraft-recipe.de.5" \
    "$PKGDIR/usr/share/man/de/man5/bcraft-recipe.5"

install -Dm644 \
    "$RECIPE_DIR/COPYING" \
    "$PKGDIR/usr/share/licenses/bcraft/COPYING"
