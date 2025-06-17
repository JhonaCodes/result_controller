import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

import 'package:result_controller/src/api_err_handler.dart';
import 'package:result_controller/src/api_response_handler.dart';

void main() {
  group('ApiResponse constructors', () {
    test('default constructor creates response with given values', () {
      final response = ApiResponse(
        data: {'key': 'value'},
        statusCode: 200,
        headers: {},
        err: null,
      );

      expect(response.data, {'key': 'value'});
      expect(response.statusCode, 200);
      expect(response.err, isNull);
    });

    test('ok factory creates response with success data', () {
      final response = ApiResponse.ok(
        {'key': 'value'},
        statusCode: 200,
        headers: {},
      );

      expect(response.data, {'key': 'value'});
      expect(response.statusCode, 200);
      expect(response.err, isNull);
    });

    test('err factory creates response with error data', () {
      final apiErr = ApiErr(title: 'Test Error', msm: 'Test error details');

      final response = ApiResponse.err(apiErr, statusCode: 400, headers: {});

      expect(response.data, isNull);
      expect(response.statusCode, 400);
      expect(response.err, apiErr);
    });
  });

  group('when method', () {
    test('calls ok function when response has no error', () {
      final response = ApiResponse.ok(
        {'name': 'John'},
        statusCode: 200,
        headers: {},
      );

      final result = response.when(
        ok: (data) => 'Success: ${data['name']}',
        err: (error) => 'Error: ${error.msm}',
      );

      expect(result, 'Success: John');
    });

    test('calls err function when response has error', () {
      final apiErr = ApiErr(title: 'Test Error', msm: 'Test error details');

      final response = ApiResponse.err(apiErr, statusCode: 400, headers: {});

      final result = response.when(
        ok: (data) => 'Success: $data',
        err: (error) => 'Error: ${error.msm}',
      );

      expect(result, 'Error: Test error details');
    });
  });

  group('whenList method', () {
    test('processes list of maps correctly', () {
      final response = ApiResponse.ok(
        [
          {'id': 1, 'name': 'John'},
          {'id': 2, 'name': 'Jane'},
        ],
        statusCode: 200,
        headers: {},
      );
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
      final response = ApiResponse.ok(
        [jsonDecode('{"id": 1, "name": "John"}')],
        statusCode: 200,
        headers: {},
      );

      final result = response.whenList(
        ok: (list) => list.map((item) => item['name']).toList(),
        err: (error) => <String>[],
      );

      expect(result, ['John']);
    });

    test('handles error when data is not a list', () {
      final response = ApiResponse.ok(
        {'key': 'value'},
        statusCode: 200,
        headers: {},
      );

      final result = response.whenList(
        ok: (list) => list.map((item) => item['name']).toList(),
        err: (error) => <String>['Error'],
      );

      expect(result, ['Error']);
    });

    test('calls err function when response has error', () {
      final apiErr = ApiErr(title: 'Test Error', msm: 'Test error details');

      final response = ApiResponse.err(apiErr, statusCode: 400, headers: {});

      final result = response.whenList(
        ok: (list) => list.map((item) => item['name']).toList(),
        err: (error) => <String>['Error'],
      );

      expect(result, ['Error']);
    });
  });
}
