// Copyright (c) 2017, Google Inc. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:func/func.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:stream_transform/stream_transform.dart';

import '../dart_downloads.dart';
import '../io_helper.dart' as io;

/// Encapsulates the `dvm install` command.
class InstallCommand extends Command<Null> {
  final Func0<OS> _getCurrentOS;
  final Func1<Channel, Future<Version>> _getLatestVersion;
  final Func0<Future<bool>> _isOnline;
  final Logger _logger;

  InstallCommand({
    @required OS getCurrentOS(),
    @required Future<Version> getLatestVersion(Channel channel),
    @required Future<bool> isOnline(),
    @required Logger logger,
  })
      : _getCurrentOS = getCurrentOS,
        _getLatestVersion = getLatestVersion,
        _isOnline = isOnline,
        _logger = logger {
    argParser
      ..addOption(
        'arch',
        abbr: 'a',
        allowed: const [
          'ia32',
          'x64',
          'arm',
          'arm64',
        ],
        help: 'What architecture to download the SDK for.',
        defaultsTo: 'x64',
      );
  }

  @override
  final description = 'Download and install a <version/channel>.';

  @override
  final invocation = 'dvm install <version/channel>';

  @override
  final name = 'install';

  @override
  run() async {
    if (!await _isOnline()) {
      _logger.severe('No internet connection detected');
      exitCode = 1;
      return;
    }
    final path = globalResults['path'] as String;
    if (path == null || path.isEmpty) {
      _logger.severe('No path specified.');
      exitCode = 1;
      printUsage();
      return;
    }
    final release = await getRelease(this, _logger, _getLatestVersion);
    final os = _getCurrentOS();
    final arch = architectureFromString(argResults['arch']);
    _logger.config('OS: $os.');
    _logger.config('Architecture: $arch.');
    final url = getDownloadUri(
      os: os,
      channel: release.channel,
      version: release.version,
      arch: arch,
    );
    _logger.config('Version: ${release.version}.');
    _install(url, release.version);
  }

  Future<Null> _install(Uri uri, Version version) async {
    final path = p.join(
      globalResults['path'],
      version.toString(),
      uri.pathSegments.last,
    );
    if (FileSystemEntity.isFileSync(path)) {
      _logger.info('Good news! $version is already installed!');
      exitCode = 0;
      return;
    }
    _logger.info('Dowloading as $path...');
    final throttler = throttle(const Duration(milliseconds: 200));
    await for (final progress in io.download(uri, path).transform(throttler)) {
      _logger.info('Dowloading: ${progress.percent}%...');
    }
    _logger.info('Downloaded as $path.');
  }
}
