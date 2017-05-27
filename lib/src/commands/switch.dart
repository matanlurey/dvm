// Copyright (c) 2017, Google Inc. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide ZLibDecoder;

import 'package:archive/archive.dart';
import 'package:args/command_runner.dart';
import 'package:func/func.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../dart_downloads.dart';
import 'package:pub_semver/pub_semver.dart';

class SwitchCommand extends Command<Null> {
  final Func1<Channel, Future<Version>> _getLatestVersion;
  final Logger _logger;

  SwitchCommand({
    @required Logger logger,
    @required Future<Version> getLatestVersion(Channel channel),
  })
      : _getLatestVersion = getLatestVersion,
        _logger = logger {
    argParser
      ..addOption(
        'current',
        abbr: 'c',
        help: 'Current Dart SDK installation (i.e. on PATH).',
        valueHelp: 'path',
      );
  }

  @override
  final description = 'Switches the `current` directory to <version/channel>.';

  @override
  final invocation = 'dvm switch <version/channel>';

  @override
  final name = 'switch';

  @override
  run() async {
    String current;
    if (argResults.wasParsed('current')) {
      current = argResults['current'];
    } else {
      current = p.join(globalResults['path'], 'current');
    }
    _logger.config('Using "$current" as the current SDK path.');
    final release = await getRelease(this, _logger, _getLatestVersion);
    _logger.info(
      'Switching to ${channelToString(release.channel)}/${release.version}...',
    );
    final path = p.join(globalResults['path'], release.version.toString());
    _logger.fine('Looking in $path...');
    try {
      final archive = new Directory(path)
          .listSync()
          .firstWhere((e) => e.path.endsWith('.zip')) as File;
      _logger.fine('Decoding ${archive.path}...');
      final zipFile = new ZipDecoder().decodeBytes(archive.readAsBytesSync());
      for (final file in zipFile.files) {
        if (file.isFile) {
          new File(p.join(current, file.name))
            ..createSync(recursive: true)
            ..writeAsBytesSync(file.content);
        }
      }
      _logger.info('Done as "${p.join(current, 'dart-sdk')}".');
    } catch (e, s) {
      _logger.severe('Could not find archive', e, s);
      exitCode = 1;
      return;
    }
  }
}
