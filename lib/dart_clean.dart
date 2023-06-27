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

  var files = dir
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
  required bool explicitRemoveCache,
  required bool explicitRemoveGenerated,
}) async {
  var path = await dir.resolveSymbolicLinks();
  if (ignores.contains(p.split(path).last) || path.endsWith('.git')) {
    return;
  }

  late final File? pubspec;
  try {
    pubspec = await dir
        .list(recursive: false)
        .where((event) => event is File)
        .cast<File>()
        .singleWhere((element) => element.path.endsWith('pubspec.yaml'));
  } catch (e) {
    pubspec = null;
  }

  if (pubspec != null) {
    YamlMap parsed = loadYaml(await pubspec.readAsString());
    YamlMap? dependencies = parsed["dependencies"];

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
          '\t${result.stdout.toString().trimRight().replaceAll('\n', '\n\t')}');
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

    // Keep looking recursively, as there could be nested packages
    // in a Dart/Flutter project
    if (recursive) {
      await _cleanRecursive(
        dir,
        isDartFlutterDir: true,
        explicitRemoveCache: explicitRemoveCache,
        explicitRemoveGenerated: explicitRemoveGenerated,
      );
    }
  } else {
    if (recursive) {
      print('No pubspec found, skipping `$path`');

      await _cleanRecursive(
        dir,
        isDartFlutterDir: false,
        explicitRemoveCache: explicitRemoveCache,
        explicitRemoveGenerated: explicitRemoveGenerated,
      );
    } else {
      print('No pubspec found, skipping `$path`');
    }
  }
}

Future<void> _cleanRecursive(
  Directory dir, {
  required bool isDartFlutterDir,
  required bool explicitRemoveCache,
  required bool explicitRemoveGenerated,
}) async {
  var subDirs = dir
      .list(recursive: false)
      .where((entity) => entity is Directory)
      .cast<Directory>();

  await for (var subDir in subDirs) {
    final folderName = p.basename(subDir.path);

    // If we are recursively cleaning from a Dart/Flutter project, there is no need
    // to navigate to `lib`, `bin` or `test` folders
    if (isDartFlutterDir && {'lib', 'bin', 'test'}.contains(folderName)) {
      continue;
    }

    await clean(
      subDir,
      true,
      explicitRemoveCache: explicitRemoveCache,
      explicitRemoveGenerated: explicitRemoveGenerated,
    );
  }
}
