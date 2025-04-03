import 'package:result_handler/src/core/result_handler.dart';

import 'api_handler.dart';

/// Represents an API error with detailed information
///
/// This class extends the base ResultError class and provides additional
/// API-specific error information such as HTTP status codes and user-friendly messages.
/// It can be used for comprehensive error handling and logging in API operations.
///
/// Example:
/// ```dart
/// // Create an API error with status code and message
/// final error = ApiErr(
///   statusCode: 404,
///   message: HttpMessage(
///     success: false,
///     title: 'Not Found',
///     details: 'The requested resource could not be found'
///   ),
///   stackTrace: StackTrace.current,
/// );
///
/// // Log the error
/// print(error.toString());
///
/// // Handle the error based on status code
/// if (error.statusCode == 401 || error.statusCode == 403) {
///   // Handle authentication/authorization errors
///   navigateToLogin();
/// } else if (error.statusCode == 404) {
///   // Handle not found
///   showNotFoundMessage();
/// } else {
///   // Handle other errors
///   showGenericErrorMessage(error.message?.details);
/// }
/// ```
class ApiErr extends ResultError {
  /// HTTP status code if available
  ///
  /// Common status codes:
  /// - 200-299: Success responses
  /// - 400: Bad request (client error)
  /// - 401: Unauthorized (authentication needed)
  /// - 403: Forbidden (authenticated but not authorized)
  /// - 404: Not found
  /// - 500-599: Server errors
  final int? statusCode;

  /// Original exception
  ///
  /// This can be any exception that was caught during the API operation,
  /// such as a network error, parsing error, etc.
  final Object? exception;

  /// User-friendly message
  ///
  /// This provides a structured message that can be displayed to the user.
  /// It includes a title and detailed description of the error.
  final HttpMessage? message;

  /// Creates a new API error
  ///
  /// Parameters:
  /// - [statusCode]: Optional HTTP status code
  /// - [exception]: Optional original exception
  /// - [message]: Optional user-friendly message
  /// - [stackTrace]: Optional stack trace for debugging
  ///
  /// The base error message is derived from the message details, exception
  /// string, or a default message if neither is available.
  ///
  /// Example:
  /// ```dart
  /// final apiError = ApiErr(
  ///   statusCode: 500,
  ///   exception: e,
  ///   message: HttpMessage(
  ///     success: false,
  ///     title: 'Server Error',
  ///     details: 'An unexpected error occurred on the server'
  ///   ),
  ///   stackTrace: stackTrace,
  /// );
  /// ```
  ApiErr({
    this.statusCode,
    this.exception,
    this.message,
    StackTrace? stackTrace,
  }) : super(
      message?.details ?? exception?.toString() ?? 'Unknown API error',
      stackTrace: stackTrace
  );

  /// Creates an API error from an HTTP error
  ///
  /// This factory constructor converts an HttpError to an ApiErr,
  /// preserving the original exception, message, and stack trace.
  ///
  /// Example:
  /// ```dart
  /// final httpError = HttpError(
  ///   exception: Exception('Network timeout'),
  ///   stackTrace: StackTrace.current,
  ///   data: HttpMessage(
  ///     success: false,
  ///     title: 'Connection Error',
  ///     details: 'Could not connect to the server'
  ///   ),
  /// );
  ///
  /// final apiError = ApiErr.fromHttpError(httpError);
  /// ```
  factory ApiErr.fromHttpError(HttpError error) {
    return ApiErr(
      exception: error.exception,
      message: error.data,
      stackTrace: error.stackTrace,
    );
  }

  /// Provides a formatted string representation of the error
  ///
  /// The string includes the status code, error message, and stack trace
  /// (if available), formatted in a readable way that's useful for
  /// logging and debugging.
  ///
  /// Example:
  /// ```dart
  /// final error = ApiErr(
  ///   statusCode: 400,
  ///   message: HttpMessage(
  ///     success: false,
  ///     title: 'Validation Error',
  ///     details: 'Invalid email format'
  ///   ),
  /// );
  ///
  /// print(error.toString());
  /// // Output: "Status: 400 | Validation Error: Invalid email format"
  /// ```
  @override
  String toString() {
    final parts = <String>[];

    if (statusCode != null) {
      parts.add('Status: $statusCode');
    }

    if (message != null) {
      parts.add('${message!.title}: ${message!.details}');
    } else if (exception != null) {
      parts.add('Error: ${exception.toString()}');
    } else {
      parts.add('Unknown API error');
    }

    final result = parts.join(' | ');

    if (stackTrace != null) {
      return '$result\n\nStackTrace:\n$stackTrace';
    }

    return result;
  }
}

/// HTTP error details
///
/// This class encapsulates the details of an HTTP error, including the
/// original exception, stack trace, and user-friendly message data.
/// It's typically used as an intermediate representation of API errors
/// before they're converted to ApiErr objects.
///
/// Example:
/// ```dart
/// try {
///   // Make an HTTP request
///   final response = await httpClient.get('https://api.example.com/data');
///
///   if (response.statusCode >= 400) {
///     throw HttpError(
///       exception: Exception('HTTP error ${response.statusCode}'),
///       stackTrace: StackTrace.current,
///       data: HttpMessage.fromJson(jsonDecode(response.body)),
///     );
///   }
///
///   // Process successful response
///   return processData(response.body);
/// } catch (e, stackTrace) {
///   // Handle network or other errors
///   throw HttpError(
///     exception: e,
///     stackTrace: stackTrace,
///     data: HttpMessage(
///       success: false,
///       title: 'Network Error',
///       details: 'Could not connect to the server'
///     ),
///   );
/// }
/// ```
class HttpError {
  /// The original exception
  ///
  /// This can be any exception that was caught during the HTTP operation,
  /// such as a network error, timeout, etc.
  final Object? exception;

  /// Stack trace for debugging
  ///
  /// This provides the call stack at the point where the error occurred,
  /// which is helpful for debugging.
  final StackTrace stackTrace;

  /// User-friendly error message data
  ///
  /// This contains structured error information that can be presented to the user,
  /// typically parsed from the API response or generated based on the exception.
  final HttpMessage? data;

  /// Creates a new HTTP error
  ///
  /// Parameters:
  /// - [exception]: The original exception (required)
  /// - [stackTrace]: The stack trace (required)
  /// - [data]: Optional user-friendly message data
  ///
  /// Example:
  /// ```dart
  /// final error = HttpError(
  ///   exception: Exception('Failed to connect'),
  ///   stackTrace: StackTrace.current,
  ///   data: HttpMessage(
  ///     success: false,
  ///     title: 'Connection Failed',
  ///     details: 'Please check your internet connection and try again'
  ///   ),
  /// );
  /// ```
  HttpError({
    required this.exception,
    required this.stackTrace,
    this.data,
  });
}