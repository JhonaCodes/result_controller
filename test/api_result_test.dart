
import 'package:test/test.dart';
import 'package:result_controller/result_controller.dart';

// Simple StackTrace for testing
class TestStackTrace implements StackTrace {
  @override
  String toString() => 'test stack trace';
}

// Model class for testing
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
      final apiErr = ApiErr(title: 'Not Found', msm: 'Resource not found');

      final result = ApiResult<int>.err(apiErr);

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.title, equals('Not Found'));
    });

    test('ApiResult when method', () {
      final okResult = ApiResult<int>.ok(42);
      final errResult = ApiResult<int>.err(
        ApiErr(title: 'Server Error', msm: 'Internal server error'),
      );

      final okValue = okResult.when(
        ok: (value) => 'Success: $value',
        err: (error) => 'Error: ${error.msm}',
      );

      final errValue = errResult.when(
        ok: (value) => 'Success: $value',
        err: (error) => 'Error: ${error.msm}',
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
        title: 'Server Error',
        msm: 'Internal server error',
      );
      final errResult = ApiResult<int>.err(apiErr);
      final mappedResult = errResult.map((value) => value.toString());

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull?.title, equals('Server Error'));
    });

    test('ApiResult map method with error transform', () {
      final apiErr = ApiErr(
        title: 'Server Error',
        msm: 'Internal server error',
      );
      final errResult = ApiResult<int>.err(apiErr);
      final mappedResult = errResult.map(
        (value) => value.toString(),
        (error) => ApiErr(title: 'Transformed', msm: 'Error was transformed'),
      );

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull?.title, equals('Transformed'));
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
        title: 'Server Error',
        msm: 'Internal server error',
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
        title: 'Server Error',
        msm: 'Internal server error',
      );
      final errResult = ApiResult<int>.err(apiErr);
      final chainedResult = errResult.flatMap(
        (value) => ApiResult<String>.ok('Value: $value'),
        (error) => ApiResult<String>.err(
          ApiErr(title: 'Transformed', msm: 'Error was transformed'),
        ),
      );

      expect(chainedResult.isErr, isTrue);
      expect(chainedResult.errorOrNull?.title, equals('Transformed'));
    });

    test('ApiResult.fromJson with successful response', () {
      final jsonData = {'id': '123', 'name': 'John Doe'};

      final result = ApiResult.fromJson<User>(
        data: jsonData,
        onData: (data) => User.fromJson(data),
        statusCode: 200,
        headers: {},
      );

      expect(result.isOk, isTrue);
      expect(result.data.id, equals('123'));
      expect(result.data.name, equals('John Doe'));
    });

    test('ApiResult.fromJson with null data', () {
      final result = ApiResult.fromJson<User>(
        data: null,
        onData: (data) => User.fromJson(data),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.title, equals('Error'));
      expect(result.errorOrNull?.msm, equals('No data provided'));
    });

    test('ApiResult.fromJson with parsing error', () {
      final jsonData = {'id': 123, 'name': null}; // Invalid data that will cause parsing error

      final result = ApiResult.fromJson<User>(
        data: jsonData,
        onData: (data) => User.fromJson(data),
        statusCode: 200,
        headers: {},
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.title, equals('Data Processing Error'));
      expect(result.errorOrNull?.msm, contains('type'));
    });

    test('ApiResult.fromJsonList with successful response', () {
      final jsonData = [
        {'id': '1', 'name': 'User 1'},
        {'id': '2', 'name': 'User 2'},
      ];

      final result = ApiResult.fromJsonList<User>(
        data: jsonData,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
        statusCode: 200,
        headers: {},
      );

      expect(result.isOk, isTrue);
      expect(result.data.length, equals(2));
      expect(result.data[0].id, equals('1'));
      expect(result.data[1].name, equals('User 2'));
    });

    test('ApiResult.fromJsonList with null data', () {
      final result = ApiResult.fromJsonList<User>(
        data: null,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.title, equals('Error'));
      expect(result.errorOrNull?.msm, equals('No data provided'));
    });

    test('ApiResult.fromJsonList with parsing error', () {
      final jsonData = [
        {'id': 1, 'name': 'User 1'}, // Invalid data types
        {'id': '2'}, // Missing name
      ];

      final result = ApiResult.fromJsonList<User>(
        data: jsonData,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
        statusCode: 200,
        headers: {},
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.title, equals('Data Processing Error'));
      expect(result.errorOrNull?.msm, contains('type'));
    });

    test('ApiResult.fromJson with JSON string', () {
      // Probar indirectamente la funcionalidad de _ensureJsonMap
      final jsonString = '{"id":"123","name":"John Doe"}';

      final result = ApiResult.fromJson<User>(
        data: jsonString,
        onData: (data) => User.fromJson(data),
        statusCode: 200,
        headers: {},
      );

      expect(result.isOk, isTrue);
      expect(result.data.id, equals('123'));
      expect(result.data.name, equals('John Doe'));
    });

    test('ApiResult.fromJsonList with JSON string', () {
      final jsonString =
          '[{"id":"1","name":"User 1"},{"id":"2","name":"User 2"}]';

      final result = ApiResult.fromJsonList<User>(
        data: jsonString,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
        statusCode: 200,
        headers: {},
      );

      expect(result.isOk, isTrue);
      expect(result.data.length, equals(2));
      expect(result.data[0].id, equals('1'));
      expect(result.data[1].name, equals('User 2'));
    });

    test('ApiResult.fromJson with invalid JSON string', () {
      final invalidJson = '{id:"123",name:John}';

      final result = ApiResult.fromJson<User>(
        data: invalidJson,
        onData: (data) => User.fromJson(data),
        statusCode: 200,
        headers: {},
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.title, equals('Data Processing Error'));
      expect(result.errorOrNull?.msm, contains('JSON'));
    });

    test('ApiResult.fromJsonList with invalid JSON string', () {
      final invalidJson = '[{id:"1",name:User 1}]';

      final result = ApiResult.fromJsonList<User>(
        data: invalidJson,
        onData: (list) => list.map((item) => User.fromJson(item)).toList(),
        statusCode: 200,
        headers: {},
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.title, equals('Data Processing Error'));
      expect(result.errorOrNull?.msm, contains('JSON'));
    });

    test('ApiResult.ok creates successful result', () {
      final result = ApiResult<String>.ok('test');

      expect(result.isOk, isTrue);
      expect(result.data, equals('test'));
      expect(result.errorOrNull, isNull);
    });

    test('ApiResult.err creates error result', () {
      final error = ApiErr(title: 'Test Error', msm: 'Test error details');
      final result = ApiResult<String>.err(error);

      expect(result.isErr, isTrue);
      expect(result.errorOrNull, equals(error));
      expect(() => result.data, throwsStateError);
    });

    test('ApiResult handles null values correctly', () {
      final result = ApiResult<String?>.ok(null);

      expect(result.isOk, isTrue);
      expect(result.data, isNull);
      expect(result.errorOrNull, isNull);
    });

    test('ApiResult preserves type information', () {
      final result = ApiResult<int>.ok(42);

      expect(result.isOk, isTrue);
      expect(result.data, isA<int>());
      expect(result.data, equals(42));
    });

    test('ApiResult.map transforms success value', () {
      final result = ApiResult<int>.ok(42);
      final transformed = result.map(
        (value) => value.toString(),
        (error) => error,
      );

      expect(transformed.isOk, isTrue);
      expect(transformed.data, equals('42'));
    });

    test('ApiResult.map transforms error value', () {
      final error = ApiErr(title: 'Original Error', msm: 'Original details');
      final result = ApiResult<int>.err(error);
      final transformed = result.map(
        (value) => value.toString(),
        (error) => ApiErr(
          title: 'Transformed Error',
          msm: 'Transformed: ${error.msm}',
        ),
      );

      expect(transformed.isErr, isTrue);
      expect(transformed.errorOrNull?.title, equals('Transformed Error'));
      expect(transformed.errorOrNull?.msm, contains('Original details'));
    });

    test('headers are preserved in success response', () {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer token',
        'Custom-Header': 'value',
      };

      final response = ApiResult.ok(
        {'data': 'value'},
        statusCode: 200,
        headers: headers,
      );

      expect(response.headers, equals(headers));
      expect(response.headers['Content-Type'], equals('application/json'));
    });

    test('headers are preserved in error response', () {
      final headers = {
        'Content-Type': 'application/json',
        'WWW-Authenticate': 'Bearer error="invalid_token"',
      };

      final response = ApiResult.err(
        ApiErr(title: 'Error', msm: 'Details'),
        statusCode: 401,
        headers: headers,
      );

      expect(response.headers, equals(headers));
      expect(response.headers['WWW-Authenticate'], contains('invalid_token'));
    });
  });
}
