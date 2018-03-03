// Copyright (c) 2017, Google Inc. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:stack_trace/stack_trace.dart';

import 'commands/install.dart';
import 'commands/list.dart';
import 'commands/switch.dart';

import 'dart_downloads.dart';
import 'io_helper.dart' as io;

/// Installed version of DVM; must be kept manually synced with the pubspec.
const _version = '0.0.0';

/// Execute the `dvm` program with [args].
///
/// Optionally specify protocols for accessing the local and remote systems:
/// - [getCurrentOS]
/// - [getHomeDir]
/// - [getLatestVersion]
void run(
  List<String> args, {
  OS getCurrentOS(): getCurrentOS,
  String getHomeDir(): io.getHomeDir,
  Future<Version> getLatestVersion(Channel channel): io.getLatestVersion,
  Future<bool> isOnline(): io.isOnline,
}) {
  var level = Level.INFO;
  assert(() {
    level = Level.ALL;
    return true;
  });
  hierarchicalLoggingEnabled = true;
  final logger = new Logger('dvm')..level = level;
  logger.onRecord.listen((log) {
    if (log.level == Level.SEVERE) {
      stderr
        ..writeln('SEVERE: ${log.message}')
        ..writeln(log.error)
        ..writeln(new Trace.from(log.stackTrace).terse);
    } else {
      stdout.writeln('${log.level.name}: ${log.message}');
    }
  });
  Chain.capture(() {
    final runner = new _DvmCommandRunner(
      getCurrentOS: getCurrentOS,
      getHomeDir: getHomeDir,
      getLatestVersion: getLatestVersion,
      isOnline: isOnline,
      logger: logger ?? new Logger('dvm'),
    );
    runner.run(args);
  }, onError: (e, Chain s) {
    stderr.writeln('Unhandled exception: $e');
    if (e is! UsageException) {
      stderr.writeln(s.terse);
    }
    exitCode = 1;
  });
}

/// Encapsulates the top-level `dvm` command.
class _DvmCommandRunner extends CommandRunner<Null> {
  final Logger _logger;

  _DvmCommandRunner({
    @required OS getCurrentOS(),
    @required String getHomeDir(),
    @required Future<Version> getLatestVersion(Channel channel),
    @required Future<bool> isOnline(),
    @required Logger logger,
  })
      : super(
          'dvm',
          'Manage multiple active Dart versions.',
        ),
        _logger = logger {
    final homeDir = getHomeDir();
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: 'Print out the latest released version of dvm.',
      )
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Installation directory for the Dart SDK.',
        defaultsTo: homeDir != null ? '$homeDir/.dvm' : null,
      );
    addCommand(new InstallCommand(
      getCurrentOS: getCurrentOS,
      getLatestVersion: getLatestVersion,
      isOnline: isOnline,
      logger: logger,
    ));
    addCommand(new ListCommand(
      logger: logger,
    ));
    addCommand(new SwitchCommand(
      getLatestVersion: getLatestVersion,
      logger: logger,
    ));
  }

  @override
  Future<Null> runCommand(ArgResults topLevelResults) async {
    assert(() {
      _logger.warning(
        'Running in developer mode. Log output will be verbose!',
      );
      return true;
    });
    if (topLevelResults.wasParsed('version')) {
      print('Dvm $_version');
      return null;
    }
    return super.runCommand(topLevelResults);
  }
}
