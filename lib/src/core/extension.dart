import 'dart:convert';

import 'package:result_handler/src/core/result_handler.dart';

import 'api_handler.dart';
import 'api_response_handler.dart';
import 'err_handler.dart';
import 'ok_handler.dart';

/// Extensions for asynchronous [Result] operations
///
/// These extensions make it easier to work with [Result] values wrapped in [Future]s,
/// enabling clean chaining of async operations that may fail.
extension FutureResultExtensions<T, E> on Future<Result<T, E>> {
  /// Transforms the success value of an async Result
  ///
  /// This allows you to chain transformations on the success path while preserving
  /// the error handling capabilities of [Result].
  ///
  /// Example:
  /// ```dart
  /// fetchUserData(userId)
  ///   .map((data) => User.fromJson(data))
  ///   .then((result) => result.when(
  ///     ok: (user) => updateUI(user),
  ///     err: (error) => showError(error)
  ///   ));
  /// ```
  Future<Result<R, E>> map<R>(R Function(T value) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Chains async operations that might fail
  ///
  /// This is particularly useful for sequential async operations where each step
  /// depends on the previous one and any step might fail.
  ///
  /// Example:
  /// ```dart
  /// fetchUser(userId)
  ///   .flatMap((user) => fetchUserPosts(user.id))
  ///   .flatMap((posts) => filterRecentPosts(posts))
  ///   .then((result) => result.when(
  ///     ok: (recentPosts) => displayPosts(recentPosts),
  ///     err: (error) => showErrorMessage(error)
  ///   ));
  /// ```
  Future<Result<R, E>> flatMap<R>(
      Future<Result<R, E>> Function(T value) transform,
      ) async {
    final result = await this;
    return result.when(
      ok: transform,
      err: (error) => Err(error),
    );
  }
}

/// Extension methods for [Result]
///
/// These methods provide additional functionality to work with [Result] values,
/// enabling more functional programming patterns.
extension ResultExtensions<T, E> on Result<T, E> {
  /// Transforms the error value if present
  ///
  /// This is useful for converting between different error types or adding
  /// context to errors as they propagate through your application.
  ///
  /// Example:
  /// ```dart
  /// parseNumber(input)
  ///   .mapError((parseError) => UserFriendlyError('Please enter a valid number'))
  /// ```
  Result<T, F> mapError<F>(F Function(E error) transform) {
    return when(
      ok: (value) => Ok(value),
      err: (error) => Err(transform(error)),
    );
  }

  /// Attempts to recover from an error
  ///
  /// Provides a way to handle specific errors and potentially convert them back
  /// to success cases.
  ///
  /// Example:
  /// ```dart
  /// fetchFromNetwork()
  ///   .recover((networkError) =>
  ///     networkError is ConnectionError
  ///       ? fetchFromCache()
  ///       : Err(networkError)
  ///   )
  /// ```
  Result<T, E> recover(Result<T, E> Function(E error) transform) {
    return when(
      ok: (value) => Ok(value),
      err: transform,
    );
  }

  /// Gets the success value or extracts a value from the error
  ///
  /// This is useful when you need to handle the error case by computing
  /// an alternative value of the same type.
  ///
  /// Example:
  /// ```dart
  /// final user = fetchUser(id).getOrElse(
  ///   (error) => User.anonymous()
  /// );
  /// ```
  T getOrElse(T Function(E error) orElse) {
    return when(
      ok: (value) => value,
      err: orElse,
    );
  }

  /// Gets the success value or falls back to a default value
  ///
  /// Provides a simple way to extract the value with a fallback when
  /// you don't need the error details.
  ///
  /// Example:
  /// ```dart
  /// final count = countItems().getOrDefault(0);
  /// ```
  T getOrDefault(T defaultValue) {
    return when(
      ok: (value) => value,
      err: (_) => defaultValue,
    );
  }
}

/// Extensions for working with [Result] in collection operations
extension ResultCollectionExtensions<T, E> on Result<List<T>, E> {
  /// Maps each element in a successful list result
  ///
  /// This simplifies working with Results that contain collections.
  ///
  /// Example:
  /// ```dart
  /// fetchUsers()
  ///   .mapEach((user) => user.displayName)
  ///   .when(
  ///     ok: (names) => displayUserList(names),
  ///     err: (error) => showError(error)
  ///   );
  /// ```
  Result<List<R>, E> mapEach<R>(R Function(T item) transform) {
    return map((list) => list.map(transform).toList());
  }

  /// Filters elements in a successful list result
  ///
  /// Example:
  /// ```dart
  /// fetchUsers()
  ///   .filter((user) => user.isActive)
  ///   .when(
  ///     ok: (activeUsers) => displayActiveUsers(activeUsers),
  ///     err: (error) => showError(error)
  ///   );
  /// ```
  Result<List<T>, E> filter(bool Function(T item) predicate) {
    return map((list) => list.where(predicate).toList());
  }
}


/// Extensions for creating [Result] objects from JSON data
extension ResultFromJsonExtension on Result {
  /// Creates a Result from a JSON parsing operation
  ///
  /// Safely handles JSON parsing that might throw exceptions, with flexible input types.
  /// Automatically detects if the JSON is already decoded or needs decoding.
  ///
  /// Example:
  /// ```dart
  /// // From a JSON string
  /// Result<User, ApiError> userResult = Result.fromJson(
  ///   json: jsonString,
  ///   fromJsonFn: User.fromJson,
  ///   errorFn: (e) => ApiError('Parsing failed: ${e.message}')
  /// );
  ///
  /// // From an already decoded Map
  /// Result<User, ApiError> userResult = Result.fromJson(
  ///   json: decodedMap,
  ///   fromJsonFn: User.fromJson,
  ///   errorFn: (e) => ApiError('Invalid data structure')
  /// );
  /// ```
  static Result<T, E> fromJson<T, E>({
    required dynamic json,
    required T Function(Map<dynamic, dynamic> json) fromJsonFn,
    required E Function(dynamic error) errorFn,
  }) {
    return Result.trySyncMap<T, E>(
          () {
        // Handle different input types
        if (json is String) {
          // If input is a JSON string, decode it first
          final decoded = jsonDecode(json);
          if (decoded is! Map) {
            throw FormatException('JSON root is not an object');
          }
          return fromJsonFn(decoded);
        } else if (json is Map) {
          // If input is already a Map
          return fromJsonFn(json);
        } else {
          throw FormatException('Input is neither a JSON string nor a Map');
        }
      },
          (error, stack) => errorFn(error),
    );
  }

  /// Creates a Result from a JSON array parsing operation
  ///
  /// Safely handles JSON array parsing with flexible input types.
  /// Supports both direct list parsing and individual item parsing.
  ///
  /// Example:
  /// ```dart
  /// // Parse a list where fromJson handles the entire list
  /// Result<UserList, ApiError> userListResult = Result.fromJsonList(
  ///   json: jsonArray,
  ///   fromJsonFn: UserList.fromJson,
  ///   errorFn: (e) => ApiError('Failed to parse user list: ${e.toString()}')
  /// );
  ///
  /// // Parse a list and map each item individually
  /// Result<List<User>, ApiError> usersResult = Result.fromJsonList(
  ///   json: jsonArray,
  ///   fromJsonFn: (json) => json.map((item) => User.fromJson(item)).toList(),
  ///   errorFn: (e) => ApiError('Failed to parse users: ${e.toString()}')
  /// );
  /// ```
  static Result<T, E> fromJsonList<T, E>({
    required dynamic json,
    required T Function(List<dynamic> jsonList) fromJsonFn,
    required E Function(dynamic error) errorFn,
  }) {
    return Result.trySyncMap<T, E>(
          () {
        // Handle different input types
        if (json is String) {
          // If input is a JSON string, decode it first
          final decoded = jsonDecode(json);
          if (decoded is! List) {
            throw FormatException('JSON root is not an array');
          }
          return fromJsonFn(decoded);
        } else if (json is List) {
          // If input is already a List
          return fromJsonFn(json);
        } else {
          throw FormatException('Input is neither a JSON string nor a List');
        }
      },
          (error, stack) => errorFn(error),
    );
  }

  /// Creates a Result where each list item is individually parsed
  ///
  /// This is useful when you need a list of model objects from a JSON array.
  ///
  /// Example:
  /// ```dart
  /// Result<List<User>, ApiError> usersResult = Result.fromJsonItems(
  ///   json: usersJsonArray,
  ///   itemFromJsonFn: User.fromJson,
  ///   errorFn: (e) => ApiError('Invalid user data: ${e.toString()}')
  /// );
  /// ```
  static Result<List<I>, E> fromJsonItems<I, E>({
    required dynamic json,
    required I Function(Map<dynamic, dynamic> json) itemFromJsonFn,
    required E Function(dynamic error) errorFn,
  }) {
    return Result.trySyncMap<List<I>, E>(
          () {
        List<dynamic> list;

        // Handle different input types
        if (json is String) {
          final decoded = jsonDecode(json);
          if (decoded is! List) {
            throw FormatException('JSON root is not an array');
          }
          list = decoded;
        } else if (json is List) {
          list = json;
        } else {
          throw FormatException('Input is neither a JSON string nor a List');
        }

        // Convert each item in the list
        return list.map((item) {
          if (item is! Map) {
            throw FormatException('Item in the array is not an object');
          }
          return itemFromJsonFn(item);
        }).toList();
      },
          (error, stack) => errorFn(error),
    );
  }

  /// Creates a Result with dynamic JSON decoding based on the input structure
  ///
  /// Automatically detects if input is an object or array and applies appropriate parsing.
  ///
  /// Example:
  /// ```dart
  /// Result<dynamic, ApiError> dataResult = Result.decodeJson(
  ///   json: responseBody,
  ///   errorFn: (e) => ApiError('Failed to decode JSON: ${e.toString()}')
  /// );
  ///
  /// // Then process based on type
  /// dataResult.when(
  ///   ok: (data) {
  ///     if (data is Map) {
  ///       // Handle object
  ///     } else if (data is List) {
  ///       // Handle array
  ///     }
  ///   },
  ///   err: handleError
  /// );
  /// ```
  static Result<dynamic, E> decodeJson<E>({
    required dynamic json,
    required E Function(dynamic error) errorFn,
  }) {
    return Result.trySyncMap<dynamic, E>(
          () {
        if (json is String) {
          return jsonDecode(json);
        }
        // If already decoded, return as is
        return json;
      },
          (error, stack) => errorFn(error),
    );
  }
}


/// Extensions for working with ApiResponse objects
extension ApiResponseExtensions on ApiResponse {
  /// Converts this ApiResponse into an ApiResult
  ///
  /// Example:
  /// ```dart
  /// final userResult = apiResponse.toResult(
  ///   onData: User.fromJson,
  /// );
  /// ```
  ApiResult<T> toResult<T>(T Function(Map<String, dynamic> data) onData) {
    return ApiResult.from(
      response: this,
      onData: onData,
    );
  }

  /// Converts this ApiResponse into an ApiResult containing a list
  ///
  /// Example:
  /// ```dart
  /// final usersResult = apiResponse.toListResult(
  ///   onData: (items) => items.map(User.fromJson).toList(),
  /// );
  /// ```
  ApiResult<List<T>> toListResult<T>(List<T> Function(List<Map<String, dynamic>> data) onData) {
    return ApiResult.fromList(
      response: this,
      onData: onData,
    );
  }
}
