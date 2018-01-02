# dvm

Dart Version Manager: Manage multiple active Dart versions.

**WORK IN PROGRESS**: See "progress" below, not yet a stable package!

_Loosely based on [@cbracken][]'s original [dvm][] shell script. Thanks Chris!_

[@cbracken]: https://github.com/cbracken
[dvm]: https://github.com/cbracken/dvm

## Installation

```bash
$ pub global activate dvm
```

## Usage

```bash
$ dvm

Manage multiple active Dart versions.

Usage: dvm <command> [arguments]

Global options:
-h, --help       Print this usage information.
-v, --version    Print out the latest released version of dvm.
-p, --path       Installation directory for the Dart SDK.
                 (defaults to "/Users/matanl/.dvm")

Available commands:
  help      Display help information for dvm.
  install   Download and install a <version/channel>.
  switch    Switches the `current` directory to <version/channel>.
```

## Progress

This package is a _work in progress_, and _pull requests are welcome_!

* [ ] Use SHA256 to validate the download.
* [ ] Support installing from a local path.
* [ ] Configure whether to keep archives or auto-unzip.
* [ ] Use system installed unzip if available.

## Why a Dart package and not X?

Dart is already a cross-platform language, and binaries can be easily installed
using [`pub global activate`][global]. I'm also hoping that being in Dart makes
it more likely to get contributions from other Dart users!

One potential issue that was pointed out is the possibility of using `dvm` to
switch to a version of the SDK that in turn, breaks dvm. That's a valid
concern, so when releasing `dvm` it will ship with its own version of the Dart
VM, similar to [dart-sass][].

[global]: https://www.dartlang.org/tools/pub/cmd/pub-global
[dart-sass]: https://github.com/sass/dart-sass
