/// Conditional export for web File creation helper.
/// On web: provides real implementation using fake_io File.fromBytes
/// On mobile: provides stub that throws (never called — guarded by kIsWeb)
library;

export 'web_file_stub.dart' if (dart.library.io) 'web_file_real.dart';
