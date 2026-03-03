/// Web-safe stubs for dart:io types.
///
/// On web, dart:io is not available. This file provides type-compatible
/// stubs so that code compiles on web. Runtime code paths that actually
/// perform I/O are guarded with `kIsWeb` checks.
library;

import 'dart:typed_data';

class File {
  final String path;
  Uint8List? _bytes;

  File(this.path);

  /// Web constructor: stores bytes in memory (no file system on web).
  File.fromBytes(this.path, this._bytes);

  File get absolute => this;

  Directory get parent {
    final idx = path.lastIndexOf('/');
    return Directory(idx >= 0 ? path.substring(0, idx) : '');
  }

  Future<Uint8List> readAsBytes() async {
    if (_bytes != null) return _bytes!;
    throw UnsupportedError('File.readAsBytes() is not supported on web');
  }

  Uint8List readAsBytesSync() {
    if (_bytes != null) return _bytes!;
    throw UnsupportedError('File.readAsBytesSync() is not supported on web');
  }

  Future<File> writeAsBytes(List<int> bytes) async {
    _bytes = Uint8List.fromList(bytes);
    return this;
  }

  Future<int> length() async {
    if (_bytes != null) return _bytes!.length;
    return 0;
  }

  int lengthSync() {
    if (_bytes != null) return _bytes!.length;
    return 0;
  }

  Future<bool> exists() async => _bytes != null;

  bool existsSync() => _bytes != null;

  Future<File> delete({bool recursive = false}) async => this;

  void deleteSync({bool recursive = false}) {}

  FileStat statSync() => FileStat._empty();
  Future<FileStat> stat() async => FileStat._empty();

  Future<File> copy(String newPath) async {
    return File.fromBytes(newPath, _bytes);
  }

  Future<File> rename(String newPath) async {
    return File.fromBytes(newPath, _bytes);
  }

  Uri get uri => Uri.file(path);
}

class Directory {
  final String path;
  Directory(this.path);

  Future<bool> exists() async => false;
  bool existsSync() => false;

  Future<Directory> create({bool recursive = false}) async => this;
  void createSync({bool recursive = false}) {}

  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) {
    return const Stream.empty();
  }

  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) {
    return const [];
  }
}

class FileSystemEntity {
  final String path;
  FileSystemEntity(this.path);

  Future<int> length() async => 0;
  Future<FileStat> stat() async => FileStat._empty();
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
  static Future<bool> isFile(String path) async => false;
  static Future<bool> isDirectory(String path) async => false;
}

class FileStat {
  final DateTime modified;
  final int size;
  FileStat._empty()
      : modified = DateTime.now(),
        size = 0;
}

class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static bool get isFuchsia => false;
  static String get pathSeparator => '/';
  static String get operatingSystem => 'web';
  static Map<String, String> get environment => const {};
}

class HttpStatus {
  static const int ok = 200;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int internalServerError = 500;
}
