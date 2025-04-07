import 'package:flutter_test/flutter_test.dart';

import 'package:result_controller/result_controller.dart';

class MockStackTrace implements StackTrace {
  @override
  String toString() => 'mock stack trace';
}

void main() {
  group('Result Class Tests', () {
    test('Ok result should return correct value', () {
      final result = Ok<int, String>(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.data, equals(42));
      expect(result.errorOrNull, isNull);
    });

    test('Err result should return correct error', () {
      final error = 'Error message';
      final result = Err<int, String>(error);

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.errorOrNull, equals(error));
      expect(() => result.data, throwsStateError);
    });

    test('when method should call correct function', () {
      final okResult = Ok<int, String>(42);
      final errResult = Err<int, String>('Error message');

      final okValue = okResult.when(
        ok: (value) => 'Success: $value',
        err: (error) => 'Failure: $error',
      );

      final errValue = errResult.when(
        ok: (value) => 'Success: $value',
        err: (error) => 'Failure: $error',
      );

      expect(okValue, equals('Success: 42'));
      expect(errValue, equals('Failure: Error message'));
    });

    test('map method should transform success value', () {
      final okResult = Ok<int, String>(42);
      final mappedResult = okResult.map((value) => value * 2);

      expect(mappedResult.isOk, isTrue);
      expect(mappedResult.data, equals(84));
    });

    test('map method should preserve error', () {
      final errResult = Err<int, String>('Error message');
      final mappedResult = errResult.map((value) => value * 2);

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull, equals('Error message'));
    });

    test('map method should transform error if errorTransform is provided', () {
      final errResult = Err<int, String>('Error message');
      final mappedResult = errResult.map(
        (value) => value * 2,
        (error) => 'Transformed: $error',
      );

      expect(mappedResult.isErr, isTrue);
      expect(mappedResult.errorOrNull, equals('Transformed: Error message'));
    });

    test('flatMap method should chain results in success case', () {
      final okResult = Ok<int, String>(42);
      final chainedResult = okResult.flatMap(
        (value) => Ok<String, String>('Value is $value'),
      );

      expect(chainedResult.isOk, isTrue);
      expect(chainedResult.data, equals('Value is 42'));
    });

    test('flatMap method should preserve error', () {
      final errResult = Err<int, String>('Error message');
      final chainedResult = errResult.flatMap(
        (value) => Ok<String, String>('Value is $value'),
      );

      expect(chainedResult.isErr, isTrue);
      expect(chainedResult.errorOrNull, equals('Error message'));
    });

    test(
      'flatMap method should transform error if errorTransform is provided',
      () {
        final errResult = Err<int, String>('Error message');
        final chainedResult = errResult.flatMap(
          (value) => Ok<String, String>('Value is $value'),
          (error) => Err<String, String>('Transformed: $error'),
        );

        expect(chainedResult.isErr, isTrue);
        expect(chainedResult.errorOrNull, equals('Transformed: Error message'));
      },
    );

    test('trySync method should wrap successful operation', () {
      final result = Result.trySync(() => 42);

      expect(result.isOk, isTrue);
      expect(result.data, equals(42));
    });

    test('trySync method should wrap exception', () {
      final result = Result.trySync(() => throw Exception('Test exception'));

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.err, contains('Exception: Test exception'));
    });

    test('trySyncMap method should use custom error mapper', () {
      final result = Result.trySyncMap<int, String>(
        () => throw Exception('Test exception'),
        (error, stack) => 'Custom error: $error',
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull, contains('Custom error:'));
    });

    test('tryAsync method should wrap successful async operation', () async {
      final result = await Result.tryAsync(() async => 42);

      expect(result.isOk, isTrue);
      expect(result.data, equals(42));
    });

    test('tryAsync method should wrap async exception', () async {
      final result = await Result.tryAsync(
        () async => throw Exception('Test exception'),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.err, contains('Exception: Test exception'));
    });

    test(
      'tryAsyncMap method should use custom error mapper for async operations',
      () async {
        final result = await Result.tryAsyncMap<int, String>(
          () async => throw Exception('Test exception'),
          (error, stack) => 'Custom async error: $error',
        );

        expect(result.isErr, isTrue);
        expect(result.errorOrNull, contains('Custom async error:'));
      },
    );

    test('equals and hashCode should work correctly for Ok', () {
      final result1 = Ok<int, String>(42);
      final result2 = Ok<int, String>(42);
      final result3 = Ok<int, String>(43);

      expect(result1 == result2, isTrue);
      expect(result1 == result3, isFalse);
      expect(result1.hashCode == result2.hashCode, isTrue);
    });

    test('equals and hashCode should work correctly for Err', () {
      final result1 = Err<int, String>('Error');
      final result2 = Err<int, String>('Error');
      final result3 = Err<int, String>('Different error');

      expect(result1 == result2, isTrue);
      expect(result1 == result3, isFalse);
      expect(result1.hashCode == result2.hashCode, isTrue);
    });

    test('toString should format correctly for Ok', () {
      final result = Ok<int, String>(42);

      expect(result.toString(), equals('Ok(42)'));
    });

    test('toString should format correctly for Err', () {
      final result = Err<int, String>('Error message');

      expect(result.toString(), equals('Err(Error message)'));
    });
  });

  group('ResultError Tests', () {
    test('ResultError basic creation', () {
      final error = ResultErr('Test error');

      expect(error.err, equals('Test error'));
      expect(error.stackTrace, isNull);
      expect(error.toString(), equals('Test error'));
    });

    test('ResultError with stack trace', () {
      final stackTrace = MockStackTrace();
      final error = ResultErr('Test error', stackTrace: stackTrace);

      expect(error.err, equals('Test error'));
      expect(error.stackTrace, equals(stackTrace));
      expect(error.toString(), contains('Test error'));
      expect(error.toString(), contains('mock stack trace'));
    });

    test('GenericResultError with original error', () {
      final originalError = Exception('Original exception');
      final stackTrace = MockStackTrace();
      final error = GenericResultError(
        'Test error',
        originalError,
        stackTrace: stackTrace,
      );

      expect(error.err, equals('Test error'));
      expect(error.originalError, equals(originalError));
      expect(error.stackTrace, equals(stackTrace));
      expect(error.toString(), contains('Test error'));
      expect(error.toString(), contains('Original error:'));
      expect(error.toString(), contains('mock stack trace'));
    });
  });
}
