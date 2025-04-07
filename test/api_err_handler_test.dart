import 'package:flutter_test/flutter_test.dart';

import 'package:result_controller/result_controller.dart';

class MockStackTrace implements StackTrace {
  @override
  String toString() => 'mock stack trace';
}

void main() {
  final header = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer token',
  };
  group('ApiErr Tests', () {
    test('ApiErr basic creation', () {
      final apiResponse =  ApiResponse(
          headers:header,
        statusCode: 404,
        err: ApiErr(
          exception: Exception('Not found'),
          message: HttpMessage(
            title: 'Not Found',
            details: 'The requested resource could not be found',
          ),
        )
      );

      expect(apiResponse.statusCode, equals(404));
      expect(apiResponse.err?.exception.toString(), equals('Exception: Not found'));
      expect(apiResponse.err?.message?.title, equals('Not Found'));
      expect(
        apiResponse.err?.message?.details,
        equals('The requested resource could not be found'),
      );
      expect(apiResponse.err?.message?.details, equals('The requested resource could not be found'));
    });

    test('ApiErr creation with null values', () {
      final apiResponse =  ApiResponse(
          headers:header,
          err: ApiErr()
      );

      expect(apiResponse.statusCode, isNull);
      expect(apiResponse.err?.exception, isNull);
      expect(apiResponse.err?.message, isNull);
      expect(apiResponse.err?.text, equals('Unknown API error'));
    });

    test('ApiErr toString formatting', () {
      final apiResponse =  ApiResponse(
          headers:header,
          statusCode: 400,
          err: ApiErr(
            message: HttpMessage(
              title: 'Validation err',
              details: 'Invalid email format',
            ),
          )
      );


      expect(
        apiResponse.err.toString(),
        equals('Validation err: Invalid email format'),
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

        ),
      );

      expect(response.err?.exception, equals(exception));
      expect(response.err?.stackTrace, equals(stackTrace));
      expect(response.data, equals(data));
    });

    test('Httperr with null exception', () {
      final stackTrace = MockStackTrace();

      // Debería compilar y ejecutarse sin erres
      final httperr = ApiErr(exception: null, stackTrace: stackTrace);

      final response = ApiResponse(
        err: httperr
      );

      expect(response.err?.exception, isNull);
      expect(response.err?.stackTrace, equals(stackTrace));
      expect(response.data, isNull);
    });

    test('Httperr with null data', () {
      final exception = Exception('Network err');
      final stackTrace = MockStackTrace();
      final response = ApiResponse(
          err: ApiErr(
            exception: exception,
            stackTrace: stackTrace,
          )
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
      final json = {
        'title': 'err Title',
        'details': 'err details',
      };

      final message = HttpMessage.fromJson(json);

      expect(message.title, equals('err Title'));
      expect(message.details, equals('err details'));
    });

    test('HttpMessage.fromJson with message field instead of content', () {
      final json = {
        'title': 'err Title',
        'message': 'err message',
      };

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

      final response = ApiResponse( err: apiError );


      expect(response.err?.message?.title, equals('Connection err'));
      expect(response.err?.message?.details, equals('Could not connect to the server'));
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
