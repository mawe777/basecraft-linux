# bcraft 0.6.0-1

## Package file format names

bcraft packages now use explicit bcraft filename suffixes:

- `name-version-release.src.bcraft` for source packages
- `name-version-release.bcraft` for installable packages

Both remain gzip-compressed tar archives internally. bcraft validates package contents and metadata and does not trust the filename suffix alone.

`bcraft src-build` creates `.src.bcraft` files and `bcraft build` consumes them and creates `.bcraft` packages.

## Smart install / update handoff

`bcraft install package.bcraft` now checks an already installed package of the same name:

- not installed: normal installation
- same version and release: aborts as already installed
- newer supplied package: asks whether to update; on confirmation the existing `update` implementation is used
- older supplied package: downgrade is refused

The interactive question is English by default and German for a German locale. The default answer is No.

The explicit `bcraft update package.bcraft` command remains available for deliberate updates and scripts.

Version and release comparisons use natural numeric/alphabetic segments, so e.g. `1.10` sorts newer than `1.9`; release is compared only when version is equal.

## Compatibility

The archive implementation remains tar+gzip. Existing 0.5.x functionality including dependencies, `--nodeps`, multi-source recipes, `src-build`, `AUTO` checksum resolution, manifests and configuration-file handling is retained.

## Documentation

English and German `bcraft(1)` and `bcraft-recipe(5)` manual pages were updated for bcraft 0.6.0 and the new package suffixes/install behavior.




-----------------



# bcraft 0.5.2-1

## New: `bcraft src-build [recipe-dir]`

`src-build` creates a bcraft source package directly from a recipe directory. If no directory is supplied, the current directory is used. The directory must contain at least `package.conf` and `build.sh`.

The generated source package is named `<name>-<version>-<release>.src.tar.gz`.

## `source_sha256="AUTO"`

For `source_mode="archive"`, recipe authors may use:

```bash
source_sha256="AUTO"
```

When `src-build` sees `AUTO`, it downloads `source_url`/`source_file`, calculates SHA-256, and writes the fixed checksum only into the temporary `package.conf` copy stored in the generated source package. The original recipe remains unchanged.

Multi-source recipes are supported as well: individual entries in `source_sha256s=(...)` may be `AUTO` and are resolved independently. Existing fixed checksums are preserved.

`AUTO` is deliberately rejected by normal `bcraft build`. A buildable SRC package must contain fixed 64-digit SHA-256 checksums. `AUTO` is also rejected for `source_mode="local"`.

## Compatibility

Existing source packages and recipes with fixed SHA-256 checksums remain compatible. Multi-source support from bcraft 0.5.1 is unchanged.

## Documentation

Updated:

- `bcraft(1)` English and German
- `bcraft-recipe(5)` English and German




-----------------



# bcraft 0.5.1-1

## Multiple source support

bcraft 0.5.1 extends source handling while retaining compatibility with existing single-source recipes.

### Remote multiple sources

New recipes can use parallel arrays:

```bash
source_mode="archive"
source_urls=(
    "https://example.org/foo-1.0.tar.xz"
    "https://example.org/foo-fix.patch"
)
source_files=(
    "foo-1.0.tar.xz"
    "foo-fix.patch"
)
source_sha256s=(
    "..."
    "..."
)
```

Each source is downloaded and SHA-256 verified individually. The first source is the primary archive and is extracted automatically. Additional sources are not unpacked; they are copied into `SRCDIR` under their declared filenames.

### Local multiple sources

Sources bundled in the bcraft source package can use:

```bash
source_mode="local"
source_files=("foo-1.0.tar.xz" "foo-fix.patch")
source_sha256s=("..." "...")
```

The files must be stored in the recipe's `sources/` directory. They receive the same checksum and primary-source handling as remote sources.

### Compatibility

The existing single-source format remains supported unchanged:

```bash
source_mode="archive"
source_url="https://example.org/foo-1.0.tar.xz"
source_file="foo-1.0.tar.xz"
source_sha256="..."
```

`source_mode="recipe"` also remains supported.

### Documentation

The English and German `bcraft-recipe(5)` manual pages document multi-source and local-source recipes. The bcraft version is 0.5.1 and the package release is 1.

### Tests performed

- shell syntax validation
- multi-source local build
- multi-source HTTP download build
- per-source SHA-256 verification
- primary archive extraction
- additional source availability in `SRCDIR`
- legacy single-source archive compatibility
