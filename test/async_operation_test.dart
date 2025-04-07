import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';
import 'dart:async';

// Mock classes for testing
class User {
  final String id;
  final String name;

  User({required this.id, required this.name});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class TestStackTrace implements StackTrace {
  @override
  String toString() => 'TestStackTrace';
}

class NetworkTimeoutException implements Exception {
  final String message;
  NetworkTimeoutException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

void main() {
  group('tryAsyncMap detailed tests', () {
    test('handles successful async operation', () async {
      final result = await Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => ApiResponse.ok(
          {'id': '123', 'name': 'Test User'},
          headers: {},
          statusCode: 200,
        ),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Error',
            details: error.toString(),
          ),
        ),
      );

      expect(result.isOk, isTrue);
      expect(result.data.statusCode, equals(200));
      expect(result.data.data, equals({'id': '123', 'name': 'Test User'}));
    });

    test('handles network timeout exception', () async {
      final result = await Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => throw NetworkTimeoutException('Request timed out'),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Network Error',
            details: error.toString(),
          ),
        ),
      );

      expect(result.isErr, isTrue);
      final error = result.errorOrNull;
      expect(error, isNotNull);
      expect(error!.message, isNotNull);
      expect(error.message!.title, equals('Network Error'));
      expect(error.message!.details, contains('Request timed out'));
    });

    test('handles API error with status code', () async {
      final result = await Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => throw ApiException('Invalid request', 400),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'API Error',
            details: error.toString(),
          ),
        ),
      );

      expect(result.isErr, isTrue);
      final error = result.errorOrNull;
      expect(error, isNotNull);
      expect(error!.message, isNotNull);
      expect(error.message!.title, equals('API Error'));
      expect(error.message!.details, contains('Invalid request'));
    });

    test('handles authentication exception', () async {
      final result = await Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => throw AuthException('Invalid credentials'),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Authentication Error',
            details: error.toString(),
          ),
        ),
      );

      expect(result.isErr, isTrue);
      final error = result.errorOrNull;
      expect(error, isNotNull);
      expect(error!.message, isNotNull);
      expect(error.message!.title, equals('Authentication Error'));
      expect(error.message!.details, contains('Invalid credentials'));
    });

    test('handles multiple async operations in chain', () async {
      final result = await Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => ApiResponse.ok(
          {'id': '123', 'name': 'Test User'},
          headers: {},
          statusCode: 200,
        ),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Error',
            details: error.toString(),
          ),
        ),
      ).then((result) => Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => ApiResponse.ok(
          {'email': 'test@example.com', 'role': 'user'},
          headers: {},
          statusCode: 200,
        ),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Error',
            details: error.toString(),
          ),
        ),
      ));

      expect(result.isOk, isTrue);
      expect(result.data.statusCode, equals(200));
      expect(result.data.data, equals({'email': 'test@example.com', 'role': 'user'}));
    });

    test('handles error in chain of async operations', () async {
      final result = await Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => ApiResponse.ok(
          {'id': '123', 'name': 'Test User'},
          headers: {},
          statusCode: 200,
        ),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Error',
            details: error.toString(),
          ),
        ),
      ).then((result) => Result.tryAsyncMap<ApiResponse, ApiErr>(
        () async => throw ApiException('Failed to fetch user details', 404),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          message: HttpMessage(
            title: 'Error',
            details: error.toString(),
          ),
        ),
      ));

      expect(result.isErr, isTrue);
      final error = result.errorOrNull;
      expect(error, isNotNull);
      expect(error!.message, isNotNull);
      expect(error.message!.title, equals('Error'));
      expect(error.message!.details, contains('Failed to fetch user details'));
    });

    test('handles concurrent async operations', () async {
      final operations = List.generate(
        5,
        (index) => Result.tryAsyncMap<ApiResponse, ApiErr>(
          () async => ApiResponse.ok(
            {'id': '${index + 1}', 'name': 'User ${index + 1}'},
            headers: {},
            statusCode: 200,
          ),
          (error, stackTrace) => ApiErr(
            exception: error,
            stackTrace: stackTrace,
            message: HttpMessage(
              title: 'Error',
              details: error.toString(),
            ),
          ),
        ),
      );

      final results = await Future.wait(operations);
      expect(results.length, equals(5));
      expect(results.every((result) => result.isOk), isTrue);
      expect(results.map((result) => result.data.data['id']).toList(),
          equals(['1', '2', '3', '4', '5']));
    });

    test('handles concurrent error recovery', () async {
      final operations = List.generate(
        5,
        (index) => Result.tryAsyncMap<ApiResponse, ApiErr>(
          () async => throw ApiException('Operation ${index + 1} failed', 500),
          (error, stackTrace) => ApiErr(
            exception: error,
            stackTrace: stackTrace,
            message: HttpMessage(
              title: 'Error',
              details: error.toString(),
            ),
          ),
        ),
      );

      final results = await Future.wait(operations);
      expect(results.length, equals(5));
      expect(results.every((result) => result.isErr), isTrue);
      expect(results.map((result) {
        final error = result.errorOrNull;
        expect(error, isNotNull);
        expect(error!.message, isNotNull);
        return error.message!.details;
      }).toList(), equals(List.generate(5, (index) => 'Operation ${index + 1} failed')));
    });

    test('preserves complete stack trace information', () async {
      // Create a function that will throw with a stack trace
      Future<User> fetchUser() async {
        await Future.delayed(Duration(milliseconds: 50));
        throw Exception('Test exception with stack trace');
      }

      // Use tryAsyncMap to wrap the operation
      final result = await Result.tryAsyncMap<User, ApiErr>(
        () async => await fetchUser(),
        (error, stackTrace) => ApiErr(
          message: HttpMessage(
            title: 'Error',
            details: 'Error occurred',
          ),
          exception: error,
          stackTrace: stackTrace,
        ),
      );

      expect(result.isErr, isTrue);
      expect(result.errorOrNull?.stackTrace, isNotNull);

      // The stack trace should contain information about where the error occurred
      final stackTraceString = result.errorOrNull?.stackTrace.toString() ?? '';
      expect(stackTraceString.isNotEmpty, isTrue);
    });
  });

  group('Chained async operations', () {
    test('handles long chain of async operations successfully', () async {
      // Define a series of mock async operations
      Future<Result<String, ApiErr>> fetchUserId() async {
        await Future.delayed(Duration(milliseconds: 10));
        return Ok('123');
      }

      Future<Result<User, ApiErr>> fetchUserDetails(String id) async {
        await Future.delayed(Duration(milliseconds: 20));
        return Ok(User(id: id, name: 'User $id'));
      }

      Future<Result<List<String>, ApiErr>> fetchUserPermissions(
        User user,
      ) async {
        await Future.delayed(Duration(milliseconds: 30));
        return Ok(['read', 'write', 'delete']);
      }

      Future<Result<Map<String, dynamic>, ApiErr>> buildUserProfile(
        User user,
        List<String> permissions,
      ) async {
        await Future.delayed(Duration(milliseconds: 40));
        return Ok({
          'user': user,
          'permissions': permissions,
          'isAdmin': permissions.contains('admin'),
        });
      }

      // Chain the operations correctly using async/await
      final userIdResult = await fetchUserId();

      // For each step, we need to await the intermediate result and then chain
      Result<User, ApiErr> userResult;
      if (userIdResult.isOk) {
        userResult = await fetchUserDetails(userIdResult.data);
      } else {
        userResult = Err(userIdResult.errorOrNull!);
      }

      Result<List<String>, ApiErr> permissionsResult;
      if (userResult.isOk) {
        permissionsResult = await fetchUserPermissions(userResult.data);
      } else {
        permissionsResult = Err(userResult.errorOrNull!);
      }

      Result<Map<String, dynamic>, ApiErr> profileResult;
      if (permissionsResult.isOk) {
        profileResult = await buildUserProfile(
          userResult.data,
          permissionsResult.data,
        );
      } else {
        profileResult = Err(permissionsResult.errorOrNull!);
      }

      expect(profileResult.isOk, isTrue);
      expect(profileResult.data['user'], isA<User>());
      expect(profileResult.data['permissions'], isA<List<String>>());
      expect(profileResult.data['isAdmin'], isFalse);
      expect(
        (profileResult.data['permissions'] as List<String>).length,
        equals(3),
      );
    });

    test('breaks chain at first error and preserves context', () async {
      // Define a series of mock async operations where one fails
      Future<Result<String, ApiErr>> fetchUserId() async {
        await Future.delayed(Duration(milliseconds: 10));
        return Ok('123');
      }

      Future<Result<User, ApiErr>> fetchUserDetails(String id) async {
        await Future.delayed(Duration(milliseconds: 20));
        // This operation fails
        return Err(
          ApiErr(
            message: HttpMessage(
              title: 'Not Found',
              details: 'User with ID $id not found',
            ),
          ),
        );
      }

      Future<Result<List<String>, ApiErr>> fetchUserPermissions(
        User user,
      ) async {
        await Future.delayed(Duration(milliseconds: 30));
        return Ok(['read', 'write', 'delete']);
      }

      // Chain the operations with proper error handling
      final userIdResult = await fetchUserId();

      // Use proper chaining with explicit error handling
      Result<Map<String, dynamic>, ApiErr> profileResult;

      if (userIdResult.isOk) {
        final userResult = await fetchUserDetails(userIdResult.data);

        if (userResult.isOk) {
          final permissionsResult = await fetchUserPermissions(userResult.data);

          if (permissionsResult.isOk) {
            profileResult = Ok({
              'user': userResult.data,
              'permissions': permissionsResult.data,
            });
          } else {
            profileResult = Err(permissionsResult.errorOrNull!);
          }
        } else {
          profileResult = Err(userResult.errorOrNull!);
        }
      } else {
        profileResult = Err(userIdResult.errorOrNull!);
      }

      expect(profileResult.isErr, isTrue);
      expect(
        profileResult.errorOrNull?.message?.details,
        contains('User with ID 123 not found'),
      );
    });

    test('allows error recovery in the middle of a chain', () async {
      // Define a series of mock async operations with error and recovery
      Future<Result<String, ApiErr>> fetchUserId() async {
        await Future.delayed(Duration(milliseconds: 10));
        return Ok('123');
      }

      Future<Result<User, ApiErr>> fetchUserDetails(String id) async {
        await Future.delayed(Duration(milliseconds: 20));
        // This operation fails
        return Err(
          ApiErr(
            message: HttpMessage(
              title: 'Not Found',
              details: 'User with ID $id not found',
            ),
          ),
        );
      }

      Future<Result<User, ApiErr>> fetchDefaultUser() async {
        await Future.delayed(Duration(milliseconds: 20));
        // Fallback operation
        return Ok(User(id: 'default', name: 'Guest User'));
      }

      Future<Result<List<String>, ApiErr>> fetchUserPermissions(
        User user,
      ) async {
        await Future.delayed(Duration(milliseconds: 30));
        if (user.id == 'default') {
          return Ok(['read']); // Limited permissions for guest
        }
        return Ok(['read', 'write', 'delete']);
      }

      // Chain the operations with proper recovery
      final userIdResult = await fetchUserId();

      // First operation: fetch user ID
      if (!userIdResult.isOk) {
        fail('User ID fetch should not fail in this test');
      }

      // Second operation: fetch user details with recovery
      Result<User, ApiErr> userResult = await fetchUserDetails(
        userIdResult.data,
      );

      // Recovery step: If user not found, use default user
      if (!userResult.isOk && userResult.errorOrNull?.message?.title == 'Not Found') {
        userResult = await fetchDefaultUser();
      }

      // Third operation: fetch permissions
      Result<List<String>, ApiErr> permissionsResult;
      if (userResult.isOk) {
        permissionsResult = await fetchUserPermissions(userResult.data);
      } else {
        permissionsResult = Err(userResult.errorOrNull!);
      }

      // Final step: build profile
      Result<Map<String, dynamic>, ApiErr> profileResult;
      if (permissionsResult.isOk) {
        profileResult = Ok({
          'user': userResult.data,
          'permissions': permissionsResult.data,
          'isGuest': userResult.data.id == 'default',
        });
      } else {
        profileResult = Err(permissionsResult.errorOrNull!);
      }

      expect(profileResult.isOk, isTrue);
      expect(profileResult.data['user'], isA<User>());
      expect(profileResult.data['user'].id, equals('default'));
      expect(profileResult.data['user'].name, equals('Guest User'));
      expect(profileResult.data['permissions'], equals(['read']));
      expect(profileResult.data['isGuest'], isTrue);
    });
  });

  group('FutureResultExtensions tests', () {
    test('maps Future<Result> values correctly', () async {
      // Create a Future<Result>
      Future<Result<int, String>> futureResult = Future.value(Ok(42));

      // Apply map
      final mappedFuture = futureResult.map((value) => value * 2);
      final result = await mappedFuture;

      expect(result.isOk, isTrue);
      expect(result.data, equals(84));
    });

    test('preserves error in mapped Future<Result>', () async {
      // Create a Future<Result> with error
      Future<Result<int, String>> futureResult = Future.value(
        Err('Test error'),
      );

      // Apply map
      final mappedFuture = futureResult.map((value) => value * 2);
      final result = await mappedFuture;

      expect(result.isErr, isTrue);
      expect(result.errorOrNull, equals('Test error'));
    });

    test('chains Future<Result> operations with flatMap', () async {
      // Create a Future<Result>
      Future<Result<int, String>> futureResult = Future.value(Ok(42));

      // Apply flatMap with another async operation
      final chainedFuture = futureResult.flatMap((value) async {
        await Future.delayed(Duration(milliseconds: 50));
        return Ok('Result: $value');
      });

      final result = await chainedFuture;

      expect(result.isOk, isTrue);
      expect(result.data, equals('Result: 42'));
    });

    test('flatMap preserves error in Future<Result> chain', () async {
      // Create a Future<Result> with error
      Future<Result<int, String>> futureResult = Future.value(
        Err('Initial error'),
      );

      // Apply flatMap
      final chainedFuture = futureResult.flatMap((value) async {
        await Future.delayed(Duration(milliseconds: 50));
        return Ok('Result: $value');
      });

      final result = await chainedFuture;

      expect(result.isErr, isTrue);
      expect(result.errorOrNull, equals('Initial error'));
    });

    test('complex chain of async operations with different types', () async {
      // Start with a Future<Result>
      Future<Result<int, ApiErr>> futureResult = Future.value(Ok(42));

      // Build a complex chain
      final finalResult = await futureResult
          .map((value) => value.toString())
          .flatMap((strValue) async {
            await Future.delayed(Duration(milliseconds: 50));
            return Ok<double, ApiErr>(double.parse(strValue) / 10);
          })
          .flatMap((doubleValue) async {
            await Future.delayed(Duration(milliseconds: 50));
            if (doubleValue < 1.0) {
              return Err<String, ApiErr>(
                ApiErr(
                  message: HttpMessage(
                    title: 'Invalid Value',
                    details: 'Value too small: $doubleValue',
                  ),
                ),
              );
            }
            return Ok<String, ApiErr>('Final: $doubleValue');
          });

      expect(finalResult.isOk, isTrue);
      expect(finalResult.data, equals('Final: 4.2'));
    });
  });

  group('Timeout and error handling scenarios', () {
    test('handles timed out operations with fallbacks', () async {
      // A function that simulates a timeout
      Future<Result<String, ApiErr>> fetchWithTimeout(Duration timeout) async {
        try {
          final completer = Completer<String>();

          // Set up a timer to complete after timeout
          Timer(timeout, () {
            if (!completer.isCompleted) {
              completer.completeError(
                NetworkTimeoutException('Operation timed out'),
              );
            }
          });

          // This operation takes longer than the timeout
          Timer(timeout + Duration(milliseconds: 50), () {
            if (!completer.isCompleted) {
              completer.complete('Late response - not used');
            }
          });

          // Attempt to get the result, may throw if timer triggers first
          return Result.tryAsyncMap<String, ApiErr>(
            () => completer.future,
            (error, stackTrace) => ApiErr(
              message: HttpMessage(
                title: 'Timeout',
                details: 'Operation timed out after ${timeout.inMilliseconds}ms',
              ),
              exception: error,
              stackTrace: stackTrace,
            ),
          );
        } catch (e, stackTrace) {
          return Err(
            ApiErr(
              message: HttpMessage(
                title: 'Error',
                details: 'Unexpected error: $e',
              ),
              exception: e,
              stackTrace: stackTrace,
            ),
          );
        }
      }

      // Function that provides a fallback result
      Future<Result<String, ApiErr>> fetchFallbackData() async {
        await Future.delayed(Duration(milliseconds: 50));
        return Ok('Fallback data');
      }

      // Execute with a short timeout
      final timeoutResult = await fetchWithTimeout(Duration(milliseconds: 100));

      // Handle the timeout by falling back
      Result<String, ApiErr> result;
      if (timeoutResult.isOk) {
        result = timeoutResult;
      } else {
        // Check if it's a timeout error
        if (timeoutResult.errorOrNull?.message?.title == 'Timeout') {
          // Use fallback data
          result = await fetchFallbackData();
        } else {
          // Propagate other errors
          result = timeoutResult;
        }
      }

      expect(result.isOk, isTrue);
      expect(result.data, equals('Fallback data'));
    });

    test('handles multiple concurrent async operations', () async {
      // Simulate multiple concurrent API calls
      Future<Result<String, ApiErr>> fetchResource1() async {
        await Future.delayed(Duration(milliseconds: 50));
        return Ok('Resource 1 data');
      }

      Future<Result<String, ApiErr>> fetchResource2() async {
        await Future.delayed(Duration(milliseconds: 30));
        return Ok('Resource 2 data');
      }

      Future<Result<String, ApiErr>> fetchResource3() async {
        await Future.delayed(Duration(milliseconds: 70));
        // This one fails
        return Err(
          ApiErr(
            message: HttpMessage(
              title: 'Server Error',
              details: 'Failed to fetch resource 3',
            ),
          ),
        );
      }

      // Run all three concurrently
      final results = await Future.wait([
        fetchResource1(),
        fetchResource2(),
        fetchResource3(),
      ]);

      // Check individual results
      expect(results[0].isOk, isTrue);
      expect(results[0].data, equals('Resource 1 data'));

      expect(results[1].isOk, isTrue);
      expect(results[1].data, equals('Resource 2 data'));

      expect(results[2].isErr, isTrue);
      expect(results[2].errorOrNull?.message?.title, equals('Server Error'));

      // Combine results handling both success and failures
      final combinedResult = results
          .map((result) {
            return result.when(
              ok: (data) => 'Success: $data',
              err: (error) => 'Error: ${error.message?.details}',
            );
          })
          .join(' | ');

      expect(combinedResult, contains('Success: Resource 1 data'));
      expect(combinedResult, contains('Success: Resource 2 data'));
      expect(combinedResult, contains('Error: Failed to fetch resource 3'));
    });

    test('handles specific network error scenarios', () async {
      // Simulate different network errors
      Future<Result<String, ApiErr>> simulateNetworkError(
        String errorType,
      ) async {
        await Future.delayed(Duration(milliseconds: 50));

        switch (errorType) {
          case 'dns':
            return Err(
              ApiErr(
                message: HttpMessage(
                  title: 'DNS Error',
                  details: 'Could not resolve host name',
                ),
                exception: Exception('Failed to resolve DNS'),
              ),
            );
          case 'connection':
            return Err(
              ApiErr(
                message: HttpMessage(
                  title: 'Connection Error',
                  details: 'Failed to connect to server',
                ),
                exception: Exception('Connection refused'),
              ),
            );
          case 'timeout':
            return Err(
              ApiErr(
                message: HttpMessage(
                  title: 'Timeout',
                  details: 'Request timed out after 5 seconds',
                ),
                exception: NetworkTimeoutException('Request timed out'),
              ),
            );
          default:
            return Ok('Success');
        }
      }

      // Test each error type
      final dnsError = await simulateNetworkError('dns');
      final connectionError = await simulateNetworkError('connection');
      final timeoutError = await simulateNetworkError('timeout');
      final success = await simulateNetworkError('none');

      expect(dnsError.isErr, isTrue);
      expect(dnsError.errorOrNull?.message?.title, equals('DNS Error'));

      expect(connectionError.isErr, isTrue);
      expect(
        connectionError.errorOrNull?.message?.title,
        equals('Connection Error'),
      );

      expect(timeoutError.isErr, isTrue);
      expect(timeoutError.errorOrNull?.message?.title, equals('Timeout'));

      expect(success.isOk, isTrue);
      expect(success.data, equals('Success'));

      // Process with specific handling for each error type
      final processedDns = dnsError.when(
        ok: (data) => 'Data: $data',
        err: (error) {
          if (error.message?.title == 'DNS Error') {
            return 'Please check your internet connection or DNS settings';
          }
          return 'Unknown error';
        },
      );

      final processedTimeout = timeoutError.when(
        ok: (data) => 'Data: $data',
        err: (error) {
          if (error.message?.title == 'Timeout') {
            return 'The server took too long to respond. Please try again later';
          }
          return 'Unknown error';
        },
      );

      expect(processedDns, contains('DNS settings'));
      expect(processedTimeout, contains('too long to respond'));
    });
  });

  group('Performance and load tests', () {
    test('handles large number of sequential async operations', () async {
      // Create a function that processes a number and returns a result
      Future<Result<int, ApiErr>> processNumber(int number) async {
        await Future.delayed(Duration(milliseconds: 5)); // Small delay
        if (number % 10 == 0) {
          // Simulate occasional errors
          return Err(
            ApiErr(
              message: HttpMessage(
                title: 'Processing Error',
                details: 'Cannot process multiple of 10: $number',
              ),
            ),
          );
        }
        return Ok(number * 2);
      }

      // Process a larger sequence of numbers
      final results = <Result<int, ApiErr>>[];
      for (int i = 1; i <= 50; i++) {
        results.add(await processNumber(i));
      }

      // Count successes and failures
      final successCount = results.where((r) => r.isOk).length;
      final errorCount = results.where((r) => r.isErr).length;

      // We should have 5 errors (multiples of 10: 10, 20, 30, 40, 50)
      expect(successCount, equals(45));
      expect(errorCount, equals(5));

      // Check some specific results
      expect(results[0].isOk, isTrue); // 1 -> 2
      expect(results[0].data, equals(2));

      expect(results[9].isErr, isTrue); // 10 -> error
      expect(results[9].errorOrNull?.message?.details, contains('10'));

      expect(results[20].isOk, isTrue); // 21 -> 42
      expect(results[20].data, equals(42));
    });

    test('handles parallel processing of many async operations', () async {
      // Create a function that simulates an API call
      Future<Result<String, ApiErr>> fetchData(int id) async {
        await Future.delayed(Duration(milliseconds: 10)); // Small delay

        if (id % 20 == 0) {
          // Simulate occasional server errors
          return Err(
            ApiErr(
              message: HttpMessage(
                title: 'Server Error',
                details: 'Internal error for ID $id',
              ),
            ),
          );
        } else if (id % 10 == 0) {
          // Simulate occasional not found errors
          return Err(
            ApiErr(
              message: HttpMessage(
                title: 'Not Found',
                details: 'Resource $id not found',
              ),
            ),
          );
        }

        return Ok('Data for ID $id');
      }

      // Execute many operations in parallel
      final futures = List.generate(100, (i) => fetchData(i + 1));
      final results = await Future.wait(futures);

      // Count by status
      final successCount = results.where((r) => r.isOk).length;
      final notFoundCount =
          results
              .where((r) => r.isErr && r.errorOrNull?.message?.title == 'Not Found')
              .length;
      final serverErrorCount =
          results
              .where((r) => r.isErr && r.errorOrNull?.message?.title == 'Server Error')
              .length;

      // We should have 90 successes, 5 not founds, and 5 server errors
      expect(successCount, equals(90));
      expect(notFoundCount, equals(5));
      expect(serverErrorCount, equals(5));
    });
  });
}
