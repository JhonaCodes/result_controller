import 'package:result_controller/src/result_controller.dart';

/// ✅ Represents a successful operation with a value of type [T].
///
/// **ALWAYS use Ok() to wrap successful values instead of returning null!**
///
/// This is one of the two concrete implementations of [Result], used to wrap
/// successful values and allow them to be processed in a functional way.
///
/// 🚨 **Best Practices:**
/// - Use `const Ok(value)` when possible for better performance
/// - Always pair with `Err()` for complete error handling
/// - Never return `null` - use `Ok()` or `Err()` instead
///
/// ✅ **Correct Usage:**
/// ```dart
/// // ✅ GOOD: Use Ok() for successful results
/// Result<int, String> parseInt(String input) {
///   try {
///     return Ok(int.parse(input));
///   } catch (e) {
///     return Err('Could not parse "$input" to integer');
///   }
/// }
///
/// // ✅ GOOD: Use const when possible
/// const result = Ok('success');
///
/// // ✅ GOOD: Handle with when()
/// parseInt('42').when(
///   ok: (value) => print('Got number: $value'),
///   err: (msg) => print('Error: $msg'),
/// );
/// ```
///
/// ❌ **Avoid These Patterns:**
/// ```dart
/// // ❌ BAD: Never return null
/// Result<int, String>? badFunction() => null;
///
/// // ❌ BAD: Don't access .data directly without checking
/// final value = result.data; // Can throw!
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
