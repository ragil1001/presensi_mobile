/// Conditional export: on mobile/desktop exports dart:io,
/// on web exports fake_io.dart with compatible stubs.
export 'fake_io.dart' if (dart.library.io) 'dart:io';
