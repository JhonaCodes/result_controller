import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

import 'api_handler_test.dart';

class CustomError extends Error {
  final String message;
  CustomError(this.message);

  @override
  String toString() => 'CustomError: $message';
}

class NetworkError implements Exception {
  final String reason;
  NetworkError(this.reason);

  @override
  String toString() => 'NetworkError: $reason';
}

void main() {
  group('Advanced Error Handling Scenarios', () {
    test('Result.trySync handles complex synchronous errors', () {
      Result<int, ResultError> complexErrorResult = Result.trySync(() {
        if (DateTime.now().millisecondsSinceEpoch.isEven) {
          throw CustomError('Random error on even timestamp');
        }
        return 42;
      });

      complexErrorResult.when(
        ok: (value) {
          expect(value, equals(42));
        },
        err: (error) {
          expect(error.error, contains('CustomError'));
        },
      );
    });

    test('Result.tryAsync handles complex asynchronous errors', () async {
      Future<Result<int, ResultError>> complexAsyncErrorResult =
          Result.tryAsync(() async {
            await Future.delayed(Duration(milliseconds: 100));
            if (DateTime.now().millisecondsSinceEpoch.isEven) {
              throw NetworkError('Simulated network failure');
            }
            return 42;
          });

      final result = await complexAsyncErrorResult;
      result.when(
        ok: (value) {
          expect(value, equals(42));
        },
        err: (error) {
          expect(error.error, contains('NetworkError'));
        },
      );
    });

    test('Result.trySyncMap provides granular error transformation', () {
      final result = Result.trySyncMap<int, String>(
        () {
          if (DateTime.now().millisecondsSinceEpoch.isEven) {
            throw FormatException('Invalid input format');
          }
          return 42;
        },
        (error, stackTrace) {
          if (error is FormatException) {
            return 'Validation Error: ${error.message}';
          }
          return 'Unknown Error: $error';
        },
      );

      result.when(
        ok: (value) {
          expect(value, equals(42));
        },
        err: (error) {
          expect(error, matches(RegExp(r'Validation Error:|Unknown Error:')));
        },
      );
    });

    test(
      'Result.tryAsyncMap handles complex asynchronous error transformations',
      () async {
        final result = await Result.tryAsyncMap<int, String>(
          () async {
            await Future.delayed(Duration(milliseconds: 100));
            if (DateTime.now().millisecondsSinceEpoch.isEven) {
              throw NetworkError('Connection timeout');
            }
            return 42;
          },
          (error, stackTrace) {
            if (error is NetworkError) {
              return 'Network Connectivity Error: ${error.reason}';
            }
            return 'Unexpected Async Error: $error';
          },
        );

        result.when(
          ok: (value) {
            expect(value, equals(42));
          },
          err: (error) {
            expect(
              error,
              matches(
                RegExp(r'Network Connectivity Error:|Unexpected Async Error:'),
              ),
            );
          },
        );
      },
    );

    test('Nested error handling with multiple Result transformations', () {
      Result<int, String> divideNumber(int dividend, int divisor) {
        if (divisor == 0) {
          return Err('Division by zero');
        }
        return Ok(dividend ~/ divisor);
      }

      Result<String, String> processResult(int value) {
        if (value >= 10) {
          return Ok('Large number: $value');
        }
        return Err('Number too small');
      }

      final result = divideNumber(20, 2)
          .flatMap((value) => processResult(value))
          .mapError((error) => 'Transformed error: $error');

      result.when(
        ok: (value) {
          expect(value, equals('Large number: 10'));
        },
        err: (error) {
          fail('Should not reach error state');
        },
      );
    });

    test('Complex error chaining with multiple error types', () {
      Result<String, String> validateInput(String input) {
        if (input.isEmpty) {
          return Err('Input cannot be empty');
        }
        return Ok(input);
      }

      Result<String, String> processAuthorization(String input) {
        if (input.length < 5) {
          return Err('Authorization failed: input too short');
        }
        return Ok('Authorized: $input');
      }

      Result<String, String> networkOperation(String input) {
        if (DateTime.now().millisecondsSinceEpoch.isEven) {
          return Err('Network connection failed');
        }
        return Ok('Network success: $input');
      }

      final result = validateInput('test123')
          .flatMap(processAuthorization)
          .flatMap(networkOperation)
          .mapError((error) => 'Final error: $error');

      result.when(
        ok: (value) {
          expect(value, contains('Network success:'));
        },
        err: (error) {
          expect(error, matches(RegExp(r'Final error:')));
        },
      );
    });

    test('Error propagation with complex type transformations', () {
      Result<User, String> fetchUser(String id) {
        if (id.isEmpty) {
          return Err('Invalid user ID');
        }
        return Ok(User(id: id, name: 'John Doe'));
      }

      Result<String, String> getUserDisplayName(User user) {
        if (user.name.isEmpty) {
          return Err('User has no name');
        }
        return Ok('Display: ${user.name}');
      }

      final result = fetchUser('123')
          .flatMap(getUserDisplayName)
          .mapError((error) => 'User processing error: $error');

      result.when(
        ok: (displayName) {
          expect(displayName, equals('Display: John Doe'));
        },
        err: (error) {
          fail('Should not reach error state');
        },
      );
    });

    test(
      'Handling edge cases with multiple error transformation strategies',
      () {
        Result<int, String> riskyCalculation(int input) {
          if (input < 0) {
            return Err('Negative input not allowed');
          }
          if (input > 100) {
            return Err('Input too large');
          }
          return Ok(input * 2);
        }

        final scenarios = [
          (-5, 'Negative input'),
          (50, 'Valid input'),
          (150, 'Oversized input'),
        ];

        for (var (input, description) in scenarios) {
          final result = riskyCalculation(input)
              .recover((error) => Ok(0))
              .map((value) => value + 10)
              .mapError((error) => 'Recovered: $error');

          result.when(
            ok: (value) {
              if (description == 'Valid input') {
                expect(value, equals(110));
              } else {
                expect(value, equals(10));
              }
            },
            err: (error) {
              fail('Should not reach error state');
            },
          );
        }
      },
    );
  });
}
