import 'dart:collection';

import 'package:result_controller/result_controller.dart';

/// Represents an API error with detailed information
///
/// This class extends the base ResultError class and provides additional
/// API-specific error information such as HTTP status codes and user-friendly messages.
/// It can be used for comprehensive error handling and logging in API operations.
///
/// Key Features:
/// - Original exception capture
/// - User-friendly error messages
/// - Stack traces for debugging
/// - Exception mapping registry
///
/// Basic Example:
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
/// // Handle error based on status code
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
///
/// Example with exception mapping:
/// ```dart
/// // Register exception mappings
/// ApiErr.addAllExceptions({
///   TimeoutException: ApiErr(
///     message: HttpMessage(
///       title: 'Timeout',
///       details: 'Server took too long to respond'
///     )
///   ),
///   SocketException: ApiErr(
///     message: HttpMessage(
///       title: 'Network Error',
///       details: 'Could not connect to server'
///     )
///   ),
/// });
///
/// // Use the mapping
/// try {
///   await fetchData();
/// } catch (e) {
///   final error = ApiErr.fromException(e);
///   print(error.message?.title); // Will show the mapped title
/// }
/// ```
class ApiErr extends ResultErr {
  /// Original exception
  ///
  /// This can be any exception that was caught during the API operation,
  /// such as a network error, parsing error, etc.
  final Object? exception;

  /// HTTP status code
  ///
  /// This indicates the status of the API response, such as 200 for success
  /// or 404 for not found, etc.
  ///
  final int? statusCode;

  /// User-friendly message
  ///
  /// This provides a structured message that can be displayed to the user.
  /// It includes a title and detailed description of the error.
  final HttpMessage? message;

  /// Creates a new API error
  ///
  /// Parameters:
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
  ///   exception: e,
  ///   message: HttpMessage(
  ///     title: 'Server Error',
  ///     details: 'An unexpected error occurred on the server'
  ///   ),
  ///   stackTrace: stackTrace,
  /// );
  /// ```
  ApiErr({this.statusCode, this.exception, this.message, StackTrace? stackTrace})
    : super(
        message?.details ?? exception?.toString() ?? 'Unknown API error',
        stackTrace: stackTrace,
      );

  /// Provides a formatted string representation of the error
  ///
  /// The string includes the error message, and stack trace
  /// (if available), formatted in a readable way that's useful for
  /// logging and debugging.
  ///
  /// Example:
  /// ```dart
  /// final error = ApiErr(
  ///   message: HttpMessage(
  ///     success: false,
  ///     title: 'Validation Error',
  ///     details: 'Invalid email format'
  ///   ),
  /// );
  ///
  /// print(error.toString());
  /// // Output: "Validation Error: Invalid email format"
  /// ```
  @override
  String toString() {
    final parts = <String>[];

    if (message != null) {
      parts.add('Code: $statusCode ${message!.title}: ${message!.details}');
    } else if (exception != null) {
      parts.add(
        'Error: ${exception is Exception ? (exception as Exception).toString().replaceAll('Exception: ', '') : exception.toString()}',
      );
    } else {
      parts.add('Unknown API error');
    }

    final result = parts.join(' | ');

    if (stackTrace != null) {
      return '$result\n\nStackTrace:\n$stackTrace';
    }

    return result;
  }

  /// Registry of exception mappings for standardized error handling
  ///
  /// This map allows the application to define custom error mappings
  /// for specific exception types.
  static final HashMap<Object, ApiErr> _currentMapExceptions = HashMap.from({});

  /// Registers multiple exception-to-ApiErr mappings
  ///
  /// Use this method to register multiple exception mappings at once.
  /// This is useful for setting up exception handling during app initialization.
  ///
  /// Parameters:
  /// - [exceptions]: List of mappings between exception types and corresponding ApiErr
  ///
  /// Example:
  /// ```dart
  /// apiErrHandler.addExceptions([
  ///   {TimeoutException: ApiErr(
  ///     message: HttpMessage(
  ///       title: 'Connection Timeout',
  ///       details: 'The server took too long to respond'
  ///     )
  ///   )},
  ///   {SocketException: ApiErr(
  ///     message: HttpMessage(
  ///       title: 'Network Error',
  ///       details: 'Unable to connect to the server'
  ///     )
  ///   )},
  /// ]);
  /// ```
  static void addAllExceptions(Map<Object, ApiErr> exception) {
    _currentMapExceptions.addAll(exception);
  }

  /// Creates an ApiErr from an exception based on registered mappings
  ///
  /// This method checks the exception against registered mappings and returns
  /// the corresponding ApiErr. If no mapping exists, it returns a default
  /// error message.
  ///
  /// Parameters:
  /// - [exception]: The exception to convert to an ApiErr
  ///
  /// Returns:
  /// An ApiErr instance appropriate for the given exception, or a default
  /// ApiErr if no mapping exists.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   // Operation that might throw
  /// } catch (e) {
  ///   return ApiResult.err(ApiErr.fromException(e));
  /// }
  /// ```
  static ApiErr fromException(Object exception) =>
      _currentMapExceptions[exception] ??
      ApiErr(
        message: HttpMessage(
          title: 'Error',
          details: 'An unexpected error occurred',
        ),
      );
}
