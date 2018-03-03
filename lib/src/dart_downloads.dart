// Copyright (c) 2017, Google Inc. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

enum Channel {
  stable,
  dev,
}

Channel toChannel(String channel) {
  switch (channel) {
    case 'stable':
      return Channel.stable;
    case 'dev':
      return Channel.dev;
    default:
      throw new ArgumentError.value(channel, 'channel');
  }
}

String channelToString(Channel channel) {
  switch (channel) {
    case Channel.stable:
      return 'stable';
    case Channel.dev:
      return 'dev';
    default:
      throw new ArgumentError.value(channel, 'channel');
  }
}

Uri getDownloadUri({
  @required OS os,
  @required Architecture arch,
  @required Channel channel,
  @required Version version,
}) {
  if (os == null) {
    throw new ArgumentError.notNull('os');
  }
  if (arch == null) {
    throw new ArgumentError.notNull('arch');
  }
  if (channel == null) {
    throw new ArgumentError.notNull('channel');
  }
  if (version == null) {
    throw new ArgumentError.notNull('version');
  }

  return new Uri(
    scheme: 'https',
    host: 'storage.googleapis.com',
    pathSegments: [
      'dart-archive',
      'channels',
      channelToString(channel),
      'release',
      '$version',
      'sdk',
      'dartsdk-${osToString(os)}-${architectureToString(arch)}-release.zip',
    ],
  );
}

enum OS {
  mac,
  linux,
  windows,
}

/// Returns the current operating system.
OS getCurrentOS() {
  if (Platform.isWindows) {
    return OS.windows;
  }
  if (Platform.isMacOS) {
    return OS.mac;
  }
  if (Platform.isLinux) {
    return OS.linux;
  }
  throw new UnsupportedError('No expected OS detected.');
}

String osToString(OS os) {
  switch (os) {
    case OS.mac:
      return 'macos';
    case OS.linux:
      return 'linux';
    case OS.windows:
      return 'windows';
    default:
      throw new ArgumentError.value(os, 'os');
  }
}

enum Architecture {
  ia32,
  x64,
  arm,
  arm64,
}

Architecture architectureFromString(String string) {
  switch (string) {
    case 'ia32':
      return Architecture.ia32;
    case 'x64':
      return Architecture.x64;
    case 'arm':
      return Architecture.arm;
    case 'arm64':
      return Architecture.arm64;
    default:
      throw new ArgumentError.value(string, 'string');
  }
}

String architectureToString(Architecture architecture) {
  switch (architecture) {
    case Architecture.ia32:
      return 'ia32';
    case Architecture.x64:
      return 'x64';
    case Architecture.arm:
      return 'arm';
    case Architecture.arm64:
      return 'arm64';
    default:
      throw new ArgumentError.value(architecture, 'architecture');
  }
}

Future<Release> getRelease(
  Command command,
  Logger logger,
  Future<Version> getLatestVersion(Channel channel),
) async {
  Channel channel;
  Version version;
  if (command.argResults.arguments.isEmpty) {
    logger.severe('No channel or version specified.');
    exitCode = 1;
    command.printUsage();
    return null;
  }
  final argument = command.argResults.arguments.first;
  if (argument == 'stable' || argument == 'dev') {
    channel = toChannel(argument);
    logger.config('Channel: ${channelToString(channel)}.');
    logger.fine('Looking up latest version for $argument...');
    try {
      version = await getLatestVersion(channel);
    } on HttpException catch (e) {
      logger.severe('Could not fetch latest version', e);
    }
  } else {
    try {
      version = new Version.parse(argument);
    } on FormatException catch (e, s) {
      logger.severe('Could not parse version: "$argument".', e, s);
      exitCode = 1;
      return null;
    }
    if (version.preRelease.isNotEmpty) {
      channel = Channel.dev;
    } else {
      channel = Channel.stable;
    }
    logger.config('Channel: ${channelToString(channel)}.');
  }
  return new Release(channel, version);
}

class Release {
  final Channel channel;
  final Version version;

  const Release(this.channel, this.version);
}
