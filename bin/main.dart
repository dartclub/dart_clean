import 'dart:io';

import 'package:dart_clean/dart_clean.dart';

final help = '''Usage: dart_clean <folder> [<flags>]\n
dart_clean – clean dart and flutter repositories
- for Flutter packages, `flutter clean` is executed
- for other Dart packages, `build/` and `.dart_tool/` are removed.\n
Flags:
--recursive or -r\tRecursively clean subfolders
--help or -h\t\tThis help page
--remove-cache\t\tExplicitly remove `.pub_cache`, `.packages` and `pubspec.lock`
--remove-generated\tExplicitly remove generated dart files matching `*.g.dart`
''';
void main(List<String> arguments) async {
  if (arguments.contains('-h') ||
      arguments.contains('--help') ||
      arguments.isEmpty) {
    print(help);
    exit(0);
  }
  var dir = Directory(arguments[0]);
  if (dir.existsSync()) {
    try {
      await clean(
        dir,
        arguments.contains('--recursive') || arguments.contains('-r'),
        explicitRemoveCache: arguments.contains('--remove-cache'),
        explicitRemoveGenerated: arguments.contains('--remove-generated'),
      );

      print('Done!');
      exit(0);
    } catch (e) {
      print(e);
      exit(1);
    }
  } else {
    print('`${arguments[1]}` is not a directory');
    print(help);
    exit(1);
  }
}
