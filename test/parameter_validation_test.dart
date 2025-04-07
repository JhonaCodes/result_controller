import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

void main() {
  group('Parameter Validation Tests', () {
    test('handles null headers', () {
      final response = ApiResponse.ok(
        {'data': 'value'},
        statusCode: 200,
        headers: {},
      );
      expect(response.headers, isEmpty);
    });

    test('validates status code range', () {
      expect(
        () => ApiResponse.ok({'data': 'value'}, statusCode: -1, headers: {}),
        throwsArgumentError,
      );

      expect(
        () => ApiResponse.ok({'data': 'value'}, statusCode: 600, headers: {}),
        throwsArgumentError,
      );
    });
  });
}
