import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

class ListCommand extends Command<Null> {
  final Logger _logger;

  ListCommand({
    @required Logger logger,
  })
      : _logger = logger {

  }

  @override
  final description = 'Lists the installed versions of the Dart SDK.';

  @override
  final invocation = 'dvm list';

  @override
  final name = 'list';

  @override
  run() async {
    var path = globalResults['path'];
    _logger.fine('Search path: $path');

    await for (final entity in new Directory(path).list()) {
      if (entity is Directory) {
        var name = p.basename(entity.path);

        if (name != 'current') {
          print('* $name');
        }
      }
    }
  }
}
