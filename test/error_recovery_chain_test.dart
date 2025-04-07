import 'package:flutter_test/flutter_test.dart';
import 'package:result_controller/result_controller.dart';

void main() {
  group('Error Recovery Chain Tests', () {
    test('recovers from multiple errors in chain', () async {
      final result = await Result.tryAsyncMap<int, ApiErr>(
        () async => throw Exception('First error'),
        (error, stack) => ApiErr(
          message: HttpMessage(title: 'First', details: error.toString())
        )
      );

      final recoveredResult = result.recover((error) {
        if (error.message?.title == 'First') {
          return Ok(42);
        }
        return Err(error);
      });
      
      expect(recoveredResult.isOk, isTrue);
      expect(recoveredResult.data, equals(42));
    });
    
    test('transforms errors through chain', () async {
      final result = await Result.tryAsyncMap<int, String>(
        () async => throw Exception('Original error'),
        (error, stack) => 'First: $error'
      );

      final transformedResult = result
        .mapError((error) => 'Second: $error')
        .mapError((error) => 'Third: $error');
        
      expect(transformedResult.isErr, isTrue);
      expect(transformedResult.errorOrNull, contains('Third: Second: First:'));
    });
  });
} 