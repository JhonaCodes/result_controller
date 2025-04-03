import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';
import 'dart:convert';

// Mock classes for testing
class TestObject {
  final String id;
  final String name;

  TestObject({required this.id, required this.name});

  factory TestObject.fromJson(Map<String, dynamic> json) {
    return TestObject(id: json['id'].toString(), name: json['name'] as String);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestObject && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class TestStackTrace implements StackTrace {
  @override
  String toString() => 'test stack trace';
}

void main() {
  late HttpErr testError;

  setUp(() {
    testError = HttpErr(
      exception: Exception('Test exception'),
      stackTrace: TestStackTrace(),
      data: HttpMessage(
        success: false,
        title: 'Test Error',
        details: 'Test error details',
      ),
    );
  });

  group('ApiResponse.whenListType exhaustive tests', () {
    test('handles List<int> correctly', () {
      final response = ApiResponse.success([1, 2, 3, 4, 5]);

      final result = response.whenListType<List<int>, int>(
        ok: (list) => list,
        err: (error) => <int>[],
      );

      expect(result, equals([1, 2, 3, 4, 5]));
    });

    test('handles List<double> correctly', () {
      final response = ApiResponse.success([1.1, 2.2, 3.3, 4.4, 5.5]);

      final result = response.whenListType<List<double>, double>(
        ok: (list) => list,
        err: (error) => <double>[],
      );

      expect(result, equals([1.1, 2.2, 3.3, 4.4, 5.5]));
    });

    test('handles List<String> correctly', () {
      final response = ApiResponse.success(['a', 'b', 'c', 'd', 'e']);

      final result = response.whenListType<List<String>, String>(
        ok: (list) => list,
        err: (error) => <String>[],
      );

      expect(result, equals(['a', 'b', 'c', 'd', 'e']));
    });

    test('handles List<bool> correctly', () {
      final response = ApiResponse.success([true, false, true, false, true]);

      final result = response.whenListType<List<bool>, bool>(
        ok: (list) => list,
        err: (error) => <bool>[],
      );

      expect(result, equals([true, false, true, false, true]));
    });

    test('handles mixed list types with appropriate conversions', () {
      // A list with mixed numeric types
      final response = ApiResponse.success([1.0, 2.5, 3.0, 4.2, 5.0]);

      // Should automatically convert all to double
      final result = response.whenListType<List<double>, double>(
        ok: (list) => list,
        err: (error) => <double>[],
      );

      expect(result.length, equals(5));
      expect(result, contains(1.0)); // Integer converted to double
      expect(result, contains(2.5));
    });

    test('filters nulls when filterNulls is true', () {
      final response = ApiResponse.success([1, null, 3, null, 5]);

      final result = response.whenListType<List<int>, int>(
        ok: (list) => list,
        err: (error) => <int>[],
        filterNulls: true,
      );

      expect(result, equals([1, 3, 5]));
    });

    test('preserves nulls when filterNulls is false', () {
      final response = ApiResponse.success([1, null, 3, null, 5]);

      final result = response.whenListType<List<int?>, int?>(
        ok: (list) => list,
        err: (error) => <int?>[],
        filterNulls: false,
      );

      expect(result, equals([1, null, 3, null, 5]));
    });

    test('handles empty list correctly', () {
      final response = ApiResponse.success([]);

      final result = response.whenListType<List<int>, int>(
        ok: (list) => list,
        err: (error) => <int>[-1],
      );

      expect(result, isEmpty);
    });

    test('handles error response correctly', () {
      final response = ApiResponse.failure(testError);

      final result = response.whenListType<List<int>, int>(
        ok: (list) => list,
        err: (error) => <int>[-1, -2, -3],
      );

      expect(result, equals([-1, -2, -3]));
    });

    test('handles non-list data as error', () {
      final response = ApiResponse.success({'key': 'value'});

      final result = response.whenListType<List<String>, String>(
        ok: (list) => list,
        err: (error) => <String>['error'],
      );

      expect(result, equals(['error']));
    });

    test('handles null data as error', () {
      final response = ApiResponse(statusCode: 200);

      final result = response.whenListType<List<String>, String>(
        ok: (list) => list,
        err: (error) => <String>['error'],
      );

      expect(result, equals(['error']));
    });

    test('handles incompatible type conversions as error', () {
      final response = ApiResponse.success(['a', 'b', 'c']);

      // Attempt to convert strings to ints should fail
      final result = response.whenListType<List<int>, int>(
        ok: (list) => list,
        err: (error) => <int>[-1],
      );

      expect(result, equals([-1]));
    });
  });

  group('ApiResponse.whenJsonListMap tests', () {
    test('processes valid list of JSON maps correctly', () {
      final response = ApiResponse.success([
        {'id': '1', 'name': 'Item 1'},
        {'id': '2', 'name': 'Item 2'},
        {'id': '3', 'name': 'Item 3'},
      ]);

      final result = response.whenJsonListMap(
        ok: (list) => list.map((item) => TestObject.fromJson(item)).toList(),
        err: (error) => <TestObject>[],
      );

      expect(result.length, equals(3));
      expect(result[0], equals(TestObject(id: '1', name: 'Item 1')));
      expect(result[1], equals(TestObject(id: '2', name: 'Item 2')));
      expect(result[2], equals(TestObject(id: '3', name: 'Item 3')));
    });

    test('handles complex nested JSON structures', () {
      final response = ApiResponse.success([
        {
          'id': '1',
          'name': 'Item 1',
          'metadata': {'created': '2023-01-01', 'updated': '2023-01-02'},
          'tags': ['tag1', 'tag2'],
        },
        {
          'id': '2',
          'name': 'Item 2',
          'metadata': {'created': '2023-02-01', 'updated': '2023-02-02'},
          'tags': ['tag3', 'tag4'],
        },
      ]);

      final result = response.whenJsonListMap(
        ok: (list) {
          return list.map((item) {
            final obj = TestObject.fromJson(item);
            // We could process the nested data here if needed
            return obj;
          }).toList();
        },
        err: (error) => <TestObject>[],
      );

      expect(result.length, equals(2));
      expect(result[0].id, equals('1'));
      expect(result[1].name, equals('Item 2'));
    });

    test('handles mixed map types and converts to Map<String, dynamic>', () {
      // A response with maps that have dynamic keys
      final jsonStr = '[{"id":1,"name":"Item 1"},{"id":"2","name":"Item 2"}]';
      final decodedList = jsonDecode(jsonStr);
      final response = ApiResponse.success(decodedList);

      final result = response.whenJsonListMap(
        ok: (list) => list.map((item) => TestObject.fromJson(item)).toList(),
        err: (error) => <TestObject>[],
      );

      expect(result.length, equals(2));
      expect(result[0].id, equals('1')); // int converted to string in fromJson
      expect(result[1].id, equals('2'));
    });

    test('handles list with non-map items as error', () {
      final response = ApiResponse.success([
        {'id': '1', 'name': 'Item 1'},
        'not a map', // This is not a map
        {'id': '3', 'name': 'Item 3'},
      ]);

      final result = response.whenJsonListMap(
        ok: (list) => list.map((item) => TestObject.fromJson(item)).toList(),
        err:
            (error) => <TestObject>[
              TestObject(id: 'error', name: 'Error object'),
            ],
      );

      expect(result.length, equals(1));
      expect(result[0].id, equals('error'));
    });

    test('handles empty list correctly', () {
      final response = ApiResponse.success([]);

      final result = response.whenJsonListMap(
        ok: (list) => list.map((item) => TestObject.fromJson(item)).toList(),
        err:
            (error) => <TestObject>[
              TestObject(id: 'error', name: 'Error object'),
            ],
      );

      expect(result, isEmpty);
    });

    test('handles error response correctly', () {
      final response = ApiResponse.failure(testError);

      final result = response.whenJsonListMap(
        ok: (list) => list.map((item) => TestObject.fromJson(item)).toList(),
        err:
            (error) => <TestObject>[
              TestObject(id: 'error', name: 'Error object'),
            ],
      );

      expect(result.length, equals(1));
      expect(result[0].id, equals('error'));
    });

    test('handles non-list data as error', () {
      final response = ApiResponse.success({'key': 'value'});

      final result = response.whenJsonListMap(
        ok: (list) => list.map((item) => TestObject.fromJson(item)).toList(),
        err:
            (error) => <TestObject>[
              TestObject(id: 'error', name: 'Error object'),
            ],
      );

      expect(result.length, equals(1));
      expect(result[0].id, equals('error'));
    });

    test('handles null data as error', () {
      final response = ApiResponse(statusCode: 200);

      final result = response.whenJsonListMap(
        ok: (list) => list.map((item) => TestObject.fromJson(item)).toList(),
        err:
            (error) => <TestObject>[
              TestObject(id: 'error', name: 'Error object'),
            ],
      );

      expect(result.length, equals(1));
      expect(result[0].id, equals('error'));
    });
  });

  group('ApiResponse edge cases and error handling', () {
    test('handles deeply nested JSON structures correctly', () {
      final response = ApiResponse.success({
        'data': {
          'items': [
            {'id': '1', 'name': 'Item 1'},
            {'id': '2', 'name': 'Item 2'},
          ],
        },
      });

      final result = response.when(
        ok: (data) {
          final itemsList =
              (data['data']['items'] as List).cast<Map<String, dynamic>>();
          return itemsList.map((item) => TestObject.fromJson(item)).toList();
        },
        err: (error) => <TestObject>[],
      );

      expect(result.length, equals(2));
      expect(result[0].id, equals('1'));
      expect(result[1].name, equals('Item 2'));
    });

    test('handles unexpected data types gracefully', () {
      // Create a response with an unexpected data type (e.g., binary data)
      final bytes = [0, 1, 2, 3, 4, 5];
      final response = ApiResponse.success(bytes);

      // Should handle this gracefully in the when method
      final result = response.when(
        ok: (data) {
          if (data is List<int>) {
            return 'Received binary data: ${data.length} bytes';
          }
          return 'Unexpected data type: ${data.runtimeType}';
        },
        err: (error) => 'Error: ${error.exception}',
      );

      expect(result, contains('Received binary data'));
    });

    test('handles null values in nested structures', () {
      final response = ApiResponse.success({
        'user': {
          'id': '123',
          'name': null,
          'settings': null,
          'friends': [
            null,
            {'id': '456', 'name': 'Friend'},
          ],
        },
      });

      final result = response.when(
        ok: (data) {
          final userData = data['user'] as Map<String, dynamic>;
          final hasFriends = userData['friends'] != null;
          final friendCount =
              hasFriends
                  ? (userData['friends'] as List).where((f) => f != null).length
                  : 0;
          return 'User ID: ${userData['id']}, Has name: ${userData['name'] != null}, Friend count: $friendCount';
        },
        err: (error) => 'Error',
      );

      expect(result, equals('User ID: 123, Has name: false, Friend count: 1'));
    });

    test('handles different status codes with appropriate responses', () {
      final okResponse = ApiResponse.success({
        'status': 'success',
      }, statusCode: 200);
      final createdResponse = ApiResponse.success({
        'id': 'new-id',
      }, statusCode: 201);
      final notModifiedResponse = ApiResponse(statusCode: 304);
      final badRequestResponse = ApiResponse.failure(
        HttpErr(
          exception: Exception('Bad request'),
          stackTrace: TestStackTrace(),
          data: HttpMessage(
            success: false,
            title: 'Error',
            details: 'Bad request',
          ),
        ),
        statusCode: 400,
      );
      final serverErrorResponse = ApiResponse.failure(
        HttpErr(
          exception: Exception('Server error'),
          stackTrace: TestStackTrace(),
          data: HttpMessage(
            success: false,
            title: 'Error',
            details: 'Server error',
          ),
        ),
        statusCode: 500,
      );

      // Process different status codes
      expect(okResponse.statusCode, equals(200));
      expect(createdResponse.statusCode, equals(201));
      expect(notModifiedResponse.statusCode, equals(304));
      expect(badRequestResponse.statusCode, equals(400));
      expect(serverErrorResponse.statusCode, equals(500));

      // Check handling of 3xx responses
      final notModifiedResult = notModifiedResponse.when(
        ok: (data) => 'Got data',
        err: (error) => 'Error: No new data',
      );

      expect(notModifiedResult, equals('Error: No new data'));
    });

    test('handles json data conversion between string and object format', () {
      // Test with JSON as string
      final jsonString = '{"id":"1","name":"Test Object"}';
      final stringResponse = ApiResponse.success(jsonString);

      final stringResult = stringResponse.when(
        ok: (data) {
          if (data is String) {
            final decoded = jsonDecode(data) as Map<String, dynamic>;
            return TestObject.fromJson(decoded);
          }
          return TestObject(id: 'error', name: 'Error');
        },
        err: (error) => TestObject(id: 'error', name: 'Error'),
      );

      expect(stringResult.id, equals('1'));
      expect(stringResult.name, equals('Test Object'));

      // Test with JSON as object
      final jsonObject = {'id': '1', 'name': 'Test Object'};
      final objectResponse = ApiResponse.success(jsonObject);

      final objectResult = objectResponse.when(
        ok: (data) {
          if (data is Map<String, dynamic>) {
            return TestObject.fromJson(data);
          }
          return TestObject(id: 'error', name: 'Error');
        },
        err: (error) => TestObject(id: 'error', name: 'Error'),
      );

      expect(objectResult.id, equals('1'));
      expect(objectResult.name, equals('Test Object'));
    });
  });
}
