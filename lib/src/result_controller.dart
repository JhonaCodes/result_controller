import 'err_handler.dart';
import 'ok_handler.dart';

/// A functional approach to handling results that may be successful or contain errors.
///
/// This class implements the Result/Either pattern for error handling, allowing operations
/// that might fail to be encapsulated without using exceptions.
///
/// Key Features:
/// - Functional handling of successful results and errors
/// - Safe value transformation
/// - Operation chaining
/// - Error handling with stack traces
///
/// Basic Example:
/// ```dart
/// // Handling a potential division by zero
/// Result<double, String> divide(double a, double b) {
///   if (b == 0) return Err('Division by zero');
///   return Ok(a / b);
/// }
///
/// // Usage
/// divide(10, 2).when(
///   ok: (result) => print('Result: $result'),
///   err: (error) => print('Error: $error')
/// );
/// ```
///
/// Example with transformations:
/// ```dart
/// Result<int, String> getAge(String input) {
///   try {
///     return Ok(int.parse(input));
///   } catch (e) {
///     return Err('Could not convert "$input" to number');
///   }
/// }
///
/// // Operation chaining
/// getAge('25')
///   .map((age) => age + 1)
///   .when(
///     ok: (age) => print('Age next year: $age'),
///     err: (error) => print(error)
///   );
/// ```
abstract class Result<T, E> {
  /// Handles both success and error cases with appropriate functions.
  ///
  /// Example:
  /// ```dart
  /// fetchUser(id).when(
  ///   ok: (user) => displayUserProfile(user),
  ///   err: (error) => showErrorMessage(error)
  /// );
  /// ```
  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  });

  /// Transforms the success value while preserving the Result structure.
  ///
  /// Example:
  /// ```dart
  /// fetchUser(id)
  ///   .map((user) => user.displayName)
  ///   .when(
  ///     ok: (name) => print('Name: $name'),
  ///     err: (error) => print('Error: $error')
  ///   );
  /// ```
  Result<R, E> map<R>(R Function(T value) ok, [E Function(E error)? err]);

  /// Chains Result-returning operations without nesting Results.
  ///
  /// Example:
  /// ```dart
  /// fetchUser(id).flatMap(
  ///   (user) => fetchUserPosts(user.id)
  /// ).when(
  ///   ok: (posts) => displayPosts(posts),
  ///   err: (error) => showErrorMessage(error)
  /// );
  /// ```
  Result<R, E> flatMap<R>(
    Result<R, E> Function(T value) ok, [
    Result<R, E> Function(E error)? err,
  ]);

  /// Accesses the success value directly, throwing an error if the Result is an Err.
  ///
  /// Only use this when you're certain the Result is Ok or when you want exceptions
  /// for error cases.
  R whenData<R>(R Function(T) ok) {
    return this.when(
      ok: ok,
      err:
          (error) =>
              throw StateError('Cannot access data on Err value: $error'),
    );
  }

  /// Executes a function only if the Result contains an error.
  ///
  /// Returns null for Ok results.
  R? whenError<R>(R Function(E) err) {
    return this.when(ok: (_) => null, err: err);
  }

  /// Executes a function that might throw and wraps the result.
  ///
  /// Example:
  /// ```dart
  /// Result.trySync(() => jsonDecode(jsonString))
  ///   .when(
  ///     ok: (data) => processData(data),
  ///     err: (error) => handleParsingError(error)
  ///   );
  /// ```
  static Result<T, ResultErr> trySync<T>(T Function() fn) {
    try {
      return Ok(fn());
    } catch (e, stackTrace) {
      return Err(GenericResultError(e.toString(), e, stackTrace: stackTrace));
    }
  }

  /// Executes an async function that might throw and wraps the result.
  ///
  /// Example:
  /// ```dart
  /// await Result.tryAsync(() => fetchDataFromApi())
  ///   .then((result) => result.when(
  ///     ok: (data) => processApiData(data),
  ///     err: (error) => handleApiError(error)
  ///   ));
  /// ```
  static Future<Result<T, ResultErr>> tryAsync<T>(
    Future<T> Function() fn,
  ) async {
    try {
      return Ok(await fn());
    } catch (e, stackTrace) {
      return Err(GenericResultError(e.toString(), e, stackTrace: stackTrace));
    }
  }

  /// Executes a function that might throw and uses a custom error mapper.
  ///
  /// Example:
  /// ```dart
  /// Result.trySyncMap(
  ///   () => parseConfig(configFile),
  ///   (error, stack) => ConfigError('Invalid configuration: ${error.message}')
  /// ).when(
  ///   ok: (config) => applyConfig(config),
  ///   err: (error) => showConfigurationError(error)
  /// );
  /// ```
  static Result<T, E> trySyncMap<T, E>(
    T Function() fn,
    E Function(dynamic error, StackTrace stackTrace) errorMapper,
  ) {
    try {
      return Ok(fn());
    } catch (e, stackTrace) {
      return Err(errorMapper(e, stackTrace));
    }
  }

  /// Executes an async function and uses a custom error mapper.
  ///
  /// Example:
  /// ```dart
  /// await Result.tryAsyncMap(
  ///   () => fetchUserData(userId),
  ///   (error, stack) => UserError('Failed to fetch user: ${error.message}')
  /// ).then((result) => result.when(
  ///   ok: (userData) => updateUserProfile(userData),
  ///   err: (error) => notifyUserFetchFailed(error)
  /// ));
  /// ```
  static Future<Result<T, E>> tryAsyncMap<T, E>(
    Future<T> Function() fn,
    E Function(dynamic error, StackTrace stackTrace) errorMapper,
  ) async {
    try {
      return Ok(await fn());
    } catch (e, stackTrace) {
      return Err(errorMapper(e, stackTrace));
    }
  }

  /// Returns true if this is a success result
  bool get isOk => this.when(ok: (_) => true, err: (_) => false);

  /// Returns true if this is an error result
  bool get isErr => !isOk;

  /// Gets the success value or throws if this is an error
  ///
  /// Throws [StateError] if called on an Err value
  T get data => this.whenData((data) => data);

  /// Gets the error value if present, null otherwise
  E? get errorOrNull => this.whenError((error) => error);

  @override
  String toString() =>
      this.when(ok: (data) => 'Ok($data)', err: (error) => 'Err($error)');

  @override
  bool operator ==(Object other) {
    return this.when(
      ok: (data) => other is Ok<T, E> && other.data == data,
      err: (error) => other is Err<T, E> && other.error == error,
    );
  }

  @override
  int get hashCode =>
      this.when(ok: (data) => data.hashCode, err: (error) => error.hashCode);
}

/// Base class for all result errors
///
/// Provides a common structure for error reporting with optional stack traces
///
/// Features:
/// - Descriptive error message
/// - Optional stack trace for debugging
/// - Custom string formatting
///
/// Example:
/// ```dart
/// final error = ResultErr(
///   'Validation Error',
///   stackTrace: StackTrace.current
/// );
///
/// print(error.toString());
/// // Output: Validation Error
/// // StackTrace:
/// // #0 main (file:///...)
/// ```
class ResultErr<T> {
  final T? type;

  /// Error message describing what went wrong
  final String details;

  /// Stack trace from when the error occurred (optional)
  final StackTrace? stackTrace;

  /// Creates a new ResultError with an error message and optional stack trace
  ResultErr(this.details, {this.stackTrace, this.type});

  @override
  String toString() {
    if (stackTrace != null) {
      return '$type\n$details\nStackTrace:\n$stackTrace';
    }
    return details;
  }
}

/// Generic implementation of ResultError that captures the original error
///
/// Useful for wrapping exceptions and preserving their context
///
/// Features:
/// - Preserves original error
/// - Maintains stack trace
/// - Enhanced string formatting
///
/// Example:
/// ```dart
/// try {
///   throw Exception('Network error');
/// } catch (e, stack) {
///   final error = GenericResultError(
///     'Connection error',
///     e,
///     stackTrace: stack
///   );
///   print(error.toString());
///   // Output: Connection error
///   // StackTrace:
///   // #0 main (file:///...)
///   // Original error: Exception: Network error
/// }
/// ```
class GenericResultError extends ResultErr {
  /// The original error object that was caught
  final dynamic originalError;

  /// Creates a new GenericResultError with a message, the original error, and optional stack trace
  GenericResultError(super.details, this.originalError, {super.stackTrace});

  @override
  String toString() {
    final baseString = super.toString();
    if (originalError != null) {
      return '$baseString\nOriginal error: $originalError';
    }
    return baseString;
  }
}
