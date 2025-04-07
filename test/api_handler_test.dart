import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

// Simple StackTrace para pruebas
class TestStackTrace implements StackTrace {
  @override
  String toString() => 'test stack trace';
}

// Clases modelo para pruebas
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<dynamic, dynamic> json) {
    return User(id: json['id'] as String, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'User(id: $id, name: $name)';
}

void main() {
  group('ApiResult Tests', () {
    test('ApiResult.ok creation', () {
      final result = ApiResult<int>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.data, equals(42));
    });

    test('ApiResult.err creation', () {
      final apiErr = ApiErr(
        message: HttpMessage(title: 'Not Found', details: 'Resource not found'),
      );

      final result = ApiResult<int>.err(apiErr);

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.message?.title, equals('Not Found'));
    });

    test('ApiResult when method', () {
      final okResult = ApiResult<int>.ok(42);
      final errResult = ApiResult<int>.err(
        ApiErr(
          message: HttpMessage(
            title: 'Server Error',
            details: 'Internal server error',
          ),
        ),
      );

      final okValue = okResult.when(
        ok: (value) => 'Success: $value',
        err: (error) => 'Error: ${error.message?.details}',
      );

      final errValue = errResult.when(
        ok: (value) => 'Success: $value',
        err: (error) => 'Error: ${error.message?.details}',
      );

      expect(okValue, equals('Success: 42'));
      expect(errValue, equals('Error: Internal server error'));
    });

    test('ApiResult map method', () {
      final okResult = ApiResult<int>.ok(42);
      final mappedResult = okResult.map((value) => value.toString());

      expect(mappedResult.isOk, isTrue);
      expect(mappedResult.data, equals('42'));
    });

    test('ApiResult map method with error', () {
      final apiErr = ApiErr(
        message: HttpMessage(
          title: 'Server Error',
          details: 'Internal server error',
        ),
      );
      final errResult = ApiResult<int>.err(apiErr);
      final mappedResult = errResult.map((value) => value.toString());

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull?.message?.title, equals('Server Error'));
    });

    test('ApiResult map method with error transform', () {
      final apiErr = ApiErr(
        message: HttpMessage(
          title: 'Server Error',
          details: 'Internal server error',
        ),
      );
      final errResult = ApiResult<int>.err(apiErr);
      final mappedResult = errResult.map(
        (value) => value.toString(),
        (error) => ApiErr(
          message: HttpMessage(
            title: 'Transformed',
            details: 'Error was transformed',
          ),
        ),
      );

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull?.message?.title, equals('Transformed'));
    });

    test('ApiResult flatMap method', () {
      final okResult = ApiResult<int>.ok(42);
      final chainedResult = okResult.flatMap(
        (value) => ApiResult<String>.ok('Value: $value'),
      );

      expect(chainedResult.isOk, isTrue);
      expect(chainedResult.data, equals('Value: 42'));
    });

    test('ApiResult flatMap method with error', () {
      final apiErr = ApiErr(
        message: HttpMessage(
          title: 'Server Error',
          details: 'Internal server error',
        ),
      );
      final errResult = ApiResult<int>.err(apiErr);
      final chainedResult = errResult.flatMap(
        (value) => ApiResult<String>.ok('Value: $value'),
      );

      expect(chainedResult.isErr, isTrue);
      expect(chainedResult.errorOrNull, equals(apiErr));
    });

    test('ApiResult flatMap method with error transform', () {
      final apiErr = ApiErr(
        message: HttpMessage(
          title: 'Server Error',
          details: 'Internal server error',
        ),
      );
      final errResult = ApiResult<int>.err(apiErr);
      final chainedResult = errResult.flatMap(
        (value) => ApiResult<String>.ok('Value: $value'),
        (error) => ApiResult<String>.err(
          ApiErr(
            message: HttpMessage(
              title: 'Transformed',
              details: 'Error was transformed',
            ),
          ),
        ),
      );

      expect(chainedResult.isErr, isTrue);
      expect(chainedResult.errorOrNull?.message?.title, equals('Transformed'));
    });

    test('ApiResult.from with successful response', () {
      final response = ApiResponse.ok(
        {'id': '123', 'name': 'John Doe'},
        statusCode: 200,
        headers: {},
      );

      final result = ApiResult.from<User>(
        response: response,
        onData: (data) => User.fromJson(data),
      );

      expect(result.isOk, isTrue);
      expect(result.data.id, equals('123'));
      expect(result.data.name, equals('John Doe'));
    });

    test('ApiResult.from with error response', () {
      final stackTrace = TestStackTrace();
      final apiErr = ApiErr(
        exception: Exception('Network error'),
        stackTrace: stackTrace,
        message: HttpMessage(
          title: 'Connection Error',
          details: 'Failed to connect to the server',
        ),
      );

      final response = ApiResponse.err(apiErr, statusCode: null, headers: {});

      final result = ApiResult.from<User>(
        response: response,
        onData: (data) => User.fromJson(data),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.message?.title, equals('Connection Error'));
      expect(result.errorOrNull?.exception, isA<Exception>());
    });

    test('ApiResult.from with parsing error', () {
      final response = ApiResponse.ok(
        {'id': 123, 'name': null}, // Invalid data that will cause parsing error
        statusCode: 200,
        headers: {},
      );

      final result = ApiResult.from<User>(
        response: response,
        onData: (data) => User.fromJson(data),
      );

      expect(result.isErr, isTrue);
      expect(
        result.errorOrNull?.message?.title,
        equals('Data Processing Error'),
      );
      expect(result.errorOrNull?.message?.details, contains('type'));
    });

    test('ApiResult.fromList with successful response', () {
      final response = ApiResponse.ok(
        [
          {'id': '1', 'name': 'User 1'},
          {'id': '2', 'name': 'User 2'},
        ],
        statusCode: 200,
        headers: {},
      );

      final result = ApiResult.fromList<User>(
        response: response,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
      );

      expect(result.isOk, isTrue);
      expect(result.data.length, equals(2));
      expect(result.data[0].id, equals('1'));
      expect(result.data[1].name, equals('User 2'));
    });

    test('ApiResult.fromList with error response', () {
      final stackTrace = TestStackTrace();
      final apiErr = ApiErr(
        exception: Exception('Network error'),
        stackTrace: stackTrace,
        message: HttpMessage(
          title: 'Connection Error',
          details: 'Failed to connect to the server',
        ),
      );

      final response = ApiResponse.err(apiErr, statusCode: null, headers: {});

      final result = ApiResult.fromList<User>(
        response: response,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.message?.title, equals('Connection Error'));
    });

    test('ApiResult.fromList with parsing error', () {
      final response = ApiResponse.ok(
        [
          {'id': 1, 'name': 'User 1'}, // Invalid data types
          {'id': '2'}, // Missing name
        ],
        statusCode: 200,
        headers: {},
      );

      final result = ApiResult.fromList<User>(
        response: response,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
      );

      expect(result.isErr, isTrue);
      expect(
        result.errorOrNull?.message?.title,
        equals('Data Processing Error'),
      );
      expect(result.errorOrNull?.message?.details, contains('type'));
    });

    test('ApiResult.from with JSON string', () {
      // Probar indirectamente la funcionalidad de _ensureJsonMap
      final jsonString = '{"id":"123","name":"John Doe"}';
      final response = ApiResponse.ok(jsonString, statusCode: 200, headers: {});

      final result = ApiResult.from<User>(
        response: response,
        onData: (data) => User.fromJson(data),
      );

      expect(result.isOk, isTrue);
      expect(result.data.id, equals('123'));
      expect(result.data.name, equals('John Doe'));
    });

    test('ApiResult.fromList with JSON string', () {
      final jsonString =
          '[{"id":"1","name":"User 1"},{"id":"2","name":"User 2"}]';
      final response = ApiResponse.ok(jsonString, statusCode: 200, headers: {});

      final result = ApiResult.fromList<User>(
        response: response,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
      );

      expect(result.isOk, isTrue);
      expect(result.data.length, equals(2));
      expect(result.data[0].id, equals('1'));
      expect(result.data[1].name, equals('User 2'));
    });

    test('ApiResult.from with invalid JSON string', () {
      final invalidJson = '{id:"123",name:John}';
      final response = ApiResponse.ok(
        invalidJson,
        statusCode: 200,
        headers: {},
      );

      final result = ApiResult.from<User>(
        response: response,
        onData: (data) => User.fromJson(data),
      );

      expect(result.isErr, isTrue);
      expect(
        result.errorOrNull?.message?.title,
        equals('Data Processing Error'),
      );
      expect(result.errorOrNull?.message?.details, contains('JSON'));
    });

    test('ApiResult.fromList with invalid JSON string', () {
      final invalidJson = '[{id:"1",name:User 1}]';
      final response = ApiResponse.ok(
        invalidJson,
        statusCode: 200,
        headers: {},
      );

      final result = ApiResult.fromList<User>(
        response: response,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
      );

      expect(result.isErr, isTrue);
      expect(
        result.errorOrNull?.message?.title,
        equals('Data Processing Error'),
      );
      expect(result.errorOrNull?.message?.details, contains('JSON'));
    });
  });

  group('Params Tests', () {
    test('Params basic creation', () {
      final params = Params(
        path: 'users/123',
        header: {'Authorization': 'Bearer token'},
        body: {'name': 'Updated Name'},
      );

      expect(params.path, equals('users/123'));
      expect(params.header?['Authorization'], equals('Bearer token'));
      expect(params.body?['name'], equals('Updated Name'));
    });

    test('Params with minimal fields', () {
      final params = Params(path: 'products');

      expect(params.path, equals('products'));
      expect(params.header, isNull);
      expect(params.body, isNull);
    });
  });
}
