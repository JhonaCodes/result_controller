import 'package:flutter_test/flutter_test.dart';
import 'package:result_handler/result_handler.dart';

// Mock classes for testing
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'].toString(), name: json['name'] as String);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

void main() {
  group('FutureResultExtensions', () {
    test('map transforms successful Future Result', () async {
      final futureResult = Future.value(Ok<int, String>(42));

      final mappedResult = await futureResult.map((value) => value * 2);

      expect(mappedResult.isOk, isTrue);
      expect(mappedResult.data, equals(84));
    });

    test('map preserves error in Future Result', () async {
      final futureResult = Future.value(Err<int, String>('Error'));

      final mappedResult = await futureResult.map((value) => value * 2);

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull, equals('Error'));
    });

    test('flatMap chains successful Future Results', () async {
      final futureResult = Future.value(Ok<int, String>(42));

      final chainedResult = await futureResult.flatMap((value) async {
        return Ok<String, String>('Value is $value');
      });

      expect(chainedResult.isOk, isTrue);
      expect(chainedResult.data, equals('Value is 42'));
    });

    test('flatMap preserves error in Future Result', () async {
      final futureResult = Future.value(Err<int, String>('Error'));

      final chainedResult = await futureResult.flatMap((value) async {
        return Ok<String, String>('Value is $value');
      });

      expect(chainedResult.isErr, isTrue);
      expect(chainedResult.errorOrNull, equals('Error'));
    });
  });

  group('ResultExtensions', () {
    test('mapError transforms error value', () {
      final okResult = Ok<int, String>(42);
      final errResult = Err<int, String>('Original Error');

      final mappedOkResult = okResult.mapError((error) => 'Transformed Error');
      final mappedErrResult = errResult.mapError(
        (error) => 'Transformed Error',
      );

      expect(mappedOkResult.isOk, isTrue);
      expect(mappedOkResult.data, equals(42));

      expect(mappedErrResult.isErr, isTrue);
      expect(mappedErrResult.errorOrNull, equals('Transformed Error'));
    });

    test('recover converts error to success', () {
      final okResult = Ok<int, String>(42);
      final errResult = Err<int, String>('Error');

      final recoveredOkResult = okResult.recover((error) => Ok(100));
      final recoveredErrResult = errResult.recover((error) => Ok(100));

      expect(recoveredOkResult.isOk, isTrue);
      expect(recoveredOkResult.data, equals(42));

      expect(recoveredErrResult.isOk, isTrue);
      expect(recoveredErrResult.data, equals(100));
    });

    test('getOrElse returns value or alternative', () {
      final okResult = Ok<int, String>(42);
      final errResult = Err<int, String>('Error');

      final okValue = okResult.getOrElse((error) => 0);
      final errValue = errResult.getOrElse((error) => 0);

      expect(okValue, equals(42));
      expect(errValue, equals(0));
    });

    test('getOrDefault returns value or default', () {
      final okResult = Ok<int, String>(42);
      final errResult = Err<int, String>('Error');

      final okValue = okResult.getOrDefault(0);
      final errValue = errResult.getOrDefault(0);

      expect(okValue, equals(42));
      expect(errValue, equals(0));
    });
  });

  group('ResultCollectionExtensions', () {
    test('mapEach transforms list items', () {
      final okResult = Ok<List<int>, String>([1, 2, 3]);

      final mappedResult = okResult.mapEach((item) => item * 2);

      expect(mappedResult.isOk, isTrue);
      expect(mappedResult.data, equals([2, 4, 6]));
    });

    test('mapEach preserves error', () {
      final errResult = Err<List<int>, String>('Error');

      final mappedResult = errResult.mapEach((item) => item * 2);

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull, equals('Error'));
    });

    test('filter selects list items', () {
      final okResult = Ok<List<int>, String>([1, 2, 3, 4, 5]);

      final filteredResult = okResult.filter((item) => item % 2 == 0);

      expect(filteredResult.isOk, isTrue);
      expect(filteredResult.data, equals([2, 4]));
    });

    test('filter preserves error', () {
      final errResult = Err<List<int>, String>('Error');

      final filteredResult = errResult.filter((item) => item % 2 == 0);

      expect(filteredResult.isErr, isTrue);
      expect(filteredResult.errorOrNull, equals('Error'));
    });
  });

  group('ApiResponseExtensions', () {
    test('toResult converts successful ApiResponse', () {
      final apiResponse = ApiResponse.success({
        'id': '123',
        'name': 'John Doe',
      }, statusCode: 200);

      final result = apiResponse.toResult(User.fromJson);

      expect(result.isOk, isTrue);
      expect(result.data.id, equals('123'));
      expect(result.data.name, equals('John Doe'));
    });

    test('toResult converts failed ApiResponse', () {
      final apiResponse = ApiResponse.failure(
        HttpError(
          exception: Exception('Network error'),
          stackTrace: StackTrace.current,
          data: HttpMessage(
            success: false,
            title: 'Error',
            details: 'Connection failed',
          ),
        ),
        statusCode: 500,
      );

      final result = apiResponse.toResult(User.fromJson);

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.message?.title, equals('Error'));
    });

    test('toListResult converts successful ApiResponse', () {
      final apiResponse = ApiResponse.success([
        {'id': '1', 'name': 'John'},
        {'id': '2', 'name': 'Jane'},
      ], statusCode: 200);

      final result = apiResponse.toListResult(
        (items) => items.map(User.fromJson).toList(),
      );

      expect(result.isOk, isTrue);
      expect(result.data.length, equals(2));
      expect(result.data[0].id, equals('1'));
      expect(result.data[1].name, equals('Jane'));
    });

    test('toListResult converts failed ApiResponse', () {
      final apiResponse = ApiResponse.failure(
        HttpError(
          exception: Exception('Network error'),
          stackTrace: StackTrace.current,
          data: HttpMessage(
            success: false,
            title: 'Error',
            details: 'Connection failed',
          ),
        ),
        statusCode: 500,
      );

      final result = apiResponse.toListResult(
        (items) => items.map(User.fromJson).toList(),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.message?.title, equals('Error'));
    });
  });
}
