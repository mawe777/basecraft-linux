# Basecraft Linux

[Deutsch](README.DE.md)


Basecraft Linux is a small experimental build and binary package layer for Linux From Scratch based systems.

It started as a personal project on top of an installed Umbra Linux (https://umbralinux.org) system. The goal is not to create another full distribution package manager and not to replace tools such as RPM/DNF, dpkg/APT or pacman.

Instead, Basecraft focuses on a much smaller model:

```text
Source
  ↓
package recipe
  ↓
build.sh
  ↓
PKGDIR / DESTDIR
  ↓
MANIFEST + PKGINFO
  ↓
binary .tar.gz package
```

The build recipes are considered more important than the package manager itself.

Basecraft Linux is an independent hobby and learning project and is not affiliated with the Linux From Scratch project or Umbra Linux.

## bcraft

`bcraft` is the package tool used by Basecraft.

Current commands:

```text
bcraft build <package.src.tar.gz>
bcraft install <package.tar.gz>
bcraft update <package.tar.gz>
bcraft remove <package>
bcraft list
bcraft info <package>

bcraft -v
bcraft -h
```

There is intentionally no automatic dependency solver.

There are also no SAT transactions or large repository infrastructure.

## Package model

A typical source recipe consists of:

```text
foo/
├── package.conf
└── build.sh
```

Optional files include:

```text
foo/
├── package.conf
├── build.sh
├── patches/
└── files/
```

For software downloaded from upstream, `package.conf` contains information such as:

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

The build script installs into the package staging directory:

```bash
#!/bin/bash
set -euo pipefail

cd "$SRCDIR"

./configure --prefix=/usr

make -j"$JOBS"

make DESTDIR="$PKGDIR" install
```

`bcraft` then creates the package manifest and metadata automatically.

The package author does not maintain the manifest manually.

See:

```bash
man bcraft
man 5 bcraft-recipe
```

for more information.

## Binary packages

A build produces a binary package such as:

```text
foo-1.0-1-x86_64.tar.gz
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

This avoids pretending that packages built against one glibc/GCC/libstdc++/Qt/Mesa environment are universally portable to unrelated LFS installations.

## Configuration files

Regular files installed below `/etc` are automatically considered configuration files.

Additional configuration files can be declared in `package.conf`:

```bash
config_files=(
    "opt/foo/settings.conf"
)
```

For configuration files, bcraft stores the package version's SHA-256 checksum.

During an update:

```text
unchanged local configuration
    → replace with new package version

locally modified configuration
    → preserve local file
    → install new version as .bcraft-new
```

For example:

```text
/etc/foo/foo.conf
/etc/foo/foo.conf.bcraft-new
```

## Updating packages

An installed package can be updated with:

```bash
bcraft update foo-1.1-1-x86_64.tar.gz
```

Files still present in the new package are replaced.

Files removed from the new package are removed from the system.

Modified configuration files are preserved.

The word `upgrade` is intentionally not currently used by bcraft. It is reserved for a possible future Basecraft base upgrade, for example:

```text
basecraft-1 → basecraft-2
```

## Bootstrapping Basecraft on an Umbra/LFS system

A clean Umbra Linux or compatible LFS-style installation does not initially contain bcraft or `/etc/basecraft-release`.

Three files are sufficient to bootstrap the system:

```text
bcraft-bootstrap
bcraft-0.4.0-3.src.tar.gz
basecraft-release-1-3.src.tar.gz
```

The bootstrap file is simply a standalone copy of the current bcraft program.

Make it executable:

```bash
chmod +x bcraft-bootstrap
```

Build the Basecraft release package:

```bash
sudo ./bcraft-bootstrap build \
    basecraft-release-1-3.src.tar.gz
```

Install it:

```bash
sudo ./bcraft-bootstrap install \
    /var/cache/basecraft/packages/basecraft-release-1-3-any.tar.gz
```

The system now contains:

```text
/etc/basecraft-release
```

with:

```text
basecraft-1
```

Next build bcraft itself:

```bash
sudo ./bcraft-bootstrap build \
    bcraft-0.4.0-3.src.tar.gz
```

Install it:

```bash
sudo ./bcraft-bootstrap install \
    /var/cache/basecraft/packages/bcraft-0.4.0-3-any.tar.gz
```

Refresh the shell command cache if necessary:

```bash
hash -r
```

Verify the installation:

```bash
bcraft -v
bcraft list
bcraft info bcraft
cat /etc/basecraft-release
```

The temporary bootstrap copy is no longer required.

## Example: JOE

The `examples/joe` recipe demonstrates converting an LFS/BLFS-style build procedure into a bcraft recipe.

Create a source package:

```bash
tar -czf joe-4.8-1.src.tar.gz joe/
```

Build it:

```bash
sudo bcraft build joe-4.8-1.src.tar.gz
```

This produces:

```text
/var/cache/basecraft/packages/joe-4.8-1-x86_64.tar.gz
```

Install it:

```bash
sudo bcraft install \
    /var/cache/basecraft/packages/joe-4.8-1-x86_64.tar.gz
```

Later versions can be built from a revised recipe and installed with:

```bash
sudo bcraft update \
    /var/cache/basecraft/packages/joe-NEWVERSION-1-x86_64.tar.gz
```

## Creating packages from LFS/BLFS instructions

The intended workflow is deliberately simple.

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

If a package does not support DESTDIR, files can instead be installed explicitly:

```bash
install -Dm755 foo "$PKGDIR/usr/bin/foo"
```

The important rule is:

> A package build must install everything into `$PKGDIR`, not directly into the running system.

After that, bcraft generates MANIFEST and PKGINFO automatically.

See:

```bash
man 5 bcraft-recipe
```

for the complete recipe documentation.

## Trust model

Source packages contain executable shell build recipes.

Do not build source packages from untrusted sources.

The current implementation is intentionally simple and does not provide sandboxing or cryptographic package signing.

Builds currently use system directories below `/var/lib/basecraft` and `/var/cache/basecraft`, so typical bootstrap usage is performed as root.

## What Basecraft does not currently provide

Basecraft deliberately does not provide:

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

These are not accidental omissions. The current goal is to keep the system understandable and useful for a small controlled LFS-based installation.

## Status

Basecraft should currently be considered experimental.

It has been used to:

```text
bootstrap bcraft on an installed Umbra Linux system
build and install JOE
build a newer JOE version
update JOE without rebuilding the operating system
update bcraft using bcraft itself
preserve modified configuration files during package updates
```

It is primarily a hobby and learning project.

## License

Basecraft's own code and documentation are licensed under:

```text
GPL-3.0-or-later
```

Copyright © 2026 Marco Welter  
<mawe@tamaly.de>

Upstream software packaged by Basecraft retains its own respective license.
