# dart_clean

![Pub Version](https://img.shields.io/pub/v/dart_clean)

dart_clean – a CLI tool to clean dart and flutter repositories recursively

## Install

```
$ pub global activate dart_clean
```

## Use

```
Usage: dart_clean <folder> [<flags>]

dart_clean – clean dart and flutter repositories
- for Flutter packages, `flutter clean` is executed
- for other Dart packages, `build/`, `.dart_tool/`, `.pub_cache/` and `.packages` are removed.

Flags:
--recursive or -r       Recursively clean subfolders
--help or -h            This help page
--no-cache              Explicitly ignore `.pub_cache` and `.packages`
--remove-generated      Explicitly remove generated dart files matching `*.g.dart`
```

## Example & Why?

You have a directory structure like this on your computer and you don't want to declutter every folder manually:

```
YourProjects/
    org1/
        repo1/ <- Flutter app
        repo2/ <- AngularDart app
        repo3/ <- business logic package in Dart
    org2/
        repo1/ <- Another Flutter app
        ...
        ...
    ...
        ...
```

## Beware

If you have installed your local Flutter or Dart SDK in a subfolder of the folder you want to clean, dart_clean won't ignore it.