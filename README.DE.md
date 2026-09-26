# Basecraft Linux

[English](README.md)

Basecraft Linux ist eine kleine experimentelle Build- und Binärpaket-Schicht für Linux-From-Scratch-basierte Systeme.

Das Projekt entstand als persönliches Hobby- und Lernprojekt auf einem installierten Umbra-Linux-System. Ziel ist ausdrücklich **nicht**, einen vollständigen Paketmanager wie RPM/DNF, dpkg/APT oder pacman nachzubauen.

Stattdessen konzentriert sich Basecraft auf ein bewusst kleines Modell:

```text
Source
  ↓
Paket-Rezept
  ↓
build.sh
  ↓
PKGDIR / DESTDIR
  ↓
MANIFEST + PKGINFO
  ↓
Binärpaket als .tar.gz
```

Die Build-Rezepte sind dabei wichtiger als der Paketmanager selbst.

Basecraft Linux ist ein unabhängiges Hobby- und Lernprojekt und nicht mit Linux From Scratch oder Umbra Linux verbunden.

## bcraft

`bcraft` ist das Paketwerkzeug von Basecraft.

Aktuelle Befehle:

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

Es gibt bewusst keine automatische Dependency-Auflösung.

Ebenso gibt es keine SAT-Transaktionen und keine große Repository-Infrastruktur.

## Paketmodell

Ein typisches Source-Rezept besteht aus:

```text
foo/
├── package.conf
└── build.sh
```

Optional können weitere Dateien enthalten sein:

```text
foo/
├── package.conf
├── build.sh
├── patches/
└── files/
```

Für Software, die von einem Upstream-Projekt heruntergeladen wird, enthält `package.conf` zum Beispiel:

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

Das Build-Skript installiert zunächst in das Paket-Staging-Verzeichnis:

```bash
#!/bin/bash
set -euo pipefail

cd "$SRCDIR"

./configure --prefix=/usr

make -j"$JOBS"

make DESTDIR="$PKGDIR" install
```

Anschließend erzeugt `bcraft` automatisch Manifest und Metadaten.

Das Manifest wird nicht von Hand gepflegt.

Weitere Informationen:

```bash
man bcraft
man 5 bcraft-recipe
```

## Binärpakete

Ein Build erzeugt beispielsweise:

```text
foo-1.0-1-x86_64.tar.gz
```

Das Paket enthält:

```text
meta/
├── PKGINFO
└── MANIFEST

root/
├── etc/
└── usr/
```

Binärpakete dürfen bewusst an eine bestimmte Basecraft-Basis gebunden sein.

Zum Beispiel:

```text
base=basecraft-1
```

Damit wird nicht behauptet, dass ein gegen eine bestimmte glibc-/GCC-/libstdc++-/Qt-/Mesa-Umgebung gebautes Paket universell auf beliebigen LFS-Systemen lauffähig ist.

## Konfigurationsdateien

Reguläre Dateien unterhalb von `/etc` gelten automatisch als Konfigurationsdateien.

Zusätzliche Konfigurationsdateien können in `package.conf` angegeben werden:

```bash
config_files=(
    "opt/foo/settings.conf"
)
```

Für Konfigurationsdateien speichert `bcraft` die SHA-256-Prüfsumme der Paketversion.

Bei einem Update gilt:

```text
lokale Konfiguration unverändert
    → durch neue Paketversion ersetzen

lokale Konfiguration verändert
    → lokale Datei erhalten
    → neue Version als .bcraft-new ablegen
```

Beispiel:

```text
/etc/foo/foo.conf
/etc/foo/foo.conf.bcraft-new
```

## Pakete aktualisieren

Ein bereits installiertes Paket kann aktualisiert werden mit:

```bash
bcraft update foo-1.1-1-x86_64.tar.gz
```

Dateien, die weiterhin zum Paket gehören, werden ersetzt.

Dateien, die in der neuen Paketversion nicht mehr enthalten sind, werden entfernt.

Veränderte Konfigurationsdateien bleiben erhalten.

Der Begriff `upgrade` wird von `bcraft` bewusst noch nicht verwendet. Er ist für einen möglichen späteren Wechsel der Basecraft-Basis reserviert, zum Beispiel:

```text
basecraft-1 → basecraft-2
```

## Basecraft auf einem Umbra-/LFS-System initialisieren

Ein frisches Umbra-Linux- oder vergleichbares LFS-System enthält zunächst weder `bcraft` noch `/etc/basecraft-release`.

Für den Bootstrap genügen:

```text
bcraft-bootstrap
bcraft-0.4.0-3.src.tar.gz
basecraft-release-1-3.src.tar.gz
```

Die Bootstrap-Datei ist lediglich eine eigenständige Kopie des aktuellen `bcraft`-Programms.

Ausführbar machen:

```bash
chmod +x bcraft-bootstrap
```

Zunächst das Basecraft-Release-Paket bauen:

```bash
sudo ./bcraft-bootstrap build \
    basecraft-release-1-3.src.tar.gz
```

Dann installieren:

```bash
sudo ./bcraft-bootstrap install \
    /var/cache/basecraft/packages/basecraft-release-1-3-any.tar.gz
```

Danach existiert:

```text
/etc/basecraft-release
```

mit:

```text
basecraft-1
```

Anschließend `bcraft` selbst bauen:

```bash
sudo ./bcraft-bootstrap build \
    bcraft-0.4.0-3.src.tar.gz
```

und installieren:

```bash
sudo ./bcraft-bootstrap install \
    /var/cache/basecraft/packages/bcraft-0.4.0-3-any.tar.gz
```

Falls nötig, den Shell-Command-Cache aktualisieren:

```bash
hash -r
```

Installation prüfen:

```bash
bcraft -v
bcraft list
bcraft info bcraft
cat /etc/basecraft-release
```

Die temporäre Bootstrap-Kopie wird danach nicht mehr benötigt.

## Beispiel: JOE

Das Rezept unter `examples/joe` zeigt, wie eine LFS-/BLFS-artige Build-Anleitung in ein `bcraft`-Rezept übertragen werden kann.

Source-Paket erzeugen:

```bash
tar -czf joe-4.8-1.src.tar.gz joe/
```

Bauen:

```bash
sudo bcraft build joe-4.8-1.src.tar.gz
```

Dadurch entsteht:

```text
/var/cache/basecraft/packages/joe-4.8-1-x86_64.tar.gz
```

Installieren:

```bash
sudo bcraft install \
    /var/cache/basecraft/packages/joe-4.8-1-x86_64.tar.gz
```

Eine spätere Version kann aus einem angepassten Rezept gebaut und anschließend aktualisiert werden:

```bash
sudo bcraft update \
    /var/cache/basecraft/packages/joe-NEWVERSION-1-x86_64.tar.gz
```

## Pakete aus LFS-/BLFS-Anleitungen erstellen

Der vorgesehene Ablauf ist bewusst einfach.

Die relevanten LFS-/BLFS-Befehle werden in `build.sh` übernommen.

Aus:

```text
./configure --prefix=/usr
make
make install
```

wird typischerweise:

```bash
./configure --prefix=/usr
make -j"$JOBS"
make DESTDIR="$PKGDIR" install
```

Unterstützt ein Paket kein `DESTDIR`, können Dateien explizit nach `$PKGDIR` installiert werden:

```bash
install -Dm755 foo "$PKGDIR/usr/bin/foo"
```

Die wichtigste Regel lautet:

> Ein Paket-Build muss alles in `$PKGDIR` installieren und darf nicht direkt in das laufende System schreiben.

Danach erzeugt `bcraft` automatisch `MANIFEST` und `PKGINFO`.

Die vollständige Rezept-Dokumentation befindet sich in:

```bash
man 5 bcraft-recipe
```

## Vertrauensmodell

Source-Pakete enthalten ausführbaren Shell-Code in ihren Build-Rezepten.

Source-Pakete aus nicht vertrauenswürdigen Quellen sollten daher nicht gebaut werden.

Die aktuelle Implementierung ist bewusst einfach und bietet derzeit weder Build-Sandboxing noch kryptographische Paketsignaturen.

Builds verwenden aktuell Systemverzeichnisse unter `/var/lib/basecraft` und `/var/cache/basecraft`. Der typische Bootstrap- und Build-Ablauf wird deshalb derzeit als `root` ausgeführt.

## Was Basecraft derzeit bewusst nicht anbietet

Basecraft bietet aktuell nicht:

```text
automatische Dependency-Auflösung
SAT-Solver
Repository-Transaktionen
Paketsignaturen
Rollback
Build-Sandboxing
Multi-User-Paketdatenbanken
große Repository-Infrastruktur
```

Diese Punkte fehlen nicht versehentlich. Ziel des aktuellen Systems ist es, klein, nachvollziehbar und für ein kontrolliertes LFS-basiertes System praktisch nutzbar zu bleiben.

## Status

Basecraft sollte derzeit als experimentell betrachtet werden.

Getestet wurden unter anderem:

```text
Bootstrap von bcraft auf einem installierten Umbra-Linux-System
JOE bauen und installieren
eine neuere JOE-Version bauen
JOE ohne Neuinstallation des Systems aktualisieren
bcraft mit bcraft selbst aktualisieren
veränderte Konfigurationsdateien bei Updates erhalten
```

Das Projekt ist in erster Linie ein Hobby- und Lernprojekt.

## Projekt

GitHub:

https://github.com/mawe777/basecraft-linux

## Lizenz

Der eigene Code und die Dokumentation von Basecraft stehen unter:

```text
GPL-3.0-or-later
```

Copyright © 2026 Marco Welter  
<mawe@tamaly.de>

Von Basecraft paketierte Upstream-Software behält selbstverständlich ihre jeweilige eigene Lizenz.
