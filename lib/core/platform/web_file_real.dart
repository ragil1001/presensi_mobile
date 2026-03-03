/// Mobile implementation: stub that throws (never called — guarded by kIsWeb).
import 'dart:io';
import 'dart:typed_data';

File createFileFromBytes(String path, Uint8List bytes) {
  throw UnsupportedError(
    'createFileFromBytes is only available on web. Guard calls with kIsWeb.',
  );
}
