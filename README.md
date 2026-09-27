# Basecraft Linux

[Deutsch](README.DE.md)

Basecraft Linux is an experimental Linux From Scratch based Linux system with a deliberately small build and package model.

The project started as a personal hobby and learning project on top of an installed Umbra Linux system. It is now evolving toward an **independent LFS-based Linux distribution**.

The long-term goal is a small live ISO that installs a minimal LFS base system first. After that, the user decides how the system should be extended:

```text
small Basecraft live ISO
        ↓
minimal LFS base system
        ↓
      bcraft
        ↓
   ┌────┴────┐
   ↓         ↓
binary       source
.bcraft      .src.bcraft
package      package
   ↓         ↓
install      build locally
   └────┬────┘
        ↓
individual Basecraft system
```

Both approaches are intended to be freely mixed. One package may be installed as a ready-made binary package while another is built locally from its source package.

Basecraft is not intended to reimplement RPM/DNF, dpkg/APT or pacman in full. The package model is deliberately kept small, transparent and close to the Linux From Scratch way of working.

Build recipes are considered at least as important as the package manager itself.

Basecraft Linux is an independent hobby and learning project and is not affiliated with Linux From Scratch or Umbra Linux.

## bcraft

`bcraft` is the build and package tool used by Basecraft Linux.

The current development state is based on `bcraft 0.6.0`.

Important commands:

```text
bcraft src-build [recipe-dir]
bcraft build <package.src.bcraft>

bcraft install [--nodeps] <package.bcraft>
bcraft update  [--nodeps] <package.bcraft>

bcraft remove <package>
bcraft list
bcraft info <package>

bcraft -v
bcraft -h
```

`bcraft` manages package metadata, installed files, configuration files and declared dependencies.

There is intentionally **no automatic dependency resolution**. Missing dependencies are detected and reported, but they are not downloaded or installed automatically.

For deliberate use on existing LFS/BLFS systems, `--nodeps` can be used to bypass dependency and normal installed-state checks and intentionally install or reinstall a package. Package structure, architecture, base and integrity checks remain independent of this option.

## Package formats

Since `bcraft 0.6.0`, Basecraft packages use their own clearly identifiable file extensions:

```text
foo-1.0-1.src.bcraft    source package
foo-1.0-1.bcraft        installable binary package
```

Internally both formats remain simple gzip-compressed tar archives. The dedicated extension identifies the purpose of the file without introducing an unnecessarily complex container format.

The basic build flow is:

```text
recipe directory
        ↓
bcraft src-build
        ↓
foo-1.0-1.src.bcraft
        ↓
bcraft build
        ↓
MANIFEST + PKGINFO
        ↓
foo-1.0-1.bcraft
        ↓
bcraft install
```

## Package recipes

A typical recipe contains at least:

```text
foo/
├── package.conf
└── build.sh
```

Optional files may include:

```text
foo/
├── package.conf
├── build.sh
├── patches/
├── files/
└── sources/
```

For software downloaded from an upstream project, `package.conf` may contain:

```bash
name="foo"
version="1.0"
release="1"

arch="x86_64"
base="basecraft-1"

description="Example package"
license="GPL-3.0-or-later"

source_mode="archive"

source_url="https://example.org/foo-1.0.tar.gz"
source_file="foo-1.0.tar.gz"
source_sha256="..."
```

Dependencies can be declared explicitly:

```bash
depends=(
    "libfoo"
    "ncurses"
)
```

During install and update, `bcraft` checks whether these packages are registered in its own package database. Dependencies are not installed automatically.

## Source packages with `src-build`

Source packages no longer need to be created manually with `tar`.

Instead, pass the recipe directory directly to `bcraft`:

```bash
bcraft src-build ./foo
```

This creates, for example:

```text
foo-1.0-1.src.bcraft
```

When creating a source package, remote sources may also use:

```bash
source_sha256="AUTO"
```

In this case, `bcraft src-build` downloads the source, calculates its SHA-256 checksum and writes the fixed hash **only to the copy of `package.conf` inside the generated source package**.

The original recipe remains unchanged.

A normal:

```bash
bcraft build foo-1.0-1.src.bcraft
```

does not accept `AUTO`. A source package must already contain fixed checksums when the actual build starts.

## Multiple sources

Since `bcraft 0.5.1`, a package may use multiple source files.

Example:

```bash
source_urls=(
    "https://example.org/foo-1.0.tar.xz"
    "https://example.org/foo-fix.patch"
)

source_files=(
    "foo-1.0.tar.xz"
    "foo-fix.patch"
)

source_sha256s=(
    "SHA256-OF-ARCHIVE"
    "SHA256-OF-PATCH"
)
```

Entries are associated by their array index.

Each source is verified separately with SHA-256. The first source is treated as the main source archive and is extracted automatically. Additional sources are made available unchanged in `SRCDIR` for use by the build script.

Example:

```bash
cd "$SRCDIR/foo-1.0"
patch -Np1 -i "$SRCDIR/foo-fix.patch"
```

For multi-source recipes, individual checksum entries may also use `AUTO` during `src-build`. The generated source package then contains only fixed hashes.

The original single-source format remains compatible.

## Build script

The build script installs into the package staging directory:

```bash
#!/bin/bash
set -euo pipefail

cd "$SRCDIR"

./configure --prefix=/usr

make -j"$JOBS"

make DESTDIR="$PKGDIR" install
```

The most important rule is:

> A package build must install everything into `$PKGDIR` and must not write directly to the running system.

If a package does not support `DESTDIR`, files can be installed explicitly into `$PKGDIR`:

```bash
install -Dm755 foo "$PKGDIR/usr/bin/foo"
```

`bcraft` then creates `MANIFEST` and `PKGINFO` automatically.

The manifest is not maintained manually.

See:

```bash
man bcraft
man 5 bcraft-recipe
```

for more information.

## Binary packages

A build produces, for example:

```text
foo-1.0-1.bcraft
```

The package contains:

```text
meta/
├── PKGINFO
└── MANIFEST

root/
├── etc/
└── usr/
```

Binary packages may deliberately be tied to a particular Basecraft base.

For example:

```text
base=basecraft-1
```

This avoids pretending that a package built against one glibc/GCC/libstdc++/Qt/Mesa environment is universally portable to unrelated LFS installations.

## Configuration files

Regular files installed below `/etc` are automatically considered configuration files.

Additional configuration files can be declared in `package.conf`:

```bash
config_files=(
    "opt/foo/settings.conf"
)
```

For configuration files, `bcraft` stores the SHA-256 checksum of the package version.

During an update:

```text
unchanged local configuration
    → replace with the new package version

locally modified configuration
    → preserve local file
    → install new version as .bcraft-new
```

For example:

```text
/etc/foo/foo.conf
/etc/foo/foo.conf.bcraft-new
```

## Installing and updating packages

A new package is installed normally:

```bash
bcraft install foo-1.0-1.bcraft
```

Since `bcraft 0.6.0`, `install` detects when an older version of the same package is already installed.

Example:

```text
installed: foo 1.0-1
provided:  foo 1.1-1
```

`bcraft install foo-1.1-1.bcraft` then interactively offers to update the installed package.

On an English-language system the prompt is:

```text
Do you want to update the installed package? [y/N]
```

The German variant uses:

```text
Möchten Sie das bereits installierte Paket aktualisieren? [j/N]
```

When confirmed, `install` uses the same update code path as the explicit command:

```bash
bcraft update foo-1.1-1.bcraft
```

`update` therefore remains available for scripts and for deliberate, explicit package updates.

The normal `install` behaviour is:

```text
package not installed
    → install

same version installed
    → report as already installed

older version installed
    → offer update

newer version installed
    → refuse downgrade
```

Version comparison considers `version` first and then `release`, using natural numeric segment comparison so that, for example, `1.10` is newer than `1.9`.

The term `upgrade` is still not used by `bcraft` for normal package updates. It remains reserved for a possible future change of the complete Basecraft base, for example:

```text
basecraft-1 → basecraft-2
```

## Basecraft as a distribution

The current Basecraft state is still experimental and currently relies on an existing LFS/Umbra-style system for early testing.

The intended direction goes beyond that.

The goal is a small **Basecraft live ISO** that installs a minimal, defined LFS base system onto a target machine. After this bootstrap, `bcraft` takes over the further expansion of the system.

The user should then be free to choose between:

```text
installing a ready-made .bcraft package
or
building a .src.bcraft package locally and installing the result
```

A mixed system is explicitly intended.

The live ISO is therefore not meant to ship a large software selection. Its purpose is to provide a small and reproducible starting point.

## Bootstrapping Basecraft on an existing LFS/Umbra system

Until a standalone live ISO is available, Basecraft can continue to be bootstrapped on an already installed Umbra/LFS system.

This uses a suitable `bcraft-bootstrap` together with the required Basecraft source packages.

The current package naming scheme is, for example:

```text
bcraft-0.6.0-1.src.bcraft
basecraft-release-1-3.src.bcraft
```

A source package can be built with:

```bash
sudo ./bcraft-bootstrap build \
    basecraft-release-1-3.src.bcraft
```

The resulting installable package can then be installed with `bcraft-bootstrap install`.

After that, `bcraft` itself can be built and installed.

Verify the installation with:

```bash
bcraft -v
bcraft list
bcraft info bcraft
cat /etc/basecraft-release
```

`--nodeps` is useful here as an explicit escape hatch when software exists on an established LFS system but has not yet been registered in the bcraft package database.

## Example: JOE

The recipe under `examples/joe` demonstrates how an LFS/BLFS-style build procedure can be translated into a `bcraft` recipe.

Create the source package:

```bash
bcraft src-build examples/joe
```

This creates, for example:

```text
joe-4.8-1.src.bcraft
```

Build it:

```bash
sudo bcraft build joe-4.8-1.src.bcraft
```

This produces:

```text
/var/cache/basecraft/packages/joe-4.8-1.bcraft
```

Install it:

```bash
sudo bcraft install \
    /var/cache/basecraft/packages/joe-4.8-1.bcraft
```

A later version can be created and built from an updated recipe.

It can then either be updated explicitly:

```bash
sudo bcraft update \
    /var/cache/basecraft/packages/joe-NEWVERSION-1.bcraft
```

or passed to `install`, which will offer the update interactively.

## Creating packages from LFS/BLFS instructions

The intended workflow remains deliberately simple.

Take the relevant LFS or BLFS commands and place the build steps into `build.sh`.

For example:

```text
./configure --prefix=/usr
make
make install
```

normally becomes:

```bash
./configure --prefix=/usr
make -j"$JOBS"
make DESTDIR="$PKGDIR" install
```

See:

```bash
man 5 bcraft-recipe
```

for the complete recipe documentation.

## Trust model

Source packages contain executable shell build recipes.

Do not build source packages from untrusted sources.

The current implementation is deliberately simple and does not currently provide build sandboxing or cryptographic package signatures.

Builds currently use system directories below `/var/lib/basecraft` and `/var/cache/basecraft`, so typical bootstrap and build usage is currently performed as root.

## What Basecraft does not currently provide

Basecraft deliberately does not currently provide:

```text
automatic dependency resolution
SAT solving
repository transactions
package signing
rollback
sandboxed builds
multi-user package databases
large repository infrastructure
```

These are not accidental omissions. Basecraft is intended to remain understandable and to leave the user in control of which software is installed as a binary package and which is built locally.

## Status and roadmap

Basecraft should still be considered **experimental**.

The current state includes, among other things:

```text
bootstrap on an existing LFS/Umbra system
source and binary packages with dedicated .bcraft extensions
reproducible source package creation with bcraft src-build
single- and multi-source recipes
SHA-256 verification of sources
declared package dependencies
explicit bypass through --nodeps
package installation and updates
preservation of locally modified configuration files
bcraft can update itself using bcraft
```

The next major development direction is the transition from this package and build layer toward a small standalone Basecraft Linux distribution with a live ISO and a defined LFS base system.

The project remains a hobby and learning project.

## Project

GitHub:

https://github.com/mawe777/basecraft-linux

## License

Basecraft's own code and documentation are licensed under:

```text
GPL-3.0-or-later
```

Copyright © 2026 Marco Welter  
<mawe@tamaly.de>

Upstream software packaged by Basecraft retains its own respective license.
