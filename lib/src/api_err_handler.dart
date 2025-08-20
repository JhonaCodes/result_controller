import 'package:result_controller/result_controller.dart';

/// Represents a detailed error originating from an API interaction.
///
/// Extends [ResultErr] to provide API-specific error details like HTTP status codes,
/// validation messages, and the original exception. It supports registering
/// error templates for different error types and contexts, allowing for
/// centralized and consistent error handling.
///
/// Type parameter [E] represents the type used for categorizing errors (e.g., an enum like `HttpError`).
///
class ApiErr<E> {
  // --- Properties ---

  /// Optional field-specific validation errors, often from form submissions (e.g., {'email': 'Invalid format'}).
  final Map<String, String>? validations;

  /// The original exception object that triggered this error (e.g., DioException, SocketException).
  final Object? exception;

  /// The title of the error message, provides a short description of the error.
  final String? title;

  /// The detailed error message providing information about what went wrong.
  final String? msm;

  /// The categorized error type (of type [E]) for identifying the kind of error.
  final E? errorType;

  /// The stack trace associated with the error, if available.
  final StackTrace? stackTrace;
  // --- Constructor ---

  /// Constructs a new [ApiErr] instance.
  ///
  /// The base error message for [ResultErr] is derived from [msm] if provided,
  /// otherwise defaults to the string representation of the [exception], or a generic message.
  ///
  /// Parameters:
  ///   * [exception] - The original exception that triggered this error.
  ///   * [title] - The title of the error message.
  ///   * [msm] - The detailed error message.
  ///   * [validations] - Field-specific validation errors map.
  ///   * [stackTrace] - Stack trace from when the error occurred.
  ///   * [errorType] - The categorized error type (of type [E]) for identification.
  ///
  /// Example:
  /// ```dart
  /// final apiError = ApiErr<NetworkErrorType>(
  ///   exception: SocketException('Service Unavailable'),
  ///   title: 'Service Down',
  ///   msm: 'The server is temporarily unavailable. Please try again later.',
  ///   errorType: NetworkErrorType.serviceUnavailable,
  ///   stackTrace: StackTrace.current,
  /// );
  /// ```
  const ApiErr({
    this.exception,
    this.title,
    this.msm,
    this.validations,
    this.stackTrace,
    this.errorType,
  });

  /// Creates a copy of this [ApiErr] instance with the given fields replaced with new values.
  ///
  /// This method allows you to create a new instance based on this one, while only
  /// changing specific properties.
  ///
  /// Parameters:
  ///   * [exception] - The new exception that replaces the current one.
  ///   * [title] - The new title that replaces the current one.
  ///   * [msm] - The new detailed error message that replaces the current one.
  ///   * [validations] - The new field-specific validation errors map that replaces the current one.
  ///   * [stackTrace] - The new stack trace that replaces the current one.
  ///   * [errorType] - The new categorized error type that replaces the current one.
  ///
  /// Returns a new [ApiErr] instance with the updated properties.
  ///
  /// Example:
  /// ```dart
  /// final originalError = ApiErr<NetworkErrorType>(
  ///   title: 'Connection Error',
  ///   errorType: NetworkErrorType.timeout,
  /// );
  ///
  /// final updatedError = originalError.copyWith(
  ///   title: 'Network Timeout',
  ///   msm: 'The connection timed out after 30 seconds',
  /// );
  /// ```
  ApiErr<E> copyWith({
    Object? exception,
    String? title,
    String? msm,
    Map<String, String>? validations,
    StackTrace? stackTrace,
    E? errorType,
  }) {
    return ApiErr<E>(
      exception: exception ?? this.exception,
      title: title ?? this.title,
      msm: msm ?? this.msm,
      validations: validations ?? this.validations,
      stackTrace: stackTrace ?? this.stackTrace,
      errorType: errorType ?? this.errorType,
    );
  }

  // --- toString Implementation ---

  /// Returns a human-readable string representation of the API error.
  ///
  /// Includes the error title and detailed message or the exception string.
  /// Optionally includes the stack trace if provided.
  ///
  /// Example:
  /// ```dart
  /// print(ApiErr<HttpError>(
  ///   errorType: HttpError.badRequest,
  ///   title: 'Bad Request',
  ///   msm: 'Invalid email address provided.',
  /// ));
  /// // Output: "Bad Request: Invalid email address provided."
  ///
  /// print(ApiErr<NetworkErrorType>(
  ///   errorType: NetworkErrorType.timeout,
  ///   exception: TimeoutException('Connection timed out'),
  /// ));
  /// // Output: "Error: Connection timed out"
  /// ```
  @override
  String toString() {
    final parts = <String>[];

    // Prefer structured message if available
    if (msm != null && title != null) {
      parts.add('$title: $msm');
    } else if (exception != null) {
      // Format exception message cleanly
      final exceptionString = exception is Exception
          ? (exception as Exception).toString()
          : exception.toString();
      parts.add('Error: $exceptionString');
    } else {
      parts.add('Unknown API error');
    }

    // Optionally add validation errors
    if (validations != null && validations!.isNotEmpty) {
      parts.add('Validations: ${validations.toString()}');
    }

    final result = parts.join(' | ');

    // Add stack trace if available
    if (stackTrace != null) {
      // Include basic info even with stack trace for context
      return '$result\n\nStackTrace:\n$stackTrace';
      // Alternative: return '$statusCode\n$type\n$result\n\nStackTrace:\n$stackTrace';
    }

    return result;
  }

  // --- Static Error Registry ---

  /// Stores mappings of error types and complex keys to predefined [ApiErr] templates.
  /// This single map holds registrations for both simple type lookups and complex context-based lookups.
  static final Map<dynamic, ApiErr> _errorRegistry = {};

  /// Registers a template for a given error type.
  static void registerTemplate<T>(T errorType, ApiErr template) {
    _errorRegistry[errorType] = template;
  }

  /// Retrieves a template for a given error type.
  static ApiErr<T>? getTemplate<T>(T errorType) {
    final template = _errorRegistry[errorType];
    return template is ApiErr<T> ? template : null;
  }
}
