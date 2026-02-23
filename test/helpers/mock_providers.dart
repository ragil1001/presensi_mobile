import 'package:flutter_test/flutter_test.dart';

/// Simple mock for testing without full Riverpod setup
class MockApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;

  MockApiResponse({this.data, this.error, this.statusCode = 200});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
