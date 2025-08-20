import 'package:result_controller/src/result_controller.dart';

import 'err_handler.dart';
import 'ok_handler.dart';

/// Extensions for asynchronous Result operations
///
/// Provides convenient methods for handling asynchronous operations with Result types,
/// including transformation, chaining, and error handling for collections.
///
/// Key Features:
/// - Transform successful values
/// - Chain asynchronous operations
/// - Handle errors in collections
/// - Convert API responses
///
/// Basic Example:
/// ```dart
/// // Transform user data
/// Future<Result<User>> fetchUserData(String id) async {
///   return await fetchUser(id).then((result) => result.map((user) {
///     return User(
///       id: user.id,
///       name: user.name.toUpperCase(),
///       email: user.email.toLowerCase(),
///     );
///   }));
/// }
/// ```
///
/// Chaining Operations Example:
/// ```dart
/// // Chain async operations
/// Future<Result<List<Post>>> fetchUserPosts(String userId) async {
///   return await fetchUser(userId).then((userResult) => userResult.flatMap((user) {
///     return fetchUserPosts(user.id);
///   }));
/// }
/// ```
///
/// Collection Processing Example:
/// ```dart
/// // Process list of users
/// Future<Result<List<User>>> fetchUsers(List<String> ids) async {
///   return await Future.wait(
///     ids.map((id) => fetchUser(id))
///   ).then((results) => results.foldResults());
/// }
/// ```
///
/// JSON Data Conversion Example:
/// ```dart
/// // Convert raw JSON data to Result
/// Future<Result<User>> fetchUserFromApi(String id) async {
///   final response = await http.get(Uri.parse('https://api.example.com/users/$id'));
///   final jsonData = jsonDecode(response.body);
///   return ApiResult.fromJson(data: jsonData, onData: (json) => User.fromJson(json));
/// }
/// ```
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
    return result.when(ok: transform, err: (error) => Err(error));
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
    return when(ok: (value) => Ok(value), err: transform);
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
    return when(ok: (value) => value, err: orElse);
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
    return when(ok: (value) => value, err: (_) => defaultValue);
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
