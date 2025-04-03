import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:result_controller/src/api_err_handler.dart';
import 'package:result_controller/src/api_handler.dart';
import 'package:result_controller/src/api_response_handler.dart';

void main() {
  late HttpErr testError;

  setUp(() {
    // Create real HttpError instance instead of using Mockito
    testError = HttpErr(
      exception: Exception('Test exception'),
      stackTrace: StackTrace.current,
      data: HttpMessage(
        success: false,
        title: 'Test Error',
        details: 'Test error details',
      ),
    );
  });

  group('ApiResponse constructors', () {
    test('default constructor creates response with given values', () {
      final response = ApiResponse(
        data: {'key': 'value'},
        statusCode: 200,
        error: null,
      );

      expect(response.data, {'key': 'value'});
      expect(response.statusCode, 200);
      expect(response.error, isNull);
    });

    test('success factory creates response with success data', () {
      final response = ApiResponse.success({'key': 'value'}, statusCode: 200);

      expect(response.data, {'key': 'value'});
      expect(response.statusCode, 200);
      expect(response.error, isNull);
    });

    test('failure factory creates response with error data', () {
      final response = ApiResponse.failure(testError, statusCode: 400);

      expect(response.data, isNull);
      expect(response.statusCode, 400);
      expect(response.error, testError);
    });
  });

  group('when method', () {
    test('calls ok function when response has no error', () {
      final response = ApiResponse.success({'name': 'John'}, statusCode: 200);

      final result = response.when(
        ok: (data) => 'Success: ${data['name']}',
        err: (error) => 'Error: ${error.data?.details}',
      );

      expect(result, 'Success: John');
    });

    test('calls err function when response has error', () {
      final response = ApiResponse.failure(testError, statusCode: 400);

      final result = response.when(
        ok: (data) => 'Success: $data',
        err: (error) => 'Error: ${error.data?.details}',
      );

      expect(result, 'Error: Test error details');
    });
  });

  group('whenList method', () {
    test('processes list of maps correctly', () {
      final response = ApiResponse.success([
        {'id': 1, 'name': 'John'},
        {'id': 2, 'name': 'Jane'},
      ]);
      final result = response.whenList(
        ok: (list) {
          final rr = list.map((item) => item['name']).toList();
          return rr;
        },
        err: (error) => <String>[],
      );

      expect(result, ['John', 'Jane']);
    });

    test('converts mixed key map types to Map<String, dynamic>', () {
      // A list with a Map that has dynamic keys but is convertible
      final response = ApiResponse.success([
        // Dart will represent this as Map<dynamic, dynamic> internally
        jsonDecode('{"id": 1, "name": "John"}'),
      ]);

      final result = response.whenList(
        ok: (list) => list.map((item) => item['name']).toList(),
        err: (error) => <String>[],
      );

      expect(result, ['John']);
    });

    test('handles error when data is not a list', () {
      final response = ApiResponse.success({'key': 'value'});

      final result = response.whenList(
        ok: (list) => list.map((item) => item['name']).toList(),
        err: (error) => <String>['Error'],
      );

      expect(result, ['Error']);
    });

    test('calls err function when response has error', () {
      final response = ApiResponse.failure(testError);

      final result = response.whenList(
        ok: (list) => list.map((item) => item['name']).toList(),
        err: (error) => <String>['Error'],
      );

      expect(result, ['Error']);
    });
  });
}
