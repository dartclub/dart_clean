import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:yaml/yaml.dart';

final ignores = [
  'node_modules',
  '.git',
  '.idea',
  '.vscode',
];

Future<void> _deleteDir(String base, String end) async {
  var dir = Directory(p.join(base, end));
  if (await dir.exists()) {
    print('\tRemoving ${dir.path}');
    await dir.delete(recursive: true);
  }
}

Future<void> _deleteFile(String base, String end) async {
  var file = File(p.join(base, end));
  if (await file.exists()) {
    print('\tRemoving ${file.path}');
    await file.delete();
  }
}

Future<void> _deleteGenerated(Directory dir) async {
  print('\tRemoving generated files matching `**/*.g.dart`');

  var files = await dir
      .list(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.g.dart'))
      .cast<File>();
  await for (var file in files) {
    await file.delete();
  }
}

Future<void> clean(
  Directory dir,
  bool recursive, {
  bool explicitRemoveCache = false,
  bool explicitRemoveGenerated = false,
}) async {
  var path = await dir.resolveSymbolicLinks();
  if (ignores.contains(p.split(path).last) || path.endsWith('.git')) {
    return;
  }
  File pubspec = await dir.list(recursive: false).singleWhere(
        (element) => (element is File) && element.path.endsWith('pubspec.yaml'),
        orElse: () => null,
      );
  if (pubspec != null) {
    YamlMap parsed = loadYaml(await pubspec.readAsString());
    YamlMap dependencies = parsed["dependencies"];

    if (dependencies != null && dependencies.containsKey('flutter')) {
      print('Cleaning `$path`');

      var result = await Process.run(
        'flutter',
        ['clean'],
        workingDirectory: path,
      );
      if (result.exitCode != 0) {
        throw result.stderr;
      }
      print(
          '\t' + result.stdout.toString().trimRight().replaceAll('\n', '\n\t'));
    } else {
      print('Cleaning `$path`');
      await _deleteDir(path, 'build');
      await _deleteDir(path, '.dart_tool');
    }
    if (explicitRemoveCache) {
      await _deleteDir(path, '.pub-cache');
      await _deleteFile(path, '.packages');
      await _deleteFile(path, 'pubspec.lock');
    }
    if (explicitRemoveGenerated) {
      await _deleteGenerated(dir);
    }
  } else {
    if (recursive) {
      print('No pubspec found, skipping `$path`');
      var subDirs = await dir
          .list(recursive: false)
          .where((entity) => entity is Directory)
          .cast<Directory>();
      await for (var subDir in subDirs) {
        await clean(subDir, recursive,
            explicitRemoveCache: explicitRemoveCache);
      }
    } else {
      print('No pubspec found, skipping `$path`');
    }
  }
}
