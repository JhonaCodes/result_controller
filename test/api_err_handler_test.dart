import 'package:flutter_test/flutter_test.dart';

import 'package:result_controller/result_controller.dart';

class MockStackTrace implements StackTrace {
  @override
  String toString() => 'mock stack trace';
}

void main() {
  group('ApiErr Tests', () {
    test('ApiErr basic creation', () {
      final apiErr = ApiErr(
        statusCode: 404,
        exception: Exception('Not found'),
        message: HttpMessage(
          success: false,
          title: 'Not Found',
          details: 'The requested resource could not be found',
        ),
      );

      expect(apiErr.statusCode, equals(404));
      expect(apiErr.exception.toString(), equals('Exception: Not found'));
      expect(apiErr.message?.title, equals('Not Found'));
      expect(
        apiErr.message?.details,
        equals('The requested resource could not be found'),
      );
      expect(apiErr.error, equals('The requested resource could not be found'));
    });

    test('ApiErr creation with null values', () {
      final apiErr = ApiErr();

      expect(apiErr.statusCode, isNull);
      expect(apiErr.exception, isNull);
      expect(apiErr.message, isNull);
      expect(apiErr.error, equals('Unknown API error'));
    });

    test('ApiErr.fromHttpError', () {
      final httpError = HttpErr(
        exception: Exception('Network timeout'),
        stackTrace: MockStackTrace(),
        data: HttpMessage(
          success: false,
          title: 'Connection Error',
          details: 'Could not connect to the server',
        ),
      );

      final apiErr = ApiErr.fromHttpError(httpError);

      expect(apiErr.exception.toString(), equals('Exception: Network timeout'));
      expect(apiErr.message?.title, equals('Connection Error'));
      expect(
        apiErr.message?.details,
        equals('Could not connect to the server'),
      );
      expect(apiErr.error, equals('Could not connect to the server'));
      expect(apiErr.stackTrace, equals(httpError.stackTrace));
    });

    test('ApiErr toString formatting', () {
      final apiErr = ApiErr(
        statusCode: 400,
        message: HttpMessage(
          success: false,
          title: 'Validation Error',
          details: 'Invalid email format',
        ),
      );

      expect(
        apiErr.toString(),
        equals('Status: 400 | Validation Error: Invalid email format'),
      );
    });

    test('ApiErr toString with null values', () {
      final apiErr = ApiErr();

      expect(apiErr.toString(), equals('Unknown API error'));
    });

    test('ApiErr toString with only exception', () {
      final apiErr = ApiErr(exception: Exception('Test exception'));

      expect(apiErr.toString(), equals('Error: Exception: Test exception'));
    });

    test('ApiErr toString with status code only', () {
      final apiErr = ApiErr(statusCode: 500);

      expect(apiErr.toString(), equals('Status: 500 | Unknown API error'));
    });

    test('ApiErr toString with stack trace', () {
      final stackTrace = MockStackTrace();
      final apiErr = ApiErr(
        statusCode: 500,
        message: HttpMessage(
          success: false,
          title: 'Server Error',
          details: 'Internal server error',
        ),
        stackTrace: stackTrace,
      );

      expect(
        apiErr.toString(),
        contains('Status: 500 | Server Error: Internal server error'),
      );
      expect(apiErr.toString(), contains('mock stack trace'));
    });
  });

  group('HttpError Tests', () {
    test('HttpError basic creation', () {
      final exception = Exception('Network error');
      final stackTrace = MockStackTrace();
      final data = HttpMessage(
        success: false,
        title: 'Connection Error',
        details: 'Failed to connect to server',
      );

      final httpError = HttpErr(
        exception: exception,
        stackTrace: stackTrace,
        data: data,
      );

      expect(httpError.exception, equals(exception));
      expect(httpError.stackTrace, equals(stackTrace));
      expect(httpError.data, equals(data));
    });

    test('HttpError with null exception', () {
      final stackTrace = MockStackTrace();

      // Debería compilar y ejecutarse sin errores
      final httpError = HttpErr(exception: null, stackTrace: stackTrace);

      expect(httpError.exception, isNull);
      expect(httpError.stackTrace, equals(stackTrace));
      expect(httpError.data, isNull);
    });

    test('HttpError with null data', () {
      final exception = Exception('Network error');
      final stackTrace = MockStackTrace();

      final httpError = HttpErr(exception: exception, stackTrace: stackTrace);

      expect(httpError.exception, equals(exception));
      expect(httpError.stackTrace, equals(stackTrace));
      expect(httpError.data, isNull);
    });
  });

  group('HttpMessage Tests', () {
    test('HttpMessage basic creation', () {
      final message = HttpMessage(
        success: true,
        title: 'Success',
        details: 'Operation completed successfully',
      );

      expect(message.success, isTrue);
      expect(message.title, equals('Success'));
      expect(message.details, equals('Operation completed successfully'));
    });

    test('HttpMessage with default success value', () {
      final message = HttpMessage(title: 'Title', details: 'Details');

      expect(message.success, isTrue);
      expect(message.title, equals('Title'));
      expect(message.details, equals('Details'));
    });

    test('HttpMessage.fromJson with all fields', () {
      final json = {
        'success': false,
        'title': 'Error Title',
        'content': 'Error details',
      };

      final message = HttpMessage.fromJson(json);

      expect(message.success, isFalse);
      expect(message.title, equals('Error Title'));
      expect(message.details, equals('Error details'));
    });

    test('HttpMessage.fromJson with message field instead of content', () {
      final json = {
        'success': false,
        'title': 'Error Title',
        'message': 'Error message',
      };

      final message = HttpMessage.fromJson(json);

      expect(message.success, isFalse);
      expect(message.title, equals('Error Title'));
      expect(message.details, equals('Error message'));
    });

    test('HttpMessage.fromJson with default values', () {
      final Map<String, dynamic> json = {};

      final message = HttpMessage.fromJson(json);

      expect(message.success, isFalse);
      expect(message.title, equals('Error'));
      expect(message.details, equals('Unknown error'));
    });

    test('HttpMessage.toJson', () {
      final message = HttpMessage(
        success: true,
        title: 'Success',
        details: 'Operation completed successfully',
      );

      final json = message.toJson();

      expect(json['success'], isTrue);
      expect(json['title'], equals('Success'));
      expect(json['content'], equals('Operation completed successfully'));
    });

    test('HttpMessage.fromException', () {
      final exception = Exception('Test exception');
      final message = HttpMessage.fromException(exception);

      expect(message.success, isFalse);
      expect(message.title, equals('Error'));
      expect(message.details, equals('Exception: Test exception'));
    });

    test('HttpMessage.fromError with data', () {
      final httpError = HttpErr(
        exception: Exception('Network timeout'),
        stackTrace: MockStackTrace(),
        data: HttpMessage(
          success: false,
          title: 'Connection Error',
          details: 'Could not connect to the server',
        ),
      );

      final message = HttpMessage.fromError(httpError);

      expect(message.success, isFalse);
      expect(message.title, equals('Connection Error'));
      expect(message.details, equals('Could not connect to the server'));
    });

    test('HttpMessage.fromError without data', () {
      final httpError = HttpErr(
        exception: Exception('Network timeout'),
        stackTrace: MockStackTrace(),
      );

      final message = HttpMessage.fromError(httpError);

      expect(message.success, isFalse);
      expect(message.title, equals('Error'));
      expect(message.details, equals('Exception: Network timeout'));
    });

    test('HttpMessage.fromError with null exception', () {
      final httpError = HttpErr(exception: null, stackTrace: MockStackTrace());

      final message = HttpMessage.fromError(httpError);

      expect(message.success, isFalse);
      expect(message.title, equals('Error'));
      expect(message.details, equals('Exception: Unknown error'));
    });
  });
}
