import 'package:result_controller/src/result_controller.dart';

/// Represents a failed operation with an error of type [E].
///
/// This is one of the two concrete implementations of [Result], used to wrap
/// error values and propagate them through a chain of operations.
///
/// Example:
/// ```dart
/// Result<User, ApiError> fetchUser(String id) {
///   if (id.isEmpty) {
///     return Err(ApiError('Invalid ID provided'));
///   }
///
///   // Continue with fetching logic...
/// }
///
/// // Usage
/// fetchUser(userId).when(
///   ok: (user) => displayUserProfile(user),
///   err: (error) => showErrorMessage(error.message)
/// );
/// ```
class Err<T, E> extends Result<T, E> {
  /// The error value contained in this result
  final E error;

  /// Creates a new error result containing [error]
  Err(this.error);

  /// Processes this result by applying [err] to the contained error
  ///
  /// Since this is an Err instance, the [ok] function is ignored.
  @override
  R when<R>({required R Function(T) ok, required R Function(E) err}) {
    return err(error);
  }

  /// Preserves the error while maintaining the Result structure
  ///
  /// Since this is an Err instance, the [transform] function is not applied.
  /// This allows errors to propagate through a chain of transformations.
  ///
  /// Example:
  /// ```dart
  /// Err<int, String>('Invalid input').map((x) => x * 2) // Results in Err('Invalid input')
  /// ```
  @override
  Result<R, E> map<R>(
    R Function(T value) transform, [
    E Function(E error)? err,
  ]) {
    if (err != null) {
      return Err(err(error));
    }
    return Err(error);
  }

  /// Short-circuits a chain of Result operations when an error occurs
  ///
  /// This ensures that once a failure happens, subsequent operations are skipped.
  ///
  /// Example:
  /// ```dart
  /// Err<User, String>('User not found')
  ///   .flatMap((user) => fetchUserPosts(user.id)) // This is never called
  /// ```
  @override
  Result<R, E> flatMap<R>(
    Result<R, E> Function(T value) ok, [
    Result<R, E> Function(E error)? err,
  ]) {
    if (err != null) {
      return err(error);
    }
    return Err(error);
  }
}
