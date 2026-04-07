/// Mobile stub: file opening is handled by OpenFilex, not this.
library;

import 'dart:typed_data';

void openBlobInBrowser(Uint8List bytes, String fileName, String mimeType) {
  throw UnsupportedError(
    'openBlobInBrowser is only available on web. Guard calls with kIsWeb.',
  );
}
