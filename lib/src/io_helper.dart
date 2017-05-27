import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'dart_downloads.dart';

final Map<String, String> _env = Platform.environment;

final InternetAddress _googleDns = new InternetAddress('8.8.8.8');

/// Returns a future that completes with whether the device seems connected.
Future<bool> isOnline({
  Duration timeout: const Duration(seconds: 5),
}) async {
  try {
    await _googleDns.reverse().timeout(timeout);
    return true;
  } on SocketException catch (_) {
    return false;
  } on TimeoutException catch (_) {
    return false;
  }
}

/// Returns the user's home directory on the current platform.
///
/// May be `null` in an environment where there is no home directory.
String getHomeDir() => _env['HOME'] ?? _env['UserProfile'];

/// Resolves the latest [Version] given the release [channel].
Future<Version> getLatestVersion(Channel channel) async {
  if (channel == null) {
    throw new ArgumentError.notNull('version');
  }
  final client = new HttpClient();
  return client
      .getUrl(new Uri(
        scheme: 'https',
        host: 'storage.googleapis.com',
        pathSegments: [
          'dart-archive',
          'channels',
          channelToString(channel),
          'release',
          'latest',
          'VERSION',
        ],
      ))
      .then((request) => request.close())
      .then(UTF8.decodeStream)
      .then(JSON.decode)
      .then((json) => json['version'])
      .then((version) {
    client.close();
    return new Version.parse(version);
  });
}

/// Downloads the file located at [uri] to [path] on disk.
///
/// Returns a [Stream] of [Progress] indication of the download.
Stream<Progress> download(Uri uri, String path) async* {
  new Directory(p.dirname(path)).createSync(recursive: true);
  final file = new File(path);
  final sink = file.openWrite();
  final client = new HttpClient();
  final response = await client.getUrl(uri).then((r) => r.close());
  yield new Progress._(file, response.contentLength, 0);
  var current = 0;
  await for (final bytes in response) {
    current += bytes.length;
    sink.add(bytes);
    yield new Progress._(file, response.contentLength, current);
  }
  await sink.close();
  client.close();
}

class Progress {
  /// Current size, in bytes.
  final int current;

  /// Total size, in bytes.
  final int total;

  /// Output file destination.
  final File file;

  const Progress._(this.file, this.total, this.current);

  num get percent => ((current / total) * 100).floor();
}
