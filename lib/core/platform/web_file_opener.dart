/// Conditional export for web file opening.
/// On web: opens blob in new browser tab using dart:html.
/// On mobile: stub that throws (never called — guarded by kIsWeb).
library;

export 'web_file_opener_stub.dart'
    if (dart.library.html) 'web_file_opener_web.dart';
