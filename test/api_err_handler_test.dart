import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/src/api_err_handler.dart';
import 'package:result_controller/src/api_handler.dart';
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
      final message = HttpMessage(
        title: 'Test Error',
        details: 'Test error details',
      );

      final error = ApiErr(
        exception: exception,
        message: message,
        stackTrace: stackTrace,
      );

      expect(error.exception, equals(exception));
      expect(error.message, equals(message));
      expect(error.stackTrace, equals(stackTrace));
      expect(error.toString(), contains('Test Error: Test error details'));
    });

    test('ApiErr creation with minimal fields', () {
      final error = ApiErr(
        message: HttpMessage(
          title: 'Server Error',
          details: 'Internal server error',
        ),
      );

      expect(error.exception, isNull);
      expect(error.message?.title, equals('Server Error'));
      expect(error.message?.details, equals('Internal server error'));
      expect(error.stackTrace, isNull);
      expect(error.toString(), equals('Server Error: Internal server error'));
    });

    test('ApiErr creation with exception only', () {
      final exception = Exception('Test exception');
      final error = ApiErr(exception: exception);

      expect(error.exception, equals(exception));
      expect(error.message, isNull);
      expect(error.stackTrace, isNull);
      expect(error.exception.toString(), equals('Exception: Test exception'));
    });

    test('ApiErr toString with stack trace', () {
      final stackTrace = StackTrace.current;
      final error = ApiErr(
        message: HttpMessage(
          title: 'Test Error',
          details: 'Test error details',
        ),
        stackTrace: stackTrace,
      );

      final errorString = error.toString();
      expect(errorString, contains('Test Error: Test error details'));
      expect(errorString, contains('StackTrace:'));
      expect(errorString, contains(stackTrace.toString()));
    });

    test('ApiErr toString with exception and message', () {
      final error = ApiErr(
        exception: Exception('Test exception'),
        message: HttpMessage(
          title: 'Validation Error',
          details: 'Invalid input',
        ),
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

    test('ApiErr registry operations', () {
      final testException = Exception('Test');

      final testError = ApiErr(
        exception: testException,
        errorType: Exception,
        message: HttpMessage(title: 'Test Error', details: 'Test details'),
      );

      // Add a mapping
      ApiErr.registerAllExceptionTypes({Exception: testError});

      // Verify the mapping was added
      final mappedError = ApiErr.fromExceptionType(Exception);
      expect(mappedError.message?.title, equals('Test Error'));
      expect(mappedError.message?.details, equals('Test details'));
    });

    test('ApiErr registry by status code and type of exception operations', () {
      // Add a mapping
      ApiErr.registerStatusTypeErrors(
        SocketException,
        [501, 502, 505],
        [TypExceptionData.type1],
        ApiErr(
          errorType: TypExceptionData.type1,
          message: HttpMessage(
            title: "Server Error",
            details: "Server not found",
          ),
        ),
      );

      // Verify the mapping was added
      final mappedError = ApiErr.fromStatusAndType(505, TypExceptionData.type1);
      expect(mappedError.message?.title, equals('Server Error'));
      expect(mappedError.message?.details, equals('Server not found'));
    });

    test('ApiErr registry with multiple mappings', () {
      // Clear any existing mappings
      ApiErr.registerAllExceptionTypes({});

      final exception1 = Exception('Test 1');
      final exception2 = SocketException('Test 2');
      final error1 = ApiErr(
        exception: exception1,
        errorType: Exception,
        message: HttpMessage(title: 'Error 1', details: 'Details 1'),
      );
      final error2 = ApiErr(
        exception: exception2,
        errorType: SocketException,
        message: HttpMessage(title: 'Error 2', details: 'Details 2'),
      );

      // Add multiple mappings
      ApiErr.registerAllExceptionTypes({
        Exception: error1,
        SocketException: error2,
      });

      // Verify the mappings were added
      final mappedError1 = ApiErr.fromExceptionType(Exception);
      final mappedError2 = ApiErr.fromExceptionType(SocketException);
      expect(mappedError1.message?.title, equals('Error 1'));
      expect(mappedError1.message?.details, equals('Details 1'));
      expect(mappedError2.message?.title, equals('Error 2'));
      expect(mappedError2.message?.details, equals('Details 2'));
    });
  });

  group('Httperr Tests', () {
    test('Httperr basic creation', () {
      final exception = Exception('Network err');
      final stackTrace = MockStackTrace();
      final data = HttpMessage(
        title: 'Connection err',
        details: 'Failed to connect to server',
      );

      final response = ApiResponse(
        data: data,
        err: ApiErr(
          exception: exception,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Connection err',
            details: 'Failed to connect to server',
          ),
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

  group('HttpMessage Tests', () {
    test('HttpMessage basic creation', () {
      final message = HttpMessage(
        title: 'Success',
        details: 'Operation completed successfully',
      );

      expect(message.title, equals('Success'));
      expect(message.details, equals('Operation completed successfully'));
    });

    test('HttpMessage with default success value', () {
      final message = HttpMessage(title: 'Title', details: 'Details');

      expect(message.title, equals('Title'));
      expect(message.details, equals('Details'));
    });

    test('HttpMessage.fromJson with all fields', () {
      final json = {'title': 'err Title', 'details': 'err details'};

      final message = HttpMessage.fromJson(json);

      expect(message.title, equals('err Title'));
      expect(message.details, equals('err details'));
    });

    test('HttpMessage.fromJson with message field instead of content', () {
      final json = {'title': 'err Title', 'message': 'err message'};

      final message = HttpMessage.fromJson(json);

      expect(message.title, equals('err Title'));
      expect(message.details, equals('err message'));
    });

    test('HttpMessage.fromJson with default values', () {
      final Map<String, dynamic> json = {};

      final message = HttpMessage.fromJson(json);

      expect(message.title, equals('Error'));
      expect(message.details, equals('Unknown error'));
    });

    test('HttpMessage.toJson', () {
      final message = HttpMessage(
        title: 'Success',
        details: 'Operation completed successfully',
      );

      final json = message.toJson();

      expect(json['title'], equals('Success'));
      expect(json['message'], equals('Operation completed successfully'));
    });

    test('HttpMessage.fromException', () {
      final exception = Exception('Test exception');
      final message = HttpMessage.fromException(exception);

      expect(message.title, equals('Error'));
      expect(message.details, equals('Exception: Test exception'));
    });

    test('HttpMessage.fromerr with data', () {
      final apiError = ApiErr(
        exception: Exception('Network timeout'),
        stackTrace: MockStackTrace(),
        message: HttpMessage(
          title: 'Connection err',
          details: 'Could not connect to the server',
        ),
      );

      final response = ApiResponse(err: apiError, headers: {});

      expect(response.err?.message?.title, equals('Connection err'));
      expect(
        response.err?.message?.details,
        equals('Could not connect to the server'),
      );
    });

    test('HttpMessage.ApiErr without data', () {
      final apiErr = ApiErr(
        exception: Exception('Network timeout'),
        stackTrace: MockStackTrace(),
      );

      final message = HttpMessage.fromError(apiErr);

      expect(message.title, equals('Error'));
      expect(message.details, equals('Exception: Network timeout'));
    });

    test('HttpMessage.fromException with null exception', () {
      final apiErr = ApiErr(exception: null, stackTrace: MockStackTrace());

      final message = HttpMessage.fromException(apiErr);

      expect(message.title, equals('Error'));
      expect(apiErr.message?.details, equals(null));
    });
  });
}
