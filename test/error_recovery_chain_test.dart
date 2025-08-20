import 'package:test/test.dart';
import 'package:result_controller/result_controller.dart';

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
  group('Error Recovery Chain Tests', () {
    test('recovers from multiple errors in chain', () async {
      final result = await tryAsyncMap<int, ApiErr>(
        () async => throw Exception('First error'),
        (error, stack) => ApiErr(title: 'First', msm: error.toString()),
      );

      final recoveredResult = result.recover((error) {
        if (error.title == 'First') {
          return Ok(42);
        }
        return Err(error);
      });

      expect(recoveredResult.isOk, isTrue);
      expect(recoveredResult.data, equals(42));
    });

    test('transforms errors through chain', () async {
      final result = await tryAsyncMap<int, String>(
        () async => throw Exception('Original error'),
        (error, stack) => 'First: $error',
      );

      final transformedResult = result
          .mapError((error) => 'Second: $error')
          .mapError((error) => 'Third: $error');

      expect(transformedResult.isErr, isTrue);
      expect(transformedResult.errorOrNull, contains('Third: Second: First:'));
    });
  });
}