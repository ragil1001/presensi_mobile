/// Web implementation: creates a File that stores bytes in memory.
import 'dart:typed_data';
import 'fake_io.dart';

File createFileFromBytes(String path, Uint8List bytes) {
  return File.fromBytes(path, bytes);
}
