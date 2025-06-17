import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/src/api_err_handler.dart';
import 'package:result_controller/src/api_response_handler.dart';

enum TypExceptionData { type1, type2 }

class MockStackTrace implements StackTrace {
  @override
  String toString() => 'mock stack trace';
}

void main() {
  group('ApiErr Tests', () {
    test('ApiErr creation with all fields', () {
      final stackTrace = StackTrace.current;
      final exception = Exception('Test exception');

      final error = ApiErr(
        exception: exception,
        msm: 'Test error details',
        title: 'Test Error',
        stackTrace: stackTrace,
      );

      expect(error.exception, equals(exception));
      expect(error.msm, equals('Test error details'));
      expect(error.stackTrace, equals(stackTrace));
      expect(error.toString(), contains('Test Error: Test error details'));
    });

    test('ApiErr creation with minimal fields', () {
      final error = ApiErr(msm: 'Internal server error', title: 'Server Error');

      expect(error.exception, isNull);
      expect(error.title, equals('Server Error'));
      expect(error.msm, equals('Internal server error'));
      expect(error.stackTrace, isNull);
      expect(error.toString(), equals('Server Error: Internal server error'));
    });

    test('ApiErr creation with exception only', () {
      final exception = Exception('Test exception');
      final error = ApiErr(exception: exception);

      expect(error.exception, equals(exception));
      expect(error.msm, isNull);
      expect(error.stackTrace, isNull);
      expect(error.exception.toString(), equals('Exception: Test exception'));
    });

    test('ApiErr toString with stack trace', () {
      final stackTrace = StackTrace.current;
      final error = ApiErr(
        msm: 'Test error details',
        title: 'Test Error',
        stackTrace: stackTrace,
      );

      final errorString = error.toString();
      expect(errorString, contains('Test Error: Test error details'));
      expect(errorString, contains('StackTrace:'));
      expect(errorString, contains(stackTrace.toString()));
    });

    test('ApiErr toString with exception and msm', () {
      final error = ApiErr(
        exception: Exception('Test exception'),
        msm: 'Invalid input',
        title: 'Validation Error',
      );

      expect(error.toString(), equals('Validation Error: Invalid input'));
    });

    test('ApiErr toString with exception only', () {
      final error = ApiErr(exception: Exception('Test exception'));

      expect(error.exception.toString(), equals('Exception: Test exception'));
    });

    test('ApiErr toString with no fields', () {
      final error = ApiErr();

      expect(error.toString(), equals('Unknown API error'));
    });
  });

  group('Httperr Tests', () {
    test('Httperr basic creation', () {
      final exception = Exception('Network err');
      final stackTrace = MockStackTrace();
      final data = {
        'title': 'Connection err',
        'details': 'Failed to connect to server',
      };

      final response = ApiResponse(
        data: data,
        err: ApiErr(
          exception: exception,
          stackTrace: stackTrace,
          title: 'Connection err',
          msm: 'Failed to connect to server',
        ),
        headers: {},
      );

      expect(response.err?.exception, equals(exception));
      expect(response.err?.stackTrace, equals(stackTrace));
      expect(response.data, equals(data));
    });

    test('Httperr with null exception', () {
      final stackTrace = MockStackTrace();

      // Debería compilar y ejecutarse sin erres
      final httperr = ApiErr(exception: null, stackTrace: stackTrace);

      final response = ApiResponse(err: httperr, headers: {});

      expect(response.err?.exception, isNull);
      expect(response.err?.stackTrace, equals(stackTrace));
      expect(response.data, isNull);
    });

    test('Httperr with null data', () {
      final exception = Exception('Network err');
      final stackTrace = MockStackTrace();
      final response = ApiResponse(
        err: ApiErr(exception: exception, stackTrace: stackTrace),
        headers: {},
      );

      expect(response.err?.exception, equals(exception));
      expect(response.err?.stackTrace, equals(stackTrace));
      expect(response.data, isNull);
    });
  });
}
