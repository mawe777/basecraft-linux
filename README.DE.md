# Basecraft Linux

[English](README.md)

Basecraft Linux ist ein experimentelles, Linux-From-Scratch-basiertes Linux-System mit einem bewusst kleinen Build- und Paketmodell.

Das Projekt entstand als persönliches Hobby- und Lernprojekt auf einem installierten Umbra-Linux-System. Inzwischen entwickelt sich Basecraft Linux in Richtung einer **eigenständigen LFS-basierten Distribution**.

Das langfristige Ziel ist eine kleine Live-ISO, mit der zunächst ein minimales LFS-Basissystem installiert werden kann. Danach entscheidet der Anwender selbst, wie das System erweitert wird:

```text
kleine Basecraft Live-ISO
        ↓
minimales LFS-Basissystem
        ↓
      bcraft
        ↓
   ┌────┴────┐
   ↓         ↓
Binärpaket   Source-Paket
.bcraft      .src.bcraft
   ↓         ↓
installieren selbst bauen
   └────┬────┘
        ↓
individuelles Basecraft-System
```

Beide Wege sollen sich beliebig kombinieren lassen. Ein Paket kann als fertiges Binärpaket installiert werden, während ein anderes lokal aus dem Source-Paket gebaut wird.

Basecraft soll dabei nicht versuchen, RPM/DNF, dpkg/APT oder pacman vollständig nachzubauen. Das Paketmodell bleibt bewusst klein, transparent und nah an der Arbeitsweise von Linux From Scratch.

Die Build-Rezepte sind dabei mindestens ebenso wichtig wie der Paketmanager selbst.

Basecraft Linux ist ein unabhängiges Hobby- und Lernprojekt und nicht mit Linux From Scratch oder Umbra Linux verbunden.

## bcraft

`bcraft` ist das Build- und Paketwerkzeug von Basecraft Linux.

Der aktuelle Entwicklungsstand basiert auf `bcraft 0.6.0`.

Wichtige Befehle:

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

`bcraft` verwaltet Paketmetadaten, Dateien, Konfigurationsdateien und deklarierte Abhängigkeiten.

Es gibt bewusst **keine automatische Dependency-Auflösung**. Fehlende Abhängigkeiten werden erkannt und gemeldet, aber nicht automatisch heruntergeladen oder installiert.

Für bewusstes Arbeiten auf bereits bestehenden LFS-/BLFS-Systemen kann `--nodeps` verwendet werden. Damit werden die Dependency-Prüfung und die normale Bestandsprüfung übersprungen und das Paket wird bewusst installiert bzw. erneut installiert. Prüfungen wie Paketstruktur, Architektur, Base und Integrität bleiben davon unabhängig.

## Paketformate

Seit `bcraft 0.6.0` besitzen Basecraft-Pakete eine eigene, eindeutig erkennbare Dateiendung:

```text
foo-1.0-1.src.bcraft    Source-Paket
foo-1.0-1.bcraft        installierbares Binärpaket
```

Intern bleiben beide Formate bewusst einfache gzip-komprimierte Tar-Archive. Die eigene Dateiendung kennzeichnet den Zweck der Datei, ohne ein unnötig komplexes Containerformat einzuführen.

Der grundsätzliche Build-Ablauf lautet:

```text
Rezept-Verzeichnis
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

## Paket-Rezepte

Ein typisches Rezept besteht mindestens aus:

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
├── files/
└── sources/
```

Für Software, die von einem Upstream-Projekt heruntergeladen wird, kann `package.conf` zum Beispiel enthalten:

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

Abhängigkeiten können deklarativ angegeben werden:

```bash
depends=(
    "libfoo"
    "ncurses"
)
```

`bcraft` prüft bei Installation und Update, ob diese Pakete in der eigenen Paketdatenbank registriert sind. Eine automatische Installation der Abhängigkeiten findet nicht statt.

## Source-Pakete mit `src-build`

Ein Source-Paket sollte nicht mehr manuell mit `tar` erzeugt werden.

Stattdessen wird das Rezept-Verzeichnis direkt an `bcraft` übergeben:

```bash
bcraft src-build ./foo
```

Dadurch entsteht beispielsweise:

```text
foo-1.0-1.src.bcraft
```

Beim Erzeugen eines Source-Pakets darf für Remote-Sources auch:

```bash
source_sha256="AUTO"
```

verwendet werden.

`bcraft src-build` lädt in diesem Fall die betreffende Source, berechnet SHA-256 und schreibt den festen Hash **nur in die Kopie von `package.conf` innerhalb des erzeugten Source-Pakets**.

Das ursprüngliche Rezept bleibt unverändert.

Ein normales:

```bash
bcraft build foo-1.0-1.src.bcraft
```

akzeptiert `AUTO` dagegen nicht. Ein Source-Paket muss beim eigentlichen Build bereits feste Prüfsummen enthalten.

## Mehrere Sources

Seit `bcraft 0.5.1` kann ein Paket mehrere Quelldateien verwenden.

Beispiel:

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
    "SHA256-DES-ARCHIVS"
    "SHA256-DES-PATCHES"
)
```

Die Einträge werden über ihren Array-Index einander zugeordnet.

Jede Source wird separat per SHA-256 geprüft. Die erste Source gilt als Hauptquellarchiv und wird automatisch entpackt. Weitere Sources werden unverändert im `SRCDIR` bereitgestellt und können vom Build-Skript verwendet werden.

Beispiel:

```bash
cd "$SRCDIR/foo-1.0"
patch -Np1 -i "$SRCDIR/foo-fix.patch"
```

Auch bei Multi-Source können beim `src-build` einzelne SHA-256-Einträge auf `AUTO` gesetzt werden. Im erzeugten Source-Paket stehen anschließend ausschließlich feste Hashes.

Das bisherige Single-Source-Format bleibt kompatibel.

## Build-Skript

Das Build-Skript installiert in das Paket-Staging-Verzeichnis:

```bash
#!/bin/bash
set -euo pipefail

cd "$SRCDIR"

./configure --prefix=/usr

make -j"$JOBS"

make DESTDIR="$PKGDIR" install
```

Die wichtigste Regel lautet:

> Ein Paket-Build muss alles in `$PKGDIR` installieren und darf nicht direkt in das laufende System schreiben.

Unterstützt ein Paket kein `DESTDIR`, können Dateien explizit nach `$PKGDIR` installiert werden:

```bash
install -Dm755 foo "$PKGDIR/usr/bin/foo"
```

Anschließend erzeugt `bcraft` automatisch `MANIFEST` und `PKGINFO`.

Das Manifest wird nicht von Hand gepflegt.

Weitere Informationen:

```bash
man bcraft
man 5 bcraft-recipe
```

## Binärpakete

Ein Build erzeugt beispielsweise:

```text
foo-1.0-1.bcraft
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

## Installieren und aktualisieren

Ein neues Paket wird normal installiert:

```bash
bcraft install foo-1.0-1.bcraft
```

Seit `bcraft 0.6.0` erkennt `install`, wenn das Paket bereits in einer älteren Version installiert ist.

Beispiel:

```text
installiert: foo 1.0-1
angegeben:   foo 1.1-1
```

`bcraft install foo-1.1-1.bcraft` bietet dann interaktiv an, das vorhandene Paket zu aktualisieren.

Auf einem deutschsprachigen System lautet die Nachfrage sinngemäß:

```text
Möchten Sie das bereits installierte Paket aktualisieren? [j/N]
```

Die englische Variante verwendet:

```text
Do you want to update the installed package? [y/N]
```

Bei Zustimmung verwendet `install` denselben Update-Codepfad wie das explizite Kommando:

```bash
bcraft update foo-1.1-1.bcraft
```

`update` bleibt damit für Skripte und für den bewussten, expliziten Paketwechsel erhalten.

Für `install` gelten grundsätzlich folgende Fälle:

```text
Paket nicht installiert
    → installieren

gleiche Version installiert
    → als bereits installiert melden

ältere Version installiert
    → Update anbieten

neuere Version installiert
    → Downgrade verweigern
```

Der Versionsvergleich berücksichtigt `version` und anschließend `release` und vergleicht numerische Segmente natürlich, sodass beispielsweise `1.10` neuer als `1.9` ist.

Der Begriff `upgrade` wird von `bcraft` weiterhin nicht für normale Paketupdates verwendet. Er bleibt für einen möglichen späteren Wechsel der gesamten Basecraft-Basis reserviert, zum Beispiel:

```text
basecraft-1 → basecraft-2
```

## Basecraft als Distribution

Der heutige Stand von Basecraft ist noch experimentell und setzt für erste Tests ein vorhandenes LFS-/Umbra-artiges System voraus.

Die geplante Entwicklung geht darüber hinaus.

Ziel ist eine kleine **Basecraft Live-ISO**, die ein minimales, definiertes LFS-Basissystem auf ein Zielsystem installiert. Nach diesem Bootstrap übernimmt `bcraft` den weiteren Ausbau.

Der Anwender soll anschließend frei entscheiden können:

```text
fertiges .bcraft-Paket installieren
oder
.src.bcraft lokal bauen und anschließend installieren
```

Auch ein gemischtes System ist ausdrücklich vorgesehen.

Die Live-ISO soll damit nicht möglichst viel Software mitbringen, sondern einen kleinen, reproduzierbaren Startpunkt schaffen.

## Basecraft auf einem bestehenden LFS-/Umbra-System initialisieren

Bis eine eigenständige Live-ISO verfügbar ist, kann Basecraft weiterhin auf einem bereits installierten Umbra-/LFS-System gebootstrapt werden.

Dafür werden ein passendes `bcraft-bootstrap` und die benötigten Basecraft-Source-Pakete verwendet.

Das aktuelle Paketschema lautet dabei beispielsweise:

```text
bcraft-0.6.0-1.src.bcraft
basecraft-release-1-3.src.bcraft
```

Aus einem Source-Paket wird mit:

```bash
sudo ./bcraft-bootstrap build \
    basecraft-release-1-3.src.bcraft
```

ein installierbares Paket erzeugt, das anschließend mit `bcraft-bootstrap install` installiert werden kann.

Danach kann `bcraft` selbst gebaut und installiert werden.

Installation prüfen:

```bash
bcraft -v
bcraft list
bcraft info bcraft
cat /etc/basecraft-release
```

`--nodeps` dient dabei unter anderem als bewusstes Werkzeug für Situationen, in denen Software auf einem bestehenden LFS-System vorhanden ist, aber noch nicht in der bcraft-Paketdatenbank registriert wurde.

## Beispiel: JOE

Das Rezept unter `examples/joe` zeigt, wie eine LFS-/BLFS-artige Build-Anleitung in ein `bcraft`-Rezept übertragen werden kann.

Source-Paket erzeugen:

```bash
bcraft src-build examples/joe
```

Dadurch entsteht beispielsweise:

```text
joe-4.8-1.src.bcraft
```

Bauen:

```bash
sudo bcraft build joe-4.8-1.src.bcraft
```

Dadurch entsteht:

```text
/var/cache/basecraft/packages/joe-4.8-1.bcraft
```

Installieren:

```bash
sudo bcraft install \
    /var/cache/basecraft/packages/joe-4.8-1.bcraft
```

Eine spätere Version kann aus einem angepassten Rezept erneut erzeugt und gebaut werden.

Anschließend kann entweder explizit aktualisiert werden:

```bash
sudo bcraft update \
    /var/cache/basecraft/packages/joe-NEWVERSION-1.bcraft
```

oder das neue Paket wird an `install` übergeben und das angebotene Update bestätigt.

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

Diese Punkte fehlen nicht versehentlich. Basecraft soll nachvollziehbar bleiben und dem Anwender die Kontrolle darüber lassen, welche Software als Binärpaket installiert und welche lokal gebaut wird.

## Status und Roadmap

Basecraft sollte derzeit weiterhin als **experimentell** betrachtet werden.

Der bisherige Stand umfasst unter anderem:

```text
Bootstrap auf einem bestehenden LFS-/Umbra-System
Source- und Binärpakete mit eigener .bcraft-Endung
Erzeugen reproduzierbarer Source-Pakete mit bcraft src-build
Single- und Multi-Source-Rezepte
SHA-256-Prüfung der Sources
deklarative Paketabhängigkeiten
bewusstes Überspringen mit --nodeps
Installation und Paketupdates
Erhalt lokal veränderter Konfigurationsdateien
bcraft kann mit bcraft selbst aktualisiert werden
```

Die nächste größere Entwicklungsrichtung ist der Weg von dieser Paket- und Build-Schicht zu einer kleinen eigenständigen Basecraft-Linux-Distribution mit Live-ISO und definiertem LFS-Basissystem.

Das Projekt bleibt dabei ein Hobby- und Lernprojekt.

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
