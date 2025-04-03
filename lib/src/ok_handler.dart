import 'package:result_handler/src/result_handler.dart';

/// Represents a successful operation with a value of type [T].
///
/// This is one of the two concrete implementations of [Result], used to wrap
/// successful values and allow them to be processed in a functional way.
///
/// Example:
/// ```dart
/// Result<int, String> parseInt(String input) {
///   try {
///     return Ok(int.parse(input));
///   } catch (e) {
///     return Err('Could not parse "$input" to integer');
///   }
/// }
///
/// // Usage
/// parseInt('42').when(
///   ok: (value) => print('Got number: $value'),
///   err: (msg) => print(msg)
/// );
/// ```
class Ok<T, E> extends Result<T, E> {
  /// The successful value contained in this result
  @override
  final T data;

  /// Creates a new successful result containing [data]
  Ok(this.data);

  /// Processes this result by applying [ok] to the contained value
  ///
  /// Since this is an Ok instance, the [err] function is ignored.
  @override
  R when<R>({required R Function(T) ok, required R Function(E) err}) {
    return ok(data);
  }

  /// Transforms the success value using [transform] while preserving the Result structure
  ///
  /// Example:
  /// ```dart
  /// Ok(5).map((x) => x * 2) // Results in Ok(10)
  /// ```
  @override
  Result<R, E> map<R>(
    R Function(T value) transform, [
    E Function(E error)? err,
  ]) {
    return Ok(transform(data));
  }

  /// Chains another Result-returning operation based on the success value
  ///
  /// This is useful for sequential operations that might fail at any step.
  ///
  /// Example:
  /// ```dart
  /// fetchUser(id).flatMap((user) => fetchUserPosts(user.id))
  /// ```
  @override
  Result<R, E> flatMap<R>(
    Result<R, E> Function(T value) ok, [
    Result<R, E> Function(E error)? err,
  ]) {
    return ok(data);
  }
}
