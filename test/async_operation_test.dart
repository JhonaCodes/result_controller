import 'package:test/test.dart';
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

Future<Result<T, E>> tryAsyncMap<T, E>(
  Future<T> Function() computation,
  E Function(Object, StackTrace) errorMapper,
) async {
  try {
    final value = await computation();
    return Ok(value);
  } catch (e, s) {
    return Err(errorMapper(e, s));
  }
}

void main() {
  group('tryAsyncMap detailed tests', () {
    test('handles successful async operation', () async {
      final result = await tryAsyncMap<ApiResult<Map<String, dynamic>>, ApiErr>(
        () async => ApiResult.ok(
          {'id': '123', 'name': 'Test User'},
          headers: {},
          statusCode: 200,
        ),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          title: 'Error',
          msm: error.toString(),
        ),
      );

      expect(result.isOk, isTrue);
      expect(result.data.statusCode, equals(200));
      expect(result.data.whenData((data) => data), equals({'id': '123', 'name': 'Test User'}));
    });

    test('handles network timeout exception', () async {
      final result = await tryAsyncMap<ApiResult, ApiErr>(
        () async => throw NetworkTimeoutException('Request timed out'),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          title: 'Network Error',
          msm: error.toString(),
        ),
      );

      expect(result.isErr, isTrue);
      final error = result.errorOrNull;
      expect(error, isNotNull);
      expect(error!.title, equals('Network Error'));
      expect(error.msm, contains('Request timed out'));
    });

    test('handles API error with status code', () async {
      final result = await tryAsyncMap<ApiResult, ApiErr>(
        () async => throw ApiException('Invalid request', 400),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          title: 'API Error',
          msm: error.toString(),
        ),
      );

      expect(result.isErr, isTrue);
      final error = result.errorOrNull;
      expect(error, isNotNull);
      expect(error!.title, equals('API Error'));
      expect(error.msm, contains('Invalid request'));
    });

    test('handles authentication exception', () async {
      final result = await tryAsyncMap<ApiResult, ApiErr>(
        () async => throw AuthException('Invalid credentials'),
        (error, stackTrace) => ApiErr(
          exception: error,
          stackTrace: stackTrace,
          title: 'Authentication Error',
          msm: error.toString(),
        ),
      );

      expect(result.isErr, isTrue);
      final error = result.errorOrNull;
      expect(error, isNotNull);
      expect(error!.title, equals('Authentication Error'));
      expect(error.msm, contains('Invalid credentials'));
    });
  });
}